import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/result.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/models/app_user.dart';

/// Sessão do app: a View só observa [user], [busy] e [error].
class AuthViewModel extends ChangeNotifier {
  AuthViewModel(this._repo) {
    _user = _repo.currentUser;
    _sub = _repo.authStateChanges().listen((u) {
      _user = u;
      _ready = true;
      notifyListeners();
    });
  }

  final AuthRepository _repo;
  late final StreamSubscription<AppUser?> _sub;

  AppUser? _user;
  bool _ready = false;
  bool _busy = false;
  String? _error;

  AppUser? get user => _user;
  bool get ready => _ready || _user != null;
  bool get busy => _busy;
  String? get error => _error;

  static String? validate(String email, String password) {
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim())) {
      return 'Informe um e-mail válido.';
    }
    if (password.length < 6) {
      return 'A senha precisa ter pelo menos 6 caracteres.';
    }
    return null;
  }

  Future<void> signIn(String email, String password) =>
      _run(email, password, () => _repo.signIn(email, password));

  Future<void> signUp(String email, String password) =>
      _run(email, password, () => _repo.signUp(email, password));

  Future<void> _run(
    String email,
    String password,
    Future<Result<AppUser>> Function() action,
  ) async {
    final invalid = validate(email, password);
    if (invalid != null) {
      _error = invalid;
      notifyListeners();
      return;
    }
    _busy = true;
    _error = null;
    notifyListeners();
    final result = await action();
    _busy = false;
    if (result case Err(:final failure)) _error = failure.message;
    notifyListeners();
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
