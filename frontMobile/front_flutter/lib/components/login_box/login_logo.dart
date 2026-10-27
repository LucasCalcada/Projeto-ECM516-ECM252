import 'package:flutter/material.dart';

class LoginLogo extends StatelessWidget {
  const LoginLogo({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'HiveApp',
    image: true,
    child: const ExcludeSemantics(
      child: Icon(
        Icons.apartment_outlined,
        size: 128,
        color: Color(0xFFD4D4D4),
      ),
    ),
  );
}
