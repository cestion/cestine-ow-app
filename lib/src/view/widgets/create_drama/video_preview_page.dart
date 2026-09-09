import 'dart:async';

import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';

/// 视频预览全屏页面：使用原生播放器渲染本地或网络视频。
///
/// 进入后自动加载并播放；退出时释放控制器。
/// 关闭原生控制条（含全屏按钮），改用自定义 overlay：
/// 播放/暂停、文字时间、可拖动进度条；
/// 控制层 3 秒无操作自动淡出，点击视频区重新显示。
class VideoPreviewPage extends StatefulWidget {
  final String videoPath;
  final String title;

  const VideoPreviewPage({
    super.key,
    required this.videoPath,
    required this.title,
  });

  @override
  State<VideoPreviewPage> createState() => _VideoPreviewPageState();
}

class _VideoPreviewPageState extends State<VideoPreviewPage>
    with SingleTickerProviderStateMixin {
  late final NativeVideoPlayerController _controller;
  bool _hasError = false;
  bool _isLoading = true;
  bool _isBuffering = false;
  StreamSubscription<PlayerActivityState>? _playerStateSubscription;

  // overlay 显示/隐藏
  late final AnimationController _overlayAnimController;
  late final Animation<double> _overlayOpacity;
  bool _overlayVisible = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _controller = NativeVideoPlayerController(
      id: DateTime.now().millisecondsSinceEpoch,
      showNativeControls: false,
    );
    _overlayAnimController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _overlayOpacity = CurvedAnimation(
      parent: _overlayAnimController,
      curve: Curves.easeInOut,
    );
    _overlayAnimController.value = 1.0;
    _playerStateSubscription = _controller.playerStateStream.listen((state) {
      if (!mounted) return;
      final isBuffering = state == PlayerActivityState.buffering;
      final hasStartedPlaying =
          state == PlayerActivityState.playing && _isLoading;
      if (_isBuffering != isBuffering || hasStartedPlaying) {
        setState(() {
          _isBuffering = isBuffering;
          if (hasStartedPlaying) _isLoading = false;
        });
      }
      if (hasStartedPlaying) {
        _startHideTimer();
      }
    });
    unawaited(_loadAndPlay());
  }

  Future<void> _loadAndPlay() async {
    try {
      await _controller.initialize();
      if (!mounted) return;
      final source = widget.videoPath;
      if (source.startsWith('http://') || source.startsWith('https://')) {
        await _controller.load(url: source);
      } else {
        await _controller.loadFile(path: source);
      }
      if (!mounted) return;
      await _controller.play();
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _overlayVisible) {
        setState(() {
          _overlayVisible = false;
          _overlayAnimController.reverse();
        });
      }
    });
  }

  void _toggleOverlay() {
    if (_isLoading) return;
    setState(() {
      _overlayVisible = !_overlayVisible;
      if (_overlayVisible) {
        _overlayAnimController.forward();
        _startHideTimer();
      } else {
        _hideTimer?.cancel();
        _overlayAnimController.reverse();
      }
    });
  }

  void _restartHideTimer() {
    if (_overlayVisible) _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    unawaited(_playerStateSubscription?.cancel());
    _overlayAnimController.dispose();
    _controller.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoryColors.darkBackground,
      appBar: AppBar(
        backgroundColor: StoryColors.darkBackground,
        foregroundColor: StoryColors.onOverlay,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: _hasError
            ? Center(
                child: Text(
                  context.l10n.playerPlayFailed,
                  style: const TextStyle(color: StoryColors.onOverlay),
                ),
              )
            : Stack(
                children: [
                  NativeVideoPlayer(controller: _controller),
                  // 点击视频区切换 overlay 显示/隐藏
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _toggleOverlay,
                      behavior: HitTestBehavior.opaque,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  // 控制层：淡入淡出
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_overlayVisible || _isLoading,
                      child: FadeTransition(
                        opacity: _overlayOpacity,
                        child: _SimpleVideoControls(
                          controller: _controller,
                          onInteract: _restartHideTimer,
                        ),
                      ),
                    ),
                  ),
                  // 控制层隐藏时，缓冲状态仍需给用户明确反馈。
                  if (!_overlayVisible && _isBuffering && !_isLoading)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: SizedBox.square(
                            dimension: 64,
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                color: StoryColors.onOverlay,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_isLoading)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: StoryColors.darkBackground,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

/// 最简自定义播放控制层：播放/暂停、时间文字、可拖动进度条。
class _SimpleVideoControls extends StatefulWidget {
  final NativeVideoPlayerController controller;
  final VoidCallback onInteract;

  const _SimpleVideoControls({
    required this.controller,
    required this.onInteract,
  });

  @override
  State<_SimpleVideoControls> createState() => _SimpleVideoControlsState();
}

class _SimpleVideoControlsState extends State<_SimpleVideoControls> {
  int? _seekingMs;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    return StreamBuilder<Duration>(
      stream: controller.durationStream,
      initialData: controller.duration,
      builder: (context, durSnapshot) {
        final duration = durSnapshot.data ?? Duration.zero;
        final durationMs = duration.inMilliseconds;
        final maxSlider = durationMs > 0 ? durationMs.toDouble() : 1.0;
        return StreamBuilder<Duration>(
          stream: controller.positionStream,
          initialData: controller.currentPosition,
          builder: (context, posSnapshot) {
            final position = posSnapshot.data ?? Duration.zero;
            final displayMs =
                _seekingMs ?? position.inMilliseconds.clamp(0, durationMs);
            final sliderValue = displayMs.toDouble().clamp(0.0, maxSlider);
            return Stack(
              children: [
                // 居中播放/暂停按钮
                Center(
                  child: StreamBuilder<PlayerActivityState>(
                    stream: controller.playerStateStream,
                    initialData: controller.activityState,
                    builder: (context, stateSnapshot) {
                      final state = stateSnapshot.data;
                      final isBuffering =
                          state == PlayerActivityState.buffering;
                      final isPlaying = state?.isPlaying ?? false;
                      if (isBuffering) {
                        return const SizedBox.square(
                          dimension: 64,
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                              color: StoryColors.onOverlay,
                            ),
                          ),
                        );
                      }
                      return IconButton(
                        iconSize: 64,
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: StoryColors.onOverlay,
                        ),
                        onPressed: () {
                          widget.onInteract();
                          if (isPlaying) {
                            unawaited(controller.pause());
                          } else {
                            unawaited(controller.play());
                          }
                        },
                      );
                    },
                  ),
                ),
                // 底部：进度条 + 时间文字
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SliderTheme(
                          data: const SliderThemeData(
                            // thumbColor: Colors.black,
                            // activeTrackColor: Colors.black,
                            // inactiveTrackColor: Colors.white,
                            // overlayColor: Colors.white,
                            // valueIndicatorColor: Colors.black,
                          ),
                          child: Slider(
                            value: sliderValue,
                            max: maxSlider,
                            onChanged: durationMs <= 0
                                ? null
                                : (v) {
                                    widget.onInteract();
                                    setState(() => _seekingMs = v.round());
                                  },
                            onChangeEnd: durationMs <= 0
                                ? null
                                : (v) {
                                    widget.onInteract();
                                    unawaited(
                                      controller.seekTo(
                                        Duration(milliseconds: v.round()),
                                      ),
                                    );
                                    setState(() => _seekingMs = null);
                                  },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(
                                  Duration(milliseconds: displayMs),
                                ),
                                style: const TextStyle(
                                  color: StoryColors.onOverlay,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(
                                  color: StoryColors.onOverlay,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

String _formatDuration(Duration d) {
  if (d.inMilliseconds < 0) return '00:00';
  final total = d.inSeconds;
  final m = (total ~/ 60).clamp(0, 99);
  final s = total % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
