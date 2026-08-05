/// Domain entity representing an authenticated user.
class User {
  const User({required this.id, required this.name, required this.email});

  final String id;
  final String name;
  final String email;
}
