import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:async';
import 'dart:ui';
import '../offline/offline_inference.dart';
import 'api_client.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  DetectionResult? _currentResult;
  bool _isFlashOn = false;
  
  Timer? _scanTimer;

  @override
  void initState() {
    super.initState();
    _initializeCameraAndModels();
  }

  Future<void> _initializeCameraAndModels() async {
    // 1. Initialize camera
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      debugPrint("No cameras available.");
      return;
    }

    // Try to pick the first back camera
    final backCamera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      backCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.off);
      if (!mounted) return;

      // Start scanning every 1 second — _isProcessing guard prevents overlapping requests
      _scanTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!_isProcessing) {
          _captureAndDetect();
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _captureAndDetect() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    _isProcessing = true;
    try {
       final xFile = await _controller!.takePicture();
       final bytes = await xFile.readAsBytes();
       
       final result = await ApiClient.detectDisease(bytes);
       
       if (mounted) {
           setState(() {
               if (result != null && result.confidence > 0.40) {
                  _currentResult = result;
               } else {
                  _currentResult = null;
               }
           });
       }
    } catch (e) {
       debugPrint('Error capturing frame: $e');
    } finally {
       if (mounted) {
           _isProcessing = false;
       }
    }
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plant Disease Scanner'),
        backgroundColor: Colors.green.shade700,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
                _controller?.setFlashMode(
                  _isFlashOn ? FlashMode.torch : FlashMode.off,
                );
              });
            },
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Preview
          CameraPreview(_controller!),

          // Overlay for results
          if (_currentResult != null)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildResultCard(),
            )
          else
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: _buildWaitingCard(),
            ),
            
          // Target reticle
          Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: _isProcessing ? 1.1 : 1.0),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutBack,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isProcessing ? Colors.yellowAccent : Colors.greenAccent, 
                        width: _isProcessing ? 4 : 2
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: _isProcessing ? [
                        BoxShadow(color: Colors.yellowAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
                      ] : [],
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    bool isHealthy = _currentResult!.disease.toLowerCase() == 'healthy';
    Color statusColor = isHealthy ? const Color(0xFF4CAF50) : const Color(0xFFE53935);
    Color statusBg = isHealthy ? const Color(0xFF1B5E20) : const Color(0xFF7F0000);
    IconData statusIcon = isHealthy ? Icons.check_circle_rounded : Icons.coronavirus_rounded;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.75),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: statusColor.withOpacity(0.5), width: 1.5),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Crop row
              Row(
                children: [
                  const Icon(Icons.eco_rounded, color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "CROP: ${_currentResult!.crop.toUpperCase()}",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.greenAccent,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Disease — the biggest, most prominent element
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: statusBg.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHealthy ? "HEALTHY" : "DISEASE DETECTED",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentResult!.disease,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Solution
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
                        SizedBox(width: 6),
                        Text(
                          "RECOMMENDATION",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentResult!.solution,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _isProcessing 
                ? const SizedBox(
                    width: 20, height: 20, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.yellowAccent)
                  )
                : const Icon(Icons.camera_alt, color: Colors.white70),
              const SizedBox(width: 12),
              Text(
                _isProcessing ? "AI is analyzing leaf..." : "Point camera clearly at a leaf...",
                style: TextStyle(
                  fontSize: 16,
                  color: _isProcessing ? Colors.yellowAccent : Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
