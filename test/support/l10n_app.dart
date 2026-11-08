import 'package:flutter/material.dart';
import 'package:openmosh/l10n/l10n.dart';

/// A [MaterialApp] with the app's localizations, English unless [locale] says otherwise.
Widget l10nApp({required Widget home, Locale locale = const Locale('en'), ThemeData? theme}) =>
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      theme: theme,
      home: home,
    );
