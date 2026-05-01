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
