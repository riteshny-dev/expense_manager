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

  void _showAddOrEditDialog({ReceivablePayable? item}) {
    final nameController = TextEditingController(text: item?.name ?? '');
    final amountController = TextEditingController(text: item?.amount.toString() ?? '');
    final fromWhomController = TextEditingController(text: item?.fromWhom ?? '');
    bool isReceivable = item?.isReceivable ?? true;
    DateTime selectedDate = item?.date ?? DateTime.now();
    String paymentMode = item?.paymentMode ?? 'Cash';
    final paymentModes = ['Cash', 'UPI', 'Bank', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item == null ? 'Add Receivable/Payable' : 'Edit Receivable/Payable',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                decoration: InputDecoration(
                  labelText: 'Amount',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('Type:', style: Theme.of(context).textTheme.bodyMedium),
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
                const SizedBox(height: 12),
                TextField(
                  controller: fromWhomController,
                  decoration: InputDecoration(
                    labelText: 'From whom to receive',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Date:', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: 10),
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text('Payment mode:', style: Theme.of(context).textTheme.bodyMedium),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () async {
                      final name = nameController.text.trim();
                      final amount = double.tryParse(amountController.text) ?? 0;
                      final fromWhom = fromWhomController.text.trim();
                      if (name.isNotEmpty && amount > 0) {
                        if (item == null) {
                          await box.add(ReceivablePayable(
                            name: name,
                            amount: amount,
                            isReceivable: isReceivable,
                            fromWhom: isReceivable ? fromWhom : null,
                            date: isReceivable ? selectedDate : null,
                            paymentMode: isReceivable ? paymentMode : null,
                          ));
                        } else {
                          item.name = name;
                          item.amount = amount;
                          item.isReceivable = isReceivable;
                          item.fromWhom = isReceivable ? fromWhom : null;
                          item.date = isReceivable ? selectedDate : null;
                          item.paymentMode = isReceivable ? paymentMode : null;
                          await item.save();
                        }
                        if (mounted) Navigator.pop(context);
                        setState(() {});
                      }
                    },
                    child: Text(item == null ? 'Add' : 'Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = box.values.toList();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Receivable & Payable'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 1,
      ),
      body: items.isEmpty
          ? Center(
              child: Text(
                'No entries yet.',
                style: textTheme.titleMedium,
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    isThreeLine: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: CircleAvatar(
                      backgroundColor: item.isReceivable ? Colors.green[100] : Colors.red[100],
                      child: Icon(
                        item.isReceivable ? Icons.arrow_downward : Icons.arrow_upward,
                        color: item.isReceivable ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      item.name,
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.isReceivable ? 'Receivable' : 'Payable',
                            style: textTheme.bodyMedium?.copyWith(
                              color: item.isReceivable ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text('Amount: ₹${item.amount.toStringAsFixed(2)}',
                              style: textTheme.bodyMedium),
                          if (item.isReceivable && item.fromWhom != null && item.fromWhom!.isNotEmpty)
                            Text('From: ${item.fromWhom}', style: textTheme.bodySmall),
                          if (item.isReceivable && item.date != null)
                            Text(
                              'Date: ${item.date!.day}/${item.date!.month}/${item.date!.year}',
                              style: textTheme.bodySmall,
                            ),
                          if (item.isReceivable && item.paymentMode != null)
                            Text('Mode: ${item.paymentMode}', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                    trailing: Wrap(
                      spacing: 0,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: 'Edit',
                          onPressed: () {
                            _showAddOrEditDialog(item: item);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete',
                          onPressed: () async {
                            await item.delete();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditDialog(),
        label: const Text('Add'),
        icon: const Icon(Icons.add),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      backgroundColor: colorScheme.background,
    );
  }
}