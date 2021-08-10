// ignore_for_file: file_names

import 'dart:core';

import 'package:flutter/material.dart';

class TaxiButton extends StatelessWidget {
  TaxiButton({this.title, this.onPressed, this.color});
  final String? title;
  final void Function()? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed,
      color: color,
      textColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      child: Container(
        height: 50,
        child: Center(
          child: Text(
            title!,
            style: TextStyle(fontSize: 18, fontFamily: 'Brand-Bold'),
          ),
        ),
      ),
    );
  }
}
