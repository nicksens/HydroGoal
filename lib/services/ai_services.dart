// lib/services/ai_service.dart
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  Future<bool> isWaterContainer(File image) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) throw Exception('API Key not found.');

      final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: apiKey);
      final imageBytes = await image.readAsBytes();

      final prompt = [
        Content.multi([
          TextPart(
              'Analyze this image. Is the primary object a water bottle, glass, or tumbler meant for drinking? Respond with only the word "yes" or "no".'),
          DataPart('image/jpeg', imageBytes)
        ])
      ];

      final response = await model.generateContent(prompt);
      // Return true if the AI's response is 'yes', otherwise false.
      return response.text?.toLowerCase().trim() == 'yes';
    } catch (e) {
      print('Error verifying image: $e');
      return false; // Assume it's not a container if an error occurs.
    }
  }

  Future<int?> analyzeWaterConsumption(
      File image, int totalCapacityMl) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) {
        print('API Key not found.');
        return null;
      }

      // Use the Gemini 1.5 Flash model for speed and cost-effectiveness
      final model = GenerativeModel(
        model: 'gemini-1.5-flash-latest',
        apiKey: apiKey,
      );

      // Read the image file as bytes
      final imageBytes = await image.readAsBytes();

      // Create the prompt with the image and the text instruction
      final prompt = [
        Content.multi([
          TextPart(
            'Analyze the provided image of a water container. '
            'The total capacity of this container is $totalCapacityMl ml. '
            'Based on the current water level, please estimate the volume of water that has been consumed in milliliters. '
            'Respond with only a single integer number representing the milliliters consumed.'
          ),
          DataPart('image/jpeg', imageBytes)
        ])
      ];

      final response = await model.generateContent(prompt);

      // Clean up the response and try to parse it as a number
      final cleanedText = response.text?.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanedText != null && cleanedText.isNotEmpty) {
        return int.tryParse(cleanedText);
      }
    } catch (e) {
      print('Error analyzing image with AI: $e');
    }
    return null; // Return null if anything goes wrong
  }
}