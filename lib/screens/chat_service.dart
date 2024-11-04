// chat_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class ChatService {
  final String apiUrl =
      'https://expertstrials.xyz/Garifix_app'; // Your server URL
  Timer? _pollingTimer;

  void startLongPolling(
      Function(List<Map<String, dynamic>>) onMessageReceived) {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final response = await http.get(Uri.parse('$apiUrl/messages'));
      if (response.statusCode == 200) {
        List<dynamic> jsonMessages = json.decode(response.body);
        List<Map<String, dynamic>> messages = jsonMessages
            .map((msg) => {
                  'text': msg,
                  'sender': 'Mechanic', // Adjust this as necessary
                  'avatar':
                      'https://example.com/avatar.png', // Placeholder avatar URL
                  'time': DateTime.now().toString(), // Replace with actual time
                })
            .toList();
        onMessageReceived(messages);
      } else {
        print("Error fetching messages: ${response.statusCode}");
      }
    });
  }

  void stopLongPolling() {
    _pollingTimer?.cancel();
  }

  Future<void> sendMessage(String message, String mechanicName) async {
    final response = await http.post(
      Uri.parse('$apiUrl/send'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'message': message,
        'mechanic_name': mechanicName, // Send mechanic name along with message
      }),
    );

    if (response.statusCode == 200) {
      print("Message sent successfully.");
    } else {
      print("Failed to send message: ${response.body}");
    }
  }
}
