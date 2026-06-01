import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../service/authentication_service.dart';

class UserProvider extends ChangeNotifier {
  final GraphQLService _graphqlService = GraphQLService();
  UserModel? _user;
  bool isLoading = false;
  String? error;

  UserModel? get user => _user;

  Map<String, dynamic>? get userMap => _user?.toMap();

  Future<void> loadUser() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _graphqlService.me();
      _user = UserModel.fromMap(result);
    } catch (e) {
      error = e.toString();
      debugPrint('Load User error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateField(String key, String value) async {
    if (_user == null) return;

    final oldMap = _user!.toMap();
    final newMap = {...oldMap, key: value};
    _user = UserModel.fromMap(newMap);
    notifyListeners();

    try {
      await _graphqlService.update(
        userName: _user?.userName ?? '',
        dob: (_user?.dob != null && _user!.dob!.isNotEmpty) ? _user!.dob : null,
        gender: _user?.gender ?? '',
        address: _user?.address ?? '',
        notification: _user?.notification ?? 'ON',
        language: _user?.language ?? 'ENGLISH',
      );
      // Reload from server to sync
      await loadUser();
    } catch (e) {
      // Revert on error
      _user = UserModel.fromMap(oldMap);
      error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }
}
