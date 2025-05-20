import 'package:build/build.dart';
import 'package:cqrs_mediatr_flutter/annotations/command_register_handler.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_register_handler.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as path;

class MediatrRegisterGenerator extends Generator {
  final BuilderOptions options;
  MediatrRegisterGenerator(this.options);

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    final assetIds = await buildStep.findAssets(Glob('lib/**/*.dart')).toList();
    final buffer = StringBuffer();
    buffer.writeln('');
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('');
    List<AnnotatedElement?>? commandResultFile =
        await _getCommandRegisterAnnotatedElements(assetIds, buildStep);

    if (commandResultFile?.isNotEmpty ?? false) {
      List<String> importsCommand = <String>[];
      for (var element in commandResultFile ?? <AnnotatedElement>[]) {
        if (element == null) {
          continue;
        }
        var commandImportPath = _convertPathToImport(
          uri: _getClassFullPath(element)!,
          buildStep: buildStep,
        );
        importsCommand.add('import \'$commandImportPath\';');
      }

      buffer.writeln('// Command Handlers Referances');
      importsCommand.forEach(buffer.writeln);
    }

    List<AnnotatedElement?>? queryResultFile =
        await _getQueryRegisterAnnotatedElements(assetIds, buildStep);

    if (queryResultFile?.isNotEmpty ?? false) {
      List<String> importsQuery = <String>[];
      for (var element in commandResultFile ?? <AnnotatedElement>[]) {
        if (element == null) {
          continue;
        }
        var commandImportPath = _convertPathToImport(
          uri: _getClassFullPath(element)!,
          buildStep: buildStep,
        );
        importsQuery.add('import \'$commandImportPath\';');
      }

      buffer.writeln('// Query Handlers Referances');

      importsQuery.forEach(buffer.writeln);
    }

    final commandHandlers = <String>[];
    final queryHandlers = <String>[];
    final queryListHandlers = <String>[];
    final queryPagedListHandlers = <String>[];
    final imports = <String>{};
    final uri = library.element.source.uri;
    final packageName = uri.isScheme('package') ? uri.pathSegments.first : null;
    var optionExportPath =
        options.config.isNotEmpty ? options.config['generate_path'] : null;
    final outputPath =
        optionExportPath == null
            ? 'generated/mediatr.dart'
            : optionExportPath + '/mediatr.dart';
    imports.add('import \'package:${packageName}/${outputPath}\';');

    // TypeChecker'ları bir kez oluştur
    final commandHandlerChecker = TypeChecker.fromRuntime(
      CommandRegisterHandler,
    );
    final queryHandlerChecker = TypeChecker.fromRuntime(QueryRegisterHandler);

    await for (var input in buildStep.findAssets(Glob('lib/**/*.dart'))) {
      final sourceText = await buildStep.readAsString(input);

      if (sourceText.contains('part of ') || sourceText.contains('part of;')) {
        continue;
      }

      try {
        final resolvedLibrary = await buildStep.resolver.libraryFor(input);
        final libraryReader = LibraryReader(resolvedLibrary);

        bool hasAnnotations = false;

        // Kütüphanedeki tüm sınıfları kontrol et
        for (var classElement in libraryReader.classes) {
          final className = classElement.name;
          final importPath = input.uri.toString();

          bool isRelevantAnnotation = false;

          // CommandHandler annotasyonu var mı?
          if (commandHandlerChecker.hasAnnotationOf(classElement)) {
            isRelevantAnnotation = true;
            commandHandlers.add(className);
            imports.add('import \'$importPath\';');
          }
          // QueryHandler annotasyonu var mı?
          else if (queryHandlerChecker.hasAnnotationOf(classElement)) {
            isRelevantAnnotation = true;
            imports.add('import \'$importPath\';');

            if (sourceText.contains('IQueryPagedListHandler')) {
              queryPagedListHandlers.add(className);
            } else if (sourceText.contains('IQueryListHandler')) {
              queryListHandlers.add(className);
            } else {
              queryHandlers.add(className);
            }
          }

          hasAnnotations = hasAnnotations || isRelevantAnnotation;
        }
      } catch (e) {
        log.severe(
          'Skipping ${input.uri} as it could not be resolved as a Dart library: $e',
        );
        continue;
      }
    }

