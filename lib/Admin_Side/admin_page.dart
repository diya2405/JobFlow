import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:job_flow_project/Admin_Side/pdfgenerateui.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(AdminApp());
}

class AdminApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JobFlow Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AdminLoginPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AdminLoginPage extends StatefulWidget {
  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  final List<String> adminEmails = [
    "diyashah2405@gmail.com",
  ]; // Add more admin emails as needed

  @override
  void initState() {
    super.initState();
  }

  Future<void> loginAdmin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: emailController.text.trim(),
              password: passwordController.text.trim());

      // Check if email is in admin list
      if (adminEmails.contains(emailController.text.trim())) {
        // Save login state
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AdminDashboard()),
        );
      } else {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Access Denied: Not an admin email.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = "Login Failed";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login Failed: ${e.toString()}")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade800, Colors.blue.shade400],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(Icons.admin_panel_settings,
                            size: 72, color: Colors.blue),
                      ),
                      SizedBox(height: 24),
                      Text("JobFlow Admin Panel",
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      SizedBox(height: 32),
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextFormField(
                                controller: emailController,
                                decoration: InputDecoration(
                                  labelText: "Email",
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                controller: passwordController,
                                decoration: InputDecoration(
                                  labelText: "Password",
                                  prefixIcon: Icon(Icons.lock),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  suffixIcon: IconButton(
                                    icon: Icon(obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () {
                                      setState(() =>
                                          obscurePassword = !obscurePassword);
                                    },
                                  ),
                                ),
                                obscureText: obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: loading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: Colors.white))
                            : ElevatedButton(
                                onPressed: loginAdmin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.blue.shade800,
                                  elevation: 5,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.all(16),
                                ),
                                child: Text("LOGIN",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade800,
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              weight: 500,
            ),
            color: Colors.white,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => AdminLoginPage()),
              );
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.grey.shade100, Colors.grey.shade300],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 600 ? 3 : 1,
                  childAspectRatio: 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 16,
                  children: [
                    AdminCard(
                      title: "Manage Users",
                      icon: Icons.people,
                      color: Colors.blue.shade800,
                      page: ManageUsersPage(),
                    ),
                    AdminCard(
                      title: "Manage Jobs",
                      icon: Icons.work,
                      color: Colors.green.shade700,
                      page: ManageJobsPage(),
                    ),
                    AdminCard(
                      title: "Manage Companies",
                      icon: Icons.business,
                      color: Colors.orange.shade700,
                      page: ManageCompanyPage(),
                    ),
                    AdminCard(
                      title: "Generate Reports",
                      icon: Icons.picture_as_pdf,
                      color: Colors.red.shade700,
                      page: AdminPdfGeneratorPage(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;

  AdminCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => page),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 52, color: color),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ManageCompanyPage extends StatefulWidget {
  @override
  _ManageCompanyPageState createState() => _ManageCompanyPageState();
}

class _ManageCompanyPageState extends State<ManageCompanyPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Companies"),
        centerTitle: true,
        backgroundColor: Colors.orange.shade700,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showAddCompanyDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: "Search companies",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Company_Data')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No companies found."));
                }

                var companies = snapshot.data!.docs.where((doc) {
                  final company = doc.data() as Map<String, dynamic>;
                  final name =
                      company['CompanyName']?.toString().toLowerCase() ?? '';
                  final email =
                      company['Email']?.toString().toLowerCase() ?? '';
                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery);
                }).toList();

                if (companies.isEmpty) {
                  return Center(child: Text("No matching companies found."));
                }

                return ListView.builder(
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    var company = companies[index];
                    var companyData = company.data() as Map<String, dynamic>;
                    return _buildCompanyCard(context, company.id, companyData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(BuildContext context, String companyId,
      Map<String, dynamic> companyData) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading:
            companyData['logoUrl'] != null && companyData['logoUrl'].isNotEmpty
                ? CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(companyData['logoUrl']),
                  )
                : CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(Icons.business, size: 30, color: Colors.orange),
                  ),
        title: Text(
          companyData['CompanyName'] ?? 'No Name',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(companyData['Email'] ?? 'No Email'),
            SizedBox(height: 4),
            Text(companyData['Location'] ?? 'No Location'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text("Edit"),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Delete"),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              _showEditCompanyDialog(context, companyId, companyData);
            } else if (value == 'delete') {
              await _confirmDeleteCompany(context, companyId);
            }
          },
        ),
        onTap: () {
          _showCompanyDetails(context, companyData);
        },
      ),
    );
  }

  Future<void> _showAddCompanyDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final locationController = TextEditingController();
    final websiteController = TextEditingController();
    final contactController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Add New Company"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Company Name"),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty || !value.contains('@')
                      ? 'Invalid email'
                      : null,
                ),
                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: "Location"),
                ),
                TextFormField(
                  controller: websiteController,
                  decoration: InputDecoration(labelText: "Website"),
                  keyboardType: TextInputType.url,
                ),
                TextFormField(
                  controller: contactController,
                  decoration: InputDecoration(labelText: "Contact Number"),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  setState(() => _isLoading = true);
                  await FirebaseFirestore.instance
                      .collection('Company_Data')
                      .add({
                    'CompanyName': nameController.text,
                    'Email': emailController.text,
                    'Location': locationController.text,
                    'Website': websiteController.text,
                    'Contact': contactController.text,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Company added successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error adding company: $e")),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: Text("Add Company"),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditCompanyDialog(BuildContext context, String companyId,
      Map<String, dynamic> companyData) async {
    final formKey = GlobalKey<FormState>();
    final nameController =
        TextEditingController(text: companyData['CompanyName']);
    final emailController = TextEditingController(text: companyData['Email']);
    final locationController =
        TextEditingController(text: companyData['Location']);
    final websiteController =
        TextEditingController(text: companyData['Website']);
    final contactController =
        TextEditingController(text: companyData['Contact']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Company"),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: "Company Name"),
                  validator: (value) => value!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(labelText: "Email"),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty || !value.contains('@')
                      ? 'Invalid email'
                      : null,
                ),
                TextFormField(
                  controller: locationController,
                  decoration: InputDecoration(labelText: "Location"),
                ),
                TextFormField(
                  controller: websiteController,
                  decoration: InputDecoration(labelText: "Website"),
                  keyboardType: TextInputType.url,
                ),
                TextFormField(
                  controller: contactController,
                  decoration: InputDecoration(labelText: "Contact Number"),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  setState(() => _isLoading = true);
                  await FirebaseFirestore.instance
                      .collection('Company_Data')
                      .doc(companyId)
                      .update({
                    'CompanyName': nameController.text,
                    'Email': emailController.text,
                    'Location': locationController.text,
                    'Website': websiteController.text,
                    'Contact': contactController.text,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Company updated successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error updating company: $e")),
                  );
                } finally {
                  setState(() => _isLoading = false);
                }
              }
            },
            child: Text("Save Changes"),
          ),
        ],
      ),
    );
  }

  Future<void> _showCompanyDetails(
      BuildContext context, Map<String, dynamic> companyData) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(companyData['CompanyName'] ?? 'Company Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (companyData['logoUrl'] != null &&
                  companyData['logoUrl'].isNotEmpty)
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(companyData['logoUrl']),
                  ),
                ),
              SizedBox(height: 16),
              _buildDetailItem("Email", companyData['Email']),
              _buildDetailItem("Location", companyData['Location']),
              _buildDetailItem("Website", companyData['Website']),
              _buildDetailItem("Contact", companyData['Contact']),
              _buildDetailItem(
                  "Description", companyData['company_description']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value ?? 'Not provided'),
          Divider(),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteCompany(
      BuildContext context, String companyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text(
            "Are you sure you want to delete this company? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        setState(() => _isLoading = true);
        await FirebaseFirestore.instance
            .collection('Company_Data')
            .doc(companyId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Company deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting company: $e")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}

class AdminNotificationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Send Notifications"),
        backgroundColor: Colors.purple.shade700,
      ),
      body: Center(child: Text("Notifications Page")),
    );
  }
}

class AdminSettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("System Settings"),
        backgroundColor: Colors.teal.shade700,
      ),
      body: Center(child: Text("Settings Page")),
    );
  }
}

class ManageUsersPage extends StatefulWidget {
  @override
  _ManageUsersPageState createState() => _ManageUsersPageState();
}

class _ManageUsersPageState extends State<ManageUsersPage> {
  final searchController = TextEditingController();
  String searchQuery = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Manage Users"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: "Search users",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchQuery = '');
                  },
                )
                    : null,
              ),
              onChanged: (value) =>
                  setState(() => searchQuery = value.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('User_Data')
                  .orderBy('Name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text("No users found."));
                }

                var users = snapshot.data!.docs.where((doc) {
                  final user = doc.data() as Map<String, dynamic>;
                  final name = user['Name']?.toString().toLowerCase() ?? '';
                  final email = user['Email']?.toString().toLowerCase() ?? '';
                  return name.contains(searchQuery) ||
                      email.contains(searchQuery);
                }).toList();

                if (users.isEmpty) {
                  return Center(child: Text("No matching users found."));
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    var user = users[index];
                    var userData = user.data() as Map<String, dynamic>;

                    // Handle both string and list formats for skills
                    List<String> skills = [];
                    if (userData['Skills'] != null) {
                      if (userData['Skills'] is String) {
                        // Handle string format (comma-separated or single skill)
                        String skillsString = userData['Skills'] as String;
                        skills = skillsString.split(',')
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty)
                            .toList();
                      } else if (userData['Skills'] is List) {
                        // Handle list format
                        skills = List<String>.from(userData['Skills']);
                      }
                    }

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: userData['ProfileImage'] != null &&
                              userData['ProfileImage'] != '-' &&
                              userData['ProfileImage'].isNotEmpty
                              ? ClipOval(
                            child: Image.network(
                              userData['ProfileImage'],
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.person,
                                    color: Colors.blue);
                              },
                            ),
                          )
                              : Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(userData['Name'] ?? 'No Name'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(userData['Email'] ?? 'No Email'),
                            if (skills.isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Wrap(
                                  spacing: 4,
                                  children: skills
                                      .map((skill) => Chip(
                                    label: Text(skill),
                                    backgroundColor: Colors.grey[200],
                                    labelStyle: TextStyle(fontSize: 12),
                                  ))
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'view',
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text("View Details"),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Delete User"),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'view') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      UserDetailPage(userId: user.id),
                                ),
                              );
                            } else if (value == 'delete') {
                              await _confirmDeleteUser(context, user);
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UserDetailPage(userId: user.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteUser(
      BuildContext context, DocumentSnapshot user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirm Delete"),
        content: Text(
            "Are you sure you want to permanently delete user \"${user['Name']}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('User_Data')
            .doc(user.id)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User deleted successfully.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting user: ${e.toString()}")),
        );
      }
    }
  }
}

