import 'package:xml_parser/xml_parser.dart';

class Times {
  int Download1;

  int Download2;

  int Download3;
  int Upload1;

  int Upload2;

  int Upload3;

  Times(this.Download1, this.Download2, this.Download3, this.Upload1, this.Upload2, this.Upload3);

  Times.fromXMLElement(XmlElement element)
      : this.Download1 = int.parse(element.getAttribute('dl1')!),
        this.Download2 = int.parse(element.getAttribute('dl2')!),
        this.Download3 = int.parse(element.getAttribute('dl3')!),
        this.Upload1 = int.parse(element.getAttribute('ul1')!),
        this.Upload2 = int.parse(element.getAttribute('ul2')!),
        this.Upload3 = int.parse(element.getAttribute('ul3')!);
}
