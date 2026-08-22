import 'package:equatable/equatable.dart';

/// A scheduled appointment, stored at `pregnancies/{pid}/appointments/{id}`.
class Appointment extends Equatable {
  const Appointment({
    required this.id,
    required this.title,
    required this.dateTime,
    this.doctorName,
    this.hospital,
    this.notes,
    this.reminderMinutesBefore = 120,
    this.status = 'upcoming',
  });

  final String id;
  final String title;
  final DateTime dateTime;
  final String? doctorName;
  final String? hospital;
  final String? notes;
  final int reminderMinutesBefore;
  final String status; // upcoming | done | cancelled

  bool get isUpcoming =>
      status == 'upcoming' && dateTime.isAfter(DateTime.now());

  DateTime get reminderTime =>
      dateTime.subtract(Duration(minutes: reminderMinutesBefore));

  Appointment copyWith({String? status}) => Appointment(
        id: id,
        title: title,
        dateTime: dateTime,
        doctorName: doctorName,
        hospital: hospital,
        notes: notes,
        reminderMinutesBefore: reminderMinutesBefore,
        status: status ?? this.status,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateTime': dateTime.toUtc().toIso8601String(),
        'doctorName': doctorName,
        'hospital': hospital,
        'notes': notes,
        'reminderMinutesBefore': reminderMinutesBefore,
        'status': status,
      };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Appointment',
        dateTime: DateTime.parse(json['dateTime'] as String),
        doctorName: json['doctorName'] as String?,
        hospital: json['hospital'] as String?,
        notes: json['notes'] as String?,
        reminderMinutesBefore:
            (json['reminderMinutesBefore'] as num?)?.toInt() ?? 120,
        status: json['status'] as String? ?? 'upcoming',
      );

  @override
  List<Object?> get props => [id, title, dateTime, status];
}
