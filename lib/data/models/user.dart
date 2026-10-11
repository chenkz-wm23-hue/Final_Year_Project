class UserProfile {
  final String name, email, phone, address;
  const UserProfile({
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
  });
}
