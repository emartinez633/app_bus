import 'package:nfc_manager/nfc_manager.dart';

class NfcService {
  
  // Verifica si el dispositivo tiene hardware NFC y si está encendido
  Future<bool> isNfcAvailable() async {
    return await NfcManager.instance.isAvailable();
  }

  // Inicia la sesión de lectura continua
  Future<void> startReading({
    required Function(String tagId, String? payload) onTagDiscovered,
    required Function(String error) onError,
  }) async {
    try {
      bool isAvailable = await isNfcAvailable();
      if (!isAvailable) {
        onError("El NFC no está disponible o está apagado.");
        return;
      }

      NfcManager.instance.startSession(
        pollingOptions: {
          NfcPollingOption.iso14443,
          NfcPollingOption.iso15693,
          NfcPollingOption.iso18092,
        },
        onDiscovered: (NfcTag tag) async {
          String tagId = _extractTagId(tag);
          
          // Enviamos el ID al controlador
          onTagDiscovered(tagId, null);
        },
      );
    } catch (e) {
      onError("Error al iniciar el lector NFC: $e");
    }
  }

  // Detiene el lector NFC para ahorrar batería
  Future<void> stopReading() async {
    await NfcManager.instance.stopSession();
  }

  // --- Métodos privados de ayuda --- //

  // Transforma el arreglo de bytes del UID a un String hexadecimal legible
  String _extractTagId(NfcTag tag) {
    try {
      // AQUÍ ESTÁ LA SOLUCIÓN: Casteo explícito con 'as Map'
      final Map nfcData = tag.data as Map;
      List<int>? identifier;

      if (nfcData.containsKey('nfca') && nfcData['nfca'].containsKey('identifier')) {
        identifier = List<int>.from(nfcData['nfca']['identifier']);
      } else if (nfcData.containsKey('mifare') && nfcData['mifare'].containsKey('identifier')) {
        identifier = List<int>.from(nfcData['mifare']['identifier']);
      } else if (nfcData.containsKey('ndef') && nfcData['ndef'].containsKey('identifier')) {
        identifier = List<int>.from(nfcData['ndef']['identifier']);
      }

      if (identifier != null && identifier.isNotEmpty) {
        return identifier.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':').toUpperCase();
      }
      return "ID_DESCONOCIDO";
    } catch (e) {
      return "ERROR_LEYENDO_ID";
    }
  }
}