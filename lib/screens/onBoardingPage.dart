import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'LoginPage.dart';

class OnBoardingPage extends StatefulWidget {
  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogo(),
              const SizedBox(height: 60),
              _buildOnBoardingMessage(),
              const SizedBox(height: 40),
              _buildPersonalFields(),
              const SizedBox(height: 60),
              _buildEnterButton()
            ]
          )
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

  Widget _buildOnBoardingMessage() {
    return const Column( // Avvolgi tutto in una Column
      crossAxisAlignment: CrossAxisAlignment.start, // Allinea il testo a sinistra
      children: [
        Text(
          'Nice meeting you!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Color(0xFF384242),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Insert some information about you...',
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

  Widget _buildEnterButton() {
    return Align(
      alignment: Alignment.center,
      child: 
        ElevatedButton(
          onPressed: () async {
            final provider = Provider.of<UserProvider>(context, listen: false);
            String? errorMessage = await provider.completeOnboarding(
              nameController.text,
              heightController.text,
              weightController.text,
            ); 

            if (!context.mounted) return;

            if (errorMessage == null) {
              // Successo
            } 
            else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMessage),
                  backgroundColor: Colors.orangeAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          child: const Text(
            "Let's start!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
          )
        )
    );
  }
}