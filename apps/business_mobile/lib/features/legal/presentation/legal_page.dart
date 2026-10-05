import '../../../core/widgets/business_bottom_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/legal_provider.dart';

class LegalPage extends ConsumerWidget {
  const LegalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final legalAsync = ref.watch(businessLegalStatusProvider);

    return Scaffold(
      bottomNavigationBar: const BusinessBottomNavigation(),
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Legal & Registration',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(businessLegalStatusProvider);
            await ref.read(businessLegalStatusProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: legalAsync.when(
                  loading: () => const _LegalLoading(),
                  error: (error, stack) => _LegalError(
                    message: error.toString(),
                    onRetry: () {
                      ref.invalidate(businessLegalStatusProvider);
                    },
                  ),
                  data: (data) {
                    if (data == null) {
                      return _LegalEmpty(
                        onRegister: () {
                          context.go('/legal/registration');
                        },
                      );
                    }

                    return _LegalContent(
                      data: data,
                      onRegister: () {
                        context.go('/legal/registration');
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LegalContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRegister;

  const _LegalContent({required this.data, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    final businessStatus = data['business_status']?.toString() ?? 'UNKNOWN';

    final canOperate = data['can_operate'] == true;

    final requiredRegistration = data['legalization_required'] == true;

    final legalization = data['legalization'];

    final legalMap = legalization is Map
        ? Map<String, dynamic>.from(legalization)
        : <String, dynamic>{};

    final nib = _registration(legalMap['nib']);

    final ahu = _registration(legalMap['ahu']);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeroCard(
          businessStatus: businessStatus,
          canOperate: canOperate,
          requiredRegistration: requiredRegistration,
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: _RegistrationCard(
                title: 'NIB',
                icon: Icons.badge_outlined,
                registration: nib,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _RegistrationCard(
                title: 'AHU',
                icon: Icons.account_balance_outlined,
                registration: ahu,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        _WorkflowCard(
          requiredRegistration: requiredRegistration,
          onRegister: onRegister,
        ),

        const SizedBox(height: 20),

        const _DisclaimerCard(),
      ],
    );
  }

  Map<String, dynamic> _registration(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }
}

class _HeroCard extends StatelessWidget {
  final String businessStatus;
  final bool canOperate;
  final bool requiredRegistration;

  const _HeroCard({
    required this.businessStatus,
    required this.canOperate,
    required this.requiredRegistration,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = businessStatus.toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Colors.white,
            size: 30,
          ),
          const SizedBox(height: 16),
          const Text(
            'LEGAL & REGISTRATION',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            statusText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            canOperate
                ? 'Business operational status is active.'
                : 'Business operational status requires attention.',
            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatusChip(
                label: canOperate ? 'OPERATING' : 'ATTENTION',
                icon: canOperate
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
              ),
              _StatusChip(
                label: requiredRegistration
                    ? 'REGISTRATION REQUIRED'
                    : 'REGISTRATION STATUS AVAILABLE',
                icon: Icons.assignment_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _StatusChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Map<String, dynamic> registration;

  const _RegistrationCard({
    required this.title,
    required this.icon,
    required this.registration,
  });

  @override
  Widget build(BuildContext context) {
    final status = registration['status']?.toString() ?? 'NOT_REGISTERED';

    final number = registration['number']?.toString();

    final source = registration['source']?.toString();

    final action = registration['action']?.toString();

    final registered = number != null && number.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF1769FF)),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _statusLabel(status),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            registered ? number : 'Registration number not available',
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          if (source != null && source.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Source: $source',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
            ),
          ],
          if (action != null && action.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Action: ${_statusLabel(action)}',
              style: const TextStyle(
                color: Color(0xFF1769FF),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .toLowerCase()
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

class _WorkflowCard extends StatelessWidget {
  final bool requiredRegistration;
  final VoidCallback onRegister;

  const _WorkflowCard({
    required this.requiredRegistration,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.account_tree_outlined,
              color: Color(0xFF1769FF),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registration Workflow',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 5),
                Text(
                  requiredRegistration
                      ? 'Business registration data masih membutuhkan proses.'
                      : 'Review dan kelola status registrasi bisnis.',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: onRegister, child: const Text('Open')),
        ],
      ),
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Color(0xFF92400E)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Business OS menampilkan status operasional dan '
              'status registrasi secara terpisah. Data di halaman '
              'ini bukan pengganti verifikasi resmi dari instansi '
              'yang berwenang.',
              style: TextStyle(
                color: Color(0xFF78350F),
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalEmpty extends StatelessWidget {
  final VoidCallback onRegister;

  const _LegalEmpty({required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return _EmptyCard(
      icon: Icons.gavel_outlined,
      title: 'Legal data not available',
      message: 'Belum ada data legalitas yang tersedia untuk business ini.',
      buttonText: 'Start Registration',
      onPressed: onRegister,
    );
  }
}

class _LegalLoading extends StatelessWidget {
  const _LegalLoading();

  @override
  Widget build(BuildContext context) {
    return const _EmptyCard(
      icon: Icons.hourglass_top,
      title: 'Loading legal status',
      message: 'Mengambil status legalitas bisnis...',
    );
  }
}

class _LegalError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LegalError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _EmptyCard(
      icon: Icons.error_outline,
      title: 'Unable to load legal status',
      message: message,
      buttonText: 'Retry',
      onPressed: onRetry,
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 38, color: const Color(0xFF1769FF)),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (buttonText != null && onPressed != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(onPressed: onPressed, child: Text(buttonText!)),
          ],
        ],
      ),
    );
  }
}
