import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'dart:convert';
import 'dart:async';
import 'package:bubble/bubble.dart';
import 'package:keyboard_detection/keyboard_detection.dart';

final logger = Logger();

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _sentMessage = '';
  List<String> messages = [];

  final _scrollController = ScrollController();

  Future<String> _getChatResponse(String message) async {
    final url = Uri.parse('https://api.a3rt.recruit.co.jp/talk/v1/smalltalk');
    const apiKey = 'ZZuX5ooBAhwgDKxY9aKNTd7YqlAEe3B0';
    final response = await http.post(
      url,
      body: {
        'apikey': apiKey,
        'query': message,
      },
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['results'][0]['reply'];
    } else {
      throw Exception('Failed to get chat response');
    }
  }

  void _scrollToBottom() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  var _chatListPadding = const EdgeInsets.all(0);

  Widget _chatList() {
    _scrollToBottom();
    return AnimatedPadding(
      padding: _chatListPadding,
      duration: const Duration(milliseconds: 100),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: messages.length,
        itemBuilder: (context, index) {
          return Bubble(
            margin: const BubbleEdges.only(top: 10, left: 10, right: 10),
            padding: const BubbleEdges.all(10),
            color: index % 2 == 0 ? Colors.blue : Colors.green,
            nip: index % 2 == 0 ? BubbleNip.rightTop : BubbleNip.leftTop,
            alignment: index % 2 == 0 ? Alignment.topRight : Alignment.topLeft,
            child: Text(
              messages[index],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      ),
    );
  }

  void _sendChatMessage(String message) async {
    final response = await _getChatResponse(message);
    setState(() {
      messages.add(response);
      _sentMessage = '';
    });
  }

  final _formController = TextEditingController();

  Widget _chatWindow() {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey,
              width: 1,
            ),
            color: Colors.grey[200],
          ),
          child: _chatList(),
        ),
      ),
    );
  }

  var _chatInputPadding = const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 20);

  Widget _chatInput(dynamic screenSize) {
    return Container(
      height: screenSize.height * 0.09,
      color: Colors.blueGrey,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 100),
        padding: _chatInputPadding,
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onTap: () {
                  _scrollToBottom();
                  setState(() {
                    _chatInputPadding = const EdgeInsets.symmetric(horizontal: 15, vertical: 0);
                  });
                },
                controller: _formController,
                onChanged: (value) {
                  _sentMessage = value;
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              color: Colors.white,
              onPressed: () {
                setState(() {
                  messages.add(_sentMessage);
                });
                _sendChatMessage(_sentMessage);
                _formController.clear();
              }
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return KeyboardDetection(
      controller: KeyboardDetectionController(
        onChanged: (value) {
          if (value == KeyboardState.visibling || value == KeyboardState.visible) {
            setState(() {
              _chatInputPadding = const EdgeInsets.symmetric(horizontal: 15, vertical: 0);
              _chatListPadding = const EdgeInsets.only(bottom: 20);
            });
          } else {
            setState(() {
              _chatInputPadding = const EdgeInsets.only(left: 15, right: 15, top: 0, bottom: 20);
              _chatListPadding = const EdgeInsets.all(0);
            });
          }
        }
      ),
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          padding: const EdgeInsets.all(0),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              _chatWindow(),
              _chatInput(screenSize),
            ],
          ),
        ),
      ),
    );
  }
}
