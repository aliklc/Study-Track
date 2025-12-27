import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/goal_model.dart';
import '../models/session_model.dart';
import '../services/database_service.dart';
import '../utils/time_utils.dart';

class TimerScreen extends StatefulWidget {
  final GoalModel goal;

  const TimerScreen({super.key, required this.goal});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  Timer? _timer;
  int _seconds = 0;
  bool _isActive = false;
  final DatabaseService _dbService = DatabaseService();
  bool _isSaving = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _isActive = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _pauseTimer() {
    setState(() => _isActive = false);
    _timer?.cancel();
  }

  void _finishSession() async {
    _timer?.cancel();
    if (_seconds < 60) {
      // 1 dakikadan azsa kaydetmeyelim
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Süre çok kısa, kaydedilmedi.")),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final int minutes = (_seconds / 60).ceil(); // Yukarı yuvarla

      final session = SessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.goal.userId,
        goalId: widget.goal.id,
        subject: widget.goal.subject,
        durationMinutes: minutes,
        date: DateTime.now(),
      );

      await _dbService.saveSession(session);

      if (mounted) {
        Navigator.pop(context); // Dashboard'a dön
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Tebrikler! $minutes dakika çalıştın.")),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Hata: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.goal.subject} Çalışılıyor")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sayaç Görünümü
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 250,
                  height: 250,
                  child: CircularProgressIndicator(
                    value: _isActive ? null : 1.0, // Çalışırken dönsün
                    strokeWidth: 10,
                    color: const Color(0xFF6C63FF),
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
                Text(
                  TimeUtils.formatTime(_seconds),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Kontrol Butonları
            if (_isSaving)
              const CircularProgressIndicator()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isActive)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      onPressed: _startTimer,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(_seconds == 0 ? "Başlat" : "Devam Et"),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 15,
                        ),
                      ),
                      onPressed: _pauseTimer,
                      icon: const Icon(Icons.pause),
                      label: const Text("Duraklat"),
                    ),

                  const SizedBox(width: 20),

                  // Bitir Butonu (Sadece süre varsa aktif olsun)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    onPressed: _seconds > 0 ? _finishSession : null,
                    icon: const Icon(Icons.stop),
                    label: const Text("Bitir"),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
