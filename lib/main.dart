import 'package:flutter/material.dart';

void main() => runApp(const GreenStepsApp());

class GreenStepsApp extends StatelessWidget {
  const GreenStepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const forest = Color(0xFF173D32);
    return MaterialApp(
      title: 'Green Steps | Carbon snapshot',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F7F2),
        colorScheme: ColorScheme.fromSeed(
            seedColor: forest, brightness: Brightness.light),
      ),
      home: const FootprintHome(),
    );
  }
}

class FootprintHome extends StatefulWidget {
  const FootprintHome({super.key});

  @override
  State<FootprintHome> createState() => _FootprintHomeState();
}

class _FootprintHomeState extends State<FootprintHome> {
  final List<double> _amounts = [1.8, 16.8, 4.9];
  final TextEditingController _distanceController =
      TextEditingController(text: '15');
  final TextEditingController _energyController =
      TextEditingController(text: '7');
  double _distanceKm = 15;
  int _mealCount = 21;
  double _energyKwh = 7;
  String _transportMode = 'Car';
  String _selectedPeriod = 'This week';

  // Illustrative lab demo factors. Replace with sourced local factors for real estimates.
  static const transportFactors = <String, double>{
    'Car': .12,
    'Bus': .08,
    'Motorcycle': .05,
    'Train': .04,
    'Walk / cycle': 0,
  };

  static const foodFactor = .8;

  static const energyFactor = .70;

  // Example activity amounts by selected period: km, meals, and electricity kWh.
  static const periodActivities = <String, List<double>>{
    'This week': [15, 21, 7],
    'Today': [2.5, 3, 1],
    'Yesterday': [3.3, 3, 1.2],
    'This month': [60, 90, 30],
  };

  static const categories = <FootprintCategory>[
    FootprintCategory('Transport', 'Getting around',
        Icons.directions_bike_rounded, Color(0xFFE8F2E8), Color(0xFF347454)),
    FootprintCategory('Food', 'Mixed meal estimate', Icons.eco_rounded,
        Color(0xFFF5EDDF), Color(0xFF9C7132)),
    FootprintCategory('Energy', 'Electricity use', Icons.bolt_rounded,
        Color(0xFFE9EEF5), Color(0xFF55799A)),
  ];

  double get _total => _amounts.fold(0, (sum, amount) => sum + amount);

  String get _tipMessage {
    if (_amounts.every((amount) => amount == 0)) {
      return 'Keep tracking your activities and look for one small change to try.';
    }
    final largestCategory =
        _amounts.indexOf(_amounts.reduce((a, b) => a > b ? a : b));
    return switch (largestCategory) {
      0 => 'Try walking, cycling, or sharing a ride for one short trip.',
      1 => 'Try swapping one meal for a plant-forward option.',
      _ => 'Switch off lights and unused appliances when you leave a room.',
    };
  }

  @override
  void dispose() {
    _distanceController.dispose();
    _energyController.dispose();
    super.dispose();
  }

  void _updateEstimates() {
    _amounts[0] = _distanceKm * transportFactors[_transportMode]!;
    _amounts[1] = _mealCount * foodFactor;
    _amounts[2] = _energyKwh * energyFactor;
  }

  void _onDistanceChanged(String value) {
    setState(() {
      _distanceKm = (double.tryParse(value) ?? 0).clamp(0, 100000).toDouble();
      _updateEstimates();
    });
  }

  void _adjustMeals(int change) {
    setState(() {
      _mealCount = (_mealCount + change).clamp(0, 100000);
      _updateEstimates();
    });
  }

  void _onEnergyChanged(String value) {
    setState(() {
      _energyKwh = (double.tryParse(value) ?? 0).clamp(0, 100000).toDouble();
      _updateEstimates();
    });
  }

  void _onTransportModeChanged(String? mode) {
    if (mode == null) return;
    setState(() {
      _transportMode = mode;
      _updateEstimates();
    });
  }

