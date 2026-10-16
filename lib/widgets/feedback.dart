import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// A short, readable sentence for a failed action, instead of the raw
/// exception (`[cloud_firestore/unavailable] The service is currently
/// unavailable…`), which reads as a crash to anyone who sees it.
///
/// Connectivity problems and permission refusals get their own message; any
/// other Firebase failure keeps its code in parentheses, so a report of it is
/// still enough to identify the cause.
String friendlyError(AppLocalizations l10n, Object error) {
  debugPrint('Action failed: $error');
  if (error is SocketException ||
      error is TimeoutException ||
      error is HandshakeException) {
    return l10n.errorOffline;
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return l10n.errorOffline;
      case 'permission-denied':
      case 'unauthenticated':
        return l10n.errorPermission;
    }
    return '${l10n.errorGeneric} (${error.code})';
  }
  return l10n.errorGeneric;
}

/// Shows [message] with an Undo button on [messenger].
///
/// Since Flutter 3.38 a snackbar with an action stays up until it is
/// dismissed, which leaves an Undo for a long-finished action covering the
/// screen. This one times out as usual — except for screen-reader users, who
/// need the time to reach the button. Both are read from the messenger's own
/// context, so this is safe to call after the calling widget is gone (a
/// deleted recipe's screen, a hidden feed card).
void showUndoSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required VoidCallback onUndo,
}) {
  final context = messenger.context;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        persist: MediaQuery.accessibleNavigationOf(context),
        action: SnackBarAction(
          label: AppLocalizations.of(context).actionUndo,
          onPressed: onUndo,
        ),
      ),
    );
}
