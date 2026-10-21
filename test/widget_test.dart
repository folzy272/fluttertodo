import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo_manager/widgets/error_widget.dart';

void main() {
  testWidgets('Екран помилки показує повторну спробу', (tester) async {
    var retried = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ErrorView(
          message: 'HTTP 503',
          onRetry: () => retried = true,
        ),
      ),
    ));

    expect(find.text('HTTP 503'), findsOneWidget);
    await tester.tap(find.text('Повторити'));
    expect(retried, isTrue);
  });
}
