import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../shared/theme/app_theme.dart';

/// Horizontal glass chips shown above the input bar.
/// Offers quick insight queries: "Today's balance", "Macro gaps", "Hydration", "Weekly trend".
class QuickChips extends StatelessWidget {
  final ValueChanged<String> onSelect;
  final bool isBusy;

  const QuickChips({
    super.key,
    required this.onSelect,
    this.isBusy = false,
  });

  static const List<_QuickChipItem> _items = [
    _QuickChipItem(
      label: "Today's balance",
      icon: Icons.history_rounded,
      query: "How's my calorie balance today?",
    ),
    _QuickChipItem(
      label: 'Macro gaps',
      icon: Icons.pie_chart_outline_rounded,
      query: 'What are my macro gaps today?',
    ),
    _QuickChipItem(
      label: 'Hydration',
      icon: Icons.water_drop_outlined,
      query: 'How is my hydration status today?',
    ),
    _QuickChipItem(
      label: 'Weekly trend',
      icon: Icons.trending_up_rounded,
      query: 'Show my weekly calorie and nutrition trend',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = _items[index];
          return _buildChip(context, item);
        },
      ),
    );
  }

  Widget _buildChip(BuildContext context, _QuickChipItem item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark
        ? const Color(0xFF1E1714).withValues(alpha: 0.25)
        : Colors.white.withValues(alpha: 0.25);
    final chipBorder = isDark
        ? AppDarkColors.border.withValues(alpha: 0.40)
        : Colors.white.withValues(alpha: 0.60);
    final contentColor = isDark
        ? const Color(0xFFB4A8FF)
        : const Color(0xFF5B4BDB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : () => onSelect(item.query),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: chipBorder,
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 15,
                    color: contentColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: contentColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChipItem {
  final String label;
  final IconData icon;
  final String query;

  const _QuickChipItem({
    required this.label,
    required this.icon,
    required this.query,
  });
}
