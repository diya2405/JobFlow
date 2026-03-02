import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;

class Resume_Match_trigger extends StatelessWidget {
  const Resume_Match_trigger({super.key});

  Future<void> triggerResumeMatcher() async {
    const String matcherUrl = 'http://127.0.0.1:5000/run-matcher'; // NOT localhost
    const String apiKey = '51ffb45fc7e81699b17081b50fac4963';

    try {
      final response = await http.post(
        Uri.parse(matcherUrl),
        headers: {
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        print('Matcher triggered successfully.');
      } else {
        print('Failed to trigger matcher: ${response.statusCode}');
      }
    } catch (e) {
      print('Error triggering matcher: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
