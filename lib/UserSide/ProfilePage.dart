import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:job_flow_project/Authentication/Login.dart';
import 'package:job_flow_project/Widgets/ShowAlert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController contactController = TextEditingController();

  String email = "";
  String imageUrl = "";
  String resumeUrl = "";
  File? pickedImage;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> deleteResume() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (resumeUrl.isEmpty) {
      ShowAlert.showAlertDialog(context, "No resume uploaded.");
      return;
    }

    try {
      Reference storageRef = FirebaseStorage.instance.refFromURL(resumeUrl);
      await storageRef.delete();
      await FirebaseFirestore.instance.collection("User_Data").doc(user.uid).update({
        "Resume": FieldValue.delete(),
      });

      setState(() {
        resumeUrl = "";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Resume deleted successfully!"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ShowAlert.showAlertDialog(context, "Error deleting resume: ${e.toString()}");
    }
  }

  Future<void> confirmDeleteResume() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text("Are you sure you want to delete your resume?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          actions: [
            TextButton(
              child: Text("CANCEL", style: TextStyle(color: Colors.blue)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: Text("DELETE", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                deleteResume();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("User_Data")
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        setState(() {
          nameController.text = data.containsKey("Name") ? data["Name"] ?? "" : "";
          email = data.containsKey("Email") ? data["Email"] ?? "" : "";
          cityController.text = data.containsKey("Location") ? data["Location"] ?? "" : "";
          contactController.text = data.containsKey("Phone") ? data["Phone"] ?? "" : "";
          imageUrl = data.containsKey("ProfileImage") ? data["ProfileImage"] ?? "" : "";
          resumeUrl = data.containsKey("Resume") ? data["Resume"] ?? "" : "";
        });
      }
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        pickedImage = File(pickedFile.path);
      });
      uploadImageToFirebase();
    }
  }

  Future<void> uploadImageToFirebase() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null || pickedImage == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String fileName = "profile_${user.uid}.jpg";
      Reference storageRef = FirebaseStorage.instance.ref().child("profile_images/$fileName");

      UploadTask uploadTask = storageRef.putFile(pickedImage!);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance.collection("User_Data").doc(user.uid).update({
        "ProfileImage": downloadUrl,
      });

      Navigator.pop(context); // Close loading dialog

      setState(() {
        imageUrl = downloadUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile Image Updated Successfully!"),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ShowAlert.showAlertDialog(context, "Error uploading image: ${e.toString()}");
    }
  }

  Future<void> updateUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        await FirebaseFirestore.instance.collection("User_Data").doc(user.uid).update({
          "Name": nameController.text.trim(),
          "Location": cityController.text.trim(),
          "Phone": contactController.text.trim(),
        });

        Navigator.pop(context); // Close loading dialog

        setState(() {
          isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Profile Updated Successfully!"),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      } catch (e) {
        Navigator.pop(context); // Close loading dialog
        ShowAlert.showAlertDialog(context, "Error updating profile: ${e.toString()}");
      }
    }
  }

  Future<void> logoutUser() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Confirm Logout",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 15),
                Text("Are you sure you want to log out?"),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      child: Text("CANCEL", style: TextStyle(color: Colors.blue)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    SizedBox(width: 10),
                    TextButton(
                      child: Text("LOGOUT", style: TextStyle(color: Colors.red)),
                      onPressed: () async {
                        var pref = await SharedPreferences.getInstance();
                        await pref.setBool("isLoggedIn", false);
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => Login_Page()),
                              (route) => false,
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void launchResume() async {
    if (resumeUrl.isEmpty) {
      ShowAlert.showAlertDialog(context, "No resume uploaded yet.");
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Profile",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[800],
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: Icon(Icons.edit, color: Colors.blue),
                          title: Text("Edit Profile"),
                          onTap: () {
                            Navigator.pop(context);
                            setState(() {
                              isEditing = !isEditing;
                            });
                          },
                        ),
                        Divider(height: 1),
                        ListTile(
                          leading: Icon(Icons.logout, color: Colors.red),
                          title: Text("Logout"),
                          onTap: logoutUser,
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Profile Picture Section
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isEditing ? Colors.blue : Colors.blue.withOpacity(0.3),
                        width: 3,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: pickedImage != null
                          ? FileImage(pickedImage!)
                          : (imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : AssetImage("assets/images/DefaultImg.png")) as ImageProvider,
                    ),
                  ),
                  if (isEditing) // Only show camera icon in edit mode
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          onPressed: pickImage,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Profile Information Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _buildProfileField(
                      icon: Icons.person_outline,
                      label: "Full Name",
                      controller: nameController,
                      isEditing: isEditing,
                    ),
                    Divider(height: 20),
                    _buildProfileField(
                      icon: Icons.email_outlined,
                      label: "Email",
                      controller: TextEditingController(text: email),
                      isEditing: false, // Email is never editable
                    ),
                    Divider(height: 20),
                    _buildProfileField(
                      icon: Icons.location_on_outlined,
                      label: "Location",
                      controller: cityController,
                      isEditing: isEditing,
                    ),
                    Divider(height: 20),
                    _buildProfileField(
                      icon: Icons.phone_outlined,
                      label: "Phone Number",
                      controller: contactController,
                      isEditing: isEditing,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Resume Section - Different in edit mode vs view mode
            if (isEditing)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Resume",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      if (resumeUrl.isNotEmpty)
                        Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.picture_as_pdf, color: Colors.red),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Current resume uploaded",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: confirmDeleteResume,
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            OutlinedButton.icon(
                              icon: Icon(Icons.visibility),
                              label: Text("View Current Resume"),
                              onPressed: launchResume,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          "No resume uploaded",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
              )
            else
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(15),
                  onTap: resumeUrl.isNotEmpty ? launchResume : null,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Resume",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                resumeUrl.isEmpty ? "No resume uploaded" : "Tap to view resume",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (resumeUrl.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.open_in_new, color: Colors.blue),
                            onPressed: launchResume,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20),

            // Save Button (Visible only when editing)
            if (isEditing)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[800],
                    padding: EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: updateUserData,
                  child: Text(
                    "SAVE CHANGES",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required bool isEditing,
  }) {
    return Row(
      children: [
        Icon(icon, color: isEditing ? Colors.blue : Colors.grey),
        SizedBox(width: 15),
        Expanded(
          child: isEditing
              ? TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(color: Colors.grey[600]),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            style: TextStyle(fontSize: 16),
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                controller.text.isNotEmpty ? controller.text : "Not provided",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}