/// Model for the local user profile.
class UserProfile {
  final String username;
  final String displayName;
  final int avatarColorValue; // stored as int (Color.value)
  final String? avatarPhotoPath; // local file path to photo

  const UserProfile({
    required this.username,
    required this.displayName,
    required this.avatarColorValue,
    this.avatarPhotoPath,
  });

  static const _defaultColors = [
    0xFF6366F1, // Indigo
    0xFF8B5CF6, // Violet
    0xFFEC4899, // Pink
    0xFF14B8A6, // Teal
    0xFFF59E0B, // Amber
    0xFFEF4444, // Red
    0xFF22C55E, // Green
    0xFF3B82F6, // Blue
  ];

  /// Default profile for new users.
  factory UserProfile.defaults() {
    return UserProfile(
      username: 'vanguard_fighter',
      displayName: 'Vanguard Fighter',
      avatarColorValue: _defaultColors[0],
    );
  }

  UserProfile copyWith({
    String? username,
    String? displayName,
    int? avatarColorValue,
    Object? avatarPhotoPath = _sentinel,
  }) {
    return UserProfile(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarColorValue: avatarColorValue ?? this.avatarColorValue,
      avatarPhotoPath: avatarPhotoPath == _sentinel
          ? this.avatarPhotoPath
          : avatarPhotoPath as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'username': username,
        'displayName': displayName,
        'avatarColorValue': avatarColorValue,
        'avatarPhotoPath': avatarPhotoPath,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      username: json['username'] as String? ?? 'vanguard_fighter',
      displayName: json['displayName'] as String? ?? 'Vanguard Fighter',
      avatarColorValue: json['avatarColorValue'] as int? ?? _defaultColors[0],
      avatarPhotoPath: json['avatarPhotoPath'] as String?,
    );
  }

  static List<int> get availableColors => _defaultColors;
}

const _sentinel = Object();