class UserDetailPage extends StatefulWidget {
  final String userId;

  const UserDetailPage({required this.userId});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  @override
  Widget build(BuildContext context) {
    final userDoc =
        FirebaseFirestore.instance.collection('User_Data').doc(widget.userId);

    return Scaffold(
      appBar: AppBar(
        title: Text("User Details"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: userDoc.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("User not found."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final resumeUrl = userData['Resume'];
          final profileImage = userData['ProfileImage'];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (profileImage != null &&
                    profileImage != '-' &&
                    profileImage.isNotEmpty)
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: NetworkImage(profileImage),
                    ),
                  ),
                SizedBox(height: 16),
                _buildDetailCard(
                  title: "Personal Information",
                  children: [
                    _buildDetailItem("Name", userData['Name']),
                    _buildDetailItem("Email", userData['Email']),
                    _buildDetailItem("Phone",
                        userData['Phone']?.toString() ?? 'Not provided'),
                    _buildDetailItem("Location", userData['Location']),
                    _buildDetailItem("User Type", userData['UserType']),
                  ],
                ),
                SizedBox(height: 16),
                _buildDetailCard(
                  title: "Professional Details",
                  children: [
                    if (userData['EducationDetails'] != null)
                      _buildDetailItem(
                        "Education",
                        userData['EducationDetails'] is Map
                            ? (userData['EducationDetails'] as Map)['degree'] ??
                                'Not specified'
                            : 'Not specified',
                      ),
                    if (userData['Skills'] != null)
                      _buildDetailItem(
                        "Skills",
                        userData['Skills'] is String
                            ? userData['Skills']
                            : 'Not specified',
                      ),
                    if (resumeUrl != null && resumeUrl.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.description),
                          label: Text("View Resume"),
                          onPressed: () async {
                            final url = userData['Resume']?.toString() ?? '';
                            if (url.isEmpty) {
                              _showAlert("No resume uploaded.");
                              return;
                            }

                            try {
                              final uri = Uri.parse(url);
                              if (!await launchUrl(uri,
                                  mode: LaunchMode.externalApplication)) {
                                _showAlert("Could not open resume.");
                              }
                            } catch (e) {
                              _showAlert("Error: ${e.toString()}");
                            }
                          },
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                _buildDetailCard(
                  title: "Job Matches",
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: userDoc.collection('JobMatches').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }

                        final docs = snapshot.data!.docs;

                        final selectedMatches = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['selectionStatus']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';
                          return status == 'selected';
                        }).toList();

                        final rejectedMatches = docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final status = data['selectionStatus']
                                  ?.toString()
                                  .toLowerCase() ??
                              '';
                          return status == 'rejected' || status == 'declined';
                        }).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Selected Matches",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            selectedMatches.isEmpty
                                ? _buildDetailItem(
                                    "Status", "No selected job matches.")
                                : _buildMatchList(
                                    selectedMatches, widget.userId),
                            SizedBox(height: 16),
                            Text("Rejected/Declined Matches",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            rejectedMatches.isEmpty
                                ? _buildDetailItem("Status",
                                    "No rejected or declined job matches.")
                                : _buildMatchList(
                                    rejectedMatches, widget.userId),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAlert(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(List<QueryDocumentSnapshot> matches, String userId) {
    return Column(
      children: matches.map((match) {
        final matchData = match.data() as Map<String, dynamic>;
        final jobId = matchData['JobID'] ?? match.id;

        return Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('Job_Posts')
                .doc(jobId)
                .get(),
            builder: (context, jobSnapshot) {
              if (!jobSnapshot.hasData || !jobSnapshot.data!.exists) {
                return Text("Job not found.");
              }

              final jobData = jobSnapshot.data!.data() as Map<String, dynamic>?;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.work, size: 20),
                title: Text(jobData?['title'] ?? 'Unknown Job',
                    style: TextStyle(fontSize: 14)),
                subtitle: Text(
                    "Match Score: ${matchData['MatchScore'] ?? 'N/A'}",
                    style: TextStyle(fontSize: 12)),
                trailing: Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          JobDetailPage(jobId: jobId, fromUser: userId),
                    ),
                  );
                },
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetailCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, dynamic value) {
    // Handle skills specifically
    if (label == "Skills" && value != null) {
      List<String> skillsList = [];
      if (value is String) {
        // Old format
        skillsList = value.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      } else if (value is List) {
        // New format
        skillsList = List<String>.from(value);
      }

      return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600])),
            if (skillsList.isNotEmpty)
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: skillsList
                    .map((skill) => Chip(
                  label: Text(skill),
                  backgroundColor: Colors.blue[100],
                  labelStyle: TextStyle(fontSize: 12),
                ))
                    .toList(),
              )
            else
              Text("No skills specified", style: TextStyle(fontSize: 16)),
            Divider(),
          ],
        ),
      );
    }

    // Default handling for other fields
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600])),
          Text(value?.toString() ?? 'Not provided',
              style: TextStyle(fontSize: 16)),
          Divider(),
        ],
      ),
    );
  }
}

