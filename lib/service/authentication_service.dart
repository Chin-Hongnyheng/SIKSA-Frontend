// ignore_for_file: avoid_print

import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class GraphQLService {
  late GraphQLClient client;

  String? accessToken;
  String? refreshToken;

  GraphQLService() {
    final HttpLink httpLink = HttpLink(dotenv.env['GRAPHQL_URL']!);
    client = GraphQLClient(link: httpLink, cache: GraphQLCache());
  }

  Future<String> register({
    required String userName,
    required String email,
    required String phone,
    required String password,
    required String confirm,
    required String role,
    t,
  }) async {
    const String mutation = """
      mutation Register(\$input: CreateRegisterInput!) {
        register(input: \$input) {
          message
          accessToken
          refreshToken
        }
      }
    """;

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "userName": userName,
            "email": email,
            "phone": int.parse(phone),
            "password": password,
            "confirmPassword": confirm,
            "role": role,
          },
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    await AuthProvider.saveTokens(
      accessToken: result.data!['register']['accessToken'],
      refreshToken: result.data!['register']['refreshToken'],
    );

    return AuthProvider.accessToken!;
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    const String mutation = """
    mutation Login(\$input: CreateLoginInput!) {
      login(input: \$input) {
        accessToken
        refreshToken
      }
    }
  """;

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {"email": email, "password": password},
        },
      ),
    );

    if (result.hasException) {
      final exception = result.exception;

      final message = (exception?.graphqlErrors.isNotEmpty == true)
          ? exception!.graphqlErrors.first.message
          : exception.toString();
      throw message;
    }

    await AuthProvider.saveTokens(
      accessToken: result.data!['login']['accessToken'],
      refreshToken: result.data!['login']['refreshToken'],
    );

    return AuthProvider.accessToken!;
  }

  Future<Map<String, dynamic>> me() async {
    final Link authLink = HttpLink(
      dotenv.env['GRAPHQL_URL']!,
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );

    final GraphQLClient authClient = GraphQLClient(
      link: authLink,
      cache: GraphQLCache(),
    );

    const String query = """
    query Me {
      me {
        id
        userName
        email
        phone
        role
        dob
        gender
        address
        photo_url
      }
    }
  """;

    final result = await authClient.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      final error = result.exception.toString();

      if (error.contains('Unauthorized') || error.contains('UNAUTHENTICATED')) {
        await AuthProvider.clearTokens();
        throw Exception('SESSION_EXPIRED');
      }

      throw Exception(error);
    }

    return result.data!['me'];
  }

  Future<void> forget({
    required String email,
    required String newPassword,
    required String confirm,
  }) async {
    const String mutation = """
      mutation Register(\$input: CreateForgetInput!){
        forgetPassword(input: \$input){
        message
        }
      }
  """;

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "email": email,
            "newPassword": newPassword,
            "confirmPassword": confirm,
          },
        },
      ),
    );

    if (result.hasException) {
      final exception = result.exception;

      final message = (exception?.graphqlErrors.isNotEmpty == true)
          ? exception!.graphqlErrors.first.message
          : exception.toString();
      throw message;
    }
  }

  Future<void> validate({
    required String userName,
    required String email,
    required String phone,
    required String password,
    required String confirm,
  }) async {
    const String mutation = """
    mutation Validate(\$input: CreateRegisterInput!) {
      validateRegister(input: \$input)
    }
  """;

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {
            "userName": userName,
            "email": email,
            "phone": int.parse(phone),
            "password": password,
            "confirmPassword": confirm,
          },
        },
      ),
    );

    if (result.hasException) {
      final exception = result.exception;

      final message = (exception?.graphqlErrors.isNotEmpty == true)
          ? exception!.graphqlErrors.first.message
          : exception.toString();
      throw message;
    }
  }

  Future<void> validateLogin({
    required String email,
    required String password,
  }) async {
    const String mutation = """
    mutation ValidateLogin(\$input: CreateLoginInput!) {
      validateLogin(input: \$input)
    }
""";

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {"email": email, "password": password},
        },
      ),
    );

    if (result.hasException) {
      final exception = result.exception;

      final message = (exception?.graphqlErrors.isNotEmpty == true)
          ? exception!.graphqlErrors.first.message
          : exception.toString();
      throw message;
    }
  }

  Future<Map<String, dynamic>> update({
    required String userName,
    required String? phone,
    required String? dob,
    required String gender,
    required String address,
  }) async {
    final Link authLink = HttpLink(
      dotenv.env['GRAPHQL_URL']!,
      defaultHeaders: {"Authorization": "Bearer ${AuthProvider.accessToken}"},
    );
    final GraphQLClient client = GraphQLClient(
      link: authLink,
      cache: GraphQLCache(),
    );
    const String mutation = """
  mutation UpdateProfile(\$input: UpdateUserInput!) {
    updateProfile(input: \$input) {
      message
      user {
        id
        userName
        email
        phone
        role
        dob
        gender
        address
        photo_url
      }
    }
  }
  """;
    final MutationOptions options = MutationOptions(
      document: gql(mutation),
      variables: {
        "input": {
          "userName": userName,
          "phone": phone != null ? int.parse(phone) : null,
          "dob": dob,
          "gender": gender,
          "address": address,
        },
      },
    );
    final result = await client.mutate(options);
    if (result.hasException) {
      final exception = result.exception;

      final message = (exception?.graphqlErrors.isNotEmpty == true)
          ? exception!.graphqlErrors.first.message
          : exception.toString();
      throw message;
    }
    print('update result: ${result.data}');
    print('update exception: ${result.exception}');
    return result.data!['updateProfile'];
  }

  Future<String> uploadPhoto({
    required String userId,
    required File imageFile,
  }) async {
    final uri = Uri.parse('${dotenv.env['BASE_URL']}/auth/users/$userId/photo');

    final request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Bearer ${AuthProvider.accessToken}'
      ..files.add(await http.MultipartFile.fromPath('photo', imageFile.path));

    final response = await request.send();
    final body = await response.stream.bytesToString();
    final json = jsonDecode(body);

    if (response.statusCode != 200) {
      throw Exception(json['message'] ?? 'Upload failed');
    }

    return json['photo_url'];
  }

  Future<String> googleAuth({
    required String idToken,
    required String role,
  }) async {
    const String mutation = """
    mutation GoogleAuth(\$input: GoogleAuthInput!) {
      googleAuth(input: \$input) {
        accessToken
        refreshToken
      }
    }
  """;

    final result = await client.mutate(
      MutationOptions(
        document: gql(mutation),
        variables: {
          "input": {"idToken": idToken, "role": role},
        },
      ),
    );

    if (result.hasException) {
      final exception = result.exception;
      final message = (exception?.graphqlErrors.isNotEmpty == true)
          ? exception!.graphqlErrors.first.message
          : exception.toString();
      throw message;
    }

    await AuthProvider.saveTokens(
      accessToken: result.data!['googleAuth']['accessToken'],
      refreshToken: result.data!['googleAuth']['refreshToken'],
    );

    return AuthProvider.accessToken!;
  }
}
