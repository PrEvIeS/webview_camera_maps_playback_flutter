import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_camera_maps_playback_flutter/utils/app_lat_long.dart';
import 'package:webview_camera_maps_playback_flutter/utils/app_location.dart';
import 'package:webview_camera_maps_playback_flutter/utils/control_button.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';

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
  final mapControllerCompleter = Completer<YandexMapController>();
  late YandexMapController controller;

  final animation =
      const MapAnimation(type: MapAnimationType.smooth, duration: 2.0);
  MoscowLocation mosc = const MoscowLocation();
  late Point _point;
  final List<MapObject> mapObjects = [];
  final MapObjectId mapObjectId = const MapObjectId('normal_icon_placemark');

  Future<void> _initPermission() async {
    if (!await LocationService().checkPermission()) {
      await LocationService().requestPermission();
    }
    await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    AppLatLong location;
    const defLocation = MoscowLocation();
    try {
      location = await LocationService().getCurrentLocation();
    } catch (_) {
      location = defLocation;
    }
    _moveToCurrentLocation(location);
  }
  Future<Uint8List> _rawPlacemarkImage() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(50, 50);
    final fillPaint = Paint()
      ..color = Colors.blue[100]!
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const radius = 20.0;

    final circleOffset = Offset(size.height / 2, size.width / 2);

    canvas.drawCircle(circleOffset, radius, fillPaint);
    canvas.drawCircle(circleOffset, radius, strokePaint);

    final image = await recorder.endRecording().toImage(size.width.toInt(), size.height.toInt());
    final pngBytes = await image.toByteData(format: ImageByteFormat.png);

    return pngBytes!.buffer.asUint8List();
  }
  @override
  void initState() {
    super.initState();
    _initPermission().ignore();
  }

  Future<void> _moveToCurrentLocation(
    AppLatLong appLatLong,
  ) async {
    final mapObjectWithCompositeIcon = PlacemarkMapObject(
      mapId: MapObjectId('composite_icon_placemark'),
      point: Point(latitude: appLatLong.lat, longitude: appLatLong.long),
      onTap: (PlacemarkMapObject self, Point point) =>
          print('Tapped me at $point'),
      isDraggable: true,
      onDragStart: (_) => print('Drag start'),
      onDrag: (_, Point point) => print('Drag at point $point'),
      onDragEnd: (_) => print('Drag end'),
      icon: PlacemarkIcon.single(PlacemarkIconStyle(image: BitmapDescriptor.fromBytes(await _rawPlacemarkImage()))),
      opacity: 0.7,
    );
    setState(() {
      _point = Point(latitude: appLatLong.lat, longitude: appLatLong.long);
      mapObjects.add(mapObjectWithCompositeIcon);
    });
    (await mapControllerCompleter.future).moveCamera(
      animation: const MapAnimation(type: MapAnimationType.linear, duration: 1),
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(
            latitude: appLatLong.lat,
            longitude: appLatLong.long,
          ),
          zoom: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Текущее местоположение'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: YandexMap(
              mapObjects: mapObjects,
              onMapCreated: (yandexMapController) {
                mapControllerCompleter.complete(yandexMapController);
                controller = yandexMapController;
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Table(
                children: [
                  TableRow(children: [
                    ControlButton(
                        onPressed: () async {
                          await controller.moveCamera(CameraUpdate.zoomIn(),
                              animation: animation);
                        },
                        title: 'Zoom in'),
                    ControlButton(
                        onPressed: () async {
                          await controller.moveCamera(CameraUpdate.zoomOut(),
                              animation: animation);
                        },
                        title: 'Zoom out'),
                    ControlButton(
                        onPressed: () async {
                          await controller.moveCamera(
                            CameraUpdate.newCameraPosition(
                              CameraPosition(target: _point),
                            ),
                            animation: animation,
                          );
                        },
                        title: 'Specific position'),
                  ])
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
