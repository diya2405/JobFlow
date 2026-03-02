import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'SelectionStatus/applicant_selection.dart';

class ApplicantDetailsPage extends StatefulWidget {
  final QueryDocumentSnapshot candidateData;
  final String jobId;

  const ApplicantDetailsPage({
    super.key,
    required this.candidateData,
    required this.jobId,
    required String userId,
  });

  @override
  State<ApplicantDetailsPage> createState() => _ApplicantDetailsPageState();
}

class _ApplicantDetailsPageState extends State<ApplicantDetailsPage> {
  late final Stream<DocumentSnapshot> _candidateStream;
  late final Stream<DocumentSnapshot> _jobMatchStream;

  @override
  void initState() {
    super.initState();
    _initializeStreams();
  }

  void _initializeStreams() {
    _candidateStream = FirebaseFirestore.instance
        .collection('User_Data')
        .doc(widget.candidateData.id)
        .snapshots();

    _jobMatchStream = FirebaseFirestore.instance
        .collection('User_Data')
        .doc(widget.candidateData.id)
        .collection('JobMatches')
        .doc(widget.jobId)
        .snapshots();
  }

  Future<void> _viewResume(Map<String, dynamic> candidateData) async {
    final url = candidateData['Resume']?.toString() ?? '';
    if (url.isEmpty) {
      _showAlert("No resume uploaded.");
      return;
    }

    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        _showAlert("Could not open resume.");
      }
    } catch (e) {
      _showAlert("Error: ${e.toString()}");
    }
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> candidateData) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.blue.shade300,
              width: 3,
            ),
          ),
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _getProfileImage(candidateData),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          candidateData['Name'] ?? 'No Name',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          candidateData['Email'] ?? 'No Email',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  ImageProvider _getProfileImage(Map<String, dynamic> candidateData) {
    final imageUrl = candidateData['ProfileImage']?.toString();
    return imageUrl?.isNotEmpty == true
        ? NetworkImage(imageUrl!)
        : const AssetImage("assets/images/DefaultImg.png") as ImageProvider;
  }

  Widget _buildInfoSection(String title, String? content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              content ?? 'Not specified',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchScoreSection(AsyncSnapshot<DocumentSnapshot> jobMatchSnapshot) {
    if (!jobMatchSnapshot.hasData || !jobMatchSnapshot.data!.exists) {
      return _buildInfoSection("Match Score", "Not calculated yet");
    }

    final jobMatchData = jobMatchSnapshot.data!.data() as Map<String, dynamic>;
    final score = jobMatchData['MatchScore']?.toString() ?? '0';
    final status = jobMatchData['selectionStatus']?.toString() ?? 'Not reviewed';

    return Column(
      children: [
        _buildInfoSection("Match Score", "$score%"),
        _buildInfoSection("Status", status[0].toUpperCase() + status.substring(1)),
      ],
    );
  }

  Future<void> _updateSelectionStatus(String newStatus) async {
    try {
      // Get the job document first to ensure we have companyId
      final jobDoc = await FirebaseFirestore.instance
          .collection('Job_Posts')
          .doc(widget.jobId)
          .get();

      if (!jobDoc.exists) {
        _showAlert("Job details not found!");
        return;
      }

      final companyId = jobDoc['companyId']?.toString() ?? '';

      // Reference to the job match document
      final jobMatchRef = FirebaseFirestore.instance
          .collection('User_Data')
          .doc(widget.candidateData.id)
          .collection('JobMatches')
          .doc(widget.jobId);

      // Get current document data
      final jobMatchDoc = await jobMatchRef.get();

      // Check current status (if exists)
      final currentStatus = jobMatchDoc.data()?['selectionStatus']?.toString();

      // Check if already has this status
      if (currentStatus == newStatus) {
        _showAlert("Candidate is already ${newStatus == "selected" ? "selected" : "rejected"}!");
        return;
      }

      // Confirmation logic
      bool confirmed = true;

      if (newStatus == "selected" && currentStatus == "rejected") {
        confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Selection"),
            content: const Text("This candidate was previously rejected. Are you sure you want to select them?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text("Confirm"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ?? false;
      }
      else if (newStatus == "rejected" && currentStatus == "selected") {
        confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Rejection"),
            content: const Text("This candidate was previously selected. Are you sure you want to reject them?"),
            actions: [
              TextButton(
                child: const Text("Cancel"),
                onPressed: () => Navigator.pop(context, false),
              ),
              TextButton(
                child: const Text("Confirm"),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ) ?? false;
      }

      if (!confirmed) return;

      // Update only the status fields while preserving existing data
      await jobMatchRef.set({
        'selectionStatus': newStatus,
        'selectionUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Send notification
      await _notifyUser(
        newStatus == 'selected' ? "You're Selected!" : "Application Rejected",
        newStatus == 'selected'
            ? "Congratulations! You've been selected for the job."
            : "We're sorry to inform you that you were not selected.",
        companyId: companyId,
        jobId: widget.jobId,
      );

      _showAlert("Candidate ${newStatus == "selected" ? "Selected" : "Rejected"} Successfully!");
    } catch (e) {
      _showAlert("Failed to update status: $e");
    }
  }

  Future<void> _notifyUser(
      String title,
      String message, {
        required String companyId,
        required String jobId,
      }) async {
    try {
      await FirebaseFirestore.instance
          .collection('User_Data')
          .doc(widget.candidateData.id)
          .collection('Notifications')
          .add({
        'title': title,
        'message': message,
        'jobId': jobId,
        'companyId': companyId,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
        'type': 'application_status',
      });
      debugPrint('Notification with job and company data added to Firestore.');
    } catch (e) {
      debugPrint('Error sending notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send notification: $e')),
        );
      }
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Applicant Details"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade700,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _candidateStream,
        builder: (context, userSnapshot) {
          return StreamBuilder<DocumentSnapshot>(
            stream: _jobMatchStream,
            builder: (context, jobMatchSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting ||
                  jobMatchSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                );
              }

              if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                return const Center(child: Text("User data not found"));
              }

              final candidateData = userSnapshot.data!.data() as Map<String, dynamic>;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildProfileHeader(candidateData),
                    const SizedBox(height: 24),
                    _buildInfoSection("Phone", candidateData['Phone']?.toString()),
                    _buildInfoSection("Location", candidateData['Location']?.toString()),
                    _buildInfoSection("Education", candidateData['EducationDetails']?.toString()),
                    _buildInfoSection("Skills", candidateData['Skills']?.toString()),
                    const SizedBox(height: 16),
                    _buildMatchScoreSection(jobMatchSnapshot),
                    const SizedBox(height: 24),
                    _buildActionButton(
                      icon: Icons.remove_red_eye,
                      label: "View Resume",
                      color: Colors.blue,
                      onPressed: () => _viewResume(candidateData),
                    ),
                    _buildActionButton(
                      icon: Icons.check_circle_outline,
                      label: "Select Candidate",
                      color: Colors.green,
                      onPressed: () => _updateSelectionStatus("selected"),
                    ),
                    _buildActionButton(
                      icon: Icons.cancel_outlined,
                      label: "Reject Candidate",
                      color: Colors.red,
                      onPressed: () => _updateSelectionStatus("rejected"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}