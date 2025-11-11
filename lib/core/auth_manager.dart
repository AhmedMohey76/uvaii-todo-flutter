import 'package:shared_preferences/shared_preferences.dart';

/// A utility class to manage authentication data (JWT token and User ID)
/// using SharedPreferences for local, persistent storage.
class AuthManager {
  // Keys for storing data
  static const String _tokenKey = 'jwt_token';
  static const String _userIdKey = 'user_id';

  /// Retrieves the JWT authentication token from local storage.
  /// Returns null if the token is not found.
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Retrieves the authenticated User ID from local storage.
  /// Returns null if the User ID is not found.
  static Future<int?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  /// Stores the authentication token and User ID after a successful login.
  /// Note: The User ID is stored as an integer (int).
  static Future<void> setAuthData(String token, int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setInt(_userIdKey, userId);
  }

  /// Clears all authentication data from local storage (logging out the user).
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
  }
}
