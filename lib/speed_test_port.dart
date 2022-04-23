library speed_test_port;

import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:math';
import 'package:xml_parser/xml_parser.dart';
import 'package:sync/sync.dart';

/// A Speed tester.
class SpeedTest {
  String ConfigUrl = "https://www.speedtest.net/speedtest-config.php";

  final List<String> ServersUrls = [
    "https://www.speedtest.net/speedtest-servers-static.php",
    "https://c.speedtest.net/speedtest-servers-static.php",
    "https://www.speedtest.net/speedtest-servers.php",
    "https://c.speedtest.net/speedtest-servers.php"
  ];

  List<int> DownloadSizes = [350, 750, 1500, 3000];
  String Chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
  int MaxUploadSize = 4; // 400 KB

  /// Returns [Settings] from speedtest.net.
  Future<Settings> GetSettings() async {
    var response = await http.get(Uri.parse(ConfigUrl));
    Settings settings = Settings.fromXMLElement(
        XmlDocument.from(response.body)?.getElement('settings'));

    var serversConfig = ServersList(<Server>[]);
    for (var element in ServersUrls) {
      if (serversConfig.Servers.length > 0) break;
      try {
        var resp = await http.get(Uri.parse(element));

        serversConfig = ServersList.fromXMLElement(
            XmlDocument.from(resp.body)?.getElement('settings'));
      } catch (ex) {
        serversConfig = ServersList(<Server>[]);
      }
    }

    var ignoredIds = settings.serverConfig.IgnoreIds.split(",");
    serversConfig.CalculateDistances(settings.client.geoCoordinate);
    settings.servers = serversConfig.Servers.where(
        (s) => !ignoredIds.contains(s.Id.toString())).toList();
    settings.servers.sort((a, b) => a.Distance.compareTo(b.Distance));

    return settings;
  }

  /// Returns [double] ping value for [Server].
  Future<double> TestServerLatency(Server server, int retryCount) async {
    var latencyUri = CreateTestUrl(server, "latency.txt");

    final stopwatch = Stopwatch();
    for (var i = 0; i < retryCount; i++) {
      String testString;
      try {
        stopwatch.start();
        testString = (await http.get(latencyUri)).body;
      } catch (ex) {
        continue;
      } finally {
        stopwatch.stop();
      }

      if (!testString.startsWith("test=test")) {
        throw new Exception(
            "Server returned incorrect test string for latency.txt");
      }
    }

    return stopwatch.elapsedMilliseconds / retryCount;
  }

  /// Creates [Uri] from [Server] and [String] file
  Uri CreateTestUrl(Server server, String file) {
    return Uri.parse(
        Uri.parse(server.Url).toString().replaceAll('upload.php', file));
  }

  /// Returns urls for download test.
  List<String> GenerateDownloadUrls(Server server, int retryCount) {
    var downloadUriBase = CreateTestUrl(server, "random{0}x{0}.jpg?r={1}");
    List<String> result = <String>[];
    DownloadSizes.forEach((downloadSize) {
      for (var i = 0; i < retryCount; i++) {
        result.add(downloadUriBase
            .toString()
            .replaceAll('%7B0%7D', downloadSize.toString())
            .replaceAll('%7B1%7D', i.toString()));
      }
    });

    return result;
  }

  /// Returns [double] downloaded speed in MB/s.
  Future<double> TestDownloadSpeed(
      Server server, int simultaneousDownloads, int retryCount) async {
    var testData = GenerateDownloadUrls(server, retryCount);

    final semaphore = Semaphore(simultaneousDownloads);

    List<Future<int>> tasks = <Future<int>>[];
    final stopwatch = Stopwatch();
    stopwatch.start();

    testData.forEach((element) {
      tasks.add(Future<int>(() async {
        semaphore.acquire();
        try {
          var data = await http.get(Uri.parse(element));
          return data.bodyBytes.length;
        } finally {
          semaphore.release();
        }
      }));
    });

    var results = await Future.wait(tasks);

    stopwatch.stop();
    int totalSize = results.reduce((a, b) => a + b);
    return (totalSize * 8 / 1024) /
        (stopwatch.elapsedMilliseconds / 1000) /
        1000;
  }

