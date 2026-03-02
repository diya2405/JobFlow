import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:job_flow_project/CompanySide/PostJobPage.dart';

class EditJobPage extends StatefulWidget {
  final String jobId;
  final Map<String, dynamic> jobData;

  const EditJobPage({Key? key, required this.jobId, required this.jobData}) : super(key: key);

  @override
  _EditJobPageState createState() => _EditJobPageState();
}

class _EditJobPageState extends State<EditJobPage> {
  late TextEditingController titleController;
  late TextEditingController requirementsController;
  late TextEditingController salaryController;
  late String selectedJobType;
  final List<String> jobTypes = ['On-site', 'Hybrid', 'Remote', 'Flexible'];

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.jobData['title']);
    requirementsController = TextEditingController(text: widget.jobData['requirements']);
    salaryController = TextEditingController(text: widget.jobData['salary'] ?? '');
    selectedJobType = widget.jobData['jobType'] ?? 'On-site';
  }

  @override
  void dispose() {
    titleController.dispose();
    requirementsController.dispose();
    salaryController.dispose();
    super.dispose();
  }

  Future<void> _updateJob() async {
    if (titleController.text.trim().isEmpty ||
        requirementsController.text.trim().isEmpty ||
        selectedJobType.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final String newTitle = titleController.text.trim();
    final String newRequirements = requirementsController.text.trim();
    final String newSalary = salaryController.text.trim();
    final String newJobType = selectedJobType;

    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();

      // 1. Update main Job_Posts/{jobId}
      DocumentReference jobRef = FirebaseFirestore.instance.collection('Job_Posts').doc(widget.jobId);
      batch.update(jobRef, {
        'title': newTitle,
        'requirements': newRequirements,
        'salary': newSalary.isNotEmpty ? newSalary : "Not specified",
        'jobType': newJobType,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Fetch all users and check if they have this JobMatches/{jobId}
      QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('User_Data').get();

      for (var userDoc in usersSnapshot.docs) {
        DocumentReference matchRef = userDoc.reference.collection('JobMatches').doc(widget.jobId);

        // Check if the match exists before updating
        DocumentSnapshot matchSnapshot = await matchRef.get();
        if (matchSnapshot.exists) {
          batch.update(matchRef, {
            'title': newTitle,
            'requirements': newRequirements,
            'salary': newSalary.isNotEmpty ? newSalary : "Not specified",
            'jobType': newJobType,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      }

      await triggerResumeMatcher(widget.jobData["company_name"]);

      await batch.commit(); // 🔥 commit all updates together

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job updated successfully')),
      );
      Navigator.pop(context); // go back
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update job: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Job')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Job Details",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTextField(titleController, "Job Title", Icons.work),
            const SizedBox(height: 12),
            _buildTextField(requirementsController, "Requirements (separate with commas)", Icons.list, maxLines: 4),
            const SizedBox(height: 12),
            _buildTextField(salaryController, "Salary (optional)", Icons.attach_money),
            const SizedBox(height: 12),
            _buildJobTypeDropdown(),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _updateJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Update Job", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildJobTypeDropdown() {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: "Job Type*",
        prefixIcon: Icon(Icons.work_outline, color: Colors.blue),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedJobType,
          isDense: true,
          isExpanded: true,
          hint: const Text("Select job type"),
          items: jobTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              selectedJobType = newValue!;
            });
          },
        ),
      ),
    );
  }

  Future<void> triggerResumeMatcher(String companyName) async {
    try {
      final url = 'http://192.168.1.3:5000/';

      print("triggerd");
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          'companyName': companyName,
        }),
      );

      if (response.statusCode == 200) {
        print('Resume matching completed.');
      } else {
        throw Exception('Failed to match resumes');
      }
    } catch (e) {
      print('Error in matching resumes: $e');
      throw Exception('Failed to connect to matcher server');
    }
  }
}