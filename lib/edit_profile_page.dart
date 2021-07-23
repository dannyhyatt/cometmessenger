import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cometmessenger/statics.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({Key? key}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {

  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    () async {
      controller.text = (await FirebaseFirestore.instance.doc('users/${Statics.currentUserPhone}').get()).get('name');
    } ();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('edit profile'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Your display name...',
                  labelText: 'Set name:'
                ),
                controller: controller
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(0, 64, 0, 0),
                child: MaterialButton(
                  padding: const EdgeInsets.all(16),
                  onPressed: () {
                    FirebaseFirestore.instance.doc('users/${Statics.currentUserPhone}').update(
                        {'name' : controller.text == '' ? 'comet user' : controller.text}).then((value) => Navigator.of(context).pop());
                  },
                  color: Colors.indigo,
                  child: Text('set name', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
