import 'package:ZeroStress/providers/user_provider.dart';
import 'package:ZeroStress/screens/BreathingExercisePage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Modello dati per ogni tecnica di respirazione
class BreathingTechnique {
  final String name;
  final String description;
  final List<int> phases;
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

class BreathingSelectionPage extends StatefulWidget {
  BreathingSelectionPage({Key? key}) : super(key: key);

  @override
  State<BreathingSelectionPage> createState() => _BreathingSelectionPageState();
}

class _BreathingSelectionPageState extends State<BreathingSelectionPage> {
  static const String _customPrefKey = 'custom_breathing_values';
  
  // Le 4 tecniche di respirazione predefinite
  final List<BreathingTechnique> techniques = const [
    BreathingTechnique(
      name: '5-2-5',
      description: 'Calm & Relaxation',
      phases: [5, 2, 5, 0], // inhale, hold, exhale, hold, total time
      icon: Icons.self_improvement,
      accentColor: Color(0xFF8EAFCE),
    ),
    BreathingTechnique(
      name: '4-7-8',
      description: 'Deep Sleep & Anxiety Relief',
      phases: [4, 7, 8, 0],
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
      phases: [4, 0, 8, 0],
      icon: Icons.timer,
      accentColor: Color(0xFF6B9FAD),
    ),
  ];

  List<int> _customValues = [4, 0, 4, 0, 5];

  @override
  void initState() {
    super.initState();
    _loadCustomValues();
  }

  Future<void> _loadCustomValues() async {
    final sp = await SharedPreferences.getInstance();
    final saved = sp.getStringList(_customPrefKey);
    if (saved != null && saved.length == 5) {
      setState(() {
        _customValues = saved.map((v) => int.tryParse(v) ?? 0).toList();
      });
    }
  }

  Future<void> _saveCustomValues(List<int> values) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(
        _customPrefKey, values.map((v) => v.toString()).toList());
  }

  // Costruisce la stringa del nome custom tipo "4-4" o "4-2-4-2"
  String _buildCustomName() {
    final inhale = _customValues[0];
    final hold1 = _customValues[1];
    final exhale = _customValues[2];
    final hold2 = _customValues[3];

    final parts = <String>[];
    parts.add(inhale.toString());
    if (hold1 > 0) parts.add(hold1.toString());
    parts.add(exhale.toString());
    if (hold2 > 0) parts.add(hold2.toString());
    return parts.join('-');
  }

  void _showTechniqueDialog(BuildContext context, BreathingTechnique technique) {
    final provider = Provider.of<UserProvider>(context, listen: false);
    final totalCtrl = TextEditingController(text: provider.time.toString());

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: technique.accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(technique.icon, color: technique.accentColor, size: 28),
          ),
          
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  technique.description,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                _buildDialogField(
                  controller: totalCtrl,
                  label: 'Total Time (min)',
                  icon: Icons.timer_outlined,
                  color: technique.accentColor,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final total = int.tryParse(totalCtrl.text.trim()) ?? 0;
                if (total <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Session duration must be greater than 0'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BreathingExercisePage(
                      technique: technique,
                      totalTimeInSeconds: total * 60,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: technique.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Start', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showCustomDialog(BuildContext context) {
    // Controller temporanei inizializzati con i valori salvati
    final inhaleCtrl   = TextEditingController(text: _customValues[0].toString());
    final hold1Ctrl    = TextEditingController(text: _customValues[1].toString());
    final exhaleCtrl   = TextEditingController(text: _customValues[2].toString());
    final hold2Ctrl    = TextEditingController(text: _customValues[3].toString());
    final totalCtrl    = TextEditingController(text: _customValues[4].toString());

    final accentColor = const Color.fromARGB(193, 48, 167, 137); 

    showDialog(
      context: context,
      builder: (dialogContext){
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.tune, color: accentColor, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Custom Technique',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Choose the duration for each phase',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                _buildDialogField(
                  controller: inhaleCtrl,
                  label: 'Inhale (sec)',
                  icon: Icons.arrow_upward,
                  color: accentColor,
                ),
                const SizedBox(height: 14),
                _buildDialogField(
                  controller: hold1Ctrl,
                  label: 'Hold (sec)',
                  icon: Icons.pause,
                  color: accentColor,
                ),
                const SizedBox(height: 14),
                _buildDialogField(
                  controller: exhaleCtrl,
                  label: 'Exhale (sec)',
                  icon: Icons.arrow_downward,
                  color: accentColor,
                ),
                const SizedBox(height: 14),
                _buildDialogField(
                  controller: hold2Ctrl,
                  label: 'Hold (sec)',
                  icon: Icons.pause,
                  color: accentColor,
                ),
                const Divider(height: 28),
                const SizedBox(height: 14),
                _buildDialogField(
                  controller: totalCtrl,
                  label: 'Total Time (min)',
                  icon: Icons.timer_outlined,
                  color: accentColor,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final inhale = int.tryParse(inhaleCtrl.text.trim()) ?? 0;
                final hold1  = int.tryParse(hold1Ctrl.text.trim())  ?? 0;
                final exhale = int.tryParse(exhaleCtrl.text.trim()) ?? 0;
                final hold2  = int.tryParse(hold2Ctrl.text.trim())  ?? 0;
                final total  = int.tryParse(totalCtrl.text.trim())  ?? 0;

                if (inhale <= 0 || exhale <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Inhale and Exhale must be greater than 0'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                if (hold1 < 0 || hold2 < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Hold times cannot be negative'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                if (total <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Session duration must be greater than 0'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                if (inhale/60 + hold1/60 + exhale/60 + hold2/60 > total) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Check the values again'),
                      backgroundColor: Colors.redAccent,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  return;
                }

                final newValues = [inhale, hold1, exhale, hold2, total];
                setState(() => _customValues = newValues);
                _saveCustomValues(newValues);

                Navigator.pop(dialogContext);

                final customTechnique = BreathingTechnique(
                  name: _buildCustomName(),
                  description: 'Custom Breathing',
                  phases: newValues,
                  icon: Icons.tune,
                  accentColor: accentColor,
                );

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BreathingExercisePage(
                      technique: customTechnique,
                      totalTimeInSeconds: total * 60,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Save & Play', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // Helper per i campi del dialog
  Widget _buildDialogField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
        prefixIcon: Icon(icon, color: color, size: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: 2),
        ),
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        floatingLabelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              // Griglia 2x2
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
                      const SizedBox(height: 16),
                      // Card custom orizzontale in fondo
                      _buildCustomCard(context),
                      const SizedBox(height: 16),
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
        _showTechniqueDialog(context, technique);
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
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: technique.accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(technique.icon, color: technique.accentColor, size: 28),
              ),
              const SizedBox(height: 14),
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

  Widget _buildCustomCard(BuildContext context) {
    const accentColor =  Color.fromARGB(193, 48, 167, 137);

    return GestureDetector(
      onTap: () => _showCustomDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.black.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icona
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            // Testo centrale
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Custom',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Freccia
            const Icon(Icons.edit_outlined, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}