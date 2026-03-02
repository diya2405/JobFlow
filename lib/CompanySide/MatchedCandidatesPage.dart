import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'applicants_page.dart';

class MatchedCandidatesPage extends StatefulWidget {
  final String jobId;
  final String jobTitle;
  final String jobRequirements;

  const MatchedCandidatesPage({
    required this.jobId,
    required this.jobTitle,
    required this.jobRequirements,
    Key? key,
  }) : super(key: key);

  @override
  _MatchedCandidatesPageState createState() => _MatchedCandidatesPageState();
}

class _MatchedCandidatesPageState extends State<MatchedCandidatesPage> {
  String _filterStatus = 'all'; // Default filter is 'all'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Applicants for ${widget.jobTitle}",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DropdownButtonFormField<String>(
                  value: _filterStatus,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    labelText: 'Filter by status',
                    labelStyle: TextStyle(color: Colors.blue.shade700),
                  ),
                  dropdownColor: Colors.white,
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                  },
                  items: <String>['all', 'selected', 'rejected']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value[0].toUpperCase() + value.substring(1),
                        style: TextStyle(
                          color: _getStatusColor(value),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('User_Data')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load applicants',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade700),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          child: Text(
                            'Try Again',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          "No applicants found",
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  );
                }

                return FutureBuilder<List<DocumentSnapshot>>(
                  future:
                      _getMatchedCandidates(snapshot.data!.docs, _filterStatus),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      );
                    }

                    if (futureSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading matches',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final candidates = futureSnapshot.data ?? [];

                    if (candidates.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_list_off,
                                size: 48, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              _filterStatus == 'all'
                                  ? "No matched applicants"
                                  : "No ${_filterStatus} applicants",
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.only(bottom: 16),
                      itemCount: candidates.length,
                      itemBuilder: (context, index) {
                        final candidate = candidates[index];
                        final data = candidate.data() as Map<String, dynamic>;
                        final name = data['Name'] as String? ?? 'No Name';
                        final email = data['Email'] as String? ?? 'No Email';

                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ApplicantDetailsPage(
                                      candidateData: candidate
                                          as QueryDocumentSnapshot<Object?>,
                                      jobId: widget.jobId,
                                      userId: candidate.id,
                                    ),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.blue.shade800,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                email,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(Icons.chevron_right,
                                            color: Colors.grey),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    FutureBuilder<DocumentSnapshot>(
                                      future: FirebaseFirestore.instance
                                          .collection('User_Data')
                                          .doc(candidate.id)
                                          .collection('JobMatches')
                                          .doc(widget.jobId)
                                          .get(),
                                      builder: (context, matchSnapshot) {
                                        if (matchSnapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return LinearProgressIndicator(
                                            minHeight: 4,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.blue),
                                          );
                                        }

                                        if (matchSnapshot.hasError ||
                                            !matchSnapshot.hasData) {
                                          return Text(
                                            "Error loading match data",
                                            style: TextStyle(color: Colors.red),
                                          );
                                        }

                                        final matchData = matchSnapshot.data!
                                            .data() as Map<String, dynamic>?;
                                        final score =
                                            (matchData?['MatchScore'] as num? ??
                                                    0)
                                                .toDouble();
                                        final selectionStatus =
                                            matchData?['selectionStatus'] ??
                                                'no_status';

                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Match Score",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                ),
                                                Text(
                                                  "${score.toStringAsFixed(1)}%",
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        _getScoreColor(score),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SizedBox(height: 8),
                                            LinearProgressIndicator(
                                              value:
                                                  (score / 100).clamp(0.0, 1.0),
                                              minHeight: 8,
                                              backgroundColor:
                                                  Colors.grey.shade200,
                                              color: _getScoreColor(score),
                                            ),
                                            SizedBox(height: 12),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12, vertical: 6),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(
                                                        selectionStatus)
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: _getStatusColor(
                                                          selectionStatus)
                                                      .withOpacity(0.3),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                selectionStatus[0]
                                                        .toUpperCase() +
                                                    selectionStatus
                                                        .substring(1),
                                                style: TextStyle(
                                                  color: _getStatusColor(
                                                      selectionStatus),
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
    );
  }

  Future<List<DocumentSnapshot>> _getMatchedCandidates(
      List<DocumentSnapshot> users, String filterStatus) async {
    final futures = users.map((user) async {
      final matchDoc = await FirebaseFirestore.instance
          .collection('User_Data')
          .doc(user.id)
          .collection('JobMatches')
          .doc(widget.jobId)
          .get();

      if (matchDoc.exists) {
        final status = matchDoc.data()?['selectionStatus'] ?? 'no_status';
        final score = (matchDoc.data()?['MatchScore'] as num? ?? 0).toDouble();

        // Filter based on selection status
        if (filterStatus == 'all' || filterStatus == status) {
          return {'user': user, 'score': score};
        }
      }
      return null;
    }).toList();

    final results = await Future.wait(futures);

    // Filter out null values and sort by match score in descending order
    final filteredResults = results.whereType<Map<String, dynamic>>().toList();
    filteredResults.sort((a, b) => b['score'].compareTo(a['score']));

    // Return the sorted user documents
    return filteredResults
        .map((result) => result['user'] as DocumentSnapshot)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'selected':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'no_status':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.blue;
    return Colors.orange;
  }
}
