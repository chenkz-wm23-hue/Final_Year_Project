import '../data/models/user.dart';
import '../data/repositories/expense_repository.dart';

class ProfileManagement {
  final ExpenseRepository repository;
  const ProfileManagement(this.repository);
  void update(String name, String email, String phone, String address) =>
      repository.saveUser(
        UserProfile(
          name: name.trim(),
          email: email.trim(),
          phone: phone.trim(),
          address: address.trim(),
        ),
      );
}
