import 'package:xml_parser/xml_parser.dart';

import 'client.dart';
import 'download.dart';
import 'server.dart';
import 'server_config.dart';
import 'times.dart';
import 'upload.dart';

class Settings {
  Client client;

  Times times;

  Download download;

  Upload upload;

  ServerConfig serverConfig;

  List<Server> servers;

  Settings(this.client, this.times, this.download, this.upload, this.serverConfig, this.servers);

  Settings.fromXMLElement(XmlElement element)
      : this.client = Client.fromXMLElement(element.getElement('client')!),
        this.times = Times.fromXMLElement(element.getElement('times')!),
        this.download = Download.fromXMLElement(element.getElement('download')!),
        this.upload = Upload.fromXMLElement(element.getElement('upload')!),
        this.serverConfig = ServerConfig.fromXMLElement(element.getElement('server-config')!),
        this.servers = <Server>[];
}
