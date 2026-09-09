import 'package:flutter/material.dart';

import '../components/notification/notification_widgets.dart';
import '../styles/story_colors.dart';

/// Full-screen notification inbox from Figma node `51:22644`.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key, this.initialTab = 1});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Scaffold(
      backgroundColor: StoryColors.cardOf(brightness),
      body: SafeArea(
        bottom: false,
        child: NotificationTabs(initialTab: initialTab),
      ),
    );
  }
}
