import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'LoginPage.dart';
import '../services/utils.dart';

class OnBoardingPage extends StatefulWidget {
  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  String genderController = "";
  double _currentSliderValue = 5.0;

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
      //backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              buildLogo(),
              const SizedBox(height: 60),
              buildMessage('Nice meeting you!', 'Let me know more about you...'),
              const SizedBox(height: 40),
              _buildPersonalFields(),
              const SizedBox(height: 10),
              _buildTimeSelector(),
              const SizedBox(height: 60),
              _buildEnterButton()
            ]
          )
        ),
      )
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

        const SizedBox(height: 10),

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
        
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                icon: const Icon(Icons.arrow_drop_down_outlined),
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), // Più respiro all'interno
                  prefixIcon: const Icon(Icons.person_outline),
                  hintText: 'Sex',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                items: ['Male', 'Female']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (value) {
                  genderController = value!;
                },
              ),
            ),
            
            const SizedBox(width: 20),

            Expanded(
              child:TextField(
                controller: ageController,
                keyboardType: TextInputType.numberWithOptions(decimal: false),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20.0)
                  ),
                  labelText: 'Age',
                  prefixIcon: Icon(Icons.elderly_outlined)
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timer_outlined, color: Colors.blueGrey),
              SizedBox(width: 8),
              Text("DAILY TIME GOAL", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),

          // 2. Slider per i minuti
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _currentSliderValue,
                  min: 1,
                  max: 60,
                  divisions: 59, // Divide lo slider in step da 1 minuto (1, 2, ..., 10)
                  label: "${_currentSliderValue.toInt()} min",
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (double value) {
                    setState(() {
                      _currentSliderValue = value;
                    });
                  },
                ),
              ),
              // 3. Mostra il valore numerico a destra
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "${_currentSliderValue.toInt()} min",
                  style: TextStyle(
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).colorScheme.primary
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
              ageController.text,
              genderController,
              _currentSliderValue
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
          child: const Text(
            "Let's start!",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
          )
        )
    );
  }
}