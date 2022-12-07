/*
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:uuid/uuid.dart';
*/

 // クラス名、メソッド名、プロパティ名（変数名）について、筆者が作成したもの（名前変更可のもの）
 // の名前の末尾には、大文字のオー「O」をつけています
 // ※ライブラリ（パッケージ）で予め決められているもの（名前の変更不可のもの）と、
 //  自分で作成したもの（名前の変更可のもの）の区別をしやすくするため
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:google_sign_in/google_sign_in.dart' as signInO;
import 'package:googleapis/calendar/v3.dart' as calendarO;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:uuid/uuid.dart';
// // firebase上にサインインしたユーザー情報を記録する場合は以下をインポート ※pubspec.yamlに追記が必要
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// void main() => runApp(MyApp());
// // firebase上にサインインのユーザー情報を記録する場合は、
// // firebaseの初期化処理が必要になるため、上の1文を下記に書き換える
// // ※firebase_coreのインポートが必要
Future<void> main() async{

  // main関数内で非同期処理をするときはこれが必要
  WidgetsFlutterBinding.ensureInitialized();

  // Firebaseの初期化処理
  await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Google Calendar Test",
      theme: ThemeData.light(),
      home: SampleScreenO(),
    );
  }
}
class SampleScreenO extends StatefulWidget {
  @override
  _SampleScreenOState createState() => _SampleScreenOState();
}
class _SampleScreenOState extends State<SampleScreenO> {
// 以下のプロパティは、メソッド間で共有したいのでクラスのトップで定義
// Google SignIn認証のためのインスタンス
// ※google_sign_inパッケージのインポート文に、as signInOを付けているので、
//  google_sign_inのクラスには「signInO.」を付けて表記
  late signInO.GoogleSignIn googleSignInO;
// GoogleSignInAccount?（ユーザー情報を保持するクラス）のインスタンス
// サインインをキャンセルしたときはnullになりうるので、null許容「?」で定義する
  signInO.GoogleSignInAccount? accountO;
// Google認証情報を入れるプロパティ
// 本来はAuthClient型で宣言するプロパティだが、AuthClientを明示すると、googleapis_authパッケージの
// インポートが必要になるので、varで宣言してインポートを回避する
// ※googleapis_authパッケージは、extension_google_sign_in_as_googleapis_authパッケージ内で
//  インポート済のため、本コード内でインポートしなくても動作する
  late var httpClientO;
// Google Calendar APIのインスタンス
// ※googleapisパッケージのインポート文に、as calendarO を付けているので、
//  googleapisのクラスには「calendarO.」を付けて表記
  late calendarO.CalendarApi googleCalendarApiO;
// Google SignInの状態を示す文字列 ※起動時は空文字
  String signInStatusO = "";
// Googleカレンダーに登録する予定ID ※初期値は空文字
  String registeredScheduleIdO = "";
// 予定のタイトル、予定のメモ、予定IDのそれぞれの入力欄（TextFormField）に
// 設置するコントローラー
  TextEditingController titleControllerO = TextEditingController();
  TextEditingController memoControllerO = TextEditingController();
  TextEditingController scheduleIdControllerO = TextEditingController();
// スクロールバーを常時表示するために必要なコントローラー
  ScrollController scrollControllerO = ScrollController();
// 予定日時を入れるプロパティ
  late DateTime registeredDateO;
// リマインダーを発動するタイミングを表す値（予定日時からどれだけ前に通知するか）
  late int reminderTimingO;
// リマインダーを発動するタイミングを表す単位（分前、時間前、日前、週間前を設定可能）
  late String reminderUnitO;
// リマインダーの方法を表すプロパティ
// ここでは、プッシュ通知にするため"popup"とする
// ※メール通知にしたい場合は、"email"に変更する
  String reminderMethodO = "popup";
  @override
  void initState() {
// 予定のタイトル・メモの初期値は空文字を設定
    titleControllerO.text = "";
    memoControllerO.text = "";
// 本サンプルコードでは、簡略化のため、
// Googleカレンダーに登録する予定日時を、現在時刻から5日後とする
    registeredDateO = DateTime.now().add(Duration(days: 5));
// 本サンプルコードでは、簡略化のため、
// リマインダーの発動タイミングを、予定日時の1日前とする
    reminderTimingO = 1;
    reminderUnitO = "日前";
    super.initState();
  }
  @override
  void dispose() {
// 画面遷移を実装した場合は、各コントローラーの破棄が必要なため設定
    titleControllerO.dispose();
    memoControllerO.dispose();
    scheduleIdControllerO.dispose();
    scrollControllerO.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text("Google Calendar 登録・読込テスト"),
        ),
      ),
      body: Scrollbar(
// スクロールバーを常時表示させる
        isAlwaysShown: true,
// スクロールバー常時表示のため、SingleChildScrollViewと同じ
// コントローラーの設置が必要
        controller: scrollControllerO,
// 画面内に表示しきれない時の描画範囲エラーを回避するため、
// SingleChildScrollViewでラップ
        child: SingleChildScrollView(
// スクロールバー常時表示のため、Scrollbarと同じ
// コントローラーの設置が必要
          controller: scrollControllerO,
          child: Center(
            child: Column(
              children: <Widget>[
                SizedBox(
                  height: 15,
                ),
                /// 予定のタイトルを入力するフォーム
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: TextFormField(
// 予定タイトルの入力結果を保持するコントローラーを設置
                    controller: titleControllerO,
                    decoration: InputDecoration(
                        hintText: "予定のタイトルを入力"
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                /// 予定のメモを入力するフォーム
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: TextFormField(
// 予定メモの入力結果を保持するコントローラーを設置
                    controller: memoControllerO,
                    decoration: InputDecoration(
                        hintText: "予定のメモを入力"
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                /// ①③でGoogleカレンダーに登録する日時とリマインダーのタイミングを表示
                Text(
                  "登録日時（現在から5日後）: ${registeredDateO.toString().substring(0,16)}",
                ),
                SizedBox(
                  height: 15,
                ),
                Text(
                    "リマインダー： 登録日時の $reminderTimingO $reminderUnitO"
                ),
                SizedBox(
                  height: 15,
                ),
                /// ①Googleカレンダーに予定を登録するボタン
                ElevatedButton(
// Googleカレンダーに登録するメソッドの呼び出し
                  onPressed: () => _registerInGoogleCalendarO(),
                  child: Text(
                    "①Googleカレンダーに予定を登録",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                /// ①で登録した予定IDを表示
// 次の予定ID入力欄にコピーペーストできるよう、SelectableTextで表示
                SelectableText(
                  "今登録した予定ID:\n$registeredScheduleIdO",
                ),
                SizedBox(
                  height: 15,
                ),
                /// ②③④の実行対象となる予定IDを入力する欄
                Container(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: TextFormField(
// 予定IDの入力結果を保持するコントローラーを設置
                    controller: scheduleIdControllerO,
                    decoration: InputDecoration(
                        hintText: "アクセスしたい予定IDを貼り付け"
                    ),
                    style: TextStyle(fontSize: 14.0),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                /// ②Googleカレンダーから予定情報を取得するボタン
                ElevatedButton(
// Googleカレンダーから予定情報を取得するメソッドの呼び出し
// 入力した予定IDを引数として渡す
                  onPressed: () => _getScheduleO(scheduleIdControllerO.text),
                  child: Text(
                    "②貼り付けたIDの予定情報を取得",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                /// ③Googleカレンダーに登録した予定を更新するボタン
                ElevatedButton(
// Googleカレンダーの予定を更新するメソッドの呼び出し
// 入力した予定IDを引数として渡す
                  onPressed: () => _updateScheduleO(scheduleIdControllerO.text),
                  child: Text(
                    "③貼り付けたIDの予定を更新",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                /// ④Googleカレンダーに登録した予定を削除するボタン
                ElevatedButton(
// Googleカレンダーの予定を削除するメソッドの呼び出し
// 入力した予定IDを引数として渡す
                  onPressed: () => _deleteScheduleO(scheduleIdControllerO.text),
                  child: Text(
                    "④貼り付けたIDの予定を削除",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                /// Googleアカウントからサインアウトするボタン
                ElevatedButton(
// サインアウトするメソッドの呼び出し
                  onPressed: () => _signOutFromGoogleO(),
                  child: Text(
                    "⑤サインアウト",
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                /// Googleアカウントへのサインイン状態を表示
                Text(signInStatusO),

                Container(
                  child: SfCalendar(
                    view:CalendarView.month,
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
  /// Google SignIn処理をするメソッド
  Future<bool> _googleSignInMethodO() async{
// Google SignIn認証のためのインスタンスを作成
    googleSignInO = signInO.GoogleSignIn(
        scopes: [
// Google APIで使用したいスコープを指定
// ※ここではGoogleカレンダーへのアクセス権を要求
          calendarO.CalendarApi.calendarScope,
        ]);
// サインイン画面や同意画面のポップアップをキャンセルした場合のエラーを回避するため、
// try catchを設定
// 但し、デバッグモードでは止まってしまうので、キャンセル時の挙動を確かめるには、
// Runモードで実行する必要あり
    try {
// isSignedInメソッドでサインイン済か否か確認
      final checkSignInResultO = await googleSignInO.isSignedIn();
      print("サインインしているか否か $checkSignInResultO");
// サインイン済の場合は、サインインのポップアップを出さずにサインイン処理する
// ※iOSの場合はsignInSilentlyにしないと、毎回サインインのポップアップが出てしまうため
      if (checkSignInResultO) {
        accountO = await googleSignInO.signInSilently();
// サインイン済にもかかわらず返り値がnullの場合、
// ユーザーがGoogleアカウントの設定画面で接続解除をした可能性があるので、
// disconnectメソッドで完全サインアウトし、認証情報を初期化する
        if (accountO == null) {
          print("認証情報を初期化する必要が生じたため、もう一度ボタンを押してください。");
          await googleSignInO.disconnect();
// 例外処理を投げて、下方のcatchに飛ばす
          throw Exception();
        }
      } else {
// サインインしていない場合は、ポップアップを出してサインイン処理
        accountO = await googleSignInO.signIn();
// 返り値がnullだったら、サインインもしくは同意処理がキャンセルされたと判断し、
// 例外処理を投げて、下方のcatchに飛ばす
        if (accountO == null) {
          print("キャンセル");
          throw Exception();
        }
      }
/// firebase上にサインインしたユーザー情報を記録する場合は以下を追加
// ※firebase_auth、firebase_coreのインポートが必要

signInO.GoogleSignInAuthentication authO =
await accountO!.authentication;

final OAuthCredential credentialO =
GoogleAuthProvider.credential(
  idToken: authO.idToken,
  accessToken: authO.accessToken,
);

// このユーザーデータ（userO）を必要に応じて使用する
User? userO =
    (await FirebaseAuth.instance.signInWithCredential(credentialO)).user;

// 使用する一例として、Firebase上で管理される「ユーザーUID」をログに表示
print("ユーザーUID: ${userO!.uid}");

// サインイン表示に変更し、再描画
      setState(() {
        signInStatusO = "サインイン中";
      });
// 返り値trueを返す
      return true;
    } catch (e) {
// サインアウト表示に変更し、再描画
      setState(() {
        signInStatusO = "サインアウト中";
      });
// 返り値falseを返す
      print("サインインできず $e");
      return false;
    }
  }
  /// ステップ① 予定の新規登録
  Future<void> _registerInGoogleCalendarO() async{
    /// Google SignInの処理
    final signInResultO = await _googleSignInMethodO();
    if (!signInResultO) {
// サインインできなかった場合は、早期リターン
      return;
    }
    /// Googleカレンダーのインスタンス作成
// Googleサインインで認証済のHTTPクライアントのインスタンスを作成
// extension_google_sign_in_as_googleapis_authパッケージのメソッドを使用
    try {
      httpClientO = (await googleSignInO.authenticatedClient())!;
// Androidの同意画面で、チェックせずに続行後、キャンセルした場合のエラー処理は、ここに含む
    } catch (eO) {
      print("権限付与エラー $eO");
// エラーの場合は、同意画面に再度チェックさせるため、一度完全サインアウトする
      await _signOutFromGoogleO();
// 早期リターン
      return;
    }
// Google Calendar APIのインスタンスを作成
    googleCalendarApiO = calendarO.CalendarApi(httpClientO);
// 予定を登録するカレンダーのIDを指定
// 本サンプルコードでは、全て「primary」
// （Googleカレンダー利用時に最初に作成されるカレンダー）を
// 指定することとする
// ※"primary"は、Googleアカウントのメールアドレス("...@gmail.com")にしても可能
    String calendarIdO = "primary";
// Googleアカウント内に複数のカレンダーを作成していて、primary以外のカレンダーに
// 登録したい場合は、下記のように「calendarList.list」メソッドを用いて
// 該当のカレンダーIDを取得しておく
// また、iOSの同意画面でチェックせず続行した場合は、このlistメソッドがエラーになるので、
// try catchでエラー処理も行う
// ※このパートは、primaryを使う場合は必須ではないが、上記エラー処理を入れる目的で①〜④の各箇所に設置
    try {
      calendarO.CalendarList calendarListO = await googleCalendarApiO.calendarList.list();
      List<calendarO.CalendarListEntry>? calendarListEntryO = calendarListO.items;
      calendarListEntryO!.forEach((elementO){print("calendarIdを表示 ${elementO.id}");});
// iOSで同意画面にチェックせず続行した場合のエラー処理
    } catch (eO) {
      print("権限付与エラー $eO");
// エラーの場合は、同意画面に再度チェックさせるため、一度完全サインアウトする
      await _signOutFromGoogleO();
// 早期リターン
      return;
    }
// 予定情報を格納するためのEventクラスのインスタンスを作成
    calendarO.Event eventO = calendarO.Event();
    /// 予定タイトルをインスタンス内のプロパティに設定
    eventO.summary = titleControllerO.text;
    /// 予定日時（期間の開始時刻）をインスタンス内のプロパティに設定
// EventDateTimeクラスのインスタンスを作成し、開始日時とタイムゾーンのプロパティに値を設定
    calendarO.EventDateTime startO = calendarO.EventDateTime();
    startO.dateTime = registeredDateO;
// 日本の場合は"GMT+09:00"
    startO.timeZone = "GMT+09:00";
// 上記開始日時に関するEventDateTimeクラスのインスタンスを
// Eventクラスのインスタンス内のstartプロパティに設定
    eventO.start = startO;
    /// 予定日時＋1h（期間の終了時刻）の登録
    calendarO.EventDateTime endO = new calendarO.EventDateTime();
// 本サンプルコードでは、Googleカレンダーに登録する終了時刻を
// 開始時刻の1時間後とする
    endO.dateTime = registeredDateO.add(Duration(hours: 1));
    endO.timeZone = "GMT+09:00";
    eventO.end = endO;
    /// リマインダーの設定
// リマインダー情報を設定するためのEventReminderクラスのインスタンスを作成
// リマインダーは複数設定できるため、リスト型になる
    List<calendarO.EventReminder>? overridesO = [];
// インスタンスに設定するリマインダーの値（予定日時からどれだけ前にリマインダーを出すか）を
// 分（minute）に換算して設定する
    final int reminderMinutesO = reminderTimingO * 60 * 24;
    calendarO.EventReminder reminderFirstO = calendarO.EventReminder(
      method: reminderMethodO,
// リマインダーの値には上限（40320分）・下限（0分）があるため、
// 上限・下限チェックを入れる
      minutes: (reminderMinutesO > 40320)
          ? 40320
          : (reminderMinutesO < 0)
          ? 0
          : reminderMinutesO,
    );
// リマインダー設定値をリストに格納
    overridesO.add(reminderFirstO);
// 上記リストをEventReminders型のインスタンスに設定
// デフォルトのリマインダー設定を使わないため、useDefaultプロパティはfalseにする
    calendarO.EventReminders eventRemindersO =
    calendarO.EventReminders(overrides: overridesO, useDefault: false);
// 上記EventReminders型のインスタンスを
// Eventクラスのインスタンス内のremindersプロパティに設定
    eventO.reminders = eventRemindersO;
    /// 予定IDの設定
// uuidパッケージを使ってユニークなIDを作成し、
// Eventクラスのインスタンス内のidプロパティに設定
// Googleカレンダーのidはハイフン不可のため削除しておく
// ※ハイフンを削除しないとエラーになる
    registeredScheduleIdO = Uuid().v1().replaceAll("-", "");
    eventO.id = registeredScheduleIdO;
    /// 予定メモの設定
// メモ内容をEventクラスのインスタンス内のdescriptionプロパティに設定
// 上記予定IDを確認できるよう、メモの冒頭に挿入する
    eventO.description = "予定ID:$registeredScheduleIdO\n${memoControllerO.text}";
    /// Googleカレンダーへの登録処理
// 下記に出てくる「events」はGoogle Calendar API内のプロパティ（既出の「eventO」とは別物）
// events.insertメソッドで予定を登録する
// ※指定したカレンダー（ここでは"primary"）に
//  上記で一連の値を設定したEventクラスのインスタンスを登録する
    try {
      await googleCalendarApiO.events.insert(eventO, calendarIdO).then((value) {
// 問題なく登録されると、返り値のstatusプロパティに"confirmed"が
// 返ってくるので、それに応じて成否メッセージを表示
        if (value.status == "confirmed") {
          print("予定の登録成功");
        } else {
          print("予定が登録されず");
        }
      });
    } catch (eO) {
      print("登録エラー $eO");
// エラーのため予定IDは表示せずリターン
      return;
    }
// 登録された予定IDを表示するため再描画
    setState(() {});
  }
  /// ステップ② 予定情報の取得
  Future<void> _getScheduleO(String scheduleIdO) async{
    /// 予定IDの入力が空だったら早期リターン
// Googleカレンダーのidはハイフン不可のため、念のため除外しておく
    scheduleIdO = scheduleIdO.replaceAll("-", "");
    if (scheduleIdO == "") return;
    /// Google SignInの処理
// サインインせずに実行した場合に備え、ここでもサインイン処理をする
    final signInResultO = await _googleSignInMethodO();
    if (!signInResultO) {
// サインインできなかった場合は、早期リターン
      return;
    }
    /// Googleカレンダーからの情報取得処理
// 起動後最初にこのボタンを実行した場合に備え、ここでも
// Googleサインインで認証済のHTTPクライアントのインスタンスを作成
    try {
      httpClientO = (await googleSignInO.authenticatedClient())!;
    } catch (eO) {
      print("権限付与エラー $eO");
// エラーの場合は、同意画面に再度チェックさせるため、一度完全サインアウトする
      await _signOutFromGoogleO();
      return;
    }
// Google Calendar APIのインスタンスを作成
    googleCalendarApiO = calendarO.CalendarApi(httpClientO);
// 予定情報を取得したいカレンダーのIDを指定
// 本サンプルコードでは、「primary」カレンダーとする
    String calendarIdO = "primary";
    try {
      calendarO.CalendarList calendarListO = await googleCalendarApiO.calendarList.list();
      List<calendarO.CalendarListEntry>? calendarListEntryO = calendarListO.items;
      calendarListEntryO!.forEach((elementO){print("calendarIdを表示 ${elementO.id}");});
// iOSで同意画面にチェックせず続行した場合のエラー処理
    } catch (eO) {
      print("権限付与エラー $eO");
      await _signOutFromGoogleO();
      return;
    }
// 上記カレンダーIDと、予定ID（TextFormFieldに入力したID）を指定し、
// events.getメソッドで予定情報を取得する
// ※エラーにならなければ、データがあることを意味する
//  その場合、予定データを取得し、設定したプロパティの値をprintで表示
    try {
      await googleCalendarApiO.events.get(calendarIdO, scheduleIdO).then(
// events.getメソッドの返り値（Event型）をvalueOで受ける
            (valueO) {
// 端末のTimeZoneで表示するため、.toLocal()をつける
// リマインダーは1つしか設定していないため、配列の1番目（配列番号0）のみを取得
          print("タイトル:${valueO.summary}, 予定日時:${valueO.start!.dateTime!.toLocal().toString()}, リマインダー:${valueO.reminders!.overrides![0].minutes}分前 (方法:${valueO.reminders!.overrides![0].method}), メモ:${valueO.description}");
        },
      );
// エラーの時はデータが無いので、何もせずリターン
    } catch (e) {
      print("予定データなし $e");
      return;
    }
  }
  /// ステップ③ 予定の更新
  Future<void> _updateScheduleO(String scheduleIdO) async{
    /// 予定IDの入力が空だったら早期リターン
// Googleカレンダーのidはハイフン不可のため、念のため除外しておく
    scheduleIdO = scheduleIdO.replaceAll("-", "");
    if (scheduleIdO == "") return;
    /// Google SignInの処理
// サインインせずに実行した場合に備え、ここでもサインイン処理をする
    final signInResultO = await _googleSignInMethodO();
    if (!signInResultO) {
// サインインできなかった場合は、早期リターン
      return;
    }
    /// Googleカレンダーのインスタンス作成
// 起動後最初にこのボタンを実行した場合に備え、ここでも
// Googleサインインで認証済のHTTPクライアントのインスタンスを作成
    try {
      httpClientO = (await googleSignInO.authenticatedClient())!;
    } catch (eO) {
      print("権限付与エラー $eO");
// エラーの場合は、同意画面に再度チェックさせるため、一度完全サインアウトする
      await _signOutFromGoogleO();
      return;
    }
// Google Calendar APIのインスタンスを作成
    googleCalendarApiO = calendarO.CalendarApi(httpClientO);
// 予定情報を更新したいカレンダーのIDを指定
// 本サンプルコードでは、「primary」カレンダーとする
    String calendarIdO = "primary";
    try {
      calendarO.CalendarList calendarListO = await googleCalendarApiO.calendarList.list();
      List<calendarO.CalendarListEntry>? calendarListEntryO = calendarListO.items;
      calendarListEntryO!.forEach((elementO){print("calendarIdを表示 ${elementO.id}");});
// iOSで同意画面にチェックせず続行した場合のエラー処理
    } catch (eO) {
      print("権限付与エラー $eO");
      await _signOutFromGoogleO();
      return;
    }
// 更新用のEventクラスのインスタンスを作成
    calendarO.Event eventO = calendarO.Event();
    /// Googleカレンダーに指定した予定IDのデータがあるか否かの判定処理
// events.getメソッドでチェックし、エラーにならなければデータあり
    try {
      await googleCalendarApiO.events.get(calendarIdO, scheduleIdO).then(
            (valueO) {
          print("既存データあり");
        },
      );
// エラーの時はデータが無いため、早期リターン
    } catch (e) {
      print("既存データなし $e");
      return;
    }
    /// タイトルの再登録
    eventO.summary = titleControllerO.text;
    /// 予定日時（期間の開始時刻）の再登録
    calendarO.EventDateTime startO = calendarO.EventDateTime();
    startO.dateTime = registeredDateO;
// 日本の場合は"GMT+09:00"
    startO.timeZone = "GMT+09:00";
    eventO.start = startO;
    /// 予定日時＋1h（期間の終了時刻）の再登録
    calendarO.EventDateTime endO = new calendarO.EventDateTime();
    endO.dateTime = registeredDateO.add(Duration(hours: 1));
    endO.timeZone = "GMT+09:00";
    eventO.end = endO;
    /// リマインダーの再設定
    List<calendarO.EventReminder>? overridesO = [];
    final int reminderMinutesO = reminderTimingO * 60 * 24;
    calendarO.EventReminder reminderFirstO = calendarO.EventReminder(
      method: reminderMethodO,
// 念のため上限・下限チェックを入れる
      minutes: (reminderMinutesO > 40320)
          ? 40320
          : (reminderMinutesO < 0)
          ? 0
          : reminderMinutesO,
    );
// アラート内容をリストに追加
    overridesO.add(reminderFirstO);
// 上記リストをEventReminders型のインスタンスに設定
    calendarO.EventReminders eventRemindersO =
    calendarO.EventReminders(overrides: overridesO, useDefault: false);
    eventO.reminders = eventRemindersO;
// 予定IDは設定済のため、再設定は不要
    /// メモ内容の再設定
    eventO.description = "予定ID:$scheduleIdO\n${memoControllerO.text}";
    /// 予定IDのデータの更新処理
    try {
//  events.updateメソッドに、
//  "primary"カレンダーを表す calendarIdO、予定IDを表す scheduleIdO、
//  更新用のEventクラスのインスタンス eventO を引数として渡すことで、予定を更新する
      await googleCalendarApiO.events
          .update(eventO, calendarIdO, scheduleIdO)
          .then((value) {
        if (value.status == "confirmed") {
          print("予定の更新に成功");
        } else {
          print("予定の更新失敗");
        }
      });
    } catch (e) {
      print("エラー $e");
      return;
    }
  }
  /// ステップ④ 予定の削除
  Future<void> _deleteScheduleO(String scheduleIdO) async{
    /// 予定IDの入力が空だったら早期リターン
// Googleカレンダーのidはハイフン不可のため、念のため除外しておく
    scheduleIdO = scheduleIdO.replaceAll("-", "");
    if (scheduleIdO == "") return;
    /// Google SignInの処理
// サインインせずに実行した場合に備え、ここでもサインイン処理をする
    final signInResultO = await _googleSignInMethodO();
    if (!signInResultO) {
// サインインできなかった場合は、早期リターン
      return;
    }
    /// Googleカレンダーのインスタンス作成
// 起動後最初にこのボタンを実行した場合に備え、ここでも
// Googleサインインで認証済のHTTPクライアントのインスタンスを作成
    try {
      httpClientO = (await googleSignInO.authenticatedClient())!;
    } catch (eO) {
      print("権限付与エラー $eO");
// エラーの場合は、同意画面に再度チェックさせるため、一度完全サインアウトする
      await _signOutFromGoogleO();
      return;
    }
// Google Calendar APIのインスタンスを作成
    googleCalendarApiO = calendarO.CalendarApi(httpClientO);
// 予定を削除したいカレンダーのIDを指定
// 本サンプルコードでは、「primary」カレンダーとする
    String calendarIdO = "primary";
    try {
      calendarO.CalendarList calendarListO = await googleCalendarApiO.calendarList.list();
      List<calendarO.CalendarListEntry>? calendarListEntryO = calendarListO.items;
      calendarListEntryO!.forEach((elementO){print("calendarIdを表示 ${elementO.id}");});
// iOSで同意画面にチェックせず続行した場合のエラー処理
    } catch (eO) {
      print("権限付与エラー $eO");
      await _signOutFromGoogleO();
      return;
    }
    /// Google Calendarに指定した予定IDのデータがあるか否かの判定処理
// events.getメソッドでチェックし、エラーにならなければデータあり
    try {
      await googleCalendarApiO.events.get(calendarIdO, scheduleIdO).then(
            (valueO) {
          print("既存データあり");
        },
      );
// エラーになればデータ無しのため、早期リターン
    } catch (e) {
      print("既存データなし $e");
      return;
    }
    /// 予定IDのデータの削除処理
    try {
// "primary"カレンダーを表す calendarIdO と、予定IDを表す scheduleIdO を引数で指定する
// ※イベントデータ eventO は引数に取れない
// ※insert、updateと異なり、返り値はなし
// events.deleteメソッドは、ゴミ箱に移すだけで、完全には削除しない（events.getメソッドで情報取得可能）
// Googleカレンダー上で手動でゴミ箱から削除すれば、完全削除される（events.getメソッドで取得できなくなる）
      await googleCalendarApiO.events.delete(calendarIdO, scheduleIdO);
      print("ID $scheduleIdO の予定を削除");
    } catch (e) {
      print("エラー $e");
      return;
    }
  }
  /// ステップ⑤ サインアウト処理
  Future<void> _signOutFromGoogleO() async {
// サインインせずこのボタンを押した場合を想定し、
// ここでもGoogle SignIn認証のためのインスタンスを作成する
    googleSignInO = signInO.GoogleSignIn(scopes: [
      calendarO.CalendarApi.calendarScope,
    ]);
    try {
      await googleSignInO.disconnect();
// // 再サインインするときに同意画面を表示させたくない場合は、上記1文を以下に変更
// await googleSignInO.signOut();
// // firebase上にサインインしたユーザー情報を記録している場合は以下を追加
// // ※firebase_auth、firebase_coreのインポートが必要
// await FirebaseAuth.instance.signOut();
// サインアウト表示に変更し、再描画
      setState(() {
        signInStatusO = "サインアウト中";
      });
    } catch (e) {
      print("サインアウトエラー $e");
// サインイン中か否か判定して、それに応じた表示に変更
      final isSignedInO = await googleSignInO.isSignedIn();
      setState(() {
        isSignedInO ? signInStatusO = "サインイン中" : signInStatusO = "サインアウト中";
      });
      return;
    }
  }
}

/*
void main() async{
  //アプリ実行前にFlutterアプリの機能を利用する場合に宣言
  WidgetsFlutterBinding.ensureInitialized();
  //Firebaseのパッケージを呼び出し

  //await ・・・非同期処理が完了するまで待ち、その非同期処理の結果を取り出してくれる
  //awaitを付与したら asyncも付与する

  await Firebase.initializeApp();
  runApp(MyApp());
}

//Stateless ・・・状態を保持する（動的に変化しない）
// Stateful  ・・・状態を保持しない（変化する）
// overrride ・・・上書き

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

             // map ・・・要素それぞれに対して、渡した関数の処理を加えて新しく繰り返し処理する
             // データを取得（名前と数）してテキストとしてColumnに書き出す

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

     // forEach ・・・要素を一個ずつ順に取り出し処理する（繰り返し）
     // ログに取得結果を表示

    documentList.forEach((elem) {
      print(elem.get('name'));
      print(elem.get('votes'));
    });
    print("##################################################### initialize()");
  }
}*/
