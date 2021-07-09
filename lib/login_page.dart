import 'package:cometmessenger/chats_list.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class LoginScreen extends StatelessWidget {

  final TextEditingController controller = TextEditingController();
  PhoneNumber? phone;
  String? userPhone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
                alignment: Alignment.center,
                child: Text('comet', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white), textScaleFactor: 2)
            ),
            Center(child: Text('modern messaging', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white), textScaleFactor: 1.25)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Theme(
                data: ThemeData(
                    cursorColor: Colors.white
                ),
                child: IntlPhoneField(

                  onChanged: (PhoneNumber p){
                    this.phone = p;
                  },
                  initialCountryCode: 'US',
                  countryCodeTextColor: Colors.white70,
                  dropDownArrowColor: Colors.white70,
                  controller: controller,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    fillColor: Colors.white,
                    focusColor: Colors.white,
                    hoverColor: Colors.white,
                    counterText: '',
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)
                    ),
                    focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white)
                    ),
                    hintText: 'Phone Number',
                    hintStyle: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
            FloatingActionButton(
              child: Icon(Icons.navigate_next, color: Colors.indigo),
              backgroundColor: Colors.white,
              onPressed: () async {
                if(phone == null) return;
                await FirebaseAuth.instance.verifyPhoneNumber(
                  phoneNumber: phone!.completeNumber,
                  verificationCompleted: (PhoneAuthCredential credential) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatsList()));
                  },
                  verificationFailed: (FirebaseAuthException e) {
                    if (e.code == 'invalid-phone-number') {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Invalid phone number}")));
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: ${e.message}")));
                  },
                  codeSent: (String? verificationId, int? resendToken) async {
                    final result = await Navigator.push(
                      context,
                      // Create the SelectionScreen in the next step.
                      MaterialPageRoute(builder: (context) => CodeInputScreen(verificationId!)),
                    );
                  },
                  codeAutoRetrievalTimeout: (String verificationId) {},
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class CodeInputScreen extends StatelessWidget {

  String code = '';
  late String verificationId;

  CodeInputScreen(this.verificationId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        elevation: 0,
      ),
      backgroundColor: Colors.indigo,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Align(
                alignment: Alignment.center,
                child: Text('comet', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white), textScaleFactor: 2)
            ),
            Center(child: Text('modern messaging', style: TextStyle(fontWeight: FontWeight.normal, color: Colors.white), textScaleFactor: 1.25)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              child: Theme(
                data: ThemeData(
                    cursorColor: Colors.white
                ),
                child: PinCodeTextField(
                  appContext: context,
                  onChanged: (c) {
                    this.code = c;
                  },
                  keyboardType: TextInputType.number,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.underline,
                    activeColor: Colors.white,
                    activeFillColor: Colors.indigo,
                    inactiveColor: Colors.white,
                    inactiveFillColor: Colors.indigo,
                    selectedColor: Colors.indigo,
                    selectedFillColor: Colors.indigo
                  ),
                  backgroundColor: Colors.indigo,
                  cursorColor: Colors.white,
                  textStyle: TextStyle(color: Colors.white),
                  length: 6,
                  enableActiveFill: true,
                  autoFocus: true,
                )
              ),
            ),
            FloatingActionButton(
              child: Icon(Icons.navigate_next, color: Colors.indigo),
              backgroundColor: Colors.white,
              onPressed: () async {
                PhoneAuthCredential authCredential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: this.code);
                UserCredential credential = await FirebaseAuth.instance.signInWithCredential(authCredential);
                debugPrint('success!');
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => ChatsList()));
              },
            )
          ],
        ),
      ),
    );
  }
}