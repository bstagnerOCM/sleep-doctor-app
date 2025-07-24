import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'health_data_point.dart' as custom_health;

class HealthDataPointWidget extends StatelessWidget {
  final custom_health.CustomHealthDataPoint dataPoint;

  const HealthDataPointWidget({Key? key, required this.dataPoint})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Format the start and end times
    String formattedStartTime =
        DateFormat("MMM d, yyyy hh:mm a").format(dataPoint.dateFrom);
    String formattedEndTime =
        DateFormat("MMM d, yyyy hh:mm a").format(dataPoint.dateTo);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Text
          Text(
            dataPoint.type,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Adjust color as needed
            ),
          ),
          const SizedBox(height: 4),
          // Start Time Text
          Text(
            'Start: $formattedStartTime',
            style: const TextStyle(
              fontSize: 8,
              color: Colors.black, // Adjust color as needed
            ),
          ),
          // End Time Text
          Text(
            'End: $formattedEndTime',
            style: const TextStyle(
              fontSize: 8,
              color: Colors.black, // Adjust color as needed
            ),
          ),
        ],
      ),
    );
  }
}
