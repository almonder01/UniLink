part of '../home_screen.dart';

enum _HomeContentFilter { all, events, posts }

enum _HomeDateFilter { anytime, today, thisWeek, thisMonth }

enum _HomeMediaFilter { any, video, music }

class _HomeFilterBar extends StatefulWidget {
  final _HomeContentFilter contentFilter;
  final _HomeDateFilter dateFilter;
  final _HomeMediaFilter mediaFilter;
  final bool hasActiveFilters;
  final ValueChanged<_HomeContentFilter> onContentChanged;
  final ValueChanged<_HomeDateFilter> onDateChanged;
  final ValueChanged<_HomeMediaFilter> onMediaChanged;
  final VoidCallback onClear;

  const _HomeFilterBar({
    required this.contentFilter,
    required this.dateFilter,
    required this.mediaFilter,
    required this.hasActiveFilters,
    required this.onContentChanged,
    required this.onDateChanged,
    required this.onMediaChanged,
    required this.onClear,
  });

  @override
  State<_HomeFilterBar> createState() => _HomeFilterBarState();
}

class _HomeFilterBarState extends State<_HomeFilterBar> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.hasActiveFilters;
  }

  @override
  void didUpdateWidget(covariant _HomeFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasActiveFilters && !oldWidget.hasActiveFilters) {
      _expanded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final summary =
        widget.hasActiveFilters ? 'Active filters' : 'Tap to refine results';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.58)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filters',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                          ),
                        ),
                        Text(
                          summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.hasActiveFilters)
                    TextButton.icon(
                      onPressed: widget.onClear,
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('Reset'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _FilterGroup<_HomeContentFilter>(
                        label: 'Show',
                        value: widget.contentFilter,
                        options: const [
                          _FilterOption(
                            value: _HomeContentFilter.all,
                            label: 'All',
                            icon: Icons.dashboard_customize_rounded,
                          ),
                          _FilterOption(
                            value: _HomeContentFilter.events,
                            label: 'Events',
                            icon: Icons.event_rounded,
                          ),
                          _FilterOption(
                            value: _HomeContentFilter.posts,
                            label: 'Posts',
                            icon: Icons.article_rounded,
                          ),
                        ],
                        onChanged: widget.onContentChanged,
                      ),
                      const SizedBox(height: 8),
                      _FilterGroup<_HomeDateFilter>(
                        label: 'Date',
                        value: widget.dateFilter,
                        options: const [
                          _FilterOption(
                            value: _HomeDateFilter.anytime,
                            label: 'Any date',
                            icon: Icons.calendar_month_outlined,
                          ),
                          _FilterOption(
                            value: _HomeDateFilter.today,
                            label: 'Today',
                            icon: Icons.today_rounded,
                          ),
                          _FilterOption(
                            value: _HomeDateFilter.thisWeek,
                            label: 'This week',
                            icon: Icons.view_week_rounded,
                          ),
                          _FilterOption(
                            value: _HomeDateFilter.thisMonth,
                            label: 'This month',
                            icon: Icons.calendar_view_month_rounded,
                          ),
                        ],
                        onChanged: widget.onDateChanged,
                      ),
                      const SizedBox(height: 8),
                      _FilterGroup<_HomeMediaFilter>(
                        label: 'Media',
                        value: widget.mediaFilter,
                        options: const [
                          _FilterOption(
                            value: _HomeMediaFilter.any,
                            label: 'Any media',
                            icon: Icons.perm_media_outlined,
                          ),
                          _FilterOption(
                            value: _HomeMediaFilter.video,
                            label: 'Video',
                            icon: Icons.ondemand_video_rounded,
                          ),
                          _FilterOption(
                            value: _HomeMediaFilter.music,
                            label: 'Music',
                            icon: Icons.music_note_rounded,
                          ),
                        ],
                        onChanged: widget.onMediaChanged,
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _FilterGroup<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<_FilterOption<T>> options;
  final ValueChanged<T> onChanged;

  const _FilterGroup({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: cs.onSurface.withValues(alpha: 0.54),
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < options.length; index++) ...[
                _FilterPill<T>(
                  option: options[index],
                  selected: value == options[index].value,
                  onSelected: () => onChanged(options[index].value),
                ),
                if (index != options.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterPill<T> extends StatelessWidget {
  final _FilterOption<T> option;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterPill({
    required this.option,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final foreground = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      avatar: Icon(option.icon, size: 16, color: foreground),
      label: Text(option.label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: foreground,
      ),
      selectedColor: cs.primaryContainer,
      backgroundColor: cs.surface,
      side: BorderSide(
        color: selected ? cs.primary.withValues(alpha: 0.5) : cs.outlineVariant,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _FilterOption<T> {
  final T value;
  final String label;
  final IconData icon;

  const _FilterOption({
    required this.value,
    required this.label,
    required this.icon,
  });
}
