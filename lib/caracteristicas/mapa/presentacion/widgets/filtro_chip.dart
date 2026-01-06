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
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final inactiveColor = Colors.grey.shade700;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // CORRECCIÓN: Padding reducido para que quepan todos en pantalla
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.2 : 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : inactiveColor,
              size: 16, // Ícono más pequeño
            ),
            const SizedBox(width: 6), // Menos espacio
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : inactiveColor,
                fontWeight: FontWeight.w600,
                fontSize: 13, // Letra compacta
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}