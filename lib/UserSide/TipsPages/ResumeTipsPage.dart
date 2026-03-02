import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'ResumeGenerator.dart'; // Import Resume Generator Page

class ResumeTipsPage extends StatelessWidget {
  final List<Map<String, String>> resumeTips = [
    {
      "title": "📄 Keep It Concise",
      "description": "Limit your resume to 1-2 pages, focusing on key achievements."
    },
    {
      "title": "🔑 Use Keywords",
      "description": "Include industry-relevant keywords for ATS compatibility."
    },
    {
      "title": "📝 Strong Summary",
      "description": "Write a powerful summary showcasing your key skills and experience."
    },
    {
      "title": "📊 Showcase Achievements",
      "description": "Use numbers and statistics to highlight your accomplishments."
    },
    {
      "title": "🎨 Clean Formatting",
      "description": "Use a readable font, bullet points, and proper spacing."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          "Resume Writing Tips",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade400,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: resumeTips.length,
                itemBuilder: (context, index) {
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    margin: EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resumeTips[index]["title"]!,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            resumeTips[index]["description"]!,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ResumeGenerator()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Colors.blue.shade700,
              ),
              child: Text(
                "Generate AI Resume 📝",
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
