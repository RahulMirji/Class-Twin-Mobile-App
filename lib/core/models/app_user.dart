class AppUser {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? childEmail;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.childEmail,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'student',
      childEmail: map['child_email'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'child_email': childEmail,
    };
  }
}
