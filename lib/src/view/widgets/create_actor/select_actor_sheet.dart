import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/result.dart';
import '../../../core/story_sdk.dart';
import '../../../foundation/story_launcher.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../widgets/widgets.dart';

class SelectActorSheet extends ConsumerStatefulWidget {
  final Actor? initialSelection;
  final VoidCallback? onGotoDreamOs;

  const SelectActorSheet({
    super.key,
    this.initialSelection,
    this.onGotoDreamOs,
  });

  static Future<Actor?> show(BuildContext context, {Actor? initialSelection}) {
    return showModalBottomSheet<Actor>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: StoryColors.overlayMedium,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.85,
        child: SelectActorSheet(
          initialSelection: initialSelection,
          onGotoDreamOs: () {
            Navigator.of(ctx).pop();
            final url = StorySdk.instance.config.env.dreamOsUrl;
            StoryLauncher.openExternal(url);
          },
        ),
      ),
    );
  }

  @override
  ConsumerState<SelectActorSheet> createState() => _SelectActorSheetState();
}

class _SelectActorSheetState extends ConsumerState<SelectActorSheet> {
  final _searchCtrl = TextEditingController();
  Actor? _currentSelection;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentSelection = widget.initialSelection;
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final l10n = context.l10n;
    final materialsState = ref.watch(createActorControllerProvider);
    final materials = materialsState.availableMaterials;
    final materialsError = materialsState.materialsError;
    final isLoading = materialsState.isMaterialsLoading;

