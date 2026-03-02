import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class ChartCaptureWidget extends StatelessWidget {
  final ScreenshotController controller;
  final Map<String, int> userLocationMap;
  final int userCount;
  final int companyCount;

  const ChartCaptureWidget({
    required this.controller,
    required this.userLocationMap,
    required this.userCount,
    required this.companyCount,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: controller,
      child: Container(
        // Your chart widgets here
      ),
    );
  }
}