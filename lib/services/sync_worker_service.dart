import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'db_offline_service.dart';
import 'api_service.dart';

class SyncWorkerService {
  // Instancias de nuestros servicios de datos y red
  final DbOfflineService _dbOfflineService = DbOfflineService();
  final ApiService _apiService = ApiService();
  
  // Bandera para evitar que múltiples procesos de sincronización se encimen
  bool _isSyncing = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Inicia la escucha continua de cambios en la red.
  /// Debe llamarse una sola vez al iniciar la aplicación (ej. en el main).
  void iniciarMonitorDeRed() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Si el dispositivo recupera conexión a internet (Móvil o WiFi), disparamos la sincronización
      if (results.contains(ConnectivityResult.mobile) || results.contains(ConnectivityResult.wifi)) {
        sincronizarViajesPendientes();
      }
    });
  }

  /// Lógica principal que extrae datos locales y los envía al backend
  Future<void> sincronizarViajesPendientes() async {
    // Si ya hay una sincronización en curso, ignoramos el llamado
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      // 1. Obtener todos los registros guardados en SQLite
      final viajes = await _dbOfflineService.obtenerViajesPendientes();

      if (viajes.isEmpty) {
        _isSyncing = false;
        return; // No hay nada pendiente
      }

      print('Iniciando sincronización de ${viajes.length} viajes...');

      // 2. Iterar sobre cada viaje guardado y enviarlo al servidor
      for (var viaje in viajes) {
        final idLocal = viaje['id'];
        final tagId = viaje['tag_id'];

        // Reutilizamos el ApiService para enviar el cobro
        final resultado = await _apiService.registrarCobroNfc(viaje['correo'], tagId);

        if (!resultado.containsKey('error')) {
          // 3. Si el servidor responde con éxito, lo eliminamos de la base de datos local
          await _dbOfflineService.eliminarViajeSincronizado(idLocal);
          print('Viaje $idLocal sincronizado y eliminado localmente.');
        } else {
          print('Fallo al sincronizar el viaje $idLocal. El backend no lo aceptó.');
          // Si falla (ej. tarjeta sin saldo detectada a destiempo), 
          // dependiendo de la regla de negocio, se podría eliminar o marcar como "rechazado".
        }
      }
    } catch (e) {
      print('Error durante la sincronización: $e');
      // Si la red vuelve a fallar a mitad del proceso, se cancela y se intentará en la próxima reconexión.
    } finally {
      // Liberamos el candado para futuras sincronizaciones
      _isSyncing = false;
    }
  }

  /// Detener el monitor cuando ya no se necesite
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}