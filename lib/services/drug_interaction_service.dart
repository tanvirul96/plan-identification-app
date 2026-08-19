import '../models/drug_interaction_model.dart';

class DrugInteractionService {
  static final DrugInteractionService _instance =
      DrugInteractionService._internal();
  factory DrugInteractionService() => _instance;
  DrugInteractionService._internal();

  final List<HerbDrugInteraction> _interactions = [
    // ── 1. Neem (Azadirachta indica) ──
    HerbDrugInteraction(
      plantLocalName: 'Neem',
      plantScientificName: 'Azadirachta indica',
      drugName: 'Metformin / Glimepiride',
      drugClass: 'Oral Antidiabetics / Hypoglycemics',
      severity: InteractionSeverity.moderateCaution,
      mechanismEn:
          'Synergistic additive hypoglycemic action via enhanced peripheral glucose uptake and insulin mimetic compounds.',
      mechanismBn:
          'রক্তে সুগারের মাত্রা অতিরিক্ত কমে যাওয়ার ঝুঁকি (অ্যাডিটিভ হাইপোগ্লাইসেমিক প্রভাব)।',
      clinicalEffectEn:
          'Risk of severe hypoglycemia (dizziness, tremors, sweating, syncope).',
      clinicalEffectBn: 'তীব্র হাইপোগ্লাইসেমিয়া এবং মাথা ঘোরার ঝুঁকি।',
      recommendationEn:
          'Monitor blood glucose regularly. Adjust antidiabetic dosage under physician guidance if consuming daily neem extracts.',
      recommendationBn:
          'নিয়মিত রক্তের গ্লুকোজ পর্যবেক্ষণ করুন এবং চিকিৎসকের পরামর্শ অনুযায়ী ওষুধের মাত্রা সমন্বয় করুন।',
    ),
    HerbDrugInteraction(
      plantLocalName: 'Neem',
      plantScientificName: 'Azadirachta indica',
      drugName: 'Cyclosporine / Tacrolimus',
      drugClass: 'Immunosuppressants',
      severity: InteractionSeverity.moderateCaution,
      mechanismEn:
          'Neem polysaccharides and nimbin exhibit immunostimulatory properties which counteract immunosuppressive efficacy.',
      mechanismBn:
          'নিমের রোগ প্রতিরোধ বৃদ্ধিকারী উপাদান ইমিউনোসাপ্রেসিভ ওষুধের কার্যকারিতা হ্রাস করতে পারে।',
      clinicalEffectEn:
          'Potential reduction of transplant organ rejection protection.',
      clinicalEffectBn: 'অঙ্গ প্রতিস্থাপন পরবর্তী সুরক্ষার কার্যকারিতা কমতে পারে।',
      recommendationEn:
          'Avoid concurrent use in organ transplant recipients or autoimmune disease patients on immunosuppressive regimens.',
      recommendationBn:
          'অঙ্গ প্রতিস্থাপনকারী রোগীদের ক্ষেত্রে একসাথে গ্রহণ পরিহার করুন।',
    ),

    // ── 2. Tulsi (Ocimum sanctum) ──
    HerbDrugInteraction(
      plantLocalName: 'Tulsi',
      plantScientificName: 'Ocimum sanctum',
      drugName: 'Warfarin / Aspirin / Clopidogrel',
      drugClass: 'Anticoagulants & Antiplatelets',
      severity: InteractionSeverity.moderateCaution,
      mechanismEn:
          'Eugenol in Tulsi inhibits platelet aggregation and COX enzymes, potentiating antithrombotic therapy.',
      mechanismBn:
          'তুলসীর ইউজেনল রক্ত জমাট বাঁধা রোধক ওষুধের কার্যকারিতা বাড়িয়ে দেয়।',
      clinicalEffectEn:
          'Increased bleeding tendency, bruising, and prolonged prothrombin time (INR).',
      clinicalEffectBn: 'রক্তক্ষরণের ঝুঁকি ও ক্ষত থেকে রক্ত পড়া বেড়ে যেতে পারে।',
      recommendationEn:
          'Discontinue high-dose Tulsi decoction 7 days prior to scheduled elective surgery. Monitor INR closely.',
      recommendationBn:
          'অপারেশনের অন্তত ৭ দিন পূর্বে তুলসীর তীব্র ব্যবহার বন্ধ করুন।',
    ),

    // ── 3. Akondo (Calotropis procera) ──
    HerbDrugInteraction(
      plantLocalName: 'Akondo',
      plantScientificName: 'Calotropis procera',
      drugName: 'Digoxin / Digitoxin',
      drugClass: 'Cardiac Glycosides',
      severity: InteractionSeverity.contraindicated,
      mechanismEn:
          'Calotropin, calactin, and uscharin in Akondo are potent Cardenolide cardiac glycosides that bind myocardial Na+/K+-ATPase pumps identically to Digoxin.',
      mechanismBn:
          'আকন্দের ক্যালোট্রপিন হার্টের সোডিয়াম-পটাশিয়াম পাম্পে ডিগক্সিনের মতো কাজ করে মারাত্মক বিষক্রিয়া ঘটায়।',
      clinicalEffectEn:
          'Fatal digitalis toxicity: Ventricular fibrillation, severe heart block, cardiac arrest.',
      clinicalEffectBn:
          'মারাত্মক হার্ট ফেইলিওর, কার্ডিয়াক অ্যারেস্ট ও মৃত্যুর চরম ঝুঁকি।',
      recommendationEn:
          'STRICTLY CONTRAINDICATED. Never ingest Akondo preparations with any cardiac medication.',
      recommendationBn:
          'সম্পূর্ণরূপে নিষিদ্ধ। হৃদরোগের ওষুধের সাথে আকন্দ কোনোভাবেই সেবনযোগ্য নয়।',
    ),

    // ── 4. Arjun (Terminalia arjuna) ──
    HerbDrugInteraction(
      plantLocalName: 'Arjun',
      plantScientificName: 'Terminalia arjuna',
      drugName: 'Amlodipine / Losartan / Atenolol',
      drugClass: 'Antihypertensives (CCBs, ARBs, Beta-blockers)',
      severity: InteractionSeverity.moderateCaution,
      mechanismEn:
          'Arjunic acid and flavonoids exert potent inotropic and hypotensive vasodilation via nitric oxide upregulation.',
      mechanismBn:
          'অর্জুনের উপাদান রক্তনালী প্রসারিত করে রক্তচাপ অতিরিক্ত নামিয়ে দিতে পারে।',
      clinicalEffectEn:
          'Enhanced hypotensive effect causing orthostatic hypotension and lightheadedness.',
      clinicalEffectBn: 'হঠাৎ প্রেসার কমে গিয়ে দুর্বলতা বা মাথা ঘোরা।',
      recommendationEn:
          'Beneficial cardiovascular synergy when calibrated, but monitor BP during initial 2 weeks.',
      recommendationBn:
          'নিয়মিত ব্লাড প্রেশার মেপে চিকিৎসকের পরামর্শে গ্রহণ করুন।',
    ),

    // ── 5. Thankuni (Centella asiatica) ──
    HerbDrugInteraction(
      plantLocalName: 'Thankuni',
      plantScientificName: 'Centella asiatica',
      drugName: 'Diazepam / Lorazepam / Zolpidem',
      drugClass: 'Sedatives & Anxiolytics (GABA agonists)',
      severity: InteractionSeverity.moderateCaution,
      mechanismEn:
          'Asiaticoside increases brain GABA levels, enhancing CNS sedative and tranquilizing activity.',
      mechanismBn:
          'মস্তিষ্কের GABA বাড়িয়ে ঘুমের ওষুধ ও সিডেটিভের প্রভাব অতিরিক্ত বাড়িয়ে দেয়।',
      clinicalEffectEn:
          'Excessive somnolence, prolonged drowsiness, and reduced psychomotor performance.',
      clinicalEffectBn: 'অতিরিক্ত তন্দ্রাচ্ছন্নতা ও মনোযোগের ঘাটতি।',
      recommendationEn:
          'Avoid heavy driving or operating machinery when consuming high-dose fresh Thankuni juice alongside sedatives.',
      recommendationBn: 'ঘুমের ওষুধের সাথে সেবনের সময় সাবধানে থাকুন।',
    ),

    // ── 6. Nayontara (Catharanthus roseus) ──
    HerbDrugInteraction(
      plantLocalName: 'Nayontara',
      plantScientificName: 'Catharanthus roseus',
      drugName: 'Vincristine / Vinblastine / Chemotherapy',
      drugClass: 'Cytotoxic Chemotherapeutic Agents',
      severity: InteractionSeverity.contraindicated,
      mechanismEn:
          'Crude vinca alkaloids directly cross-interfere with microtubule spindle inhibition and bone marrow myelosuppression.',
      mechanismBn:
          'ক্যান্সারের কেমোথেরাপির ওষুধের সাথে মিলে অস্থিমজ্জার উপর চরম বিষক্রিয়া সৃষ্টি করে।',
      clinicalEffectEn:
          'Severe peripheral neuropathy, leukopenia, and myelosuppressive crisis.',
      clinicalEffectBn:
          'শ্বেতকণিকা মারাত্মকভাবে কমে যাওয়া ও স্নায়ুর ক্ষয়ক্ষতি।',
      recommendationEn:
          'CONTRAINDICATED. Do not self-prescribe crude Nayontara preparations.',
      recommendationBn: 'নিজে নিজে নয়নতারার কোনো ওষুধ খাওয়া সম্পূর্ণ নিষিদ্ধ।',
    ),

    // ── 7. Pathorkuchi (Kalanchoe pinnata) ──
    HerbDrugInteraction(
      plantLocalName: 'Pathorkuchi',
      plantScientificName: 'Kalanchoe pinnata',
      drugName: 'Furosemide / Hydrochlorothiazide',
      drugClass: 'Diuretics & Antihypertensives',
      severity: InteractionSeverity.moderateCaution,
      mechanismEn:
          'Potent aquaretic and natriuretic effect enhances renal potassium and water clearance.',
      mechanismBn:
          'প্রস্রাবের মাত্রা বৃদ্ধি করে শরীর থেকে ইলেক্ট্রোলাইট বের করে দিতে পারে।',
      clinicalEffectEn: 'Electrolyte imbalance, dehydration, mild hypokalemia.',
      clinicalEffectBn: 'শরীরে পানিশূন্যতা ও পটাশিয়ামের অভাব হতে পারে।',
      recommendationEn:
          'Ensure adequate hydration and electrolyte intake when taking alongside loop diuretics.',
      recommendationBn: 'পর্যাপ্ত পানি ও তরল খাবার গ্রহণ নিশ্চিত করুন।',
    ),
  ];

  List<HerbDrugInteraction> getAllInteractions() => _interactions;

  List<HerbDrugInteraction> searchInteractions({
    String? plantName,
    String? drugQuery,
  }) {
    return _interactions.where((item) {
      bool matchesPlant = true;
      if (plantName != null && plantName.isNotEmpty && plantName != 'All') {
        matchesPlant = item.plantLocalName.toLowerCase() == plantName.toLowerCase() ||
            item.plantScientificName.toLowerCase().contains(plantName.toLowerCase());
      }

      bool matchesDrug = true;
      if (drugQuery != null && drugQuery.isNotEmpty) {
        final q = drugQuery.toLowerCase();
        matchesDrug = item.drugName.toLowerCase().contains(q) ||
            item.drugClass.toLowerCase().contains(q) ||
            item.mechanismEn.toLowerCase().contains(q);
      }

      return matchesPlant && matchesDrug;
    }).toList();
  }
}
