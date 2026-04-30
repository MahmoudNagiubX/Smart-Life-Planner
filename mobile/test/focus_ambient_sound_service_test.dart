import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/focus/services/focus_ambient_sound_service.dart';

void main() {
  test('ambient sound keys normalize to supported bundled assets', () {
    expect(FocusAmbientSoundService.normalizeKey('RAIN'), 'rain');
    expect(FocusAmbientSoundService.normalizeKey('unknown'), 'silence');
    expect(
      FocusAmbientSoundService.assetForKey('white_noise'),
      'assets/audio/focus_white_noise.wav',
    );
    expect(FocusAmbientSoundService.isAudibleKey('silence'), isFalse);
    expect(FocusAmbientSoundService.isAudibleKey('cafe'), isTrue);
  });

  test('ambient sound assets are bundled', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    for (final key in FocusAmbientSoundService.supportedKeys) {
      final asset = FocusAmbientSoundService.assetForKey(key);
      expect(asset, isNotNull);
      final data = await rootBundle.load(asset!);
      expect(data.lengthInBytes, greaterThan(44));
    }
  });
}
