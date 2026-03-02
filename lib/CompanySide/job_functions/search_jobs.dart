import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/job_services.dart';
import '../MatchedCandidatesPage.dart';

class JobSearchDelegate extends SearchDelegate<String> {
  final JobService _jobService = JobService();

  // Fetching jobs stream directly
  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<Stream<QuerySnapshot>>(
      future: _jobService.getAllJobs(), // Wait for the Future<Stream>
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading jobs'));
        }

        if (snapshot.hasData) {
          return StreamBuilder<QuerySnapshot>(
            stream: snapshot.data, // Now you have the stream here
            builder: (context, streamSnapshot) {
              if (streamSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (streamSnapshot.hasError) {
                return const Center(child: Text('Error loading jobs'));
              }

              final jobs = streamSnapshot.data?.docs ?? [];
              final filteredJobs = jobs.where((job) {
                final title = (job['title'] ?? '').toLowerCase();
                final location = (job['company_location'] ?? '').toLowerCase();
                return title.contains(query.toLowerCase()) ||
                    location.contains(query.toLowerCase());
              }).toList();

              return ListView.builder(
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
                  return ListTile(
                    title: Text(job['title']),
                    subtitle: Text(job['company_location'] ?? 'No location'),
                    onTap: () {
                      query = job['title']; // Set the selected title as query
                      showResults(context); // Show results
                    },
                  );
                },
              );
            },
          );
        } else {
          return const Center(child: Text('No jobs found'));
        }
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<Stream<QuerySnapshot>>(
      future: _jobService.getAllJobs(), // Wait for the Future<Stream>
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading jobs'));
        }

        if (snapshot.hasData) {
          return StreamBuilder<QuerySnapshot>(
            stream: snapshot.data, // Now you have the stream here
            builder: (context, streamSnapshot) {
              if (streamSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (streamSnapshot.hasError) {
                return const Center(child: Text('Error loading jobs'));
              }

              final jobs = streamSnapshot.data?.docs ?? [];
              final filteredJobs = jobs.where((job) {
                final title = (job['title'] ?? '').toLowerCase();
                return title.contains(query.toLowerCase());
              }).toList();

              return ListView.builder(
                itemCount: filteredJobs.length,
                itemBuilder: (context, index) {
                  final job = filteredJobs[index];
                  return ListTile(
                    title: Text(job['title']),
                    subtitle: Text(job['company_location'] ?? 'No location'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MatchedCandidatesPage(
                            jobId: job.id,
                            jobTitle: job['title'],
                            jobRequirements: job['requirements'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        } else {
          return const Center(child: Text('No jobs found'));
        }
      },
    );
  }

  @override
  String? get searchFieldLabel => 'Search for jobs';

  // Implement `buildLeading`
  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, ''); // Close the search
      },
    );
  }

  // Implement `buildActions`
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = ''; // Clear the search query
        },
      ),
    ];
  }
}
