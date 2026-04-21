import 'package:flutter/material.dart';
import '../model/search_result.dart';

/// 单条搜索结果行
class SearchResultItem extends StatelessWidget {
  final SearchResult result;
  final String keyword;
  final VoidCallback onTap;

  const SearchResultItem({
    super.key,
    required this.result,
    required this.keyword,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _buildAvatar(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _HighlightText(text: result.title, keyword: keyword, bold: true)),
                      if (result.time != null)
                        Text(
                          result.time!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  _HighlightText(text: result.subtitle, keyword: keyword, bold: false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final isGroup = result.type == SearchResultType.group;
    final color = _avatarColor(result.title);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(isGroup ? 10 : 6),
      ),
      alignment: Alignment.center,
      child: isGroup
          ? const Icon(Icons.group, color: Colors.white, size: 22)
          : Text(
              result.title.characters.first,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
            ),
    );
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF5B9BD5),
      Color(0xFF70AD47),
      Color(0xFFED7D31),
      Color(0xFFFFC000),
      Color(0xFF4472C4),
      Color(0xFF9E480E),
      Color(0xFF636363),
      Color(0xFF997300),
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }
}

/// 高亮关键词的文本组件
class _HighlightText extends StatelessWidget {
  final String text;
  final String keyword;
  final bool bold;

  const _HighlightText({
    required this.text,
    required this.keyword,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    if (keyword.isEmpty) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: bold ? 15 : 13,
          fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
          color: bold ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
        ),
      );
    }

    final lowerText = text.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();
    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final idx = lowerText.indexOf(lowerKeyword, start);
      if (idx == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (idx > start) {
        spans.add(TextSpan(text: text.substring(start, idx)));
      }
      spans.add(TextSpan(
        text: text.substring(idx, idx + keyword.length),
        style: const TextStyle(color: Color(0xFF07C160), fontWeight: FontWeight.w600),
      ));
      start = idx + keyword.length;
    }

    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: TextStyle(
          fontSize: bold ? 15 : 13,
          fontWeight: bold ? FontWeight.w500 : FontWeight.normal,
          color: bold ? const Color(0xFF1A1A1A) : const Color(0xFF999999),
        ),
        children: spans,
      ),
    );
  }
}
