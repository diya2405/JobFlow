// services/job_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class JobService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<QuerySnapshot> getCompanyJobs(String companyId) {
    return _firestore
        .collection('Job_Posts')
        .where('companyId', isEqualTo: companyId)
        .snapshots();
  }

  Future<Stream<QuerySnapshot<Object?>>> getAllJobs() async {
    return _firestore.collection('Job_Posts').snapshots();
  }

  Future<DocumentSnapshot> getJobDetails(String jobId) {
    return _firestore.collection('Job_Posts').doc(jobId).get();
  }

  Stream<List<DocumentSnapshot>> getMatchedCandidates(String jobId) async* {
    final usersSnapshot = _firestore.collection('User_Data').snapshots();

    await for (var users in usersSnapshot) {
      List<DocumentSnapshot> matchedCandidates = [];

      for (var user in users.docs) {
        final jobMatchDoc = await _firestore
            .collection('User_Data')
            .doc(user.id)
            .collection('JobMatches')
            .doc(jobId)
            .get();

        if (jobMatchDoc.exists && (jobMatchDoc['MatchScore'] ?? 0) > 0) {
          matchedCandidates.add(user);
        }
      }

      // Sort by MatchScore descending
      matchedCandidates.sort((a, b) {
        final aScore = (a.data() as Map<String, dynamic>)['JobMatches']?[jobId]?['MatchScore'] ?? 0;
        final bScore = (b.data() as Map<String, dynamic>)['JobMatches']?[jobId]?['MatchScore'] ?? 0;
        return bScore.compareTo(aScore);
      });

      yield matchedCandidates;
    }
  }
}