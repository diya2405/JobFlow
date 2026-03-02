import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:job_flow_project/CompanySide/resume_matche/trigger_resume_matcher.dart';
import 'CompanyProfilePage.dart';
import 'UploadedJobsPage.dart';

class PostJobPage extends StatefulWidget {
  final String companyId;
  PostJobPage({required this.companyId});

  @override
  _PostJobPageState createState() => _PostJobPageState();
}

class _PostJobPageState extends State<PostJobPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController requirementsController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController salaryController = TextEditingController();
  bool isLoading = false;
  Map<String, dynamic>? companyData;
  String? selectedJobType; // To store the selected job type
  final List<String> jobTypes = ['On-site', 'Hybrid', 'Remote', 'Flexible'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkCompanyDetails());
  }

  Future<void> _checkCompanyDetails() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('Company_Data')
          .doc(widget.companyId)
          .get();

      if (!doc.exists || doc.data() == null) {
        _showSnackBarAndNavigate();
        return;
      }

      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data["CompanyName"]?.toString().trim().isEmpty == true ||
          data["company_decription"]?.toString().trim().isEmpty == true) {
        _showSnackBarAndNavigate();
      } else {
        setState(() {
          companyData = data;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching company details: $e')),
      );
    }
  }

  void _showSnackBarAndNavigate() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please complete your company profile before posting a job.')),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => CompanyProfilePage(companyId: widget.companyId)),
    );
  }

  String? jobId;

  Future<void> _postJob() async {
    if (titleController.text.trim().isEmpty ||
        requirementsController.text.trim().isEmpty ||
        selectedJobType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill in all required job details.')));
      return;
    }

    setState(() => isLoading = true);

    try {
      if (companyData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Company details missing.')));
        setState(() => isLoading = false);
        return;
      }

      var jobRef = await FirebaseFirestore.instance.collection('Job_Posts').add({
        'companyId': widget.companyId,
        'title': titleController.text.trim(),
        'requirements': requirementsController.text.trim(),
        'salary': salaryController.text.trim().isNotEmpty ? salaryController.text.trim() : "Not specified",
        'jobType': selectedJobType,
        "company_description": companyData!["company_description"],
        "company_name": companyData!["CompanyName"],
        "company_location": companyData!["Location"] ?? "Not specified",
        "logo_url": companyData!["logoUrl"] ?? "",
        'company_website': companyData!["Website"] ?? "",
        'company_contact': companyData!["Contact"] ?? "",
        'company_email': companyData!["Email"] ?? "",
        'timestamp': FieldValue.serverTimestamp(),
      });

      setState(() {
        jobId = jobRef.id;
      });

      await triggerResumeMatcher(companyData!["CompanyName"]);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job posted successfully')));

      // Clear fields
      titleController.clear();
      requirementsController.clear();
      salaryController.clear();
      setState(() {
        selectedJobType = null;
      });

      // Navigate to uploaded jobs page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UploadedJobsPage(companyId: widget.companyId)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post job: $e')));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Post a Job"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UploadedJobsPage(companyId: widget.companyId)),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                  onPressed: isLoading ? null : _postJob,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Submit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              selectedJobType = newValue;
            });
          },
        ),
      ),
    );
  }

  Future<void> triggerResumeMatcher(String companyName) async {
    try {
      final url = 'http://192.168.4.135:5000/';
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