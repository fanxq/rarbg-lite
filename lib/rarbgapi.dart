import 'package:dio/dio.dart';
import 'dart:core';

class RarbgApi {
  final String _url = 'https://torrentapi.org/pubapi_v2.php';
  static Map categories = {
    'XXX': 4,
    'MOVIES_XVID': 14,
    'MOVIES_XVID_720': 48,
    'MOVIES_X264': 17,
    'MOVIES_X264_1080': 44,
    'MOVIES_X264_720': 45,
    'MOVIES_X264_3D': 47,
    'MOVIES_X264_4K': 50,
    'MOVIES_X265_4K': 51,
    'MOVIES_X265_4K_HDR': 52,
    'MOVIES_FULL_BD': 42,
    'MOVIES_BD_REMUX': 46,
    'TV_EPISODES': 18,
    'TV_HD_EPISODES': 41,
    'MUSIC_MP3': 23,
    'MUSIC_FLAC': 25,
    'GAMES_PC_ISO': 27,
    'GAMES_PC_RIP': 28,
    'GAMES_PS3': 40,
    'GAMES_XBOX_360': 32,
    'SOFTWARE_PC_ISO': 33,
    'E_BOOKS': 35
  };
  var lastRequestTime = DateTime.now();
  var tokenTimestamp = DateTime.utc(1970);
  String _token;
  Dio _dio = Dio();

  Future<void> setToken() async {
    try {
      Response response =
          await _dio.get('$_url?get_token=get_token&app_id=myapp');
      if (response != null) {
        //_token = response.data['token'];
        _token = response?.data['token'];
        tokenTimestamp = DateTime.now();
      }
    } catch (e) {
      print(e.message);
    }
  }

  Future<void> getToken() async {
    var diff = DateTime.now().millisecondsSinceEpoch -
        tokenTimestamp.millisecondsSinceEpoch;
    if (_token == null || _token.isEmpty || diff > 14 * 60 * 1000) {
      print('setToken');
      await setToken();
    }
  }

  Future<dynamic> search(String searchString, int category) async {
    await getToken();
    var diff = 2000 -
        (DateTime.now().millisecondsSinceEpoch -
            lastRequestTime.millisecondsSinceEpoch);
    print(diff);
    var delay = diff > 0 ? diff.toInt() : 0;
    await Future.delayed(Duration(milliseconds: delay));

    var url =
        '$_url?mode=search&token=$_token&search_string=$searchString&category=$category&sort=last&app_id=myapp&limit=100';
    print(url);
    Response response = await _dio.get(url);
    lastRequestTime = DateTime.now();
    return response;
  }
}
