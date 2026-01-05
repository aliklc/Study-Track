import 'dart:async';
import 'package:flutter/material.dart';
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

  void _resetTimer() {
    setState(() {
      _isActive = false;
      _seconds = 0;
    });
    _timer?.cancel();
  }

  // GÜNCELLENDİ: Hem manuel süreyi hem de manuel ders adını alabiliyor
  void _finishSession({int? manualMinutes, String? manualSubject}) async {
    _timer?.cancel();

    // Eğer manuel giriş değilse ve sayaç 1 dakikadan azsa kaydetme
    if (manualMinutes == null && _seconds < 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Süre çok kısa, kaydedilmedi.")),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Manuel dakika geldiyse onu kullan, yoksa sayacı dakikaya çevir
      final int minutes = manualMinutes ?? (_seconds / 60).ceil();

      // Manuel konu adı geldiyse onu kullan, yoksa hedefin adını kullan
      final String subjectName = manualSubject ?? widget.goal.subject;

      final session = SessionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: widget.goal.userId,
        goalId: widget.goal.id,
        subject: subjectName, // Güncellenen kısım
        durationMinutes: minutes,
        date: DateTime.now(),
      );

      await _dbService.saveSession(session);

      if (mounted) {
        Navigator.pop(context); // Dashboard'a dön
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Tebrikler! $subjectName için $minutes dakika kaydedildi.",
            ),
          ),
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

  // GÜNCELLENDİ: Hem Ders Adı hem Süre soran pencere
  void _showManualEntryDialog() {
    final minuteController = TextEditingController();
    // Varsayılan olarak hedefin adını (örn: Matematik) getiriyoruz
    final subjectController = TextEditingController(text: widget.goal.subject);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Manuel Çalışma Ekle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Zamanlayıcıyı kullanmadan çalışma eklemek üzeresiniz.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // Ders Adı Girişi
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                labelText: "Ders / Konu",
                hintText: "Örn: Matematik - Türev",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.book),
              ),
            ),
            const SizedBox(height: 16),

            // Süre Girişi
            TextField(
              controller: minuteController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Süre (Dakika)",
                hintText: "Örn: 45",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6C63FF),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final min = int.tryParse(minuteController.text);
              final sub = subjectController.text.trim();

              if (min != null && min > 0 && sub.isNotEmpty) {
                Navigator.pop(context); // Dialogu kapat
                // Verileri kaydetme fonksiyonuna gönder
                _finishSession(manualMinutes: min, manualSubject: sub);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Lütfen geçerli bir süre ve ders adı giriniz.",
                    ),
                  ),
                );
              }
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.goal.subject} Çalışılıyor"),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8.0,
              horizontal: 12.0,
            ),
            child: SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.zero,
                ),
                onPressed: _isActive ? null : _showManualEntryDialog,
                child: const Icon(Icons.edit_note, size: 28),
              ),
            ),
          ),
        ],
      ),
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
              Column(
                children: [
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

                      // Bitir Butonu
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                        ),
                        onPressed: _seconds > 0 ? () => _finishSession() : null,
                        icon: const Icon(Icons.stop),
                        label: const Text("Bitir"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Sıfırla Butonu
                  TextButton.icon(
                    onPressed: _seconds > 0 ? _resetTimer : null,
                    icon: const Icon(Icons.refresh),
                    label: const Text("Sayacı Sıfırla"),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
