import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../widgets/button.dart';
import '../core/theme/app_colors.dart';
import '../service/schedule_service.dart';
import '../service/course_service.dart';
import '../widgets/center_toast.dart';
import '../widgets/loading.dart';

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
    builder: (ctx) => Dialog(
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
  // Course fields
  final _courseNameController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _courseDescriptionController = TextEditingController();

  // Schedule fields
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();

  final ScheduleService _scheduleService = ScheduleService();
  final CourseService _courseService = CourseService();

  // Image picker
  File? _selectedCourseImage;
  final ImagePicker _imagePicker = ImagePicker();

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

  bool get _isEditing => widget.scheduleId != null;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _courseCodeController.text =
          widget.initialData!['courseCode'] as String? ?? '';
      _courseNameController.text =
          widget.initialData!['courseName'] as String? ?? '';
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

  int? _toMinutes(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    final dt = DateTime.tryParse(isoString);
    if (dt != null) return dt.hour * 60 + dt.minute;
    final parts = isoString.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h != null && m != null) return h * 60 + m;
    }
    return null;
  }

  Future<void> _pickCourseImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image != null) {
      setState(() => _selectedCourseImage = File(image.path));
    }
  }

  Future<bool> _checkOverlapAndConfirm() async {
    try {
      final existing = await _scheduleService.getMySchedules();
      if (existing.isEmpty) return true;

      final newStartMin = _startTime!.hour * 60 + _startTime!.minute;
      final newEndMin = _endTime!.hour * 60 + _endTime!.minute;

      bool hasOverlap = false;
      for (final s in existing) {
        if (widget.scheduleId != null && s['scheduleId'] == widget.scheduleId) {
          continue;
        }

        final existStartMin = _toMinutes(s['startTime'] as String?);
        final existEndMin = _toMinutes(s['endTime'] as String?);
        if (existStartMin == null || existEndMin == null) continue;

        final overlaps = newStartMin < existEndMin && newEndMin > existStartMin;
        if (overlaps) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) return true;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Schedule Conflict',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  'This schedule overlaps with an existing one. Are you sure you want to continue?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      return confirmed == true;
    } catch (_) {
      return true;
    }
  }

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
    _courseNameController.dispose();
    _courseCodeController.dispose();
    _courseDescriptionController.dispose();
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
    if (_courseCodeController.text.trim().isEmpty) {
      _errorMessage = 'Course code is required.';
      return false;
    }
    if (_courseNameController.text.trim().isEmpty) {
      _errorMessage = 'Course name is required.';
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
      final courseCode = _courseCodeController.text.trim();
      final courseName = _courseNameController.text.trim();
      final description = _courseDescriptionController.text.trim();

      // ── Step 1: Create OR edit course ────────────────────────────────
      if (_isEditing) {
        await _courseService.editCourse(
          courseCode: courseCode,
          courseName: courseName,
          newCourseCode: courseCode,
          description: description.isNotEmpty ? description : null,
        );
      } else {
        await _courseService.createCourse(
          courseCode: courseCode,
          courseName: courseName,
          description: description.isNotEmpty ? description : null,
        );
      }

      // ── Step 2: Upload course image if selected ───────────────────────
      if (_selectedCourseImage != null) {
        try {
          await _courseService.uploadCourseImage(
            courseCode: courseCode,
            imageFile: _selectedCourseImage!,
          );
        } catch (e) {
          debugPrint('Course image upload failed: $e');
        }
      }

      // ── Step 3: Check for schedule overlap ───────────────────────────
      final shouldProceed = await _checkOverlapAndConfirm();
      if (!shouldProceed) return;

      // ── Step 4: Create or edit schedule ──────────────────────────────
      DateTime baseDate;
      if (_recurrenceType == 'NONE') {
        baseDate = _date!;
      } else if (_recurrenceType == 'MONTHLY' && _monthlyDates.isNotEmpty) {
        baseDate = _monthlyDates.first;
      } else {
        baseDate = _startDate!;
      }

      String message;
      if (_isEditing) {
        message = await _scheduleService.editSchedule(
          scheduleId: widget.scheduleId!,
          courseCode: courseCode,
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
        message = await _scheduleService.createSchedule(
          courseCode: courseCode,
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
        message: _isEditing
            ? 'Course saved successfully'
            : 'Schedule created successfully',
        icon: Icons.check_circle,
        color: Colors.green,
      );

      final schedule = {
        'courseCode': courseCode,
        'courseName': courseName,
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

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSubmit(schedule);
    } catch (e, stackTrace) {
      debugPrint('SUBMIT FAILED:');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      if (errorMessage == 'SESSION_EXPIRED') {
        errorMessage = 'Session expired. Please login again.';
      }
      setState(() {
        _errorMessage = errorMessage;
      });
    }
  }

  Widget _buildSectionHeader(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: AppColors.primary.withOpacity(0.2))),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool locked = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.darkText,
              ),
            ),
            if (locked) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.lock_outline,
                size: 14,
                color: AppColors.caption,
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: locked
                  ? AppColors.primary.withOpacity(0.15)
                  : AppColors.primary.withOpacity(0.3),
            ),
            borderRadius: BorderRadius.circular(12),
            color: locked ? Colors.grey.shade100 : Colors.white,
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            readOnly: locked,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.caption),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: locked ? AppColors.caption : AppColors.darkText,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
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
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 6),
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
                Icon(Icons.calendar_today, size: 18, color: AppColors.primary),
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

  Widget _buildCourseImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Course Image (optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickCourseImage,
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: _selectedCourseImage != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedCourseImage!,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                      ),
                      // Change photo button overlay
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit, color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'Change',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 36,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to upload course image',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primary.withOpacity(0.5),
                        ),
                      ),
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
                fontSize: 14,
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
                const Expanded(
                  child: Text(
                    'Monthly dates',
                    style: TextStyle(
                      fontSize: 14,
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
                style: TextStyle(color: AppColors.caption, fontSize: 13),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _monthlyDates.map((date) {
                return InputChip(
                  label: Text(_buildDateLabel(date)),
                  onDeleted: () {
                    setState(() => _monthlyDates.remove(date));
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 22,
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

            // ── COURSE INFO SECTION ──────────────────────────────────────
            _buildSectionHeader('Course Information', Icons.school_outlined),

            _buildTextField(
              controller: _courseCodeController,
              label: 'Course Code',
              hint: 'e.g. CS101',
              locked: _isEditing,
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _courseNameController,
              label: 'Course Name',
              hint: 'e.g. Introduction to Computer Science',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _courseDescriptionController,
              label: 'Description (optional)',
              hint: 'Brief description of the course',
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            // ── COURSE IMAGE PICKER ──────────────────────────────────────
            _buildCourseImagePicker(),
            const SizedBox(height: 20),

            // ── SCHEDULE SECTION ─────────────────────────────────────────
            _buildSectionHeader(
              'Schedule Details',
              Icons.calendar_month_outlined,
            ),

            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'Enter a location',
            ),
            const SizedBox(height: 12),

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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkText,
                        ),
                      ),
                      const SizedBox(height: 6),
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
            const SizedBox(height: 12),

            // Recurrence Type
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recurrence Type',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 6),
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
                              option[0].toUpperCase() +
                                  option.substring(1).toLowerCase(),
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
            const SizedBox(height: 12),

            _buildRecurrenceControls(),
            const SizedBox(height: 16),

            // Color picker
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 14,
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

            // Reminder
            const Text(
              'Reminder',
              style: TextStyle(
                fontSize: 14,
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
                hint: const Text(
                  'No reminder',
                  style: TextStyle(color: AppColors.caption),
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
            AppButton(
              text: _isEditing ? 'Edit Course' : 'Save Schedule',
              onPressed: _submit,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

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
          Icon(Icons.schedule, size: 18, color: AppColors.primary),
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
