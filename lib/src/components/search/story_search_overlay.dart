import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../controller/search_state.dart';
import '../../core/debouncer.dart';
import '../../core/logging_request_policy_observer.dart';
import '../../core/request_keys.dart';
import '../../core/story_constants.dart';
import '../../provider/app_providers.dart';
import 'search_input_bar.dart';
import 'search_results_list.dart';

/// Shows the search overlay dialog in-place without page routing.
///
/// [type] controls which search results are shown:
/// - [SearchType.dramas] — only drama results (used from Theater page)
/// - [SearchType.actors] — only actor results (used from NFT page)
void showStorySearch(
  BuildContext context, {
  SearchType type = SearchType.dramas,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Search',
    barrierColor: Colors.transparent,
    pageBuilder: (context, anim1, anim2) {
      return StorySearchOverlay(searchType: type);
    },
  );
}

class StorySearchOverlay extends ConsumerStatefulWidget {
  final SearchType searchType;

  const StorySearchOverlay({super.key, required this.searchType});

  @override
  ConsumerState<StorySearchOverlay> createState() => _StorySearchOverlayState();
}

class _StorySearchOverlayState extends ConsumerState<StorySearchOverlay> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _history = [];
  final Debouncer _debouncer =
      TimerDebouncer(observer: debugRequestPolicyObserver);

  @override
  void initState() {
    super.initState();
    // Set the search type so the controller only calls the relevant API.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(searchControllerProvider.notifier)
            .setActiveTab(widget.searchType);
      }
    });
  }

  @override
  void dispose() {
    _debouncer.cancelAll();
    _searchController.dispose();
    // Ensure keyboard is dismissed when overlay is disposed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    super.dispose();
  }

  void _onSearchTextChanged(String value) {
    if (value.trim().isEmpty) {
      _debouncer.cancel(RequestKeys.searchQuery);
      ref.read(searchControllerProvider.notifier).clear();
      return;
    }
    // Immediately sync keyword so provider always reflects current input.
    ref.read(searchControllerProvider.notifier).syncKeyword(value);
    // Debounce only the API call.
    _debouncer(
      RequestKeys.searchQuery,
      () {
        unawaited(_onSearchSubmit(value));
      },
      delay: StoryConstants.searchQueryDebounce,
    );
  }

  Future<void> _onSearchSubmit(String value) async {
    _debouncer.cancel(RequestKeys.searchQuery);
    if (value.trim().isEmpty) return;
    setState(() {
      _history.remove(value);
      _history.insert(0, value);
      if (_history.length > 20) _history.removeLast();
    });
    await ref.read(searchControllerProvider.notifier).search(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final keyword = ref.watch(
      searchControllerProvider.select((s) => s.keyword),
    );
    final isLoading = ref.watch(
      searchControllerProvider.select((s) => s.isLoading),
    );
    final hasSearched = ref.watch(
      searchControllerProvider.select((s) => s.hasSearched),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Bottom glassmorphic mask — always shown to allow dismiss by tap
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
                Navigator.of(context).pop();
                ref.read(searchControllerProvider.notifier).clear();
              },
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          // 2. Main content with Safe Area prefix
          Positioned.fill(
            child: Column(
              children: [
                SearchInputBar(
                  inputController: _searchController,
                  onSubmit: _onSearchSubmit,
                  onChanged: _onSearchTextChanged,
                  keyword: keyword,
                  onAvatarTap: () {
                    FocusScope.of(context).unfocus();
                    Navigator.of(context).pop();
                    ref.read(searchControllerProvider.notifier).clear();
                  },
                ),
                // 3. Results Panel — max 2/3 screen height
                if (hasSearched || isLoading)
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.sizeOf(context).height * 2 / 3,
                      ),
                      child: _buildResultsPanel(
                        context,
                        theme,
                        isDark,
                        keyword,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsPanel(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    String keyword,
  ) {
    final isLoading = ref.watch(
      searchControllerProvider.select((s) => s.isLoading),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E2228) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : const Color(0x0F000033),
              blurRadius: 32,
              offset: const Offset(0, 12),
              spreadRadius: -16,
            ),
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.2)
                  : const Color(0x0D000000),
              blurRadius: 40,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              : SearchResultsList(
                  history: _history,
                  onHistoryTap: (value) {
                    _searchController.text = value;
                    _onSearchSubmit(value);
                  },
                  onClearHistory: () => setState(_history.clear),
                ),
        ),
      ),
    );
  }
}
