import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
  int _currentPageIndex = 0;
  late List<CameraDescription> cameras;
  List<XFile> photos = [];
  CameraController? _controller;
  XFile? lastImage;

  @override
  void initState() {
    super.initState();
    unawaited(initCamera());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onNewCameraSelected(CameraDescription description) async {
    if (_controller != null) {
      await _controller!.dispose();
    }

    final CameraController cameraController = CameraController(
      description,
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = cameraController;

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();

    _controller = CameraController(cameras[0], ResolutionPreset.max);

    await _controller!.initialize();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentPageIndex = index;
          });
        },
        selectedIndex: _currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.camera),
            label: 'Camera',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo),
            label: 'Gallery',
          ),
        ],
      ),
      body: <Widget>[
        _controller?.value.isInitialized == true
            ? Center(
                child: CameraPreview(_controller!),
              )
            : const SizedBox(),
        ListView.builder(
          itemCount: photos.length,
          itemBuilder: (context, index) {
            return Image.file(
              File(photos[index].path),
              fit: BoxFit.cover,
            );
          },
        ),
      ][_currentPageIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          lastImage = await _controller?.takePicture();
          setState(() {
            photos.add(lastImage!);
            print(photos);
          });
        },
        tooltip: 'Photo',
        child: const Icon(Icons.camera),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
