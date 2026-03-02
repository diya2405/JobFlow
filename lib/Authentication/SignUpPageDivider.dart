import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';



class SignUpPageDivider extends StatelessWidget {
  SignUpPageDivider({
    super.key,
    required this.text
  });

  String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
            child: Divider(
              color: Colors.grey,
              thickness: 1.5,
              indent: 10,
              endIndent: 5,
            )),
        Text(
          text,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        Flexible(
            child: Divider(
              color: Colors.grey,
              thickness: 1.5,
              indent: 5,
              endIndent: 10,
            ))
      ],
    );
  }
}