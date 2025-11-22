import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'booking_page.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class FlightsPage extends StatefulWidget {
  final String? from;
  final String? to;
  final DateTime? departureDate;
  final DateTime? returnDate;

  const FlightsPage({
    super.key,
    this.from,
    this.to,
    this.departureDate,
    this.returnDate,
  });

  @override
  State<FlightsPage> createState() => _FlightsPageState();
}

class _FlightsPageState extends State<FlightsPage>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> outboundFlights = [];
  List<Map<String, dynamic>> returnFlights = [];
  Map<String, dynamic>? selectedOutbound;
  Map<String, dynamic>? selectedReturn;

  final user = FirebaseAuth.instance.currentUser;
  final Random _random = Random();

  bool _inReturnSelectionMode = false;

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

  @override
  void initState() {
    super.initState();
    _generateOutboundFlights();
    if (widget.returnDate != null) _generateReturnFlights();
  }

  void _generateOutboundFlights() {
    final seedDate = widget.departureDate ?? DateTime.now();
    final seed = seedDate.year * 10000 + seedDate.month * 100 + seedDate.day;
    final dailyRandom = Random(seed);

    final airlines = [
      'Philippine Airlines',
      'Cebu Pacific',
      'AirAsia',
      'PAL Express',
    ];

    List<Map<String, dynamic>>
    temp = List.generate(5 + dailyRandom.nextInt(5), (index) {
      String from =
          widget.from ?? locations[dailyRandom.nextInt(locations.length)];
      String to = widget.to ?? locations[dailyRandom.nextInt(locations.length)];
      while (to == from) {
        to = locations[dailyRandom.nextInt(locations.length)];
      }

      final depHour = 6 + dailyRandom.nextInt(12);
      final depMinute = [0, 15, 30, 45][dailyRandom.nextInt(4)];

      final depDateTime = DateTime(
        seedDate.year,
        seedDate.month,
        seedDate.day,
        depHour,
        depMinute,
      );

      final durationMinutes =
          (1 + dailyRandom.nextInt(5)) * 60 +
          [0, 15, 30, 45][dailyRandom.nextInt(4)];

      final arrDateTime = depDateTime.add(Duration(minutes: durationMinutes));

      String formatTime(DateTime dt) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      }

      return {
        'airline': airlines[dailyRandom.nextInt(airlines.length)],
        'flightNumber': 'PH${100 + dailyRandom.nextInt(900)}',
        'departure': from,
        'destination': to,
        'departureTime': formatTime(depDateTime),
        'arrivalTime': formatTime(arrDateTime),
        'duration':
            '${durationMinutes ~/ 60}h ${(durationMinutes % 60).toString().padLeft(2, '0')}m',
        'status': dailyRandom.nextBool() ? 'Scheduled' : 'Delayed',
        'price': 8000 + dailyRandom.nextInt(5000),
      };
    });

    setState(() => outboundFlights = temp);
  }

  void _generateReturnFlights() {
    final seedDate =
        widget.returnDate ??
        (widget.departureDate?.add(const Duration(days: 1)) ??
            DateTime.now().add(const Duration(days: 1)));

    final seed = seedDate.year * 10000 + seedDate.month * 100 + seedDate.day;
    final dailyRandom = Random(seed + 7);

    final airlines = [
      'Philippine Airlines',
      'Cebu Pacific',
      'AirAsia',
      'PAL Express',
    ];

    List<Map<String, dynamic>>
    temp = List.generate(5 + dailyRandom.nextInt(5), (index) {
      String from =
          widget.to ?? locations[dailyRandom.nextInt(locations.length)];
      String to =
          widget.from ?? locations[dailyRandom.nextInt(locations.length)];
      while (to == from) {
        to = locations[dailyRandom.nextInt(locations.length)];
      }

      final depHour = 6 + dailyRandom.nextInt(12);
      final depMinute = [0, 15, 30, 45][dailyRandom.nextInt(4)];

      final depDateTime = DateTime(
        seedDate.year,
        seedDate.month,
        seedDate.day,
        depHour,
        depMinute,
      );

      final durationMinutes =
          (1 + dailyRandom.nextInt(5)) * 60 +
          [0, 15, 30, 45][dailyRandom.nextInt(4)];

      final arrDateTime = depDateTime.add(Duration(minutes: durationMinutes));

      String formatTime(DateTime dt) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return '$hour:$minute $period';
      }

      return {
        'airline': airlines[dailyRandom.nextInt(airlines.length)],
        'flightNumber': 'PH${100 + dailyRandom.nextInt(900)}',
        'departure': from,
        'destination': to,
        'departureTime': formatTime(depDateTime),
        'arrivalTime': formatTime(arrDateTime),
        'duration':
            '${durationMinutes ~/ 60}h ${(durationMinutes % 60).toString().padLeft(2, '0')}m',
        'status': dailyRandom.nextBool() ? 'Scheduled' : 'Delayed',
        'price': 8000 + dailyRandom.nextInt(5000),
      };
    });

    setState(() => returnFlights = temp);
  }

  @override
  Widget build(BuildContext context) {
    final hasReturn = widget.returnDate != null;
    final dateFormat = DateFormat('MMM dd, yyyy');

    return WillPopScope(
      onWillPop: () async => !_inReturnSelectionMode,
      child: DefaultTabController(
        length: hasReturn ? 2 : 1,
        child: Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 11, 66, 121),
            centerTitle: true,
            elevation: 4,
            leading: _inReturnSelectionMode ? const SizedBox.shrink() : null,
            title: Text(
              widget.from != null && widget.to != null
                  ? '${widget.from} → ${widget.to}'
                  : 'FLIGHT SCHEDULES',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            bottom: hasReturn
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(60),
                    child: Container(
                      color: const Color.fromARGB(255, 11, 66, 121),
                      padding: const EdgeInsets.only(bottom: 8),
                      child: TabBar(
                        labelColor: Colors.black, // text color selected
                        unselectedLabelColor:
                            Colors.white, // text color not selected
                        dividerColor: Colors.transparent,

                        indicator: BoxDecoration(
                          color: const Color.fromARGB(
                            255,
                            181,
                            228,
                            235,
                          ), // light blue
                          borderRadius: BorderRadius.circular(12),
                        ),

                        indicatorSize: TabBarIndicatorSize.tab,

                        overlayColor: WidgetStateProperty.all(
                          Colors.transparent,
                        ),

                        labelPadding: const EdgeInsets.symmetric(vertical: 4),

                        tabs: [
                          SizedBox(
                            height: 40, // IMPORTANT = fixes layout
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Outbound',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (widget.departureDate != null)
                                  Text(
                                    dateFormat.format(widget.departureDate!),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Return',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (widget.returnDate != null)
                                  Text(
                                    dateFormat.format(widget.returnDate!),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          body: hasReturn ? _buildRoundTripBody() : _buildOneWayBody(),
        ),
      ),
    );
  }

  Widget _buildOneWayBody() {
    return RefreshIndicator(
      onRefresh: () async => _generateOutboundFlights(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: outboundFlights.length,
        itemBuilder: (context, index) {
          final flight = outboundFlights[index];
          return _flightCard(
            flight,
            isReturnCard: false,
            onSelect: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookingPage(
                    flight: flight,
                    travelDate: widget.departureDate ?? DateTime.now(),
                    returnDate: null,
                    returnFlight: null,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRoundTripBody() {
    return TabBarView(
      children: [
        RefreshIndicator(
          onRefresh: () async => _generateOutboundFlights(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: outboundFlights.length,
            itemBuilder: (context, index) {
              final flight = outboundFlights[index];
              final isSelected =
                  selectedOutbound != null &&
                  selectedOutbound!['flightNumber'] == flight['flightNumber'];

              return _flightCard(
                flight,
                isReturnCard: false,
                selectedFlag: isSelected,
                onSelect: () {
                  setState(() {
                    selectedOutbound = flight;
                    _inReturnSelectionMode = true;
                  });

                  _generateReturnFlights();

                  final tabController = DefaultTabController.of(context);
                  if (tabController != null && tabController.length > 1) {
                    tabController.animateTo(1);
                  }
                },
              );
            },
          ),
        ),

        RefreshIndicator(
          onRefresh: () async => _generateReturnFlights(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: returnFlights.length,
            itemBuilder: (context, index) {
              final flight = returnFlights[index];
              final isSelected =
                  selectedReturn != null &&
                  selectedReturn!['flightNumber'] == flight['flightNumber'];

              return Column(
                children: [
                  _flightCard(
                    flight,
                    isReturnCard: true,
                    selectedFlag: isSelected,
                    onSelect: () {
                      setState(() {
                        selectedReturn = flight;
                      });
                    },
                  ),
                  if (index == returnFlights.length - 1)
                    const SizedBox(height: 96),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _flightCard(
    Map<String, dynamic> flight, {
    required bool isReturnCard,
    bool selectedFlag = false,
    required VoidCallback onSelect,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: selectedFlag ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  flight['departureTime'],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Column(
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    size: 26,
                    color: Colors.amber[700],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    flight['duration'],
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ],
              ),
              SizedBox(
                width: 60,
                child: Text(
                  flight['arrivalTime'],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  "Depart – ${flight['departure']}",
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  "Arrive – ${flight['destination']}",
                  style: GoogleFonts.poppins(fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight['airline'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      flight['flightNumber'],
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "PHP ${flight['price']}.00",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1155CC),
                    ),
                  ),
                  Text(
                    "All-in Fare/guest",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          ElevatedButton(
            onPressed: onSelect,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedFlag
                  ? Colors.green
                  : const Color.fromARGB(255, 78, 127, 186),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              selectedFlag
                  ? (isReturnCard ? "Selected (Return)" : "Selected (Outbound)")
                  : (isReturnCard ? "Select Return" : "Select Outbound"),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          if (isReturnCard &&
              selectedReturn != null &&
              selectedReturn!['flightNumber'] == flight['flightNumber'])
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingPage(
                        flight: selectedOutbound ?? outboundFlights.first,
                        travelDate: widget.departureDate ?? DateTime.now(),
                        returnDate: widget.returnDate,
                        returnFlight: selectedReturn,
                      ),
                    ),
                  ).then((_) {
                    setState(() => _inReturnSelectionMode = false);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 56, 82, 163),
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Proceed to Booking",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
