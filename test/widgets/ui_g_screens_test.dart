import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/home_shell.dart';
import 'package:openmosh/app/theme.dart';
import 'package:openmosh/features/hosts/presentation/views/hosts_view.dart';
import 'package:openmosh/features/inbox/domain/entities/inbox_event.dart';
import 'package:openmosh/features/keyboard/domain/entities/key_presets.dart';
import 'package:openmosh/features/keyboard/domain/entities/modifier_state.dart';
import 'package:openmosh/features/keyboard/presentation/views/extra_keys_bar.dart';
import 'package:openmosh/features/inbox/presentation/views/event_confirm_view.dart';
import 'package:openmosh/features/inbox/presentation/views/inbox_view.dart';
import 'package:openmosh/features/pairing/presentation/views/pair_success_view.dart';
import 'package:openmosh/features/settings/domain/entities/app_settings.dart';
import 'package:openmosh/features/settings/presentation/views/colors_view.dart';
import 'package:openmosh/shared/ui/atoms/mole_logo.dart';

import '../support/fakes.dart';

final now = DateTime.utc(2026, 11, 8, 21);

InboxEvent pending() => InboxEvent.received(
  id: 'ev1',
  hostId: 'h1',
  seq: 1,
  agent: 'claude',
  kind: EventKind.approvalRequired,
  title: 'Run tests?',
  summary: 'npm test --workspace api',
  pane: 'p1',
  at: now.subtract(const Duration(seconds: 12)),
);

/// Pumps [child] on a 390 × 844 phone in the given theme.
Future<void> phone(WidgetTester t, Widget child, {Brightness b = Brightness.dark}) async {
  t.view.physicalSize = const Size(390, 844);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      theme: buildTheme(b),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  for (final b in Brightness.values) {
    testWidgets('home shows the waiting host, the approval card and opens it (${b.name})', (
      t,
    ) async {
      InboxEvent? opened;
      await phone(
        t,
        HostsView(
          hosts: [testHost()],
          events: [pending()],
          now: now,
          onOpen: (_) {},
          onPair: () {},
          onAdd: () {},
          onOpenEvent: (e) => opened = e,
        ),
        b: b,
      );
      expect(find.text('Good evening'), findsOneWidget);
      expect(find.textContaining('except work'), findsOneWidget);
      expect(find.text('12 s ago'), findsOneWidget);
      expect(find.text('1 waiting for you'), findsOneWidget);
      await t.tap(find.byKey(const Key('approval_card')));
      expect(opened?.id, 'ev1');
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('home without pending events says all quiet and has no approval card', (t) async {
    await phone(
      t,
      HostsView(hosts: [testHost()], now: now, onOpen: (_) {}, onPair: () {}, onAdd: () {}),
    );
    expect(find.text('All quiet.'), findsOneWidget);
    expect(find.byKey(const Key('approval_card')), findsNothing);
  });

  testWidgets('home without hosts shows the mole', (t) async {
    await phone(t, HostsView(hosts: const [], onOpen: (_) {}, onPair: () {}, onAdd: () {}));
    expect(find.byType(MoleLogo), findsOneWidget);
    expect(find.text('No computers yet'), findsOneWidget);
  });

  testWidgets('empty inbox shows the mole', (t) async {
    await phone(t, InboxView(events: const [], hostAlias: (_) => 'work', onOpen: (_) {}));
    expect(find.byType(MoleLogo), findsOneWidget);
  });

  testWidgets('approve screen: big approve block, deny and reply fit on a phone', (t) async {
    final calls = <String>[];
    await phone(
      t,
      EventConfirmView(
        event: pending(),
        hostAlias: 'work',
        busy: false,
        when: '12 s ago',
        onAllow: () => calls.add('allow'),
        onDeny: () => calls.add('deny'),
        onText: (_) {},
        onOpenTerminal: () {},
        onClose: () => calls.add('close'),
      ),
    );
    expect(find.text('work · claude · 12 s ago'), findsOneWidget);
    expect(t.getSize(find.byKey(const Key('approve'))).height, greaterThanOrEqualTo(100));
    await t.tap(find.byKey(const Key('reply')));
    await t.pump();
    expect(t.widget<TextField>(find.byType(TextField)).focusNode?.hasFocus, isTrue);
    await t.tap(find.byTooltip('Close'));
    expect(calls, ['close']);
    expect(t.takeException(), isNull);
  });

  testWidgets('pairing success shows the mole and opens the host', (t) async {
    var opened = 0;
    await phone(t, PairSuccessView(alias: 'laptop', onOpen: () => opened++));
    expect(find.byType(MoleLogo), findsOneWidget);
    expect(find.text('Paired with laptop'), findsOneWidget);
    await t.tap(find.byKey(const Key('open_paired_host')));
    expect(opened, 1);
  });

  for (final b in Brightness.values) {
    testWidgets('Colors screen fits a phone without overflow (${b.name})', (t) async {
      await phone(
        t,
        ColorsView(settings: const AppSettings(), onChanged: (_) {}, onBack: () {}),
        b: b,
      );
      expect(t.takeException(), isNull);
    });
  }

  testWidgets('home dock labels the selected tab and switches tabs', (t) async {
    final picked = <int>[];
    await phone(t, HomeDock(selectedIndex: 1, onSelected: picked.add));
    expect(find.text('Inbox'), findsOneWidget);
    expect(find.text('Hosts'), findsNothing);
    expect(
      t.getSemantics(find.bySemanticsLabel('Inbox')),
      isSemantics(label: 'Inbox', isSelected: true),
    );
    await t.tap(find.bySemanticsLabel('Settings'));
    expect(picked, [3]);
  });

  testWidgets('the 6-key grid and the expanded rows fit a phone', (t) async {
    for (final expanded in [false, true]) {
      await phone(
        t,
        Align(
          alignment: Alignment.bottomCenter,
          child: ExtraKeysBar(
            base: KeyPresets.base,
            preset: KeyPresets.forName(PresetName.herdr),
            modifiers: const ModifierState(ctrl: true),
            onKey: (_) {},
            onModifier: (_) {},
            onModifierLock: (_) {},
            expanded: expanded,
            onToggleExpanded: () {},
            pinned: [
              KeyGridButton(tooltip: 'Chat', icon: Icons.chat_bubble_outline, onPressed: () {}),
              KeyGridButton(tooltip: 'Keyboard', icon: Icons.keyboard, onPressed: () {}),
            ],
          ),
        ),
      );
      expect(t.takeException(), isNull, reason: 'expanded: $expanded');
    }
  });
}
