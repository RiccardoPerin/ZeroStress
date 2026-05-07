import 'package:flutter/material.dart';


// Modello dati per ogni tecnica di respirazione
class BreathingTechnique {
  final String name;
  final String description;
  final List<int> phases; // durata in secondi per ogni fase
  final IconData icon;
  final Color accentColor;

  const BreathingTechnique({
    required this.name,
    required this.description,
    required this.phases,
    required this.icon,
    required this.accentColor,
  });
}

class BreathingSelectionPage extends StatelessWidget {
  BreathingSelectionPage({Key? key}) : super(key: key);

  // Le 4 tecniche di respirazione
  final List<BreathingTechnique> techniques = const [
    BreathingTechnique(
      name: '5-2-5',
      description: 'Calm & Relaxation',
      phases: [5, 2, 5],
      icon: Icons.self_improvement,
      accentColor: Color(0xFF8EAFCE),
    ),
    BreathingTechnique(
      name: '4-7-8',
      description: 'Deep Sleep & Anxiety Relief',
      phases: [4, 7, 8],
      icon: Icons.nightlight_round,
      accentColor: Color(0xFFBDB2FF),
    ),
    BreathingTechnique(
      name: '4-4-4-4',
      description: 'Box Breathing & Focus',
      phases: [4, 4, 4, 4],
      icon: Icons.wb_incandescent,
      accentColor: Color(0xFFD4A9C7),
    ),
    BreathingTechnique(
      name: '4-8',
      description: 'Quick Stress Relief',
      phases: [4, 8],
      icon: Icons.timer,
      accentColor: Color(0xFF6B9FAD)
    ),
  ];

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Sottotitolo
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                  'Choose your breathing technique',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
              // Griglia card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildTechniqueCard(context, techniques[0])),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTechniqueCard(context, techniques[1])),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _buildTechniqueCard(context, techniques[2])),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTechniqueCard(context, techniques[3])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
      onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'BREATHING SELECTION',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildTechniqueCard(BuildContext context, BreathingTechnique technique) {
    return GestureDetector(
      onTap: () {
        // Placeholder: navigazione alla pagina dell'esercizio (da definire)
        // Navigator.push(context, MaterialPageRoute(
        //   builder: (context) => BreathingExercisePage(technique: technique),
        // ));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icona con cerchio colorato
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: technique.accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  technique.icon,
                  color: technique.accentColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              // Nome della tecnica (grande)
              Text(
                technique.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: technique.accentColor,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              // Descrizione
              Text(
                technique.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}