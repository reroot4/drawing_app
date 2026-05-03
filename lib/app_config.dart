/// 앱 전역 설정 상수
/// 매직 넘버를 한 곳에서 관리합니다.
class AppConfig {
  AppConfig._();

  /// 기본 서버 URL — 여기 한 곳만 수정하면 전체에 반영됩니다.
  static String serverUrl = 'http://192.168.0.2:8080';
  static const String uploadPath = '/api/upload';

  /// 드로잉 설정
  static const double defaultStrokeWidth = 5.0;
  static const double minStrokeWidth = 1.0;
  static const double maxStrokeWidth = 30.0;

  /// 캔버스 저장 설정
  static const double exportPixelRatio = 3.0;
  static const String exportAlbum = 'PiLink';
}
