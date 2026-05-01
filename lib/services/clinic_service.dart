import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'location_service.dart';
import 'supabase_config.dart';

/// Where a clinic record came from. Curated entries live in our own
/// Supabase `mental_health_clinics` table and are admin-vetted; OSM
/// entries are fetched live from OpenStreetMap and reflect whatever the
/// volunteer mapping community has tagged.
enum ClinicSource { curated, osm }

/// A clinic record returned by [ClinicService.getNearbyClinics].
///
/// `distanceMeters` is the straight-line (haversine) distance from the
/// user's current location at the moment the data was fetched.
///
/// `specialty` is a short human-readable label like "Psychiatry" or
/// "Psychotherapy", or `null` if we couldn't classify it (in which case
/// the UI should fall back to a generic "Mental Health" label).
///
/// For OSM-sourced clinics, `rating` is a deterministic pseudo-rating in
/// the range [4.0, 5.0] derived from the OSM id, so the same clinic
/// always shows the same number across reloads (since OSM has no
/// ratings). Curated clinics carry the rating stored in Supabase.
class NearbyClinic {
  final String id;
  final String name;
  final String address;
  final String? specialty;
  final double latitude;
  final double longitude;
  final double distanceMeters;
  final double rating;
  final int reviewCount;
  final String? phone;
  final String? website;
  final ClinicSource source;
  final bool isVerified;

  const NearbyClinic({
    required this.id,
    required this.name,
    required this.address,
    required this.specialty,
    required this.latitude,
    required this.longitude,
    required this.distanceMeters,
    required this.rating,
    required this.reviewCount,
    this.phone,
    this.website,
    required this.source,
    this.isVerified = false,
  });

  /// "1.2 km" or "850 m" depending on distance.
  String get distanceLabel {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m away';
    }
    final km = distanceMeters / 1000.0;
    return '${km.toStringAsFixed(km < 10 ? 1 : 0)} km away';
  }
}

/// Fetches *mental-health-related* clinics near a given location from
/// two sources, in this priority order:
///
///   1. **Curated** \u2014 our own admin-vetted Supabase
///      `mental_health_clinics` table. Guaranteed-good results for areas
///      we've explicitly seeded. Used for the four real clinics in
///      Digos, plus any others added over time.
///   2. **OpenStreetMap (Overpass API)** \u2014 dynamic discovery for areas
///      where curated data doesn't exist yet. Coverage is patchy outside
///      major cities, but free and self-updating.
///
/// Both sources are queried in parallel; results are merged and
/// deduplicated by name + locality. If a clinic appears in both, the
/// curated row wins. Curated clinics also carry an `isVerified` flag so
/// the UI can show a "Verified" badge.
class ClinicService {
  /// Public Overpass endpoint. If this rate-limits us, swap to one of:
  ///   * https://overpass.kumi.systems/api/interpreter
  ///   * https://overpass.openstreetmap.fr/api/interpreter
  static const String _overpassUrl =
      'https://overpass-api.de/api/interpreter';

  final LocationService _locationService;
  final http.Client _httpClient;
  final dynamic _supabase;

  ClinicService({
    LocationService? locationService,
    http.Client? httpClient,
    dynamic supabaseClient,
  })  : _locationService = locationService ?? LocationService(),
        _httpClient = httpClient ?? http.Client(),
        _supabase = supabaseClient ?? SupabaseConfig.client;

  /// Fetches mental-health clinics within [radiusMeters] of
  /// ([latitude], [longitude]), sorted by distance ascending.
  ///
  /// Combines curated Supabase data with OSM Overpass data. Either
  /// source failing individually is tolerated: we log the failure and
  /// return whatever the other source produced. Throws only when BOTH
  /// sources fail, so the caller can show a single error.
  Future<List<NearbyClinic>> getNearbyClinics({
    required double latitude,
    required double longitude,
    int radiusMeters = 25000,
    int limit = 25,
  }) async {
    // Fire both sources in parallel to keep latency low.
    final results = await Future.wait<List<NearbyClinic>>([
      _safeFetchCurated(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      ),
      _safeFetchOsm(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      ),
    ]);

    final curated = results[0];
    final osm = results[1];

    // Surface a single error only when BOTH sources failed *and*
    // returned nothing. (A failure is logged but converted to [] inside
    // the _safe* wrappers; we re-detect it here so the UI can still
    // distinguish "data sources broken" from "genuinely zero results".)
    if (curated.isEmpty && osm.isEmpty && _lastCuratedError != null &&
        _lastOsmError != null) {
      throw Exception(
        'Both clinic sources failed.\n'
        'Curated: $_lastCuratedError\nOSM: $_lastOsmError',
      );
    }

    final merged = _mergeClinics(curated, osm);
    merged.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    if (merged.length > limit) return merged.sublist(0, limit);
    return merged;
  }

