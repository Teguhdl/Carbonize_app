/// Simple user class that provides the same interface as Firebase User
/// to maintain backward compatibility with existing screens.
class AppUser {
  final String uid;
  final String? email;
  final String? displayName;

  AppUser({
    required this.uid,
    this.email,
    this.displayName,
  });
}
