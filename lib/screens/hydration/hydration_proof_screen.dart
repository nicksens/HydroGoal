import 'dart:io'; // IMPORTANT: Used for Platform detection
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrogoal/utils/colors.dart';
import 'package:image_picker/image_picker.dart'; // We need this again for mobile
import 'package:hydrogoal/services/ai_services.dart';

class HydrationProofScreen extends StatefulWidget {
  // 1. Add this final variable to hold the passed-in capacity
  final int totalBottleCapacity;

  // 2. Correct the constructor to use the new variable
  const HydrationProofScreen({super.key, required this.totalBottleCapacity});

  @override
  State<HydrationProofScreen> createState() => _HydrationProofScreenState();
}

class _HydrationProofScreenState extends State<HydrationProofScreen> {
  final AiService _aiService = AiService();
  // Controllers for BOTH packages
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  
  File? _image;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _totalCapacityController = TextEditingController();
  
  bool _isLoadingAi = false;
  // New state variables for the two-step AI process
  bool _isVerifyingImage = false;     // True while checking if it's a bottle
  bool _isAnalyzingConsumption = false; // True while analyzing consumption
  bool? _isWaterContainer;            // Stores the result of the verification

  // Helper to check the platform
  bool get isDesktop => Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  void initState() {
    super.initState();
    // ONLY initialize the camera controller if we are on a desktop platform
    if (isDesktop) {
      _initializeCamera();
    }
    _totalCapacityController.text = widget.totalBottleCapacity.toString();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _cameraController = CameraController(firstCamera, ResolutionPreset.medium);
    _initializeControllerFuture = _cameraController!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // A single function to handle taking a picture on any platform
  Future<void> _captureImage() async {
    XFile? imageFile;

    if (isDesktop) {
      // Desktop logic using the 'camera' package
      await _initializeControllerFuture;
      try {
        imageFile = await _cameraController!.takePicture();
      } catch (e) {
        print('Error taking picture on desktop: $e');
      }
    } else {
      // Mobile logic using the 'image_picker' package
      try {
        imageFile = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 50,
          maxWidth: 600,
        );
      } catch (e) {
        print('Error picking image on mobile: $e');
      }
    }

    // Common logic to handle the result
    if (imageFile != null) {
      setState(() {
        _image = File(imageFile!.path);
        _isWaterContainer = null;
      });
      _verifyImageContent();
    }
  }

  Future<void> _verifyImageContent() async {
    if (_image == null) return;
    setState(() { _isVerifyingImage = true; });

    final result = await _aiService.isWaterContainer(_image!);

    setState(() {
      _isWaterContainer = result;
      _isVerifyingImage = false;
    });
  }

  void _retakePicture() {
    setState(() {
      _image = null;
      _isWaterContainer = null;
    });
  }

  Future<void> _analyzeConsumptionWithAi() async {
    if (_image == null) return;
    final totalCapacity = int.tryParse(_totalCapacityController.text);
    if (totalCapacity == null || totalCapacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a valid total capacity for your bottle.'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() { _isLoadingAi = true; });

    final result = await _aiService.analyzeWaterConsumption(_image!, totalCapacity);
    
    setState(() { _isLoadingAi = false; });

    if (result != null) {
      _amountController.text = result.toString();
      _showLogWaterDialog();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('AI analysis failed. Please try again or enter manually.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  void _showLogWaterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_isLoadingAi ? 'Analyzing...' : 'Confirm Amount'),
        content: TextFormField(
          controller: _amountController,
          autofocus: true,
          decoration:
              const InputDecoration(labelText: 'How much did you drink? (ml)'),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(ctx).pop()),
          ElevatedButton(
              child: const Text('Log'),
              onPressed: () {
                final amount = int.tryParse(_amountController.text) ?? 0;
                // Pop twice: once for the dialog, once for the screen, returning the amount.
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(amount);
              }),
        ],
      ),
    );
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hydration Proof')),
      body: Stack( // Use a Stack to overlay the loading indicator
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: isDesktop ? 400 : 300, // Make preview taller on desktop
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.lightBlue, width: 2),
                      borderRadius: BorderRadius.circular(16),
                      color: AppColors.white,
                    ),
                    child: _buildCameraOrImagePreview(),
                  ),
                  const SizedBox(height: 20),
                  // --- NEW UI ELEMENTS ---
                  _buildButtonsAndCapacityField(),
                ],
              ),
            ),
          ),
          // --- LOADING INDICATOR ---
          if (_isVerifyingImage || _isAnalyzingConsumption)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isVerifyingImage ? 'Checking image content...' : 'Analyzing consumption...',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }

  // Helper widget to decide what to show in the preview area
  Widget _buildCameraOrImagePreview() {
    if (_image != null) {
      // If an image has been taken, always display it.
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.file(_image!, fit: BoxFit.cover),
      );
    }
    
    // If no image, show the appropriate camera UI
    if (isDesktop) {
      // On desktop, show the live camera preview
      return FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(14.0),
              child: CameraPreview(_cameraController!),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      );
    } else {
      // On mobile, show the placeholder icon
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_camera_outlined, size: 80, color: AppColors.lightText),
          SizedBox(height: 16),
          Text('Take a picture of your water',
              style: TextStyle(color: AppColors.lightText, fontSize: 16)),
        ],
      );
    }
  }

  // Helper widget to decide which buttons to show
  Widget _buildButtonsAndCapacityField() {
    // Case 1: No image has been taken yet
    if (_image == null) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.camera_alt),
        label: const Text('TAKE PICTURE'),
        onPressed: _captureImage,
      );
    }
    
    // Case 2: Image is taken, but AI verification is not complete yet (_isWaterContainer is null)
    // We don't show any buttons here while verifying, as the loader is visible.
    if (_isWaterContainer == null) {
      return const SizedBox(height: 56); // Placeholder for button height
    }

    // Case 3: AI verified it IS a water container
    if (_isWaterContainer == true) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _totalCapacityController,
            decoration: const InputDecoration(
              labelText: 'Total Bottle Capacity (ml)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.biotech),
            label: const Text('ANALYZE WITH AI'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentAqua),
            onPressed: _analyzeConsumptionWithAi,
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retake Picture'),
            onPressed: _retakePicture,
          ),
        ],
      );
    } 
    
    // Case 4: AI verified it is NOT a water container
    else {
      return Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 40),
          const SizedBox(height: 8),
          const Text(
            "This doesn't look like a water container. Please try again.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
            onPressed: _retakePicture,
          ),
        ],
      );
    }
  }
}