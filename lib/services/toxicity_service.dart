class ToxicPlantProfile {
  final String plantName;
  final String scientificName;
  final String riskTier; // Critical, High, Moderate
  final String toxicPartsEn;
  final String toxicPartsBn;
  final String toxinCompoundsEn;
  final String toxinCompoundsBn;
  final List<String> symptomsEn;
  final List<String> symptomsBn;
  final List<String> emergencyFirstAidEn;
  final List<String> emergencyFirstAidBn;
  final String medicalAntidoteProtocolEn;
  final String medicalAntidoteProtocolBn;

  ToxicPlantProfile({
    required this.plantName,
    required this.scientificName,
    required this.riskTier,
    required this.toxicPartsEn,
    required this.toxicPartsBn,
    required this.toxinCompoundsEn,
    required this.toxinCompoundsBn,
    required this.symptomsEn,
    required this.symptomsBn,
    required this.emergencyFirstAidEn,
    required this.emergencyFirstAidBn,
    required this.medicalAntidoteProtocolEn,
    required this.medicalAntidoteProtocolBn,
  });
}

class ToxicityService {
  static final ToxicityService _instance = ToxicityService._internal();
  factory ToxicityService() => _instance;
  ToxicityService._internal();

  final List<ToxicPlantProfile> _profiles = [
    // ── 1. Akondo (Calotropis procera) ──
    ToxicPlantProfile(
      plantName: 'Akondo',
      scientificName: 'Calotropis procera',
      riskTier: 'CRITICAL (Cardiotoxic & Keratotoxic)',
      toxicPartsEn: 'Milky latex sap, leaves, root bark, flower nectar',
      toxicPartsBn: 'সাদা দুধের মতো ক্ষীর (Latex), পাতা, শিকড়ের ছাল ও ফুল',
      toxinCompoundsEn: 'Calotropin, Uscharin, Calactin, Calotropagenin (Cardiac Glycosides)',
      toxinCompoundsBn: 'ক্যালোট্রপিন, উশচারিন, ক্যালোট্যাকটিন (কার্ডিয়াক গ্লাইকোসাইড)',
      symptomsEn: [
        'Ocular Contact: Severe corneal endothelial necrosis, photophobia, chemical keratitis, temporary or permanent blindness.',
        'Ingestion: Burning stomatitis, violent vomiting, bradycardia, complete heart block, delirium, convulsions, fatal cardiac collapse.',
        'Dermal: Vesicular dermatitis and painful chemical burns.',
      ],
      symptomsBn: [
        'চোখে লাগলে: চোখের কর্নিয়ার মারাত্মক ক্ষতি, তীব্র প্রদাহ, কর্নিয়াল অন্ধত্বের চরম ঝুঁকি।',
        'খেলে: মুখ ও গলায় তীব্র জ্বালাপোড়া, অনবরত বমি, অস্বাভাবিক হৃদস্পন্দন ও কার্ডিয়াক অ্যারেস্ট।',
        'ত্বকে লাগলে: ফোসকা ও তীব্র রাসায়নিক ক্ষতের সৃষ্টি।',
      ],
      emergencyFirstAidEn: [
        'OCULAR: Immediately flush eyes under continuous running water or normal saline for at least 15-20 minutes without rubbing.',
        'DERMAL: Wash skin thoroughly with cold water and mild non-abrasive soap. Apply soothing aloe gel.',
        'INGESTION: DO NOT induce vomiting if unconscious. Administer activated charcoal slurry (1g/kg) immediately. Rush to hospital ER.',
      ],
      emergencyFirstAidBn: [
        'চোখে লাগলে: সাথে সাথে অন্তত ১৫-২০ মিনিট একটানা পরিষ্কার পানির ঝাপটা দিন বা স্যালাইন দিয়ে ধুয়ে ফেলুন। চোখ ডলবেন না।',
        'ত্বকে লাগলে: সাবান-পানি দিয়ে ভালো করে ধুয়ে ফেলুন।',
        'খেলে: দ্রুত রোগীকে নিকটস্থ হাসপাতালের ইমার্জেন্সিতে নিয়ে যান। কোনোভাবেই জোর করে বমি করাবেন না।',
      ],
      medicalAntidoteProtocolEn:
          'ECG continuous monitoring, Digoxin Immune Fab (DigiFab) if severe cardiotoxicity, Atropine for bradycardia, IV fluids.',
      medicalAntidoteProtocolBn:
          'ইসিজি মনিটরিং, ডিগক্সিন ইমিউন ফ্যাব অ্যান্টিবডি এবং ব্র্যাডিকার্ডিয়ার জন্য অ্যাট্রোপিন ইনজেকশন।',
    ),

    // ── 2. Devil\'s Backbone (Euphorbia tithymaloides) ──
    ToxicPlantProfile(
      plantName: "Devil's Backbone",
      scientificName: 'Euphorbia tithymaloides',
      riskTier: 'HIGH (Corrosive Latex & Irritant)',
      toxicPartsEn: 'Latex sap present in stems, branches, and leaves',
      toxicPartsBn: 'কাণ্ড, ডাল ও পাতার মধ্যকার সাদা দুধালো কষ বা ল্যাটেক্স',
      toxinCompoundsEn: 'Euphorbin, diterpene esters, irritant tigliane resins',
      toxinCompoundsBn: 'ইউফরবিন, ডাইটারপিন এস্টার ও তীব্র প্রদাহজনক রজন',
      symptomsEn: [
        'Dermal: Severe erythema, blistering, burning pain, contact dermatitis.',
        'Ocular: Intense conjunctival hyperaemia, lacrimation, corneal ulceration.',
        'Ingestion: Irritation of oral mucosa, severe burning throat, nausea, hematemesis.',
      ],
      symptomsBn: [
        'ত্বকে: তীব্র জ্বালাপোড়া, লাল হয়ে যাওয়া ও ফোসকা পড়া।',
        'চোখে: চোখ লাল হওয়া, পানি পড়া ও কর্নিয়ায় ঘা সৃষ্টি।',
        'খেলে: মুখ ও গলায় তীব্র জ্বালাপোড়া, বমি ও পেটে তীব্র ব্যথা।',
      ],
      emergencyFirstAidEn: [
        'Ocular: Flush copiously with saline for 15 minutes. Instill lubricating eye drops and seek ophthalmology exam.',
        'Dermal: Wash with cool water & soap. Cold compresses for burning relief.',
        'Ingestion: Rinse mouth thoroughly with cold milk or water. Administer oral demulcents.',
      ],
      emergencyFirstAidBn: [
        'চোখে লাগলে: ১৫ মিনিট ধরে প্রচুর পরিষ্কার পানি দিয়ে চোখ ধুয়ে চক্ষু বিশেষজ্ঞের কাছে যান।',
        'ত্বকে লাগলে: ঠান্ডা পানি ও সাবান দিয়ে ধুয়ে ঠান্ডা সেঁক দিন।',
        'খেলে: ঠান্ডা দুধ বা পানি দিয়ে ভালোভাবে মুখ কুলকুচি করে পান করান।',
      ],
      medicalAntidoteProtocolEn:
          'Symptomatic management: Topical corticosteroids, anti-inflammatory analgesics, gastroprotective agents (PPIs).',
      medicalAntidoteProtocolBn:
          'লক্ষণভিত্তিক চিকিৎসা: ব্যথানাশক, অ্যান্টিহিস্টামিন ও পাকস্থলী সুরক্ষাকারী ওষুধ।',
    ),

    // ── 3. Nayontara (Catharanthus roseus) ──
    ToxicPlantProfile(
      plantName: 'Nayontara',
      scientificName: 'Catharanthus roseus',
      riskTier: 'HIGH (Cytotoxic Overdose Risk)',
      toxicPartsEn: 'All plant parts, especially root bark and leaves',
      toxicPartsBn: 'গাছের সমস্ত অংশ, বিশেষ করে শিকড়ের ছাল ও কচি পাতা',
      toxinCompoundsEn: 'Vincristine, Vinblastine, Ajmalicine, Catharanthine (Vinca Alkaloids)',
      toxinCompoundsBn: 'ভিনক্রিস্টিন, ভিনব্লাস্টিন, আজমালিসিন (ভেসোঅ্যাক্টিভ অ্যালকালয়েড)',
      symptomsEn: [
        'Overdose Ingestion: Profound hypotension, severe nausea, neuropathic tingling, bone marrow suppression (leukopenia), hair loss, organ failure.',
      ],
      symptomsBn: [
        'অতিরিক্ত সেবনে: রক্তচাপ হঠাৎ মারাত্মক কমে যাওয়া, অবশ ভাব, রক্তে শ্বেতকণিকা বিপজ্জনকভাবে হ্রাস ও লিভার-কিডনির ক্ষতি।',
      ],
      emergencyFirstAidEn: [
        'Never consume uncontrolled home extracts. If accidental overdose occurs, administer activated charcoal and transfer to hospital for monitoring.',
      ],
      emergencyFirstAidBn: [
        'কখনই নিজে নিজে মাত্রাতিরিক্ত নয়নতারা সেবন করবেন না। অতিরিক্ত সেবনে সাথে সাথে হাসপাতালে নিয়ে যান।',
      ],
      medicalAntidoteProtocolEn:
          'Supportive hemodynamic resuscitation, Complete Blood Count (CBC) monitoring, Granulocyte colony-stimulating factors (G-CSF) if neutropenia develops.',
      medicalAntidoteProtocolBn:
          'স্যালাইন ও ওষুধ দিয়ে প্রেসার নিয়ন্ত্রণ, সিবিসি টেস্ট এবং রক্তকণিকার নিবিড় পর্যবেক্ষণ।',
    ),
  ];

  List<ToxicPlantProfile> getAllProfiles() => _profiles;

  ToxicPlantProfile? getProfile(String plantName) {
    final clean = plantName.trim().toLowerCase();
    for (var p in _profiles) {
      if (p.plantName.toLowerCase() == clean ||
          p.scientificName.toLowerCase().contains(clean)) {
        return p;
      }
    }
    return null;
  }
}
