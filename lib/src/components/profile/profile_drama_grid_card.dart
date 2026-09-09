import 'package:flutter/material.dart';

import '../../model/models.dart';
import '../content/content_drama_grid_card.dart';

/// 个人中心短剧网格卡 — 复用 [ContentDramaGridCard]（与搜索短剧卡同源）。
class ProfileDramaGridCard extends StatelessWidget {
  final DramaListItem drama;
  final VoidCallback? onTap;

  const ProfileDramaGridCard({super.key, required this.drama, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ContentDramaGridCard(drama: drama, onTap: onTap);
  }
}
