import 'package:flutter/material.dart';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app_passwords.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AizaSyCpd5aEsRrxI906lhVI236X1PvxoZAF_sI",
      appId: "1:767492508544:web:a7db6486f8e7203a15cf65",
      messagingSenderId: "767492508544",
      projectId: "black-hole-b7f18",
      authDomain: "black-hole-b7f18.firebaseapp.com",
      storageBucket: "black-hole-b7f18.firebasestorage.app",
      measurementId: "G-WZQMV0EVRX",
    ),
  );

  await Hive.initFlutter();
  await Hive.openBox('blackHoleBox');

  runApp(MaterialApp(
    home: MainNavigation(),
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, primaryColor: Colors.orangeAccent),
  ));
}

class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  double totalDailyRevenue = 0.0;
  double totalDailyCosts = 0.0;
  List costsHistory = [];
  List otherSales = [];
  List roomsHistory = [];
  List dailyArchive = [];
  List staffDebts = [];
  Map<String, int> stock = {};

  List<String> staffNames = ["SALAH", "Ahmed", "Ziad", "Karim", "Amr k", "Lala", "sawy"];

  Map<String, double> pricesMenu = {
    'Backet': 15.0, 'coffe': 25.0, 'cola': 35.0, 'water': 15.0, 'v7': 35.0
  };

  late List roomsData;
  final _box = Hive.box('blackHoleBox');

  bool _isStockUnlocked = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _initRooms();
  }

  void _loadData() {
    setState(() {
      totalDailyRevenue = (_box.get('rev', defaultValue: 0.0) as num).toDouble();
      totalDailyCosts = (_box.get('costs', defaultValue: 0.0) as num).toDouble();
      dailyArchive = List.from(_box.get('archive', defaultValue: []));
      costsHistory = List.from(_box.get('costsHist', defaultValue: []));
      otherSales = List.from(_box.get('otherSales', defaultValue: []));
      roomsHistory = List.from(_box.get('roomsHistory', defaultValue: []));
      staffDebts = List.from(_box.get('staffDebts', defaultValue: []));

      var savedStaff = _box.get('staffNames');
      if (savedStaff != null) {
        staffNames = List<String>.from(savedStaff);
      }

      var savedStock = _box.get('stock');
      if (savedStock != null) {
        stock = Map<String, int>.from(savedStock);
      } else {
        stock = {'Backet': 0, 'coffe': 0, 'cola': 0, 'water': 0, 'v7': 0};
      }

      var savedPrices = _box.get('pricesMenu');
      if (savedPrices != null) {
        pricesMenu = Map<String, double>.from(savedPrices);
      }
    });
  }

  void _saveToDisk() {
    _box.put('rev', totalDailyRevenue);
    _box.put('costs', totalDailyCosts);
    _box.put('archive', dailyArchive);
    _box.put('costsHist', costsHistory);
    _box.put('otherSales', otherSales);
    _box.put('roomsHistory', roomsHistory);
    _box.put('stock', stock);
    _box.put('pricesMenu', pricesMenu);
    _box.put('staffDebts', staffDebts);
    _box.put('staffNames', staffNames);
  }

  void _addStaffName(String name) {
    if (name.isNotEmpty && !staffNames.contains(name)) {
      setState(() {
        staffNames.add(name);
        _saveToDisk();
      });
    }
  }

  void _removeStaffName(String name) {
    setState(() {
      staffNames.remove(name);
      _saveToDisk();
    });
  }

  void _initRooms() {
    roomsData = List.generate(10, (index) {
      String name = (index == 8) ? "BING PONG" : (index == 9 ? "BILLIARD" : "ROOM ${index + 1}");
      return {
        'id': index + 1,
        'name': name,
        'isRunning': false,
        'seconds': 0,
        'timer': null,
        'drinksCount': <String, int>{},
        'drinksTotal': 0.0,
        'timePriceController': TextEditingController(text: "0.0"),
      };
    });
  }

  void _updateStock(String item, int qty) {
    setState(() {
      stock[item] = (stock[item] ?? 0) + qty;
      if (stock[item]! < 0) stock[item] = 0;
      _saveToDisk();
    });
  }

  void _updateItemPrice(String item, double newPrice) {
    setState(() {
      pricesMenu[item] = newPrice;
      _saveToDisk();
    });
  }

  void _addNewStockItem(String item, int initialQty, double price) {
    setState(() {
      stock[item] = initialQty;
      pricesMenu[item] = price;
      _saveToDisk();
    });
  }

  void _addRevenue(double val) { setState(() => totalDailyRevenue += val); _saveToDisk(); }

  void _addExpense(double val, String reason) {
    setState(() {
      totalDailyCosts += val;
      costsHistory.insert(0, {'amount': val, 'reason': reason, 'time': DateTime.now().toString().substring(11, 16)});
    });
    _saveToDisk();
  }

  void _addStaffDebt(String name, double amount, String reason, String type) {
    setState(() {
      staffDebts.insert(0, {
        'name': name,
        'amount': amount,
        'note': reason,
        'type': type,
        'time': DateTime.now().toString().substring(5, 16)
      });
    });
    _saveToDisk();
  }

  void _handleMultiOtherSales(double totalAmt, String summaryNote, Map<String, int> selectedItems, String person, bool isStaff, String method) {
    if (isStaff) {
      double discountedAmt = totalAmt * 0.80;
      _addStaffDebt(person, discountedAmt, "مشاريب أجل (بعد خصم 20%): $summaryNote", 'drinks');
    } else {
      _addRevenue(totalAmt);
      setState(() {
        otherSales.insert(0, {
          'amount': totalAmt,
          'note': summaryNote,
          'person': person,
          'method': method,
          'items': Map<String, int>.from(selectedItems),
          'time': DateTime.now().toString().substring(11, 16)
        });
      });
    }
    selectedItems.forEach((item, qty) {
      _updateStock(item, -qty);
    });
    _saveToDisk();
  }

  void _onTabTapped(int index) async {
    if (index == 5) {
      if (!_isStockUnlocked) {
        bool ok = await promptPasswordDialog(
          context: context,
          passwordKey: AppPasswordsService.stockKey,
          title: 'الـ Stock / المخزن',
        );
        if (ok) {
          setState(() {
            _isStockUnlocked = true;
            _currentIndex = index;
          });
        }
      } else {
        setState(() => _currentIndex = index);
      }
    } else {
      setState(() {
        _isStockUnlocked = false;
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PlayStationTimer(
            rooms: roomsData, pricesMenu: pricesMenu, staffNames: staffNames, onRevenueChanged: _addRevenue, onExpenseAdded: _addExpense,
            onStaffExpenseAdded: (name, amt, reason) {
              _addExpense(amt, "سلفة/مصاريف موظف: $name ($reason)");
              _addStaffDebt(name, amt, reason, 'cash');
            },
            onSessionFinished: (data) { setState(() => roomsHistory.insert(0, data)); _saveToDisk(); },
            onEndDay: () => setState(() {
              var report = {
                'id': DateTime.now().millisecondsSinceEpoch,
                'date': "${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
                'revenue': totalDailyRevenue,
                'costs': totalDailyCosts,
                'net': totalDailyRevenue - totalDailyCosts,
                'roomsDetails': List.from(roomsHistory),
                'drinksDetails': List.from(otherSales),
                'costsDetails': List.from(costsHistory)
              };
              dailyArchive.insert(0, report);
              totalDailyRevenue = 0.0; totalDailyCosts = 0.0; costsHistory.clear(); otherSales.clear(); roomsHistory.clear(); _saveToDisk();
            }),
            totalRevenue: totalDailyRevenue, totalCosts: totalDailyCosts, stock: stock, onUpdateStock: _updateStock,
          ),
          OtherSalesPage(
            stock: stock,
            pricesMenu: pricesMenu,
            staffNames: staffNames,
            onSalesAdded: _handleMultiOtherSales,
            onAddStaff: _addStaffName,
            onRemoveStaff: _removeStaffName,
          ),
          BirthdayPage(stock: stock, pricesMenu: pricesMenu, onUpdateStock: _updateStock, onAddEventToHistory: (total, details, method) {
            _addRevenue(total);
            if (method != "Cash") _addExpense(total, "Birthday ($method): $details");
            setState(() { otherSales.insert(0, {'amount': total, 'note': "Birthday: $details", 'person': "Event", 'method': method, 'time': DateTime.now().toString().substring(11, 16)}); });
            _saveToDisk();
          }),
          StaffAccountsPage(
            staffDebts: staffDebts,
            onDeleteDebt: (idx) {
              setState(() => staffDebts.removeAt(idx));
              _saveToDisk();
            },
          ),
          ReportsPage(
            roomsHistory: roomsHistory, otherSales: otherSales, dailyArchive: dailyArchive, costsHistory: costsHistory,
            totalRevenue: totalDailyRevenue, totalCosts: totalDailyCosts,
            onDeleteEntry: (type, index) {
              setState(() {
                if (type == "rooms") {
                  double amt = (roomsHistory[index]['total'] as num).toDouble();
                  totalDailyRevenue -= amt;
                  roomsHistory.removeAt(index);
                } else if (type == "drinks") {
                  double amt = (otherSales[index]['amount'] as num).toDouble();
                  totalDailyRevenue -= amt;
                  otherSales.removeAt(index);
                } else if (type == "costs") {
                  double amt = (costsHistory[index]['amount'] as num).toDouble();
                  totalDailyCosts -= amt;
                  costsHistory.removeAt(index);
                }
              });
              _saveToDisk();
            },
            onUpdateArchive: () => _saveToDisk(),
          ),
          StockPage(
            stock: stock,
            pricesMenu: pricesMenu,
            onUpdate: _updateStock,
            onUpdatePrice: _updateItemPrice,
            onAddNewItem: _addNewStockItem,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, selectedItemColor: Colors.orangeAccent, unselectedItemColor: Colors.grey, type: BottomNavigationBarType.fixed,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.videogame_asset), label: 'Games'),
          BottomNavigationBarItem(icon: Icon(Icons.add_shopping_cart), label: 'Drinks'),
          BottomNavigationBarItem(icon: Icon(Icons.cake), label: 'Events'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Staff'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'Reports'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
        ],
      ),
    );
  }
}

