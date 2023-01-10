import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

var location;
var timer;

Future<bool> setupLocation() async {
  location ??= Location();
  location.enableBackgroundMode(enable: true);

  var serviceEnabled = await location!.serviceEnabled();
  if (!serviceEnabled) {
    serviceEnabled = await location!.requestService();
    if (!serviceEnabled) {
      return false;
    }
  }

  var permissionGranted = await location!.hasPermission();
  if (permissionGranted == PermissionStatus.denied) {
    permissionGranted = await location!.requestPermission();
    if (permissionGranted != PermissionStatus.granted) {
      return false;
    }
  }
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
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

class _MyHomePageState extends State<MyHomePage> {
  final int _counter = 0;

  @override
  void initState() {
    setupLocation();
    super.initState();
  }

  _stopSendingLocation() {
    timer.cancel();
  }

  _startSendingLocation() async {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      LocationData locationData = await location.getLocation();
      debugPrint(locationData.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _startSendingLocation,
            tooltip: 'Send Location',
            child: const Icon(Icons.start),
          ),
          const SizedBox(
            height: 10,
          ),
          FloatingActionButton(
            onPressed: _stopSendingLocation,
            tooltip: 'Stop Location',
            child: const Icon(Icons.stop),
          ),
        ],
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
