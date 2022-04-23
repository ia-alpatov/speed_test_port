<div>
  <h1 align="center">speed_test_port</h1>
  <p align="center" >
    <a title="Pub" href="https://pub.dartlang.org/packages/speed_test_port" >
      <img src="https://img.shields.io/pub/v/speed_test_port.svg?style=popout&include_prereleases" />
    </a>
  </p>
  <p align="center">
  Internet speed tester (ping, upload, download) using speedtest.net
  </p>
</div>

Port of [SpeedTest.Net](https://github.com/hasali19/SpeedTest.Net) to Dart

## Installation

Add the package to your dependencies:

```yaml
dependencies:
  speed_test_port: ^1.0.3
```

OR:

```yaml
dependencies:
  fluent_ui:
    git: https://github.com/oiuldashov/speed_test_port.git
```


Finally, run `dart pub get` to download the package.

Projects using this library should use the stable channel of Flutter



## Example of usage
```dart
    SpeedTest tester = SpeedTest();

    //Getting closest servers
    var settings = await tester.GetSettings();
    
    var servers = settings.servers;
    
    //Test latency for each server
    for (var server in servers) {
      server.Latency = await tester.TestServerLatency(server, 3);
    }
    
    //Getting best server
    servers.sort((a, b) => a.Latency.compareTo(b.Latency));
    var bestServer = servers.first;
    
    //Test download speed in MB/s
    var downloadSpeed = await tester.TestDownloadSpeed(
        bestServer,
        settings.download.ThreadsPerUrl == 0
            ? 2
            : settings.download.ThreadsPerUrl,
        3);
        
    //Test upload speed in MB/s
    var uploadSpeed = await tester.TestUploadSpeed(
        bestServer,
        settings.upload.ThreadsPerUrl == 0 ? 2 : settings.upload.ThreadsPerUrl,
        3);

```
