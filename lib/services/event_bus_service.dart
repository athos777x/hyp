import 'dart:async';

class EventBusService {
  static final EventBusService _instance = EventBusService._internal();
  factory EventBusService() => _instance;
  EventBusService._internal();

  final _medicationUpdateController = StreamController<void>.broadcast();
  final _bloodPressureUpdateController = StreamController<void>.broadcast();

  Stream<void> get medicationUpdateStream => _medicationUpdateController.stream;
  Stream<void> get bloodPressureUpdateStream =>
      _bloodPressureUpdateController.stream;

  void notifyMedicationUpdate() {
    _medicationUpdateController.add(null);
  }

  void notifyBloodPressureUpdate() {
    _bloodPressureUpdateController.add(null);
  }

  void dispose() {
    _medicationUpdateController.close();
    _bloodPressureUpdateController.close();
  }
}
