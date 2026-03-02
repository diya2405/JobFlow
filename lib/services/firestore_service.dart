import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Update candidate status in Firestore
  Future<void> updateCandidateStatus(String applicantId, bool isSelected) async {
    try {
      // Reference to the candidate's document in Firestore
      DocumentReference applicantRef = _db.collection('User_Data').doc(applicantId);

      // Update the 'status' field of the candidate document
      await applicantRef.update({
        'status': isSelected ? 'selected' : 'rejected',  // You can customize the status field and values
      });

      print('Candidate status updated successfully.');
    } catch (e) {
      print('Error updating candidate status: $e');
    }
  }

  // Fetch applicant data by ID
  Future<DocumentSnapshot> getApplicantById(String applicantId) async {
    try {
      // Reference to the candidate's document
      DocumentReference applicantRef = _db.collection('applicants').doc(applicantId);
      return await applicantRef.get();  // Fetch the document
    } catch (e) {
      print('Error fetching applicant data: $e');
      rethrow;  // Re-throw error to handle it in calling code
    }
  }

  // Fetch all applicants data (if needed)
  Future<List<QueryDocumentSnapshot>> getAllApplicants() async {
    try {
      // Reference to the applicants collection
      QuerySnapshot snapshot = await _db.collection('applicants').get();
      return snapshot.docs;  // Return the list of documents
    } catch (e) {
      print('Error fetching applicants: $e');
      return [];
    }
  }
}
