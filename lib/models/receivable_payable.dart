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
  });
}