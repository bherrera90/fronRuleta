// Este archivo fuerza la inclusión de todos los widgets en la compilación release
// usando múltiples técnicas para evitar tree-shaking

import 'package:flutter/material.dart';
import 'scr/QuestionTest.dart';
import 'scr/Curiosamente.dart';
import 'scr/Qmas.dart';
import 'scr/Clave.dart';
import 'scr/Desmintiendo.dart';
import 'scr/final.dart';

class WidgetLoader {
  // Mapa global de widgets para evitar tree-shaking
  static final Map<String, Widget Function()> _widgetMap = {
    'Mente Sana': () => const QuestionTestQuiz(),
    'Curiosamente': () => const CuriosamenteQuiz(),
    'Curiosamente Mental': () => const CuriosamenteQuiz(),
    'Curiosa Mente': () => const CuriosamenteQuiz(),
    'Q+ve': () => const QmasQuiz(),
    'Q+VE': () => const QmasQuiz(),
    'Q+Ve': () => const QmasQuiz(),
    'Q+vE': () => const QmasQuiz(),
    'Clave Mental': () => const ClaveMentalQuiz(),
    'Mitos Desmentidos': () => const DesmintendoQuiz(),
  };

  // Lista de todas las categorías soportadas
  static const List<String> supportedCategories = [
    'Mente Sana',
    'Curiosamente',
    'Curiosamente Mental',
    'Curiosa Mente',
    'Q+ve',
    'Q+VE',
    'Q+Ve',
    'Q+vE',
    'Clave Mental',
    'Mitos Desmentidos',
  ];

  // Método principal para crear widgets
  static Widget createWidget(String categoryName) {
    print('WIDGET_LOADER: Intentando crear widget para: "$categoryName"');
    
    if (_widgetMap.containsKey(categoryName)) {
      print('WIDGET_LOADER: Widget encontrado en mapa para: "$categoryName"');
      return _widgetMap[categoryName]!();
    }
    
    print('WIDGET_LOADER: Widget NO encontrado para: "$categoryName"');
    print('WIDGET_LOADER: Categorías disponibles: ${_widgetMap.keys.toList()}');
    
    return Scaffold(
      appBar: AppBar(title: const Text('Categoría no encontrada')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No se encontró pantalla para: $categoryName'),
            const SizedBox(height: 20),
            Text('Categorías disponibles:'),
            ...supportedCategories.map((cat) => Text('- $cat')),
          ],
        ),
      ),
    );
  }

  // Método que fuerza la inclusión de todos los widgets
  static void forceIncludeAllWidgets() {
    print('WIDGET_LOADER: Forzando inclusión de todos los widgets...');
    
    // Crear instancias de todos los widgets
    final allWidgets = [
      const QuestionTestQuiz(),
      const CuriosamenteQuiz(),
      const QmasQuiz(),
      const ClaveMentalQuiz(),
      const DesmintendoQuiz(),
      const PantallaFinJuego(
        mensajeFinal: '',
        rutaImagen: '',
        textoSecundario: '',
      ),
    ];
    
    // Usar las instancias para evitar tree-shaking
    for (final widget in allWidgets) {
      widget.toString();
    }
    
    // También usar el mapa para asegurar que se incluya
    for (final entry in _widgetMap.entries) {
      entry.value();
    }
    
    print('WIDGET_LOADER: Todos los widgets incluidos forzadamente');
  }

  // Verificar si una categoría es soportada
  static bool isCategorySupported(String categoryName) {
    return _widgetMap.containsKey(categoryName);
  }

  // Obtener todas las categorías disponibles
  static List<String> getAvailableCategories() {
    return _widgetMap.keys.toList();
  }
} 