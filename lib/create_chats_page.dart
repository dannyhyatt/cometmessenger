import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cometmessenger/statics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';

class CreateChatPage extends StatefulWidget {
  const CreateChatPage({Key? key}) : super(key: key);

  @override
  _CreateChatPageState createState() => _CreateChatPageState();
}

class _CreateChatPageState extends State<CreateChatPage> {

  String phoneNumber = '';
  TextEditingController controller = TextEditingController();

  List<String> numbers = [];
  List<String> names = [];
  List<Contact> contacts = [];

  bool loading = false;

  @override
  void initState() {
    super.initState();

    if(!kIsWeb) {
      FlutterContacts.requestPermission().then((hasPermission) {
        if (hasPermission) {
          FlutterContacts.getContacts().then((value) => contacts = value);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('names: ${names.length}, ${names.length > 0}');
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('create a chat'),
        bottom: PreferredSize(
          preferredSize: Size(
            0, 64
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Phone number or contact name',
                border: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
                hintStyle: TextStyle(color: Colors.white, letterSpacing: 1),
                focusColor: Colors.white
              ),
              style: TextStyle(color: Colors.white, letterSpacing: 2),
              cursorColor: Colors.white,
              autofocus: true,
              controller: controller,
              onSubmitted: (text) {
                setState(() {
                  phoneNumber = text;
                });
              },
            ),
          ),
        ),
      ),
      body: ListView.builder(
        key: GlobalKey(),
        itemCount: phoneNumber == '' ? 0 : contacts.length + 1,
        itemBuilder: (ctx, index) {
          index -= 1;
          if(index == -1) {
            return PhoneNumberListTile(
              phoneNumber: phoneNumber,
              key: GlobalKey(),
              callback: (name, number) {
                if(numbers.contains(number)) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This number is already added to the chat')));
                  return;
                }

                setState(() {
                  numbers.add(number);
                  names.add(name);
                  controller.text = '';
                });

              },
            );
          }
          return Container(
            height: 20,
            color: Colors.transparent,
            width: 20,
          );
        },
      ),
      bottomSheet: names.length == 0 ? Container(height: 0, width: 0,) : SizedBox(
        height: 64,
        child: Stack(
          children: [
            ListView.builder(
              itemCount: numbers.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (ctx, index) {
                return Container(
                  margin: EdgeInsets.all(8),
                  decoration: ShapeDecoration(
                    shape: StadiumBorder(side: BorderSide(color: Colors.indigo, width: 2))
                  ),
                  child: Chip(
                    backgroundColor: Colors.white,
                    deleteIcon: Icon(Icons.close, color: Colors.black, size: 20),
                    onDeleted: (){
                      setState(() {
                        numbers.removeAt(index);
                        names.removeAt(index);
                      });
                    },
                    labelPadding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                    padding: EdgeInsets.zero,
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(names[index], textScaleFactor: 1.2, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(numbers[index], textScaleFactor: 0.9,)
                      ],
                    ),
                  ),
                );
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                height: 64,
                width: 64,
                child: IconButton(
                    icon: Icon(Icons.check, color: Colors.indigo,),
                    color: Colors.indigo,
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewChatPage(names: names, numbers: numbers)));
                    }
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void addNumber(PhoneNumber phone) {
  }
}

class PhoneNumberListTile extends StatefulWidget {
  final String phoneNumber;
  final void Function(String, String) callback;
  const PhoneNumberListTile({Key? key, required this.phoneNumber, required this.callback}) : super(key: key);

  @override
  _PhoneNumberListTileState createState() => _PhoneNumberListTileState();
}

class _PhoneNumberListTileState extends State<PhoneNumberListTile> {

  CrossFadeState currentCrossFadeState = CrossFadeState.showFirst;
  // show nothing until the widget is loaded
  Widget loadedWidget = Container();
  String tapMessage = 'Checking to see if this number is registered on Comet...';
  String name = ''; // sets to name

  @override
  void initState() {
    super.initState();
    checkIfValid();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: ListTile(
        onTap: () {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tapMessage)));
        },
        // leading: SizedBox(
        //     width: 64,
        //     height: 64,
        //     child: Padding(
        //       padding: EdgeInsets.all(4),
        //       // prob should upload this to the site
        //       child: Image.network('https://img.icons8.com/pastel-glyph/2x/person-male.png'),
        //     )
        // ),
        title: Text(widget.phoneNumber, style: TextStyle(color: Colors.black38),),
      ),
      secondChild: loadedWidget,
      crossFadeState: currentCrossFadeState,
      duration: Duration(milliseconds: 250));
  }

  void checkIfValid() async {
    debugPrint('checking if valid: ${formatPhoneNumber(widget.phoneNumber)}');
    final doc = await FirebaseFirestore.instance.collection('users').doc('/${formatPhoneNumber(widget.phoneNumber)}').get();
    debugPrint('path: ${doc.reference.path}');
    if(!doc.exists) {
      setState(() {
        tapMessage = 'This phone number does not have a Comet account';
      });
      debugPrint('no account for number');
      return;
    }
    debugPrint('found account for this number');
    setState(() {
      loadedWidget = ListTile(
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 0, 0),
        onTap: () {
          debugPrint('tapped');
          widget.callback(doc.get('name'), formatPhoneNumber(widget.phoneNumber));
        },
        // leading: SizedBox(
        //     width: 64,
        //     height: 64,
        //     child: Padding(
        //       padding: EdgeInsets.all(4),
        //       // prob should upload this to the site
        //       child: Image.network('https://img.icons8.com/pastel-glyph/2x/person-male.png'),
        //     )
        // ),
        title: Text(doc.get('name'), style: TextStyle(color: Colors.indigo),),
        subtitle: Text(formatPhoneNumber(widget.phoneNumber)),
      );
      currentCrossFadeState = CrossFadeState.showSecond;
    });
  }

  String formatPhoneNumber(String rawNumber) {
    if(!(rawNumber.startsWith('+') || rawNumber.length < 10)) {
      rawNumber = '+1' + rawNumber;
    }
    return rawNumber.replaceAll(' ', '');
  }
}

