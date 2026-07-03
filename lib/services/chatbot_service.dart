import 'package:cloud_functions/cloud_functions.dart';
import 'package:you_app/services/base/app_log.dart';

/// Result of a Dodo turn. Either the free daily cap was hit ([capReached]) or a
/// [reply] is available.
class DodoResponse {
  final bool capReached;
  final String reply;
  const DodoResponse({required this.capReached, this.reply = ''});
}

/// Talks to Dodo via the `sendDodoMessage` callable Cloud Function. The Groq API
/// key now lives server-side (Functions secret), and the function enforces the
/// free-tier daily cap authoritatively — the client no longer contacts Groq
/// directly and cannot see or count around the limit.
class ChatbotService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<DodoResponse> generateResponse(
      List<Map<String, String>> history) async {
    try {
      final result = await _functions.httpsCallable('sendDodoMessage').call({
        'history': history
            .map((m) => {
                  'isMe': m['isMe'] ?? 'false',
                  'text': m['text'] ?? '',
                })
            .toList(),
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['capReached'] == true) {
        return const DodoResponse(capReached: true);
      }
      return DodoResponse(
        capReached: false,
        reply: (data['reply'] ?? '').toString(),
      );
    } on FirebaseFunctionsException catch (e) {
      AppLog.error('ChatbotService.generateResponse', '${e.code}: ${e.message}');
      rethrow;
    } catch (e) {
      AppLog.error('ChatbotService.generateResponse', e);
      rethrow;
    }
  }
}
