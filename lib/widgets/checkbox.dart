import 'package:flutter/material.dart';

class AppCheckbox extends StatefulWidget {
  final String text;
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  const AppCheckbox({
    super.key,
    required this.text,
    this.initialValue = false,
    this.onChanged,
  });

  @override
  State<AppCheckbox> createState() => _AppCheckboxState();
}

class _AppCheckboxState extends State<AppCheckbox> {
  late bool value;

  @override
  void initState() {
    super.initState();
    value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          activeColor: Colors.green,
          onChanged: (v) {
            setState(() {
              value = v!;
            });

            widget.onChanged?.call(value);
          },
        ),

        Expanded(
          child: Text(
            widget.text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
