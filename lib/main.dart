import 'package:ZeroStress/providers/user_provider.dart';
import 'package:ZeroStress/screens/BreathingExercisePage.dart';
import 'package:ZeroStress/screens/SettingPage.dart';
import 'screens/HomePage.dart';
import 'screens/onBoardingPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/LoginPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/BreathingSelectionPage.dart';

void main () async {
  WidgetsFlutterBinding.ensureInitialized();
  final userProvider = UserProvider();
  await userProvider.loadUser(); // Carica i dati prima di far partire l'app

  runApp(
    ChangeNotifierProvider(
      create: (context) => userProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF8EAFCE);
    const Color accentLavender = Color(0xFFBDB2FF);

    final userProvider = Provider.of<UserProvider>(context);

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
      //home: BreathingSelectionPage(),
     home : userProvider.isLoggedIn
        ? (userProvider.hasDoneOnboarding)
        ? HomePage(userName: userProvider.name)
         : OnBoardingPage()
         : LoginPage()
      //home: HomePage(userName: userProvider.name),
      //home: SettingPage(),
      //home: BreathingExercisePage(),
    );
  }


}
