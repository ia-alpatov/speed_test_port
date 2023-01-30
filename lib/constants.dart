import 'package:speed_test_port/enums/file_size.dart';

const configUrl = 'https://www.speedtest.net/speedtest-config.php';

const serversUrls = [
  'https://www.speedtest.net/speedtest-servers-static.php',
  'https://c.speedtest.net/speedtest-servers-static.php',
  'https://www.speedtest.net/speedtest-servers.php',
  'https://c.speedtest.net/speedtest-servers.php'
];

const defaultDownloadSizes = [
  FileSize.SIZE_350,
  FileSize.SIZE_750,
  FileSize.SIZE_1500,
  FileSize.SIZE_3000,
];
const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
const maxUploadSize = 4; // 400 KB