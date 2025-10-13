import 'package:flutter/material.dart';
import 'formpage.dart';
import 'daftar_tamu.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _containerController;
  late AnimationController _contentController;

  late Animation<double> _containerScaleAnimation;
  late Animation<double> _containerFadeAnimation;
  late Animation<Offset> _leftSlideAnimation;
  late Animation<Offset> _rightSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _buttonSlideAnimation;

  @override
  void initState() {
    super.initState();

    // Controller untuk container utama
    _containerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Controller untuk konten
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Animasi container utama
    _containerScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _containerController, curve: Curves.elasticOut),
    );

    _containerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _containerController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Animasi slide untuk kedua sisi
    _leftSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _rightSlideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.3, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _buttonSlideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    // Start animasi
    _startAnimations();
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _containerController.forward();

    await Future.delayed(const Duration(milliseconds: 300));
    _contentController.forward();
  }

  @override
  void dispose() {
    _containerController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF018A3C),
        child: Center(
          child: AnimatedBuilder(
            animation: _containerController,
            builder: (context, child) {
              return Transform.scale(
                scale: _containerScaleAnimation.value,
                child: Opacity(
                  opacity: _containerFadeAnimation.value,
                  child: Container(
                    width: 1200,
                    height: 600,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Left Side - Logo & Info
                        Expanded(
                          flex: 1,
                          child: SlideTransition(
                            position: _leftSlideAnimation,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0xFF0A5D2B),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _contentController,
                                  builder: (context, child) {
                                    return FadeTransition(
                                      opacity: _contentFadeAnimation,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          TweenAnimationBuilder<double>(
                                            duration: const Duration(
                                              milliseconds: 800,
                                            ),
                                            tween: Tween<double>(
                                              begin: 0.0,
                                              end: 1.0,
                                            ),
                                            builder: (context, value, child) {
                                              return Transform.scale(
                                                scale: value,
                                                child: Transform.rotate(
                                                  angle: (1 - value) * 0.1,
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          20,
                                                        ),
                                                    child: Image.asset(
                                                      "assets/kemenag (1).png",
                                                      width: 230,
                                                      height: 230,
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 20),
                                          Transform.translate(
                                            offset: Offset(
                                              0,
                                              _buttonSlideAnimation.value,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 20,
                                              ),
                                              child: Text(
                                                "KANTOR KEMENTERIAN AGAMA\nKOTA TASIKMALAYA",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Right Side - Content & Buttons
                        Expanded(
                          flex: 1,
                          child: SlideTransition(
                            position: _rightSlideAnimation,
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topRight: Radius.circular(20),
                                  bottomRight: Radius.circular(20),
                                ),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(40),
                                  child: AnimatedBuilder(
                                    animation: _contentController,
                                    builder: (context, child) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FadeTransition(
                                            opacity: _contentFadeAnimation,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                _buttonSlideAnimation.value,
                                              ),
                                              child: const Text(
                                                "Buku Tamu Digital",
                                                style: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 15),
                                          FadeTransition(
                                            opacity: _contentFadeAnimation,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                _buttonSlideAnimation.value *
                                                    0.8,
                                              ),
                                              child: const Text(
                                                "Alamat Jl. Ahmad Yani No.75, Lengkongsari,\n"
                                                "Kec. Tawang, Kab. Tasikmalaya, Jawa Barat 46111\n"
                                                "Telp. (0265) - 340003",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.black54,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 35),

                                          // Button 1 - Data Tamu
                                          Transform.translate(
                                            offset: Offset(
                                              0,
                                              _buttonSlideAnimation.value * 1.2,
                                            ),
                                            child: FadeTransition(
                                              opacity: _contentFadeAnimation,
                                              child: SizedBox(
                                                width: 250,
                                                height: 45,
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF018A3C),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            25,
                                                          ),
                                                    ),
                                                    elevation: 3,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      PageRouteBuilder(
                                                        pageBuilder:
                                                            (
                                                              context,
                                                              animation,
                                                              secondaryAnimation,
                                                            ) =>
                                                                const DashboardPage(),
                                                        transitionsBuilder: (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                          child,
                                                        ) {
                                                          return SlideTransition(
                                                            position: Tween<
                                                              Offset
                                                            >(
                                                              begin:
                                                                  const Offset(
                                                                    1.0,
                                                                    0.0,
                                                                  ),
                                                              end: Offset.zero,
                                                            ).animate(
                                                              animation,
                                                            ),
                                                            child: child,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.admin_panel_settings,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  label: const Text(
                                                    "Data Tamu",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 18),

                                          // Button 2 - Input Data Tamu
                                          Transform.translate(
                                            offset: Offset(
                                              0,
                                              _buttonSlideAnimation.value * 1.5,
                                            ),
                                            child: FadeTransition(
                                              opacity: _contentFadeAnimation,
                                              child: SizedBox(
                                                width: 250,
                                                height: 45,
                                                child: ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        const Color(0xFF01C853),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            25,
                                                          ),
                                                    ),
                                                    elevation: 3,
                                                  ),
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      PageRouteBuilder(
                                                        pageBuilder:
                                                            (
                                                              context,
                                                              animation,
                                                              secondaryAnimation,
                                                            ) =>
                                                                const FormTamu(),
                                                        transitionsBuilder: (
                                                          context,
                                                          animation,
                                                          secondaryAnimation,
                                                          child,
                                                        ) {
                                                          return SlideTransition(
                                                            position: Tween<
                                                              Offset
                                                            >(
                                                              begin:
                                                                  const Offset(
                                                                    1.0,
                                                                    0.0,
                                                                  ),
                                                              end: Offset.zero,
                                                            ).animate(
                                                              animation,
                                                            ),
                                                            child: child,
                                                          );
                                                        },
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(
                                                    Icons.edit_note,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                  label: const Text(
                                                    "Input Data Tamu",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
