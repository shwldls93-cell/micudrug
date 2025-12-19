import 'package:flutter/material.dart';

void main() {
  runApp(const DrugCalcApp());
}

// 약물 정보를 담는 데이터 클래스 (구조체)
class Drug {
  final String name;          // 약물명
  final String mixInfo;       // 믹스 정보
  final String rangeInfo;     // 최소~최대 용량 정보
  final String formulaText;   // 보여줄 계산 공식 텍스트
  final double solute;        // 용질 (약물 총량)
  final double solvent;       // 용매 (수액 총량)
  final bool isWeightBased;   // 체중 비례 여부 (kg 필요?)
  final bool isPerMinute;     // 분 단위 여부 (min -> *60 필요?)
  final double minDose;       // 안전 최소 용량 (숫자)
  final double maxDose;       // 안전 최대 용량 (숫자)
  final bool isProtocol;      // 계산이 아닌 프로토콜 텍스트를 보여줄 경우 (예: 아미오다론)

  Drug({
    required this.name,
    required this.mixInfo,
    required this.rangeInfo,
    required this.formulaText,
    required this.solute,
    required this.solvent,
    this.isWeightBased = true,
    this.isPerMinute = false,
    this.minDose = 0,
    this.maxDose = 0,
    this.isProtocol = false,
  });
}

class DrugCalcApp extends StatelessWidget {
  const DrugCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '간호사 약물 계산기',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF2F4F6),
        primaryColor: const Color(0xFF3182F6),
        fontFamily: 'Pretendard',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF2F4F6),
          elevation: 0,
          titleTextStyle: TextStyle(
              color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3182F6),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: const CalculationScreen(),
    );
  }
}

class CalculationScreen extends StatefulWidget {
  const CalculationScreen({super.key});

  @override
  State<CalculationScreen> createState() => _CalculationScreenState();
}

class _CalculationScreenState extends State<CalculationScreen> {
  // 컨트롤러
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  
  // 선택된 약물 (기본값: 첫 번째 약물)
  late Drug _selectedDrug;
  String _resultText = "계산하기를 눌러주세요";
  Color _resultColor = Colors.grey;

