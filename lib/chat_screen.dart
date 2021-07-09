import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cometmessenger/statics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/bubble_type.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_1.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_2.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_3.dart';
import 'package:flutter_chat_bubble/clippers/chat_bubble_clipper_4.dart';

class ChatScreen extends StatefulWidget {
  final DocumentReference docRef;
  const ChatScreen({Key? key, required this.docRef}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  TextEditingController controller = TextEditingController();
  bool sendEnabled = false;

  @override
  void initState() {
    controller.addListener(() {
      // this isn't very clear, sorry
      // check create_chats_page.dart for an easy-to-understand explanation of what this code does
      if(sendEnabled != (controller.text != '')) {
        setState(() {
          sendEnabled = controller.text != '';
        });
      }
      // todo add typing feature
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: widget.docRef.snapshots(),
      builder: (context, chatSnapshot) {
        if(!chatSnapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: Text('Loading...'),),
          );
        }
        if(chatSnapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text('Error:...'),),
          );
        }
        return Scaffold(
          appBar: AppBar(
            title: FutureBuilder<String>(
              future: getChatName(chatSnapshot.data!),
              builder: (context, snapshot) {
                debugPrint('data: ${chatSnapshot.data}');
                debugPrint('${snapshot.error}');
                if(snapshot.hasError) return Text('Error');
                if(!snapshot.hasData) return Text('Loading...');
                return Text(snapshot.data!);
              }
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('messages').where('to_chat', isEqualTo: widget.docRef).orderBy('sent').snapshots(),
            builder: (ctx, messagesSnapshot) {
              if(messagesSnapshot.hasError) {
                debugPrint('Error: ${messagesSnapshot.error}');
                return Center(child: Text('Error'));
              }
              if(messagesSnapshot.connectionState == ConnectionState.waiting && !messagesSnapshot.hasData) {
                return Center(child: Text('Loading...'));
              }

              return Padding(
                padding: const EdgeInsets.fromLTRB(2,0,2,52),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: messagesSnapshot.data!.docs.length,
                    itemBuilder: (ctx, index) {
                      bool isSender = messagesSnapshot.data!.docs[index].get('from').contains(Statics.currentUserPhone);
                      return ChatBubble(
                        clipper: ChatBubbleClipper4(type: isSender ? BubbleType.sendBubble : BubbleType.receiverBubble),
                        backGroundColor: isSender ? Colors.indigo : Color(0xffE7E7ED),
                        alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                        margin: EdgeInsets.only(top: 2),
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.7,
                          ),
                          child: SelectableText(
                            messagesSnapshot.data!.docs[index].get('content'),
                            style: TextStyle(color: isSender ? Colors.white : Colors.black, fontSize: 16),
                          )
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          bottomSheet: SizedBox(
            height: 52,
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Your message...',
                        contentPadding: EdgeInsets.fromLTRB(12, 0, 0, 0)
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Colors.indigo,
                  iconSize: 24,
                  onPressed: !sendEnabled ? null : () async {
                    try {
                      final msgRef = await FirebaseFirestore.instance.collection('messages').add({
                        'from' : Statics.currentUserPhone,
                        'content' : controller.text,
                        'sent' : FieldValue.serverTimestamp(),
                        'text' : true,
                        'to_chat' : widget.docRef,
                        'reactions' : []
                      });
                      widget.docRef.update({
                        'last_message' : msgRef,
                      });
                      controller.text = '';
                    } on Exception catch(e) {
                      debugPrint(e.toString());
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating chat')));
                    }
                  },
                )
              ],
            ),
          ),
        );
      }
    );
  }

  Future<String> getChatName(DocumentSnapshot chatSnapshot) async {
    try {
      debugPrint('1');
      // todo this doesnt work
      // if(chatSnapshot.get('name')! != null) return chatSnapshot.get('name');
    } on Exception catch(e) {
      debugPrint(e.toString());
    }
    debugPrint('3');
    if(chatSnapshot.get('members_references').length == 2) {
      debugPrint('4');
      int index = chatSnapshot.get('members_references')[0] == FirebaseFirestore.instance.collection('users').doc('${Statics.currentUserPhone}') ? 1 : 0;
      return (await chatSnapshot.get('members_references')[index].get()).get('name');
    }
    debugPrint('5');
    return 'Group chat';

  }
}
