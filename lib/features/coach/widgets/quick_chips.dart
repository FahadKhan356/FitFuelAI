import 'dart:ui';
import 'package:flutter/material.dart';

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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : () => onSelect(item.query),
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF5B4BDB).withValues(alpha: 0.04),
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
                    color: const Color(0xFF5B4BDB),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B4BDB),
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
