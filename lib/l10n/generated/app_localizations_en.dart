// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Retry';

  @override
  String get save => 'Save';

  @override
  String get continueAction => 'Continue';

  @override
  String get delete => 'Delete';

  @override
  String get dismiss => 'Dismiss';

  @override
  String get notFound => 'Not found';

  @override
  String get logoSemanticLabel => 'Falconer logo';

  @override
  String get somethingWentWrong => 'Something went wrong.';

  @override
  String get navHosts => 'Hosts';

  @override
  String get navInbox => 'Inbox';

  @override
  String get navKeys => 'Keys';

  @override
  String get navSettings => 'Settings';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeSecondsAgo(int count) {
    return '$count s ago';
  }

  @override
  String timeMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count d ago';
  }

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get hostKeyChangedTitle => 'Host key changed';

  @override
  String get hostKeyChangedBody =>
      'The server presented a different key than the one pinned at pairing. This can mean someone is intercepting the connection. The connection was blocked. If you reinstalled the host on purpose, delete this host and pair it again.';

  @override
  String get fingerprintPinned => 'Pinned';

  @override
  String get fingerprintPresented => 'Presented';

  @override
  String get noComputersTitle => 'No computers yet';

  @override
  String get noComputersBody => 'Run `falconer-hook pair` on your computer, then scan the code.';

  @override
  String get scanPairingCode => 'Scan pairing code';

  @override
  String get addHostManually => 'Add host manually';

  @override
  String get allQuiet => 'All quiet.';

  @override
  String allGoodExcept(String alias, int more) {
    String _temp0 = intl.Intl.pluralLogic(
      more,
      locale: localeName,
      other: 'All good,\nexcept $alias and $more more.',
      zero: 'All good,\nexcept $alias.',
    );
    return '$_temp0';
  }

  @override
  String computersPairedNothingWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count computers paired. Nothing is waiting for you.',
      one: '1 computer paired. Nothing is waiting for you.',
    );
    return '$_temp0';
  }

  @override
  String agentWaitingForAnswer(String agent) {
    return '$agent is waiting for your answer.';
  }

  @override
  String inboxTileSemantics(int today, int waiting) {
    return 'Inbox, $today events today, $waiting waiting';
  }

  @override
  String get today => 'Today';

  @override
  String eventCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count events',
      one: '1 event',
    );
    return '$_temp0';
  }

  @override
  String waitingCount(int count) {
    return '$count waiting';
  }

  @override
  String get pairTileSemantics => 'Pair a computer with a QR code';

  @override
  String get addTile => 'Add';

  @override
  String get pairWithQr => 'Pair with QR';

  @override
  String get yourComputers => 'Your computers';

  @override
  String get aHost => 'a host';

  @override
  String get host => 'host';

  @override
  String get needsYou => 'Needs you';

  @override
  String reviewRequestSemantics(String alias, String agent, String what) {
    return 'Review request from $alias, $agent: $what';
  }

  @override
  String get badgePush => 'push';

  @override
  String get badgeNoPush => 'no push';

  @override
  String waitingForYou(int count) {
    return '$count waiting for you';
  }

  @override
  String get terminal => 'Terminal';

  @override
  String get sessions => 'Sessions';

  @override
  String get editHost => 'Edit host';

  @override
  String get deleteHost => 'Delete host';

  @override
  String get addHost => 'Add host';

  @override
  String get notificationsOn => 'Notifications on';

  @override
  String get notificationsOff => 'Notifications off';

  @override
  String get agentStateWaiting => 'waiting';

  @override
  String get agentStateWorking => 'working';

  @override
  String get agentStateDone => 'done';

  @override
  String get agentStateIdle => 'idle';

  @override
  String get agentStateUnknown => 'unknown';

  @override
  String get shell => 'Shell';

  @override
  String get loadSessions => 'Load sessions';

  @override
  String get refresh => 'Refresh';

  @override
  String get enableNotifications => 'Enable notifications';

  @override
  String get noSessions => 'No Herdr or tmux sessions';

  @override
  String sessionAttached(String kind) {
    return '$kind · attached';
  }

  @override
  String get agents => 'Agents';

  @override
  String get noAgents => 'No agents running';

  @override
  String get pinnedHostKey => 'Pinned host key';

  @override
  String get openingHost => 'Opening host';

  @override
  String get deleteHostTitle => 'Delete host?';

  @override
  String get deleteHostBody =>
      'Removes the host, its pinned key and its inbox from this phone. To also remove this phone from the host, revoke it under Paired devices first.';

  @override
  String get revokeThisPhoneTitle => 'Revoke this phone?';

  @override
  String revokeDeviceTitle(String name) {
    return 'Revoke $name?';
  }

  @override
  String revokeThisPhoneBody(String alias) {
    return 'This is the phone you are using. Falconer will lose access to $alias: the host removes its SSH key and push key. Pair again to get access back.';
  }

  @override
  String revokeDeviceBody(String alias) {
    return 'Removes its SSH key and push key from $alias. It can no longer connect or get notifications.';
  }

  @override
  String get revoke => 'Revoke';

  @override
  String deviceRevoked(String name) {
    return '$name was revoked.';
  }

  @override
  String thisPhoneRevoked(String alias) {
    return 'This phone was revoked from $alias. Pair again or delete the host.';
  }

  @override
  String get pairedDevices => 'Paired devices';

  @override
  String get showPairedDevices => 'Show paired devices';

  @override
  String get noPairedDevices => 'No devices are paired with this host.';

  @override
  String get badgeThisPhone => 'this phone';

  @override
  String pairedOn(String date) {
    return 'Paired $date';
  }

  @override
  String pairedOnStale(String date) {
    return 'Paired $date · endpoint stale';
  }

  @override
  String revokeDeviceTooltip(String name) {
    return 'Revoke $name';
  }

  @override
  String get fieldName => 'Name';

  @override
  String get fieldAddress => 'Hostname or Tailscale IP';

  @override
  String get fieldPort => 'Port';

  @override
  String get fieldUser => 'User';

  @override
  String get fieldKey => 'Key';

  @override
  String get thisDeviceKey => 'This device (Ed25519)';

  @override
  String get checkingHostKey => 'Checking host key…';

  @override
  String verifyHostKeyOf(String address) {
    return 'Verify the host key of $address';
  }

  @override
  String get verifyHostKeyHelp =>
      'On the host run:\n  ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub\nTrust it only if the fingerprint is identical. It will be pinned, and any later change will block the connection.';

  @override
  String get presentedHostKey => 'Presented host key';

  @override
  String get trustAndSave => 'It matches — trust and save';

  @override
  String get eventNotFound => 'Event not found';

  @override
  String get eventMayBeCleared => 'It may have been cleared.';

  @override
  String get badgeQuestion => 'question';

  @override
  String get badgeNeedsApproval => 'needs approval';

  @override
  String get badgeSending => 'sending…';

  @override
  String get badgeFailed => 'failed';

  @override
  String get badgeResolved => 'resolved';

  @override
  String get badgeDone => 'done';

  @override
  String get responseAllow => 'allow';

  @override
  String get responseDeny => 'deny';

  @override
  String get responseText => 'text';

  @override
  String get noAgentEventsTitle => 'No agent events yet.';

  @override
  String get noAgentEventsBody => 'When an agent on a paired computer needs you, it shows up here.';

  @override
  String get nothingWaiting => 'Nothing waiting for you.';

  @override
  String requestsWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests wait for you.',
      one: '1 request waits for you.',
    );
    return '$_temp0';
  }

  @override
  String agentOnHost(String agent, String alias) {
    return '$agent on $alias';
  }

  @override
  String agentAsks(String agent) {
    return '$agent asks';
  }

  @override
  String get agentNeedsYou => 'Agent needs you';

  @override
  String get alreadyAnswered => 'Already answered.';

  @override
  String get nothingToAnswer => 'Nothing to answer.';

  @override
  String youPickedInNotification(String action) {
    return 'You picked \"$action\" in the notification. Confirm below.';
  }

  @override
  String get approve => 'Approve';

  @override
  String get deny => 'Deny';

  @override
  String get reply => 'Reply';

  @override
  String get replyToAgent => 'Reply to the agent';

  @override
  String get openTerminal => 'Open terminal';

  @override
  String get sendReply => 'Send reply';

  @override
  String get asksVerificationBeforeSending =>
      'Asks for your fingerprint or screen lock before sending.';

  @override
  String get confirmAnswerReason => 'Confirm your answer to the agent';

  @override
  String get pairAHost => 'Pair a host';

  @override
  String get cameraPermissionDenied =>
      'Falconer cannot use the camera. Allow it in Android Settings > Apps > Falconer > Permissions > Camera, then tap Retry.';

  @override
  String get cameraUnavailable =>
      'The camera could not start. Close other apps using it and tap Retry.';

  @override
  String get newComputer => 'New computer';

  @override
  String pairWith(String ip) {
    return 'Pair with $ip';
  }

  @override
  String get pairReviewSubtitle =>
      'The host proves itself with the key in the code; its name and SSH host key fingerprint are pinned from its encrypted reply.';

  @override
  String get nameForThisPhone => 'Name for this phone';

  @override
  String get defaultDeviceName => 'Android phone';

  @override
  String get defaultDeviceNameIphone => 'iPhone';

  @override
  String get defaultDeviceNameIpad => 'iPad';

  @override
  String get defaultDeviceNameMac => 'Mac';

  @override
  String get pairReviewNote =>
      'This creates an SSH key on this phone, authorizes it on the host only from your tailnet, and registers encrypted notifications.';

  @override
  String get pairing => 'Pairing…';

  @override
  String get pair => 'Pair';

  @override
  String get pasteLinkLabel => 'Or paste the openmosh://pair link';

  @override
  String get pasteLinkHelper => 'Print it on the host with: falconer-hook pair --uri';

  @override
  String pairedWith(String alias) {
    return 'Paired with $alias';
  }

  @override
  String get pairedBody => 'Its SSH host key is pinned and notifications are encrypted end to end.';

  @override
  String get openHost => 'Open host';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get colors => 'Colors';

  @override
  String colorsSummary(String accent, String theme, String scheme) {
    return '$accent accent · $theme · $scheme terminal';
  }

  @override
  String get themeSummarySystem => 'system theme';

  @override
  String get themeSummaryLight => 'light theme';

  @override
  String get themeSummaryDark => 'dark theme';

  @override
  String get notificationPreviews => 'Notification previews';

  @override
  String get notificationPreviewsBody =>
      'Off: notifications only say \"<host>: <agent> needs you\". On: they show the request text, hidden on the lock screen.';

  @override
  String get keepConnected => 'Keep sessions connected';

  @override
  String get keepConnectedBody =>
      'Terminals stay open and keep reconnecting after you leave them, until you disconnect or close the app.';

  @override
  String get lockApp => 'Lock Falconer';

  @override
  String get lockAppBody =>
      'Ask for your fingerprint, face or screen lock when Falconer opens and after a minute in the background. Turning it on or off asks for it too.';

  @override
  String terminalFontSize(String size) {
    return 'Terminal font size · $size';
  }

  @override
  String get shortcutRow => 'Shortcut row';

  @override
  String get presetNone => 'None';

  @override
  String get herdrPrefix => 'Herdr prefix';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get privacy => 'Privacy';

  @override
  String get privacyBody =>
      'No accounts, analytics or crash reporting. The app only talks to your hosts over Tailscale and to your UnifiedPush server, which sees ciphertext only. Voice models are downloaded only when you ask, and speech is turned into text on the phone.';

  @override
  String get colorsCaption => 'Settings › Colors';

  @override
  String get sectionAccent => 'Accent';

  @override
  String get sectionApp => 'App';

  @override
  String get sectionTerminal => 'Terminal';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get contrastNote =>
      'Every accent is checked for 4.5:1 contrast in the light and dark themes.';

  @override
  String get preview => 'Preview';

  @override
  String accentSemantics(String accent) {
    return '$accent accent';
  }

  @override
  String schemeSemantics(String scheme) {
    return '$scheme terminal';
  }

  @override
  String get accentBlue => 'Blue';

  @override
  String get accentGreen => 'Green';

  @override
  String get accentViolet => 'Violet';

  @override
  String get accentAmber => 'Amber';

  @override
  String get accentCoral => 'Coral';

  @override
  String get accentWhite => 'White';

  @override
  String get schemeBlack => 'Black';

  @override
  String get schemePaper => 'Paper';

  @override
  String get schemeSepia => 'Sepia';

  @override
  String get schemeHighContrast => 'High contrast';

  @override
  String get schemeHighContrastShort => 'High';

  @override
  String get errHostKeyChanged => 'Host key changed. The connection was blocked.';

  @override
  String get errAuthRejected => 'The host rejected this device key.';

  @override
  String get errAuthTimeout =>
      'The host did not answer the SSH key. If Tailscale SSH is enabled on it, run: sudo tailscale set --ssh=false';

  @override
  String get errCannotReachHost => 'Could not reach the host.';

  @override
  String get errUnlockCancelled => 'Unlock was cancelled.';

  @override
  String get errAddressNeedsNewCheck =>
      'Changing address or port needs a new host key check. Add the host again.';

  @override
  String get errNoDistributor =>
      'No UnifiedPush distributor found. Install ntfy (F-Droid or GitHub) and try again.';

  @override
  String get errNeedsScreenLock =>
      'Set a screen lock (PIN, pattern, password or biometrics) to store SSH keys.';

  @override
  String get errKeyInvalidated =>
      'The screen lock or biometrics changed, so this key can no longer be unlocked. Pair the host again.';

  @override
  String get errPairingRejected =>
      'The host rejected pairing. Check that both devices use the same Tailscale account and that the code is still valid.';

  @override
  String get errPairingUnreachable =>
      'Could not reach the host. Check that Tailscale is on and falconer-hook pair is still running.';

  @override
  String get errInvalidPush => 'Discarded an invalid push message.';

  @override
  String get errEnterAddress => 'Enter a hostname or IP address.';

  @override
  String get errEnterUser => 'Enter a valid user name.';

  @override
  String get errEventNotFound => 'Event not found.';

  @override
  String get errFileTooLarge => 'Files are limited to 50 MB.';

  @override
  String get errNotPairedForPush => 'Host is not paired for push.';

  @override
  String get errInvalidFingerprint => 'Invalid host key fingerprint.';

  @override
  String get errInvalidIdentifier => 'Invalid identifier.';

  @override
  String get errMessageTooLong => 'Message is longer than 4 KiB.';

  @override
  String get errNameLength => 'Name must be 1–64 characters.';

  @override
  String get errPairingReplyTooLarge => 'Pairing reply is too large.';

  @override
  String get errPairingRequestTooLarge => 'Pairing request is too large.';

  @override
  String get errPortRange => 'Port must be 1–65535.';

  @override
  String get errHostClosed => 'The host closed the connection.';

  @override
  String get errHostTimeout => 'The host did not answer in time.';

  @override
  String get errInvalidPairingResponse => 'The host sent an invalid pairing response.';

  @override
  String get errPairingFailed => 'The pairing connection failed.';

  @override
  String get errDistributorNoAnswer => 'The push distributor did not answer. Open ntfy and retry.';

  @override
  String get errDistributorRefused => 'The push distributor refused the registration.';

  @override
  String get errEndpointHttps => 'The push endpoint must use https.';

  @override
  String get errKeyMissing => 'This key is missing. Pair the host again.';

  @override
  String get errUnexpectedPairingReply => 'Unexpected pairing reply.';

  @override
  String get errUnknownHost => 'Unknown host.';

  @override
  String get errUnreadableFileSize => 'Unreadable file size.';

  @override
  String get errWriteMessageFirst => 'Write a message first.';

  @override
  String get errHostCommandFailed => 'Host command failed.';

  @override
  String get errHookMissing => 'falconer-hook is not installed on this host.';

  @override
  String get errHookUnexpectedOutput => 'falconer-hook returned unexpected output.';

  @override
  String get errUploadFailed => 'Upload failed.';

  @override
  String get errDataTooLarge => 'The data is too large.';

  @override
  String get errKeyImportFailed =>
      'That is not an ssh-ed25519 private key, or the passphrase is wrong.';

  @override
  String get errNotUsableKey => 'That is not a usable ssh-ed25519 private key.';

  @override
  String get errLockStaysOff =>
      'Could not verify you, so the lock stays off. Set up a fingerprint, face or screen lock on this phone, then try again.';

  @override
  String get errLockStaysOn => 'Could not verify you, so the lock stays on.';

  @override
  String get errAlreadyAnswered => 'This event was already answered.';

  @override
  String get errReplyNotSubmitted =>
      'Your reply was typed but not sent. Press Enter in the terminal.';

  @override
  String get terminalTitle => 'Terminal';

  @override
  String get terminalShell => 'shell';

  @override
  String terminalHostShell(String host) {
    return '$host · shell';
  }

  @override
  String terminalHostSession(String host, String kind) {
    return '$host · $kind';
  }

  @override
  String get terminalHostFallback => 'host';

  @override
  String get terminalSessionFallback => 'session';

  @override
  String get fullScreen => 'Full screen';

  @override
  String get exitFullScreen => 'Exit full screen';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get terminalChat => 'Chat';

  @override
  String get typeInTerminal => 'Type in the terminal';

  @override
  String get keyboard => 'Keyboard';

  @override
  String get smallerText => 'Smaller text';

  @override
  String get largerText => 'Larger text';

  @override
  String get paste => 'Paste';

  @override
  String get addShortcut => 'Add shortcut';

  @override
  String get copy => 'Copy';

  @override
  String get clearSelection => 'Clear selection';

  @override
  String get copied => 'Copied';

  @override
  String removeShortcutTitle(String label) {
    return 'Remove \"$label\"?';
  }

  @override
  String get remove => 'Remove';

  @override
  String get attachPhotos => 'Photos';

  @override
  String get attachFile => 'File';

  @override
  String get connecting => 'Connecting…';

  @override
  String get reconnecting => 'Reconnecting…';

  @override
  String get chatAttach => 'Attach images or files';

  @override
  String get chatHint => 'Message the agent…';

  @override
  String get chatClose => 'Close chat';

  @override
  String get chatSend => 'Send';

  @override
  String chatRemoveAttachment(String name) {
    return 'Remove $name';
  }

  @override
  String get sessionEndedTitle => 'The session ended.';

  @override
  String get sessionEndedBody => 'The shell on the computer exited. Start it again or go back.';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get shortcutCtrlKey => 'Ctrl + key';

  @override
  String get shortcutText => 'Text';

  @override
  String get shortcutLetter => 'Letter';

  @override
  String get shortcutTextToSend => 'Text to send';

  @override
  String get shortcutLabelOptional => 'Label (optional)';

  @override
  String get shortcutPressEnter => 'Press Enter after the text';

  @override
  String get shortcutAdd => 'Add';

  @override
  String shortcutAddNamed(String label) {
    return 'Add $label';
  }

  @override
  String get moreKeys => 'More keys';

  @override
  String get fewerKeys => 'Fewer keys';

  @override
  String get keysTitle => 'Keys';

  @override
  String get keysEmpty =>
      'No keys yet. Pairing creates this device\'s key, or generate/import one.';

  @override
  String get generateKey => 'Generate key';

  @override
  String get importKey => 'Import key';

  @override
  String get copyPublicKey => 'Copy public key';

  @override
  String get publicKeyCopied => 'Public key copied';

  @override
  String generatedKeyLabel(String date) {
    return 'Key $date';
  }

  @override
  String get importedKeyLabel => 'Imported key';

  @override
  String deleteKeyTitle(String label) {
    return 'Delete $label?';
  }

  @override
  String get deleteKeyBody =>
      'Hosts that use this key will stop connecting until you pair them again.';

  @override
  String get importKeyTitle => 'Import ssh-ed25519 key';

  @override
  String get keyLabel => 'Label';

  @override
  String get pastePrivateKey => 'Paste the OpenSSH private key';

  @override
  String get importAction => 'Import';

  @override
  String get lockedTitle => 'Falconer is locked';

  @override
  String get lockedBody => 'Verify it is you to continue.';

  @override
  String get unlock => 'Unlock';

  @override
  String get lockPromptUnlock => 'Unlock Falconer';

  @override
  String get lockPromptTurnOn => 'Turn on the Falconer lock';

  @override
  String get lockPromptTurnOff => 'Turn off the Falconer lock';

  @override
  String get pairedWithoutPush =>
      'Notifications are off: the push app (ntfy) did not answer. Open ntfy, then tap Enable notifications on this host.';

  @override
  String get arrowUp => 'Up';

  @override
  String get arrowDown => 'Down';

  @override
  String get arrowLeft => 'Left';

  @override
  String get arrowRight => 'Right';

  @override
  String get agentUsage => 'Agent usage';

  @override
  String get usageSubtitle => 'Tokens your agents recorded on this computer.';

  @override
  String get usagePeriod => 'Period';

  @override
  String usageDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String usagePeriodTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last $count days',
      one: 'Last day',
    );
    return '$_temp0';
  }

  @override
  String usageBreakdown(String input, String output, String cache) {
    return 'In $input · Out $output · Cache $cache';
  }

  @override
  String get usagePlanLimits => 'Plan limits';

  @override
  String usagePercentUsed(String percent) {
    return '$percent% used';
  }

  @override
  String usageResetsIn(String time) {
    return 'Resets in $time';
  }

  @override
  String get usageResetsSoon => 'Resets soon';

  @override
  String get usageProjects => 'Projects';

  @override
  String get usageModels => 'Models';

  @override
  String usageNotRecorded(int count) {
    return 'Not recorded ($count)';
  }

  @override
  String get usageNotRecordedHint => 'These agents leave no local usage logs to read.';

  @override
  String get usageEmpty => 'No agent usage recorded in this period.';

  @override
  String get usageLoading => 'Reading usage…';

  @override
  String get errHookOutdatedUsage => 'Update falconer-hook on this computer to see usage.';

  @override
  String get errUsagePeriod => 'The period must be 1–31 days.';

  @override
  String get notifyHours => 'Notification hours';

  @override
  String get notifyHoursBody =>
      'Outside these hours, events still reach the inbox, without sound or a notification.';

  @override
  String get notifyAlways => 'Always';

  @override
  String notifyBetween(String from, String to) {
    return '$from – $to';
  }

  @override
  String notifyUsesApp(String hours) {
    return 'App setting: $hours';
  }

  @override
  String get notifyUseAppSetting => 'Use the app setting';

  @override
  String get notifyOnlyBetween => 'Only between';

  @override
  String get notifyFrom => 'From';

  @override
  String get notifyTo => 'To';

  @override
  String get appTheme => 'Theme';

  @override
  String get openHerdr => 'Open Herdr';

  @override
  String get openHerdrHint =>
      'Opens the Herdr session with mirroring: the computer follows the tab and workspace you pick here.';

  @override
  String get showSensitive => 'Show';

  @override
  String get hideSensitive => 'Hide';

  @override
  String get showToCompare => 'Show to compare';

  @override
  String get copyPublicKeyTitle => 'Copy the public key?';

  @override
  String get copyPublicKeyBody =>
      'It is marked as sensitive on the clipboard. Paste it only on computers you trust.';

  @override
  String get verifyToShowTerminal => 'Verify it\'s you to show the open terminal';

  @override
  String get showFullText => 'Show full text';

  @override
  String get showLess => 'Show less';

  @override
  String get keyPassphrase => 'Passphrase (if the key has one)';

  @override
  String get chooseKeyFile => 'Choose file';

  @override
  String get pairConfirmOnComputer =>
      'Confirm on your computer: type y in the terminal where falconer-hook pair is running.';

  @override
  String get enterKey => 'Enter';

  @override
  String get voiceTitle => 'Voice input';

  @override
  String get voiceSummaryNone => 'No model yet: tap to set up';

  @override
  String get voiceIntro =>
      'Dictate into the chat with the mic button. Speech becomes text on this phone and the audio is never saved or sent. Models are downloaded only when you tap Download, once, and stay until you delete them.';

  @override
  String get voiceLanguage => 'Spoken language';

  @override
  String get voiceLanguageAuto => 'Automatic';

  @override
  String get voiceLanguageAutoOnly => 'This model detects the language by itself.';

  @override
  String get voiceEnglishOnly => 'English only';

  @override
  String voiceLanguagesCount(int count) {
    return '$count languages';
  }

  @override
  String get voiceRecommended => 'Recommended';

  @override
  String get voiceCustomBadge => 'Your model';

  @override
  String get voiceModels => 'Models';

  @override
  String get voiceDownload => 'Download';

  @override
  String voiceDownloadTitle(String name) {
    return 'Download $name?';
  }

  @override
  String voiceDownloadBody(String size, String host) {
    return '$size will be downloaded from $host and checked against its SHA-256 before use. Use Wi-Fi if your mobile data is limited.';
  }

  @override
  String voiceDownloadBodyUnknown(String host) {
    return 'The size is unknown until the download starts. It comes from $host and is checked against its SHA-256 before use.';
  }

  @override
  String get voiceUnpacking => 'Checking and unpacking…';

  @override
  String get voiceVerifying => 'Checking the files…';

  @override
  String get voiceCancelDownload => 'Cancel download';

  @override
  String get voiceUse => 'Use';

  @override
  String get voiceInUse => 'In use';

  @override
  String get voiceDelete => 'Delete model';

  @override
  String voiceDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get voiceDeleteBody =>
      'The files are removed from the phone. You can download the model again later.';

  @override
  String get voiceDeleteCustomBody => 'The files and this entry are removed from the phone.';

  @override
  String voiceReady(String name) {
    return '$name is ready.';
  }

  @override
  String get voiceChecksum => 'The download did not match its SHA-256 and was deleted.';

  @override
  String get voiceMissingFiles => 'The archive does not have the files this model type needs.';

  @override
  String get voiceUnsafe =>
      'The archive was refused: it tries to write outside its folder or contains links.';

  @override
  String get voiceDownloadFailed => 'The download failed. Check the connection and try again.';

  @override
  String get voiceAddCustom => 'Add a model';

  @override
  String get voiceAddCustomBody =>
      'A sherpa-onnx .tar.bz2 archive over HTTPS, with its SHA-256. It is downloaded only when you tap Download.';

  @override
  String get voiceCustomName => 'Name';

  @override
  String get voiceCustomUrl => 'Archive URL (https://…tar.bz2)';

  @override
  String get voiceCustomSha => 'SHA-256 of the archive';

  @override
  String get voiceCustomFamily => 'Model type';

  @override
  String get voiceCustomLanguages => 'Languages (optional, e.g. es, en)';

  @override
  String get voiceErrName => 'Enter a name.';

  @override
  String get voiceErrUrl => 'Use an https:// address.';

  @override
  String get voiceErrSha => 'Enter the 64 hexadecimal characters of the SHA-256.';

  @override
  String get voiceErrLanguages => 'Use language codes such as es, en, pt, separated by commas.';

  @override
  String get voiceDictate => 'Dictate';

  @override
  String get voiceStop => 'Stop and transcribe';

  @override
  String get voiceTranscribing => 'Transcribing…';

  @override
  String get voiceMicDenied => 'Dictation needs the microphone permission.';

  @override
  String get voiceFailed => 'Could not transcribe. Try again.';

  @override
  String get herdrNavigator => 'Agents & workspaces';

  @override
  String get herdrNavigatorHint =>
      'Browse Herdr workspaces, tabs and agents and answer agents with buttons.';

  @override
  String get herdrStatusBlocked => 'needs you';

  @override
  String get herdrFocused => 'on screen';

  @override
  String get herdrShellPane => 'Terminal';

  @override
  String get herdrNewWorkspace => 'New workspace';

  @override
  String get herdrNewTab => 'New tab';

  @override
  String get herdrRename => 'Rename';

  @override
  String get herdrCreate => 'Create';

  @override
  String get herdrStartAgent => 'Start an agent';

  @override
  String get herdrStartAgentIn => 'Start an agent in this pane';

  @override
  String herdrCloseWorkspaceTitle(String name) {
    return 'Close workspace $name?';
  }

  @override
  String herdrCloseTabTitle(String name) {
    return 'Close tab $name?';
  }

  @override
  String get herdrCloseBody => 'Everything running in it on the computer stops.';

  @override
  String get herdrName => 'Name';

  @override
  String get herdrNameOptional => 'Name (optional)';

  @override
  String get herdrEmpty => 'This Herdr session has no workspaces.';

  @override
  String get herdrNoTabs => 'No tabs';

  @override
  String get herdrLoading => 'Reading Herdr…';

  @override
  String get herdrMoreActions => 'More actions';

  @override
  String get herdrPickPane => 'Pick an agent to see it here.';

  @override
  String get herdrTerminalMode => 'Terminal mode';

  @override
  String get herdrGraphicMode => 'Graphic mode';

  @override
  String get herdrNoFocusedPane => 'No pane is focused in Herdr.';

  @override
  String get herdrOutOfDate => 'Showing the last state; trying to reach Herdr again.';

  @override
  String get agentViewLoadEarlier => 'Load earlier';

  @override
  String get agentViewEmpty => 'The pane is empty.';

  @override
  String agentViewNeedsPermission(String agent) {
    return '$agent needs your permission';
  }

  @override
  String agentViewIsAsking(String agent) {
    return '$agent is asking';
  }

  @override
  String get agentViewCurrentOption => 'current option';

  @override
  String get agentViewSending => 'sending';

  @override
  String agentViewDraft(String text) {
    return 'Typed on the computer: $text';
  }

  @override
  String get herdrKeyUp => 'Up';

  @override
  String get herdrKeyDown => 'Down';

  @override
  String get herdrKeyEsc => 'Esc';

  @override
  String get herdrKeyEnter => 'Enter';

  @override
  String get herdrKeyTab => 'Tab';

  @override
  String get errHerdrInvalid => 'Herdr no longer has that item. The list was refreshed.';

  @override
  String get errHerdrNotRunning => 'Herdr is not running on this computer.';

  @override
  String get errHerdrRefused => 'Herdr refused the request.';

  @override
  String get errHerdrHookOutdated =>
      'Update falconer-hook on this computer to use the Herdr navigator.';

  @override
  String get errMessageTooLong4000 => 'Message is longer than 4000 characters.';

  @override
  String get herdrViewAsAgents => 'View as agents';

  @override
  String get herdrNewTerminal => 'New terminal';

  @override
  String herdrAgentCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count agents',
      one: '1 agent',
    );
    return '$_temp0';
  }

  @override
  String herdrTerminalCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terminals',
      one: '1 terminal',
    );
    return '$_temp0';
  }

  @override
  String get herdrWorkspaceGone => 'This workspace is no longer open.';

  @override
  String get herdrPickWorkspace => 'Pick a workspace to see its terminals.';

  @override
  String get webPushTitle => 'Web notifications (iOS / browser)';

  @override
  String get webPushExplain =>
      'Install the Falconer Notifications web app, enable notifications there, then copy its code and paste it here. Links that open the app are not accepted.';

  @override
  String get webPushStatusOff => 'Not set';

  @override
  String webPushStatusOn(String service) {
    return 'Active via $service';
  }

  @override
  String get webPushPasteHint => 'Paste code';

  @override
  String get webPushReview => 'Review code';

  @override
  String get webPushTurnOff => 'Turn off';

  @override
  String get webPushTurnedOff => 'Web notifications turned off.';

  @override
  String get webPushUse => 'Use for notifications';

  @override
  String get webPushScreenTitle => 'Web notifications';

  @override
  String get webPushConfirmBody =>
      'Your paired hosts will use this registration to notify this device through the web app.';

  @override
  String get webPushServiceLabel => 'Push service';

  @override
  String webPushDestination(String service) {
    return 'Notifications will be sent to $service.';
  }

  @override
  String get webPushReplaces =>
      'This replaces where your paired hosts send web notifications. Continue only if you copied this code from your own Falconer Notifications web app.';

  @override
  String get webPushSending => 'Sending to your hosts…';

  @override
  String get webPushNoHosts =>
      'No paired hosts yet. Pair a host and it will receive this automatically.';

  @override
  String webPushHostDelivered(String host) {
    return '$host: delivered';
  }

  @override
  String webPushHostPending(String host) {
    return '$host: pending, will be sent when the host connects';
  }

  @override
  String webPushHostTooOld(String host) {
    return '$host: update falconer-hook (hook too old)';
  }

  @override
  String get webPushDone => 'Done';

  @override
  String get errWebPushCode => 'This is not a valid web notifications code.';

  @override
  String get errWebPushVersion =>
      'This web notifications code is from another Falconer version. Update the app.';
}
