import 'package:flutter/material.dart';
import '../config/app_colors.dart';

class TabNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;

  const TabNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildTab('Pasadas', 0)),
          Expanded(child: _buildTab('Servicios', 1)),
          Expanded(child: _buildTab('En Proceso', 2)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTabChanged(index),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize:20,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.secondary : AppColors.gray500,
            ),
          ),
          const SizedBox(height: 8),
          if (isSelected)
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 3),
        ],
      ),
    );
  }
}

