import 'package:flutter/material.dart';

class AppliedJobsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: const Text(
        "You haven't applied for any jobs yet!",
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
