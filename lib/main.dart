import 'package:ZeroStress/providers/health_data_provider.dart';
import 'package:ZeroStress/providers/polar_provider.dart';
import 'package:ZeroStress/providers/user_provider.dart';
import 'package:ZeroStress/services/notification_service.dart';
import 'screens/HomePage.dart';
import 'screens/onBoardingPage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/LoginPage.dart';
import 'package:google_fonts/google_fonts.dart';

void main () async {
  WidgetsFlutterBinding.ensureInitialized();
  final userProvider = UserProvider();
  await userProvider.loadUser(); // Carica i dati prima di far partire l'app

  await NotificationService.instance.init();
  GoogleFonts.config.allowRuntimeFetching = false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => userProvider),
        ChangeNotifierProvider(create: (context) => HealthDataProvider()),
        ChangeNotifierProvider(create: (context) => PolarProvider()),
      ],
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

        textTheme: GoogleFonts.nunitoTextTheme( //poppinsTextTheme altrimenti
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

      home: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (!provider.isLoggedIn) {
            return LoginPage();
          }
          else if (!provider.hasDoneOnboarding) {
            return OnBoardingPage();
          }
          else {
            return HomePage(userName: provider.name);
          }
        }
      )
    );
  }


}
