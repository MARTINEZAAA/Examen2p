import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/character.dart';

class CharacterApi {
  CharacterApi({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://rickandmortyapi.com/api/character';
  final http.Client _client;

  Future<List<Character>> fetchAllCharacters() async {
    final characters = <Character>[];
    var nextUrl = Uri.parse(_baseUrl);

    while (true) {
      final response = await _client
          .get(nextUrl)
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) {
        throw Exception(
          'La API respondió con el código ${response.statusCode}.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>? ?? const [];
      characters.addAll(
        results.map((item) => Character.fromJson(item as Map<String, dynamic>)),
      );

      final info = data['info'] as Map<String, dynamic>?;
      final next = info?['next'] as String?;
      if (next == null || next.isEmpty) break;
      nextUrl = Uri.parse(next);
    }

    return characters;
  }

  void dispose() => _client.close();
}