    if (commandHandlers.isEmpty &&
        queryHandlers.isEmpty &&
        queryPagedListHandlers.isEmpty &&
        queryListHandlers.isEmpty) {
      log.severe('No annotated handlers found in any files.');
      return '';
    }

    // Import ifadelerini ekle
    imports.forEach(buffer.writeln);
    buffer.writeln('class MediatrRegister {\n');

    buffer.writeln();

    // registerCommandHandlers fonksiyonunu oluştur
    buffer.writeln('void registerCommandHandlers() {');
    for (var handler in commandHandlers) {
      buffer.writeln(
        '\tMediatR.instance.registerCommandHandler(() => ${handler}());',
      );
    }
    buffer.writeln('} \n');

    // registerQueryHandlers fonksiyonunu oluştur
    buffer.writeln('void registerQueryHandlers() {');
    for (var handler in queryHandlers) {
      buffer.writeln(
        '\tMediatR.instance.registerQueryHandler(() => ${handler}());',
      );
    }
    buffer.writeln('} \n');

    buffer.writeln('void registerQueryListHandlers() {');
    for (var handler in queryListHandlers) {
      buffer.writeln(
        '\tMediatR.instance.registerQueryListHandler(() => ${handler}());',
      );
    }
    buffer.writeln('} \n');
    buffer.writeln('void registerQueryPagedListHandlers() {');
    for (var handler in queryPagedListHandlers) {
      buffer.writeln(
        '\tMediatR.instance.registerQueryPagedListHandler(() => ${handler}());',
      );
    }
    buffer.writeln('} \n');
    // registerAllHandlers fonksiyonunu oluştur
    buffer.writeln('void registerAllHandlers() {');
    buffer.writeln('\tregisterCommandHandlers();');
    buffer.writeln('\tregisterQueryHandlers();');
    buffer.writeln('\tregisterQueryListHandlers();');
    buffer.writeln('\tregisterQueryPagedListHandlers();');
    buffer.writeln('} \n');
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

  Future<List<AnnotatedElement?>?> _getCommandRegisterAnnotatedElements(
    List<AssetId> assetIds,
    BuildStep buildStep,
  ) async {
    List<AnnotatedElement?> commandResultFiles = <AnnotatedElement?>[];
    for (var assetId in assetIds) {
      final sourceText = await buildStep.readAsString(assetId);

      if (sourceText.contains('part of ') || sourceText.contains('part of;')) {
        continue;
      }
      try {
        final otherLibrary = await buildStep.resolver.libraryFor(assetId);
        final otherLibraryReader = LibraryReader(otherLibrary);

        // Bu dosyada CommandResultPaternModel annotation'ı var mı?
        final elements = otherLibraryReader.annotatedWith(
          TypeChecker.fromRuntime(CommandRegisterHandler),
        );
        commandResultFiles.addAll(elements);
        break;
      } catch (e) {
        continue;
      }
    }
    return commandResultFiles;
  }

  Future<List<AnnotatedElement?>?> _getQueryRegisterAnnotatedElements(
    List<AssetId> assetIds,
    BuildStep buildStep,
  ) async {
    List<AnnotatedElement?> commandResultFiles = <AnnotatedElement?>[];
    for (var assetId in assetIds) {
      try {
        final sourceText = await buildStep.readAsString(assetId);

        if (sourceText.contains('part of ') ||
            sourceText.contains('part of;')) {
          continue;
        }
        final otherLibrary = await buildStep.resolver.libraryFor(assetId);
        final otherLibraryReader = LibraryReader(otherLibrary);

        final elements = otherLibraryReader.annotatedWith(
          TypeChecker.fromRuntime(QueryRegisterHandler),
        );

        commandResultFiles.addAll(elements);
      } catch (e) {
        continue;
      }
    }
    return commandResultFiles;
  }
}
