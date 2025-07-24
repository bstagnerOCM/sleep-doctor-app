package com.sleepdoctor.sleep_doctor

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.util.Log // For logging
import androidx.annotation.NonNull
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.fitness.Fitness
import com.google.android.gms.fitness.FitnessActivities
import com.google.android.gms.fitness.FitnessOptions
import com.google.android.gms.fitness.data.DataSet
import com.google.android.gms.fitness.data.DataSource // Ensure this is imported
import com.google.android.gms.fitness.data.DataType
import com.google.android.gms.fitness.data.Field
import com.google.android.gms.fitness.data.DataPoint
import com.google.android.gms.fitness.request.DataReadRequest
import com.google.android.gms.fitness.request.SessionReadRequest
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.time.ZonedDateTime
import java.util.concurrent.TimeUnit


class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sleepdoctor.app/healthdata"
    private val GOOGLE_FIT_PERMISSIONS_REQUEST_CODE = 1001

    private var pendingResult: MethodChannel.Result? = null
    private var pendingMethod: String? = null

    private val fitnessOptions by lazy {
        FitnessOptions.builder()
            // Steps
            .addDataType(DataType.TYPE_STEP_COUNT_DELTA, FitnessOptions.ACCESS_READ)
            // Height, Weight, Heart Rate
            .addDataType(DataType.TYPE_HEIGHT, FitnessOptions.ACCESS_READ)
            .addDataType(DataType.TYPE_WEIGHT, FitnessOptions.ACCESS_READ)
            .addDataType(DataType.TYPE_HEART_RATE_BPM, FitnessOptions.ACCESS_READ)
            // Sleep - Read and Write Permissions
            .addDataType(DataType.TYPE_SLEEP_SEGMENT, FitnessOptions.ACCESS_READ)
            .addDataType(DataType.TYPE_SLEEP_SEGMENT, FitnessOptions.ACCESS_WRITE)
            .build()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSleepData" -> {
                    pendingResult = result
                    pendingMethod = call.method
                    checkPermissionsAndRun()
                }
                "getBodyData" -> {
                    pendingResult = result
                    pendingMethod = call.method
                    checkPermissionsAndRun()
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkPermissionsAndRun() {
        val account = GoogleSignIn.getLastSignedInAccount(this)
        if (!GoogleSignIn.hasPermissions(account, fitnessOptions)) {
            GoogleSignIn.requestPermissions(
                this,
                GOOGLE_FIT_PERMISSIONS_REQUEST_CODE,
                account,
                fitnessOptions
            )
        } else {
            // Permissions granted, proceed based on requested method
            runPendingMethod()
        }
    }

    private fun runPendingMethod() {
        when (pendingMethod) {
            "getSteps" -> accessGoogleFitSteps()
            "getSleepData" -> accessSleepData() // Updated method
            "getBodyData" -> accessBodyData()
            else -> {
                pendingResult?.notImplemented()
                pendingResult = null
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == GOOGLE_FIT_PERMISSIONS_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                runPendingMethod()
            } else {
                // Permission denied
                pendingResult?.error("PERMISSION_DENIED", "Google Fit permission denied", null)
                pendingResult = null
            }
        }
    }

    private fun accessGoogleFitSteps() {
        val account = GoogleSignIn.getAccountForExtension(this, fitnessOptions)
        val end = ZonedDateTime.now()
        val start = end.minusDays(1)

        val readRequest = DataReadRequest.Builder()
            .aggregate(DataType.TYPE_STEP_COUNT_DELTA, DataType.AGGREGATE_STEP_COUNT_DELTA)
            .bucketByTime(1, TimeUnit.DAYS)
            .setTimeRange(start.toEpochSecond(), end.toEpochSecond(), TimeUnit.SECONDS)
            .build()

        Fitness.getHistoryClient(this, account)
            .readData(readRequest)
            .addOnSuccessListener { response ->
                Log.d("MainActivity", "Inside onSuccessListener for Sleep.")
                var totalSteps = 0
                if (response.buckets.isNotEmpty()) {
                    for (bucket in response.buckets) {
                        for (dataSet in bucket.dataSets) {
                            for (dp in dataSet.dataPoints) {
                                val steps = dp.getValue(Field.FIELD_STEPS).asInt()
                                totalSteps += steps
                            }
                        }
                    }
                }
                pendingResult?.success(totalSteps)
                pendingResult = null
            }
            .addOnFailureListener { e ->
                pendingResult?.error("READ_ERROR", "Failed to read steps: ${e.message}", null)
                pendingResult = null
            }
             .addOnCompleteListener {
                Log.d("MainActivity", "Inside onCompleteListener for Sleep.")
            }
    }

private fun accessSleepData() {
    val account = GoogleSignIn.getAccountForExtension(this, fitnessOptions)
    val endTime = ZonedDateTime.now()
    val startTime = endTime.minusDays(30) // Adjust the time range as needed

    // Define the sleep stage names array
    val SLEEP_STAGE_NAMES = arrayOf(
        "Unused",                  // 0
        "Awake (during sleep)",    // 1
        "Sleep",                   // 2
        "Out-of-bed",              // 3
        "Light sleep",             // 4
        "Deep sleep",              // 5
        "REM sleep"                // 6
    )

    val request = DataReadRequest.Builder()
        .read(DataType.TYPE_SLEEP_SEGMENT)
        .setTimeRange(startTime.toEpochSecond(), endTime.toEpochSecond(), TimeUnit.SECONDS)
        .build()

    Fitness.getHistoryClient(this, account)
        .readData(request)
        .addOnSuccessListener { response ->
            val sleepData = mutableListOf<Map<String, Any>>()

            val allDataSets = response.getDataSets()
            val sleepDataSets = allDataSets.filter { it.dataType == DataType.TYPE_SLEEP_SEGMENT }

            // Log.i("MainActivity", "Sleep DataSets count: ${sleepDataSets.size}")

            // if (sleepDataSets.isEmpty()) {
            //     Log.w("MainActivity", "No sleep data found for the specified time range.")
            // }

            for (dataSet in sleepDataSets) {
                // Log.i("MainActivity", "Processing DataSet: ${dataSet.dataType.name}")
                // Log.i("MainActivity", "DataPoints count: ${dataSet.dataPoints.size}")

                for (dataPoint in dataSet.dataPoints) {
                    // Log.i("MainActivity", "DataPoint: $dataPoint")

                    // Safely handle nullable values
                    val sleepStageVal = dataPoint.getValue(Field.FIELD_SLEEP_SEGMENT_TYPE)?.asInt() ?: -1
                    val sleepStage = if (sleepStageVal in SLEEP_STAGE_NAMES.indices) {
                        SLEEP_STAGE_NAMES[sleepStageVal]
                    } else {
                        "Unknown"
                    }
                    val segmentStart = dataPoint.getStartTime(TimeUnit.MILLISECONDS)
                    val segmentEnd = dataPoint.getEndTime(TimeUnit.MILLISECONDS)

                    // Log.i(
                    //     "MainActivity",
                    //     "\t* Stage: $sleepStage between $segmentStart and $segmentEnd"
                    // )

                    // Add the sleep stage data to the list
                    val segmentMap = mapOf(
                        "type" to sleepStage, // Include sleep stage type
                        "startTime" to segmentStart,
                        "endTime" to segmentEnd
                    )
                    sleepData.add(segmentMap)
                }
            }

            // Log the total number of sleep data points found
            // Log.i("MainActivity", "Total sleep data points collected: ${sleepData.size}")

            // Return the structured sleep data to Flutter
            pendingResult?.success(sleepData)
            pendingResult = null
        }
        .addOnFailureListener { e ->
            Log.e("MainActivity", "Failed to read sleep data: ${e.message}")
            pendingResult?.error("SLEEP_READ_ERROR", "Failed to read sleep data: ${e.message}", null)
            pendingResult = null
        }
}

    private fun accessBodyData() {
        val account = GoogleSignIn.getAccountForExtension(this, fitnessOptions)
        val end = ZonedDateTime.now()
        val start = end.minusDays(30) // last 30 days for example

        // We'll read height, weight, and heart rate data from the past 30 days.
        // For simplicity, we will read each data type separately and combine them.
        // You could also aggregate or process them as needed.

        val dataTypes = listOf(
            Pair(DataType.TYPE_HEIGHT, "height"),
            Pair(DataType.TYPE_WEIGHT, "weight"),
        )

        val bodyData = mutableListOf<Map<String, Any>>()

        fun readNext(index: Int) {
            if (index >= dataTypes.size) {
                // All data types read, return the result
                pendingResult?.success(bodyData)
                pendingResult = null
                return
            }

            val (dataType, label) = dataTypes[index]
            val request = DataReadRequest.Builder()
                .read(dataType)
                .setTimeRange(start.toEpochSecond(), end.toEpochSecond(), TimeUnit.SECONDS)
                .build()

            Fitness.getHistoryClient(this, account)
                .readData(request)
                .addOnSuccessListener { response ->
                    for (dataSet in response.dataSets) {
                        for (dp in dataSet.dataPoints) {
                            val value = dp.getValue(dp.dataType.fields[0])
                            val timestamp = dp.getStartTime(TimeUnit.SECONDS) // when this measurement was recorded

                            val measurement = mapOf(
                                "type" to label,
                                "value" to value.toString(),
                                "timestamp" to timestamp
                            )
                            bodyData.add(measurement)
                        }
                    }
                    readNext(index + 1)
                }
                .addOnFailureListener { e ->
                    // If one fails, we still return what we have
                    pendingResult?.error("BODY_READ_ERROR", "Failed to read $label data: ${e.message}", null)
                    pendingResult = null
                }
        }

        // Start reading data types one by one
        readNext(0)
    }
}