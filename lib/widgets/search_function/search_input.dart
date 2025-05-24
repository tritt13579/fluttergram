import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/searchfl_controller.dart';

class SearchInput extends StatelessWidget {
  final SearchFlutterController controller;

  const SearchInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Center(
        child: TextFormField(
          controller: controller.textEditingController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Tìm kiếm',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            icon: Icon(Icons.search, color: Colors.white70),
          ),
          onFieldSubmitted: (value) {
            if (value.startsWith('#')) {
              controller.onHashtagSubmitted(value);
            } else {
              controller.onUserSearchSubmitted(value);
            }
          },
        ),
      ),
    );
  }
}