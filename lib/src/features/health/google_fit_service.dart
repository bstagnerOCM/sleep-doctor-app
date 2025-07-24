import 'package:flutter/services.dart';

class GoogleFitService {
  static const _channel = MethodChannel('com.sleepdoctor.app/healthdata');

  Future<List<dynamic>> getSleep() async {
    final sleepData =
        await _channel.invokeMethod<List<dynamic>>('getSleepData');
    return sleepData ?? [];
  }

  Future<List<dynamic>> getBody() async {
    final bodyData = await _channel.invokeMethod<List<dynamic>>('getBodyData');
    return bodyData ?? [];
  }
}
