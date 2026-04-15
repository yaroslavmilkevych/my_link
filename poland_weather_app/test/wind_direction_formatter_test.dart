import 'package:flutter_test/flutter_test.dart';
import 'package:poland_weather_app/src/core/utils/wind_direction_formatter.dart';

void main() {
  group('WindDirectionFormatter', () {
    test('maps cardinal directions correctly', () {
      expect(WindDirectionFormatter.fromDegrees(0), 'N');
      expect(WindDirectionFormatter.fromDegrees(45), 'NE');
      expect(WindDirectionFormatter.fromDegrees(90), 'E');
      expect(WindDirectionFormatter.fromDegrees(135), 'SE');
      expect(WindDirectionFormatter.fromDegrees(180), 'S');
      expect(WindDirectionFormatter.fromDegrees(225), 'SW');
      expect(WindDirectionFormatter.fromDegrees(270), 'W');
      expect(WindDirectionFormatter.fromDegrees(315), 'NW');
    });
  });
}
