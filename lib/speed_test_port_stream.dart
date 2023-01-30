library speed_test_port;

import 'package:http/http.dart' as http;
import 'package:speed_test_port/classes/classes.dart';
import 'package:speed_test_port/constants.dart';
import 'package:speed_test_port/enums/file_size.dart';
import 'dart:async';
import 'dart:math';

import 'package:xml_parser/xml_parser.dart';

/// A Speed tester. [Stream] based
class SpeedTestPortStream {
  /// Returns Stream[Settings] from speedtest.net.
  Stream<Settings> getSettings() async* {
    final response = await http.get(Uri.parse(configUrl));
    final doc = XmlDocument.from(response.body);

    if (doc == null) throw Exception("Can't get speed test settings");
    if (!doc.hasChild('settings')) throw Exception("Can't get settings from settings xml");

    final settings = Settings.fromXMLElement(
      doc!.getElement('settings')!,
    );

    var serversConfig = ServersList(<Server>[]);
    for (final element in serversUrls) {
      if (serversConfig.servers.isNotEmpty) break;
      try {
        final resp = await http.get(Uri.parse(element));

        final docServersList = XmlDocument.from(resp.body);

        if (docServersList == null) throw Exception("Can't get speed test settings");
        if (!docServersList.hasChild('settings')) throw Exception("Can't get settings from settings xml");

        serversConfig = ServersList.fromXMLElement(
          docServersList.getElement('settings')!,
        );
      } catch (ex) {
        serversConfig = ServersList(<Server>[]);
      }
    }

    final ignoredIds = settings.serverConfig.ignoreIds.split(',');
    serversConfig.calculateDistances(settings.client.geoCoordinate);
    settings.servers = serversConfig.servers
        .where(
          (s) => !ignoredIds.contains(s.id.toString()),
        )
        .toList();
    settings.servers.sort((a, b) => a.distance.compareTo(b.distance));

    yield settings;
  }

  /// Returns a Stream[Server] with latency
  /// Use serversToTest.sort((a, b) => a.latency.compareTo(b.latency)); for ordering
  Stream<Server> getServersWithLatency({
    required List<Server> servers,
    int retryCount = 2,
    int timeoutInSeconds = 2,
  }) async* {
    List<Server> serversToTest = [];

    for (final server in servers) {
      final latencyUri = createTestUrl(server, 'latency.txt');
      final stopwatch = Stopwatch();

      stopwatch.start();
      try {
        await http.get(latencyUri).timeout(
              Duration(
                seconds: timeoutInSeconds,
              ),
              onTimeout: (() => http.Response(
                    '999999999',
                    500,
                  )),
            );
        // If a server fails the request, continue in the iteration
      } catch (_) {
        continue;
      } finally {
        stopwatch.stop();
      }

      final latency = stopwatch.elapsedMilliseconds / retryCount;
      if (latency < 500) {
        server.latency = latency;
        yield server;
      }
    }
  }

  /// Creates [Uri] from [Server] and [String] file
  Uri createTestUrl(Server server, String file) {
    return Uri.parse(
      Uri.parse(server.url).toString().replaceAll('upload.php', file),
    );
  }

  /// Returns urls for download test.
  List<String> generateDownloadUrls(
    Server server,
    int retryCount,
    List<FileSize> downloadSizes,
  ) {
    final downloadUriBase = createTestUrl(server, 'random{0}x{0}.jpg?r={1}');
    final result = <String>[];
    for (final ds in downloadSizes) {
      for (var i = 0; i < retryCount; i++) {
        result.add(
          downloadUriBase
              .toString()
              .replaceAll('%7B0%7D', FILE_SIZE_MAPPING[ds].toString())
              .replaceAll('%7B1%7D', i.toString()),
        );
      }
    }
    return result;
  }

  double getSpeed(List<int> tasks, int elapsedMilliseconds) {
    final _totalSize = tasks.reduce((a, b) => a + b);
    return (_totalSize * 8 / 1024) / (elapsedMilliseconds / 1000) / 1000;
  }

