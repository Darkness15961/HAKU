import 'package:flutter/material.dart';

class FiltroChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const FiltroChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : theme.colorScheme.onSurface),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}