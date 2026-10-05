import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LegalRegistrationPage extends StatefulWidget {
  const LegalRegistrationPage({super.key});

  @override
  State<LegalRegistrationPage> createState() => _LegalRegistrationPageState();
}

class _LegalRegistrationPageState extends State<LegalRegistrationPage> {
  int step = 0;

  final steps = const [
    (
      'Entity Type',
      'Pilih bentuk badan usaha yang akan digunakan.',
      Icons.account_balance_outlined,
    ),
    (
      'Business Data',
      'Review identitas dan aktivitas utama bisnis.',
      Icons.business_outlined,
    ),
    (
      'Documents',
      'Siapkan dokumen pendukung registrasi.',
      Icons.description_outlined,
    ),
    (
      'Review',
      'Periksa seluruh data sebelum mengajukan request.',
      Icons.fact_check_outlined,
    ),
    (
      'Submit',
      'Kirim registration request untuk diproses.',
      Icons.send_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final current = steps[step];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Legal Registration',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(step: step),
                  const SizedBox(height: 24),
                  _StepCard(
                    title: current.$1,
                    description: current.$2,
                    icon: current.$3,
                  ),
                  const SizedBox(height: 20),
                  _WorkflowSteps(currentStep: step, steps: steps),
                  const SizedBox(height: 24),
                  _Navigation(
                    first: step == 0,
                    last: step == steps.length - 1,
                    onBack: () {
                      if (step > 0) {
                        setState(() => step--);
                      }
                    },
                    onNext: () {
                      if (step < steps.length - 1) {
                        setState(() => step++);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Registration workflow siap untuk integrasi API.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int step;

  const _Header({required this.step});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111827), Color(0xFF1D4ED8)],
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BUSINESS REGISTRATION',
                  style: TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Step ${step + 1} of 5',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
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

class _StepCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFF1769FF)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 13,
                    height: 1.4,
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

class _WorkflowSteps extends StatelessWidget {
  final int currentStep;
  final List<(String, String, IconData)> steps;

  const _WorkflowSteps({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(steps.length, (index) {
        final item = steps[index];
        final active = index == currentStep;
        final completed = index < currentStep;

        return Container(
          margin: EdgeInsets.only(bottom: index == steps.length - 1 ? 0 : 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: active ? const Color(0xFF93C5FD) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: completed || active
                    ? const Color(0xFF1769FF)
                    : const Color(0xFFE2E8F0),
                child: Icon(
                  completed ? Icons.check : item.$3,
                  size: 17,
                  color: completed || active
                      ? Colors.white
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.$1,
                  style: TextStyle(
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _Navigation extends StatelessWidget {
  final bool first;
  final bool last;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _Navigation({
    required this.first,
    required this.last,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        OutlinedButton.icon(
          onPressed: first ? () => context.go('/legal') : onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back'),
        ),
        ElevatedButton.icon(
          onPressed: onNext,
          icon: Icon(last ? Icons.send : Icons.arrow_forward),
          label: Text(last ? 'Submit Request' : 'Continue'),
        ),
      ],
    );
  }
}
