import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:job_flow_project/CompanySide/CompanyHomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../UserSide/MainScreen.dart';
import '../WelcomePages/SplashScreen.dart';
import '../Widgets/Input.dart';
import '../Widgets/ShowAlert.dart';
import 'Login.dart';

class CompanySignup extends StatefulWidget {
  const CompanySignup({super.key});

  @override
  State<CompanySignup> createState() => _CompanySignupState();
}

class _CompanySignupState extends State<CompanySignup> {
  final TextEditingController companyNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController contactController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  bool viewPassword1 = true;
  bool viewPassword2 = true;

  // Toggle the visibility of passwords
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
    String companyName = companyNameController.text.trim();
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPass = confirmPasswordController.text.trim();
    String location = locationController.text.trim();
    String contact = contactController.text.trim();
    String website = websiteController.text.trim();

    if (_validateFields(companyName, email, password, confirmPass, location, contact, website)) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        await userCredential.user!.sendEmailVerification();
        ShowAlert.showAlertDialog(context, "A verification email has been sent. Please check your inbox.");

        bool isVerified = await _waitForEmailVerification(userCredential.user!);
        if (isVerified) {
          await _saveCompanyData(userCredential.user!.uid, companyName, email, location, contact, website);
        } else {
          ShowAlert.showAlertDialog(context, "Email not verified. Please verify before logging in.");
        }
      } catch (e) {
        ShowAlert.showAlertDialog(context, "Error: ${e.toString()}");
      }
    }
  }

  // Validate input fields
  bool _validateFields(String companyName, String email, String password, String confirmPass, String location, String contact, String website) {
    if (companyName.isEmpty || email.isEmpty || password.isEmpty || confirmPass.isEmpty ||
        location.isEmpty || contact.isEmpty || website.isEmpty) {
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

  // Save company data to Firestore
  Future<void> _saveCompanyData(String uid, String companyName, String email, String location, String contact, String website) async {
    try {
      await FirebaseFirestore.instance.collection("Company_Data").doc(uid).set({
        "CompanyName": companyName,
        "Email": email,
        "Location": location,
        "Contact": contact,
        "Website": website,
        "UserType": "Company",
        "logoUrl": "",
        "company_description": "",
        "UID": uid,
      });

      var pref = await SharedPreferences.getInstance();
      await pref.setBool(SplashScreen.KEYLOGINVALUE, true);
      pref.setString(SplashScreen.KEYUSERROLE, "Company");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => CompanyHomePage()),
            (route) => false,
      );
    } catch (e) {
      ShowAlert.showAlertDialog(context, "Error saving company data: ${e.toString()}");
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
                  "Company Sign Up",
                  style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 21.0),
                child: Text("Register your company.", style: TextStyle(fontSize: 25, color: Colors.white)),
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
                          Input(controller: companyNameController, hint: "Enter Company Name", icon: const Icon(Icons.business), input_type: TextInputType.text),
                          const SizedBox(height: 20),
                          Input(controller: emailController, hint: "Enter Email", icon: const Icon(Icons.mail), input_type: TextInputType.emailAddress),
                          const SizedBox(height: 20),
                          Input(controller: locationController, hint: "Enter Location", icon: const Icon(Icons.location_city), input_type: TextInputType.text),
                          const SizedBox(height: 20),
                          Input(controller: contactController, hint: "Enter Contact Number", icon: const Icon(Icons.phone), input_type: TextInputType.phone),
                          const SizedBox(height: 20),
                          Input(controller: websiteController, hint: "Enter Website URL", icon: const Icon(Icons.web), input_type: TextInputType.url),
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
        prefixIcon: Icon(
          Icons.password,
          color: Colors.black,
        ),
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
