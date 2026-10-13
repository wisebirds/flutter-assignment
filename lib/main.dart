import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Wisebirds Flutter Assignment',
      home: Scaffold(
        body: Center(child: Text('wisebirds flutter assignment')),
      ),
    );
  }
}
