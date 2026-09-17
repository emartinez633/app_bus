import 'package:flutter/material.dart';
import '../services/nfc_service.dart';
import '../services/tts_service.dart';
import '../services/api_service.dart';
import '../services/db_offline_service.dart';

class OperadorController extends ChangeNotifier {
  // Instanciamos los servicios que construimos previamente
  final NfcService _nfcService = NfcService();
  final TtsService _ttsService = TtsService();
  final ApiService _apiService = ApiService();
  final DbOfflineService _dbOfflineService = DbOfflineService();

  // Variables de estado para la UI
  bool isScanning = false;
  String statusMessage = "Listo para iniciar el recorrido.";

  // Inicialización de periféricos (Llamar al entrar a la pantalla del chofer)
  Future<void> init() async {
    await _ttsService.initTts();
  }

  // Enciende el sensor NFC y queda a la espera de pasajeros
  void iniciarEscaneo() async {
    isScanning = true;
    statusMessage = "Acerca una tarjeta NFC al dispositivo...";
    notifyListeners(); // Avisa a la vista que debe redibujarse

    await _nfcService.startReading(
      onTagDiscovered: _procesarCobro,
      onError: (error) {
        statusMessage = error;
        isScanning = false;
        notifyListeners();
      },
    );
  }

  // Apaga el sensor NFC
  void detenerEscaneo() async {
    await _nfcService.stopReading();
    isScanning = false;
    statusMessage = "Escáner detenido.";
    notifyListeners();
  }

  // Lógica principal: Orquesta el cobro, la red, la BD local y la voz
  Future<void> _procesarCobro(String tagId, String? payload) async {
    statusMessage = "Procesando tarjeta...";
    notifyListeners();

    try {
      // 1. Intentamos comunicación directa con el servidor Node.js
      bool exito = await _apiService.registrarCobroNfc(tagId);
      
      if (exito) {
        statusMessage = "Viaje cobrado exitosamente.";
        await _ttsService.speak("Viaje cobrado.");
      } else {
        statusMessage = "Tarjeta rechazada o saldo insuficiente.";
        await _ttsService.speak("Tarjeta rechazada.");
      }
    } catch (e) {
      // 2. Si hay error de red (falla el catch), guardamos en SQLite
      await _dbOfflineService.guardarViajeOffline(tagId);
      statusMessage = "Sin red. Viaje guardado localmente.";
      await _ttsService.speak("Modo sin conexión. Viaje registrado.");
    }
    
    notifyListeners();

    // 3. Pequeña pausa para evitar cobros dobles si el pasajero deja la tarjeta pegada
    await Future.delayed(const Duration(seconds: 2));
    
    if (isScanning) {
      statusMessage = "Acerca una tarjeta NFC al dispositivo...";
      notifyListeners();
    }
  }

  // Liberar recursos cuando el controlador se destruye
  @override
  void dispose() {
    _nfcService.stopReading();
    _ttsService.stop();
    super.dispose();
  }
}