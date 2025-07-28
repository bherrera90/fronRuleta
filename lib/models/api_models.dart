// Modelos de datos para la API de Ruleta

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String message;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    required this.message,
    this.error,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      data: json['data'] != null ? fromJsonT(json['data']) : null,
      message: json['message'] ?? '',
      error: json['error'],
    );
  }
}

class RuletaCategory {
  final int id;
  final String name;
  final String description;
  final String color;
  final String icon;

  RuletaCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
    required this.icon,
  });

  factory RuletaCategory.fromJson(Map<String, dynamic> json) {
    return RuletaCategory(
      id: json['id'],
      name: json['name'] ?? json['nombre'] ?? '',
      description: json['description'] ?? json['descripcion'] ?? '',
      color: json['color'] ?? '',
      icon: json['icon'] ?? json['icono'] ?? '',
    );
  }

  // Mapeo de nombres de categorías de la API a los assets locales
  String get iconAsset {
    switch (name) {
      case 'Mente Sana':
        return 'assets/icons/ICONO MENTE SANA w53 h54.png';
      case 'Mitos Desmentidos':
        return 'assets/icons/Iconos mitos.png';
      case 'Curiosamente':
        return 'assets/icons/ICONO CURIOSAMENT.png';
      case 'Q+VE':
        return 'assets/icons/ICONO Q+VE.png';
      case 'Clave Mental':
        return 'assets/icons/ICONO CLAVE MENTAL.png';
      default:
        return 'assets/icons/ICONO MENTE SANA w53 h54.png';
    }
  }

  // Los nombres ya coinciden con los locales, no necesitamos mapeo
  String get localName {
    return name; // Los nombres de la API ya son los correctos
  }
}

class Question {
  final int id;
  final String question;
  final List<String> options;
  final int categoryId;
  final String categoryName;
  final String explanation; // <-- Nuevo campo

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.categoryId,
    required this.categoryName,
    required this.explanation, // <-- Nuevo campo
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'],
      question: json['question'] ?? json['texto'],
      options: List<String>.from(json['options'] ?? json['opciones']),
      categoryId: json['categoria'] != null ? json['categoria']['id'] : 0,
      categoryName: json['categoria'] != null ? json['categoria']['nombre'] : '',
      explanation: json['explanation'] ?? json['explicacion'] ?? '', // <-- Nuevo campo
    );
  }
}

class MotivationalPhrase {
  final String phrase;
  final String emotion;

  MotivationalPhrase({
    required this.phrase,
    required this.emotion,
  });

  factory MotivationalPhrase.fromString(String phrase, String emotion) {
    return MotivationalPhrase(
      phrase: phrase,
      emotion: emotion,
    );
  }
}

class GameMessage {
  final String message;
  final String type;

  GameMessage({
    required this.message,
    required this.type,
  });

  factory GameMessage.fromString(String message, String type) {
    return GameMessage(
      message: message,
      type: type,
    );
  }
}

class EmotionMessage {
  final String message;
  final String emotion;

  EmotionMessage({
    required this.message,
    required this.emotion,
  });

  factory EmotionMessage.fromString(String message, String emotion) {
    return EmotionMessage(
      message: message,
      emotion: emotion,
    );
  }
}
