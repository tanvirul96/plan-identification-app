import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/scan_record.dart';

class HistoryService {
  static final HistoryService _instance = HistoryService._internal();
  factory HistoryService() => _instance;
  HistoryService._internal();

  static const String _storageKey = 'plant_identification_scans_v1';
  final ValueNotifier<List<ScanRecord>> scansNotifier =
      ValueNotifier<List<ScanRecord>>([]);

  Future<void> init() async {
    await loadScans();
  }

  Future<void> loadScans() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(_storageKey) ?? [];
      final loaded = rawList
          .map((item) {
            try {
              return ScanRecord.fromMap(
                  jsonDecode(item) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<ScanRecord>()
          .toList();

      // Sort newest first
      loaded.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      scansNotifier.value = loaded;
    } catch (e) {
      debugPrint('Error loading scan history: $e');
    }
  }

  Future<void> saveScan(ScanRecord record) async {
    try {
      final current = List<ScanRecord>.from(scansNotifier.value);
      current.insert(0, record);
      // Keep up to 100 recent scans
      if (current.length > 100) {
        current.removeLast();
      }
      scansNotifier.value = current;
      await _persistToStorage(current);
    } catch (e) {
      debugPrint('Error saving scan: $e');
    }
  }

  Future<void> toggleBookmark(String id) async {
    try {
      final current = List<ScanRecord>.from(scansNotifier.value);
      final idx = current.indexWhere((s) => s.id == id);
      if (idx != -1) {
        current[idx].isBookmarked = !current[idx].isBookmarked;
        scansNotifier.value = current;
        await _persistToStorage(current);
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
    }
  }

  Future<void> deleteScan(String id) async {
    try {
      final current = List<ScanRecord>.from(scansNotifier.value);
      current.removeWhere((s) => s.id == id);
      scansNotifier.value = current;
      await _persistToStorage(current);
    } catch (e) {
      debugPrint('Error deleting scan: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      scansNotifier.value = [];
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      debugPrint('Error clearing scans: $e');
    }
  }

  Future<void> _persistToStorage(List<ScanRecord> list) async {
    final prefs = await SharedPreferences.getInstance();
    final stringList = list.map((e) => jsonEncode(e.toMap())).toList();
    await prefs.setStringList(_storageKey, stringList);
  }
}
