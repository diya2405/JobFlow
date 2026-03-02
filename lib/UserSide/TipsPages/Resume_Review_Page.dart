import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class ResumePreviewPage extends StatefulWidget {
  final String name, email, objective, education, skills, interests, projects;
  final File? profileImage;

  ResumePreviewPage({
    required this.name,
    required this.email,
    required this.objective,
    required this.education,
    required this.skills,
    required this.interests,
    required this.projects,
    this.profileImage,
  });

  @override
  _ResumePreviewPageState createState() => _ResumePreviewPageState();
}

class _ResumePreviewPageState extends State<ResumePreviewPage> {
  late pw.Document pdf;
  String? savedFilePath;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    generatePDF();
  }

  /// ✅ Pick Image for Resume
  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
      generatePDF();
    }
  }

  /// ✅ Validate Input (Ensures proper formatting)
  String validateText(String text) {
    return text.isEmpty ? "Not Provided" : text.trim();
  }

  /// ✅ Generate Resume as PDF
  Future<void> generatePDF() async {
    pdf = pw.Document();

    final profileImage = selectedImage != null
        ? pw.MemoryImage(selectedImage!.readAsBytesSync())
        : null;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (profileImage != null)
                pw.Center(
                  child: pw.Container(
                    width: 100,
                    height: 100,
                    decoration: pw.BoxDecoration(
                      shape: pw.BoxShape.circle,
                      image: pw.DecorationImage(
                        image: profileImage,
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Center(
                child: pw.Text(" Resume",
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text(" Name: ${validateText(widget.name)}",
                  style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Text(" Email: ${validateText(widget.email)}",
                  style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 10),
              pw.Text(" Objective",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(validateText(widget.objective), style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Text(" Education",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(validateText(widget.education), style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Text(" Skills",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(validateText(widget.skills), style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Text(" Interests",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(validateText(widget.interests), style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 10),
              pw.Text(" Projects",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text(validateText(widget.projects), style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Text(" Thank You!",
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );
    setState(() {});
  }

  /// ✅ Save PDF to Storage
  Future<void> downloadResume() async {
    if (await Permission.storage.request().isGranted) {
      final directory = Directory("Download/Resumes/");
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      final filePath = "${directory.path}Resume_${widget.name}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());
      setState(() {
        savedFilePath = filePath;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ Resume saved at: $filePath")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Permission Denied")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Resume Preview"),
        backgroundColor: Colors.blue.shade400,
        actions: [
          IconButton(
            icon: Icon(Icons.image),
            onPressed: pickImage,
            tooltip: "Pick Profile Image",
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfPreview(
              build: (format) => pdf.save(),
              allowPrinting: true,
              allowSharing: true,
            ),
          ),
        ],
      ),
    );
  }
}
