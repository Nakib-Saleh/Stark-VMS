import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vehicle_providers.dart';

/// Whether the API is answering (ADR-0008). The free host puts the API to sleep after 15 minutes
/// without visitors and takes up to a minute to wake it, so a slow request most likely means
/// "waking up", not "broken".
enum ServerWake { answering, waking, unreachable }

/// Fed by the Dio client: every request reports when it starts and ends. If any request is still
/// waiting after [slowAfter], the app shows the waking notice; the first answer clears it.
class ServerWakeController extends Notifier<ServerWake> {
  static const slowAfter = Duration(seconds: 3);

  int _pending = 0;
  Timer? _slow;

  @override
  ServerWake build() {
    ref.onDispose(() => _slow?.cancel());
    return ServerWake.answering;
  }

  void requestStarted() {
    _pending++;
    _slow ??= Timer(slowAfter, () {
      _slow = null;
      if (_pending > 0 && state == ServerWake.answering) state = ServerWake.waking;
    });
  }

  /// [error] is null when the server answered (any status code counts as an answer).
  void requestEnded(DioException? error) {
    _pending = _pending > 0 ? _pending - 1 : 0;
    if (_pending == 0) {
      _slow?.cancel();
      _slow = null;
    }
    if (error == null || error.type == DioExceptionType.cancel) {
      if (error == null) state = ServerWake.answering;
      return;
    }
    final status = error.response?.statusCode;
    // No response at all, or the host's own "service unavailable" while it starts the API.
    final noAnswer = status == null || status == 502 || status == 503 || status == 504;
    state = noAnswer ? ServerWake.unreachable : ServerWake.answering;
  }

  /// Wakes the server early (called at app start, while the visitor reads the landing page) and
  /// backs the notice's "Try again" button. Its result reaches [state] through the Dio callbacks.
  Future<void> probe() async {
    if (state == ServerWake.unreachable) state = ServerWake.waking; // the button answers at once
    try {
      await ref.read(dioProvider).get<dynamic>('/health');
    } on DioException {
      // Already reported through requestEnded.
    }
  }
}

final serverWakeProvider = NotifierProvider<ServerWakeController, ServerWake>(ServerWakeController.new);
