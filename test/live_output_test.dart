import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_horizon_app/main.dart';

void main() {
  testWidgets(
    'accumulates stream messages and changes demo connection states',
    (tester) async {
      await tester.pumpWidget(const MainApp());
      expect(find.textContaining('Text from your hardware'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('test test test\n\ntable ahead'), findsOneWidget);

      await tester.ensureVisible(find.text('Hardware connecting'));
      await tester.tap(find.text('Hardware connecting'));
      await tester.pump();
      expect(find.text('Connecting'), findsOneWidget);
      expect(find.text('Connecting…'), findsOneWidget);

      await tester.tap(find.text('Hardware offline'));
      await tester.pump();
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Waiting for connection'), findsOneWidget);

      await tester.tap(find.text('Model offline'));
      await tester.pump();
      final model = tester.widget<StatusPill>(
        find.byWidgetPredicate(
          (widget) => widget is StatusPill && widget.label == 'Model',
        ),
      );
      expect(model.status, ConnectionStatus.offline);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    },
  );

  testWidgets('fits a narrow phone without layout overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MainApp());
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Model offline'));
    await tester.tap(find.text('Model offline'));
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
  });
}