  /// Returns [double] upload speed in MB/s.
  Future<double> TestUploadSpeed(
      Server server, int simultaneousDownloads, int retryCount) async {
    var testData = GenerateUploadData(retryCount);

    final semaphore = Semaphore(simultaneousDownloads);

    List<Future<int>> tasks = <Future<int>>[];
    final stopwatch = Stopwatch();
    stopwatch.start();

    testData.forEach((element) {
      tasks.add(Future<int>(() async {
        semaphore.acquire();
        try {
          var data = await http.post(Uri.parse(server.Url), body: element);
          return element.length;
        } finally {
          semaphore.release();
        }
      }));
    });

    var results = await Future.wait(tasks);

    stopwatch.stop();
    int totalSize = results.reduce((a, b) => a + b);
    return (totalSize * 8 / 1024) /
        (stopwatch.elapsedMilliseconds / 1000) /
        1000;
  }

  /// Generate list of [String] urls for upload.
  List<String> GenerateUploadData(int retryCount) {
    var random = new Random();
    var result = <String>[];

    for (var sizeCounter = 1; sizeCounter < MaxUploadSize + 1; sizeCounter++) {
      var size = sizeCounter * 200 * 1024;
      var builder = new StringBuffer();

      builder.write("content" + sizeCounter.toString() + "=");

      for (var i = 0; i < size; ++i)
        builder.write(Chars[random.nextInt(Chars.length)]);

      for (var i = 0; i < retryCount; i++) {
        result.add(builder.toString());
      }
    }

    return result;
  }
}

class Settings {
  Client client;

  Times times;

  Download download;

  Upload upload;

  ServerConfig serverConfig;

  List<Server> servers;

  Settings(this.client, this.times, this.download, this.upload,
      this.serverConfig, this.servers);

  Settings.fromXMLElement(XmlElement? element)
      : this.client = Client.fromXMLElement(element?.getElement('client')),
        this.times = Times.fromXMLElement(element?.getElement('times')),
        this.download =
            Download.fromXMLElement(element?.getElement('download')),
        this.upload = Upload.fromXMLElement(element?.getElement('upload')),
        this.serverConfig =
            ServerConfig.fromXMLElement(element?.getElement('server-config')),
        this.servers = <Server>[];
}

class Client {
  String Ip;
  double Latitude;
  double Longitude;
  String Isp;
  double IspRating;
  double Rating;
  int IspAvarageDownloadSpeed;
  int IspAvarageUploadSpeed;
  Coordinate geoCoordinate;

  Client(
      this.Ip,
      this.Latitude,
      this.Longitude,
      this.Isp,
      this.IspRating,
      this.Rating,
      this.IspAvarageDownloadSpeed,
      this.IspAvarageUploadSpeed,
      this.geoCoordinate);

  Client.fromXMLElement(XmlElement? element)
      : this.Ip = element!.getAttribute('ip')!,
        this.Latitude = double.parse(element!.getAttribute('lat')!),
        this.Longitude = double.parse(element!.getAttribute('lon')!),
        this.Isp = element!.getAttribute('isp')!,
        this.IspRating = double.parse(element!.getAttribute('isprating')!),
        this.Rating = double.parse(element!.getAttribute('rating')!),
        this.IspAvarageDownloadSpeed =
            int.parse(element!.getAttribute('ispdlavg')!),
        this.IspAvarageUploadSpeed =
            int.parse(element!.getAttribute('ispulavg')!),
        this.geoCoordinate = Coordinate(
            double.parse(element!.getAttribute('lat')!),
            double.parse(element!.getAttribute('lon')!));
}

class Coordinate {
  double Latitude;
  double Longitude;

  Coordinate(this.Latitude, this.Longitude);

  double GetDistanceTo(Coordinate other) {
    var d1 = Latitude * (pi / 180.0);
    var num1 = Longitude * (pi / 180.0);
    var d2 = other.Latitude * (pi / 180.0);
    var num2 = other.Longitude * (pi / 180.0) - num1;
    var d3 = pow(sin((d2 - d1) / 2.0), 2.0) +
        cos(d1) * cos(d2) * pow(sin(num2 / 2.0), 2.0);

    return 6376500.0 * (2.0 * atan2(sqrt(d3), sqrt(1.0 - d3)));
  }
}

class Times {
  int Download1;

  int Download2;

  int Download3;
  int Upload1;

  int Upload2;

