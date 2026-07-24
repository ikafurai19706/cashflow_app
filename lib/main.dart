import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

int? parsePositiveAmount(String value) {
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < 1) {
    return null;
  }
  return parsed;
}

void main() {
  runApp(const CashflowApp());
}

class CashflowApp extends StatelessWidget {
  const CashflowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cashflow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        fontFamily: 'NotoSansJP',
      ),
      home: const DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final List<_EntryRecord> _history = [];
  final List<_FixedCostRecord> _fixedCosts = [];
  late final PageController _pageController;
  int _selectedIndex = 0;
  int _creditPaymentDay = 27;
  bool _isMonthEndPayment = false;
  bool _isNextBusinessDayOnHoliday = false;

  static const List<String> _pageTitles = ['ホーム', '履歴', '固定費'];

  final int currentBalance = 245000;
  final int monthlyCashSpent = 38200;
  final int unpaidCredit = 68400;
  final int nextWithdrawal = 52100;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _openEntryDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _EntryInputDialog(),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final amountText = result['amount'] as String? ?? '';
    final amount = parsePositiveAmount(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('金額は1円以上の整数で入力してください')));
      return;
    }
    setState(() {
      _history.insert(
        0,
        _EntryRecord(
          date: result['date'] as DateTime,
          type: result['type'] as String,
          amount: amount,
          memo: result['memo'] as String? ?? '',
        ),
      );
      if (_history.length > 20) {
        _history.removeLast();
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('モック保存しました')));
  }

  Future<_ListItemAction?> _showListItemActionSheet(BuildContext context) {
    return showModalBottomSheet<_ListItemAction>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('編集'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_ListItemAction.edit),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('削除'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_ListItemAction.delete),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editHistoryEntry(BuildContext context, int index) async {
    final item = _history[index];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _EntryInputDialog(
        title: '収支編集',
        saveLabel: '更新',
        initialDate: item.date,
        initialType: item.type,
        initialAmountText: item.amount.toString(),
        initialMemo: item.memo,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final amount = parsePositiveAmount(result['amount'] as String? ?? '');
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('金額は1円以上の整数で入力してください')));
      return;
    }

    setState(() {
      _history[index] = _EntryRecord(
        date: result['date'] as DateTime,
        type: result['type'] as String,
        amount: amount,
        memo: result['memo'] as String? ?? '',
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('モック更新しました')));
  }

  Future<void> _deleteHistoryEntry(BuildContext context, int index) async {
    final item = _history[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('履歴を削除'),
          content: Text('「${item.type}」を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    setState(() {
      _history.removeAt(index);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('モック削除しました')));
  }

  Future<void> _openFixedCostDialog(BuildContext context) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => const _FixedCostInputDialog(),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final amountText = result['amount'] as String? ?? '';
    final amount = parsePositiveAmount(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('金額は1円以上の整数で入力してください')));
      return;
    }

    final title = result['title'] as String? ?? '';
    setState(() {
      _fixedCosts.insert(
        0,
        _FixedCostRecord(
          title: title,
          amount: amount,
          memo: result['memo'] as String? ?? '',
        ),
      );
      if (_fixedCosts.length > 20) {
        _fixedCosts.removeLast();
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('モック保存しました')));
  }

  Future<void> _editFixedCost(BuildContext context, int index) async {
    final item = _fixedCosts[index];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FixedCostInputDialog(
        title: '固定費編集',
        saveLabel: '更新',
        initialTitle: item.title,
        initialAmountText: item.amount.toString(),
        initialMemo: item.memo,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final amount = parsePositiveAmount(result['amount'] as String? ?? '');
    if (amount == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('金額は1円以上の整数で入力してください')));
      return;
    }

    setState(() {
      _fixedCosts[index] = _FixedCostRecord(
        title: result['title'] as String? ?? '',
        amount: amount,
        memo: result['memo'] as String? ?? '',
      );
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('モック更新しました')));
  }

  Future<void> _deleteFixedCost(BuildContext context, int index) async {
    final item = _fixedCosts[index];
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('固定費を削除'),
          content: Text('「${item.title}」を削除しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    setState(() {
      _fixedCosts.removeAt(index);
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('モック削除しました')));
  }

  Future<void> _openSettingsPage(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => _SettingsPage(
          initialCreditPaymentDay: _creditPaymentDay,
          initialIsMonthEndPayment: _isMonthEndPayment,
          initialIsNextBusinessDayOnHoliday: _isNextBusinessDayOnHoliday,
          onCreditPaymentDayChanged: (day) {
            setState(() {
              _creditPaymentDay = day;
            });
          },
          onMonthEndPaymentChanged: (enabled) {
            setState(() {
              _isMonthEndPayment = enabled;
            });
          },
          onNextBusinessDayOnHolidayChanged: (enabled) {
            setState(() {
              _isNextBusinessDayOnHoliday = enabled;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBalance = currentBalance - unpaidCredit;
    final pages = [
      _HomePage(
        effectiveBalance: effectiveBalance,
        currentBalance: currentBalance,
        monthlyCashSpent: monthlyCashSpent,
        unpaidCredit: unpaidCredit,
        nextWithdrawal: nextWithdrawal,
        recentHistory: _history.take(3).toList(),
        onAddPressed: () => _openEntryDialog(context),
      ),
      _HistoryPage(
        history: _history,
        onItemLongPressed: _showListItemActionSheet,
        onEditPressed: _editHistoryEntry,
        onDeletePressed: _deleteHistoryEntry,
      ),
      _FixedCostPage(
        fixedCosts: _fixedCosts,
        onAddPressed: () => _openFixedCostDialog(context),
        onItemLongPressed: _showListItemActionSheet,
        onEditPressed: _editFixedCost,
        onDeletePressed: _deleteFixedCost,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles[_selectedIndex]),
        actions: [
          IconButton(
            onPressed: () => _openSettingsPage(context),
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: '履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.payments_outlined),
            label: '固定費',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEntryDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({
    required this.effectiveBalance,
    required this.currentBalance,
    required this.monthlyCashSpent,
    required this.unpaidCredit,
    required this.nextWithdrawal,
    required this.recentHistory,
    required this.onAddPressed,
  });

  final int effectiveBalance;
  final int currentBalance;
  final int monthlyCashSpent;
  final int unpaidCredit;
  final int nextWithdrawal;
  final List<_EntryRecord> recentHistory;
  final VoidCallback onAddPressed;

  String _yen(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final indexFromEnd = text.length - i - 1;
      if (indexFromEnd > 0 && indexFromEnd % 3 == 0) {
        buffer.write(',');
      }
    }
    return '¥${buffer.toString()}';
  }

  String _dateText(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '実質残高',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _yen(effectiveBalance),
            style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _InfoCard(label: '現在高', value: _yen(currentBalance)),
              _InfoCard(label: '今月現金で使った金額', value: _yen(monthlyCashSpent)),
              _InfoCard(label: 'クレジット未払い残高', value: _yen(unpaidCredit)),
              _InfoCard(label: '次の引き落とし予定額', value: _yen(nextWithdrawal)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '直近の履歴',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: recentHistory.isEmpty
                ? const Center(child: Text('まだ履歴がありません'))
                : ListView.separated(
                    itemCount: recentHistory.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = recentHistory[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          title: Text('${item.type}  ${_yen(item.amount)}'),
                          subtitle: Text(
                            item.memo.isEmpty
                                ? _dateText(item.date)
                                : '${_dateText(item.date)}  ${item.memo}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _HistoryPage extends StatelessWidget {
  const _HistoryPage({
    required this.history,
    required this.onItemLongPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  final List<_EntryRecord> history;
  final Future<_ListItemAction?> Function(BuildContext context)
  onItemLongPressed;
  final Future<void> Function(BuildContext context, int index) onEditPressed;
  final Future<void> Function(BuildContext context, int index) onDeletePressed;

  String _yen(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final indexFromEnd = text.length - i - 1;
      if (indexFromEnd > 0 && indexFromEnd % 3 == 0) {
        buffer.write(',');
      }
    }
    return '¥${buffer.toString()}';
  }

  String _dateText(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '全履歴',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: history.isEmpty
                ? const Center(child: Text('まだ履歴がありません'))
                : ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          onLongPress: () async {
                            final action = await onItemLongPressed(context);
                            if (action == _ListItemAction.edit) {
                              await onEditPressed(context, index);
                            } else if (action == _ListItemAction.delete) {
                              await onDeletePressed(context, index);
                            }
                          },
                          title: Text('${item.type}  ${_yen(item.amount)}'),
                          subtitle: Text(
                            item.memo.isEmpty
                                ? _dateText(item.date)
                                : '${_dateText(item.date)}  ${item.memo}',
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FixedCostPage extends StatelessWidget {
  const _FixedCostPage({
    required this.fixedCosts,
    required this.onAddPressed,
    required this.onItemLongPressed,
    required this.onEditPressed,
    required this.onDeletePressed,
  });

  final List<_FixedCostRecord> fixedCosts;
  final VoidCallback onAddPressed;
  final Future<_ListItemAction?> Function(BuildContext context)
  onItemLongPressed;
  final Future<void> Function(BuildContext context, int index) onEditPressed;
  final Future<void> Function(BuildContext context, int index) onDeletePressed;

  String _yen(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final indexFromEnd = text.length - i - 1;
      if (indexFromEnd > 0 && indexFromEnd % 3 == 0) {
        buffer.write(',');
      }
    }
    return '¥${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '固定費',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (fixedCosts.isEmpty)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add),
                label: const Text('固定費を追加'),
              ),
            )
          else if (fixedCosts.length <= 2)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: fixedCosts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = fixedCosts[index];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: ListTile(
                        dense: true,
                        onLongPress: () async {
                          final action = await onItemLongPressed(context);
                          if (action == _ListItemAction.edit) {
                            await onEditPressed(context, index);
                          } else if (action == _ListItemAction.delete) {
                            await onDeletePressed(context, index);
                          }
                        },
                        title: Text(item.title),
                        subtitle: Text(
                          item.memo.isEmpty
                              ? _yen(item.amount)
                              : '${_yen(item.amount)}  ${item.memo}',
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onAddPressed,
                    icon: const Icon(Icons.add),
                    label: const Text('固定費を追加'),
                  ),
                ),
              ],
            )
          else
            Expanded(
              child: Stack(
                children: [
                  ListView.separated(
                    padding: const EdgeInsets.only(bottom: 160),
                    itemCount: fixedCosts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = fixedCosts[index];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          onLongPress: () async {
                            final action = await onItemLongPressed(context);
                            if (action == _ListItemAction.edit) {
                              await onEditPressed(context, index);
                            } else if (action == _ListItemAction.delete) {
                              await onDeletePressed(context, index);
                            }
                          },
                          title: Text(item.title),
                          subtitle: Text(
                            item.memo.isEmpty
                                ? _yen(item.amount)
                                : '${_yen(item.amount)}  ${item.memo}',
                          ),
                        ),
                      );
                    },
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Theme.of(
                                context,
                              ).scaffoldBackgroundColor.withOpacity(0),
                              Theme.of(context).scaffoldBackgroundColor,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: onAddPressed,
                          icon: const Icon(Icons.add),
                          label: const Text('固定費を追加'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EntryRecord {
  const _EntryRecord({
    required this.date,
    required this.type,
    required this.amount,
    required this.memo,
  });

  final DateTime date;
  final String type;
  final int amount;
  final String memo;
}

enum _ListItemAction { edit, delete }

class _FixedCostRecord {
  const _FixedCostRecord({
    required this.title,
    required this.amount,
    required this.memo,
  });

  final String title;
  final int amount;
  final String memo;
}

class _EntryInputDialog extends StatefulWidget {
  const _EntryInputDialog({
    this.title = '収支入力',
    this.saveLabel = '保存',
    this.initialDate,
    this.initialType,
    this.initialAmountText,
    this.initialMemo,
  });

  final String title;
  final String saveLabel;
  final DateTime? initialDate;
  final String? initialType;
  final String? initialAmountText;
  final String? initialMemo;

  @override
  State<_EntryInputDialog> createState() => _EntryInputDialogState();
}

class _FixedCostInputDialog extends StatefulWidget {
  const _FixedCostInputDialog({
    this.title = '固定費入力',
    this.saveLabel = '保存',
    this.initialTitle,
    this.initialAmountText,
    this.initialMemo,
  });

  final String title;
  final String saveLabel;
  final String? initialTitle;
  final String? initialAmountText;
  final String? initialMemo;

  @override
  State<_FixedCostInputDialog> createState() => _FixedCostInputDialogState();
}

class _FixedCostInputDialogState extends State<_FixedCostInputDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  bool _titleTouched = false;
  bool _amountTouched = false;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _amountController.text = widget.initialAmountText ?? '';
    _memoController.text = widget.initialMemo ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  String? get _titleErrorText {
    final value = _titleController.text.trim();
    if (value.isEmpty) {
      return _titleTouched ? 'タイトルを入力してください' : null;
    }
    return null;
  }

  String? get _amountErrorText {
    final value = _amountController.text;
    if (value.isEmpty) {
      return _amountTouched ? '1円以上の整数を入力してください' : null;
    }
    return parsePositiveAmount(value) == null ? '1円以上の整数を入力してください' : null;
  }

  bool get _canSave => _titleErrorText == null && _amountErrorText == null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                onChanged: (_) {
                  setState(() {
                    _titleTouched = true;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                ).copyWith(errorText: _titleErrorText),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  setState(() {
                    _amountTouched = true;
                  });
                },
                decoration: const InputDecoration(
                  labelText: '金額',
                  prefixText: '￥ ',
                ).copyWith(errorText: _amountErrorText),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoController,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: 'メモ',
                  hintText: '例: サブスク',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              _titleTouched = true;
              _amountTouched = true;
            });
            if (!_canSave) {
              return;
            }
            Navigator.of(context).pop({
              'title': _titleController.text.trim(),
              'amount': _amountController.text,
              'memo': _memoController.text,
            });
          },
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}

class _EntryInputDialogState extends State<_EntryInputDialog> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _selectedType = '収入';
  bool _amountTouched = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    _selectedType = widget.initialType ?? '収入';
    _amountController.text = widget.initialAmountText ?? '';
    _memoController.text = widget.initialMemo ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  String _dateText(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  String? get _amountErrorText {
    final value = _amountController.text;
    if (value.isEmpty) {
      return _amountTouched ? '1円以上の整数を入力してください' : null;
    }
    return parsePositiveAmount(value) == null ? '1円以上の整数を入力してください' : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('日付'),
              const SizedBox(height: 6),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label: Text(_dateText(_selectedDate)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: '種類'),
                items: const [
                  DropdownMenuItem(value: '収入', child: Text('収入')),
                  DropdownMenuItem(value: '現金支出', child: Text('現金支出')),
                  DropdownMenuItem(value: 'クレジット支出', child: Text('クレジット支出')),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedType = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) {
                  setState(() {
                    _amountTouched = true;
                  });
                },
                decoration: const InputDecoration(
                  labelText: '金額',
                  prefixText: '￥ ',
                ).copyWith(errorText: _amountErrorText),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _memoController,
                maxLines: 1,
                decoration: const InputDecoration(
                  labelText: 'メモ',
                  hintText: '例: ランチ',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () {
            setState(() {
              _amountTouched = true;
            });
            if (_amountErrorText != null) {
              return;
            }
            Navigator.of(context).pop({
              'date': _selectedDate,
              'type': _selectedType,
              'amount': _amountController.text,
              'memo': _memoController.text,
            });
          },
          child: Text(widget.saveLabel),
        ),
      ],
    );
  }
}

class _SettingsPage extends StatefulWidget {
  const _SettingsPage({
    required this.initialCreditPaymentDay,
    required this.initialIsMonthEndPayment,
    required this.initialIsNextBusinessDayOnHoliday,
    required this.onCreditPaymentDayChanged,
    required this.onMonthEndPaymentChanged,
    required this.onNextBusinessDayOnHolidayChanged,
  });

  final int initialCreditPaymentDay;
  final bool initialIsMonthEndPayment;
  final bool initialIsNextBusinessDayOnHoliday;
  final ValueChanged<int> onCreditPaymentDayChanged;
  final ValueChanged<bool> onMonthEndPaymentChanged;
  final ValueChanged<bool> onNextBusinessDayOnHolidayChanged;

  @override
  State<_SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<_SettingsPage> {
  late int _creditPaymentDay;
  late bool _isMonthEndPayment;
  late bool _isNextBusinessDayOnHoliday;

  @override
  void initState() {
    super.initState();
    _creditPaymentDay = widget.initialCreditPaymentDay;
    _isMonthEndPayment = widget.initialIsMonthEndPayment;
    _isNextBusinessDayOnHoliday = widget.initialIsNextBusinessDayOnHoliday;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'クレジット支払日',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  child: DropdownMenu<int>(
                    enabled: !_isMonthEndPayment,
                    initialSelection: _creditPaymentDay,
                    dropdownMenuEntries: List.generate(
                      31,
                      (i) =>
                          DropdownMenuEntry(value: i + 1, label: '${i + 1}日'),
                    ),
                    onSelected: (value) {
                      if (value != null) {
                        setState(() => _creditPaymentDay = value);
                        widget.onCreditPaymentDayChanged(value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150,
                  child: CheckboxListTile(
                    value: _isMonthEndPayment,
                    contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    title: const Text('月末払い'),
                    controlAffinity: ListTileControlAffinity.leading,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _isMonthEndPayment = value;
                      });
                      widget.onMonthEndPaymentChanged(value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              value: _isNextBusinessDayOnHoliday,
              contentPadding: EdgeInsets.zero,
              title: const Text('土日祝の場合は翌営業日に引き落とし'),
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _isNextBusinessDayOnHoliday = value;
                });
                widget.onNextBusinessDayOnHolidayChanged(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
