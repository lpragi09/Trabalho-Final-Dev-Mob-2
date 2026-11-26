/// Estados que toda tela com dados remotos precisa representar.
sealed class UiState<T> {
  const UiState();
}

final class UiIdle<T> extends UiState<T> {
  const UiIdle();
}

final class UiLoading<T> extends UiState<T> {
  const UiLoading();
}

final class UiSuccess<T> extends UiState<T> {
  const UiSuccess(this.data);
  final T data;
}

final class UiEmpty<T> extends UiState<T> {
  const UiEmpty(this.message);
  final String message;
}

final class UiError<T> extends UiState<T> {
  const UiError(this.message);
  final String message;
}
