import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final token = GoRouterState.of(context).extra as String?;
    return Scaffold(
      body: Center(
        child: Text(token ?? "No Token", textAlign: TextAlign.center),
      ),
    );
  }
}
