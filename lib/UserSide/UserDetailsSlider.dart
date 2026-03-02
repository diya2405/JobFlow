import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:job_flow_project/UserSide/MainScreen.dart';

class UserDetailsSlider extends StatefulWidget {
  @override
  _UserDetailsSliderState createState() => _UserDetailsSliderState();
}

class _UserDetailsSliderState extends State<UserDetailsSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  TextEditingController locationController = TextEditingController();
  TextEditingController educationController = TextEditingController();
  TextEditingController skillsController = TextEditingController();
  TextEditingController skillSearchController = TextEditingController();

  File? resumeFile;
  String? resumeUrl;
  String? userName;
  bool isUploading = false;

  // Predefined options
  final List<String> popularSkills = [
    'Flutter',
    'Dart',
    'Python',
    'Java',
    'JavaScript',
    'TypeScript',
    'React',
    'React Native',
    'Node.js',
    'Express.js',
    'Angular',
    'Vue.js',
    'Firebase',
    'AWS',
    'Google Cloud',
    'Azure',
    'Docker',
    'Kubernetes',
    'UI/UX Design',
    'Figma',
    'Adobe XD',
    'GraphQL',
    'REST API',
    'MongoDB',
    'PostgreSQL',
    'MySQL',
    'SQL',
    'Git',
    'GitHub',
    'CI/CD',
    'Jenkins',
    'TensorFlow',
    'Machine Learning',
    'Data Science',
    'Android',
    'iOS',
    'Swift',
    'Kotlin',
    'C++',
    'C#',
    '.NET',
    'PHP',
    'Laravel',
    'Ruby',
    'Rails',
    'Go',
    'Rust',
    'SwiftUI',
    'Jetpack Compose',
    'Redux',
    'MobX',
    'Bloc',
    'Provider',
    'GetX',
    'Svelte',
    'Next.js',
    'Nuxt.js',
    'Django',
    'Flask',
    'Spring Boot',
    'Hibernate',
    'JPA',
    'Microservices',
    'Blockchain',
    'Solidity',
    'Web3',
    'Ethereum',
    'Smart Contracts',
    'NFT',
    'Cryptography',
    'Cybersecurity',
    'Penetration Testing',
    'Ethical Hacking',
    'Linux',
    'Bash Scripting',
    'DevOps',
    'Terraform',
    'Ansible',
    'Nginx',
    'Apache',
    'Webpack',
    'Babel',
    'ESLint',
    'Jest',
    'Mocha',
    'Chai',
    'Cypress',
    'Selenium',
    'JIRA',
    'Agile',
    'Scrum',
    'Kanban',
    'Project Management',
    'Product Management',
    'Technical Writing',
    'Documentation',
    'Teaching',
    'Mentoring',
    'Leadership',
    'Team Management',
    'Communication',
    'Public Speaking'
  ];

  final List<String> educationLevels = [
    'High School',
    'Associate Degree',
    'Bachelor\'s Degree',
    'Master\'s Degree',
    'PhD',
    'Other'
  ];

  final List<String> popularLocations = [
    "Mumbai",
    "Delhi",
    "Bangalore",
    "Hyderabad",
    "Ahmedabad",
    "Chennai",
    "Kolkata",
    "Pune",
    "Jaipur",
    "Surat",
    "Lucknow",
    "Kanpur",
    "Nagpur",
    "Indore",
    "Thane",
    "Bhopal",
    "Visakhapatnam",
    "Patna",
    "Vadodara",
    "Ghaziabad",
    "Ludhiana",
    "Agra",
    "Nashik",
    "Faridabad",
    "Meerut",
    "Rajkot",
    "Kalyan-Dombivli",
    "Vasai-Virar",
    "Varanasi",
    "Srinagar",
    "Aurangabad",
    "Dhanbad",
    "Amritsar",
    "Navi Mumbai",
    "Allahabad",
    "Howrah",
    "Gwalior",
    "Jabalpur",
    "Coimbatore",
    "Vijayawada",
    "Jodhpur",
    "Madurai",
    "Raipur",
    "Kota",
    "Guwahati",
    "Chandigarh",
    "Solapur",
    "Hubli–Dharwad",
    "Mysore",
    "Tiruchirappalli",
    "Bareilly",
    "Aligarh",
    "Tiruppur",
    "Moradabad",
    "Jalandhar",
    "Bhubaneswar",
    "Salem",
    "Warangal",
    "Guntur",
    "Bhiwandi",
    "Saharanpur",
    "Gorakhpur",
    "Bikaner",
    "Amravati",
    "Noida",
    "Jamshedpur",
    "Bhilai",
    "Cuttack",
    "Firozabad",
    "Kochi",
    "Nellore",
    "Bhavnagar",
    "Dehradun",
    "Durgapur",
    "Asansol",
    "Rourkela",
    "Nanded",
    "Kolhapur",
    "Ajmer",
    "Akola",
    "Gulbarga",
    "Jamnagar",
    "Ujjain",
    "Loni",
    "Siliguri",
    "Jhansi",
    "Ulhasnagar",
    "Jammu",
    "Sangli",
    "Mangalore",
    "Erode",
    "Belgaum",
    "Kurnool",
    "Ambattur",
    "Tirunelveli",
    "New York",
    "London",
    "Tokyo",
    "Paris",
    "Dubai",
    "Singapore",
    "Sydney",
    "Toronto",
    "Berlin",
    "San Francisco",
    "Los Angeles",
    "Chicago",
    "Houston",
    "Seattle",
    "Boston",
    "Austin",
    "Washington DC",
    "Miami",
    "Atlanta",
    "Denver"
  ];

  List<String> selectedSkills = [];
  List<String> filteredSkills = [];
  List<String> filteredLocations = [];

  @override
  void initState() {
    super.initState();
    fetchUserName();
    filteredSkills = List.from(popularSkills);
    filteredLocations = List.from(popularLocations);

    skillSearchController.addListener(() {
      filterSkills();
    });
  }

  void filterSkills() {
    setState(() {
      if (skillSearchController.text.isEmpty) {
        filteredSkills = List.from(popularSkills);
      } else {
        filteredSkills = popularSkills
            .where((skill) => skill
                .toLowerCase()
                .contains(skillSearchController.text.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    skillSearchController.dispose();
    super.dispose();
  }

  Future<void> fetchUserName() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection("User_Data")
          .doc(user.uid)
          .get();
      setState(() {
        userName = userDoc.exists ? userDoc["Name"] : "User";
      });
    }
  }

  void _goToNextPage() {
    bool isValid = false;

    switch (_currentPage) {
      case 0:
        isValid = locationController.text.isNotEmpty;
        break;
      case 1:
        isValid = educationController.text.isNotEmpty;
        break;
      case 2:
        isValid = selectedSkills.isNotEmpty;
        break;
      case 3:
        isValid = resumeUrl != null && resumeUrl!.isNotEmpty;
        break;
      case 4:
        isValid = true; // Submission page
        break;
    }

    if (isValid) {
      if (_currentPage < 4) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        setState(() {
          _currentPage++;
        });
      } else {
        _submitData();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Please complete this step before proceeding",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _submitData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection("User_Data")
          .doc(user.uid)
          .set(
        {
          "Location": locationController.text,
          "EducationDetails": educationController.text,
          "Skills": selectedSkills,
          "Resume": resumeUrl ?? "",
          "ProfileImage": ""
        },
        SetOptions(merge: true),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => UserHomePage()),
      );
    }
  }

  Future<void> pickAndUploadResume() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        isUploading = true;
        resumeFile = File(result.files.single.path!);
      });

      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && userName != null) {
        String fileName =
            "resumes/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.pdf";
        UploadTask uploadTask =
            FirebaseStorage.instance.ref(fileName).putFile(resumeFile!);

        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          double progress =
              (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
          print("Upload progress: $progress%");
        });

        try {
          TaskSnapshot snapshot = await uploadTask;
          String downloadUrl = await snapshot.ref.getDownloadURL();

          setState(() {
            resumeUrl = downloadUrl;
            isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Resume uploaded successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          setState(() {
            isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to upload resume: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please select a PDF or Word document"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void toggleSkill(String skill) {
    setState(() {
      if (selectedSkills.contains(skill)) {
        selectedSkills.remove(skill);
      } else {
        selectedSkills.add(skill);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Complete Your Profile"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildLocationPage(),
                  _buildEducationPage(),
                  _buildSkillsPage(),
                  _buildResumeUploadPage(),
                  _buildSubmitPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _currentPage > 0
          ? FloatingActionButton(
              onPressed: () {
                _pageController.previousPage(
                  duration: Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
                setState(() {
                  _currentPage--;
                });
              },
              backgroundColor: Colors.blueAccent,
              child: Icon(Icons.arrow_back, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 30),
      child: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentPage + 1) / 5,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            minHeight: 8,
          ),
          SizedBox(height: 8),
          Text(
            "Step ${_currentPage + 1} of 5",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Where are you based?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "This helps us show you relevant opportunities",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          Autocomplete<String>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return const Iterable<String>.empty();
              }
              return popularLocations.where((location) => location
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()));
            },
            onSelected: (String selection) {
              setState(() {
                locationController.text = selection;
              });
            },
            fieldViewBuilder:
                (context, controller, focusNode, onFieldSubmitted) {
              return TextField(
                controller: controller..text = locationController.text,
                focusNode: focusNode,
                decoration: InputDecoration(
                  hintText: "Search for a location",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: locationController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              locationController.clear();
                              controller.clear();
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    locationController.text = value;
                  });
                },
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4.0,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (BuildContext context, int index) {
                        final String option = options.elementAt(index);
                        return InkWell(
                          onTap: () {
                            onSelected(option);
                          },
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: Text(option),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          Text(
            "Popular Locations",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          SizedBox(
            height: 380, // Fixed height to prevent overflow
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: popularLocations
                    .map((location) => FilterChip(
                          label: Text(location),
                          selected: locationController.text == location,
                          onSelected: (bool selected) {
                            setState(() {
                              locationController.text =
                                  selected ? location : "";
                            });
                          },
                        ))
                    .toList(),
              ),
            ),
          ),
          Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: _goToNextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text("Next", style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEducationPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Education",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Tell us about your highest education level",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: "Education Level",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school),
            ),
            items: educationLevels.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                educationController.text = newValue!;
              });
            },
          ),
          SizedBox(height: 16),
          TextField(
            controller: educationController,
            decoration: InputDecoration(
              labelText: "Additional Details (Optional)",
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: _goToNextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text("Next", style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSkillsPage() {
    return LayoutBuilder(
      builder: (context, constraints) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                "Select Your Skills",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                "Choose skills that match your expertise",
                style: TextStyle(color: Colors.grey),
              ),
              SizedBox(height: 20),

              // Search Field
              TextField(
                controller: skillSearchController,
                decoration: InputDecoration(
                  hintText: "Search skills...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    filteredSkills = popularSkills.where((skill) =>
                        skill.toLowerCase().contains(value.toLowerCase())
                    ).toList();
                  });
                },
              ),
              SizedBox(height: 20),

              // Selected Skills
              if (selectedSkills.isNotEmpty) ...[
                Text("Selected Skills:", style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: selectedSkills.map((skill) => Chip(
                    label: Text(skill),
                    deleteIcon: Icon(Icons.close, size: 18),
                    onDeleted: () => toggleSkill(skill),
                    backgroundColor: Colors.blue[50],
                  )).toList(),
                ),
                SizedBox(height: 20),
              ],

              // Available Skills - Fixed Section
              Text("Available Skills (${filteredSkills.length})",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                constraints: BoxConstraints(
                  minHeight: 200,
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: filteredSkills.isEmpty
                    ? Center(child: Text("No skills found"))
                    : SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: filteredSkills.map((skill) => FilterChip(
                        label: Text(skill),
                        selected: selectedSkills.contains(skill),
                        onSelected: (selected) => toggleSkill(skill),
                        selectedColor: Colors.blue[100],
                        checkmarkColor: Colors.blue,
                      )).toList(),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Continue Button
              Align(
                alignment: Alignment.bottomRight,
                child: ElevatedButton(
                  onPressed: _goToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text("Next", style: TextStyle(fontSize: 16)),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildResumeUploadPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Upload Your Resume",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Help employers discover your qualifications",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.insert_drive_file,
                        size: 60, color: Colors.blueAccent),
                    SizedBox(height: 16),
                    if (resumeUrl == null) ...[
                      Text(
                        "Upload your resume (PDF or Word)",
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: isUploading ? null : pickAndUploadResume,
                        icon: Icon(Icons.cloud_upload),
                        label: Text("Select File"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ] else ...[
                      Text(
                        "Resume Uploaded Successfully!",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        resumeFile?.path.split('/').last ?? "resume.pdf",
                        style: TextStyle(fontSize: 14),
                      ),
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: pickAndUploadResume,
                        icon: Icon(Icons.refresh),
                        label: Text("Replace Resume"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                    if (isUploading) ...[
                      SizedBox(height: 16),
                      LinearProgressIndicator(),
                      SizedBox(height: 8),
                      Text("Uploading...",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: _goToNextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text("Next", style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSubmitPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Review Your Profile",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            "Please review your information before submitting",
            style: TextStyle(color: Colors.grey.shade600),
          ),
          SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailItem(Icons.location_on, "Location",
                          locationController.text),
                      Divider(),
                      _buildDetailItem(
                          Icons.school, "Education", educationController.text),
                      Divider(),
                      _buildDetailItem(
                          Icons.star, "Skills", selectedSkills.join(", ")),
                      Divider(),
                      _buildDetailItem(
                        Icons.insert_drive_file,
                        "Resume",
                        resumeUrl != null ? "Uploaded" : "Not uploaded",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text("Complete Profile", style: TextStyle(fontSize: 16)),
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              _pageController.animateToPage(
                0,
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
              setState(() {
                _currentPage = 0;
              });
            },
            child: Text("Edit Information"),
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: Colors.blueAccent),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : "Not provided",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
