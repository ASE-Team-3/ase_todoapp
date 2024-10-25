import 'package:app/utils/app_str.dart';
import 'package:flutter/material.dart';

class RepTextField extends StatelessWidget {
  const RepTextField({
    super.key,
    required this.controller,
    this.isForDescription = false,
  });

  final TextEditingController controller;
  final bool isForDescription;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListTile(
        title: TextFormField(
          controller: controller,
          maxLines: !isForDescription ? 4 : null,
          cursorHeight: !isForDescription ? 60 : null,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            border: isForDescription ? InputBorder.none : null,
            counter: Container(),
            hintText: isForDescription ? AppStr.addNote : null,
            prefixIcon: isForDescription
                ? const Icon(
                    Icons.bookmark_border,
                    color: Colors.grey,
                  )
                : null,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.grey.shade300,
              ),
            ),
          ),
          onFieldSubmitted: (value) {
            /// TODO: WORK ON THIS LATER
          },
          onChanged: (value) {
            /// TODO: WORK ON THIS LATER
          },
        ),
      ),
    );
  }
}
