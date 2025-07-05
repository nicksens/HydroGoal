import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrogoal/utils/colors.dart';
import 'package:image_picker/image_picker.dart';

class HydrationProofScreen extends StatefulWidget {
  const HydrationProofScreen({super.key});

  @override
  State<HydrationProofScreen> createState() => _HydrationProofScreenState();
}

class _HydrationProofScreenState extends State<HydrationProofScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _amountController = TextEditingController();

  Future<void> _takePicture() async {
    final XFile? imageFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 50,
      maxWidth: 600,
    );

    if (imageFile != null) {
      setState(() {
        _image = File(imageFile.path);
      });
    }
  }

  void _showLogWaterDialog() {
    _amountController.text = "250";
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Great Job!'),
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
      appBar: AppBar(
        title: const Text('Hydration Proof'),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.lightBlue, width: 2),
                  borderRadius: BorderRadius.circular(16),
                  color: AppColors.white,
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_camera_outlined,
                              size: 80, color: AppColors.lightText),
                          SizedBox(height: 16),
                          Text('Take a picture of your water',
                              style: TextStyle(
                                  color: AppColors.lightText, fontSize: 16)),
                        ],
                      ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text(_image == null ? 'TAKE PICTURE' : 'RETAKE PICTURE'),
                onPressed: _takePicture,
              ),
              const SizedBox(height: 12),
              if (_image != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('CONFIRM & LOG WATER'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentAqua),
                  onPressed: _showLogWaterDialog,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
