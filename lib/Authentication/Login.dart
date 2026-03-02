import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../UserSide/MainScreen.dart';
import '../CompanySide/CompanyHomePage.dart';
import '../WelcomePages/RoleSelectionPage.dart';
import '../WelcomePages/SplashScreen.dart';
import '../Widgets/Input.dart';
import '../Widgets/ShowAlert.dart';
import 'ForgetPassword.dart';
import 'SignUpPageDivider.dart';
import 'SignUpPageIconButtons.dart';

// Constants for SharedPreferences keys
class SharedPrefKeys {
  static const isLoggedIn = "isLoggedIn";
  static const userRole = "userRole";
  static const KEYLOGINVALUE = "KEYLOGINVALUE";
  static const KEYUSERROLE = "KEYUSERROLE";
}

class Login_Page extends StatefulWidget {
  const Login_Page({super.key});

  @override
  State<Login_Page> createState() => _Login_PageState();
}

class _Login_PageState extends State<Login_Page> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool viewPassword = true;
  bool isLoading = false;  // State to control loading indicator

  void signin(String email, String password) async {
    if (email.isNotEmpty && password.isNotEmpty) {
      setState(() {
        isLoading = true; // Show loading indicator
      });

      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        String userId = userCredential.user!.uid;

        // Check in user_data collection
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection("User_Data").doc(userId).get();

        if (userDoc.exists) {
          String role = userDoc["UserType"];

          // Save login state
          var pref = await SharedPreferences.getInstance();
          await pref.setBool(SplashScreen.KEYLOGINVALUE, true);
          await pref.setString(SplashScreen.KEYUSERROLE, role);

          // Navigate to user home page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => UserHomePage()),
                (Route<dynamic> route) => false,
          );
          return;
        }

        // Check in company_data collection
        DocumentSnapshot companyDoc = await FirebaseFirestore.instance.collection("Company_Data").doc(userId).get();

        if (companyDoc.exists) {
          String role = companyDoc["UserType"];

          // Save login state
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool(SplashScreen.KEYLOGINVALUE, true);
          prefs.setString(SplashScreen.KEYUSERROLE, "Company");
          // Navigate to company home page
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => CompanyHomePage()),
                (Route<dynamic> route) => false,
          );
          return;
        }

        // If neither collection has the data
        ShowAlert.showAlertDialog(context, "User data not found!");
      } catch (e) {
        ShowAlert.showAlertDialog(context, "Error: ${e.toString()}");
      } finally {
        setState(() {
          isLoading = false; // Hide loading indicator
        });
      }
    } else {
      ShowAlert.showAlertDialog(context, "Please enter required information");
    }
  }

  void togglePasswordView() {
    setState(() {
      viewPassword = !viewPassword;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [
              Colors.lightBlueAccent,
              Colors.blue
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            const Padding(
              padding: EdgeInsets.only(left: 21.0),
              child: Text(
                "Sign In",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Montserrat',
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 21.0),
              child: Text(
                "Welcome Back! Sign in to continue.",
                style: TextStyle(fontSize: 24, color: Colors.white,),
              ),
            ),
            Center(
              child: Image.asset(
                "assets/images/Login.png",
                width: 200,
                height: 200,
              ),
            ),
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
                  padding: const EdgeInsets.all(21.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Input(
                          controller: emailController,
                          hint: "Enter Email ID",
                          icon: const Icon(Icons.mail),
                          input_type: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),
                        input_field_password(
                          controller: passwordController,
                          hint: "Enter Password",
                          hide: viewPassword,
                          toggleView: togglePasswordView,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Forgetpassword(),
                                ),
                              );
                            },
                            child: const Text("Forget Password?"),
                          ),
                        ),
                        // Sign In Button with loading indicator
                        isLoading
                            ? CircularProgressIndicator()
                            : ElevatedButton(
                          onPressed: () {
                            signin(
                              emailController.text.trim(),
                              passwordController.text.trim(),
                            );
                          },
                          child: const Text(
                            "Sign In",
                            style: TextStyle(fontSize: 20),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(90, 20),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 70,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 19),
                        SignUpPageDivider(text: 'Or Sign In With'),
                        const SizedBox(height: 19),
                        const SignUpPageIconButtons(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("New user? Create an account "),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RoleSelectionPage(),
                                  ),
                                );
                              },
                              child: const Text("Sign Up"),
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
    );
  }

  Widget input_field_password({
    required TextEditingController controller,
    required String hint,
    required bool hide,
    required VoidCallback toggleView,
  }) {
    return TextField(
      controller: controller,
      obscureText: hide,
      decoration: InputDecoration(
        fillColor: Colors.grey.shade200,
        filled: true,
        hintText: hint,
        suffixIcon: IconButton(
          icon: Icon(
            hide ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: toggleView,
        ),
        prefixIcon: const Icon(
          Icons.password,
          color: Colors.black,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(55),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(55),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
    );
  }
}
