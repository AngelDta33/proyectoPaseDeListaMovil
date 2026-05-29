import 'package:flutter/material.dart';
import '../../models/activity_model.dart';
import 'activity_card.dart';

class CategorySection extends StatelessWidget {
  final ActivityCategory category;
  final void Function(Activity) onActivityTap;

  const CategorySection({
    super.key,
    required this.category,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: category.color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                category.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: category.color,
                  letterSpacing: -0.3,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: category.color.withOpacity(0.6),
                size: 16,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: category.activities.length,
            itemBuilder: (context, index) => ActivityCard(
              activity: category.activities[index],
              categoryColor: category.color,
              onTap: () => onActivityTap(category.activities[index]),
            ),
          ),
        ),
      ],
    );
  }
}
