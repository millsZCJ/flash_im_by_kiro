import 'package:flutter/material.dart';
import '../model/search_result.dart';
import 'search_result_item.dart';

/// 搜索结果分类区块（联系人 / 群聊 / 聊天记录）
class SearchSection extends StatelessWidget {
  final String title;
  final List<SearchResult> results;
  final String keyword;
  final void Function(SearchResult) onTap;

  const SearchSection({
    super.key,
    required this.title,
    required this.results,
    required this.keyword,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类标题
        Container(
          width: double.infinity,
          color: const Color(0xFFEDEDED),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF888888),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // 结果列表
        ...results.asMap().entries.map((entry) {
          final i = entry.key;
          final result = entry.value;
          return Column(
            children: [
              SearchResultItem(
                result: result,
                keyword: keyword,
                onTap: () => onTap(result),
              ),
              if (i < results.length - 1)
                const Divider(height: 1, indent: 72, color: Color(0xFFE5E5E5)),
            ],
          );
        }),
      ],
    );
  }
}
