import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:job_flow_project/UserSide/apllicants-historypage.dart';
import 'AppliedJobsPage.dart';
import 'HomePage.dart';
import 'ProfilePage.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userName;
  String? userEmail;
  int _selectedIndex = 0;
  User? user =FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  // Fetch user details from Firestore
  Future<void> fetchUserData() async {
    if (user != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection("User_Data").doc(user!.uid).get();
      setState(() {
        userName = userDoc["Name"];
        userEmail = userDoc["Email"];
      });
    }
  }

  // Pages for bottom navigation
  final List<Widget> _pages = [
    HomePageContent(), // Home Page Content
    ApplicantHistoryPage(userId: FirebaseAuth.instance.currentUser!.uid), // Applied Jobs Page
    ProfilePage(),     // Profile Page

  ];

  // Function to update the selected index
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Dynamically show content
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: "Application History",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), // Fixed Profile icon
            label: "Profile",
          ),
        ],
      ),
    );
  }
}

// Extracted Home Page Content

