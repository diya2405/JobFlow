import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import '../Authentication/Login.dart';
import '../WelcomePages/SplashScreen.dart';

class CompanyProfilePage extends StatefulWidget {
  final String companyId;

  CompanyProfilePage({required this.companyId});

  @override
  _CompanyProfilePageState createState() => _CompanyProfilePageState();
}

class _CompanyProfilePageState extends State<CompanyProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  bool _isEditing = false;
  String companyName = '';
  String companyDescription = '';
  String companyContact = '';
  String companyWebsite = '';
  String profileImageUrl = '';
  bool _isLoading = false;
  File? _image;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchCompanyDetails();
  }

  Future<void> _fetchCompanyDetails() async {
    setState(() {
      _isLoading = true;
    });

    DocumentSnapshot doc =
    await FirebaseFirestore.instance.collection('Company_Data').doc(widget.companyId).get();

    if (doc.exists) {
      setState(() {
        companyName = doc['CompanyName'] ?? '';
        companyDescription = doc['company_description'] ?? '';
        companyContact = doc['Contact'] ?? '';
        companyWebsite = doc['Website'] ?? '';
        profileImageUrl = doc['logoUrl'] ?? "assets/images/logo.png";

        _nameController.text = companyName;
        _descriptionController.text = companyDescription;
        _contactController.text = companyContact;
        _websiteController.text = companyWebsite;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Company details not found!')),
      );
    }
  }

  Future<void> _updateCompanyProfile() async {
    if (_nameController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Company Name and Description are required!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    if (_image != null) {
      String fileName = 'company_logo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      firebase_storage.Reference storageRef = firebase_storage.FirebaseStorage.instance.ref().child('company_logos').child(fileName);

      // Upload image
      firebase_storage.UploadTask uploadTask = storageRef.putFile(_image!);
      await uploadTask;

      String downloadUrl = await storageRef.getDownloadURL();
      // Update Firestore with the new logo URL
      await FirebaseFirestore.instance.collection('Company_Data').doc(widget.companyId).update({
        'CompanyName': _nameController.text.trim(),
        'company_description': _descriptionController.text.trim(),
        'Contact': _contactController.text.trim(),
        'Website': _websiteController.text.trim(),
        'logoUrl': downloadUrl,
      });

      // Update Job Posts where the companyId matches
      var jobPostsSnapshot = await FirebaseFirestore.instance
          .collection('Job_Posts')
          .where('companyId', isEqualTo: widget.companyId)
          .get();

      for (var doc in jobPostsSnapshot.docs) {
        await doc.reference.update({
          'CompanyName': _nameController.text.trim(),
          'company_description': _descriptionController.text.trim(),
          'Contact': _contactController.text.trim(),
          'Website': _websiteController.text.trim(),
          'logoUrl': downloadUrl,
        });
      }

      setState(() {
        profileImageUrl = downloadUrl;
      });
    } else {
      await FirebaseFirestore.instance.collection('Company_Data').doc(widget.companyId).update({
        'CompanyName': _nameController.text.trim(),
        'company_description': _descriptionController.text.trim(),
        'Contact': _contactController.text.trim(),
        'Website': _websiteController.text.trim(),
      });

      // Update Job Posts where the companyId matches
      var jobPostsSnapshot = await FirebaseFirestore.instance
          .collection('Job_Posts')
          .where('companyId', isEqualTo: widget.companyId)
          .get();

      for (var doc in jobPostsSnapshot.docs) {
        await doc.reference.update({
          'CompanyName': _nameController.text.trim(),
          'company_description': _descriptionController.text.trim(),
          'Contact': _contactController.text.trim(),
          'Website': _websiteController.text.trim(),
        });
      }
    }

    setState(() {
      companyName = _nameController.text;
      companyDescription = _descriptionController.text;
      companyContact = _contactController.text;
      companyWebsite = _websiteController.text;
      _isEditing = false;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile updated successfully!')),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> logoutUser() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              child: Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("Logout", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                var pref = await SharedPreferences.getInstance();

                await pref.setBool(SplashScreen.KEYLOGINVALUE, true);
                await pref.setString(SplashScreen.KEYUSERROLE, "");

                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => Login_Page()),
                      (route) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Company Profile', style: TextStyle(fontWeight: FontWeight.bold)),
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
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white, size: 26),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
                          title: Text("Logout"),
                          onTap: logoutUser,
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Picture Section
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.blue.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 56,
                      backgroundImage: _image == null
                          ? (profileImageUrl.isEmpty || profileImageUrl == "assets/images/logo.png"
                          ? AssetImage("assets/images/DefaultImg.png")
                          : NetworkImage(profileImageUrl)) as ImageProvider
                          : FileImage(_image!),
                    ),
                  ),
                ),
                if (_isEditing)
                  FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: _pickImage,
                  ),
              ],
            ),
            SizedBox(height: 24),

            // Company Name
            _buildProfileSection(
              title: "Company Name",
              content: _isEditing
                  ? TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              )
                  : Text(
                companyName.isNotEmpty ? companyName : "No Name Provided",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              icon: Icons.business,
            ),

            SizedBox(height: 16),

            // Company Description
            _buildProfileSection(
              title: "Description",
              content: _isEditing
                  ? TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              )
                  : Text(
                companyDescription.isNotEmpty ? companyDescription : "No Description Provided",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              icon: Icons.description,
            ),

            SizedBox(height: 16),

            // Contact Info
            _buildProfileSection(
              title: "Contact Information",
              content: _isEditing
                  ? TextField(
                controller: _contactController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              )
                  : Text(
                companyContact.isNotEmpty ? companyContact : "No Contact Info",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              icon: Icons.phone,
            ),

            SizedBox(height: 16),

            // Website
            _buildProfileSection(
              title: "Website",
              content: _isEditing
                  ? TextField(
                controller: _websiteController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
              )
                  : Text(
                companyWebsite.isNotEmpty ? companyWebsite : "No Website Provided",
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              ),
              icon: Icons.language,
            ),

            SizedBox(height: 30),

            // Action Buttons
            if (_isEditing) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _updateCompanyProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('SAVE CHANGES', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _nameController.text = companyName;
                    _descriptionController.text = companyDescription;
                    _contactController.text = companyContact;
                    _websiteController.text = companyWebsite;
                  });
                },
                child: Text('CANCEL', style: TextStyle(color: Colors.grey)),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: () => setState(() => _isEditing = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text('EDIT PROFILE', style: TextStyle(color: Colors.white)),
              ),
            ],
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection({required String title, required Widget content, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        content,
      ],
    );
  }
}