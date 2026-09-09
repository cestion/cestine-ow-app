import 'dart:async';

abstract class StoryAuthProvider {
  String? get accessToken;
  String? get userId;
  Future<String?> getAccessToken();
  Stream<bool> get authStateChanges;
  bool get isLoggedIn;
  Future<void> logout();
}
