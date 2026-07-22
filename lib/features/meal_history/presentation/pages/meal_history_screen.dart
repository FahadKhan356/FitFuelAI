import 'package:fitfuel_ai/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

const _bg = Color(0xFFF7F6FB);
const _surface = Colors.white;
const _purple = Color(AppColors.authPurple);
const _purpleLight = Color(0xFFEDEBFB);
const _purpleSoft = Color(0xFFF3F0FF);
const _textPrimary = Color(0xFF1F1F2E);
const _textSecondary = Color(0xFF70707C);
const _border = Color(0xFFE7E3EF);
const _line = Color(0xFFE3DFFF);

class MealHistoryScreen extends StatelessWidget {
  const MealHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Row(
                children: [
                  _IconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Meal History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFECE9F4)),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  const _SearchBar(),
                  const SizedBox(height: 16),
                  const _FilterChips(),
                  const SizedBox(height: 18),
                  _DayHeader(
                    title: 'Today',
                    dateLabel: 'Oct 24',
                    totalLabel: 'TOTAL',
                    totalValue: '1,450 / 2,100 kcal',
                  ),
                  const SizedBox(height: 12),
                  const _MealEntryCard(
                    category: 'LUNCH',
                    time: '01:45 PM',
                    title: 'Grilled Salmon & more',
                    description: 'Grilled Salmon, Quinoa Salad, Avocado',
                    calories: '540',
                    protein: '42g',
                    carbs: '35g',
                    fat: '22g',
                    thumbnail: _ThumbnailStyle.salmon,
                  ),
                  const SizedBox(height: 18),
                  const _MealEntryCard(
                    category: 'BREAKFAST',
                    time: '08:15 AM',
                    title: 'Greek Yogurt & more',
                    description: 'Greek Yogurt, Mixed Berries, Granola',
                    calories: '320',
                    protein: '24g',
                    carbs: '45g',
                    fat: '8g',
                    thumbnail: _ThumbnailStyle.yogurt,
                  ),
                  const SizedBox(height: 22),
                  _DayHeader(
                    title: 'Yesterday',
                    dateLabel: 'Oct 23',
                    totalLabel: 'TOTAL',
                    totalValue: '2,050 / 2,100 kcal',
                  ),
                  const SizedBox(height: 12),
                  const _MealEntryCard(
                    category: 'DINNER',
                    time: '07:30 PM',
                    title: 'Stir-fry Tofu & more',
                    description: 'Stir-fry Tofu, Broccoli, Brown Rice',
                    calories: '480',
                    protein: '30g',
                    carbs: '62g',
                    fat: '12g',
                    thumbnail: _ThumbnailStyle.tofu,
                  ),
                  const SizedBox(height: 18),
                  const _MealEntryCard(
                    category: 'SNACK',
                    time: '04:00 PM',
                    title: 'Almonds & more',
                    description: 'Almonds, Protein Shake',
                    calories: '210',
                    protein: '25g',
                    carbs: '8g',
                    fat: '14g',
                    thumbnail: _ThumbnailStyle.almonds,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 20, color: _textPrimary),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, size: 22, color: _textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Search meals, ingredients...',
              style: TextStyle(
                fontSize: 15.5,
                color: _textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: const [
          _FilterChip(label: 'All', selected: true),
          SizedBox(width: 10),
          _FilterChip(label: 'Breakfast'),
          SizedBox(width: 10),
          _FilterChip(label: 'Lunch'),
          SizedBox(width: 10),
          _FilterChip(label: 'Dinner'),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    this.selected = false,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? _purple : _surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? _purple : _border,
          width: selected ? 0 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? _purple.withValues(alpha: 0.22)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : _textSecondary,
        ),
      ),
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({
    required this.title,
    required this.dateLabel,
    required this.totalLabel,
    required this.totalValue,
  });

  final String title;
  final String dateLabel;
  final String totalLabel;
  final String totalValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.calendar_month_outlined, size: 18, color: _purple),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              totalLabel,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _textSecondary,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              totalValue,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _purple,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MealEntryCard extends StatelessWidget {
  const _MealEntryCard({
    required this.category,
    required this.time,
    required this.title,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.thumbnail,
  });

  final String category;
  final String time;
  final String title;
  final String description;
  final String calories;
  final String protein;
  final String carbs;
  final String fat;
  final _ThumbnailStyle thumbnail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: -16,
            top: 0,
            bottom: 0,
            child: _TimelineDot(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _iconForCategory(category),
                      size: 16,
                      color: _textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '$category • $time',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: _textSecondary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const Icon(Icons.more_horiz, size: 22, color: _textSecondary),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MealThumb(style: thumbnail),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.25,
                                fontWeight: FontWeight.w500,
                                color: _textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  calories,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 3),
                                  child: Text(
                                    'KCAL',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: _textSecondary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, thickness: 1, color: Color(0xFFECEAF2)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _MacroItem(label: 'PROTEIN', value: protein)),
                    const SizedBox(width: 10),
                    Expanded(child: _MacroItem(label: 'CARBS', value: carbs, accent: _cyan)),
                    const SizedBox(width: 10),
                    Expanded(child: _MacroItem(label: 'FAT', value: fat)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    _ActionPill(icon: Icons.edit_outlined, label: 'Edit'),
                    SizedBox(width: 10),
                    _ActionPill(icon: Icons.add, label: 'Re-add'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _cyan = Color(0xFF35D1F2);

class _TimelineDot extends StatelessWidget {
  const _TimelineDot();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: _purple,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _purple.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            width: 2,
            margin: const EdgeInsets.only(top: 8),
            color: _line,
          ),
        ),
      ],
    );
  }
}

class _MealThumb extends StatelessWidget {
  const _MealThumb({required this.style});

  final _ThumbnailStyle style;

  @override
  Widget build(BuildContext context) {
    final config = switch (style) {
      _ThumbnailStyle.salmon => (
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF2D6B5), Color(0xFFD79A6B)],
          ),
          icon: Icons.set_meal_rounded,
          iconColor: Color(0xFF8A4E26),
        ),
      _ThumbnailStyle.yogurt => (
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF1E4CF), Color(0xFFC39A6B)],
          ),
          icon: Icons.breakfast_dining_rounded,
          iconColor: Color(0xFF7B5327),
        ),
      _ThumbnailStyle.tofu => (
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFDAB58C), Color(0xFF9A6A43)],
          ),
          icon: Icons.dinner_dining_rounded,
          iconColor: Color(0xFF5C3C23),
        ),
      _ThumbnailStyle.almonds => (
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE9D3B4), Color(0xFFB98D5E)],
          ),
          icon: Icons.lunch_dining_rounded,
          iconColor: Color(0xFF6A4322),
        ),
    };

    return Container(
      width: 86,
      height: 86,
      decoration: BoxDecoration(
        gradient: config.gradient,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(config.icon, color: config.iconColor, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}

enum _ThumbnailStyle { salmon, yogurt, tofu, almonds }

class _MacroItem extends StatelessWidget {
  const _MacroItem({
    required this.label,
    required this.value,
    this.accent = _purple,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: _textSecondary,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 4,
            value: 0.72,
            backgroundColor: const Color(0xFFE9E7F1),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _textSecondary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: _textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForCategory(String category) {
  switch (category) {
    case 'LUNCH':
      return Icons.restaurant_menu_outlined;
    case 'BREAKFAST':
      return Icons.free_breakfast_outlined;
    case 'DINNER':
      return Icons.local_dining_outlined;
    case 'SNACK':
      return Icons.apple;
    default:
      return Icons.restaurant_outlined;
  }
}
