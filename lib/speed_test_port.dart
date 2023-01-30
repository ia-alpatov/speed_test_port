library speed_test_port;

import 'package:http/http.dart' as http;
import 'package:speed_test_port/classes/classes.dart';
import 'package:speed_test_port/constants.dart';
import 'package:speed_test_port/enums/file_size.dart';
import 'dart:async';
import 'dart:math';

import 'package:sync/sync.dart';
import 'package:xml_parser/xml_parser.dart';

typedef void DoneCallback(double transferRate);
typedef void ProgressCallback(double transferRate);
typedef void ErrorCallback(String errorMessage);

/// A Speed tester. [Future] based
class SpeedTestPort {
  /// Returns [Settings] from speedtest.net.
  Future<Settings> getSettings() async {
    final response = await http.get(Uri.parse(configUrl));
    final doc = XmlDocument.from(response.body);

    if (doc == null) throw Exception("Can't get speed test settings");
    if (!doc.hasElement('settings')) throw Exception("Can't get settings from settings xml");

    final settings = Settings.fromXMLElement(
      doc.getElement('settings')!,
    );

    var serversConfig = ServersList(<Server>[]);
    for (final element in serversUrls) {
      if (serversConfig.servers.isNotEmpty) break;
      try {
        final resp = await http.get(Uri.parse(element));

        final docServersList = XmlDocument.from(resp.body);

        if (docServersList == null) throw Exception("Can't get speed test settings");
        if (!docServersList.hasElement('settings')) throw Exception("Can't get settings from settings xml");

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

    return settings;
  }

  /// Returns a List[Server] with the best servers, ordered
  /// by lowest to highest latency.
  Future<List<Server>> getBestServers({
    required List<Server> servers,
    int retryCount = 2,
    int timeoutInSeconds = 2,
  }) async {
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
        serversToTest.add(server);
      }
    }

    serversToTest.sort((a, b) => a.latency.compareTo(b.latency));

    return serversToTest;
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

  /// Returns [double] downloaded speed in MB/s.
  Future<void> testDownloadSpeed({
    required List<Server> servers,
    int simultaneousDownloads = 2,
    int retryCount = 3,
    List<FileSize> downloadSizes = defaultDownloadSizes,
    required ProgressCallback onProgress,
    required DoneCallback onDone,
    required ErrorCallback onError,
  }) async {
    try {
      double downloadSpeed = 0;

      // Iterates over all servers, if one request fails, the next one is tried.
      for (final s in servers) {
        final testData = generateDownloadUrls(s, retryCount, downloadSizes);
        final semaphore = Semaphore(simultaneousDownloads);
        final tasks = <int>[];
        final stopwatch = Stopwatch()..start();

        try {
          await Future.forEach(testData, (String td) async {
            await semaphore.acquire();
            try {
              final data = await http.get(Uri.parse(td));
              tasks.add(data.bodyBytes.length);
              onProgress(
                getSpeed(
                  tasks,
                  stopwatch.elapsedMilliseconds,
                ),
              );
            } finally {
              semaphore.release();
            }
          });
          stopwatch.stop();
          downloadSpeed = getSpeed(tasks, stopwatch.elapsedMilliseconds);

          break;
        } catch (_) {
          continue;
        }
      }
      onDone(downloadSpeed);
    } catch (e) {
      onError(e.toString());
    }
  }

  /// Returns [double] upload speed in MB/s.
  Future<void> testUploadSpeed({
    required List<Server> servers,
    int simultaneousUploads = 2,
    int retryCount = 3,
    required ProgressCallback onProgress,
    required DoneCallback onDone,
    required ErrorCallback onError,
  }) async {
    try {
      double uploadSpeed = 0;
      for (var s in servers) {
        final testData = generateUploadData(retryCount);
        final semaphore = Semaphore(simultaneousUploads);
        final stopwatch = Stopwatch()..start();
        final tasks = <int>[];

        try {
          await Future.forEach(testData, (String td) async {
            await semaphore.acquire();
            try {
              // do post request to measure time for upload
              await http.post(Uri.parse(s.url), body: td);
              tasks.add(td.length);
              onProgress(
                getSpeed(
                  tasks,
                  stopwatch.elapsedMilliseconds,
                ),
              );
            } finally {
              semaphore.release();
            }
          });
          stopwatch.stop();
          uploadSpeed = getSpeed(tasks, stopwatch.elapsedMilliseconds);

          break;
        } catch (_) {
          continue;
        }
      }
      onDone(uploadSpeed);
    } catch (e) {
      onError(e.toString());
    }
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
