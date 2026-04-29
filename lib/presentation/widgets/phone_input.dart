import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final Function(String)? onChanged;
  final String? initialValue;

  const PhoneInput({
    super.key,
    this.controller,
    this.label,
    this.onChanged,
    this.initialValue,
  });

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController(text: widget.initialValue);
    
    if (_internalController.text.startsWith('0')) {
      _internalController.text = _internalController.text.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 8),
            child: Text(
              widget.label!,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14, 
                fontWeight: FontWeight.bold, 
                color: Color(0xFF475467),
                fontFamily: 'IranYekan',
              ),
            ),
          ),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD0D5DD)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            textDirection: TextDirection.ltr,
            children: [
              const Text(
                "+98",
                style: TextStyle(
                  color: Color(0xFF101828),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                height: 24,
                color: const Color(0xFFEAECF0),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _internalController,
                  onChanged: (value) {
                    if (value.startsWith('0')) {
                      _internalController.text = value.substring(1);
                      _internalController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _internalController.text.length),
                      );
                    }
                    if (widget.onChanged != null) {
                      widget.onChanged!(_internalController.text);
                    }
                  },
                  keyboardType: TextInputType.phone,
                  textAlign: TextAlign.left,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(
                    color: Color(0xFF101828),
                    fontSize: 18,
                    letterSpacing: 2,
                  ),
                  decoration: const InputDecoration(
                    hintText: "9123456789",
                    hintStyle: TextStyle(color: Color(0xFF98A2B3), letterSpacing: 2),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
