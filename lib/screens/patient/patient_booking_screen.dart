import 'package:flutter/material.dart';

import '../../services/clinic_service.dart';
import '../../services/location_service.dart';
import '../../services/provider_directory_service.dart';
import '../../theme/app_theme.dart';

/// Patient "Book Consultation" tab. Lets the patient toggle between
/// browsing individual providers (existing list) and discovering nearby
/// clinics (new). Clinics are pulled live from the OpenStreetMap
/// Overpass API and ranked by distance from the user's GPS location.
class PatientBookingScreen extends StatefulWidget {
  const PatientBookingScreen({super.key});

  @override
  State<PatientBookingScreen> createState() => _PatientBookingScreenState();
}

enum _BookingMode { providers, clinics }

class _PatientBookingScreenState extends State<PatientBookingScreen> {
  final _locationService = LocationService();
  final _clinicService = ClinicService();
  final _providerDirectoryService = ProviderDirectoryService();

  _BookingMode _mode = _BookingMode.providers;

  // Clinic state. We hold the data on the screen so toggling back to
  // Providers and returning doesn't refetch unnecessarily.
  bool _clinicsLoading = false;
  String? _clinicsError;
  List<NearbyClinic> _clinics = const [];

  bool _providersLoading = false;
  String? _providersError;
  List<ApprovedProvider> _providers = const [];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() {
      _providersLoading = true;
      _providersError = null;
    });
    try {
      final providers = await _providerDirectoryService.fetchApprovedProviders();
      if (!mounted) return;
      setState(() {
        _providers = providers;
        _providersLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _providersError = 'Couldn\'t load approved providers. Please try again.\n$e';
        _providersLoading = false;
      });
    }
  }

  Future<void> _loadClinics() async {
    setState(() {
      _clinicsLoading = true;
      _clinicsError = null;
    });
    try {
      final position = await _locationService.getCurrentPosition();
      final clinics = await _clinicService.getNearbyClinics(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      setState(() {
        _clinics = clinics;
        _clinicsLoading = false;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _clinicsError = e.message;
        _clinicsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _clinicsError = 'Couldn\'t load nearby clinics. Please try again.\n$e';
        _clinicsLoading = false;
      });
    }
  }

  void _setMode(_BookingMode next) {
    if (next == _mode) return;
    setState(() => _mode = next);
    // Lazy-load clinics the first time the user opens that tab.
    if (next == _BookingMode.clinics &&
        _clinics.isEmpty &&
        !_clinicsLoading &&
        _clinicsError == null) {
      _loadClinics();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Book Consultation'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _ModeToggle(mode: _mode, onChanged: _setMode),
            const SizedBox(height: 16),
            _SearchBar(mode: _mode),
            Expanded(
              child: _mode == _BookingMode.providers
                  ? _buildProvidersList(theme)
                  : _buildClinicsList(theme),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- PROVIDERS TAB ----------

  Widget _buildProvidersList(ThemeData theme) {
    if (_providersLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_providersError != null) {
      return _ProvidersErrorState(
        message: _providersError!,
        onRetry: _loadProviders,
      );
    }

    if (_providers.isEmpty) {
      return _ProvidersEmptyState(onRetry: _loadProviders);
    }

    return RefreshIndicator(
      onRefresh: _loadProviders,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _providers.length,
        itemBuilder: (context, index) {
          final provider = _providers[index];
          final cardColor = const [
            Color(0xFFEDE8FF),
            Color(0xFFE5F7F3),
            Color(0xFFFFEEE7),
          ][index % 3];
          final displayName = _providerNameForCard(provider);

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        provider.specialization,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${provider.yearsOfExperience} years exp',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const _ApprovedProviderBadge(),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6D8FE5),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Book'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _providerNameForCard(ApprovedProvider provider) {
    final specialization = provider.specialization.toLowerCase();
    final isPsychiatry = specialization.contains('psychiatrist') ||
        specialization.contains('psychiatry');
    if (isPsychiatry) return provider.displayName;
    return provider.displayName.replaceFirst(RegExp(r'^Dr\.\s*'), '');
  }

  // ---------- CLINICS TAB ----------

  Widget _buildClinicsList(ThemeData theme) {
    if (_clinicsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_clinicsError != null) {
      return _ClinicsErrorState(
        message: _clinicsError!,
        onRetry: _loadClinics,
      );
    }

    if (_clinics.isEmpty) {
      return _ClinicsEmptyState(onRetry: _loadClinics);
    }

    return RefreshIndicator(
      onRefresh: _loadClinics,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _clinics.length,
        itemBuilder: (context, index) =>
            _ClinicCard(clinic: _clinics[index]),
      ),
    );
  }
}

// =====================================================================
// Sub-widgets
// =====================================================================

/// Pill-style segmented toggle: Providers | Clinics.
class _ModeToggle extends StatelessWidget {
  final _BookingMode mode;
  final ValueChanged<_BookingMode> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: [
            _ToggleButton(
              label: 'Providers',
              icon: Icons.person_outline,
              selected: mode == _BookingMode.providers,
              onTap: () => onChanged(_BookingMode.providers),
            ),
            _ToggleButton(
              label: 'Clinics',
              icon: Icons.local_hospital_outlined,
              selected: mode == _BookingMode.clinics,
              onTap: () => onChanged(_BookingMode.clinics),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Search bar with mode-specific hint text. Currently a placeholder \u2014
/// wiring it up to filter the lists is a follow-up.
class _SearchBar extends StatelessWidget {
  final _BookingMode mode;
  const _SearchBar({required this.mode});

  @override
  Widget build(BuildContext context) {
    final hint = mode == _BookingMode.providers
        ? 'Search providers, specialties...'
        : 'Search clinics by name...';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: const Icon(Icons.filter_list),
          filled: true,
          fillColor: const Color(0xFFF5F7FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  final NearbyClinic clinic;
  const _ClinicCard({required this.clinic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: theme.colorScheme.secondary,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          clinic.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (clinic.isVerified) ...[
                        const SizedBox(width: 6),
                        const _VerifiedBadge(),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    clinic.specialty ?? 'Mental Health',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          clinic.address,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Rating pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              clinic.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8A6D00),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${clinic.reviewCount})',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Distance pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.near_me_rounded,
                              size: 12,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              clinic.distanceLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
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
          ],
        ),
      ),
    );
  }
}

/// Small "Verified" pill shown on curated clinics that an admin has
/// confirmed (coordinates checked, name accurate). OSM clinics never
/// show this pill since their data is volunteer-contributed and not
/// vetted by us.
class _VerifiedBadge extends StatelessWidget {
  const _VerifiedBadge();

  static const Color _verifiedGreen = Color(0xFF1F9D55);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _verifiedGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, color: _verifiedGreen, size: 12),
          SizedBox(width: 2),
          Text(
            'Verified',
            style: TextStyle(
              color: _verifiedGreen,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovedProviderBadge extends StatelessWidget {
  const _ApprovedProviderBadge();

  static const Color _approvedBlue = Color(0xFF2F73E0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _approvedBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, color: _approvedBlue, size: 12),
          SizedBox(width: 4),
          Text(
            'Approved',
            style: TextStyle(
              color: _approvedBlue,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicsErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ClinicsErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 56,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProvidersErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ProvidersErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search_outlined,
              size: 56,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProvidersEmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ProvidersEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.medical_information_outlined,
              size: 56,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No approved providers are available yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Approved providers will appear here once their verification is complete.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClinicsEmptyState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ClinicsEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 56,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No mental health clinics found within 25\u202Fkm of you.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Clinic data comes from OpenStreetMap, which can be sparse '
              'in some areas. Clinics you see on Google Maps may not be '
              'mapped on OSM yet.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
