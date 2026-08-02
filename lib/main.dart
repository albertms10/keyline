import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/widgets/circle_of_fifths_screen.dart';
import 'package:web/web.dart';

Map<String, String>? initialQueryParameters;

void main() {
  initialQueryParameters = Uri.parse(window.location.href).queryParameters;
  runApp(const CircleOfFifthsApp());
}

class CircleOfFifthsApp extends StatelessWidget {
  const CircleOfFifthsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Keyline',
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: const Color(0xff256f72),
        ),
        scaffoldBackgroundColor: const Color(0xfff7f3ea),
        useMaterial3: true,
      ),
      home: CircleOfFifthsScreen(initialVectors: initialQueryParameters?['k']),
    );
  }
}
