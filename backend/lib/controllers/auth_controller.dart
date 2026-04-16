import 'package:flint_dart/auth.dart';
import 'package:flint_dart/flint_dart.dart';
import 'package:backend/models/user_model.dart';

class AuthController extends Controller {
  Future<Response> register() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        "email": "required|email",
        "name": "required|string|min:2|max:255",
        "password": "required|string",
        "role": "string",
      });
      final allowedRoles = ['admin', 'customer', 'reseller'];
      final role = (body["role"] ?? 'customer').toString().toLowerCase();
      if (!allowedRoles.contains(role)) {
        return res.status(422).json({
          "status": "errors",
          "errors": {"role": ["Role must be admin, customer, or reseller."]}
        });
      }
      String hashPassword = Hashing().hash(body["password"]);
      body["password"] = hashPassword;
      body["role"] = role;
      final User? user = await User().create(body);

      return res.json({"status": "success", "data": user?.toMap()});
    } on ValidationException catch (e) {
      return res.status(422).json({"status": "errors", "errors": e.errors});
    } catch (e) {
      return res.status(422).json(
        {"status": "error", "message": e.toString()},
      );
    }
  }

  Future<Response> login() async {
    try {
      var body = await req.json();

      Validator.validate(
          body, {"email": "required|string", "password": "required|string"});

      final authResult = await Auth.login(body['email'], body["password"]);

      return res.json({
        "status": "successful",
        "data": authResult
      });
    } on ValidationException catch (e) {
      return res.status(422).json({"status": "errors", "errors": e});
    } catch (e) {
      return res.status(422).json({"status": "errors", "errors": e.toString()});
    }
  }

  Future<Response> loginWithGoogle() async {
    try {
      final body = await req.json();

      // Check if idToken or code is present and validate
      await Validator.validate(body,
          {"idToken": "string", "code": "string", "callbackPath": "string"});

      // Pass either idToken or code to the Auth class
      final Map<String, dynamic> authResult = await Auth.loginWithGoogle(
        idToken: body['idToken'],
        code: body['code'],
        callbackPath: body['callbackPath'],
      );

      return res.json({
        "status": "success",
        "data": authResult,
      });
    } on ArgumentError catch (e) {
      return res.status(400).json({"status": "error", "message": e.message});
    } on ValidationException catch (e) {
      return res.status(400).json({"status": "error", "message": e.errors});
    } catch (e) {
      return res.status(401).json({"status": "error", "message": e.toString()});
    }
  }

  Future<Response> update() async {
    return res.send('Updating item ${req.params['id']}');
  }

  Future<Response> delete() async {
    return res.send('Deleting item ${req.params['id']}');
  }

  Future<Response> me() async {
    final user = await req.user;
    if (user == null) {
      return res.status(401).json({"status": "error", "message": "Unauthorized"});
    }
    return res.json({"status": "success", "data": user});
  }

  Future<Response> seedDefaultUsers() async {
    try {
      final defaults = [
        {
          "name": "System Admin",
          "email": "admin@eupanel.local",
          "password": "Admin@12345",
          "role": "admin",
        },
        {
          "name": "Demo Customer",
          "email": "customer@eupanel.local",
          "password": "Customer@12345",
          "role": "customer",
        },
        {
          "name": "Demo Reseller",
          "email": "reseller@eupanel.local",
          "password": "Reseller@12345",
          "role": "reseller",
        },
      ];

      final createdOrExisting = <Map<String, dynamic>>[];
      for (final seed in defaults) {
        final existing = await User().whereSimple('email', seed["email"]);
        if (existing.isNotEmpty) {
          createdOrExisting.add(existing.first.toMap());
          continue;
        }

        final created = await User().create({
          "name": seed["name"],
          "email": seed["email"],
          "password": Hashing().hash(seed["password"]!),
          "role": seed["role"],
        });

        if (created != null) {
          createdOrExisting.add(created.toMap());
        }
      }

      return res.json({
        "status": "success",
        "message": "Default users are ready.",
        "credentials": defaults
            .map((seed) => {
                  "email": seed["email"],
                  "password": seed["password"],
                  "role": seed["role"],
                })
            .toList(),
        "users": createdOrExisting,
      });
    } catch (e) {
      return res.status(500).json({"status": "error", "message": e.toString()});
    }
  }
}
