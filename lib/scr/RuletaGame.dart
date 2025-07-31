import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:ruleta/main.dart';
import 'package:ruleta/scr/Curiosamente.dart';
import 'package:ruleta/scr/Desmintiendo.dart';
import 'package:ruleta/scr/Qmas.dart';
import 'package:ruleta/scr/Clave.dart';
import 'dart:async';

import 'package:ruleta/scr/QuestionTest.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ruleta/scr/final.dart';
import 'package:ruleta/services/ruleta_api_service.dart';
import 'package:ruleta/models/api_models.dart';
import 'package:ruleta/services/audio_manager.dart';
import 'package:ruleta/widget_loader.dart';

class RuletaGameApp extends StatelessWidget {
  const RuletaGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ruleta de Salud Mental',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RouletteScreen(),
    );
  }
}

class RouletteItem {
  final String label;
  final String iconAsset;

  RouletteItem({required this.label, required this.iconAsset});
}

class RouletteScreen extends StatefulWidget {
  final List<RuletaCategory>? preloadedCategories;
  
  const RouletteScreen({
    super.key,
    this.preloadedCategories,
  });

  @override
  State<RouletteScreen> createState() => _RouletteScreenState();
}

class _RouletteScreenState extends State<RouletteScreen>
  with TickerProviderStateMixin, WidgetsBindingObserver { 
  late AnimationController _controller;
  late Animation<double> _animation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _spinAudioPlayer = AudioPlayer(); // Nuevo: para el sonido de la ruleta
  bool _isSoundOn = true;
  Timer? _autoSpinTimer;
  Timer? _redirectionTimer;
  bool _isSpinButtonEnabled = true;

  final Set<String> _categoriasJugadas = {};
  int _puntos = 0;
  
  // Variables para rastrear el usuario y determinar el mensaje final
  int? _usuarioActual;
  bool _esMismoUsuario = false;

  // Variables para el índice objetivo (solución de sincronización)
  int? _targetCategoryIndex;
  String? _targetCategoryLabel;

  // Variables de estado para el orden aleatorio y el progreso
  List<int> _ordenCategorias = [];
  int _progresoActual = 0;

  // Datos dinámicos de la API
  List<RuletaCategory> _categories = [];
  List<RouletteItem> _items = [];
  bool _isLoadingData = true;
  String? _errorMessage;
  final Map<String, ui.Image> _loadedImages = {};

  double _currentRotationAngle = 0;
  bool _isSpinning = false;
  int? _highlightedIndex;
  String? _selectedOption;
  // Variable para almacenar la categoría seleccionada directamente desde _spin()
  String? _preSelectedOption;
  int? _preSelectedIndex;
  // Variables para efecto de luminosidad parpadeante
  bool _isBlinking = false;
  double _blinkIntensity = 0.0;
  Timer? _blinkTimer;
  final bool _blinkIncreasing = true;
  bool _showDarkOverlay = true; // Controla la visibilidad de la capa oscura
  // Variable _shouldStop eliminada (no se usaba)

  List<RouletteItem> get _opcionesDisponibles =>
      _items.where((item) => !_categoriasJugadas.contains(item.label)).toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // <-- Se agrega observer del ciclo de vida
    
    // Configurar modo de pantalla para evitar notificaciones
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Sincronizar el estado del sonido con el AudioManager
    _isSoundOn = AudioManager().isSoundEnabled;
    print('RuletaGame: Estado inicial del sonido - _isSoundOn: $_isSoundOn, AudioManager: ${AudioManager().isSoundEnabled}');
    
    // Verificar que el estado esté correctamente sincronizado
    if (!_isSoundOn) {
      print('⚠️ ADVERTENCIA: El sonido está desactivado al iniciar RuletaGame');
    }
    
    _playSound(); // Reproduce el sonido al iniciar (solo si está activado)
    _generarUsuarioActual(); // Generar usuario actual
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );

    _animation = Tween<double>(begin: 0, end: 0).animate(_controller)
      ..addListener(() => setState(() {
            if (_isSpinning) {
              _highlightedIndex = _getSelectedIndex(_animation.value);
            }
          }))
      ..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          final finalAngle = _animation.value;
          final finalIndex = _targetCategoryIndex;
          final labelBajoSelector = finalIndex != null ? _items[finalIndex].label : 'null';
          
          // Verificar que el progreso actual sea válido
          if (_progresoActual < _ordenCategorias.length) {
            final objetivo = _ordenCategorias[_progresoActual];
            
            setState(() {
              _highlightedIndex = objetivo;
              _selectedOption = _items[objetivo].label;
              _isSpinning = false;
              _isSpinButtonEnabled = true; // Asegurar que el botón se habilite
            });
            _startBlinkingEffect();
          } else {
            // Si no hay más categorías disponibles, habilitar el botón
            setState(() {
              _isSpinning = false;
              _isSpinButtonEnabled = true;
              _highlightedIndex = null;
              _selectedOption = null;
            });
          }

          // Reproducir sonido de selección de categoría SOLO si el sonido está activado
          if (_isSoundOn) {
            final player = AudioPlayer();
            await player.play(AssetSource('sounds/Sonidocuandoseescogecategoria.mp3'));
          }

              _redirectionTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        print('TIMER EJECUTADO: Llamando a _navigateToSelected()');
        _navigateToSelected();
      } else {
        print('TIMER EJECUTADO: Widget no está montado, no navegando');
      }
    });
        }
      });

    // Cargar datos de la API o usar categorías precargadas
    if (widget.preloadedCategories != null && widget.preloadedCategories!.isNotEmpty) {
      print('✅ Usando categorías precargadas: ${widget.preloadedCategories!.length}');
      _loadDataFromPreloadedCategories();
    } else {
      print('📡 Cargando categorías desde la API...');
      _loadDataFromApi();
    }
  }

  // --- Manejo del ciclo de vida para pausar/reanudar audio ---
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // Pausa el audio cuando la app va a segundo plano
      _audioPlayer.pause();
      _spinAudioPlayer.pause();
    } else if (state == AppLifecycleState.resumed) {
      // Reanuda el audio SOLO si el sonido está activado
      if (_isSoundOn) {
        _audioPlayer.resume();
        // No reanudar _spinAudioPlayer automáticamente
      }
      // Asegurar que el modo de pantalla se mantenga al regresar
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  /// Cargar datos dinámicamente desde la API
  Future<void> _loadDataFromApi() async {
    try {
      setState(() {
        _isLoadingData = true;
        _errorMessage = null;
      });

      // Obtener categorías de la API
      final categories = await RuletaApiService.getCategories();
      
      // Debug: Imprimir información sobre las categorías recibidas
      print('🔍 DEBUG: Categorías recibidas de la API: ${categories.length}');
      for (var cat in categories) {
        print('  - ID: ${cat.id}, Nombre: "${cat.name}", LocalName: "${cat.localName}"');
      }
      
      // Si la API devuelve vacío, usa las categorías por defecto
      // Mapa fijo de iconos por categoría
      final iconMap = {
        'Mente Sana': 'assets/icons/ICONO MENTE SANA w53 h54.png',
        'Curiosa Mente': 'assets/icons/ICONO CURIOSAMENT.png',
        'Curiosamente': 'assets/icons/ICONO CURIOSAMENT.png',
        'Curiosamente Mental': 'assets/icons/ICONO CURIOSAMENT.png',
        'Q+VE': 'assets/icons/ICONO Q+VE.png',
        'Q+ve': 'assets/icons/ICONO Q+VE.png',
        'Clave Mental': 'assets/icons/ICONO CLAVE MENTAL.png',
        'Mitos Desmentidos': 'assets/icons/Iconos mitos.png',
      };

      final items = (categories.isEmpty)
          ? [
              RouletteItem(label: 'Mente Sana', iconAsset: iconMap['Mente Sana']!),
              RouletteItem(label: 'Curiosa Mente', iconAsset: iconMap['Curiosa Mente']!),
              RouletteItem(label: 'Q+VE', iconAsset: iconMap['Q+VE']!),
              RouletteItem(label: 'Clave Mental', iconAsset: iconMap['Clave Mental']!),
              RouletteItem(label: 'Mitos Desmentidos', iconAsset: iconMap['Mitos Desmentidos']!),
            ]
          : categories.map((category) => RouletteItem(
              label: category.localName,
              iconAsset: iconMap[category.localName] ?? category.iconAsset,
            )).toList();

      // Usar categorías de la API si están disponibles, sino usar las por defecto
      if (categories.isEmpty) {
        print('ℹ️ INFO: Usando categorías por defecto (comportamiento normal)');
      } else {
        print('✅ ÉXITO: Usando ${categories.length} categorías de la API');
      }

      // Print para depuración
      for (var item in items) {
        print('CATEGORÍA USADA: ${item.label}');
      }

      setState(() {
        _categories = categories;
        _items = items;
        _isLoadingData = false;
      });
      _generarOrdenAleatorio();

      // Precargar iconos y esperar a que estén listos antes de pintar
      await _preloadImages(_items);
      setState(() {});

      // Iniciar el timer de auto-spin solo después de cargar los datos
      _startAutoSpinTimer();
      
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = 'Error al cargar datos: $e';
        // Usar datos por defecto en caso de error
        _items = [
          RouletteItem(label: 'Mente Sana', iconAsset: 'assets/icons/ICONO MENTE SANA w53 h54.png'),
          RouletteItem(label: 'Curiosa Mente', iconAsset: 'assets/icons/ICONO CURIOSAMENT.png'),
          RouletteItem(label: 'Q+VE', iconAsset: 'assets/icons/ICONO Q+VE.png'),
          RouletteItem(label: 'Clave Mental', iconAsset: 'assets/icons/ICONO CLAVE MENTAL.png'),
          RouletteItem(label: 'Mitos Desmentidos', iconAsset: 'assets/icons/Iconos mitos.png'),
        ];
      });
      

      _startAutoSpinTimer();
      print('Error cargando datos de la API: $e');
    }
  }

  /// Cargar datos desde categorías precargadas
  Future<void> _loadDataFromPreloadedCategories() async {
    try {
      setState(() {
        _isLoadingData = true;
        _errorMessage = null;
      });

      // Mapa fijo de iconos por categoría
      final iconMap = {
        'Mente Sana': 'assets/icons/ICONO MENTE SANA w53 h54.png',
        'Curiosa Mente': 'assets/icons/ICONO CURIOSAMENT.png',
        'Curiosamente': 'assets/icons/ICONO CURIOSAMENT.png',
        'Curiosamente Mental': 'assets/icons/ICONO CURIOSAMENT.png',
        'Q+VE': 'assets/icons/ICONO Q+VE.png',
        'Q+ve': 'assets/icons/ICONO Q+VE.png',
        'Clave Mental': 'assets/icons/ICONO CLAVE MENTAL.png',
        'Mitos Desmentidos': 'assets/icons/Iconos mitos.png',
      };

      final items = widget.preloadedCategories!.map((category) => RouletteItem(
        label: category.localName,
        iconAsset: iconMap[category.localName] ?? category.iconAsset,
      )).toList();

      // Print para depuración
      for (var item in items) {
        print('CATEGORÍA PRECARGADA: ${item.label}');
      }

      setState(() {
        _categories = widget.preloadedCategories!;
        _items = items;
        _isLoadingData = false;
      });
      _generarOrdenAleatorio();

      // Precargar iconos y esperar a que estén listos antes de pintar
      await _preloadImages(_items);
      setState(() {});

      // Iniciar el timer de auto-spin solo después de cargar los datos
      _startAutoSpinTimer();
      
    } catch (e) {
      setState(() {
        _isLoadingData = false;
        _errorMessage = 'Error al cargar categorías precargadas: $e';
        // Usar datos por defecto en caso de error
        _items = [
          RouletteItem(label: 'Mente Sana', iconAsset: 'assets/icons/ICONO MENTE SANA w53 h54.png'),
          RouletteItem(label: 'Curiosa Mente', iconAsset: 'assets/icons/ICONO CURIOSAMENT.png'),
          RouletteItem(label: 'Q+VE', iconAsset: 'assets/icons/ICONO Q+VE.png'),
          RouletteItem(label: 'Clave Mental', iconAsset: 'assets/icons/ICONO CLAVE MENTAL.png'),
          RouletteItem(label: 'Mitos Desmentidos', iconAsset: 'assets/icons/Iconos mitos.png'),
        ];
      });
      
      _startAutoSpinTimer();
      print('Error cargando categorías precargadas: $e');
    }
  }

  // Función para reproducir sonido de fondo
  void _playSound() async {
    if (_isSoundOn) {
      try {
        // Configura el modo de bucle ANTES de reproducir
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        // Corregir la ruta del archivo de sonido
        await _audioPlayer.play(AssetSource('sounds/sonidofondo.mp3'));
        print('Sonido iniciado correctamente');
      } catch (e) {
        print('Error al reproducir el sonido: $e');
        // Intentar con una ruta alternativa si falla
        try {
          await _audioPlayer.play(AssetSource('sounds/sonidofondo.mp3'));
          print('Sonido iniciado con ruta alternativa');
        } catch (e2) {
          print('Error con ruta alternativa: $e2');
        }
      }
    }
  }

  // Función para alternar el sonido on/off
  void _toggleSound() {
    setState(() {
      _isSoundOn = !_isSoundOn;
      
      // Actualizar el estado global del AudioManager
      AudioManager().setSoundEnabled(_isSoundOn);
      print('RuletaGame: Sonido cambiado - _isSoundOn: $_isSoundOn, AudioManager: ${AudioManager().isSoundEnabled}');
      
      if (_isSoundOn) {
        _audioPlayer.resume(); // Reanuda donde se quedó
      } else {
        // Detener TODOS los reproductores de audio cuando se desactiva el sonido
        _audioPlayer.pause();
        _spinAudioPlayer.stop();
      }
    });
  }

  int _getSelectedIndex(double angle) {
    final sectorAngle = 360 / _items.length;
    double normalized = (angle % 360 + 360) % 360;
    return (_items.length - (normalized ~/ sectorAngle) - 1) % _items.length;
  }

  void _startAutoSpinTimer() {
    _autoSpinTimer?.cancel();
    _autoSpinTimer = Timer(const Duration(minutes: 1), () {
      if (!mounted) return;
      if (!_isSpinning) {
        _spin(randomSpin: true);
      }
    });
  }
  
  // Inicia el efecto de luminosidad parpadeante
  void _startBlinkingEffect() {
    _stopBlinkingEffect();
    setState(() {
      _isBlinking = true;
      _blinkIntensity = 1.0; // Empieza encendido
    });

    _blinkTimer = Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _blinkIntensity = _blinkIntensity == 1.0 ? 0.0 : 1.0; // ON/OFF rápido
      });
    });
  }
  
  // Detiene el efecto de luminosidad parpadeante
  void _stopBlinkingEffect() {
    _blinkTimer?.cancel();
    _blinkTimer = null;
    
    if (mounted) {
      setState(() {
        _isBlinking = false;
        _blinkIntensity = 0.0;
      });
    }
  }

  Future<void> _loadImage(String asset) async {
    final ByteData data = await rootBundle.load(asset);
    final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final ui.FrameInfo frame = await codec.getNextFrame();
    setState(() {
      _loadedImages[asset] = frame.image;
    });
  }

  // Pre-carga todos los iconos y espera a que estén listos
  Future<void> _preloadImages(List<RouletteItem> items) async {
    final futures = items.map((item) async {
      final ByteData data = await rootBundle.load(item.iconAsset);
      final ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final ui.FrameInfo frame = await codec.getNextFrame();
      _loadedImages[item.iconAsset] = frame.image;
    });
    await Future.wait(futures);
  }

  // 2. Al cargar las categorías (después de cargar _items), genera el orden aleatorio
  //    solo con las categorías que no han sido respondidas correctamente
  void _generarOrdenAleatorio({bool mantenerProgreso = false}) {
    // Si no hay que mantener el progreso, reiniciar categorías jugadas
    if (!mantenerProgreso) {
      _categoriasJugadas.clear();
    }
    
    // Crear lista de índices de categorías que NO han sido respondidas correctamente
    final categoriasDisponibles = <int>[];
    for (int i = 0; i < _items.length; i++) {
      if (!_categoriasJugadas.contains(_items[i].label)) {
        categoriasDisponibles.add(i);
      }
    }
    
    // Si no hay categorías disponibles, reiniciar todo
    if (categoriasDisponibles.isEmpty) {
      _categoriasJugadas.clear();
      _progresoActual = 0;
      _puntos = 0;
      _generarOrdenAleatorio(mantenerProgreso: false);
      return;
    }
    
    // Mezclar las categorías disponibles
    categoriasDisponibles.shuffle();
    _ordenCategorias = categoriasDisponibles;
    
    // Si mantenemos el progreso, no reiniciamos _progresoActual
    if (!mantenerProgreso) {
      _progresoActual = 0;
    }
    
    // Log para depuración
    print('NUEVO ORDEN ALEATORIO (${_ordenCategorias.length} categorías):');
    for (final idx in _ordenCategorias) {
      final estado = _categoriasJugadas.contains(_items[idx].label) ? '[COMPLETADA]' : '[PENDIENTE]';
      print('  $idx: ${_items[idx].label} $estado');
    }
  }

  // Función para generar usuario aleatorio al regresar desde RuletaGame
  void _generarUsuarioAleatorioAlRegresar() {
    try {
      final random = Random();
      final userId = random.nextInt(1000000);
      print('🎲 Usuario aleatorio generado al regresar desde RuletaGame: $userId');
      
      // Marcar que ya no es el mismo usuario
      _esMismoUsuario = false;
      print('🔄 Usuario cambiado: _esMismoUsuario = $_esMismoUsuario');
      
    } catch (e) {
      print('❌ Error generando usuario aleatorio al regresar: $e');
    }
  }

  // Función para generar y establecer el usuario actual
  void _generarUsuarioActual() {
    try {
      final random = Random();
      _usuarioActual = random.nextInt(1000000);
      print('🎲 Usuario actual establecido en RuletaGame: $_usuarioActual');
      
      // Verificar si es el mismo usuario que inició en main.dart
      // Por ahora asumimos que es el mismo si no se ha regenerado
      _esMismoUsuario = true;
      
    } catch (e) {
      print('❌ Error generando usuario actual: $e');
    }
  }

  // Elimina cualquier llamada a setState o a _generarOrdenAleatorio() que esté fuera de métodos.
  // Asegúrate de que solo haya una función _generarOrdenAleatorio().

  // 3. En _spin(), usa el índice de _ordenCategorias[_progresoActual] como objetivo
  void _spin({bool randomSpin = true}) {
    if (!mounted) return;
    
    // Verificar si hay categorías disponibles para girar
    final categoriasDisponibles = _items.where((item) => !_categoriasJugadas.contains(item.label)).toList();
    if (categoriasDisponibles.isEmpty) {
      print('No hay categorías disponibles para girar');
      return;
    }
    
    // Si el progreso actual es mayor o igual al número de categorías, reiniciar el progreso
    if (_progresoActual >= _ordenCategorias.length) {
      print('⚠️ Progreso actual ($_progresoActual) excede el número de categorías (${_ordenCategorias.length}). Reiniciando progreso...');
      _progresoActual = 0;
      
      // Verificar si hay categorías disponibles para jugar
      final categoriasPendientes = _items.where((item) => !_categoriasJugadas.contains(item.label)).toList();
      if (categoriasPendientes.isEmpty) {
        print('⚠️ No hay categorías pendientes para jugar');
        return;
      }
      
      // Si hay categorías pendientes pero no en el orden actual, regenerar el orden
      _generarOrdenAleatorio(mantenerProgreso: true);
      print('🔄 Orden regenerado. Nuevo progreso: $_progresoActual, Categorías en orden: ${_ordenCategorias.map((i) => _items[i].label).toList()}');
    }
    
    if (_isSpinning) {
      print('⚠️ Ya hay un giro en progreso');
      return;
    }
    
    _autoSpinTimer?.cancel();
    print('Iniciando giro con _progresoActual=$_progresoActual, categorías restantes: ${categoriasDisponibles.length}');
    setState(() {
      _isSpinButtonEnabled = false;
      _isSpinning = true;
      _highlightedIndex = null;
      _showDarkOverlay = false; // Ocultar la capa oscura al girar
      _stopBlinkingEffect();
    });
    // --- SONIDO DE GIRO ---
    if (_isSoundOn) {
      _audioPlayer.pause(); // Pausa el fondo
      _spinAudioPlayer.stop(); // Por si acaso
      _spinAudioPlayer.play(AssetSource('sounds/Ruletaenmovimiento02.mp3'));
      // Detener el sonido de la ruleta después de 5 segundos y reanudar fondo
      Future.delayed(const Duration(seconds: 5), () async {
        await _spinAudioPlayer.stop();
        if (_isSoundOn) {
          _audioPlayer.resume();
        }
      });
    }
    // El índice objetivo es el siguiente en el orden aleatorio
    final targetIndex = _ordenCategorias[_progresoActual];
    _targetCategoryIndex = targetIndex;
    _targetCategoryLabel = _items[targetIndex].label;
    // Calcula el ángulo para que ese sector quede bajo el selector (arriba)
    final sectorAngle = 360.0 / _items.length;
    final baseRotation = 360.0 * (10 + Random().nextInt(3));
    final centerAngleOfSector = (targetIndex * sectorAngle) + (sectorAngle / 2);
    // El ángulo final debe poner el sector objetivo en 0 grados (arriba)
    final targetAngle = _currentRotationAngle + baseRotation + (360 - centerAngleOfSector) - (_currentRotationAngle % 360);
    //print('SPIN DEBUG: targetIndex=$targetIndex, label=${_items[targetIndex].label}, centerAngleOfSector=$centerAngleOfSector, targetAngle=$targetAngle');

    bool finalHighlightSet = false;
    _animation = Tween<double>(
      begin: _currentRotationAngle,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addListener(() => setState(() {
        if (_isSpinning) {
          double progress = _controller.value;
          if (progress < 0.9) {
            finalHighlightSet = false;
            final categoriasDisponibles = <int>[];
            for (int i = 0; i < _items.length; i++) {
              if (!_categoriasJugadas.contains(_items[i].label)) {
                categoriasDisponibles.add(i);
              }
            }
            if (categoriasDisponibles.isNotEmpty) {
              int visualIndex = (progress * categoriasDisponibles.length * 8).floor() % categoriasDisponibles.length;
              _highlightedIndex = categoriasDisponibles[visualIndex];
            } else {
              _highlightedIndex = _getSelectedIndex(_animation.value);
            }
          } else {
            if (!finalHighlightSet && _targetCategoryIndex != null) {
              _highlightedIndex = _targetCategoryIndex!;
              finalHighlightSet = true;
              print('OBJETIVO FINAL: índice $_targetCategoryIndex = "${_items[_targetCategoryIndex!].label}"');
            }
          }
        }
      }));
    _currentRotationAngle = targetAngle % 360;
    _controller.duration = const Duration(seconds: 5);
    _controller.reset();
    _controller.forward();
  }



  void _navigateToSelected() async {
    print('=== INICIO _navigateToSelected ===');
    print('_selectedOption: $_selectedOption');
    if (_selectedOption == null) {
      print('ERROR: _selectedOption es null, no navegando');
      return;
    }

    // DEBUG: Mostrar información de depuración
    print('=== DEBUG NAVEGACIÓN ===');
    print('Categoría seleccionada: "$_selectedOption"');
    print('_highlightedIndex actual: $_highlightedIndex');
    print('Categoría en _highlightedIndex: ${_highlightedIndex != null ? _items[_highlightedIndex!].label : "null"}');
    print('_preSelectedIndex: $_preSelectedIndex');
    print('_preSelectedOption: $_preSelectedOption');
    print('Categorías jugadas: $_categoriasJugadas');
    print('Contiene categoría: ${_categoriasJugadas.contains(_selectedOption!)}');
    
    // VERIFICACIÓN ADICIONAL: Si la categoría ya fue jugada, no permitir acceso
    if (_categoriasJugadas.contains(_selectedOption!)) {
      print('BLOQUEO ACTIVADO: Categoría $_selectedOption ya fue jugada. Bloqueando acceso.');
      setState(() {
        _isSpinButtonEnabled = true;
        _selectedOption = null;
        _highlightedIndex = null;
      });
      // Mostrar un mensaje visual al usuario
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Esta categoría ya fue completada, vuelve a girar'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
  
    setState(() {
      _isSpinButtonEnabled = false;
    });
    _redirectionTimer?.cancel();
    _redirectionTimer = Timer(const Duration(seconds: 2), () {
      print('=== TIMER EJECUTADO - Creando destino ===');
      Widget destination;
      print('SWITCH DEBUG: Evaluando switch con _selectedOption: "$_selectedOption"');
      print('SWITCH DEBUG: Tipo de _selectedOption: ${_selectedOption.runtimeType}');
      print('SWITCH DEBUG: Longitud de _selectedOption: ${_selectedOption?.length}');
      print('SWITCH DEBUG: Códigos ASCII de _selectedOption: ${_selectedOption?.codeUnits}');
      print('SWITCH DEBUG: _selectedOption == "Curiosamente Mental": ${_selectedOption == "Curiosamente Mental"}');
      print('SWITCH DEBUG: _selectedOption == "Curiosamente": ${_selectedOption == "Curiosamente"}');
      
      try {
        print('FACTORY DEBUG: Intentando crear widget para: "$_selectedOption"');
        
        // Verificar si la categoría es soportada
        if (WidgetLoader.isCategorySupported(_selectedOption!)) {
          print('WIDGET_LOADER DEBUG: Categoría soportada, creando widget...');
          destination = WidgetLoader.createWidget(_selectedOption!);
          print('WIDGET_LOADER DEBUG: Widget creado exitosamente: ${destination.runtimeType}');
        } else {
          print('WIDGET_LOADER DEBUG: Categoría no soportada: "$_selectedOption"');
          print('WIDGET_LOADER DEBUG: Categorías soportadas: ${WidgetLoader.getAvailableCategories()}');
          destination = Scaffold(
            appBar: AppBar(title: const Text('Categoría no encontrada')),
            body: Center(child: Text('No se encontró pantalla para: $_selectedOption')),
          );
        }
      } catch (e) {
        print('ERROR en factory: $e');
        print('ERROR en factory: Stack trace: ${StackTrace.current}');
        destination = Scaffold(
          appBar: AppBar(title: const Text('Error')),
          body: Center(child: Text('Error al crear destino: $e')),
        );
      }
      print('NAVEGACIÓN FINAL: Navegando a quiz de categoría: $_selectedOption');
      print('NAVEGACIÓN FINAL: Widget destino: ${destination.runtimeType}');
    
    // Detener el audio antes de navegar a otra pantalla
    _audioPlayer.pause();

    print('=== EJECUTANDO Navigator.push ===');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => destination),
    ).then((resultado) {
      print('=== NAVEGACIÓN COMPLETADA - resultado: $resultado ===');
      
      // Asegurar que el modo de pantalla se mantenga al regresar del quiz
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      
      if (mounted) {
        setState(() {
          bool juegoCompletado = false;
          
          if (resultado == 1 && _selectedOption != null) {
            // Respuesta correcta
            _categoriasJugadas.add(_selectedOption!);
            _puntos++;
            _progresoActual++;
            
            // Verificar si todas las categorías han sido completadas correctamente
            if (_categoriasJugadas.length >= _items.length) {
              juegoCompletado = true;
              print('✅ Todas las categorías completadas correctamente');
            } else if (_progresoActual >= _ordenCategorias.length) {
              // Si se completó el orden actual pero aún hay categorías por responder
              print('🔄 Generando nuevo orden con las categorías restantes');
              _generarOrdenAleatorio(mantenerProgreso: true);
              print('Nuevo orden generado con ${_ordenCategorias.length} categorías restantes');
            }
          } else if (resultado == 0) {
            // Respuesta incorrecta - Generar nuevo orden aleatorio
            print('❌ Respuesta incorrecta, generando nuevo orden');
            
            // No incrementar el progreso en respuestas incorrectas
            // Solo generar un nuevo orden con las categorías pendientes
            final _ = _ordenCategorias.length; // Solo para referencia de depuración
            _generarOrdenAleatorio(mantenerProgreso: true);
            
            print('🔀 Nuevo orden aleatorio generado después de respuesta incorrecta');
            print('Se mantienen las ${_categoriasJugadas.length} categorías ya completadas');
            print('Categorías en el nuevo orden (${_ordenCategorias.length}): ${_ordenCategorias.map((i) => _items[i].label).toList()}');
            
            // Si el progreso era mayor que el número de categorías, reiniciarlo
            if (_progresoActual >= _ordenCategorias.length) {
              _progresoActual = 0;
              print('🔄 Progreso reiniciado a 0 porque excedía el número de categorías');
            }
          }
          
// Asegurarse de que el botón de girar esté habilitado
          _isSpinButtonEnabled = true;
          _selectedOption = null;
          _highlightedIndex = null;
          _showDarkOverlay = true; // Asegurar que la capa oscura sea visible
          
          // Verificar si hay categorías disponibles para girar
          final categoriasDisponibles = _items.where((item) => !_categoriasJugadas.contains(item.label)).toList();
          if (categoriasDisponibles.isEmpty) {
            print('⚠️ No hay más categorías disponibles para jugar');
            juegoCompletado = true;
          } else {
            print('🔄 Categorías disponibles para el próximo giro: ${categoriasDisponibles.map((e) => e.label).toList()}');
          }
          
          // Si el juego está completado, navegar a la pantalla final
          if (juegoCompletado) {
            // Determinar el mensaje según los puntos y el usuario
            String mensajeFinal;
            String textoSecundario;
            
            if (_puntos >= 5 && _esMismoUsuario) {
              mensajeFinal = '¡Gracias por participar!';
              textoSecundario = '+5 puntos, por tu gran\ndesempeño.';
              print('🎯 Usuario con 5 puntos y mismo usuario: Mostrando mensaje de éxito');
            } else {
              mensajeFinal = '¡Gracias por participar!';
              textoSecundario = 'Cada vez está más cerca\nde conocer sobre tu salud mental';
              print('📈 Usuario sin 5 puntos o usuario diferente: Mostrando mensaje de motivación');
            }
            
            // Usar un post-frame callback para asegurar que el setState se complete
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => PantallaFinJuego(
                  mensajeFinal: mensajeFinal,
                  rutaImagen: 'assets/animations/copa-con-confetti.gif',
                  textoSecundario: textoSecundario,
                )),
              );
            });
          }
        });
        
        // Reanudar el audio cuando regrese de la pantalla de quiz
        if (_isSoundOn) {
          _audioPlayer.resume();
        }
      }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // <-- Elimina el observer
    _redirectionTimer?.cancel();
    _autoSpinTimer?.cancel();
    _blinkTimer?.cancel();
    _controller.dispose();
    // Detener TODOS los reproductores de audio
    _audioPlayer.stop();
    _audioPlayer.dispose();
    _spinAudioPlayer.stop();
    _spinAudioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Asegurar que el modo de pantalla se mantenga en cada build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    });
    
    // Obtener dimensiones de la pantalla usando MediaQuery
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;
    
    // Obtener padding del sistema para SafeArea
    final EdgeInsets padding = MediaQuery.of(context).padding;
    final double topPadding = padding.top;
    final double bottomPadding = padding.bottom;
    
    // Cálculos responsivos usando MediaQuery
    final double titleHeight = screenHeight * 0.15;
    final double rouletteSize = screenWidth < screenHeight * 0.5
        ? screenWidth * 0.85
        : screenHeight * 0.55;
    final double buttonSize = screenWidth * 0.08;
    final double titleWidth = screenWidth * 0.65;
    final double fontSize = screenWidth * 0.045;
    final double buttonFontSize = rouletteSize * 0.050;
    
    // Espaciados responsivos
    final double topSpacing = screenHeight * 0.02;
    final double horizontalSpacing = screenWidth * 0.04;
    final double titleSpacing = screenHeight * 0.02;
    final double textSpacing = screenHeight * 0.03;
    final double smallSpacing = 8.0;
    
    // Variables para la lógica (sin cambios)
    final totalCategorias = _items.length;
    final categoriasRestantes = totalCategorias - _categoriasJugadas.length;

    // --- Corregido: Stack ocupa toda la pantalla sin espacios ---
    return Scaffold(
      body: Stack(
        children: [
          // Fondo de pantalla (cubre toda la pantalla)
          Positioned.fill(
            child: Image.asset(
              'assets/images/CUADRO.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Botón atrás y sonido arriba
          Positioned(
            top: topSpacing,
            left: horizontalSpacing,
            child: SafeArea(
              child: IconButton(
                icon: Image.asset(
                  'assets/images/Boton atrás.png',
                  width: buttonSize,
                  height: buttonSize,
                ),
                onPressed: () {
                  // Generar usuario aleatorio al regresar desde RuletaGame
                  _generarUsuarioAleatorioAlRegresar();
                  
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const MentalHealthApp(preloadedCategories: [])),
                    (route) => false, // Elimina todas las rutas anteriores
                  );
                },
              ),
            ),
          ),
          
          // Botón de sonido
          Positioned(
            top: topSpacing,
            right: horizontalSpacing,
            child: SafeArea(
              child: IconButton(
                icon: Image.asset(
                  _isSoundOn
                      ? 'assets/images/Botón Musica.png'
                      : 'assets/images/Botón Musica Mute.png',
                  width: buttonSize,
                  height: buttonSize,
                ),
                onPressed: _toggleSound,
              ),
            ),
          ),
          // Bloque ruleta centrado verticalmente
          Column(
            children: [
              const Spacer(flex: 2),
              // Imagen título
              SizedBox(
                height: titleHeight,
                width: titleWidth,
                child: Image.asset(
                  'assets/images/textoRuleta.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: smallSpacing),
              // Ruleta centrada
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


              Center(
                child: SizedBox(
                  height: rouletteSize,
                  width: rouletteSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Ruleta
                      Transform.rotate(
                        angle: _animation.value * pi / 180,
                        child: CustomPaint(
                          size: Size(rouletteSize, rouletteSize),
                          painter: WheelPainter(
                            items: _items,
                            highlightedIndex: _highlightedIndex,
                            loadedImages: _loadedImages,
                            categoriasJugadas: _categoriasJugadas,
                            isBlinking: _isBlinking,
                            blinkIntensity: _blinkIntensity,
                          ),
                        ),
                      ),
                      // Capa oscura que se oculta al presionar el botón
                      if (_showDarkOverlay)
                        Container(
                          width: rouletteSize,
                          height: rouletteSize,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      // Botón central con la imagen de girar
                      Positioned(
                        left: (rouletteSize - rouletteSize * 0.3) / 2,
                        top: (rouletteSize - rouletteSize * 0.3) / 2,
                        child: GestureDetector(
                          onTap: _isSpinButtonEnabled ? _spin : null,
                          child: Container(
                            width: rouletteSize * 0.3,
                            height: rouletteSize * 0.3,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Imagen de fondo del botón
                                Image.asset(
                                  'assets/icons/Btn-parar-sintexto 02.png',
                                  width: rouletteSize * 0.3,
                                  height: rouletteSize * 0.3,
                                  fit: BoxFit.contain,
                                  color: _isSpinButtonEnabled ? null : Colors.grey[400],
                                ),
                                // Texto GIRAR centrado
                                Center(
                                  child: Text(
                                    'GIRAR',
                                    style: TextStyle(
                                      fontSize: rouletteSize * 0.05,
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black,
                                      letterSpacing: 1.5,
                                     
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ],
      ),
    ); // <-- Cierre correcto de Scaffold
  }
  
}

class WheelPainter extends CustomPainter {
  final List<RouletteItem> items;
  final int? highlightedIndex;
  final Map<String, ui.Image> loadedImages;
  final Set<String> categoriasJugadas;
  final bool isBlinking;
  final double blinkIntensity;

  WheelPainter({
    required this.items,
    this.highlightedIndex,
    required this.loadedImages,
    required this.categoriasJugadas,
    this.isBlinking = false,
    this.blinkIntensity = 0.0,
  });

  final List<Color> customColors = [
    Color(0xFF176BAB), // Azul - Mente Sana
    Color(0xFF6BA72D), // Verde - Curiosa Mente
    Color(0xFFE8C136), // Amarillo - Q+VE
    Color(0xFFF97C34), // Naranja - Clave Mental
    Color(0xFF784BAA), // Morado - Mitos Desmentidos
  ];

  // Función para formatear el texto según las especificaciones
  String _getFormattedText(String label) {
    switch (label) {
      case 'Mente Sana':
        return 'MENTE\nSANA';
      case 'Curiosamente': // Nombre correcto de la API
        return 'CURIOSAMENTE';
      case 'Curiosamente Mental': // Agregado para mostrar CURIOSAMENTE
        return 'CURIOSAMENTE';
      case 'Q+ve': // Nombre correcto de la API (minúscula)
        return 'Q+VE';
      case 'Q+VE': // Nombre correcto de la API
        return 'Q+VE';
      case 'Clave Mental':
        return 'CLAVE\nMENTAL';
      case 'Mitos Desmentidos':
        return 'MITOS\nDESMENTIDOS';
      default:
        return label.toUpperCase();
    }
  }

  // Función para obtener el color específico por nombre de categoría
  Color _getColorForCategory(String label) {
    switch (label) {
      case 'Mente Sana':
        return Color(0xFF176BAB); // Azul
      case 'Curiosamente':
      case 'Curiosamente Mental':
        return Color(0xFF6BA72D); // Verde
      case 'Q+ve':
      case 'Q+VE':
      case 'Q+Ve':
      case 'Q+vE':
        return Color(0xFFE8C136); // Amarillo
      case 'Clave Mental':
        return Color(0xFFF97C34); // Naranja
      case 'Mitos Desmentidos':
        return Color(0xFF784BAA); // Morado
      default:
        return Color(0xFF176BAB); // Azul por defecto
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sectorAngle = 2 * pi / items.length;
    final paint = Paint()..style = PaintingStyle.fill;

    // Dibuja un borde blanco general para toda la ruleta
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0;
      
    // Dibujar el borde blanco de la ruleta
    canvas.drawCircle(center, radius, borderPaint);

    for (int i = 0; i < items.length; i++) {
      // Color basado en la categoría para asegurar correspondencia fija
    final baseColor = _getColorForCategory(items[i].label);
      // Debug: imprime el label de cada sector
      //print('Sector $i: ${items[i].label}');

        // Si la categoría ya fue jugada, usa el color base con opacidad 0.25 (muy oscuro)
      if (categoriasJugadas.contains(items[i].label)) {
        paint.color = _getColorForCategory(items[i].label).withOpacity(0.50);
      } else if (i == highlightedIndex && isBlinking && blinkIntensity == 1.0) {
        // Glow fuerte (prendido)
        double glowIntensity = 0.8 + (blinkIntensity * 0.2);
        double whiteGlowIntensity = 0.7 + (blinkIntensity * 0.3);

        paint.color = baseColor.withOpacity(1.0);

        // Outer glow
        final outerGlow = Paint()
          ..color = baseColor.withOpacity(glowIntensity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 45.0 + (blinkIntensity * 15.0));
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          i * sectorAngle - pi / 2 - (sectorAngle * 0.1),
          sectorAngle * 1.24,
          true,
          outerGlow,
        );

        // Inner glow
        final innerGlow = Paint()
          ..color = Colors.white.withOpacity(whiteGlowIntensity)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 25.0 + (blinkIntensity * 20.0));
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius * 0.95),
          i * sectorAngle - pi / 2,
          sectorAngle,
          true,
          innerGlow,
        );
      } else {
        // Sin glow (apagado)
        paint.color = categoriasJugadas.contains(items[i].label)
            ? _getColorForCategory(items[i].label).withOpacity(0.25)
            : baseColor.withOpacity(1.0);
      }

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sectorAngle - pi / 2,
        sectorAngle,
        true,
        paint,
      );

      final separatorPaint = Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        i * sectorAngle - pi / 2,
        sectorAngle,
        true,
        separatorPaint,
      );

      // Texto personalizado con formato específico
      final midAngle = i * sectorAngle + sectorAngle / 2 - pi / 2;
      String displayText = _getFormattedText(items[i].label);
      
      final textSpan = TextSpan(
        text: displayText,
        style: TextStyle(
          color: categoriasJugadas.contains(items[i].label)
             ? Colors.white.withOpacity(0.45)
             : Colors.white,
          fontSize: size.width * 0.045,
          fontWeight: FontWeight.w900,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.6),
              blurRadius: 3,
              offset: Offset(2, 2),
            ),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.center,
        maxLines: 2,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout(maxWidth: radius * 0.7); // Ajustado para mejor visibilidad
      final textRadialDistance = radius * 0.7; // Ajustado para mejor visibilidad
      final textX = center.dx + textRadialDistance * cos(midAngle);
      final textY = center.dy + textRadialDistance * sin(midAngle);

      canvas.save();
      canvas.translate(textX, textY);
      canvas.rotate(midAngle + pi / 2);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();

      // Icono en gris si está jugada
      final ui.Image? uiImage = loadedImages[items[i].iconAsset];
      if (uiImage != null) {
        final paintIcon = Paint();
        final iconRadialDistance = radius * 0.45;
        final iconX = center.dx + iconRadialDistance * cos(midAngle);
        final iconY = center.dy + iconRadialDistance * sin(midAngle);

        canvas.save();
        canvas.translate(iconX, iconY);
        canvas.rotate(midAngle + pi / 2);
        canvas.drawImageRect(
          uiImage,
          Rect.fromLTWH(0, 0, uiImage.width.toDouble(), uiImage.height.toDouble()),
          Rect.fromLTWH(-size.width * 0.07, -size.width * 0.07, size.width * 0.13, size.width * 0.13),
          paintIcon,
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant WheelPainter oldDelegate) {
    return oldDelegate.highlightedIndex != highlightedIndex ||
        oldDelegate.items != items ||
        oldDelegate.loadedImages.length != loadedImages.length ||
        oldDelegate.isBlinking != isBlinking ||
        oldDelegate.blinkIntensity != blinkIntensity;
  }
}
