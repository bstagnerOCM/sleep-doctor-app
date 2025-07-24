import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import './google_fit_service.dart';
import 'health_data_point.dart' as custom_health;
import 'package:collection/collection.dart';
import 'health_data_point_widget.dart';

void main() => runApp(const HealthApp());

class HealthApp extends StatefulWidget {
  const HealthApp({super.key});

  @override
  HealthAppState createState() => HealthAppState();
}

enum AppState {
  dataNotFetched,
  fetchingData,
  dataReady,
  noData,
  authorized,
  authNotGranted,
  dataAdded,
  dataDeleted,
  dataNotAdded,
  dataNotDeleted,
  stepsReady,
  healthConnectedStatus,
}

class HealthAppState extends State<HealthApp> {
  static List<custom_health.CustomHealthDataPoint>? _cachedHealthDataList;
  static AppState? _cachedState;

  Health health = Health();
  List<custom_health.CustomHealthDataPoint> _healthDataList = [];
  AppState _state = AppState.dataNotFetched;
  final int _nofSteps = 0;

  // All types available depending on platform (iOS or Android).
  List<HealthDataType> get types => (Platform.isAndroid)
      ? dataTypesAndroid
      : (Platform.isIOS)
          ? dataTypesIOS
          : [];

  List<HealthDataAccess> get permissions => types.map((type) {
        // Assign READ_WRITE for the first group
        if ([
          HealthDataType.STEPS,
          HealthDataType.BODY_TEMPERATURE,
          HealthDataType.SLEEP_ASLEEP,
          HealthDataType.SLEEP_AWAKE,
          HealthDataType.SLEEP_DEEP,
          HealthDataType.SLEEP_LIGHT,
          HealthDataType.SLEEP_REM,
          HealthDataType.SLEEP_IN_BED,
          HealthDataType.SLEEP_SESSION,
        ].contains(type)) {
          return HealthDataAccess.READ_WRITE;
        }
        // Assign READ for the second group
        else if ([
          HealthDataType.HEIGHT,
          HealthDataType.WEIGHT,
          HealthDataType.GENDER,
          HealthDataType.BIRTH_DATE,
        ].contains(type)) {
          return HealthDataAccess.READ;
        }
        // Default to READ_WRITE if not explicitly listed
        else {
          return HealthDataAccess.READ;
        }
      }).toList();

