/// Produces a useful startup diagnostic without database URLs or SQL contents.
/// Server messages, details and hints can include credentials or stored values.
String describeMigrationDatabaseFailure(String? code) {
  final sqlState = code != null && RegExp(r'^[0-9A-Z]{5}$').hasMatch(code)
      ? code
      : 'unknown';
  final guidance = switch (sqlState) {
    '3D000' =>
      'O banco configurado não existe. Execute a inicialização dos bancos '
          'pelo Docker Compose da raiz do projeto e tente novamente.',
    '28000' || '28P01' =>
      'A autenticação no PostgreSQL falhou. Verifique as credenciais '
          'configuradas para o serviço.',
    '42501' =>
      'O usuário do PostgreSQL não possui as permissões necessárias '
          'para executar a migração.',
    '42601' || '42P01' || '42703' =>
      'A migração é incompatível com o esquema atual. Verifique as '
          'migrações e os logs do PostgreSQL.',
    '57P03' =>
      'O PostgreSQL ainda não aceita conexões. Aguarde o banco ficar '
          'disponível e tente novamente.',
    _ => 'Verifique o estado do banco e os logs do PostgreSQL.',
  };
  return 'Migration failed (PostgreSQL SQLSTATE $sqlState). $guidance';
}
