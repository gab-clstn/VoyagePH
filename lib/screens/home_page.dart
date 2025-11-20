import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  String tripType = 'Round Trip';
  DateTime? departureDate;
  DateTime? returnDate;

  String? fromLocation;
  String? toLocation;

  final List<String> locations = [
    'Bacolod',
    'Bohol',
    'Boracay (Caticlan)',
    'Butuan',
    'Cagayan De Oro',
    'Calbayog',
    'Camiguin',
    'Cauayan',
    'Cebu',
    'Clark',
    'Coron (Basuanga)',
    'Cotabato',
    'Davao',
    'Dipolog',
    'Dumaguete',
    'El Nido',
    'General Santos',
    'Iloilo',
    'Kalibo',
    'Laoag',
    'Legazpi (Daraga)',
    'Manila',
    'Masbate',
    'Naga',
    'Ozamiz',
    'Pagadian',
    'Puerto Princesa',
    'Roxas',
    'San Jose (Mindoro)',
    'San Vicente (Port Barton)',
    'Siargao',
    'Surigao',
    'Tacloban',
    'Tawi-Tawi',
    'Tuguegarao',
    'Virac',
    'Zamboanga',
  ];

  final List<String> heroImages = [
    "assets/images/cebu.jpg",
    "assets/images/boracay.jpg",
    "assets/images/bacolod.jpg",
    "assets/images/davao.jpg",
    "assets/images/laoag.jpg",
    "assets/images/manila.jpg",
    "assets/images/palawan.jpg",
    "assets/images/siargao.jpg",
  ];

  late AnimationController _zoomController;
  late Animation<double> _zoomAnimation;

  @override
  void initState() {
    super.initState();

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat(reverse: true);

    _zoomAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _zoomController, curve: Curves.easeInOut),
    );

    // Auto slide every 4 seconds
    Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final next = (_currentPage + 1) % heroImages.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isDeparture) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isDeparture
          ? (departureDate ?? DateTime.now())
          : (returnDate ?? DateTime.now().add(const Duration(days: 1))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isDeparture) {
          departureDate = picked;
          if (returnDate != null && returnDate!.isBefore(departureDate!)) {
            returnDate = departureDate!.add(const Duration(days: 1));
          }
        } else {
          returnDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(),
            const SizedBox(height: 40),
            _buildSectionTitle("Discover the Philippines"),
            _buildDestinationGrid(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: 420,
      width: double.infinity,
      child: Stack(
        children: [
          // Hero image
          PageView.builder(
            controller: _pageController,
            itemCount: heroImages.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (_, index) {
              return ClipRRect(
                child: AnimatedBuilder(
                  animation: _zoomController,
                  builder: (_, child) => Transform.scale(
                    scale: _zoomAnimation.value,
                    child: child,
                  ),
                  child: Image.asset(
                    heroImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
          // Gradient overlay
          Container(
            height: 420,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.1),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          // Floating card
          Positioned(
            top: 20,
            left: 16,
            right: 16,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _tripTypeButton('Round Trip'),
                        _tripTypeButton('One Way'),
                        _tripTypeButton('Multi-City'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _customDropdownField(
                      label: 'From',
                      selected: fromLocation,
                      options: locations,
                      onChanged: (val) {
                        setState(() {
                          fromLocation = val;
                          if (toLocation == val) toLocation = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _customDropdownField(
                      label: 'To',
                      selected: toLocation,
                      options: locations
                          .where((loc) => loc != fromLocation)
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          toLocation = val;
                          if (fromLocation == val) fromLocation = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _dateField(
                            'Departure',
                            departureDate,
                            () => _selectDate(context, true),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dateField(
                            'Return',
                            returnDate,
                            () => _selectDate(context, false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Search Flights",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripTypeButton(String type) {
    final isSelected = tripType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => tripType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _customDropdownField({
    required String label,
    required String? selected,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<String>(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SizedBox(
              height: 300,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected = option == selected;
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context, option);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blue
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              option,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (result != null) {
          onChanged(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(20),
          color: Colors.grey[100],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selected ?? label,
              style: TextStyle(
                color: selected == null ? Colors.grey[700] : Colors.black,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[100],
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              date != null ? DateFormat('MMM dd, yyyy').format(date) : label,
              style: TextStyle(
                color: date != null ? Colors.black : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDestinationGrid() {
    final destinations = [
      {"name": "Boracay", "image": "assets/images/boracay.jpg"},
      {"name": "Cebu", "image": "assets/images/cebu.jpg"},
      {"name": "Palawan", "image": "assets/images/palawan.jpg"},
      {"name": "Siargao", "image": "assets/images/siargao.jpg"},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: destinations.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 3 / 4,
        ),
        itemBuilder: (_, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Image.asset(
                  destinations[index]["image"]!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(color: Colors.black26),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Text(
                    destinations[index]["name"]!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