  @override
  void initState() {
    super.initState();

    if (_cachedHealthDataList != null && _cachedState == AppState.dataReady) {
      _healthDataList = _cachedHealthDataList!;
      _state = _cachedState!;
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Health().configure();
      await _authorizeOnScreenLoad();
    });
  }

  /// Automatically checks and requests authorization when the screen loads
  Future<void> _authorizeOnScreenLoad() async {
    debugPrint("Requesting permissions...");

    // Request activity and location permissions (if applicable)
    await Permission.activityRecognition.request();
    await Permission.location.request();

    // Check if the user has already granted permissions
    bool? hasPermissions =
        await health.hasPermissions(types, permissions: permissions);

    if (hasPermissions == null || hasPermissions == false) {
      if (Platform.isAndroid) {
        setState(() {
          _state = AppState.authorized;
        });
        await fetchAndroidData();
      } else {
        try {
          // Request HealthKit permissions
          bool authorized = await health.requestAuthorization(types,
              permissions: permissions);

          // Update the app state based on the authorization result
          setState(() {
            _state = authorized ? AppState.authorized : AppState.authNotGranted;
          });

          // Only fetch data if authorized
          if (authorized) {
            await fetchUserData(); // Call iOS-specific data fetch
          } else {
            debugPrint("Authorization denied.");
          }
        } catch (error) {
          debugPrint("Error requesting permissions: $error");
          setState(() {
            _state = AppState.authNotGranted;
          });
        }
      }
    } else {
      debugPrint("Permissions already granted.");
      setState(() {
        _state = AppState.authorized;
      });

      // Fetch data based on platform
      if (Platform.isAndroid) {
        await fetchAndroidData();
      } else {
        await fetchUserData();
      }
    }
  }

  // Fetch User data
  Future<void> fetchUserData() async {
    setState(() => _state = AppState.fetchingData);

    _healthDataList.clear();

    try {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
          types: types, startTime: thirtyDaysAgo, endTime: now);

      // Convert to custom_health.CustomHealthDataPoint
      _healthDataList = healthData.map((point) {
        double numericValue;

        // Safely extract the numeric value from HealthValue
        if (point.value is NumericHealthValue) {
          numericValue =
              (point.value as NumericHealthValue).numericValue.toDouble();
        } else {
          // Default to 0.0 or handle unexpected value types gracefully
          numericValue = 0.0;
        }

        return custom_health.CustomHealthDataPoint(
          type: point.typeString,
          value: numericValue,
          dateFrom: point.dateFrom,
          dateTo: point.dateTo,
        );
      }).toList();

      setState(() {
        _state = _healthDataList.isEmpty ? AppState.noData : AppState.dataReady;
      });

      // Cache the data and state
      _cachedHealthDataList = _healthDataList;
      _cachedState = _state;
    } catch (error) {
      setState(() {
        _state = AppState.noData;
      });
    }
  }

  /// Refresh data method, triggered by pull-to-refresh
  Future<void> _refreshData() async {
    // Just fetchUserData again
    if (Platform.isAndroid) {
      await fetchAndroidData();
    } else {
      await fetchUserData();
    }
  }

  /// Gets the Health Connect status on Android.
  Future<void> getHealthConnectSdkStatus() async {
    assert(Platform.isAndroid, "This is only available on Android");

    final status = await health.getHealthConnectSdkStatus();

    setState(() {
      _state = AppState.healthConnectedStatus;
    });

    debugPrint('Health Connect Status: $status');
  }

  Future<void> fetchAndroidData() async {
    debugPrint("Fetching Android data...");
    setState(() => _state = AppState.fetchingData);

    try {
      debugPrint("Fetching..");
      final fitService = GoogleFitService();
      List<dynamic> sleepData = await fitService.getSleep();
      debugPrint("Sleep Data: $sleepData");
      List<dynamic> bodyData = await fitService.getBody();
      debugPrint("Body Data: $bodyData");
      List<custom_health.CustomHealthDataPoint> combinedHealthData = [];

      // Process body data
      for (var item in bodyData) {
        debugPrint("Body Data loop: $item");
        debugPrint("Item runtime type: ${item.runtimeType}");

        if (item is Map) {
          // General Map check
          try {
            // Convert to Map<String, dynamic>
            final Map<String, dynamic> parsedItem =
                Map<String, dynamic>.from(item);

            // Extract and validate 'type'
            final String? typeRaw = parsedItem['type']?.toString();
            final String type =
                typeRaw != null ? typeRaw.toUpperCase() : 'UNKNOWN';
            if (type == 'UNKNOWN') {
              // debugPrint("Skipping item without valid 'type': $parsedItem");
              continue;
            }

            // Extract and validate 'value'
            final dynamic rawValue = parsedItem['value'];
            double? numericValue;

            if (rawValue is num) {
              numericValue = rawValue.toDouble();
            } else if (rawValue is String) {
              numericValue = double.tryParse(rawValue);
              if (numericValue == null) {
                // debugPrint(
                //     "Failed to parse 'value' as double: $rawValue in item: $parsedItem");
                continue;
              }
            } else {
              // debugPrint(
              //     "Unsupported 'value' type: ${rawValue.runtimeType} in item: $parsedItem");
              continue;
            }

            // debugPrint("Parsed numeric value: $numericValue");

            // Extract and validate 'timestamp'
            final dynamic rawTimestamp = parsedItem['timestamp'];
            int? timestampInMillis;

            if (rawTimestamp is int) {
              if (rawTimestamp.toString().length == 10) {
                // seconds
                timestampInMillis = rawTimestamp * 1000;
              } else if (rawTimestamp.toString().length == 13) {
                // milliseconds
                timestampInMillis = rawTimestamp;
              } else {
                // debugPrint(
                //     "Unexpected 'timestamp' length: ${rawTimestamp.toString().length} in item: $parsedItem");
                continue;
              }
            } else if (rawTimestamp is double) {
              int ts = rawTimestamp.toInt();
              if (ts.toString().length == 10) {
                // seconds
                timestampInMillis = ts * 1000;
              } else if (ts.toString().length == 13) {
                // milliseconds
                timestampInMillis = ts;
              } else {
                // debugPrint(
                //     "Unexpected 'timestamp' length: ${ts.toString().length} in item: $parsedItem");
                continue;
              }
            } else {
              // debugPrint(
              //     "Unsupported 'timestamp' type: ${rawTimestamp.runtimeType} in item: $parsedItem");
              continue;
            }

            DateTime dateFrom =
                DateTime.fromMillisecondsSinceEpoch(timestampInMillis);
            DateTime dateTo =
                DateTime.fromMillisecondsSinceEpoch(timestampInMillis);

            // debugPrint("Parsed timestamp: $dateFrom");

            // Add to combinedHealthData
            combinedHealthData.add(
              custom_health.CustomHealthDataPoint(
                type: type,
                value: numericValue,
                dateFrom: dateFrom,
                dateTo: dateTo,
              ),
            );

            // debugPrint("Successfully processed item: $parsedItem");
          } catch (e) {
            debugPrint("Error processing item: $item, Error: $e");
          }
        } else {
          // debugPrint("Skipping item, not a Map: $item");
        }
      }
      // Process sleep data
      for (var item in sleepData) {
        if (item is Map) {
          // General Map check
          try {
            // Convert to Map<String, dynamic>
            final Map<String, dynamic> parsedItem =
                Map<String, dynamic>.from(item);

            // Extract and validate 'sleepStage' if available, else set to a default
            final String sleepStage =
                parsedItem['type']?.toString().toUpperCase() ?? 'UNKNOWN';
            if (sleepStage == 'UNKNOWN') {
              debugPrint(
                  "Skipping sleep item without valid 'sleepStage': $parsedItem");
              continue;
            }

            // Extract and validate 'startTime' and 'endTime'
            final dynamic rawStartTime = parsedItem['startTime'];
            final dynamic rawEndTime = parsedItem['endTime'];
            int? startTimeMillis;
            int? endTimeMillis;

            // Convert 'startTime'
            if (rawStartTime is int) {
              if (rawStartTime.toString().length == 10) {
                // seconds
                startTimeMillis = rawStartTime * 1000;
              } else if (rawStartTime.toString().length == 13) {
                // milliseconds
                startTimeMillis = rawStartTime;
              } else {
                debugPrint(
                    "Unexpected 'startTime' length: ${rawStartTime.toString().length} in item: $parsedItem");
                continue;
              }
            } else if (rawStartTime is double) {
              int ts = rawStartTime.toInt();
              if (ts.toString().length == 10) {
                // seconds
                startTimeMillis = ts * 1000;
              } else if (ts.toString().length == 13) {
                // milliseconds
                startTimeMillis = ts;
              } else {
                debugPrint(
                    "Unexpected 'startTime' length: ${ts.toString().length} in item: $parsedItem");
                continue;
              }
            } else {
              debugPrint(
                  "Unsupported 'startTime' type: ${rawStartTime.runtimeType} in item: $parsedItem");
              continue;
            }

            // Convert 'endTime'
            if (rawEndTime is int) {
              if (rawEndTime.toString().length == 10) {
                // seconds
                endTimeMillis = rawEndTime * 1000;
              } else if (rawEndTime.toString().length == 13) {
                // milliseconds
                endTimeMillis = rawEndTime;
              } else {
                debugPrint(
                    "Unexpected 'endTime' length: ${rawEndTime.toString().length} in item: $parsedItem");
                continue;
              }
            } else if (rawEndTime is double) {
              int ts = rawEndTime.toInt();
              if (ts.toString().length == 10) {
                // seconds
                endTimeMillis = ts * 1000;
              } else if (ts.toString().length == 13) {
                // milliseconds
                endTimeMillis = ts;
              } else {
                debugPrint(
                    "Unexpected 'endTime' length: ${ts.toString().length} in item: $parsedItem");
                continue;
              }
            } else {
              debugPrint(
                  "Unsupported 'endTime' type: ${rawEndTime.runtimeType} in item: $parsedItem");
              continue;
            }

            if (startTimeMillis == null || endTimeMillis == null) {
              debugPrint(
                  "Invalid 'startTime' or 'endTime' in item: $parsedItem");
              continue;
            }

            DateTime dateFrom =
                DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
            DateTime dateTo =
                DateTime.fromMillisecondsSinceEpoch(endTimeMillis);

            // Calculate sleep duration in minutes
            double sleepDurationMinutes =
                (endTimeMillis - startTimeMillis) / 60000.0;

            // Add to combinedHealthData
            combinedHealthData.add(
              custom_health.CustomHealthDataPoint(
                type: sleepStage,
                value: sleepDurationMinutes,
                dateFrom: dateFrom,
                dateTo: dateTo,
              ),
            );
          } catch (e) {
            debugPrint("Error processing sleep item: $item, Error: $e");
          }
        } else {
          debugPrint("Skipping sleep item, not a Map: $item");
        }
      }

      _healthDataList = combinedHealthData;

      setState(() {
        _state = _healthDataList.isEmpty ? AppState.noData : AppState.dataReady;
      });

      _cachedHealthDataList = _healthDataList;
      _cachedState = _state;
    } catch (error) {
      setState(() {
        _state = AppState.noData;
      });
    }
  }

  /// Install Google Health Connect on this phone.
  Future<void> installHealthConnect() async {
    await health.installHealthConnect();
  }

  /// Fetch data points from the health plugin and show them in the app.
  Future<void> fetchData() async {
    setState(() => _state = AppState.fetchingData);

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    _healthDataList.clear();

    try {
      // Fetch data from the health plugin
      List<HealthDataPoint> healthData = await health.getHealthDataFromTypes(
        types: types,
        startTime: thirtyDaysAgo,
        endTime: now,
      );

      // Convert HealthDataPoint to CustomHealthDataPoint
      _healthDataList = healthData.map((point) {
        double numericValue = 0.0;

        // Safely extract numeric value
        if (point.value is NumericHealthValue) {
          numericValue =
              (point.value as NumericHealthValue).numericValue.toDouble();
        }

        return custom_health.CustomHealthDataPoint(
          type: point.typeString,
          value: numericValue,
          dateFrom: point.dateFrom,
          dateTo: point.dateTo,
        );
      }).toList();

      setState(() {
        _state = _healthDataList.isEmpty ? AppState.noData : AppState.dataReady;
      });
    } catch (error) {
      debugPrint("Error fetching data: $error");
      setState(() {
        _state = AppState.noData;
      });
    }
  }

  /// Delete some random health data.
  Future<void> deleteData() async {
    final startTime = DateTime(2024, 11, 10);
    final endTime = DateTime(2024, 12, 14);

    bool success = true;

    // List of sleep-related data types
    final sleepTypes = [
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_IN_BED,
    ];

    try {
      for (HealthDataType type in sleepTypes) {
        debugPrint(
            "Attempting to delete data for $type from $startTime to $endTime");
        bool result = await health.delete(
          type: type,
          startTime: startTime,
          endTime: endTime,
        );

        if (!result) {
          debugPrint("Failed to delete data for $type");
          // Fetch health data for the type to see if any data exists
          try {
            List<HealthDataPoint> existingData =
                await health.getHealthDataFromTypes(
              types: [type],
              startTime: startTime,
              endTime: endTime,
            );
            debugPrint(
                "Existing data points for $type: ${existingData.length} - $existingData");
          } catch (fetchError) {
            debugPrint("Error fetching data for $type: $fetchError");
          }

          success = false;
        } else {
          debugPrint("Successfully deleted data for $type");
        }
      }
    } catch (error) {
      debugPrint("Error deleting sleep data: $error");
      success = false;
    }

    setState(() {
      _state = success ? AppState.dataDeleted : AppState.dataNotDeleted;
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 0.0),
              child: Text('Health',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0, // Space between buttons
                runSpacing: 8.0, // Space between rows
                children: [
                  if (Platform.isAndroid)
                    TextButton(
                        onPressed: getHealthConnectSdkStatus,
                        style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Check Health Connect Status",
                            style: TextStyle(color: Colors.white))),
                  if (Platform.isAndroid)
                    TextButton(
                        onPressed: fetchAndroidData,
                        style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Fetch Android Data",
                            style: TextStyle(color: Colors.white))),
                  TextButton(
                      onPressed: fetchData,
                      style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                      child: const Text("Fetch Data",
                          style: TextStyle(color: Colors.white))),
                  if (Platform.isAndroid)
                    TextButton(
                        onPressed: installHealthConnect,
                        style: const ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(Colors.blue)),
                        child: const Text("Install Health Connect",
                            style: TextStyle(color: Colors.white))),
                  TextButton(
                      onPressed: deleteData,
                      style: const ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Colors.blue)),
                      child: const Text("Delete Data",
                          style: TextStyle(color: Colors.white))),
                ],
              ),
            ),
            const Divider(color: Colors.grey),
            Center(child: _content),
          ],
        ),
      ),
    );
  }

  Widget get _contentFetchingData => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
              padding: const EdgeInsets.all(20),
              child: const CircularProgressIndicator(
                strokeWidth: 10,
              )),
          const Text('Fetching data...')
        ],
      );

