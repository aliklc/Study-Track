class GoalModel {
  final String id;
  final String userId;
  final String subject; // Örn: Matematik
  final int targetMinutes; // Örn: 60 dakika
  final int currentMinutes; // Şu ana kadar çalışılan (Sprint 5'te artacak)
  final String period; // 'Günlük' veya 'Haftalık'
  final DateTime createdAt;

  GoalModel({
    required this.id,
    required this.userId,
    required this.subject,
    required this.targetMinutes,
    this.currentMinutes = 0,
    this.period = 'Günlük',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'subject': subject,
      'targetMinutes': targetMinutes,
      'currentMinutes': currentMinutes,
      'period': period,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
    return GoalModel(
      id: map['id'],
      userId: map['userId'],
      subject: map['subject'],
      targetMinutes: map['targetMinutes'],
      currentMinutes: map['currentMinutes'] ?? 0,
      period: map['period'] ?? 'Günlük',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
