import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/auth_provider.dart';

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

    AuthProvider.accessToken = result.data!['register']['accessToken'];
    AuthProvider.refreshToken = result.data!['register']['refreshToken'];

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
      throw Exception(result.exception.toString());
    }

    AuthProvider.accessToken = result.data!['login']['accessToken'];

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
        notification
        language
      }
    }
  """;

    final result = await authClient.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      throw Exception(result.exception.toString());
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
    required String dob,
    required String gender,
    required String address,
    required String notification,
    required String language,
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
        notification
        language
      }
    }
  }
  """;
    final MutationOptions options = MutationOptions(
      document: gql(mutation),
      variables: {
        "input": {
          "userName": userName,
          "dob": dob,
          "gender": gender,
          "address": address,
          "notification": notification,
          "language": language,
        },
      },
    );
    final result = await client.mutate(options);
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
    print('update result: ${result.data}');
    print('update exception: ${result.exception}');
    return result.data!['updateProfile'];
  }
}
