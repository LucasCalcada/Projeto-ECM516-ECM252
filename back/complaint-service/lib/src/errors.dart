class ApiException implements Exception {
  const ApiException(this.statusCode, this.code, this.message);

  final int statusCode;
  final String code;
  final String message;

  static const notFound = ApiException(
    404,
    'not_found',
    'Reclamação não encontrada.',
  );
  static const forbidden = ApiException(
    403,
    'forbidden',
    'Acesso não permitido.',
  );
  static const unauthorized = ApiException(
    401,
    'unauthorized',
    'Autenticação inválida.',
  );
}
