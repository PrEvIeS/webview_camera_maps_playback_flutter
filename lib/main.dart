import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  late VideoPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(
            'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
        videoPlayerOptions: VideoPlayerOptions())
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        setState(() {
          _videoPlayerController.play();
        });
      });
    _videoPlayerController.setLooping(true);
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int maxBuffering = 0;
    for (final DurationRange range in _videoPlayerController.value.buffered) {
      final int end = range.end.inMilliseconds;
      if (end > maxBuffering) {
        maxBuffering = end;
      }
    }
    StreamBuilder<Duration?> _progressBar() {
      return StreamBuilder<Duration?>(
        stream: _videoPlayerController.position.asStream(),
        builder: (context, snapshot) {
          final int duration =
              _videoPlayerController.value.duration.inMilliseconds;
          final int position =
              _videoPlayerController.value.position.inMilliseconds;
          final progress = position / duration;
          final buffered = maxBuffering / duration;
          final total = _videoPlayerController.value.duration;
          return ProgressBar(
            progress: Duration(milliseconds: progress.round()),
            buffered: Duration(milliseconds: buffered.round()),
            total: total,
            onDragUpdate: (details) {
              debugPrint('${details.timeStamp}, ${details.localPosition}');
            },
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            children: [
              _videoPlayerController.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoPlayerController.value.aspectRatio,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: <Widget>[
                          VideoPlayer(_videoPlayerController),
                          _progressBar(),
                        ],
                      ),
                    )
                  : Container(),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    fixedSize: MaterialStateProperty.all(const Size(70, 70)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100)))),
                onPressed: () {
                  _videoPlayerController.seekTo(
                    Duration(
                        seconds:
                            _videoPlayerController.value.position.inSeconds -
                                10),
                  );
                },
                child: const Icon(Icons.replay_10),
              ),
              ElevatedButton(
                onPressed: () {
                  _videoPlayerController.pause();
                },
                child: const Icon(Icons.pause),
              ),
              const Padding(padding: EdgeInsets.all(2)),
              ElevatedButton(
                onPressed: () {
                  _videoPlayerController.play();
                },
                child: const Icon(Icons.play_arrow),
              ),
              ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all<Color>(Colors.white),
                    fixedSize: MaterialStateProperty.all(const Size(70, 70)),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  onPressed: () {
                    _videoPlayerController.seekTo(
                      Duration(
                        seconds:
                            _videoPlayerController.value.position.inSeconds +
                                10,
                      ),
                    );
                  },
                  child: const Icon(Icons.forward_10))
            ],
          )
        ],
      ),
    );
  }
}
