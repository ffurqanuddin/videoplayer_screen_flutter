import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class VideoViewPage extends ConsumerStatefulWidget {
  const VideoViewPage({super.key, required this.videoLink});

  final String videoLink;

  @override
  ConsumerState<VideoViewPage> createState() => _VideoViewPageState();
}

class _VideoViewPageState extends ConsumerState<VideoViewPage> {
  late VideoPlayerController _videoController;
  late ChewieController _chewieController;

  // 🎥 Initialize video and Chewie controllers
  @override
  void initState() {
    super.initState();

    // Initialize the video controller with the provided video link
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoLink));

    // Initialize ChewieController with video options
    _chewieController = ChewieController(
      placeholder: const Center(
        child: CircularProgressIndicator(
          color: Colors.amber,
          backgroundColor: Colors.pink,
        ),
      ),
      videoPlayerController: _videoController,
      autoInitialize: true,
      autoPlay: true,
      showControls: false,
      aspectRatio: _videoController.value.aspectRatio,
      showControlsOnInitialize: false,
      allowMuting: true,
      looping: false,
      errorBuilder: (context, errorMessage) => Center(
        child: Text(errorMessage),
      ),
    );

    // Listen to video playback position changes
    _videoController.addListener(() {
      ref.read(_sliderValueStateProvider.notifier).state =
          _videoController.value.position.inSeconds.toDouble();

      ref.read(_videoIsPlayingStateProvider.notifier).state =
          _chewieController.isPlaying;
    });

    // Auto-hide the slider after three seconds
    Future.delayed(const Duration(seconds: 3), () {
      ref.read(_showControlsStateProvider.notifier).state = false;
    });
  }

  // Handle slider value change
  void onChanged(double value) {
    final Duration newPosition = Duration(seconds: value.toInt());
    _videoController.seekTo(newPosition);
    _chewieController.play();
  }

  // Toggle slider visibility on tap
  void toggleSliderVisibility() {
    ref.read(_showControlsStateProvider.notifier).state =
    !ref.read(_showControlsStateProvider.notifier).state;
  }

  /// Format Duration as 'mm:ss'
  String _formatDuration(Duration duration) {
    int minutes = duration.inMinutes;
    int seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    double _sliderValue = ref.watch(_sliderValueStateProvider);
    final isVideoPlaying = ref.watch(_videoIsPlayingStateProvider);

    return GestureDetector(
      onTap: toggleSliderVisibility, // Toggle slider visibility on tap
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: Visibility(
            visible: ref.watch(_showControlsStateProvider),
            child: IconButton(
              onPressed: () {
                _videoController.pause(); // Pause the video on back button press
                Navigator.pop(context);
              },
              icon: const Icon(CupertinoIcons.back),
            ),
          ),
        ),
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // 🎥 Video Player
            Chewie(controller: _chewieController),

            // 🎚️ Custom Slider (conditionally visible)
            if (ref.watch(_showControlsStateProvider))
              Positioned(
                bottom: 2.h,
                left: 10.w,
                right: 10.w,
                child: Slider(
                  thumbColor: Colors.amber,
                  activeColor: Colors.pink,
                  value: _sliderValue,
                  onChanged: onChanged,
                  min: 0.0,
                  max: _videoController.value.duration.inSeconds
                      .toDouble(), // Set max slider value based on video duration
                ),
              ),

            // ⏯️ Play/Pause Button
            Positioned(
              bottom: 2.h,
              left: 2.w,
              child: IconButton(
                onPressed: () {
                  if (_chewieController.isPlaying) {
                    _chewieController.pause();
                    ref.read(_videoIsPlayingStateProvider.notifier).state =
                    false;
                  } else {
                    _chewieController.play();
                    ref.read(_videoIsPlayingStateProvider.notifier).state =
                    true;
                  }
                },
                icon: Icon(
                    isVideoPlaying == true ? Icons.pause : Icons.play_arrow),
              ),
            ),

            // 🕒 Video Duration (conditionally visible)
            if (ref.watch(_showControlsStateProvider))
              Positioned(
                bottom: 3.7.h,
                right: 2.w,
                child: Text(
                  _formatDuration(_videoController.value.duration),
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    _videoController.dispose(); // Dispose of the video controller
    _chewieController.dispose(); // Dispose of the Chewie controller
  }
}

// Provider
final _sliderValueStateProvider = StateProvider.autoDispose<double>((ref) => 0);
final _videoIsPlayingStateProvider =
StateProvider.autoDispose<bool>((ref) => false);

final _showControlsStateProvider =
StateProvider.autoDispose<bool>((ref) => false);
