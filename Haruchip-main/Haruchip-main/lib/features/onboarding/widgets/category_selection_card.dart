import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/onboarding_category.dart';

/// 온보딩 카테고리 선택 컴팩트 칩/카드 (수평 10dp / 수직 6dp 슬림 규격, 햅틱 피드백 & 파스텔 하이라이트)
class CategorySelectionCard extends StatelessWidget {
  const CategorySelectionCard({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final OnboardingCategory category;
  final bool selected;
  final VoidCallback onTap;

  void _handleTap() {
    HapticFeedback.lightImpact();
    onTap();
  }

  Color _getPastelHighlightColor() {
    switch (category.key) {
      case 'couple':
        return const Color(0xFFFF7A9C);
      case 'wedding':
        return const Color(0xFFFF9EAA);
      case 'baby':
        return const Color(0xFFFBBF24);
      case 'military':
        return const Color(0xFF34D399);
      case 'exam':
        return const Color(0xFF60A5FA);
      case 'meeting':
        return const Color(0xFF818CF8);
      case 'pet':
        return const Color(0xFFFB923C);
      case 'birthday':
        return const Color(0xFFF472B6);
      case 'hobby':
        return const Color(0xFF10B981);
      case 'travel':
        return const Color(0xFF0EA5E9);
      default:
        return const Color(0xFF6366F1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlightColor = _getPastelHighlightColor();

    return Semantics(
      button: true,
      selected: selected,
      label: '${category.labelKo} 카테고리',
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? highlightColor.withValues(alpha: 0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? highlightColor
                  : const Color(0xFFE5E7EB),
              width: selected ? 1.6 : 1.0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: highlightColor.withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  category.labelKo,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? const Color(0xFF191F28)
                        : const Color(0xFF4B5563),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
