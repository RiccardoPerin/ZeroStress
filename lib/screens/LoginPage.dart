import 'package:flutter/material.dart';

class Login extends StatelessWidget {
  Login({Key? key}) : super(key: key);

  final TextEditingController nameController = TextEditingController();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  static const Color primaryAzure = Color(0xFF8EAFCE);
  static const Color focusedAzure = Color(0xFF5B85AA);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/logo.png',
                    height: 100,
                  ),
                  const SizedBox(width: 10,),
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
                            color: primaryAzure,
                          )
                        )
                      ]
                    )
                  ),
                ],
              ),

              const SizedBox(height: 60),
                  
              const Text(
                'Welcome!',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 32,
                  // Optional color
                  color: Color(0xFF384242)),
              ),

              const SizedBox(height: 10),

              const Text(
                //'Login',
                'Breathe in, breathe out...',
                style: TextStyle(
                  color: Colors.grey, 
                  fontSize: 16),
              ),

              const SizedBox(height: 40),

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

              TextField(
                controller: userController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0)
                  ),
                  hintText: 'Enter your username',
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.account_circle_outlined)
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0)
                  ),
                  hintText: 'Enter your password',
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline)
                ),
              ),

              const SizedBox(height: 40),
              
              Align(
                alignment: Alignment.center,
                child: 
                  ElevatedButton(
                    onPressed: () {
                      // Login Logic TODO
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAzure,
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
              ),    
            ],
          ),
        )
      )
    );
  }
}