import 'package:flutter_test/flutter_test.dart';
import 'package:just_the_crumbs_mobile/providers/locale_provider.dart'
    show MeasurementSystem;
import 'package:just_the_crumbs_mobile/services/measurement_converter.dart';

void main() {
  String metric(String s) => convertMeasurements(s, MeasurementSystem.metric);
  String imperial(String s) =>
      convertMeasurements(s, MeasurementSystem.imperial);

  group('convertMeasurements', () {
    test('leaves text untouched when "as written"', () {
      expect(
        convertMeasurements('2 cups flour', MeasurementSystem.asWritten),
        '2 cups flour',
      );
    });

    test('converts imperial volume to metric', () {
      expect(metric('1 cup sugar'), '240 ml sugar');
      expect(metric('1 tsp salt'), '5 ml salt');
      expect(metric('2 tbsp olive oil'), '30 ml olive oil');
    });

    test('converts imperial weight to metric', () {
      expect(metric('1 lb chicken'), '450 g chicken');
      expect(metric('8 oz cream cheese'), '230 g cream cheese');
    });

    test('converts fahrenheit to celsius', () {
      expect(metric('Bake at 350°F'), 'Bake at 177°C');
      expect(metric('heat to 212 degrees F'), 'heat to 100°C');
    });

    test('converts metric to imperial', () {
      expect(imperial('200 g flour'), '7 oz flour');
      expect(imperial('180°C'), '356°F');
    });

    test('handles fractions and mixed numbers', () {
      expect(metric('1/2 cup milk'), '120 ml milk');
      expect(metric('1 1/2 tsp vanilla'), '7 ml vanilla');
      expect(metric('½ cup water'), '120 ml water');
    });

    test('preserves ranges', () {
      expect(metric('1-2 tsp chili'), '5–10 ml chili');
    });

    test('leaves units already in the target system alone', () {
      expect(metric('200 g flour'), '200 g flour');
      expect(imperial('2 cups flour'), '2 cups flour');
    });

    test('ignores plain numbers with no unit', () {
      expect(metric('3 eggs'), '3 eggs');
      expect(metric('Preheat the oven'), 'Preheat the oven');
    });
  });
}
