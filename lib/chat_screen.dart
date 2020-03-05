import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:chat/chat_message.dart';
import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  FirebaseUser _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Monitora se o usuário é alterado no estado do Widget
    FirebaseAuth.instance.onAuthStateChanged.listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  // Função para logar o usuario pelo Google
  Future<FirebaseUser> _getUser() async {
    if (_currentUser != null) return _currentUser;
    try {
      final GoogleSignInAccount googleSignInAccount =
          await googleSignIn.signIn();

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.getCredential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);

      final AuthResult authResult =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final FirebaseUser user = authResult.user;
      return user;
    } catch (error) {
      return null;
    }
  }

  // Função para enviar a mensagem ou imagem
  void _sendMessage({String text, File imgFile}) async {
    final FirebaseUser user = await _getUser();

    if (user == null) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text("Não foi possível fazer o login. Tente novamente!"),
          backgroundColor: Colors.red));
    }

    // Mapa que ia receber a mensagem ou imagem a ser enviada
    Map<String, dynamic> data = {
      "uid": user.uid,
      "senderName": user.displayName,
      "senderPhotoUrl": user.photoUrl,
      "time": Timestamp.now()
    };

    // Envia a imagem para o Firebase, com a data atual como ID unico
    if (imgFile != null) {
      StorageUploadTask task = FirebaseStorage.instance
          .ref()
          .child(user.uid + DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(imgFile);

      setState(() {
        _isLoading = true;
      });

      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;
    }

    setState(() {
      _isLoading = false;
    });

    if (text != null) data['text'] = text;

    // Envia o mapa com a mensagem ou imagem para o Firebase
    Firestore.instance.collection("messages").add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_currentUser != null
            ? 'Olá, ${_currentUser.displayName}'
            : 'Chat App'),
        centerTitle: true,
        elevation: 0,
        actions: <Widget>[
          _currentUser != null
              ? IconButton(
                  icon: Icon(Icons.exit_to_app),
                  onPressed: () {
                    FirebaseAuth.instance.signOut();
                    googleSignIn.signOut();
                    _scaffoldKey.currentState.showSnackBar(SnackBar(
                      content: Text("Você saiu com sucesso!"),
                    ));
                  },
                )
              : Container()
        ],
      ),
      // Chama o TextComposer passando o texto digitado como parametro
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Sempre que houver uma alteração em messages no banco ele irá reconstruiu a lista
              stream: Firestore.instance
                  .collection('messages')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  // Casa não haja conexão ou esteja esperando
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return Center(
                      // irá retornar um circulo de espera
                      child: CircularProgressIndicator(),
                    );
                  default:
                    // Case de tudo certo irá montarr a lista "documents" contendo as mensagens
                    List<DocumentSnapshot> documents =
                        snapshot.data.documents.reversed.toList();

                    // Retorna a lista montada com as mensagens
                    return ListView.builder(
                        // quantidade de mensagens
                        itemCount: documents.length,
                        // mosta as mensagens de baixo para cima
                        reverse: true,
                        itemBuilder: (context, index) {
                          // Widget do chat
                          return ChatMessage(
                              documents[index].data,
                              documents[index].data['uid'] ==
                                  _currentUser?.uid);
                        });
                }
              },
            ),
          ),
          _isLoading ? LinearProgressIndicator() : Container(),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
