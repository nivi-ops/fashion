// location_picker_page.dart
//
// Flipkart-style "Select delivery address" bottom sheet.
//
// Open:
//   LocationPickerSheet.show(context)
//
// Returns:
//   ShopAddress? -> selected / newly added / edited address
//   null         -> dismissed
//
// Works with:
//   - location_map_picker_page.dart
//   - api_service.dart
//   - app_colors.dart
//
// Features:
//   • Saved addresses
//   • Search saved addresses
//   • Use current location
//   • Add New
//   • Edit address
//   • Delete address
//   • Manual map fallback
//   • Location permission handling
//   • GPS timeout fallback
//   • Reverse geocoding
//

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'api_service.dart';
import 'app_colors.dart';
import 'location_map_picker_page.dart';

class LocationPickerSheet extends StatefulWidget {
  const LocationPickerSheet({super.key});

  /// Opens the address picker bottom sheet.
  ///
  /// Returns the selected ShopAddress or null.
  static Future<ShopAddress?> show(BuildContext context) {
    return showModalBottomSheet<ShopAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => const LocationPickerSheet(),
    );
  }

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet> {
  final ApiService _api = ApiService.instance;

  final TextEditingController _searchController =
      TextEditingController();

  List<ShopAddress> _allAddresses = [];
  List<ShopAddress> _filteredAddresses = [];

  bool _loadingAddresses = true;
  bool _locating = false;

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    _loadAddresses();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD SAVED ADDRESSES
  // ============================================================

  Future<void> _loadAddresses() async {
    if (mounted) {
      setState(() {
        _loadingAddresses = true;
      });
    }

    try {
      final addresses = await _api.getAddresses();

      if (!mounted) return;

      setState(() {
        _allAddresses = addresses;
        _filteredAddresses = addresses;
        _loadingAddresses = false;
      });

      _applySearch();
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _allAddresses = [];
        _filteredAddresses = [];
        _loadingAddresses = false;
      });

      _showSnack(
        'Could not load saved addresses. Please try again.',
      );
    }
  }

  Future<void> _refreshAddresses() async {
    await _loadAddresses();
  }

  // ============================================================
  // SEARCH
  // ============================================================

  void _onSearchChanged() {
    _applySearch();
  }

  void _applySearch() {
    if (!mounted) return;

    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _filteredAddresses = List<ShopAddress>.from(_allAddresses);
      });
      return;
    }

    final results = _allAddresses.where((address) {
      final label = address.label.toLowerCase();
      final addressLine = address.addressLine.toLowerCase();
      final city = address.city.toLowerCase();
      final pincode = address.pincode.toLowerCase();
      final phone = address.phone?.toLowerCase() ?? '';

      return label.contains(query) ||
          addressLine.contains(query) ||
          city.contains(query) ||
          pincode.contains(query) ||
          phone.contains(query);
    }).toList();

    setState(() {
      _filteredAddresses = results;
    });
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  Future<void> _useCurrentLocation() async {
    if (_locating) return;

    setState(() {
      _locating = true;
    });

    try {
      // --------------------------------------------------------
      // 1. Check whether location service is enabled
      // --------------------------------------------------------

      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await _showLocationFailure(
          title: 'Location is turned off',
          message:
              'Please turn on Location on your phone, or choose your delivery location manually on the map.',
          showSettingsButton: true,
        );

        return;
      }

      // --------------------------------------------------------
      // 2. Check permission
      // --------------------------------------------------------

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        await _showLocationFailure(
          title: 'Location permission denied',
          message:
              'Location permission is required to automatically detect your delivery location.',
          showSettingsButton: false,
        );

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        await _showLocationFailure(
          title: 'Location permission blocked',
          message:
              'Location permission is permanently blocked. You can enable it from app settings or select the location manually.',
          showSettingsButton: true,
        );

        return;
      }

      // --------------------------------------------------------
      // 3. Get GPS position
      // --------------------------------------------------------

      Position? position;

      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 15),
          ),
        );
      } catch (_) {
        // Try medium accuracy
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 8),
            ),
          );
        } catch (_) {
          // Try last known location
          try {
            position = await Geolocator.getLastKnownPosition();
          } catch (_) {
            position = null;
          }
        }
      }

      // --------------------------------------------------------
      // 4. No position
      // --------------------------------------------------------

      if (position == null) {
        await _showLocationFailure(
          title: 'Could not detect your location',
          message:
              'GPS signal is unavailable right now. You can still select your exact delivery location manually on the map.',
          showSettingsButton: false,
        );

        return;
      }

      // --------------------------------------------------------
      // 5. Reverse geocode
      // --------------------------------------------------------

      String addressLine = '';
      String city = '';
      String pincode = '';

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final p = placemarks.first;

          final parts = <String>[
            if (p.subLocality != null &&
                p.subLocality!.trim().isNotEmpty)
              p.subLocality!.trim(),

            if (p.thoroughfare != null &&
                p.thoroughfare!.trim().isNotEmpty)
              p.thoroughfare!.trim(),

            if (p.street != null &&
                p.street!.trim().isNotEmpty)
              p.street!.trim(),
          ];

          addressLine = parts.toSet().join(', ');

          if (addressLine.isEmpty &&
              p.name != null &&
              p.name!.trim().isNotEmpty) {
            addressLine = p.name!.trim();
          }

          city =
              p.locality?.trim() ??
              p.subAdministrativeArea?.trim() ??
              '';

          pincode = p.postalCode?.trim() ?? '';
        }
      } catch (_) {
        // Reverse geocoding failure should NOT block map picker.
      }

      // --------------------------------------------------------
      // 6. Open map picker with detected coordinates
      // --------------------------------------------------------

      if (!mounted) return;

      final result = await Navigator.of(context).push<ShopAddress>(
        MaterialPageRoute(
          builder: (_) => LocationMapPickerPage(
            initialLatitude: position!.latitude,
            initialLongitude: position.longitude,
            initialAddressLine: addressLine,
            initialCity: city,
            initialPincode: pincode,
          ),
        ),
      );

      // --------------------------------------------------------
      // 7. Address saved from map
      // --------------------------------------------------------

      if (result != null) {
        await _refreshAddresses();

        if (!mounted) return;

        Navigator.pop(context, result);
      }
    } catch (_) {
      if (!mounted) return;

      await _showLocationFailure(
        title: 'Location error',
        message:
            'Something went wrong while detecting your location. You can select your address manually on the map.',
        showSettingsButton: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  // ============================================================
  // LOCATION FAILURE DIALOG
  // ============================================================

  Future<void> _showLocationFailure({
    required String title,
    required String message,
    required bool showSettingsButton,
  }) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_off_outlined,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            if (showSettingsButton)
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  await Geolocator.openLocationSettings();
                },
                child: const Text('Settings'),
              ),

            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                Future.delayed(
                  const Duration(milliseconds: 200),
                  () {
                    if (mounted) {
                      _openMapPicker();
                    }
                  },
                );
              },
              child: const Text('Set on map'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ADD / EDIT MAP PICKER
  // ============================================================

  Future<void> _openMapPicker({
    ShopAddress? editing,
  }) async {
    if (!mounted) return;

    final result = await Navigator.of(context).push<ShopAddress>(
      MaterialPageRoute(
        builder: (_) {
          if (editing != null) {
            return LocationMapPickerPage(
              editingAddress: editing,
              initialLatitude: editing.latitude,
              initialLongitude: editing.longitude,
              initialAddressLine: editing.addressLine,
              initialCity: editing.city,
              initialPincode: editing.pincode,
            );
          }

          return const LocationMapPickerPage();
        },
      ),
    );

    if (result == null) return;

    await _refreshAddresses();

    if (!mounted) return;

    Navigator.pop(context, result);
  }

  // ============================================================
  // DELETE ADDRESS
  // ============================================================

  Future<void> _deleteAddress(
    ShopAddress address,
  ) async {
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete address?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to remove "${address.label}" from your saved addresses?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.deleteAddress(address.id);

      await _refreshAddresses();

      if (!mounted) return;

      _showSnack('Address deleted successfully.');
    } catch (_) {
      if (!mounted) return;

      _showSnack(
        'Could not delete address. Please try again.',
      );
    }
  }

  // ============================================================
  // SELECT ADDRESS
  // ============================================================

  void _selectAddress(ShopAddress address) {
    Navigator.pop(context, address);
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final mediaHeight = MediaQuery.of(context).size.height;

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.96,
      expand: false,
      builder: (
        context,
        scrollController,
      ) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: mediaHeight * 0.96,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              24,
            ),
            children: [
              // ==================================================
              // TOP HANDLE
              // ==================================================

              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // HEADER
              // ==================================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select delivery address',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ==================================================
              // SEARCH
              // ==================================================

              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: AppColors.gray,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AppColors.textLight,
                      size: 21,
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        decoration: const InputDecoration(
                          hintText:
                              'Search by name, area, street, pincode',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: AppColors.textLight,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),

                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.clear,
                          size: 18,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // CURRENT LOCATION
              // ==================================================

              _actionTile(
                icon: Icons.my_location,
                title: 'Use my current location',
                subtitle: _locating
                    ? 'Detecting your location...'
                    : 'Use GPS to find your delivery location',
                loading: _locating,
                onTap: _locating
                    ? null
                    : _useCurrentLocation,
              ),

              const SizedBox(height: 10),

              // ==================================================
              // ADD NEW
              // ==================================================

              _actionTile(
                icon: Icons.add_location_alt_outlined,
                title: 'Add New',
                subtitle: 'Select a delivery location on the map',
                iconColor: AppColors.primary,
                onTap: () {
                  _openMapPicker();
                },
              ),

              const SizedBox(height: 22),

              // ==================================================
              // SAVED ADDRESSES TITLE
              // ==================================================

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Saved addresses',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),

                  if (!_loadingAddresses)
                    Text(
                      '${_filteredAddresses.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 10),

              // ==================================================
              // LOADING
              // ==================================================

              if (_loadingAddresses)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 45,
                  ),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )

              // ==================================================
              // EMPTY
              // ==================================================

              else if (_filteredAddresses.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 35,
                    horizontal: 20,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _searchController.text.trim().isEmpty
                            ? 'No saved addresses yet'
                            : 'No address found',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _searchController.text.trim().isEmpty
                            ? 'Tap "Add New" to create your delivery address.'
                            : 'Try searching with another area, street or pincode.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ),
                )

              // ==================================================
              // SAVED ADDRESS LIST
              // ==================================================

              else
                ..._filteredAddresses.map(
                  (address) => _addressCard(address),
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // ACTION TILE
  // ============================================================

  Widget _actionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    bool loading = false,
    VoidCallback? onTap,
  }) {
    final color = iconColor ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.055),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: loading
                    ? Padding(
                        padding: const EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : Icon(
                        icon,
                        color: color,
                        size: 21,
                      ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),

                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget _addressCard(
    ShopAddress address,
  ) {
    final isWork = address.label.toLowerCase() == 'work';

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectAddress(address),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: AppColors.gray,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // ----------------------------------------------
                // ICON
                // ----------------------------------------------

                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    isWork
                        ? Icons.work_outline
                        : Icons.home_outlined,
                    size: 21,
                    color: AppColors.text,
                  ),
                ),

                const SizedBox(width: 12),

                // ----------------------------------------------
                // ADDRESS INFO
                // ----------------------------------------------

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.label.isNotEmpty
                            ? address.label
                            : 'Address',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        _formatAddress(address),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: AppColors.textLight,
                        ),
                      ),

                      if (address.phone != null &&
                          address.phone!.trim().isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            const Icon(
                              Icons.phone_outlined,
                              size: 14,
                              color: AppColors.textLight,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              address.phone!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                // ----------------------------------------------
                // 3 DOT MENU
                // ----------------------------------------------

                PopupMenuButton<String>(
                  tooltip: 'Address options',
                  icon: const Icon(
                    Icons.more_vert,
                    size: 20,
                    color: AppColors.textLight,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openMapPicker(
                        editing: address,
                      );
                    } else if (value == 'delete') {
                      _deleteAddress(address);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                          ),
                          SizedBox(width: 9),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.red,
                          ),
                          SizedBox(width: 9),
                          Text(
                            'Delete',
                            style: TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FORMAT ADDRESS
  // ============================================================

  String _formatAddress(
    ShopAddress address,
  ) {
    final parts = <String>[];

    if (address.addressLine.trim().isNotEmpty) {
      parts.add(address.addressLine.trim());
    }

    if (address.city.trim().isNotEmpty) {
      parts.add(address.city.trim());
    }

    if (address.pincode.trim().isNotEmpty) {
      parts.add(address.pincode.trim());
    }

    if (parts.isEmpty) {
      return 'Address details unavailable';
    }

    if (address.pincode.trim().isNotEmpty &&
        address.city.trim().isNotEmpty) {
      final withoutPincode = <String>[];

      if (address.addressLine.trim().isNotEmpty) {
        withoutPincode.add(
          address.addressLine.trim(),
        );
      }

      withoutPincode.add(
        '${address.city.trim()} - ${address.pincode.trim()}',
      );

      return withoutPincode.join(', ');
    }

    return parts.join(', ');
  }
}