class PlayStationTimer extends StatefulWidget {
  final List rooms; final Map<String, double> pricesMenu; final List<String> staffNames; final Function(double) onRevenueChanged;
  final Function(double, String) onExpenseAdded; final Function(String, double, String) onStaffExpenseAdded; final Function(Map<String, dynamic>) onSessionFinished;
  final VoidCallback onEndDay; final double totalRevenue, totalCosts; final Map<String, int> stock; final Function(String, int) onUpdateStock;
  PlayStationTimer({required this.rooms, required this.pricesMenu, required this.staffNames, required this.onRevenueChanged, required this.onExpenseAdded, required this.onStaffExpenseAdded, required this.onSessionFinished, required this.onEndDay, required this.totalRevenue, required this.totalCosts, required this.stock, required this.onUpdateStock});
  @override _PlayStationTimerState createState() => _PlayStationTimerState();
}

class _PlayStationTimerState extends State<PlayStationTimer> {
  TextEditingController costAmt = TextEditingController(), costRes = TextEditingController();
  String? selectedStaffForCost;

  void _applyDiscount(int idx, double currentTotal, StateSetter setModalState) async {
    bool ok = await promptPasswordDialog(
      context: context,
      passwordKey: AppPasswordsService.globalSummaryKey,
      title: 'خصم 10%',
    );
    if (ok) {
      var r = widget.rooms[idx];
      double timePart = double.tryParse(r['timePriceController'].text) ?? 0.0;

      setState(() {
        double discountedTime = timePart * 0.90;
        r['timePriceController'].text = discountedTime.toStringAsFixed(1);
      });
      setModalState(() {});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم تطبيق الخصم!")));
    }
  }

