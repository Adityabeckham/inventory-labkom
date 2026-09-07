import 'dart:async';

import 'package:flutter/material.dart';

/// Kotak pencarian yang menunda pemanggilan API sampai pengetikan berhenti.
///
/// Tanpa jeda ini, mengetik "Lenovo" memicu enam request berturut-turut dan
/// hasil yang datang belakangan bisa menimpa yang lebih baru.
class SearchField extends StatefulWidget {
  const SearchField({
    required this.hintText,
    required this.onChanged,
    this.initialValue = '',
    this.debounce = const Duration(milliseconds: 350),
    super.key,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final String initialValue;
  final Duration debounce;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    _timer = Timer(widget.debounce, () => widget.onChanged(value.trim()));
    setState(() {}); // memunculkan/menyembunyikan tombol bersihkan
  }

  void _clear() {
    _timer?.cancel();
    _controller.clear();
    widget.onChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Bersihkan pencarian',
                onPressed: _clear,
              ),
      ),
    );
  }
}