  // 📋 약물 데이터 리스트 (보내주신 23종 완벽 반영)
  final List<Drug> _drugList = [
    Drug(
      name: 'Precedex (프리세덱스)',
      mixInfo: '400mcg / 100ml (premix)',
      rangeInfo: '0.1 ~ 1.0 (mcg/kg/hr)',
      formulaText: '(용량 * 체중 * 100) / 400',
      solute: 400, solvent: 100, isPerMinute: false,
      minDose: 0.1, maxDose: 1.0,
    ),
    Drug(
      name: 'Remifentanil',
      mixInfo: '2000mcg(2vial) + 5DW 40ml',
      rangeInfo: '0.01 ~ 0.1 (mcg/kg/min)',
      formulaText: '(용량 * 체중 * 40 * 60) / 2000',
      solute: 2000, solvent: 40, isPerMinute: true,
      minDose: 0.01, maxDose: 0.1,
    ),
    Drug(
      name: 'Sufentanil',
      mixInfo: '200mcg(4@) + 5DW 40ml',
      rangeInfo: '0.2 ~ 1 (mcg/kg/hr)',
      formulaText: '(용량 * 체중 * 40 * 1) / 200',
      solute: 200, solvent: 40, isPerMinute: false,
      minDose: 0.2, maxDose: 1.0,
    ),
    Drug(
      name: 'Propofol (2%)',
      mixInfo: '2% 50ml/1000mg (premix)',
      rangeInfo: '10 ~ 50 (mcg/kg/min)',
      formulaText: '(용량 * 체중 * 50 * 60) / 1,000,000',
      solute: 1000000, solvent: 50, isPerMinute: true,
      minDose: 10, maxDose: 50,
    ),
    Drug(
      name: 'Rocuronium',
      mixInfo: '250mg(5vial) + 5DW 50ml',
      rangeInfo: '0.2 ~ 10 (mg/kg/hr)',
      formulaText: '(용량 * 체중 * 50 * 1) / 250',
      solute: 250, solvent: 50, isPerMinute: false,
      minDose: 0.2, maxDose: 10,
    ),
    Drug(
      name: 'Ketamine',
      mixInfo: '500mg(2@) + 5DW 250ml',
      rangeInfo: '0.2 ~ 4 (mg/kg/hr)',
      formulaText: '(용량 * 체중 * 250 * 1) / 250',
      solute: 250, solvent: 250, isPerMinute: false,
      minDose: 0.2, maxDose: 4,
    ),
    Drug(
      name: 'Midazolam',
      mixInfo: '45mg(3@) + 5DW 45ml',
      rangeInfo: '1 ~ 제한없음 (mg/hr)',
      formulaText: '(용량 * 45 * 1) / 45',
      solute: 45, solvent: 45, isWeightBased: false, isPerMinute: false,
      minDose: 1, maxDose: 9999,
    ),
    Drug(
      name: 'Norphin (Central)',
      mixInfo: '12mg(3@) + 5DW 200ml',
      rangeInfo: '1 ~ 64 (mcg/min)',
      formulaText: '(용량 * 200 * 60) / 12,000',
      solute: 12000, solvent: 200, isWeightBased: false, isPerMinute: true,
      minDose: 1, maxDose: 64,
    ),
    Drug(
      name: 'Norphin (PPH)',
      mixInfo: '6mg(1.5@) + 5DW 200ml',
      rangeInfo: '1 ~ 20 (mcg/min)',
      formulaText: '(용량 * 200 * 60) / 6,000',
      solute: 6000, solvent: 200, isWeightBased: false, isPerMinute: true,
      minDose: 1, maxDose: 20,
    ),
    Drug(
      name: 'Vasopressin',
      mixInfo: '40iu(2@) + 5DW 100ml',
      rangeInfo: '0.01 ~ 0.1 (iu/min)',
      formulaText: '(용량 * 100 * 60) / 40',
      solute: 40, solvent: 100, isWeightBased: false, isPerMinute: true,
      minDose: 0.01, maxDose: 0.1,
    ),
    Drug(
      name: 'Dopamine',
      mixInfo: '400mg/200ml (premix)',
      rangeInfo: '3 ~ 20 (mcg/kg/min)',
      formulaText: '(용량 * 체중 * 200 * 60) / 400,000',
      solute: 400000, solvent: 200, isPerMinute: true,
      minDose: 3, maxDose: 20,
    ),
    Drug(
      name: 'Dobutamine',
      mixInfo: '500mg/250ml (premix)',
      rangeInfo: '3 ~ 20 (mcg/kg/min)',
      formulaText: '(용량 * 체중 * 250 * 60) / 500,000',
      solute: 500000, solvent: 250, isPerMinute: true,
      minDose: 3, maxDose: 20,
    ),
    Drug(
      name: 'Epinephrine',
      mixInfo: '10mg(10@) + 5DW 100ml',
      rangeInfo: '0.02 ~ 0.7 (mcg/kg/min)',
      formulaText: '(용량 * 체중 * 100 * 60) / 10,000',
      solute: 10000, solvent: 100, isPerMinute: true,
      minDose: 0.02, maxDose: 0.7,
    ),
    Drug(
      name: 'Nicardipine',
      mixInfo: '50mg(5@) + 5DW 250ml',
      rangeInfo: '1 ~ 15 (mg/hr)',
      formulaText: '(용량 * 250 * 1) / 50',
      solute: 50, solvent: 250, isWeightBased: false, isPerMinute: false,
      minDose: 1, maxDose: 15,
    ),
    Drug(
      name: 'Nitroglycerin',
      mixInfo: '50mg + 5DW 250ml',
      rangeInfo: '10 ~ 200 (mcg/min)',
      formulaText: '(용량 * 250 * 60) / 50,000',
      solute: 50000, solvent: 250, isWeightBased: false, isPerMinute: true,
      minDose: 10, maxDose: 200,
    ),
    Drug(
      name: 'Esmolol',
      mixInfo: '2500mg(1vial) + 5DW 250ml',
      rangeInfo: '50 ~ 300 (mcg/kg/min)\n(Loading: 250-500mcg/kg 1min)',
      formulaText: '(용량 * 체중 * 250 * 60) / 2,500,000',
      solute: 2500000, solvent: 250, isPerMinute: true,
      minDose: 50, maxDose: 300,
    ),
    Drug(
      name: 'Diltiazem',
      mixInfo: '100mg(2vial) + 5DW 100ml',
      rangeInfo: '5 ~ 50 (mg/hr)',
      formulaText: '(용량 * 100 * 1) / 100',
      solute: 100, solvent: 100, isWeightBased: false, isPerMinute: false,
      minDose: 5, maxDose: 50,
    ),
    Drug(
      name: 'Amiodarone', // ⚠️ 프로토콜 특이 케이스
      mixInfo: '900mg(6@) + 5DW 500ml',
      rangeInfo: 'Loading: 150-300mg (10min 이상)',
      formulaText: '첫 6시간: 1mg/min (33.3cc/hr)\n다음 18시간: 0.5mg/min (16.7cc/hr)',
      solute: 0, solvent: 0, isProtocol: true,
      minDose: 0, maxDose: 0,
    ),
    Drug(
      name: 'Lidocaine',
      mixInfo: '1600mg(8vial) + 5DW 200ml',
      rangeInfo: '0.5 ~ 4 (mg/min)',
      formulaText: '(용량 * 200 * 60) / 1,600',
      solute: 1600, solvent: 200, isWeightBased: false, isPerMinute: true,
      minDose: 0.5, maxDose: 4,
    ),
    Drug(
      name: 'Isoprel',
      mixInfo: '1mg(5@) + 5DW 500ml',
      rangeInfo: '0.5 ~ 5 (mcg/min)',
      formulaText: '(용량 * 500 * 60) / 1,000',
      solute: 1000, solvent: 500, isWeightBased: false, isPerMinute: true,
      minDose: 0.5, maxDose: 5,
    ),
    Drug(
      name: 'Milrinone',
      mixInfo: '50mg + 5DW 200ml',
      rangeInfo: '0.25 ~ 0.75 (mcg/kg/min)',
      formulaText: '(용량 * 체중 * 200 * 60) / 50,000',
      solute: 50000, solvent: 200, isPerMinute: true,
      minDose: 0.25, maxDose: 0.75,
    ),
    Drug(
      name: 'Heparine',
      mixInfo: '25,000iu(1vial) + 5DW 500ml',
      rangeInfo: '12iu/kg/hr ~ 1000iu/hr',
      formulaText: '(용량 * 체중 * 500 * 1) / 25,000',
      solute: 25000, solvent: 500, isPerMinute: false,
      minDose: 12, maxDose: 1000,
    ),
    Drug(
      name: 'Novastan',
      mixInfo: '20mg(2@) + 5DW 100ml',
      rangeInfo: '0.5 ~ 10 (mcg/kg/min)',
      formulaText: '(용량 * 체중 * 100 * 60) / 20,000',
      solute: 20000, solvent: 100, isPerMinute: true,
      minDose: 0.5, maxDose: 10,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDrug = _drugList[0]; // 초기값 설정
  }

  void _calculate() {
    // 아미오다론 같은 프로토콜 약물은 계산 건너뜀
    if (_selectedDrug.isProtocol) {
      setState(() {
        _resultText = "아래 프로토콜을\n참고하세요";
        _resultColor = const Color(0xFF3182F6);
      });
      return;
    }

    setState(() {
      double? weight = double.tryParse(_weightController.text);
      double? dose = double.tryParse(_doseController.text);

      // 1. 유효성 검사
      if (dose == null) {
        _resultText = "용량을 입력해주세요";
        _resultColor = Colors.red;
        return;
      }
      if (_selectedDrug.isWeightBased && weight == null) {
        _resultText = "몸무게를 입력해주세요";
        _resultColor = Colors.red;
        return;
      }

      // 2. 계산 로직 (유저가 준 공식 자동 적용)
      // Rate = (Dose * Weight(if needed) * Solvent * TimeFactor) / Solute
      
      double weightFactor = _selectedDrug.isWeightBased ? weight! : 1.0;
      double timeFactor = _selectedDrug.isPerMinute ? 60.0 : 1.0;

     double rate = (dose * weightFactor * _selectedDrug.solvent * timeFactor) / _selectedDrug.solute;

// 🔹 반올림 규칙 적용
String displayRate;

if (_selectedDrug.name.toLowerCase().contains('heparin')) {
  // Heparin: 소수점 첫째자리에서 반올림 → 정수
  int roundedRate = rate.round();
  displayRate = roundedRate.toString();
} else {
  // 일반 약물: 소수점 둘째자리에서 반올림 → 소수점 첫째자리
  double roundedRate = (rate * 10).round() / 10;
  displayRate = roundedRate.toStringAsFixed(1);
}

// 3. 결과 표시
_resultText = "$displayRate cc/hr";

      // 4. 안전 범위 체크
      if (dose < _selectedDrug.minDose!) {
        _resultColor = Colors.orange; // 최소 미만 경고
        _resultText += "\n(최소 용량 미만)";
      } else if (dose > _selectedDrug.maxDose!) {
        _resultColor = Colors.red; // 최대 초과 경고
        _resultText += "\n(최대 용량 초과)";
      } else {
        _resultColor = const Color(0xFF3182F6); // 정상 (토스 블루)
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("약물 계산기")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 입력 카드
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("약물 선택"),
                  const SizedBox(height: 8),
                  _buildDropdown(),
                  
                  // 💡 약물 선택 시 뜨는 메모 (Mix, 공식, Range)
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMemoRow("📝 Mix", _selectedDrug.mixInfo),
                        const SizedBox(height: 8),
                        _buildMemoRow("⚖️ Range", _selectedDrug.rangeInfo),
                        const SizedBox(height: 8),
                        _buildMemoRow("🧮 공식", _selectedDrug.formulaText),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // 체중 기반 약물이 아닐 경우 몸무게 입력칸 숨김/비활성화
                  if (_selectedDrug.isWeightBased) ...[
                    _buildLabel("환자 몸무게 (kg)"),
                    const SizedBox(height: 8),
                    _buildTextField(_weightController, "예: 60"),
                    const SizedBox(height: 24),
                  ] else ...[
                     Text("※ 이 약물은 몸무게 입력이 필요 없습니다.", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                     const SizedBox(height: 24),
                  ],
                  
                  _buildLabel("목표 용량"),
                  const SizedBox(height: 8),
                  _buildTextField(_doseController, "숫자만 입력하세요"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. 계산 버튼
            ElevatedButton(
              onPressed: _calculate,
              child: const Text("계산하기"),
            ),

            const SizedBox(height: 30),

            // 3. 결과 표시 영역
            Center(
              child: Column(
                children: [
                  const Text("주입 속도 (cc/hr)", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                    _resultText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32, 
                      fontWeight: FontWeight.bold,
                      color: _resultColor
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 작은 위젯들
  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF4E5968)));
  }

  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(12)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Drug>(
          value: _selectedDrug,
          isExpanded: true,
          items: _drugList.map((Drug drug) {
            return DropdownMenuItem<Drug>(
              value: drug,
              child: Text(drug.name, style: const TextStyle(fontSize: 16)),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedDrug = newValue!;
              _resultText = "계산하기를 눌러주세요"; // 약물 바꾸면 결과 초기화
              _resultColor = Colors.grey;
            });
          },
        ),
      ),
    );
  }

  Widget _buildMemoRow(String label, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 70, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87))),
        Expanded(child: Text(content, style: const TextStyle(fontSize: 13, color: Colors.black54))),
      ],
    );
  }
}