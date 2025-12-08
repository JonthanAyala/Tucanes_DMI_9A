import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../viewmodels/paquete_viewmodel.dart';
import '../utils/app_theme.dart';

// Vista de escáner QR para validar entregas - Aserejex22
class QRScannerView extends StatefulWidget {
  final String paqueteId;
  final String codigoQREsperado;

  const QRScannerView({
    super.key,
    required this.paqueteId,
    required this.codigoQREsperado,
  });

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() {
      _isProcessing = true;
    });

    // Validar código QR
    if (code == widget.codigoQREsperado) {
      // Obtener ubicación actual
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition();
      } catch (e) {
        print('Error al obtener ubicación: $e');
      }

      final Map<String, dynamic>? ubicacion = position != null
          ? {
              'lat': position.latitude,
              'lng': position.longitude,
              'timestamp': DateTime.now().toIso8601String(),
            }
          : null;

      // Código correcto, actualizar estado a entregado
      final paqueteViewModel = context.read<PaqueteViewModel>();
      final success = await paqueteViewModel.actualizarEstado(
        widget.paqueteId,
        'entregado',
        ubicacion: ubicacion,
      );

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Entrega confirmada exitosamente!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } else {
      // Código incorrecto
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Código QR incorrecto'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear QR'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
            tooltip: 'Linterna',
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
            tooltip: 'Cambiar cámara',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cámara
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          // Overlay con marco
          CustomPaint(painter: ScannerOverlay(), child: Container()),

          // Instrucciones
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Apunta la cámara al código QR del paquete',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Código esperado: ${widget.codigoQREsperado}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Painter para el overlay del escáner
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
    );

    // Dibujar overlay oscuro
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(scanArea)
        ..fillType = PathFillType.evenOdd,
      paint,
    );

    // Dibujar marco del área de escaneo
    final borderPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRect(scanArea, borderPaint);

    // Dibujar esquinas
    final cornerPaint = Paint()
      ..color = AppTheme.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;

    final cornerLength = 30.0;

    // Esquina superior izquierda
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, cornerLength),
      cornerPaint,
    );

    // Esquina superior derecha
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, cornerLength),
      cornerPaint,
    );

    // Esquina inferior izquierda
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -cornerLength),
      cornerPaint,
    );

    // Esquina inferior derecha
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
