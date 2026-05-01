import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BreathingExercisePage extends StatefulWidget {
  const BreathingExercisePage({Key? key}) : super(key: key);

  @override
  State<BreathingExercisePage> createState() => _BreathingExercisePageState();
}

class _BreathingExercisePageState extends State<BreathingExercisePage> with TickerProviderStateMixin {
  
  // --- VARIABILI DA IMPORTARE (Inizializzate con valori di default) ---
  int totalTimeInSeconds = 14; // Timer totale (1 minuto)
  
  // Fasi della respirazione
  int inhaleTime = 5; // Secondi inspirazione
  int holdTime = 2;   // Secondi in cui si trattiene il respiro
  int exhaleTime = 5; // Secondi espirazione

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
  late Animation<double> _buttonShadowOpacity;
  late Animation<double> _buttonShadowSpread;

  @override
  void initState() {
    super.initState();

    int totalCycleTime = inhaleTime + holdTime + exhaleTime + holdTime;
    
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

    _buttonShadowOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.5), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 70),
    ]).animate(_heartbeatController);

    _buttonShadowSpread = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 15),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 70),
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
      setState(() {
        if (totalTimeInSeconds > 0) {
          totalTimeInSeconds--;
        } else {
          // IL TEMPO È SCADUTO!
          _timerFinished();
        }
      });
    });
  }

  void _timerFinished() {
    setState(() {
      _countdownTimer?.cancel();
      _preStartTimer?.cancel();
      
      _breathController.stop();
      _breathController.value = 0.0; 
      
      isPlaying = false;
      isCountingDown = false;
      _stopBtnController.reset();

      finalBpm = (initialBpm > 50) ? initialBpm - 5 : initialBpm;
    });

    _showCompletionDialog();
  }

  //POP-UP DI FINE ESERCIZIO
  void _showCompletionDialog() {
    int delta = initialBpm - finalBpm;
    // String deltaText = delta > 0 ? "$delta" : "$delta"; // CAPIRE I SEGNI
    String deltaText = "$delta";

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

                const SizedBox(height: 15),

                // DELTA
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Theme.of(context).colorScheme.primary, width: 4),
                  ),
                  child: Column(
                    children: [
                      const Text("Delta", style: TextStyle(fontSize: 15, color: Colors.black54)),
                      const SizedBox(height: 5),
                      Text(
                        "$deltaText BPM", 
                        style: TextStyle(
                          fontSize: 25, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.black
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // BOTTONE RITORNO ALLA HOME
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _resetExercise(); 
                      Navigator.of(context)..pop()..pop();
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
    setState(() {
      isPlaying = false;
      isCountingDown = false; 
      
      _countdownTimer?.cancel();
      _preStartTimer?.cancel(); 
      
      totalTimeInSeconds = 60; 
      
      _breathController.stop();
      _breathController.value = 0.0; 
    
      _stopBtnController.reset(); 
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
        int totalCycleTime = inhaleTime + holdTime + exhaleTime + holdTime;
        
        double inhaleLimit = inhaleTime / totalCycleTime;
        double hold1Limit = (inhaleTime + holdTime) / totalCycleTime;
        double exhaleLimit = (inhaleTime + holdTime + exhaleTime) / totalCycleTime;

        String actionText = "READY";
        double actionFontSize = 38.0; 

        if (isCountingDown) {
          actionText = "$preStartCountdown";
          actionFontSize = 45.0; // solo i numeri un po' più grandi
        } else if (isPlaying) {
          if (p < inhaleLimit) {
            actionText = "INHALE";
            actionFontSize = 35.0;
          } else if (p < hold1Limit) {
            actionText = "HOLD";
            actionFontSize = 35.0;
          } else if (p < exhaleLimit) {
            actionText = "EXHALE";
            actionFontSize = 35.0;
          } else {
            actionText = "HOLD";
            actionFontSize = 35.0;
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
                  holdTime: holdTime,
                  exhaleTime: exhaleTime,
                  inhaleColor: const Color(0xFF4DD0E1).withOpacity(0.4), 
                  holdColor: const Color(0xFF7986CB).withOpacity(0.4),   
                  exhaleColor: const Color(0xFFBA68C8).withOpacity(0.4), 
                ),
              ),

              Text(
                actionText,
                style: TextStyle(
                  color: Colors.black, 
                  fontSize: actionFontSize, 
                  fontWeight: FontWeight.w500,
                  letterSpacing: isCountingDown ? 0 : 3, 
                ),
              ),
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
            border: Border.all(color: Colors.black, width: 2.5), 
            boxShadow: [
              BoxShadow(
                color: Colors.redAccent.withOpacity(_buttonShadowOpacity.value),
                blurRadius: 4,
                spreadRadius: _buttonShadowSpread.value,
              )
            ],
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
  final int holdTime;
  final int exhaleTime;
  
  final Color inhaleColor;
  final Color holdColor;
  final Color exhaleColor;

  _BreathingTrackPainter({
    required this.progress,
    required this.inhaleTime,
    required this.holdTime,
    required this.exhaleTime,
    required this.inhaleColor,
    required this.holdColor,
    required this.exhaleColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    int totalTime = inhaleTime + holdTime + exhaleTime + holdTime;
    
    double inhaleAngle = (inhaleTime / totalTime) * 2 * pi;
    double holdAngle = (holdTime / totalTime) * 2 * pi;
    double exhaleAngle = (exhaleTime / totalTime) * 2 * pi;

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
    canvas.drawArc(rect, startAngle, holdAngle, false, trackPaint);
    startAngle += holdAngle;

    // Exhale
    trackPaint.color = exhaleColor;
    canvas.drawArc(rect, startAngle, exhaleAngle, false, trackPaint);
    startAngle += exhaleAngle;

    // Hold 2
    trackPaint.color = holdColor;
    canvas.drawArc(rect, startAngle, holdAngle, false, trackPaint);

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