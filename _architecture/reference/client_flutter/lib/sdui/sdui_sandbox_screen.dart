import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/registry/sdui_type_registry.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';

class SduiSandboxScreen extends ConsumerStatefulWidget {
  const SduiSandboxScreen({super.key});

  @override
  ConsumerState<SduiSandboxScreen> createState() => _SduiSandboxScreenState();
}

class _SduiSandboxScreenState extends ConsumerState<SduiSandboxScreen> {
  int _selectedIndex = 0;
  List<MapEntry<String, SduiNode>> _blueprints = [];
  bool _isLoading = true;
  String? _error;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    try {
      final list = await _loadBlueprints();
      if (mounted) {
        setState(() {
          _blueprints = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<List<MapEntry<String, SduiNode>>> _loadBlueprints() async {
    final String jsonStr = await rootBundle.loadString('assets/mock_sdui/sdui_blueprints.json');
    final Map<String, dynamic> data = json.decode(jsonStr);
    final Map<String, dynamic> blueprints = data['blueprints'];
    
    return blueprints.entries.map((e) {
      // Add fake ID to the JSON before parsing
      final map = Map<String, dynamic>.from(e.value);
      map['id'] = 'sandbox_${e.key}';
      
      final nodeJson = {
        'id': map['id'],
        'typeId': map['0'],
        'behaviors': map['3'] ?? {},
        'content': map['4'] ?? {},
        'children': map['2'],
      };
      
      return MapEntry(e.key, _parseLegacyV4Format(nodeJson));
    }).toList();
  }

  SduiNode _parseLegacyV4Format(Map<String, dynamic> map) {
    return SduiNode(
      id: map['id'] ?? 'unknown_id',
      typeId: map['typeId'] ?? map['0'] ?? 100,
      behaviors: _parseIntMap(map['behaviors'] ?? map['3']) as Map<int, dynamic>? ?? const <int, dynamic>{},
      content: _parseIntMap(map['content'] ?? map['4']) as Map<int, dynamic>? ?? const <int, dynamic>{},
      children: map['children'] != null || map['2'] != null
          ? ((map['children'] ?? map['2']) as List)
              .map((c) => _parseLegacyV4Format(c as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  dynamic _parseIntMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<int, dynamic>) return value;
    if (value is Map) {
      final canParseAllKeys = value.keys.every((k) => int.tryParse(k.toString()) != null);
      if (canParseAllKeys) {
        final Map<int, dynamic> result = {};
        for (final entry in value.entries) {
          result[int.parse(entry.key.toString())] = _parseIntMap(entry.value);
        }
        return result;
      } else {
        final Map<String, dynamic> result = {};
        for (final entry in value.entries) {
          result[entry.key.toString()] = _parseIntMap(entry.value);
        }
        return result;
      }
    }
    if (value is List) {
      return value.map((v) => _parseIntMap(v)).toList();
    }
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final dispatcher = ref.watch(sduiDispatcherProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SDUI-4 Sandbox'),
        actions: _isLoading || _error != null || _blueprints.isEmpty
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: _showAll
                      ? null
                      : () {
                          setState(() {
                            _selectedIndex = (_selectedIndex - 1 + _blueprints.length) % _blueprints.length;
                          });
                        },
                ),
                Center(
                  child: Text(
                    _showAll ? 'All (${_blueprints.length})' : '${_selectedIndex + 1}/${_blueprints.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded),
                  onPressed: _showAll
                      ? null
                      : () {
                          setState(() {
                            _selectedIndex = (_selectedIndex + 1) % _blueprints.length;
                          });
                        },
                ),
                IconButton(
                  icon: Icon(_showAll ? Icons.filter_none_rounded : Icons.view_headline_rounded),
                  tooltip: _showAll ? 'Show Single' : 'Show All in List',
                  onPressed: () {
                    setState(() {
                      _showAll = !_showAll;
                    });
                  },
                ),
              ],
      ),
      body: _buildBody(dispatcher),
    );
  }

  Widget _buildBody(SduiEventDispatcher dispatcher) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Error loading blueprints:\n$_error', 
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_blueprints.isEmpty) {
      return const Center(child: Text('No blueprints compiled.'));
    }

    if (_showAll) {
      return ListView.separated(
        padding: const EdgeInsets.all(24.0),
        itemCount: _blueprints.length,
        separatorBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24.0),
          child: Divider(thickness: 2),
        ),
        itemBuilder: (context, index) {
          final blueprint = _blueprints[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Name: ${blueprint.key}', 
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                  ),
                  Text(
                    'Type ID: ${blueprint.value.typeId}', 
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Render the individual primitive layout node
              KeyedSubtree(
                key: ValueKey('sandbox_render_all_${blueprint.key}'),
                child: SduiTypeRegistry.buildNode(blueprint.value, dispatcher, context),
              ),
            ],
          );
        },
      );
    }

    final blueprint = _blueprints[_selectedIndex];

    return Column(
      children: [
        // Dropdown Selector Bar
        Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              const Text('Select Blueprint: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedIndex,
                    isExpanded: true,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedIndex = val;
                        });
                      }
                    },
                    items: List.generate(_blueprints.length, (index) {
                      final key = _blueprints[index].key;
                      return DropdownMenuItem<int>(
                        value: index,
                        child: Text(
                          '$index: $key',
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Target Blueprint Render Box
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Name: ${blueprint.key}', 
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                Text(
                  'Type ID: ${blueprint.value.typeId}', 
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Divider(height: 24),
                const SizedBox(height: 12),
                
                // Render the individual primitive layout node
                KeyedSubtree(
                  key: ValueKey('sandbox_render_${blueprint.key}'),
                  child: SduiTypeRegistry.buildNode(blueprint.value, dispatcher, context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