  int Upload3;

  Times(this.Download1, this.Download2, this.Download3, this.Upload1,
      this.Upload2, this.Upload3);

  Times.fromXMLElement(XmlElement? element)
      : this.Download1 = int.parse(element!.getAttribute('dl1')!),
        this.Download2 = int.parse(element!.getAttribute('dl2')!),
        this.Download3 = int.parse(element!.getAttribute('dl3')!),
        this.Upload1 = int.parse(element!.getAttribute('ul1')!),
        this.Upload2 = int.parse(element!.getAttribute('ul2')!),
        this.Upload3 = int.parse(element!.getAttribute('ul3')!);
}

class Download {
  int TestLength;

  String InitialTest;

  String MinTestSize;

  int ThreadsPerUrl;

  Download(
      this.TestLength, this.InitialTest, this.MinTestSize, this.ThreadsPerUrl);

  Download.fromXMLElement(XmlElement? element)
      : this.TestLength = int.parse(element!.getAttribute('testlength')!),
        this.InitialTest = element!.getAttribute('initialtest')!,
        this.MinTestSize = element!.getAttribute('mintestsize')!,
        this.ThreadsPerUrl = int.parse(element!.getAttribute('threadsperurl')!);
}

class Upload {
  int TestLength;

  int Ratio;

  int InitialTest;

  String MinTestSize;

  int Threads;

  String MaxChunkSize;
  String MaxChunkCount;
  int ThreadsPerUrl;

  Upload(this.TestLength, this.Ratio, this.InitialTest, this.MinTestSize,
      this.Threads, this.MaxChunkSize, this.MaxChunkCount, this.ThreadsPerUrl);

  Upload.fromXMLElement(XmlElement? element)
      : this.TestLength = int.parse(element!.getAttribute('testlength')!),
        this.Ratio = int.parse(element!.getAttribute('ratio')!),
        this.InitialTest = int.parse(element!.getAttribute('initialtest')!),
        this.MinTestSize = element!.getAttribute('mintestsize')!,
        this.Threads = int.parse(element!.getAttribute('threads')!),
        this.MaxChunkSize = element!.getAttribute('maxchunksize')!,
        this.MaxChunkCount = element!.getAttribute('maxchunkcount')!,
        this.ThreadsPerUrl = int.parse(element!.getAttribute('threadsperurl')!);
}

class ServerConfig {
  String IgnoreIds;

  ServerConfig(this.IgnoreIds);

  ServerConfig.fromXMLElement(XmlElement? element)
      : this.IgnoreIds = element!.getAttribute('ignoreids')!;
}

class Server {
  int Id;

  String Name;

  String Country;

  String Sponsor;

  String Host;

  String Url;

  double Latitude;
  double Longitude;

  double Distance;

  double Latency;

  Coordinate geoCoordinate;

  Server(
      this.Id,
      this.Name,
      this.Country,
      this.Sponsor,
      this.Host,
      this.Url,
      this.Latitude,
      this.Longitude,
      this.Distance,
      this.Latency,
      this.geoCoordinate);

  Server.fromXMLElement(XmlElement? element)
      : this.Id = int.parse(element!.getAttribute('id')!),
        this.Name = element!.getAttribute('name')!,
        this.Country = element!.getAttribute('country')!,
        this.Sponsor = element!.getAttribute('sponsor')!,
        this.Host = element!.getAttribute('host')!,
        this.Url = element!.getAttribute('url')!,
        this.Latitude = double.parse(element!.getAttribute('lat')!),
        this.Longitude = double.parse(element!.getAttribute('lon')!),
        this.Distance = 99999999999,
        this.Latency = 99999999999,
        this.geoCoordinate = Coordinate(
            double.parse(element!.getAttribute('lat')!),
            double.parse(element!.getAttribute('lon')!));
}

class ServersList {
  Iterable<Server> Servers;

  ServersList(this.Servers);

  ServersList.fromXMLElement(XmlElement? element)
      : this.Servers = element!.getElement('servers')!.children!.map((element) {
          var server = Server.fromXMLElement(element as XmlElement);
          return server;
        });

  void CalculateDistances(Coordinate clientCoordinate) {
    Servers.forEach((element) {
      element.Distance = clientCoordinate.GetDistanceTo(element.geoCoordinate);
    });
  }
}
