import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/goal_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _subjectController = TextEditingController();
  final _minutesController = TextEditingController();
  final DatabaseService _dbService = DatabaseService();
  String _selectedPeriod = 'Günlük';
  bool _isLoading = false;

  void _addGoal() async {
    if (_subjectController.text.isEmpty || _minutesController.text.isEmpty)
      return;

    setState(() => _isLoading = true);

    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final goalId = DateTime.now().millisecondsSinceEpoch.toString();

      final newGoal = GoalModel(
        id: goalId,
        userId: user.uid,
        subject: _subjectController.text.trim(),
        targetMinutes: int.parse(_minutesController.text.trim()),
        period: _selectedPeriod,
        createdAt: DateTime.now(),
      );

      await _dbService.addGoal(newGoal);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Yeni Hedef Ekle")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: "Ders Adı (Örn: Matematik)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _minutesController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Hedef Süre (Dakika)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedPeriod,
              items: ['Günlük', 'Haftalık'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPeriod = newValue!;
                });
              },
              decoration: const InputDecoration(
                labelText: "Periyot",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.white,
                ),
                onPressed: _isLoading ? null : _addGoal,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Hedefi Kaydet"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