class NewChatPage extends StatefulWidget {
  final List<String> names;
  final List<String> numbers;
  const NewChatPage({Key? key, required this.names, required this.numbers}) : super(key: key);

  @override
  _NewChatPageState createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {

  TextEditingController controller = TextEditingController();
  bool sendEnabled = false;

  @override
  void initState() {
    controller.addListener(() {
      // this isn't very clear, sorry
      // but figure it out urself you github stalker you
      if(sendEnabled != (controller.text != '')) {
        debugPrint('setting sendenabled');
        setState(() {
          sendEnabled = controller.text != '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.names}'.substring(1, '${widget.names}'.length-1)),
      ),
      bottomSheet: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Greeting...',
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.send),
              color: Colors.indigo,
              onPressed: !sendEnabled ? null : () async {
                try {
                  final chatRef = await FirebaseFirestore.instance.collection('chats').add({
                    'img_url': 'https://cdn.iconscout.com/icon/premium/png-256-thumb/group-chat-2027621-1708690.png',
                    'members': [
                      ...widget.numbers,
                      Statics.currentUserPhone
                    ],
                    'members_references': [
                      ...widget.numbers.map((e) => FirebaseFirestore.instance.doc('users/$e')),
                      FirebaseFirestore.instance.doc('users/${Statics.currentUserPhone}')
                    ],
                    'typing': []
                  });
                  final msgRef = await FirebaseFirestore.instance.collection('messages').add({
                    'from' : Statics.currentUserPhone,
                    'content' : controller.text,
                    'sent' : FieldValue.serverTimestamp(),
                    'text' : true,
                    'to_chat' : chatRef,
                    'reactions' : []
                  });
                  chatRef.update({
                    'last_message' : msgRef
                  });
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
}
