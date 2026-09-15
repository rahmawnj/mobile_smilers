import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:smile_rs/main.dart';

void main() {
  testWidgets('login page renders its controls', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('RUMAH SAKIT\nANUGERAH GLOBAL SEHAT'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
    expect(find.text('Stream Linen'), findsOneWidget);

    await tester.tap(find.text('Masuk'));
    await tester.pumpAndSettle();
    expect(find.text('Linen & Tirai Ready'), findsOneWidget);
    expect(find.text('Keluar Masuk Linen & Tirai'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('account-settings')));
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT & SETTING'), findsOneWidget);
    expect(find.text('Ganti Sandi'), findsOneWidget);
    expect(find.text('Manual Book'), findsOneWidget);
    expect(find.text('Tentang SMileRS'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('Rusak'));
    await tester.pumpAndSettle();
    expect(find.text('LINEN & TIRAI RUSAK'), findsOneWidget);
    expect(find.text('Nama Linen'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Hilang'));
    await tester.pumpAndSettle();
    expect(find.text('LINEN & TIRAI HILANG'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Linen & Tirai Ready'));
    await tester.pumpAndSettle();
    expect(find.text('LINEN & TIRAI READY'), findsOneWidget);
    expect(find.text('Nama Kategori'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('transaction-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transaction-0')));
    await tester.pumpAndSettle();
    expect(find.text('LINEN & TIRAI KELUAR'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('transaction-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transaction-1')));
    await tester.pumpAndSettle();
    expect(find.text('LINEN & TIRAI MASUK'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('transaction-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('transaction-2')));
    await tester.pumpAndSettle();
    expect(find.text('PERMINTAAN LINEN & TIRAI'), findsOneWidget);
  });
}
