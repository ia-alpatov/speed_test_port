import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speed_test_port/classes/classes.dart';
import 'package:speed_test_port/speed_test_port_stream.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(),
      home: Scaffold(
        body: MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  @override
  State<MyHomePage> createState() {
    return _MyHomePageState();
  }
}

class MyHomePageViewModel extends ChangeNotifier {
  String? PING;
  String? IN;
  String? OUT;
  String? SERVER;
  SpeedTestPortStream _speedTestPortStream = SpeedTestPortStream();

  Future<void> measureConnection() async {
    var Title = "Getting settings...";

    showDialog<void>(
        barrierDismissible: false,
        context: _buildContext!,
        builder: (_) {
          return Dialog(
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 15,
                  ),
                  ChangeNotifierProvider<MyHomePageViewModel>.value(
                      value: this, child: Consumer<MyHomePageViewModel>(builder: (_, vm, __) => Text(Title)))
                ],
              ),
            ),
          );
        });

    _speedTestPortStream.getSettings().listen((settings) async {
      Title = "Checking servers...";
      notifyListeners();

      var serversTested = List<Server>.empty(growable: true);

      await for (final server in _speedTestPortStream.getServersWithLatency(servers: settings.servers)) {
        serversTested.add(server);
        Title = serversTested.length.toString() + "/" + settings.servers.length.toString() + " servers checked...";
        notifyListeners();
      }

      serversTested.sort((a, b) => a.latency.compareTo(b.latency));
      var bestServers = serversTested.take(3); //Take top 3 servers for test
      Server? bestServer;
      var downloadResults = List<SpeedTestResult>.empty(growable: true);

      _speedTestPortStream.testDownloadSpeed(servers: bestServers.toList()).listen((testResults) {
        switch (testResults.type) {
          case SpeedTestResultType.Try:
            Title = "[Download speed] checking server: " +
                testResults.server.toString() +
                " try " +
                testResults.tryCount.toString() +
                " done " +
                (testResults.withException
                    ? "with exception" + testResults.exception.toString()
                    : "successfully with result " + (testResults.speed).toStringAsFixed(2) + " Mb/s");
            notifyListeners();
            break;
          case SpeedTestResultType.ServerDone:
            Title = "[Download speed] checking server: " +
                testResults.server.toString() +
                " done " +
                (testResults.withException
                    ? "with exception" + testResults.exception.toString()
                    : "successfully with result " + (testResults.speed).toStringAsFixed(2) + " Mb/s");
            notifyListeners();
            downloadResults.add(testResults);
            break;
          case SpeedTestResultType.TestDone:
            downloadResults.sort((a, b) => a.server.latency.compareTo(b.server.latency));

            var bestTest = downloadResults.firstWhere((result) => result.withException == false);
            IN = (bestTest.speed).toStringAsFixed(2);
            bestServer = bestTest.server;
            SERVER = bestServer?.toString();
            PING = bestTest.server.latency.toString();

            Title = "[Download speed] result is done " +
                (testResults.withException
                    ? "with exception" + testResults.exception.toString()
                    : "with best server: " +
                        bestTest.server.toString() +
                        " with speed " +
                        bestTest.speed.toStringAsFixed(2) +
                        " Mb/s");
            notifyListeners();

            break;
        }
      }).onDone(() {
        if (bestServer != null) {
          _speedTestPortStream.testUploadSpeed(servers: List.filled(1, bestServer!)).listen((testResults) {
            switch (testResults.type) {
              case SpeedTestResultType.Try:
                Title = "[Upload speed] checking server: " +
                    testResults.server.toString() +
                    " try " +
                    testResults.tryCount.toString() +
                    " done " +
                    (testResults.withException
                        ? "with exception" + testResults.exception.toString()
                        : "successfully with result " + (testResults.speed).toStringAsFixed(2) + " Mb/s");
                notifyListeners();
                break;
              case SpeedTestResultType.ServerDone:
                Title = "[Upload speed] checking server: " +
                    testResults.server.toString() +
                    " done " +
                    (testResults.withException
                        ? "with exception" + testResults.exception.toString()
                        : "successfully with result " + (testResults.speed).toStringAsFixed(2) + " Mb/s");

                OUT = (testResults.speed).toStringAsFixed(2);
                notifyListeners();

                break;
              case SpeedTestResultType.TestDone:
                Title = "All tests is done!";
                notifyListeners();
                break;
            }
          }).onDone(() {
            Navigator.of(_buildContext!).pop();
          });
        } else {
          //TODO: show error
          Navigator.of(_buildContext!).pop();
        }
      });
    });
  }

  BuildContext? _buildContext;
  void initContext(BuildContext buildContext) {
    _buildContext = buildContext;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  SpeedTestPortStream stream = SpeedTestPortStream();

  MyHomePageViewModel model = MyHomePageViewModel();
  @override
  void initState() {
    model = MyHomePageViewModel();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ButtonStyle styleBlue = ElevatedButton.styleFrom(
        textStyle: const TextStyle(fontSize: 20), minimumSize: Size(0, 50), primary: Color(0xFF3A7EBC));
    model.initContext(context);
    return ChangeNotifierProvider<MyHomePageViewModel>.value(
        value: model,
        child: Consumer<MyHomePageViewModel>(
            builder: (_, vm, __) => Container(
                    // Center is a layout widget. It takes a single child and positions it
                    // in the middle of the parent.
                    child: Column(
                  children: [
                    SizedBox(height: 100),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text("Connection info", style: TextStyle(fontWeight: FontWeight.normal))),
                    const SizedBox(height: 10),
                    Table(columnWidths: {
                      0: FlexColumnWidth(1),
                      1: FlexColumnWidth(1),
                      2: FlexColumnWidth(1),
                      3: FlexColumnWidth(1),
                    }, children: [
                      TableRow(children: [
                        Text("Server"),
                        Text("Ping"),
                        Text("IN, Mb/s"),
                        Text("OUT, Mb/s"),
                      ]),
                      TableRow(children: [
                        Text(model.SERVER ?? ""),
                        Text(model.PING ?? ""),
                        Text(model.IN ?? ""),
                        Text(model.OUT ?? ""),
                      ])
                    ]),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: ElevatedButton(
                        style: styleBlue,
                        onPressed: () async {
                          await model.measureConnection();
                        },
                        child: const Text('Check connection'),
                      ),
                    )
                  ],
                ))));
  }
}
