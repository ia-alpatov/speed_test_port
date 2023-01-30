import 'package:xml_parser/xml_parser.dart';

class Download {
  int TestLength;

  String InitialTest;

  String MinTestSize;

  int ThreadsPerUrl;

  Download(this.TestLength, this.InitialTest, this.MinTestSize, this.ThreadsPerUrl);

  Download.fromXMLElement(XmlElement element)
      : this.TestLength = int.parse(element.getAttribute('testlength')!),
        this.InitialTest = element.getAttribute('initialtest')!,
        this.MinTestSize = element.getAttribute('mintestsize')!,
        this.ThreadsPerUrl = int.parse(element.getAttribute('threadsperurl')!);
}
