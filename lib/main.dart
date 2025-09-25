import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const OnePayReportApp());
}

class OnePayReportApp extends StatelessWidget {
  const OnePayReportApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MobilityOne Test Interview',
      theme: ThemeData(
        primarySwatch: Colors.green,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.green)
            .copyWith(secondary: Colors.amber),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

/// ---------------- SPLASH SCREEN -----------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 2));

    _scale = Tween<double>(begin: 0.5, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _opacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const ReportPage()));
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: ScaleTransition(
          scale: _scale,
          child: FadeTransition(
            opacity: _opacity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.mobile_friendly,
                    size: 80, color: Colors.amber),
                SizedBox(height: 20),
                Text("MobilityOne Test Interview",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                SizedBox(height: 8),
                Text("by Muhammad Shahir",
                    style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        color: Colors.amber)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------------- MAIN PAGE -----------------
class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  static const String merchantKey = 'aaabbbccc1987238812';
  static const String channel = 'ISO';
  static const String url =
      'https://uat.onepay.com.my:65002/M1RSv1/M1RS.aspx';

  final _formKey = GlobalKey<FormState>();
  final _midCtrl = TextEditingController(text: '609340082007580');
  final _tidCtrl = TextEditingController();
  final _txnIdCtrl = TextEditingController();
  final _beneCtrl = TextEditingController();
  final _prodCtrl = TextEditingController();
  final _txnStatusCtrl = TextEditingController();
  final _maxRowCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _loading = false;
  String? _rawResponse;
  List<dynamic>? _reportRows;
  String _message = '';

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  String _sha512Hex(String input) {
    final bytes = utf8.encode(input);
    return sha512.convert(bytes).toString();
  }

  String computeAuthToken(
      {required String mid, required String tid, required String bene}) {
    final inner = _sha512Hex(merchantKey + channel + mid + tid + bene);
    return _sha512Hex(merchantKey + inner);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      setState(() => _message = 'Please select StartDate and EndDate.');
      return;
    }

    setState(() {
      _loading = true;
      _message = '';
      _rawResponse = null;
      _reportRows = null;
    });

    final body = {
      "OpName": "WSC_GetReport",
      "AuthToken": computeAuthToken(
          mid: _midCtrl.text, tid: _tidCtrl.text, bene: _beneCtrl.text),
      "Channel": channel,
      "MID": _midCtrl.text,
      "TID": _tidCtrl.text,
      "RefID": _txnIdCtrl.text,
      "ReportType": "M1-IV-TEST-API",
      "StartDate": _formatDate(_startDate!),
      "EndDate": _formatDate(_endDate!),
      "TxnID": _txnIdCtrl.text,
      "BeneAcctNo": _beneCtrl.text,
      "ProdCode": _prodCtrl.text,
      "TxnStatus": _txnStatusCtrl.text,
      "MaxRow": _maxRowCtrl.text,
    };

    try {
      final resp = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      setState(() {
        _rawResponse =
            const JsonEncoder.withIndent('  ').convert(jsonDecode(resp.body));
        final parsed = jsonDecode(resp.body);
        if (parsed is Map && parsed['Report'] is List) {
          _reportRows = parsed['Report'];
        }
      });
    } catch (e) {
      setState(() => _message = 'Request failed: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {IconData? icon,
      String? hint,
      TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: Colors.green) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("MobilityOne Test Interview"),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: SingleChildScrollView(
          key: ValueKey(_loading.toString() + _reportRows.toString()),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(true),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: "Start Date",
                                    prefixIcon: Icon(Icons.calendar_today,
                                        color: Colors.green),
                                  ),
                                  child: Text(_startDate == null
                                      ? "Select"
                                      : _formatDate(_startDate!)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: () => _pickDate(false),
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: "End Date",
                                    prefixIcon: Icon(Icons.calendar_today,
                                        color: Colors.green),
                                  ),
                                  child: Text(_endDate == null
                                      ? "Select"
                                      : _formatDate(_endDate!)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildField("MID", _midCtrl,
                            icon: Icons.confirmation_number),
                        _buildField("TID", _tidCtrl, icon: Icons.numbers),
                        _buildField("TxnID / RefID", _txnIdCtrl,
                            icon: Icons.receipt),
                        _buildField("BeneAcctNo", _beneCtrl,
                            icon: Icons.account_balance),
                        _buildField("ProdCode", _prodCtrl, icon: Icons.category),
                        _buildField("TxnStatus", _txnStatusCtrl,
                            type: TextInputType.number, icon: Icons.info),
                        _buildField("MaxRow", _maxRowCtrl,
                            type: TextInputType.number,
                            icon: Icons.format_list_numbered),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const CircularProgressIndicator(
                                    color: Colors.amber)
                                : const Text("Search"),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_message.isNotEmpty)
                Text(_message, style: const TextStyle(color: Colors.red)),
              if (_reportRows != null) ...[
                const Text("Report Results",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                AnimatedList(
                  shrinkWrap: true,
                  initialItemCount: _reportRows!.length,
                  itemBuilder: (context, i, animation) {
                    final item = _reportRows![i];
                    return SizeTransition(
                      sizeFactor: animation,
                      child: Card(
                        color: Colors.green.shade50,
                        child: ListTile(
                          title: Text(item['TxnID'] ?? 'Transaction'),
                          subtitle: Text(item.toString()),
                          leading: const Icon(Icons.payment,
                              color: Colors.green),
                        ),
                      ),
                    );
                  },
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}