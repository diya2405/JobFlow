import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DressingTipsPage extends StatelessWidget {
  final List<Map<String, String>> dressingTips = [
    {
      "title": "👔 Choose Professional Attire",
      "description": "Wear formal or business casual depending on the company culture."
    },
    {
      "title": "🧼 Maintain Good Hygiene",
      "description": "Ensure clean and well-ironed clothes, neat hair, and trimmed nails."
    },
    {
      "title": "👞 Wear Proper Footwear",
      "description": "Opt for formal shoes for men and professional-looking footwear for women."
    },
    {
      "title": "⌚ Avoid Excess Accessories",
      "description": "Minimal jewelry, a classic watch, and no flashy accessories."
    },
    {
      "title": "👕 Choose Neutral Colors",
      "description": "Stick to neutral and professional shades like black, navy, and white."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(
          "Dressing Tips",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade400,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: dressingTips.length,
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
                      dressingTips[index]["title"]!,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      dressingTips[index]["description"]!,
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
