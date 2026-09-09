import 'package:flutter/material.dart';

import '../l10n/story_l10n.dart';
import '../styles/story_spacing.dart';
import '../widgets/widgets.dart';

class EditPage extends StatefulWidget {
  final String type;
  final String id;
  const EditPage({super.key, required this.type, required this.id});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDrama = widget.type == 'drama';
    final l10n = context.l10n;
    return AppScaffold(
      title: isDrama ? l10n.editDramaTitle : l10n.editActorTitle,
      body: ListView(
        padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
        children: [
          const SizedBox(height: StorySpacing.lg),
          StoryTextField(
            label: isDrama
                ? l10n.createDramaTitleLabel
                : l10n.createActorNameLabel,
            controller: _nameCtrl,
            hint: isDrama
                ? l10n.createDramaTitleHint
                : l10n.createActorNameHint,
          ),
          const SizedBox(height: StorySpacing.md),
          StoryTextField(
            label: isDrama
                ? l10n.createDramaSynopsisLabel
                : l10n.createActorBioLabel,
            controller: _descCtrl,
            hint: isDrama
                ? l10n.createDramaSynopsisHint
                : l10n.createActorBioHint,
            maxLines: 4,
          ),
          const SizedBox(height: StorySpacing.xl),
          StoryButton(
            label: l10n.editSaveChanges,
            block: true,
            onPressed: () {},
          ),
          const SizedBox(height: StorySpacing.xxl),
        ],
      ),
    );
  }
}
