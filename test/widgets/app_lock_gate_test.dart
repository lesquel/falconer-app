import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/lock/domain/app_lock.dart';
import 'package:openmosh/features/lock/presentation/app_lock_gate.dart';
import 'package:openmosh/shared/ui/atoms/mole_logo.dart';

import '../features/hosts/paired_devices_test.dart' show ScriptedAuth;

void main() {
  late ScriptedAuth auth;
  late DateTime now;
  late AppLock lock;

  setUp(() {
    auth = ScriptedAuth()..allow = false;
    now = DateTime.utc(2026, 11, 8, 12);
    lock = AppLock(auth: auth, now: () => now);
  });

  Widget gate(bool? enabled) => MaterialApp(
    home: AppLockGate(lock: lock, enabled: enabled, child: const Text('secret')),
  );

  bool contentVisible(WidgetTester t) => find.text('secret').hitTestable().evaluate().isNotEmpty;

  testWidgets('nothing is shown while the setting is loading', (t) async {
    await t.pumpWidget(gate(null));
    expect(contentVisible(t), isFalse);
  });

  testWidgets('lock off: content shows right away', (t) async {
    await t.pumpWidget(gate(false));
    await t.pump();
    expect(contentVisible(t), isTrue);
    expect(auth.reasons, isEmpty);
  });

  testWidgets('lock on: cold start hides content behind the mole until verified', (t) async {
    await t.pumpWidget(gate(true));
    await t.pump();
    expect(contentVisible(t), isFalse);
    expect(find.byType(MoleLogo), findsOneWidget);
    expect(auth.reasons, ['Unlock OpenMosh'], reason: 'prompts once on its own');
    auth.allow = true;
    await t.tap(find.text('Unlock'));
    await t.pump();
    expect(contentVisible(t), isTrue);
  });

  testWidgets('lock on: a short trip to the background does not lock, a long one does', (t) async {
    auth.allow = true;
    await t.pumpWidget(gate(true));
    await t.pump();
    await t.pump();
    expect(contentVisible(t), isTrue);

    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 30));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(contentVisible(t), isTrue);

    auth.allow = false;
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 61));
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(contentVisible(t), isFalse);
  });

  testWidgets('locking takes the keyboard focus away from the hidden content', (t) async {
    auth.allow = true;
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await t.pumpWidget(
      MaterialApp(
        home: AppLockGate(
          lock: lock,
          enabled: true,
          child: Material(child: TextField(focusNode: focus)),
        ),
      ),
    );
    await t.pump();
    await t.pump();
    focus.requestFocus();
    await t.pump();
    expect(focus.hasFocus, isTrue);

    auth.allow = false;
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 61));
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive]) {
      t.binding.handleAppLifecycleStateChanged(s);
    }
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(lock.locked, isTrue);
    expect(focus.hasFocus, isFalse);
  });
}