class JobDetailPage extends StatelessWidget {
  final String jobId;
  final String? fromUser;

  const JobDetailPage({required this.jobId, this.fromUser});

  @override
  Widget build(BuildContext context) {
    final jobDoc =
        FirebaseFirestore.instance.collection('Job_Posts').doc(jobId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Job Details"),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: jobDoc.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Job not found."));
          }

          final jobData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Company Header with Logo
                _buildCompanyHeader(jobData),
                const SizedBox(height: 20),

                // Job Info Card
                Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Job Title
                        Text(
                          jobData['title'] ?? "No title specified",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Job Type and Salary
                        Row(
                          children: [
                            _buildInfoChip(
                              icon: Icons.work_outline,
                              text: jobData['jobType'] ?? "Not specified",
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 10),
                            if (jobData['salary'] != null &&
                                jobData['salary'] != "Not specified")
                              _buildInfoChip(
                                icon: Icons.attach_money,
                                text: jobData['salary'],
                                color: Colors.green,
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        // Posted Date
                        if (jobData['timestamp'] != null)
                          _buildDetailItem(
                            "Posted",
                            _formatTimestamp(jobData['timestamp']),
                            icon: Icons.calendar_today,
                          ),

                        // Requirements Section
                        _buildSectionTitle("Requirements"),
                        const SizedBox(height: 8),
                        ..._buildRequirementsList(jobData),
                        const SizedBox(height: 15),

                        // Job Description
                        _buildSectionTitle("Job Description"),
                        const SizedBox(height: 8),
                        Text(
                          jobData['company_description'] ??
                              "No description available",
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Company Contact Info
                _buildContactInfo(jobData),
                const SizedBox(height: 20),

                // Match details if viewing from user context
                if (fromUser != null)
                  _buildUserMatchScore(context, fromUser!, jobId),

                // Action Buttons
                if (fromUser == null) // Only show for company/admin view
                  Column(
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            _showDeleteConfirmation(context, jobId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Delete Job",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SelectionDetailsScreen(
                                jobId: jobId,
                                jobTitle:
                                    jobData['title'] ?? "No title specified",
                              ), // pass jobId here
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "View Selection Details",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyHeader(Map<String, dynamic> jobData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Company Logo
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: jobData['logo_url'] != null && jobData['logo_url'].isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    jobData['logo_url'],
                    fit: BoxFit.contain,
                  ),
                )
              : const Icon(Icons.business, size: 40, color: Colors.blue),
        ),
        const SizedBox(width: 16),

        // Company Name and Location
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                jobData['company_name'] ?? "Company not specified",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    jobData['company_location'] ?? "Location not specified",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(
      {required IconData icon, required String text, required Color color}) {
    return Chip(
      backgroundColor: color.withOpacity(0.1),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.blue),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildRequirementsList(Map<String, dynamic> jobData) {
    if (jobData['requirements'] == null) {
      return [
        const Text("No requirements specified",
            style: TextStyle(color: Colors.grey)),
      ];
    }

    // Handle both string (comma separated) and list formats
    List<String> requirements = [];
    if (jobData['requirements'] is String) {
      requirements = (jobData['requirements'] as String).split(',');
    } else if (jobData['requirements'] is List) {
      requirements = List<String>.from(jobData['requirements']);
    }

    return requirements.map((req) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                req.trim(),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildContactInfo(Map<String, dynamic> jobData) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("Contact Information"),
            const SizedBox(height: 10),

            // Website
            if (jobData['company_website'] != null &&
                jobData['company_website'].isNotEmpty)
              _buildContactTile(
                icon: Icons.link,
                text: jobData['company_website'],
                onTap: () => launchUrl(Uri.parse(jobData['company_website'])),
              ),

            // Email
            if (jobData['company_email'] != null &&
                jobData['company_email'].isNotEmpty)
              _buildContactTile(
                icon: Icons.email,
                text: jobData['company_email'],
                onTap: () =>
                    launchUrl(Uri.parse("mailto:${jobData['company_email']}")),
              ),

            // Phone
            if (jobData['company_contact'] != null &&
                jobData['company_contact'].isNotEmpty)
              _buildContactTile(
                icon: Icons.phone,
                text: jobData['company_contact'],
                onTap: () =>
                    launchUrl(Uri.parse("tel:${jobData['company_contact']}")),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserMatchScore(
      BuildContext context, String userId, String jobId) {
    final matchDoc = FirebaseFirestore.instance
        .collection('User_Data')
        .doc(userId)
        .collection('JobMatches')
        .doc(jobId);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Match Details",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const Divider(),
            StreamBuilder<DocumentSnapshot>(
              stream: matchDoc.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final matchData =
                    snapshot.data!.data() as Map<String, dynamic>?;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      "Match Score",
                      matchData?['MatchScore']?.toString() ?? 'N/A',
                      icon: Icons.score,
                    ),
                    _buildDetailItem(
                      "Status",
                      matchData?['selectionStatus']?.toString() ??
                          'Not specified',
                      icon: Icons.info,
                    ),
                    if (matchData?['matchingDetails'] != null)
                      _buildDetailItem(
                        "Matching Details",
                        matchData?['matchingDetails'],
                        icon: Icons.details,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content:
            const Text("Are you sure you want to delete this job posting?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "DELETE",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteJobEverywhere(jobId);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting job: $e")),
        );
      }
    }
  }

  Future<void> deleteJobEverywhere(String jobId) async {
    final firestore = FirebaseFirestore.instance;

    // Delete from main job collection
    await firestore.collection('Job_Posts').doc(jobId).delete();

    // Delete from all users' JobMatches subcollections
    final usersSnapshot = await firestore.collection('User_Data').get();
    for (final userDoc in usersSnapshot.docs) {
      await userDoc.reference.collection('JobMatches').doc(jobId).delete();
    }

    // Delete any applications for this job
    final applications = await firestore
        .collection('applications')
        .where('jobId', isEqualTo: jobId)
        .get();
    for (final appDoc in applications.docs) {
      await appDoc.reference.delete();
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Date not available";
    if (timestamp is Timestamp) {
      return "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}";
    }
    return timestamp.toString();
  }
}

class SelectionDetailsScreen extends StatefulWidget {
  final String jobId;
  final String jobTitle;

  const SelectionDetailsScreen({
    Key? key,
    required this.jobId,
    required this.jobTitle,
  }) : super(key: key);

  @override
  _SelectionDetailsScreenState createState() => _SelectionDetailsScreenState();
}

class _SelectionDetailsScreenState extends State<SelectionDetailsScreen> {
  late Future<Map<String, List<Map<String, dynamic>>>> _matchedUsersFuture;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _matchedUsersFuture = _fetchMatchedUsers();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchMatchedUsers() async {
    final firestore = FirebaseFirestore.instance;
    final usersSnapshot = await firestore.collection('User_Data').get();

    List<Map<String, dynamic>> selected = [];
    List<Map<String, dynamic>> rejected = [];
    List<Map<String, dynamic>> pending = [];

    for (var userDoc in usersSnapshot.docs) {
      final jobMatchDoc = await firestore
          .collection('User_Data')
          .doc(userDoc.id)
          .collection('JobMatches')
          .doc(widget.jobId)
          .get();

      if (jobMatchDoc.exists) {
        final data = jobMatchDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('selectionStatus')) {
          final userData = userDoc.data() as Map<String, dynamic>;
          userData['userId'] = userDoc.id;
          userData['status'] = data['selectionStatus'];
          userData['matchScore'] = data['MatchScore'] ?? 'N/A';
          userData['resumeUrl'] = data['resumeUrl'] ?? '';

          switch (data['selectionStatus']) {
            case 'selected':
              selected.add(userData);
              break;
            case 'rejected':
              rejected.add(userData);
              break;
            default:
              pending.add(userData);
          }
        }
      }
    }

    // Sort by match score (highest first)
    selected.sort(
        (a, b) => (b['matchScore'] as num).compareTo(a['matchScore'] as num));
    rejected.sort(
        (a, b) => (b['matchScore'] as num).compareTo(a['matchScore'] as num));
    pending.sort(
        (a, b) => (b['matchScore'] as num).compareTo(a['matchScore'] as num));

    return {
      'selected': selected,
      'rejected': rejected,
      'pending': pending,
    };
  }

  void _filterUsers(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<Map<String, dynamic>> _filterList(List<Map<String, dynamic>> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((user) {
      final name = user['Name']?.toString().toLowerCase() ?? '';
      final email = user['Email']?.toString().toLowerCase() ?? '';
      final skills = user['Skills']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery) ||
          email.contains(_searchQuery) ||
          skills.contains(_searchQuery);
    }).toList();
  }

  Future<void> _updateSelectionStatus(String userId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('User_Data')
          .doc(userId)
          .collection('JobMatches')
          .doc(widget.jobId)
          .update({
        'selectionStatus': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _matchedUsersFuture = _fetchMatchedUsers();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Selections for ${widget.jobTitle}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _matchedUsersFuture = _fetchMatchedUsers();
                _searchController.clear();
                _searchQuery = '';
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search candidates',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterUsers('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterUsers,
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: _matchedUsersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData ||
                    (snapshot.data?['selected']?.isEmpty ?? true) &&
                        (snapshot.data?['rejected']?.isEmpty ?? true) &&
                        (snapshot.data?['pending']?.isEmpty ?? true)) {
                  return const Center(child: Text('No matched users found.'));
                }

                final selected = _filterList(snapshot.data!['selected']!);
                final rejected = _filterList(snapshot.data!['rejected']!);
                final pending = _filterList(snapshot.data!['pending']!);

                return DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      const TabBar(
                        tabs: [
                          Tab(text: 'Selected', icon: Icon(Icons.check_circle)),
                          Tab(text: 'Rejected', icon: Icon(Icons.cancel)),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildUserList(selected, 'selected'),
                            _buildUserList(rejected, 'rejected'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<Map<String, dynamic>> users, String statusType) {
    if (users.isEmpty) {
      return Center(
        child: Text(
          statusType == 'selected'
              ? 'No selected candidates'
              : statusType == 'rejected'
                  ? 'No rejected candidates'
                  : 'No pending candidates',
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          elevation: 2,
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                user['Name']?.toString().substring(0, 1) ?? '?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              user['Name'] ?? 'No Name',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user['Email'] ?? 'No Email'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text('Score: ${user['matchScore']}'),
                      backgroundColor: Colors.green.shade50,
                    ),
                    if (user['Skills'] != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          user['Skills'] is String
                              ? user['Skills']
                              : (user['Skills'] as List<dynamic>).join(', '),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              itemBuilder: (context) => [
                if (user['Resume'] != null && user['Resume'].isNotEmpty)
                  const PopupMenuItem(
                    value: 'view_resume',
                    child: ListTile(
                      leading: Icon(Icons.picture_as_pdf),
                      title: Text('View Resume'),
                    ),
                  ),
                if (statusType != 'selected')
                  const PopupMenuItem(
                    value: 'select',
                    child: ListTile(
                      leading: Icon(Icons.check, color: Colors.green),
                      title: Text('Select Candidate'),
                    ),
                  ),
                if (statusType != 'rejected')
                  const PopupMenuItem(
                    value: 'reject',
                    child: ListTile(
                      leading: Icon(Icons.close, color: Colors.red),
                      title: Text('Reject Candidate'),
                    ),
                  ),
                if (statusType != 'pending')
                  const PopupMenuItem(
                    value: 'pending',
                    child: ListTile(
                      leading: Icon(Icons.access_time, color: Colors.orange),
                      title: Text('Mark as Pending'),
                    ),
                  ),
              ],
              onSelected: (value) async {
                if (value == 'view_resume') {
                  if (await canLaunch(user['Resume'])) {
                    await launch(user['Resume']);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Could not open resume')),
                    );
                  }
                } else if (value == 'select') {
                  await _updateSelectionStatus(user['userId'], 'selected');
                } else if (value == 'reject') {
                  await _updateSelectionStatus(user['userId'], 'rejected');
                } else if (value == 'pending') {
                  await _updateSelectionStatus(user['userId'], 'pending');
                }
              },
            ),
            onTap: () {
              _showUserDetails(context, user);
            },
          ),
        );
      },
    );
  }

  void _showUserDetails(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user['Name'] ?? 'User Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (user['ProfileImage'] != null &&
                  user['ProfileImage'].isNotEmpty)
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(user['ProfileImage']),
                  ),
                ),
              const SizedBox(height: 16),
              _buildDetailItem('Email', user['Email']),
              _buildDetailItem('Phone', user['Phone']),
              _buildDetailItem('Location', user['Location']),
              _buildDetailItem('Match Score', user['matchScore'].toString()),
              _buildDetailItem('Status', user['status']),
              if (user['EducationDetails'] != null)
                _buildDetailItem(
                    'Education',
                    user['EducationDetails'] is String
                        ? user['EducationDetails']
                        : (user['EducationDetails']
                                as Map<String, dynamic>)['degree'] ??
                            'Not specified'),
              if (user['Skills'] != null)
                _buildDetailItem(
                  'Skills',
                  user['Skills'] is String
                      ? user['Skills']
                      : (user['Skills'] as List<dynamic>).join(', '),
                ),
              if (user['resumeUrl'] != null && user['resumeUrl'].isNotEmpty)
                TextButton(
                  onPressed: () async {
                    if (await canLaunch(user['resumeUrl'])) {
                      await launch(user['resumeUrl']);
                    }
                  },
                  child: const Text('View Resume'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value ?? 'Not provided'),
          const Divider(),
        ],
      ),
    );
  }
}

