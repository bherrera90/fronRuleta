import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../models/api_models.dart';

String normalizarCategoria(String nombre) {
  switch (nombre) {
    case 'Curiosamente Mental':
    case 'Curiosamente':
      return 'Curiosa Mente';
    default:
      return nombre;
  }
}

class RuletaApiService {
  // ============= CONFIGURACIÓN DINÁMICA DE IP =============
  
  // Ahora solo se usa el túnel de DevTunnels para la API:
  static const List<String> _possibleBaseUrls = [
    // 🌐 PRODUCCIÓN (URL de la nube)
    //'https://ruleta-backend-o3i2.onrender.com/api',    // Render - URL de producción
    //'https://ruleta-backend.up.railway.app/api',       // Railway - URL alternativa
    
    // 🏠 DESARROLLO LOCAL
    //'http://localhost:3000/api',           // Para emulador/desarrollo local
    //'http://10.0.2.2:3000/api',          // Para emulador Android
    //'http://192.168.1.100:3000/api',     // IP común en redes domésticas
    //'http://192.168.0.100:3000/api',     // IP alternativa
    //'http://192.168.1.101:3000/api',     // Otra IP común
    //'http://192.168.0.101:3000/api',     // Otra IP alternativa
   // 'http://192.168.1.102:3000/api',     // Más IPs comunes
    //'http://192.168.0.102:3000/api',     // Más IPs comunesx
    'https://dls92kmj-3003.use2.devtunnels.ms/api', // Túnel actual para desarrollo
  ];

  // URL base actual (se detecta automáticamente)
  static String _currentBaseUrl = _possibleBaseUrls.first;
  
  // Obtener la URL base actual
  static String get baseUrl => _currentBaseUrl;
  
  // Inicializar y detectar la mejor URL disponible
  static Future<void> initialize() async {
    final workingUrl = await _detectWorkingUrl();
    if (workingUrl != null) {
      _currentBaseUrl = workingUrl;
      print('🚀 Backend configurado en: $_currentBaseUrl');
    } else {
      print('⚠️ Usando URL por defecto: $_currentBaseUrl');
    }
  }
  
  // Configurar URL personalizada
  static void setCustomUrl(String customUrl) {
    _currentBaseUrl = customUrl.endsWith('/api') ? customUrl : '$customUrl/api';
    print('🔧 URL personalizada: $_currentBaseUrl');
  }
  
  // Detectar automáticamente qué URL funciona
  static Future<String?> _detectWorkingUrl() async {
    print('🔍 Detectando URL del backend que funciona...');
    
    for (String url in _possibleBaseUrls) {
      try {
        print('⏳ Probando: $url');
        final testUrl = url.replaceAll('/api', '');
        final response = await http.get(
          Uri.parse(testUrl),
          headers: _headers,
        ).timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          print('✅ Backend encontrado en: $url');
          return url;
        }
      } catch (e) {
        print('❌ No funciona: $url - Error: $e');
        continue;
      }
    }
    
    print('⚠️ No se encontró backend disponible, usando URL por defecto');
    return null;
  }
  
  // Resetear detección (para volver a detectar)
  static void resetUrlDetection() {
    _currentBaseUrl = _possibleBaseUrls.first;
    print('🔄 Detección de URL reseteada');
  }
  
  // Timeout para las peticiones
  // Original: static const Duration timeout = Duration(seconds: 10);
static const Duration timeout = Duration(seconds: 20);

  // Headers comunes para las peticiones HTTP
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Manejo de errores HTTP
  static void _handleHttpError(http.Response response) {
    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception('Error ${response.statusCode}: ${errorData['message'] ?? 'Error desconocido'}');
    }
  }

  // ============= CATEGORÍAS =============
  
  /// Obtener todas las categorías de ruleta
  // Mapa de categorías por nombre
  static final Map<String, RuletaCategory> _categoriesCache = {};

  /// Obtiene todas las categorías y actualiza la caché
  // Implementación con reintentos automáticos y timeout aumentado
