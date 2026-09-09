import 'package:flutter/material.dart';

import 'comment_empty_state.dart';

/// 角色 Tab。当前为占位空状态，待接入 ActorRepository 后填充。
class ActorsTabContent extends StatefulWidget {
  final String dramaId;

  const ActorsTabContent({super.key, required this.dramaId});

  @override
  State<ActorsTabContent> createState() => _ActorsTabContentState();
}

class _ActorsTabContentState extends State<ActorsTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const CommentEmptyState();
  }
}
