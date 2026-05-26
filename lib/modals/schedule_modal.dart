import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/button.dart';
import '../core/theme/app_colors.dart';
import '../service/Schedule_service.dart';
import '../widgets/center_toast.dart';
import '../providers/course_provider.dart';
import '../providers/assessment_provider.dart';

Future<void> showCreateScheduleModal(
  BuildContext context, {
  required void Function(Map<String, dynamic> schedule) onSubmit,
  Map<String, dynamic>? initialData,
  String title = 'Create Schedule',
  String? scheduleId,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: Provider.of<CourseProvider>(context, listen: false),
        ),
        ChangeNotifierProvider.value(
          value: Provider.of<AssessmentProvider>(context, listen: false),
        ),
      ],

      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _CreateScheduleDialog(
          onSubmit: onSubmit,
          initialData: initialData,
          title: title,
          scheduleId: scheduleId,
        ),
      ),
    ),
  );
}

class _CreateScheduleDialog extends StatefulWidget {
  final void Function(Map<String, dynamic> schedule) onSubmit;
  final Map<String, dynamic>? initialData;
  final String title;
  final String? scheduleId;

  const _CreateScheduleDialog({
    required this.onSubmit,
    this.initialData,
    required this.title,
    this.scheduleId,
  });

  @override
  State<_CreateScheduleDialog> createState() => _CreateScheduleDialogState();
}

class _CreateScheduleDialogState extends State<_CreateScheduleDialog> {
  String? _selectedCourseCode;
  String? _selectedAssessmentName;
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final ScheduleService _scheduleService = ScheduleService();

  String _recurrenceType = 'NONE';
  DateTime? _date;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final Set<String> _weeklyDays = {};
  final List<DateTime> _monthlyDates = [];
  String? _errorMessage;
  Color _selectedColor = const Color(0xFF2E7D32);
  int? _selectedReminder = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _selectedCourseCode = widget.initialData!['courseCode'] as String?;
      _selectedAssessmentName =
          widget.initialData!['assessmentName'] as String?;
      _locationController.text =
          widget.initialData!['location'] as String? ?? '';
      _startTimeController.text =
          widget.initialData!['startTime'] as String? ?? '';
      _endTimeController.text = widget.initialData!['endTime'] as String? ?? '';