static Future<List<RuletaCategory>> getCategories({int retries = 2}) async {
    print('[DEBUG] Iniciando getCategories()');
    try {
      final url = '$baseUrl/ruleta/categories';
      print('[GET] $url');
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(timeout);
      
      stopwatch.stop();
      print('[DEBUG] Respuesta recibida en ${stopwatch.elapsedMilliseconds}ms');
      print('[STATUS] ${response.statusCode}');
      print('[SIZE] ${response.bodyBytes.length} bytes');
      print('[RESPONSE] ${response.body}');

      _handleHttpError(response);

      final List<dynamic> categoriesJson = json.decode(response.body);
      print('[DEBUG] Categorías encontradas: ${categoriesJson.length}');
      
      final categories = categoriesJson
          .map((json) => RuletaCategory.fromJson(json))
          .toList();
          
      // Actualizar caché de categorías
      _categoriesCache.clear();
      for (var category in categories) {
        _categoriesCache[normalizarCategoria(category.name)] = category;
      }
          
      print('[DEBUG] Categorías procesadas: ${categories.map((c) => c.name).toList()}');
      return categories;
    } catch (e) {
      // Reintentos automáticos
      if (retries > 0) {
        print('Error al obtener categorías, reintentando...');
        return getCategories(retries: retries - 1);
      } else {
        print('Error al obtener categorías: $e');
        return [];
      }
    }
  }

  /// Obtener una categoría específica por ID
  static Future<RuletaCategory?> getCategoryById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ruleta/categories/$id'),
        headers: _headers,
      ).timeout(timeout);
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      return RuletaCategory.fromJson(data['data']);
    } catch (e) {
      print('Error al obtener categoría $id: $e');
      return null;
    }
  }

  /// Obtiene el ID de una categoría por su nombre
  /// Devuelve null si la categoría no se encuentra
  static Future<int?> getCategoryIdByName(String categoryName) async {
    // Normalizar el nombre antes de buscar
    categoryName = normalizarCategoria(categoryName);
    // Si ya tenemos las categorías en caché, usarlas
    if (_categoriesCache.isEmpty) {
      await getCategories();
    }
    // Buscar la categoría por nombre (insensible a mayúsculas/minúsculas)
    final category = _categoriesCache.entries
        .firstWhere(
          (entry) => entry.key.toLowerCase() == categoryName.toLowerCase(),
          orElse: () => MapEntry('', RuletaCategory(
            id: -1, 
            name: '', 
            description: '', 
            color: '', 
            icon: ''
          )),
        );
    if (category.key.isEmpty) {
      print('[WARNING] No se encontró la categoría: $categoryName');
      return null;
    }
    print('[DEBUG] ID encontrado para categoría "$categoryName": ${category.value.id}');
    return category.value.id;
  }

  // ============= PREGUNTAS =============
  
  /// Obtener todas las preguntas
  static Future<List<Question>> getQuestions({int? categoryId}) async {
    print('[DEBUG] Iniciando getQuestions()');
    
    // Primero, obtener las categorías disponibles
    final categories = await getCategories();
    
    // Verificar si el categoryId proporcionado es válido
    if (categoryId != null) {
      final categoryExists = categories.any((category) => category.id == categoryId);
      if (!categoryExists) {
        print('[WARNING] La categoría con ID $categoryId no existe. Usando una categoría aleatoria.');
        // Si la categoría no existe, seleccionar una aleatoria
        if (categories.isNotEmpty) {
          final randomCategory = categories[Random().nextInt(categories.length)];
          categoryId = randomCategory.id;
          print('[DEBUG] Usando categoría aleatoria: ${randomCategory.name} (ID: $categoryId)');
        } else {
          // Si no hay categorías disponibles, no filtrar por categoría
          categoryId = null;
          print('[WARNING] No hay categorías disponibles. Obteniendo preguntas sin filtro.');
        }
      }
    }
    
    print(categoryId != null 
        ? '[FILTER] Filtrando por categoría ID: $categoryId'
        : '[DEBUG] Obteniendo todas las preguntas sin filtro');
        
    try {
      String url = '$baseUrl/ruleta/questions';
      if (categoryId != null) {
        url += '?categoryId=$categoryId';
      }
      print('[GET] $url');
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(timeout);
      
      stopwatch.stop();
      print('[DEBUG] Respuesta recibida en ${stopwatch.elapsedMilliseconds}ms');
      print('[STATUS] ${response.statusCode}');
      print('[SIZE] ${response.bodyBytes.length} bytes');
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      final List<dynamic> questionsJson = data['data'];
      
      print('[DEBUG] Preguntas encontradas: ${questionsJson.length}');
      if (questionsJson.isNotEmpty) {
        print('[EXAMPLE] Ejemplo de pregunta: ${questionsJson.first['question']?.toString().substring(0, 30)}...');
      }
      
      final questions = questionsJson
          .map((json) => Question.fromJson(json))
          .toList();
          
      return questions;
    } catch (e) {
      print('Error al obtener preguntas: $e');
      return [];
    }
  }

  /// Obtener una pregunta aleatoria
  static Future<Question?> getRandomQuestion({int? categoryId}) async {
    print('[DEBUG] Iniciando getRandomQuestion()');
    print(categoryId != null 
        ? '[FILTER] Filtrando por categoría ID: $categoryId'
        : '[DEBUG] Obteniendo pregunta aleatoria sin filtro');
        
    try {
      String url = '$baseUrl/ruleta/questions/random';
      if (categoryId != null) {
        url += '?categoryId=$categoryId';
      }
      print('[GET] $url');
      final stopwatch = Stopwatch()..start();
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(timeout);
      
      stopwatch.stop();
      print('[DEBUG] Respuesta recibida en  [1m${stopwatch.elapsedMilliseconds}ms');
      print('[STATUS] ${response.statusCode}');
      print('[SIZE] ${response.bodyBytes.length} bytes');
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      dynamic preguntaJson;
      if (data is Map && data.containsKey('data')) {
        preguntaJson = data['data'];
      } else {
        preguntaJson = data;
      }
      if (preguntaJson == null) {
        print('No se recibió pregunta aleatoria');
        return null;
      }
      final question = Question.fromJson(preguntaJson);
      
      print('[DEBUG] Pregunta aleatoria obtenida:');
      print('   ID: ${question.id}');
      print('   Categoría ID: ${question.categoryId}');
      print('   Pregunta: ${question.question}');
      
      return question;
    } catch (e) {
      print('Error al obtener pregunta aleatoria: $e');
      return null;
    }
  }

  /// Obtener una pregunta específica por ID
  static Future<Question?> getQuestionById(int id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ruleta/questions/$id'),
        //Uri.parse('$baseUrl/questions/$id'),
        headers: _headers,
      ).timeout(timeout);
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      return Question.fromJson(data['data']);
    } catch (e) {
      print('Error al obtener pregunta $id: $e');
      return null;
    }
  }

  // ============= FRASES MOTIVACIONALES =============
  
  /// Obtener frase motivacional aleatoria por emoción
  static Future<MotivationalPhrase?> getRandomPhrase(String emotion) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ruleta/phrases/${emotion.toLowerCase()}/random'),
        //Uri.parse('$baseUrl/phrases/${emotion.toLowerCase()}/random'),
        headers: _headers,
      ).timeout(timeout);
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      return MotivationalPhrase.fromString(data['data'], emotion);
    } catch (e) {
      print('Error al obtener frase motivacional para $emotion: $e');
      return null;
    }
  }

  /// Obtener todas las frases por emoción
  static Future<List<String>> getPhrasesByEmotion(String emotion) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ruleta/phrases/${emotion.toLowerCase()}'),
        //Uri.parse('$baseUrl/phrases/${emotion.toLowerCase()}'),
        headers: _headers,
      ).timeout(timeout);
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      return List<String>.from(data['data']);
    } catch (e) {
      print('Error al obtener frases para $emotion: $e');
      return [];
    }
  }

  // ============= MENSAJES DE JUEGO =============
  
  /// Obtener mensaje de juego aleatorio por tipo
  static Future<GameMessage?> getRandomGameMessage(String type) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ruleta/game-messages/${type.toLowerCase()}/random'),
        //Uri.parse('$baseUrl/game-messages/${type.toLowerCase()}/random'),
        headers: _headers,
      ).timeout(timeout);
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      return GameMessage.fromString(data['data'], type);
    } catch (e) {
      print('Error al obtener mensaje de juego tipo $type: $e');
      return null;
    }
  }

  /// Obtener todos los mensajes por tipo
  static Future<List<String>> getGameMessagesByType(String type) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ruleta/game-messages/${type.toLowerCase()}'),
        //Uri.parse('$baseUrl/game-messages/${type.toLowerCase()}'),
        headers: _headers,
      ).timeout(timeout);
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      return List<String>.from(data['data']);
    } catch (e) {
      print('Error al obtener mensajes de juego tipo $type: $e');
      return [];
    }
  }

  // ============= MENSAJES POR EMOCIÓN =============
  
  /// Obtener mensaje aleatorio por emoción
  static Future<EmotionMessage?> getRandomEmotionMessage(String emotion) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ruleta/emotion-messages/${emotion.toLowerCase()}/random'),
        //Uri.parse('$baseUrl/emotion-messages/${emotion.toLowerCase()}/random'),
        headers: _headers,
      ).timeout(timeout);
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      return EmotionMessage.fromString(data['data'], emotion);
    } catch (e) {
      print('Error al obtener mensaje emocional para $emotion: $e');
      return null;
    }
  }

  /// Obtener todos los mensajes por emoción
  static Future<List<String>> getEmotionMessagesByEmotion(String emotion) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ruleta/emotion-messages/${emotion.toLowerCase()}'),
        //Uri.parse('$baseUrl/emotion-messages/${emotion.toLowerCase()}'),
        headers: _headers,
      ).timeout(timeout);
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      return List<String>.from(data['data']);
    } catch (e) {
      print('Error al obtener mensajes emocionales para $emotion: $e');
      return [];
    }
  }

  // ============= INFORMACIÓN DE LA API =============
  
  /// Obtener información general de la API
  static Future<Map<String, dynamic>?> getApiInfo() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ruleta/info'),
        //Uri.parse('$baseUrl/info'),
        headers: _headers,
      ).timeout(timeout);
      
      _handleHttpError(response);
      
      final data = json.decode(response.body);
      return data['data'];
    } catch (e) {
      print('Error al obtener información de la API: $e');
      return null;
    }
  }

  // ============= DATOS POR DEFECTO (FALLBACK) =============
  
  // Las categorías se obtienen dinámicamente desde la API
  static List<RuletaCategory> get defaultCategories => [
    RuletaCategory(
      id: 4,
      name: 'Mindfulness',
      description: 'Atención plena y consciencia del momento presente',
      color: '#96CEB4',
      icon: '🧘',
    ),
    RuletaCategory(
      id: 5,
      name: 'Creatividad',
      description: 'Estimulación del pensamiento creativo y artístico',
      color: '#FFEAA7',
      icon: '🎨',
      ),
    ];

  // ============= UTILIDADES =============
  
  /// Verificar si la API está disponible
  static Future<bool> isApiAvailable() async {
    try {
      final testUrl = RuletaApiService._currentBaseUrl.replaceAll('/api', '');
      final response = await http.get(
        Uri.parse(testUrl),
        headers: RuletaApiService._headers,
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('API no disponible: $e');
      return false;
    }
  }

  /// Mapear nombre de categoría local a emoción para la API
  static String mapCategoryToEmotion(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'mente sana':
      case 'emociones':
        return 'alegria';
      case 'clave mental':
      case 'autoestima':
        return 'seguridad';
      case 'q+ve':
      case 'relaciones':
        return 'amor';
      case 'curiosa mente':
      case 'mindfulness':
        return 'paz';
      case 'mitos desmentidos':
      case 'creatividad':
        return 'creatividad';
      default:
        return 'alegria';
    }
  }

  /// Mapear nombre de categoría local a tipo de mensaje de juego
  static String mapCategoryToGameMessageType(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'mente sana':
      case 'emociones':
        return 'sabias_que';
      case 'clave mental':
      case 'autoestima':
        return 'puzzle';
      case 'q+ve':
      case 'relaciones':
        return 'mente_en_pares';
      case 'curiosa mente':
      case 'mindfulness':
        return 'curiosamente';
      case 'mitos desmentidos':
      case 'creatividad':
        return 'curiosamente';
      default:
        return 'curiosamente';
    }
  }

  /// Obtiene las categorías con solo id y nombre
  static Future<List<Map<String, dynamic>>> getCategoriasIdNombre() async {
    try {
      final response = await http.get(
        Uri.parse('${RuletaApiService._currentBaseUrl}/ruleta/categories'),
        headers: RuletaApiService._headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Extrae solo id y nombre
        return data.map((cat) => {
          'id': cat['id'],
          'nombre': cat['name'] ?? cat['nombre'] ?? '', // Usa name o nombre, con valor por defecto
        }).toList();
      } else {
        throw Exception('Error al obtener categorías: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en getCategoriasIdNombre: $e');
      rethrow;
    }
  }
}
