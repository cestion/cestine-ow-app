import 'package:flutter/material.dart';

import 'public_profile_page.dart';

/// "My Profile" tab — delegates to the unified [PublicProfilePage] in self mode.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // No userId → self mode. A bottom-nav root must not show a back button.
    return const PublicProfilePage(showBack: false);
  }
}
