import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/registry/sdui_icon_registry.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiMap extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiMap({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiMap> createState() => _SduiMapState();
}

class _SduiMapState extends ConsumerState<SduiMap> {
  late final MapController _mapController;
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng? _parseCoordinates(dynamic value) {
    if (value == null) return null;
    try {
      if (value is List && value.length >= 2) {
        final lat = double.tryParse(value[0].toString());
        final lng = double.tryParse(value[1].toString());
        if (value.length >= 3) {
          final zoom = double.tryParse(value[2].toString());
          if (zoom != null) {
            _currentZoom = zoom;
          }
        }
        if (lat != null && lng != null) {
          return LatLng(lat, lng);
        }
      } else if (value is String) {
        final parts = value.split(',');
        if (parts.length >= 2) {
          final lat = double.tryParse(parts[0].trim());
          final lng = double.tryParse(parts[1].trim());
          if (parts.length >= 3) {
            final zoom = double.tryParse(parts[2].trim());
            if (zoom != null) {
              _currentZoom = zoom;
            }
          }
          if (lat != null && lng != null) {
            return LatLng(lat, lng);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  List<Marker> _buildMarkers(BuildContext context, dynamic rawData, ThemeData theme, ColorScheme colorScheme) {
    if (rawData is! List) return [];
    final List<Marker> markers = [];
    for (final item in rawData) {
      if (item is Map) {
        final lat = double.tryParse(item['latitude']?.toString() ?? '');
        final lng = double.tryParse(item['longitude']?.toString() ?? '');
        if (lat != null && lng != null) {
          final String iconName = item['icon']?.toString() ?? 'location_on';
          final int? colorToken = int.tryParse(item['color']?.toString() ?? '');
          final String markerLabel = item['label']?.toString() ?? '';
          final Map<dynamic, dynamic>? actionPayload = item['action'] as Map<dynamic, dynamic>?;

          final markerColor = resolveHbpColorToken(context, colorToken ?? HbpColorToken.PRIMARY) ?? colorScheme.primary;
          final markerIcon = SduiIconRegistry.resolve(iconName);

          markers.add(
            Marker(
              point: LatLng(lat, lng),
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  if (actionPayload != null) {
                    widget.dispatcher.onAction(actionPayload.map((k, v) => MapEntry(int.parse(k.toString()), v)));
                  } else if (markerLabel.isNotEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(markerLabel),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Tooltip(
                  message: markerLabel,
                  child: Icon(
                    markerIcon,
                    color: markerColor,
                    size: 30,
                  ),
                ),
              ),
            ),
          );
        }
      }
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;
    final dispatcher = widget.dispatcher;

    // 1. Retrieve Behaviors
    final double height = node.behavior<double>(HbpBehavior.HEIGHT) ?? 
                          node.behavior<int>(HbpBehavior.HEIGHT)?.toDouble() ?? 250.0;
    final double borderRadiusVal = node.behavior<double>(HbpBehavior.BORDER_RADIUS) ?? 
                                   node.behavior<int>(HbpBehavior.BORDER_RADIUS)?.toDouble() ?? 12.0;
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0; // 0=readonly, 1=editable
    final int allowZoom = node.behavior<int>(HbpBehavior.ALLOW_ZOOM) ?? 1; // 0=locked, 1=zoomable
    final String bindKey = node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;
    final Map<int, dynamic>? actionPayload = node.behavior<Map<int, dynamic>>(HbpBehavior.ACTION_PAYLOAD);
    
    // Zoom overrides from server behavior (max_value key)
    final serverZoom = node.behavior<double>(HbpBehavior.MAX_VALUE) ?? 
                       node.behavior<int>(HbpBehavior.MAX_VALUE)?.toDouble();

    // 2. Retrieve Content
    final String tileUrl = node.contentVal<String>(HbpContent.SRC) ?? 
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    final String? label = node.contentVal<String>(HbpContent.LABEL);
    
    // Watch coordinates from StateVault for hot updates
    final vaultValue = ref.watch(sduiStateVaultProvider.select((state) => state[bindKey]));
    
    // Fallback: Localized coordinate matching regional setup (Cebu city default)
    final LatLng defaultCenter = const LatLng(10.3298, 123.9351); 
    
    // Parse coordinates and update _currentZoom side-effect
    final LatLng center = _parseCoordinates(vaultValue) ?? 
                          _parseCoordinates(node.contentVal(HbpContent.VALUE)) ?? 
                          defaultCenter;
    
    if (serverZoom != null && vaultValue == null) {
      _currentZoom = serverZoom;
    }

    // Set up reactive camera listener on StateVault changes
    ref.listen(sduiStateVaultProvider.select((state) => state[bindKey]), (previous, next) {
      final newCoords = _parseCoordinates(next);
      if (newCoords != null) {
        _mapController.move(newCoords, _currentZoom);
      }
    });

    // 3. Parse Custom Markers from DATA
    final rawData = node.contentVal(HbpContent.DATA);
    final List<Marker> markers = _buildMarkers(context, rawData, theme, colorScheme);

    // If in interactive mode, show a tapped/relocated marker representing current coordinates
    if (interactiveMode == 1) {
      markers.add(
        Marker(
          point: center,
          width: 45,
          height: 45,
          child: Icon(
            Icons.location_searching_rounded,
            color: colorScheme.secondary,
            size: 32,
          ),
        ),
      );
    }

    Widget mapWidget = SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadiusVal),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: _currentZoom,
            interactionOptions: InteractionOptions(
              flags: allowZoom == 1 
                  ? InteractiveFlag.all 
                  : (InteractiveFlag.all & 
                     ~InteractiveFlag.pinchZoom & 
                     ~InteractiveFlag.doubleTapZoom & 
                     ~InteractiveFlag.scrollWheelZoom),
            ),
            onTap: (tapPosition, point) {
              if (interactiveMode == 1) {
                final coordList = [point.latitude, point.longitude, _currentZoom];
                ref.read(sduiStateVaultProvider.notifier).set(bindKey, coordList);
                dispatcher.onStateChange(bindKey, coordList);
              } else if (actionPayload != null) {
                dispatcher.onAction(actionPayload);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: tileUrl,
              userAgentPackageName: 'com.horaizon.app',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );

    // If a label exists, wrap the map in a clean styled card layout
    if (label != null && label.isNotEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadiusVal)),
        color: colorScheme.surfaceContainer,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.map_outlined, color: colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              mapWidget,
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: mapWidget,
    );
  }
}
