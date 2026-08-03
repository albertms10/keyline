import 'package:flutter/material.dart' hide Interval, Key;
import 'package:keyline/colors.dart';
import 'package:keyline/query_parameters.dart';
import 'package:keyline/widgets/circle_of_fifths_screen.dart';
import 'package:web/web.dart';

late QueryParameters queryParameters;

void main() {
  queryParameters = QueryParameters.fromUri(.parse(window.location.href));
  runApp(const CircleOfFifthsApp());
}

class CircleOfFifthsApp extends StatefulWidget {
  const CircleOfFifthsApp({super.key});

  @override
  State<CircleOfFifthsApp> createState() => _CircleOfFifthsAppState();
}

class _CircleOfFifthsAppState extends State<CircleOfFifthsApp> {
  ThemeMode _themeMode = .light;

  ThemeData _buildTheme(Brightness brightness) {
    final palette = brightness == .dark
        ? KeylineColors.dark
        : KeylineColors.light;

    return ThemeData(
      colorScheme: .fromSeed(
        seedColor: const Color(0xff256f72),
        brightness: brightness,
      ),
      scaffoldBackgroundColor: palette.surface,
      useMaterial3: true,
      extensions: [palette],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Keyline',
      themeMode: _themeMode,
      theme: _buildTheme(.light),
      darkTheme: _buildTheme(.dark),
      home: CircleOfFifthsScreen(
        initialVectors: queryParameters.keys,
        themeMode: _themeMode,
        onThemeModeChanged: (mode) {
          setState(() {
            _themeMode = mode;
          });
        },
      ),
    );
  }
}
