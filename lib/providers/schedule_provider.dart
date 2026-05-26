import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../service/Schedule_service.dart';

class ScheduleProvider extends ChangeNotifier {
  final ScheduleService _scheduleService = ScheduleService();

  List<ScheduleModel> _schedules = [];
  bool isLoading = false;
  String? error;

  List<ScheduleModel> get schedules => _schedules;

  Future<void> loadSchedules() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final result = await _scheduleService.getMySchedules();
      _schedules = result.map((e) => ScheduleModel.fromMap(e)).toList();
    } catch (e) {
      error = e.toString();
      debugPrint('Load Schedules error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void addSchedule(ScheduleModel schedule) {
    _schedules.add(schedule);
    notifyListeners();
    loadSchedules();
  }

  Future<void> removeSchedule(String scheduleId) async {
    try {
      await _scheduleService.deleteSchedule(scheduleId: scheduleId);
      _schedules.removeWhere((e) => e.scheduleId == scheduleId);
      error = null;
      notifyListeners();
    } catch (e) {
      error = e.toString();
      debugPrint('Delete error: $e');
      notifyListeners();
    }
  }

  Future<void> editSchedule(String scheduleId, ScheduleModel updated) async {
    try {
      final index = _schedules.indexWhere((e) => e.scheduleId == scheduleId);
      if (index != -1) {
        _schedules[index] = updated;
        error = null;
        notifyListeners();
      }
      loadSchedules();
    } catch (e) {
      error = e.toString();
      debugPrint('Edit error: $e');
      notifyListeners();
    }
  }
}
