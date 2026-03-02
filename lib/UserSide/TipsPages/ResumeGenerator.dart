import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';

class ResumeGenerator extends StatefulWidget {
  @override
  _ResumeGeneratorState createState() => _ResumeGeneratorState();
}

class _ResumeGeneratorState extends State<ResumeGenerator> {
  final _formKey = GlobalKey<FormState>();
  final _resumeData = ResumeData();
  File? _profileImage;

  // Sections with auto-expanding text fields
  final Map<String, TextEditingController> _sectionControllers = {
    'Personal Details': TextEditingController(),
    'Professional Summary': TextEditingController(),
    'Work Experience': TextEditingController(),
    'Education': TextEditingController(),
    'Skills': TextEditingController(),
    'Projects': TextEditingController(),
    'Certifications': TextEditingController(),
    'Languages': TextEditingController(),
  };

  @override
  void dispose() {
    _sectionControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  void _generateResume() {
    if (_formKey.currentState!.validate()) {
      // Process and organize data before preview
      _processResumeData();

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResumePreviewPage(
            resumeData: _resumeData,
            profileImage: _profileImage,
          ),
        ),
      );
    }
  }

  void _processResumeData() {
    // Extract and format personal details
    final personalDetails = _sectionControllers['Personal Details']!.text.split('\n');
    _resumeData.name = personalDetails.isNotEmpty ? personalDetails[0] : '';
    _resumeData.email = personalDetails.length > 1 ? personalDetails[1] : '';
    _resumeData.phone = personalDetails.length > 2 ? personalDetails[2] : '';
    _resumeData.linkedIn = personalDetails.length > 3 ? personalDetails[3] : '';
    _resumeData.address = personalDetails.length > 4 ? personalDetails[4] : '';

    // Process other sections with AI-like formatting
    _resumeData.summary = _formatText(_sectionControllers['Professional Summary']!.text);
    _resumeData.experience = _formatExperience(_sectionControllers['Work Experience']!.text);
    _resumeData.education = _formatEducation(_sectionControllers['Education']!.text);
    _resumeData.skills = _formatList(_sectionControllers['Skills']!.text);
    _resumeData.projects = _formatProjects(_sectionControllers['Projects']!.text);
    _resumeData.certifications = _formatList(_sectionControllers['Certifications']!.text);
    _resumeData.languages = _formatList(_sectionControllers['Languages']!.text);
  }

  String _formatText(String text) {
    // Basic text formatting (like an AI would do)
    return text.trim().isEmpty ? 'Not specified' : text.trim();
  }

  List<String> _formatList(String text) {
    // Convert bullet points or commas to formatted list
    return text.split(RegExp(r'[\n•,;]'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  List<Experience> _formatExperience(String text) {
    // Parse experience entries with AI-like pattern recognition
    return text.split('\n\n').map((entry) {
      final lines = entry.split('\n');
      if (lines.length >= 3) {
        return Experience(
          position: lines[0],
          company: lines.length > 1 ? lines[1] : '',
          duration: lines.length > 2 ? lines[2] : '',
          description: lines.length > 3 ? lines.sublist(3).join('\n') : '',
        );
      }
      return Experience(position: entry, company: '', duration: '', description: '');
    }).toList();
  }

  List<Education> _formatEducation(String text) {
    // Parse education entries
    return text.split('\n\n').map((entry) {
      final lines = entry.split('\n');
      if (lines.length >= 2) {
        return Education(
          degree: lines[0],
          institution: lines[1],
          year: lines.length > 2 ? lines[2] : '',
        );
      }
      return Education(degree: entry, institution: '', year: '');
    }).toList();
  }

  List<Project> _formatProjects(String text) {
    // Parse project entries
    return text.split('\n\n').map((entry) {
      final lines = entry.split('\n');
      if (lines.length >= 2) {
        return Project(
          name: lines[0],
          description: lines.sublist(1).join('\n'),
        );
      }
      return Project(name: entry, description: '');
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text("AI Resume Generator", style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue.shade400,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
              children: [
              _buildSectionHeader("Personal Details", "Enter your name, email, phone, LinkedIn, address (one per line)"),
          _buildExpandingTextField(_sectionControllers['Personal Details']!, minLines: 5),

          _buildSectionHeader("Professional Summary", "Briefly describe your professional background"),
          _buildExpandingTextField(_sectionControllers['Professional Summary']!, minLines: 3),

          _buildSectionHeader("Work Experience", "For each position:\nJob Title\nCompany\nDuration\nDescription"),
          _buildExpandingTextField(_sectionControllers['Work Experience']!, minLines: 5),

          _buildSectionHeader("Education", "For each degree:\nDegree Name\nInstitution\nYear"),
          _buildExpandingTextField(_sectionControllers['Education']!, minLines: 3),

          _buildSectionHeader("Skills", "List skills separated by commas or new lines"),
          _buildExpandingTextField(_sectionControllers['Skills']!),

          _buildSectionHeader("Projects", "For each project:\nProject Name\nDescription"),
          _buildExpandingTextField(_sectionControllers['Projects']!, minLines: 3),

          _buildSectionHeader("Certifications", "List certifications separated by commas or new lines"),
          _buildExpandingTextField(_sectionControllers['Certifications']!),

          _buildSectionHeader("Languages", "List languages separated by commas or new lines"),
          _buildExpandingTextField(_sectionControllers['Languages']!),

          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _generateResume,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
              child: Text("Generate Professional Resume", style: GoogleFonts.poppins(color: Colors.white)),
            ),
              ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(hint, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
        SizedBox(height: 8),
      ],
    );
  }

  Widget _buildExpandingTextField(TextEditingController controller, {int minLines = 1}) {
    return TextFormField(
      controller: controller,
      minLines: minLines,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      decoration: InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.all(12),
      ),
      validator: (value) => value!.isEmpty ? "This section is required" : null,
    );
  }
}

// Data model classes
class ResumeData {
  String name = '';
  String email = '';
  String phone = '';
  String linkedIn = '';
  String address = '';
  String summary = '';
  List<Experience> experience = [];
  List<Education> education = [];
  List<String> skills = [];
  List<Project> projects = [];
  List<String> certifications = [];
  List<String> languages = [];
}

class Experience {
  final String position;
  final String company;
  final String duration;
  final String description;

  Experience({
    required this.position,
    required this.company,
    required this.duration,
    required this.description,
  });
}

class Education {
  final String degree;
  final String institution;
  final String year;

  Education({
    required this.degree,
    required this.institution,
    required this.year,
  });
}

class Project {
  final String name;
  final String description;

  Project({
    required this.name,
    required this.description,
  });
}
class ResumePreviewPage extends StatelessWidget {
  final ResumeData resumeData;
  final File? profileImage;

  const ResumePreviewPage({required this.resumeData, this.profileImage});

  Future<pw.Document> _generatePdf() async {
    final pdf = pw.Document();
    final profileImageBytes = profileImage != null ? await profileImage!.readAsBytes() : null;

    final image = profileImageBytes != null
        ? pw.MemoryImage(profileImageBytes)
        : null;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) => [
          // Header
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (image != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  margin: const pw.EdgeInsets.only(right: 16),
                  decoration: pw.BoxDecoration(
                    shape: pw.BoxShape.circle,
                    image: pw.DecorationImage(image: image),
                  ),
                ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(resumeData.name, style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                  pw.Text(resumeData.email),
                  pw.Text(resumeData.phone),
                  pw.Text(resumeData.linkedIn),
                  pw.Text(resumeData.address),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // Professional Summary
          _buildSection("Professional Summary", resumeData.summary),

          // Work Experience
          _buildSection("Work Experience", null, children: resumeData.experience.map((e) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(e.position, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${e.company} | ${e.duration}'),
                  pw.Text(e.description),
                ],
              ),
            );
          }).toList()),

          // Education
          _buildSection("Education", null, children: resumeData.education.map((e) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(e.degree, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text('${e.institution} | ${e.year}'),
                ],
              ),
            );
          }).toList()),

          // Skills
          _buildSection("Skills", null, children: [
            pw.Wrap(
              spacing: 8,
              children: resumeData.skills.map((skill) => pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(skill),
              )).toList(),
            )
          ]),

          // Projects
          _buildSection("Projects", null, children: resumeData.projects.map((p) {
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(p.name, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text(p.description),
                ],
              ),
            );
          }).toList()),

          // Certifications
          _buildSection("Certifications", null, children: [
            pw.Bullet(
              text: resumeData.certifications.join(', '),
            )
          ]),

          // Languages
          _buildSection("Languages", null, children: [
            pw.Wrap(
              spacing: 10,
              children: resumeData.languages.map((lang) => pw.Text(lang)).toList(),
            ),
          ]),
        ],
      ),
    );

    return pdf;
  }

  pw.Widget _buildSection(String title, String? content, {List<pw.Widget>? children}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(height: 16),
        pw.Text(title, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 6),
        if (content != null) pw.Text(content),
        if (children != null) ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Resume Preview", style: GoogleFonts.poppins()),
        backgroundColor: Colors.blue.shade400,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: Icon(Icons.picture_as_pdf),
          label: Text("Preview & Print Resume"),
          onPressed: () async {
            final pdf = await _generatePdf();
            await Printing.layoutPdf(onLayout: (format) => pdf.save());
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Colors.blue.shade600,
          ),
        ),
      ),
    );
  }
}
