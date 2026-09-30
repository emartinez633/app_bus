import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'login_screen.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../services/api_service.dart'; // <--- FALTABA ESTO: Importar tu API

class ChoferScreen extends StatefulWidget {
  final Map<String, dynamic> usuario;

  const ChoferScreen({super.key, required this.usuario});

  @override
  State<ChoferScreen> createState() => _ChoferScreenState();
}

class _ChoferScreenState extends State<ChoferScreen> {
  late IO.Socket socket;
  
  String _estadoCobro = 'Esperando tarjeta...';
  Color _colorEstado = Colors.grey;
  IconData _iconoEstado = Icons.contactless;

  // Variables para la contabilidad del turno
  final List<Map<String, dynamic>> _historialCobros = [];
  double _gananciasTotales = 0.0;

  @override
  void initState() {
    super.initState();
    _cargarHistorial(); // <--- FALTABA ESTO: Cargar SQLite primero
    _conectarSocket();  // Luego conectar el socket en vivo
  }

  // --- FALTABA ESTA FUNCIÓN COMPLETA ---
  // Descarga los viajes pasados desde Node.js al abrir la pantalla
  Future<void> _cargarHistorial() async {
    final historialDb = await ApiService().obtenerHistorialChofer();
    
    if (mounted) {
      setState(() {
        _historialCobros.clear();
        _gananciasTotales = 0.0;
        
        for (var cobro in historialDb) {
          final montoDouble = (cobro['monto'] ?? 0).toDouble();
          _historialCobros.add({
            'correo': cobro['correo'],
            'monto': montoDouble,
            'hora': cobro['hora'],
          });
          _gananciasTotales += montoDouble;
        }
      });
    }
  }
  // ------------------------------------

  void _conectarSocket() {
    // Asegúrate de usar tu Ngrok aquí (sin el /api)
    const String urlServidor = 'https://tu-dominio-asignado.ngrok-free.app'; 
    
    socket = IO.io(urlServidor, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'ngrok-skip-browser-warning': 'true'} 
    });

    socket.connect();
    socket.onConnect((_) => debugPrint('✅ Conectado al WebSocket del servidor'));

    // EVENTO 1: PAGO APROBADO
    socket.on('pago_exitoso', (data) {
      if (mounted) {
        final double montoCobrado = (data['montoPagado'] ?? 0).toDouble();
        final ahora = DateTime.now();
        final horaFormato = "${ahora.hour.toString().padLeft(2, '0')}:${ahora.minute.toString().padLeft(2, '0')}";

        setState(() {
          // 1. Actualizamos el radar visual
          _estadoCobro = '¡Pago Aprobado!\n${data['correo']}\nDescontado: \$${montoCobrado.toStringAsFixed(2)}';
          _colorEstado = Colors.green;
          _iconoEstado = Icons.check_circle;

          // 2. Registramos en la bitácora
          _gananciasTotales += montoCobrado;
          _historialCobros.insert(0, { // insert(0) para que los más nuevos salgan arriba
            'correo': data['correo'],
            'monto': montoCobrado,
            'hora': horaFormato,
          });
        });
        _regresarAEstadoEspera();
      }
    });

    // EVENTO 2: PAGO RECHAZADO
    socket.on('pago_rechazado', (data) {
      if (mounted) {
        setState(() {
          _estadoCobro = 'Pago Rechazado\n${data['motivo']}';
          _colorEstado = Colors.red;
          _iconoEstado = Icons.cancel;
        });
        _regresarAEstadoEspera();
      }
    });
  }

  void _regresarAEstadoEspera() {
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _estadoCobro = 'Esperando tarjeta...';
          _colorEstado = Colors.grey;
          _iconoEstado = Icons.contactless;
        });
      }
    });
  }

  // Función para mostrar el corte de caja
  void _mostrarReporteTurno() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Corte de Caja', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF09155B))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.monetization_on, size: 60, color: Colors.green),
            const SizedBox(height: 16),
            Text('Pasajeros cobrados: ${_historialCobros.length}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Ganancias totales:', style: const TextStyle(fontSize: 18)),
            Text('\$${_gananciasTotales.toStringAsFixed(2)}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text('Exportar a PDF', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(context); // Cerramos el diálogo para que no estorbe
              _generarYCompartirPDF(); // Lanzamos la creación del PDF
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generarYCompartirPDF() async {
    final pdf = pw.Document();
    final ahora = DateTime.now();
    final fechaStr = "${ahora.day}/${ahora.month}/${ahora.year} ${ahora.hour}:${ahora.minute}";

    // Dibujamos la página
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Text('Reporte de Corte de Caja', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('Unidad de transporte: ${widget.usuario['correo']}'),
              pw.Text('Fecha de emisión: $fechaStr'),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              // Resumen
              pw.Text('Resumen del Turno', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Pasajeros totales: ${_historialCobros.length}'),
              pw.Text('Ganancias totales: \$${_gananciasTotales.toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              
              // Tabla de Historial
              pw.Text('Desglose de Cobros:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                context: context,
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                headers: ['Pasajero', 'Hora', 'Monto Cobrado'],
                data: _historialCobros.map((cobro) => [
                  cobro['correo'],
                  cobro['hora'],
                  '\$${cobro['monto'].toStringAsFixed(2)}'
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(), 
      filename: 'corte_caja_${ahora.millisecondsSinceEpoch}.pdf'
    );
  }

  @override
  void dispose() {
    socket.disconnect(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Unidad: ${widget.usuario['correo']}', style: const TextStyle(color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xFF09155B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            tooltip: 'Ver Reporte',
            onPressed: _mostrarReporteTurno,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmar = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Cerrar Sesión'),
                  content: const Text('¿Cerrar el panel de cobro? Se perderá el historial visual del turno actual.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Salir', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirmar == true && context.mounted) {
                socket.disconnect();
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Radar Visual Superior 
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: _colorEstado, width: 4),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
            ),
            child: Column(
              children: [
                Icon(_iconoEstado, size: 80, color: _colorEstado),
                const SizedBox(height: 16),
                Text(
                  _estadoCobro,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _colorEstado),
                ),
              ],
            ),
          ),

          // 2. Encabezado de Bitácora
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Historial de Cobros', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF09155B))),
                Text('Total: \$${_gananciasTotales.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          const Divider(),

          // 3. Lista de transacciones
          Expanded(
            child: _historialCobros.isEmpty
                ? const Center(child: Text('Aún no hay pasajes cobrados', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _historialCobros.length,
                    itemBuilder: (context, index) {
                      final cobro = _historialCobros[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: ListTile(
                          leading: const Icon(Icons.directions_bus, color: Colors.green),
                          title: Text(cobro['correo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Hora: ${cobro['hora']}'),
                          trailing: Text('+\$${cobro['monto'].toStringAsFixed(2)}', 
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}