  /// Returns Steam[double] downloaded speed in MB/s.
  Stream<SpeedTestResult> testDownloadSpeed(
      {required List<Server> servers, int retryCount = 3, List<FileSize> downloadSizes = defaultDownloadSizes}) async* {
    // Iterates over all servers, if one request fails, the next one is tried.
    try {
      for (final s in servers) {
        final testData = generateDownloadUrls(s, retryCount, downloadSizes);
        final tasks = <int>[];
        final stopwatch = Stopwatch()..start();
        try {
          for (final td in testData) {
            try {
              final data = await http.get(Uri.parse(td));
              tasks.add(data.bodyBytes.length);

              var result = SpeedTestResult(SpeedTestResultType.Try);
              result.server = s;
              result.tryCount = testData.indexOf(td);
              result.speed = getSpeed(
                tasks,
                stopwatch.elapsedMilliseconds,
              );
              yield result;
            } catch (exc) {
              var result = SpeedTestResult(SpeedTestResultType.Try);
              result.server = s;
              result.withException = true;
              result.exception = e as Exception;
              yield result;
            } finally {}
          }

          stopwatch.stop();
          var result = SpeedTestResult(SpeedTestResultType.ServerDone);
          result.server = s;
          result.speed = getSpeed(
            tasks,
            stopwatch.elapsedMilliseconds,
          );
          yield result;
        } catch (ex) {
          var result = SpeedTestResult(SpeedTestResultType.ServerDone);
          result.server = s;
          result.withException = true;
          result.exception = e as Exception;
          yield result;
        }
      }
    } catch (e) {
      var result = SpeedTestResult(SpeedTestResultType.TestDone);
      result.withException = true;
      result.exception = e as Exception;
      yield result;
    }

    var result = SpeedTestResult(SpeedTestResultType.TestDone);
    result.withException = false;
    yield result;
  }

  /// Returns [double] upload speed in MB/s.
  Stream<SpeedTestResult> testUploadSpeed({required List<Server> servers, int retryCount = 3}) async* {
    // Iterates over all servers, if one request fails, the next one is tried.
    try {
      for (final s in servers) {
        final testData = generateUploadData(retryCount);
        final tasks = <int>[];
        final stopwatch = Stopwatch()..start();
        try {
          for (final td in testData) {
            try {
              await http.post(Uri.parse(s.url), body: td);
              tasks.add(td.length);

              var result = SpeedTestResult(SpeedTestResultType.Try);
              result.tryCount = testData.indexOf(td);
              result.server = s;
              result.speed = getSpeed(
                tasks,
                stopwatch.elapsedMilliseconds,
              );
              yield result;
            } catch (exc) {
              var result = SpeedTestResult(SpeedTestResultType.Try);
              result.server = s;
              result.withException = true;
              result.exception = e as Exception;
              yield result;
            } finally {}
          }
          stopwatch.stop();
          var result = SpeedTestResult(SpeedTestResultType.ServerDone);
          result.server = s;
          result.speed = getSpeed(
            tasks,
            stopwatch.elapsedMilliseconds,
          );
          yield result;
        } catch (ex) {
          var result = SpeedTestResult(SpeedTestResultType.ServerDone);
          result.server = s;
          result.withException = true;
          result.exception = e as Exception;
          yield result;
        }
      }
    } catch (e) {
      var result = SpeedTestResult(SpeedTestResultType.TestDone);
      result.withException = true;
      result.exception = e as Exception;
      yield result;
    }

    var result = SpeedTestResult(SpeedTestResultType.TestDone);
    result.withException = false;
    yield result;
  }

  /// Generate list of [String] urls for upload.
  List<String> generateUploadData(int retryCount) {
    final random = Random();
    final result = <String>[];

    for (var sizeCounter = 1; sizeCounter < maxUploadSize + 1; sizeCounter++) {
      final size = sizeCounter * 200 * 1024;
      final builder = StringBuffer()..write('content ${sizeCounter.toString()}=');

      for (var i = 0; i < size; ++i) {
        builder.write(chars[random.nextInt(chars.length)]);
      }

      for (var i = 0; i < retryCount; i++) {
        result.add(builder.toString());
      }
    }

    return result;
  }
}
