import 'package:graphql_flutter/graphql_flutter.dart';

class GraphQLService {
  late GraphQLClient client;

  String? accessToken;

  GraphQLService() {
    final HttpLink httpLink = HttpLink("http://172.18.18.217:3000/graphql");
    client = GraphQLClient(link: httpLink, cache: GraphQLCache());
  }

  Future<void> register({
    required String userName,
    required String email,
    required String phone,
    required String password,
    required String confirm,
  }) async {
    const String mutation = """
      mutation Register(\$input: CreateRegisterInput!) {
        register(input: \$input) {
          message
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
          },
        },
      ),
    );

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }
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

    accessToken = result.data!['login']['accessToken'];

    return accessToken!;
  }

  Future<Map<String, dynamic>> me() async {
    final Link authLink = HttpLink(
      "http://192.168.1.2:3000/graphql",
      defaultHeaders: {"Authorization": "Bearer $accessToken"},
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
      }
    }
  """;

    final result = await authClient.query(QueryOptions(document: gql(query)));

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    return result.data!['me'];
  }
}
