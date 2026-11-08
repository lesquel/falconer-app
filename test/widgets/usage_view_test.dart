import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openmosh/app/theme.dart';
import 'package:openmosh/features/usage/domain/entities/agent_usage.dart';
import 'package:openmosh/features/usage/domain/usecases/load_agent_usage.dart';
import 'package:openmosh/features/usage/presentation/views/usage_format.dart';
import 'package:openmosh/features/usage/presentation/views/usage_view.dart';
import 'package:openmosh/l10n/l10n.dart';
import 'package:openmosh/shared/domain/failure.dart';

import '../features/usage/agent_usage_test.dart' show fixture;

final generated = DateTime.fromMillisecondsSinceEpoch(1794168000 * 1000, isUtc: true);

Future<void> pump(
  WidgetTester t, {
  UsageReport? report,
  Object? error,
  bool loading = false,
  int days = 7,
  ValueChanged<int>? onDays,
  Locale locale = const Locale('en'),
  double width = 390,
}) async {
  t.view.physicalSize = Size(width, 800);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedAppLocales,
      theme: buildTheme(Brightness.dark),
      home: Scaffold(
        body: UsageView(
          days: days,
          report: report,
          loading: loading,
          error: error,
          now: generated,
          onDays: onDays ?? (_) {},
          onRefresh: () async {},
          onBack: () {},
        ),
      ),
    ),
  );
}

void main() {
  group('compactTokens', () {
    test('formats like 1.2M and 850K', () {
      expect(compactTokens(0), '0');
      expect(compactTokens(850), '850');
      expect(compactTokens(1234), '1.2K');
      expect(compactTokens(850000), '850K');
      expect(compactTokens(999999), '1M');
      expect(compactTokens(1200000), '1.2M');
      expect(compactTokens(85000000), '85M');
      expect(compactTokens(3000000000), '3B');
      expect(compactTokens(1200000, decimal: ','), '1,2M');
    });

    test('short durations', () {
      expect(shortDuration(const Duration(minutes: 45)), '45m');
      expect(shortDuration(const Duration(hours: 2, minutes: 10)), '2h 10m');
      expect(shortDuration(const Duration(days: 3, hours: 4)), '3d 4h');
    });
  });

  testWidgets('renders totals, breakdown, projects and models in compact format', (t) async {
    await pump(t, report: UsageReport.fromJson(fixture()));
    expect(find.text('Agent usage'), findsOneWidget);
    expect(find.text('Claude Code'), findsOneWidget);
    expect(find.text('1.2M'), findsOneWidget, reason: 'claude today');
    expect(find.text('8.4M'), findsWidgets, reason: 'claude period and model');
    expect(find.text('Last 7 days'), findsWidgets);
    expect(find.text('In 850K · Out 150K · Cache 7.4M'), findsOneWidget);
    expect(find.text('OpenMosh'), findsOneWidget);
    expect(find.text('claude-opus'), findsOneWidget);
    await t.scrollUntilVisible(find.text('gpt-5-codex'), 200);
    expect(find.text('Codex'), findsOneWidget);
  });

  testWidgets('shows plan limits first with % and reset time', (t) async {
    await pump(t, report: UsageReport.fromJson(fixture()));
    await t.scrollUntilVisible(find.text('5h'), 200);
    expect(find.text('42% used'), findsOneWidget);
    expect(find.text('Resets in 2h'), findsOneWidget);
    expect(find.text('7% used'), findsOneWidget);
    final bar = t.widget<LinearProgressIndicator>(
      find.descendant(
        of: find.bySemanticsLabel(RegExp('^5h')),
        matching: find.byType(LinearProgressIndicator),
      ),
    );
    expect(bar.value, closeTo(0.42, 1e-9));
    // The limit sits above the agent's totals inside the card.
    expect(t.getTopLeft(find.text('5h')).dy, lessThan(t.getTopLeft(find.text('850K').last).dy));
  });

  testWidgets('agents without logs sit in a collapsed "Not recorded" section', (t) async {
    await pump(t, report: UsageReport.fromJson(fixture()));
    await t.scrollUntilVisible(find.text('Not recorded (1)'), 200);
    expect(find.text('OpenCode'), findsNothing);
    await t.ensureVisible(find.byType(ExpansionTile));
    await t.pumpAndSettle();
    await t.tap(find.text('Not recorded (1)'));
    await t.pumpAndSettle();
    expect(find.text('OpenCode'), findsOneWidget);
    expect(find.text('No local usage logs.'), findsOneWidget);
  });

  testWidgets('period switch reports the chosen days', (t) async {
    int? chosen;
    await pump(t, report: UsageReport.fromJson(fixture()), onDays: (d) => chosen = d);
    await t.tap(find.text('30 days'));
    expect(chosen, 30);
    final seg = find.byType(SegmentedButton<int>);
    expect(t.getSize(seg).height, greaterThanOrEqualTo(44));
  });

  testWidgets('loading and empty states', (t) async {
    await pump(t, loading: true);
    expect(find.text('Reading usage…'), findsOneWidget);
    await pump(t, report: const UsageReport(days: 7));
    expect(find.text('No agent usage recorded in this period.'), findsOneWidget);
  });

  testWidgets('an older hook asks to update it', (t) async {
    await pump(t, error: const HookFailure('hook_outdated', hookOutdatedForUsage));
    expect(find.text('Update openmosh-hook on this computer to see usage.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('Spanish strings', (t) async {
    await pump(t, report: UsageReport.fromJson(fixture()), locale: const Locale('es'));
    expect(find.text('Uso de agentes'), findsOneWidget);
    expect(find.text('Últimos 7 días'), findsWidgets);
    expect(find.text('1,2M'), findsOneWidget);
    expect(find.text('Entrada 850K · Salida 150K · Caché 7,4M'), findsOneWidget);
    await t.scrollUntilVisible(find.text('42% usado'), 200);
    expect(find.text('Se reinicia en 2h'), findsOneWidget);
    await t.scrollUntilVisible(find.text('Sin registros (1)'), 200);
    await pump(
      t,
      error: const HookFailure('hook_outdated', hookOutdatedForUsage),
      locale: const Locale('es'),
    );
    expect(find.text('Actualiza openmosh-hook en este equipo para ver el uso.'), findsOneWidget);
  });

  for (final locale in const [Locale('en'), Locale('es')]) {
    testWidgets('fits a 360 px phone without overflow (${locale.languageCode})', (t) async {
      await pump(t, report: UsageReport.fromJson(fixture()), width: 360, locale: locale);
      expect(t.takeException(), isNull);
      await t.scrollUntilVisible(find.byType(ExpansionTile), 300);
      await t.ensureVisible(find.byType(ExpansionTile));
      await t.pumpAndSettle();
      await t.tap(
        find.text(locale.languageCode == 'es' ? 'Sin registros (1)' : 'Not recorded (1)'),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
}
