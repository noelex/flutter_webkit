enum LoadEvent {
  started,
  redirected,
  commited,
  finished;
}

class WebViewError extends Error {
  final Object? message;

  /// Creates an [WebViewError] with the provided [message].
  WebViewError([this.message]);

  @override
  String toString() {
    if (message != null) {
      return "WebViewError: ${Error.safeToString(message)}";
    }
    return "WebViewError";
  }
}
