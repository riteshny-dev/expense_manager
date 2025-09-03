import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/receivable_payable.dart';

class ReceivablePayableScreen extends StatefulWidget {
  const ReceivablePayableScreen({super.key});

  @override
  State<ReceivablePayableScreen> createState() => _ReceivablePayableScreenState();
}

class _ReceivablePayableScreenState extends State<ReceivablePayableScreen> {
  late Box<ReceivablePayable> box;

  @override
  void initState() {
    super.initState();
    box = Hive.box<ReceivablePayable>('receivables_payables');
  }

  void _showAddDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final fromWhomController = TextEditingController();
    bool isReceivable = true;
    DateTime selectedDate = DateTime.now();
    String paymentMode = 'Cash';
    final paymentModes = ['Cash', 'UPI', 'Bank', 'Other'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Receivable/Payable'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                Row(
                  children: [
                    const Text('Type:'),
                    const SizedBox(width: 10),
                    DropdownButton<bool>(
                      value: isReceivable,
                      items: const [
                        DropdownMenuItem(value: true, child: Text('Receivable')),
                        DropdownMenuItem(value: false, child: Text('Payable')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            isReceivable = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (isReceivable) ...[
                  TextField(
                    controller: fromWhomController,
                    decoration: const InputDecoration(labelText: 'From whom to receive'),
                  ),
                  Row(
                    children: [
                      const Text('Date: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Payment mode: '),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: paymentMode,
                        items: paymentModes
                            .map((mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              paymentMode = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0;
              final fromWhom = fromWhomController.text.trim();
              if (name.isNotEmpty && amount > 0) {
                box.add(ReceivablePayable(
                  name: name,
                  amount: amount,
                  isReceivable: isReceivable,
                  fromWhom: isReceivable ? fromWhom : null,
                  date: isReceivable ? selectedDate : null,
                  paymentMode: isReceivable ? paymentMode : null,
                ));
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(ReceivablePayable item) {
    final nameController = TextEditingController(text: item.name);
    final amountController = TextEditingController(text: item.amount.toString());
    final fromWhomController = TextEditingController(text: item.fromWhom ?? '');
    bool isReceivable = item.isReceivable;
    DateTime selectedDate = item.date ?? DateTime.now();
    String paymentMode = item.paymentMode ?? 'Cash';
    final paymentModes = ['Cash', 'UPI', 'Bank', 'Other'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Receivable/Payable'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                Row(
                  children: [
                    const Text('Type:'),
                    const SizedBox(width: 10),
                    DropdownButton<bool>(
                      value: isReceivable,
                      items: const [
                        DropdownMenuItem(value: true, child: Text('Receivable')),
                        DropdownMenuItem(value: false, child: Text('Payable')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            isReceivable = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
                if (isReceivable) ...[
                  TextField(
                    controller: fromWhomController,
                    decoration: const InputDecoration(labelText: 'From whom to receive'),
                  ),
                  Row(
                    children: [
                      const Text('Date: '),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Payment mode: '),
                      const SizedBox(width: 10),
                      DropdownButton<String>(
                        value: paymentMode,
                        items: paymentModes
                            .map((mode) => DropdownMenuItem(
                                  value: mode,
                                  child: Text(mode),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              paymentMode = val;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text) ?? 0;
              final fromWhom = fromWhomController.text.trim();
              if (name.isNotEmpty && amount > 0) {
                item.name = name;
                item.amount = amount;
                item.isReceivable = isReceivable;
                item.fromWhom = isReceivable ? fromWhom : null;
                item.date = isReceivable ? selectedDate : null;
                item.paymentMode = isReceivable ? paymentMode : null;
                await item.save();
                Navigator.pop(context);
                setState(() {});
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = box.values.toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Receivable & Payable')),
      body: items.isEmpty
          ? const Center(child: Text('No entries yet.'))
          : ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(item.isReceivable ? Icons.arrow_downward : Icons.arrow_upward,
                      color: item.isReceivable ? Colors.green : Colors.red),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.isReceivable ? 'Receivable' : 'Payable'),
                      if (item.isReceivable && item.fromWhom != null)
                        Text('From: ${item.fromWhom}'),
                      if (item.isReceivable && item.date != null)
                        Text('Date: ${item.date!.day}/${item.date!.month}/${item.date!.year}'),
                      if (item.isReceivable && item.paymentMode != null)
                        Text('Mode: ${item.paymentMode}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditDialog(item);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await item.delete();
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}