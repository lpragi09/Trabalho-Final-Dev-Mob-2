import 'package:firebase_auth/firebase_auth.dart';

import '../../core/result.dart';
import '../../domain/models/app_user.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> authStateChanges();
  AppUser? get currentUser;
  Future<Result<AppUser>> signIn(String email, String password);
  Future<Result<AppUser>> signUp(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  AppUser? _map(User? u) =>
      u == null ? null : AppUser(uid: u.uid, email: u.email ?? '');

  @override
  Stream<AppUser?> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AppUser? get currentUser => _map(_auth.currentUser);

  @override
  Future<Result<AppUser>> signIn(String email, String password) => _guard(
    () => _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<Result<AppUser>> signUp(String email, String password) => _guard(
    () => _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    ),
  );

  @override
  Future<void> signOut() => _auth.signOut();

  Future<Result<AppUser>> _guard(
    Future<UserCredential> Function() action,
  ) async {
    try {
      final cred = await action();
      return Ok(_map(cred.user)!);
    } on FirebaseAuthException catch (e) {
      return Err(AppFailure(FailureKind.auth, _message(e.code)));
    } on Object {
      return const Err(
        AppFailure(FailureKind.unknown, 'Não foi possível autenticar.'),
      );
    }
  }

  static String _message(String code) => switch (code) {
    'invalid-email' => 'E-mail inválido.',
    'user-disabled' => 'Conta desativada.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'E-mail ou senha incorretos.',
    'email-already-in-use' => 'Já existe uma conta com este e-mail.',
    'weak-password' => 'A senha precisa ter pelo menos 6 caracteres.',
    'network-request-failed' => 'Sem conexão para autenticar.',
    'too-many-requests' => 'Muitas tentativas. Aguarde um pouco.',
    _ => 'Não foi possível autenticar ($code).',
  };
}
