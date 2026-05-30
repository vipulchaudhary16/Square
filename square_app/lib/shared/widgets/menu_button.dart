import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/scaffold_key.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(LucideIcons.menu),
      onPressed: () => appScaffoldKey.currentState?.openEndDrawer(),
    );
  }
}
