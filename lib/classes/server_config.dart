import 'package:xml_parser/xml_parser.dart';

class ServerConfig {
  String ignoreIds;

  ServerConfig(this.ignoreIds);

  ServerConfig.fromXMLElement(XmlElement element) : this.ignoreIds = element.getAttribute('ignoreids')!;
}
