import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

import 'chart_capture.dart';

class PdfService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final ScreenshotController _screenshotController = ScreenshotController();

  Future<void> generatePdf(String option, BuildContext context) async {
    try {
      final pdf = pw.Document();
      final currentDate = _dateFormat.format(DateTime.now());

      // Add cover page first
      _addCoverPage(pdf, option, currentDate);

      // Generate content based on selected option
      if (option == 'Users' || option == 'Both') {
        await _addUsersToPdf(pdf);
      }

      if (option == 'Companies' || option == 'Both') {
        await _addCompaniesToPdf(pdf);
      }

      // Add charts at the end
      await _addChartsToPdf(pdf, context);

      // Save and share the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'jobflow_${option.toLowerCase()}_report_$currentDate.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
      );
      rethrow;
    }
  }

  void _addCoverPage(pw.Document pdf, String option, String currentDate) {
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'JobFlow Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  option == 'Both' ? 'Companies and Users' : '$option Report',
                  style: pw.TextStyle(fontSize: 18),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated on: $currentDate',
                  style: pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addUsersToPdf(pw.Document pdf) async {
    final users = await _firestore.collection('User_Data').get();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 1,
                child: pw.Text('Users Report'),
              ),
              pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(fontSize: 10),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                data: [
                  ['Name', 'Email', 'Phone', 'Location'],
                  ...users.docs.map((doc) {
                    final data = doc.data();
                    return [
                      data['Name'] ?? 'N/A',
                      data['Email'] ?? 'N/A',
                      data['Phone']?.toString() ?? 'N/A',
                      data['Location'] ?? 'N/A',
                    ];
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addCompaniesToPdf(pw.Document pdf) async {
    final companies = await _firestore.collection('Company_Data').get();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 1,
                child: pw.Text('Companies Report'),
              ),
              pw.Table.fromTextArray(
                context: context,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                cellStyle: pw.TextStyle(fontSize: 10),
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
                data: [
                  ['Company Name', 'Email', 'Contact', 'Location'],
                  ...companies.docs.map((doc) {
                    final data = doc.data();
                    return [
                      data['CompanyName'] ?? 'N/A',
                      data['Email'] ?? 'N/A',
                      data['Contact']?.toString() ?? 'N/A',
                      data['Location'] ?? 'N/A',
                    ];
                  }).toList(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addChartsToPdf(pw.Document pdf, BuildContext context) async {
    final userSnapshot = await _firestore.collection('User_Data').get();
    final companySnapshot = await _firestore.collection('Company_Data').get();

    // Map user locations
    final Map<String, int> locationCount = {};
    for (var doc in userSnapshot.docs) {
      final loc = doc['Location'] ?? 'Unknown';
      locationCount[loc] = (locationCount[loc] ?? 0) + 1;
    }

    final chartImageBytes = await _generateChartImage(
      context: context,
      userCount: userSnapshot.docs.length,
      companyCount: companySnapshot.docs.length,
      userLocationMap: locationCount,
    );

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Image(
              pw.MemoryImage(chartImageBytes),
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );
  }

  Future<Uint8List> _generateChartImage({
    required BuildContext context,
    required int userCount,
    required int companyCount,
    required Map<String, int> userLocationMap,
  }) async {
    final chartWidget = ChartCaptureWidget(
      controller: _screenshotController,
      userLocationMap: userLocationMap,
      userCount: userCount,
      companyCount: companyCount,
    );

    return await _screenshotController.captureFromWidget(
      MediaQuery(
        data: MediaQueryData(size: Size(1080, 1920)),
        child: MaterialApp(
          home: Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: chartWidget),
          ),
        ),
      ),
      delay: Duration(milliseconds: 500),
      pixelRatio: 2.0,
    );
  }
}