// lib/screens/inventory/bottle_inventory_screen.dart
// (This is a complete, new screen)

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hydrogoal/models/bottle_model.dart';
import 'package:hydrogoal/services/firestore_service.dart';

class BottleInventoryScreen extends StatefulWidget {
  const BottleInventoryScreen({super.key});

  @override
  State<BottleInventoryScreen> createState() => _BottleInventoryScreenState();
}

class _BottleInventoryScreenState extends State<BottleInventoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  void _showAddBottleDialog() {
    final nameController = TextEditingController();
    final capacityController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Bottle'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Bottle Name (e.g., Blue Tumbler)'),
                validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: capacityController,
                decoration: const InputDecoration(labelText: 'Capacity (ml)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return 'Please enter capacity';
                  if (int.tryParse(value) == null) return 'Enter a valid number';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                if (_userId != null) {
                  _firestoreService.addBottle(
                    _userId!,
                    nameController.text,
                    int.parse(capacityController.text),
                  );
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Bottles')),
      body: _userId == null
          ? const Center(child: Text('Please log in to see your bottles.'))
          : StreamBuilder<List<Bottle>>(
              stream: _firestoreService.getBottles(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No bottles saved yet. Add one!'));
                }

                final bottles = snapshot.data!;

                return ListView.builder(
                  itemCount: bottles.length,
                  itemBuilder: (context, index) {
                    final bottle = bottles[index];
                    return ListTile(
                      title: Text(bottle.name),
                      subtitle: Text('${bottle.capacity} ml'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _firestoreService.deleteBottle(_userId!, bottle.id),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddBottleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Bottle'),
      ),
    );
  }
}