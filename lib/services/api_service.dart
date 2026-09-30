import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Reemplaza con tu URL de Ngrok
  final String _baseUrl = 'https://rephrase-velocity-viability.ngrok-free.dev/api';

  Future<Map<String, dynamic>> login(String correo, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true'
        },
        body: jsonEncode({
          'correo': correo,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['error'] ?? 'Error desconocido'};
      }
    }  catch (e) {
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
        final List<String> universidades = data.map((u) => u['name'].toString()).toSet().toList();
        universidades.sort(); 
        return universidades;
      }
    } catch (e) {
      return ['Universidad de Colima', 'UNAM', 'IPN', 'Tecnológico de Monterrey'];
    }
    return [];
  }

  // --- MÉTODO PARA COBRO NFC ---
  Future<Map<String, dynamic>> registrarCobroNfc(String correo, String tagId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/pagar-pasaje'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true' 
        },
        body: jsonEncode({
          'correo': correo,
          'tagId': tagId, 
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body); 
      } else {
        final errorData = jsonDecode(response.body);
        return {'error': errorData['error'] ?? 'Error al cobrar pasaje'};
      }
    } catch (e) {
      return {'error': 'Falla de conexión: $e'};
    }
  }

  // --- MÉTODO PARA EL HISTORIAL DEL CHOFER (AHORA ADENTRO DE LA CLASE) ---
  Future<List<dynamic>> obtenerHistorialChofer() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/historial-cobros'),
        headers: {'ngrok-skip-browser-warning': 'true'}, 
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error obteniendo historial: $e');
    }
    return []; 
  }

} // <--- ESTA ES LA ÚNICA LLAVE QUE CIERRA LA CLASE AL FINAL