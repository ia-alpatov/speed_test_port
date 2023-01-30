import 'package:xml_parser/xml_parser.dart';

import 'coordinate.dart';
import 'server.dart';

class ServersList {
  Iterable<Server> servers;

  ServersList(this.servers);

  ServersList.fromXMLElement(XmlElement element)
      : this.servers = element.getElement('servers')!.children!.map((element) {
          var server = Server.fromXMLElement(element as XmlElement);
          return server;
        });

  void calculateDistances(Coordinate clientCoordinate) {
    servers.forEach((element) {
      element.distance = clientCoordinate.getDistanceTo(element.geoCoordinate);
    });
  }
}
