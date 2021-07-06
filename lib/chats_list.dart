import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cometmessenger/login_page.dart';
import 'package:cometmessenger/statics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatsList extends StatefulWidget {

  @override
  _ChatsListState createState() => _ChatsListState();
}

class _ChatsListState extends State<ChatsList> {

  bool loggedIn = false;

  @override
  void initState() {
    super.initState();
        () async {
      await Firebase.initializeApp();
      FirebaseAuth auth = FirebaseAuth.instance;
      auth.authStateChanges()
          .listen((User? user) {
        if (user == null) {
          // user isn't logged in
          Get.to(LoginScreen());
        }  else {
          // user is logged in
          Statics.currentUserPhone = user.phoneNumber;
          setState(() {
            loggedIn = true;
          });
        }
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    if(!loggedIn) return Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('comet'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.add),
      ),
      body: FutureBuilder<bool>(
        future: checkAccount(),
        builder: (context, snapshot) {
          if(snapshot.hasData) {
            // if ur reviewing this code, yes i am aware i can omit the '== true'
            // i have not for clarity purposes
            // because snapshot.data is often not just a boolean
            if(snapshot.data == true) {
              return StreamBuilder<QuerySnapshot>(
                // todo make it only have the chats from the users phone
                stream: FirebaseFirestore.instance.collection('chats').where('members', arrayContains: Statics.currentUserPhone).snapshots(),
                builder: (context, snapshot) {
                  if(snapshot.hasError) {
                    debugPrint('Error: ${snapshot.error}');
                    return Center(child: Text('Error'));
                  }
                  if(snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData)
                    return Center(child: Text('Loading...'));
                  if(snapshot.data!.docs.length == 0) {
                    return Center(child: Text('You don\'t have any conversations.\nTap the plus button to start a new one.',
                      textAlign: TextAlign.center,));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (ctx, index) {
                      return ListTile(
                        onTap: () {},
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox(
                          width: 96,
                          height: 96,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            // that's for group chats
                            // child: Image.network(snapshot.data!.docs[index]['img_url']),
                          )
                        ),
                        // you have to get the reference separately
                        // todo make sure it doesn't get the current users id
                        // by checking to see which phone of the members array
                        // isn't the users phone number
                        // and group chats will have a name field
                        // so check if theres more than two members to know if it's a group chat
                        title: FutureBuilder<DocumentSnapshot>(
                          future: snapshot.data!.docs[index]['members_references'][0].get(),
                          builder: (context, doc) {
                            return Text(doc.data!['name']);
                          }
                        ),
                      );
                    }
                  );
                },
              );
            } else {
              return Center(child: Text('error :('));
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        }
      ),
    );
  }

  // returns true for success
  Future<bool> checkAccount() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    final account = (await firestore.collection('/users').doc('/${Statics.currentUserPhone}').get());
    if(account.exists) {
      return true;
    } else {
      return createAccount();
    }
  }

  Future<bool> createAccount() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    await firestore.collection('/users').doc('/${Statics.currentUserPhone}').set({
      "img_url": 'https://img.icons8.com/pastel-glyph/2x/person-male.png',
      "name" : 'Comet User'
    });
    return true;
  }
}
