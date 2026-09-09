import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../components/common/report_success_dialog.dart';
import '../components/common/story_toast.dart';
import '../core/result.dart';
import '../l10n/story_l10n.dart';
import '../l10n/app_localizations.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../utils/auth_navigation.dart';
import '../widgets/widgets.dart';

/// Popped from [ReportPage] after a successful submit.
class ReportPageResult {
  /// True when the success dialog advanced the recommend feed via
  /// `dislikeCurrent` (not a bare repository dislike). Callers must sync the
  /// pager and must not advance again.
  final bool reducedRecommend;

  const ReportPageResult({this.reducedRecommend = false});
}

/// Whether [result] is a successful report pop value.
bool isReportPageSuccess(Object? result) =>
    result == true || result is ReportPageResult;

class ReportPage extends ConsumerStatefulWidget {
  final String? dramaId;
  final int? episodeNo;
  final String? episodeId;
  final WorkContentType contentType;

  /// UGC report scope. `WORK`/`DRAMA` report an episode via [episodeId];
  /// `COMMENT` reports a comment via [commentId]; `USER` reports [userId].
  final String scope;

  /// Comment id to report when [scope] is [UgcReportScope.comment].
  final String? commentId;

  /// User id to report when [scope] is [UgcReportScope.user], or the
  /// content creator when reporting work / drama / comment.
  final String? userId;

  /// Display name for the block-target row (creator / commenter / user).
  final String? targetDisplayName;

  /// Avatar for the block-target row.
  final String? targetAvatarUrl;

  /// Work title for the reduce-recommend row (work / drama reports).
  final String? contentTitle;

  /// Work cover for the reduce-recommend row.
  final String? contentCoverUrl;

