import 'package:flutter/material.dart';
import 'user_search_section.dart';

class SearchTabContent extends StatelessWidget {
  const SearchTabContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 16),
      child: UserSearchSection(),
    );
  }
} 