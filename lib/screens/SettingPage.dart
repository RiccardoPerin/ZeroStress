import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../providers/user_provider.dart';
//import 'LoginPage.dart'; //Not needed anymore since we are using popUntil

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late TextEditingController nameController;
  late TextEditingController heightController;
  late TextEditingController weightController;
  late TextEditingController ageController;
  late String genderController;
  late TextEditingController timeController;
  double _currentSliderValue = 5;
  bool _forcePop = false; //Variabile necessaria per far si che possa tornare indietro dopo premere Save 


  @override
  void initState() {
    super.initState();
    
    // Leggiamo i valori ATTUALI dal provider una sola volta
    final provider = Provider.of<UserProvider>(context, listen: false);
    
    nameController = TextEditingController(text: provider.name);
    heightController = TextEditingController(text: provider.height > 0 ? provider.height.toString() : "");
    weightController = TextEditingController(text: provider.weight > 0 ? provider.weight.toString() : "");
    ageController = TextEditingController(text: provider.age > 0 ? provider.age.toString() : "");
    genderController = provider.gender;
    _currentSliderValue = provider.time > 0 ? provider.time.toDouble() : 5.0;
  }

  @override
  void dispose() { 
    nameController.dispose();
    heightController.dispose();
    weightController.dispose();
    super.dispose();
  }

  // Funzione per verificare se ci sono delle modifiche non salvate
  bool _hasUnsavedChanges() {
    final provider = Provider.of<UserProvider>(context, listen: false);
    
    String originalHeight = provider.height > 0 ? provider.height.toString() : "";
    String originalWeight = provider.weight > 0 ? provider.weight.toString() : "";
    double originalTime = provider.time > 0 ? provider.time.toDouble() : 5.0;

    return nameController.text != provider.name || 
           heightController.text != originalHeight || 
           weightController.text != originalWeight || 
           _currentSliderValue != originalTime;
  }

  // Funzione di salvataggio per il pop-up
  Future<bool> _saveChanges() async {
    FocusScope.of(context).unfocus(); // Nasconde tastiera
    final provider = Provider.of<UserProvider>(context, listen: false);

    bool success = await provider.updateProfile(
      nameController.text,
      heightController.text,
      weightController.text,
      ageController.text,
      genderController,
      _currentSliderValue
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Profile Updated!"), 
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        )
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Invalid data! Please check that all fields are correct"), 
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
        )
      );
    }
    return success;
  }

  // POP-UP se uscita senza salvataggio
  Future<void> _showExitWarning() async {
    final bool? shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        // Icona di attenzione in alto
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 48),
        title: const Text("Unsaved Changes", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          "You have modified some information.\nDo you want to save before leaving?",
          textAlign: TextAlign.center, 
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly, 
        actions: [

          // Tasto DISCARD
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), 
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.1), 
              foregroundColor: Colors.redAccent,
              elevation: 0, 
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
            child: const Text("DISCARD", style: TextStyle(fontWeight: FontWeight.bold)),
          ),

          // Tasto SAVE
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context, false);
              bool saved = await _saveChanges();
              if (saved && mounted) {
                setState(() { _forcePop = true; }); // Sblocca
                WidgetsBinding.instance.addPostFrameCallback((_) { //Dice a flutter di fare questo non appena ha finito cio che sta facendo
                  if (mounted) Navigator.pop(context);
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))
            ),
            child: const Text("SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      )
    );

    // Se l'utente ha cliccato "DISCARD", chiudiamo la pagina Settings
    if (shouldExit == true && mounted) {
      Navigator.pop(context); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope( // popscope per 'bloccare' il tasto indietro
      canPop: _forcePop || !_hasUnsavedChanges(), //Se _forcePop è vero o se non ci sono modifiche allora può tornare indietro
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Se è già uscito, ignora

        if (_hasUnsavedChanges()) {
          // Se ci sono modifiche, mostra il popup
          await _showExitWarning();
        } else {
          // Se non ci sono modifiche, esce normalmente
          Navigator.pop(context);
        }
      },
    
      child: Scaffold(
        extendBodyBehindAppBar: true, 
        appBar: _createAppBar(context),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary, 
                Theme.of(context).colorScheme.secondary 
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [

                        _buildPersonalInfo(context),

                        const SizedBox(height: 20),

                        _buildTimeInfo(context),

                        const SizedBox(height: 20),

                        _buildDangerZone(context),

                      ]
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  // --- WIDGETS DI SUPPORTO ---

  PreferredSizeWidget _createAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: const Text("SETTINGS", style: TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        _buildSaveButton(context),
        const SizedBox(width: 20)
      ],
    );
  }

  Widget _buildPersonalInfo(BuildContext context) {

    // regola per le etichette dei campi
    final floatingStyleRule = MaterialStateTextStyle.resolveWith((states) {
      final Color color = states.contains(MaterialState.focused) ? Theme.of(context).colorScheme.primary : Colors.grey;
      return TextStyle(color: color, fontWeight: FontWeight.bold);
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_circle_outlined),
              SizedBox(width: 8),
              Text("PERSONAL INFO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),

          const SizedBox(height: 20),

          TextField(
            controller: nameController,
            decoration: InputDecoration(
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: const BorderSide(color: Colors.grey, width: 1.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
              ),
              labelText: 'Name',
              labelStyle: const TextStyle(color: Colors.grey), // Testo a riposo
              floatingLabelStyle: floatingStyleRule,
              prefixIcon: const Icon(Icons.face_outlined)
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                    ),
                    labelText: 'Height',
                    labelStyle: const TextStyle(color: Colors.grey), // Testo a riposo
                    floatingLabelStyle: floatingStyleRule,
                    prefixIcon: const Icon(Icons.height)
                  ),
                ),
              ),
                  
              const SizedBox(width: 20),

              Expanded(
                child:TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                    ),
                    labelText: 'Weight',
                    labelStyle: const TextStyle(color: Colors.grey), // Testo a riposo
                    floatingLabelStyle: floatingStyleRule,
                    prefixIcon: const Icon(Icons.monitor_weight_outlined)
                  ),
                ),
              )
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: genderController,
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(20.0),
                icon: const Icon(Icons.arrow_drop_down_outlined),
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0), 
                  prefixIcon: const Icon(Icons.person_outline),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                  ),
                  labelText: 'Sex',
                  labelStyle: const TextStyle(color: Colors.grey), // Testo a riposo
                  floatingLabelStyle: floatingStyleRule,
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
                child:
                TextField(
                  controller: ageController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: false),
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: const BorderSide(color: Colors.grey, width: 1.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20.0),
                      borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2.0),
                    ),
                    labelText: 'Age',
                    labelStyle: const TextStyle(color: Colors.grey), // Testo a riposo
                    floatingLabelStyle: floatingStyleRule,
                    prefixIcon: const Icon(Icons.elderly_outlined)
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
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

  Widget _buildSaveButton(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton(
        onPressed: () async {
          FocusScope.of(context).unfocus();

          final provider = Provider.of<UserProvider>(context, listen: false);

          bool success = await provider.updateProfile(
            nameController.text,
            heightController.text,
            weightController.text,
            ageController.text,
            genderController,
            _currentSliderValue
          );

          //if (context.mounted) return;

          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Profile Updated!"), 
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );

            setState(() {
              _forcePop = true;
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.pop(context);
            });

            //Navigator.pop(context);

          } 
          else {
            // Popup di errore (rosso)
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Invalid data! Please check that all fields are correct"),
                backgroundColor: Colors.redAccent,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          //backgroundColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Colors.white, 
              width: 2, 
            ),
          )
        ),
        child: const Text(
          'Save',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)
        )
      )
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    final provider = Provider.of<UserProvider>(context, listen: false);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.blueGrey),
                title: const Text("Logout", style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () async {
                  await provider.logout();
                  // Torna alla schermata di Login
                  if (context.mounted) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
              ),
            ),

            const VerticalDivider(),

            Expanded(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                title: const Text("Reset Data", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                onTap: () => _showResetConfirmation(context, provider),
              )
            ),
          ],
        ),
      )
    );
  }

  // Popup di conferma prima di resettare tutto
  Future<void> _showResetConfirmation(BuildContext context, UserProvider provider) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Are you sure?"),
        content: const Text("This will permanently delete all your data and reset the app."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("RESET", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.resetAllData();
      if (context.mounted) {
        // Va indietro fino alla prima (login)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
}