import 'package:hive/hive.dart';

part 'receivable_payable.g.dart';

@HiveType(typeId: 1)
class ReceivablePayable extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  double amount;

  @HiveField(2)
  bool isReceivable; // true = Receivable, false = Payable

  @HiveField(3)
  String? fromWhom; // New: from whom to receive

  @HiveField(4)
  DateTime? date; // New: date of transaction

  @HiveField(5)
  String? paymentMode; // New: payment mode

  ReceivablePayable({
    required this.name,
    required this.amount,
    required this.isReceivable,
    this.fromWhom,
    this.date,
    this.paymentMode,
  }) {
    validate();
  }

  void validate() {
    if (name.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    if (amount <= 0) {
      throw ArgumentError('Amount must be greater than 0');
    }
    if (date != null && date!.isAfter(DateTime.now().add(const Duration(days: 365)))) {
      throw ArgumentError('Date cannot be more than a year in the future');
    }
    if (paymentMode != null && paymentMode!.trim().isEmpty) {
      throw ArgumentError('Payment mode cannot be empty if provided');
    }
  }
}