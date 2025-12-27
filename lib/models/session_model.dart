class SessionModel {
  final String id;
  final String userId;
  final String goalId; // Hangi hedefe ait olduğu
  final String subject; // Ders adı (Matematik vs.)
  final int durationMinutes; // Kaç dakika sürdüğü
  final DateTime date; // Ne zaman yapıldığı

  SessionModel({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.subject,
    required this.durationMinutes,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'goalId': goalId,
      'subject': subject,
      'durationMinutes': durationMinutes,
      'date': date.toIso8601String(),
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'],
      userId: map['userId'],
      goalId: map['goalId'],
      subject: map['subject'],
      durationMinutes: map['durationMinutes'],
      date: DateTime.parse(map['date']),
    );
  }
}
