
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final TextEditingController searchController =
      TextEditingController();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late final Stream<QuerySnapshot<Map<String, dynamic>>> _usersStream;

  String selectedRole = 'All';
  String selectedStatus = 'All';

  final List<String> roles = [
    'All',
    'Donor',
    'Receiver',
    'Volunteer',
    'Pending',
  ];

  final List<String> statuses = [
    'All',
    'Active',
    'Blocked',
  ];

  final Set<String> _processingUserIds = {};

  bool _isCheckingAdmin = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _usersStream = _db.collection('users').snapshots();

    _verifyAdmin();
  }

  Future<void> _verifyAdmin() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('Please log in first.');
      }

      final tokenResult = await user.getIdTokenResult(true);

      if (!mounted) return;

      setState(() {
        _isAdmin = tokenResult.claims?['admin'] == true;
        _isCheckingAdmin = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isCheckingAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'donor':
        return Colors.green;
      case 'receiver':
        return Colors.blue;
      case 'volunteer':
        return Colors.orange;
      case 'pending':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  Color _statusColor(String status) {
    return status.toLowerCase() == 'active'
        ? Colors.green
        : Colors.red;
  }

  Future<void> _changeUserStatus(UserModel user) async {
    if (_processingUserIds.contains(user.id)) return;

    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      _showMessage('Please log in first.');
      return;
    }

    // Admin cannot change their own account status.
    if (currentUser.uid == user.id) {
      _showMessage(
        'You cannot change your own account status.',
      );
      return;
    }

    final currentStatus = user.status.toLowerCase();

    if (currentStatus != 'active' &&
        currentStatus != 'blocked') {
      _showMessage('This user status cannot be changed.');
      return;
    }

    final bool shouldBlock = currentStatus == 'active';
    final String newStatus = shouldBlock ? 'blocked' : 'active';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: Text(
            shouldBlock ? 'Block User?' : 'Activate User?',
          ),
          content: Text(
            shouldBlock
                ? 'Are you sure you want to block ${user.name}? '
                    'This user will no longer be able to use the platform.'
                : 'Are you sure you want to activate ${user.name}? '
                    'This user will be able to use the platform again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    shouldBlock ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: Text(
                shouldBlock ? 'Block' : 'Activate',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _processingUserIds.add(user.id);
    });

    try {
      // Refresh and verify the current admin claim.
      final tokenResult = await currentUser.getIdTokenResult(true);

      if (tokenResult.claims?['admin'] != true) {
        throw Exception('Admin permission is required.');
      }

      await _db.collection('users').doc(user.id).update({
        'status': newStatus,
      });

      if (!mounted) return;

      _showMessage(
        shouldBlock
            ? '${user.name} has been blocked.'
            : '${user.name} has been activated.',
      );
    } catch (e) {
      if (!mounted) return;

      _showMessage('Could not update user status: $e');
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(user.id);
        });
      }
    }
  }

  void _showMessage(String message) {
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final roleColor = _roleColor(user.userType);
    final statusColor = _statusColor(user.status);

    final bool isCurrentUser =
        _auth.currentUser?.uid == user.id;

    final bool canChangeStatus =
        user.status.toLowerCase() == 'active' ||
        user.status.toLowerCase() == 'blocked';

    final bool isBlocked =
        user.status.toLowerCase() == 'blocked';

    final bool isProcessing =
        _processingUserIds.contains(user.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.green.shade50,
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
                child: user.photoUrl.isEmpty
                    ? const Icon(
                        Icons.person,
                        color: Colors.green,
                        size: 27,
                      )
                    : null,
              ),

              const SizedBox(width: 13),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name.isEmpty
                          ? 'Unnamed User'
                          : user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      user.email,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),

                    if (user.phone.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.phone,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildBadge(
                          user.userType.toUpperCase(),
                          roleColor,
                        ),
                        _buildBadge(
                          user.status.toUpperCase(),
                          statusColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (canChangeStatus && !isCurrentUser) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isProcessing
                    ? null
                    : () => _changeUserStatus(user),
                icon: isProcessing
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        isBlocked
                            ? Icons.check_circle_outline
                            : Icons.block_outlined,
                      ),
                label: Text(
                  isProcessing
                      ? 'Please wait...'
                      : isBlocked
                          ? 'Activate User'
                          : 'Block User',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      isBlocked ? Colors.green : Colors.red,
                  side: BorderSide(
                    color: isBlocked ? Colors.green : Colors.red,
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 11,
                  ),
                ),
              ),
            ),
          ] else if (isCurrentUser) ...[
            const SizedBox(height: 10),
            Text(
              'Your Admin Account',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 35,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 65,
            color: Colors.green.shade300,
          ),

          const SizedBox(height: 15),

          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.5,
            ),
          ),

          const SizedBox(height: 18),

          OutlinedButton.icon(
            onPressed: () {
              searchController.clear();

              setState(() {
                selectedRole = 'All';
                selectedStatus = 'All';
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filters'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips({
    required List<String> options,
    required String selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          final isSelected = selectedValue == option;

          return ChoiceChip(
            label: Text(option),
            selected: isSelected,
            selectedColor: Colors.green,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            onSelected: (selected) {
              if (selected) {
                onSelected(option);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildUserList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(35),
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildEmptyState(
            title: 'Could Not Load Users',
            message:
                'Please check your Firestore permissions and connection.\n'
                '${snapshot.error}',
          );
        }

        final users = snapshot.data?.docs.map((doc) {
              return UserModel.fromMap(doc.id, doc.data());
            }).toList() ??
            <UserModel>[];

        final searchText =
            searchController.text.trim().toLowerCase();

        final filteredUsers = users.where((user) {
          final matchesRole = selectedRole == 'All' ||
              user.userType.toLowerCase() ==
                  selectedRole.toLowerCase();

          final matchesStatus = selectedStatus == 'All' ||
              user.status.toLowerCase() ==
                  selectedStatus.toLowerCase();

          final matchesSearch =
              user.name.toLowerCase().contains(searchText) ||
              user.email.toLowerCase().contains(searchText) ||
              user.phone.toLowerCase().contains(searchText);

          return matchesRole &&
              matchesStatus &&
              matchesSearch;
        }).toList();

        if (filteredUsers.isEmpty) {
          return _buildEmptyState(
            title: 'No Users Found',
            message: users.isEmpty
                ? 'No user records are available yet.'
                : 'No users match your search or selected filters.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${filteredUsers.length} user(s) found',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 12),

            ...filteredUsers.map(_buildUserCard),
          ],
        );
      },
    );
  }

  Widget _buildAccessDenied() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 75,
              color: Colors.red.shade300,
            ),

            const SizedBox(height: 18),

            const Text(
              'Admin Access Required',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'You do not have permission to manage users.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 20),

            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _isCheckingAdmin = true;
                  _error = null;
                });
                _verifyAdmin();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Check Again'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F5),
      appBar: AppBar(
        title: const Text(
          'Manage Users',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isCheckingAdmin
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.green,
              ),
            )
          : !_isAdmin
              ? _buildAccessDenied()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'User Management',
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'View, search, block and activate platform users.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 22),

                      TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.green,
                          ),
                          suffixIcon: searchController.text.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      const Text(
                        'Filter by Role',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildFilterChips(
                        options: roles,
                        selectedValue: selectedRole,
                        onSelected: (value) {
                          setState(() {
                            selectedRole = value;
                          });
                        },
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'Filter by Account Status',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      _buildFilterChips(
                        options: statuses,
                        selectedValue: selectedStatus,
                        onSelected: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                      ),

                      const SizedBox(height: 30),

                      const Text(
                        'All Users',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      _buildUserList(),
                    ],
                  ),
                ),
    );
  }
}
