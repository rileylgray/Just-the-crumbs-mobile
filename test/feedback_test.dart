// The user-facing feedback helpers: readable error text, error states with a
// retry, and undo snackbars that don't outstay their welcome.

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_the_crumbs_mobile/l10n/gen/app_localizations.dart';
import 'package:just_the_crumbs_mobile/theme/app_theme.dart';
import 'package:just_the_crumbs_mobile/widgets/empty_state.dart';
import 'package:just_the_crumbs_mobile/widgets/feedback.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('friendlyError', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('connectivity failures read as being offline', () {
      expect(
        friendlyError(
          l10n,
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
        l10n.errorOffline,
      );
      expect(friendlyError(l10n, TimeoutException('slow')), l10n.errorOffline);
    });

    test('refusals read as a permission problem', () {
      expect(
        friendlyError(
          l10n,
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
            message: 'Missing or insufficient permissions.',
          ),
        ),
        l10n.errorPermission,
      );
    });

    test('other Firebase failures keep their code for reports', () {
      expect(
        friendlyError(
          l10n,
          FirebaseException(plugin: 'cloud_firestore', code: 'aborted'),
        ),
        '${l10n.errorGeneric} (aborted)',
      );
    });

    test('anything else never shows the raw exception', () {
      expect(friendlyError(l10n, StateError('boom')), l10n.errorGeneric);
    });
  });

  testWidgets('ErrorState offers a retry', (tester) async {
    var retried = 0;
    await _pump(
      tester,
      ErrorState(error: StateError('boom'), onRetry: () => retried++),
    );
    expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('an undo snackbar times out on its own', (tester) async {
    var undone = false;
    await _pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showUndoSnackBar(
            ScaffoldMessenger.of(context),
            message: 'Deleted “Tart”',
            onUndo: () => undone = true,
          ),
          child: const Text('delete'),
        ),
      ),
    );

    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
    expect(find.text('Deleted “Tart”'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    expect(undone, isTrue);

    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('Deleted “Tart”'), findsNothing);
  });
}
