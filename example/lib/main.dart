import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_full_pdf_viewer/full_pdf_viewer_scaffold.dart';
import 'package:flutter_full_pdf_viewer/models/full_pdf_viewer_context_notification.dart';
import 'package:flutter_full_pdf_viewer/models/full_pdf_viewer_page_change_notification.dart';
import 'package:flutter_full_pdf_viewer/models/full_pdf_viewer_set_page_notification.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    title: 'Plugin example app',
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String pdfPath;

  Future<File> createFileOfPdfUrl() async {
    final url = "http://africau.edu/images/default/sample.pdf";
    final filename = url.substring(url.lastIndexOf("/") + 1);
    var request = await HttpClient().getUrl(Uri.parse(url));
    var response = await request.close();
    var bytes = await consolidateHttpClientResponseBytes(response);
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = new File('$dir/$filename');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<File> multipagePdf() async {
    Directory tempDir = await getTemporaryDirectory();
    String tempPath = tempDir.path;
    File tempFile = File('$tempPath/sample.pdf');
    ByteData bd = await rootBundle.load('assets/multipagePdf.pdf');
    await tempFile.writeAsBytes(bd.buffer.asUint8List(), flush: true);
    return tempFile;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plugin example app')),
      body: Container(
        width: double.infinity,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                  child: Text("Open PDF"),
                  onPressed: () async {
                    var pathPdf = pdfPath ??
                        await createFileOfPdfUrl().then((f) => f.path);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PDFScreen(pathPdf)),
                    );
                  }),
              RaisedButton(
                  child: Text("Open PDF with layoutparameters"),
                  onPressed: () async {
                    var pathPdf = pdfPath ??
                        await createFileOfPdfUrl().then((f) => f.path);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PDFScreenBottomWidget(pathPdf)),
                    );
                  }),
              RaisedButton(
                  child: Text("Open PDF with pageCount"),
                  onPressed: () async {
                    var pathPdf =
                        pdfPath ?? await multipagePdf().then((f) => f.path);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PDFScreenPageCount(pathPdf)),
                    );
                  }),
              RaisedButton(
                  child: Text("Open PDF with pagechange buttons"),
                  onPressed: () async {
                    var pathPdf =
                        pdfPath ?? await multipagePdf().then((f) => f.path);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PDFScreenSetPage(pathPdf)),
                    );
                  }),
            ]),
      ),
    );
  }
}

class PDFScreen extends StatelessWidget {
  final String pathPDF;

  PDFScreen(this.pathPDF);

  @override
  Widget build(BuildContext context) {
    return PDFViewerScaffold(
        appBar: AppBar(
          title: Text("Document"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {},
            ),
          ],
        ),
        path: pathPDF);
  }
}

class PDFScreenBottomWidget extends StatelessWidget {
  final String pathPDF;

  PDFScreenBottomWidget(this.pathPDF);

  @override
  Widget build(BuildContext context) {
    return PDFViewerScaffold(
        appBar: AppBar(
          title: Text("Document"),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.share),
              onPressed: () {},
            ),
          ],
        ),
        path: pathPDF,
        backgroundColor: Colors.red,
        left: 10,
        right: 10,
        bottomWidget: PreferredSize(
            child: Container(
              color: Colors.orange,
            ),
            preferredSize: Size(double.infinity, 50)));
  }
}

class PDFScreenSetPage extends StatefulWidget {
  final String pathPDF;

  PDFScreenSetPage(this.pathPDF);

  @override
  State<StatefulWidget> createState() => _PDFScreenSetPageState();
}

class _PDFScreenSetPageState extends State<PDFScreenSetPage> {
  BuildContext pdfViewerBuildContext;

  bool onContextRecviedNotification(
      FullPdfViewerContextNotification notification) {
    pdfViewerBuildContext = notification.context;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<FullPdfViewerContextNotification>(
        onNotification: (FullPdfViewerContextNotification notification) {
          pdfViewerBuildContext = notification.context;
          return true;
        },
        child: PDFViewerScaffold(
            appBar: AppBar(
              title: Text("Document"),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {},
                ),
              ],
            ),
            path: widget.pathPDF,
            bottomWidget: PreferredSize(
                child: Container(
                    color: Colors.orange,
                    child: Row(children: <Widget>[
                      Expanded(
                        child: RaisedButton.icon(
                            splashColor: Colors.green,
                            icon: Icon(Icons.chevron_left),
                            onPressed: () {
                              FullPdfViewerSetPageNotification(change: -1)
                                ..dispatch(pdfViewerBuildContext);
                            },
                            label: Text("previous")),
                      ),
                      Expanded(
                        child: TextField(
                            keyboardType: TextInputType.numberWithOptions(
                                decimal: false, signed: false),
                            textInputAction: TextInputAction.go,
                            onSubmitted: (data) =>
                                FullPdfViewerSetPageNotification(
                                    page: int.tryParse(data))
                                  ..dispatch(pdfViewerBuildContext)),
                      ),
                      Expanded(
                        child: RaisedButton.icon(
                          splashColor: Colors.green,
                          icon: Icon(Icons.chevron_right),
                          onPressed: () {
                            FullPdfViewerSetPageNotification(change: 1)
                              ..dispatch(pdfViewerBuildContext);
                          },
                          label: Text("next"),
                        ),
                      ),
                    ])),
                preferredSize: Size(MediaQuery.of(context).size.width, 50))));
  }
}

class PDFScreenPageCount extends StatefulWidget {
  final String pathPDF;

  PDFScreenPageCount(this.pathPDF);

  @override
  State<StatefulWidget> createState() => _PDFScreenPageCountState();
}

class _PDFScreenPageCountState extends State<PDFScreenPageCount> {
  int page;
  int pageCount;

  @override
  void initState() {
    page = 0;
    pageCount = 0;
    super.initState();
  }

  bool onPageChange(FullPdfViewerPageChangeNotification notification) {
    setState(() {
      page = notification.page + 1;
      pageCount = notification.pageCount;
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<FullPdfViewerPageChangeNotification>(
        onNotification: (FullPdfViewerPageChangeNotification notification) {
          setState(() {
            page = notification.page + 1;
            pageCount = notification.pageCount;
          });
          return true;
        },
        child: PDFViewerScaffold(
            appBar: AppBar(
              title: Text("Document $page / $pageCount"),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.share),
                  onPressed: () {},
                ),
              ],
            ),
            path: widget.pathPDF));
  }
}
