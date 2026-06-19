import 'package:flint_dart/auth.dart';
import 'package:flint_dart/flint_dart.dart';
import 'package:backend/models/user_model.dart';
import 'package:backend/models/plan_model.dart';
import 'package:backend/models/subscription_model.dart';
import 'package:backend/models/server_model.dart';
import 'package:backend/models/job_model.dart';
import 'package:backend/config/app_config.dart';

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
      const role = 'customer';
      final requestedRole = (body["role"] ?? role).toString().toLowerCase();
      if (requestedRole != role) {
        return res.status(422).json({
          "status": "errors",
          "errors": {
            "role": ["Public registration can only create customer accounts."]
          }
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

      await Validator.validate(
          body, {"email": "required|string", "password": "required|string"});

      final login = body['email'].toString().trim().toLowerCase();
      final password = body['password'].toString();
      final foundByUsername = await User().whereSimple('username', login);
      final foundByEmail = foundByUsername.isEmpty
          ? await User().whereSimple('email', login)
          : [];
      final userModel = foundByUsername.isNotEmpty
          ? foundByUsername.first
          : (foundByEmail.isNotEmpty ? foundByEmail.first : null);

      if (userModel == null ||
          !Hashing().verify(password, userModel.password ?? '')) {
        return res.status(422).json({
          "status": "errors",
          "errors": "Invalid email, username, or password"
        });
      }

      final user = Map<String, dynamic>.from(userModel.toMap());
      user.remove('password');
      final authResult = {
        'user': user,
        'token': Auth.generateToken(user),
      };

      return res.json({"status": "successful", "data": authResult});
    } on ValidationException catch (e) {
      return res.status(422).json({"status": "errors", "errors": e.errors});
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
      return res
          .status(401)
          .json({"status": "error", "message": "Unauthorized"});
    }
    return res.json({"status": "success", "data": user});
  }

  Future<Response> seedDefaultUsers() async {
    try {
      if (AppConfig.isProduction || !AppConfig.enableDemoSeed) {
        return res.status(404).json({
          "status": "error",
          "message": "Demo user seeding is disabled.",
        });
      }

      final defaults = [
        {
          "name": "System Admin",
          "username": "admin",
          "email": "admin@eupanel.local",
          "password": "Admin@12345",
          "role": "admin",
        },
        {
          "name": "Demo Customer",
          "username": "customer",
          "email": "customer@eupanel.local",
          "password": "Customer@12345",
          "role": "customer",
        },
        {
          "name": "Demo Reseller",
          "username": "reseller",
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
          "username": seed["username"],
          "email": seed["email"],
          "password": Hashing().hash(seed["password"]!),
          "role": seed["role"],
        });

        if (created != null) {
          createdOrExisting.add(created.toMap());
        }
      }

      // Seed a default Server if none exists
      final serverModel = Server();
      final existingServers = await serverModel.all();
      String? serverId;
      if (existingServers.isEmpty) {
        final server = await serverModel.create({
          'name': 'Primary Node-1 (US East)',
          'host': '192.168.1.100',
          'status': 'active',
          'agent_port': '7820',
          'agent_version': '1.0.0',
        });
        serverId = server?.id?.toString();
      } else {
        serverId = existingServers.first.id?.toString();
      }

      // Seed default Plans if none exist
      final planModel = Plan();
      final existingPlans = await planModel.all();
      String? planId1;
      String? planId2;
      if (existingPlans.isEmpty) {
        final p1 = await planModel.create({
          'name': 'Starter Plan',
          'description': 'Perfect for personal sites and blogs',
          'disk_limit': 10,
          'bandwidth_limit': 100,
          'ftp_accounts_limit': 2,
          'database_limit': 2,
          'domain_limit': 1,
          'subdomain_limit': 5,
          'price': 4.99,
          'status': 'active',
        });
        final p2 = await planModel.create({
          'name': 'Business Pro',
          'description': 'For high traffic business sites',
          'disk_limit': 50,
          'bandwidth_limit': 500,
          'ftp_accounts_limit': 10,
          'database_limit': 10,
          'domain_limit': 5,
          'subdomain_limit': 20,
          'price': 14.99,
          'status': 'active',
        });
        planId1 = p1?.id?.toString();
        planId2 = p2?.id?.toString();
      } else {
        planId1 = existingPlans.first.id?.toString();
        planId2 = existingPlans.length > 1
            ? existingPlans[1].id?.toString()
            : existingPlans.first.id?.toString();
      }

      // Find the customer user
      final customerUser = createdOrExisting.firstWhere(
        (u) => u['role']?.toString().toLowerCase() == 'customer',
        orElse: () => createdOrExisting.first,
      );
      final customerUserId = customerUser['id']?.toString();

      // Seed default Subscriptions if none exist
      final subModel = Subscription();
      final existingSubs = await subModel.all();
      if (existingSubs.isEmpty && customerUserId != null && planId1 != null) {
        await subModel.create({
          'user_id': customerUserId,
          'created_by_user_id': customerUserId,
          'plan_id': planId1,
          'server_id': serverId,
          'primary_domain': 'site1.eupanel.local',
          'panel_username': 'eupanel_user1',
          'system_username': 'eupanel_user1',
          'ftp_username': 'ftp_user1',
          'ftp_password': 'Password@12345',
          'home_directory': '/home/eupanel_user1',
          'status': 'active',
          'provisioning_status': 'success',
          'provisioning_log': 'nginx: ok | SSL: active',
        });
        if (planId2 != null) {
          await subModel.create({
            'user_id': customerUserId,
            'created_by_user_id': customerUserId,
            'plan_id': planId2,
            'server_id': serverId,
            'primary_domain': 'site2.eupanel.local',
            'panel_username': 'eupanel_user2',
            'system_username': 'eupanel_user2',
            'ftp_username': 'ftp_user2',
            'ftp_password': 'Password@67890',
            'home_directory': '/home/eupanel_user2',
            'status': 'suspended',
            'provisioning_status': 'success',
            'provisioning_log':
                'nginx: ok | SSL: active | status: suspended by admin',
          });
        }
      }

      // Seed default Jobs if none exist
      final jobModel = Job();
      final existingJobs = await jobModel.all();
      if (existingJobs.isEmpty) {
        await jobModel.create({
          'type': 'provision_nginx',
          'status': 'success',
          'targetType': 'subscription',
          'targetId': '1',
          'serverId': serverId,
          'payload': '{"domain": "site1.eupanel.local"}',
          'logs':
              'Nginx virtual host created successfully\nNginx service reloaded',
        });
        await jobModel.create({
          'type': 'issue_ssl',
          'status': 'success',
          'targetType': 'ssl_certificate',
          'targetId': '1',
          'serverId': serverId,
          'payload':
              '{"domain": "site1.eupanel.local", "email": "admin@eupanel.local"}',
          'logs':
              'Let\'s Encrypt challenge solved\nSSL certificate stored locally',
        });
      }

      return res.json({
        "status": "success",
        "message": "Default users are ready.",
        "credentials": defaults
            .map((seed) => {
                  "email": seed["email"],
                  "username": seed["username"],
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
