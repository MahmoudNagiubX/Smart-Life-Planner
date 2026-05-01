class StudyPlanDay {
  final String date;
  final String topic;
  final String title;
  final int studyMinutes;
  final int practiceMinutes;
  final bool revision;
  final String priority;

  const StudyPlanDay({
    required this.date,
    required this.topic,
    required this.title,
    required this.studyMinutes,
    required this.practiceMinutes,
    required this.revision,
    required this.priority,
  });

  factory StudyPlanDay.fromJson(Map<String, dynamic> json) {
    return StudyPlanDay(
      date: json['date'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      title: json['title'] as String? ?? '',
      studyMinutes: json['study_minutes'] as int? ?? 30,
      practiceMinutes: json['practice_minutes'] as int? ?? 15,
      revision: json['revision'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'medium',
    );
  }

  int get totalMinutes => studyMinutes + practiceMinutes;

  StudyPlanDay copyWith({String? title}) {
    return StudyPlanDay(
      date: date,
      topic: topic,
      title: title ?? this.title,
      studyMinutes: studyMinutes,
      practiceMinutes: practiceMinutes,
      revision: revision,
      priority: priority,
    );
  }
}

class StudyPlanResult {
  final String subject;
  final String examDate;
  final List<StudyPlanDay> dailyPlan;
  final String confidence;
  final bool overloadWarning;
  final bool requiresConfirmation;

  const StudyPlanResult({
    required this.subject,
    required this.examDate,
    required this.dailyPlan,
    required this.confidence,
    required this.overloadWarning,
    required this.requiresConfirmation,
  });

  factory StudyPlanResult.fromJson(Map<String, dynamic> json) {
    return StudyPlanResult(
      subject: json['subject'] as String? ?? '',
      examDate: json['exam_date'] as String? ?? '',
      dailyPlan: (json['daily_plan'] as List<dynamic>? ?? const [])
          .map((item) => StudyPlanDay.fromJson(item as Map<String, dynamic>))
          .toList(),
      confidence: json['confidence'] as String? ?? 'low',
      overloadWarning: json['overload_warning'] as bool? ?? false,
      requiresConfirmation: json['requires_confirmation'] as bool? ?? true,
    );
  }
}
