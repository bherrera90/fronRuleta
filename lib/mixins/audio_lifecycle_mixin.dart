import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Mixin para gestionar el ciclo de vida del audio en widgets de quiz
/// Pausa el audio cuando el widget no está activo o la app está en segundo plano
mixin AudioLifecycleMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  AudioPlayer? _audioPlayer;
  bool _isWidgetActive = true;
  
  /// Obtiene el reproductor de audio del widget
  AudioPlayer get audioPlayer {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }
  
  /// Indica si el widget está actualmente activo
  bool get isWidgetActive => _isWidgetActive;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isWidgetActive = true;
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseAudio();
    _audioPlayer?.dispose();
    _audioPlayer = null;
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        _pauseAudio();
        break;
      case AppLifecycleState.resumed:
        if (_isWidgetActive) {
          _resumeAudio();
        }
        break;
      case AppLifecycleState.hidden:
        _pauseAudio();
        break;
    }
  }
  
  /// Marca el widget como activo (cuando entra en pantalla)
  void setWidgetActive() {
    _isWidgetActive = true;
  }
  
  /// Marca el widget como inactivo (cuando sale de pantalla)
  void setWidgetInactive() {
    _isWidgetActive = false;
    _pauseAudio();
  }
  
  /// Pausa todos los audios del widget
  void _pauseAudio() {
    _audioPlayer?.pause();
  }
  
  /// Reanuda el audio si el widget está activo
  void _resumeAudio() {
    // Este método puede ser sobrescrito por cada widget si necesita lógica específica
    // Por defecto no reanuda automáticamente para evitar sonidos no deseados
  }
  
  /// Reproduce un sonido de manera segura
  Future<void> playSoundSafely(String assetPath) async {
    if (_isWidgetActive && _audioPlayer != null) {
      try {
        await _audioPlayer!.play(AssetSource(assetPath));
      } catch (e) {
        debugPrint('Error reproduciendo sonido $assetPath: $e');
      }
    }
  }
  
  /// Detiene todos los sonidos del widget
  Future<void> stopAllSounds() async {
    await _audioPlayer?.stop();
  }
}
