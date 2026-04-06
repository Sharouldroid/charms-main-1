// auth_card.dart
import 'dart:io';

import 'package:charms/models/http_exception.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:charms/models/user.dart';
import 'package:charms/providers/auth.dart';
import 'package:charms/services/secure_storage_service.dart';
import 'package:charms/services/login_rate_limiter.dart';
import 'package:charms/services/connectivity_service.dart';
import 'package:charms/screens/terms_of_service_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_constants.dart';
import 'package:flutter/services.dart';
import 'auth_utils.dart';

enum AuthMode { Signup, Login }

class AuthCard extends StatefulWidget {
  const AuthCard({super.key});

  @override
  AuthCardState createState() => AuthCardState();
}

class AuthCardState extends State<AuthCard> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;
  final Map<String, String> _authData = {'username': '', 'passkey': ''};
  bool _rememberMe = false;
  bool _useBiometrics = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedTerms = false; // Terms acceptance for registration
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedCountry = 'Malaysia';

  final _newUser = User(
    id: '',
    firstname: '',
    lastname: '',
    phone: '',
    dob: '',
    address1: '',
    address2: '',
    city: '',
    postcode: 0,
    state: '',
    country: '',
    occupation: '',
    username: '',
    email: '',
    password: '',
    usertype: 2,
    gender: 0,
    idnum: '',
  );

  final FocusNode _usernameFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _idNumFocus = FocusNode();
  final FocusNode _occupationFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _address1Focus = FocusNode();
  final FocusNode _address2Focus = FocusNode();
  final FocusNode _cityFocus = FocusNode();
  final FocusNode _postcodeFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _idNumFocus.dispose();
    _occupationFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _address1Focus.dispose();
    _address2Focus.dispose();
    _cityFocus.dispose();
    _postcodeFocus.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- HELPER FOR RESPONSIVE TEXT LABELS ---
  // This automatically shrinks text to fit the box
  Widget _responsiveLabel(String text) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(text, style: textStyle),
    );
  }

  Future<void> _loadSavedPreferences() async {
    // Load remember me and biometrics preferences from secure storage
    final rememberMe = await SecureStorageService.getRememberMe();
    final useBiometrics = await SecureStorageService.getBiometricsPreference();

    if (rememberMe) {
      final credentials = await SecureStorageService.getCredentials();
      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
          _useBiometrics = useBiometrics;
          _authData['username'] = credentials['username'] ?? '';
          _authData['passkey'] = credentials['passkey'] ?? '';
          _usernameController.text = _authData['username']!;
          _passwordController.text = _authData['passkey']!;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _rememberMe = rememberMe;
          _useBiometrics = useBiometrics;
        });
      }
    }

    // Check for lockout before allowing biometric login
    if (_rememberMe && _useBiometrics && mounted) {
      if (await LoginRateLimiter.isLockedOut()) {
        final remainingMinutes = await LoginRateLimiter.getRemainingLockoutMinutes();
        if (mounted) {
          LoginRateLimiter.showLockoutDialog(context, remainingMinutes);
        }
        return;
      }

      final didAuthenticate = await AuthUtils.authenticateWithBiometrics();
      if (didAuthenticate) {
        final success = await _tryAutoLogin();
        if (success && mounted) {
          await LoginRateLimiter.resetAttempts();
          Navigator.of(context).pushReplacementNamed('/dashboard');
        }
      }
    }
  }

  Future<bool> _tryAutoLogin() async {
    final credentials = await SecureStorageService.getCredentials();
    final username = credentials['username'];
    final passkey = credentials['passkey'];

    if (username == null || passkey == null || username.isEmpty || passkey.isEmpty) {
      return false;
    }

    try {
      await Provider.of<Auth>(
        context,
        listen: false,
      ).authenticate(username, passkey);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _savePreferences() async {
    // Save remember me and biometrics preferences
    await SecureStorageService.saveRememberMe(_rememberMe);
    await SecureStorageService.saveBiometricsPreference(_useBiometrics);

    if (_rememberMe) {
      // Save credentials securely
      await SecureStorageService.saveCredentials(
        username: _authData['username']!,
        password: _authData['passkey']!,
      );
    } else {
      // Clear credentials if remember me is disabled
      await SecureStorageService.clearCredentials();
      await SecureStorageService.saveBiometricsPreference(false);
    }
  }

  void _switchAuthMode() {
    setState(() {
      _authMode =
          _authMode == AuthMode.Login ? AuthMode.Signup : AuthMode.Login;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      // Check network connectivity (non-blocking - just a warning)
      try {
        final isConnected = await ConnectivityService().checkConnectivity();
        if (!isConnected && mounted) {
          ConnectivityService.showNoConnectionDialog(context);
          setState(() => _isLoading = false);
          return;
        }
      } catch (e) {
        // Connectivity check failed, continue anyway
        debugPrint('Connectivity check failed: $e');
      }

      // Check for lockout before login attempt
      if (_authMode == AuthMode.Login) {
        try {
          if (await LoginRateLimiter.isLockedOut()) {
            final remainingMinutes = await LoginRateLimiter.getRemainingLockoutMinutes();
            if (mounted) {
              LoginRateLimiter.showLockoutDialog(context, remainingMinutes);
            }
            setState(() => _isLoading = false);
            return;
          }

          // Apply progressive delay if there have been failed attempts
          final delay = await LoginRateLimiter.getProgressiveDelay();
          if (delay > 0) {
            await Future.delayed(Duration(seconds: delay));
          }
        } catch (e) {
          // Rate limiter check failed, continue anyway
          debugPrint('Rate limiter check failed: $e');
        }
      }

      if (_authMode == AuthMode.Login) {
        await _handleLogin();
      } else {
        await _handleRegistration();
      }
    } catch (error) {
      _handleError(error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    try {
      await Provider.of<Auth>(
        context,
        listen: false,
      ).authenticate(_authData['username']!, _authData['passkey']!);

      // Reset rate limiter on successful login
      try {
        await LoginRateLimiter.resetAttempts();
      } catch (e) {
        debugPrint('Failed to reset rate limiter: $e');
      }
      await _savePreferences();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } on HttpException catch (e) {
      // Record failed attempt for rate limiting
      try {
        final result = await LoginRateLimiter.recordFailedAttempt();

        if (result.isLockedOut && mounted) {
          LoginRateLimiter.showLockoutDialog(context, result.remainingMinutes);
          return;
        } else if (result.attemptsRemaining > 0 && result.attemptsRemaining < 3 && mounted) {
          LoginRateLimiter.showAttemptsWarning(context, result.attemptsRemaining);
        }
      } catch (limiterError) {
        debugPrint('Rate limiter error: $limiterError');
      }

      // --- START ADDED HANDLING FOR PENDING/REJECTED ---
      final errorString = e.toString();
      if (errorString.contains('account_pending')) {
        AuthUtils.showPendingApprovalDialog(context);
        return;
      } else if (errorString.contains('account_rejected')) {
        AuthUtils.showErrorDialog(context, message: 'Your account has been rejected. Please contact support.');
        return;
      }
      // --- END ADDED HANDLING ---

      String message = 'Authentication failed';
      if (e.toString().contains('invalid_credentials')) {
        message = 'Invalid username or password';
      } else if (e.toString().contains('user_not_found')) {
        message = 'User not found. Please check your credentials or register.';
      }
      throw HttpException(message);
    } catch (e) {
      // Record failed attempt for rate limiting
      try {
        await LoginRateLimiter.recordFailedAttempt();
      } catch (limiterError) {
        debugPrint('Rate limiter error: $limiterError');
      }
      throw Exception('Login failed. Please try again.');
    }
  }

  Future<void> _handleRegistration() async {
    final response = await Provider.of<Auth>(
      context,
      listen: false,
    ).register(_newUser);

    if (response == null) {
      throw Exception('Registration failed. No response from server.');
    }

    if (response['status'] == 201 || response['status'] == 200) {
      bool needsApproval =
          _newUser.usertype == 10 || _newUser.usertype == 11;

      if (needsApproval) {
        // Show "waiting for approval" dialog
        AuthUtils.showPendingApprovalDialog(
          context,
          onDismiss: () {
            _switchAuthMode(); // go back to login
          },
        );
      } else {
        // Normal success
        AuthUtils.showErrorDialog(
          context,
          message:
              'Registration successful! You can now login with your credentials.',
          isSuccess: true,
          onDismiss: _switchAuthMode,
        );
      }
    } else {
      String errorMessage =
          response['message'] ?? 'Registration failed';

      if (errorMessage.contains('username_taken')) {
        errorMessage =
            'Username already exists. Please choose another.';
      } else if (errorMessage.contains('email_taken')) {
        errorMessage =
            'Email already registered. Please use another email.';
      }

      throw HttpException(errorMessage);
    }
  }

  void _handleError(dynamic error) {
    if (error is HttpException) {
      AuthUtils.showErrorDialog(context, message: error.toString());
    } else if (error is SocketException) {
      AuthUtils.showErrorDialog(
        context,
        message: 'Network error. Please check your internet connection.',
      );
    } else {
      AuthUtils.showErrorDialog(context, message: error.toString());
    }

    debugPrint('Authentication error: ${error.toString()}');
  }

  Future<DateTime?> _pickDate() => showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(1900),
    lastDate: DateTime.now(),
  );

  Widget _buildLoginForm() {
    return Column(
      children: [
        TextFormField(
          decoration: InputDecoration(
            // Changed labelText to label + _responsiveLabel
            label: _responsiveLabel('Username'),
            prefixIcon: const Icon(Icons.person),
          ),
          controller: _usernameController,
          textInputAction: TextInputAction.next,
          focusNode: _usernameFocus,
          onFieldSubmitted:
              (_) => FocusScope.of(context).requestFocus(_passwordFocus),
          autocorrect: false,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your username';
            }
            return null;
          },
          onSaved: (value) {
            _authMode == AuthMode.Login
                ? _authData['username'] = value!
                : _newUser.username = value!;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            // Changed labelText to label + _responsiveLabel
            label: _responsiveLabel('Password'),
            prefixIcon: const Icon(Icons.lock),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed:
                  () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          focusNode: _passwordFocus,
          controller: _passwordController,
          validator: (value) {
            if (value!.isEmpty || value.length < 4) {
              return 'Password is too short';
            }
            return null;
          },
          onSaved: (value) {
            _authMode == AuthMode.Login
                ? _authData['passkey'] = value!
                : _newUser.password = value!;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
        if (_authMode == AuthMode.Login) ...[
          const SizedBox(height: 16),
          CheckboxListTile(
            title: _responsiveLabel('Remember Me'),
            value: _rememberMe,
            onChanged: (newValue) {
              setState(() => _rememberMe = newValue!);
              if (!newValue!) {
                setState(() => _useBiometrics = false);
                _savePreferences();
              }
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),
          if (_rememberMe)
            CheckboxListTile(
              title: _responsiveLabel('Use Biometric Authentication'),
              value: _useBiometrics,
              onChanged: (newValue) {
                setState(() => _useBiometrics = newValue!);
                _savePreferences();
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
        ],
      ],
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      children: [
        _buildLoginForm(), // Reuse username/password fields
        TextFormField(
          decoration: InputDecoration(
            // Changed labelText to label + _responsiveLabel
            label: _responsiveLabel('Confirm Password'),
            prefixIcon: const Icon(Icons.lock_outline),
          ),
          obscureText: true,
          textInputAction: TextInputAction.next,
          focusNode: _confirmPasswordFocus,
          onFieldSubmitted:
              (_) => FocusScope.of(context).requestFocus(_firstNameFocus),
          validator: (value) {
            if (value != _passwordController.text) {
              return 'Password does not match';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  // Changed labelText to label + _responsiveLabel
                  label: _responsiveLabel('First Name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                focusNode: _firstNameFocus,
                onFieldSubmitted:
                    (_) => FocusScope.of(context).requestFocus(_lastNameFocus),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your first name';
                  }
                  return null;
                },
                onSaved: (value) => _newUser.firstname = value!,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  // Changed labelText to label + _responsiveLabel
                  label: _responsiveLabel('Last Name'),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
                textInputAction: TextInputAction.next,
                focusNode: _lastNameFocus,
                onFieldSubmitted:
                    (_) => FocusScope.of(context).requestFocus(_idNumFocus),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Please enter your last name';
                  }
                  return null;
                },
                onSaved: (value) => _newUser.lastname = value!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            // Changed labelText to label + _responsiveLabel
            label: _responsiveLabel('I/C @ Passport'),
            prefixIcon: const Icon(Icons.credit_card),
          ),
          textInputAction: TextInputAction.next,
          focusNode: _idNumFocus,
          onFieldSubmitted: (_) => _selectDate(context),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Please enter your I/C @ passport number';
            }
            return null;
          },
          onSaved: (value) => _newUser.idnum = value!,
        ),
        const SizedBox(height: 16),
        
        // --- UPDATED DATE & GENDER ROW ---
        Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: InputDecoration(
                  // Changed labelText to label + _responsiveLabel
                  label: _responsiveLabel('D.O.B'),
                  prefixIcon: const Icon(Icons.calendar_today),
                  floatingLabelBehavior: FloatingLabelBehavior.never,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          _selectedDate != null
                              ? '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'
                              : 'D.O.B',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _selectDate(context),
                      icon: const Icon(Icons.calendar_month),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int>(
                isExpanded: true,
                decoration: InputDecoration(
                  // Changed labelText to label + _responsiveLabel
                  label: _responsiveLabel('Gender'),
                  prefixIcon: const Icon(Icons.person_outline),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                items: AuthConstants.genders.map((gender) {
                  return DropdownMenuItem<int>(
                    value: gender['value'],
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        gender['label'],
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) => _newUser.gender = value!,
                validator:
                    (value) =>
                        value == null ? 'Please choose your gender' : null,
              ),
            ),
          ],
        ),
        // --- END UPDATED ROW ---
        
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  // Changed labelText to label + _responsiveLabel
                  label: _responsiveLabel('Occupation'),
                  prefixIcon: const Icon(Icons.work_outline),
                ),
                textInputAction: TextInputAction.next,
                focusNode: _occupationFocus,
                onFieldSubmitted:
                    (_) => FocusScope.of(context).requestFocus(_phoneFocus),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your occupation';
                  }
                  return null;
                },
                onSaved: (value) => _newUser.occupation = value!,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  // Changed labelText to label + _responsiveLabel
                  label: _responsiveLabel('Phone'),
                  prefixIcon: const Icon(Icons.phone),
                ),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.phone,
                focusNode: _phoneFocus,
                
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_emailFocus),
                
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  
                  if (value.length < 9) {
                    return 'Phone number is too short';
                  }

                  return null;
                },
                onSaved: (value) => _newUser.phone = value!,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            // Changed labelText to label + _responsiveLabel
            label: _responsiveLabel('Email'),
            prefixIcon: const Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          focusNode: _emailFocus,
          onFieldSubmitted:
              (_) => FocusScope.of(context).requestFocus(_address1Focus),
          
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an email address';
            }

            final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

            if (!emailRegex.hasMatch(value)) {
              return 'Invalid email format. (Example: user@domain.my)';
            }
            
            return null;
          },
          onSaved: (value) => _newUser.email = value!,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          isExpanded: true,
          decoration: InputDecoration(
            // Changed labelText to label + _responsiveLabel
            label: _responsiveLabel('Country'),
            prefixIcon: const Icon(Icons.public),
          ),
          initialValue: _selectedCountry,
          items:
              AuthConstants.countries.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }).toList(),
          onChanged: (value) {
            setState(() => _selectedCountry = value!);
            _newUser.country = value!;
          },
          validator:
              (value) => value == null ? 'Please specify your country' : null,
        ),
        const SizedBox(height: 16),
        _selectedCountry == 'Malaysia'
            ? DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                // Changed labelText to label + _responsiveLabel
                label: _responsiveLabel('State'),
                prefixIcon: const Icon(Icons.map),
              ),
              initialValue: AuthConstants.statesOfMalaysia[0],
              items:
                  AuthConstants.statesOfMalaysia.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (value) => _newUser.state = value!,
              validator:
                  (value) =>
                      value == null ? 'Please specify your state' : null,
            )
            : TextFormField(
              decoration: InputDecoration(
                // Changed labelText to label + _responsiveLabel
                label: _responsiveLabel('State'),
                prefixIcon: const Icon(Icons.map),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please specify your state';
                }
                return null;
              },
              onSaved: (value) => _newUser.state = value!,
            ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            // Changed labelText to label + _responsiveLabel
            label: _responsiveLabel('Address Line 1'),
            prefixIcon: const Icon(Icons.home),
          ),
          textInputAction: TextInputAction.next,
          focusNode: _address1Focus,
          onFieldSubmitted:
              (_) => FocusScope.of(context).requestFocus(_address2Focus),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a valid address';
            }
            return null;
          },
          onSaved: (value) => _newUser.address1 = value!,
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: InputDecoration(
            // Changed labelText to label + _responsiveLabel
            label: _responsiveLabel('Address Line 2'),
            prefixIcon: const Icon(Icons.home_outlined),
          ),
          textInputAction: TextInputAction.next,
          focusNode: _address2Focus,
          onFieldSubmitted:
              (_) => FocusScope.of(context).requestFocus(_cityFocus),
          onSaved: (value) => _newUser.address2 = value ?? '',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  // Changed labelText to label + _responsiveLabel
                  label: _responsiveLabel('City'),
                  prefixIcon: const Icon(Icons.location_city),
                ),
                textInputAction: TextInputAction.next,
                focusNode: _cityFocus,
                
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                ],

                onFieldSubmitted:
                    (_) => FocusScope.of(context).requestFocus(_postcodeFocus),
                
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your city';
                  }
                  
                  if (value.contains(RegExp(r'[0-9]'))) {
                    return 'City name cannot contain numbers';
                  }
                  
                  return null;
                },
                onSaved: (value) => _newUser.city = value!,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                decoration: InputDecoration(
                  // Changed labelText to label + _responsiveLabel
                  label: _responsiveLabel(
                    _selectedCountry == 'Malaysia' ? 'Postcode' : 'Zip Code',
                  ),
                  prefixIcon: const Icon(Icons.markunread_mailbox),
                ),
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.number,
                focusNode: _postcodeFocus,
                
                onFieldSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_address1Focus),
                
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(
                    _selectedCountry == 'Malaysia' ? 5 : 10,
                  ),
                ],

                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter zip code';
                  }

                  if (_selectedCountry == 'Malaysia') {
                    if (value.length != 5) {
                      return 'Format must be 5 digits (e.g. 50450)';
                    }
                  } else {
                    if (value.length < 4) {
                      return 'Zip code too short';
                    }
                  }
                  return null;
                },
                
                onSaved: (value) => _newUser.postcode = int.parse(value!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          isExpanded: true,
          decoration: InputDecoration(
            label: _responsiveLabel('Role'),
            prefixIcon: const Icon(Icons.people_outline),
          ),
          items: [
            ...AuthConstants.userRoles.map((role) {
              return DropdownMenuItem<int>(
                value: role['value'],
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    role['label'],
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
            }).toList(),
            // Add manager and marine biologist roles
            const DropdownMenuItem<int>(
              value: 5,
              child: Text("Manager"),
            ),
            const DropdownMenuItem<int>(
              value: 9,
              child: Text("Marine Biologist"),
            ),
          ],
          onChanged: (value) => _newUser.usertype = value!,
          validator: (value) => value == null ? 'Please choose your role' : null,
        ),
        
        // Terms and Privacy Policy Acceptance (Required for App Store)
        const SizedBox(height: 16),
        FormField<bool>(
          initialValue: _acceptedTerms,
          validator: (value) {
            if (value != true) {
              return 'You must accept the Terms of Service and Privacy Policy';
            }
            return null;
          },
          builder: (FormFieldState<bool> state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() => _acceptedTerms = value ?? false);
                    state.didChange(value);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  title: Wrap(
                    children: [
                      const Text('I agree to the ', style: TextStyle(fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => const TermsOfServiceScreen(),
                          ),
                        ),
                        child: const Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const Text(' and ', style: TextStyle(fontSize: 13)),
                      GestureDetector(
                        onTap: () => _openUrl('http://conservems.my/PrivacyPolicyCHARMs/PrivacyPolicy.html'),
                        child: Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.grey[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.hasError)
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
  
  Future<void> _openUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final pickedDate = await _pickDate();
    if (pickedDate == null) return;

    final currentYear = DateTime.now().year;
    final cutoffYear = currentYear - 16;

    if (pickedDate.year > cutoffYear) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 48,
          ),
          title: const Text(
            'Age Restriction',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'You must be 16 years old and above to register for an account.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text(
                'Confirm',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      
      return;
    }

    setState(() => _selectedDate = pickedDate);
    _newUser.dob = pickedDate.toIso8601String();
    FocusScope.of(context).requestFocus(_occupationFocus);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _authMode == AuthMode.Login
                    ? _buildLoginForm()
                    : _buildRegistrationForm(),
                const SizedBox(height: 24),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _submit,
                          child: Text(
                            _authMode == AuthMode.Login ? 'Login' : 'Register',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _switchAuthMode,
                        child: Text(
                          _authMode == AuthMode.Login
                              ? 'Create an account'
                              : 'I already have an account',
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
}