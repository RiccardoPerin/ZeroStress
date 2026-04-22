import 'package:flutter/material.dart';
import 'HomePage.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';

class LoginPage extends StatefulWidget {
  LoginPage({Key? key}) : super(key: key);

  static const Color primaryAzure = Color(0xFF8EAFCE);
  static const Color focusedAzure = Color(0xFF5B85AA);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;

  // Necessario metodo dispose() per eliminare i controllori dalla memoria post login, altrimenti andrebbero ad occupare spazio
  // nella RAM per nulla. A memorizzarne i valori ci pensa il provider
  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
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
              _buildLogo(),
              const SizedBox(height: 60),                  
              _buildWelcome(),
              const SizedBox(height: 40),
              _buildPersonalFields(),
              const SizedBox(height: 20),             
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

  Widget _buildLogo() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            'assets/logo.png',
            height: 100,
          ),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Zero',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 50,
                    color: Color(0xFF384242),
                  )
                ),

                const TextSpan(
                  text: 'Stress',
                  style: TextStyle(
                    fontWeight: FontWeight.w200,
                    fontSize: 50,
                    color: LoginPage.primaryAzure,
                  )
                )
              ]
            )
          ),
        ],
      ),
    );
  }


  Widget _buildWelcome() {
    return const Column( // Avvolgi tutto in una Column
      crossAxisAlignment: CrossAxisAlignment.start, // Allinea il testo a sinistra
      children: [
        Text(
          'Welcome!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Color(0xFF384242),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Breathe in, breathe out...',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ],
    );
  }


  Widget _buildPersonalFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20.0)
            ),
            hintText: 'Enter your name',
            labelText: 'Name',
            prefixIcon: Icon(Icons.face_outlined)
          ),
        ),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0)
                  ),
                  hintText: 'cm',
                  labelText: 'Height',
                  prefixIcon: Icon(Icons.height)
                ),
              ),
            ),
            
            const SizedBox(width: 20),

            Expanded(
              child:TextField(
                controller: weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0)
                  ),
                  hintText: 'Kg',
                  labelText: 'Weight',
                  prefixIcon: Icon(Icons.monitor_weight_outlined)
                ),
              ),
            ),
          ],
        ),
      ],
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
          onPressed: () async {
            final provider = Provider.of<UserProvider>(context, listen: false);

            String? errorMessage = await provider.login(
              userController.text,
              passwordController.text,
              nameController.text,
              heightController.text,
              weightController.text,
            );

            if (!context.mounted) return;

            if (errorMessage == null) {
              // Successo
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: errorMessage.contains("errati")
                      ? Colors.redAccent
                      : Colors.orangeAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ), // Chiusura SnackBar
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
          child: const Text(
            'Login',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
          )
        )
    );
  }
}