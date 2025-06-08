// lib/widgets/main_bottom_navigation.dart
import 'package:flutter/material.dart';
import 'package:pro_aula/core/theme/app_theme.dart';

class MainBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const MainBottomNavigation({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0:
            if (currentIndex != 0) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              );
            }
            break;
          case 1:
            if (currentIndex != 1) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/courses',
                (route) => false,
              );
            }
            break;
          case 2:
            if (currentIndex != 2) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/ai-assistant',
                (route) => false,
              );
            }
            break;
          case 3:
            if (currentIndex != 3) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/profile',
                (route) => false,
              );
            }
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.school_rounded),
          label: 'Cursos',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.psychology_rounded),
          label: 'AI',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    );
  }
}
