import 'dart:convert';
import 'package:http/http.dart' as http;

class SponsorSegment {
  final double start;
  final double end;
  final String category;

  SponsorSegment({
    required this.start,
    required this.end,
    required this.category,
  });

  factory SponsorSegment.fromJson(Map<String, dynamic> json) {
    // API returns segment as [start, end]
    final List<dynamic> segment = json['segment'] ?? [0.0, 0.0];
    return SponsorSegment(
      start: (segment[0] as num).toDouble(),
      end: (segment[1] as num).toDouble(),
      category: json['category'] ?? 'unknown',
    );
  }
}

class SponsorBlockService {
  static const String baseUrl = 'https://sponsor.ajay.app/api';

  Future<List<SponsorSegment>> getSegments(String videoId) async {
    try {
      final categories = [
        'sponsor',
        'intro',
        'outro',
        'interaction',
        'selfpromo',
        'music_offtopic'
      ];

      final queryParams = categories.map((c) => 'category=$c').join('&');
      final url = '$baseUrl/skipSegments?videoID=$videoId&$queryParams';

      print('SponsorBlock: Fetching segments for $videoId');
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final segments = data
            .map(
                (json) => SponsorSegment.fromJson(json as Map<String, dynamic>))
            .toList();
        print('SponsorBlock: Found ${segments.length} segments for $videoId');
        return segments;
      } else if (response.statusCode == 404) {
        print('SponsorBlock: No segments found for $videoId');
        return [];
      } else {
        print(
            'SponsorBlock: API error ${response.statusCode}: ${response.body}');
        return [];
      }
    } catch (e) {
      print('SponsorBlock: Error fetching segments: $e');
      return [];
    }
  }
}
