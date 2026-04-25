import 'package:flutter/material.dart';
import 'package:brain_anchor/screens/patient/patient_main_screen.dart';

class PatientLoginMpinScreen extends StatefulWidget {
  final String phoneNumber;

  const PatientLoginMpinScreen({super.key, required this.phoneNumber});

  @override
  State<PatientLoginMpinScreen> createState() => _PatientLoginMpinScreenState();
}

class _PatientLoginMpinScreenState extends State<PatientLoginMpinScreen> {
  String _mpin = '';

  void _onKeypadTap(String value) {
    if (_mpin.length < 4) {
      setState(() {
        _mpin += value;
      });
    }
  }

  void _onDeleteTap() {
    if (_mpin.isNotEmpty) {
      setState(() {
        _mpin = _mpin.substring(0, _mpin.length - 1);
      });
    }
  }

  void _login() {
    if (_mpin.length == 4) {
      // Static logic: bypass real authentication and log in
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const PatientMainScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String maskedPhone = widget.phoneNumber.length >= 4 
        ? widget.phoneNumber.substring(widget.phoneNumber.length - 4) 
        : 'XXXX';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter MPIN',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please enter the MPIN for your account ending in $maskedPhone.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const Spacer(),
              
              // PIN Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _mpin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? theme.colorScheme.primary : theme.colorScheme.surface,
                      border: Border.all(
                        color: isFilled ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              
              const Spacer(),
              
              // Numeric Keypad
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (index == 9) return const SizedBox.shrink(); // Empty slot
                  if (index == 11) {
                    return InkWell(
                      onTap: _onDeleteTap,
                      customBorder: const CircleBorder(),
                      child: Icon(Icons.backspace_outlined, color: theme.colorScheme.onSurface),
                    );
                  }
                  
                  final number = index == 10 ? '0' : '${index + 1}';
                  return InkWell(
                    onTap: () => _onKeypadTap(number),
                    customBorder: const CircleBorder(),
                    child: Center(
                      child: Text(
                        number,
                        style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _mpin.length == 4 ? _login : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: const Text('Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
