import 'package:flutter/material.dart';
import 'screens/LoginPage.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF8EAFCE);
    const Color accentLavender = Color(0xFFBDB2FF);

    return MaterialApp(
      title: 'Breathing App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
            seedColor: primaryBlue,
            primary: primaryBlue,
            secondary: accentLavender
        ),

        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme
        ),

        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: primaryBlue, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          labelStyle: const TextStyle(color: Colors.grey),
          floatingLabelStyle: const TextStyle(color: primaryBlue)
        ),
      ),

      home : Login()
    );
  }
}
