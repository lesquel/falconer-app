import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/hosts/presentation/containers/host_detail_container.dart';
import '../features/hosts/presentation/containers/host_form_container.dart';
import '../features/hosts/presentation/containers/hosts_container.dart';
import '../features/keys/presentation/containers/keys_container.dart';
import '../features/settings/presentation/containers/settings_container.dart';
import 'home_shell.dart';

final _id = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

String? _guardIds(GoRouterState s) {
  for (final v in s.pathParameters.values) {
    if (!_id.hasMatch(v)) return '/';
  }
  return null;
}

GoRouter buildRouter({String initialLocation = '/'}) => GoRouter(
      initialLocation: initialLocation,
      redirect: (_, s) => _guardIds(s),
      errorBuilder: (_, _) => const Scaffold(body: Center(child: Text('Not found'))),
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (_, _, shell) => HomeShell(shell: shell),
          branches: [
            StatefulShellBranch(routes: [GoRoute(path: '/', builder: (_, _) => const HostsContainer())]),
            StatefulShellBranch(routes: [GoRoute(path: '/keys', builder: (_, _) => const KeysContainer())]),
            StatefulShellBranch(routes: [GoRoute(path: '/settings', builder: (_, _) => const SettingsContainer())]),
          ],
        ),
        GoRoute(path: '/hosts/new', builder: (_, _) => const HostFormContainer()),
        GoRoute(path: '/hosts/:id', builder: (_, s) => HostDetailContainer(hostId: s.pathParameters['id']!)),
        GoRoute(path: '/hosts/:id/edit', builder: (_, s) => HostFormContainer(hostId: s.pathParameters['id']!)),
      ],
    );
