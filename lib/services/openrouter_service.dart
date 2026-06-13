import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OpenRouterException implements Exception {
  final String message;
  OpenRouterException(this.message);
  @override
  String toString() => message;
}

class OpenRouterService {
  static const String _apiKeyKey = 'openrouter_api_key';
  static const String _apiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _defaultModel = 'openrouter/auto'; // Let OpenRouter auto-select the best model

  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiKeyKey, apiKey);
  }

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyKey);
  }

  Future<dynamic> analyzeText(String systemPrompt, String documentText, {bool isFormatter = false}) async {
    final apiKey = await getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw OpenRouterException('No API key set. Add your OpenRouter API key in Settings to enable analysis.');
    }

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _defaultModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': documentText},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw OpenRouterException('Error ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body);
    final String contentString = data['choices'][0]['message']['content'] ?? '';

    String cleanContent = contentString;
    if (isFormatter) {
      final match = RegExp(r'\{.*\}', dotAll: true).firstMatch(cleanContent);
      if (match != null) cleanContent = match.group(0)!;
    } else {
      final match = RegExp(r'\[.*\]', dotAll: true).firstMatch(cleanContent);
      if (match != null) cleanContent = match.group(0)!;
    }

    try {
      final parsedJson = jsonDecode(cleanContent);
      if (isFormatter) {
        if (parsedJson is! Map<String, dynamic>) {
          throw const FormatException();
        }
      } else {
        if (parsedJson is! List) {
          throw const FormatException();
        }
      }
      return parsedJson;
    } catch (e) {
      throw OpenRouterException('AI returned invalid JSON. Try rephrasing or reducing input length.');
    }
  }
}
