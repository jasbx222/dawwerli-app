import 'package:flutter/material.dart';

import '../router/app_router.dart';
import '../router/routes.dart';
import 'api_client.dart';

/// App-wide messenger so API failures from any screen surface as a snackbar.
final messengerKey = GlobalKey<ScaffoldMessengerState>();

abstract final class ApiStatusCodes {
  static const unauthorized = 401;
  static const upgradeRequired = 426;
}

/// Handles an uncaught API error; returns false for anything else.
bool reportApiError(Object e) {
  if (e is! ApiException) return false;
  if (e.status == ApiStatusCodes.upgradeRequired) {
    appRouter.go(Routes.forceUpdate);
    return true;
  }
  if (e.status == ApiStatusCodes.unauthorized) {
    appRouter.go(Routes.login);
    return true;
  }
  final text = e.offline
      ? 'ما نكدر نوصل للخادم. تأكد من الانترنت أو عنوان الخادم'
      : 'ما زبطت العملية، جرّب مرة ثانية (${e.code})';
  messengerKey.currentState
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
  return true;
}
