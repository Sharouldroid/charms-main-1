
import 'package:charms/HRmodels/user.dart';
import 'package:charms/HRproviders/auth.dart';
import 'package:charms/HRscreens/admin/admin_dashboard_screen.dart';
import 'package:charms/HRscreens/main_dashboard.dart';
import 'package:charms/HRscreens/staff/staff_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum AuthMode { Signup, Login }

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});
  static const double pi = 3.142;
  
  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final transformConfig = Matrix4.rotationZ(-8 * pi / 180);
    transformConfig.translate(-10.0);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Container(
            decoration:  BoxDecoration(
                 gradient: LinearGradient(
                   colors: [
                     const Color.fromRGBO(215, 117, 255, 1).withOpacity(0.5),
                     const Color.fromRGBO(255, 188, 117, 1).withOpacity(0.9),
                   ],
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                   stops: [0, 1],
                 ),
                image: DecorationImage(
                    image: AssetImage('assets/logos/seatrulogo2.png'))),
          ),
          SingleChildScrollView(
            child: SizedBox(
              height: deviceSize.height,
              width: deviceSize.width,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20.0),
                      padding: const EdgeInsets.symmetric(
                          vertical: 8.0, horizontal: 94.0),
                      // transform: Matrix4.rotationZ(-8 * pi / 180)
                      // ..translate(-10.0),
                      // ..translate(-10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white70,
                        boxShadow: const [
                          BoxShadow(
                            blurRadius: 8,
                            color: Colors.black26,
                            offset: Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        'CHARMS',
                        style: TextStyle(
                          color: Colors.black,//Theme.of(context).colorScheme.primaryContainer,
                          fontSize: 30,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: deviceSize.width > 600 ? 2 : 1,
                    child: const AuthCard(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthCard extends StatefulWidget {
  const AuthCard({super.key});

  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;
  final Map<String, String> _authData = {
    'username': '',
    'passkey': '',
  };
  var _isLoading = false;
  final _passwordController = TextEditingController();
  DateTime? _selectedDate;

  var _newuser = User(
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
  );

  void _showErrorDialog(String message, int type) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            Text(type == 1 ? 'Warning' : 'Message'), // 1 = error, 2 = success
        content: Text(message),
        actions: <Widget>[
          ElevatedButton(
            child: const Text('Okay'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

Future<void> _submit() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }
  _formKey.currentState!.save();
  setState(() {
    _isLoading = true;
  });

  try {
    if (_authMode == AuthMode.Login) {
      // Authenticate and get the userType
      final userType = await Provider.of<Auth>(context, listen: false).authenticate(
        _authData['username']!,
        _authData['passkey']!,
      );

      // Get username from Auth provider
      final username = Provider.of<Auth>(context, listen: false).username;

      // Redirect based on userType
      Widget destination;
      
      // 1 = Super Admin, 6 = Staff/HR Admin
      if (userType == 1 || userType == 6) {
        destination = AdminDashboard(username: username);
      } 
      // 2, 3, 4, 5 = Volunteers, Researchers, Boat Owners, etc.
      else if ([2, 3, 4, 5].contains(userType)) {
        destination = MainDashboard();
      } 
      // 7, 8, 9, 10 = Standard Staff, Managers, Officers, Trainees
      else if ([7, 8, 9, 10].contains(userType)) {
        destination = StaffDashboardScreen(username: username);
      } 
      else {
        throw Exception("Unknown user type: $userType");
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      }
    } else {
      // Handle registration logic
      await Provider.of<Auth>(context, listen: false).register(_newuser);
      _showErrorDialog('You will be redirected to the login page', 2);
    }
  } catch (error) {
    _showErrorDialog(error.toString(), 1);
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}




  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _authMode = AuthMode.Signup;
      });
    } else {
      setState(() {
        _authMode = AuthMode.Login;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Color.fromRGBO(215, 117, 255, 1).withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      elevation: 8.0,
      child: Container(
        height: _authMode == AuthMode.Signup ? 700 : 300,
        constraints:
            BoxConstraints(minHeight: _authMode == AuthMode.Signup ? 500 : 150),
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Username'),
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    if (_authMode == AuthMode.Login) {
                      _authData['username'] = value!;
                    } else {
                      _newuser = User(
                        id: _newuser.id,
                        username: value!,
                        password: _newuser.password,
                        firstname: _newuser.firstname,
                        lastname: _newuser.lastname,
                        phone: _newuser.phone,
                        dob: _newuser.dob,
                        email: _newuser.email,
                        address1: _newuser.address1,
                        address2: _newuser.address2,
                        city: _newuser.city,
                        postcode: _newuser.postcode,
                        state: _newuser.state,
                        country: _newuser.country,
                        usertype: _newuser.usertype,
                        occupation: _newuser.occupation,
                        gender: _newuser.gender,
                      );
                    }
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  textInputAction: _authMode == AuthMode.Login
                      ? TextInputAction.done
                      : TextInputAction.next,
                  controller: _passwordController,
                  validator: (value) {
                    if (value!.isEmpty || value.length < 4) {
                      return 'Password is too short';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    if (_authMode == AuthMode.Login) {
                      _authData['passkey'] = value!;
                    } else {
                      _newuser = User(
                        id: _newuser.id,
                        username: _newuser.username,
                        password: value!,
                        firstname: _newuser.firstname,
                        lastname: _newuser.lastname,
                        phone: _newuser.phone,
                        dob: _newuser.dob,
                        email: _newuser.email,
                        address1: _newuser.address1,
                        address2: _newuser.address2,
                        city: _newuser.city,
                        postcode: _newuser.postcode,
                        state: _newuser.state,
                        country: _newuser.country,
                        usertype: _newuser.usertype,
                        occupation: _newuser.occupation,
                        gender: _newuser.gender,
                      );
                    }
                  },
                ),
                if (_authMode == AuthMode.Signup)
                  Column(
                    children: [
                      TextFormField(
                        enabled: _authMode == AuthMode.Signup,
                        decoration: const InputDecoration(
                            labelText: 'Confirm Password'),
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        validator: _authMode == AuthMode.Signup
                            ? (value) {
                                if (value != _passwordController.text) {
                                  return 'Password does not match';
                                }
                                return null;
                              }
                            : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: _authMode == AuthMode.Signup,
                              decoration: const InputDecoration(
                                  labelText: 'First Name'),
                              textInputAction: TextInputAction.next,
                              validator: _authMode == AuthMode.Signup
                                  ? (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your first name';
                                      }
                                      return null;
                                    }
                                  : null,
                              onSaved: (value) {
                                _newuser = User(
                                  id: _newuser.id,
                                  username: _newuser.username,
                                  password: _newuser.password,
                                  firstname: value!,
                                  lastname: _newuser.lastname,
                                  phone: _newuser.phone,
                                  dob: _newuser.dob,
                                  email: _newuser.email,
                                  address1: _newuser.address1,
                                  address2: _newuser.address2,
                                  city: _newuser.city,
                                  postcode: _newuser.postcode,
                                  state: _newuser.state,
                                  country: _newuser.country,
                                  usertype: _newuser.usertype,
                                  occupation: _newuser.occupation,
                                  gender: _newuser.gender,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              enabled: _authMode == AuthMode.Signup,
                              decoration:
                                  const InputDecoration(labelText: 'Last Name'),
                              textInputAction: TextInputAction.next,
                              validator: _authMode == AuthMode.Signup
                                  ? (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your last name';
                                      }
                                      return null;
                                    }
                                  : null,
                              onSaved: (value) {
                                _newuser = User(
                                  id: _newuser.id,
                                  username: _newuser.username,
                                  password: _newuser.password,
                                  firstname: _newuser.firstname,
                                  lastname: value!,
                                  phone: _newuser.phone,
                                  dob: _newuser.dob,
                                  email: _newuser.email,
                                  address1: _newuser.address1,
                                  address2: _newuser.address2,
                                  city: _newuser.city,
                                  postcode: _newuser.postcode,
                                  state: _newuser.state,
                                  country: _newuser.country,
                                  usertype: _newuser.usertype,
                                  occupation: _newuser.occupation,
                                  gender: _newuser.gender,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(_selectedDate != null
                              ? '${_selectedDate!.day}-${_selectedDate!.month}-${_selectedDate!.year}'
                              : 'Date of Birth'),
                          // const Spacer(),
                          IconButton(
                            onPressed: () async {
                              _selectedDate = await pickDate();

                              if (_selectedDate == null) return;

                              setState(() => _selectedDate = _selectedDate!);

                              _newuser = User(
                                id: _newuser.id,
                                username: _newuser.username,
                                password: _newuser.password,
                                firstname: _newuser.firstname,
                                lastname: _newuser.lastname,
                                phone: _newuser.phone,
                                dob: _selectedDate!.toIso8601String(),
                                email: _newuser.email,
                                address1: _newuser.address1,
                                address2: _newuser.address2,
                                city: _newuser.city,
                                postcode: _newuser.postcode,
                                state: _newuser.state,
                                country: _newuser.country,
                                usertype: _newuser.usertype,
                                occupation: _newuser.occupation,
                                gender: _newuser.gender,
                              );
                            },
                            icon: const Icon(Icons.calendar_month),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<dynamic>(
                              initialValue: null,
                              hint: const Text('Gender'),
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('Male')),
                                DropdownMenuItem(
                                    value: 2, child: Text('Female')),
                              ],
                              onChanged: (value) {
                                setState(() {});
                              },
                              validator: (value) => value == null
                                  ? 'Please choose your gender'
                                  : null,
                              onSaved: (value) {
                                _newuser = User(
                                  id: _newuser.id,
                                  username: _newuser.username,
                                  password: _newuser.password,
                                  firstname: _newuser.firstname,
                                  lastname: _newuser.lastname,
                                  phone: _newuser.phone,
                                  dob: _newuser.dob,
                                  email: _newuser.email,
                                  address1: _newuser.address1,
                                  address2: _newuser.address2,
                                  city: _newuser.city,
                                  postcode: _newuser.postcode,
                                  state: _newuser.state,
                                  country: _newuser.country,
                                  usertype: _newuser.usertype,
                                  occupation: _newuser.occupation,
                                  gender: value!,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                  labelText: 'Occupation'),
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              textCapitalization: TextCapitalization.none,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your occupation';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _newuser = User(
                                  id: _newuser.id,
                                  username: _newuser.username,
                                  password: _newuser.password,
                                  firstname: _newuser.firstname,
                                  lastname: _newuser.lastname,
                                  phone: _newuser.phone,
                                  dob: _newuser.dob,
                                  email: _newuser.email,
                                  address1: _newuser.address1,
                                  address2: _newuser.address2,
                                  city: _newuser.city,
                                  postcode: _newuser.postcode,
                                  state: _newuser.state,
                                  country: _newuser.country,
                                  usertype: _newuser.usertype,
                                  occupation: value!,
                                  gender: _newuser.gender,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              enabled: _authMode == AuthMode.Signup,
                              decoration:
                                  const InputDecoration(labelText: 'Phone'),
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.phone,
                              validator: _authMode == AuthMode.Signup
                                  ? (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your phone number';
                                      }
                                      return null;
                                    }
                                  : null,
                              onSaved: (value) {
                                _newuser = User(
                                  id: _newuser.id,
                                  username: _newuser.username,
                                  password: _newuser.password,
                                  firstname: _newuser.firstname,
                                  lastname: _newuser.lastname,
                                  phone: value!,
                                  dob: _newuser.dob,
                                  email: _newuser.email,
                                  address1: _newuser.address1,
                                  address2: _newuser.address2,
                                  city: _newuser.city,
                                  postcode: _newuser.postcode,
                                  state: _newuser.state,
                                  country: _newuser.country,
                                  usertype: _newuser.usertype,
                                  occupation: _newuser.occupation,
                                  gender: _newuser.gender,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      TextFormField(
                        decoration: const InputDecoration(labelText: 'Email'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        textCapitalization: TextCapitalization.none,
                        validator: (value) {
                          if (value == null ||
                              value.trim().isEmpty ||
                              !value.contains('@')) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _newuser = User(
                            id: _newuser.id,
                            username: _newuser.username,
                            password: _newuser.password,
                            firstname: _newuser.firstname,
                            lastname: _newuser.lastname,
                            phone: _newuser.phone,
                            dob: _newuser.dob,
                            email: value!,
                            address1: _newuser.address1,
                            address2: _newuser.address2,
                            city: _newuser.city,
                            postcode: _newuser.postcode,
                            state: _newuser.state,
                            country: _newuser.country,
                            usertype: _newuser.usertype,
                            occupation: _newuser.occupation,
                            gender: _newuser.gender,
                          );
                        },
                      ),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Address Line 1'),
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a valid address';
                          }
                          return null;
                        },
                        onSaved: (value) {
                          _newuser = User(
                            id: _newuser.id,
                            username: _newuser.username,
                            password: _newuser.password,
                            firstname: _newuser.firstname,
                            lastname: _newuser.lastname,
                            phone: _newuser.phone,
                            dob: _newuser.dob,
                            email: _newuser.email,
                            address1: value!,
                            address2: _newuser.address2,
                            city: _newuser.city,
                            postcode: _newuser.postcode,
                            state: _newuser.state,
                            country: _newuser.country,
                            usertype: _newuser.usertype,
                            occupation: _newuser.occupation,
                            gender: _newuser.gender,
                          );
                        },
                      ),
                      TextFormField(
                        enabled: _authMode == AuthMode.Signup,
                        decoration:
                            const InputDecoration(labelText: 'Address Line 2'),

                        textInputAction: TextInputAction.next,
                        // validator: _authMode == AuthMode.Signup
                        //     ? (value) {
                        //         if (value!.isEmpty) {
                        //           return 'Please enter your second line address';
                        //         }
                        //       }
                        //     : null,
                        onSaved: (value) {
                          _newuser = User(
                            id: _newuser.id,
                            username: _newuser.username,
                            password: _newuser.password,
                            firstname: _newuser.firstname,
                            lastname: _newuser.lastname,
                            phone: _newuser.phone,
                            dob: _newuser.dob,
                            email: _newuser.email,
                            address1: _newuser.address1,
                            address2: value,
                            city: _newuser.city,
                            postcode: _newuser.postcode,
                            state: _newuser.state,
                            country: _newuser.country,
                            usertype: _newuser.usertype,
                            occupation: _newuser.occupation,
                            gender: _newuser.gender,
                          );
                        },
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: _authMode == AuthMode.Signup,
                              decoration:
                                  const InputDecoration(labelText: 'City'),
                              textInputAction: TextInputAction.next,
                              validator: _authMode == AuthMode.Signup
                                  ? (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your city';
                                      }
                                      return null;
                                    }
                                  : null,
                              onSaved: (value) {
                                _newuser = User(
                                  id: _newuser.id,
                                  username: _newuser.username,
                                  password: _newuser.password,
                                  firstname: _newuser.firstname,
                                  lastname: _newuser.lastname,
                                  phone: _newuser.phone,
                                  dob: _newuser.dob,
                                  email: _newuser.email,
                                  address1: _newuser.address1,
                                  address2: _newuser.address2,
                                  city: value!,
                                  postcode: _newuser.postcode,
                                  state: _newuser.state,
                                  country: _newuser.country,
                                  usertype: _newuser.usertype,
                                  occupation: _newuser.occupation,
                                  gender: _newuser.gender,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              decoration:
                                  const InputDecoration(labelText: 'Zip code'),
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null ||
                                    value.trim().isEmpty ||
                                    value.length < 5) {
                                  return 'Please enter a valid zip code';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                _newuser = User(
                                  id: _newuser.id,
                                  username: _newuser.username,
                                  password: _newuser.password,
                                  firstname: _newuser.firstname,
                                  lastname: _newuser.lastname,
                                  phone: _newuser.phone,
                                  dob: _newuser.dob,
                                  email: _newuser.email,
                                  address1: _newuser.address1,
                                  address2: _newuser.address2,
                                  city: _newuser.city,
                                  postcode: int.parse(value!),
                                  state: _newuser.state,
                                  country: _newuser.country,
                                  usertype: _newuser.usertype,
                                  occupation: _newuser.occupation,
                                  gender: _newuser.gender,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              enabled: _authMode == AuthMode.Signup,
                              decoration:
                                  const InputDecoration(labelText: 'State'),
                              textInputAction: TextInputAction.done,
                              validator: _authMode == AuthMode.Signup
                                  ? (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your state';
                                      }
                                      return null;
                                    }
                                  : null,
                              onSaved: (value) {
                                _newuser = User(
                                  id: _newuser.id,
                                  username: _newuser.username,
                                  password: _newuser.password,
                                  firstname: _newuser.firstname,
                                  lastname: _newuser.lastname,
                                  phone: _newuser.phone,
                                  dob: _newuser.dob,
                                  email: _newuser.email,
                                  address1: _newuser.address1,
                                  address2: _newuser.address2,
                                  city: _newuser.city,
                                  postcode: _newuser.postcode,
                                  state: value!,
                                  country: _newuser.country,
                                  usertype: _newuser.usertype,
                                  occupation: _newuser.occupation,
                                  gender: _newuser.gender,
                                );
                              },
                            ),
                          ),
                          Expanded(
                            child: TextFormField(
                              enabled: _authMode == AuthMode.Signup,
                              decoration:
                                  const InputDecoration(labelText: 'Country'),
                              textInputAction: TextInputAction.done,
                              validator: _authMode == AuthMode.Signup
                                  ? (value) {
                                      if (value!.isEmpty) {
                                        return 'Please enter your country';
                                      }
                                      return null;
                                    }
                                  : null,
                              onSaved: (value) {
                                _newuser = User(
                                  id: _newuser.id,
                                  username: _newuser.username,
                                  password: _newuser.password,
                                  firstname: _newuser.firstname,
                                  lastname: _newuser.lastname,
                                  phone: _newuser.phone,
                                  dob: _newuser.dob,
                                  email: _newuser.email,
                                  address1: _newuser.address1,
                                  address2: _newuser.address2,
                                  city: _newuser.city,
                                  postcode: _newuser.postcode,
                                  state: _newuser.state,
                                  country: value!,
                                  usertype: _newuser.usertype,
                                  occupation: _newuser.occupation,
                                  gender: _newuser.gender,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      DropdownButtonFormField<dynamic>(
                        initialValue: null,
                        hint: const Text('Role'),
                        items: const [
                          DropdownMenuItem(value: 2, child: Text('Volunteer')),
                          DropdownMenuItem(value: 3, child: Text('Researcher')),
                          DropdownMenuItem(value: 4, child: Text('Boat Owner')),
                        ],
                        onChanged: (value) {
                          setState(() {});
                        },
                        validator: (value) =>
                            value == null ? 'Please choose your role' : null,
                        onSaved: (value) {
                          _newuser = User(
                            id: _newuser.id,
                            username: _newuser.username,
                            password: _newuser.password,
                            firstname: _newuser.firstname,
                            lastname: _newuser.lastname,
                            phone: _newuser.phone,
                            dob: _newuser.dob,
                            email: _newuser.email,
                            address1: _newuser.address1,
                            address2: _newuser.address2,
                            city: _newuser.city,
                            postcode: _newuser.postcode,
                            state: _newuser.state,
                            country: _newuser.country,
                            usertype: value!,
                            occupation: _newuser.occupation,
                            gender: _newuser.gender,
                          );
                        },
                      ),
                    ],
                  ),
                const SizedBox(
                  height: 20,
                ),
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                    ),
                    onPressed: _submit,
                    child: Text(
                        _authMode == AuthMode.Login ? 'Login' : 'Register'),
                  ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                  ),
                  onPressed: _switchAuthMode,
                  child: Text(_authMode == AuthMode.Login
                      ? 'Register'
                      : 'I already have an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<DateTime?> pickDate() => showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now());
}
