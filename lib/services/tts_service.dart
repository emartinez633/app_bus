import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  // Inicialización y configuración básica
  Future<void> initTts() async {
    await _flutterTts.setLanguage("es-MX");
    await _flutterTts.setSpeechRate(0.5); // Velocidad normal
    await _flutterTts.setVolume(1.0); // Volumen máximo
    await _flutterTts.setPitch(1.0); // Tono natural
  }

  // Método para reproducir un mensaje
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  // Método para detener la reproducción en curso
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}