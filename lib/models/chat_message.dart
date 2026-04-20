//import not needed this is pure data
class ChatMessage {
  final String text;
  final bool isUser;
  final String? time; 

  ChatMessage({required this.text, required this.isUser,this.time,});
}

class User {
  final String id;
  final String username;
  final String email;
  final String? dob;
  final String? gender;
  final String? profileImage;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.dob,
    this.gender,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      dob: json['dob'],
      gender: json['gender'],
      profileImage: json['profile_image'],
    );
  }
}


class Report {
  final String reportText;
  final DateTime generatedAt;

  Report({required this.reportText, required this.generatedAt});

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      reportText: json['report_text'] ?? '',
      generatedAt: DateTime.parse(json['generated_at']),
    );
  }
}

