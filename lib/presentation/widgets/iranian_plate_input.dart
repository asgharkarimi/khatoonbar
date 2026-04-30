import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IranianPlateInput extends StatefulWidget {
  final String? initialValue;
  final Function(String) onChanged;

  const IranianPlateInput({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<IranianPlateInput> createState() => _IranianPlateInputState();
}

class _IranianPlateInputState extends State<IranianPlateInput> {
  late TextEditingController _part1Controller; // 2 digits
  late TextEditingController _letterController; // letter
  late TextEditingController _part2Controller; // 3 digits
  late TextEditingController _part3Controller; // 2 digits (Iran code)

  final FocusNode _fn1 = FocusNode();
  final FocusNode _fnLetter = FocusNode();
  final FocusNode _fn2 = FocusNode();
  final FocusNode _fn3 = FocusNode();

  final List<String> _persianLetters = [
    'الف', 'ب', 'ج', 'د', 'س', 'ص', 'ط', 'ع', 'ق', 'ل', 'م', 'ن', 'و', 'ه', 'ی', 'ژ'
  ];

  @override
  void initState() {
    super.initState();
    
    String p1 = "";
    String letter = "ب";
    String p2 = "";
    String p3 = "";

    if (widget.initialValue != null && widget.initialValue!.length >= 8) {
      // Assuming a simple format for now based on how it's concatenated in _update
      // format: 2digits + letter + 3digits + 2digits
      // This is a bit brittle if letter length varies, but usually it's 1 char or "الف"
      // Let's try to parse it more intelligently or just handle common cases.
      String val = widget.initialValue!;
      p1 = val.substring(0, 2);
      
      // Find where the letter ends. It starts at index 2.
      // After the letter, there should be 5 digits (3+2) at the end.
      int letterEnd = val.length - 5;
      if (letterEnd > 2) {
        letter = val.substring(2, letterEnd);
        p2 = val.substring(letterEnd, letterEnd + 3);
        p3 = val.substring(letterEnd + 3);
      }
    }

    _part1Controller = TextEditingController(text: p1);
    _letterController = TextEditingController(text: letter);
    _part2Controller = TextEditingController(text: p2);
    _part3Controller = TextEditingController(text: p3);
  }

  void _update() {
    final plate = "${_part1Controller.text}${_letterController.text}${_part2Controller.text}${_part3Controller.text}";
    widget.onChanged(plate);
  }

  @override
  Widget build(BuildContext context) {
    const double plateHeight = 52.0;
    const double capsuleHeight = 32.0;
    const TextStyle digitStyle = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.bold,
      color: Colors.black,
    );

    return Container(
      height: plateHeight,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Row(
        textDirection: TextDirection.ltr,
        children: [
          // بخش آبی سمت چپ
          Container(
            width: 35,
            decoration: const BoxDecoration(
              color: Color(0xFF063B96),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                bottomLeft: Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 12,
                  child: Column(
                    children: [
                      Expanded(child: Container(color: Colors.green)),
                      Expanded(child: Container(color: Colors.white)),
                      Expanded(child: Container(color: Colors.red)),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'I.R. IRAN',
                  style: TextStyle(color: Colors.white, fontSize: 4.5, fontWeight: FontWeight.bold, height: 1),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // بخش ۱: ۲ رقم (بدون کپسول)
          Expanded(
            flex: 2,
            child: _buildDigitField(_part1Controller, _fn1, 2, digitStyle, nextNode: _fnLetter),
          ),
          
          // بخش حروف
          GestureDetector(
            onTap: _showLetterPicker,
            child: Container(
              width: 35,
              alignment: Alignment.center,
              child: Text(
                _letterController.text,
                style: digitStyle.copyWith(fontSize: 16),
              ),
            ),
          ),

          // بخش ۲: ۳ رقم (داخل کپسول)
          Expanded(
            flex: 3,
            child: Container(
              height: capsuleHeight,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.grey.shade300, width: 1.2),
              ),
              child: _buildDigitField(_part2Controller, _fn2, 3, digitStyle, prevNode: _fnLetter, nextNode: _fn3),
            ),
          ),

          // خط جداکننده عمودی
          Container(width: 1.5, color: Colors.black, height: double.infinity),

          // بخش ۳: کد ایران (متن ایران در بالا و عدد در کپسول)
          Container(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('ایران', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 1),
                Container(
                  height: capsuleHeight - 2,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.grey.shade300, width: 1.2),
                  ),
                  child: _buildDigitField(_part3Controller, _fn3, 2, digitStyle, prevNode: _fn2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitField(
    TextEditingController controller, 
    FocusNode focusNode, 
    int maxLength, 
    TextStyle style, 
    {FocusNode? nextNode, FocusNode? prevNode}
  ) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      style: style,
      showCursor: false,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        counterText: '',
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (value) {
        if (value.length == maxLength && nextNode != null) {
          nextNode.requestFocus();
        }
        if (value.isEmpty && prevNode != null) {
          prevNode.requestFocus();
        }
        _update();
      },
    );
  }

  void _showLetterPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('انتخاب حرف پلاک', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: _persianLetters.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () {
                      setState(() => _letterController.text = _persianLetters[index]);
                      _update();
                      Navigator.pop(context);
                      _fn2.requestFocus();
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(_persianLetters[index], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