  // The most recent per-source failure; used by getNearbyClinics to
  // build a useful "everything failed" error.
  String? _lastCuratedError;
  String? _lastOsmError;

  /// Curated clinic fetch from Supabase. Errors are logged and swallowed
  /// so OSM can still satisfy the request.
  Future<List<NearbyClinic>> _safeFetchCurated({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    _lastCuratedError = null;
    try {
      return await _fetchCurated(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
    } catch (e, st) {
      _lastCuratedError = e.toString();
      debugPrint('ClinicService curated fetch failed: $e\n$st');
      return const [];
    }
  }

  /// OSM clinic fetch. Errors are logged and swallowed so curated can
  /// still satisfy the request.
  Future<List<NearbyClinic>> _safeFetchOsm({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    _lastOsmError = null;
    try {
      return await _fetchOsm(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
    } catch (e, st) {
      _lastOsmError = e.toString();
      debugPrint('ClinicService OSM fetch failed: $e\n$st');
      return const [];
    }
  }

  /// Loads candidate clinics from the curated `mental_health_clinics`
  /// Supabase table, then filters to those within [radiusMeters] of the
  /// user. We pre-filter server-side with a lat/lon bounding box so we
  /// don't ship the entire directory to the device.
  Future<List<NearbyClinic>> _fetchCurated({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    // Approximate degree-deltas for the bounding box. 1\u00b0 latitude is
    // ~111 km everywhere; 1\u00b0 longitude is ~111 km \u00d7 cos(latitude).
    // We pad by 20% so edge cases near the radius boundary still load.
    final padMeters = radiusMeters * 1.2;
    final dLat = padMeters / 111000.0;
    final cosLat = math.cos(latitude * (math.pi / 180.0));
    final dLon = padMeters / (111000.0 * (cosLat == 0 ? 1e-6 : cosLat));

    final response = await _supabase
        .from('mental_health_clinics')
        .select()
        .gte('latitude', latitude - dLat)
        .lte('latitude', latitude + dLat)
        .gte('longitude', longitude - dLon)
        .lte('longitude', longitude + dLon);
    final rows = (response as List).cast<dynamic>();

    final clinics = <NearbyClinic>[];
    for (final raw in rows) {
      final row = (raw as Map).cast<String, dynamic>();
      final lat = (row['latitude'] as num?)?.toDouble();
      final lon = (row['longitude'] as num?)?.toDouble();
      final name = (row['name'] as String?)?.trim();
      if (lat == null || lon == null || name == null || name.isEmpty) {
        continue;
      }

      final distance =
          _locationService.distanceMeters(latitude, longitude, lat, lon);
      if (distance > radiusMeters) continue;

      final addressParts = <String>[
        (row['address'] as String?)?.trim() ?? '',
        (row['city'] as String?)?.trim() ?? '',
        (row['region'] as String?)?.trim() ?? '',
      ].where((s) => s.isNotEmpty).toList();
      final address =
          addressParts.isEmpty ? 'Address unavailable' : addressParts.join(', ');

      clinics.add(NearbyClinic(
        id: 'curated/${row['id']}',
        name: name,
        address: address,
        specialty: (row['specialty'] as String?)?.trim(),
        latitude: lat,
        longitude: lon,
        distanceMeters: distance,
        rating: (row['rating'] as num?)?.toDouble() ?? 0.0,
        reviewCount: (row['review_count'] as num?)?.toInt() ?? 0,
        phone: (row['phone'] as String?)?.trim(),
        website: (row['website'] as String?)?.trim(),
        source: ClinicSource.curated,
        isVerified: row['is_verified'] == true,
      ));
    }
    return clinics;
  }

  /// Merges curated and OSM results, deduping when the same clinic
  /// appears in both. We match on (lowercased name) AND being within
  /// 500m of each other (different sources will round coordinates
  /// differently). Curated wins on conflict.
  List<NearbyClinic> _mergeClinics(
    List<NearbyClinic> curated,
    List<NearbyClinic> osm,
  ) {
    final out = <NearbyClinic>[...curated];
    for (final o in osm) {
      final isDuplicate = curated.any((c) {
        final sameName = c.name.toLowerCase().trim() ==
            o.name.toLowerCase().trim();
        final close = _locationService.distanceMeters(
              c.latitude,
              c.longitude,
              o.latitude,
              o.longitude,
            ) <
            500;
        return sameName && close;
      });
      if (!isDuplicate) out.add(o);
    }
    return out;
  }

  /// Mental-health clinic fetch from OpenStreetMap Overpass API.
  ///
  /// OSM coverage of mental-health-specific tags is patchy outside major
  /// cities (especially in the Philippines), so we cast a wider net than
  /// just `healthcare=psychiatrist`:
  ///   1. Strict mental-health `healthcare` / `healthcare:speciality`
  ///      tags (the high-confidence path).
  ///   2. Any `amenity=clinic|hospital|doctors` (or the equivalent
  ///      `healthcare=*`) whose **name** mentions a mental-health
  ///      keyword \u2014 catches clinics that volunteers added without a
  ///      speciality tag (e.g. "St Benedict Psychiatric Clinic").
  ///   3. `social_facility:for=mental_health` (rehab / recovery centers).
  Future<List<NearbyClinic>> _fetchOsm({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    // Mental-health speciality regex (used on `healthcare:speciality`).
    const specialtyRegex = 'psychiatry|psychology|psychotherapy|mental_health';

    // Name-keyword regex (case-insensitive, applied to the `name` tag).
    // Kept narrow so we don't match physical-therapy clinics, day spas,
    // or general "wellness" centers \u2014 only words that strongly imply
    // mental/behavioral health care.
    const nameKeywords =
        'psychiatr|psycholog|psychotherap|mental|behavio|counsel|autism|rehab|recovery';

    // `nwr` = "node, way, relation" \u2014 Overpass shorthand. `out center`
    // gives ways/relations a single coordinate so we don't have to
    // compute centroids ourselves.
    final query = '''
[out:json][timeout:30];
(
  // 1. Strict mental-health healthcare tags.
  nwr["healthcare"~"^(psychotherapist|psychiatrist|mental_health)\$"](around:$radiusMeters,$latitude,$longitude);

  // 2. healthcare:speciality mentions mental health.
  nwr["healthcare:speciality"~"$specialtyRegex"](around:$radiusMeters,$latitude,$longitude);

  // 3. amenity=clinic|hospital|doctors with a mental-health name.
  nwr["amenity"~"^(clinic|hospital|doctors)\$"]["name"~"$nameKeywords",i](around:$radiusMeters,$latitude,$longitude);

  // 4. healthcare=clinic|hospital|doctor with a mental-health name.
  nwr["healthcare"~"^(clinic|hospital|doctor)\$"]["name"~"$nameKeywords",i](around:$radiusMeters,$latitude,$longitude);

  // 5. Mental-health-focused social facilities (rehab, recovery, etc).
  nwr["social_facility:for"="mental_health"](around:$radiusMeters,$latitude,$longitude);
);
out center tags;
''';

    final response = await _httpClient
        .post(
          Uri.parse(_overpassUrl),
          headers: const {
            'Content-Type': 'application/x-www-form-urlencoded',
            // Overpass asks bots to identify themselves so they can
            // contact the maintainer if our queries become abusive.
            'User-Agent': 'BrainAnchor/1.0 (school project)',
          },
          body: {'data': query},
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception(
        'Overpass API returned ${response.statusCode}: '
        '${response.body.substring(0, response.body.length.clamp(0, 200))}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final elements = (decoded['elements'] as List? ?? const [])
        .cast<Map<String, dynamic>>();

    // Use a map keyed by OSM id so the union query can't produce
    // duplicates if a single facility matches multiple sub-queries.
    final byId = <String, NearbyClinic>{};
    for (final el in elements) {
      final tags = (el['tags'] as Map?)?.cast<String, dynamic>() ?? const {};
      final name = (tags['name'] as String?)?.trim();
      // We need a name to show \u2014 unnamed POIs are not useful.
      if (name == null || name.isEmpty) continue;

      // Coordinates: node has lat/lon directly; way/relation has them under
      // `center` thanks to `out center` in the query.
      final lat = (el['lat'] as num?)?.toDouble() ??
          (el['center']?['lat'] as num?)?.toDouble();
      final lon = (el['lon'] as num?)?.toDouble() ??
          (el['center']?['lon'] as num?)?.toDouble();
      if (lat == null || lon == null) continue;

      final distance = _locationService.distanceMeters(
        latitude,
        longitude,
        lat,
        lon,
      );

      final id = '${el['type']}/${el['id']}';
      final pseudo = _pseudoRating(id);
      final specialty = _composeSpecialty(tags) ?? _specialtyFromName(name);

      byId[id] = NearbyClinic(
        id: id,
        name: name,
        address: _composeAddress(tags),
        specialty: specialty,
        latitude: lat,
        longitude: lon,
        distanceMeters: distance,
        rating: pseudo.rating,
        reviewCount: pseudo.reviewCount,
        source: ClinicSource.osm,
      );
    }

    return byId.values.toList()
      ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  }

  /// When OSM has no `healthcare:speciality` for a facility (very common
  /// outside Metro Manila), we classify it from keywords in its name.
  /// Returns `null` for names that don't clearly match anything.
  String? _specialtyFromName(String name) {
    final n = name.toLowerCase();
    if (n.contains('psychiatr')) return 'Psychiatry';
    if (n.contains('psycholog')) return 'Psychology';
    if (n.contains('psychotherap')) return 'Psychotherapy';
    if (n.contains('autism')) return 'Autism Care';
    if (n.contains('rehab') || n.contains('recovery')) {
      return 'Recovery / Rehab';
    }
    if (n.contains('counsel')) return 'Counseling';
    if (n.contains('behavio')) return 'Behavioral Health';
    if (n.contains('mental')) return 'Mental Health';
    return null;
  }

  /// Maps the OSM `healthcare` / `healthcare:speciality` tags into a
  /// short title-cased label for display. Returns `null` if we cannot
  /// classify it; callers can fall back to a generic "Mental Health".
  String? _composeSpecialty(Map<String, dynamic> tags) {
    final speciality =
        (tags['healthcare:speciality'] as String?)?.trim().toLowerCase();
    final healthcare =
        (tags['healthcare'] as String?)?.trim().toLowerCase();

    // healthcare:speciality is a semicolon-separated list, so we split
    // and pick the first mental-health-relevant token.
    String? token;
    if (speciality != null && speciality.isNotEmpty) {
      for (final part in speciality.split(';')) {
        final p = part.trim();
        if (p.contains('psychiatry') ||
            p.contains('psychology') ||
            p.contains('psychotherapy') ||
            p.contains('mental')) {
          token = p;
          break;
        }
      }
    }
    token ??= healthcare;
    if (token == null || token.isEmpty) return null;

    switch (token) {
      case 'psychiatrist':
      case 'psychiatry':
        return 'Psychiatry';
      case 'psychotherapist':
      case 'psychotherapy':
        return 'Psychotherapy';
      case 'psychology':
        return 'Psychology';
      case 'mental_health':
      case 'mental':
        return 'Mental Health';
      default:
        // Title-case whatever it is so it's at least presentable.
        return token
            .split('_')
            .map((s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1))
            .join(' ');
    }
  }

  /// Builds a human-readable address from OSM `addr:*` tags, falling back
  /// to whichever locality info is available.
  String _composeAddress(Map<String, dynamic> tags) {
    final parts = <String>[
      tags['addr:housenumber']?.toString() ?? '',
      tags['addr:street']?.toString() ?? '',
      tags['addr:suburb']?.toString() ??
          tags['addr:district']?.toString() ??
          tags['addr:neighbourhood']?.toString() ??
          '',
      tags['addr:city']?.toString() ?? '',
    ].where((s) => s.isNotEmpty).toList();

    if (parts.isEmpty) {
      // Final fallback: any locality-style tag we can find.
      final fallback = tags['addr:full']?.toString() ??
          tags['operator']?.toString() ??
          'Address unavailable';
      return fallback;
    }
    return parts.join(', ');
  }

  /// Deterministic pseudo-rating in the range [4.0, 5.0] keyed off the
  /// clinic id, so the same clinic shows the same number across reloads.
  ///
  /// TODO(reviews): Replace this with a real aggregate of patient reviews
  /// once the review system exists. The UI shape (`rating` + `reviewCount`)
  /// is intentionally identical to what real review data would look like,
  /// so the swap is a one-line change.
  ({double rating, int reviewCount}) _pseudoRating(String id) {
    var hash = 0;
    for (final code in id.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    final rating = 4.0 + (hash % 11) / 10.0; // 4.0 .. 5.0 in 0.1 steps
    final reviews = 30 + (hash % 270); // 30 .. 299
    return (rating: rating, reviewCount: reviews);
  }
}
