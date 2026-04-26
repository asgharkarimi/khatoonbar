import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/utils/formatters.dart';

class AmountInput extends StatefulWidget {
  final String label;
  final String? hint;
  final String unit;
  final double? initialValue;
  final Function(double) onChanged;
  final bool isDecimal;

  const AmountInput({
    super.key, 
    required this.label, 
    required this.onChanged,
    this.unit = "تومان",
    this.hint,
    this.initialValue,
    this.isDecimal = false,
  });

  @override
  State<AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<AmountInput> {
  late TextEditingController _controller;
  String _words = "";
  final _formatter = intl.NumberFormat("#,###.###");

  @override
  void initState() {
    super.initState();
    String initialText = "";
    if (widget.initialValue != null && widget.initialValue! > 0) {
      if (widget.isDecimal) {
        initialText = widget.initialValue!.toString().toPersianDigit();
      } else {
        initialText = _formatter.format(widget.initialValue!.toInt());
      }
      _words = AppFormatters.amountToWords(widget.initialValue!, unit: widget.unit);
    }
    _controller = TextEditingController(text: initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          keyboardType: TextInputType.numberWithOptions(decimal: widget.isDecimal),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint ?? (widget.isDecimal ? "مثلا 24.5" : "مثلا 50,000"),
            hintStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          ),
          onChanged: (val) {
            final cleanVal = val.replaceAll(',', '').toEnglishDigit();
            final double? amount = double.tryParse(cleanVal);
            
            if (amount != null) {
              setState(() {
                _words = amount == 0 ? "صفر ${widget.unit}" : AppFormatters.amountToWords(amount, unit: widget.unit);
              });
              
              if (!widget.isDecimal) {
                // جدا کردن سه رقم سه رقم فقط برای مبالغ غیر اعشاری
                if (amount > 0) {
                  String formatted = _formatter.format(amount.toInt());
                  if (val != formatted) {
                    _controller.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  }
                }
              }

              widget.onChanged(amount);
            } else {
              setState(() {
                _words = "";
              });
              widget.onChanged(0);
            }
          },
        ),
        if (_words.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, right: 8),
            child: Text(
              _words,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}
