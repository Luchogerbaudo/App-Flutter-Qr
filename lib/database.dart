// Función para abrir y cerrar la conexión a la base de datos
import 'package:postgres/postgres.dart';

class DatabaseHelper {
  // Función para abrir la conexión a la base de datos
  static Future<PostgreSQLConnection> openConnection() async {
    final connection = PostgreSQLConnection(
        // Conexion a BD de escritorio remoto Pruebas
        '111.111.11.111',
        1111,
        'NombreBd',
        username: 'username',
        password: 'username'

    );

    await connection.open();
    return connection;
  }

  // Función para ejecutar una consulta
  static Future<List<List<dynamic>>> executeQuery(
      PostgreSQLConnection connection, String query) async {
    final result = await connection.query(query);
    return result;
  }

  // Función para cerrar la conexión
  static Future<void> closeConnection(PostgreSQLConnection connection) async {
    await connection.close();
  }
}
