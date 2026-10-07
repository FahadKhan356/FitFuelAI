import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {

  const CustomAppBar({
    Key? key,
    this.title,
    this.centerTitle = true,
    this.actions,
    this.leading,
    this.onLeadingPressed,
    this.showBackButton = true,
  }) : super(key: key);
  final String? title;
  final bool centerTitle;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onLeadingPressed;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) => AppBar(
      title: title != null ? Text(title!) : null,
      centerTitle: centerTitle,
      actions: actions,
      leading: leading ??
          (showBackButton
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: onLeadingPressed ?? () => Navigator.of(context).pop(),
                )
              : null),
      backgroundColor: const Color(AppColors.background),
      foregroundColor: const Color(AppColors.textPrimary),
      elevation: 0,
      scrolledUnderElevation: 0,
    );

  @override
  Size get preferredSize => const Size.fromHeight(56);
}

class CustomBottomNavBar extends StatelessWidget {

  const CustomBottomNavBar({
    required this.currentIndex, required this.onItemTapped, required this.items, Key? key,
  }) : super(key: key);
  final int currentIndex;
  final Function(int) onItemTapped;
  final List<BottomNavigationBarItem> items;

  @override
  Widget build(BuildContext context) => BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onItemTapped,
      items: items,
      backgroundColor: const Color(AppColors.surface),
      selectedItemColor: const Color(AppColors.primary),
      unselectedItemColor: const Color(AppColors.textSecondary),
      type: BottomNavigationBarType.fixed,
      elevation: 10,
    );
}
