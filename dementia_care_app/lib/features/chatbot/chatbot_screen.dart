import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

const Color coral = Color(0xFFFF6B6B);
const Color babyPink = Color(0xFFFFF5F5);
class MicPulse extends StatefulWidget {
  final bool isListening;

  const MicPulse({super.key, required this.isListening});

  @override
  State<MicPulse> createState() => _MicPulseState();
}

class _MicPulseState extends State<MicPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant MicPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (_, child) {
        return Transform.scale(
          scale: widget.isListening ? _scaleAnimation.value : 1.0,
          child: child,
        );
      },
      child: const Icon(Icons.mic, color: coral, size: 28),
    );
  }
}

class PatientChatbotScreen extends StatefulWidget {
  final String patientId;
  const PatientChatbotScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  State<PatientChatbotScreen> createState() => _PatientChatbotScreenState();
}

class _PatientChatbotScreenState extends State<PatientChatbotScreen> {
  final List<Map<String, String>> messages = [];
  final TextEditingController _controller = TextEditingController();
  final FlutterTts tts = FlutterTts();
  final stt.SpeechToText speech = stt.SpeechToText();
  final ScrollController _scrollController = ScrollController();

  bool isListening = false;
  bool isTyping = false;

  @override
  void initState() {
    super.initState();
    tts.setSpeechRate(0.5);
    tts.setPitch(1.0);
  }

Future<void> handleSend(String userMessage) async {
  if (userMessage.trim().isEmpty) return;

  setState(() {
    messages.add({'role': 'user', 'text': userMessage});
    _controller.clear();
    isTyping = true;
  });

  _scrollToBottom();

  try {
    final response = await http.post(
      Uri.parse('https://us-central1-dementia-care-9bbf2.cloudfunctions.net/chatbotReply'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': userMessage,
        'patientId': widget.patientId,
      }),
    );

    final body = jsonDecode(response.body);
    final reply = body['reply'] ?? "I'm not sure how to respond to that.";
    final ttsReply = body['tts'] ?? reply;

    if (reply.startsWith("IMAGE:")) {
      final urls = reply.replaceFirst("IMAGE:", "").trim().split(" ");
      setState(() {
        messages.add({'role': 'bot', 'text': "Here are some of your photos!"});
        for (var url in urls) {
          messages.add({'role': 'bot', 'image': url});
        }
        isTyping = false;
      });
      // Only speak the friendly caption, not the image URLs
      await tts.speak("Here are some of your memory photos.");
    } else {
      setState(() {
        messages.add({'role': 'bot', 'text': reply});
        isTyping = false;
      });
      await tts.speak(ttsReply);
    }

    _scrollToBottom();
  } catch (e) {
    setState(() {
      messages.add({'role': 'bot', 'text': 'Sorry, I had trouble understanding. Try again!'});
      isTyping = false;
    });
    print("❌ Chatbot error: $e");
  }
}






  void startListening() async {
  final available = await speech.initialize();
  if (available) {
    setState(() => isListening = true);

    speech.listen(
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
        });

        if (result.finalResult) {
          handleSend(result.recognizedWords);
          setState(() => isListening = false);
        }
      },
    );
  }
}


  void stopListening() async {
    await speech.stop();
    setState(() => isListening = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _buildBotTypingBubble() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: coral,
            child: Icon(Icons.face, color: Colors.white),
            radius: 16,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text("Typing...", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

 Widget _buildMessageBubble(Map<String, String> msg) {
  final isUser = msg['role'] == 'user';
  final isImage = msg.containsKey('image');

  if (isImage) {
  return Container(
    alignment: Alignment.centerLeft,
    margin: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          backgroundColor: coral,
          child: Icon(Icons.face, color: Colors.white),
          radius: 16,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            msg['image']!,
            height: 160,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Text("Image failed to load"),
           ),
         ),
       ],
     ),
   );
  }

  return AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    margin: const EdgeInsets.symmetric(vertical: 6),
    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isUser)
          const CircleAvatar(
            backgroundColor: coral,
            child: Icon(Icons.face, color: Colors.white),
            radius: 16,
          ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
          decoration: BoxDecoration(
            color: isUser ? coral : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 4,
                offset: const Offset(2, 2),
              )
            ],
          ),
          child: Text(
            msg['text'] ?? '',
            style: TextStyle(
              color: isUser ? Colors.white : Colors.black,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (isUser)
          const CircleAvatar(
            backgroundColor: Colors.black,
            child: Icon(Icons.person, color: Colors.white),
            radius: 16,
          ),
      ],
    ),
  );
}




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: babyPink,
      appBar: AppBar(
        title: const Text("Companion Chatbot"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (isTyping && index == messages.length) {
                  return _buildBotTypingBubble();
                }
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                IconButton(
  icon: MicPulse(isListening: isListening),
  onPressed: isListening ? stopListening : startListening,
),

                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: handleSend,
                    decoration: InputDecoration(
                      hintText: "Ask something...",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: coral,
                  onPressed: () => handleSend(_controller.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
