import 'dart:async';
import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/domain/entities/admin_profile.dart';
import '../../../auth/domain/usecases/get_user_accounts_usecase.dart';
import '../../domain/usecases/create_user_usecase.dart';
import '../../domain/usecases/delete_user_usecase.dart';
import '../../domain/usecases/get_users_usecase.dart';
import '../../domain/usecases/update_user_usecase.dart';

@injectable
class MultiUserProvider extends ChangeNotifier {
  final GetUsersUseCase _getUsersUseCase;
  final CreateUserUseCase _createUserUseCase;
  final UpdateUserUseCase _updateUserUseCase;
  final DeleteUserUseCase _deleteUserUseCase;
  final GetUserAccountsUseCase _getUserAccountsUseCase;

  MultiUserProvider(
    this._getUsersUseCase,
    this._createUserUseCase,
    this._updateUserUseCase,
    this._deleteUserUseCase,
    this._getUserAccountsUseCase,
  );

  List<AdminProfile> _users = [];
  List<AdminProfile> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  StreamSubscription? _usersSubscription;
  String? _currentAccountId;

  AdminProfile? _currentUser;
  AdminProfile? get currentUser => _currentUser;

  /// Check if current user has permission to create/manage users
  bool get canCreateUsers => _currentUser?.multiuser ?? false;

  @override
  void dispose() {
    _usersSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentAccountId = await _getUserAccountsUseCase.getSelectedAccountId();

      // Load current user from persistence
      _currentUser = await _getUserAccountsUseCase.loadAdminProfile();

      if (_currentAccountId != null) {
        _usersSubscription?.cancel();
        _usersSubscription = _getUsersUseCase(_currentAccountId!).listen(
          (result) {
            result.fold(
              (failure) {
                _errorMessage = failure.message;
                _isLoading = false;
                notifyListeners();
              },
              (users) {
                _users = users;
                _isLoading = false;
                notifyListeners();
              },
            );
          },
        );
      } else {
        _errorMessage = "No account selected";
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createUser(AdminProfile user) async {
    if (_currentAccountId == null) return false;

    _isLoading = true;
    notifyListeners();

    final result = await _createUserUseCase(
      CreateUserParams(user: user, accountId: _currentAccountId!),
    );

    bool success = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (_) {
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> updateUser(AdminProfile user) async {
    if (_currentAccountId == null) return false;

    _isLoading = true;
    notifyListeners();

    final result = await _updateUserUseCase(
      UpdateUserParams(user: user, accountId: _currentAccountId!),
    );

    bool success = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (_) {
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> deleteUser(AdminProfile user) async {
    if (_currentAccountId == null) return false;

    _isLoading = true;
    notifyListeners();

    final result = await _deleteUserUseCase(
      DeleteUserParams(user: user, accountId: _currentAccountId!),
    );

    bool success = false;
    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (_) {
        success = true;
      },
    );

    _isLoading = false;
    notifyListeners();
    return success;
  }
}
