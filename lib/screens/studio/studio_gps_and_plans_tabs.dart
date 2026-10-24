part of '../studio_screen.dart';

/// Tab 3: All Pinned GPS Locations + 1-Tap Google Maps & Apple Maps Verification
class _GpsLocationsDirectoryTab extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _GpsLocationsDirectoryTab({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final located = plan.locatedBlocks;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF1D1D28),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.satellite_alt_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Google & Apple Maps GPS Hub',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${located.length} stops linked with turn-by-turn GPS navigation.',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D1D28),
                ),
                onPressed: () async {
                  final b = await provider.addBlock(BlockType.placeEvent);
                  if (b != null && context.mounted) {
                    BlockEditorModal.show(
                      context,
                      block: b,
                      onSave: provider.updateBlock,
                    );
                  }
                },
                icon: const Icon(Icons.add_location_alt_rounded, size: 16),
                label: const Text(
                  'Add New GPS Stop',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...List.generate(located.length, (idx) {
          final block = located[idx];
          final loc = block.location!;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE4E4EC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 11,
                      backgroundColor: const Color(0xFF1D1D28),
                      child: Text(
                        '${idx + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        block.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(
                        Icons.edit_location_alt_outlined,
                        size: 16,
                      ),
                      onPressed: () => BlockEditorModal.show(
                        context,
                        block: block,
                        onSave: provider.updateBlock,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  loc.displayLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF717182),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D1D28),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: () => MapsService.openGoogleMaps(loc),
                        icon: const Icon(Icons.directions, size: 13.5),
                        label: const Text(
                          'Google Maps',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1D1D28),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        onPressed: () => MapsService.openAppleMaps(loc),
                        icon: const Icon(Icons.apple, size: 13.5),
                        label: const Text(
                          'Apple Maps',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

/// Tab 4: Switch Between Plans or Create New Plan
class _SavedPlansDirectoryTab extends StatelessWidget {
  final PlanModel plan;
  final PlanStudioProvider provider;

  const _SavedPlansDirectoryTab({
    required this.plan,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D1D28),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () => _showCreateNewPlanDialog(context, provider),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          label: const Text(
            'Create New Plan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'YOUR SAVED PLANS',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: Color(0xFF717182),
          ),
        ),
        const SizedBox(height: 10),
        ...provider.plans.map((item) {
          final isCurrent = item.id == plan.id;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? const Color(0xFF1D1D28)
                    : const Color(0xFFE4E4EC),
                width: isCurrent ? 2 : 1,
              ),
            ),
            child: ListTile(
              onTap: () => provider.selectPlan(item.id),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              subtitle: Text(
                'plaans.co/${item.slug} · ${item.locatedBlocks.length} GPS pins',
                style: const TextStyle(fontSize: 11.5),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'duplicate') {
                    provider.duplicatePlan(item);
                  } else if (action == 'delete' && provider.plans.length > 1) {
                    provider.deletePlan(item.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Text('Duplicate Plan'),
                  ),
                  if (provider.plans.length > 1)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Plan'),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showCreateNewPlanDialog(
    BuildContext context,
    PlanStudioProvider provider,
  ) {
    final titleCtrl = TextEditingController();
    final subCtrl = TextEditingController();
    PlanTheme selectedPreset = PlanTheme.presets.first;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Create a New Plan',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Plan Title (e.g., Miami Art Basel Weekend)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Bio / Subtitle',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Choose Starting Theme:',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: PlanTheme.presets.map((preset) {
                    final isChosen = selectedPreset.presetId == preset.presetId;
                    return ChoiceChip(
                      label: Text(preset.presetName),
                      selected: isChosen,
                      selectedColor: const Color(0xFF1D1D28),
                      labelStyle: TextStyle(
                        color: isChosen ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) =>
                          setDialogState(() => selectedPreset = preset),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D1D28),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final title = titleCtrl.text.trim().isEmpty
                    ? 'My Weekend Plan'
                    : titleCtrl.text.trim();
                provider.createNewPlan(
                  title: title,
                  subtitle: subCtrl.text.trim().isEmpty
                      ? 'Curated stops, tickets & GPS locations.'
                      : subCtrl.text.trim(),
                  theme: selectedPreset,
                );
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Launch Plan Studio',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

