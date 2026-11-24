import 'package:flutter/material.dart';
import 'registration_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  final PageController _controller = PageController();

  int currentPage = 0;

  final List<Map<String, String>> pages = [

    {
      'title': 'Discover Events Around You',
      'description':
      'Find exciting events happening around you, from concerts and football matches to conferences, birthdays and more.',
      'number': '01',
    },

    {
      'title': 'Tickets at Your Fingertips',
      'description':
      'No need to travel or stand in long queues. Browse events and purchase your tickets wherever you are.',
      'number': '02',
    },

    {
      'title': 'Every Ticket, Verified',
      'description':
      'Enjoy peace of mind with unique digital tickets that can be verified at the entrance to prevent duplication and fraudulent entry.',
      'number': '03',
    },

  ];

  void nextPage() {

    if (currentPage < 2) {

      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

    } else {

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RegistrationScreen(),
        ),
      );

    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: SafeArea(

        child: Padding(

          padding: const EdgeInsets.symmetric(horizontal: 25),

          child: Column(

            children: [

              const SizedBox(height: 35),

              // App name

              Align(
                alignment: Alignment.centerLeft,

                child: RichText(

                  text: const TextSpan(

                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),

                    children: [

                      TextSpan(
                        text: 'Tick',
                        style: TextStyle(color: Color(0xFF222222)),
                      ),

                      TextSpan(
                        text: 'et',
                        style: TextStyle(color: Color(0xFFF28C28)),
                      ),

                    ],

                  ),
                ),
              ),

              const SizedBox(height: 35),

              // Introduction pages

              Expanded(

                child: PageView.builder(

                  controller: _controller,

                  itemCount: pages.length,

                  onPageChanged: (index) {

                    setState(() {
                      currentPage = index;
                    });

                  },

                  itemBuilder: (context, index) {

                    return Column(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        // Illustration area

                        Container(

                          height: 260,
                          width: double.infinity,

                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF5EA),
                            borderRadius: BorderRadius.circular(25),
                          ),

                          child: Center(

                            child: Container(

                              height: 145,
                              width: 220,

                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),

                                boxShadow: [

                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.10),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),

                                ],
                              ),

                              child: Column(

                                mainAxisAlignment: MainAxisAlignment.center,

                                children: [

                                  Text(
                                    pages[index]['number']!,
                                    style: const TextStyle(
                                      color: Color(0xFFF28C28),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  Container(
                                    height: 3,
                                    width: 110,
                                    color: const Color(0xFFF28C28),
                                  ),

                                  const SizedBox(height: 12),

                                  const Text(
                                    'YOUR NEXT EXPERIENCE',
                                    style: TextStyle(
                                      fontSize: 11,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF777777),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  const Text(
                                    'One ticket. One experience.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF222222),
                                    ),
                                  ),

                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 45),

                        // Heading

                        Text(

                          pages[index]['title']!,

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF222222),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Description

                        Text(

                          pages[index]['description']!,

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.7,
                            color: Color(0xFF777777),
                          ),
                        ),

                      ],
                    );

                  },
                ),
              ),

              // Page indicators

              Row(

                mainAxisAlignment: MainAxisAlignment.center,

                children: List.generate(

                  pages.length,

                      (index) {

                    return AnimatedContainer(

                      duration: const Duration(milliseconds: 300),

                      margin: const EdgeInsets.symmetric(horizontal: 4),

                      height: 7,

                      width: currentPage == index ? 25 : 7,

                      decoration: BoxDecoration(

                        color: currentPage == index
                            ? const Color(0xFFF28C28)
                            : Colors.grey.shade300,

                        borderRadius: BorderRadius.circular(10),

                      ),
                    );

                  },
                ),
              ),

              const SizedBox(height: 35),

              // Next arrow button

              Align(

                alignment: Alignment.centerRight,

                child: GestureDetector(

                  onTap: nextPage,

                  child: Container(

                    height: 58,
                    width: 58,

                    decoration: BoxDecoration(
                      color: const Color(0xFFF28C28),
                      borderRadius: BorderRadius.circular(18),
                    ),

                    child: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

            ],
          ),
        ),
      ),
    );
  }
}