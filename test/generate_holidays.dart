import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

// ★Holidays JP API (内閣府のデータを元にした、日本の祝日専用API)
// メンテナンスフリーで、法律上の祝日だけを取得できます。
const String apiUrl = 'https://holidays-jp.github.io/api/v1/date.json';

void main() async {
  print('日本の公式サイト(Holidays JP)からデータを取得中...');

  try {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      print('【APIエラー】ステータスコード: ${response.statusCode}');
      exit(1);
    }

    // データは {"2025-01-01": "元日", "2025-01-13": "成人の日"...} の形式で返ってきます
    final Map<String, dynamic> rawData = json.decode(utf8.decode(response.bodyBytes));
    
    // 必要な期間（去年〜再来年）だけに絞り込む
    final now = DateTime.now();
    final startYear = now.year - 1;
    final endYear = now.year + 2;

    Map<String, String> finalHolidays = {};

    rawData.forEach((dateStr, title) {
      // dateStrは "YYYY-MM-DD" 形式
      final year = int.parse(dateStr.split('-')[0]);

      if (year >= startYear && year <= endYear) {
        finalHolidays[dateStr] = title.toString();
      }
    });

    // JSON書き出し
    final jsonString = const JsonEncoder.withIndent('  ').convert(finalHolidays);
    final outputFile = File('holidays.json');
    
    await outputFile.writeAsString(jsonString);

    print('------------------------------------------------');
    print('✅ 成功しました！(内閣府データ準拠)');
    print('取得件数: ${finalHolidays.length}件');
    print('APIキー不要・リスト管理不要で完全自動化されました。');
    print('------------------------------------------------');

  } catch (e) {
    print('【ネットワークエラー】: $e');
    exit(1);
  }
}