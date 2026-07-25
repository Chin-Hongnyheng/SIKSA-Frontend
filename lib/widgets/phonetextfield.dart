import 'package:flutter/material.dart';

class PhoneTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String?
  initialValue; // full number e.g. "855912345678" or "+855912345678"

  const PhoneTextField({
    super.key,
    this.label = "Phone Number",
    this.hint = "Enter phone number",
    required this.controller,
    this.initialValue,
  });

  @override
  State<PhoneTextField> createState() => _PhoneTextFieldState();
}

class _PhoneTextFieldState extends State<PhoneTextField> {
  late FocusNode _focusNode;
  bool isFocused = false;
  String countryCode = "+855";
  late TextEditingController _phoneOnlyController;

  final List<Map<String, String>> countries = [
    {"code": "+855", "flag": "🇰🇭"},
    {"code": "+1", "flag": "🇺🇸"},
    {"code": "+66", "flag": "🇹🇭"},
    {"code": "+84", "flag": "🇻🇳"},
  ];

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _phoneOnlyController = TextEditingController();

    _focusNode.addListener(() {
      setState(() {
        isFocused = _focusNode.hasFocus;
      });
    });

    // Parse initialValue BEFORE attaching the listener,
    // so we don't trigger _updateFullPhoneNumber while splitting.
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      // Strip any leading "+" so comparisons are consistent either way.
      final raw = widget.initialValue!.trim().replaceAll('+', '');

      // Sort codes longest-first so "+855" is checked before any shorter overlap.
      final sortedCountries = [...countries]
        ..sort((a, b) => b["code"]!.length.compareTo(a["code"]!.length));

      final match = sortedCountries.firstWhere(
        (c) => raw.startsWith(c["code"]!.replaceAll('+', '')),
        orElse: () => countries.first,
      );

      countryCode = match["code"]!;
      final codeDigits = match["code"]!.replaceAll('+', '');

      _phoneOnlyController.text = raw.startsWith(codeDigits)
          ? raw.substring(codeDigits.length)
          : raw;
    }

    // Attach listener AFTER initial split, so typing updates the combined value
    // but the initial prefill doesn't get double-processed.
    _phoneOnlyController.addListener(_updateFullPhoneNumber);

    // Sync the combined controller once, after state is set.
    _updateFullPhoneNumber();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _phoneOnlyController.dispose();
    super.dispose();
  }

  void _updateFullPhoneNumber() {
    final phoneOnly = _phoneOnlyController.text.trim();
    final codeOnly = countryCode.replaceAll('+', '');
    final fullPhone = codeOnly + phoneOnly;
    widget.controller.text = fullPhone;
  }

  void _onCountryCodeChanged(String? value) {
    setState(() {
      countryCode = value!;
    });
    _updateFullPhoneNumber();
  }

  Map<String, String> get selectedCountry {
    return countries.firstWhere((c) => c["code"] == countryCode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneOnlyController,
          focusNode: _focusNode,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: isFocused ? null : widget.hint,
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 12,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 12, right: 8),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: countryCode,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  items: countries.map((country) {
                    return DropdownMenuItem(
                      value: country["code"],
                      child: Row(
                        children: [
                          Text(
                            country["flag"]!,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Text(country["code"]!),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _onCountryCodeChanged,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 90,
              maxWidth: 120,
            ),
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
              borderSide: const BorderSide(color: Colors.green, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
