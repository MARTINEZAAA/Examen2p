import 'package:examen2p/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login requires username and password', (tester) async {
    final users = <String, String>{};
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(users: users, onLoginSuccess: _noop),
      ),
    );

    await tester.tap(find.text('INGRESAR'));
    await tester.pumpAndSettle();

    expect(find.text('Ingresa tu usuario.'), findsOneWidget);
    expect(find.text('Ingresa tu contraseña.'), findsOneWidget);
  });

  testWidgets('a registered user can log in', (tester) async {
    final users = <String, String>{'admin': '1234'};
    var loggedIn = false;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(users: users, onLoginSuccess: () => loggedIn = true),
      ),
    );

    final registerLink = find.text('¿No tienes cuenta? Regístrate');
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'newuser');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
    await tester.ensureVisible(find.byType(TextFormField).at(2));
    await tester.enterText(find.byType(TextFormField).at(2), 'pass123');
    final createAccount = find.text('CREAR CUENTA');
    await tester.ensureVisible(createAccount);
    await tester.tap(createAccount);
    await tester.pumpAndSettle();

    expect(users['newuser'], 'pass123');
    await tester.enterText(find.byType(TextFormField).at(1), 'pass123');
    await tester.tap(find.text('INGRESAR'));
    await tester.pumpAndSettle();
    expect(loggedIn, isTrue);
  });
}

void _noop() {}
