import 'package:flutter/material.dart';

import '../api/api_service.dart';

class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    required this.meta,
    required this.onPage,
  });

  final LinenMeta meta;
  final ValueChanged<int> onPage;

  @override
  Widget build(BuildContext context) {
    if (meta.lastPage <= 1) return const SizedBox.shrink();

    final canPrevious = meta.currentPage > 1;
    final canNext = meta.currentPage < meta.lastPage;

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 100),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PaginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: canPrevious,
            onTap: canPrevious ? () => onPage(meta.currentPage - 1) : null,
          ),
          const SizedBox(width: 12),
          Text(
            'Halaman ${meta.currentPage} dari ${meta.lastPage}',
            style: const TextStyle(
              fontSize: 9,
              color: Color(0xff6f7f8d),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          _PaginationButton(
            icon: Icons.chevron_right_rounded,
            enabled: canNext,
            onTap: canNext ? () => onPage(meta.currentPage + 1) : null,
          ),
        ],
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  const _PaginationButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? const Color(0xff1261dc) : const Color(0xffdfe7ef),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 21,
            color: enabled ? Colors.white : const Color(0xff9aa7b3),
          ),
        ),
      ),
    );
  }
}