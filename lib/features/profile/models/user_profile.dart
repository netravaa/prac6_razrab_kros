class UserProfile {
  final String id;
  final String nickname;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.nickname,
    this.avatarUrl,
  });

  UserProfile copyWith({
    String? id,
    String? nickname,
    String? avatarUrl,
  }) {
    return UserProfile(
      id: id ?? this.id,
      nickname: nickname ?? this.nickname,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
