import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// 注意: GitHub Actions上で動くとき、このキーは「Secrets」から自動で読み込まれます。
// コードに直接APIキーを書かないでください（セキュリティのため）。
final String apiKey = Platform.environment['GOOGLE_API_KEY'] ?? '';

// URLエンコード済みのカレンダーID (# -> %23)
const String calendarId = 'ja.japanese%23holiday@group.v.calendar.google.com';

void main() async {
  // 1. APIキーのチェック
  if (apiKey.isEmpty) {
    print('【エラー】APIキーが設定されていません。');
    print('GitHubのSettings > Secrets and variables > Actions に "GOOGLE_API_KEY" を追加してください。');
    // ローカルでテストする場合は、以下のように一時的に書き換えても良いですが、コミットしないでください。
    // apiKey = 'AIzaSy...'; 
    exit(1);
  }

  // 2. 取得範囲の設定 (去年〜再来年まで)
  final now = DateTime.now();
  final start = DateTime(now.year - 1, 1, 1);
  final end = DateTime(now.year + 2, 12, 31);

  final String timeMin = start.toUtc().toIso8601String();
  final String timeMax = end.toUtc().toIso8601String();

  final Uri url = Uri.parse(
      'https://www.googleapis.com/calendar/v3/calendars/$calendarId/events'
      '?key=$apiKey'
      '&timeMin=$timeMin'
      '&timeMax=$timeMax'
      '&singleEvents=true'
      '&orderBy=startTime');

  print('Google Calendar APIからデータを取得中...');
  print('Target URL: $url'); // デバッグ用（キー以外を表示）

  try {
    final response = await http.get(url);

    if (response.statusCode != 200) {
      print('【APIエラー】ステータスコード: ${response.statusCode}');
      print('内容: ${response.body}');
      exit(1);
    }

    final data = json.decode(response.body);
    final List<dynamic> items = data['items'];

    // 3. アプリで使いやすい形に整形 {"2025-01-01": "元日", ...}
    Map<String, String> simpleHolidays = {};

    for (var item in items) {
      // 終日イベントの場合、dateフィールドに "yyyy-MM-dd" が入る
      final date = item['start']['date'];
      final title = item['summary'];

      if (date != null && title != null) {
        simpleHolidays[date] = title.toString();
      }
    }

    // 4. ファイルに書き出し (holidays.json)
    // 整形して読みやすくする (JsonEncoder.withIndent)
    final jsonString = const JsonEncoder.withIndent('  ').convert(simpleHolidays);
    final outputFile = File('holidays.json');
    
    await outputFile.writeAsString(jsonString);

    print('------------------------------------------------');
    print('✅ 成功しました！');
    print('ファイル名: holidays.json');
    print('取得件数: ${simpleHolidays.length}件');
    print('------------------------------------------------');

  } catch (e) {
    print('【ネットワークエラー】: $e');
    exit(1);
  }
}