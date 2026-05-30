import 'package:flint_dart/flint_dart.dart';
import 'package:flint_dart/storage.dart';
import 'package:backend/models/user_model.dart';

class UserController extends Controller {
  Future<Response> index() async {
    final users = await User().all();
    return res.json({
      "message": 'List of user ',
      "users": users.map((user) => user.toMap()).toList()
    });
  }

  Future<Response> show() async {
    var user = await User().find(req.params['id']);
    // User user = await User().update(req.params['id'], {"name": "IBK Upade"});

    if (user != null) {
      return res.send('User ${user.toMap()}');
    }

    return res.status(404).json({"message": "user not found"});
  }

  Future<Response> create() async {
    try {
      final body = await req.json();
      await Validator.validate(body, {
        'name': 'required|string|min:2|max:255',
        'email': 'required|email',
        'password': 'required|string|min:8',
        'role': 'string',
      });

      final allowedRoles = ['admin', 'customer', 'reseller'];
      final role = (body['role'] ?? 'customer').toString().toLowerCase();
      if (!allowedRoles.contains(role)) {
        return res.status(422).json({
          'status': 'errors',
          'errors': {'role': ['Role must be admin, customer, or reseller.']}
        });
      }

      final existing = await User().whereSimple('email', body['email']);
      if (existing.isNotEmpty) {
        return res.status(422).json({
          'status': 'error',
          'message': 'A user with this email already exists.',
        });
      }

      final user = await User().create({
        'name': body['name'],
        'email': body['email'],
        'password': Hashing().hash(body['password']),
        'role': role,
      });

      return res.status(201).json({'status': 'success', 'data': user?.toMap()});
    } on ValidationException catch (e) {
      return res.status(422).json({'status': 'errors', 'errors': e.errors});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }

  Future<Response> update() async {
    try {
      final String userId = req.params['id']!;
      final body = await req.form();
      final String? name = body['name'];
      String? profilePicUrl;
      // Use the Storage class to handle file updates
      if (await req.hasFile('profile_pic')) {
        final file = await req.file('profile_pic');
        if (file != null) {
          final User? userToUpdate = await User().find(userId);
          final String? existingProfilePic = userToUpdate?.profilePicUrl;
          if (existingProfilePic != null) {
            // Update the existing profile picture
            profilePicUrl = await Storage.update(
                existingProfilePic, file,
                subdirectory: 'profiles');
          } else {
            // Create a new profile picture
            profilePicUrl =
                await Storage.create(file, subdirectory: 'profiles');
          }
        }
      }
      // Find the user and prepare the data for an update
      final User? userToUpdate = await User().find(userId);
      final Map<String, dynamic> updateData = {};
      if (name != null) {
        updateData['name'] = name;
      }
      if (profilePicUrl != null) {
        updateData['profilePicUrl'] = profilePicUrl;
      }
      // Update the user in the database
      if (updateData.isNotEmpty) {
        if (userToUpdate == null) {
          return res.status(404).json({"status": "error", "message": "User not found"});
        }
        await userToUpdate.update(id: userId, data: updateData);
      }

      final updatedUser = await User().find(userId);

      return res.json({
        "status": "success",
        "message": "User updated successfully.",
        "user": updatedUser?.toMap(),
      });
    } on ValidationException catch (e) {
      return res.status(422).json({"status": "errors", "errors": e.errors});
    } catch (e) {
      return res.status(500).json({
        "status": "error",
        "message": "Failed to update user: ${e.toString()}",
      });
    }
  }

  Future<Response> delete() async {
    try {
      final userId = req.params['id'];
      if (userId == null) {
        return res.status(400).json({'status': 'error', 'message': 'Missing user id'});
      }

      final user = await User().find(userId);
      if (user == null) {
        return res.status(404).json({'status': 'error', 'message': 'User not found'});
      }

      await user.delete(userId);
      return res.json({'status': 'success', 'message': 'User deleted successfully'});
    } catch (e) {
      return res.status(500).json({'status': 'error', 'message': e.toString()});
    }
  }
}
