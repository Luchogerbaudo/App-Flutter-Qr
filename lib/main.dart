// ignore_for_file: deprecated_member_use, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:probando/database.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Escaner QR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ScanerQr(title: 'Escaner'),
    );
  }
}

class ScanerQr extends StatefulWidget {
  const ScanerQr({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<ScanerQr> createState() => _ScanerQr();
}

class _ScanerQr extends State<ScanerQr> {
  // Global Key para acceder al controlador del QR
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  late QRViewController controller;
  late String qrText;
  List<List<dynamic>> infoResult = [];
  int fifoQuery = 0;
  String codigo = '';
  String proveedor = '';
  String remito = '';
  String fecha = '';
  String cantidad = '';
  String fifo = '';
  String codigoPieza = '';
  String todoElQr = '';
  late String codigoPiezaGlobal;
  TextEditingController cantidadController = TextEditingController();

  @override
  void initState() {
    super.initState();
    qrText = 'Escanea un código QR';
    _solicitarPermisoDeCamara();
  }

  // Función para solicitar permiso de la cámara
  void _solicitarPermisoDeCamara() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _inicializarEscaneo();
    } else {
      // Mostrar un mensaje de error al usuario
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: const Text(
                'La aplicación necesita acceso a la cámara para funcionar.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Ok'),
              ),
            ],
          );
        },
      );
    }
  }

  // Función para inicializar el escáner QR
  void _inicializarEscaneo() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Mostrar la vista del escáner QR
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _qrEscaneado,
            ),
          ),
          // Mostrar la información del código escaneado
          Expanded(
            flex: 1,
            child: _infoCodigo(),
          ),
        ],
      ),
      floatingActionButton: Positioned(
        bottom: 16.0,
        right: 16.0,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MyApp(),
              ),
            );
          },
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }

  // Mostrar la información del código escaneado
  Widget _infoCodigo() {
    if (infoResult.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Mostrar el código escaneado
          Text('Codigo: ${infoResult[0][0]}'),
          // Botón para ver información
          ElevatedButton(
            onPressed: () {
              _mostrarAlertDialog(context, infoResult[0]);
            },
            style: ElevatedButton.styleFrom(
              primary: Colors.deepPurple, // Color de fondo del botón
              onPrimary: Colors.white, // Color del texto del botón
              elevation: 4, // Elevación del botón
              padding: const EdgeInsets.symmetric(
                  vertical: 16.0, horizontal: 24.0), // Ajuste de padding
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0), // Borde redondeado
              ),
            ),
            child: const Text(
              'Ver Información Detallada',
              style: TextStyle(
                fontSize: 18.0, // Tamaño de la fuente del texto
                fontWeight: FontWeight.bold, // Negrita
              ),
            ),
          ),

          // Mensaje para escanear otro QR
          const Text(
            'Escanee otro QR para ver info',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    } else {
      // Manejar el caso cuando no se encuentra código
      if (qrText == 'Escanea un código QR') {
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Mensaje para escanear un código QR
            Text(
              'Escanea un código QR',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      } else {
        // Indicar que no se encontró el código
        return const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('No se encontró el código'),
            // Mensaje para escanear otro QR
            Text(
              'Escanee otro QR para ver info',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      }
    }
  }

  // Función para manejar el escaneo del QR
  void _qrEscaneado(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrText = scanData.code ?? 'N/A';
      });

      RegExp regex = RegExp(
          r"'CODIGO':([^,]+),'PROVEEDOR':([^,]+),'REMITO':([^,]+),'FECHA':([^,]+),'CANTIDAD':([^,]+),'FIFO':([^}]+)");
      Match? match = regex.firstMatch(qrText);

      if (match != null) {
        codigo = match.group(1)?.trim() ?? 'N/A';
        proveedor = match.group(2)?.trim() ?? 'N/A';
        remito = match.group(3)?.trim() ?? 'N/A';
        fecha = match.group(4)?.trim() ?? 'N/A';
        cantidad = match.group(5)?.trim() ?? 'N/A';
        fifo = match.group(6)?.trim() ?? 'N/A';

        selectCodigo(codigo);
      } else {
        setState(() {
          qrText = 'Formato de código QR no válido';
        });
      }
    });
  }

  // Función para seleccionar el código escaneado
  Future<void> selectCodigo(String codigo) async {
    final connection = await DatabaseHelper.openConnection();
    try {
      // Realizar la consulta en la base de datos
      final result = await DatabaseHelper.executeQuery(
        connection,
        'SELECT "Codigo", "Descripcion" FROM "Tpieza" WHERE "Codigo" = \'$codigo\'',
      );

      if (result.isNotEmpty) {
        // Mostrar el resultado
        _mostrarResultado(result);
        codigoPiezaGlobal = result[0][0];
      } else {
        setState(() {
          infoResult = [];
        });
      }
    } catch (e) {
      setState(() {
        qrText = 'Error al realizar la consulta';
      });
    } finally {
      await DatabaseHelper.closeConnection(connection);
    }
  }

  // Función para mostrar el resultado
  void _mostrarResultado(List<List<dynamic>> result) {
    setState(() {
      infoResult = List.from(result);
    });
  }

  // Función para mostrar un AlertDialog con la info
  Future<void> _mostrarAlertDialog(
      BuildContext context, List<dynamic> info) async {
    final connection = await DatabaseHelper.openConnection();

    try {
      var result = await connection.query(
        'Select "Fifo" from "Ttransferencia" where "Corigen" = \'$codigo\' order by "Fifo" ASC limit 1',
      );

      int fifoInt = int.parse(fifo);
      fifoQuery = int.parse(result[0][0].toString());

      if (result.isNotEmpty) {
        if (fifoInt > fifoQuery) {
          _mostrarIncorrecto(context);
        } else {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text(
                  'Información del Código',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Info QR:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18.0,
                            )),
                        Text(
                          'Codigo: $codigo\nProveedor: $proveedor\nRemito: $remito\nFecha: $fecha\nCantidad: $cantidad\nFifo: $fifo',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text('Origen:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        )),
                    Text(
                      'Codigo pieza origen: ${info[0]} \nDescripcion origen: ${info[1]} \nDeposito origen: 01',
                    ),
                    const SizedBox(height: 10),
                    const Text('Destino:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0,
                        )),
                    Text(
                      'Codigo pieza destino: ${info[0]} \nDescripcion destino: ${info[1]} \nDeposito destino: 04',
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text('Cantidad: '),
                        Expanded(
                          child: TextField(
                            controller: cantidadController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  // Botón para cancelar
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancelar'),
                  ),
                  // Botón para enviar la cantidad
                  TextButton(
                    onPressed: () {
                      postCodigo(info[0]);
                      Navigator.of(context).pop();
                    },
                    child: const Text('Enviar'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      // ...
    } finally {
      await DatabaseHelper.closeConnection(connection);
    }
  }

  void _mostrarIncorrecto(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          title: const Text(
            'Incorrecto',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            'Existe el fifo $fifoQuery para despachar',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Ok',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red,
          title: const Text(
            "La cantidad debe ser mayor que 0",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            // Cerrar el cuadro de diálogo
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Ok", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Función para realizar el registro en la bd
  Future<void> postCodigo(String codigoPieza) async {
    final connection = await DatabaseHelper.openConnection();

    try {
      DateTime now = DateTime.now();
      String fechaActual =
          "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      String horaActual =
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      String usuario = obtenerUsuarioHora(now.hour);

      if (int.parse(cantidadController.text) > 0) {
        var result = await connection
            .query('SELECT MAX("id") FROM public."Ttransferencia"');
        var idQuery = result.first.first + 1;

        await connection.query('''
        INSERT INTO public."Ttransferencia"(id, "Corigen", "Cdestino", "Dorigen", "Ddestino", "Cantidad", "Procesado", "Fecha", "Hora", "Usuario")
        VALUES ($idQuery, '$codigoPieza', '$codigoPieza', '01', '04', '${cantidadController.text}', true, '$fechaActual', '$horaActual', '$usuario');
      ''');

        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.green,
              title: Text(
                "Transferencia realizada con éxito. ID: $idQuery",
                style: const TextStyle(color: Colors.white),
              ),
              actions: [
                // Cerrar el cuadro de diálogo
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:
                      const Text("Ok", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      } else {
        // Mensaje de error si la cantidad no es válida
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.red,
              title: const Text(
                "La cantidad debe ser mayor que 0",
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                // Cerrar el cuadro de diálogo
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child:
                      const Text("Ok", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Mensaje de error si hay fallo
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.red,
            title: Text(
              "Error al realizar la transferencia: $e",
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              // Cerrar el cuadro de diálogo
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Ok", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    } finally {
      await connection.close();
    }
  }

  // usuario = TM si hora es menor a 12, si no, TT
  String obtenerUsuarioHora(int hora) {
    return (hora >= 0 && hora < 12) ? 'TM' : 'TT';
  }

  // Cerrar QR al salir de vista
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
