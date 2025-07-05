// lib/models/bottle_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart'; // We'll use this for easier comparison

// Use Equatable to handle object comparison for us automatically
class Bottle extends Equatable {
  final String id;
  final String name;
  final int capacity; // in milliliters

  const Bottle({required this.id, required this.name, required this.capacity});

  // From Firestore document to Bottle object
  factory Bottle.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Bottle(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Bottle',
      capacity: data['capacity'] ?? 500,
    );
  }

  // From Bottle object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'capacity': capacity,
    };
  }

  // This tells Equatable which properties to use for comparison.
  // Two bottles are now the same if they have the same id.
  @override
  List<Object?> get props => [id];
}