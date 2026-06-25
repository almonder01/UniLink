import 'package:flutter/material.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  String? _attachedFileName;
  bool _sending = false;

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _sending = false);
    _subjectCtrl.clear();
    _bodyCtrl.clear();
    setState(() => _attachedFileName = null);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Flexible(
                child: Text(
                    'Message sent! We\'ll get back to you within 24 hours.')),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Frequently Asked Questions',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            const Card(
              child: Column(
                children: [
                  _FaqTile(
                    question: 'How do I follow a club?',
                    answer:
                        'Go to the Clubs tab, browse or search for a club, then tap the "Follow" button on the club card or inside the club detail page.',
                  ),
                  _FaqTile(
                    question: 'How do I register for an event?',
                    answer:
                        'Find the event in your home feed or the club\'s events tab, then tap the "Register" button. You\'ll receive a confirmation notification.',
                  ),
                  _FaqTile(
                    question: 'Can I unfollow a club?',
                    answer:
                        'Yes! Tap the "Following" button on any club card or inside the club detail page. It will toggle back to "Follow".',
                  ),
                  _FaqTile(
                    question: 'How do I become a club manager?',
                    answer:
                        'Contact your university admin or club advisor. They can assign you as a manager through the UniLink admin dashboard.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Divider(color: cs.onSurface.withValues(alpha: 0.1)),
            const SizedBox(height: 20),
            Text(
              "Can't find what you're looking for?",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Send us a message and we\'ll respond within 24 hours.',
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface.withValues(alpha: 0.55)),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _subjectCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          prefixIcon: Icon(Icons.subject_rounded),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Please enter a subject'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bodyCtrl,
                        maxLines: 7,
                        minLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Describe your issue',
                          alignLabelWithHint: true,
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(bottom: 80),
                            child: Icon(Icons.message_rounded),
                          ),
                        ),
                        validator: (v) => (v == null || v.trim().length < 10)
                            ? 'Please describe your issue (min 10 characters)'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      // Attachment
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(
                              () => _attachedFileName = 'screenshot_01.png');
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content:
                                Text('File picker not available in demo mode'),
                          ));
                        },
                        icon: const Icon(Icons.attach_file_rounded, size: 18),
                        label: Text(_attachedFileName != null
                            ? _attachedFileName!
                            : 'Attach a file (optional)'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _attachedFileName != null
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.6),
                          side: BorderSide(
                            color: _attachedFileName != null
                                ? cs.primary
                                : cs.onSurface.withValues(alpha: 0.25),
                          ),
                          textStyle: const TextStyle(fontSize: 13),
                        ),
                      ),
                      if (_attachedFileName != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.check_circle_rounded,
                                size: 14, color: Color(0xFF22C55E)),
                            const SizedBox(width: 6),
                            Text(
                              _attachedFileName!,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.6)),
                            ),
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _attachedFileName = null),
                              child: Icon(Icons.close_rounded,
                                  size: 14,
                                  color: cs.onSurface.withValues(alpha: 0.4)),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(_sending ? 'Sending...' : 'Send Message'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      title: Text(
        question,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      expandedAlignment: Alignment.topLeft,
      children: [
        Text(
          answer,
          style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: cs.onSurface.withValues(alpha: 0.65)),
        ),
      ],
    );
  }
}