  @override Widget build(BuildContext context) {
    List<String> activeDrinkItems = widget.stock.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('BLACK HOLE (SL)'), actions: [IconButton(icon: const Icon(Icons.logout), onPressed: widget.onEndDay)]),
      body: Column(children: [
        Container(padding: const EdgeInsets.all(10), color: Colors.black, child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _stat('Income', widget.totalRevenue, Colors.greenAccent), _stat('Cost', widget.totalCosts, Colors.redAccent), _stat('Net', widget.totalRevenue - widget.totalCosts, Colors.cyanAccent),
          ]),
          const SizedBox(height: 8),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('Cost & Staff Expenses', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          const SizedBox(height: 4),
          Row(children: [
            Expanded(child: TextField(controller: costAmt, decoration: const InputDecoration(hintText: 'Amt'), keyboardType: TextInputType.number)),
            const SizedBox(width: 5),
            Expanded(child: TextField(controller: costRes, decoration: const InputDecoration(hintText: 'Reason'))),
            const SizedBox(width: 5),
            DropdownButton<String>(
              hint: const Text("Staff?"),
              value: selectedStaffForCost,
              items: widget.staffNames.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (val) => setState(() => selectedStaffForCost = val),
            ),
            IconButton(icon: const Icon(Icons.add, color: Colors.redAccent), onPressed: () {
              double amt = double.tryParse(costAmt.text) ?? 0;
              if (amt > 0) {
                if (selectedStaffForCost != null) {
                  widget.onStaffExpenseAdded(selectedStaffForCost!, amt, costRes.text.isEmpty ? "سلفة نقدي" : costRes.text);
                } else {
                  widget.onExpenseAdded(amt, costRes.text);
                }
                costAmt.clear(); costRes.clear();
                setState(() => selectedStaffForCost = null);
              }
            }),
          ])
        ])),
        Expanded(child: GridView.builder(padding: const EdgeInsets.all(8), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.52, crossAxisSpacing: 8, mainAxisSpacing: 8), itemCount: widget.rooms.length, itemBuilder: (context, index) {
          var room = widget.rooms[index]; if (room['isRunning']) { double price = (room['name'] == "BING PONG" || room['name'] == "BILLIARD") ? 1.66 : (room['id'] == 4 ? 2.5 : 2.0); room['timePriceController'].text = ((room['seconds'] / 60) * price).toStringAsFixed(1); }
          double tTotal = double.tryParse(room['timePriceController'].text) ?? 0.0; double dTotal = room['drinksTotal'];
          return Card(color: Colors.grey[900], child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
            Text('${room['name']}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
            Text('${room['seconds'] ~/ 60}:${(room['seconds'] % 60).toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 22, color: Colors.greenAccent)),
            const Divider(),
            Expanded(
                child: ListView(
                    children: activeDrinkItems.map((d) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("$d (${widget.stock[d] ?? 0})", style: const TextStyle(fontSize: 9)),
                          Row(children: [
                            IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.remove, size: 16), onPressed: () => _updateDrink(index, d, -1)),
                            Text('${room['drinksCount'][d] ?? 0}', style: const TextStyle(fontSize: 11)),
                            IconButton(padding: EdgeInsets.zero, constraints: const BoxConstraints(), icon: const Icon(Icons.add, size: 16), onPressed: () => _updateDrink(index, d, 1)),
                          ])
                        ]
                    )).toList()
                )
            ),
            const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Time:", style: TextStyle(fontSize: 12)), SizedBox(width: 50, height: 30, child: TextField(controller: room['timePriceController'], decoration: const InputDecoration(isDense: true), style: const TextStyle(fontSize: 12, color: Colors.yellow), keyboardType: TextInputType.number)),]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Drinks:", style: TextStyle(fontSize: 12)), Text("${dTotal.toStringAsFixed(1)}", style: const TextStyle(fontSize: 12, color: Colors.cyanAccent)),]),
            Text('Total: ${(tTotal + dTotal).toStringAsFixed(1)} ج', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ElevatedButton(onPressed: () => _toggle(index), child: Text(room['isRunning'] ? 'Stop' : 'Start', style: const TextStyle(fontSize: 10))), ElevatedButton(onPressed: () => _showPaymentDialog(index, tTotal + dTotal), child: const Text('Pay', style: TextStyle(fontSize: 10))),]),
          ])),);
        }))
      ]),
    );
  }

  void _updateDrink(int idx, String d, int c) { setState(() { var r = widget.rooms[idx]; r['drinksCount'][d] = (r['drinksCount'][d] ?? 0) + c; if (r['drinksCount'][d] < 0) r['drinksCount'][d] = 0; r['drinksTotal'] = 0.0; r['drinksCount'].forEach((key, val) => r['drinksTotal'] += (val * (widget.pricesMenu[key] ?? 0.0))); }); }
  void _toggle(int idx) { setState(() { var r = widget.rooms[idx]; if (r['isRunning']) { r['timer']?.cancel(); r['isRunning'] = false; } else { r['isRunning'] = true; r['timer'] = Timer.periodic(const Duration(seconds: 1), (t) => setState(() => r['seconds']++)); } }); }

  void _showPaymentDialog(int idx, double total) {
    String method = "Cash";
    showDialog(context: context, builder: (c) => StatefulBuilder(builder: (context, setModalState) {
      var r = widget.rooms[idx];
      double timePrice = double.tryParse(r['timePriceController'].text) ?? 0;
      double currentT = timePrice + r['drinksTotal'];

      String drinksSummary = "";
      r['drinksCount'].forEach((k, v) { if (v > 0) drinksSummary += "$k x$v (${(widget.pricesMenu[k] ?? 0.0) * v}ج), "; });

      return AlertDialog(
        title: Text("Payment - ${r['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Total: ${currentT.toStringAsFixed(1)} EGP", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
            const SizedBox(height: 15),
            DropdownButton<String>(value: method, isExpanded: true, items: ["Cash", "Fawry", "InstaPay", "VC"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setModalState(() => method = v!)),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _applyDiscount(idx, currentT, setModalState),
              icon: const Icon(Icons.percent, size: 16),
              label: const Text("Apply 10% Discount"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
            )
          ],
        ),
        actions: [TextButton(onPressed: () {
          Map<String, int> drinksMap = Map<String, int>.from(r['drinksCount']);
          r['drinksCount'].forEach((k, v) { if (v > 0) widget.onUpdateStock(k, -v); });
          if (method != "Cash") widget.onExpenseAdded(currentT, "Payment: $method - ${r['name']}");
          widget.onSessionFinished({
            'room': r['name'],
            'total': currentT,
            'timePrice': timePrice,
            'drinksPrice': r['drinksTotal'],
            'drinksSummary': drinksSummary,
            'drinksMap': drinksMap,
            'method': method,
            'timestamp': DateTime.now().toString().substring(11, 16)
          });
          widget.onRevenueChanged(currentT);
          setState(() { r['timer']?.cancel(); r['isRunning'] = false; r['seconds'] = 0; r['drinksCount'] = {}; r['drinksTotal'] = 0.0; r['timePriceController'].text = "0.0"; });
          Navigator.pop(c);
        }, child: const Text("CONFIRM & PAY"))],
      );
    }));
  }
  Widget _stat(String l, double v, Color c) => Column(children: [Text(l), Text(v.toStringAsFixed(1), style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.bold))]);
}

