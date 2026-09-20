import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class PlaceSearchField extends StatefulWidget {
  final String apiKey;
  final String hint;
  final double biasLat;
  final double biasLng;
  final void Function(String desc, double lat, double lng) onSelected;

  // إضافة Controller من الخارج
  final TextEditingController? controller;

  const PlaceSearchField({
    super.key,
    required this.apiKey,
    required this.hint,
    required this.biasLat,
    required this.biasLng,
    required this.onSelected,
    this.controller,
  });

  @override
  State<PlaceSearchField> createState() => _PlaceSearchFieldState();
}

class _PlaceSearchFieldState extends State<PlaceSearchField> {
  late TextEditingController _controller;

  final _focus = FocusNode();
  final _uuid = const Uuid();
  final LayerLink _layerLink = LayerLink();

  Timer? _debounce;
  String _sessionToken = "";
  bool _loading = false;
  List<_Suggestion> _suggestions = [];
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController();

    _focus.addListener(() {
      if (!_focus.hasFocus) {
        _hideOverlay();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();

    if (widget.controller == null) {
      _controller.dispose();
    }

    _focus.dispose();
    _hideOverlay();
    super.dispose();
  }

  void _ensureSession() {
    if (_sessionToken.isEmpty) {
      _sessionToken = _uuid.v4();
    }
  }

  void _showOverlay() {
    _hideOverlay();

    if (_suggestions.isEmpty) return;

    double listHeight =
    (_suggestions.length * 55.0).clamp(55.0, 400.0);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: MediaQuery.of(context).size.width * 0.9,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(
              -(MediaQuery.of(context).size.width * 0.1),
              -(listHeight + 10),
            ),
            child: Material(
              elevation: 10,
              borderRadius: BorderRadius.circular(15),
              child: Container(
                constraints: BoxConstraints(maxHeight: listHeight),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _suggestions.length,
                  itemBuilder: (context, index) {
                    final s = _suggestions[index];

                    return ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(
                        s.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectSuggestion(s),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      _hideOverlay();
      return;
    }

    _ensureSession();

    setState(() {
      _loading = true;
    });

    try {
      final url = Uri.parse(
        "https://maps.googleapis.com/maps/api/place/autocomplete/json"
            "?input=${Uri.encodeComponent(input)}"
            "&key=${widget.apiKey}"
            "&sessiontoken=$_sessionToken"
            "&location=${widget.biasLat},${widget.biasLng}"
            "&radius=50000"
            "&components=country:eg",
      );

      final response = await http.get(url);

      final json = jsonDecode(response.body);

      if (json["status"] == "OK") {
        final list = (json["predictions"] as List)
            .take(10)
            .map(
              (e) => _Suggestion(
            placeId: e["place_id"],
            description: e["description"],
          ),
        )
            .toList();

        setState(() {
          _suggestions = list;
        });

        if (_focus.hasFocus) {
          _showOverlay();
        }
      } else {
        _hideOverlay();
      }
    } catch (e) {
      _hideOverlay();
    }

    setState(() {
      _loading = false;
    });
  }

  Future<void> _selectSuggestion(_Suggestion s) async {
    _hideOverlay();
    _focus.unfocus();

    final url = Uri.parse(
      "https://maps.googleapis.com/maps/api/place/details/json"
          "?place_id=${s.placeId}"
          "&fields=geometry,name,formatted_address"
          "&key=${widget.apiKey}"
          "&sessiontoken=$_sessionToken",
    );

    final response = await http.get(url);

    final json = jsonDecode(response.body);

    if (json["status"] != "OK") return;

    final result = json["result"];

    final loc = result["geometry"]["location"];

    final lat = (loc["lat"] as num).toDouble();
    final lng = (loc["lng"] as num).toDouble();

    final title =
        result["name"] ?? result["formatted_address"];

    _controller.text = title;

    _sessionToken = "";

    widget.onSelected(title, lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        onChanged: (value) {
          _debounce?.cancel();

          _debounce = Timer(
            const Duration(milliseconds: 300),
                () {
              _fetchSuggestions(value);
            },
          );
        },
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          suffixIcon: _loading
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
          )
              : const Icon(Icons.search),
        ),
      ),
    );
  }
}

class _Suggestion {
  final String placeId;
  final String description;

  _Suggestion({
    required this.placeId,
    required this.description,
  });
}