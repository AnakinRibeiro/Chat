import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TextComposer extends StatefulWidget {
  // Recebe o texto enviado por parametro
  TextComposer(this.sendMessage);

  // Função para enviar mensagem parao banco
  final Function({String text, File imgFile}) sendMessage;

  @override
  _TextComposerState createState() => _TextComposerState();
}

class _TextComposerState extends State<TextComposer> {
  final TextEditingController _controller = TextEditingController();

  bool _isComposing = false;

  // Função para resetar o campo e transformar a seta em cinca
  void _reset() {
    _controller.clear();
    setState(() {
      _isComposing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: <Widget>[
          IconButton(
            icon: Icon(Icons.photo_camera),
            onPressed: () async {
              // Usa a biblioteca ImagePicker para tirar um foto
              final File imgFile =
                  await ImagePicker.pickImage(source: ImageSource.camera);
              // Envia a mensagem se imgFile não for igual a nulo
              if (imgFile == null) return;
              widget.sendMessage(imgFile: imgFile);
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              decoration:
                  InputDecoration.collapsed(hintText: "Enviar uma Mensagem"),
              onChanged: (text) {
                setState(() {
                  // Se o texto não estiver vazio eu estou digitando
                  _isComposing = text.isNotEmpty;
                });
              },
              onSubmitted: (text) {
                // Coloca no onSubmit e envia o texto recebido
                widget.sendMessage(text: text);
                // Reseta o campo e cor da seta
                _reset();
              },
            ),
          ),
          IconButton(
              icon: Icon(Icons.send),
              // Se estiver digitando ativa o botão
              onPressed: _isComposing
                  ? () {
                      // Envia o texto digitado pressionando o botão (arrow)
                      widget.sendMessage(text: _controller.text);
                      // Reseta o campo e cor da seta
                      _reset();
                    }
                  : null),
        ],
      ),
    );
  }
}
