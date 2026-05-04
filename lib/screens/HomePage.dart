import 'package:ZeroStress/providers/user_provider.dart';
import 'package:ZeroStress/screens/BreathingSelectionPage.dart';
import 'package:flutter/material.dart';
import 'SettingPage.dart';
import 'package:provider/provider.dart'; 
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:fl_chart/fl_chart.dart';


class HomePage extends StatefulWidget {
  final String userName; // Riceviamo il nome dal Login

  const HomePage({Key? key, required this.userName}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String infoStress = '';
  String infoRecovery = '';
  String infoRHR = '';

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
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
                          Expanded(child: _buildSmallStatCardIncreasingValue("Today Stress", 30.0, infoStress)),
                          const SizedBox(width: 15),
                          Expanded(child: _buildSmallStatCardDecreasingValue("Recovery", 80, infoRecovery))
                        ],
                      ),
                      const SizedBox(height: 10),

                      // GRAFICO RHR
                      _buildRHRChartCard("Resting HR Trend", infoRHR),
                      const SizedBox(height: 10),

                      _buildDailyGoalCard("Daily Goal", userProvider.time.toDouble(), 30.0),
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

  //IncreasingValue perchè serve per creare Stress level, per cui il colore 'peggiora' al crescere
  Widget _buildSmallStatCardIncreasingValue(String title, double valPerc, String info) {
    Color colorTxt = Colors.greenAccent;
    String txtVal = '';
    if (valPerc >= 0 && valPerc <= 20) {
      colorTxt = Colors.greenAccent;
      txtVal = 'Low';
    }
    else if (valPerc > 20 && valPerc <= 60) {
      colorTxt = Colors.orangeAccent;
      txtVal = 'Medium';
    }
    else {
      colorTxt = Colors.redAccent;
      txtVal = 'High';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.5)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Qui potrai mostrare un dialogo o un messaggio con la stringa 'info'
                },
                icon: const Icon(Icons.info_outline),
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                color: Colors.grey,
              ),
            ],
          ),

          Center(
            child: Text(txtVal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorTxt.withOpacity(0.8)))
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
                                color: colorTxt.withOpacity(0.8),
                              )
                            ],
                            annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                positionFactor: 0,
                                angle: 90,
                                widget: Text(
                                  "${valPerc.toStringAsFixed(0)}%",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorTxt)
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

  //DecreasingValue perchè serve per creare Recovery level, per cui il colore 'migliora' al crescere
  Widget _buildSmallStatCardDecreasingValue(String title, double valPerc, String info) {
    Color colorTxt = Colors.greenAccent;
    String txtVal = '';
    if (valPerc >= 0 && valPerc <= 15) {
      colorTxt = Colors.redAccent;
      txtVal = 'Low';
    }
    else if (valPerc > 15 && valPerc <= 50) {
      colorTxt = Colors.orangeAccent;
      txtVal = 'Medium';
    }
    else {
      colorTxt = Colors.greenAccent;
      txtVal = 'High';
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.5)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Qui potrai mostrare un dialogo o un messaggio con la stringa 'info'
                },
                icon: const Icon(Icons.info_outline),
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                color: Colors.grey,
              ),
            ],
          ),

          Center(
            child: Text(txtVal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorTxt.withOpacity(0.8)))
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
                                color: colorTxt.withOpacity(0.8),
                              )
                            ],
                            annotations: <GaugeAnnotation>[
                              GaugeAnnotation(
                                positionFactor: 0,
                                angle: 90,
                                widget: Text(
                                  "${valPerc.toStringAsFixed(0)}%",
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorTxt)
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

  Widget _buildRHRChart(double rhr) {
    double threshold = 1.2 * rhr;
    return SizedBox(
      height: 130, 
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => Theme.of(context).primaryColor.withOpacity(0.8),
              getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                return touchedBarSpots.map((barSpot) {
                  return LineTooltipItem(
                    '${barSpot.y.toInt()} BPM',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  );
                }).toList();
              },
            ),
            handleBuiltInTouches: true,
          ),

          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: threshold,
                color: Colors.redAccent.withOpacity(0.8),
                strokeWidth: 2,
                dashArray: [10, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 5, bottom: 5),
                  style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                    fontSize: 10
                  ),
                  labelResolver: (line) => 'RHR + 20%'
                )
              )
            ]
          ),
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: false,
            drawVerticalLine: false, // Pulizia: solo linee orizzontali
            horizontalInterval: 10, 
            getDrawingHorizontalLine: (value) => const FlLine(
              color: Colors.grey,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  // Mostriamo i giorni della settimana abbreviati
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(days[value.toInt()], 
                        style: const TextStyle(color: Colors.grey, fontSize: 10)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 10, // Mostra 40, 60, 80 BPM
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          // Adattiamo i limiti per il battito cardiaco
          minX: 0,
          maxX: 6,  // 7 giorni (0-6)
          minY: 40, // Minimo BPM
          maxY: 80, // Massimo BPM
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 50),
                FlSpot(1, 61),
                FlSpot(2, 58),
                FlSpot(3, 63),
                FlSpot(4, 72), 
                FlSpot(5, 60),
                FlSpot(6, 70),
              ],
              isCurved: false,
              color: Theme.of(context).primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRHRChartCard(String title, String info) {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.5)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title, 
                style: const TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 18,
                  color: Color(0xFF384242)
                )
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  // Qui potrai mostrare un dialogo o un messaggio con la stringa 'info'
                },
                icon: const Icon(Icons.info_outline),
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                color: Colors.grey,
              ),
            ],
          ),
          
          const Spacer(),
          Center(
            child: _buildRHRChart(50)
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(String title, double timeGoal, double timeDone) {
    bool isOverGoal = timeDone > timeGoal;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Padding bilanciato
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.5)),
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
                  startAngle: 270,
                  endAngle: 270,
                  radiusFactor: 1, 
                  axisLineStyle: const AxisLineStyle(
                    thickness: 0.2,
                    cornerStyle: CornerStyle.bothFlat,
                    thicknessUnit: GaugeSizeUnit.factor,
                  ), 
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
                  ],
                  pointers: <GaugePointer>[
                    RangePointer(
                      value: isOverGoal ? timeGoal : timeDone, // Si ferma al massimo
                      width: 0.2,
                      sizeUnit: GaugeSizeUnit.factor,
                      color: Theme.of(context).primaryColor,
                      cornerStyle: CornerStyle.bothFlat,
                      enableAnimation: true,
                      animationDuration: 500,
                      animationType: AnimationType.ease,
                    ),

                    if (isOverGoal) //Per fare l'overlapping stile Apple
                      RangePointer(
                        value: timeDone - timeGoal,
                        width: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                        cornerStyle: CornerStyle.bothCurve,
                        enableAnimation: true,
                        animationDuration: 4000,
                        gradient: SweepGradient(
                          colors: [
                            //Theme.of(context).colorScheme.primary.withOpacity(0.5), 
                            Theme.of(context).primaryColor,
                            Colors.purpleAccent
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                  ],
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
            onPressed: () {
              Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => BreathingSelectionPage()));
            },
          ),
        ],
      ),
    );
  }
}
