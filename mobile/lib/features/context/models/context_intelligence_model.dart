class ContextIntelligenceSnapshot {
  final String energyLevel;
  final String locationContext;
  final String deviceContext;
  final String timeContext;
  final String weatherContext;

  const ContextIntelligenceSnapshot({
    this.energyLevel = 'medium',
    this.locationContext = 'Manual location context placeholder',
    this.deviceContext = 'Device state placeholder',
    this.timeContext = 'Time-aware planning placeholder',
    this.weatherContext = 'Weather suggestions placeholder',
  });

  ContextIntelligenceSnapshot copyWith({
    String? energyLevel,
    String? locationContext,
    String? deviceContext,
    String? timeContext,
    String? weatherContext,
  }) {
    return ContextIntelligenceSnapshot(
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
    return 'Recommendations can use your $energyLevel energy level to suggest $energyText.';
  }
}
