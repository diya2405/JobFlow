// job_model.dart
class Job {
  final String jobId;
  final String title;
  final String company;
  final String description;

  Job({required this.jobId, required this.title, required this.company, required this.description});

  // Convert Job to JSON format for Firestore
  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'title': title,
      'company': company,
      'description': description,
    };
  }

  // Convert from JSON
  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      jobId: json['jobId'],
      title: json['title'],
      company: json['company'],
      description: json['description'],
    );
  }
}
