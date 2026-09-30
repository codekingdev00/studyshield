import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'models/study_material.dart';

/// Base URL of the Cloudflare Worker backend, e.g.
/// `https://studyfocus-api.your-subdomain.workers.dev`.
///
/// Set this once your Worker is deployed (see backend/README.md).
const String kApiBaseUrl = 'https://studyfocus-api.codekingdev03.workers.dev';

const _cacheKey = 'cached_study_groups_v1';

/// Fetches study groups/materials from the backend, falling back to the
/// last cached response, and finally to the bundled sample data if neither
/// is available (e.g. first run with no internet).
class StudyApi {
  StudyApi._();

  static Future<List<StudyGroup>> fetchGroups() async {
    try {
      final res = await http
          .get(Uri.parse('$kApiBaseUrl/api/materials'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final groups = (data['groups'] as List)
            .map((g) => StudyGroup.fromJson(g as Map<String, dynamic>))
            .toList();
        _cache(groups);
        return groups;
      }
    } catch (_) {
      // Network unavailable or backend unreachable — fall through to cache.
    }

    final cached = await _readCache();
    if (cached != null) return cached;

    return [fallbackStudyGroup];
  }

  static Future<void> _cache(List<StudyGroup> groups) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded =
          jsonEncode(groups.map((g) => g.toJson()).toList());
      await prefs.setString(_cacheKey, encoded);
    } catch (_) {
      // Caching is best-effort.
    }
  }

  static Future<List<StudyGroup>?> _readCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return null;
      final list = jsonDecode(raw) as List;
      return list
          .map((g) => StudyGroup.fromJson(g as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
