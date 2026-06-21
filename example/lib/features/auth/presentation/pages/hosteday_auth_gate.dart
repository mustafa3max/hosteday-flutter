import 'package:flutter/material.dart';
import 'package:hosteday_flutter/hosteday_flutter.dart';

import '../../../../core/widgets/app_loading_page.dart';
import '../../../dashboard/presentation/pages/hosteday_home_page.dart';
import 'hosteday_auth_page.dart';

/// يشبه Auth Gate في Firebase.
///
/// يستمع إلى:
/// HosteDay.auth.authStateChanges()
///
/// ويعرض صفحة الدخول عند عدم وجود جلسة، أو التطبيق الداخلي عند وجود مستخدم.
class HosteDayAuthGate extends StatelessWidget {
  const HosteDayAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<HosteDayUser?>(
      stream: HosteDay.auth.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingPage(message: 'جاري استعادة الجلسة...');
        }

        final user = snapshot.data;

        if (user == null) {
          return const HosteDayAuthPage();
        }

        return HosteDayHomePage(user: user);
      },
    );
  }
}