class OtherSalesPage extends StatefulWidget {
  final Map<String, int> stock;
  final Map<String, double> pricesMenu;
  final List<String> staffNames;
  final Function(double, String, Map<String, int>, String, bool, String) onSalesAdded;
  final Function(String) onAddStaff;
  final Function(String) onRemoveStaff;

  OtherSalesPage({
    required this.stock,
    required this.pricesMenu,
    required this.staffNames,
    required this.onSalesAdded,
    required this.onAddStaff,
    required this.onRemoveStaff,
  });

  @override
  _OtherSalesPageState createState() => _OtherSalesPageState();
}

class _OtherSalesPageState extends State<OtherSalesPage> {
  final customerNameCtrl = TextEditingController();
  Map<String, int> selectedItems = {};
  String? selectedStaff;
  bool isStaff = false;
  String selectedMethod = "Cash";

  void _updateQty(String item, int delta) {
    setState(() {
      int current = selectedItems[item] ?? 0;
      int updated = current + delta;
      if (updated <= 0) {
        selectedItems.remove(item);
      } else {
        selectedItems[item] = updated;
      }
    });
  }

  double get _calculatedTotal {
    double total = 0;
    selectedItems.forEach((item, qty) {
      total += (widget.pricesMenu[item] ?? 0.0) * qty;
    });
    return total;
  }

