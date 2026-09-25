/// Which ranking a list of [LeaderboardEntry] represents.
///
/// [rpcValue] is passed to `get_leaderboard` as `p_scope`.
enum LeaderboardScope {
  global('global', 'All Time'),
  weekly('weekly', 'This Week'),
  friends('friends', 'Friends');

  const LeaderboardScope(this.rpcValue, this.label);

  final String rpcValue;
  final String label;

  /// There is no friends graph in the product yet, so the RPC answers this
  /// scope with the global ranking rather than pretending to filter. The UI
  /// says so instead of faking a result.
  bool get isPlaceholder => this == LeaderboardScope.friends;
}

/// One row of the leaderboard.
///
/// `get_leaderboard` is `SECURITY DEFINER` because `gamification` is readable
/// only by its owner, so it projects exactly these columns and nothing else —
/// no email, no raw XP ledger, no write access.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    required this.xp,
    this.avatarUrl,
    this.level = 1,
    this.tier = 'Bronze',
    this.streakDays = 0,
    this.isMe = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: _int(json['rank']),
      userId: json['user_id']?.toString() ?? '',
      displayName: _text(json['display_name'], fallback: 'FitFuel Athlete'),
      xp: _int(json['xp']),
      avatarUrl: _optionalText(json['avatar_url']),
      level: _int(json['level'], fallback: 1),
      tier: _text(json['tier'], fallback: 'Bronze'),
      streakDays: _int(json['streak_days']),
      isMe: json['is_me'] == true,
    );
  }

  final int rank;
  final String userId;
  final String displayName;
  final int xp;
  final String? avatarUrl;
  final int level;
  final String tier;
  final int streakDays;

  /// True for the signed-in user's own row, so the UI can pin and highlight it.
  final bool isMe;

  /// Initials for the avatar placeholder, e.g. "FitFuel Athlete" -> "FA".
  String get initials {
    final parts = displayName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static int _int(Object? value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    return fallback;
  }

  static String _text(Object? value, {String? fallback}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? (fallback ?? '') : text;
  }

  /// Returns null when the column is absent or blank, so the UI can fall back
  /// to an initials avatar instead of rendering a broken image.
  static String? _optionalText(Object? value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
