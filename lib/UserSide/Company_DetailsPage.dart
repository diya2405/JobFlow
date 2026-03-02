import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CompanyDetailsPage extends StatelessWidget {
  final String companyId;
  final String jobID;
  const CompanyDetailsPage({Key? key, required this.companyId, required this.jobID}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Company Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('Company_Data')
            .doc(companyId)
            .get(),
        builder: (context, companySnapshot) {
          if (companySnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (companySnapshot.hasError) {
            return Center(child: Text('Error loading company: ${companySnapshot.error}'));
          }

          if (!companySnapshot.hasData || !companySnapshot.data!.exists) {
            return const Center(child: Text("Company details not found."));
          }

          final companyData = companySnapshot.data!.data() as Map<String, dynamic>;

          // Extract company fields with null checks
          final companyName = companyData['CompanyName']?.toString() ?? 'Unknown Company';
          final companyLocation = companyData['Location']?.toString() ?? 'N/A';
          final companyDescription = companyData['company_description']?.toString() ?? 'No description available.';

          // Fetch specific job details using jobID
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Job_Posts')
                .doc(jobID)
                .get(),
            builder: (context, jobSnapshot) {
              if (jobSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (jobSnapshot.hasError) {
                return Center(child: Text('Error loading job: ${jobSnapshot.error}'));
              }

              if (!jobSnapshot.hasData || !jobSnapshot.data!.exists) {
                return const Center(child: Text("Job details not found."));
              }

              final jobData = jobSnapshot.data!.data() as Map<String, dynamic>;

              // Extract job details with null checks
              final jobTitle = jobData['title']?.toString() ?? 'No title available';
              final jobRequirements = jobData['requirements']?.toString() ?? 'No requirements available';
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company Information
                      Text(
                        companyName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Location: $companyLocation',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Company Description:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(companyDescription),
                      const SizedBox(height: 24),

                      // Job Information
                      Text(
                        'Job Title:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(jobTitle),
                      const SizedBox(height: 16),

                      Text(
                        'Job Requirements:',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(jobRequirements),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}