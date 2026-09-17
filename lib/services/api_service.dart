import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Reemplaza con la IP de tu computadora
  final String _baseUrl = 'https://rephrase-velocity-viability.ngrok-free.dev/api';

Future<Map<String, dynamic>> login(String correo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json','ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({
          'correo': correo,
          'password': password,
        }),
      );
      // ... (el resto del código se queda igual)

      if (response.statusCode == 200) {
        // Login exitoso
        return jsonDecode(response.body); 
      } else {
        // Error de credenciales o usuario no encontrado
        final errorData = jsonDecode(response.body);
        return {'error': errorData['error'] ?? 'Error desconocido'};
      }
    }  catch (e) {
      // Ahora el SnackBar nos dirá el error técnico exacto
      return {'error': 'Falla de red: $e'}; 
    }
  }

  // --- MÉTODO PARA REGISTRO ---
  Future<Map<String, dynamic>> registro(String correo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/registro'),
        headers: {'Content-Type': 'application/json','ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({
          'correo': correo,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['error'] ?? 'Error al registrar'};
      }
    } catch (e) {
      return {'error': 'No se pudo conectar con el servidor.'};
    }
  }

  // --- MÉTODO PARA RECARGAR SALDO ---
  Future<Map<String, dynamic>> recargarSaldo(String correo, double monto) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/recargar'),
        headers: {'Content-Type': 'application/json','ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({
          'correo': correo,
          'monto': monto,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['error'] ?? 'Error al recargar'};
      }
    } catch (e) {
      return {'error': 'No se pudo conectar con el servidor.'};
    }
  }

  // --- MÉTODO PARA VERIFICAR ESTUDIANTE ---
  Future<Map<String, dynamic>> verificarEstudiante(
      String correo, String nombre, String curp, String escuela, String matricula) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/verificar-estudiante'),
        headers: {'Content-Type': 'application/json','ngrok-skip-browser-warning': 'true'},
        body: jsonEncode({
          'correo': correo,
          'nombreCompleto': nombre,
          'curp': curp,
          'escuela': escuela,
          'matricula': matricula,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['error'] ?? 'Error en la verificación'};
      }
    } catch (e) {
      return {'error': 'No se pudo conectar con el servidor.'};
    }
  }

  // --- MÉTODO PARA OBTENER UNIVERSIDADES DE MÉXICO ---
  Future<List<String>> obtenerUniversidades() async {
    try {
      final response = await http.get(Uri.parse('http://universities.hipolabs.com/search?country=Mexico'));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        // Extraemos los nombres, eliminamos duplicados con toSet() y volvemos a lista
        final List<String> universidades = data.map((u) => u['name'].toString()).toSet().toList();
        universidades.sort(); // Las ordenamos alfabéticamente
        return universidades;
      }
    } catch (e) {
      // Si el usuario no tiene internet en este momento o la API falla, mandamos un respaldo básico
      return ['Universidad de Colima', 'UNAM', 'IPN', 'Tecnológico de Monterrey'];
    }
    return [];
  }

  // --- MÉTODO RESTAURADO PARA EL CHOFER ---
  Future<bool> registrarCobroNfc(String tagId) async {
    try {
      // Por ahora simularemos la respuesta para que la app compile y podamos probar el Login.
      // Una vez que el Login funcione, conectaremos esto a una ruta real en Node.js
      await Future.delayed(const Duration(milliseconds: 500));
      return true; // Simulamos que el cobro fue exitoso
    } catch (e) {
      return false;
    }
  }
}