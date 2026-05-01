class ContextIntelligenceSnapshot {
  final String id;
  final DateTime? timestamp;
  final String timezone;
  final String energyLevel;
  final String locationContext;
  final String deviceContext;
  final String timeContext;
  final String weatherContext;

  const ContextIntelligenceSnapshot({
    this.id = '',
    this.timestamp,
    this.timezone = 'UTC',
    this.energyLevel = 'medium',
    this.locationContext = 'Not set',
    this.deviceContext = 'Not set',
    this.timeContext = 'night',
    this.weatherContext = 'Not set',
  });

  factory ContextIntelligenceSnapshot.fromJson(Map<String, dynamic> json) {
    return ContextIntelligenceSnapshot(
      id: json['id'] as String? ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? ''),
      timezone: json['timezone'] as String? ?? 'UTC',
      energyLevel: json['energy_level'] as String? ?? 'medium',
      locationContext: json['coarse_location_context'] as String? ?? 'Not set',
      deviceContext: json['device_context'] as String? ?? 'Not set',
      timeContext: json['local_time_block'] as String? ?? 'night',
      weatherContext: json['weather_summary'] as String? ?? 'Not set',
    );
  }

  ContextIntelligenceSnapshot copyWith({
    String? id,
    DateTime? timestamp,
    String? timezone,
    String? energyLevel,
    String? locationContext,
    String? deviceContext,
    String? timeContext,
    String? weatherContext,
  }) {
    return ContextIntelligenceSnapshot(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      timezone: timezone ?? this.timezone,
      energyLevel: energyLevel ?? this.energyLevel,
      locationContext: locationContext ?? this.locationContext,
      deviceContext: deviceContext ?? this.deviceContext,
      timeContext: timeContext ?? this.timeContext,
      weatherContext: weatherContext ?? this.weatherContext,
    );
  }

  String get recommendationExplanation {
    final energyText = switch (energyLevel) {
      'low' => 'lighter tasks, review, or recovery-friendly work',
      'high' => 'deep work, difficult tasks, or focused study',
      _ => 'balanced tasks with normal effort',
    };
    return 'Current context is $timeContext with $energyLevel energy, so recommendations can prefer $energyText.';
  }

  Map<String, dynamic> toCreatePayload({String? nextEnergyLevel}) {
    return {
      'timezone': timezone,
      'energy_level': nextEnergyLevel ?? energyLevel,
      if (locationContext != 'Not set')
        'coarse_location_context': locationContext,
      if (weatherContext != 'Not set') 'weather_summary': weatherContext,
      if (deviceContext != 'Not set') 'device_context': deviceContext,
    };
  }
}

class TimeContextRecommendation {
  final String taskType;
  final String title;
  final String reason;
  final String suggestedEnergy;
  final bool preferenceMatch;

  const TimeContextRecommendation({
    required this.taskType,
    required this.title,
    required this.reason,
    required this.suggestedEnergy,
    required this.preferenceMatch,
  });

  factory TimeContextRecommendation.fromJson(Map<String, dynamic> json) {
    return TimeContextRecommendation(
      taskType: json['task_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      suggestedEnergy: json['suggested_energy'] as String? ?? 'medium',
      preferenceMatch: json['preference_match'] as bool? ?? false,
    );
  }
}

class TimeContextRecommendationResult {
  final String localTimeBlock;
  final String energyLevel;
  final List<String> goalTags;
  final List<TimeContextRecommendation> recommendations;
  final String explanation;

  const TimeContextRecommendationResult({
    required this.localTimeBlock,
    required this.energyLevel,
    required this.goalTags,
    required this.recommendations,
    required this.explanation,
  });

  factory TimeContextRecommendationResult.fromJson(Map<String, dynamic> json) {
    final rawRecommendations =
        json['recommendations'] as List<dynamic>? ?? const [];
    return TimeContextRecommendationResult(
      localTimeBlock: json['local_time_block'] as String? ?? 'morning',
      energyLevel: json['energy_level'] as String? ?? 'medium',
      goalTags: (json['goal_tags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      recommendations: rawRecommendations
          .map(
            (item) => TimeContextRecommendation.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class ContextTaskScoreBreakdown {
  final double priorityComponent;
  final double timeMatchComponent;
  final double energyMatchComponent;
  final double locationMatchComponent;
  final double weatherMatchComponent;
  final double frictionPenalty;
  final double dueBonus;

  const ContextTaskScoreBreakdown({
    required this.priorityComponent,
    required this.timeMatchComponent,
    required this.energyMatchComponent,
    required this.locationMatchComponent,
    required this.weatherMatchComponent,
    required this.frictionPenalty,
    required this.dueBonus,
  });

  factory ContextTaskScoreBreakdown.fromJson(Map<String, dynamic> json) {
    double read(String key) => (json[key] as num?)?.toDouble() ?? 0;
    return ContextTaskScoreBreakdown(
      priorityComponent: read('priority_component'),
      timeMatchComponent: read('time_match_component'),
      energyMatchComponent: read('energy_match_component'),
      locationMatchComponent: read('location_match_component'),
      weatherMatchComponent: read('weather_match_component'),
      frictionPenalty: read('friction_penalty'),
      dueBonus: read('due_bonus'),
    );
  }
}

class ContextTaskRecommendation {
  final String taskId;
  final String title;
  final String priority;
  final String status;
  final String? category;
  final String? dueAt;
  final String energyRequired;
  final String difficultyLevel;
  final int? estimatedMinutes;
  final double score;
  final ContextTaskScoreBreakdown scoreBreakdown;
  final String explanation;

  const ContextTaskRecommendation({
    required this.taskId,
    required this.title,
    required this.priority,
    required this.status,
    this.category,
    this.dueAt,
    required this.energyRequired,
    required this.difficultyLevel,
    this.estimatedMinutes,
    required this.score,
    required this.scoreBreakdown,
    required this.explanation,
  });

  factory ContextTaskRecommendation.fromJson(Map<String, dynamic> json) {
    return ContextTaskRecommendation(
      taskId: json['task_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      category: json['category'] as String?,
      dueAt: json['due_at'] as String?,
      energyRequired: json['energy_required'] as String? ?? 'medium',
      difficultyLevel: json['difficulty_level'] as String? ?? 'medium',
      estimatedMinutes: json['estimated_minutes'] as int?,
      score: (json['score'] as num?)?.toDouble() ?? 0,
      scoreBreakdown: ContextTaskScoreBreakdown.fromJson(
        json['score_breakdown'] as Map<String, dynamic>? ?? const {},
      ),
      explanation: json['explanation'] as String? ?? '',
    );
  }
}

class ContextTaskRecommendationResult {
  final String localTimeBlock;
  final String energyLevel;
  final List<ContextTaskRecommendation> recommendations;
  final String explanation;

  const ContextTaskRecommendationResult({
    required this.localTimeBlock,
    required this.energyLevel,
    required this.recommendations,
    required this.explanation,
  });

  factory ContextTaskRecommendationResult.fromJson(Map<String, dynamic> json) {
    final rawRecommendations =
        json['recommendations'] as List<dynamic>? ?? const [];
    return ContextTaskRecommendationResult(
      localTimeBlock: json['local_time_block'] as String? ?? 'morning',
      energyLevel: json['energy_level'] as String? ?? 'medium',
      recommendations: rawRecommendations
          .map(
            (item) => ContextTaskRecommendation.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      explanation: json['explanation'] as String? ?? '',
    );
  }
}
