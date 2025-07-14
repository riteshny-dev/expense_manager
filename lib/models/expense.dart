import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 0)
class Expense extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  double amount;

  @HiveField(2)
  DateTime date;

  @HiveField(3)
  String category; // e.g. Food, Travel, EMIs

  Expense({
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });
}