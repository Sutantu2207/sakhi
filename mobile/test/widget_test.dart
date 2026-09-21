import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sakhi/widgets/risk_badge.dart';
import 'package:sakhi/widgets/sos_button.dart';

void main() {
  testWidgets('RiskBadge renders lower reported risk correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RiskBadge(category: 'lower_reported_risk'),
        ),
      ),
    );

    expect(find.text('Lower reported risk'), findsOneWidget);
  });

  testWidgets('RiskBadge renders moderate and higher reported risk correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              RiskBadge(category: 'moderate_reported_risk'),
              RiskBadge(category: 'higher_reported_risk'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Moderate reported risk'), findsOneWidget);
    expect(find.text('Higher reported risk'), findsOneWidget);
  });

  testWidgets('SOSButton renders and handles tap callback', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SOSButton(
            onTap: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('SOS'), findsOneWidget);
    expect(find.text('EMERGENCY'), findsOneWidget);

    await tester.tap(find.text('SOS'));
    expect(tapped, isTrue);
  });
}
