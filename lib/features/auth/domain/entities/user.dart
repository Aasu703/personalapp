/// Domain entity representing an authenticated user.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.isVerified = true,
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final bool isVerified;
  final DateTime? createdAt;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      isVerified: json['isVerified'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'isVerified': isVerified,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
