import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es')];

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @dismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get dismiss;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not found'**
  String get notFound;

  /// Accessibility label of the mascot.
  ///
  /// In en, this message translates to:
  /// **'OpenMosh mole'**
  String get moleSemanticLabel;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.'**
  String get somethingWentWrong;

  /// Bottom dock tab.
  ///
  /// In en, this message translates to:
  /// **'Hosts'**
  String get navHosts;

  /// Bottom dock tab.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get navInbox;

  /// Bottom dock tab.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get navKeys;

  /// Bottom dock tab.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} s ago'**
  String timeSecondsAgo(int count);

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String timeDaysAgo(int count);

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @hostKeyChangedTitle.
  ///
  /// In en, this message translates to:
  /// **'Host key changed'**
  String get hostKeyChangedTitle;

  /// No description provided for @hostKeyChangedBody.
  ///
  /// In en, this message translates to:
  /// **'The server presented a different key than the one pinned at pairing. This can mean someone is intercepting the connection. The connection was blocked. If you reinstalled the host on purpose, delete this host and pair it again.'**
  String get hostKeyChangedBody;

  /// Label of the pinned host key fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Pinned'**
  String get fingerprintPinned;

  /// Label of the presented host key fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Presented'**
  String get fingerprintPresented;

  /// No description provided for @noComputersTitle.
  ///
  /// In en, this message translates to:
  /// **'No computers yet'**
  String get noComputersTitle;

  /// No description provided for @noComputersBody.
  ///
  /// In en, this message translates to:
  /// **'Run `openmosh-hook pair` on your computer, then scan the code.'**
  String get noComputersBody;

  /// No description provided for @scanPairingCode.
  ///
  /// In en, this message translates to:
  /// **'Scan pairing code'**
  String get scanPairingCode;

  /// No description provided for @addHostManually.
  ///
  /// In en, this message translates to:
  /// **'Add host manually'**
  String get addHostManually;

  /// No description provided for @allQuiet.
  ///
  /// In en, this message translates to:
  /// **'All quiet.'**
  String get allQuiet;

  /// Home headline; {alias} is highlighted.
  ///
  /// In en, this message translates to:
  /// **'{more, plural, =0{All good,\nexcept {alias}.} other{All good,\nexcept {alias} and {more} more.}}'**
  String allGoodExcept(String alias, int more);

  /// No description provided for @computersPairedNothingWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 computer paired. Nothing is waiting for you.} other{{count} computers paired. Nothing is waiting for you.}}'**
  String computersPairedNothingWaiting(int count);

  /// No description provided for @agentWaitingForAnswer.
  ///
  /// In en, this message translates to:
  /// **'{agent} is waiting for your answer.'**
  String agentWaitingForAnswer(String agent);

  /// No description provided for @inboxTileSemantics.
  ///
  /// In en, this message translates to:
  /// **'Inbox, {today} events today, {waiting} waiting'**
  String inboxTileSemantics(int today, int waiting);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @eventCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 event} other{{count} events}}'**
  String eventCount(int count);

  /// No description provided for @waitingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String waitingCount(int count);

  /// No description provided for @pairTileSemantics.
  ///
  /// In en, this message translates to:
  /// **'Pair a computer with a QR code'**
  String get pairTileSemantics;

  /// No description provided for @addTile.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addTile;

  /// No description provided for @pairWithQr.
  ///
  /// In en, this message translates to:
  /// **'Pair with QR'**
  String get pairWithQr;

  /// No description provided for @yourComputers.
  ///
  /// In en, this message translates to:
  /// **'Your computers'**
  String get yourComputers;

  /// Fallback when the host of an event is unknown.
  ///
  /// In en, this message translates to:
  /// **'a host'**
  String get aHost;

  /// Fallback host name.
  ///
  /// In en, this message translates to:
  /// **'host'**
  String get host;

  /// No description provided for @needsYou.
  ///
  /// In en, this message translates to:
  /// **'Needs you'**
  String get needsYou;

  /// No description provided for @reviewRequestSemantics.
  ///
  /// In en, this message translates to:
  /// **'Review request from {alias}, {agent}: {what}'**
  String reviewRequestSemantics(String alias, String agent, String what);

  /// No description provided for @badgePush.
  ///
  /// In en, this message translates to:
  /// **'push'**
  String get badgePush;

  /// No description provided for @badgeNoPush.
  ///
  /// In en, this message translates to:
  /// **'no push'**
  String get badgeNoPush;

  /// No description provided for @waitingForYou.
  ///
  /// In en, this message translates to:
  /// **'{count} waiting for you'**
  String waitingForYou(int count);

  /// No description provided for @terminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminal;

  /// No description provided for @sessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get sessions;

  /// No description provided for @editHost.
  ///
  /// In en, this message translates to:
  /// **'Edit host'**
  String get editHost;

  /// No description provided for @deleteHost.
  ///
  /// In en, this message translates to:
  /// **'Delete host'**
  String get deleteHost;

  /// No description provided for @addHost.
  ///
  /// In en, this message translates to:
  /// **'Add host'**
  String get addHost;

  /// No description provided for @notificationsOn.
  ///
  /// In en, this message translates to:
  /// **'Notifications on'**
  String get notificationsOn;

  /// No description provided for @notificationsOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications off'**
  String get notificationsOff;

  /// No description provided for @agentStateWaiting.
  ///
  /// In en, this message translates to:
  /// **'waiting'**
  String get agentStateWaiting;

  /// No description provided for @agentStateWorking.
  ///
  /// In en, this message translates to:
  /// **'working'**
  String get agentStateWorking;

  /// No description provided for @agentStateDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get agentStateDone;

  /// No description provided for @agentStateIdle.
  ///
  /// In en, this message translates to:
  /// **'idle'**
  String get agentStateIdle;

  /// No description provided for @agentStateUnknown.
  ///
  /// In en, this message translates to:
  /// **'unknown'**
  String get agentStateUnknown;

  /// No description provided for @shell.
  ///
  /// In en, this message translates to:
  /// **'Shell'**
  String get shell;

  /// No description provided for @loadSessions.
  ///
  /// In en, this message translates to:
  /// **'Load sessions'**
  String get loadSessions;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @enableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable notifications'**
  String get enableNotifications;

  /// No description provided for @noSessions.
  ///
  /// In en, this message translates to:
  /// **'No Herdr or tmux sessions'**
  String get noSessions;

  /// No description provided for @sessionAttached.
  ///
  /// In en, this message translates to:
  /// **'{kind} · attached'**
  String sessionAttached(String kind);

  /// No description provided for @agents.
  ///
  /// In en, this message translates to:
  /// **'Agents'**
  String get agents;

  /// No description provided for @noAgents.
  ///
  /// In en, this message translates to:
  /// **'No agents running'**
  String get noAgents;

  /// No description provided for @pinnedHostKey.
  ///
  /// In en, this message translates to:
  /// **'Pinned host key'**
  String get pinnedHostKey;

  /// No description provided for @openingHost.
  ///
  /// In en, this message translates to:
  /// **'Opening host'**
  String get openingHost;

  /// No description provided for @deleteHostTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete host?'**
  String get deleteHostTitle;

  /// No description provided for @deleteHostBody.
  ///
  /// In en, this message translates to:
  /// **'Removes the host, its pinned key and its inbox from this phone. To also remove this phone from the host, revoke it under Paired devices first.'**
  String get deleteHostBody;

  /// No description provided for @revokeThisPhoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke this phone?'**
  String get revokeThisPhoneTitle;

  /// No description provided for @revokeDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Revoke {name}?'**
  String revokeDeviceTitle(String name);

  /// No description provided for @revokeThisPhoneBody.
  ///
  /// In en, this message translates to:
  /// **'This is the phone you are using. OpenMosh will lose access to {alias}: the host removes its SSH key and push key. Pair again to get access back.'**
  String revokeThisPhoneBody(String alias);

  /// No description provided for @revokeDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Removes its SSH key and push key from {alias}. It can no longer connect or get notifications.'**
  String revokeDeviceBody(String alias);

  /// No description provided for @revoke.
  ///
  /// In en, this message translates to:
  /// **'Revoke'**
  String get revoke;

  /// No description provided for @deviceRevoked.
  ///
  /// In en, this message translates to:
  /// **'{name} was revoked.'**
  String deviceRevoked(String name);

  /// No description provided for @thisPhoneRevoked.
  ///
  /// In en, this message translates to:
  /// **'This phone was revoked from {alias}. Pair again or delete the host.'**
  String thisPhoneRevoked(String alias);

  /// No description provided for @pairedDevices.
  ///
  /// In en, this message translates to:
  /// **'Paired devices'**
  String get pairedDevices;

  /// No description provided for @showPairedDevices.
  ///
  /// In en, this message translates to:
  /// **'Show paired devices'**
  String get showPairedDevices;

  /// No description provided for @noPairedDevices.
  ///
  /// In en, this message translates to:
  /// **'No devices are paired with this host.'**
  String get noPairedDevices;

  /// No description provided for @badgeThisPhone.
  ///
  /// In en, this message translates to:
  /// **'this phone'**
  String get badgeThisPhone;

  /// No description provided for @pairedOn.
  ///
  /// In en, this message translates to:
  /// **'Paired {date}'**
  String pairedOn(String date);

  /// No description provided for @pairedOnStale.
  ///
  /// In en, this message translates to:
  /// **'Paired {date} · endpoint stale'**
  String pairedOnStale(String date);

  /// No description provided for @revokeDeviceTooltip.
  ///
  /// In en, this message translates to:
  /// **'Revoke {name}'**
  String revokeDeviceTooltip(String name);

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldName;

  /// No description provided for @fieldAddress.
  ///
  /// In en, this message translates to:
  /// **'Hostname or Tailscale IP'**
  String get fieldAddress;

  /// No description provided for @fieldPort.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get fieldPort;

  /// No description provided for @fieldUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get fieldUser;

  /// No description provided for @fieldKey.
  ///
  /// In en, this message translates to:
  /// **'Key'**
  String get fieldKey;

  /// No description provided for @thisDeviceKey.
  ///
  /// In en, this message translates to:
  /// **'This device (Ed25519)'**
  String get thisDeviceKey;

  /// No description provided for @checkingHostKey.
  ///
  /// In en, this message translates to:
  /// **'Checking host key…'**
  String get checkingHostKey;

  /// No description provided for @verifyHostKeyOf.
  ///
  /// In en, this message translates to:
  /// **'Verify the host key of {address}'**
  String verifyHostKeyOf(String address);

  /// No description provided for @verifyHostKeyHelp.
  ///
  /// In en, this message translates to:
  /// **'On the host run:\n  ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub\nTrust it only if the fingerprint is identical. It will be pinned, and any later change will block the connection.'**
  String get verifyHostKeyHelp;

  /// No description provided for @presentedHostKey.
  ///
  /// In en, this message translates to:
  /// **'Presented host key'**
  String get presentedHostKey;

  /// No description provided for @trustAndSave.
  ///
  /// In en, this message translates to:
  /// **'It matches — trust and save'**
  String get trustAndSave;

  /// No description provided for @eventNotFound.
  ///
  /// In en, this message translates to:
  /// **'Event not found'**
  String get eventNotFound;

  /// No description provided for @eventMayBeCleared.
  ///
  /// In en, this message translates to:
  /// **'It may have been cleared.'**
  String get eventMayBeCleared;

  /// No description provided for @badgeQuestion.
  ///
  /// In en, this message translates to:
  /// **'question'**
  String get badgeQuestion;

  /// No description provided for @badgeNeedsApproval.
  ///
  /// In en, this message translates to:
  /// **'needs approval'**
  String get badgeNeedsApproval;

  /// No description provided for @badgeSending.
  ///
  /// In en, this message translates to:
  /// **'sending…'**
  String get badgeSending;

  /// No description provided for @badgeFailed.
  ///
  /// In en, this message translates to:
  /// **'failed'**
  String get badgeFailed;

  /// No description provided for @badgeResolved.
  ///
  /// In en, this message translates to:
  /// **'resolved'**
  String get badgeResolved;

  /// No description provided for @badgeDone.
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get badgeDone;

  /// Answer kind sent to the agent.
  ///
  /// In en, this message translates to:
  /// **'allow'**
  String get responseAllow;

  /// Answer kind sent to the agent.
  ///
  /// In en, this message translates to:
  /// **'deny'**
  String get responseDeny;

  /// Answer kind sent to the agent.
  ///
  /// In en, this message translates to:
  /// **'text'**
  String get responseText;

  /// No description provided for @noAgentEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'No agent events yet.'**
  String get noAgentEventsTitle;

  /// No description provided for @noAgentEventsBody.
  ///
  /// In en, this message translates to:
  /// **'When an agent on a paired computer needs you, it shows up here.'**
  String get noAgentEventsBody;

  /// No description provided for @nothingWaiting.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for you.'**
  String get nothingWaiting;

  /// No description provided for @requestsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 request waits for you.} other{{count} requests wait for you.}}'**
  String requestsWaiting(int count);

  /// No description provided for @agentOnHost.
  ///
  /// In en, this message translates to:
  /// **'{agent} on {alias}'**
  String agentOnHost(String agent, String alias);

  /// No description provided for @agentAsks.
  ///
  /// In en, this message translates to:
  /// **'{agent} asks'**
  String agentAsks(String agent);

  /// No description provided for @agentNeedsYou.
  ///
  /// In en, this message translates to:
  /// **'Agent needs you'**
  String get agentNeedsYou;

  /// No description provided for @alreadyAnswered.
  ///
  /// In en, this message translates to:
  /// **'Already answered.'**
  String get alreadyAnswered;

  /// No description provided for @nothingToAnswer.
  ///
  /// In en, this message translates to:
  /// **'Nothing to answer.'**
  String get nothingToAnswer;

  /// No description provided for @youPickedInNotification.
  ///
  /// In en, this message translates to:
  /// **'You picked \"{action}\" in the notification. Confirm below.'**
  String youPickedInNotification(String action);

  /// No description provided for @approve.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approve;

  /// No description provided for @deny.
  ///
  /// In en, this message translates to:
  /// **'Deny'**
  String get deny;

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @replyToAgent.
  ///
  /// In en, this message translates to:
  /// **'Reply to the agent'**
  String get replyToAgent;

  /// No description provided for @openTerminal.
  ///
  /// In en, this message translates to:
  /// **'Open terminal'**
  String get openTerminal;

  /// No description provided for @sendReply.
  ///
  /// In en, this message translates to:
  /// **'Send reply'**
  String get sendReply;

  /// No description provided for @asksVerificationBeforeSending.
  ///
  /// In en, this message translates to:
  /// **'Asks for your fingerprint or screen lock before sending.'**
  String get asksVerificationBeforeSending;

  /// Reason shown in the biometric prompt.
  ///
  /// In en, this message translates to:
  /// **'Confirm your answer to the agent'**
  String get confirmAnswerReason;

  /// No description provided for @pairAHost.
  ///
  /// In en, this message translates to:
  /// **'Pair a host'**
  String get pairAHost;

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'OpenMosh cannot use the camera. Allow it in Android Settings > Apps > OpenMosh > Permissions > Camera, then tap Retry.'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'The camera could not start. Close other apps using it and tap Retry.'**
  String get cameraUnavailable;

  /// No description provided for @newComputer.
  ///
  /// In en, this message translates to:
  /// **'New computer'**
  String get newComputer;

  /// No description provided for @pairWith.
  ///
  /// In en, this message translates to:
  /// **'Pair with {ip}'**
  String pairWith(String ip);

  /// No description provided for @pairReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The host proves itself with the key in the code; its name and SSH host key fingerprint are pinned from its encrypted reply.'**
  String get pairReviewSubtitle;

  /// No description provided for @nameForThisPhone.
  ///
  /// In en, this message translates to:
  /// **'Name for this phone'**
  String get nameForThisPhone;

  /// Default name of this phone on the host.
  ///
  /// In en, this message translates to:
  /// **'Android phone'**
  String get defaultDeviceName;

  /// No description provided for @pairReviewNote.
  ///
  /// In en, this message translates to:
  /// **'This creates an SSH key on this phone, authorizes it on the host only from your tailnet, and registers encrypted notifications.'**
  String get pairReviewNote;

  /// No description provided for @pairing.
  ///
  /// In en, this message translates to:
  /// **'Pairing…'**
  String get pairing;

  /// No description provided for @pair.
  ///
  /// In en, this message translates to:
  /// **'Pair'**
  String get pair;

  /// No description provided for @pasteLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Or paste the openmosh://pair link'**
  String get pasteLinkLabel;

  /// No description provided for @pasteLinkHelper.
  ///
  /// In en, this message translates to:
  /// **'Print it on the host with: openmosh-hook pair --uri'**
  String get pasteLinkHelper;

  /// No description provided for @pairedWith.
  ///
  /// In en, this message translates to:
  /// **'Paired with {alias}'**
  String pairedWith(String alias);

  /// No description provided for @pairedBody.
  ///
  /// In en, this message translates to:
  /// **'Its SSH host key is pinned and notifications are encrypted end to end.'**
  String get pairedBody;

  /// No description provided for @openHost.
  ///
  /// In en, this message translates to:
  /// **'Open host'**
  String get openHost;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @colors.
  ///
  /// In en, this message translates to:
  /// **'Colors'**
  String get colors;

  /// No description provided for @colorsSummary.
  ///
  /// In en, this message translates to:
  /// **'{accent} accent · {theme} · {scheme} terminal'**
  String colorsSummary(String accent, String theme, String scheme);

  /// No description provided for @themeSummarySystem.
  ///
  /// In en, this message translates to:
  /// **'system theme'**
  String get themeSummarySystem;

  /// No description provided for @themeSummaryLight.
  ///
  /// In en, this message translates to:
  /// **'light theme'**
  String get themeSummaryLight;

  /// No description provided for @themeSummaryDark.
  ///
  /// In en, this message translates to:
  /// **'dark theme'**
  String get themeSummaryDark;

  /// No description provided for @notificationPreviews.
  ///
  /// In en, this message translates to:
  /// **'Notification previews'**
  String get notificationPreviews;

  /// No description provided for @notificationPreviewsBody.
  ///
  /// In en, this message translates to:
  /// **'Off: notifications only say \"<host>: <agent> needs you\". On: they show the request text, hidden on the lock screen.'**
  String get notificationPreviewsBody;

  /// No description provided for @keepConnected.
  ///
  /// In en, this message translates to:
  /// **'Keep sessions connected'**
  String get keepConnected;

  /// No description provided for @keepConnectedBody.
  ///
  /// In en, this message translates to:
  /// **'Terminals stay open and keep reconnecting after you leave them, until you disconnect or close the app.'**
  String get keepConnectedBody;

  /// No description provided for @lockApp.
  ///
  /// In en, this message translates to:
  /// **'Lock OpenMosh'**
  String get lockApp;

  /// No description provided for @lockAppBody.
  ///
  /// In en, this message translates to:
  /// **'Ask for your fingerprint, face or screen lock when OpenMosh opens and after a minute in the background. Turning it on or off asks for it too.'**
  String get lockAppBody;

  /// No description provided for @terminalFontSize.
  ///
  /// In en, this message translates to:
  /// **'Terminal font size · {size}'**
  String terminalFontSize(String size);

  /// No description provided for @shortcutRow.
  ///
  /// In en, this message translates to:
  /// **'Shortcut row'**
  String get shortcutRow;

  /// No description provided for @presetNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get presetNone;

  /// No description provided for @herdrPrefix.
  ///
  /// In en, this message translates to:
  /// **'Herdr prefix'**
  String get herdrPrefix;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// Always the endonym.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Always the endonym.
  ///
  /// In en, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get privacy;

  /// No description provided for @privacyBody.
  ///
  /// In en, this message translates to:
  /// **'No accounts, analytics or crash reporting. The app only talks to your hosts over Tailscale and to your UnifiedPush server, which sees ciphertext only.'**
  String get privacyBody;

  /// No description provided for @colorsCaption.
  ///
  /// In en, this message translates to:
  /// **'Settings › Colors'**
  String get colorsCaption;

  /// No description provided for @sectionAccent.
  ///
  /// In en, this message translates to:
  /// **'Accent'**
  String get sectionAccent;

  /// No description provided for @sectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get sectionApp;

  /// No description provided for @sectionTerminal.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get sectionTerminal;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @contrastNote.
  ///
  /// In en, this message translates to:
  /// **'Every accent is checked for 4.5:1 contrast in the light and dark themes.'**
  String get contrastNote;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @accentSemantics.
  ///
  /// In en, this message translates to:
  /// **'{accent} accent'**
  String accentSemantics(String accent);

  /// No description provided for @schemeSemantics.
  ///
  /// In en, this message translates to:
  /// **'{scheme} terminal'**
  String schemeSemantics(String scheme);

  /// No description provided for @accentBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get accentBlue;

  /// No description provided for @accentGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get accentGreen;

  /// No description provided for @accentViolet.
  ///
  /// In en, this message translates to:
  /// **'Violet'**
  String get accentViolet;

  /// No description provided for @accentAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get accentAmber;

  /// No description provided for @accentCoral.
  ///
  /// In en, this message translates to:
  /// **'Coral'**
  String get accentCoral;

  /// No description provided for @accentWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get accentWhite;

  /// No description provided for @schemeBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get schemeBlack;

  /// No description provided for @schemePaper.
  ///
  /// In en, this message translates to:
  /// **'Paper'**
  String get schemePaper;

  /// No description provided for @schemeSepia.
  ///
  /// In en, this message translates to:
  /// **'Sepia'**
  String get schemeSepia;

  /// No description provided for @schemeHighContrast.
  ///
  /// In en, this message translates to:
  /// **'High contrast'**
  String get schemeHighContrast;

  /// Short label on the scheme button.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get schemeHighContrastShort;

  /// No description provided for @errHostKeyChanged.
  ///
  /// In en, this message translates to:
  /// **'Host key changed. The connection was blocked.'**
  String get errHostKeyChanged;

  /// No description provided for @errAuthRejected.
  ///
  /// In en, this message translates to:
  /// **'The host rejected this device key.'**
  String get errAuthRejected;

  /// No description provided for @errCannotReachHost.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the host.'**
  String get errCannotReachHost;

  /// No description provided for @errUnlockCancelled.
  ///
  /// In en, this message translates to:
  /// **'Unlock was cancelled.'**
  String get errUnlockCancelled;

  /// No description provided for @errAddressNeedsNewCheck.
  ///
  /// In en, this message translates to:
  /// **'Changing address or port needs a new host key check. Add the host again.'**
  String get errAddressNeedsNewCheck;

  /// No description provided for @errNoDistributor.
  ///
  /// In en, this message translates to:
  /// **'No UnifiedPush distributor found. Install ntfy (F-Droid or GitHub) and try again.'**
  String get errNoDistributor;

  /// No description provided for @errNeedsScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Set a screen lock (PIN, pattern, password or biometrics) to store SSH keys.'**
  String get errNeedsScreenLock;

  /// No description provided for @errKeyInvalidated.
  ///
  /// In en, this message translates to:
  /// **'The screen lock or biometrics changed, so this key can no longer be unlocked. Pair the host again.'**
  String get errKeyInvalidated;

  /// No description provided for @errPairingRejected.
  ///
  /// In en, this message translates to:
  /// **'The host rejected pairing. Check that both devices use the same Tailscale account and that the code is still valid.'**
  String get errPairingRejected;

  /// No description provided for @errPairingUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the host. Check that Tailscale is on and openmosh-hook pair is still running.'**
  String get errPairingUnreachable;

  /// No description provided for @errInvalidPush.
  ///
  /// In en, this message translates to:
  /// **'Discarded an invalid push message.'**
  String get errInvalidPush;

  /// No description provided for @errEnterAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a hostname or IP address.'**
  String get errEnterAddress;

  /// No description provided for @errEnterUser.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid user name.'**
  String get errEnterUser;

  /// No description provided for @errEventNotFound.
  ///
  /// In en, this message translates to:
  /// **'Event not found.'**
  String get errEventNotFound;

  /// No description provided for @errFileTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Files are limited to 50 MB.'**
  String get errFileTooLarge;

  /// No description provided for @errNotPairedForPush.
  ///
  /// In en, this message translates to:
  /// **'Host is not paired for push.'**
  String get errNotPairedForPush;

  /// No description provided for @errInvalidFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Invalid host key fingerprint.'**
  String get errInvalidFingerprint;

  /// No description provided for @errInvalidIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Invalid identifier.'**
  String get errInvalidIdentifier;

  /// No description provided for @errMessageTooLong.
  ///
  /// In en, this message translates to:
  /// **'Message is longer than 4 KiB.'**
  String get errMessageTooLong;

  /// No description provided for @errNameLength.
  ///
  /// In en, this message translates to:
  /// **'Name must be 1–64 characters.'**
  String get errNameLength;

  /// No description provided for @errPairingReplyTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Pairing reply is too large.'**
  String get errPairingReplyTooLarge;

  /// No description provided for @errPairingRequestTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Pairing request is too large.'**
  String get errPairingRequestTooLarge;

  /// No description provided for @errPortRange.
  ///
  /// In en, this message translates to:
  /// **'Port must be 1–65535.'**
  String get errPortRange;

  /// No description provided for @errHostClosed.
  ///
  /// In en, this message translates to:
  /// **'The host closed the connection.'**
  String get errHostClosed;

  /// No description provided for @errHostTimeout.
  ///
  /// In en, this message translates to:
  /// **'The host did not answer in time.'**
  String get errHostTimeout;

  /// No description provided for @errInvalidPairingResponse.
  ///
  /// In en, this message translates to:
  /// **'The host sent an invalid pairing response.'**
  String get errInvalidPairingResponse;

  /// No description provided for @errPairingFailed.
  ///
  /// In en, this message translates to:
  /// **'The pairing connection failed.'**
  String get errPairingFailed;

  /// No description provided for @errDistributorNoAnswer.
  ///
  /// In en, this message translates to:
  /// **'The push distributor did not answer. Open ntfy and retry.'**
  String get errDistributorNoAnswer;

  /// No description provided for @errDistributorRefused.
  ///
  /// In en, this message translates to:
  /// **'The push distributor refused the registration.'**
  String get errDistributorRefused;

  /// No description provided for @errEndpointHttps.
  ///
  /// In en, this message translates to:
  /// **'The push endpoint must use https.'**
  String get errEndpointHttps;

  /// No description provided for @errKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'This key is missing. Pair the host again.'**
  String get errKeyMissing;

  /// No description provided for @errUnexpectedPairingReply.
  ///
  /// In en, this message translates to:
  /// **'Unexpected pairing reply.'**
  String get errUnexpectedPairingReply;

  /// No description provided for @errUnknownHost.
  ///
  /// In en, this message translates to:
  /// **'Unknown host.'**
  String get errUnknownHost;

  /// No description provided for @errUnreadableFileSize.
  ///
  /// In en, this message translates to:
  /// **'Unreadable file size.'**
  String get errUnreadableFileSize;

  /// No description provided for @errWriteMessageFirst.
  ///
  /// In en, this message translates to:
  /// **'Write a message first.'**
  String get errWriteMessageFirst;

  /// No description provided for @errHostCommandFailed.
  ///
  /// In en, this message translates to:
  /// **'Host command failed.'**
  String get errHostCommandFailed;

  /// No description provided for @errHookMissing.
  ///
  /// In en, this message translates to:
  /// **'openmosh-hook is not installed on this host.'**
  String get errHookMissing;

  /// No description provided for @errHookUnexpectedOutput.
  ///
  /// In en, this message translates to:
  /// **'openmosh-hook returned unexpected output.'**
  String get errHookUnexpectedOutput;

  /// No description provided for @errUploadFailed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed.'**
  String get errUploadFailed;

  /// No description provided for @errDataTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The data is too large.'**
  String get errDataTooLarge;

  /// No description provided for @errNotUnencryptedKey.
  ///
  /// In en, this message translates to:
  /// **'That is not an unencrypted ssh-ed25519 private key.'**
  String get errNotUnencryptedKey;

  /// No description provided for @errNotUsableKey.
  ///
  /// In en, this message translates to:
  /// **'That is not a usable ssh-ed25519 private key.'**
  String get errNotUsableKey;

  /// No description provided for @errLockStaysOff.
  ///
  /// In en, this message translates to:
  /// **'Could not verify you, so the lock stays off. Set up a fingerprint, face or screen lock on this phone, then try again.'**
  String get errLockStaysOff;

  /// No description provided for @errLockStaysOn.
  ///
  /// In en, this message translates to:
  /// **'Could not verify you, so the lock stays on.'**
  String get errLockStaysOn;

  /// No description provided for @errAlreadyAnswered.
  ///
  /// In en, this message translates to:
  /// **'This event was already answered.'**
  String get errAlreadyAnswered;

  /// Terminal app bar title when there is no session or host name.
  ///
  /// In en, this message translates to:
  /// **'Terminal'**
  String get terminalTitle;

  /// Terminal subtitle for a plain shell.
  ///
  /// In en, this message translates to:
  /// **'shell'**
  String get terminalShell;

  /// Terminal subtitle: host name and a plain shell.
  ///
  /// In en, this message translates to:
  /// **'{host} · shell'**
  String terminalHostShell(String host);

  /// Terminal subtitle: host name and session kind (tmux, herdr…).
  ///
  /// In en, this message translates to:
  /// **'{host} · {kind}'**
  String terminalHostSession(String host, String kind);

  /// Placeholder in the terminal subtitle while the host is loading.
  ///
  /// In en, this message translates to:
  /// **'host'**
  String get terminalHostFallback;

  /// Placeholder in the terminal subtitle when the session kind is unknown.
  ///
  /// In en, this message translates to:
  /// **'session'**
  String get terminalSessionFallback;

  /// Terminal toolbar tooltip.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get fullScreen;

  /// Terminal corner button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Exit full screen'**
  String get exitFullScreen;

  /// Terminal toolbar tooltip.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// Keys grid button that opens the chat composer.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get terminalChat;

  /// Keys grid button that closes the chat composer.
  ///
  /// In en, this message translates to:
  /// **'Type in the terminal'**
  String get typeInTerminal;

  /// Keys grid button that opens or closes the on-screen keyboard.
  ///
  /// In en, this message translates to:
  /// **'Keyboard'**
  String get keyboard;

  /// Terminal font size button.
  ///
  /// In en, this message translates to:
  /// **'Smaller text'**
  String get smallerText;

  /// Terminal font size button.
  ///
  /// In en, this message translates to:
  /// **'Larger text'**
  String get largerText;

  /// Pastes the phone clipboard into the chat message.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// Adds a saved shortcut key; also the dialog title.
  ///
  /// In en, this message translates to:
  /// **'Add shortcut'**
  String get addShortcut;

  /// Copies the selected terminal text.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Clears the terminal text selection.
  ///
  /// In en, this message translates to:
  /// **'Clear selection'**
  String get clearSelection;

  /// Snackbar after copying terminal text.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// Confirms removing a saved shortcut key.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{label}\"?'**
  String removeShortcutTitle(String label);

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Attachment source in the chat sheet.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get attachPhotos;

  /// Attachment source in the chat sheet.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get attachFile;

  /// Terminal banner.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// Terminal banner.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get reconnecting;

  /// Chat composer button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Attach images or files'**
  String get chatAttach;

  /// Chat composer input hint.
  ///
  /// In en, this message translates to:
  /// **'Message the agent…'**
  String get chatHint;

  /// Chat composer button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Close chat'**
  String get chatClose;

  /// Chat composer send button tooltip.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chatSend;

  /// Tooltip on an attachment thumbnail.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}'**
  String chatRemoveAttachment(String name);

  /// No description provided for @sessionEndedTitle.
  ///
  /// In en, this message translates to:
  /// **'The session ended.'**
  String get sessionEndedTitle;

  /// No description provided for @sessionEndedBody.
  ///
  /// In en, this message translates to:
  /// **'The shell on the computer exited. Start it again or go back.'**
  String get sessionEndedBody;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// Shortcut dialog segment.
  ///
  /// In en, this message translates to:
  /// **'Ctrl + key'**
  String get shortcutCtrlKey;

  /// Shortcut dialog segment.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get shortcutText;

  /// Shortcut dialog field label for the Ctrl letter.
  ///
  /// In en, this message translates to:
  /// **'Letter'**
  String get shortcutLetter;

  /// Shortcut dialog field label.
  ///
  /// In en, this message translates to:
  /// **'Text to send'**
  String get shortcutTextToSend;

  /// Shortcut dialog field label.
  ///
  /// In en, this message translates to:
  /// **'Label (optional)'**
  String get shortcutLabelOptional;

  /// Shortcut dialog checkbox.
  ///
  /// In en, this message translates to:
  /// **'Press Enter after the text'**
  String get shortcutPressEnter;

  /// Shortcut dialog confirm button while the shortcut is incomplete.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get shortcutAdd;

  /// Shortcut dialog confirm button naming the shortcut.
  ///
  /// In en, this message translates to:
  /// **'Add {label}'**
  String shortcutAddNamed(String label);

  /// Keys grid toggle tooltip.
  ///
  /// In en, this message translates to:
  /// **'More keys'**
  String get moreKeys;

  /// Keys grid toggle tooltip.
  ///
  /// In en, this message translates to:
  /// **'Fewer keys'**
  String get fewerKeys;

  /// Title of the SSH keys screen.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get keysTitle;

  /// No description provided for @keysEmpty.
  ///
  /// In en, this message translates to:
  /// **'No keys yet. Pairing creates this device\'s key, or generate/import one.'**
  String get keysEmpty;

  /// No description provided for @generateKey.
  ///
  /// In en, this message translates to:
  /// **'Generate key'**
  String get generateKey;

  /// No description provided for @importKey.
  ///
  /// In en, this message translates to:
  /// **'Import key'**
  String get importKey;

  /// No description provided for @copyPublicKey.
  ///
  /// In en, this message translates to:
  /// **'Copy public key'**
  String get copyPublicKey;

  /// No description provided for @publicKeyCopied.
  ///
  /// In en, this message translates to:
  /// **'Public key copied'**
  String get publicKeyCopied;

  /// Default name of a generated key; date is YYYY-MM-DD.
  ///
  /// In en, this message translates to:
  /// **'Key {date}'**
  String generatedKeyLabel(String date);

  /// Default name of an imported key.
  ///
  /// In en, this message translates to:
  /// **'Imported key'**
  String get importedKeyLabel;

  /// No description provided for @deleteKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {label}?'**
  String deleteKeyTitle(String label);

  /// No description provided for @deleteKeyBody.
  ///
  /// In en, this message translates to:
  /// **'Hosts that use this key will stop connecting until you pair them again.'**
  String get deleteKeyBody;

  /// No description provided for @importKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Import ssh-ed25519 key'**
  String get importKeyTitle;

  /// Name field of the import key dialog.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get keyLabel;

  /// No description provided for @pastePrivateKey.
  ///
  /// In en, this message translates to:
  /// **'Paste the OpenSSH private key'**
  String get pastePrivateKey;

  /// No description provided for @importAction.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importAction;

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'OpenMosh is locked'**
  String get lockedTitle;

  /// No description provided for @lockedBody.
  ///
  /// In en, this message translates to:
  /// **'Verify it is you to continue.'**
  String get lockedBody;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// System biometric prompt reason.
  ///
  /// In en, this message translates to:
  /// **'Unlock OpenMosh'**
  String get lockPromptUnlock;

  /// System biometric prompt reason.
  ///
  /// In en, this message translates to:
  /// **'Turn on the OpenMosh lock'**
  String get lockPromptTurnOn;

  /// System biometric prompt reason.
  ///
  /// In en, this message translates to:
  /// **'Turn off the OpenMosh lock'**
  String get lockPromptTurnOff;

  /// Pairing success when the phone paired without a push endpoint.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off: the push app (ntfy) did not answer. Open ntfy, then tap Enable notifications on this host.'**
  String get pairedWithoutPush;

  /// Accessibility label of an arrow key on the arrow cross.
  ///
  /// In en, this message translates to:
  /// **'Up'**
  String get arrowUp;

  /// Accessibility label of an arrow key on the arrow cross.
  ///
  /// In en, this message translates to:
  /// **'Down'**
  String get arrowDown;

  /// Accessibility label of an arrow key on the arrow cross.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get arrowLeft;

  /// Accessibility label of an arrow key on the arrow cross.
  ///
  /// In en, this message translates to:
  /// **'Right'**
  String get arrowRight;

  /// Host screen button and title of the screen with token usage per agent.
  ///
  /// In en, this message translates to:
  /// **'Agent usage'**
  String get agentUsage;

  /// No description provided for @usageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tokens your agents recorded on this computer.'**
  String get usageSubtitle;

  /// No description provided for @usagePeriod.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get usagePeriod;

  /// No description provided for @usageDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String usageDays(int count);

  /// No description provided for @usagePeriodTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Last day} other{Last {count} days}}'**
  String usagePeriodTotal(int count);

  /// Token breakdown; values are compact numbers like 1.2M.
  ///
  /// In en, this message translates to:
  /// **'In {input} · Out {output} · Cache {cache}'**
  String usageBreakdown(String input, String output, String cache);

  /// No description provided for @usagePlanLimits.
  ///
  /// In en, this message translates to:
  /// **'Plan limits'**
  String get usagePlanLimits;

  /// No description provided for @usagePercentUsed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String usagePercentUsed(String percent);

  /// {time} is a short duration like 2h 10m.
  ///
  /// In en, this message translates to:
  /// **'Resets in {time}'**
  String usageResetsIn(String time);

  /// No description provided for @usageResetsSoon.
  ///
  /// In en, this message translates to:
  /// **'Resets soon'**
  String get usageResetsSoon;

  /// No description provided for @usageProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get usageProjects;

  /// No description provided for @usageModels.
  ///
  /// In en, this message translates to:
  /// **'Models'**
  String get usageModels;

  /// No description provided for @usageNotRecorded.
  ///
  /// In en, this message translates to:
  /// **'Not recorded ({count})'**
  String usageNotRecorded(int count);

  /// No description provided for @usageNotRecordedHint.
  ///
  /// In en, this message translates to:
  /// **'These agents leave no local usage logs to read.'**
  String get usageNotRecordedHint;

  /// No description provided for @usageEmpty.
  ///
  /// In en, this message translates to:
  /// **'No agent usage recorded in this period.'**
  String get usageEmpty;

  /// No description provided for @usageLoading.
  ///
  /// In en, this message translates to:
  /// **'Reading usage…'**
  String get usageLoading;

  /// No description provided for @errHookOutdatedUsage.
  ///
  /// In en, this message translates to:
  /// **'Update openmosh-hook on this computer to see usage.'**
  String get errHookOutdatedUsage;

  /// No description provided for @errUsagePeriod.
  ///
  /// In en, this message translates to:
  /// **'The period must be 1–31 days.'**
  String get errUsagePeriod;

  /// Notification hours setting.
  ///
  /// In en, this message translates to:
  /// **'Notification hours'**
  String get notifyHours;

  /// Notification hours setting.
  ///
  /// In en, this message translates to:
  /// **'Outside these hours, events still reach the inbox, without sound or a notification.'**
  String get notifyHoursBody;

  /// Notification hours setting.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get notifyAlways;

  /// No description provided for @notifyBetween.
  ///
  /// In en, this message translates to:
  /// **'{from} – {to}'**
  String notifyBetween(String from, String to);

  /// No description provided for @notifyUsesApp.
  ///
  /// In en, this message translates to:
  /// **'App setting: {hours}'**
  String notifyUsesApp(String hours);

  /// Notification hours setting.
  ///
  /// In en, this message translates to:
  /// **'Use the app setting'**
  String get notifyUseAppSetting;

  /// Notification hours setting.
  ///
  /// In en, this message translates to:
  /// **'Only between'**
  String get notifyOnlyBetween;

  /// Notification hours setting.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get notifyFrom;

  /// Notification hours setting.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get notifyTo;

  /// Settings row: light, dark or system theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get appTheme;

  /// Primary host action: attach the Herdr session through openmosh-hook (mirroring).
  ///
  /// In en, this message translates to:
  /// **'Open Herdr'**
  String get openHerdr;

  /// Tooltip of the Open Herdr action.
  ///
  /// In en, this message translates to:
  /// **'Opens the Herdr session with mirroring: the computer follows the tab and workspace you pick here.'**
  String get openHerdrHint;

  /// Tooltip of the eye button that reveals a hidden address, key or fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showSensitive;

  /// Tooltip of the eye button that hides a revealed address, key or fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideSensitive;

  /// Tooltip of the eye button on a fingerprint the user must compare with the computer.
  ///
  /// In en, this message translates to:
  /// **'Show to compare'**
  String get showToCompare;

  /// Confirmation before copying a public key to the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy the public key?'**
  String get copyPublicKeyTitle;

  /// Body of the copy public key confirmation.
  ///
  /// In en, this message translates to:
  /// **'It is marked as sensitive on the clipboard. Paste it only on computers you trust.'**
  String get copyPublicKeyBody;

  /// Biometric prompt reason before showing a terminal that stayed connected.
  ///
  /// In en, this message translates to:
  /// **'Verify it\'s you to show the open terminal'**
  String get verifyToShowTerminal;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
