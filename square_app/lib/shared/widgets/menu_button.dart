import 'package:flutter/material.dart';
import '../../core/utils/scaffold_key.dart';
import 'app_icon_button.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return AppIconButton(
      icon: Icons.menu,
      onPressed: () => appScaffoldKey.currentState?.openEndDrawer(),
    );
  }
}
