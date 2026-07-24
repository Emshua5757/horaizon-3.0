import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart' show getTemporaryDirectory;
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/network/media_uploader.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';


class SduiVideo extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiVideo({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiVideo> createState() => _SduiVideoState();
}

class _SduiVideoState extends ConsumerState<SduiVideo> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _loadedPath;

  Timer? _hideTimer;
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Controller will be initialized dynamically in the build pass based on current path
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    if (_controller != null) {
      _controller!.removeListener(_onControllerUpdate);
      _controller!.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _resetHideTimer() {
    _hideTimer?.cancel();
    if (mounted) {
      if (!_showControls) {
        setState(() {
          _showControls = true;
        });
      }
    }
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  Future<void> _initVideoSource(String path) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _isInitialized = false;
        _loadedPath = path;
      });
    }

    final oldController = _controller;
    if (oldController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldController.removeListener(_onControllerUpdate);
        oldController.dispose();
      });
    }

    try {
      VideoPlayerController controller;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(path));
      } else if (path.startsWith('assets/')) {
        // Copy the asset data to a temporary file because video_player_win does not support assets directly
        final byteData = await rootBundle.load(path);
        final tempDir = await getTemporaryDirectory();
        final tempFile = File('${tempDir.path}/${path.split('/').last}');
        await tempFile.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ));
        controller = VideoPlayerController.file(tempFile);
      } else {
        controller = VideoPlayerController.file(File(path));
      }

      _controller = controller;
      await controller.initialize();
      controller.addListener(_onControllerUpdate);

      if (mounted && _loadedPath == path) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
        _resetHideTimer();
      }
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'sdui_video', 'Failed to initialize source ($path): $e', tags: HbpLogTag.SDUI);
      if (mounted && _loadedPath == path) {
        setState(() {
          _isInitialized = false;
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showPicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bindKey = widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Video Track',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(Icons.video_library_outlined, color: colorScheme.primary),
                  title: const Text('Mock Opossum Clip 1'),
                  subtitle: const Text('assets/mock_sdui/video1.mp4'),
                  onTap: () => _onSelectFile(context, bindKey, 'assets/mock_sdui/video1.mp4'),
                ),
                ListTile(
                  leading: Icon(Icons.video_library_outlined, color: colorScheme.primary),
                  title: const Text('Mock Opossum Clip 2'),
                  subtitle: const Text('assets/mock_sdui/video2.mp4'),
                  onTap: () => _onSelectFile(context, bindKey, 'assets/mock_sdui/video2.mp4'),
                ),
                ListTile(
                  leading: Icon(Icons.folder_open_rounded, color: colorScheme.secondary),
                  title: const Text('Select Local Video File...'),
                  subtitle: const Text('Browse your local storage for video files'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ref.read(mediaUploaderProvider).pickAndUploadWithUi(
                      context: context,
                      ref: ref,
                      bindKey: bindKey,
                      fileType: FileType.video,
                      moduleOwner: 'sdui_video',
                      dispatcher: widget.dispatcher,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSelectFile(BuildContext context, String bindKey, String filePath) {
    if (_controller != null) {
      _controller!.pause();
    }
    if (mounted) {
      setState(() {
        _isInitialized = false;
        _loadedPath = null;
        _isLoading = false;
        _hasError = false;
      });
    }

    // 1. Update StateVault
    ref.read(sduiStateVaultProvider.notifier).set(bindKey, filePath);

    // 2. Dispatch state changes back to the server
    widget.dispatcher.onStateChange(bindKey, filePath);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected Video: ${filePath.split('/').last}'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;

    // 1. Retrieve Behaviors
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0;
    final int? accentColorToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final String bindKey = node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;
    final double borderRadiusVal = node.behavior<double>(HbpBehavior.BORDER_RADIUS) ?? 
                                   node.behavior<int>(HbpBehavior.BORDER_RADIUS)?.toDouble() ?? 8.0;
    final double parsedAspect = node.behavior<double>(HbpBehavior.ASPECT_RATIO) ?? 
                               node.behavior<int>(HbpBehavior.ASPECT_RATIO)?.toDouble() ?? 1.777;

    final accentColor = SduiStyleResolver.resolveColor(context, accentColorToken) ?? colorScheme.primary;

    // 2. Retrieve Content
    final vaultValue = ref.watch(sduiStateVaultProvider.select((state) => state[bindKey] as String?));
    final String? initialSrc = node.contentVal<String>(HbpContent.SRC);
    final String? currentVideoPath = vaultValue ?? initialSrc;
    final String? label = node.contentVal<String>(HbpContent.LABEL);
    final String? placeholder = node.contentVal<String>(HbpContent.PLACEHOLDER);

    // Set source dynamically if path changes
    if (currentVideoPath != null && currentVideoPath.isNotEmpty && currentVideoPath != _loadedPath) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initVideoSource(currentVideoPath);
      });
    }

    Widget buildVideoWidget() {
      if (currentVideoPath == null || currentVideoPath.isEmpty) {
        if (interactiveMode == 1) {
          // Dotted Upload Box for picking video
          return Material(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(borderRadiusVal),
            child: InkWell(
              onTap: () => _showPicker(context),
              borderRadius: BorderRadius.circular(borderRadiusVal),
              child: Container(
                width: double.infinity,
                height: 150.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadiusVal),
                  border: Border.all(
                    color: colorScheme.outline.withAlpha(128),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.video_call_outlined, size: 36, color: colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      placeholder ?? label ?? 'Upload Video File',
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
          // Readonly Fallback
          return Container(
            width: double.infinity,
            height: 150.0,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(borderRadiusVal),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.video_camera_back_outlined, color: colorScheme.onSurfaceVariant.withAlpha(128)),
                  const SizedBox(width: 8),
                  Text(
                    placeholder ?? 'No Video Source Loaded',
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

      if (_isLoading) {
        return Container(
          width: double.infinity,
          height: 150.0,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(borderRadiusVal),
          ),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (_hasError) {
        final errorCard = Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 150.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(borderRadiusVal),
            border: Border.all(color: colorScheme.errorContainer, width: 1.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_outlined, color: colorScheme.error, size: 28),
              const SizedBox(height: 8),
              Text(
                'Failed to load video source',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage ?? 'Unknown source details',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
              ),
              if (interactiveMode == 1) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Retry'),
                      onPressed: () => _initVideoSource(currentVideoPath),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Change Source'),
                      onPressed: () => _showPicker(context),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );

        if (interactiveMode == 1) {
          return Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadiusVal),
            child: InkWell(
              onTap: () => _showPicker(context),
              borderRadius: BorderRadius.circular(borderRadiusVal),
              child: errorCard,
            ),
          );
        }
        return errorCard;
      }

      if (!_isInitialized || _controller == null) {
        return const SizedBox.shrink();
      }

      final isPlaying = _controller!.value.isPlaying;
      final position = _controller!.value.position;
      final duration = _controller!.value.duration;

      return MouseRegion(
        onHover: (_) => _resetHideTimer(),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
            if (_showControls) {
              _resetHideTimer();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadiusVal),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Video Frame Viewport
                AspectRatio(
                  aspectRatio: parsedAspect,
                  child: VideoPlayer(_controller!),
                ),

                // 2. Play/Pause Big Center Button Overlay
                AnimatedOpacity(
                  opacity: (_showControls || !isPlaying) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    ignoring: !_showControls && isPlaying,
                    child: IconButton.filled(
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withAlpha(150),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isPlaying) {
                            _controller!.pause();
                          } else {
                            _controller!.play();
                          }
                        });
                        _resetHideTimer();
                      },
                    ),
                  ),
                ),

                // 3. Bottom Gradient Controls Bar Overlay
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _showControls ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(180),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                if (isPlaying) {
                                  _controller!.pause();
                                } else {
                                  _controller!.play();
                                }
                              });
                              _resetHideTimer();
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                                activeTrackColor: accentColor,
                                inactiveTrackColor: Colors.white.withAlpha(80),
                                thumbColor: accentColor,
                              ),
                              child: Slider(
                                value: position.inMilliseconds.toDouble().clamp(
                                      0.0,
                                      duration.inMilliseconds.toDouble(),
                                    ),
                                max: duration.inMilliseconds > 0 
                                    ? duration.inMilliseconds.toDouble() 
                                    : 1.0,
                                onChanged: (value) {
                                  setState(() {
                                    _controller!.seekTo(Duration(milliseconds: value.toInt()));
                                  });
                                  _resetHideTimer();
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_formatDuration(position)} / ${_formatDuration(duration)}',
                            style: const TextStyle(
                              fontFamily: 'JetBrainsMono',
                              fontSize: 10,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Floating Edit Button (Editable Mode only)
                if (interactiveMode == 1)
                  Positioned(
                    top: 8.0,
                    right: 8.0,
                    child: AnimatedOpacity(
                      opacity: _showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Material(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          onTap: () => _showPicker(context),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.edit_outlined, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Change Video',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget contentWidget = buildVideoWidget();

    // 5. Card Wrap Strategy (If label present)
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
                  Icon(Icons.video_library_rounded, color: colorScheme.primary, size: 20),
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
              contentWidget,
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: contentWidget,
    );
  }
}