  void _selectPeriod(String period) {
    setState(() {
      _selectedPeriod = period;
      final activities = periodActivities[period]!;
      _distanceKm = activities[0];
      _mealCount = activities[1].round();
      _energyKwh = activities[2];
      _distanceController.text = _distanceKm.toString();
      _energyController.text = _energyKwh.toString();
      _updateEstimates();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
                  sliver: SliverList.list(children: [
                    _TopBar(
                        period: _selectedPeriod,
                        onPeriodChanged: _selectPeriod),
                    const SizedBox(height: 28),
                    const _Greeting(),
                    const SizedBox(height: 22),
                    _TotalCard(
                        total: _total,
                        amounts: _amounts,
                        period: _selectedPeriod),
                    const SizedBox(height: 28),
                    const _SectionHeading(),
                    const SizedBox(height: 5),
                    const Text(
                        'Enter activities for this period to estimate all three categories.',
                        style:
                            TextStyle(color: Color(0xFF7C8780), fontSize: 12)),
                    const SizedBox(height: 14),
                    for (var i = 0; i < categories.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: CategoryCard(
                          category: categories[i],
                          amount: _amounts[i],
                          share: _total == 0 ? 0 : _amounts[i] / _total * 100,
                          extraControls: switch (i) {
                            0 => _TransportInputs(
                                controller: _distanceController,
                                selectedMode: _transportMode,
                                factors: transportFactors,
                                onDistanceChanged: _onDistanceChanged,
                                onModeChanged: _onTransportModeChanged,
                              ),
                            1 => _FoodInputs(
                                meals: _mealCount,
                                factor: foodFactor,
                                onDecrease: () => _adjustMeals(-1),
                                onIncrease: () => _adjustMeals(1),
                              ),
                            _ => _EnergyInputs(
                                controller: _energyController,
                                factor: energyFactor,
                                onEnergyChanged: _onEnergyChanged),
                          },
                        ),
                      ),
                    const SizedBox(height: 10),
                    _TipCard(message: _tipMessage),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text('SMALL STEPS, LIGHTER FOOTPRINT',
                          style: TextStyle(
                              color: Color(0xFF87918B),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5)),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.period, required this.onPeriodChanged});
  final String period;
  final ValueChanged<String> onPeriodChanged;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
                color: const Color(0xFFE5EEE5),
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.spa_rounded,
                color: Color(0xFF285B43), size: 23),
          ),
          const SizedBox(width: 10),
          const Text('Green Steps',
              style: TextStyle(
                  color: Color(0xFF173D32),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6)),
          const Spacer(),
          PopupMenuButton<String>(
            initialValue: period,
            onSelected: onPeriodChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'This week', child: Text('This week')),
              PopupMenuItem(value: 'Today', child: Text('Today')),
              PopupMenuItem(value: 'Yesterday', child: Text('Yesterday')),
              PopupMenuItem(value: 'This month', child: Text('This month')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: const Color(0xFFE8EBE5))),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 13, color: Color(0xFF64736B)),
                const SizedBox(width: 7),
                Text(period.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                        color: Color(0xFF526259))),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 16, color: Color(0xFF64736B))
              ]),
            ),
          ),
        ],
      );
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your footprint,',
              style: TextStyle(color: Color(0xFF738078), fontSize: 16)),
          SizedBox(height: 2),
          Text('made visible.',
              style: TextStyle(
                  color: Color(0xFF193A30),
                  fontSize: 29,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.1)),
          SizedBox(height: 7),
          Text('A little awareness goes a long way.',
              style: TextStyle(color: Color(0xFF7C8780), fontSize: 13)),
        ],
      );
}

class _TotalCard extends StatelessWidget {
  const _TotalCard(
      {required this.total, required this.amounts, required this.period});
  final double total;
  final List<double> amounts;
  final String period;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(21),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF204C3D), Color(0xFF15372D)]),
          boxShadow: [
            BoxShadow(
                color: const Color(0xFF204C3D).withValues(alpha: .16),
                blurRadius: 20,
                offset: const Offset(0, 10))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('YOUR ${period.toUpperCase()} ESTIMATE',
                    style: const TextStyle(
                        color: Color(0xFFC6D8CC),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2))),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(20)),
                child: const Row(children: [
                  Icon(Icons.tune_rounded, size: 13, color: Color(0xFFBDE6C4)),
                  SizedBox(width: 4),
                  Text('editable',
                      style: TextStyle(
                          color: Color(0xFFE0F0E3),
                          fontSize: 10,
                          fontWeight: FontWeight.w600))
                ])),
          ]),
          const SizedBox(height: 9),
          Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(total.toStringAsFixed(1),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 43,
                        height: 1,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.5)),
                const SizedBox(width: 8),
                const Text('kg CO₂e',
                    style: TextStyle(
                        color: Color(0xFFD1E0D6),
                        fontSize: 15,
                        fontWeight: FontWeight.w500))
              ]),
          const SizedBox(height: 18),
          Row(children: [
            for (var i = 0; i < amounts.length; i++)
              Expanded(
                  flex: ((total == 0 ? 1 / 3 : amounts[i] / total) * 100)
                      .round()
                      .clamp(1, 100)
                      .toInt(),
                  child: Container(
                      height: 5,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                          color: const [
                            Color(0xFF9BD2A7),
                            Color(0xFFE2BC79),
                            Color(0xFF91B0CF)
                          ][i],
                          borderRadius: BorderRadius.circular(6))))
          ]),
          const SizedBox(height: 11),
          const Row(children: [
            Icon(Icons.auto_awesome_rounded,
                size: 14, color: Color(0xFFE7D29D)),
            SizedBox(width: 6),
            Text('Small activity changes add up.',
                style: TextStyle(color: Color(0xFFD8E5DC), fontSize: 11))
          ]),
        ]),
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading();

  @override
  Widget build(BuildContext context) =>
      const Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
            child: Text('Activity breakdown',
                style: TextStyle(
                    color: Color(0xFF203B31),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -.4))),
        Text('BY CATEGORY',
            style: TextStyle(
                color: Color(0xFF87918B),
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1))
      ]);
}

