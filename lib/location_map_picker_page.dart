// location_map_picker_page.dart
//
// Flipkart-style Add / Edit Address flow
//
// STEP 1 - New address only:
//   "Where do you want us to deliver the order?"
//   - Away from my location
//   - Use current location
//
// STEP 2 - Map:
//   - Google Map
//   - Fixed center pin
//   - Search bar
//   - Use my current location
//   - Resolved locality chip
//   - Deliver To summary
//   - Add address Details
//
// STEP 3 - Address Details:
//   - Flat / House / Building name
//   - Area / Sector / Locality
//   - Full name
//   - Mobile
//   - Alternate mobile
//   - Home / Work
//   - Save address
//
// LOCATION FIX:
//   If device Location is OFF, location package will request the
//   Android native Location Service dialog.
//
// Required packages:
//   google_maps_flutter
//   geolocator
//   geocoding
//   location
//
// pubspec.yaml:
//   google_maps_flutter: ^2.9.0
//   geolocator: ^13.0.0
//   geocoding: ^3.0.0
//   location: ^7.0.1

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;

import 'api_service.dart';
import 'app_colors.dart';

class LocationMapPickerPage extends StatefulWidget {
  final ShopAddress? editingAddress;

  final double? initialLatitude;
  final double? initialLongitude;

  final String? initialAddressLine;
  final String? initialCity;
  final String? initialPincode;

  const LocationMapPickerPage({
    super.key,
    this.editingAddress,
    this.initialLatitude,
    this.initialLongitude,
    this.initialAddressLine,
    this.initialCity,
    this.initialPincode,
  });

  @override
  State<LocationMapPickerPage> createState() =>
      _LocationMapPickerPageState();
}

