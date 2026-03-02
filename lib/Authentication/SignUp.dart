import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:job_flow_project/Widgets/ShowAlert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Login.dart';
import '../UserSide/MainScreen.dart';
import '../WelcomePages/SplashScreen.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool viewPassword1 = true;
  bool viewPassword2 = true;

  // Toggle password visibility
  Widget suffixIcon(String pass) {
    return InkWell(
      onTap: () {
        setState(() {
          if (pass == "1") {
            viewPassword1 = !viewPassword1;
          } else if (pass == "2") {
            viewPassword2 = !viewPassword2;
          }
        });
      },
      child: Icon(viewPassword1 ? Icons.visibility : Icons.visibility_off),
    );
  }

  // Handle user sign-up
  Future<void> signup() async {
    String name = nameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPass = confirmPasswordController.text.trim();
    String phone = phoneController.text.trim();

    if (_validateFields(name, email, password, confirmPass, phone)) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user!.sendEmailVerification();
        ShowAlert.showAlertDialog(context, "A verification email has been sent. Please check your inbox.");

        bool isVerified = await _waitForEmailVerification(userCredential.user!);
        if (isVerified) {
          await _saveUserData(userCredential.user!.uid, name, email, phone);
        } else {
          ShowAlert.showAlertDialog(context, "Email not verified. Please verify before logging in.");
        }
      } catch (e) {
        ShowAlert.showAlertDialog(context, "Error: ${e.toString()}");
      }
    }
  }

  // Validate input fields
  bool _validateFields(String name, String email, String password, String confirmPass, String phone) {
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPass.isEmpty || phone.isEmpty) {
      ShowAlert.showAlertDialog(context, "Please enter all required details.");
      return false;
    }
    if (confirmPass != password) {
      ShowAlert.showAlertDialog(context, "Passwords do not match.");
      return false;
    }
    return true;
  }

  // Wait for email verification
  Future<bool> _waitForEmailVerification(User user) async {
    int attempts = 0;
    while (!user.emailVerified && attempts < 10) {
      await Future.delayed(Duration(seconds: 5));
      await user.reload();
      user = FirebaseAuth.instance.currentUser!;
      if (user.emailVerified) return true;
      attempts++;
    }
    return false;
  }

  // Save user data to Firestore
  Future<void> _saveUserData(String uid, String name, String email, String phone) async {
    try {
      await FirebaseFirestore.instance.collection("User_Data").doc(uid).set({
        "Name": name,
        "Email": email,
        "Phone": phone,
        "UserType": "User",
        "UID": uid,
      });

      var pref = await SharedPreferences.getInstance();
      await pref.setBool(SplashScreen.KEYLOGINVALUE, true);
      pref.setString(SplashScreen.KEYUSERROLE, "User");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => UserHomePage()),
            (route) => false,
      );
    } catch (e) {
      ShowAlert.showAlertDialog(context, "Error saving user data: ${e.toString()}");
    }
  }

  // Build the widget UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.lightBlueAccent, Colors.lightBlue],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 21.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              const Padding(
                padding: EdgeInsets.only(left: 21.0),
                child: Text(
                  "Sign Up",
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 21.0),
                child: Text("Create your account.", style: TextStyle(fontSize: 25, color: Colors.white)),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(55),
                      topRight: Radius.circular(55),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _inputField(nameController, "Enter Full Name", Icons.person),
                          const SizedBox(height: 20),
                          _inputField(emailController, "Enter Email", Icons.mail),
                          const SizedBox(height: 20),
                          _inputField(phoneController, "Enter Phone Number", Icons.phone),
                          const SizedBox(height: 20),

                          // Password Fields
                          _inputFieldPassword(passwordController, "Enter Password", viewPassword1, "1"),
                          const SizedBox(height: 15),
                          _inputFieldPassword(confirmPasswordController, "Confirm Password", viewPassword2, "2"),
                          const SizedBox(height: 15),

                          // Sign Up Button
                          ElevatedButton(
                            onPressed: signup,
                            child: const Text("Sign Up", style: TextStyle(fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Login Redirect
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Already have an account?"),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => Login_Page()));
                                },
                                child: const Text("Sign In"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Input Field for Text (e.g., Name, Email, Phone)
  Widget _inputField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        fillColor: Colors.grey.shade200,
        filled: true,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(55),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(55),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }

  // Input Field for Password
  Widget _inputFieldPassword(TextEditingController controller, String hint, bool hide, String buttonNo) {
    return TextField(
      controller: controller,
      obscureText: hide,
      decoration: InputDecoration(
        fillColor: Colors.grey.shade200,
        filled: true,
        hintText: hint,
        suffixIcon: suffixIcon(buttonNo),
        prefixIcon: Icon(Icons.password, color: Colors.black),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(55),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(55),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}
