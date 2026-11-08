import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/l10n/l10n.dart';
import 'package:openmosh/shared/domain/failure.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final es = lookupAppLocalizations(const Locale('es'));

  test('the system language leaves the locale to the phone', () {
    expect(localeFor(AppLanguage.system), isNull);
    expect(localeFor(AppLanguage.en), const Locale('en'));
    expect(localeFor(AppLanguage.es), const Locale('es'));
  });

  test('known domain failures are translated; unknown messages pass through', () {
    expect(en.failureText(const ConnectionFailure()), 'Could not reach the host.');
    expect(es.failureText(const ConnectionFailure()), 'No se pudo conectar con el equipo.');
    expect(es.failureText(const HookFailure('error', 'disk full')), 'disk full');
    expect(es.failureText(Exception('x')), 'Algo salió mal.');
  });

  test('plural strings follow the locale', () {
    expect(es.navSettings, 'Ajustes');
    expect(es.requestsWaiting(2), '2 solicitudes te esperan.');
    expect(en.requestsWaiting(1), '1 request waits for you.');
  });
}