  void _showAddStaffDialog() {
    TextEditingController nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("إضافة اسم موظف جديد"),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: "اسم الموظف"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                widget.onAddStaff(nameCtrl.text.trim());
                Navigator.pop(c);
              }
            },
            child: const Text("إضافة"),
          )
        ],
      ),
    );
  }

  void _confirmDeleteStaff(String name) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("حذف ($name)؟"),
        content: Text("هل أنت تأكد من حذف $name من قائمة الموظفين؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              if (selectedStaff == name) {
                setState(() => selectedStaff = null);
              }
              widget.onRemoveStaff(name);
              Navigator.pop(c);
            },
            child: const Text("حذف"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<String> stockItems = widget.stock.keys.toList();
    double totalAmt = _calculatedTotal;
    double staffDiscountedTotal = totalAmt * 0.80;

    return Scaffold(
      appBar: AppBar(title: const Text('Sales / Drinks')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              title: const Text("حساب أجل (Staff/Debt)", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
              subtitle: const Text("تحديد الحساب كـ أجل للموظفين (خصم 20%)"),
              value: isStaff,
              onChanged: (v) => setState(() { isStaff = v; if(!v) selectedStaff = null; }),
            ),
            const SizedBox(height: 10),
            if (isStaff) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("اختر الموظف (اضغط مطولاً للحذف):"),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.orangeAccent),
                    tooltip: "إضافة موظف",
                    onPressed: _showAddStaffDialog,
                  )
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ...widget.staffNames.map((name) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: GestureDetector(
                        onLongPress: () => _confirmDeleteStaff(name),
                        child: ChoiceChip(
                          label: Text(name),
                          selected: selectedStaff == name,
                          onSelected: (s) => setState(() => selectedStaff = s ? name : null),
                        ),
                      ),
                    )).toList(),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.orangeAccent),
                      onPressed: _showAddStaffDialog,
                    )
                  ],
                ),
              )
            ] else ...[
              TextField(controller: customerNameCtrl, decoration: const InputDecoration(labelText: 'Customer Name (اسم العميل)')),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("طريقة الدفع: "),
                  const SizedBox(width: 10),
                  DropdownButton<String>(
                    value: selectedMethod,
                    items: ["Cash", "Fawry", "InstaPay", "VC"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (v) => setState(() => selectedMethod = v!),
                  )
                ],
              )
            ],
            const SizedBox(height: 15),
            const Text("اختر المشاريب والكمية (+ / -):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[800]!), borderRadius: BorderRadius.circular(8)),
              child: Column(
                children: stockItems.map((item) {
                  int qty = selectedItems[item] ?? 0;
                  double price = widget.pricesMenu[item] ?? 0.0;
                  return ListTile(
                    dense: true,
                    title: Text("$item ($price EGP)"),
                    subtitle: Text("المتوفر: ${widget.stock[item]}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                          onPressed: () => _updateQty(item, -1),
                        ),
                        Text("$qty", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                          onPressed: () => _updateQty(item, 1),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("إجمالي المبيعات:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isStaff) ...[
                      Text("${totalAmt.toStringAsFixed(1)} EGP", style: const TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                      Text("${staffDiscountedTotal.toStringAsFixed(1)} EGP (خصم 20%)", style: const TextStyle(fontSize: 20, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ] else
                      Text("${totalAmt.toStringAsFixed(1)} EGP", style: const TextStyle(fontSize: 20, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.orangeAccent),
              onPressed: () {
                if (selectedItems.isNotEmpty && (!isStaff || selectedStaff != null)) {
                  String person = isStaff ? selectedStaff! : (customerNameCtrl.text.isEmpty ? "Customer" : customerNameCtrl.text);
                  String summary = selectedItems.entries.map((e) => "${e.key} x${e.value}").join(", ");
                  widget.onSalesAdded(totalAmt, summary, selectedItems, person, isStaff, selectedMethod);
                  customerNameCtrl.clear();
                  setState(() {
                    selectedItems.clear();
                    isStaff = false;
                    selectedStaff = null;
                    selectedMethod = "Cash";
                  });
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("تم حفظ المبيعات بنجاح!")));
                }
              },
              child: const Text('حفظ الطلب', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

class BirthdayPage extends StatefulWidget {
  final Map<String, int> stock; final Map<String, double> pricesMenu; final Function(String, int) onUpdateStock; final Function(double, String, String) onAddEventToHistory;
  BirthdayPage({required this.stock, required this.pricesMenu, required this.onUpdateStock, required this.onAddEventToHistory});
  @override _BirthdayPageState createState() => _BirthdayPageState();
}
class _BirthdayPageState extends State<BirthdayPage> {
  final TextEditingController pricePerPersonCtrl = TextEditingController(text: "200"), guestNameCtrl = TextEditingController();
  List<Map<String, dynamic>> guests = [];
  void _addGuest() { if (guestNameCtrl.text.isEmpty) return; setState(() { guests.add({'name': guestNameCtrl.text, 'basePrice': double.tryParse(pricePerPersonCtrl.text) ?? 0.0, 'method': "Cash", 'drinks': <String, int>{}, 'drinksPrice': 0.0}); guestNameCtrl.clear(); }); }
  void _updateGuestDrink(int index, String drink, int change) { setState(() { var g = guests[index]; g['drinks'][drink] = (g['drinks'][drink] ?? 0) + change; if (g['drinks'][drink] < 0) g['drinks'][drink] = 0; double totalD = 0; int totalDrinksCount = 0; String? firstFoundDrink; g['drinks'].forEach((name, qty) { int q = (qty as num).toInt(); if (q > 0) { totalDrinksCount += q; if (firstFoundDrink == null) firstFoundDrink = name; totalD += (q * (widget.pricesMenu[name] ?? 0.0)); } }); if (totalDrinksCount > 0 && firstFoundDrink != null) totalD -= (widget.pricesMenu[firstFoundDrink] ?? 0.0); g['drinksPrice'] = (totalD < 0) ? 0.0 : totalD; }); }
  @override Widget build(BuildContext context) {
    List<String> activeDrinkItems = widget.stock.keys.toList();
    double grandTotal = 0; for (var g in guests) grandTotal += (g['basePrice'] + g['drinksPrice']);
    return Scaffold(appBar: AppBar(title: const Text("Birthday Event")), body: Column(children: [
      Padding(padding: const EdgeInsets.all(10), child: Row(children: [SizedBox(width: 80, child: TextField(controller: pricePerPersonCtrl, decoration: const InputDecoration(labelText: "Price/P"), keyboardType: TextInputType.number)), const SizedBox(width: 10), Expanded(child: TextField(controller: guestNameCtrl, decoration: const InputDecoration(labelText: "Guest Name"))), IconButton(icon: const Icon(Icons.person_add, color: Colors.orangeAccent), onPressed: _addGuest),])),
      const Divider(), Expanded(child: ListView.builder(itemCount: guests.length, itemBuilder: (c, i) { var g = guests[i]; return Card(margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), child: ExpansionTile(title: Text("${g['name']} - (${g['basePrice'] + g['drinksPrice']} ج)"), subtitle: Text("Method: ${g['method']}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => guests.removeAt(i))), children: [Padding(padding: const EdgeInsets.all(12), child: Column(children: [DropdownButton<String>(value: g['method'], isExpanded: true, items: ["Cash", "Fawry", "InstaPay", "VC"].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(), onChanged: (v) => setState(() => g['method'] = v!)), ...activeDrinkItems.map((drink) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(drink), Row(children: [IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => _updateGuestDrink(i, drink, -1)), Text("${g['drinks'][drink] ?? 0}"), IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.green), onPressed: () => _updateGuestDrink(i, drink, 1)),])])).toList()]))],)); })),
      Container(padding: const EdgeInsets.all(15), color: Colors.black, child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Total: $grandTotal ج", style: const TextStyle(fontSize: 18, color: Colors.greenAccent)), ElevatedButton(onPressed: guests.isEmpty ? null : () { for (var g in guests) { String drinksSummary = ""; g['drinks'].forEach((k, v) { if (v > 0) { drinksSummary += "$k x$v, "; widget.onUpdateStock(k, -v); } }); widget.onAddEventToHistory(g['basePrice'] + g['drinksPrice'], "Event: ${g['name']} ($drinksSummary)", g['method']); } setState(() => guests.clear()); }, child: const Text("FINISH ALL"))]))
    ]));
  }
}

class StaffAccountsPage extends StatelessWidget {
  final List staffDebts;
  final Function(int) onDeleteDebt;

  StaffAccountsPage({required this.staffDebts, required this.onDeleteDebt});

  Map<String, List> _groupStaffDebts() {
    Map<String, List> grouped = {};
    for (var debt in staffDebts) {
      String name = debt['name'] ?? "Unknown";
      if (!grouped.containsKey(name)) grouped[name] = [];
      grouped[name]!.add(debt);
    }
    return grouped;
  }

  void _confirmDelete(BuildContext ctx, int index) async {
    bool ok = await promptPasswordDialog(
      context: ctx,
      passwordKey: AppPasswordsService.globalSummaryKey,
      title: 'حذف مديونية موظف',
    );
    if (ok) {
      onDeleteDebt(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    var groupedData = _groupStaffDebts();
    var names = groupedData.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Staff Accounts (حسابات الموظفين)")),
      body: names.isEmpty
          ? const Center(child: Text("لا توجد مديونيات أو مسحوبات للموظفين"))
          : ListView.builder(
        itemCount: names.length,
        itemBuilder: (context, index) {
          String name = names[index];
          List debts = groupedData[name]!;

          double drinksTotal = 0;
          double cashTotal = 0;

          for (var d in debts) {
            double amt = (d['amount'] as num).toDouble();
            if (d['type'] == 'cash') {
              cashTotal += amt;
            } else {
              drinksTotal += amt;
            }
          }

          double grandTotal = drinksTotal + cashTotal;

          return Card(
            margin: const EdgeInsets.all(8),
            child: ExpansionTile(
              leading: const Icon(Icons.person, color: Colors.orangeAccent),
              title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              subtitle: Text("الإجمالي: $grandTotal ج | (مشاريب: $drinksTotal ج - سلف/كوست: $cashTotal ج)", style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text("مشاريب: $drinksTotal ج", style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                      Text("سلف وكوست: $cashTotal ج", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const Divider(),
                ...debts.map((d) {
                  int originalIndex = staffDebts.indexOf(d);
                  bool isCash = d['type'] == 'cash';
                  return ListTile(
                    dense: true,
                    leading: Icon(isCash ? Icons.attach_money : Icons.local_drink, color: isCash ? Colors.cyanAccent : Colors.orangeAccent),
                    title: Text("${d['note']} - ${d['amount']} ج"),
                    subtitle: Text("النوع: ${isCash ? 'سلفة / كوست' : 'مشاريب أجل'} | الوقت: ${d['time']}"),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, originalIndex),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ReportsPage extends StatefulWidget {
  final List roomsHistory, otherSales, dailyArchive, costsHistory;
  final double totalRevenue, totalCosts;
  final Function(String, int) onDeleteEntry;
  final VoidCallback onUpdateArchive;

  ReportsPage({
    required this.roomsHistory,
    required this.otherSales,
    required this.dailyArchive,
    required this.costsHistory,
    required this.totalRevenue,
    required this.totalCosts,
    required this.onDeleteEntry,
    required this.onUpdateArchive,
  });

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  bool _isGlobalUnlocked = false;

  Future<void> _requestGlobalSummaryPassword() async {
    bool ok = await promptPasswordDialog(
      context: context,
      passwordKey: AppPasswordsService.globalSummaryKey,
      title: 'Global Summary',
    );
    if (ok) {
      setState(() {
        _isGlobalUnlocked = true;
      });
    }
  }

  void _confirmDelete(BuildContext ctx, String type, int index) async {
    // تحديد مفتاح الباسورد بناءً على نوع العملية
    String requiredKey = (type == "costs")
        ? AppPasswordsService.deleteCostKey
        : AppPasswordsService.globalSummaryKey;

    String titleText = (type == "costs") ? 'حذف مصروف (Cost)' : 'تأكيد الحذف';

    bool ok = await promptPasswordDialog(
      context: ctx,
      passwordKey: requiredKey,
      title: titleText,
    );
    if (ok) {
      widget.onDeleteEntry(type, index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Reports"),
          bottom: TabBar(
            isScrollable: true,
            onTap: (index) {
              if (index != 0 && _isGlobalUnlocked) {
                setState(() {
                  _isGlobalUnlocked = false;
                });
              }
            },
            tabs: const [
              Tab(text: 'Global Summary'),
              Tab(text: 'Rooms'),
              Tab(text: 'Drinks'),
              Tab(text: 'Costs'),
              Tab(text: 'Archive'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _isGlobalUnlocked
                ? GlobalSummaryTab(
              dailyArchive: widget.dailyArchive,
              currentRooms: widget.roomsHistory,
              currentDrinks: widget.otherSales,
              currentCosts: widget.costsHistory,
              currentRev: widget.totalRevenue,
              currentCost: widget.totalCosts,
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, size: 64, color: Colors.orangeAccent),
                  const SizedBox(height: 16),
                  const Text("قسم Global Summary محمي بباسورد", style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _requestGlobalSummaryPassword,
                    icon: const Icon(Icons.key),
                    label: const Text("إدخال كلمة السر"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      foregroundColor: Colors.black,
                    ),
                  )
                ],
              ),
            ),
            _l(context, widget.roomsHistory, "rooms"),
            _l(context, widget.otherSales, "drinks"),
            _l(context, widget.costsHistory, "costs"),
            _a(context),
          ],
        ),
      ),
    );
  }

  Widget _l(BuildContext ctx, List l, String t) => ListView.builder(
    itemCount: l.length,
    itemBuilder: (c, i) => ListTile(
      title: Text("${l[i]['room'] ?? l[i]['note'] ?? l[i]['reason']} ${l[i]['name'] != null ? '(${l[i]['name']})' : ''}"),
      subtitle: Text("${l[i]['total'] ?? l[i]['amount']}ج | ${l[i]['method'] ?? l[i]['time'] ?? ''}"),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () => _confirmDelete(ctx, t, i),
      ),
    ),
  );

  Widget _a(BuildContext context) => ListView.builder(
    itemCount: widget.dailyArchive.length,
    itemBuilder: (c, i) => ListTile(
      title: Text("Date: ${widget.dailyArchive[i]['date']}"),
      subtitle: Text("Net: ${widget.dailyArchive[i]['net']}ج"),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (c) => DayDetailsPage(
            dayData: widget.dailyArchive[i],
            onSave: widget.onUpdateArchive,
          ),
        ),
      ),
    ),
  );
}

class GlobalSummaryTab extends StatelessWidget {
  final List dailyArchive;
  final List currentRooms;
  final List currentDrinks;
  final List currentCosts;
  final double currentRev;
  final double currentCost;

  GlobalSummaryTab({
    required this.dailyArchive,
    required this.currentRooms,
    required this.currentDrinks,
    required this.currentCosts,
    required this.currentRev,
    required this.currentCost,
  });

  @override
  Widget build(BuildContext context) {
    double grandTotalRevenue = currentRev;
    double grandTotalCosts = currentCost;

    Map<String, double> paymentMethods = {
      'Cash': 0.0,
      'Fawry': 0.0,
      'InstaPay': 0.0,
      'VC': 0.0,
    };

    Map<String, int> totalDrinksSold = {};
    List<Map<String, dynamic>> allCostsWithReasons = [];

    for (var c in currentCosts) {
      allCostsWithReasons.add({
        'reason': c['reason'] ?? 'مصاريف عامة',
        'amount': (c['amount'] as num).toDouble(),
        'date': 'اليوم'
      });
    }

    for (var r in currentRooms) {
      String m = r['method'] ?? 'Cash';
      double amt = (r['total'] as num).toDouble();
      paymentMethods[m] = (paymentMethods[m] ?? 0.0) + amt;

      if (r['drinksMap'] != null) {
        Map dMap = r['drinksMap'];
        dMap.forEach((k, v) {
          int q = (v as num).toInt();
          if (q > 0) totalDrinksSold[k] = (totalDrinksSold[k] ?? 0) + q;
        });
      }
    }

    for (var d in currentDrinks) {
      String m = d['method'] ?? 'Cash';
      double amt = (d['amount'] as num).toDouble();
      paymentMethods[m] = (paymentMethods[m] ?? 0.0) + amt;

      if (d['items'] != null) {
        Map items = d['items'];
        items.forEach((k, v) {
          int q = (v as num).toInt();
          if (q > 0) totalDrinksSold[k] = (totalDrinksSold[k] ?? 0) + q;
        });
      }
    }

    for (var day in dailyArchive) {
      grandTotalRevenue += (day['revenue'] as num).toDouble();
      grandTotalCosts += (day['costs'] as num).toDouble();
      String dayDate = day['date'] ?? 'تاريخ سابق';

      List cList = day['costsDetails'] ?? [];
      for (var c in cList) {
        allCostsWithReasons.add({
          'reason': c['reason'] ?? 'مصاريف عامة',
          'amount': (c['amount'] as num).toDouble(),
          'date': dayDate
        });
      }

      List rList = day['roomsDetails'] ?? [];
      for (var r in rList) {
        String m = r['method'] ?? 'Cash';
        double amt = (r['total'] as num).toDouble();
        paymentMethods[m] = (paymentMethods[m] ?? 0.0) + amt;

        if (r['drinksMap'] != null) {
          Map dMap = r['drinksMap'];
          dMap.forEach((k, v) {
            int q = (v as num).toInt();
            if (q > 0) totalDrinksSold[k] = (totalDrinksSold[k] ?? 0) + q;
          });
        }
      }

      List dList = day['drinksDetails'] ?? [];
      for (var d in dList) {
        String m = d['method'] ?? 'Cash';
        double amt = (d['amount'] as num).toDouble();
        paymentMethods[m] = (paymentMethods[m] ?? 0.0) + amt;

        if (d['items'] != null) {
          Map items = d['items'];
          items.forEach((k, v) {
            int q = (v as num).toInt();
            if (q > 0) totalDrinksSold[k] = (totalDrinksSold[k] ?? 0) + q;
          });
        }
      }
    }

    double grandNet = grandTotalRevenue - grandTotalCosts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("إجمالي الأيام كلها (All-Time Summary)", style: TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.key, color: Colors.orangeAccent, size: 22),
                            tooltip: "تغيير باسورد Global",
                            onPressed: () {
                              showChangePasswordDialog(
                                context: context,
                                passwordKey: AppPasswordsService.globalSummaryKey,
                                title: 'الـ Global Summary',
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.lock_reset, color: Colors.redAccent, size: 22),
                            tooltip: "تغيير باسورد مسح الكوست",
                            onPressed: () {
                              showChangePasswordDialog(
                                context: context,
                                passwordKey: AppPasswordsService.deleteCostKey,
                                title: 'حذف المصاريف (Cost)',
                              );
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("إجمالي الدخل (Total Rev):"), Text("${grandTotalRevenue.toStringAsFixed(1)} ج", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16))]),
                  const SizedBox(height: 5),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("إجمالي الكوست (Total Costs):"), Text("${grandTotalCosts.toStringAsFixed(1)} ج", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16))]),
                  const Divider(),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("إجمالي الصافي (Total Net):"), Text("${grandNet.toStringAsFixed(1)} ج", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 20))]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          const Text("تقسيم أرباح الفلوس حسب طريقة الدفع:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.yellowAccent)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _paymentRow("كاش (Cash)", paymentMethods['Cash']!, Colors.greenAccent),
                const Divider(),
                _paymentRow("فوري (Fawry)", paymentMethods['Fawry']!, Colors.amberAccent),
                const Divider(),
                _paymentRow("إنستا باي (InstaPay)", paymentMethods['InstaPay']!, Colors.purpleAccent),
                const Divider(),
                _paymentRow("فودافون كاش (Vodafone Cash)", paymentMethods['VC']!, Colors.redAccent),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("إجمالي المشاريب المباعة عبر التاريخ:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.orangeAccent)),
          const SizedBox(height: 8),
          totalDrinksSold.isEmpty
              ? const Text("لا توجد مبيعات مشاريب مسجلة بعد", style: TextStyle(color: Colors.grey))
              : Container(
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: totalDrinksSold.entries.map((e) => ListTile(
                dense: true,
                leading: const Icon(Icons.local_drink, color: Colors.cyanAccent),
                title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Text("${e.value} قطعة", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 14)),
              )).toList(),
            ),
          ),
          const SizedBox(height: 20),
          const Text("سجل المصاريف والكوست بالتفصيل والأسباب:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
          const SizedBox(height: 8),
          allCostsWithReasons.isEmpty
              ? const Text("لا توجد مصاريف مسجلة", style: TextStyle(color: Colors.grey))
              : Container(
            decoration: BoxDecoration(color: Colors.grey[900], borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: allCostsWithReasons.map((c) => ListTile(
                dense: true,
                leading: const Icon(Icons.money_off, color: Colors.redAccent),
                title: Text("${c['reason']} - ${c['amount']} ج"),
                subtitle: Text("التاريخ/اليوم: ${c['date']}"),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentRow(String title, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          Text("${amount.toStringAsFixed(1)} ج", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class DayDetailsPage extends StatefulWidget {
  final Map<dynamic, dynamic> dayData; final VoidCallback onSave;
  DayDetailsPage({required this.dayData, required this.onSave});
  @override _DayDetailsPageState createState() => _DayDetailsPageState();
}

class _DayDetailsPageState extends State<DayDetailsPage> {
  final TextEditingController _costAmt = TextEditingController();
  final TextEditingController _costReason = TextEditingController();

  void _addCostToArchivedDay() {
    double amt = double.tryParse(_costAmt.text) ?? 0.0;
    String reason = _costReason.text.trim();
    if (amt > 0 && reason.isNotEmpty) {
      setState(() {
        (widget.dayData['costsDetails'] as List).insert(0, {
          'amount': amt,
          'reason': reason,
          'time': DateTime.now().toString().substring(11, 16)
        });
        widget.dayData['costs'] = (widget.dayData['costs'] as num).toDouble() + amt;
        widget.dayData['net'] = (widget.dayData['revenue'] as num).toDouble() - (widget.dayData['costs'] as num).toDouble();
      });
      widget.onSave();
      _costAmt.clear();
      _costReason.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Extra Cost Added Successfully")));
    }
  }

  @override
  Widget build(BuildContext context) {
    List roomsDetails = widget.dayData['roomsDetails'] ?? [];
    List drinksDetails = widget.dayData['drinksDetails'] ?? [];
    List costsDetails = widget.dayData['costsDetails'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text("Day Summary - ${widget.dayData['date']}")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.black45,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Revenue:"), Text("${widget.dayData['revenue']} EGP", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 5),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Costs:"), Text("${widget.dayData['costs']} EGP", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))]),
                    const Divider(),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text("Net Profit:"), Text("${widget.dayData['net']} EGP", style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.bold))]),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            const Text("Add Extra Cost (مصاريف إضافية):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.orangeAccent)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _costAmt, decoration: const InputDecoration(hintText: 'Amt'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _costReason, decoration: const InputDecoration(hintText: 'Reason'))),
                IconButton(icon: const Icon(Icons.add_circle, color: Colors.redAccent, size: 30), onPressed: _addCostToArchivedDay)
              ],
            ),
            const Divider(height: 30),
            const Text("Rooms Sessions (الغرف):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...roomsDetails.map((r) => ListTile(
              dense: true,
              title: Text("${r['room']} - Total: ${r['total']} EGP (${r['method']})"),
              subtitle: Text("Time: ${r['timePrice'] ?? 0} EGP | Drinks: ${r['drinksSummary'] ?? 'None'} (${r['drinksPrice'] ?? 0} EGP)"),
            )),
            const Divider(),
            const Text("Other Sales & Drinks (مبيعات خارجية):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...drinksDetails.map((d) => ListTile(
              dense: true,
              title: Text("${d['note']} - ${d['amount']} EGP (${d['method'] ?? 'Cash'})"),
              subtitle: Text("Person: ${d['person']} | Time: ${d['time']}"),
            )),
            const Divider(),
            const Text("Costs & Expenses (المصاريف والتكاليف):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ...costsDetails.map((c) => ListTile(
              dense: true,
              title: Text("${c['reason']} - ${c['amount']} EGP"),
              subtitle: Text("Time: ${c['time'] ?? 'N/A'}"),
            )),
          ],
        ),
      ),
    );
  }
}

class StockPage extends StatelessWidget {
  final Map<String, int> stock;
  final Map<String, double> pricesMenu;
  final Function(String, int) onUpdate;
  final Function(String, double) onUpdatePrice;
  final Function(String, int, double) onAddNewItem;

  StockPage({
    required this.stock,
    required this.pricesMenu,
    required this.onUpdate,
    required this.onUpdatePrice,
    required this.onAddNewItem
  });

  void _showAddItemDialog(BuildContext context) {
    TextEditingController nameController = TextEditingController();
    TextEditingController qtyController = TextEditingController(text: "0");
    TextEditingController priceController = TextEditingController(text: "0.0");

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Add New Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Item Name")),
            TextField(controller: qtyController, decoration: const InputDecoration(labelText: "Initial Quantity"), keyboardType: TextInputType.number),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "Price (EGP)"), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                int qty = int.tryParse(qtyController.text) ?? 0;
                double price = double.tryParse(priceController.text) ?? 0.0;
                onAddNewItem(nameController.text.trim(), qty, price);
                Navigator.pop(c);
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  void _showEditPriceDialog(BuildContext context, String item, double currentPrice) {
    TextEditingController priceController = TextEditingController(text: currentPrice.toString());

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text("تعديل سعر ($item)"),
        content: TextField(
          controller: priceController,
          decoration: const InputDecoration(labelText: "السعر الجديد (EGP)"),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              double newPrice = double.tryParse(priceController.text) ?? currentPrice;
              onUpdatePrice(item, newPrice);
              Navigator.pop(c);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم تعديل سعر $item لـ $newPrice EGP")));
            },
            child: const Text("حفظ السعر"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock"),
        actions: [
          IconButton(
            icon: const Icon(Icons.key, color: Colors.orangeAccent),
            tooltip: "تغيير باسورد Stock",
            onPressed: () {
              showChangePasswordDialog(
                context: context,
                passwordKey: AppPasswordsService.stockKey,
                title: 'الـ Stock',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: "Add New Item",
            onPressed: () => _showAddItemDialog(context),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 45),
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => _showAddItemDialog(context),
              icon: const Icon(Icons.add),
              label: const Text("ADD NEW ITEM", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView(
              children: stock.keys.map((item) {
                double currentPrice = pricesMenu[item] ?? 0.0;
                return ListTile(
                  title: Text(item, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("المخزن: ${stock[item]} قطعة | السعر: $currentPrice EGP"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orangeAccent),
                        tooltip: "تعديل السعر",
                        onPressed: () => _showEditPriceDialog(context, item, currentPrice),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                        onPressed: () => onUpdate(item, -1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
                        onPressed: () => onUpdate(item, 1),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}