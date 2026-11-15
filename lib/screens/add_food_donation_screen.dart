
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/donation_model.dart';
import '../services/donation_service.dart';

class AddFoodDonationScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const AddFoodDonationScreen({
    super.key,
    this.onBack,
  });

  @override
  State<AddFoodDonationScreen> createState() =>
      _AddFoodDonationScreenState();
}

class _AddFoodDonationScreenState
    extends State<AddFoodDonationScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController foodNameController =
      TextEditingController();

  final TextEditingController quantityController =
      TextEditingController();

  final TextEditingController descriptionController =
      TextEditingController();

  final TextEditingController locationController =
      TextEditingController();

  final DonationService _donationService = DonationService();

  String? selectedCategory;
  DateTime? selectedDate;

  GeoPoint? selectedLocation;

  bool isLoading = false;
  bool isGettingLocation = false;

  final List<String> categories = [
    'Cooked Food',
    'Rice & Grains',
    'Fruits & Vegetables',
    'Bakery Items',
    'Packaged Food',
    'Other',
  ];

  @override
  void dispose() {
    foodNameController.dispose();
    quantityController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // GET CURRENT GPS LOCATION
  Future<void> getCurrentLocation() async {
    if (isLoading || isGettingLocation) return;

    setState(() {
      isGettingLocation = true;
    });

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Please turn on your phone location/GPS.',
          isError: true,
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage(
          'Location permission was denied.',
          isError: true,
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is permanently denied. '
          'Please enable it from App Settings.',
          isError: true,
        );
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) return;

      setState(() {
        selectedLocation = GeoPoint(
          position.latitude,
          position.longitude,
        );
      });

      _showMessage('GPS location captured successfully!');
    } catch (e) {
      debugPrint('GPS LOCATION ERROR: $e');

      _showMessage(
        'Could not get your current location. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isGettingLocation = false;
        });
      }
    }
  }

  // PICK AVAILABILITY DATE
  Future<void> pickAvailabilityDate() async {
    if (isLoading) return;

    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null && mounted) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // INPUT DECORATION
  InputDecoration inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.all(16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // SHOW MESSAGE
  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // RESET FORM
  void _resetForm() {
    _formKey.currentState?.reset();

    foodNameController.clear();
    quantityController.clear();
    descriptionController.clear();
    locationController.clear();

    setState(() {
      selectedCategory = null;
      selectedDate = null;
      selectedLocation = null;
    });
  }

  // SUBMIT DONATION TO FIRESTORE
  Future<void> submitDonation() async {
    FocusScope.of(context).unfocus();

    if (isLoading || isGettingLocation) return;

    final bool isValid =
        _formKey.currentState?.validate() ?? false;

    if (selectedDate == null) {
      _showMessage(
        'Please select an availability date.',
        isError: true,
      );
      return;
    }

    if (!isValid) return;

    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage(
        'Please login first.',
        isError: true,
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final DateTime expiryTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        23,
        59,
        59,
      );

      final DonationModel donation = DonationModel(
        donorId: user.uid,
        donorName: user.displayName ?? 'FoodLink User',
        title: foodNameController.text.trim(),
        description: descriptionController.text.trim(),
        foodType: selectedCategory!,
        quantity: quantityController.text.trim(),
        imageUrl: '',
        pickupLocation: selectedLocation,
        pickupAddress: locationController.text.trim(),
        expiryTime: expiryTime,
        status: 'available',
      );

      final String donationId =
          await _donationService.addDonation(donation);

      debugPrint('DONATION CREATED SUCCESSFULLY');
      debugPrint('DONATION ID: $donationId');

      if (!mounted) return;

      _resetForm();

      _showMessage(
        'Food donation submitted successfully!',
      );
    } catch (e) {
      debugPrint('DONATION SUBMISSION ERROR: $e');

      if (!mounted) return;

      String message =
          'Failed to submit donation. Please try again.';

      if (e.toString().contains('Only donors')) {
        message = 'Only donors can create food donations.';
      } else if (e.toString().contains('User profile not found')) {
        message = 'Your user profile was not found.';
      } else if (e.toString().contains('Please log in')) {
        message = 'Please login first.';
      }

      _showMessage(message, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        leading: widget.onBack != null
            ? IconButton(
                tooltip: 'Back to Home',
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBack,
              )
            : null,
        title: const Text('Add Food Donation'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share Your Extra Food',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Provide food details to help people in need.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 25),

              const Text('Food Name *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: foodNameController,
                enabled: !isLoading,
                decoration: inputDecoration('Enter food name'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter food name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text('Food Category *'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                isExpanded: true,
                hint: const Text('Select category'),
                decoration: inputDecoration('Select category'),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Please select a category';
                  }
                  return null;
                },
                onChanged: isLoading
                    ? null
                    : (value) {
                        setState(() {
                          selectedCategory = value;
                        });
                      },
              ),

              const SizedBox(height: 20),

              const Text('Quantity *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: quantityController,
                enabled: !isLoading,
                keyboardType: TextInputType.number,
                decoration: inputDecoration('Enter quantity'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }

                  final int? quantity =
                      int.tryParse(value.trim());

                  if (quantity == null || quantity <= 0) {
                    return 'Enter a valid positive number';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text('Food Description *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: descriptionController,
                enabled: !isLoading,
                maxLines: 4,
                decoration: inputDecoration(
                  'Describe the food and its condition',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter food description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text('Pickup Location *'),
              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: isLoading || isGettingLocation
                      ? null
                      : getCurrentLocation,
                  icon: isGettingLocation
                      ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        )
                      : const Icon(
                          Icons.my_location,
                          color: Colors.green,
                        ),
                  label: Text(
                    isGettingLocation
                        ? 'Getting Current Location...'
                        : 'Use Current Location',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              if (selectedLocation != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'GPS Location Captured',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Latitude: ${selectedLocation!.latitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              'Longitude: ${selectedLocation!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  selectedLocation = null;
                                });
                              },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 15),

              const Text('Pickup Address *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: locationController,
                enabled: !isLoading,
                maxLines: 2,
                decoration: inputDecoration(
                  'Enter complete pickup address',
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.home_outlined,
                    color: Colors.green,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter pickup address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              const Text(
                'You can provide GPS location and your complete '
                'address for easier food collection.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 20),

              const Text('Availability Date *'),
              const SizedBox(height: 8),
              InkWell(
                onTap: isLoading ? null : pickAvailabilityDate,
                child: InputDecorator(
                  decoration: inputDecoration(
                    'Select availability date',
                  ).copyWith(
                    prefixIcon: const Icon(
                      Icons.calendar_today,
                      color: Colors.green,
                    ),
                  ),
                  child: Text(
                    selectedDate == null
                        ? 'Select a date'
                        : '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                    style: TextStyle(
                      color: selectedDate == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading || isGettingLocation
                      ? null
                      : submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Submit Donation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