      if (_startTimeController.text.isNotEmpty) {
        _startTime = _parseTime(_startTimeController.text);
      }
      if (_endTimeController.text.isNotEmpty) {
        _endTime = _parseTime(_endTimeController.text);
      }
    }
  }

  TimeOfDay? _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  final List<Color> _colorOptions = [
    const Color(0xFF2E7D32),
    const Color(0xFF1565C0),
    const Color(0xFFE65100),
    const Color(0xFF6A1B9A),
    const Color(0xFFC62828),
    const Color(0xFF00838F),
  ];

  final List<Map<String, dynamic>> _reminderOptions = [
    {'label': 'None', 'value': 0},
    {'label': '5 minutes before', 'value': 5},
    {'label': '10 minutes before', 'value': 10},
    {'label': '15 minutes before', 'value': 15},
    {'label': '30 minutes before', 'value': 30},
    {'label': '1 hour before', 'value': 60},
  ];

  static const List<String> _weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _dateController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDate({
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
  }

  String _buildDateLabel(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _buildTimeLabel(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute $period';
  }

  String _formatTimeForPayload(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _buildIsoDateTime(DateTime date, TimeOfDay time) {
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return dt.toIso8601String();
  }

  bool _validate() {
    if (_selectedCourseCode == null || _selectedCourseCode!.isEmpty) {
      _errorMessage = 'Course code is required.';
      return false;
    }
    if (_selectedAssessmentName == null || _selectedAssessmentName!.isEmpty) {
      _errorMessage = 'Assessment name is required.';
      return false;
    }
    if (_locationController.text.trim().isEmpty) {
      _errorMessage = 'Location is required.';
      return false;
    }
    if (_startTime == null || _endTime == null) {
      _errorMessage = 'Start time and end time are required.';
      return false;
    }
    if (_recurrenceType == 'NONE') {
      if (_date == null) {
        _errorMessage = 'Date is required for one-time schedules.';
        return false;
      }
    } else {
      if (_startDate == null || _endDate == null) {
        _errorMessage = 'Start date and end date are required.';
        return false;
      }
      if (_endDate!.isBefore(_startDate!)) {
        _errorMessage = 'End date must be on or after start date.';
        return false;
      }
      if (_recurrenceType == 'WEEKLY' && _weeklyDays.isEmpty) {
        _errorMessage = 'Select at least one day of the week.';
        return false;
      }
      if (_recurrenceType == 'MONTHLY' && _monthlyDates.isEmpty) {
        _errorMessage = 'Add at least one monthly date.';
        return false;
      }
    }

    _errorMessage = null;
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) {
      setState(() {});
      return;
    }
    try {
      DateTime baseDate;
      if (_recurrenceType == 'NONE') {
        baseDate = _date!;
      } else if (_recurrenceType == 'MONTHLY' && _monthlyDates.isNotEmpty) {
        baseDate = _monthlyDates.first;
      } else {
        baseDate = _startDate!;
      }
      String message;

      if (widget.scheduleId != null) {
        // EDIT mode
        message = await _scheduleService.editSchedule(
          scheduleId: widget.scheduleId!,
          courseCode: _selectedCourseCode!,
          assessmentName: _selectedAssessmentName!,
          location: _locationController.text.trim(),
          startTime: _buildIsoDateTime(baseDate, _startTime!),
          endTime: _buildIsoDateTime(baseDate, _endTime!),
          color: _selectedColor.value.toRadixString(16),
          reminder: _selectedReminder ?? 0,
          recurrenceType: _recurrenceType,
          date: _date?.toIso8601String(),
          startDate: _startDate?.toIso8601String(),
          endDate: _endDate?.toIso8601String(),
          selectedDays: _recurrenceType == 'WEEKLY' ? _weeklyDays.toList() : [],
        );
      } else {
        // CREATE mode
        message = await _scheduleService.createSchedule(
          courseCode: _selectedCourseCode!,
          assessmentName: _selectedAssessmentName!,
          location: _locationController.text.trim(),
          startTime: _buildIsoDateTime(baseDate, _startTime!),
          endTime: _buildIsoDateTime(baseDate, _endTime!),
          color: _selectedColor.value.toRadixString(16),
          reminder: _selectedReminder ?? 0,
          recurrenceType: _recurrenceType,
          date: _date?.toIso8601String(),
          startDate: _startDate?.toIso8601String(),
          endDate: _endDate?.toIso8601String(),
          selectedDays: _recurrenceType == 'WEEKLY'
              ? _weeklyDays.toList()
              : _recurrenceType == 'MONTHLY'
              ? _monthlyDates.map((d) => _buildDateLabel(d)).toList()
              : [],
        );
      }

      debugPrint(message);
      CenterToast.show(
        context,
        message: widget.scheduleId != null
            ? "Schedule updated successfully"
            : "Schedule created successfully",
        icon: Icons.check_circle,
        color: Colors.green,
      );

      final schedule = {
        'courseCode': _selectedCourseCode,
        'courseName': _selectedAssessmentName,
        'assessmentName': _selectedAssessmentName,
        'location': _locationController.text.trim(),
        'startTime': _formatTimeForPayload(_startTime!),
        'endTime': _formatTimeForPayload(_endTime!),
        'date': _date?.toIso8601String(),
        'startDate': _startDate?.toIso8601String(),
        'endDate': _endDate?.toIso8601String(),
        'color': _selectedColor.value.toRadixString(16),
        'recurrenceType': _recurrenceType,
        'reminder': _selectedReminder ?? 0,
        'selectedDays': _recurrenceType == 'WEEKLY' ? _weeklyDays.toList() : [],
      };

      widget.onSubmit(schedule);
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e, stackTrace) {
      debugPrint("SCHEDULE FAILED:");
      debugPrint("ERROR: $e");
      debugPrint("STACK TRACE: $stackTrace");
      String errorMessage = e.toString();
      if (errorMessage.startsWith("Exception: ")) {
        errorMessage = errorMessage.replaceFirst("Exception: ", "");
      }
      if (errorMessage == "SESSION_EXPIRED") {
        errorMessage = "Session expired. Please login again.";
      }
      setState(() {
        _errorMessage = errorMessage;
      });
    }
  }

  Widget _buildDateField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    controller.text.isEmpty ? 'Select $label' : controller.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: controller.text.isEmpty
                          ? AppColors.caption
                          : AppColors.darkText,
                    ),
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrenceControls() {
    switch (_recurrenceType) {
      case 'NONE':
        return _buildDateField(
          label: 'Date',
          controller: _dateController,
          onTap: () async {
            final date = await _pickDate(
              initialDate: _date ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (date != null) {
              setState(() {
                _date = date;
                _dateController.text = _buildDateLabel(date);
              });
            }
          },
        );
      case 'DAILY':
        return Column(
          children: [
            _buildDateField(
              label: 'Start Date',
              controller: _startDateController,
              onTap: () async {
                final date = await _pickDate(
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                    _startDateController.text = _buildDateLabel(date);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            _buildDateField(
              label: 'End Date',
              controller: _endDateController,
              onTap: () async {
                final date = await _pickDate(
                  initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                    _endDateController.text = _buildDateLabel(date);
                  });
                }
              },
            ),
          ],
        );
      case 'WEEKLY':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateField(
              label: 'Start Date',
              controller: _startDateController,
              onTap: () async {
                final date = await _pickDate(
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                    _startDateController.text = _buildDateLabel(date);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            _buildDateField(
              label: 'End Date',
              controller: _endDateController,
              onTap: () async {
                final date = await _pickDate(
                  initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                    _endDateController.text = _buildDateLabel(date);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            const Text(
              'Select days',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _weekDays.map((day) {
                final selected = _weeklyDays.contains(day);
                return ChoiceChip(
                  label: Text(day),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      if (selected) {
                        _weeklyDays.remove(day);
                      } else {
                        _weeklyDays.add(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      case 'MONTHLY':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDateField(
              label: 'Start Date',
              controller: _startDateController,
              onTap: () async {
                final date = await _pickDate(
                  initialDate: _startDate ?? DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _startDate = date;
                    _startDateController.text = _buildDateLabel(date);
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            _buildDateField(
              label: 'End Date',
              controller: _endDateController,
              onTap: () async {
                final date = await _pickDate(
                  initialDate: _endDate ?? (_startDate ?? DateTime.now()),
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() {
                    _endDate = date;
                    _endDateController.text = _buildDateLabel(date);
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Monthly dates',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final date = await _pickDate(
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(
                        const Duration(days: 365 * 5),
                      ),
                    );
                    if (date != null) {
                      setState(() {
                        if (!_monthlyDates.any(
                          (d) => d.day == date.day && d.month == date.month,
                        )) {
                          _monthlyDates.add(date);
                        }
                      });
                    }
                  },
                  child: const Text('Add date'),
                ),
              ],
            ),
            if (_monthlyDates.isEmpty)
              const Text(
                'Pick one or more dates like 14 Feb or 16 Jul.',
                style: TextStyle(color: AppColors.caption),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _monthlyDates.map((date) {
                return InputChip(
                  label: Text(_buildDateLabel(date)),
                  onDeleted: () {
                    setState(() {
                      _monthlyDates.remove(date);
                    });
                  },
                );
              }).toList(),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final assessmentProvider = Provider.of<AssessmentProvider>(context);

    final courseCodeList = courseProvider.courseCodes.toSet().toList();
    final assessmentNameList = assessmentProvider.assessmentName
        .toSet()
        .toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Course Code Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Course Code',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: courseCodeList.contains(_selectedCourseCode)
                        ? _selectedCourseCode
                        : null,
                    items: courseCodeList
                        .map(
                          (course) => DropdownMenuItem(
                            value: course,
                            child: Text(
                              course,
                              style: const TextStyle(color: AppColors.darkText),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) async {
                      if (value == null) return;

                      setState(() {
                        _selectedCourseCode = value;
                        _selectedAssessmentName = null;
                        _errorMessage = null;
                      });

                      final assessmentProvider =
                          Provider.of<AssessmentProvider>(
                            context,
                            listen: false,
                          );
                      assessmentProvider.clearAssessments();
                      await assessmentProvider.loadAssessments(value);
                    },
                    hint: const Text('Select a course'),
                    isExpanded: true,
                    underline: const SizedBox(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Assessment Name Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assessment Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: assessmentNameList.contains(_selectedAssessmentName)
                        ? _selectedAssessmentName
                        : null,
                    items: assessmentNameList
                        .map(
                          (assessment) => DropdownMenuItem(
                            value: assessment,
                            child: Text(
                              assessment,
                              style: const TextStyle(color: AppColors.darkText),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAssessmentName = value;
                        _errorMessage = null;
                      });
                    },
                    hint: const Text(
                      'Select an assessment',
                      style: TextStyle(color: AppColors.caption),
                    ),
                    isExpanded: true,
                    underline: const SizedBox(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Location TextField
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                _buildBorderedTextField(
                  controller: _locationController,
                  hint: 'Enter a location',
                  icon: Icons.location_on,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Start and End Time
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime:
                                _startTime ??
                                const TimeOfDay(hour: 9, minute: 0),
                          );
                          if (time != null) {
                            setState(() {
                              _startTime = time;
                              _startTimeController.text = _buildTimeLabel(time);
                            });
                          }
                        },
                        child: _buildBorderedTimeDisplay(
                          label: _startTime != null
                              ? _buildTimeLabel(_startTime!)
                              : 'Select time',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'End Time',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime:
                                _endTime ??
                                const TimeOfDay(hour: 10, minute: 0),
                          );
                          if (time != null) {
                            setState(() {
                              _endTime = time;
                              _endTimeController.text = _buildTimeLabel(time);
                            });
                          }
                        },
                        child: _buildBorderedTimeDisplay(
                          label: _endTime != null
                              ? _buildTimeLabel(_endTime!)
                              : 'Select time',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recurrence Type Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recurrence Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _recurrenceType,
                    items: ['NONE', 'DAILY', 'WEEKLY', 'MONTHLY']
                        .map(
                          (option) => DropdownMenuItem(
                            value: option,
                            child: Text(
                              option[0].toUpperCase() + option.substring(1),
                              style: const TextStyle(color: AppColors.darkText),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _recurrenceType = value;
                        _errorMessage = null;
                      });
                    },
                    isExpanded: true,
                    underline: const SizedBox(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recurrence Controls
            _buildRecurrenceControls(),

            const SizedBox(height: 16),
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _colorOptions.map((color) {
                final isSelected = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 2.5)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'Reminder',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<int>(
                value: _selectedReminder,
                hint: Row(
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'No reminder',
                      style: TextStyle(color: AppColors.caption),
                    ),
                  ],
                ),
                isExpanded: true,
                underline: const SizedBox(),
                items: _reminderOptions.map((option) {
                  return DropdownMenuItem<int>(
                    value: option['value'] as int,
                    child: Text(
                      option['label'] as String,
                      style: const TextStyle(color: AppColors.darkText),
                    ),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedReminder = value),
              ),
            ),

            // Error Message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 14),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Save Button
            AppButton(text: 'Save Schedule', onPressed: _submit),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /// Build a bordered text field with OTP-like style
  Widget _buildBorderedTextField({
    required TextEditingController controller,
    required String hint,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.caption),
          prefixIcon: icon != null
              ? Icon(icon, size: 20, color: AppColors.primary)
              : null,
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
        style: const TextStyle(color: AppColors.darkText),
      ),
    );
  }

  /// Build a bordered time display (read-only)
  Widget _buildBorderedTimeDisplay({required String label}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.schedule, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: label == 'Select time'
                  ? AppColors.caption
                  : AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }
}
