import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class JobDetailsPageUser extends StatelessWidget {
  final Map<String, dynamic> job;

  JobDetailsPageUser({required this.job});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(job["title"] ?? "Job Details",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Header with Logo
            _buildCompanyHeader(),
            const SizedBox(height: 20),

            // Job Info Card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Job Title
                    Text(
                      job["title"] ?? "No title specified",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Job Type and Salary
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.work_outline,
                          text: job["jobType"] ?? "Not specified",
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 10),
                        if (job["salary"] != null && job["salary"] != "Not specified")
                          _buildInfoChip(
                            icon: Icons.attach_money,
                            text: job["salary"],
                            color: Colors.green,
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),

                    // Requirements Section
                    _buildSectionTitle("Requirements"),
                    const SizedBox(height: 8),
                    ..._buildRequirementsList(),
                    const SizedBox(height: 15),

                    // Job Description
                    _buildSectionTitle("Company Description"),
                    const SizedBox(height: 8),
                    Text(
                      job["company_description"] ?? "No description available",
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Company Contact Info
            _buildContactInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Company Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: job["logo_url"] != null && job["logo_url"].isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              job["logo_url"],
              fit: BoxFit.contain,
            ),
          )
              : const Icon(Icons.business, size: 40, color: Colors.blue),
        ),
        const SizedBox(width: 16),

        // Company Name and Location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job["company_name"] ?? "Company not specified",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    job["company_location"] ?? "Location not specified",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text, required Color color}) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  List<Widget> _buildRequirementsList() {
    if (job["requirements"] == null) {
      return [
        const Text("No requirements specified", style: TextStyle(color: Colors.grey)),
      ];
    }

    // Handle both string (comma separated) and list formats
    List<String> requirements = [];
    if (job["requirements"] is String) {
      requirements = (job["requirements"] as String).split(',');
    } else if (job["requirements"] is List) {
      requirements = List<String>.from(job["requirements"]);
    }

    return requirements.map((req) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                req.trim(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildContactInfo() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Contact Information"),
            const SizedBox(height: 10),

            // Website
            if (job["company_website"] != null && job["company_website"].isNotEmpty)
              _buildContactTile(
                icon: Icons.link,
                text: job["company_website"],
                onTap: () => launchUrl(Uri.parse(job["company_website"])),
              ),

            // Email
            if (job["company_email"] != null && job["company_email"].isNotEmpty)
              _buildContactTile(
                icon: Icons.email,
                text: job["company_email"],
                onTap: () => launchUrl(Uri.parse("mailto:${job["company_email"]}")),
              ),

            // Phone
            if (job["company_contact"] != null && job["company_contact"].isNotEmpty)
              _buildContactTile(
                icon: Icons.phone,
                text: job["company_contact"],
                onTap: () => launchUrl(Uri.parse("tel:${job["company_contact"]}")),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

}