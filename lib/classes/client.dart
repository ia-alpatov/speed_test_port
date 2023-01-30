import 'package:xml_parser/xml_parser.dart';

import 'coordinate.dart';

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

  Client(this.Ip, this.Latitude, this.Longitude, this.Isp, this.IspRating, this.Rating, this.IspAvarageDownloadSpeed,
      this.IspAvarageUploadSpeed, this.geoCoordinate);

  Client.fromXMLElement(XmlElement element)
      : this.Ip = element.getAttribute('ip')!,
        this.Latitude = double.parse(element.getAttribute('lat')!),
        this.Longitude = double.parse(element.getAttribute('lon')!),
        this.Isp = element.getAttribute('isp')!,
        this.IspRating = double.parse(element.getAttribute('isprating')!),
        this.Rating = double.parse(element.getAttribute('rating')!),
        this.IspAvarageDownloadSpeed = int.parse(element.getAttribute('ispdlavg')!),
        this.IspAvarageUploadSpeed = int.parse(element.getAttribute('ispulavg')!),
        this.geoCoordinate =
            Coordinate(double.parse(element.getAttribute('lat')!), double.parse(element.getAttribute('lon')!));
}
