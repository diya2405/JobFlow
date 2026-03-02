import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:job_flow_project/CompanySide/CompanyHomePage.dart';
import 'package:job_flow_project/WelcomePages/Onbording_Screen.dart';
import 'package:job_flow_project/UserSide/MainScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Authentication/Login.dart';

class SplashScreen extends StatefulWidget {
  static const String KEYLOGINVALUE = "Login";
  static const String KEYUSERROLE = "UserRole"; // Key to store role

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WhereToGo();
  }

  void WhereToGo() async {
    var pref = await SharedPreferences.getInstance();
    var isLogedIn = pref.getBool(SplashScreen.KEYLOGINVALUE) ?? false;
    var userRole = pref.getString(SplashScreen.KEYUSERROLE) ?? ""; // Default role is "User"

    log("Is user logged in? $isLogedIn");
    log("User Role: $userRole");

    Timer(const Duration(seconds: 2), () {
      if (isLogedIn) {
        if (userRole == "User") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => UserHomePage()), // User dashboard
          );
        } else if (userRole == "Company") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => CompanyHomePage()), // Company dashboard
          );
        }
          else {
          Navigator.pushReplacement(context , MaterialPageRoute(builder: (context) => Login_Page()));
        }
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingScreen()), // First-time users
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue, // Change as per your theme
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/img2.png', height: 170, width: 250), // Add your logo
            SizedBox(height: 50),
            CircularProgressIndicator(color: Colors.white), // Loading indicator
          ],
        ),
      ),
    );
  }
}
