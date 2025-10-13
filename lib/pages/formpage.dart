import 'package:flutter/material.dart';
import '../db/database.dart';

class FormTamu extends StatefulWidget {
  const FormTamu({super.key});

  @override
  State<FormTamu> createState() => _FormTamuState();
}

class _FormTamuState extends State<FormTamu> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController instansiController = TextEditingController();
  final TextEditingController keperluanController = TextEditingController();
  final TextEditingController teleponController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final FocusNode namaFocus = FocusNode();
  final FocusNode instansiFocus = FocusNode();
  final FocusNode keperluanFocus = FocusNode();
  final FocusNode teleponFocus = FocusNode();
  final FocusNode pegawaiFocus = FocusNode();

  int? _pegawaiDipilih;
  String? _namaPegawaiDipilih;
  String? _nipPegawaiDipilih;
  String? _jabatanPegawaiDipilih;
  List<Map<String, dynamic>> _pegawaiList = [];
  List<Map<String, dynamic>> _filteredPegawaiList = [];

  late AnimationController _containerController;
  late AnimationController _formController;
  late AnimationController _buttonController;

  late Animation<double> _containerScaleAnimation;
  late Animation<double> _containerFadeAnimation;
  late Animation<Offset> _leftSlideAnimation;
  late Animation<Offset> _rightSlideAnimation;
  late Animation<double> _formItemAnimation;
  late Animation<double> _buttonBounceAnimation;
  late Animation<double> _backButtonAnimation;

  @override
  void initState() {
    super.initState();
    _loadPegawai();
    _setupAnimations();
    _startAnimations();
    searchController.addListener(_filterPegawai);
  }

  void _setupAnimations() {
    _containerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _containerScaleAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _containerController, curve: Curves.elasticOut),
    );

    _containerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _containerController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _leftSlideAnimation = Tween<Offset>(
      begin: const Offset(-1.2, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _rightSlideAnimation = Tween<Offset>(
      begin: const Offset(1.2, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _formItemAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _formController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    _buttonBounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.elasticOut),
    );

    _backButtonAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _containerController,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  void _startAnimations() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _containerController.forward();

    await Future.delayed(const Duration(milliseconds: 200));
    _formController.forward();

    await Future.delayed(const Duration(milliseconds: 1000));
    _buttonController.forward();
  }

  Future<void> _loadPegawai() async {
    final data = await DBHelper.getAllPegawai();
    setState(() {
      _pegawaiList = data;
      _filteredPegawaiList = data;
    });
  }

  void _filterPegawai() {
    final query = searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredPegawaiList = _pegawaiList;
      } else {
        _filteredPegawaiList =
            _pegawaiList.where((pegawai) {
              final nama = pegawai['nama']?.toString().toLowerCase() ?? '';
              final nip = pegawai['nip']?.toString().toLowerCase() ?? '';
              final jabatan =
                  pegawai['jabatan']?.toString().toLowerCase() ?? '';
              return nama.contains(query) ||
                  nip.contains(query) ||
                  jabatan.contains(query);
            }).toList();
      }
    });
  }

  void _showPegawaiModal() {
    searchController.clear();
    _filteredPegawaiList = _pegawaiList;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 900,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Pilih Pegawai",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setModalState(() {
                          _filterPegawai();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Cari pegawai...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: Row(
                              children: [
                                _buildHeaderCell("NIP", flex: 2),
                                _buildHeaderCell("Nama Pegawai", flex: 3),
                                _buildHeaderCell("Jabatan", flex: 3),
                              ],
                            ),
                          ),
                          _filteredPegawaiList.isEmpty
                              ? Container(
                                padding: const EdgeInsets.all(40),
                                child: const Text("Tidak ada data"),
                              )
                              : Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    _filteredPegawaiList.map((pegawai) {
                                      final isSelected =
                                          _pegawaiDipilih == pegawai["id"];

                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _pegawaiDipilih = pegawai["id"];
                                            _namaPegawaiDipilih =
                                                pegawai["nama"];
                                            _nipPegawaiDipilih = pegawai["nip"];
                                            _jabatanPegawaiDipilih =
                                                pegawai["jabatan"];
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? const Color(
                                                      0xFF018A3C,
                                                    ).withOpacity(0.1)
                                                    : Colors.white,
                                            border: Border(
                                              bottom: BorderSide(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _buildDataCell(
                                                pegawai["nip"]?.toString() ??
                                                    "-",
                                                flex: 2,
                                                isSelected: isSelected,
                                              ),
                                              _buildDataCell(
                                                pegawai["nama"] ?? "-",
                                                flex: 3,
                                                isSelected: isSelected,
                                              ),
                                              _buildDataCell(
                                                pegawai["jabatan"]
                                                        ?.toString() ??
                                                    "-",
                                                flex: 3,
                                                isSelected: isSelected,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeaderCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[400]!, width: 1)),
        ),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildDataCell(
    String text, {
    required int flex,
    bool isSelected = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey[300]!, width: 1)),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isSelected ? const Color(0xFF018A3C) : Colors.black87,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _simpanData() async {
    _buttonController.reset();
    _buttonController.forward();

    if (_formKey.currentState!.validate()) {
      if (_pegawaiDipilih == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("⚠️ Pegawai harus dipilih")),
        );
        return;
      }

      await DBHelper.insertTamu({
        "nama": namaController.text.trim(),
        "instansi": instansiController.text.trim(),
        "keperluan": keperluanController.text.trim(),
        "telepon": teleponController.text.trim(),
        "pegawai_id": _pegawaiDipilih,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Data tamu berhasil disimpan!",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      namaController.clear();
      instansiController.clear();
      keperluanController.clear();
      teleponController.clear();
      setState(() {
        _pegawaiDipilih = null;
        _namaPegawaiDipilih = null;
        _nipPegawaiDipilih = null;
        _jabatanPegawaiDipilih = null;
      });
    }
  }

  @override
  void dispose() {
    _containerController.dispose();
    _formController.dispose();
    _buttonController.dispose();
    namaController.dispose();
    instansiController.dispose();
    keperluanController.dispose();
    teleponController.dispose();
    searchController.dispose();
    namaFocus.dispose();
    instansiFocus.dispose();
    keperluanFocus.dispose();
    teleponFocus.dispose();
    pegawaiFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: const Color(0xFF018A3C),
        child: Stack(
          children: [
            Center(
              child: AnimatedBuilder(
                animation: _containerController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _containerScaleAnimation.value,
                    child: Opacity(
                      opacity: _containerFadeAnimation.value,
                      child: Container(
                        width: 1200,
                        height: 750,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
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
                            Expanded(
                              flex: 1,
                              child: SlideTransition(
                                position: _leftSlideAnimation,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF0A5D2B),
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(24),
                                      bottomLeft: Radius.circular(24),
                                    ),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _formController,
                                    builder: (context, child) {
                                      return Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          FadeTransition(
                                            opacity: _formItemAnimation,
                                            child: TweenAnimationBuilder<
                                              double
                                            >(
                                              duration: const Duration(
                                                milliseconds: 1000,
                                              ),
                                              tween: Tween<double>(
                                                begin: 0.0,
                                                end: 1.0,
                                              ),
                                              builder: (context, value, child) {
                                                return Transform.scale(
                                                  scale: value,
                                                  child: Transform.rotate(
                                                    angle: (1 - value) * 0.2,
                                                    child: Image.asset(
                                                      "assets/kemenag (1).png",
                                                      width: 220,
                                                      height: 220,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                          const SizedBox(height: 30),
                                          FadeTransition(
                                            opacity: _formItemAnimation,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                (1 - _formItemAnimation.value) *
                                                    30,
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 30,
                                                ),
                                                child: Text(
                                                  "KANTOR KEMENTERIAN AGAMA\nKOTA TASIKMALAYA",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    height: 1.4,
                                                    letterSpacing: 0.5,
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
                            Expanded(
                              flex: 2,
                              child: SlideTransition(
                                position: _rightSlideAnimation,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(24),
                                      bottomRight: Radius.circular(24),
                                    ),
                                  ),
                                  child: Center(
                                    child: SingleChildScrollView(
                                      padding: const EdgeInsets.all(60),
                                      child: AnimatedBuilder(
                                        animation: _formController,
                                        builder: (context, child) {
                                          return Column(
                                            children: [
                                              FadeTransition(
                                                opacity: _formItemAnimation,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    0,
                                                    (1 -
                                                            _formItemAnimation
                                                                .value) *
                                                        30,
                                                  ),
                                                  child: const Text(
                                                    "Form Input Data Tamu",
                                                    style: TextStyle(
                                                      fontSize: 32,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.black87,
                                                      letterSpacing: 0.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              FadeTransition(
                                                opacity: _formItemAnimation,
                                                child: Transform.translate(
                                                  offset: Offset(
                                                    0,
                                                    (1 -
                                                            _formItemAnimation
                                                                .value) *
                                                        20,
                                                  ),
                                                  child: const Text(
                                                    "Buku Tamu Digital\nKantor Kementerian Agama Kota Tasikmalaya",
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 15,
                                                      height: 1.5,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 40),
                                              Form(
                                                key: _formKey,
                                                child: Column(
                                                  children: [
                                                    ..._buildAnimatedFormFields(),
                                                    const SizedBox(height: 35),
                                                    AnimatedBuilder(
                                                      animation:
                                                          _buttonController,
                                                      builder: (
                                                        context,
                                                        child,
                                                      ) {
                                                        return Transform.scale(
                                                          scale:
                                                              _buttonBounceAnimation
                                                                  .value,
                                                          child: SizedBox(
                                                            width:
                                                                double.infinity,
                                                            height: 56,
                                                            child: ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor:
                                                                    const Color(
                                                                      0xFF018A3C,
                                                                    ),
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        28,
                                                                      ),
                                                                ),
                                                                elevation: 3,
                                                              ),
                                                              onPressed:
                                                                  _simpanData,
                                                              child: const Text(
                                                                "Submit",
                                                                style: TextStyle(
                                                                  fontSize: 19,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color:
                                                                      Colors
                                                                          .white,
                                                                  letterSpacing:
                                                                      0.5,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ],
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
            Positioned(
              top: 35,
              left: 35,
              child: AnimatedBuilder(
                animation: _containerController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _backButtonAnimation.value,
                    child: Opacity(
                      opacity: _backButtonAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: IconButton(
                          iconSize: 28,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
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
    );
  }

  List<Widget> _buildAnimatedFormFields() {
    final fields = [
      _buildAnimatedFormField(
        controller: namaController,
        focusNode: namaFocus,
        nextFocusNode: instansiFocus,
        label: "Nama",
        validator:
            (value) =>
                value == null || value.isEmpty
                    ? "Nama tidak boleh kosong"
                    : null,
        delay: 0.0,
      ),
      _buildAnimatedFormField(
        controller: instansiController,
        focusNode: instansiFocus,
        nextFocusNode: keperluanFocus,
        label: "Alamat/Instansi",
        delay: 0.1,
      ),
      _buildAnimatedFormField(
        controller: keperluanController,
        focusNode: keperluanFocus,
        nextFocusNode: teleponFocus,
        label: "Keperluan / Maksud Tujuan",
        validator:
            (value) =>
                value == null || value.isEmpty ? "Keperluan wajib diisi" : null,
        delay: 0.2,
      ),
      _buildAnimatedFormField(
        controller: teleponController,
        focusNode: teleponFocus,
        nextFocusNode: pegawaiFocus,
        label: "No Telp/HP",
        keyboardType: TextInputType.phone,
        delay: 0.3,
      ),
      _buildAnimatedPegawaiSelector(delay: 0.4),
    ];

    List<Widget> animatedFields = [];
    for (int i = 0; i < fields.length; i++) {
      animatedFields.add(fields[i]);
      if (i < fields.length - 1) {
        animatedFields.add(const SizedBox(height: 22));
      }
    }

    return animatedFields;
  }

  Widget _buildAnimatedFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    required String label,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _formController,
      builder: (context, child) {
        final delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _formController,
            curve: Interval(0.5 + delay, 1.0, curve: Curves.easeOutQuart),
          ),
        );

        return Transform.translate(
          offset: Offset(0, (1 - delayedAnimation.value) * 50),
          child: Opacity(
            opacity: delayedAnimation.value,
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: keyboardType,
              textInputAction:
                  nextFocusNode != null
                      ? TextInputAction.next
                      : TextInputAction.done,
              style: const TextStyle(fontSize: 17),
              decoration: _inputDecoration(label),
              validator: validator,
              onFieldSubmitted: (value) {
                if (nextFocusNode != null) {
                  FocusScope.of(context).requestFocus(nextFocusNode);
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedPegawaiSelector({required double delay}) {
    return AnimatedBuilder(
      animation: _formController,
      builder: (context, child) {
        final delayedAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _formController,
            curve: Interval(0.5 + delay, 1.0, curve: Curves.easeOutQuart),
          ),
        );

        return Transform.translate(
          offset: Offset(0, (1 - delayedAnimation.value) * 50),
          child: Opacity(
            opacity: delayedAnimation.value,
            child: FormField<int>(
              validator:
                  (value) =>
                      _pegawaiDipilih == null ? "Pilih pegawai dulu" : null,
              builder: (FormFieldState<int> state) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Focus(
                      focusNode: pegawaiFocus,
                      onKey: (node, event) {
                        if (event.logicalKey.keyLabel == 'Enter' ||
                            event.logicalKey.keyLabel == 'Arrow Down') {
                          _showPegawaiModal();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: GestureDetector(
                        onTap: _showPegawaiModal,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color:
                                  state.hasError
                                      ? Colors.red
                                      : const Color.fromARGB(255, 70, 70, 70),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _namaPegawaiDipilih ??
                                      "Pilih Pegawai yang Ditemui",
                                  style: TextStyle(
                                    color:
                                        _namaPegawaiDipilih != null
                                            ? Colors.black87
                                            : Colors.black54,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.grey[600],
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (state.hasError)
                      Padding(
                        padding: const EdgeInsets.only(left: 12, top: 6),
                        child: Text(
                          state.errorText!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color.fromARGB(255, 70, 70, 70)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF018A3C), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
