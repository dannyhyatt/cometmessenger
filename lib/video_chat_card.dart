import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cometmessenger/statics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

class VideoChatCard extends StatefulWidget {
  final DocumentReference chatDoc;
  final bool isCalling;
  const VideoChatCard({Key? key, required this.chatDoc, required this.isCalling}) : super(key: key);

  @override
  _VideoChatCardState createState() => _VideoChatCardState();
}

class _VideoChatCardState extends State<VideoChatCard> {
  
  String currentStuff = 'nothing so far...';
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  late MediaStream _localStream;
  bool _offer = false;
  RTCPeerConnection? _peerConnection;

  @override
  dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initAll();
  }

  initAll() async {
    if(widget.isCalling) {
      _offer = true;
      debugPrint('calling 1');
      await initRenderers();
      debugPrint('calling 2');
      await _getUserMedia();
      debugPrint('calling 3');
      _peerConnection = await _createPeerConnecion();
      debugPrint('calling 4');
      await _createOffer();
      debugPrint('calling 5');
      await _addCandidate();
      debugPrint('calling 6');
      Stream s = widget.chatDoc.snapshots();
      debugPrint('calling 7');
      s.listen((event) {
        widget.chatDoc.get().then((snapshot) async {
          debugPrint('calling 8');
          try {
            String callAnswer = snapshot.get('call_answer');
            RTCSessionDescription description =
            new RTCSessionDescription(callAnswer, _offer ? 'answer' : 'offer');
            print(description.toMap());

            await _peerConnection!.setRemoteDescription(description);
          } catch(_) {}
        });
      });
    } else {
      debugPrint('not calling 1');
      await initRenderers();
      debugPrint('not calling 2');
      await _getUserMedia();
      debugPrint('not calling 3');
      _peerConnection = await _createPeerConnecion();
      debugPrint('not calling 4');
      await _createAnswer();
      debugPrint('not calling 5');
      await _setRemoteDescription();
      debugPrint('not calling 6');
    }
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }


  _createPeerConnecion() async {
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      "mandatory": {
        "OfferToReceiveAudio": true,
        "OfferToReceiveVideo": true,
      },
      "optional": [],
    };

    _localStream = await _getUserMedia();

    RTCPeerConnection pc =
    await createPeerConnection(configuration, offerSdpConstraints);

    pc.addStream(_localStream);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMlineIndex,
        }));
      }
    };

    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      _remoteRenderer.srcObject = stream;
    };

    return pc;
  }

  _getUserMedia() async {
    final Map<String, dynamic> constraints = {
      'audio': false,
      'video': {
        'facingMode': 'user',
      },
    };

    MediaStream stream = await navigator.mediaDevices.getUserMedia(constraints);

    _localRenderer.srcObject = stream;
    // _localRenderer.mirror = true;

    return stream;
  }

  Future<void> _createOffer() async {
    RTCSessionDescription description = await _peerConnection!.createOffer({'offerToReceiveVideo': 1});
    var sdpOffer = (description.sdp.toString());
    // thats da sdp offerrrrr
    // this is what needs to be transmitted
    await widget.chatDoc.update({
      'call_offer' : sdpOffer
    });
    _offer = true;

    _peerConnection!.setLocalDescription(description);
  }

  // accepts the offer metadata or soemthing i think
  Future<void> _createAnswer() async {
    RTCSessionDescription description =
    await _peerConnection!.createAnswer({'offerToReceiveVideo': 1});

    var session = parse(description.sdp.toString());
    print(json.encode(session));
    // print(json.encode({
    //       'sdp': description.sdp.toString(),
    //       'type': description.type.toString(),
    //     }));
    
    _peerConnection!.setLocalDescription(description);
    
    widget.chatDoc.update({
      'chat_answer' : session
    });
  }

  Future<void> _setRemoteDescription() async {
    // String jsonString = sdpController.text;
    // dynamic session = await jsonDecode('$jsonString');

    String sdp = (await widget.chatDoc.get()).get('call_offer');

    // String sdp = write(session, null);

    // RTCSessionDescription description =
    //     new RTCSessionDescription(session['sdp'], session['type']);

  }

  Future<void> _addCandidate() async {
    // String jsonString = sdpController.text;
    String jsonString = (await widget.chatDoc.get()).get('call_offer');
    dynamic session = parse('$jsonString');
    print(session['candidate']);
    dynamic candidate =
    new RTCIceCandidate(session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection!.addCandidate(candidate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Card(
        child: Center(child: RTCVideoView(_localRenderer, mirror: true,)),
      ),
    );
  }
}
