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
  speed_test_port: ^1.0.4
```

OR:

```yaml
dependencies:
  fluent_ui:
    git: https://github.com/oiuldashov/speed_test_port.git
```


Finally, run `dart pub get` to download the package.

Projects using this library should use the stable channel of Flutter



## Example of usage for Future version
```dart
    // Create a tester instance
    SpeedTestPort tester = SpeedTestPort();

    // And a variable to store the best servers
    List<Server> bestServersList = [];

    // Example function to set the best servers, could be called
    // in an initState()
    Future<void> setBestServers() async {
      final settings = await tester.getSettings();
      final servers = settings.servers;

      final _bestServersList = await tester.getBestServers(
        servers: servers,
      );

      setState(() {
        bestServersList = _bestServersList;
      });
    }

    //Test download speed in MB/s
    final downloadRate =
        await tester.testDownloadSpeed(servers: bestServersList);

    //Test upload speed in MB/s
    final uploadRate = await tester.testUploadSpeed(servers: bestServersList);
```

## Example of usage for Stream version
### Example version in "example" folder
![](https://github.com/oiuldashov/speed_test_port/readme_media/example.gif)
