import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_locale.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _prefKey = 'selected_app_language';
  final ValueNotifier<AppLanguage> currentLanguage =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLang = prefs.getString(_prefKey);
      if (savedLang == 'bn') {
        currentLanguage.value = AppLanguage.bangla;
      } else {
        currentLanguage.value = AppLanguage.english;
      }
    } catch (_) {}
  }

  Future<void> toggleLanguage() async {
    final next = currentLanguage.value == AppLanguage.english
        ? AppLanguage.bangla
        : AppLanguage.english;
    currentLanguage.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, next.code);
    } catch (_) {}
  }

  bool get isBangla => currentLanguage.value == AppLanguage.bangla;

  String tr(String enKey, {String? bnText}) {
    if (isBangla) {
      return bnText ?? _translationsBn[enKey] ?? enKey;
    }
    return _translationsEn[enKey] ?? enKey;
  }

  // Plant Name Localization helper
  static const Map<String, String> plantNamesBn = {
    'Akondo': 'আকন্দ',
    'Amloki': 'আমলকী',
    'Arjun': 'অর্জুন',
    'Basok': 'বাসক',
    'Bohera': 'বহেরা',
    'Devilbackbone': 'ডেভিলস ব্যাকবোন',
    "Devil's Backbone": 'ডেভিলস ব্যাকবোন',
    'Haritoki': 'হরিতকী',
    'Jarmani Lata': 'জার্মানি লতা',
    'Joba': 'জবা',
    'Lemongrass': 'লেমনগ্রাস',
    'Nayontara': 'নয়নতারা',
    'Neem': 'নিম',
    'Pathorkuchi': 'পাথরকুচি',
    'Thankuni': 'থানকুনি',
    'Tulsi': 'তুলসী',
    'Zenora': 'জেনোরা',
  };

  String getPlantDisplayName(String englishName) {
    if (isBangla) {
      return plantNamesBn[englishName] ?? englishName;
    }
    return englishName == 'Devilbackbone' ? "Devil's Backbone" : englishName;
  }

  // Dictionary of EN and BN strings
  static const Map<String, String> _translationsEn = {
    'app_title': 'Medicinal Plant RAG',
    'app_full_title': 'Medicinal Plant Identification & Clinical RAG',
    'tab_identify': 'Identify',
    'tab_clinical': 'Clinical Hub',
    'tab_chat': 'RAG Chat',
    'tab_explorer': 'Explorer',
    'tab_history': 'History',
    'capture_specimen': 'Capture / Select Leaf',
    'take_photo': 'Take Photo',
    'pick_gallery': 'Gallery',
    'crop_rotate': 'Crop / Rotate',
    'quality_score': 'Quality Score',
    'quality_excellent': 'Excellent Quality',
    'quality_good': 'Good Quality',
    'quality_fair': 'Fair Quality',
    'quality_poor': 'Blurry / Poor Light',
    'quality_tip': 'Hold camera steady and ensure bright natural lighting for >99% accuracy.',
    'model_predictions': 'Model Predictions',
    'top_prediction': 'Top Prediction',
    'top_3_candidates': 'Top 3 Candidates',
    'generate_report': '📄 Generate Pharmacological Report',
    'regenerate_report': 'Re-Generate Report',
    'show_gradcam': 'Show Grad-CAM',
    'hide_gradcam': 'Hide Grad-CAM Heatmap',
    'clear_screen': 'Clear Screen',
    'export_report': 'Export / Share',
    'search_hint': 'Search species, indication, chemical...',
    'ask_question': 'Ask about medicinal plants...',
    'drug_interactions': 'Drug-Herb Interactions',
    'dosage_calculator': 'Dosage Calculator',
    'toxicity_guide': 'Toxicity & Emergency',
    'scan_history': 'Scan History',
    'bookmarks': 'Saved Bookmarks',
    'offline_mode': '100% Offline Vector Search',
    'exit_dialog_title': 'Exit App',
    'exit_dialog_msg': 'Are you sure you want to exit the application?',
    'stay': 'Stay',
    'exit': 'Exit',
  };

  static const Map<String, String> _translationsBn = {
    'app_title': 'ভেষজ উদ্ভিদ শনাক্তকরণ ও RAG',
    'app_full_title': 'ঔষধি উদ্ভিদ শনাক্তকরণ ও ক্লিনিক্যাল RAG অ্যাসিস্ট্যান্ট',
    'tab_identify': 'শনাক্তকরণ',
    'tab_clinical': 'ক্লিনিক্যাল হাব',
    'tab_chat': 'RAG চ্যাট',
    'tab_explorer': 'উদ্ভিদকোষ',
    'tab_history': 'ইতিহাস',
    'capture_specimen': 'পাতার ছবি তুলুন বা নির্বাচন করুন',
    'take_photo': 'ছবি তুলুন',
    'pick_gallery': 'গ্যালারি',
    'crop_rotate': 'ক্রপ / ঘোরান',
    'quality_score': 'ছবির মান',
    'quality_excellent': 'চমৎকার মান',
    'quality_good': 'ভালো মান',
    'quality_fair': 'মোটামুটি মান',
    'quality_poor': 'ঝাপসা / কম আলো',
    'quality_tip': 'স্পষ্ট ফলাফল ও ৯৯% নির্ভুলতার জন্য আলোতে স্থিরভাবে ছবি তুলুন।',
    'model_predictions': 'মডেলের ফলাফল ও বিশ্লেষণ',
    'top_prediction': 'প্রধান শনাক্তকরণ',
    'top_3_candidates': 'শীর্ষ ৩টি সম্ভাব্য প্রজাতি',
    'generate_report': '📄 ফার্মাকোলজিক্যাল রিপোর্ট তৈরি করুন',
    'regenerate_report': 'পুনরায় রিপোর্ট তৈরি করুন',
    'show_gradcam': 'Grad-CAM হিটম্যাপ দেখুন',
    'hide_gradcam': 'হিটম্যাপ লুকান',
    'clear_screen': 'স্ক্রিন পরিষ্কার করুন',
    'export_report': 'এক্সপোর্ট / শেয়ার',
    'search_hint': 'নাম, রোগ নিরাময়, রাসায়নিক খুঁজুন...',
    'ask_question': 'ভেষজ উদ্ভিদ সম্পর্কে যেকোনো প্রশ্ন করুন...',
    'drug_interactions': 'ওষুধ ও ভেষজ মিথস্ক্রিয়া',
    'dosage_calculator': 'মাত্রা ও প্রস্তুত ক্যালকুলেটর',
    'toxicity_guide': 'বিষাক্ততা ও জরুরি নির্দেশিকা',
    'scan_history': 'শনাক্তকরণের ইতিহাস',
    'bookmarks': 'সংরক্ষিত প্রজাতি',
    'offline_mode': '১০০% অফলাইন ভেক্টর সার্চ',
    'exit_dialog_title': 'অ্যাপ বন্ধ করবেন?',
    'exit_dialog_msg': 'আপনি কি নিশ্চিতভাবে অ্যাপ থেকে বের হতে চান?',
    'stay': 'থাকুন',
    'exit': 'বের হন',
  };
}
