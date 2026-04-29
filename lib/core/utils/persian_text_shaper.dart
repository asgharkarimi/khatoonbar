class PersianTextShaper {
  static const Map<int, List<int>> _forms = {
    0x0621: [0xFE80, 0xFE80, 0xFE80, 0xFE80], // Hamza
    0x0622: [0xFE81, 0xFE82, 0xFE81, 0xFE82], // Alef Mad
    0x0623: [0xFE83, 0xFE84, 0xFE83, 0xFE84], // Alef Hamza Top
    0x0624: [0xFE85, 0xFE86, 0xFE85, 0xFE86], // Waw Hamza
    0x0625: [0xFE87, 0xFE88, 0xFE87, 0xFE88], // Alef Hamza Bottom
    0x0626: [0xFE89, 0xFE8A, 0xFE8B, 0xFE8C], // Yeh Hamza
    0x0627: [0xFE8D, 0xFE8E, 0xFE8D, 0xFE8E], // Alef
    0x0628: [0xFE8F, 0xFE90, 0xFE91, 0xFE92], // Beh
    0x067E: [0xFB56, 0xFB57, 0xFB58, 0xFB59], // Peh
    0x062A: [0xFE95, 0xFE96, 0xFE97, 0xFE98], // Teh
    0x062B: [0xFE99, 0xFE9A, 0xFE9B, 0xFE9C], // Theh
    0x062C: [0xFE9D, 0xFE9E, 0xFE9F, 0xFEA0], // Jeem
    0x0686: [0xFB7A, 0xFB7B, 0xFB7C, 0xFB7D], // Cheh
    0x062D: [0xFEA1, 0xFEA2, 0xFEA3, 0xFEA4], // Hah
    0x062E: [0xFEA5, 0xFEA6, 0xFEA7, 0xFEA8], // Khah
    0x062F: [0xFEA9, 0xFEAA, 0xFEA9, 0xFEAA], // Dal
    0x0630: [0xFEAB, 0xFEAC, 0xFEAB, 0xFEAC], // Thal
    0x0631: [0xFEAD, 0xFEAE, 0xFEAD, 0xFEAE], // Reh
    0x0632: [0xFEAF, 0xFEB0, 0xFEAF, 0xFEB0], // Zeh
    0x0698: [0xFB8A, 0xFB8B, 0xFB8A, 0xFB8B], // Zheh
    0x0633: [0xFEB1, 0xFEB2, 0xFEB3, 0xFEB4], // Seen
    0x0634: [0xFEB5, 0xFEB6, 0xFEB7, 0xFEB8], // Sheen
    0x0635: [0xFEB9, 0xFEBA, 0xFEBB, 0xFEBC], // Sad
    0x0636: [0xFEBD, 0xFEBE, 0xFEBF, 0xFEC0], // Dad
    0x0637: [0xFEC1, 0xFEC2, 0xFEC3, 0xFEC4], // Tah
    0x0638: [0xFEC5, 0xFEC6, 0xFEC7, 0xFEC8], // Zah
    0x0639: [0xFEC9, 0xFECA, 0xFECB, 0xFECC], // Ain
    0x063A: [0xFECD, 0xFECE, 0xFECF, 0xFED0], // Ghain
    0x0641: [0xFED1, 0xFED2, 0xFED3, 0xFED4], // Feh
    0x0642: [0xFED5, 0xFED6, 0xFED7, 0xFED8], // Qaf
    0x06A9: [0xFB8E, 0xFB8F, 0xFB90, 0xFB91], // Kaf
    0x06AF: [0xFB92, 0xFB93, 0xFB94, 0xFB95], // Gaf
    0x0644: [0xFEDD, 0xFEDE, 0xFEDF, 0xFEE0], // Lam
    0x0645: [0xFEE1, 0xFEE2, 0xFEE3, 0xFEE4], // Meem
    0x0646: [0xFEE5, 0xFEE6, 0xFEE7, 0xFEE8], // Noon
    0x0648: [0xFEED, 0xFEEE, 0xFEED, 0xFEEE], // Waw (FIXED: Isolated=FEED, Final=FEEE)
    0x0647: [0xFEE9, 0xFEEA, 0xFEEB, 0xFEEC], // Heh (FIXED: Iso=FEE9, Fin=FEEA, Ini=FEEB, Med=FEEC)
    0x06CC: [0xFBFC, 0xFBFD, 0xFBFE, 0xFBFF], // Yeh
  };

  static bool _connectsToLeft(int charCode) {
    // حروف که به چپ نمی‌چسبند
    return _forms.containsKey(charCode) && 
           !([0x0627, 0x0622, 0x062F, 0x0630, 0x0631, 0x0632, 0x0698, 0x0648].contains(charCode));
  }

  static bool _connectsToRight(int charCode) {
    return _forms.containsKey(charCode) && charCode != 0x0621;
  }

  static String shape(String text) {
    if (text.isEmpty) return text;

    List<int> codes = text.codeUnits;
    List<int> shapedCodes = [];

    for (int i = 0; i < codes.length; i++) {
      int current = codes[i];
      if (!_forms.containsKey(current)) {
        shapedCodes.add(current);
        continue;
      }

      bool hasRightConn = i > 0 && _connectsToLeft(codes[i - 1]) && _connectsToRight(current);
      bool hasLeftConn = i < codes.length - 1 && _connectsToLeft(current) && _connectsToRight(codes[i + 1]);

      int formIndex;
      if (hasRightConn && hasLeftConn) formIndex = 3; // میانی
      else if (hasRightConn) formIndex = 1; // پایانی
      else if (hasLeftConn) formIndex = 2; // آغازی
      else formIndex = 0; // تنها

      shapedCodes.add(_forms[current]![formIndex]);
    }

    List<int> reversed = shapedCodes.reversed.toList();
    
    // اصلاح پرانتزها
    for (int i = 0; i < reversed.length; i++) {
      if (reversed[i] == 0x28) reversed[i] = 0x29;
      else if (reversed[i] == 0x29) reversed[i] = 0x28;
    }

    // اصلاح بخش‌های LTR (اعداد و انگلیسی)
    int j = 0;
    while (j < reversed.length) {
      if (_isLTR(reversed[j])) {
        int start = j;
        while (j < reversed.length && (_isLTR(reversed[j]) || _isLTRPunct(reversed[j], reversed, j))) {
          j++;
        }
        _reverseRange(reversed, start, j - 1);
      } else {
        j++;
      }
    }

    return String.fromCharCodes(reversed);
  }

  static bool _isLTR(int code) {
    return (code >= 0x30 && code <= 0x39) || (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A) || (code >= 0x06F0 && code <= 0x06F9);
  }

  static bool _isLTRPunct(int code, List<int> list, int index) {
    if ([0x2E, 0x2C, 0x2F, 0x2D, 0x3A].contains(code)) {
      if (index + 1 < list.length && _isLTR(list[index + 1])) return true;
    }
    return false;
  }

  static void _reverseRange(List<int> list, int start, int end) {
    while (start < end) {
      int temp = list[start];
      list[start] = list[end];
      list[end] = temp;
      start++;
      end--;
    }
  }
}
