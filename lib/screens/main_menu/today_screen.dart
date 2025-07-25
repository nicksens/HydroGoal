// lib/screens/main_menu/today_screen.dart
// FINAL, CLEANED-UP VERSION

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrogoal/models/bottle_model.dart';
import 'package:hydrogoal/screens/hydration/hydration_proof_screen.dart';
import 'package:hydrogoal/screens/inventory/bottle_inventory_screen.dart';
import 'package:hydrogoal/screens/profile/profile_screen.dart';
import 'package:hydrogoal/services/firestore_service.dart';
import 'package:hydrogoal/services/notification_service.dart';
import 'package:hydrogoal/utils/colors.dart';
import 'package:hydrogoal/widgets/wave_clipper.dart'; // This is used
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  // --- Main State ---
  int _goal = 2000;
  int _currentIntake = 0;
  Bottle? _selectedBottle;

  // --- Drawer Calculator State ---
  double _weight = 70.0;
  double _age = 30.0;
  String _gender = 'male';
  double _activityLevel = 2.0;
  double _climateLevel = 2.0;
  int _recommendedGoal = 2000;

  // --- Reminder State ---
  int _reminderInterval = 60;
  bool _remindersActive = false;

  // --- Services & Controllers ---
  final NotificationService _notificationService = NotificationService();
  final FirestoreService _firestoreService = FirestoreService();
  final String? _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadData();
    _notificationService.initialize();
  }

  // --- Data Persistence ---
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _goal = prefs.getInt('goal') ?? 2000;
    _reminderInterval = prefs.getInt('reminderInterval') ?? 60;
    _remindersActive = prefs.getBool('remindersActive') ?? false;
    _weight = prefs.getDouble('user_weight') ?? 70.0;
    _age = prefs.getDouble('user_age') ?? 30.0;
    _gender = prefs.getString('user_gender') ?? 'male';
    _activityLevel = prefs.getDouble('user_activity') ?? 2.0;
    _climateLevel = prefs.getDouble('user_climate') ?? 2.0;


    if (_userId != null) {
      _currentIntake = await _firestoreService.getTodaysIntake(_userId!);
    }
    if (mounted) setState(() {});
  }

  Future<void> _updateGoal(int newGoal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('goal', newGoal);
    setState(() => _goal = newGoal);
  }

  Future<void> _saveUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('user_weight', _weight);
    await prefs.setDouble('user_age', _age);
    await prefs.setString('user_gender', _gender);
    await prefs.setDouble('user_activity', _activityLevel);
    await prefs.setDouble('user_climate', _climateLevel);
  }

  Future<void> _updateReminderSettings(int interval, bool isActive) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminderInterval', interval);
    await prefs.setBool('remindersActive', isActive);
    setState(() {
      _reminderInterval = interval;
      _remindersActive = isActive;
    });
  }

  // --- Logic Functions ---
  void _calculateRecommendedGoal() {
    final double weightMultiplier = (_gender == 'male') ? 35 : 31;
    double weightBasedIntake = _weight * weightMultiplier;
    double ageMultiplier;
    if (_age < 30) ageMultiplier = 1.0;
    else if (_age <= 55) ageMultiplier = 0.95;
    else ageMultiplier = 0.90;
    double ageAdjustedIntake = weightBasedIntake * ageMultiplier;
    double activityBonus = (_activityLevel - 1) * 250;
    double climateBonus = (_climateLevel - 1) * 200;
    double calculatedGoal = ageAdjustedIntake + activityBonus + climateBonus;
    setState(() {
      _recommendedGoal = (calculatedGoal / 50).round() * 50;
    });
  }

  // --- Logic ---
  Future<void> _toggleReminders(int interval, bool start) async {
    await _updateReminderSettings(interval, start);
    if (start) {
      final bool hasPermission = await _notificationService.requestPermissions();
      if (!hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permissions are required.')));
        await _updateReminderSettings(interval, false);
        return;
      }
      await _notificationService.scheduleRepeatingNotification(
          intervalMinutes: interval, title: '💧 Time to Hydrate!', body: "A quick reminder to drink some water.");
    } else {
      await _notificationService.cancelAllNotifications();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminders ${start ? 'are on' : 'are off'}.')));
    }
  }

  Future<void> _logWaterWithProof() async {
    if (_selectedBottle == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a bottle from your inventory first.'),
        backgroundColor: Colors.orangeAccent,
      ));
      return;
    }
    final amount = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (context) => HydrationProofScreen(
          totalBottleCapacity: _selectedBottle!.capacity,
        ),
      ),
    );
    if (amount != null && amount > 0 && _userId != null) {
      await _firestoreService.logWaterIntake(_userId!, amount);
      _loadData();
    }
  }

  void _showReminderSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        int tempInterval = _reminderInterval;
        bool tempRemindersActive = _remindersActive;

        // --- FIX IS HERE ---
        // 1. Define the list of valid options we are using.
        const validIntervals = [30, 60, 90, 120];

        // 2. Check if the currently saved interval is in our valid list.
        // If not, reset it to a default value (e.g., 60).
        if (!validIntervals.contains(tempInterval)) {
          tempInterval = 60;
        }
        // --- END OF FIX ---

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reminder Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: tempInterval,
                    // Use the list we defined above
                    items: validIntervals.map((interval) {
                      String label;
                      if (interval >= 60) {
                        label = '${interval ~/ 60} hour${interval > 60 ? 's' : ''}';
                      } else {
                        label = '$interval minutes';
                      }
                      if (interval == 90) label = '1.5 hours';
                      
                      return DropdownMenuItem(value: interval, child: Text(label));
                    }).toList(),
                    onChanged: (value) =>
                        setDialogState(() => tempInterval = value ?? 60),
                    decoration: const InputDecoration(labelText: 'Interval'),
                  ),
                  SwitchListTile(
                    title: const Text('Enable Reminders'),
                    value: tempRemindersActive,
                    onChanged: (value) =>
                        setDialogState(() => tempRemindersActive = value),
                    activeColor: AppColors.primaryBlue,
                  ),
                ],
              ),
              actions: [
                TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(ctx).pop()),
                ElevatedButton(
                    child: const Text('Save'),
                    onPressed: () async { // Make it async
                      final bool permissionsGranted =
                          await _notificationService.requestPermissions();
                      if (permissionsGranted && mounted) {
                        _toggleReminders(tempInterval, tempRemindersActive);
                        Navigator.of(ctx).pop();
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Permissions are required to set reminders.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }),
              ],
            );
          },
        );
      },
    );
  }

  // --- Build Methods ---
 @override
  Widget build(BuildContext context) {
    final double percent = _goal > 0 ? (_currentIntake / _goal) : 0;
    
    return Scaffold(
      // THE DRAWER IS NOW RESTORED
      drawer: _buildAppDrawer(), 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkText), // Ensures burger icon is visible
        title: const Text('Today', style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 28)),
        actions: [
          IconButton(
            icon: Icon(
              _remindersActive ? Icons.notifications_active : Icons.notifications_none_outlined,
              color: _remindersActive ? AppColors.primaryBlue : AppColors.darkText,
            ),
            onPressed: _showReminderSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.darkText),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ProfileScreen())),
          ),
        ],
      ),
      // THE BODY IS WRAPPED IN SingleChildScrollView TO PREVENT OVERFLOW
      body: SingleChildScrollView(
        child: Column(
          children: [
            // The main content area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  CircularPercentIndicator(
                    radius: 120.0,
                    lineWidth: 24.0,
                    percent: percent > 1.0 ? 1.0 : percent,
                    center: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.water_drop,
                            size: 40, color: AppColors.primaryBlue),
                        Text('$_currentIntake',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 48,
                                color: AppColors.darkText)),
                        Text('/ $_goal ml',
                            style: const TextStyle(
                                fontSize: 16, color: AppColors.lightText)),
                      ],
                    ),
                    circularStrokeCap: CircularStrokeCap.round,
                    progressColor: AppColors.primaryBlue,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    animation: true,
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 2,
                    shadowColor: AppColors.primaryBlue.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatColumn('Current', '$_currentIntake ml'),
                          _buildStatColumn('Goal', '$_goal ml'),
                          _buildStatColumn('Remaining',
                              '${_goal - _currentIntake > 0 ? _goal - _currentIntake : 0} ml'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('SELECT YOUR BOTTLE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.lightText)),
                  const SizedBox(height: 8),
                  _buildBottleSelector(),
                ],
              ),
            ),
            // The action button is now at the bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: _logWaterWithProof,
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Add Hydration Proof'),
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 50), // Make button wide
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration:
                BoxDecoration(color: AppColors.primaryBlue.withOpacity(0.8)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.calculate_outlined, color: Colors.white, size: 40),
                SizedBox(height: 8),
                Text('Goal Calculator',
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Text('Adjust your profile to get a recommended goal.',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          _buildSliderTile(
            label: 'Weight',
            value: _weight,
            min: 30,
            max: 150,
            divisions: 120,
            displayValue: '${_weight.round()} kg',
            onChanged: (newValue) {
              setState(() => _weight = newValue);
              _calculateRecommendedGoal();
            },
            onChangedEnd: (value) => _saveUserSettings(),
          ),
          _buildSliderTile(
            label: 'Age',
            value: _age,
            min: 14,
            max: 80,
            divisions: 66,
            displayValue: '${_age.round()} years',
            onChanged: (newValue) {
              setState(() => _age = newValue);
              _calculateRecommendedGoal();
            },
            onChangedEnd: (value) => _saveUserSettings(),
          ),
          _buildGenderSelector(),
          _buildSliderTile(
            label: 'Daily Activity',
            value: _activityLevel,
            min: 1,
            max: 5,
            divisions: 4,
            displayValue: [
              'Sedentary', 'Light', 'Moderate', 'Active', 'Very Active'
            ][_activityLevel.round() - 1],
            onChanged: (newValue) {
              setState(() => _activityLevel = newValue);
              _calculateRecommendedGoal();
            },
            onChangedEnd: (value) => _saveUserSettings(),
          ),
          _buildSliderTile(
            label: 'Climate',
            value: _climateLevel,
            min: 1,
            max: 5,
            divisions: 4,
            displayValue: [
              'Cold', 'Cool', 'Temperate', 'Warm', 'Hot'
            ][_climateLevel.round() - 1],
            onChanged: (newValue) {
              setState(() => _climateLevel = newValue);
              _calculateRecommendedGoal();
            },
            onChangedEnd: (value) => _saveUserSettings(),
          ),
          const Divider(height: 40, thickness: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const Text('Recommended Goal:',
                    style: TextStyle(fontSize: 16, color: AppColors.lightText)),
                Text('${_recommendedGoal} ml',
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    _updateGoal(_recommendedGoal);
                    Navigator.pop(context); // Close the drawer
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            'Daily goal updated to $_recommendedGoal ml!')));
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Apply as My Goal'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangedEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 16)),
              Text(displayValue,
                  style: const TextStyle(
                      color: AppColors.lightText, fontSize: 16)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: value.round().toString(),
            activeColor: AppColors.primaryBlue,
            inactiveColor: AppColors.lightBlue,
            onChanged: onChanged,
            onChangeEnd: onChangedEnd,
          ),
        ],
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gender',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  label: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.male, size: 20),
                        SizedBox(width: 8),
                        Flexible(child: Text('Male')),
                      ]),
                  selected: _gender == 'male',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _gender = 'male');
                      _calculateRecommendedGoal();
                      _saveUserSettings();
                    }
                  },
                  selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                  label: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.female, size: 20),
                        SizedBox(width: 8),
                        Flexible(child: Text('Female')),
                      ]),
                  selected: _gender == 'female',
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _gender = 'female');
                      _calculateRecommendedGoal();
                      _saveUserSettings();
                    }
                  },
                  selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottleSelector() {
    if (_userId == null) return const SizedBox.shrink();

    // The main Column now has padding to match the Card's margin
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        children: [
          TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const BottleInventoryScreen())),
            child: const Text('Manage My Bottles'),
          ),
          const SizedBox(height: 8),

          // This SizedBox constrains the height of the scrollable area
          SizedBox(
            height: 80,
            child: StreamBuilder<List<Bottle>>(
              stream: _firestoreService.getBottles(_userId!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) =>
                                  const BottleInventoryScreen())),
                      child: const Text('Add Your First Bottle'),
                    ),
                  );
                }
                final bottles = snapshot.data!;

                if (_selectedBottle == null ||
                    !bottles.contains(_selectedBottle)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _selectedBottle = bottles.first;
                      });
                    }
                  });
                }

                // We use a SingleChildScrollView with a Row to achieve centering
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  // The Row's properties allow for centering
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: bottles.map((bottle) {
                      final isSelected = bottle.id == _selectedBottle?.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedBottle = bottle;
                          });
                        },
                        child: Container(
                          width: 120,
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryBlue.withOpacity(0.1)
                                : Colors.white,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(bottle.name,
                                  overflow: TextOverflow.ellipsis),
                              Text('${bottle.capacity} ml',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(color: AppColors.lightText, fontSize: 16)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: AppColors.darkText,
                fontSize: 20,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}