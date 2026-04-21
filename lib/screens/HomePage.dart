import 'package:flutter/material.dart';
import 'SettingPage.dart';

class HomePage extends StatelessWidget {
  final String userName; // Riceviamo il nome dal Login

  const HomePage({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, //Serve perchè AppBar tiene sfondo solido
      // Build AppBar
      appBar: _createAppBar(context),

      body: Container(
        // SFONDO CON GRADIENTE
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary, // Azzurro
              Theme.of(context).colorScheme.secondary // Viola Pastello
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // CONTENUTO SCROLLABILE (Per far stare tutto lo schizzo)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // STREAK & RECAP BOX
                      _buildStreakBox(),
                      const SizedBox(height: 20),

                      // TODAY STRESS & RECOVERY (Due box affiancati)
                      Row(
                        children: [
                          Expanded(child: _buildSmallStatCard("Today Stress", "Medium", Colors.orangeAccent)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildSmallStatCard("Recovery", "High", Colors.greenAccent)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // GRAFICO RHR
                      _buildWideChartCard("Resting HR Trend", "RHR +20%"),
                      const SizedBox(height: 20),

                      // BOX CIRCOLARE (Progressi/Anello)
                      _buildCircularProgressCard("Daily Goal"),
                    ],
                  ),
                ),
              ),
              
              // 4. NAVIGATION BAR (Home e Respiro)
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DI SUPPORTO (Seguendo il tuo schizzo) ---
  String _greeting() {
    final hourNow = DateTime.now().hour;
    if (hourNow > 5 && hourNow < 13) {
      return 'Morning';
    }
    else if (hourNow > 13 && hourNow < 18) {
      return 'Afternoon';
    }
    else if (hourNow > 18 && hourNow < 22) {
      return 'Evening';
    }
    else {
      return 'Night';
    }
  }

  //Deve essere PreferredSizeWidget perchè AppBar è già implementata ma facciamo così per miglior lettura codice
  PreferredSizeWidget _createAppBar(BuildContext context) {
    String greet = _greeting();
    return AppBar(
      backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text("Good $greet,", style: TextStyle(color: Colors.white70, fontSize: 20)),
                    Text(userName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                  ],
                ),
          actions: [
            IconButton(
              onPressed: () {
                //Navigator.push(
                  //context, 
                  //MaterialPageRoute(builder: (context) => SettingPage(userName: userName)));
              },
              icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 28)
            ),
          ],
    );
  }

  Widget _buildStreakBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: const Column(
        children: [
          Text("STREAK USO SEZIONE RESPIRAZ.", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Divider(color: Colors.white24),
          Text("Recap disponibile dopo la notifica", style: TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
        ],
      ),
    );
  }

  Widget _buildWideChartCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(subtitle, style: const TextStyle(color: Colors.redAccent, fontSize: 10)),
          const Spacer(),
          const Center(child: Text("📊 Qui andrà il grafico fl_chart", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  Widget _buildCircularProgressCard(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(
            height: 50, width: 50,
            child: CircularProgressIndicator(value: 0.7, strokeWidth: 8, color: Color(0xFF8EAFCE)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          const Icon(Icons.home, color: Color(0xFF8EAFCE), size: 30),
          IconButton(
            icon: const Icon(Icons.air, color: Colors.grey, size: 30),
            onPressed: () { /* Naviga alla sezione respiro */ },
          ),
        ],
      ),
    );
  }
}