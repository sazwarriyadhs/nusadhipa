import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

class NusaDhipaBrandHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const NusaDhipaBrandHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(AppConstants.line),
          ),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 180,
            child: Image.asset(
              AppConstants.logoAsset,
              width: 180,
              fit: BoxFit.contain,
              alignment: Alignment.centerLeft,
              errorBuilder: (_, _, _) {
                return const SizedBox(
                  width: 180,
                  height: 48,
                  child: Icon(
                    Icons.restaurant,
                    color: Color(AppConstants.primaryRed),
                    size: 32,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(AppConstants.text),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(AppConstants.muted),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
