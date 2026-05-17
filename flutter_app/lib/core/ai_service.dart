/// AgriSutra NE — AI Service (Groq LLaMA-3)
/// ============================================
/// Mirrors the `get_explainable_summary_table()` function in the Streamlit
/// app.py.  Calls the Groq REST endpoint directly so no extra package is
/// needed — we already have `http` in pubspec.yaml.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secrets.dart';

class AiService {
  static const _url = 'https://api.groq.com/openai/v1/chat/completions';
  static const _model = 'llama-3.3-70b-versatile';

  /// Returns a markdown-formatted explainable summary for the fertilizer
  /// recommendation.  Throws [AiException] on any failure.
  static Future<String> getExplainableSummary({
    required String crop,
    required double yieldTarget,
    required double ureaKg,
    required double sspKg,
    required double mopKg,
    String? weatherContext,
  }) async {
    final prompt = _buildPrompt(
      crop: crop,
      yieldTarget: yieldTarget,
      ureaKg: ureaKg,
      sspKg: sspKg,
      mopKg: mopKg,
      weatherContext: weatherContext,
    );

    final response = await http
        .post(
          Uri.parse(_url),
          headers: {
            'Authorization': 'Bearer ${Secrets.groqApiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': _model,
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an expert agricultural scientist working with ICAR data for Northeast India. '
                    'Provide clear, concise, markdown-formatted tables and advice. '
                    'Keep the response under 400 words.',
              },
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.3,
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      return body['choices'][0]['message']['content'] as String;
    } else if (response.statusCode == 401) {
      throw AiException('Invalid API key. Please check your Groq API key in secrets.dart.');
    } else {
      throw AiException('Groq API error ${response.statusCode}: ${response.body}');
    }
  }

  static String _buildPrompt({
    required String crop,
    required double yieldTarget,
    required double ureaKg,
    required double sspKg,
    required double mopKg,
    String? weatherContext,
  }) {
    var prompt =
        'We are recommending fertilizers for $crop with a target yield of '
        '${yieldTarget.toStringAsFixed(0)} q/ha using STCR (Soil Test Crop Response) methodology '
        'from ICAR Research Complex for NEH Region.\n'
        'The recommended amounts are: ${ureaKg.toStringAsFixed(1)} kg Urea, '
        '${sspKg.toStringAsFixed(1)} kg SSP, and ${mopKg.toStringAsFixed(1)} kg MOP '
        '(total for the farm, based on actual land size).\n';

    if (weatherContext != null && weatherContext.isNotEmpty) {
      prompt +=
          '\nLocal weather context: $weatherContext '
          'Please briefly mention how this affects application timing and nutrient uptake.\n';
    }

    prompt +=
        '\nProvide a detailed, explainable, technical summary. '
        'Include a clear markdown table breaking down each fertilizer: '
        'nutrient supplied, role in crop growth, and best application timing. '
        'Add a brief agronomic rationale section. '
        'Format the response in clean markdown.';

    return prompt;
  }
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);

  @override
  String toString() => 'AiException: $message';
}
