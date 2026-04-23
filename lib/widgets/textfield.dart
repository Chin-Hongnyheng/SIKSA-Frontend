import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData? icon;
  final bool secure;
  final bool showToggle;
  final TextEditingController controller;

  const AppTextField({
    super.key,
    required this.label,
    required this.hint,
    this.icon,
    required this.secure,
    this.showToggle = false,
    required this.controller,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool isFocused = false;
  late bool obscure;

  @override
  void initState() {
    super.initState();

    obscure = widget.secure;

    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        TextField(
          controller: widget.controller,
          focusNode: _focusNode,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: isFocused ? null : widget.hint,
            hintStyle: const TextStyle(color: Colors.grey),

            prefixIcon: widget.icon != null
                ? Padding(
                    padding: EdgeInsets.only(left: 12, right: 8),
                    child: Icon(
                      widget.icon,
                      size: 25,
                      color: isFocused ? Colors.green : Colors.grey,
                    ),
                  )
                : null,

            // 🔥 PASSWORD TOGGLE ICON
            suffixIcon: widget.showToggle
                ? IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                      color: isFocused ? Colors.green : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        obscure = !obscure;
                      });
                    },
                  )
                : null,

            prefixIconConstraints: BoxConstraints(maxHeight: 40, maxWidth: 50),

            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),

            filled: true,
            fillColor: Colors.white,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
