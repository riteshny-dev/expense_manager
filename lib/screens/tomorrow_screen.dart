import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/tomorrow_task.dart';

class TomorrowScreen extends StatelessWidget {
  const TomorrowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Box<TomorrowTask> taskBox = Hive.box<TomorrowTask>('tomorrow_tasks');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tomorrow's Plan"),
      ),
      body: ValueListenableBuilder(
        valueListenable: taskBox.listenable(),
        builder: (context, Box<TomorrowTask> box, _) {
          if (box.isEmpty) {
            return const Center(child: Text("No tasks planned for tomorrow."));
          }
          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final task = box.getAt(index)!;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(task.title,
                      style: TextStyle(
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      )),
                  subtitle: Text(task.description),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == "done") {
                        task.isDone = true;
                        task.save();
                      } else if (value == "next") {
                        // move task to next day
                        box.deleteAt(index);
                        box.add(TomorrowTask(
                          title: task.title,
                          description: task.description,
                        ));
                      } else if (value == "skip") {
                        box.deleteAt(index);
                      } else if (value == "delete") {
                        box.deleteAt(index);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: "done", child: Text("✅ Done")),
                      const PopupMenuItem(
                          value: "next", child: Text("➡ Move to Next Day")),
                      const PopupMenuItem(
                          value: "skip", child: Text("⏭ Skip")),
                      const PopupMenuItem(
                          value: "delete", child: Text("🗑 Delete")),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTaskDialog(context, taskBox);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context, Box<TomorrowTask> taskBox) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: "Title")),
            TextField(controller: descController, decoration: const InputDecoration(labelText: "Description")),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                taskBox.add(TomorrowTask(
                  title: titleController.text,
                  description: descController.text,
                ));
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}