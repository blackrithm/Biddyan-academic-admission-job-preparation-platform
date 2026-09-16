import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants.dart';
import '../widgets/brand_navigation.dart';

class BiddyanAiScreen extends StatefulWidget {
  const BiddyanAiScreen({super.key});

  @override
  State<BiddyanAiScreen> createState() => _BiddyanAiScreenState();
}

class _BiddyanAiScreenState extends State<BiddyanAiScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  final _messages = <_AiMessage>[
    const _AiMessage(
      text: 'আসসালামু আলাইকুম! আমি বিদ্বান AI। পড়াশোনার প্রশ্ন, MCQ, সূত্র বা কোনো কঠিন বিষয় বুঝতে আমাকে জিজ্ঞেস করুন।',
      fromUser: false,
    ),
  ];
  XFile? _photo;
  bool _isThinking = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppConstants.golden),
            SizedBox(width: 8),
            Text('বিদ্বান AI'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'নতুন chat',
            icon: const Icon(Icons.refresh),
            onPressed: _resetChat,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildIntro(),
          Expanded(child: _buildMessages()),
          _buildComposer(),
        ],
      ),
      bottomNavigationBar: BrandBottomNavigation(
        selectedIndex: 5,
        onSelected: (index) => BrandBottomNavigation.navigate(context, index),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      color: const Color(0xFFE8F3F1),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _PromptChip(label: 'গণিত বুঝিয়ে দাও', onPressed: _usePrompt),
          _PromptChip(label: 'এই MCQ-এর সমাধান কী?', onPressed: _usePrompt),
          _PromptChip(label: 'ছবি থেকে প্রশ্ন পড়ো', onPressed: _usePrompt),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      itemCount: _messages.length + (_isThinking ? 1 : 0),
      itemBuilder: (context, index) {
        if (_isThinking && index == _messages.length) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: _MessageBubble(text: 'ভাবছি...', fromUser: false),
          );
        }
        final message = _messages[index];
        return Align(
          alignment: message.fromUser
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: _MessageBubble(
            text: message.text,
            fromUser: message.fromUser,
            photo: message.photo,
          ),
        );
      },
    );
  }

  Widget _buildComposer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: [
            if (_photo != null)
              Align(
                alignment: Alignment.centerLeft,
                child: InputChip(
                  avatar: const Icon(Icons.image, size: 18),
                  label: Text(_photo!.name, overflow: TextOverflow.ellipsis),
                  onDeleted: () => setState(() => _photo = null),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'ছবি যোগ করুন',
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  onPressed: _pickPhoto,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'আপনার প্রশ্ন লিখুন...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  tooltip: 'প্রশ্ন পাঠান',
                  icon: const Icon(Icons.arrow_upward),
                  onPressed: _isThinking ? null : _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final photo = await _picker.pickImage(source: ImageSource.gallery);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty && _photo == null) return;
    final photo = _photo;
    setState(() {
      _messages.add(_AiMessage(text: text, fromUser: true, photo: photo));
      _messageController.clear();
      _photo = null;
      _isThinking = true;
    });
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isThinking = false;
        _messages.add(_AiMessage(
          text: _answerFor(text, hasPhoto: photo != null),
          fromUser: false,
        ));
      });
      _scrollToBottom();
    });
    _scrollToBottom();
  }

  String _answerFor(String text, {required bool hasPhoto}) {
    if (hasPhoto) {
      return text.isEmpty
          ? 'ছবিটি পেয়েছি। ছবির প্রশ্নের সঙ্গে ১-২টি শব্দ লিখে বিষয়টি জানান, যেমন “এটি সমাধান করো” বা “সঠিক উত্তর কোনটি?” তারপর আমি ধাপে ধাপে সাহায্য করব।'
          : 'ছবির সঙ্গে আপনার প্রশ্নটিও পেয়েছি। ছবির প্রশ্নটি ধাপে ধাপে পড়ুন, অপশনগুলো মিলিয়ে দেখুন এবং যে অংশটি বুঝতে সমস্যা হচ্ছে সেটি লিখলে আমি ব্যাখ্যা করে দেব।';
    }
    final lower = text.toLowerCase();
    if (lower.contains('গণিত') || lower.contains('math')) {
      return 'গণিতের প্রশ্নটি ধাপে ধাপে সমাধান করব। প্রথমে প্রশ্নের দেওয়া তথ্য আলাদা করুন, তারপর কোন সূত্র বা নিয়ম প্রযোজ্য তা ঠিক করুন। সম্পূর্ণ প্রশ্ন ও অপশন পাঠালে নির্দিষ্ট উত্তরও দেখাব।';
    }
    if (lower.contains('mcq') || lower.contains('উত্তর') || lower.contains('সমাধান')) {
      return 'MCQ সমাধানের নিয়ম: প্রশ্নের মূল শব্দ চিহ্নিত করুন, ভুল অপশনগুলো বাদ দিন, তারপর সঠিক অপশনটি কেন সঠিক তার কারণ মিলিয়ে নিন। প্রশ্ন ও চারটি অপশন পাঠান।';
    }
    if (lower.contains('ইংরেজি') || lower.contains('english') || lower.contains('grammar')) {
      return 'ইংরেজি প্রশ্নে tense, subject-verb agreement এবং বাক্যের অর্থ আগে দেখুন। পুরো বাক্যটি পাঠালে নিয়মটি উদাহরণসহ বুঝিয়ে দেব।';
    }
    if (lower.contains('পড়তে') || lower.contains('routine') || lower.contains('রুটিন')) {
      return 'আজকের study plan: ২৫ মিনিট একটি বিষয় পড়ুন, ১০টি MCQ দিন, ভুলগুলো নোট করুন এবং শেষে ৫ মিনিট revision করুন। আপনার target exam বললে plan আরও নির্দিষ্ট করে দেব।';
    }
    return 'আপনার প্রশ্নটি পেয়েছি। বিষয়, পুরো প্রশ্ন এবং থাকলে অপশন বা ছবিটি দিন। আমি উত্তর, কারণ এবং পরীক্ষায় মনে রাখার সহজ কৌশলসহ বুঝিয়ে দেব।';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _resetChat() {
    setState(() {
      _messages
        ..clear()
        ..add(const _AiMessage(
          text: 'আসসালামু আলাইকুম! আমি বিদ্বান AI। পড়াশোনার প্রশ্ন, MCQ, সূত্র বা কোনো কঠিন বিষয় বুঝতে আমাকে জিজ্ঞেস করুন।',
          fromUser: false,
        ));
      _photo = null;
    });
  }

  void _usePrompt(String prompt) {
    _messageController
      ..text = prompt
      ..selection = TextSelection.collapsed(offset: prompt.length);
  }
}

class _AiMessage {
  const _AiMessage({required this.text, required this.fromUser, this.photo});

  final String text;
  final bool fromUser;
  final XFile? photo;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.text, required this.fromUser, this.photo});

  final String text;
  final bool fromUser;
  final XFile? photo;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 680),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: fromUser ? AppConstants.primary : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: fromUser ? null : Border.all(color: const Color(0xFFDDE5E5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photo != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
                child: kIsWeb
                  ? Image.network(photo!.path, height: 160, fit: BoxFit.cover)
                  : Image.file(File(photo!.path), height: 160, fit: BoxFit.cover),
            ),
            if (text.isNotEmpty) const SizedBox(height: 8),
          ],
          if (text.isNotEmpty)
            Text(text, style: TextStyle(color: fromUser ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onPressed});

  final String label;
  final ValueChanged<String> onPressed;

  @override
  Widget build(BuildContext context) => ActionChip(
        label: Text(label),
        onPressed: () => onPressed(label),
      );
}