  const ReportPage({
    super.key,
    this.dramaId,
    this.episodeNo,
    this.episodeId,
    this.contentType = WorkContentType.shortDrama,
    this.scope = UgcReportScope.work,
    this.commentId,
    this.userId,
    this.targetDisplayName,
    this.targetAvatarUrl,
    this.contentTitle,
    this.contentCoverUrl,
  });

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> {
  final TextEditingController _descController = TextEditingController();
  String? _selectedReasonCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrap());
    });
  }

  /// Unauthenticated entry → login first; leave the page if still logged out.
  Future<void> _bootstrap() async {
    if (!await ensureLoggedInOrRedirect(context, ref)) {
      if (mounted) Navigator.of(context).maybePop();
      return;
    }
    if (!mounted) return;
    await _loadReportTypes();
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  List<ReportTypeItem> _getFallbackReasons(AppLocalizations l10n) {
    // Comment reports use「我不喜欢」for #7 (work/drama use「质量问题」).
    final notLikeOrQuality = widget.scope == UgcReportScope.comment
        ? ReportTypeItem(
            id: '7',
            code: 'NOT_LIKE',
            name: l10n.reportReasonNotLike,
          )
        : ReportTypeItem(
            id: '7',
            code: 'QUALITY',
            name: l10n.reportReasonQuality,
          );
    return [
      ReportTypeItem(id: '1', code: 'PORN', name: l10n.reportReasonPorn),
      ReportTypeItem(id: '2', code: 'ILLEGAL', name: l10n.reportReasonIllegal),
      ReportTypeItem(
        id: '3',
        code: 'SENSITIVE',
        name: l10n.reportReasonSensitive,
      ),
      ReportTypeItem(
        id: '4',
        code: 'GAMBLING',
        name: l10n.reportReasonGambling,
      ),
      ReportTypeItem(id: '5', code: 'MINORS', name: l10n.reportReasonMinors),
      ReportTypeItem(
        id: '6',
        code: 'COPYRIGHT',
        name: l10n.reportReasonCopyright,
      ),
      notLikeOrQuality,
      ReportTypeItem(id: '8', code: 'OTHER', name: l10n.reportReasonOther),
    ];
  }

  Future<void> _loadReportTypes() async {
    final reasons = await ref
        .read(reportControllerProvider.notifier)
        .loadReportTypes(
          fallbackReasons: _getFallbackReasons(context.l10n),
          scope: widget.scope,
        );
    if (!mounted || reasons.isEmpty) return;
    setState(() {
      _selectedReasonCode ??= reasons.first.code;
    });
  }

  bool get _isCommentScope => widget.scope == UgcReportScope.comment;
  bool get _isUserScope => widget.scope == UgcReportScope.user;

  /// 整剧举报（scope=DRAMA）：以 [dramaId] 为目标提交，不要求 episodeId。
  bool get _isDramaScope => widget.scope == UgcReportScope.drama;

  /// 单集/作品举报（scope=WORK）：通过 [episodeId] 提交到
  /// `/ugc/works/{episodeId}/report`。
  bool get _isWorkScope => widget.scope == UgcReportScope.work;

  ReportBlockTarget? get _blockTarget {
    // 评论举报成功弹窗不展示拉黑。
    if (_isCommentScope) return null;
    final userId = widget.userId?.trim() ?? '';
    if (userId.isEmpty) return null;
    final selfId = ref.read(authControllerProvider).userId?.trim() ?? '';
    if (selfId.isNotEmpty && selfId == userId) return null;
    return ReportBlockTarget(
      userId: userId,
      displayName: widget.targetDisplayName,
      avatarUrl: widget.targetAvatarUrl,
    );
  }

  ReportReduceTarget? get _reduceTarget {
    if (!_isWorkScope) return null;
    final episodeId = widget.episodeId?.trim() ?? '';
    if (episodeId.isEmpty) return null;
    return ReportReduceTarget(
      episodeId: episodeId,
      title: widget.contentTitle,
      coverUrl: widget.contentCoverUrl,
    );
  }

  Future<void> _showSuccessAndPop() async {
    final block = _blockTarget;
    final reduce = _reduceTarget;
    // True only if feed dislikeCurrent already advanced; bare API dislike is false.
    final reducedViaFeed = await ReportSuccessDialog.show(
      context,
      blockTarget: block,
      reduceTarget: reduce,
    );
    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(ReportPageResult(reducedRecommend: reducedViaFeed));
  }

  Future<void> _submitReport() async {
    final reasonCode = _selectedReasonCode;
    if (reasonCode == null) {
      await _showSuccessAndPop();
      return;
    }

    final description = _descController.text.trim().isNotEmpty
        ? _descController.text.trim()
        : null;
    final notifier = ref.read(reportControllerProvider.notifier);

    final Result<void> result;
    if (_isUserScope) {
      final userId = widget.userId;
      if (userId == null || userId.isEmpty) {
        await _showSuccessAndPop();
        return;
      }
      result = await notifier.submitUserReport(
        userId: userId,
        reportType: reasonCode,
        description: description,
      );
    } else if (_isCommentScope) {
      final commentId = widget.commentId;
      if (commentId == null || commentId.isEmpty) {
        await _showSuccessAndPop();
        return;
      }
      result = await notifier.submitCommentReport(
        commentId: commentId,
        reportType: reasonCode,
        description: description,
      );
    } else if (_isDramaScope) {
      // 整剧举报：以 dramaId 为目标，不依赖当前剧集。
      final dramaId = widget.dramaId;
      if (dramaId == null || dramaId.isEmpty) {
        await _showSuccessAndPop();
        return;
      }
      result = await notifier.submitDramaReport(
        dramaId: dramaId,
        reportType: reasonCode,
        description: description,
      );
    } else {
      final episodeId = widget.episodeId;
      if (episodeId == null || episodeId.isEmpty) {
        await _showSuccessAndPop();
        return;
      }
      result = await notifier.submitReport(
        dramaId: widget.dramaId ?? '',
        episodeId: episodeId,
        reportType: reasonCode,
        description: description,
        type: widget.contentType,
      );
    }

    if (!mounted) return;

    await result.when(
      success: (_) => _showSuccessAndPop(),
      failure: (error) async {
        StoryToast.error(context, context.l10nError(error));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final reportState = ref.watch(reportControllerProvider);
    final reasons = reportState.reasons.isNotEmpty
        ? reportState.reasons
        : _getFallbackReasons(l10n);

    return AppScaffold(
      title: l10n.playerReport,
      body: reportState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: StorySpacing.screenHorizontal,
                      vertical: StorySpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: reasons.length,
                          separatorBuilder: (context, index) => Divider(
                            height: 1,
                            color: StoryColors.borderOf(brightness),
                          ),
                          itemBuilder: (context, index) {
                            final item = reasons[index];
                            final isSelected = _selectedReasonCode == item.code;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedReasonCode = item.code;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: StorySpacing.md,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.name ?? '',
                                        style: StoryTextStyles.titleMedium(
                                          color: StoryColors.foregroundOf(
                                            brightness,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: StoryColors.foregroundOf(
                                            brightness,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: 14,
                                          color: StoryColors.backgroundOf(
                                            brightness,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                StoryColors.mutedForegroundOf(
                                                  brightness,
                                                ),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: StorySpacing.xl),
                        Text(
                          l10n.reportDescription,
                          style: StoryTextStyles.bodyMedium(
                            color: StoryColors.mutedForegroundOf(brightness),
                          ),
                        ),
                        const SizedBox(height: StorySpacing.sm),
                        StoryTextField(
                          controller: _descController,
                          hint: l10n.reportDescriptionPlaceholder,
                          maxLines: 4,
                          variant: StoryTextFieldVariant.form,
                        ),
                        const SizedBox(height: StorySpacing.xxl),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    StorySpacing.screenHorizontal,
                    StorySpacing.md,
                    StorySpacing.screenHorizontal,
                    MediaQuery.paddingOf(context).bottom + StorySpacing.md,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: reportState.isSubmitting
                          ? null
                          : _submitReport,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                        backgroundColor: StoryColors.foregroundOf(brightness),
                        foregroundColor: StoryColors.backgroundOf(brightness),
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: StoryRadius.brMd,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: StorySpacing.md,
                        ),
                        disabledBackgroundColor: brightness == Brightness.dark
                            ? StoryColors.darkMuted
                            : StoryColors.lightMuted,
                      ),
                      child: reportState.isSubmitting
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  StoryColors.backgroundOf(brightness),
                                ),
                              ),
                            )
                          : Text(
                              l10n.playerReport,
                              style: StoryTextStyles.labelLarge(
                                color: StoryColors.backgroundOf(brightness),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
