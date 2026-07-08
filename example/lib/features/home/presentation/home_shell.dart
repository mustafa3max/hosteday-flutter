import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../posts/presentation/pages/posts_page.dart';
import '../../profile/presentation/pages/profile_page.dart';
import '../../realtime/presentation/pages/realtime_page.dart';

/// The authenticated area of the example app.
class HomeShell extends StatefulWidget {
  final HosteDayUser user;

  const HomeShell({required this.user, super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

enum HomeTab { posts, profile, realtime }

class _HomeShellState extends State<HomeShell> {
  HomeTab _tab = HomeTab.posts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.user.displayName ?? 'HosteDay Example'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await HosteDay.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: switch (_tab) {
        HomeTab.posts => const PostsPage(),
        HomeTab.profile => const ProfilePage(),
        HomeTab.realtime => const RealtimePage(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab.index,
        onDestinationSelected: (index) {
          setState(() {
            _tab = HomeTab.values[index];
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Posts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'User',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt_outlined),
            selectedIcon: Icon(Icons.bolt),
            label: 'Realtime',
          ),
        ],
      ),
    );
  }
}
