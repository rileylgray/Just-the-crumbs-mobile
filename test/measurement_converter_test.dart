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

    test('converts every way of writing a mixed number whole', () {
      // Matching only the fraction used to strand the whole number in front.
      expect(metric('3 1/2 cups flour'), '830 ml flour');
      expect(metric('3 ½ cups flour'), '830 ml flour');
      expect(metric('3½ cups flour'), '830 ml flour');
      expect(metric('3-1/2 cups flour'), '830 ml flour');
      expect(metric('3 and 1/2 cups flour'), '830 ml flour');
      expect(metric('1 ½ tbsp sugar'), '20 ml sugar');
    });

    test('reads the fraction slash recipe sites use', () {
      expect(metric('3 1⁄2 cups flour'), '830 ml flour');
      expect(metric('1⁄2 cup milk'), '120 ml milk');
    });

    test('preserves ranges', () {
      expect(metric('1-2 tsp chili'), '5–10 ml chili');
      expect(metric('1 1/2-2 cups stock'), '350–470 ml stock');
    });

    test('says "cup" for one cup or less', () {
      expect(imperial('240 ml milk'), '1 cup milk');
      expect(imperial('180 ml milk'), '3/4 cup milk');
      expect(imperial('500 ml milk'), '2 1/8 cups milk');
    });

    test('uses ounces below a pound, rounded to the half past a few', () {
      expect(imperial('400 g can tomatoes'), '14 oz can tomatoes');
      expect(imperial('250 g butter'), '9 oz butter');
      expect(imperial('450 g beef'), '1 lb beef');
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

  group('scaleQuantities', () {
    test('returns the line untouched at 1×', () {
      expect(scaleQuantities('2 cups flour', 1), '2 cups flour');
    });

    test('scales a leading measurement into kitchen fractions', () {
      expect(scaleQuantities('3 1/2 cups flour', 0.5), '1 3/4 cups flour');
      expect(scaleQuantities('1/3 cup sugar', 2), '2/3 cup sugar');
      expect(scaleQuantities('½ cup water', 3), '1 1/2 cups water');
      expect(scaleQuantities('1/8 tsp salt', 0.5), '1/16 tsp salt');
    });

    test('keeps a weight given alongside in step', () {
      expect(
        scaleQuantities('1 cup (120 g) flour', 2),
        '2 cups (240 g) flour',
      );
    });

    test('scales a leading count, but not the package size', () {
      expect(scaleQuantities('3 eggs', 0.5), '1 1/2 eggs');
      expect(
        scaleQuantities('1 (14 oz) can tomatoes', 2),
        '2 (14 oz) can tomatoes',
      );
      expect(scaleQuantities('2 x 400g cans', 2), '4 x 400g cans');
    });

    test('scales both ends of a range', () {
      expect(scaleQuantities('2-3 cloves garlic', 2), '4-6 cloves garlic');
      expect(scaleQuantities('2 to 3 cups stock', 2), '4 to 6 cups stock');
    });

    test('scales a measurement later in the line', () {
      expect(scaleQuantities('Flour, 2 cups', 0.5), 'Flour, 1 cup');
    });

    test('writes metric and decimal amounts as decimals', () {
      expect(scaleQuantities('250 g butter', 0.5), '125 g butter');
      expect(scaleQuantities('1 l milk', 0.5), '0.5 l milk');
      expect(scaleQuantities('1.5 lbs beef', 0.5), '0.75 lbs beef');
      expect(scaleQuantities('1,5 kg potatoes', 0.5), '0,75 kg potatoes');
    });

    test('leaves sizes, percentages and temperatures alone', () {
      expect(scaleQuantities('9-inch pie crust', 2), '9-inch pie crust');
      expect(scaleQuantities('2% milk', 2), '2% milk');
      expect(
        scaleQuantities('Butter, softened to 65°F', 2),
        'Butter, softened to 65°F',
      );
      expect(scaleQuantities('Salt to taste', 2), 'Salt to taste');
    });

    test('scaled amounts still convert', () {
      expect(metric(scaleQuantities('1 1/2 cups milk', 2)), '710 ml milk');
    });
  });
}
