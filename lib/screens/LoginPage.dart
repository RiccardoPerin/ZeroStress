import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/utils.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  static const Color primaryAzure = Color(0xFF8EAFCE);
  static const Color focusedAzure = Color(0xFF5B85AA);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  // Necessario metodo dispose() per eliminare i controllori dalla memoria post login, altrimenti andrebbero ad occupare spazio
  // nella RAM per nulla. A memorizzarne i valori ci pensa il provider
  @override
  void dispose() {
    userController.dispose();
    passwordController.dispose();
    super.dispose(); //Flutter pulisce il widget
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLogo(),
              const SizedBox(height: 60),                  
              buildMessage('Welcome!', 'Breathe in, breathe out...'),
              const SizedBox(height: 40),             
              _buildUsernameField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 40),
              _buildLoginButton()    
            ],
          ),
        )
      )
    );
  }


  Widget _buildUsernameField() {
    return TextField(
      controller: userController,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0)
        ),
        hintText: 'Enter your username',
        labelText: 'Username',
        prefixIcon: Icon(Icons.account_circle_outlined)
      ),
    );
  }


  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0)
        ),
        hintText: 'Enter your password',
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outline),
        
        //Icona per nascondere/mostrare password
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          }, 
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey
          )
        )
      ),
    );
  }

  Widget _buildLoginButton() {
    return Align(
      alignment: Alignment.center,
      child: 
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            setState(() => _isLoading = true);

            final provider = Provider.of<UserProvider>(context, listen: false);

            String? errorMessage = await provider.login(
              userController.text,
              passwordController.text
            );

            if (!context.mounted) return;

            setState(() => _isLoading = false);

            if (errorMessage == null) {
              // Successo
            }
            else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: Duration(seconds: 2),
                ),
              ); // Chiusura showSnackBar
            }
          }, // Chiusura onPressed
          style: ElevatedButton.styleFrom(
            backgroundColor: LoginPage.primaryAzure,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 18),
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30)
            )
          ),
          child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
            : const Text(
                'Login',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              )
        )
    );
  }
}