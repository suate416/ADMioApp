import 'package:flutter/material.dart';

import '../config/app_colors.dart';

class BuildBottomNavigationBar extends StatefulWidget {
  final Function(int) cambiarTab;
  final int currentIndex;

  const BuildBottomNavigationBar({
    super.key,
    required this.cambiarTab,
    required this.currentIndex,
  });

  @override
  State<BuildBottomNavigationBar> createState() =>
      BuildBottomNavigationBarState();
}

class BuildBottomNavigationBarState extends State<BuildBottomNavigationBar> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 70,
          decoration: BoxDecoration(
            color: AppColors.white,
            border: Border(
              top: BorderSide(
                color: AppColors.gray400,
                width: 0.5,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray300.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Home
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.cambiarTab(0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.home_outlined,
                        color: widget.currentIndex == 0
                            ? AppColors.secondary
                            : AppColors.gray500,
                        size: 45,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ),
              // Espacio para el botón central
              const SizedBox(width: 60),
              // Account
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.cambiarTab(2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: widget.currentIndex == 2
                            ? AppColors.secondary
                            : AppColors.gray500,
                        size: 45,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Botón central flotante con icono de tijeras
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 30,
          top: -25,
          child: GestureDetector(
            onTap: () => widget.cambiarTab(1),
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: widget.currentIndex == 1
                    ? AppColors.secondary
                    : AppColors.black,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color:
                        (widget.currentIndex == 1
                                ? AppColors.secondary
                                : AppColors.black)
                            .withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.content_cut,
                color: AppColors.white,
                size: 32,
              ),
            ),
          ),
        ),
        // Línea indicadora en la parte inferior
        Positioned(
          bottom: 0,
          left: widget.currentIndex == 0
              ? MediaQuery.of(context).size.width / 4 - 30
              : widget.currentIndex == 2
              ? MediaQuery.of(context).size.width * 3 / 4 - 30
              : MediaQuery.of(context).size.width / 2 - 30,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray900,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}
