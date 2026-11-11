import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/l10n/device_name.dart';
import 'package:openmosh/l10n/l10n.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final es = lookupAppLocalizations(const Locale('es'));

  test('iPhone and iPad are told apart by screen size', () {
    expect(deviceNameFor(en, TargetPlatform.iOS, 390), 'iPhone');
    expect(deviceNameFor(en, TargetPlatform.iOS, 744), 'iPad');
  });

  test('Mac and Android keep platform names; Android stays localized', () {
    expect(deviceNameFor(en, TargetPlatform.macOS, 800), 'Mac');
    expect(deviceNameFor(en, TargetPlatform.android, 400), 'Android phone');
    expect(deviceNameFor(es, TargetPlatform.android, 400), 'Teléfono Android');
    expect(deviceNameFor(es, TargetPlatform.iOS, 390), 'iPhone');
  });
}
