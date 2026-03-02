import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InterviewTipsPage extends StatelessWidget {
  final List<Map<String, String>> interviewTips = [
    {
      "title": "📌 Research the Company",
      "description": "Learn about the company's history, products, and culture before the interview."
    },
    {
      "title": "📌 Practice Common Questions",
      "description": "Prepare answers for common interview questions like 'Tell me about yourself' or 'Why should we hire you?'."
    },
    {
      "title": "📌 Dress Professionally",
      "description": "Wear formal attire that aligns with the company's culture to make a great first impression."
    },
    {
      "title": "📌 Arrive Early",
      "description": "Be at the venue or join the virtual call at least 10 minutes early to avoid last-minute stress."
    },
    {
      "title": "📌 Show Confidence & Body Language",
      "description": "Maintain eye contact, sit straight, and use gestures naturally while speaking."
    },
    {
      "title": "📌 Ask Smart Questions",
      "description": "At the end of the interview, ask about company growth, team structure, or future projects."
    },
    {
      "title": "📌 Follow Up with a Thank You Email",
      "description": "Send a polite email thanking the interviewer for their time and expressing your interest in the position."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          "Interview Tips",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold , color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade400,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: interviewTips.length,
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
                      interviewTips[index]["title"]!,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      interviewTips[index]["description"]!,
                      style: GoogleFonts.poppins(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
