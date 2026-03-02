import 'package:flutter/widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../Widgets/Input.dart';
import '../Widgets/ShowAlert.dart';


class Forgetpassword extends StatefulWidget {
  const Forgetpassword({super.key});

  @override
  State<Forgetpassword> createState() => _ForgetpasswordState();
}

class _ForgetpasswordState extends State<Forgetpassword> {
  final TextEditingController email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height :60),
              Text("Forget Password?" , style: TextStyle(fontSize: 30 , fontWeight: FontWeight.w300) ),
          
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
          
                  SizedBox(height: 20,),
          
                  Image.asset("assets/images/Forget_Password.png"),
          
                  SizedBox(height: 20,),
          
                  Text("Enter your email ID to reset it.", style: TextStyle(fontSize: 18 , fontWeight: FontWeight.w200),),
          
                  SizedBox(height: 20,),
          
                  Input(
                    controller: email,
                    hint: "Enter Your Email ID",
                    icon: const Icon(Icons.email),
                    input_type: TextInputType.emailAddress,
                  ),
          
                  SizedBox(height: 20,),
          
          
                ],
              ),
              ElevatedButton(
                onPressed: () async {
                  if (email.text.trim().isNotEmpty) {
                    try {
                      await FirebaseAuth.instance.sendPasswordResetEmail(
                        email: email.text.trim(),
                      );
                      // Display success message or navigate to another page
                      ShowAlert.showAlertDialog(
                        context,
                        "Password reset email sent. Check your inbox.",
                      );
                    } catch (e) {
                      // Handle errors
                      ShowAlert.showAlertDialog(
                        context,
                        "Error: ${e.toString()}",
                      );
                    }
                  } else {
                    // Show alert if the email field is empty
                    ShowAlert.showAlertDialog(
                      context,
                      "Please enter your email ID.",
                    );
                  }
                },
                child: const Text("Reset Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
