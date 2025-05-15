import 'package:build/build.dart';
import 'package:cqrs_mediatr_flutter/annotations/command_register_handler.dart';
import 'package:cqrs_mediatr_flutter/annotations/main_mediatr_file.dart';
import 'package:cqrs_mediatr_flutter/annotations/mediatr_init.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_register_handler.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as path;

class MediatrGenerator extends Generator {
  final BuilderOptions options;

  // Constructor'da options'ı alıyoruz
  MediatrGenerator(this.options);
  @override
  Future<String?> generate(LibraryReader library, BuildStep buildStep) async {
    var mainPartFile =
        library
            .annotatedWith(TypeChecker.fromRuntime(MainMediatrFile))
            .firstOrNull;
    if (mainPartFile == null) {
      return null; // MainMediatrFile ile işaretlenmiş değilse atla
    }

    var mainPartFileImportPath = _convertPathToImport(
      uri: _getClassFullPath(mainPartFile)!,
      buildStep: buildStep,
    );

    // Sadece MediatrInit annotasyonu olan kütüphaneleri işle
    if (!library
        .annotatedWith(TypeChecker.fromRuntime(MediatrInit))
        .isNotEmpty) {
      return null; // MediatrInit ile işaretlenmiş değilse atla
    }

    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');

    final commandHandlers = <String>[];
    final queryHandlers = <String>[];
    final imports = <String>{};
    imports.add('import \'$mainPartFileImportPath\';');

    // TypeChecker'ları bir kez oluştur
    final commandHandlerChecker = TypeChecker.fromRuntime(
      CommandRegisterHandler,
    );
    final queryHandlerChecker = TypeChecker.fromRuntime(QueryRegisterHandler);

    await for (var input in buildStep.findAssets(Glob('lib/**/*.dart'))) {
      print('Scanning file: ${input.uri}');

      // Part veya part-of dosyalarını atlamak için içeriği oku
      final sourceText = await buildStep.readAsString(input);

      if (sourceText.contains('part of ') || sourceText.contains('part of;')) {
        print('Skipping ${input.uri} because it appears to be a part file.');
        continue;
      }

      try {
        final resolvedLibrary = await buildStep.resolver.libraryFor(input);
        final libraryReader = LibraryReader(resolvedLibrary);
        print('Resolved library for: ${input.uri}');

        bool hasAnnotations = false;

        // Kütüphanedeki tüm sınıfları kontrol et
        for (var classElement in libraryReader.classes) {
          final className = classElement.name;
          final importPath = input.uri.toString();

          bool isRelevantAnnotation = false;

          // CommandHandler annotasyonu var mı?
          if (commandHandlerChecker.hasAnnotationOf(classElement)) {
            isRelevantAnnotation = true;
            print('Found CommandHandler: $className in $importPath');
            commandHandlers.add(className);
            imports.add('import \'$importPath\';');
          }
          // QueryHandler annotasyonu var mı?
          else if (queryHandlerChecker.hasAnnotationOf(classElement)) {
            isRelevantAnnotation = true;
            print('Found QueryHandler: $className in $importPath');
            imports.add('import \'$importPath\';');

            if (sourceText.contains('IQueryPagedListHandler')) {
            } else if (sourceText.contains('IQueryListHandler')) {
            } else {
              queryHandlers.add(className);
            }
          }

          hasAnnotations = hasAnnotations || isRelevantAnnotation;
        }

        if (!hasAnnotations) {
          print(
            'No relevant annotated classes found in ${input.uri}, skipping file.',
          );
        }
      } catch (e) {
        print(
          'Skipping ${input.uri} as it could not be resolved as a Dart library: $e',
        );
        continue;
      }
    }

    if (commandHandlers.isEmpty && queryHandlers.isEmpty) {
      print('No annotated handlers found in any files.');
      return ''; // Boş dosya oluşturma, hiçbir handler bulunamadı
    }

    // Import ifadelerini ekle
    imports.forEach(buffer.writeln);
    buffer.writeln();

    buffer.write('final Mediator mediator = Mediator(); \n\n');

    // registerCommandHandlers fonksiyonunu oluştur
    buffer.writeln('void registerCommandHandlers() {');
    for (var handler in commandHandlers) {
      buffer.writeln('\tmediator.registerCommandHandler($handler());');
    }
    buffer.writeln('} \n');

    // registerQueryHandlers fonksiyonunu oluştur
    buffer.writeln('void registerQueryHandlers() {');
    for (var handler in queryHandlers) {
      buffer.writeln('\tmediator.registerQueryHandler($handler());');
    }
    buffer.writeln('} \n');

    // registerAllHandlers fonksiyonunu oluştur
    buffer.writeln('void registerAllHandlers() {');
    buffer.writeln('\tregisterCommandHandlers();');
    buffer.writeln('\tregisterQueryHandlers();');
    buffer.writeln('} \n');

    return buffer.toString();
  }

  String _convertPathToImport({
    required Uri uri,
    required BuildStep buildStep,
  }) {
    String importPath;

    // URI'yi import ifadesine dönüştür
    if (uri.scheme == 'package') {
      importPath = uri.toString();
    } else if (uri.scheme == 'file') {
      try {
        final assetId = AssetId.resolve(uri);
        importPath =
            'package:${assetId.package}/${assetId.path.split('lib/').last}';
      } catch (e) {
        // Dönüştürme başarısız olursa, göreceli yol kullan
        final currentPath = buildStep.inputId.path;
        final currentDir = path.dirname(currentPath);
        final filePath = uri.toFilePath();
        importPath = path.relative(filePath, from: currentDir);
        importPath =
            importPath.startsWith('../') ? importPath : './$importPath';
      }
    } else {
      importPath = uri.toString();
    }
    return importPath;
  }

  Uri? _getClassFullPath(AnnotatedElement annotatedElement) {
    final element = annotatedElement.element;
    return element.source?.uri;
  }
}

Builder mediatorInitBuilder(BuilderOptions options) =>
    SharedPartBuilder([MediatrGenerator(options)], 'mediatr_init');
