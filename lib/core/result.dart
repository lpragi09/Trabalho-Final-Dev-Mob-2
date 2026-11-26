/// Resultado de uma operação que pode falhar, sem exceções atravessando camadas.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final AppFailure failure;
}

enum FailureKind {
  network,
  timeout,
  invalidData,
  server,
  auth,
  permission,
  unknown,
}

class AppFailure {
  const AppFailure(this.kind, this.message);

  final FailureKind kind;

  /// Mensagem segura para exibir ao usuário (sem stack trace nem dados pessoais).
  final String message;

  @override
  String toString() => 'AppFailure($kind, $message)';
}
