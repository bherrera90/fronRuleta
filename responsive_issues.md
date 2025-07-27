# Análisis de Responsividad - Ruleta de la Salud Mental

## Problemas identificados y soluciones

### 1. Configuración de Orientación Fija
**Archivo**: `lib/main.dart`  
**Línea**: ~24-27  
**Problema**: La aplicación está configurada para forzar solo la orientación vertical, lo que puede no ser óptimo para todos los dispositivos.

**Solución**:
```dart
// Reemplazar el bloque actual con:
await SystemChrome.setPreferredOrientations([
  DeviceOrientation.portraitUp,
  // Opcional: permitir landscape para tablets
  // DeviceOrientation.landscapeLeft,
  // DeviceOrientation.landscapeRight,
]);
```

### 2. Dimensiones Fijas en RuletaGame.dart
**Archivo**: `lib/scr/RuletaGame.dart`  
**Problema**: Uso de valores fijos para dimensiones que no se adaptan a diferentes tamaños de pantalla.

**Solución**:
- Reemplazar dimensiones fijas con `MediaQuery` o `LayoutBuilder`
- Usar `FractionallySizedBox` o `Expanded` para elementos que deben ocupar porcentajes de pantalla
- Implementar `AspectRatio` para mantener proporciones en la ruleta

### 3. Textos sin Ajuste Automático
**Archivo**: `lib/scr/RuletaGame.dart` y otros
**Problema**: Textos que no se ajustan al tamaño de la pantalla.

**Solución**:
```dart
Text(
  'Texto de ejemplo',
  style: TextStyle(
    fontSize: MediaQuery.of(context).size.width * 0.05, // 5% del ancho de la pantalla
  ),
  textAlign: TextAlign.center,
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### 4. Botones con Tamaño Fijo
**Archivo**: `lib/scr/QuestionTest.dart` y otros
**Problema**: Botones con dimensiones fijas que no se adaptan a pantallas pequeñas.

**Solución**:
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    minimumSize: Size(
      MediaQuery.of(context).size.width * 0.8, // 80% del ancho
      MediaQuery.of(context).size.height * 0.06, // 6% de la altura
    ),
    padding: EdgeInsets.symmetric(vertical: 12),
  ),
  // ... resto del código
)
```

### 5. Imágenes sin Escalado Responsivo
**Archivo**: Varios archivos con recursos de imágenes
**Problema**: Las imágenes podrían no escalar correctamente.

**Solución**:
```dart
Image.asset(
  'assets/images/ejemplo.png',
  width: MediaQuery.of(context).size.width * 0.9, // 90% del ancho
  fit: BoxFit.contain,
)
```

### 6. Diálogos y Popups
**Archivo**: `lib/scr/QuestionTest.dart` (IncorrectAnswerDialog)
**Problema**: Los diálogos podrían desbordarse en pantallas pequeñas.

**Solución**:
```dart
showDialog(
  context: context,
  builder: (context) => Dialog(
    insetPadding: EdgeInsets.symmetric(
      horizontal: MediaQuery.of(context).size.width * 0.05,
      vertical: 20,
    ),
    child: SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Contenido del diálogo
          ],
        ),
      ),
    ),
  ),
);
```

## Recomendaciones Generales

1. **Usar MediaQuery**: Para obtener dimensiones de pantalla y ajustar los tamaños en consecuencia.

2. **LayoutBuilder**: Para crear diseños que respondan a diferentes restricciones de tamaño.

3. **Widgets Flexibles**:
   - `Expanded` y `Flexible` para distribuir el espacio
   - `Wrap` para widgets que deben fluir en múltiples líneas
   - `AspectRatio` para mantener proporciones

4. **Fuentes Responsivas**:
   - Usar `MediaQuery.textScaleFactor` para ajustar el tamaño del texto
   - Considerar paquetes como `auto_size_text` para textos que deben ajustarse

5. **Pruebas en Diferentes Dispositivos**:
   - Probar en diferentes tamaños de pantalla
   - Usar el modo de diseño adaptable de Flutter
   - Considerar el uso de `DevicePreview` para pruebas rápidas

6. **SafeArea**: Asegurar que el contenido no se oculte detrás de muescas o áreas seguras.

## Herramientas Útiles

1. **Flutter DevTools**: Para inspeccionar el diseño
2. **Flutter Layout Builder**: Herramienta visual para construir diseños responsivos
3. **Extensiones de VSCode**: Como "Flutter Widget Snippets" para generar código responsive rápidamente

## Próximos Pasos

1. Implementar las correcciones sugeridas en los archivos mencionados
2. Realizar pruebas exhaustivas en diferentes dispositivos
3. Considerar el uso de paquetes como `flutter_screenutil` o `sizer` para un manejo más sencillo de dimensiones responsivas
4. Realizar pruebas de usabilidad en dispositivos reales