    final filtered = materials.where((actor) {
      final name = actor.name?.toLowerCase() ?? '';
      return name.contains(_searchQuery);
    }).toList();

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.backgroundOf(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(
                top: StorySpacing.md,
                bottom: StorySpacing.md,
              ),
              decoration: BoxDecoration(
                color: StoryColors.dividerOf(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: StorySpacing.xl),
            child: Center(
              child: Text(
                l10n.createActorSelectButton,
                style: StoryTextStyles.titleMedium(
                  color: StoryColors.foregroundOf(brightness),
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: StorySpacing.lg),
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: StorySpacing.xl),
            child: StoryTextField(
              controller: _searchCtrl,
              hint: l10n.createActorSearchPlaceholder,
              prefixIcon: Icon(
                Icons.search,
                color: StoryColors.mutedForegroundOf(brightness),
              ),
            ),
          ),
          const SizedBox(height: StorySpacing.md),
          // Materials content
          Expanded(
            child: _buildMaterialsBody(
              brightness: brightness,
              l10n: l10n,
              materials: materials,
              filtered: filtered,
              materialsError: materialsError,
              isLoading: isLoading,
            ),
          ),
          // Bottom Actions
          Padding(
            padding: EdgeInsets.only(
              left: StorySpacing.xl,
              right: StorySpacing.xl,
              top: StorySpacing.md,
              bottom: StorySpacing.xl + MediaQuery.paddingOf(context).bottom,
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: BorderSide(color: StoryColors.borderOf(brightness)),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      l10n.createActorCancelButton,
                      style: StoryTextStyles.bodyMedium(
                        color: StoryColors.foregroundOf(brightness),
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: StorySpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentSelection == null
                        ? null
                        : () => Navigator.of(context).pop(_currentSelection),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      backgroundColor: StoryColors.foregroundOf(brightness),
                      foregroundColor: StoryColors.backgroundOf(brightness),
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      disabledBackgroundColor: brightness == Brightness.dark
                          ? StoryColors.darkMuted
                          : StoryColors.lightMuted,
                    ),
                    child: Text(
                      l10n.commonConfirm,
                      style: StoryTextStyles.bodyMedium().copyWith(
                        fontWeight: FontWeight.bold,
                        color: _currentSelection == null
                            ? StoryColors.mutedForegroundOf(brightness)
                            : StoryColors.backgroundOf(brightness),
                      ),
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

  Widget _buildMaterialsBody({
    required Brightness brightness,
    required AppLocalizations l10n,
    required List<Actor> materials,
    required List<Actor> filtered,
    required ApiError? materialsError,
    required bool isLoading,
  }) {
    if (isLoading && materials.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: StoryColors.brandTeal,
          ),
        ),
      );
    }

    if (materialsError != null && materials.isEmpty) {
      return _buildErrorState(l10n, isLoading);
    }

    if (materials.isEmpty) {
      return _buildEmptyState(brightness, l10n);
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          l10n.searchEmpty,
          style: StoryTextStyles.bodyMedium(
            color: StoryColors.mutedForegroundOf(brightness),
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.xl,
        vertical: StorySpacing.sm,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: StorySpacing.md,
        mainAxisSpacing: StorySpacing.md,
        childAspectRatio: 0.85,
      ),
      itemCount: filtered.length,
      itemBuilder: (ctx, idx) {
        final actor = filtered[idx];
        final isSelected = _currentSelection?.id == actor.id;
        return _buildActorCard(actor, isSelected, brightness);
      },
    );
  }

  Widget _buildErrorState(AppLocalizations l10n, bool isLoading) {
    return Padding(
      padding: const EdgeInsets.all(StorySpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: isLoading
                ? null
                : () => ref
                      .read(createActorControllerProvider.notifier)
                      .loadMaterials(),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.xxl,
                vertical: StorySpacing.md,
              ),
              decoration: BoxDecoration(
                color: StoryColors.brandTeal.withValues(alpha: 0.08),
                borderRadius: StoryRadius.brPill,
                border: Border.all(
                  color: StoryColors.brandTeal.withValues(alpha: 0.24),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: StoryColors.brandTeal,
                      ),
                    )
                  : Text(
                      l10n.dramaRefresh,
                      style: StoryTextStyles.labelMedium(
                        color: StoryColors.brandTeal,
                      ).copyWith(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Brightness brightness, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(StorySpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Empty State Icon Box
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: brightness == Brightness.dark
                  ? StoryColors.darkMuted
                  : StoryColors.lightMuted,
              borderRadius: StoryRadius.brLg,
            ),
            child: Icon(
              Icons.portrait_outlined,
              size: 40,
              color: StoryColors.mutedForegroundOf(brightness),
            ),
          ),
          const SizedBox(height: StorySpacing.xl),
          Text(
            l10n.createActorEmptyTitle,
            textAlign: TextAlign.center,
            style: StoryTextStyles.bodyMedium(
              color: StoryColors.mutedForegroundOf(brightness),
            ),
          ),
          const SizedBox(height: StorySpacing.xl),
          // Go to DreamOS button
          GestureDetector(
            onTap: widget.onGotoDreamOs,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.xxl,
                vertical: StorySpacing.md,
              ),
              decoration: BoxDecoration(
                color: StoryColors.brandTeal.withValues(alpha: 0.08),
                borderRadius: StoryRadius.brPill,
                border: Border.all(
                  color: StoryColors.brandTeal.withValues(alpha: 0.24),
                ),
              ),
              child: Text(
                l10n.createActorGotoDreamOs,
                style: StoryTextStyles.labelMedium(
                  color: StoryColors.brandTeal,
                ).copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActorCard(Actor actor, bool isSelected, Brightness brightness) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentSelection = actor;
        });
      },
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StoryColors.mutedOf(brightness),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(StorySpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipOval(child: StoryAvatar(imageUrl: actor.avatarUrl, size: 72)),
              const SizedBox(height: StorySpacing.xs),
              Text(
                actor.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: StoryTextStyles.bodyLarge(
                  color: StoryColors.foregroundOf(brightness),
                ).copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: StorySpacing.xs),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: StoryColors.foregroundOf(brightness),
                  size: 24,
                )
              else
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: StoryColors.borderOf(brightness),
                      width: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
