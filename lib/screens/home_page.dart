import 'dart:async';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --------------------------------------------------------------
  // SLIDESHOW CONTROLLER + IMAGES
  // --------------------------------------------------------------
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> heroImages = [
    "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=1200&q=80", // Boracay
    "https://images.unsplash.com/photo-1505739773434-c246b2f3e9a3?auto=format&fit=crop&w=1200&q=80", // Cebu
    "https://images.unsplash.com/photo-1500375592092-40eb2168fd21?auto=format&fit=crop&w=1200&q=80", // Palawan
    "https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1200&q=80", // Siargao
  ];

  @override
  void initState() {
    super.initState();

    // AUTO-SLIDE (every 4 seconds)
    Timer.periodic(const Duration(seconds: 4), (Timer t) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % heroImages.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------
  // PAGE UI
  // --------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroBanner(),
            const SizedBox(height: 20),
            _buildSectionTitle("Discover the Philippines"),
            _buildDestinationGrid(),
            const SizedBox(height: 20),
            _buildSectionTitle("Latest Promos"),
            _buildPromoCarousel(),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // HERO BANNER (SLIDESHOW + SEARCH BOX)
  // --------------------------------------------------------------
  Widget _buildHeroBanner() {
    return Stack(
      children: [
        SizedBox(
          height: 260,
          width: double.infinity,
          child: PageView.builder(
            controller: _pageController,
            itemCount: heroImages.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (_, index) {
              return Image.network(heroImages[index], fit: BoxFit.cover);
            },
          ),
        ),

        // GRADIENT OVERLAY
        Container(
          height: 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black.withOpacity(0.35),
                Colors.black.withOpacity(0.1),
                Colors.transparent,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),

        // DOT INDICATOR
        Positioned(
          bottom: 90,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(heroImages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.white : Colors.white54,
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          ),
        ),

        // SEARCH CARD
        Positioned(
          bottom: 0,
          left: 16,
          right: 16,
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _inputField(label: "From", icon: Icons.flight_takeoff),
                  const SizedBox(height: 12),
                  _inputField(label: "To", icon: Icons.flight_land),
                  const SizedBox(height: 12),
                  _inputField(
                    label: "Departure Date",
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 12),
                  _searchButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------
  // INPUT FIELD
  // --------------------------------------------------------------
  Widget _inputField({required String label, required IconData icon}) {
    return TextField(
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --------------------------------------------------------------
  // SEARCH BUTTON
  // --------------------------------------------------------------
  Widget _searchButton() {
    return SizedBox(
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
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------
  // SECTION TITLE
  // --------------------------------------------------------------
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

  // --------------------------------------------------------------
  // DESTINATION GRID
  // --------------------------------------------------------------
  Widget _buildDestinationGrid() {
    final List<Map<String, String>> destinations = [
      {
        "name": "Boracay",
        "image":
            "https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=600",
      },
      {
        "name": "Cebu",
        "image":
            "https://images.unsplash.com/photo-1505739773434-c246b2f3e9a3?auto=format&fit=crop&q=80&w=900",
      },
      {
        "name": "Palawan",
        "image":
            "https://images.unsplash.com/photo-1500375592092-40eb2168fd21?w=600",
      },
      {
        "name": "Siargao",
        "image":
            "https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=600",
      },
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
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                Image.network(
                  destinations[index]["image"]!,
                  fit: BoxFit.cover,
                  width: double.infinity,
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

  // --------------------------------------------------------------
  // PROMO CAROUSEL
  // --------------------------------------------------------------
  Widget _buildPromoCarousel() {
    final promos = [
      "https://images.unsplash.com/photo-1483683804023-6ccdb62f86ef?w=800",
      "https://images.unsplash.com/photo-1519681393784-d120267933ba?w=800",
      "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=800",
    ];

    return SizedBox(
      height: 150,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: promos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(promos[index], width: 250, fit: BoxFit.cover),
          );
        },
      ),
    );
  }
}
