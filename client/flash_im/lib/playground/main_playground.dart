import 'package:flutter/material.dart';
import 'cases/fireworks_case.dart';
import 'cases/conversation_case.dart';

void main() {
  runApp(const PlaygroundApp());
}

final _cases = [
  _Case(title: FireworksCase.title, builder: (_) => const FireworksCase()),
  _Case(title: ConversationCase.title, builder: (_) => const ConversationCase()),
];

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Playground',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const _PlaygroundHome(),
    );
  }
}

class _PlaygroundHome extends StatelessWidget {
  const _PlaygroundHome();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('🛝 开发游乐场'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _cases.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, i) {
          final c = _cases[i];
          return ListTile(
            title: Text(c.title, style: const TextStyle(fontSize: 16)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () =>
                Navigator.push(context, MaterialPageRoute(builder: c.builder)),
          );
        },
      ),
    );
  }
}

class _Case {
  final String title;
  final WidgetBuilder builder;
  const _Case({required this.title, required this.builder});
}
