import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../offline/offline_inference.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isProcessing = false;
  DetectionResult? _currentResult;
  final OfflineInference _inference = OfflineInference();
  
  // Production Temporal Smoothing: Requires 4 out of last 5 frames to agree
  final List<DetectionResult?> _predictionHistory = [];
  static const int _historySize = 5;
  static const int _consensusThreshold = 4;
  
  // Throttle to ~6.5 FPS (150ms) for fast consensus building
  DateTime _lastFrameTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _initializeCameraAndModels();
  }

  Future<void> _initializeCameraAndModels() async {
    // 1. Initialize models
    await _inference.initializeModels();

    // 2. Initialize camera
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
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;

      _controller!.startImageStream((CameraImage image) {
        if (!_isProcessing) {
          _processCameraFrame(image);
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _processCameraFrame(CameraImage image) async {
    final now = DateTime.now();
    if (now.difference(_lastFrameTime).inMilliseconds < 150) {
      return; // Skip frame to maintain ~6.5 fps
    }
    _lastFrameTime = now;
    
    _isProcessing = true;

    try {
      final result = await _inference.processFrame(image);
     
      if (mounted) {
        setState(() {
          // 1. Add current frame result to rolling history (null if confidence is low)
          if (result != null && result.confidence > 0.70) {
            _predictionHistory.add(result);
          } else {
            _predictionHistory.add(null);
          }
          
          // 2. Keep queue size strictly at limit
          if (_predictionHistory.length > _historySize) {
            _predictionHistory.removeAt(0);
          }

          // 3. Count occurrences of each disease in recent memory
          final diseaseCounts = <String, int>{};
          for (var r in _predictionHistory) {
            if (r != null) {
              diseaseCounts[r.disease] = (diseaseCounts[r.disease] ?? 0) + 1;
            }
          }

          // 4. Check if any disease has achieved consensus
          String? consensusDisease;
          for (var entry in diseaseCounts.entries) {
            if (entry.value >= _consensusThreshold) {
              consensusDisease = entry.key;
              break;
            }
          }

          // 5. Update UI based on consensus
          if (consensusDisease != null) {
             // Consensus reached! Lock it into the UI with the highest confidence read
             _currentResult = _predictionHistory
                .where((r) => r != null && r.disease == consensusDisease)
                .reduce((a, b) => a!.confidence > b!.confidence ? a : b);
          } else {
             // No consensus - user is likely panning or looking at background noise
             _currentResult = null;
          }
        });
      }
    } catch (e) {
      debugPrint('Error processing frame: $e');
    } finally {
      if (mounted) {
        _isProcessing = false;
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _inference.dispose();
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
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Crop: ${_currentResult!.crop.toUpperCase()}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _currentResult!.disease == 'Healthy'
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${(_currentResult!.confidence * 100).toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: _currentResult!.disease == 'Healthy'
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Status: ${_currentResult!.disease}",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _currentResult!.disease == 'Healthy'
                    ? Colors.green.shade700
                    : Colors.red.shade700,
              ),
            ),
            const Divider(),
            const Text(
              "Recommended Solution:",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              _currentResult!.solution,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      );
  }

  Widget _buildWaitingCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, color: Colors.white70),
          SizedBox(width: 12),
          Text(
            "Point camera clearly at a leaf...",
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
