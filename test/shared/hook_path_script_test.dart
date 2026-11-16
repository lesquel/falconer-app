@TestOn('linux || mac-os')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/sessions/domain/entities/remote_session.dart';
import 'package:openmosh/shared/hook/domain/hook_command.dart';

/// Runs the scripts the app sends to a host, in a real `sh`, against a
/// throwaway HOME, to check which hook binary they pick.
void main() {
  late Directory home;
  late Directory emptyPath;

  setUp(() {
    home = Directory.systemTemp.createTempSync('falconer-hook-path-');
    emptyPath = Directory('${home.path}/empty-path')..createSync();
  });
  tearDown(() => home.deleteSync(recursive: true));

  void fakeHook(String dir, String name) {
    Directory(dir).createSync(recursive: true);
    final f = File('$dir/$name')..writeAsStringSync('#!/bin/sh\necho "$name \$*"\n');
    Process.runSync('chmod', ['+x', f.path]);
  }

  ProcessResult run(List<String> args, {String? path}) => Process.runSync(
    '/bin/sh',
    args,
    environment: {'HOME': home.path, 'PATH': '${path ?? emptyPath.path}:/usr/bin:/bin'},
    includeParentEnvironment: false,
  );

  String resolve({String? path}) =>
      (run(['-c', HookCommand.resolvePathScript], path: path).stdout as String).trim();

  group('hook path resolution', () {
    test('prefers falconer-hook on PATH', () {
      final bin = '${home.path}/bin';
      fakeHook(bin, 'falconer-hook');
      fakeHook(bin, 'openmosh-hook');
      expect(resolve(path: bin), '$bin/falconer-hook');
    });

    test('falls back to openmosh-hook on PATH for hosts not yet upgraded', () {
      final bin = '${home.path}/bin';
      fakeHook(bin, 'openmosh-hook');
      expect(resolve(path: bin), '$bin/openmosh-hook');
    });

    test('prefers ~/.local/bin/falconer-hook when nothing is on PATH', () {
      fakeHook('${home.path}/.local/bin', 'falconer-hook');
      fakeHook('${home.path}/.local/bin', 'openmosh-hook');
      expect(resolve(), '${home.path}/.local/bin/falconer-hook');
    });

    test('falls back to ~/.local/bin/openmosh-hook', () {
      fakeHook('${home.path}/.local/bin', 'openmosh-hook');
      expect(resolve(), '${home.path}/.local/bin/openmosh-hook');
    });

    test('with no hook installed it names the falconer-hook default path', () {
      expect(resolve(), '${home.path}/.local/bin/falconer-hook');
    });
  });

  group('herdr attach', () {
    List<String> attachArgs() {
      final s = const RemoteSession(name: 'main', kind: SessionKind.herdr).attachCommand;
      // attachCommand is `'sh' '-c' '<script>' 'sh' 'main'`; run it through sh.
      return ['-c', s];
    }

    test('attaches through falconer-hook', () {
      fakeHook('${home.path}/.local/bin', 'falconer-hook');
      fakeHook('${home.path}/.local/bin', 'openmosh-hook');
      expect(
        (run(attachArgs()).stdout as String).trim(),
        'falconer-hook attach herdr --session main',
      );
    });

    test('attaches through openmosh-hook on hosts not yet upgraded', () {
      fakeHook('${home.path}/.local/bin', 'openmosh-hook');
      expect(
        (run(attachArgs()).stdout as String).trim(),
        'openmosh-hook attach herdr --session main',
      );
    });
  });
}
