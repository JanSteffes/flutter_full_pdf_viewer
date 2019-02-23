import 'package:flutter/widgets.dart';

class FullPdfViewerPageChangeNotification extends Notification 
{
  final int page;
  final int pageCount;

  FullPdfViewerPageChangeNotification({this.page, this.pageCount});
}