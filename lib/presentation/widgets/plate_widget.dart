import 'package:flutter/material.dart';
import 'package:persian_number_utility/persian_number_utility.dart';

class PlateWidget extends StatelessWidget {
  final String plate;
  final double scale;

  const PlateWidget({super.key, required this.plate, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    if (plate.isEmpty || plate == "---") {
      return const Text("بدون پلاک", style: TextStyle(color: Colors.grey, fontSize: 12));
    }

    // Attempt to parse: 2 digits + letter(s) + 3 digits + 2 digits
    // Format is stored as concatenated string.
    // Standard Iranian plate: 22 B 333 44
    
    String p1 = "";
    String letter = "";
    String p2 = "";
    String p3 = "";

    try {
      p1 = plate.substring(0, 2);
      // The letter can be 1-3 characters (e.g. "ب" or "الف")
      // After the letter there are 5 digits at the end (3 for p2, 2 for p3)
      int letterEnd = plate.length - 5;
      if (letterEnd > 2) {
        letter = plate.substring(2, letterEnd);
        p2 = plate.substring(letterEnd, letterEnd + 3);
        p3 = plate.substring(letterEnd + 3);
      }
    } catch (e) {
      return Text(plate, style: const TextStyle(fontWeight: FontWeight.bold));
    }

    return Transform.scale(
      scale: scale,
      child: Container(
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.black, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Left blue part
            Container(
              width: 12,
              height: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF063B96),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(3),
                  bottomLeft: Radius.circular(3),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 8,
                    height: 5,
                    child: Column(
                      children: [
                        Expanded(child: Container(color: Colors.green)),
                        Expanded(child: Container(color: Colors.white)),
                        Expanded(child: Container(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Text(p1.toPersianDigit(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
            const SizedBox(width: 4),
            Text(letter, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: Text(p2.toPersianDigit(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
            ),
            const VerticalDivider(width: 1, color: Colors.black, thickness: 1),
            Container(
              width: 30,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("ایران", style: TextStyle(fontSize: 6, fontWeight: FontWeight.bold, color: Colors.black)),
                  Text(p3.toPersianDigit(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black, height: 1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
