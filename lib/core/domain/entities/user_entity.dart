class UserEntity {

  const UserEntity({
    required this.id,
    this.email,
    this.name,
    this.avatarUrl,
  });
  final String id;
  final String? email;
  final String? name;
  final String? avatarUrl;
}