class ManageJobsPage extends StatefulWidget {
  @override
  _ManageJobsPageState createState() => _ManageJobsPageState();
}

class _ManageJobsPageState extends State<ManageJobsPage> {
  final searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'all';
  String sortBy = 'newest';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Jobs"),
        backgroundColor: Colors.blue,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // TODO: Implement add job functionality
              // Navigator.push(context, MaterialPageRoute(
              //   builder: (_) => PostJobPage(companyId: currentCompanyId),
              // ));
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Field
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    labelText: "Search jobs",
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              searchController.clear();
                              setState(() => searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (value) =>
                      setState(() => searchQuery = value.toLowerCase()),
                ),
                const SizedBox(height: 10),
                // Filter and Sort Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: filterType,
                        decoration: InputDecoration(
                          labelText: 'Filter',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Jobs')),
                          DropdownMenuItem(
                              value: 'active', child: Text('Active Jobs')),
                          DropdownMenuItem(
                              value: 'archived', child: Text('Archived')),
                        ],
                        onChanged: (value) =>
                            setState(() => filterType = value!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: sortBy,
                        decoration: InputDecoration(
                          labelText: 'Sort By',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'newest', child: Text('Newest First')),
                          DropdownMenuItem(
                              value: 'oldest', child: Text('Oldest First')),
                          DropdownMenuItem(
                              value: 'title', child: Text('By Title')),
                        ],
                        onChanged: (value) => setState(() => sortBy = value!),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Jobs List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getJobsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No jobs found."));
                }

                var jobs = snapshot.data!.docs.where((doc) {
                  final job = doc.data() as Map<String, dynamic>;
                  final title = job['title']?.toString().toLowerCase() ?? '';
                  final company =
                      job['company_name']?.toString().toLowerCase() ?? '';
                  return title.contains(searchQuery) ||
                      company.contains(searchQuery);
                }).toList();

                // Apply additional filtering
                if (filterType != 'all') {
                  jobs = jobs.where((doc) {
                    final job = doc.data() as Map<String, dynamic>;
                    if (filterType == 'active') {
                      return job['isArchived'] != true;
                    } else {
                      return job['isArchived'] == true;
                    }
                  }).toList();
                }

                // Apply sorting
                jobs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  if (sortBy == 'newest') {
                    final aTime = aData['timestamp'] as Timestamp?;
                    final bTime = bData['timestamp'] as Timestamp?;
                    return (bTime ?? Timestamp.now())
                        .compareTo(aTime ?? Timestamp.now());
                  } else if (sortBy == 'oldest') {
                    final aTime = aData['timestamp'] as Timestamp?;
                    final bTime = bData['timestamp'] as Timestamp?;
                    return (aTime ?? Timestamp.now())
                        .compareTo(bTime ?? Timestamp.now());
                  } else {
                    final aTitle =
                        aData['title']?.toString().toLowerCase() ?? '';
                    final bTitle =
                        bData['title']?.toString().toLowerCase() ?? '';
                    return aTitle.compareTo(bTitle);
                  }
                });

                if (jobs.isEmpty) {
                  return const Center(child: Text("No matching jobs found."));
                }

                return ListView.builder(
                  itemCount: jobs.length,
                  itemBuilder: (context, index) {
                    var job = jobs[index];
                    var jobData = job.data() as Map<String, dynamic>;
                    return _buildJobCard(context, job, jobData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getJobsStream() {
    // Adjust this based on your actual Firestore structure and requirements
    return FirebaseFirestore.instance
        .collection('Job_Posts')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Widget _buildJobCard(BuildContext context, DocumentSnapshot job,
      Map<String, dynamic> jobData) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JobDetailPage(jobId: job.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Logo
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                      image: jobData['logo_url'] != null &&
                              jobData['logo_url'].isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(jobData['logo_url']),
                              fit: BoxFit.contain,
                            )
                          : null,
                    ),
                    child: jobData['logo_url'] == null ||
                            jobData['logo_url'].isEmpty
                        ? const Icon(Icons.business,
                            size: 30, color: Colors.blue)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Job Title and Company
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          jobData['title'] ?? 'No Title',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          jobData['company_name'] ?? 'No Company',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Job Type and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Chip(
                        label: Text(
                          jobData['jobType'] ?? 'N/A',
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      if (jobData['isArchived'] == true)
                        const Chip(
                          label: Text(
                            'Archived',
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Job Details Row
              Row(
                children: [
                  if (jobData['salary'] != null &&
                      jobData['salary'] != "Not specified")
                    Row(
                      children: [
                        const Icon(Icons.attach_money,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          jobData['salary'],
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 16),
                      ],
                    ),
                  const Icon(Icons.location_on, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    jobData['company_location'] ?? 'No Location',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Posted Date and Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Posted: ${_formatTimestamp(jobData['timestamp'])}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  PopupMenuButton<String>(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility,
                                size: 18, color: Colors.blue),
                            SizedBox(width: 8),
                            Text("View Details"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18, color: Colors.orange),
                            SizedBox(width: 8),
                            Text("Edit Job"),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: jobData['isArchived'] == true
                            ? 'unarchive'
                            : 'archive',
                        child: Row(
                          children: [
                            Icon(
                              jobData['isArchived'] == true
                                  ? Icons.unarchive
                                  : Icons.archive,
                              size: 18,
                              color: Colors.purple,
                            ),
                            const SizedBox(width: 8),
                            Text(jobData['isArchived'] == true
                                ? "Unarchive"
                                : "Archive"),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text("Delete Job"),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == 'view') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => JobDetailPage(jobId: job.id),
                          ),
                        );
                      } else if (value == 'edit') {
                        // TODO: Implement edit functionality
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => EditJobPage(jobId: job.id, jobData: jobData),
                        //   ),
                        // );
                      } else if (value == 'archive' || value == 'unarchive') {
                        await _toggleArchiveStatus(
                            job.id, !(jobData['isArchived'] == true));
                      } else if (value == 'delete') {
                        await _confirmDeleteJob(context, job);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleArchiveStatus(String jobId, bool archive) async {
    try {
      await FirebaseFirestore.instance
          .collection('Job_Posts')
          .doc(jobId)
          .update({'isArchived': archive});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(archive ? "Job archived" : "Job unarchived")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating job status: $e")),
      );
    }
  }

  Future<void> _confirmDeleteJob(
      BuildContext context, DocumentSnapshot job) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: Text(
            "Are you sure you want to permanently delete job \"${job['title']}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("CANCEL"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "DELETE",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await deleteJobEverywhere(job.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Job deleted successfully.")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error deleting job: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> deleteJobEverywhere(String jobId) async {
    final firestore = FirebaseFirestore.instance;

    // Delete from main job collection
    await firestore.collection('Job_Posts').doc(jobId).delete();

    // Delete from all users' JobMatches subcollections
    final usersSnapshot = await firestore.collection('User_Data').get();
    for (final userDoc in usersSnapshot.docs) {
      await userDoc.reference.collection('JobMatches').doc(jobId).delete();
    }

    // Delete any applications for this job
    // final applications = await firestore
    //     .collection('applications')
    //     .where('jobId', isEqualTo: jobId)
    //     .get();
    // for (final appDoc in applications.docs) {
    //   await appDoc.reference.delete();
    // }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "N/A";
    if (timestamp is Timestamp) {
      return "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year}";
    }
    return timestamp.toString();
  }
}
