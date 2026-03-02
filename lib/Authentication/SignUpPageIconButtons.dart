import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../WelcomePages/SplashScreen.dart';
import '../UserSide/MainScreen.dart';

class SignUpPageIconButtons extends StatelessWidget {
  const SignUpPageIconButtons({super.key});

  Future<User?> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        return null; // User canceled sign-in
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      return userCredential.user;
    } catch (error) {
      print("Google Sign-In Error: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Google Sign-In Failed!")),
      );
      return null;
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    User? user = await _signInWithGoogle(context);
    if (user == null) return; // If user canceled login

    // Check if user exists in Firestore
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection("User_Data")
        .doc(user.uid)
        .get();

    if (!userDoc.exists) {
      // Show dialog to collect User Type & City
      Map<String, String>? userInfo = await _showUserInfoDialog(context);
      if (userInfo == null) return; // User canceled

      String userType = userInfo['UserType']!;
      String city = userInfo['City']!;

      // Store new user details in Firestore
      await FirebaseFirestore.instance.collection("User_Data").doc(user.uid).set({
        "UID": user.uid,
        "Name": user.displayName ?? "Unknown",
        "Email": user.email ?? "",
        "ProfilePic": user.photoURL ?? "",
        "LoginMethod": "Google",
        "UserType": userType,
        "City": city,
        "CreatedAt": FieldValue.serverTimestamp(),
      });
    }

    // Store login status in SharedPreferences
    var pref = await SharedPreferences.getInstance();
    await pref.setBool(SplashScreen.KEYLOGINVALUE, true);

    // Navigate to appropriate screen based on user type
    if (userDoc.exists) {
      String userType = userDoc["UserType"];
      if (userType == "Company") {
        // Navigate to company dashboard if implemented
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => CompanyHomePage()));
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => UserHomePage()),
        );
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Welcome, ${user.displayName}!")),
    );
  }

  // Show dialog to collect User Type & City
  Future<Map<String, String>?> _showUserInfoDialog(BuildContext context) async {
    String userType = "User";
    TextEditingController cityController = TextEditingController();

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Complete Your Profile"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Select Account Type:"),
                  RadioListTile(
                    title: const Text("User"),
                    value: "User",
                    groupValue: userType,
                    onChanged: (value) => setState(() => userType = value!),
                  ),
                  RadioListTile(
                    title: const Text("Company"),
                    value: "Company",
                    groupValue: userType,
                    onChanged: (value) => setState(() => userType = value!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cityController,
                    decoration: const InputDecoration(labelText: "Enter City"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null), // Cancel
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (cityController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter your city")),
                      );
                      return;
                    }
                    Navigator.pop(context, {"UserType": userType, "City": cityController.text});
                  },
                  child: const Text("Continue"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 60,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.grey),
          ),
          child: IconButton(
            onPressed: () => _handleGoogleSignIn(context),
            icon: const Image(
              width: 50,
              height: 50,
              image: AssetImage("assets/icons/google-icon.png"),
            ),
          ),
        ),
      ],
    );
  }
}
