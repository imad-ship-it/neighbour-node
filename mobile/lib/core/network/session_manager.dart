import 'dart:async';

/// Global session signals. The auth interceptor calls [notifyLoggedOut] when
/// a token refresh fails; app-level listeners (router redirect / auth bloc)
/// subscribe to [onForcedLogout] to send the user back to the login screen.
class SessionManager {
  final StreamController<void> _forcedLogout = StreamController<void>.broadcast();

  Stream<void> get onForcedLogout => _forcedLogout.stream;

  void notifyLoggedOut() {
    if (!_forcedLogout.isClosed) _forcedLogout.add(null);
  }

  void dispose() => _forcedLogout.close();
}
