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
  final push = await PushRuntime.start(onTap: (payload) => _router?.go(payload));

  // Started by UnifiedPush to handle a message while the UI is closed.
  if (args.contains('--unifiedpush-bg')) return;

  // The bundled Manrope font ships under the SIL Open Font License.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/Manrope-OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Manrope'], text);
  });
  await RustLib.init();
  final launch = await push.notifier.launchPayload();
  final router = _router = buildRouter(initialLocation: launch ?? '/');

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

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: OpenMoshApp(router: router),
    ),
  );
  await push.notifier.requestPermission();
}
