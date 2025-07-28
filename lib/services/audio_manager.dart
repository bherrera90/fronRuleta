import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

/// Gestor centralizado de audio para toda la aplicación
/// Maneja los sonidos de respuesta correcta, incorrecta y tiempo agotado
/// Respeta el estado de silencio global configurado desde la ruleta
class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;
  AudioManager._internal();

  final AudioPlayer _effectsPlayer = AudioPlayer();
  bool _isSoundEnabled = true;

  static const String _correctSoundPath = 'sounds/respuestacorrecta.wav';
  static const String _incorrectSoundPath = 'sounds/respuestaincorrecta.wav';
  static const String _timeoutSoundPath = 'sounds/tiempoagotado.mp3';

  bool get isSoundEnabled => _isSoundEnabled;

  void setSoundEnabled(bool enabled) {
    print('🔊 AudioManager.setSoundEnabled: Cambiando de $_isSoundEnabled a $enabled');
    _isSoundEnabled = enabled;
    if (!enabled) {
      _effectsPlayer.stop();
    }
    debugPrint('AudioManager: Sonido ${enabled ? 'activado' : 'desactivado'}');
  }

  Future<void> playCorrectSound() async {
    await _playSoundEffect(_correctSoundPath, 'respuesta correcta');
  }

  Future<void> playIncorrectSound() async {
    await _playSoundEffect(_incorrectSoundPath, 'respuesta incorrecta');
  }

  Future<void> playTimeoutSound() async {
    await _playSoundEffect(_timeoutSoundPath, 'tiempo agotado');
  }

  Future<void> _playSoundEffect(String assetPath, String soundType) async {
    debugPrint('AudioManager: Intentando reproducir $soundType, sonido habilitado: $_isSoundEnabled');
    if (!_isSoundEnabled) {
      debugPrint('AudioManager: Sonido desactivado, no reproduciendo $soundType');
      return;
    }

    try {
      await _effectsPlayer.stop();
      debugPrint('AudioManager: Reproduciendo $soundType desde: $assetPath');
      await _effectsPlayer.play(AssetSource(assetPath));
      debugPrint('AudioManager: Reproduciendo sonido de $soundType exitosamente');
    } catch (e) {
      debugPrint('AudioManager: Error reproduciendo sonido de $soundType: $e');
    }
  }

  Future<void> stopAllEffects() async {
    await _effectsPlayer.stop();
  }

  Future<void> dispose() async {
    await _effectsPlayer.dispose();
  }
}

/// Mixin para gestionar audio en widgets de quiz
/// Integra con AudioManager para sonidos de respuesta y respeta el estado global de sonido
mixin QuizAudioMixin<T extends StatefulWidget> on State<T>, WidgetsBindingObserver {
  AudioPlayer? _backgroundAudioPlayer;
  AudioPlayer? _timeoutWarningPlayer;
  bool _isWidgetActive = true;

  AudioPlayer get backgroundAudioPlayer {
    _backgroundAudioPlayer ??= AudioPlayer();
    return _backgroundAudioPlayer!;
  }

  bool get isWidgetActive => _isWidgetActive;

  AudioManager get audioManager => AudioManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isWidgetActive = true;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseBackgroundAudio();
    _backgroundAudioPlayer?.dispose();
    _backgroundAudioPlayer = null;

    stopTimeoutWarningLoop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _pauseBackgroundAudio();
        break;
      case AppLifecycleState.resumed:
        if (_isWidgetActive && audioManager.isSoundEnabled) {
          _resumeBackgroundAudio();
        }
        break;
    }
  }

  void setWidgetActive() {
    _isWidgetActive = true;
  }

  void setWidgetInactive() {
    _isWidgetActive = false;
    _pauseBackgroundAudio();
    stopTimeoutWarningLoop();
  }

  void _pauseBackgroundAudio() {
    _backgroundAudioPlayer?.pause();
  }

  void _resumeBackgroundAudio() {
    // Sobrescribible si se necesita lógica específica para reanudar audio
  }

  Future<void> playBackgroundSoundSafely(String assetPath) async {
    if (_isWidgetActive && audioManager.isSoundEnabled && _backgroundAudioPlayer != null) {
      try {
        await _backgroundAudioPlayer!.play(AssetSource(assetPath));
      } catch (e) {
        debugPrint('Error reproduciendo sonido de fondo $assetPath: $e');
      }
    }
  }

  Future<void> stopBackgroundSounds() async {
    await _backgroundAudioPlayer?.stop();
  }

  Future<void> playCorrectAnswerSound() async {
    await audioManager.playCorrectSound();
  }

  Future<void> playIncorrectAnswerSound() async {
    await audioManager.playIncorrectSound();
  }

  Future<void> playTimeoutSound() async {
    await audioManager.playTimeoutSound();
  }

  Future<void> playTimeoutWarningLoop() async {
    if (!_isWidgetActive || !audioManager.isSoundEnabled) return;

    _timeoutWarningPlayer ??= AudioPlayer();
    await _timeoutWarningPlayer!.setReleaseMode(ReleaseMode.loop);

    try {
      await _timeoutWarningPlayer!.play(AssetSource('sounds/tiempoagotado.mp3'));
    } catch (e) {
      debugPrint('Error reproduciendo sonido de tiempo agotado en loop: $e');
    }
  }

  Future<void> stopTimeoutWarningLoop() async {
    await _timeoutWarningPlayer?.stop();
    await _timeoutWarningPlayer?.dispose();
    _timeoutWarningPlayer = null;
  }
}
