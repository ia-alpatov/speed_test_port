import 'package:xml_parser/xml_parser.dart';

import 'coordinate.dart';

class Server {
  int id;

  String name;

  String country;

  String sponsor;

  String host;

  String url;

  double latitude;
  double longitude;

  double distance;

  double latency;

  Coordinate geoCoordinate;

  Server(this.id, this.name, this.country, this.sponsor, this.host, this.url, this.latitude, this.longitude,
      this.distance, this.latency, this.geoCoordinate);

  Server.fromXMLElement(XmlElement element)
      : this.id = int.parse(element.getAttribute('id')!),
        this.name = element.getAttribute('name')!,
        this.country = element.getAttribute('country')!,
        this.sponsor = element.getAttribute('sponsor')!,
        this.host = element.getAttribute('host')!,
        this.url = element.getAttribute('url')!,
        this.latitude = double.parse(element.getAttribute('lat')!),
        this.longitude = double.parse(element.getAttribute('lon')!),
        this.distance = 99999999999,
        this.latency = 99999999999,
        this.geoCoordinate =
            Coordinate(double.parse(element.getAttribute('lat')!), double.parse(element.getAttribute('lon')!));

  @override
  String toString() {
    return sponsor + " " + name;
  }
}
