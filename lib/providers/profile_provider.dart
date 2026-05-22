import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

const _kProfileKey = 'vg_user_profile';

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    return _load();
  }

  Future<UserProfile> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kProfileKey);
    if (raw == null) return UserProfile.defaults();
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return UserProfile.fromJson(json);
    } catch (_) {
      return UserProfile.defaults();
    }
  }

  Future<void> save(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileKey, jsonEncode(profile.toJson()));
    state = AsyncData(profile);
  }

  Future<void> updateUsername(String username, String displayName) async {
    final current = state.value ?? UserProfile.defaults();
    await save(current.copyWith(username: username, displayName: displayName));
  }

  Future<void> updateAvatarColor(int colorValue) async {
    final current = state.value ?? UserProfile.defaults();
    await save(current.copyWith(avatarColorValue: colorValue));
  }

  Future<void> updateAvatarPhoto(String? path) async {
    final current = state.value ?? UserProfile.defaults();
    await save(current.copyWith(avatarPhotoPath: path));
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile>(() {
  return ProfileNotifier();
});
