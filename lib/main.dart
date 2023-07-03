import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

void main() {
  runApp(const MyApp());
}

Location? location;
Timer? timer;

const int frequencyTimer = 5;

Future<bool> setupLocation() async {
  location ??= Location();
  location?.enableBackgroundMode(enable: true);

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
  late IO.Socket socket;
  String _mobileNumber = '';
  bool _saved = false;
  bool _isWorking = false;
  bool _isConnected = false;

  IO.Socket connectSocket() {
    IO.Socket socket =
        IO.io('https://location-tracker-sr6p.onrender.com/', <String, dynamic>{
      'transports': ['websocket'],
      'headers':
          "{'Content-Type': 'application/json', ' Bypass-Tunnel-Reminder': 'true'}",
      'autoConnect': true,
    });
    socket.onConnect((_) {
      setState(() => _isConnected = true);
    });
    socket.onDisconnect((_) => {setState(() => _isConnected = false)});
    socket.onError((data) => {debugPrint(data)});
    socket.on('fromServer', (_) => debugPrint(_));
    return socket;
  }

  @override
  void initState() {
    setupLocation();
    socket = connectSocket();
    super.initState();
  }

  _stopSendingLocation() {
    timer!.cancel();
    setState(() => _isWorking = false);
  }

  _startSendingLocation(IO.Socket socket) async {
    if (_isWorking) {
      return;
    }
    if (!_isConnected) {
      socket = connectSocket();
    }
    timer =
        Timer.periodic(const Duration(seconds: frequencyTimer), (timer) async {
      LocationData locationData = await location!.getLocation();
      socket.emit(
          'newLocationObject',
          jsonEncode({
            "phone": _mobileNumber,
            "timestamp": DateTime.now().microsecondsSinceEpoch,
            "lat": locationData.latitude,
            "lng": locationData.longitude,
          }));
      debugPrint(locationData.toString());
    });
    setState(() => _isWorking = true);
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
            Text(_isWorking
                ? "Working Right Now"
                : "Press Start to start working"),
            Text(_isConnected ? "Connected" : "Not Connected"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: TextFormField(
                onChanged: (value) => {_mobileNumber = value},
                enabled: !_saved,
                decoration: const InputDecoration(
                  border: UnderlineInputBorder(),
                  labelText: 'Phone Number',
                ),
              ),
            ),
            TextButton(
                onPressed: () => {setState(() => _saved = !_saved)},
                child: Text(_saved ? "Edit" : "Save"))
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isWorking
            ? _stopSendingLocation
            : () => _startSendingLocation(socket),
        tooltip: 'Send Location',
        child: Icon(_isWorking ? Icons.stop : Icons.play_arrow),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
