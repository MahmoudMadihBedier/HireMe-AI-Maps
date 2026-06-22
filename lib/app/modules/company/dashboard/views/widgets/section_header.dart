import 'package:flutter/material.dart';

import '../../../../../../core/utils/app_color.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onMoreTap;

  const SectionHeader({
    super.key,
    required this.title,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColor.kblack,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        GestureDetector(
          onTap: onMoreTap,
          child: Text(
            'More',
            style: TextStyle(
              color: AppColor.kblue,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
