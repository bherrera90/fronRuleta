import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ruleta/scr/RuletaGame.dart';
import 'dart:io';
// import 'package:ruleta/scr/final.dart';
import 'package:ruleta/services/ruleta_api_service.dart';
import 'package:ruleta/models/api_models.dart';
import 'package:ruleta/widget_loader.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Forzar la inclusión de todos los widgets en release
  WidgetLoader.forceIncludeAllWidgets();

  // Configurar orientación
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  print('🚀 Inicializando detección automática de backend...');
  await RuletaApiService.initialize();

  // Precargar categorías de la API
  print('📡 Precargando categorías de la API...');
  final categories = await RuletaApiService.getCategories();
  print('✅ Categorías precargadas: ${categories.length}');

  // Generar usuario aleatorio al iniciar la aplicación
  await _generarUsuarioAleatorio();

  runApp(MentalHealthApp(preloadedCategories: categories));
}

// Función para generar usuario aleatorio
Future<void> _generarUsuarioAleatorio() async {
  try {
    // Generar un ID de usuario aleatorio
    final random = Random();
    final userId = random.nextInt(1000000); // ID entre 0 y 999999
    
    print('🎲 Usuario aleatorio generado: $userId');
    
    // Aquí puedes agregar lógica adicional para configurar el usuario
    // Por ejemplo, guardar en SharedPreferences o enviar al backend
    
  } catch (e) {
    print('❌ Error generando usuario aleatorio: $e');
  }
}

class MentalHealthApp extends StatelessWidget {
  final List<RuletaCategory> preloadedCategories;
  
  const MentalHealthApp({
    super.key,
    required this.preloadedCategories,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ruleta de la Salud Mental',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: MentalHealthWheel(preloadedCategories: preloadedCategories),
    );
  }
}

class MentalHealthWheel extends StatefulWidget {
  final List<RuletaCategory> preloadedCategories;
  
  const MentalHealthWheel({
    super.key,
    required this.preloadedCategories,
  });

  @override
  State<MentalHealthWheel> createState() => _MentalHealthWheelState();
}

class _MentalHealthWheelState extends State<MentalHealthWheel> with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<int> _ordenCategorias = [];
  int _progresoActual = 0;
  final bool _showContent = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _generarOrdenAleatorio();
    // No generar usuario aleatorio automáticamente aquí
  }

  void _generarOrdenAleatorio() {
    List<String> items = [
      'Mente Sana',
      'Curiosamente',
      'Mitos Desmentidos',
      'Q+VE',
      'Clave Mental',
    ];
    _ordenCategorias = List.generate(items.length, (i) => i)..shuffle();
    _progresoActual = 0;
  }

  // Función para generar usuario aleatorio en el widget
  void _generarUsuarioAleatorioEnWidget() {
    try {
      final random = Random();
      final userId = random.nextInt(1000000);
      print('🎲 Usuario aleatorio generado en widget: $userId');
      
      // Aquí puedes agregar lógica adicional para el usuario en el contexto del widget
      
    } catch (e) {
      print('❌ Error generando usuario aleatorio en widget: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _audioPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      _audioPlayer.resume();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Obtener dimensiones de la pantalla usando MediaQuery
    final Size screenSize = MediaQuery.of(context).size;
    final double screenHeight = screenSize.height;
    final double screenWidth = screenSize.width;
    
    // Obtener padding del sistema para SafeArea
    final EdgeInsets padding = MediaQuery.of(context).padding;
    final double topPadding = padding.top;
    final double bottomPadding = padding.bottom;

    // Cálculos responsivos usando MediaQuery
    final double titleHeight = screenHeight * 0.15;
    final double gifHeight = screenHeight * 0.5;
    final double buttonWidth = screenWidth * 0.6;
    final double buttonHeight = screenHeight * 0.065;
    
    // Tamaños responsivos para iconos y elementos
    final double iconSize = screenWidth * 0.08;
    final double titleWidth = screenWidth * 0.7;
    final double gifWidth = screenWidth * 0.9;

    
    // Espaciados responsivos
    final double topSpacing = screenHeight * 0.06;
    final double titleSpacing = screenHeight * 0.02;
    final double textSpacing = screenHeight * 0.03;
    final double buttonSpacing = screenHeight * 0.03;
    final double bottomSpacing = screenHeight * 0.02;
    final double horizontalPadding = screenWidth * 0.1;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo
          Positioned.fill(
            child: Image.asset(
              'assets/images/CUADRO.jpg',
              fit: BoxFit.cover,
            ),
          ),


          // Botón X para cerrar la app
          Positioned(
            top: titleSpacing,
            right: screenWidth * 0.04,
            child: SafeArea(
              child: IconButton(
                icon: Image.asset(
                  'assets/images/boton x.png',
                  width: iconSize,
                  height: iconSize,
                ),
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else {
                    exit(0);
                  }
                },
                tooltip: 'Cerrar aplicación',
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: topSpacing),

                // Imagen título
                SizedBox(
                  height: titleHeight,
                  width: titleWidth,
                  child: Image.asset(
                    'assets/images/textoRuleta.png',
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(height: titleSpacing),

                Text(
                  'Pon a prueba tu mente\nen cada pregunta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    fontSize: min(screenWidth * 0.048, 20.0),
                    height: 1.2,
                  ),
                ),
                SizedBox(height: textSpacing),
                // GIF central
                Expanded(
                  child: _showContent
                      ? Center(
                          child: SizedBox(
                            height: gifHeight,
                            width: gifWidth,
                            child: Image.asset(
                              'assets/animations/MALABARES.gif',
                              fit: BoxFit.contain,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Botón "Comenzar"
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: buttonSpacing,
                  ),
                  child: SizedBox(
                    width: buttonWidth,
                    height: buttonHeight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(buttonHeight / 2),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        // Generar usuario aleatorio solo cuando se navega desde main.dart
                        _generarUsuarioAleatorioEnWidget();
                        
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => RouletteScreen(preloadedCategories: widget.preloadedCategories),
                          ),
                        );
                      },
                        child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                        'Comenzar',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          fontSize: min(screenWidth * 0.05, 22.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: bottomSpacing),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

