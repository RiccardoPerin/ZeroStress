import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'BreathingSelectionPage.dart';
import 'package:provider/provider.dart';
import 'package:ZeroStress/providers/user_provider.dart';
import 'package:ZeroStress/providers/health_data_provider.dart';

class BreathingExercisePage extends StatefulWidget {
  final BreathingTechnique technique;
  final int totalTimeInSeconds;

  const BreathingExercisePage({
    Key? key,
    required this.technique,
    required this.totalTimeInSeconds,
  }) : super(key: key);

  @override
  State<BreathingExercisePage> createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<BreathingExercisePage> with TickerProviderStateMixin {
  
  // --- VARIABILI DA IMPORTARE (Inizializzate con valori di default) ---
  int totalTimeInSeconds = 13; // Timer totale (1 minuto)
  
  // Fasi della respirazione
  int inhaleTime = 5;  // Secondi inspirazione
  int hold1Time = 2;   // Secondi in cui si trattiene il respiro (prima volta)
  int exhaleTime = 5;  // Secondi espirazione
  int hold2Time = 1;   // Secondi in cui si trattiene il respiro (seconda volta)

  // --- STATO DELLA PAGINA ---
  bool isPlaying = false;
  bool isCountingDown = false; 
  int preStartCountdown = 3;   
  
  Timer? _countdownTimer;
  Timer? _preStartTimer;       

  // Variabili per il battito cardiaco
  int currentBpm = 62; 
  int initialBpm = 0; // Salvato all'inizio dell'esercizio
  int finalBpm = 0;   // Calcolato alla fine dell'esercizio

  // --- CONTROLLER ANIMAZIONI ---
  late AnimationController _breathController;
  late AnimationController _stopBtnController;
  late AnimationController _heartbeatController; 

  // --- SEQUENZE DI ANIMAZIONE (Cuore e Ombra) ---
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();

    //Legge le fasi dalla technique scelta
    final p = widget.technique.phases;
    inhaleTime = p.isNotEmpty ? p[0] : 4;
    hold1Time = p.length > 1 ? p[1] : 0;
    exhaleTime = p.length > 2 ? p[2] : 4;
    hold2Time = p.length > 3 ? p[3] : 0;
    totalTimeInSeconds = widget.totalTimeInSeconds;

    final totalCycleTime = inhaleTime + hold1Time + exhaleTime + hold2Time;
    
    _breathController = AnimationController(
      vsync: this,
      duration: Duration(seconds: totalCycleTime),
    );

    _stopBtnController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _stopBtnController.addListener(() => setState(() {}));
    _stopBtnController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          Navigator.pop(context);
        }
      }
    });

    _heartbeatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(); 

    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 70), 
    ]).animate(_heartbeatController);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _preStartTimer?.cancel(); 
    _breathController.dispose();
    _stopBtnController.dispose();
    _heartbeatController.dispose();
    super.dispose();
  }

  // --- LOGICA DEL TIMER E PULSANTI ---

  void _togglePlayPause() {
    setState(() {
      if (isCountingDown) {
        // Pausa durante il conto alla rovescia
        _preStartTimer?.cancel();
        isCountingDown = false;
        isPlaying = false;
      } else if (isPlaying) {
        // Pausa durante l'esercizio
        isPlaying = false;
        _countdownTimer?.cancel();
        _breathController.stop(); 
      } else {
        // Pressione di START
        isCountingDown = true;
        preStartCountdown = 3;
        initialBpm = currentBpm; 
        
        _preStartTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            if (preStartCountdown > 1) {
              preStartCountdown--; 
            } else {
              _preStartTimer?.cancel();
              isCountingDown = false;
              isPlaying = true;
              
              _startTimer();
              _breathController.repeat(); 
            }
          });
        });
      }
    });
  }

  void _startTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (totalTimeInSeconds > 1) {
        setState(() => totalTimeInSeconds--);
      } else {
        setState(() => totalTimeInSeconds = 0);
        _timerFinished();
      }
    });
  }

  Future<void> _timerFinished() async {
    _countdownTimer?.cancel();
    _preStartTimer?.cancel();
    setState(() {
      _breathController.stop();
      _breathController.value = 0.0;
      isPlaying = false;
      isCountingDown = false;
      _stopBtnController.reset();
      finalBpm = (initialBpm > 50) ? initialBpm - 5 : initialBpm;
    });

    final minutesCompleted = widget.totalTimeInSeconds ~/ 60;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final healthProvider = Provider.of<HealthDataProvider>(context, listen: false);

    await healthProvider.addBreathingMinutes(minutesCompleted, userProvider.time);

    _showCompletionDialog();
  }

  //POP-UP DI FINE ESERCIZIO
  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20), 
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adatta l'altezza al contenuto, evitando spazi vuoti
              children: [
                // RIGA INTESTAZIONE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded, 
                      color: Colors.green, 
                      size: 35 // Icona più piccola
                    ),
                    
                    const Text(
                      "EXERCISE COMPLETED",
                      style: TextStyle(
                        fontSize: 22, 
                        fontWeight: FontWeight.bold, 
                        letterSpacing: 1.0
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 25),

                // FRASE A EFFETTO
                const Text(
                  "Mind cleared, body relaxed",
                  style: TextStyle(
                    fontSize: 18, 
                    color: Colors.black45,
                    fontStyle: FontStyle.italic
                  ),
                  textAlign: TextAlign.center,
                ),
                
                
                const SizedBox(height: 25),

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text("Initial", style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 5),
                            Text("$initialBpm", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text("Final", style: TextStyle(fontSize: 12, color: Colors.black54)),
                            const SizedBox(height: 5),
                            Text("$finalBpm", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),
                
                // BOTTONE RITORNO ALLA HOME
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _resetExercise(); 
                      Navigator.of(context).popUntil((route) => route.isFirst); //Goes back to HomePage 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: const Text(
                      "BACK TO HOME", 
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)
                    ),
                  ),
                )
              ],
            ),
          ),
        );
      }
    );
  }

  void _resetExercise() {
    _countdownTimer?.cancel();
    _preStartTimer?.cancel();
    _breathController.stop();
    _breathController.value = 0.0;
    _stopBtnController.reset();
    setState(() {
      isPlaying = false;
      isCountingDown = false;
      totalTimeInSeconds = widget.totalTimeInSeconds;
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // --- WIDGET BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, 
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTimer(),

            const SizedBox(height: 50),
            
            _buildBreathingTrack(),
            
            const SizedBox(height: 70),

            _buildControls(),

            const SizedBox(height: 50),

            _buildBpmIndicator(),
          ],
        ),
      ),
    );
  }

  // --- WIDGET MINIFUNCTIONS ---

  Widget _buildTimer() {
    return Text(
      _formatTime(totalTimeInSeconds),
      style: TextStyle(
        fontSize: 60,
        fontWeight: FontWeight.w200,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildBreathingTrack() {
    return AnimatedBuilder(
      animation: _breathController,
      builder: (context, child) {
        
        double p = _breathController.value;
        int totalCycleTime = inhaleTime + hold1Time + exhaleTime + hold2Time;
        
        double inhaleLimit = inhaleTime / totalCycleTime;
        double hold1Limit = (inhaleTime + hold1Time) / totalCycleTime;
        double exhaleLimit = (inhaleTime + hold1Time + exhaleTime) / totalCycleTime;

        String actionText = "READY";
        double actionFontSize = 38.0; 

        // per inserire i secondi nel cerchio
        double elapsedSeconds = p * totalCycleTime;
        int secondsLeft = 0;

        if (isCountingDown) {
          actionText = "$preStartCountdown";
          actionFontSize = 45.0; // solo i numeri un po' più grandi
        } else if (isPlaying) {
          if (p < inhaleLimit) {
            actionText = "INHALE";
            actionFontSize = 35.0;
            secondsLeft = (inhaleTime - elapsedSeconds).ceil();
          } else if (p < hold1Limit) {
            actionText = "HOLD";
            actionFontSize = 35.0;
            secondsLeft = ((inhaleTime + hold1Time) - elapsedSeconds).ceil();
          } else if (p < exhaleLimit) {
            actionText = "EXHALE";
            actionFontSize = 35.0;
            secondsLeft = ((inhaleTime + hold1Time + exhaleTime) - elapsedSeconds).ceil();
          } else {
            actionText = "HOLD";
            actionFontSize = 35.0;
            secondsLeft = ((inhaleTime + hold1Time + exhaleTime + hold2Time) - elapsedSeconds).ceil();
          }
        }

        return SizedBox(
          width: 270,
          height: 270,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: const Size(270, 270),
                painter: _BreathingTrackPainter(
                  progress: p,
                  inhaleTime: inhaleTime,
                  hold1Time: hold1Time,
                  exhaleTime: exhaleTime,
                  hold2Time: hold2Time,
                  inhaleColor: const Color(0xFF4DD0E1).withOpacity(0.4), 
                  holdColor: const Color(0xFF7986CB).withOpacity(0.4),   
                  exhaleColor: const Color(0xFFBA68C8).withOpacity(0.4), 
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 3),

                  Text(
                    actionText,
                    style: TextStyle(
                      color: Colors.black, 
                      fontSize: actionFontSize, 
                      fontWeight: FontWeight.w500,
                      letterSpacing: isCountingDown ? 0 : 3, 
                    ),
                  ),

                  // SOLO se stiamo facendo l'esercizio (e non nel 3..2..1)
                  if (isPlaying && !isCountingDown)
                    Text(
                      "$secondsLeft",
                      style: const TextStyle(
                        color: Colors.black, 
                        fontSize: 28, 
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                ]
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    bool showPauseIcon = isPlaying || isCountingDown;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: _togglePlayPause,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            elevation: 0,
          ),
          child: Row(
            children: [
              Icon(showPauseIcon ? Icons.pause_rounded : Icons.play_arrow_rounded),
              const SizedBox(width: 10),
              Text(
                showPauseIcon ? "PAUSE" : "START",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ]
          ),
        ),

        const SizedBox(width: 30),

        _buildAnimatedStopButton(),
      ],
    );
  }

  Widget _buildAnimatedStopButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque, 
      onTapDown: (_) => _stopBtnController.forward(),
      onTapUp: (_) {
        if (_stopBtnController.status != AnimationStatus.completed) {
          _stopBtnController.reverse();
        }
      },
      onTapCancel: () => _stopBtnController.reverse(),
      
      child: AnimatedBuilder(
        animation: _stopBtnController,
        builder: (context, child) {
          return CustomPaint(
            foregroundPainter: _PillProgressPainter(_stopBtnController.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1), 
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.transparent, 
                  width: 2
                ), 
              ),
              child: const Row(
                children: [
                  Icon(Icons.stop_rounded, color: Colors.redAccent),
                  SizedBox(width: 10),
                  Text(
                    "STOP",
                    style: TextStyle(
                      color: Colors.redAccent, 
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      letterSpacing: 1.5
                    ),
                  ),
                ]
              ),
            )
          );
        },
      ),
    );
  }

  Widget _buildBpmIndicator() {
    return AnimatedBuilder(
      animation: _heartbeatController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5), 
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.black, width: 1.5), 
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: _heartScale.value,
                child: const Icon(Icons.favorite, color: Colors.redAccent, size: 28),
              ),
              const SizedBox(width: 15),
              Text(
                "$currentBpm BPM",
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- CLASSI CUSTOM PAINTER ---

class _BreathingTrackPainter extends CustomPainter {
  final double progress;
  final int inhaleTime;
  final int hold1Time;
  final int exhaleTime;
  final int hold2Time;
  
  final Color inhaleColor;
  final Color holdColor;
  final Color exhaleColor;

  _BreathingTrackPainter({
    required this.progress,
    required this.inhaleTime,
    required this.hold1Time,
    required this.exhaleTime,
    required this.hold2Time,
    required this.inhaleColor,
    required this.holdColor,
    required this.exhaleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int totalTime = inhaleTime + hold1Time + exhaleTime + hold2Time;
    
    double inhaleAngle = (inhaleTime / totalTime) * 2 * pi;
    double hold1Angle = (hold1Time / totalTime) * 2 * pi;
    double exhaleAngle = (exhaleTime / totalTime) * 2 * pi;
    double hold2Angle = (hold2Time / totalTime) * 2 * pi;

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = size.width / 2 - 12; 
    Rect rect = Rect.fromCircle(center: center, radius: radius);

    Paint trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24.0 
      ..strokeCap = StrokeCap.butt; 

    double startAngle = -pi / 2;

    // Inhale
    trackPaint.color = inhaleColor;
    canvas.drawArc(rect, startAngle, inhaleAngle, false, trackPaint);
    startAngle += inhaleAngle;

    // Hold 1
    trackPaint.color = holdColor;
    canvas.drawArc(rect, startAngle, hold1Angle, false, trackPaint);
    startAngle += hold1Angle;

    // Exhale
    trackPaint.color = exhaleColor;
    canvas.drawArc(rect, startAngle, exhaleAngle, false, trackPaint);
    startAngle += exhaleAngle;

    // Hold 2
    trackPaint.color = holdColor;
    canvas.drawArc(rect, startAngle, hold2Angle, false, trackPaint);

    // Pallina
    double currentAngle = -pi / 2 + (progress * 2 * pi);
    
    double ballX = center.dx + radius * cos(currentAngle);
    double ballY = center.dy + radius * sin(currentAngle);
    Offset ballPos = Offset(ballX, ballY);

    Paint ballShadow = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    canvas.drawCircle(ballPos, 12, ballShadow);

    Paint ballPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(ballPos, 12, ballPaint);
  }

  @override
  bool shouldRepaint(covariant _BreathingTrackPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PillProgressPainter extends CustomPainter {
  final double progress;

  _PillProgressPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0.0) return; 

    final paint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double radius = 30.0; 

    final path = Path()
      ..moveTo(size.width / 2, 0) 
      ..lineTo(size.width - radius, 0) 
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius), clockwise: true) 
      ..lineTo(size.width, size.height - radius) 
      ..arcToPoint(Offset(size.width - radius, size.height), radius: Radius.circular(radius), clockwise: true) 
      ..lineTo(radius, size.height) 
      ..arcToPoint(Offset(0, size.height - radius), radius: Radius.circular(radius), clockwise: true) 
      ..lineTo(0, radius) 
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius), clockwise: true) 
      ..close(); 

    final pathMetrics = path.computeMetrics();
    final extractPath = Path();

    for (final metric in pathMetrics) {
      final segment = metric.extractPath(0.0, metric.length * progress);
      extractPath.addPath(segment, Offset.zero);
    }

    canvas.drawPath(extractPath, paint);
  }

  @override
  bool shouldRepaint(covariant _PillProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}