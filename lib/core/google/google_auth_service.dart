import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GoogleAccountProfile {
  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final DateTime connectedAt;

  GoogleAccountProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.connectedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'connectedAt': connectedAt.toIso8601String(),
  };

  factory GoogleAccountProfile.fromJson(Map<String, dynamic> json) =>
      GoogleAccountProfile(
        id: json['id'] as String? ?? '',
        email: json['email'] as String? ?? '',
        displayName: json['displayName'] as String? ?? '',
        photoUrl: json['photoUrl'] as String?,
        connectedAt: json['connectedAt'] != null
            ? DateTime.tryParse(json['connectedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

class GoogleAuthService extends ChangeNotifier {
  static const String _keyGoogleProfile = 'google_account_profile';
  static const String _keyAccessToken = 'google_access_token';
  static const String _photosScope =
      'https://www.googleapis.com/auth/photoslibrary.readonly';

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;
  late final GoogleSignIn _googleSignIn;

  GoogleAccountProfile? _currentProfile;
  String? _accessToken;
  bool _isLoading = false;

  GoogleAccountProfile? get currentProfile => _currentProfile;
  bool get isSignedIn => _currentProfile != null;
  bool get isLoading => _isLoading;
  String? get accessToken => _accessToken;

  GoogleAuthService({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  }) : _secureStorage = secureStorage,
       _prefs = prefs {
    _googleSignIn = GoogleSignIn(
      scopes: <String>['email', 'profile', _photosScope],
    );

    _initFromStorage();
  }

  Future<void> _initFromStorage() async {
    final rawProfile = _prefs.getString(_keyGoogleProfile);
    if (rawProfile != null) {
      try {
        _currentProfile = GoogleAccountProfile.fromJson(
          jsonDecode(rawProfile) as Map<String, dynamic>,
        );
        _accessToken = await _secureStorage.read(key: _keyAccessToken);
        notifyListeners();
      } catch (e) {
        debugPrint('[GoogleAuthService] Error reading cached profile: $e');
      }
    }

    // Attempt silent sign-in to refresh tokens
    try {
      if (await _googleSignIn.isSignedIn()) {
        final account = await _googleSignIn.signInSilently();
        if (account != null) {
          await _onSignInSuccess(account);
        }
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] Silent sign-in error: $e');
    }
  }

  Future<bool> signIn() async {
    _isLoading = true;
    notifyListeners();

    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _onSignInSuccess(account);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        debugPrint('[GoogleAuthService] User cancelled Google Sign-In');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] Error during Google Sign-In: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _onSignInSuccess(GoogleSignInAccount account) async {
    final auth = await account.authentication;
    _accessToken = auth.accessToken;

    _currentProfile = GoogleAccountProfile(
      id: account.id,
      email: account.email,
      displayName: account.displayName ?? account.email.split('@').first,
      photoUrl: account.photoUrl,
      connectedAt: DateTime.now(),
    );

    await _prefs.setString(
      _keyGoogleProfile,
      jsonEncode(_currentProfile!.toJson()),
    );
    if (_accessToken != null) {
      await _secureStorage.write(key: _keyAccessToken, value: _accessToken);
    }
    notifyListeners();
  }

  Future<Map<String, String>> getAuthHeaders() async {
    if (_accessToken != null) {
      return {
        'Authorization': 'Bearer $_accessToken',
        'Content-Type': 'application/json',
      };
    }

    try {
      final account =
          _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      if (account != null) {
        final auth = await account.authentication;
        _accessToken = auth.accessToken;
        if (_accessToken != null) {
          await _secureStorage.write(key: _keyAccessToken, value: _accessToken);
          return {
            'Authorization': 'Bearer $_accessToken',
            'Content-Type': 'application/json',
          };
        }
      }
    } catch (e) {
      debugPrint('[GoogleAuthService] Error refreshing auth headers: $e');
    }

    return {};
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuthService] Error on Google signOut: $e');
    }

    _currentProfile = null;
    _accessToken = null;
    await _prefs.remove(_keyGoogleProfile);
    await _secureStorage.delete(key: _keyAccessToken);
    notifyListeners();
  }
}
