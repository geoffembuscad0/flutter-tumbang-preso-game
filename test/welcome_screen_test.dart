import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_tumbang_preso/main.dart';

// The can wobbles forever, so pumpAndSettle would never finish. These tests
// use pump(Duration) to move past route and sheet transitions instead.
const _transition = Duration(milliseconds: 500);

void main() {
  testWidgets('landing page shows both actions', (tester) async {
    await tester.pumpWidget(const TumbangPresoApp());

    expect(find.text('Play Game'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
  });

  testWidgets('How to Play opens and closes', (tester) async {
    await tester.pumpWidget(const TumbangPresoApp());

    await tester.tap(find.text('How to Play'));
    await tester.pump(_transition);
    expect(find.text('How to play'), findsOneWidget);

    await tester.ensureVisible(find.text('Got it'));
    await tester.tap(find.text('Got it'));
    await tester.pump(_transition);
    expect(find.text('How to play'), findsNothing);
  });

  testWidgets('Play Game opens player setup', (tester) async {
    await tester.pumpWidget(const TumbangPresoApp());

    await tester.tap(find.text('Play Game'));
    await tester.pump(_transition);

    expect(find.text('Player setup'), findsOneWidget);
  });

  testWidgets('fits a small phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const TumbangPresoApp());

    expect(tester.takeException(), isNull);
    expect(find.text('Play Game'), findsOneWidget);
  });
}
