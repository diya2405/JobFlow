import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:job_flow_project/UserSide/JobDetailsPage.dart';

import 'Company_DetailsPage.dart';

class ApplicantHistoryPage extends StatefulWidget {
  final String userId;

  const ApplicantHistoryPage({Key? key, required this.userId}) : super(key: key);

  @override
  _ApplicantHistoryPageState createState() => _ApplicantHistoryPageState();
}

class _ApplicantHistoryPageState extends State<ApplicantHistoryPage> {
  late final Stream<QuerySnapshot> _jobMatchesStream;
  String? _selectedCompanyId;
  Map<String, String> _companyNames = {};
  String _searchQuery = '';
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  Map<String, Map<String, dynamic>> _jobCache = {}; // Cache for job data

  @override
  void initState() {
    super.initState();
    _jobMatchesStream = FirebaseFirestore.instance
        .collection('User_Data')
        .doc(widget.userId)
        .collection('JobMatches')
        .orderBy('selectionUpdated', descending: true)
        .snapshots();

    _fetchCompanies();// Add cleanup on init
  }

  Future<void> _fetchCompanies() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Company_Data')
          .get();

      final names = <String, String>{};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        names[doc.id] = data['CompanyName'] ?? 'Unknown Company';
      }

      if (mounted) {
        setState(() {
          _companyNames = names;
        });
      }
    } catch (e) {
      debugPrint('Error fetching companies: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'selected':
        return Colors.green.shade700;
      case 'rejected':
        return Colors.red.shade700;
      case 'interview':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'selected':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'interview':
        return Icons.calendar_today;
      default:
        return Icons.hourglass_empty;
    }
  }

  Future<void> _refresh() async {
    _jobCache.clear(); // Clear cache on refresh
    await _fetchCompanies();
    if (mounted) setState(() {});
  }

  Future<Map<String, dynamic>?> _getJobData(String jobId) async {
    if (_jobCache.containsKey(jobId)) {
      return _jobCache[jobId];
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Job_Posts')
          .doc(jobId)
          .get();

      if (doc.exists) {
        _jobCache[jobId] = doc.data()!;
        return doc.data()!;
      }
    } catch (e) {
      debugPrint('Error fetching job data: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Application History"),
        actions: [
          if (_selectedCompanyId != null || _searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() {
                _selectedCompanyId = null;
                _searchQuery = '';
              }),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by job title...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: (val) => setState(() {
                      _searchQuery = val.trim().toLowerCase();
                    }),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedCompanyId,
                    hint: const Text('Filter by Company'),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All Companies'),
                      ),
                      ..._companyNames.entries.map(
                            (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() {
                      _selectedCompanyId = val;
                    }),
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _jobMatchesStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return _emptyStateWidget("No applications yet.");
                  }

                  return FutureBuilder<List<DocumentSnapshot>>(
                    future: _filterApplications(snapshot.data!.docs),
                    builder: (context, filterSnapshot) {
                      if (filterSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (filterSnapshot.hasError) {
                        return Center(child: Text('Filter error: ${filterSnapshot.error}'));
                      }

                      final applications = filterSnapshot.data ?? [];

                      if (applications.isEmpty) {
                        return _emptyStateWidget(
                            "No applications found with current filters.");
                      }

                      return ListView.builder(
                        itemCount: applications.length,
                        itemBuilder: (context, index) {
                          final doc = applications[index];
                          final appData = doc.data() as Map<String, dynamic>;
                          final status = (appData['selectionStatus'] ?? 'pending')
                              .toString()
                              .toLowerCase();
                          final jobTitle = appData['JobTitle'] ?? 'Unknown Position';
                          final jobId = appData['JobId'];

                          return FutureBuilder<Map<String, dynamic>?>(
                            future: jobId != null ? _getJobData(jobId) : Future.value(null),
                            builder: (context, jobSnapshot) {
                              final jobData = jobSnapshot.data;
                              final companyId = jobData?['companyId'];
                              final companyName = companyId != null
                                  ? _companyNames[companyId] ?? 'Unknown Company'
                                  : 'Unknown Company';

                              final dateStr = appData['selectionUpdated'] != null
                                  ? _dateFormat.format(
                                  (appData['selectionUpdated'] as Timestamp).toDate())
                                  : '';

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                child: ListTile(
                                  leading: Icon(
                                    _getStatusIcon(status),
                                    color: _getStatusColor(status),
                                  ),
                                  title: Text(jobTitle),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(companyName),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Status: ${status[0].toUpperCase()}${status.substring(1)}',
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Text(dateStr),
                                  onTap: () => _openJobDetails(appData),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<DocumentSnapshot>> _filterApplications(List<DocumentSnapshot> docs) async {
    final filtered = <DocumentSnapshot>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final jobId = data['JobId'];

      // Apply search filter first (cheaper)
      final matchesSearch = _searchQuery.isEmpty ||
          (data['JobTitle'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery);

      if (!matchesSearch) continue;

      // If no company filter, add to results
      if (_selectedCompanyId == null) {
        filtered.add(doc);
        continue;
      }

      // If we have a company filter, we need to check the job data
      if (jobId != null) {
        try {
          final jobData = await _getJobData(jobId);
          if (jobData != null && jobData['companyId'] == _selectedCompanyId) {
            filtered.add(doc);
          }
        } catch (e) {
          debugPrint('Error filtering by company: $e');
        }
      }
    }

    return filtered;
  }

  Future<void> _openJobDetails(Map<String, dynamic> appData) async {
    final jobId = appData['JobId'];
    if (jobId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Job details not available")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final jobData = await _getJobData(jobId);
      if (jobData == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job no longer exists")),
        );
        return;
      }

      final companyId = jobData['companyId'];
      if (companyId == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Company information missing")),
        );
        return;
      }

      Navigator.pop(context); // Close loading dialog

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => JobDetailsPageUser(job: jobData)
        ),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading details: ${e.toString()}")),
      );
    }
  }

  Widget _emptyStateWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

}