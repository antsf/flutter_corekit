import 'package:flutter/material.dart';
import 'package:flutter_corekit/src/widgets/core_search_dropdown.dart';
import 'package:flutter_test/flutter_test.dart';

const items = [
  'Jakarta',
  'Bandung',
  'Surabaya',
  'Semarang',
  'Yogyakarta',
];

Future<void> openDropdown(
  WidgetTester tester, {
  Size size = const Size(320, 568),
  double scale = 1,
  double keyboard = 0,
  String? value,
  bool disabled = false,
  String? errorText,
  List<String>? items,
  void Function(String?)? onChanged,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
    builder: (context, child) => MediaQuery(
      data:
          MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: Scaffold(
      body: Builder(
        builder: (context) => CoreSearchDropdown<String>(
          items: items ?? ['Jakarta', 'Bandung', 'Surabaya'],
          value: value,
          hintText: 'A long hint message',
          labelText: 'Select a city',
          sheetTitle: 'A long sheet header that must wrap',
          searchHint: 'Cari Kota/Kab.',
          errorText: errorText,
          disabled: disabled,
          onChanged: onChanged,
        ),
      ),
    ),
  ));
}

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.text('A long hint message'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('opens the sheet with the search field and options',
      (tester) async {
    await openDropdown(tester);
    await openSheet(tester);
    expect(find.text('A long sheet header that must wrap'), findsOneWidget);
    expect(find.text('Jakarta'), findsOneWidget);
    expect(find.text('Bandung'), findsOneWidget);
    expect(find.text('A long hint message'), findsOneWidget);
  });

  testWidgets(
      'picking an option pops the sheet and fires onChanged with the value',
      (tester) async {
    String? picked;
    await openDropdown(tester, onChanged: (v) => picked = v);
    await openSheet(tester);
    await tester.tap(find.text('Bandung'));
    await tester.pumpAndSettle();
    expect(picked, 'Bandung');
    expect(find.text('A long sheet header that must wrap'), findsNothing);
  });

  testWidgets('cancelling the sheet never calls onChanged', (tester) async {
    var changed = false;
    await openDropdown(tester, onChanged: (_) => changed = true);
    await openSheet(tester);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(changed, isFalse);
    expect(find.text('Bandung'), findsNothing); // sheet is gone
  });

  testWidgets('search filters sheet options and shows a no-results message',
      (tester) async {
    await openDropdown(tester);
    await openSheet(tester);
    await tester.enterText(
        find.widgetWithText(TextField, 'Cari Kota/Kab.'), 'ban');
    await tester.pumpAndSettle();
    expect(find.text('Bandung'), findsOneWidget);
    expect(find.text('Jakarta'), findsNothing);

    await tester.enterText(
        find.widgetWithText(TextField, 'Cari Kota/Kab.'), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('No results'), findsOneWidget);
    expect(find.text('Jakarta'), findsNothing);
  });

  testWidgets('disabled trigger does not open the sheet', (tester) async {
    await openDropdown(tester, disabled: true);
    await openSheet(tester);
    expect(find.text('A long sheet header that must wrap'), findsNothing);
  });

  testWidgets('exposes label and error and a value that is not the hint',
      (tester) async {
    await openDropdown(tester,
        value: 'Bandung',
        errorText: 'A required city must be chosen before continuing');
    expect(find.text('Select a city'), findsOneWidget);
    expect(find.text('Bandung'), findsOneWidget);
    expect(find.text('A long hint message'), findsNothing);
    expect(find.text('A required city must be chosen before continuing'),
        findsOneWidget);
  });

  testWidgets('trigger and options keep a 48px touch target', (tester) async {
    await openDropdown(tester);
    final trigger = tester.getRect(find.ancestor(
        of: find.text('A long hint message'), matching: find.byType(InkWell)));
    expect(trigger.height, greaterThanOrEqualTo(48));
    await openSheet(tester);
    final option = tester.getRect(find.ancestor(
        of: find.text('Jakarta'), matching: find.byType(InkWell)));
    expect(option.height, greaterThanOrEqualTo(48));
  });

  for (final size in [const Size(320, 568), const Size(568, 320)]) {
    for (final scale in [1.0, 2.0, 3.0]) {
      for (final keyboard in [0.0, 120.0]) {
        testWidgets('sheet fits Size($size) scale $scale keyboard $keyboard',
            (tester) async {
          await openDropdown(tester,
              size: size, scale: scale, keyboard: keyboard);
          await openSheet(tester);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
