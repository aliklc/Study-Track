import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; // Gün isimleri için
import 'package:provider/provider.dart';
import '../models/session_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = true;

  // Grafik için veriler: Hangi gün kaç dakika?
  Map<int, int> _dailyTotals = {};
  // Liste için veriler: Hangi ders toplam kaç dakika?
  Map<String, int> _subjectTotals = {};

  // Haftanın günleri (Grafik altındaki yazılar için)
  List<DateTime> _last7Days = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final user = context.read<AuthService>().currentUser;
    if (user == null) return;

    // 1. Son 7 günün tarihlerini hazırla
    final now = DateTime.now();
    _last7Days = List.generate(7, (index) {
      return now.subtract(Duration(days: 6 - index)); // Bugünden geriye 6 gün
    });

    // 2. Verileri çek
    final sessions = await _dbService.getLast7DaysSessions(user.uid);

    // 3. Verileri işle (Grupla)
    Map<int, int> tempDaily = {};
    Map<String, int> tempSubject = {};

    for (var session in sessions) {
      // Günlük Toplam Hesaplama (Key: Ayın günü, Value: Dakika)
      final day = session.date.day;
      tempDaily[day] = (tempDaily[day] ?? 0) + session.durationMinutes;

      // Ders Bazlı Toplam Hesaplama
      tempSubject[session.subject] =
          (tempSubject[session.subject] ?? 0) + session.durationMinutes;
    }

    setState(() {
      _dailyTotals = tempDaily;
      _subjectTotals = tempSubject;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Haftalık İstatistikler")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // --- GRAFİK ALANI ---
                  const Text(
                    "Son 7 Günlük Çalışma (dk)",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200, // Grafiğin yüksekliği
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY:
                            200, // Grafiğin tavan değeri (ihtiyaca göre artırılabilir)
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (double value, TitleMeta meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= _last7Days.length)
                                  return const Text('');
                                // Tarihi alıp gün ismine çevir (Örn: 'Pt')
                                final date = _last7Days[index];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat(
                                      'E',
                                      'tr',
                                    ).format(date), // intl paketi gerekli
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ), // Sol sayıları gizle
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        barGroups: _last7Days.asMap().entries.map((entry) {
                          final index = entry.key;
                          final date = entry.value;
                          final minutes = _dailyTotals[date.day] ?? 0;

                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: minutes.toDouble(),
                                color: const Color(0xFF6C63FF),
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Divider(),
                  const SizedBox(height: 10),

                  // --- DERS LİSTESİ ---
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Ders Bazlı Toplamlar",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: _subjectTotals.isEmpty
                        ? const Center(child: Text("Henüz veri yok."))
                        : ListView.builder(
                            itemCount: _subjectTotals.length,
                            itemBuilder: (context, index) {
                              final subject = _subjectTotals.keys.elementAt(
                                index,
                              );
                              final minutes = _subjectTotals[subject];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(
                                      0xFF6C63FF,
                                    ).withOpacity(0.2),
                                    child: const Icon(
                                      Icons.book,
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                  title: Text(subject),
                                  trailing: Text(
                                    "$minutes dk",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
