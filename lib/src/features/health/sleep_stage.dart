import 'dart:io';

SleepStage? mapPlatformSleepStage(String type) {
  const androidMapping = {
    "Unused": SleepStage.UNUSED,
    "Awake (during sleep)": SleepStage.AWAKE,
    "Sleep": SleepStage.ASLEEP,
    "Out-of-bed": SleepStage.OUT_OF_BED,
    "Light sleep": SleepStage.LIGHT,
    "Deep sleep": SleepStage.DEEP,
    "REM sleep": SleepStage.REM,
  };

  const iosMapping = {
    "SLEEP_DEEP": SleepStage.DEEP,
    "SLEEP_LIGHT": SleepStage.LIGHT,
    "SLEEP_ASLEEP": SleepStage.ASLEEP,
    "SLEEP_REM": SleepStage.REM,
    "SLEEP_AWAKE": SleepStage.AWAKE,
    // Add any iOS-specific mappings here if necessary
  };

  if (Platform.isAndroid) {
    return androidMapping[type];
  } else if (Platform.isIOS) {
    return iosMapping[type];
  } else {
    return null;
  }
}

enum SleepStage {
  DEEP,
  LIGHT,
  ASLEEP,
  REM,
  AWAKE,
  OUT_OF_BED,
  UNUSED,
}

Map<SleepStage, double> sleepStageMap = {
  SleepStage.DEEP: 0,
  SleepStage.LIGHT: 1,
  SleepStage.ASLEEP: 1.5,
  SleepStage.REM: 2,
  SleepStage.AWAKE: 3,
  SleepStage.OUT_OF_BED: 4,
  SleepStage.UNUSED: 5,
};

// lib/models/custom_health_data_point.dart

class CustomHealthDataPoint {
  final String type;
  final double value;
  final DateTime dateFrom;
  final DateTime dateTo;

  CustomHealthDataPoint({
    required this.type,
    required this.value,
    required this.dateFrom,
    required this.dateTo,
  });
}
