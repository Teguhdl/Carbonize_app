import 'package:flutter/material.dart';

/// A reusable dropdown widget that uses an overlay for the dropdown menu.
/// Replaces the 6 identical dropdown toggle methods from calculator_screen.
class CustomDropdown extends StatefulWidget {
  final String? selectedValue;
  final String hintText;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  const CustomDropdown({
    Key? key,
    this.selectedValue,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<CustomDropdown> createState() => _CustomDropdownState();
}

class _CustomDropdownState extends State<CustomDropdown> {
  final GlobalKey _dropdownKey = GlobalKey();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
      setState(() => _isOpen = false);
      return;
    }

    final RenderBox renderBox =
        _dropdownKey.currentContext!.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFA4B465),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              constraints: const BoxConstraints(maxHeight: 200),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    final isLast = index == widget.items.length - 1;
                    return InkWell(
                      onTap: () {
                        widget.onChanged(value);
                        _removeOverlay();
                        setState(() => _isOpen = false);
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          border: !isLast
                              ? Border(
                                  bottom: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                )
                              : null,
                          borderRadius: isLast
                              ? const BorderRadius.vertical(
                                  bottom: Radius.circular(8))
                              : null,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _isOpen = true);
  }

  /// Close the dropdown programmatically (e.g. when scrolling).
  void close() {
    if (_isOpen) {
      _removeOverlay();
      setState(() => _isOpen = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: _dropdownKey,
      onTap: widget.isLoading ? null : _toggleDropdown,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFA4B465),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: widget.isLoading
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Loading...',
                            style: TextStyle(color: Colors.white70, fontSize: 16),
                          ),
                        ],
                      )
                    : Text(
                        widget.selectedValue ?? widget.hintText,
                        style: TextStyle(
                          color: widget.selectedValue == null
                              ? Colors.white70
                              : Colors.white,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              Image.asset(
                _isOpen
                    ? 'assets/icons/dropdownbutton2back_icon.png'
                    : 'assets/icons/dropdownbutton2_icon.png',
                width: 20,
                height: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
