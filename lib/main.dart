import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'app/push_runtime.dart';
import 'app/router.dart';
import 'shared/bridge/frb_generated.dart';

GoRouter? _router;

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Started by UnifiedPush to handle a message while the UI is closed:
  // no Rust needed. Otherwise the Rust core loads while the database and
  // notifications start.
  final background = args.contains('--unifiedpush-bg');
  final (push, _) = await (
    PushRuntime.start(onTap: (path, answer) => _router?.go(path, extra: answer)),
    background ? Future<void>.value() : RustLib.init(),
  ).wait;
  if (background) return;

  // The bundled Manrope font ships under the SIL Open Font License.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/Manrope-OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Manrope'], text);
  });
  final launch = await push.notifier.launchRoute();
  final router = _router = buildRouter(
    initialLocation: launch?.path ?? '/',
    initialExtra: launch?.answer,
  );

  final container = ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(push.db),
      secureStorageProvider.overrideWithValue(push.storage),
      pushEndpointsProvider.overrideWithValue(push.endpoints),
      notifierProvider.overrideWithValue(push.notifier),
    ],
  );
  // A v0.1 key still outside the auth-bound namespace moves at the next
  // successful user verification.
  unawaited(container.read(legacyKeyMigrationProvider).checkOnStartup());
  // Registered before any screen, so a resume unpauses terminals before a
  // terminal screen handles it.
  final terminals = container.read(terminalLifecycleProvider);
  // The listener registers with the binding and lives as long as the app.
  AppLifecycleListener(onPause: terminals.paused, onResume: terminals.resumed);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: FalconerApp(router: router),
    ),
  );
  await push.notifier.requestPermission();
}
