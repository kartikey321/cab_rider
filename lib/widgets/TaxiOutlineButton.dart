// ignore_for_file: file_names, unnecessary_new, prefer_const_constructors

import 'package:cab_rider/brand_colors.dart';
import 'package:flutter/material.dart';

class TaxiOutlineButton extends StatelessWidget {
  final String? title;
  final void Function()? onPressed;
  final Color? color;

  TaxiOutlineButton({this.title, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color!),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25.0),
          ),
          backgroundColor: color,
          foregroundColor: color, // Text color
        ),
        child: Container(
          height: 50.0,
          child: Center(
            child: Text(title!,
                style: TextStyle(
                    fontSize: 15.0,
                    fontFamily: 'Brand-Bold',
                    color: BrandColors.colorText)),
          ),
        ));
  }
}
