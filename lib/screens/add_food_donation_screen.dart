
import 'package:flutter/material.dart';

class AddFoodDonationScreen extends StatefulWidget {
  const AddFoodDonationScreen({super.key});

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

  String? selectedCategory;
  DateTime? selectedDate;

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

  Future<void> pickAvailabilityDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

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

  void submitDonation() {
    final isValid = _formKey.currentState!.validate();

    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an availability date.'),
        ),
      );
      return;
    }

    if (!isValid) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Form completed. Backend integration is pending.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
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
                value: selectedCategory,
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
                onChanged: (value) {
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
                keyboardType: TextInputType.number,
                decoration: inputDecoration('Enter quantity'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value.trim()) == null ||
                      int.parse(value.trim()) <= 0) {
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
              TextFormField(
                controller: locationController,
                maxLines: 2,
                decoration: inputDecoration(
                  'Enter complete pickup address',
                ).copyWith(
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Colors.green,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter pickup location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              const Text('Availability Date *'),
              const SizedBox(height: 8),
              InkWell(
                onTap: pickAvailabilityDate,
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
              const SizedBox(height: 20),

              const Text('Food Image (Optional)'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 42,
                      color: Colors.green,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Upload Food Image',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Image upload will be connected later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: submitDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
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
