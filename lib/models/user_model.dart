class AppUser {
  final String name;
  final String phone;
  final String gender;

  AppUser({
    required this.name,
    required this.phone,
    required this.gender,
  });

  factory AppUser.fromMap(Map<String, dynamic> data) {
    return AppUser(
      name: data['name'],
      phone: data['phone'],
      gender: data['gender'],
    );
  }
}
