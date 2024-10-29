import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';  // Agregar firebase_core para inicializar Firebase
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';  // Para obtener rutas de almacenamiento
import 'package:firebase_storage/firebase_storage.dart';  // Firebase Storage para subir archivos

void main() async {
  WidgetsFlutterBinding.ensureInitialized();  // Asegúrate de que Flutter esté inicializado
  await Firebase.initializeApp();  // Inicializa Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('Formulario de Trabajadores'),
        ),
        body: WorkerForm(), // Llama al widget del formulario
      ),
    );
  }
}

class WorkerForm extends StatefulWidget {
  @override
  _WorkerFormState createState() => _WorkerFormState();
}

class _WorkerFormState extends State<WorkerForm> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _positionController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> createCSVFile(String name, int age, String position) async {
    try {
      List<List<dynamic>> rows = [];
      rows.add(['Nombre', 'Edad', 'Posición']);
      rows.add([name, age, position]);

      String csv = const ListToCsvConverter().convert(rows);

      // Obtener el directorio de documentos (una ruta permitida para escritura)
      Directory? directory = await getExternalStorageDirectory();
      String path = "${directory?.path}/$name.csv";

      File csvFile = File(path);
      await csvFile.writeAsString(csv);

      print('Archivo CSV creado en: $path');

      // Llamar a la función para subir el archivo a Firebase Storage
      await uploadFileToFirebase(csvFile, name);
    } catch (e) {
      print('Error al crear el archivo CSV: $e');
    }
  }

  // Función para subir el archivo CSV a Firebase Storage
  Future<void> uploadFileToFirebase(File file, String fileName) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;

      // Crear una referencia en Firebase Storage
      Reference ref = storage.ref().child('formularios/$fileName.csv');

      // Subir el archivo CSV
      await ref.putFile(file);

      // Obtener la URL del archivo subido (opcional, para compartir)
      String downloadURL = await ref.getDownloadURL();
      print('Archivo subido a Firebase Storage. URL de descarga: $downloadURL');
    } catch (e) {
      print('Error al subir el archivo a Firebase: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: 'Nombre'),
          ),
          TextField(
            controller: _ageController,
            decoration: InputDecoration(labelText: 'Edad'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _positionController,
            decoration: InputDecoration(labelText: 'Posición'),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              String name = _nameController.text;
              int age = int.tryParse(_ageController.text) ?? 0;
              String position = _positionController.text;

              // Crear el archivo CSV con los datos ingresados
              createCSVFile(name, age, position);
            },
            child: Text('Guardar Datos y Crear CSV'),
          ),
        ],
      ),
    );
  }
}
