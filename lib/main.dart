import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

void main() async{
  //アプリ実行前にFlutterアプリの機能を利用する場合に宣言
  WidgetsFlutterBinding.ensureInitialized();
  //Firebaseのパッケージを呼び出し
  /*
  await ・・・非同期処理が完了するまで待ち、その非同期処理の結果を取り出してくれる
  awaitを付与したら asyncも付与する
   */
  await Firebase.initializeApp();
  runApp(MyApp());
}
/*
Stateless ・・・状態を保持する（動的に変化しない）
Stateful  ・・・状態を保持しない（変化する）
overrride ・・・上書き

*/

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // アイコンやタスクバーの時の表示
      title: 'Baby Names',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  //createState()でState（Stateを継承したクラス）を返す
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}
//Stateをextendsしたクラスを作る
class _MyHomePageState extends State<MyHomePage> {
  //ドキュメント情報を入れる箱を用意
  List<DocumentSnapshot> documentList = [];
  // List<String> name = [];
  // List<int> votes = [];

  @override
  Widget build(BuildContext context) {
    //デザインWidget
    return Scaffold(
      appBar: AppBar(title: Text('Baby Name Votes')),
      //非同期処理でWigetを生成
      body: FutureBuilder(
        //initialize ・・・初期化
        future: initialize(),
        builder: (context, snapshot) {
          // // 通信中はスピナーを表示
          // if (snapshot.connectionState != ConnectionState.done) {
          //   return CircularProgressIndicator();
          // }
          // // エラー発生時はエラーメッセージを表示
          // if (snapshot.hasError) {
          //   return Text(snapshot.error.toString());
          // }

          // // データがnullでないかチェック
          // if (!snapshot.hasData) {
          //   return Text("データが存在しません");
          // }

          return Column(
            /*
             map ・・・要素それぞれに対して、渡した関数の処理を加えて新しく繰り返し処理する
             データを取得（名前と数）してテキストとしてColumnに書き出す
            */
            children: documentList.map((data) => Text(data.get('name') + ' : ' + data.get('votes').toString())).toList(),
          );
        },
      ),
    );
  }
  Future<void> initialize() async {
    //指定コレクション（baby）のドキュメント一覧を取得
    final snapshot =
    await FirebaseFirestore.instance.collection('baby').get();
    //取得したドキュメント一覧を画面に反映
    documentList = snapshot.docs;

    print("##################################################### initialize()");
    /*
     forEach ・・・要素を一個ずつ順に取り出し処理する（繰り返し）
     ログに取得結果を表示
     */
    documentList.forEach((elem) {
      print(elem.get('name'));
      print(elem.get('votes'));
    });
    print("##################################################### initialize()");
  }
}