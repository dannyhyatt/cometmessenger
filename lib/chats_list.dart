import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cometmessenger/chat_screen.dart';
import 'package:cometmessenger/create_chats_page.dart';
import 'package:cometmessenger/login_page.dart';
import 'package:cometmessenger/statics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
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
      debugPrint('no');
      FirebaseAuth auth = FirebaseAuth.instance;
      // if(!kReleaseMode) {
      //   debugPrint("YES");
      //   // auth.useAuthEmulator("10.0.2.2", 9099);
      //   // FirebaseFirestore.instance.useFirestoreEmulator("10.0.2.2", 8080);
      // }
      auth.authStateChanges()
          .listen((User? user) {
        if (user == null) {
          // user isn't logged in
          debugPrint('user not logged in');
          Get.to(() => LoginScreen());
        }  else {
          // user is logged in
          debugPrint('user logged in');
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
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('comet'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => CreateChatPage());
        },
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
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatScreen(docRef: snapshot.data!.docs[index].reference)));
                        },
                        contentPadding: EdgeInsets.zero,
                        leading: SizedBox(
                          width: 96,
                          height: 96,
                          child: Padding(
                            padding: EdgeInsets.all(4),
                            // that's for group chats
                            child: Image.network(snapshot.data!.docs[index]['img_url']),
                          )
                        ),
                        // you have to get the reference separately
                        // todo make sure it doesn't get the current users id
                        // by checking to see which phone of the members array
                        // isn't the users phone number
                        // and group chats will have a name field
                        // so check if theres more than two members to know if it's a group chat
                        // todo fix the weird flash in the beginning
                        title: FutureBuilder<DocumentSnapshot>(
                          future: snapshot.data?.docs[index]['members_references'][0].get(),
                          builder: (context, doc) {
                            if(doc.hasError) return Text('Error');
                            if(!doc.hasData) return Text('Loading...');
                            debugPrint('text is: ${doc.data?.get('name')}');
                            return Text(doc.data!.get('name'));
                          },
                        ),
                        subtitle: FutureBuilder<DocumentSnapshot>(
                          future: snapshot.data?.docs[index]['last_message'].get(),
                          builder: (context, doc) {
                            if(doc.hasError) return Text('Error');
                            if(!doc.hasData) return Text('Loading...');
                            debugPrint('text is: ${doc.data?.get('content')}');
                            return Text(doc.data!.get('content'));
                          },
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