class _LocationMapPickerPageState
    extends State<LocationMapPickerPage> {
  // -------------------------------------------------------------------------
  // DEFAULT LOCATION
  // -------------------------------------------------------------------------

  static const LatLng _fallbackCenter =
      LatLng(13.0827, 80.2707); // Chennai

  // -------------------------------------------------------------------------
  // MAP
  // -------------------------------------------------------------------------

  GoogleMapController? _mapController;

  final Completer<void> _mapReadyCompleter =
      Completer<void>();

  // -------------------------------------------------------------------------
  // SEARCH
  // -------------------------------------------------------------------------

  final TextEditingController _searchController =
      TextEditingController();

  Timer? _debounce;

  // Used to prevent old reverse-geocoding results from replacing
  // a newer selected location.
  int _resolveRequestId = 0;

  // -------------------------------------------------------------------------
  // LOCATION DATA
  // -------------------------------------------------------------------------

  late LatLng _pinPosition;

  String _pinLabel = '';
  String _shortLabel = 'Locating...';

  String _fullAddress = '';
  String _city = '';
  String _pincode = '';

  // -------------------------------------------------------------------------
  // STATES
  // -------------------------------------------------------------------------

  bool _resolvingAddress = false;
  bool _fetchingCurrentLocation = false;
  bool _entryChoicePending = false;

  // -------------------------------------------------------------------------
  // NEW ADDRESS CHECK
  // -------------------------------------------------------------------------

  bool get _isBrandNewAddress =>
      widget.editingAddress == null &&
      widget.initialLatitude == null &&
      widget.initialLongitude == null;

  // -------------------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    final double? lat =
        widget.initialLatitude ??
        widget.editingAddress?.latitude;

    final double? lng =
        widget.initialLongitude ??
        widget.editingAddress?.longitude;

    if (lat != null && lng != null) {
      _pinPosition = LatLng(lat, lng);
    } else {
      _pinPosition = _fallbackCenter;
    }

    _fullAddress =
        widget.initialAddressLine ??
        widget.editingAddress?.addressLine ??
        '';

    _city =
        widget.initialCity ??
        widget.editingAddress?.city ??
        '';

    _pincode =
        widget.initialPincode ??
        widget.editingAddress?.pincode ??
        '';

    _shortLabel =
        _fullAddress.trim().isNotEmpty
            ? _fullAddress
            : 'Locating...';

    // -------------------------------------------------------------
    // NEW ADDRESS
    // -------------------------------------------------------------

    if (_isBrandNewAddress) {
      _entryChoicePending = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showEntryChoice();
        }
      });
    }

    // -------------------------------------------------------------
    // EDIT ADDRESS
    // -------------------------------------------------------------

    else {
      if (_fullAddress.trim().isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _resolveAddressForPin();
          }
        });
      } else {
        _pinLabel = _shortLabel;
      }
    }
  }

  // -------------------------------------------------------------------------
  // DISPOSE
  // -------------------------------------------------------------------------

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // =========================================================================
  // STEP 1
  // ENTRY CHOICE
  // =========================================================================

  Future<void> _showEntryChoice() async {
    final bool? useCurrentLocation =
        await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              24,
              20,
              20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Where do you want us to deliver the order?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'This will help with the right map location',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 22),

                // -------------------------------------------------
                // AWAY FROM MY LOCATION
                // -------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                        false,
                      );
                    },
                    child: const Text(
                      'Away from my location',
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // -------------------------------------------------
                // USE CURRENT LOCATION
                // -------------------------------------------------

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.my_location,
                      size: 18,
                    ),
                    label: const Text(
                      'Use current location',
                    ),
                    onPressed: () {
                      Navigator.pop(
                        sheetContext,
                        true,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;

    setState(() {
      _entryChoicePending = false;
    });

    if (useCurrentLocation == true) {
      await _centerOnDeviceLocation(
        showErrors: true,
      );
    } else {
      await _resolveAddressForPin();
    }
  }

  // =========================================================================
  // MAP CAMERA
  // =========================================================================

  void _onCameraMove(
    CameraPosition position,
  ) {
    _pinPosition = position.target;

    _debounce?.cancel();
  }

  void _onCameraIdle() {
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(milliseconds: 500),
      () {
        _resolveAddressForPin();
      },
    );
  }

  // =========================================================================
  // REVERSE GEOCODING
  // =========================================================================

  Future<void> _resolveAddressForPin() async {
    if (!mounted) return;

    final int requestId = ++_resolveRequestId;

    final double latitude =
        _pinPosition.latitude;

    final double longitude =
        _pinPosition.longitude;

    setState(() {
      _resolvingAddress = true;
    });

    try {
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(
        latitude,
        longitude,
      );

      // Ignore an old request if user moved the map again.
      if (!mounted ||
          requestId != _resolveRequestId) {
        return;
      }

      if (placemarks.isNotEmpty) {
        final Placemark p = placemarks.first;

        final List<String> addressParts = [
          p.subLocality,
          p.thoroughfare,
          p.street,
        ]
            .where(
              (value) =>
                  value != null &&
                  value.trim().isNotEmpty,
            )
            .map(
              (value) => value!.trim(),
            )
            .toSet()
            .toList();

        final String resolvedLine =
            addressParts.join(', ');

        final String shortName =
            (p.subLocality?.trim().isNotEmpty ?? false)
                ? p.subLocality!.trim()
                : ((p.name?.trim().isNotEmpty ?? false)
                    ? p.name!.trim()
                    : 'Selected location');

        setState(() {
          _shortLabel = shortName;
          _pinLabel = shortName;

          _fullAddress =
              resolvedLine.isNotEmpty
                  ? resolvedLine
                  : (p.name ?? '');

          _city =
              (p.locality?.trim().isNotEmpty ?? false)
                  ? p.locality!.trim()
                  : ((p.subAdministrativeArea
                              ?.trim()
                              .isNotEmpty ??
                          false)
                      ? p.subAdministrativeArea!.trim()
                      : _city);

          _pincode =
              (p.postalCode?.trim().isNotEmpty ?? false)
                  ? p.postalCode!.trim()
                  : _pincode;
        });
      } else {
        setState(() {
          _shortLabel =
              'Address not found';
          _pinLabel = '';
        });
      }
    } catch (_) {
      if (!mounted ||
          requestId != _resolveRequestId) {
        return;
      }

      setState(() {
        _shortLabel =
            'Could not detect address';
        _pinLabel = '';
      });
    } finally {
      if (mounted &&
          requestId == _resolveRequestId) {
        setState(() {
          _resolvingAddress = false;
        });
      }
    }
  }

  // =========================================================================
  // CURRENT LOCATION
  // =========================================================================

  Future<void> _centerOnDeviceLocation({
    bool showErrors = true,
  }) async {
    if (_fetchingCurrentLocation) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _fetchingCurrentLocation = true;
    });

    try {
      // ---------------------------------------------------------------
      // STEP 1
      // CHECK LOCATION SERVICE
      // ---------------------------------------------------------------

      final loc.Location location =
          loc.Location();

      bool serviceEnabled =
          await location.serviceEnabled();

      // ---------------------------------------------------------------
      // STEP 2
      // NATIVE ANDROID LOCATION DIALOG
      // ---------------------------------------------------------------

      if (!serviceEnabled) {
        try {
          serviceEnabled =
              await location.requestService();
        } catch (_) {
          serviceEnabled = false;
        }

        if (!serviceEnabled) {
          if (showErrors) {
            _showSnack(
              'Location is off. Search or drag the map instead.',
            );
          }

          return;
        }
      }

      // ---------------------------------------------------------------
      // STEP 3
      // CHECK APP PERMISSION
      // ---------------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      // ---------------------------------------------------------------
      // PERMISSION DENIED
      // ---------------------------------------------------------------

      if (permission ==
          LocationPermission.denied) {
        if (showErrors) {
          _showSnack(
            'Location permission is required.',
          );
        }

        return;
      }

      // ---------------------------------------------------------------
      // PERMISSION DENIED FOREVER
      // ---------------------------------------------------------------

      if (permission ==
          LocationPermission.deniedForever) {
        if (showErrors) {
          _showSnack(
            'Location permission is blocked. Opening app settings…',
          );

          await Geolocator.openAppSettings();
        }

        return;
      }

      // ---------------------------------------------------------------
      // STEP 4
      // GET HIGH ACCURACY LOCATION
      // ---------------------------------------------------------------

      Position position;

      try {
        position =
            await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
      } catch (_) {
        // -------------------------------------------------------------
        // RETRY WITH MEDIUM ACCURACY
        // -------------------------------------------------------------

        try {
          position =
              await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 6),
            ),
          );
        } catch (_) {
          // -----------------------------------------------------------
          // FALLBACK TO LAST KNOWN LOCATION
          // -----------------------------------------------------------

          final Position? lastKnown =
              await Geolocator.getLastKnownPosition();

          if (lastKnown == null) {
            if (showErrors) {
              _showSnack(
                'Could not get your location. Search or drag the map instead.',
              );
            }

            return;
          }

          position = lastKnown;
        }
      }

      if (!mounted) return;

      // ---------------------------------------------------------------
      // STEP 5
      // UPDATE PIN POSITION
      // ---------------------------------------------------------------

      final LatLng target = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _pinPosition = target;
        _shortLabel = 'Locating...';
        _pinLabel = '';
      });

      // ---------------------------------------------------------------
      // STEP 6
      // WAIT FOR MAP CONTROLLER
      // ---------------------------------------------------------------

      try {
        await _mapReadyCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              target,
              17,
            ),
          );
        }
      } catch (_) {
        // onMapCreated will sync the latest
        // _pinPosition automatically.
      }

      // ---------------------------------------------------------------
      // STEP 7
      // REVERSE GEOCODE
      // ---------------------------------------------------------------

      await _resolveAddressForPin();
    } catch (_) {
      if (showErrors) {
        _showSnack(
          'Could not detect your location. Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _fetchingCurrentLocation = false;
        });
      }
    }
  }

  // =========================================================================
  // SNACKBAR
  // =========================================================================

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

  // =========================================================================
  // SEARCH
  // =========================================================================

  Future<void> _searchAndMove(
    String query,
  ) async {
    final String text = query.trim();

    if (text.isEmpty) {
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      final List<Location> locations =
          await locationFromAddress(text);

      if (locations.isEmpty) {
        _showSnack(
          'No results for "$text"',
        );

        return;
      }

      final Location selected =
          locations.first;

      final LatLng target = LatLng(
        selected.latitude,
        selected.longitude,
      );

      if (!mounted) return;

      setState(() {
        _pinPosition = target;
        _shortLabel = 'Locating...';
        _pinLabel = '';
      });

      // ---------------------------------------------------------------
      // WAIT FOR MAP
      // ---------------------------------------------------------------

      try {
        await _mapReadyCompleter.future.timeout(
          const Duration(seconds: 5),
        );

        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              target,
              17,
            ),
          );
        }
      } catch (_) {
        // onMapCreated handles latest position.
      }

      await _resolveAddressForPin();
    } catch (_) {
      _showSnack(
        'Could not search that location. Try a different term.',
      );
    }
  }

  // =========================================================================
  // STEP 3
  // ADDRESS DETAILS SHEET
  // =========================================================================

  Future<void> _openAddressDetailsSheet() async {
    if (_fullAddress.trim().isEmpty) {
      _showSnack(
        'Please wait for the address to resolve, or search above.',
      );

      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(18),
        ),
      ),
      builder: (sheetContext) {
        return _AddressDetailsSheet(
          resolvedLocality: [
            _fullAddress,
            if (_city.isNotEmpty) _city,
            if (_pincode.isNotEmpty) _pincode,
          ]
              .where(
                (value) => value.trim().isNotEmpty,
              )
              .join(', '),

          initialFlatHouse:
              widget.editingAddress?.addressLine,

          initialPhone:
              widget.editingAddress?.phone,

          initialLabel:
              widget.editingAddress?.label,

          onChangeLocation: () {
            Navigator.pop(sheetContext);
          },

          onSave: _saveAddressDetails,
        );
      },
    );
  }

  // =========================================================================
  // SAVE ADDRESS
  // =========================================================================

  Future<void> _saveAddressDetails(
    String flatHouse,
    String fullName,
    String phone,
    String altPhone,
    String label,
  ) async {
    // ---------------------------------------------------------------
    // MODEL DOES NOT HAVE:
    // recipientName
    // alternatePhone
    //
    // So full name is folded into addressLine.
    // ---------------------------------------------------------------

    final List<String> addressParts = [
      flatHouse,
      fullName,
      _fullAddress,
    ]
        .where(
          (value) => value.trim().isNotEmpty,
        )
        .map(
          (value) => value.trim(),
        )
        .toList();

    final String addressLine =
        addressParts.join(', ');

    final ShopAddress address =
        ShopAddress(
      id:
          widget.editingAddress?.id ??
          'a${DateTime.now().millisecondsSinceEpoch}',

      label: label,

      addressLine: addressLine,

      city: _city.trim(),

      pincode: _pincode.trim(),

      phone: phone.trim(),

      latitude: _pinPosition.latitude,

      longitude: _pinPosition.longitude,
    );

    // ---------------------------------------------------------------
    // UPDATE
    // ---------------------------------------------------------------

    if (widget.editingAddress != null) {
      await ApiService.instance.updateAddress(
        address,
      );
    }

    // ---------------------------------------------------------------
    // ADD
    // ---------------------------------------------------------------

    else {
      await ApiService.instance.addAddress(
        address,
      );
    }

    if (!mounted) return;

    // Close details sheet
    Navigator.pop(context);

    // Close map page and return saved address
    Navigator.pop(
      context,
      address,
    );
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------------------------------------------------------------
      // APP BAR
      // ---------------------------------------------------------------------

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: Text(
          widget.editingAddress != null
              ? 'Edit Address'
              : 'Add new address',
        ),

        backgroundColor: Colors.white,

        foregroundColor: Colors.black,

        elevation: 0.5,
      ),

      // ---------------------------------------------------------------------
      // BODY
      // ---------------------------------------------------------------------

      body: Column(
        children: [
          // =================================================================
          // MAP
          // =================================================================

          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // -----------------------------------------------------------
                // GOOGLE MAP
                // -----------------------------------------------------------

                GoogleMap(
                  initialCameraPosition:
                      CameraPosition(
                    target: _pinPosition,
                    zoom: 16,
                  ),

                  onMapCreated:
                      (GoogleMapController controller) {
                    _mapController = controller;

                    if (!_mapReadyCompleter
                        .isCompleted) {
                      _mapReadyCompleter.complete();
                    }

                    // If current location was detected
                    // before map creation, sync camera.
                    controller.moveCamera(
                      CameraUpdate.newLatLngZoom(
                        _pinPosition,
                        16,
                      ),
                    );
                  },

                  onCameraMove:
                      _onCameraMove,

                  onCameraIdle:
                      _onCameraIdle,

                  myLocationButtonEnabled: false,

                  zoomControlsEnabled: false,

                  mapToolbarEnabled: false,

                  compassEnabled: true,

                  rotateGesturesEnabled: true,

                  scrollGesturesEnabled: true,

                  zoomGesturesEnabled: true,

                  tiltGesturesEnabled: false,
                ),

                // -----------------------------------------------------------
                // FIXED CENTER PIN
                // -----------------------------------------------------------

                IgnorePointer(
                  child: Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 42,
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        // ---------------------------------------------------
                        // PIN TOP MESSAGE
                        // ---------------------------------------------------

                        Container(
                          margin:
                              const EdgeInsets.only(
                            bottom: 4,
                          ),

                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),

                          decoration:
                              BoxDecoration(
                            color: Colors.black87,
                            borderRadius:
                                BorderRadius.circular(
                              8,
                            ),
                          ),

                          child: Text(
                            _resolvingAddress
                                ? 'Locating...'
                                : 'Place pin on the exact location',

                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        // ---------------------------------------------------
                        // PIN ICON
                        // ---------------------------------------------------

                        const Icon(
                          Icons.location_pin,
                          size: 44,
                          color: Colors.black87,
                        ),

                        // ---------------------------------------------------
                        // LOCATION LABEL
                        // ---------------------------------------------------

                        if (!_resolvingAddress &&
                            _pinLabel
                                .trim()
                                .isNotEmpty)
                          Container(
                            margin:
                                const EdgeInsets.only(
                              top: 4,
                            ),

                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),

                            decoration:
                                BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                color: Colors.blue,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                6,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color:
                                      Colors.black12,
                                  blurRadius: 3,
                                ),
                              ],
                            ),

                            child: Text(
                              _pinLabel,

                              maxLines: 1,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // -----------------------------------------------------------
                // SEARCH BAR
                // -----------------------------------------------------------

                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Material(
                    elevation: 4,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),

                    child: TextField(
                      controller:
                          _searchController,

                      textInputAction:
                          TextInputAction.search,

                      decoration:
                          InputDecoration(
                        hintText:
                            'Search by area, name, street.',

                        prefixIcon:
                            const Icon(
                          Icons.search,
                        ),

                        suffixIcon:
                            _searchController
                                    .text
                                    .isNotEmpty
                                ? IconButton(
                                    icon:
                                        const Icon(
                                      Icons.clear,
                                    ),
                                    onPressed: () {
                                      _searchController
                                          .clear();

                                      setState(() {});
                                    },
                                  )
                                : null,

                        border:
                            OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          borderSide:
                              BorderSide.none,
                        ),

                        filled: true,

                        fillColor:
                            Colors.white,

                        contentPadding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 14,
                        ),
                      ),

                      onChanged: (_) {
                        setState(() {});
                      },

                      onSubmitted:
                          _searchAndMove,
                    ),
                  ),
                ),

                // -----------------------------------------------------------
                // USE CURRENT LOCATION BUTTON
                // -----------------------------------------------------------

                Positioned(
                  bottom: 12,
                  child: Material(
                    elevation: 4,

                    borderRadius:
                        BorderRadius.circular(
                      24,
                    ),

                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),

                      onTap:
                          _fetchingCurrentLocation
                              ? null
                              : () {
                                  _centerOnDeviceLocation(
                                    showErrors: true,
                                  );
                                },

                      child: Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),

                        decoration:
                            BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(
                            24,
                          ),
                        ),

                        child: Row(
                          mainAxisSize:
                              MainAxisSize.min,
                          children: [
                            if (_fetchingCurrentLocation)
                              const SizedBox(
                                height: 16,
                                width: 16,
                                child:
                                    CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            else
                              const Icon(
                                Icons.my_location,
                                size: 18,
                                color: Colors.blue,
                              ),

                            const SizedBox(width: 8),

                            Text(
                              _fetchingCurrentLocation
                                  ? 'Locating...'
                                  : 'Use my current location',

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // -----------------------------------------------------------
                // ENTRY CHOICE SCRIM
                // -----------------------------------------------------------

                if (_entryChoicePending)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black
                            .withOpacity(0.15),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // =================================================================
          // DELIVER TO SUMMARY
          // =================================================================

          Container(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              20,
            ),

            decoration:
                const BoxDecoration(
              color: Colors.white,

              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, -2),
                ),
              ],
            ),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Deliver To',

                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 8),

                // -----------------------------------------------------------
                // ADDRESS CARD
                // -----------------------------------------------------------

                Container(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  decoration:
                      BoxDecoration(
                    border: Border.all(
                      color: AppColors.gray,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 20,
                      ),

                      const SizedBox(width: 8),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: [
                            Text(
                              _shortLabel,
                              maxLines: 1,
                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 4,
                            ),

                            Text(
                              [
                                _fullAddress,
                                if (_city
                                    .trim()
                                    .isNotEmpty)
                                  _city,
                                if (_pincode
                                    .trim()
                                    .isNotEmpty)
                                  _pincode,
                              ]
                                  .where(
                                    (value) =>
                                        value
                                            .trim()
                                            .isNotEmpty,
                                  )
                                  .join(', '),

                              maxLines: 3,

                              overflow:
                                  TextOverflow.ellipsis,

                              style:
                                  const TextStyle(
                                fontSize: 12.5,
                                color:
                                    AppColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // -----------------------------------------------------------
                // ADD ADDRESS DETAILS
                // -----------------------------------------------------------

                SizedBox(
                  width: double.infinity,

                  child: FilledButton(
                    onPressed:
                        _openAddressDetailsSheet,

                    style:
                        FilledButton.styleFrom(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 14,
                      ),
                    ),

                    child: const Text(
                      'Add address Details',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// STEP 3
// ADDRESS DETAILS BOTTOM SHEET
// =============================================================================

class _AddressDetailsSheet
    extends StatefulWidget {
  final String resolvedLocality;

  final String? initialFlatHouse;
  final String? initialPhone;
  final String? initialLabel;

  final VoidCallback onChangeLocation;

  final Future<void> Function(
    String flatHouse,
    String fullName,
    String phone,
    String altPhone,
    String label,
  ) onSave;

  const _AddressDetailsSheet({
    required this.resolvedLocality,
    required this.onChangeLocation,
    required this.onSave,
    this.initialFlatHouse,
    this.initialPhone,
    this.initialLabel,
  });

  @override
  State<_AddressDetailsSheet> createState() =>
      _AddressDetailsSheetState();
}

class _AddressDetailsSheetState
    extends State<_AddressDetailsSheet> {
  // -------------------------------------------------------------------------
  // FORM
  // -------------------------------------------------------------------------

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _flatHouseController;

  final TextEditingController
      _fullNameController =
      TextEditingController();

  late final TextEditingController
      _phoneController;

  final TextEditingController
      _altPhoneController =
      TextEditingController();

  // -------------------------------------------------------------------------
  // ADDRESS TYPE
  // -------------------------------------------------------------------------

  String _addressType = 'Home';

  bool _saving = false;

  // -------------------------------------------------------------------------
  // INIT
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _flatHouseController =
        TextEditingController(
      text: widget.initialFlatHouse ?? '',
    );

    _phoneController =
        TextEditingController(
      text: widget.initialPhone ?? '',
    );

    _addressType =
        widget.initialLabel == 'Work'
            ? 'Work'
            : 'Home';
  }

  // -------------------------------------------------------------------------
  // DISPOSE
  // -------------------------------------------------------------------------

  @override
  void dispose() {
    _flatHouseController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _altPhoneController.dispose();

    super.dispose();
  }

  // =========================================================================
  // SUBMIT
  // =========================================================================

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (_saving) return;

    setState(() {
      _saving = true;
    });

    try {
      await widget.onSave(
        _flatHouseController.text.trim(),
        _fullNameController.text.trim(),
        _phoneController.text.trim(),
        _altPhoneController.text.trim(),
        _addressType,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Could not save address. Please try again.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  // =========================================================================
  // BUILD
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final double keyboardHeight =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: keyboardHeight,
      ),

      child: SafeArea(
        top: false,

        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior
                  .onDrag,

          padding:
              const EdgeInsets.fromLTRB(
            20,
            20,
            20,
            20,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              mainAxisSize:
                  MainAxisSize.min,

              children: [
                // ===========================================================
                // HEADER
                // ===========================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    const Text(
                      'Deliver To',

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    IconButton(
                      icon: const Icon(
                        Icons.close,
                      ),

                      onPressed: _saving
                          ? null
                          : () {
                              Navigator.pop(
                                context,
                              );
                            },
                    ),
                  ],
                ),

                // ===========================================================
                // INFO BOX
                // ===========================================================

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  margin:
                      const EdgeInsets.only(
                    bottom: 16,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFFFF3E0,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),

                  child: const Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 18,
                        color: Colors.orange,
                      ),

                      SizedBox(width: 8),

                      Expanded(
                        child: Text(
                          'Ensure your address details are accurate for a smooth delivery experience',
                          style: TextStyle(
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ===========================================================
                // FLAT / HOUSE
                // ===========================================================

                TextFormField(
                  controller:
                      _flatHouseController,

                  textCapitalization:
                      TextCapitalization
                          .words,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Flat/House/building name *',
                    border:
                        OutlineInputBorder(),
                    isDense: true,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Required';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // ===========================================================
                // AREA / LOCALITY
                // ===========================================================

                const Text(
                  'Area / Sector / Locality',

                  style: TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textLight,
                  ),
                ),

                const SizedBox(height: 6),

                Container(
                  width: double.infinity,

                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFF2F2F2,
                    ),

                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Expanded(
                        child: Text(
                          widget
                              .resolvedLocality,

                          style:
                              const TextStyle(
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),
                      ),

                      TextButton(
                        onPressed: _saving
                            ? null
                            : widget
                                .onChangeLocation,

                        child:
                            const Text(
                          'Change',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ===========================================================
                // FULL NAME
                // ===========================================================

                TextFormField(
                  controller:
                      _fullNameController,

                  textCapitalization:
                      TextCapitalization
                          .words,

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Enter your full name *',
                    border:
                        OutlineInputBorder(),
                    isDense: true,
                  ),

                  validator: (value) {
                    if (value == null ||
                        value.trim().isEmpty) {
                      return 'Required';
                    }

                    if (value.trim().length <
                        2) {
                      return 'Enter a valid name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // ===========================================================
                // MOBILE
                // ===========================================================

                TextFormField(
                  controller:
                      _phoneController,

                  keyboardType:
                      TextInputType.phone,

                  maxLength: 10,

                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,
                  ],

                  decoration:
                      const InputDecoration(
                    labelText:
                        '10-digit mobile number *',
                    border:
                        OutlineInputBorder(),
                    isDense: true,
                    counterText: '',
                  ),

                  validator: (value) {
                    final String phone =
                        value?.trim() ?? '';

                    if (phone.length != 10) {
                      return 'Enter a valid 10-digit number';
                    }

                    if (phone.startsWith('0')) {
                      return 'Enter a valid mobile number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 14),

                // ===========================================================
                // ALTERNATE MOBILE
                // ===========================================================

                TextFormField(
                  controller:
                      _altPhoneController,

                  keyboardType:
                      TextInputType.phone,

                  maxLength: 10,

                  inputFormatters: [
                    FilteringTextInputFormatter
                        .digitsOnly,
                  ],

                  decoration:
                      const InputDecoration(
                    labelText:
                        'Alternate phone number (Optional)',
                    border:
                        OutlineInputBorder(),
                    isDense: true,
                    counterText: '',
                  ),

                  validator: (value) {
                    final String altPhone =
                        value?.trim() ?? '';

                    if (altPhone.isEmpty) {
                      return null;
                    }

                    if (altPhone.length != 10) {
                      return 'Enter a valid 10-digit number';
                    }

                    if (altPhone.startsWith('0')) {
                      return 'Enter a valid mobile number';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ===========================================================
                // ADDRESS TYPE
                // ===========================================================

                const Text(
                  'Type of address',

                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    _AddressTypeChip(
                      icon:
                          Icons.home_outlined,

                      label: 'Home',

                      selected:
                          _addressType ==
                              'Home',

                      onTap: _saving
                          ? () {}
                          : () {
                              setState(() {
                                _addressType =
                                    'Home';
                              });
                            },
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    _AddressTypeChip(
                      icon:
                          Icons.apartment_outlined,

                      label: 'Work',

                      selected:
                          _addressType ==
                              'Work',

                      onTap: _saving
                          ? () {}
                          : () {
                              setState(() {
                                _addressType =
                                    'Work';
                              });
                            },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ===========================================================
                // SAVE
                // ===========================================================

                SizedBox(
                  width: double.infinity,

                  child: FilledButton(
                    onPressed:
                        _saving
                            ? null
                            : _submit,

                    style:
                        FilledButton.styleFrom(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        vertical: 14,
                      ),
                    ),

                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,

                            child:
                                CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save address',
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// HOME / WORK CHIP
// =============================================================================

class _AddressTypeChip
    extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AddressTypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      borderRadius:
          BorderRadius.circular(8),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        decoration:
            BoxDecoration(
          border: Border.all(
            color: selected
                ? Colors.blue
                : AppColors.gray,
          ),

          borderRadius:
              BorderRadius.circular(8),

          color: selected
              ? Colors.blue.withOpacity(
                  0.08,
                )
              : Colors.white,
        ),

        child: Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            Icon(
              icon,

              size: 18,

              color: selected
                  ? Colors.blue
                  : Colors.black87,
            ),

            const SizedBox(width: 6),

            Text(
              label,

              style: TextStyle(
                color: selected
                    ? Colors.blue
                    : Colors.black87,

                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}