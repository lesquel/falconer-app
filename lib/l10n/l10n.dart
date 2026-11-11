/// Localization entry point: `context.l10n` plus presentation mappings for
/// domain values (enum labels, failure messages) that stay English in domain.
library;

import 'package:flutter/widgets.dart';

import '../features/settings/domain/entities/app_settings.dart';
import '../features/settings/domain/entities/appearance.dart';
import '../shared/domain/failure.dart';
import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// Locales the app ships, English first (the fallback).
const supportedAppLocales = AppLocalizations.supportedLocales;

/// `null` lets the phone's language decide (English when unsupported).
Locale? localeFor(AppLanguage language) => switch (language) {
  AppLanguage.system => null,
  AppLanguage.en => const Locale('en'),
  AppLanguage.es => const Locale('es'),
};

extension L10nContext on BuildContext {
  /// Strings for the current locale; English when no delegate is installed.
  AppLocalizations get l10n =>
      AppLocalizations.of(this) ?? lookupAppLocalizations(const Locale('en'));
}

extension AppearanceL10n on AppLocalizations {
  String accentName(AccentColor a) => switch (a) {
    AccentColor.blue => accentBlue,
    AccentColor.green => accentGreen,
    AccentColor.violet => accentViolet,
    AccentColor.amber => accentAmber,
    AccentColor.coral => accentCoral,
    AccentColor.white => accentWhite,
  };

  String schemeName(TerminalScheme s) => switch (s) {
    TerminalScheme.black => schemeBlack,
    TerminalScheme.paper => schemePaper,
    TerminalScheme.sepia => schemeSepia,
    TerminalScheme.highContrast => schemeHighContrast,
  };

  String themeName(ThemePreference p) => switch (p) {
    ThemePreference.system => themeSystem,
    ThemePreference.light => themeLight,
    ThemePreference.dark => themeDark,
  };

  String languageName(AppLanguage l) => switch (l) {
    AppLanguage.system => languageSystem,
    AppLanguage.en => languageEnglish,
    AppLanguage.es => languageSpanish,
  };
}

extension FailureL10n on AppLocalizations {
  /// Text for any error: known domain messages are translated, others
  /// (for example a message relayed from the host) are shown as they are.
  String failureText(Object failure) =>
      failure is AppFailure ? failureMessage(failure.message) : somethingWentWrong;

  /// Translates a domain failure message, identified by its English text.
  String failureMessage(String message) => switch (message) {
    'Host key changed. The connection was blocked.' => errHostKeyChanged,
    'The host rejected this device key.' => errAuthRejected,
    'Could not reach the host.' => errCannotReachHost,
    'Unlock was cancelled.' => errUnlockCancelled,
    'Changing address or port needs a new host key check. Add the host again.' =>
      errAddressNeedsNewCheck,
    'No UnifiedPush distributor found. Install ntfy (F-Droid or GitHub) and try again.' =>
      errNoDistributor,
    'Set a screen lock (PIN, pattern, password or biometrics) to store SSH keys.' =>
      errNeedsScreenLock,
    'The screen lock or biometrics changed, so this key can no longer be unlocked. '
        'Pair the host again.' =>
      errKeyInvalidated,
    'The host rejected pairing. Check that both devices use the same Tailscale account '
        'and that the code is still valid.' =>
      errPairingRejected,
    'Could not reach the host. Check that Tailscale is on and openmosh-hook pair is still '
        'running.' =>
      errPairingUnreachable,
    'Discarded an invalid push message.' => errInvalidPush,
    'Enter a hostname or IP address.' => errEnterAddress,
    'Enter a valid user name.' => errEnterUser,
    'Event not found.' => errEventNotFound,
    'Files are limited to 50 MB.' => errFileTooLarge,
    'Host is not paired for push.' => errNotPairedForPush,
    'Invalid host key fingerprint.' => errInvalidFingerprint,
    'Invalid identifier.' => errInvalidIdentifier,
    'Message is longer than 4 KiB.' => errMessageTooLong,
    'Name must be 1–64 characters.' => errNameLength,
    'Pairing reply is too large.' => errPairingReplyTooLarge,
    'Pairing request is too large.' => errPairingRequestTooLarge,
    'Port must be 1–65535.' => errPortRange,
    'The host closed the connection.' => errHostClosed,
    'The host did not answer in time.' => errHostTimeout,
    'The host sent an invalid pairing response.' => errInvalidPairingResponse,
    'The pairing connection failed.' => errPairingFailed,
    'The push distributor did not answer. Open ntfy and retry.' => errDistributorNoAnswer,
    'The push distributor refused the registration.' => errDistributorRefused,
    'The push endpoint must use https.' => errEndpointHttps,
    'This key is missing. Pair the host again.' => errKeyMissing,
    'Unexpected pairing reply.' => errUnexpectedPairingReply,
    'Unknown host.' => errUnknownHost,
    'Unreadable file size.' => errUnreadableFileSize,
    'Write a message first.' => errWriteMessageFirst,
    'Host command failed.' => errHostCommandFailed,
    'openmosh-hook is not installed on this host.' => errHookMissing,
    'openmosh-hook returned unexpected output.' => errHookUnexpectedOutput,
    'Update openmosh-hook on this computer to see usage.' => errHookOutdatedUsage,
    'The period must be 1–31 days.' => errUsagePeriod,
    'Upload failed.' => errUploadFailed,
    'The data is too large.' => errDataTooLarge,
    'That is not an ssh-ed25519 private key, or the passphrase is wrong.' => errKeyImportFailed,
    'That is not a usable ssh-ed25519 private key.' => errNotUsableKey,
    'Could not verify you, so the lock stays off. Set up a fingerprint, face or screen '
        'lock on this phone, then try again.' =>
      errLockStaysOff,
    'Could not verify you, so the lock stays on.' => errLockStaysOn,
    'This event was already answered.' => errAlreadyAnswered,
    'Herdr no longer has that item. The list was refreshed.' => errHerdrInvalid,
    'Herdr is not running on this computer.' => errHerdrNotRunning,
    'Herdr refused the request.' => errHerdrRefused,
    'Update openmosh-hook on this computer to use the Herdr navigator.' => errHerdrHookOutdated,
    'Message is longer than 4000 characters.' => errMessageTooLong4000,
    _ => message,
  };
}