// Convert height in meters to feet and inches
  String convertMetersToFeetAndInches(double heightInMeters) {
    double heightInFeet = heightInMeters * 3.28084;
    int feet = heightInFeet.floor(); // Get the integer part as feet
    double inches = (heightInFeet - feet) *
        12; // Convert the remaining decimal part to inches
    return "$feet' ${inches.toStringAsFixed(1)}\""; // Return as formatted string
  }

  Widget get _contentDataReady {
    // Extract weight and height data with proper handling for null

    String normalizeHealthDataType(HealthDataType type) {
      return type.toString().split('.').last.toUpperCase();
    }

// Fetch weight data
    custom_health.CustomHealthDataPoint? weightDataPoint =
        _healthDataList.firstWhereOrNull(
            (p) => p.type == normalizeHealthDataType(HealthDataType.WEIGHT));

// Fetch height data
    custom_health.CustomHealthDataPoint? heightDataPoint =
        _healthDataList.firstWhereOrNull(
            (p) => p.type == normalizeHealthDataType(HealthDataType.HEIGHT));

// Fetch birth date data
    custom_health.CustomHealthDataPoint? birthDateDataPoint =
        _healthDataList.firstWhereOrNull((p) =>
            p.type == normalizeHealthDataType(HealthDataType.BIRTH_DATE));

// Fetch gender data
    custom_health.CustomHealthDataPoint? genderDataPoint =
        _healthDataList.firstWhereOrNull(
            (p) => p.type == normalizeHealthDataType(HealthDataType.GENDER));

    // Convert weight to pounds if available
    double? weightInLbs;
    double? weightInKg;
    String? formattedBirthDate;
    String? gender;

    if (weightDataPoint != null) {
      weightInKg = weightDataPoint.value; // Directly use the value as a double
      weightInLbs = weightInKg * 2.20462; // Conversion to pounds
    }

    // Convert height to feet and inches if available
    String? heightInFeetAndInches;
    double? heightInMeters;

    if (heightDataPoint != null) {
      heightInMeters = heightDataPoint.value;
      heightInFeetAndInches = convertMetersToFeetAndInches(heightInMeters);
    }

    // Calculate BMI if both weight and height are available
    double? bmi;
    if (weightInKg != null && heightInMeters != null) {
      bmi = weightInKg / (heightInMeters * heightInMeters);
    }

    if (birthDateDataPoint != null) {
      double birthDateTimestamp =
          birthDateDataPoint.value; // Directly use the value as double
      DateTime birthDate = DateTime.fromMillisecondsSinceEpoch(
          (birthDateTimestamp * 1000).toInt());
      formattedBirthDate =
          "${birthDate.year}-${birthDate.month}-${birthDate.day}";
    }

    // Extract gender if available
    if (genderDataPoint != null) {
      double genderValue =
          genderDataPoint.value; // Directly use the value as double
      if (genderValue == 1.0) {
        gender = "Female";
      } else if (genderValue == 2.0) {
        gender = "Male";
      } else {
        gender = "Unknown"; // Handle unexpected values gracefully
      }
    }

    Map<DateTime, List<custom_health.CustomHealthDataPoint>>
        groupedSleepCycles = {};
    List<custom_health.CustomHealthDataPoint> currentCycle = [];
    DateTime? currentCycleStartTime;

// Sort the data points by their start time
    _healthDataList.sort((a, b) => a.dateFrom.compareTo(b.dateFrom));

// A helper function to finalize the current cycle
    void finalizeCycle() {
      if (currentCycle.isNotEmpty && currentCycleStartTime != null) {
        groupedSleepCycles[currentCycleStartTime!] = List.from(currentCycle);
        currentCycle.clear();
        currentCycleStartTime = null;
      }
    }

    //  define new variable to FIlter out sleep data points for

    List<custom_health.CustomHealthDataPoint> sleepDataPoints = _healthDataList
        .where((element) =>
            element.type == "SLEEP_LIGHT" ||
            element.type == "SLEEP_DEEP" ||
            element.type == "SLEEP_REM" ||
            element.type == "SLEEP_ASLEEP" ||
            element.type == "SLEEP_AWAKE" ||
            element.type == "SLEEP_IN_BED" ||
            element.type == "LIGHT SLEEP" ||
            element.type == "DEEP SLEEP" ||
            element.type == "REM SLEEP" ||
            element.type == "AWAKE (DURING SLEEP)" ||
            element.type == "ASLEEP" ||
            element.type == "IN BED")
        .toList();

    for (int i = 0; i < sleepDataPoints.length; i++) {
      var dataPoint = sleepDataPoints[i];

      // Start a new cycle if the current cycle is empty
      if (currentCycle.isEmpty) {
        if (dataPoint.type == "SLEEP_LIGHT" ||
            dataPoint.type == "SLEEP_DEEP" ||
            dataPoint.type == "SLEEP_REM" ||
            dataPoint.type == "SLEEP_ASLEEP" ||
            dataPoint.type == "SLEEP_IN_BED" ||
            dataPoint.type == "LIGHT SLEEP" ||
            dataPoint.type == "DEEP SLEEP" ||
            dataPoint.type == "REM SLEEP" ||
            dataPoint.type == "AWAKE (DURING SLEEP)" ||
            dataPoint.type == "ASLEEP" ||
            dataPoint.type == "IN BED") {
          currentCycleStartTime = dataPoint.dateFrom;
          currentCycle.add(dataPoint);
        }
      } else {
        // Check for continuity
        var previousDataPoint = currentCycle.last;
        final difference =
            dataPoint.dateFrom.difference(previousDataPoint.dateTo);

        if (difference.inMinutes > 5) {
          // Gap too large, finalize previous cycle
          finalizeCycle();
          if (dataPoint.type == "SLEEP_LIGHT" ||
              dataPoint.type == "SLEEP_DEEP" ||
              dataPoint.type == "SLEEP_REM" ||
              dataPoint.type == "SLEEP_ASLEEP" ||
              dataPoint.type == "SLEEP_IN_BED" ||
              dataPoint.type == "SLEEP_AWAKE" ||
              dataPoint.type == "LIGHT SLEEP" ||
              dataPoint.type == "DEEP SLEEP" ||
              dataPoint.type == "REM SLEEP" ||
              dataPoint.type == "AWAKE (DURING SLEEP)" ||
              dataPoint.type == "ASLEEP" ||
              dataPoint.type == "IN BED") {
            currentCycle.add(dataPoint);
          }
        } else {
          // Continue the current cycle
          currentCycle.add(dataPoint);

          // Finalize if this is the last data point or if the next point doesn't continue the cycle
          bool endCycle = true;
          if (i + 1 < sleepDataPoints.length) {
            var nextDataPoint = sleepDataPoints[i + 1];
            final nextDifference =
                nextDataPoint.dateFrom.difference(dataPoint.dateTo);
            if (nextDifference.inMinutes <= 5 &&
                (nextDataPoint.type == "SLEEP_LIGHT" ||
                    nextDataPoint.type == "SLEEP_DEEP" ||
                    nextDataPoint.type == "SLEEP_REM" ||
                    nextDataPoint.type == "SLEEP_ASLEEP" ||
                    nextDataPoint.type == "SLEEP_IN_BED" ||
                    nextDataPoint.type == "LIGHT SLEEP" ||
                    nextDataPoint.type == "SLEEP_AWAKE" ||
                    nextDataPoint.type == "DEEP SLEEP" ||
                    nextDataPoint.type == "REM SLEEP" ||
                    nextDataPoint.type == "AWAKE (DURING SLEEP)" ||
                    nextDataPoint.type == "ASLEEP" ||
                    nextDataPoint.type == "IN BED")) {
              endCycle = false;
            }
          }

          if (endCycle) {
            finalizeCycle();
          }
        }
      }
    }

// After the loop, finalize any remaining cycle
    finalizeCycle();

    // Function to calculate the sleep score
    double calculateSleepScore({
      required int totalSleepTime,
      required int remTime,
      required int deepTime,
      required int awakeTime,
    }) {
      const int idealSleepTime = 8 * 60; // 8 hours in minutes
      const int idealREMTime =
          (idealSleepTime * 20) ~/ 100; // ~20% of total sleep
      const int idealDeepTime =
          (idealSleepTime * 25) ~/ 100; // ~25% of total sleep

      double sleepTimeScore =
          (totalSleepTime / idealSleepTime).clamp(0.0, 1.0) * 40;
      double remScore = (remTime / idealREMTime).clamp(0.0, 1.0) * 30;
      double deepScore = (deepTime / idealDeepTime).clamp(0.0, 1.0) * 30;

      return (sleepTimeScore + remScore + deepScore).clamp(0.0, 100.0);
    }

    String formattedTypeString(String original) {
      // Replace underscores with spaces
      String result = original.replaceAll("_", " ");

      // Convert to lowercase then capitalize each word
      List<String> words = result.toLowerCase().split(" ");
      words = words.map((word) {
        if (word.isEmpty) return word;
        return word[0].toUpperCase() + word.substring(1);
      }).toList();

      return words.join(" ");
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row to show weight and height at the top
          if (weightDataPoint != null ||
              heightDataPoint != null ||
              bmi != null ||
              formattedBirthDate != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 24.0,
                runSpacing: 24.0,
                children: [
                  if (bmi != null)
                    Text(
                      "BMI: ${bmi.toStringAsFixed(1)}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (weightInLbs != null)
                    Text(
                      "Weight: ${weightInLbs.toStringAsFixed(1)} lbs",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (heightDataPoint != null)
                    Text(
                      "Height: $heightInFeetAndInches",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (formattedBirthDate != null)
                    Text(
                      "Birth Date: $formattedBirthDate",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  if (gender != null)
                    Text(
                      "Gender: $gender",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ),
          // Display grouped sleep data
          ...groupedSleepCycles.entries.toList().reversed.map((entry) {
            DateTime inBedPoint = entry.key;
            List<custom_health.CustomHealthDataPoint> sleepCycles = entry.value;

            // Calculate total durations for each sleep stage
            int totalSleepTime = 0;
            int totalREMTime = 0;
            int totalAwakeTime = 0;
            int totalDeepSleepTime = 0;
            int totalLightSleepTime = 0;

            // Set graph start and end time based on the first and last data points in the cycle
            DateTime graphStartTime = sleepCycles
                .first.dateFrom; // Start from the first sleep stage's dateFrom
            DateTime graphEndTime = sleepCycles
                .last.dateTo; // End with the last sleep stage's dateTo
            int totalSleepDuration =
                graphEndTime.difference(graphStartTime).inMinutes;
            const int shortSleepThreshold = 360; // 6 hours

            // Iterate over sleep stages to calculate total time in each category
            for (var cycle in sleepCycles) {
              final duration =
                  cycle.dateTo.difference(cycle.dateFrom).inMinutes;
              if (cycle.type == HealthDataType.SLEEP_REM) {
                totalREMTime += duration;
              } else if (cycle.type == HealthDataType.SLEEP_AWAKE) {
                totalAwakeTime += duration;
              } else if (cycle.type == HealthDataType.SLEEP_DEEP) {
                totalDeepSleepTime += duration;
              } else if (cycle.type == HealthDataType.SLEEP_LIGHT) {
                totalLightSleepTime += duration;
              }

              totalSleepTime += duration;
            }

            // Adjust graph time for short sleep cycles by adding a buffer
            // Adjust graph time for short sleep cycles by adding a buffer if necessary
            if (totalSleepDuration < shortSleepThreshold) {
              graphStartTime = graphStartTime
                  .subtract(const Duration(minutes: 30)); // 30 minutes before
              graphEndTime = graphEndTime
                  .add(const Duration(minutes: 30)); // 30 minutes after
            } else {
              graphStartTime = graphStartTime.subtract(
                  const Duration(hours: 1)); // 1 hour before for longer cycles
              graphEndTime = graphEndTime.add(
                  const Duration(hours: 1)); // 1 hour after for longer cycles
            }

            // Sleep Score Calculation (unchanged)
            double sleepScore = calculateSleepScore(
              totalSleepTime: totalSleepTime,
              remTime: totalREMTime,
              deepTime: totalDeepSleepTime,
              awakeTime: totalAwakeTime,
            );

            // Graph X-axis calculation
            double minX = 0; // Start of the x-axis
            double maxX = graphEndTime
                .difference(graphStartTime)
                .inMinutes
                .toDouble(); // End of the x-axis
            double xInterval = totalSleepDuration < shortSleepThreshold
                ? 30
                : 120; // Smaller interval for short cycles

            // Map sleep stages to y-axis values for graph
            Map<String, double> sleepStageMap;
            List<FlSpot> sleepStageSpots;

            if (Platform.isIOS) {
              sleepStageMap = {
                "SLEEP_DEEP": 0,
                "SLEEP_LIGHT": 1,
                "SLEEP_ASLEEP": 1.5,
                "SLEEP_REM": 2,
                "SLEEP_AWAKE": 3,
                // Add any Android-specific mappings here
              };
              // Add any Android-specific mappings here

              sleepStageSpots = sleepCycles
                  .where((p) => sleepStageMap
                      .containsKey(p.type)) // Ensure p.type is a string
                  .expand((p) {
                DateTime start = p.dateFrom;
                DateTime end = p.dateTo;
                double y = sleepStageMap[p.type]!;

                // Calculate x-values relative to graphStartTime
                double startX =
                    start.difference(graphStartTime).inMinutes.toDouble();
                double endX =
                    end.difference(graphStartTime).inMinutes.toDouble();

                return [
                  FlSpot(startX, y),
                  FlSpot(endX, y),
                ];
              }).toList();
            } else {
              sleepStageMap = {
                "Unused": 2.5,
                "AWAKE (DURING SLEEP)": 3,
                "Sleep": 2.5,
                "Out-of-bed": 3,
                "LIGHT SLEEP": 1,
                "DEEP SLEEP": 0,
                "REM SLEEP": 2,
              };
              sleepStageSpots = sleepCycles
                  .where((p) => sleepStageMap
                      .containsKey(p.type)) // Ensure p.type is a string
                  .expand((p) {
                DateTime start = p.dateFrom;
                DateTime end = p.dateTo;
                double y = sleepStageMap[p.type]!;

                // Calculate x-values relative to graphStartTime
                double startX =
                    start.difference(graphStartTime).inMinutes.toDouble();
                double endX =
                    end.difference(graphStartTime).inMinutes.toDouble();

                return [
                  FlSpot(startX, y),
                  FlSpot(endX, y),
                ];
              }).toList();
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "In Bed" section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850], // Dark grey background
                      borderRadius:
                          BorderRadius.circular(15), // Border radius of 15
                      border: Border.all(
                          color: Colors.blue, width: 1), // Optional border
                    ),
                    padding:
                        const EdgeInsets.all(12), // Inner padding for content
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Display the "In Bed" time range
                              Text(
                                'In Bed: ${DateFormat("MMM d, yyyy hh:mm a").format(inBedPoint)} - ${DateFormat("hh:mm a").format(graphEndTime)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.white, // Text color
                                ),
                              ),
                              const SizedBox(height: 16.0),

                              // Calculate and display total sleep statistics
                              Builder(
                                builder: (_) {
                                  // Calculate durations in minutes
                                  int totalSleepTime = 0;
                                  int totalREMTime = 0;
                                  int totalAwakeTime = 0;
                                  int totalDeepSleepTime = 0;
                                  int totalLightSleepTime = 0;

                                  for (var cycle in sleepCycles) {
                                    final duration = cycle.dateTo
                                        .difference(cycle.dateFrom)
                                        .inMinutes;

                                    if (cycle.type == 'SLEEP_REM' ||
                                        cycle.type == 'REM SLEEP') {
                                      totalREMTime += duration;
                                    } else if (cycle.type == 'SLEEP_AWAKE' ||
                                        cycle.type == 'AWAKE (DURING SLEEP)') {
                                      totalAwakeTime += duration;
                                    } else if (cycle.type == 'SLEEP_DEEP' ||
                                        cycle.type == 'DEEP SLEEP') {
                                      totalDeepSleepTime += duration;
                                    } else if (cycle.type == 'SLEEP_LIGHT' ||
                                        cycle.type == 'LIGHT SLEEP' ||
                                        cycle.type == 'SLEEP_LIGHT') {
                                      totalLightSleepTime += duration;
                                    }
                                    totalSleepTime += duration;
                                  }

                                  // Format durations into hours and minutes
                                  String formatDuration(int minutes) {
                                    final hours = minutes ~/ 60;
                                    final mins = minutes % 60;
                                    return '${hours}h ${mins}m';
                                  }

                                  return Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              text: TextSpan(
                                                text: 'Total Sleep Time: ',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                                children: [
                                                  TextSpan(
                                                    text: formatDuration(
                                                        totalSleepTime),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                text: 'Total REM Time: ',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                                children: [
                                                  TextSpan(
                                                    text: formatDuration(
                                                        totalREMTime),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                text: 'Total Awake Time: ',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                                children: [
                                                  TextSpan(
                                                    text: formatDuration(
                                                        totalAwakeTime),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                text: 'Total Deep Sleep Time: ',
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                                children: [
                                                  TextSpan(
                                                    text: formatDuration(
                                                        totalDeepSleepTime),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            RichText(
                                              text: TextSpan(
                                                text:
                                                    'Total Light Sleep Time: ', // Change the label here
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.white),
                                                children: [
                                                  TextSpan(
                                                    text: formatDuration(
                                                        totalLightSleepTime), // Use the variable that tracks light sleep
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 1,
                                        child: Center(
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Transform.scale(
                                                scale:
                                                    1.75, // Increase the size of the progress circle
                                                child:
                                                    CircularProgressIndicator(
                                                  value: sleepScore /
                                                      100, // Sleep score as a percentage
                                                  strokeWidth:
                                                      8.0, // Keep the stroke width smaller for better aesthetics
                                                  backgroundColor:
                                                      Colors.grey[300],
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              Text(
                                                '${sleepScore.toInt()}',
                                                style: const TextStyle(
                                                  fontSize:
                                                      24, // Adjust font size for better visibility
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850], // Dark grey background
                      borderRadius:
                          BorderRadius.circular(15), // Border radius of 15
                    ),
                    padding: const EdgeInsets.only(
                        right: 8, top: 20, bottom: 8, left: 8),
                    child: SizedBox(
                      height: 200, // Adjust the height as needed
                      child: LineChart(LineChartData(
                        minX: minX, // Set the minimum value for the x-axis
                        maxX: maxX, // Set the maximum value for the x-axis
                        minY: -0.5,
                        maxY: 3.5,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              reservedSize:
                                  60, // Increase reserved size to account for padding
                              getTitlesWidget: (value, meta) {
                                // Skip showing labels at padding boundaries
                                // Make sure not to display the first 'Awake' at the top of the graph
                                if (value < 0) {
                                  return const SizedBox
                                      .shrink(); // Remove the first "Awake"
                                } else if (value > 3) {
                                  return const SizedBox
                                      .shrink(); // Remove the last "Deep"
                                }
                                switch (value.toInt()) {
                                  case 0:
                                    return const Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Text('Deep',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white)),
                                    );
                                  case 1:
                                    return const Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Text('Light',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white)),
                                    );
                                  case 2:
                                    return const Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Text('REM',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white)),
                                    );
                                  case 3:
                                    return const Padding(
                                      padding: EdgeInsets.only(left: 10.0),
                                      child: Text('Awake',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white)),
                                    );
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles:
                                  false, // Removes the numbers at the top of the X-axis
                            ),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false, // Removes right-side labels
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: xInterval, // Dynamically set interval
                              getTitlesWidget: (value, meta) {
                                if ((value / xInterval) % 2 != 0) {
                                  return const SizedBox.shrink();
                                }

                                DateTime time = graphStartTime
                                    .add(Duration(minutes: value.toInt()));
                                return Text(
                                  DateFormat('h:mm a')
                                      .format(time), // Format as '12:30 AM'
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.white),
                                );
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            right: BorderSide(
                                width: 20,
                                color: Colors.transparent), // Adjust border
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: sleepStageSpots,
                            isCurved:
                                false, // Keeps the line straight; set to true for a curved line
                            barWidth: 2, // Thickness of the line
                            color: Colors.blue, // Color of the line
                            dotData: const FlDotData(
                              show: false,
                            ),
                            // Ensures no dots are shown on the line
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  ColorTween(
                                          begin: Colors.grey, end: Colors.grey)
                                      .lerp(0.2)!
                                      .withOpacity(0.1),
                                  ColorTween(
                                          begin: Colors.grey, end: Colors.grey)
                                      .lerp(0.2)!
                                      .withOpacity(0.1),
                                ],
                              ),
                            ),
                          ),
                        ],
                        gridData: FlGridData(
                          show: true,
                          drawHorizontalLine: true,
                          drawVerticalLine: true,
                          horizontalInterval: 1, // Spacing for horizontal lines
                          verticalInterval:
                              (totalSleepDuration < shortSleepThreshold)
                                  ? 30
                                  : 60,
                          getDrawingHorizontalLine: (value) {
                            if (value == -0.5 || value == 2.5)
                              return FlLine(strokeWidth: 0); // Skip outer lines
                            return FlLine(
                                color: Colors.white.withOpacity(0.2),
                                strokeWidth: 1);
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                                color: Colors.white.withOpacity(0.2),
                                strokeWidth: 1);
                          },
                        ),
                      )),
                    ),
                  ),
                ), // List of sleep cycles
                const SizedBox(height: 16),
                ExpansionTile(
                  title: const Text(
                    "Details",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  children: sleepCycles.map((p) {
                    final durationInMinutes =
                        p.dateTo.difference(p.dateFrom).inMinutes;

                    return ListTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat("MMM dd / hh:mm a").format(p.dateFrom)} - ${DateFormat("MMM dd / hh:mm a").format(p.dateTo)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            '${formattedTypeString(p.type)}: $durationInMinutes mins',
                            style: const TextStyle(
                              fontWeight: FontWeight.normal,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              ],
            );
          }).toList(),
          ListView.builder(
            shrinkWrap: true, // Ensures the ListView takes up minimum space
            physics:
                const NeverScrollableScrollPhysics(), // Prevents scrolling inside ListView
            itemCount: _healthDataList.length,
            itemBuilder: (context, index) {
              final dataPoint = _healthDataList[index];
              return HealthDataPointWidget(dataPoint: dataPoint);
            },
          ),
        ],
      ),
    );
  }

  final Widget _contentNoData = const Text('No Data to show');

  final Widget _contentNotFetched =
      const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Text("Press 'Auth' to get permissions to access health data."),
    Text("Press 'Fetch Data' to get health data."),
    Text("Press 'Add Data' to add some random health data."),
    Text("Press 'Delete Data' to remove some random health data."),
  ]);

  final Widget _authorized = const Text('Authorization granted!');

  final Widget _authorizationNotGranted = const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Text('Authorization not given.'),
      Text(
          'For Google Fit please check your OAUTH2 client ID is correct in Google Developer Console.'),
      Text(
          'For Google Health Connect please check if you have added the right permissions and services to the manifest file.'),
      Text('For Apple Health check your permissions in Apple Health.'),
    ],
  );

  final Widget _contentHealthConnectStatus = const Text(
      'No status, click getHealthConnectSdkStatus to get the status.');

  final Widget _dataAdded = const Text('Data points inserted successfully.');

  final Widget _dataDeleted = const Text('Data points deleted successfully.');

  Widget get _stepsFetched => Text('Total number of steps: $_nofSteps.');

  final Widget _dataNotAdded =
      const Text('Failed to add data.\nDo you have permissions to add data?');

  final Widget _dataNotDeleted = const Text('Failed to delete data');

  Widget get _content => switch (_state) {
        AppState.dataReady => _contentDataReady,
        AppState.dataNotFetched => _contentNotFetched,
        AppState.fetchingData => _contentFetchingData,
        AppState.noData => _contentNoData,
        AppState.authorized => _authorized,
        AppState.authNotGranted => _authorizationNotGranted,
        AppState.dataAdded => _dataAdded,
        AppState.dataDeleted => _dataDeleted,
        AppState.dataNotAdded => _dataNotAdded,
        AppState.dataNotDeleted => _dataNotDeleted,
        AppState.stepsReady => _stepsFetched,
        AppState.healthConnectedStatus => _contentHealthConnectStatus,
      };
}

List<HealthDataType> get dataTypesIOS => [
      HealthDataType.HEIGHT,
      HealthDataType.WEIGHT,
      HealthDataType.GENDER,
      HealthDataType.WATER,
      HealthDataType.BIRTH_DATE,
      HealthDataType.HEART_RATE,
      HealthDataType.BODY_TEMPERATURE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_IN_BED,
    ];

List<HealthDataType> get dataTypesAndroid => [
      HealthDataType.HEIGHT,
      HealthDataType.WEIGHT,
      HealthDataType.HEART_RATE,
      HealthDataType.BODY_TEMPERATURE,
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_LIGHT,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_SESSION,
    ];
