import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/network/media_uploader.dart';

class SduiImage extends ConsumerWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiImage({super.key, required this.node, required this.dispatcher});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dpr = MediaQuery.devicePixelRatioOf(context);

    // 1. Retrieve Behaviors
    final double? width = node.behavior(HbpBehavior.WIDTH)?.toDouble();
    final double? height = node.behavior(HbpBehavior.HEIGHT)?.toDouble();
    final double? aspectRatio = node
        .behavior(HbpBehavior.ASPECT_RATIO)
        ?.toDouble();
    final double borderRadiusVal =
        node.behavior(HbpBehavior.BORDER_RADIUS)?.toDouble() ?? 8.0;
    final int clipBehaviorVal =
        node.behavior(HbpBehavior.CLIP_BEHAVIOR) ?? 1; // 1 = antiAlias
    final int interactiveMode =
        node.behavior(HbpBehavior.INTERACTIVE_MODE) ??
        0; // 0=readonly, 1=editable
    final int allowZoom =
        node.behavior(HbpBehavior.ALLOW_ZOOM) ?? 0; // 0=disabled, 1=enabled

    final Clip clipBehavior = clipBehaviorVal == 1 ? Clip.antiAlias : Clip.none;

    // Calculate Cache Dimensions to prevent OOM
    final int? cacheWidth = width != null ? (width * dpr).round() : null;
    final int? cacheHeight = height != null ? (height * dpr).round() : null;

    // 2. State & Content Resolution
    final String? vaultValue = ref.watch(
      sduiStateVaultProvider.select((state) => state[node.id] as String?),
    );
    final String? initialSrc = node.contentVal(HbpContent.SRC);
    final String? currentImagePath = vaultValue ?? initialSrc;
    final String? label = node.contentVal(HbpContent.LABEL);

    // Unique tag for Hero animation
    final String heroTag = 'sdui_image_${node.id}';

    // 3. Render Strategies
    Widget buildImageWidget() {
      if (currentImagePath == null || currentImagePath.isEmpty) {
        if (interactiveMode == 1) {
          return Material(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(borderRadiusVal),
            child: InkWell(
              onTap: () => _pickAndUpload(context, ref, fileType: FileType.image),
              borderRadius: BorderRadius.circular(borderRadiusVal),
              child: Container(
                width: width ?? double.infinity,
                height: height ?? 150.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadiusVal),
                  border: Border.all(
                    color: colorScheme.outline.withAlpha(128),
                    style: BorderStyle.solid,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      size: 36,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      label ?? 'Upload Image File',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        } else {
          return Container(
            width: width ?? double.infinity,
            height: height ?? 150.0,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(borderRadiusVal),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    color: colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'No Image Source',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(128),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }

      Widget rawImage;
      try {
        if (currentImagePath.startsWith('http://') ||
            currentImagePath.startsWith('https://')) {
          rawImage = CachedNetworkImage(
            imageUrl: currentImagePath,
            fit: BoxFit.cover,
            width: width,
            height: height,
            memCacheWidth: cacheWidth,
            memCacheHeight: cacheHeight,
            placeholder: (context, url) => Container(
              width: width ?? double.infinity,
              height: height ?? 150.0,
              color: colorScheme.surfaceContainerHighest,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => _buildErrorImage(
              currentImagePath,
              width,
              height,
              colorScheme,
              theme,
            ),
          );
        } else if (currentImagePath.startsWith('data:image')) {
          final UriData? data = Uri.parse(currentImagePath).data;
          if (data != null && data.isBase64) {
            rawImage = Image.memory(
              data.contentAsBytes(),
              fit: BoxFit.cover,
              width: width,
              height: height,
              cacheWidth: cacheWidth,
              cacheHeight: cacheHeight,
              errorBuilder: (c, e, s) => _buildErrorImage(
                'Invalid Base64 Data',
                width,
                height,
                colorScheme,
                theme,
              ),
            );
          } else {
            throw Exception('Invalid data URI');
          }
        } else if (currentImagePath.startsWith('assets/')) {
          rawImage = Image.asset(
            currentImagePath,
            fit: BoxFit.cover,
            width: width,
            height: height,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (c, e, s) => _buildErrorImage(
              currentImagePath,
              width,
              height,
              colorScheme,
              theme,
            ),
          );
        } else {
          rawImage = Image.file(
            io.File(currentImagePath),
            fit: BoxFit.cover,
            width: width,
            height: height,
            cacheWidth: cacheWidth,
            cacheHeight: cacheHeight,
            errorBuilder: (c, e, s) => _buildErrorImage(
              currentImagePath,
              width,
              height,
              colorScheme,
              theme,
            ),
          );
        }
      } catch (e) {
        rawImage = _buildErrorImage(
          currentImagePath,
          width,
          height,
          colorScheme,
          theme,
        );
      }

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadiusVal),
        clipBehavior: clipBehavior,
        child: InkWell(
          onTap: () {
            if (interactiveMode == 1) {
              _pickAndUpload(context, ref, fileType: FileType.image);
            } else if (allowZoom == 1) {
              _showZoomModal(
                context,
                currentImagePath,
                heroTag,
                colorScheme,
                theme,
              );
            }
          },
          child: Hero(
            tag: heroTag,
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.passthrough,
              children: [
                rawImage,
                if (interactiveMode == 1)
                  Positioned(
                    bottom: 8.0,
                    right: 8.0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                if (allowZoom == 1 && interactiveMode == 0)
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(100),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: const Icon(
                        Icons.zoom_in_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget contentWidget = buildImageWidget();

    // 4. Structural Modifier Wrappers
    if (aspectRatio != null && aspectRatio > 0) {
      contentWidget = AspectRatio(
        aspectRatio: aspectRatio,
        child: contentWidget,
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: contentWidget,
    );
  }

  Widget _buildErrorImage(
    String path,
    double? width,
    double? height,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 150.0,
      color: colorScheme.surfaceContainer,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image_outlined, color: colorScheme.error),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Failed loading file:\n$path',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showZoomModal(
    BuildContext context,
    String imagePath,
    String heroTag,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withAlpha(220),
        pageBuilder: (ctx, animation, secondaryAnimation) {
          return SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Hero(
                      tag: heroTag,
                      child: _buildZoomImage(imagePath, colorScheme, theme),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Material(
                    color: Colors.transparent,
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildZoomImage(
    String imagePath,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    // No memCacheWidth applied here to allow full resolution zoom when expanded
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: imagePath,
        errorWidget: (ctx, url, error) =>
            _buildErrorImage(imagePath, null, null, colorScheme, theme),
      );
    } else if (imagePath.startsWith('data:image')) {
      final UriData? data = Uri.parse(imagePath).data;
      return Image.memory(
        data!.contentAsBytes(),
        errorBuilder: (c, e, s) => _buildErrorImage(
          'Invalid Base64 Data',
          null,
          null,
          colorScheme,
          theme,
        ),
      );
    } else if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        errorBuilder: (ctx, err, stack) =>
            _buildErrorImage(imagePath, null, null, colorScheme, theme),
      );
    } else {
      return Image.file(
        io.File(imagePath),
        errorBuilder: (ctx, err, stack) =>
            _buildErrorImage(imagePath, null, null, colorScheme, theme),
      );
    }
  }

  // _showPicker is removed to directly trigger _pickAndUpload(FileType.image) and prevent format mismatches.


  /// Pick file from native picker then upload via Governor CAS pipeline.
  Future<void> _pickAndUpload(
    BuildContext context,
    WidgetRef ref, {
    required FileType fileType,
  }) async {
    await ref.read(mediaUploaderProvider).pickAndUploadWithUi(
      context: context,
      ref: ref,
      bindKey: node.id,
      fileType: fileType,
      moduleOwner: 'sdui_image',
      dispatcher: dispatcher,
    );
  }
}
