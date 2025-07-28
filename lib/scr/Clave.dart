import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:ruleta/services/ruleta_api_service.dart';
import 'package:ruleta/models/api_models.dart';
import 'package:ruleta/services/audio_manager.dart';
import 'package:audioplayers/audioplayers.dart';

class ClaveMentalQuiz extends StatefulWidget {
  const ClaveMentalQuiz({super.key});

  @override
  _ClaveMentalQuizState createState() => _ClaveMentalQuizState();
}

class _ClaveMentalQuizState extends State<ClaveMentalQuiz>
    with WidgetsBindingObserver, QuizAudioMixin {
  int _timeLeft = 25;
  Timer? _timer;
  String? _selectedOption;
  bool _isAnswered = false;
  bool _showCorrectAnswer = false;
  bool _isTimeUp = false;
  bool _showQuestionAndAnswers = true; // Solo oculta pregunta y respuestas

  Question? _currentQuestion;
  List<Map<String, String>> _options = [];
  bool _isLoadingQuestion = true;
  String? _errorMessage;
  String _correctAnswer = '';

  double get progress => _timeLeft / 25.0;
  int get timeLeft => _timeLeft;

  String _statusMessage = 'CLAVE\nMENTAL';
  Color _statusColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    print('🟠 WIDGET ABIERTO: ClaveMentalQuiz (Clave Mental) - initState ejecutado');
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _loadQuestionFromBackend();
  }

  @override
  void dispose() {
    _timer?.cancel();
    setWidgetInactive();
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _timer?.cancel();
      setWidgetInactive();
    } else if (state == AppLifecycleState.resumed && !_isAnswered && !_isTimeUp) {
      setWidgetActive();
      _startTimer();
    }
  }

  void _onCorrectAnswer() async {
    print('Clave: Respuesta correcta - AudioManager habilitado: ${AudioManager().isSoundEnabled}');
    // Usar el AudioManager que ya está configurado y respeta el estado global
    await AudioManager().playCorrectSound();
    setState(() {
      _statusMessage = 'CORRECTO';
      _statusColor = _getStatusColor(_statusMessage);
      _showCorrectAnswer = true;
    });
  }

  void _onIncorrectAnswer() async {
    print('Clave: Respuesta incorrecta - AudioManager habilitado: ${AudioManager().isSoundEnabled}');
    // Usar el AudioManager que ya está configurado y respeta el estado global
    await AudioManager().playIncorrectSound();
    setState(() {
      _statusMessage = 'INCORRECTO';
      _statusColor = const Color(0xFFE52330);
      _showCorrectAnswer = true;
    });
  }

  void _onTimeUp() {
    playTimeoutSound();
    setState(() {
      _statusMessage = 'TIEMPO AGOTADO';
      _statusColor = const Color(0xFFE52330);
      _showCorrectAnswer = true;
      _isTimeUp = true;
    });
  }

  Color _getStatusColor(String statusMessage) {
    switch (statusMessage) {
      case 'CORRECTO':
        return const Color(0xFF73B735);
      case 'INCORRECTO':
      case 'TIEMPO AGOTADO':
        return const Color(0xFFE52330);
      default:
        return Colors.black;
    }
  }

  Future<void> _loadQuestionFromBackend() async {
    try {
      setState(() {
        _isLoadingQuestion = true;
        _errorMessage = null;
        _isAnswered = false;
        _showCorrectAnswer = false;
        _isTimeUp = false;
        _selectedOption = null;
      });

      final categoryId = await RuletaApiService.getCategoryIdByName('Clave Mental');
      if (categoryId == null) {
        setState(() {
          _errorMessage = 'Categoría "Clave Mental" no encontrada';
          _isLoadingQuestion = false;
        });
        return;
      }

      final question = await RuletaApiService.getRandomQuestion(categoryId: categoryId);

      if (question != null) {
        setState(() {
          _currentQuestion = question;
          _options = question.options.asMap().entries.map((entry) {
            int index = entry.key;
            String option = entry.value;
            String letter = String.fromCharCode(65 + index);
            return {'value': letter, 'text': option};
          }).toList();
          _options.shuffle();
          // Buscar la opción correcta dentro de las opciones
          final correct = question.options.firstWhere(
            (opt) => opt.trim().toLowerCase() == question.explanation.trim().toLowerCase(),
            orElse: () => '',
          );
          _correctAnswer = correct.isNotEmpty ? correct : question.options.first;
          _isLoadingQuestion = false;
        });
        _startTimer();
      } else {
        setState(() {
          _errorMessage = 'No se pudo cargar la pregunta';
          _isLoadingQuestion = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al cargar pregunta: $e';
        _isLoadingQuestion = false;
      });
      print('Error cargando pregunta: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 25;
    _isTimeUp = false;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _timer?.cancel();
        setState(() {
          _isTimeUp = true;
          _isAnswered = true;
        });
        _onTimeUp();
        Future.delayed(const Duration(seconds: 8), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    });
  }

  void _selectOption(String option) {
    if (_isAnswered) return;

    setState(() {
      _selectedOption = option;
      _isAnswered = true;
      _showCorrectAnswer = true;
    });

    _timer?.cancel();

    final selectedText =
        _options.firstWhere((opt) => opt['value'] == option)['text']!;

    if (selectedText == _correctAnswer) {
      _onCorrectAnswer();
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context, 1);
        }
      });
    } else {
      _onIncorrectAnswer();
      Future.delayed(const Duration(seconds: 3), () async {
        if (mounted) {
          setState(() {
            _showQuestionAndAnswers = false; // Oculta solo pregunta y respuestas
          });
          
          // Solo reproducir sonido si está habilitado
          AudioPlayer? player;
          if (AudioManager().isSoundEnabled) {
            player = AudioPlayer();
            await player.play(AssetSource('sounds/sonidointentalootravez.mp3'));
          }
          
          // Capturamos contexto
          final quizContext = context;
          showDialog(
            context: quizContext,
            barrierDismissible: false,
            builder: (dialogContext) => IncorrectAnswerDialog(
              timeLeft: _timeLeft,
              progress: progress,
              onRetry: () async {
                await player?.stop();
                await player?.dispose();
                // cierra diálogo
                Navigator.of(dialogContext).pop();
                // regresa a ruleta
                Navigator.pop(quizContext, 0);
              },
            ),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoadingQuestion) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          Container(
            height: screenHeight * 0.13,
            width: double.infinity,
            color: const Color(0xFFF97C34),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'CLAVE MENTAL',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w900,
                    fontSize: 20.0,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        offset: Offset(2, 2),
                        blurRadius: 4,
                        color: Colors.black45,
                      ),
                    ],
                  ),
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: screenWidth * 0.075,
                      height: screenWidth * 0.075,
                      child: CustomPaint(
                        painter: TimerPainter(
                          progress: progress,
                          timeLeft: timeLeft,
                        ),
                      ),
                    ),
                    Text(
                      '$_timeLeft',
                      style: TextStyle(
                        fontSize: screenWidth * 0.030,
                        fontWeight: FontWeight.bold,
                        color: _timeLeft > 10 ? Colors.white : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/back-azul-salud-menatl.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.01),
                  if (_showQuestionAndAnswers) ...[
                    if (_isAnswered || _isTimeUp)
                      _buildAnsweredContainer(screenWidth)
                    else
                      _buildQuestionContainer(screenWidth),
                    SizedBox(height: screenHeight * 0.015),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: _options.length,
                                itemBuilder: (context, index) {
                                  final option = _options[index];
                                  return _buildOption(
                                    option['value']!,
                                    option['text']!,
                                    screenWidth,
                                    screenHeight,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnsweredContainer(double screenWidth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _statusMessage,
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: _getStatusColor(_statusMessage),
              fontWeight: FontWeight.w900,
              fontSize: screenWidth * 0.063,
            ),
          ),
          const SizedBox(height: 10),
          if (_currentQuestion != null)
            Text(
              _currentQuestion!.question,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF28367F),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionContainer(double screenWidth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: screenWidth * 0.15,
            height: screenWidth * 0.15,
            child: Image.asset(
              'assets/icons/icono-naranja.png',
              width: screenWidth * 0.08,
              height: screenWidth * 0.08,
            ),
          ),
          const SizedBox(height: 10),
          if (_currentQuestion != null)
            Text(
              _currentQuestion!.question,
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF28367F),
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildOption(String value, String text, double screenWidth, double screenHeight) {
    bool isSelected = _selectedOption == value;
    bool isCorrect = text.trim().toLowerCase() == _correctAnswer.trim().toLowerCase();
    bool showResult = _showCorrectAnswer || _isTimeUp;

    Color backgroundColor = Colors.white;
    Color textColor = Colors.black;
    Color borderColor = Colors.grey;

    if (showResult) {
      if (_isTimeUp) {
        backgroundColor = Colors.grey.shade300;
        textColor = Colors.grey.shade700;
        borderColor = Colors.grey.shade500;
      } else if (isCorrect) {
        backgroundColor = const Color(0xFF4CAF50);
        textColor = Colors.white;
        borderColor = const Color(0xFF388E3C);
      } else if (isSelected && !isCorrect) {
        backgroundColor = const Color(0xFFF44336);
        textColor = Colors.white;
        borderColor = const Color(0xFFD32F2F);
      } else {
        backgroundColor = Colors.white;
        textColor = Colors.black87;
        borderColor = Colors.grey.shade400;
      }
    } else {
      backgroundColor = Colors.white;
      textColor = Colors.black87;
      borderColor = Colors.grey.shade400;
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
      child: ElevatedButton(
        onPressed: (_isAnswered || _isTimeUp) ? null : () => _selectOption(value),
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: backgroundColor,
          disabledForegroundColor: textColor,
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.025,
            horizontal: screenWidth * 0.04,
          ),
          elevation: _isTimeUp ? 0 : 3,
          minimumSize: Size(double.infinity, screenHeight * 0.08),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Montserrat',
              color: showResult ? textColor : const Color(0xFF28367F),
              fontSize: screenWidth * 0.033,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// CustomPainter para el timer circular
class TimerPainter extends CustomPainter {
  final double progress;
  final int timeLeft;

  TimerPainter({required this.progress, required this.timeLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.18;

    final progressColor = timeLeft > 10 ? Colors.green : const Color(0xFFEA4335);

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final startAngle = -pi / 2;
    final sweepAngle = progress * 2 * pi;

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant TimerPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.timeLeft != timeLeft;
  }
}

// Dialog para respuesta incorrecta
class IncorrectAnswerDialog extends StatelessWidget {
  final int timeLeft;
  final double progress;
  final VoidCallback onRetry;

  const IncorrectAnswerDialog({
    super.key,
    required this.timeLeft,
    required this.progress,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double buttonWidth = screenWidth * 0.4;
    final double buttonHeight = screenHeight * 0.06;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/TITULO TRIVIA.png',
                  width: screenWidth * 0.60,
                  height: screenWidth * 0.14,
                  fit: BoxFit.contain,
                ),
                Image.asset(
                  'assets/animations/payaso-triste-2.gif',
                  width: screenWidth * 0.80,
                  height: screenWidth * 0.74,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: screenHeight * 0.02),
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176BAB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(buttonHeight / 2),
                      ),
                    ),
                    onPressed: onRetry,
                    child: Text(
                      'Inténtalo\nde nuevo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.01),
              ],
            ),
          ),
        ],
      ),
    );
  }
}