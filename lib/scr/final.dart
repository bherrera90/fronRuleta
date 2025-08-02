import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruleta/scr/RuletaGame.dart';

class PantallaFinJuego extends StatefulWidget {
  final String mensajeFinal;
  final String rutaImagen;
  final String? textoSecundario;

  const PantallaFinJuego({
    super.key,
    this.mensajeFinal = '¡Ganaste!',
    this.rutaImagen = 'assets/animations/copa-con-confetti.gif',
    this.textoSecundario,
  });

  @override
  State<PantallaFinJuego> createState() => _PantallaFinJuegoState();
}

class _PantallaFinJuegoState extends State<PantallaFinJuego> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    // Configurar modo de pantalla para evitar notificaciones
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _startTrophyAnimation();
  }

  void _startTrophyAnimation() async {
    // Repetir la animación solo los primeros 3 segundos (parte del confeti)
    for (int i = 0; i < 3; i++) {
      if (!mounted) return; // Verificar si el widget aún está montado
      await _animationController.forward();
      if (!mounted) return;
      await _animationController.reverse();
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 300)); // Más lento para simular confeti
    }
    // Mantener la animación en su posición final (copa estática)
    if (mounted) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.stop();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final imagenSize = screenWidth * 0.75;
    final String textoSecundario = widget.textoSecundario ?? '+5 puntos, por tu gran\ndesempeño.';
    print('LOG: Mostrando mensaje secundario en PantallaFinJuego: $textoSecundario');

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back-azul-salud-menatl.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Stack(
                    children: [
              // Contenedor blanco
              Container(
                margin: EdgeInsets.only(
                  top: imagenSize * 0.85, // Aumentado para bajar más el contenedor
                  left: screenWidth * 0.08,
                  right: screenWidth * 0.08,
                  bottom: screenHeight * 0.02,
                ),
                constraints: BoxConstraints(
                  maxHeight: screenHeight * 0.5, // Limita la altura máxima al 50% de la pantalla
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: imagenSize * 0.25, // Espacio para el trofeo
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.mensajeFinal,
                          style: TextStyle(
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E5BBA),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        Text(
                          textoSecundario,
                          style: TextStyle(
                            fontSize: screenWidth * 0.04,
                            color: const Color(0xFF5DADE2),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: screenHeight * 0.03),
                        SizedBox(
                          width: screenWidth * 0.6,
                          height: screenHeight * 0.055,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF176BAB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5,
                            ),
                            onPressed: () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) =>  RuletaGameApp()),
                                (route) => false,
                              );
                            },
                            child: Text(
                              'Volver a jugar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.015),
                        SizedBox(
                          width: screenWidth * 0.6,
                          height: screenHeight * 0.055,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF176BAB),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 5,
                            ),
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                            child: Text(
                              'Volver al inicio',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.04,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Trofeo animado superpuesto
              Positioned(
                top: imagenSize * 0.1, // Bajado el trofeo aún más
                left: 0,
                right: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: SizedBox(
                          width: imagenSize,
                          height: imagenSize,
                          child: Image.asset(
                            widget.rutaImagen,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}