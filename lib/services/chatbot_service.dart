import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:you_app/env.dart';

class ChatbotService {
  final String _apiKey = Environments.dodoAPIKey;

  Future<String> generateResponse(List<Map<String, String>> history) async {
    final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    // 1. Explicitly initialize an empty List of Map<String, dynamic>
    final List<Map<String, dynamic>> messages = [];

    // 2. Prepend the System Prompt first
    messages.add({
      'role': 'system',
      'content':
          'You are Dodo, a comforting, empathetic, and exceptionally supportive mental health assistant. Do not break character. Provide short, practical, warm, and highly compassionate assistance to the user. Do not give medical diagnoses.'
    });

    // 3. Use an explicit for-loop to safely read and map the history
    for (var msg in history) {
      final role = msg['isMe'] == 'true' ? 'user' : 'assistant';

      messages.add({
        'role': role,
        'content': msg['text'] ?? '', // Safeguard against null values
      });
    }

    final payload = {
      'model': 'llama-3.1-8b-instant',
      'messages': messages,
      'temperature': 0.7,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        try {
          final text = data['choices'][0]['message']['content'];
          return text;
        } catch (e) {
          return "I'm having a little trouble focusing right now. Could you repeat that?";
        }
      } else {
        print("Groq API Error: ${response.body}");
        throw Exception(
            "Failed to contact Groq API. Status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error in ChatbotService: $e");
      throw Exception("Network error occurred.");
    }
  }
}

// import 'dart:convert';
// import 'dart:io';
// import 'package:you_app/env.dart';

// class ChatbotService {
//   final String _apiKey = Environments.googleGeminiKey;

//   /// Sends the conversation history to Gemini and retrieves the AI's response.
//   /// The [history] list expects maps with two keys: 'isMe' (String 'true' or 'false') and 'text' (String).
//   Future<String> generateResponse(List<Map<String, String>> history) async {
//     final url = Uri.parse(
//         'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$_apiKey');

//     // Map our local history state to Gemini's expected format
//     final contents = history.map((msg) {
//       final role = msg['isMe'] == 'true' ? 'user' : 'model';
//       return {
//         'role': role,
//         'parts': [
//           {'text': msg['text']}
//         ]
//       };
//     }).toList();

//     // Payload configured with system instructions to mold 'Dodo's personality
//     final payload = {
//       'systemInstruction': {
//         'parts': [
//           {
//             'text':
//                 'You are Dodo, a comforting, empathetic, and exceptionally supportive mental health assistant. Do not break character. Provide short, practical, warm, and highly compassionate assistance to the user. Do not give medical diagnoses.'
//           }
//         ]
//       },
//       'contents': contents,
//       'generationConfig': {
//         'temperature': 0.7,
//       }
//     };

//     try {
//       final request = await HttpClient().postUrl(url);
//       request.headers.set('Content-Type', 'application/json');
//       request.add(utf8.encode(jsonEncode(payload)));

//       final response = await request.close();
//       final responseBody = await response.transform(utf8.decoder).join();

//       if (response.statusCode == 200) {
//         final data = jsonDecode(responseBody);
//         try {
//           final text = data['candidates'][0]['content']['parts'][0]['text'];
//           return text;
//         } catch (e) {
//           return "I'm having a little trouble focusing right now. Could you repeat that?";
//         }
//       } else {
//         print("Gemini API Error: $responseBody");
//         throw Exception(
//             "Failed to contact Gemini API. Status code: ${response.statusCode}");
//       }
//     } catch (e) {
//       print("Error in ChatbotService: $e");
//       throw Exception("Network error occurred.");
//     }
//   }
// }
