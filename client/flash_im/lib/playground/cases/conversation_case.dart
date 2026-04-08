import 'package:flutter/material.dart';
import '../../features/conversation/api/conversation_api.dart';
import '../../features/conversation/model/conversation.dart';

class ConversationCase extends StatefulWidget {
  const ConversationCase({super.key});

  static const String title = '💬 会话列表';

  @override
  State<ConversationCase> createState() => _ConversationCaseState();
}

class _ConversationCaseState extends State<ConversationCase> {
  final _api = ConversationApi();
  late Future<List<Conversation>> _future;

  @override
  void initState() {
    super.initState();
    _future = _api.getList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(ConversationCase.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = _api.getList()),
          ),
        ],
      ),
      body: FutureBuilder<List<Conversation>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                '请求失败\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final list = snap.data!;
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = list[i];
              return ListTile(
                leading: CircleAvatar(child: Text(c.title[0])),
                title: Text(c.title),
                subtitle: Text(c.lastMsg),
                trailing: Text(
                  c.time.substring(11),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
