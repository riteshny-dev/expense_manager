import 'package:hive/hive.dart';

part 'tomorrow_task.g.dart';

@HiveType(typeId: 3) // make sure this ID is unique
class TomorrowTask extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  bool isDone;

  TomorrowTask({
    required this.title,
    this.description = '',
    this.isDone = false,
  });
}