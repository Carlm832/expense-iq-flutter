import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isReady = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) return;

    _controller = CameraController(
      _cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() => _isReady = true);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isCapturing) {
      return;
    }

    setState(() => _isCapturing = true);

    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.pop(context, image);
    } catch (e) {
      debugPrint('Error taking picture: $e');
      setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // Viewfinder Overlay
          _buildOverlay(),

          // Back Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Shutter Button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _takePicture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: _isCapturing
                          ? const Center(
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: AppColors.primary)))
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 130,
            left: 0,
            right: 0,
            child: Text(
              'Align receipt within the frame',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [const Shadow(blurRadius: 10, color: Colors.black)],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: const ShapeDecoration(
        shape: _ViewfinderShape(
          borderRadius: 20,
          innerSize: Size(280, 450),
        ),
      ),
    );
  }
}

class _ViewfinderShape extends ShapeBorder {
  final double borderRadius;
  final Size innerSize;

  const _ViewfinderShape({required this.borderRadius, required this.innerSize});

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => Path();

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final outerPath = Path()..addRect(rect);
    final innerRect = Rect.fromCenter(
      center: rect.center,
      width: innerSize.width,
      height: innerSize.height,
    );
    final innerPath = Path()
      ..addRRect(
          RRect.fromRectAndRadius(innerRect, Radius.circular(borderRadius)));
    return Path.combine(PathOperation.difference, outerPath, innerPath);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawPath(getOuterPath(rect), paint);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final innerRect = Rect.fromCenter(
      center: rect.center,
      width: innerSize.width,
      height: innerSize.height,
    );
    canvas.drawRRect(
        RRect.fromRectAndRadius(innerRect, Radius.circular(borderRadius)),
        borderPaint);
  }

  @override
  ShapeBorder scale(double t) => this;
}
