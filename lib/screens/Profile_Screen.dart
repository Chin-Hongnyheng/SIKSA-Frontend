import 'package:flutter/material.dart';
import '../graphql/graphql_service.dart';
import '../widgets/loading.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final GraphQLService graphqlService = GraphQLService();

  Map<String, dynamic>? user;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      LoadingOverlay.show(context);
      final result = await graphqlService.me();

      setState(() {
        user = result;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      LoadingOverlay.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Center(
        child: error != null
            ? Text("Error: $error", style: const TextStyle(color: Colors.red))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Username: ${user?['userName']}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "Email: ${user?['email']}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "Phone: ${user?['phone']}",
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    "Role: ${user?['role']}",
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
      ),
    );
  }
}
