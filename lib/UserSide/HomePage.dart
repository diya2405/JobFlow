import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../Widgets/ShowAlert.dart';
import '../firebasenotifications/firebase_messaging_handler.dart';
import 'JobDetailsPage.dart';
import 'NotificationPage.dart';
import 'TipsPages/DressingTipsPag.dart';
import 'TipsPages/InterviewTipsPage.dart';
import 'TipsPages/ResumeTipsPage.dart';
import 'UserDetailsSlider.dart';

class HomePageContent extends StatefulWidget {
  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  String resumeUrl = "";
  bool _showPermissionDialog = false;
  bool isLoading = false;
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
    checkUserDetails();
    fetchResume();
    _checkFirstLaunch();
  }

  Future<void> checkUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("User_Data")
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

        if (data == null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserDetailsSlider()),
          );
        } else {
          bool missingImportantFields = (data["Location"] == null || data["Location"].toString().trim().isEmpty) ||
              (data["EducationDetails"] == null || data["EducationDetails"].toString().trim().isEmpty) ||
              (data["Skills"] == null || data["Skills"].toString().trim().isEmpty);

          if (missingImportantFields) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserDetailsSlider()),
            );
          } else {
            if (data.containsKey("Resume") && data["Resume"] != null && data["Resume"].toString().trim().isNotEmpty) {
              setState(() {
                resumeUrl = data["Resume"];
              });
            } else {
              setState(() {
                resumeUrl = "";
              });
            }
          }
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserDetailsSlider()),
        );
      }
    }
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('notifications_requested') != true;
    if (isFirstLaunch) {
      setState(() => _showPermissionDialog = true);
    }
  }

  Future<void> _handlePermissionResponse(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_requested', true);

    if (accepted) {
      final granted = await NotificationHelper.requestPermission();
      if (granted) {
        final token = await FirebaseMessaging.instance.getToken();
        await FirebaseFirestore.instance
            .collection('User_Data')
            .doc(userId)
            .update({'fcmToken': token});
      }
    }

    setState(() => _showPermissionDialog = false);
  }

  Future<void> fetchResume() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("User_Data")
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;

        if (data != null && data.containsKey("Resume")) {
          setState(() {
            resumeUrl = data["Resume"];
          });
        }
      }
    }
  }

  Future<void> uploadResume() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      setState(() => isLoading = true);
      String fileName = "${user.displayName ?? user.uid}_resume.pdf";
      Reference storageRef =
      FirebaseStorage.instance.ref().child("resumes/$fileName");

      try {
        TaskSnapshot taskSnapshot = await storageRef.putFile(file);
        String downloadUrl = await taskSnapshot.ref.getDownloadURL();
        await FirebaseFirestore.instance
            .collection("User_Data")
            .doc(user.uid)
            .set({"Resume": downloadUrl}, SetOptions(merge: true));

        setState(() {
          resumeUrl = downloadUrl;
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Resume Uploaded Successfully!")),
        );
      } catch (e) {
        setState(() => isLoading = false);
        ShowAlert.showAlertDialog(
            context, "Error uploading resume: ${e.toString()}");
      }
    }
  }

  void launchResume() async {
    if (resumeUrl.isNotEmpty) {
      Uri url = Uri.parse(resumeUrl);

      try {
        bool launched = await launchUrl(url, mode: LaunchMode.externalApplication);
        if (!launched) {
          ShowAlert.showAlertDialog(context, "Could not open resume. Please try again.");
        }
      } catch (e) {
        ShowAlert.showAlertDialog(context, "Error opening resume: ${e.toString()}");
      }
    }
  }

  final List<Map<String, dynamic>> tips = [
    {"title": "Interview Tips", "icon": Icons.work, "page": InterviewTipsPage()},
    {"title": "Resume Writing", "icon": Icons.description, "page": ResumeTipsPage()},
    {"title": "Dressing Tips", "icon": Icons.checkroom, "page": DressingTipsPage()},
  ];


  final List<Map<String, dynamic>> resources = [
    {
      "title": "LinkedIn Profile Tips",
      "url": "https://www.youtube.com/watch?v=J30wmYgzVXM",
      "videoId": "J30wmYgzVXM"
    },
    {
      "title": "Salary Negotiation Guide",
      "url": "https://www.youtube.com/watch?v=NxKDHq4ts5A",
      "videoId": "NxKDHq4ts5A"
    },
    {
      "title": "How to answer tell me about yourself",
      "url": "https://www.youtube.com/watch?v=NxKDHq4ts5A",
      "videoId": "NxKDHq4ts5A"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Career Companion", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: userId == null
                ? Stream.empty()
                : FirebaseFirestore.instance
                .collection('User_Data')
                .doc(userId)
                .collection('Notifications')
                .where('read', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int unreadCount = snapshot.data?.docs.length ?? 0;

              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications, color: Colors.white),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 14,
                            minHeight: 14,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                  ],
                ),
                onPressed: () {
                  if (userId != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotificationsPage(userId: userId!),
                      ),
                    );
                  }
                },
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                SizedBox(height: 20),
                _buildSectionTitle("Career Guidance Tips"),
                _buildHorizontalList(tips),
                SizedBox(height: 20),
                _buildSectionTitle("Recommended Resources"),
                _buildResourceList(),
                SizedBox(height: 20),
                _buildSectionTitle("Daily Motivation"),
                _buildMotivationCard(),
              ],
            ),
          ),
          if (_showPermissionDialog) ...[
            const ModalBarrier(dismissible: false),
            AlertDialog(
              title: const Text('Enable Notifications'),
              content: Text(
                'Would you like to receive notifications about job applications updates?',
              ),
              actions: [
                TextButton(
                  onPressed: () => _handlePermissionResponse(false),
                  child: const Text('Not Now'),
                ),
                TextButton(
                  onPressed: () => _handlePermissionResponse(true),
                  child: const Text('Allow'),
                ),
              ],
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: resumeUrl.isNotEmpty ? launchResume : uploadResume,
        backgroundColor: resumeUrl.isNotEmpty ? Colors.green : Colors.blue[800],
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Icon(
          resumeUrl.isNotEmpty ? Icons.picture_as_pdf : Icons.upload_file,
          color: Colors.white,
        ),
        tooltip: resumeUrl.isNotEmpty ? "View Resume" : "Upload Resume",
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Welcome Back!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 8),
            Text(
              "Your next career opportunity is waiting. Keep applying and stay persistent!",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.7,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 8),
            Text(
              "Profile Strength: 70%",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.blue[900],
        ),
      ),
    );
  }

  Widget _buildHorizontalList(List<Map<String, dynamic>> items) {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: items.map((item) {
          return InkWell(
            onTap: item.containsKey("page")
                ? () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => item["page"]));
            }
                : null,
            child: Container(
              width: 120,
              margin: EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item["icon"], size: 40, color: Colors.blue[800]),
                  SizedBox(height: 8),
                  Text(
                    item["title"],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildResourceList() {
    return Column(
      children: resources.map((resource) {
        return Card(
          margin: EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: Icon(Icons.play_circle_filled, color: Colors.red),
            title: Text(resource["title"]),
            subtitle: Text("Tap to watch", style: TextStyle(color: Colors.grey)),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchYouTubeVideo(resource["videoId"], context),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMotivationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Today's Motivation",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[900],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "\"Success is not final, failure is not fatal: It is the courage to continue that counts.\"",
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "- Winston Churchill",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _launchYouTubeVideo(String videoId, BuildContext context) async {
  final nativeUrls = [
    'vnd.youtube:$videoId',          // Android native app
    'youtube://$videoId',            // iOS native app
    'https://www.youtube.com/watch?v=$videoId' // Web fallback
  ];

  for (final url in nativeUrls) {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        return;
      }
    } catch (e) {
      print('Error launching $url: $e');
    }
  }

  // If all else fails
  ShowAlert.showAlertDialog(
    context,
    "Could not open YouTube. Please make sure the YouTube app is installed.",
  );
}