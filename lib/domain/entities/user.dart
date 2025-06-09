class User {
  final String uid;
  final String? displayName;
  final String? email;
  final String? photoUrl;

  User({
    required this.uid,
    this.displayName,
    this.email,
    this.photoUrl,
  });
}
