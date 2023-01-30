import 'package:speed_test_port/classes/server.dart';

class SpeedTestResult {
  late double speed;
  final SpeedTestResultType type;

  late Server server;

  late int tryCount;

  bool withException = false;
  late Exception exception;

  SpeedTestResult(this.type);
}

enum SpeedTestResultType { Try, ServerDone, TestDone }
