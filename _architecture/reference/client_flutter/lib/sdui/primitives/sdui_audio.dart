import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/network/media_uploader.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';


class SduiAudio extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiAudio({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiAudio> createState() => _SduiAudioState();
}

class _SduiAudioState extends ConsumerState<SduiAudio> {
  late final AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isSourceLoaded = false;
  bool _isLoading = false;
  bool _hasError = false;
  String? _errorMessage;
  String? _loadedPath;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    
    // Set up listeners for player state events
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _setAudioSource(String path) async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _isSourceLoaded = false;
        _loadedPath = path;
        _position = Duration.zero;
        _duration = Duration.zero;
      });
    }
    try {
      Source source;
      if (path.startsWith('http://') || path.startsWith('https://')) {
        source = UrlSource(path);
      } else if (path.startsWith('assets/')) {
        final cleanPath = path.replaceFirst('assets/', '');
        source = AssetSource(cleanPath);
      } else {
        source = DeviceFileSource(path);
      }
      await _audioPlayer.setSource(source);
      if (mounted) {
        setState(() {
          _isSourceLoaded = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'sdui_audio', 'Failed to set source: $e', tags: HbpLogTag.SDUI);
      if (mounted) {
        setState(() {
          _isSourceLoaded = false;
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (!_isSourceLoaded) return;
    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _showPicker(BuildContext context, String bindKey) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  'Select Audio Track',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(Icons.music_note_rounded, color: colorScheme.primary),
                  title: const Text('Mock Podcast Clip 1'),
                  subtitle: const Text('assets/mock_sdui/sample1.mp3'),
                  onTap: () => _onSelectFile(context, bindKey, 'assets/mock_sdui/sample1.mp3'),
                ),
                ListTile(
                  leading: Icon(Icons.spatial_audio_off_rounded, color: colorScheme.primary),
                  title: const Text('Mock Nature Ambience'),
                  subtitle: const Text('assets/mock_sdui/sample2.mp3'),
                  onTap: () => _onSelectFile(context, bindKey, 'assets/mock_sdui/sample2.mp3'),
                ),
                ListTile(
                  leading: Icon(Icons.folder_open_rounded, color: colorScheme.secondary),
                  title: const Text('Select Local File...'),
                  subtitle: const Text('Browse your local storage for audio files'),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await ref.read(mediaUploaderProvider).pickAndUploadWithUi(
                      context: context,
                      ref: ref,
                      bindKey: bindKey,
                      fileType: FileType.audio,
                      moduleOwner: 'sdui_audio',
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
    _audioPlayer.stop();
    if (mounted) {
      setState(() {
        _isSourceLoaded = false;
        _loadedPath = null;
        _position = Duration.zero;
        _duration = Duration.zero;
        _isLoading = false;
        _hasError = false;
      });
    }
    
    // 1. Update StateVault
    ref.read(sduiStateVaultProvider.notifier).set(bindKey, filePath);

    // 2. Dispatch state change back to the server
    widget.dispatcher.onStateChange(bindKey, filePath);

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Selected Track: ${filePath.split('/').last}'),
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
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0; // 0=readonly, 1=editable
    final int? accentColorToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final String bindKey = node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;
    final double borderRadiusVal = node.behavior<double>(HbpBehavior.BORDER_RADIUS) ?? 
                                   node.behavior<int>(HbpBehavior.BORDER_RADIUS)?.toDouble() ?? 12.0;

    final accentColor = SduiStyleResolver.resolveColor(context, accentColorToken) ?? colorScheme.primary;

    // 2. Retrieve Content
    final vaultValue = ref.watch(sduiStateVaultProvider.select((state) => state[bindKey] as String?));
    final String? initialSrc = node.contentVal<String>(HbpContent.SRC);
    final String? currentAudioPath = vaultValue ?? initialSrc;
    final String? label = node.contentVal<String>(HbpContent.LABEL);
    final String? placeholder = node.contentVal<String>(HbpContent.PLACEHOLDER);

    // Set source dynamically if path changes
    if (currentAudioPath != null && currentAudioPath.isNotEmpty && currentAudioPath != _loadedPath) {
      // Run as post frame callback to avoid triggers during build cycle
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _setAudioSource(currentAudioPath);
      });
    }

    Widget buildPlayerWidget() {
      if (currentAudioPath == null || currentAudioPath.isEmpty) {
        if (interactiveMode == 1) {
          // Dotted Upload Box for picking audio
          return Material(
            color: colorScheme.surfaceContainer,
            borderRadius: BorderRadius.circular(borderRadiusVal),
            child: InkWell(
              onTap: () => _showPicker(context, bindKey),
              borderRadius: BorderRadius.circular(borderRadiusVal),
              child: Container(
                width: double.infinity,
                height: 100.0,
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
                    Icon(Icons.audiotrack_outlined, size: 28, color: colorScheme.primary),
                    const SizedBox(height: 8),
                    Text(
                      placeholder ?? label ?? 'Upload Audio File',
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
            height: 70.0,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(borderRadiusVal),
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spatial_audio_off_outlined, color: colorScheme.onSurfaceVariant.withAlpha(128)),
                  const SizedBox(width: 8),
                  Text(
                    placeholder ?? 'No Audio Track Loaded',
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
          height: 72.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(borderRadiusVal),
            border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.0),
              ),
              const SizedBox(width: 16),
              Text(
                'Loading audio track...',
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        );
      }

      if (_hasError) {
        final errorCard = Container(
          height: 72.0,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(borderRadiusVal),
            border: Border.all(color: colorScheme.errorContainer, width: 1.0),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.error),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Failed to load track',
                      style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _errorMessage ?? 'Unknown error source',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ],
                ),
              ),
              if (interactiveMode == 1) ...[
                IconButton(
                  tooltip: 'Retry',
                  icon: Icon(Icons.refresh_rounded, color: colorScheme.primary),
                  onPressed: () => _setAudioSource(currentAudioPath),
                ),
                IconButton(
                  tooltip: 'Choose another file',
                  icon: Icon(Icons.edit_outlined, color: colorScheme.primary),
                  onPressed: () => _showPicker(context, bindKey),
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
              onTap: () => _showPicker(context, bindKey),
              borderRadius: BorderRadius.circular(borderRadiusVal),
              child: errorCard,
            ),
          );
        }
        return errorCard;
      }

      final isPlaying = _playerState == PlayerState.playing;

      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(borderRadiusVal),
          border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
        ),
        child: Row(
          children: [
            // Play/Pause circular button
            IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: colorScheme.onPrimary,
              ),
              icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
              onPressed: _isSourceLoaded ? _togglePlayback : null,
            ),
            const SizedBox(width: 12),
            // Track Info / Progress scrubber
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          label ?? currentAudioPath.split('/').last,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'JetBrainsMono',
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3.0,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12.0),
                      activeTrackColor: accentColor,
                      inactiveTrackColor: colorScheme.outlineVariant,
                      thumbColor: accentColor,
                    ),
                    child: Slider(
                      value: _position.inMilliseconds.toDouble(),
                      max: _duration.inMilliseconds > 0 
                          ? _duration.inMilliseconds.toDouble() 
                          : 1.0,
                      onChanged: _isSourceLoaded
                          ? (value) {
                              setState(() {
                                _position = Duration(milliseconds: value.toInt());
                              });
                            }
                          : null,
                      onChangeEnd: (value) {
                        _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (interactiveMode == 1) ...[
              const SizedBox(width: 8),
              // Edit/Source Change Option
              IconButton(
                icon: Icon(Icons.edit_outlined, color: colorScheme.primary, size: 20),
                onPressed: () => _showPicker(context, bindKey),
              ),
            ],
          ],
        ),
      );
    }

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
                  Icon(Icons.audiotrack_rounded, color: colorScheme.primary, size: 20),
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
              buildPlayerWidget(),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: buildPlayerWidget(),
    );
  }
}
