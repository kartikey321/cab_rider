import 'package:flutter/material.dart';

class BrandDivider extends StatelessWidget {
  const BrandDivider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1.0,
      color: Color(0xFFE2E2E2),
      thickness: 1.0,
    );
  }
}
