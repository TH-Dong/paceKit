import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pacekit/src/shared/empty_state.dart';

void main() {
  testWidgets('EmptyState renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyState(
            icon: Icons.add_task_rounded,
            title: '还没有计划',
            subtitle: '添加一件最小可完成的事',
          ),
        ),
      ),
    );

    expect(find.text('还没有计划'), findsOneWidget);
    expect(find.text('添加一件最小可完成的事'), findsOneWidget);
    expect(find.byIcon(Icons.add_task_rounded), findsOneWidget);
  });
}
