import 'package:flutter/material.dart';
import 'package:job_flow_project/services/firestore_service.dart';

class ApplicantSelectionPage extends StatelessWidget {
  final String applicantId;

  ApplicantSelectionPage({required this.applicantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Select or Reject Candidate')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () async {
              await FirestoreService().updateCandidateStatus(applicantId, true);
              Navigator.pop(context);
            },
            child: Text('Select Candidate'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirestoreService().updateCandidateStatus(applicantId, false);
              Navigator.pop(context);
            },
            child: Text('Reject Candidate'),
          ),
        ],
      ),
    );
  }
}
