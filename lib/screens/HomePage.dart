import 'package:flutter/material.dart';
import 'SettingPage.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HomePage extends StatefulWidget {
  final String userName; // Riceviamo il nome dal Login

  const HomePage({Key? key, required this.userName}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, //Serve perchè AppBar tiene sfondo solido
      // Build AppBar
      appBar: _createAppBar(context),

      body: Container(
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
                          Expanded(child: _buildSmallStatCard("Today Stress", "Medium", Colors.orangeAccent, 30.0)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildSmallStatCard("Recovery", "High", Colors.greenAccent, 30.0)),
                        ],
                      ),
                      const SizedBox(height: 15),

                      // GRAFICO RHR
                      _buildWideChartCard("Resting HR Trend", "RHR +20%"),
                      const SizedBox(height: 15),

                      // BOX CIRCOLARE (Progressi/Anello)
                      _buildDailyGoalCard("Daily Goal", 20.0, 15.0),
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
                    Text(widget.userName.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold)),
                  ],
                ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => SettingPage()));
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

  Widget _buildSmallStatCard(String title, String value, Color color, double valPerc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 10),

          Center(
            child: Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color.withOpacity(0.8)))
          ),
              
          const SizedBox(height: 5),

          Center(
            child: SizedBox(
                height: 120,
                child: SfRadialGauge(
                  axes: <RadialAxis>[ //Serve per avere il cerchio di progresso
                          RadialAxis(
                            minimum: 0,
                            maximum: 100,
                            showLabels: false,
                            showTicks: false,
                            axisLineStyle: AxisLineStyle(
                              thickness: 0.2,
                              cornerStyle: CornerStyle.bothCurve,
                              color: Color.fromARGB(30, 0, 169, 181),
                              thicknessUnit: GaugeSizeUnit.factor,
                            ),
                            pointers: <GaugePointer>[
                              RangePointer(
                                value: valPerc,
                                cornerStyle: CornerStyle.bothCurve,
                                width: 0.2,
                                sizeUnit: GaugeSizeUnit.factor,
                                color: color.withOpacity(0.8),
                              )
                            ],
                            annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                positionFactor: 0,
                                angle: 90,
                                widget: Text(
                                  "${valPerc.toStringAsFixed(0)}%",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)
                                )
                              )
                            ]
                          )
                        ]
                ),
            ),
          )   
        ]
      )
    );
  }

  Widget _buildWideChartCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
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

  Widget _buildDailyGoalCard(String title, double timeGoal, double timeDone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Padding bilanciato
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        // Centra verticalmente tutti i figli della Row (titolo e gauge)
        crossAxisAlignment: CrossAxisAlignment.center, 
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Occupa solo lo spazio necessario
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, 
                    fontSize: 20,
                    color: Color(0xFF384242),
                  ),
                ),
                const Text(
                  "Daily progress", 
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          SizedBox(
            height: 110,
            width: 110,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  minimum: 0,
                  maximum: timeGoal,
                  showLabels: false,
                  showTicks: false,
                  radiusFactor: 1, 
                  axisLineStyle: AxisLineStyle(
                    thickness: 0.15,
                    cornerStyle: CornerStyle.bothCurve,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    thicknessUnit: GaugeSizeUnit.factor,
                  ),
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: timeDone,
                      cornerStyle: CornerStyle.bothCurve,
                      width: 0.15,
                      sizeUnit: GaugeSizeUnit.factor,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      positionFactor: 0,
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "${timeDone.toStringAsFixed(0)} / ${timeGoal.toStringAsFixed(0)}",
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: Theme.of(context).colorScheme.primary
                            ),
                          ),
                          Text(
                            "minutes", 
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  ]
                )
              ]
            ),
          ), 
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 5),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        //boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
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