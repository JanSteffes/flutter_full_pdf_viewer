import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_full_pdf_viewer/full_pdf_viewer_plugin.dart';
import 'package:flutter_full_pdf_viewer/models/full_pdf_viewer_context_notification.dart';
import 'package:flutter_full_pdf_viewer/models/full_pdf_viewer_page_change_notification.dart';
import 'package:flutter_full_pdf_viewer/models/full_pdf_viewer_set_page_notification.dart';

class PDFViewerScaffold extends StatefulWidget {
  final PreferredSizeWidget appBar;
  final String path;
  final bool primary;
  final double left;
  final double right;
  final PreferredSizeWidget bottomWidget;
  final Color backgroundColor;

  const PDFViewerScaffold({
    Key key,
    this.appBar,
    @required this.path,
    this.left = 0.0,
    this.right = 0.0,
    this.bottomWidget,
    this.primary = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  _PDFViewScaffoldState createState() => _PDFViewScaffoldState();
}

class _PDFViewScaffoldState extends State<PDFViewerScaffold> {
  final pdfViwerRef = new PDFViewerPlugin();
  Rect _rect;
  Timer _resizeTimer;
  int pageNumber;
  int pageCount;

  Future<dynamic> getPage() {
    return pdfViwerRef.getPage();
  }

  @override
  void initState() {
    super.initState();
    pdfViwerRef.onPageChange.listen((data) =>
        FullPdfViewerPageChangeNotification(
            page: data.page, pageCount: data.pageCount)
          ..dispatch(context));
    pdfViwerRef.close();
  }

  @override
  void dispose() {
    super.dispose();
    pdfViwerRef.close();
    pdfViwerRef.dispose();
  }

  bool onPageSetNotificationReceived(
      FullPdfViewerSetPageNotification notification) {
    if (notification.page != null) {
      pdfViwerRef.setPage(notification.page);
    } else if (notification.change != null && notification.change != 0) {
      var change = notification.change;
      pdfViwerRef
          .getPage()
          .then((current) => pdfViwerRef.getPageCount().then((maxPage) {
                var resultPage = change > 0
                    ? current + change > maxPage ? maxPage : current + change
                    : current + change < 0 ? 0 : current + change;
                return resultPage;
              }).then((resultPage) => pdfViwerRef.setPage(resultPage)));
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (_rect == null) {
      _rect = _buildRect(context);
      pdfViwerRef.launch(
        widget.path,
        rect: _rect,
      );
    } else {
      final rect = _buildRect(context);
      if (_rect != rect) {
        _rect = rect;
        _resizeTimer?.cancel();
        _resizeTimer = new Timer(new Duration(milliseconds: 300), () {
          pdfViwerRef.resize(_rect);
        });
      }
    }
    return NotificationListener<FullPdfViewerSetPageNotification>(
        onNotification: onPageSetNotificationReceived,
        child: Builder(builder: (BuildContext newContext) {
          FullPdfViewerContextNotification(newContext)..dispatch(context);
          return Scaffold(
              appBar: widget.appBar,
              body: widget.bottomWidget == null
                  ? Container()
                  : Container(
                      height: MediaQuery.of(context).size.height -
                          widget.appBar.preferredSize.height -
                          MediaQuery.of(context).viewInsets.bottom,
                      color: widget.backgroundColor,
                      child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                              width: widget.bottomWidget.preferredSize.width,
                              height: widget.bottomWidget.preferredSize.height,
                              child: widget.bottomWidget))));
        }));
  }

  Rect _buildRect(BuildContext context) {
    final fullscreen = widget.appBar == null;

    final mediaQuery = MediaQuery.of(context);
    final topPadding = widget.primary ? mediaQuery.padding.top : 0.0;
    final top =
        fullscreen ? 0.0 : widget.appBar.preferredSize.height + topPadding;
    final bottom = fullscreen
        ? 0.0
        : widget.bottomWidget != null
            ? widget.bottomWidget.preferredSize.height
            : 0.0;
    var height = mediaQuery.size.height - top - bottom;
    if (height < 0.0) {
      height = 0.0;
    }
    var width = mediaQuery.size.width - widget.right - widget.left;

    return new Rect.fromLTWH(widget.left, top, width, height);
  }
}
