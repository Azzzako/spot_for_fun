import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    super.key,
    this.size = 120,
    this.height,
  });

  final double size;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/identity/logo.png',
      width: size,
      height: height ?? size,
      fit: BoxFit.contain,
    );
  }
}