class FootprintCategory {
  const FootprintCategory(
      this.name, this.subtitle, this.icon, this.tint, this.accent);
  final String name, subtitle;
  final IconData icon;
  final Color tint, accent;
}

class CategoryCard extends StatelessWidget {
  const CategoryCard(
      {super.key,
      required this.category,
      required this.amount,
      required this.share,
      required this.extraControls});
  final FootprintCategory category;
  final double amount;
  final double share;
  final Widget extraControls;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEBEEE8))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                    color: category.tint,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(category.icon, color: category.accent, size: 22)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(category.name,
                      style: const TextStyle(
                          color: Color(0xFF233B31),
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(category.subtitle,
                      style: const TextStyle(
                          color: Color(0xFF89928D), fontSize: 11))
                ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(amount.toStringAsFixed(1),
                        style: const TextStyle(
                            color: Color(0xFF243D32),
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 3),
                    const Text('kg',
                        style:
                            TextStyle(color: Color(0xFF77847C), fontSize: 10))
                  ]),
              const SizedBox(height: 3),
              Text('${share.round()}% of total',
                  style:
                      const TextStyle(color: Color(0xFF89928D), fontSize: 10))
            ]),
            const SizedBox(width: 7),
          ]),
          const SizedBox(height: 12),
          extraControls,
        ]),
      );
}

class _TransportInputs extends StatelessWidget {
  const _TransportInputs(
      {required this.controller,
      required this.selectedMode,
      required this.factors,
      required this.onDistanceChanged,
      required this.onModeChanged});
  final TextEditingController controller;
  final String selectedMode;
  final Map<String, double> factors;
  final ValueChanged<String> onDistanceChanged;
  final ValueChanged<String?> onModeChanged;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: onDistanceChanged,
              decoration: const InputDecoration(
                labelText: 'Distance travelled',
                suffixText: 'km',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: selectedMode,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: 'Travel mode',
                  isDense: true,
                  border: OutlineInputBorder()),
              items: factors.keys
                  .map((mode) => DropdownMenuItem(
                      value: mode,
                      child: Text(mode, overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: onModeChanged,
            ),
          ),
        ]),
        const SizedBox(height: 6),
        Text(
          'Estimate = km × factor (${factors[selectedMode]!.toStringAsFixed(2)} kg CO₂e/km). Demo factors are illustrative.',
          style: const TextStyle(
              color: Color(0xFF7C8780), fontSize: 10, height: 1.4),
        ),
      ]);
}

class _FoodInputs extends StatelessWidget {
  const _FoodInputs(
      {required this.meals,
      required this.factor,
      required this.onDecrease,
      required this.onIncrease});
  final int meals;
  final double factor;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(
              child: Text('Meals this period',
                  style: TextStyle(
                      color: Color(0xFF526259),
                      fontSize: 12,
                      fontWeight: FontWeight.w600))),
          IconButton(
              onPressed: meals > 0 ? onDecrease : null,
              tooltip: 'Remove one meal',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              icon: const Icon(Icons.remove_circle_outline_rounded)),
          SizedBox(
              width: 34,
              child: Text('$meals',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Color(0xFF243D32),
                      fontSize: 18,
                      fontWeight: FontWeight.w700))),
          IconButton(
              onPressed: onIncrease,
              tooltip: 'Add one meal',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              icon: const Icon(Icons.add_circle_outline_rounded,
                  color: Color(0xFF347454))),
        ]),
        const SizedBox(height: 6),
        Text(
          'Mixed profile · estimate = meals × ${factor.toStringAsFixed(2)} kg CO₂e/meal (demo factor).',
          style: const TextStyle(
              color: Color(0xFF7C8780), fontSize: 10, height: 1.4),
        ),
      ]);
}

class _EnergyInputs extends StatelessWidget {
  const _EnergyInputs(
      {required this.controller,
      required this.factor,
      required this.onEnergyChanged});
  final TextEditingController controller;
  final double factor;
  final ValueChanged<String> onEnergyChanged;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onEnergyChanged,
          decoration: const InputDecoration(
              labelText: 'Electricity used',
              suffixText: 'kWh',
              isDense: true,
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 6),
        Text(
          'Estimate = kWh × demo grid factor (${factor.toStringAsFixed(2)} kg CO₂e/kWh).',
          style: const TextStyle(
              color: Color(0xFF7C8780), fontSize: 10, height: 1.4),
        ),
      ]);
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
            color: const Color(0xFFEAF0E8),
            borderRadius: BorderRadius.circular(18)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .8),
                  borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.lightbulb_outline_rounded,
                  color: Color(0xFF567A54), size: 18)),
          const SizedBox(width: 11),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('A gentle idea',
                    style: TextStyle(
                        color: Color(0xFF34543C),
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(
                        color: Color(0xFF687B6B), fontSize: 11, height: 1.4))
              ])),
          const Icon(Icons.arrow_forward_rounded,
              size: 16, color: Color(0xFF729075)),
        ]),
      );
}
