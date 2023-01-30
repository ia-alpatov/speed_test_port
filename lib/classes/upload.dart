import 'package:xml_parser/xml_parser.dart';

class Upload {
  int TestLength;

  int Ratio;

  int InitialTest;

  String MinTestSize;

  int Threads;

  String MaxChunkSize;
  String MaxChunkCount;
  int ThreadsPerUrl;

  Upload(this.TestLength, this.Ratio, this.InitialTest, this.MinTestSize, this.Threads, this.MaxChunkSize,
      this.MaxChunkCount, this.ThreadsPerUrl);

  Upload.fromXMLElement(XmlElement element)
      : this.TestLength = int.parse(element.getAttribute('testlength')!),
        this.Ratio = int.parse(element.getAttribute('ratio')!),
        this.InitialTest = int.parse(element.getAttribute('initialtest')!),
        this.MinTestSize = element.getAttribute('mintestsize')!,
        this.Threads = int.parse(element.getAttribute('threads')!),
        this.MaxChunkSize = element.getAttribute('maxchunksize')!,
        this.MaxChunkCount = element.getAttribute('maxchunkcount')!,
        this.ThreadsPerUrl = int.parse(element.getAttribute('threadsperurl')!);
}
