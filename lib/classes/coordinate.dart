import 'dart:math';

class Coordinate {
  double latitude;
  double longitude;

  Coordinate(this.latitude, this.longitude);

  double getDistanceTo(Coordinate other) {
    var d1 = latitude * (pi / 180.0);
    var num1 = longitude * (pi / 180.0);
    var d2 = other.latitude * (pi / 180.0);
    var num2 = other.longitude * (pi / 180.0) - num1;
    var d3 = pow(sin((d2 - d1) / 2.0), 2.0) + cos(d1) * cos(d2) * pow(sin(num2 / 2.0), 2.0);

    return 6376500.0 * (2.0 * atan2(sqrt(d3), sqrt(1.0 - d3)));
  }
}
