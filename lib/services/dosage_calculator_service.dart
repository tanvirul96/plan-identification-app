enum PatientAgeGroup {
  adult,    // 18 - 65 yrs
  pediatric,// 2 - 12 yrs (Young's formula)
  geriatric,// > 65 yrs (25% reduction)
}

enum HerbalFormulation {
  swarasa,  // Fresh expressed juice
  kwatha,   // Boiled aqueous decoction
  churna,   // Fine micronized powder
  kalka,    // Fresh ground leaf paste
  hima,     // Cold aqueous infusion
  arishta,  // Fermented herbal wine/elixir
}

class DosageResult {
  final String plantName;
  final String formulationNameEn;
  final String formulationNameBn;
  final double calculatedDoseAmount;
  final String unit;
  final String frequencyEn;
  final String frequencyBn;
  final String vehicleAnupanaEn;
  final String vehicleAnupanaBn;
  final String timingEn;
  final String timingBn;
  final String safetyLimitEn;
  final String safetyLimitBn;
  final List<String> clinicalNotesEn;
  final List<String> clinicalNotesBn;

  DosageResult({
    required this.plantName,
    required this.formulationNameEn,
    required this.formulationNameBn,
    required this.calculatedDoseAmount,
    required this.unit,
    required this.frequencyEn,
    required this.frequencyBn,
    required this.vehicleAnupanaEn,
    required this.vehicleAnupanaBn,
    required this.timingEn,
    required this.timingBn,
    required this.safetyLimitEn,
    required this.safetyLimitBn,
    required this.clinicalNotesEn,
    required this.clinicalNotesBn,
  });
}

class DosageCalculatorService {
  static DosageResult calculateDosage({
    required String plantName,
    required PatientAgeGroup ageGroup,
    required double weightKg,
    required HerbalFormulation formulation,
  }) {
    // 1. Age-based fraction
    double ageFactor = 1.0;
    if (ageGroup == PatientAgeGroup.pediatric) {
      // Young's rule: Age / (Age + 12) ~ approx 0.35 - 0.50
      ageFactor = (weightKg / 70.0).clamp(0.25, 0.65);
    } else if (ageGroup == PatientAgeGroup.geriatric) {
      ageFactor = 0.75; // 25% renal clearance safety buffer
    }

    // Weight factor normalized to standard 65kg adult
    final double weightFactor = (weightKg / 65.0).clamp(0.4, 1.4);
    final double compositeFactor = ageFactor * (0.5 + 0.5 * weightFactor);

    // Standard base adult doses per formulation
    double baseDose = 10.0;
    String unit = 'ml';
    String formEn = 'Fresh Juice (Swarasa)';
    String formBn = 'তাজা পাতার রস (স্বরস)';
    String anupanaEn = 'Warm Water or Pure Honey';
    String anupanaBn = 'কুসুম গরম পানি বা মধু';

    switch (formulation) {
      case HerbalFormulation.swarasa:
        baseDose = 12.0;
        unit = 'ml';
        formEn = 'Fresh Expressed Juice (Swarasa)';
        formBn = 'তাজা পাতার রস (স্বরস)';
        anupanaEn = 'Warm Water (100ml) or 1 tsp Pure Honey';
        anupanaBn = '১০০ মিলি কুসুম গরম পানি বা ১ চা চামচ খাঁটি মধু';
        break;
      case HerbalFormulation.kwatha:
        baseDose = 40.0;
        unit = 'ml';
        formEn = 'Boiled Decoction (Kwatha)';
        formBn = 'সিদ্ধ করা ক্বাথ বা ডিককশন';
        anupanaEn = 'Pinch of Black Pepper / Cardamom Powder';
        anupanaBn = 'এক চিমটি গোলমরিচ বা এলাচ গুঁড়া';
        break;
      case HerbalFormulation.churna:
        baseDose = 3.5;
        unit = 'g (grams)';
        formEn = 'Fine Powder (Churna)';
        formBn = 'মিহি পাতার বা বাকলের চূর্ণ';
        anupanaEn = 'Warm Water or Warm Cow Milk';
        anupanaBn = 'কুসুম গরম পানি বা দুধ';
        break;
      case HerbalFormulation.kalka:
        baseDose = 6.0;
        unit = 'g (grams)';
        formEn = 'Herbal Paste (Kalka)';
        formBn = 'বাটা ভেষজ পেস্ট (কল্ক)';
        anupanaEn = 'Honey or Ghee (Clarified Butter)';
        anupanaBn = 'মধু অথবা সামান্য খাঁটি ঘি';
        break;
      case HerbalFormulation.hima:
        baseDose = 30.0;
        unit = 'ml';
        formEn = 'Cold Infusion (Hima)';
        formBn = 'ঠান্ডা পানিতে ভেজানো নির্যাস (হিম)';
        anupanaEn = 'Rock Sugar / Mishri Syrup';
        anupanaBn = 'তালমিছরি বা চিনির সিরাপ';
        break;
      case HerbalFormulation.arishta:
        baseDose = 20.0;
        unit = 'ml';
        formEn = 'Fermented Elixir (Arishta/Asava)';
        formBn = 'ফার্মেন্টেড তরল অরিষ্ট / আসব';
        anupanaEn = 'Equal Volume of Plain Water';
        anupanaBn = 'সমপরিমাণ সাধারণ পানি';
        break;
    }

    final double calculatedDose =
        double.parse((baseDose * compositeFactor).toStringAsFixed(1));

    return DosageResult(
      plantName: plantName,
      formulationNameEn: formEn,
      formulationNameBn: formBn,
      calculatedDoseAmount: calculatedDose,
      unit: unit,
      frequencyEn: 'Twice daily (BD) after meals',
      frequencyBn: 'দিনে ২ বার (খাবারের ২০ মিনিট পর)',
      vehicleAnupanaEn: anupanaEn,
      vehicleAnupanaBn: anupanaBn,
      timingEn: 'Morning & Evening post-prandial',
      timingBn: 'সকাল ও রাতে আহারের পর',
      safetyLimitEn: 'Do not exceed ${baseDose * 1.5 * compositeFactor} $unit per 24 hours.',
      safetyLimitBn: '২৪ ঘণ্টায় মোট ${baseDose * 1.5 * compositeFactor} $unit এর বেশি গ্রহণ করবেন না।',
      clinicalNotesEn: [
        'Course duration: 14 to 21 consecutive days maximum, followed by a 7-day washout period.',
        'If gastrointestinal discomfort occurs, reduce dosage by 50% and take strictly with food.',
      ],
      clinicalNotesBn: [
        'সর্বোচ্চ ১৪ থেকে ২১ দিন একটানা সেবনযোগ্য, এরপর ৭ দিনের বিরতি প্রয়োজন।',
        'পেটে অস্বস্তি অনুভূত হলে মাত্রা অর্ধেক করুন এবং অবশ্যই ভরা পেটে সেবন করুন।',
      ],
    );
  }
}
