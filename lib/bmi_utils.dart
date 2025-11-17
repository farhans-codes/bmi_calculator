class BMIUtils {
  static double poundsToKg(double pounds) {
    return pounds * 0.45359237;
  }

  static double cmToMeters(double cm) {
    return cm / 100;
  }

  static double feetInchToMeters(double feet, double inches) {
    return (feet * 12 + inches) * 0.0254;
  }

  static Map<String, double> normalizeFeetInches(double feet, double inches) {
    if (inches >= 12) {
      feet = feet + (inches / 12).floor();
      inches = inches % 12;
    }
    return {'feet': feet, 'inches': inches};
  }

  static double calculateBMI(double weightInKg, double heightInMeters) {
    return weightInKg / (heightInMeters * heightInMeters);
  }

  static String getCategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi >= 18.5 && bmi <= 24.9) {
      return 'Normal';
    } else if (bmi >= 25.0 && bmi <= 29.9) {
      return 'Overweight';
    } else {
      return 'Obese';
    }
  }

  static String getCategoryColor(String category) {
    switch (category) {
      case 'Underweight':
        return 'blue';
      case 'Normal':
        return 'green';
      case 'Overweight':
        return 'orange';
      case 'Obese':
        return 'red';
      default:
        return 'grey';
    }
  }
}
