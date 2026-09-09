import 'package:flutter/material.dart';

import 'comment_empty_state.dart';

/// 短剧 Tab。当前为占位空状态，待接入 DramaRepository 后填充。
class DramasTabContent extends StatefulWidget {
  final String dramaId;

  const DramasTabContent({super.key, required this.dramaId});

  @override
  State<DramasTabContent> createState() => _DramasTabContentState();
}

class _DramasTabContentState extends State<DramasTabContent>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const CommentEmptyState();
  }
}
