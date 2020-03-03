import 'package:chat/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Função para enviar a mensagem ou imagem
  void _sendMessage({String text, File imgFile}) async {
    // Mapa que ia receber a mensagem ou imagem a ser enviada
    Map<String, dynamic> data = {};

    // Envia a imagem para o Firebase, com a data atual como ID unico
    if (imgFile != null) {
      StorageUploadTask task = FirebaseStorage.instance
          .ref()
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .putFile(imgFile);

      StorageTaskSnapshot taskSnapshot = await task.onComplete;
      String url = await taskSnapshot.ref.getDownloadURL();
      data['imgUrl'] = url;
    }

    if (text != null) data['text'] = text;

    // Envia o mapa com a mensagem ou imagem para o Firebase
    Firestore.instance.collection("messages").add(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Olá"),
        elevation: 0,
      ),
      // Chama o TextComposer passando o texto digitado como parametro
      body: Column(
        children: <Widget>[
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Sempre que houver uma alteração em messages no banco ele irá reconstruiu a lista
              stream: Firestore.instance.collection('messages').snapshots(),
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
                        return ListTile(
                            title: Text(documents[index].data['text']));
                      },
                    );
                }
              },
            ),
          ),
          TextComposer(_sendMessage),
        ],
      ),
    );
  }
}
