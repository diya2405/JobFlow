import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

Future<void> calculateJobMatchScores(String userId) async {
  // Fetch all jobs from Firestore
  var jobsSnapshot = await FirebaseFirestore.instance.collection("Jobs").get();

  // Fetch the user's resume from Firestore
  var userDoc = await FirebaseFirestore.instance.collection('User_Data').doc(userId).get();
  String resumeUrl = userDoc['Resume'];  // Assuming 'Resume' field contains the resume URL

  // Fetch the resume file (PDF in this case) and extract the text
  var response = await http.get(Uri.parse(resumeUrl));
  if (response.statusCode == 200) {
    var resumeText = extractTextFromResume(response.body);

    // Loop through all jobs and calculate match score
    for (var job in jobsSnapshot.docs) {
      var jobDescription = job['JobDescription'];

      // Calculate similarity score (using some algorithm like Cosine Similarity)
      double matchScore = calculateCosineSimilarity(resumeText, jobDescription);

      // Save the match score in Firestore under 'JobMatches' collection for this user
      await FirebaseFirestore.instance
          .collection('User_Data')
          .doc(userId)
          .collection('JobMatches')
          .doc(job.id) // Use job ID as document ID
          .set({'MatchScore': matchScore});
    }
  } else {
    throw Exception('Failed to fetch resume');
  }
}

// Function to extract text from the resume PDF
String extractTextFromResume(String resumePdf) {
  // Implement PDF parsing and text extraction logic (e.g., using libraries like pdf or pdf2text)
  // Returning a dummy string for now
  return "Sample extracted resume text";
}

// Function to calculate cosine similarity between the resume and job description
double calculateCosineSimilarity(String resumeText, String jobDescription) {
  // Implement cosine similarity calculation logic
  // Returning a dummy score for now
  return 0.85;
}
