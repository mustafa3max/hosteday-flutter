import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';
import 'package:hosteday_flutter_example/features/posts/presentation/widgets/post/create_page.dart';
import 'package:hosteday_flutter_example/shared/widgets/app_bar.dart';

import '../widgets/post/index.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Future<void> _openCreatePage() async {
    final created = await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CreatePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarMy(title: 'Posts'),
      body: Index(),
      floatingActionButton: StreamBuilder<HosteDayUser?>(
        stream: HosteDay.auth.authStateChanges(),
        initialData: HosteDay.auth.currentUser,
        builder: (context, snapshot) {
          final user = snapshot.data;
          final isAuthenticated = user?.hasEmail == true;
          if (isAuthenticated) {
            return FloatingActionButton.extended(
              onPressed: _openCreatePage,
              icon: const Icon(Icons.add),
              label: const Text('Create post'),
            );
          }
          return SizedBox();
        },
      ),
    );
  }
}
