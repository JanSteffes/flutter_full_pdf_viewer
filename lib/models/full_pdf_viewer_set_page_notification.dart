import 'package:flutter/material.dart';

class FullPdfViewerSetPageNotification extends Notification {
  final int page;
  final int change;

  FullPdfViewerSetPageNotification({this.page, this.change});
}
