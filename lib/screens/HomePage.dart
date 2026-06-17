import 'package:ZeroStress/providers/health_data_provider.dart';
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
  int _todayBreathingMinutes = 0;
  final _scrollController = ScrollController();

  // inizializza homepage richiedendo i dati al server impact e popolando i widget
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final health = Provider.of<HealthDataProvider>(context, listen: false);
      await health.fetchAllData();
      final minutes = await health.getTodayBreathingMinutes();
      if (!mounted) return;
      setState(() => _todayBreathingMinutes = minutes);
      _showErrorIfAny(health);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // funzione per refreshare i dati quando richiesto
  Future<void> _onRefresh() async {
    final health = Provider.of<HealthDataProvider>(context, listen: false);
    _scrollController.jumpTo(0); //Fa si che quando scrolli per refreshare non scenda 
    await health.fetchAllData();
    final minutes = await health.getTodayBreathingMinutes();
    if (!mounted) return;
    setState(() => _todayBreathingMinutes = minutes);
    _showErrorIfAny(health);
  }

  // controlla se qualcosa è andato storto durante il caricamento dei dati
  void _showErrorIfAny(HealthDataProvider health) {
    if (health.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(health.errorMessage!),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _onRefresh,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    return Scaffold(
      extendBodyBehindAppBar: true, //Serve perchè AppBar tiene sfondo solido
      // Build AppBar
      appBar: _buildAppBar(context),

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
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: Colors.white,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Consumer<HealthDataProvider>(
                      builder: (context, health, _) {
                        return Column(
                          children: [
                            // STREAK & RECAP BOX
                            _buildStreakBox(health),
                            const SizedBox(height: 20),

                            // TODAY STRESS & RECOVERY (Due box affiancati)
                            Row(
                              children: [
                                Expanded(child: _buildSmallStatCardIncreasingValue("Today Stress", health.stressLevel)), // ("Today Stress",health.stressLevel)
                                const SizedBox(width: 15),
                                Expanded(child: _buildSmallStatCardDecreasingValue("Recovery", 80))
                              ],
                            ),

                            const SizedBox(height: 10),

                            // GRAFICO RHR
                            _buildRHRChartCard("Resting HR Trend", health),
                            const SizedBox(height: 10),

                            _buildDailyGoalCard("Daily Goal", userProvider.time.toDouble(), _todayBreathingMinutes.toDouble())
                          ]
                        );
                      }
                    ),
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
    if (hourNow >= 5 && hourNow < 13) {
      return 'Morning';
    }
    else if (hourNow >= 13 && hourNow <= 18) {
      return 'Afternoon';
    }
    else if (hourNow > 18 && hourNow <= 22) {
      return 'Evening';
    }
    else {
      return 'Night';
    }
  }

  //Deve essere PreferredSizeWidget perchè AppBar è già implementata ma facciamo così per miglior lettura codice
  PreferredSizeWidget _buildAppBar(BuildContext context) {
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

  Widget _buildStreakBox(HealthDataProvider health) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final todayIndex = DateTime.now().weekday - 1; // 0=Mon, 6=Sun
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_fire_department,
                  color: Colors.orangeAccent, size: 28),
              const SizedBox(width: 8),
              Text(
                "${health.currentStreak} Day Streak",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (i) {
              final done = i < health.last7DaysCompleted.length
                  ? health.last7DaysCompleted[i]
                  : false;
              final isToday = i == todayIndex;
              return Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done
                          ? Colors.orangeAccent
                          : Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: done
                            ? Colors.orangeAccent
                            : isToday
                                ? Colors.orangeAccent
                                : Colors.white38,
                        width: isToday && !done ? 3 : 2,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        done ? Icons.check : Icons.circle,
                        color: done ? Colors.white : Colors.white38,
                        size: done ? 16 : 6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(days[i],
                    style: const TextStyle(color: Colors.white70, fontSize: 11)
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  //IncreasingValue perchè serve per creare Stress level, per cui il colore 'peggiora' al crescere
  Widget _buildSmallStatCardIncreasingValue(String title, double valPerc) {
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
          Text(
            title, 
            style: const TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 14,
              color: Color(0xFF384242)
            )
          ),
              
          const SizedBox(height: 5),

          Center(
            child: SizedBox(
                height: 110,
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
          ),

          //const SizedBox(height: 5),

          Center(
            child: Text(txtVal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorTxt.withOpacity(0.8)))
          ),   
        ]
      )
    );
  }

  //DecreasingValue perchè serve per creare Recovery level, per cui il colore 'migliora' al crescere
  Widget _buildSmallStatCardDecreasingValue(String title, double valPerc) {
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
          Text(
            title, 
            style: const TextStyle(
              fontWeight: FontWeight.w600, 
              fontSize: 14,
              color: Color(0xFF384242)
            )
          ),
              
          const SizedBox(height: 5),

          Center(
            child: SizedBox(
                height: 110,
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
          ),

          Center(
            child: Text(txtVal, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorTxt.withOpacity(0.8)))
          ),  
        ]
      )
    );
  }

  Widget _buildRHRChartCard(String title, HealthDataProvider health) {
    return Container(
      width: double.infinity,
      height: 200,
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
          Text(
            title, 
            style: const TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 18,
              color: Color(0xFF384242)
            )
          ),
          
          const Spacer(),
          Center(
            child: _buildRHRChart(health.weeklyRHR, health.baselineRHR)
          ),
        ],
      ),
    );
  }

  Widget _buildRHRChart(List<double?> weeklyRHR, double baseline) {
    final double threshold = baseline * 1.2;

    // Build day labels: index 0 = yesterday-6, index 6 = yesterday
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dayLabels = List.generate(7, (i) {
      final d = yesterday.subtract(Duration(days: 6 - i));
      const abbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return abbr[d.weekday - 1];
    });

    final allSpots = <FlSpot>[];
    final validSpots = <FlSpot>[];
    for (int i = 0; i < 7; i++) {
      if (weeklyRHR[i] != null) {
        final spot = FlSpot(i.toDouble(), weeklyRHR[i]!);
        allSpots.add(spot);
        validSpots.add(spot);
      } else {
        allSpots.add(FlSpot(i.toDouble(), double.nan));
      }
    }

    if (validSpots.isEmpty) {
      return const SizedBox(
        height: 130,
        child: Center(
          child: Text("No data available",
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    final allValues = validSpots.map((s) => s.y).toList()..add(threshold);
    final minY =
        (allValues.reduce((a, b) => a < b ? a : b) - 10).roundToDouble();
    final maxY =
        (allValues.reduce((a, b) => a > b ? a : b) + 10).roundToDouble();

    return SizedBox(
      height: 130,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (spot) =>
                  Theme.of(context).primaryColor.withOpacity(0.8),
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toInt()} BPM',
                        const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ))
                  .toList(),
            ),
            handleBuiltInTouches: true,
          ),
          extraLinesData: ExtraLinesData(horizontalLines: [
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
                    fontSize: 10),
                labelResolver: (_) => 'RHR +20%',
              ),
            ),
          ]),
          gridData: const FlGridData(
            show: true,
            drawHorizontalLine: false,
            drawVerticalLine: false,
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < dayLabels.length) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(dayLabels[idx],
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 10)),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 10, 
                reservedSize: 30,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 6,
          minY: minY,
          maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: allSpots,
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
                  maximum: timeGoal > 0 ? timeGoal : 1,
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
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
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
                  MaterialPageRoute(builder: (context) => BreathingSelectionPage()),
              ).then((_) => _onRefresh()); //This triggers the refresh whenever we go back to homepage after breathing section
            },
          ),
        ],
      ),
    );
  }
}
