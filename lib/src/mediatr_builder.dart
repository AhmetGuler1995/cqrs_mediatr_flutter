import 'dart:async';
import 'dart:io';
import 'package:cqrs_mediatr_flutter/annotations/command_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_list_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_paged_list_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/src/mediatr_register_generator.dart';
import 'package:glob/glob.dart';
import 'package:path/path.dart' as path;
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class MediatRGenerator extends Generator {
  final BuilderOptions options;

  MediatRGenerator(this.options);

  @override
  FutureOr<String> generate(LibraryReader library, BuildStep buildStep) async {
    // Generate response models
    final buffer = StringBuffer();

    buffer.writeln('// Generated code - do not modify');
    buffer.writeln('// CQRS MediatR implementation for Flutter');
    buffer.writeln('// Generated on: ${DateTime.now()}\n');

    // Import section
    buffer.writeln("import 'dart:async';");
    await _importGenerating(buffer, library, buildStep);
    await _generateBaseClasses(buffer);
    await _generateMediatR(buffer, library, buildStep);

    return buffer.toString();
  }

  Future _generateBaseClasses(StringBuffer buffer) async {
    buffer.writeln('// Base Command and Query Classes');
    buffer.writeln('abstract class IBaseCommand<TResult> {}');
    buffer.writeln('abstract class IBaseQuery<TResult> {}\n');

    buffer.writeln('// Abstract Main Class');
    buffer.writeln('abstract class IBaseHandler {}\n');

    buffer.writeln('// Command and Query Types');
    buffer.writeln(
      'abstract class ICommand<TResult> extends IBaseCommand<TResult> {}',
    );
    buffer.writeln(
      'abstract class IAsyncCommand extends IBaseCommand<Future> {}',
    );
    buffer.writeln(
      'abstract class IQuery<TResult> extends IBaseQuery<TResult> {}',
    );
    buffer.writeln(
      'abstract class IQueryList<TResult> extends IBaseQuery<TResult> {}',
    );
    buffer.writeln(
      'abstract class IQueryPagedList<TResult> extends IBaseQuery<TResult> {}',
    );
    buffer.writeln(
      'abstract class IAsyncQuery<TResult> extends IBaseCommand<Future<TResult>> {}\n',
    );
  }

  Uri? _getClassFullPath(AnnotatedElement annotatedElement) {
    final element = annotatedElement.element;
    return element.source?.uri;
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

  final Set<String> imports = {};

  Future<void> _importGenerating(
    StringBuffer buffer,
    LibraryReader library,
    BuildStep buildStep,
  ) async {
    final commandResultClass = await getAnnotatedFile(
      buildStep,
      CommandResultPaternModel,
    );
    // Find classes with QueryResultPaternModel annotation
    final queryResultClass = await getAnnotatedFile(
      buildStep,
      QueryResultPaternModel,
    );
    // Find classes with QueryResultPaternModel annotation
    final queryListResultClass = await getAnnotatedFile(
      buildStep,
      QueryListResultPaternModel,
    );
    final queryPagedListResultClass = await getAnnotatedFile(
      buildStep,
      QueryPagedListResultPaternModel,
    );

    // Only process if there are annotated classes
    var commandResultFileImportPath = _convertPathToImport(
      uri: _getClassFullPath(commandResultClass!)!,
      buildStep: buildStep,
    );
    if (!imports.any((e) => e == 'import \'$commandResultFileImportPath\';')) {
      imports.add('import \'$commandResultFileImportPath\';');
    }
    log.info('Command Result Import Content: $commandResultFileImportPath');

    var queryResultFileImportPath = _convertPathToImport(
      uri: _getClassFullPath(queryResultClass!)!,
      buildStep: buildStep,
    );
    if (!imports.any((e) => e == 'import \'$queryResultFileImportPath\';')) {
      imports.add('import \'$queryResultFileImportPath\';');
    }
    log.info('Query Result Import Content: $queryResultFileImportPath');

    var queryListResultFileImportPath = _convertPathToImport(
      uri: _getClassFullPath(queryListResultClass!)!,
      buildStep: buildStep,
    );
    if (!imports.any(
      (e) => e == 'import \'$queryListResultFileImportPath\';',
    )) {
      imports.add('import \'$queryListResultFileImportPath\';');
    }
    log.info(
      'Query List Result Import Content: $queryListResultFileImportPath',
    );

    var queryPagedListResultFileImportPath = _convertPathToImport(
      uri: _getClassFullPath(queryPagedListResultClass!)!,
      buildStep: buildStep,
    );
    if (!imports.any(
      (e) => e == 'import \'$queryPagedListResultFileImportPath\';',
    )) {
      imports.add('import \'$queryPagedListResultFileImportPath\';');
    }
    log.info(
      'Query Paged List Result Import Content: $queryPagedListResultFileImportPath',
    );

    imports.forEach(buffer.writeln);
  }

  Future<AnnotatedElement?> getAnnotatedFile(
    BuildStep buildStep,
    Type annotation,
  ) async {
    final assetIds =
        await buildStep
            .findAssets(Glob('lib/**/*.dart'))
            .where((e) => e.extension != ".g.dart")
            .where((e) => !e.path.endsWith('.freezed.dart'))
            .where((e) => !e.path.endsWith('.g.dart'))
            .toList();
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
          TypeChecker.fromRuntime(annotation),
        );
        if (elements.isEmpty) continue;
        return elements.first;
      } catch (e) {
        continue;
      }
    }
    return null;
  }

  Future<void> _generateMediatR(
    StringBuffer buffer,
    LibraryReader library,
    BuildStep buildStep,
  ) async {
    // Find classes with CommandResultPaternModel annotation
    final commandResultClass = await getAnnotatedFile(
      buildStep,
      CommandResultPaternModel,
    );
    // Find classes with QueryResultPaternModel annotation
    final queryResultClass = await getAnnotatedFile(
      buildStep,
      QueryResultPaternModel,
    );
    // Find classes with QueryResultPaternModel annotation
    final queryListResultClass = await getAnnotatedFile(
      buildStep,
      QueryListResultPaternModel,
    );
    final queryPagedListResultClass = await getAnnotatedFile(
      buildStep,
      QueryPagedListResultPaternModel,
    );

    // Define default class names to use if annotations are not found
    final String? commandResultClassName = commandResultClass?.element.name;
    final String? queryResultClassName = queryResultClass?.element.name;
    final String? queryListResultClassName = queryListResultClass?.element.name;
    final String? queryPagedListResultClassName =
        queryPagedListResultClass?.element.name;

    // Type Definitions
    buffer.writeln('// Type Definitions');
    buffer.writeln(
      'typedef _InstanceFactoryChecker<TResult, Command extends IBaseCommand<TResult>> = _ICommandHandler<Command, TResult> Function();',
    );
    buffer.writeln(
      'typedef _InstanceFactoryCheckerQuery<TResult, Command extends IBaseQuery<TResult>> = _IQueryHandler<Command, TResult> Function();',
    );
    buffer.writeln(
      'typedef _InstanceFactoryCheckerQueryList<TResult, Command extends IQueryList<TResult>> = _IQueryListHandler<Command, TResult> Function();',
    );
    buffer.writeln(
      'typedef _InstanceFactoryCheckerQueryPagedList<TResult, Command extends IQueryPagedList<TResult>> = _IQueryPagedListHandler<Command, TResult> Function();',
    );
    buffer.writeln(
      'typedef InstanceFactory<T extends IBaseHandler> = T Function();\n',
    );

    // Handler Abstract Classes
    buffer.writeln('// Handler Abstract Classes');
    buffer.writeln(
      'abstract class _ICommandHandler<Command extends IBaseCommand<TResult>, TResult> extends IBaseHandler {',
    );
    buffer.writeln(
      '  Future<$commandResultClassName<TResult>> handle(Command command);',
    );
    buffer.writeln('}\n');

    buffer.writeln(
      'abstract class _IQueryHandler<Command extends IBaseQuery<TResult>, TResult> extends IBaseHandler {',
    );
    buffer.writeln(
      '  Future<$queryResultClassName<TResult>> handle(Command query);',
    );
    buffer.writeln('}\n');

    buffer.writeln(
      'abstract class _IQueryListHandler<Command extends IBaseQuery<TResult>, TResult> extends IBaseHandler {',
    );
    buffer.writeln(
      '  Future<$queryListResultClassName<TResult>> handle(Command query);',
    );
    buffer.writeln('}\n');

    buffer.writeln(
      'abstract class _IQueryPagedListHandler<Command extends IBaseQuery<TResult>, TResult> extends IBaseHandler {',
    );
    buffer.writeln(
      '  Future<$queryPagedListResultClassName<TResult>> handle(Command query);',
    );
    buffer.writeln('}\n');

    // Concrete Handler Classes
    buffer.writeln('// Concrete Handler Classes');
    buffer.writeln(
      'abstract class ICommandHandler<Command extends IBaseCommand<TResult>, TResult> extends _ICommandHandler<Command, TResult> {}',
    );
    buffer.writeln(
      'abstract class IAsyncCommandHandler<Command extends IAsyncCommand> extends _ICommandHandler<Command, Future> {}',
    );
    buffer.writeln(
      'abstract class IQueryHandler<Query extends IQuery<TResult>, TResult> extends _IQueryHandler<Query, TResult> {}',
    );
    buffer.writeln(
      'abstract class IQueryListHandler<Query extends IQueryList<TResult>, TResult> extends _IQueryListHandler<Query, TResult> {}',
    );
    buffer.writeln(
      'abstract class IQueryPagedListHandler<Query extends IQueryPagedList<TResult>, TResult> extends _IQueryPagedListHandler<Query, TResult> {}',
    );
    buffer.writeln(
      'abstract class IAsyncQueryHandler<Query extends IAsyncQuery<TResult>, TResult> extends _ICommandHandler<Query, Future<TResult>> {}\n',
    );

    // MediatR Class
    buffer.writeln('// MediatR Main Process Class');
    buffer.writeln('class MediatR {');
    buffer.writeln('  static MediatR? _instance;');
    buffer.writeln('  static MediatR get instance => _instance ??= MediatR();');
    buffer.writeln(
      '  final Set<InstanceFactory<IBaseHandler>> _commands = <InstanceFactory<IBaseHandler>>{};\n',
    );

    // Registration Methods
    buffer.writeln(
      '  void registerCommandHandler<TResult, Command extends IBaseCommand<TResult>, Handler extends _ICommandHandler<Command, TResult>>(',
    );
    buffer.writeln('      InstanceFactory<Handler> handler) {');
    buffer.writeln(
      '    var handlers = _commands.whereType<InstanceFactory<Handler>>();',
    );
    buffer.writeln('    if (handlers.isEmpty) {');
    buffer.writeln('      _commands.add(handler);');
    buffer.writeln('    }');
    buffer.writeln('  }\n');

    buffer.writeln(
      '  void registerQueryHandler<TResult, Command extends IBaseQuery<TResult>, Handler extends _IQueryHandler<Command, TResult>>(',
    );
    buffer.writeln('      InstanceFactory<Handler> handler) {');
    buffer.writeln(
      '    var handlers = _commands.whereType<InstanceFactory<Handler>>();',
    );
    buffer.writeln('    if (handlers.isEmpty) {');
    buffer.writeln('      _commands.add(handler);');
    buffer.writeln('    }');
    buffer.writeln('  }\n');

    buffer.writeln(
      '  void registerQueryListHandler<TResult, Command extends IBaseQuery<TResult>, Handler extends _IQueryListHandler<Command, TResult>>(',
    );
    buffer.writeln('      InstanceFactory<Handler> handler) {');
    buffer.writeln(
      '    var handlers = _commands.whereType<InstanceFactory<Handler>>();',
    );
    buffer.writeln('    if (handlers.isEmpty) {');
    buffer.writeln('      _commands.add(handler);');
    buffer.writeln('    }');
    buffer.writeln('  }\n');

    buffer.writeln(
      '  void registerQueryPagedListHandler<TResult, Command extends IBaseQuery<TResult>, Handler extends _IQueryPagedListHandler<Command, TResult>>(',
    );
    buffer.writeln('      InstanceFactory<Handler> handler) {');
    buffer.writeln(
      '    var handlers = _commands.whereType<InstanceFactory<Handler>>();',
    );
    buffer.writeln('    if (handlers.isEmpty) {');
    buffer.writeln('      _commands.add(handler);');
    buffer.writeln('    }');
    buffer.writeln('  }\n');

    // Execution Methods
    buffer.writeln(
      '  Future<$queryResultClassName<TResult>> query<Query extends IQuery<TResult>, TResult>(Query query) {',
    );
    buffer.writeln('    var handlers = _commands');
    buffer.writeln(
      '        .whereType<InstanceFactory<_IQueryHandler<Query, TResult>>>()',
    );
    buffer.writeln(
      '        .cast<_InstanceFactoryCheckerQuery<TResult, Query>>();',
    );
    buffer.writeln('    if (handlers.isEmpty) {');
    buffer.writeln('      throw Exception(');
    buffer.writeln(
      '        "You must register query handler for \${query.runtimeType} before calling this function",',
    );
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('    return handlers.first.call().handle(query);');
    buffer.writeln('  }\n');

    buffer.writeln(
      '  Future<$queryListResultClassName<TResult>> queryList<Query extends IQueryList<TResult>, TResult>(Query query) {',
    );
    buffer.writeln('    var handlers = _commands');
    buffer.writeln(
      '        .whereType<InstanceFactory<_IQueryListHandler<Query, TResult>>>()',
    );
    buffer.writeln(
      '        .cast<_InstanceFactoryCheckerQueryList<TResult, Query>>();',
    );
    buffer.writeln('    if (handlers.isEmpty) {');
    buffer.writeln('      throw Exception(');
    buffer.writeln(
      '        "You must register query handler for \${query.runtimeType} before calling this function",',
    );
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('    return handlers.first.call().handle(query);');
    buffer.writeln('  }\n');

    buffer.writeln(
      '  Future<$queryPagedListResultClassName<TResult>> queryPagedList<Query extends IQueryPagedList<TResult>, TResult>(Query query) {',
    );
    buffer.writeln('    var handlers = _commands');
    buffer.writeln(
      '        .whereType<InstanceFactory<_IQueryPagedListHandler<Query, TResult>>>()',
    );
    buffer.writeln(
      '        .cast<_InstanceFactoryCheckerQueryPagedList<TResult, Query>>();',
    );
    buffer.writeln('    if (handlers.isEmpty) {');
    buffer.writeln('      throw Exception(');
    buffer.writeln(
      '        "You must register query handler for \${query.runtimeType} before calling this function",',
    );
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('    return handlers.first.call().handle(query);');
    buffer.writeln('  }\n');

    buffer.writeln(
      '  Future<$commandResultClassName<TResult>> command<Command extends ICommand<TResult>, TResult>(Command query) async {',
    );
    buffer.writeln('    var handlers = _commands');
    buffer.writeln(
      '        .whereType<InstanceFactory<_ICommandHandler<Command, TResult>>>()',
    );
    buffer.writeln(
      '        .cast<_InstanceFactoryChecker<TResult, Command>>();',
    );
    buffer.writeln('    if (handlers.isEmpty) {');
    buffer.writeln('      throw Exception(');
    buffer.writeln(
      '        "You must register query handler for \${query.runtimeType} before calling this function",',
    );
    buffer.writeln('      );');
    buffer.writeln('    }');
    buffer.writeln('    return await handlers.first.call().handle(query);');
    buffer.writeln('  }\n');

    // Utility Methods
    buffer.writeln('  void clearHandlers() {');
    buffer.writeln('    _commands.clear();');
    buffer.writeln('  }\n');

    buffer.writeln('  void removeHandlers<T extends IBaseHandler>() {');
    buffer.writeln(
      '    _commands.removeWhere((element) => element is InstanceFactory<T>);',
    );
    buffer.writeln('  }\n');

    buffer.writeln(
      '  void removeHandler<T extends IBaseHandler>(InstanceFactory<T> handler) {',
    );
    buffer.writeln('    _commands.remove(handler);');
    buffer.writeln('  }\n');

    buffer.writeln(
      '  Iterable<InstanceFactory<T>> getHandler<T extends IBaseHandler>() {',
    );
    buffer.writeln('    return _commands.whereType<InstanceFactory<T>>();');
    buffer.writeln('  }\n');

    buffer.writeln(
      '  Iterable<_InstanceFactoryChecker<TResult, Command>> getHandlersFor<TResult, Command extends IBaseCommand<TResult>>(Command command) {',
    );
    buffer.writeln(
      '    return _commands.whereType<_InstanceFactoryChecker<TResult, Command>>();',
    );
    buffer.writeln('  }');
    buffer.writeln('}');
  }
}

// Builder
class MediatRBuilder implements Builder {
  final BuilderOptions options;
  const MediatRBuilder(this.options);
  @override
  Map<String, List<String>> get buildExtensions => {
    '.dart': ['.mediatr.dart'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    await mediatrMainGenerator(buildStep);
    await mediatrRegisterGenerator(buildStep);
  }

  Future<void> mediatrMainGenerator(BuildStep buildStep) async {
    var optionExportPath =
        options.config.isNotEmpty ? options.config['generate_path'] : null;
    if (optionExportPath == null) return;
    final outputPath = path.join('lib', optionExportPath, 'mediatr.dart');

    final generator = MediatRGenerator(options);
    var pathFile = buildStep.inputId.path;
    if (pathFile.contains('.g.dart') || pathFile.contains('.freezed.dart')) {
      return;
    }
    final library = LibraryReader(await buildStep.inputLibrary);
    final generatedCode = await generator.generate(library, buildStep);

    final outputFile = File(outputPath);
    if (!await outputFile.exists()) {
      await outputFile.create(recursive: true);
    }

    await outputFile.writeAsString(generatedCode);
  }

  Future<void> mediatrRegisterGenerator(BuildStep buildStep) async {
    var optionExportPath =
        options.config.isNotEmpty ? options.config['generate_path'] : null;

    if (optionExportPath == null) return;

    final outputPath =
        optionExportPath = path.join(
          'lib',
          optionExportPath,
          'mediatr_register.dart',
        );
    var pathFile = buildStep.inputId.path;
    if (pathFile.contains('.g.dart') || pathFile.contains('.freezed.dart')) {
      return;
    }
    final generator = MediatrRegisterGenerator(options);
    final library = LibraryReader(await buildStep.inputLibrary);
    final generatedCode = await generator.generate(library, buildStep);

    final outputFile = File(outputPath);
    if (!await outputFile.exists()) {
      await outputFile.create(recursive: true);
    }

    await outputFile.writeAsString(generatedCode);
  }
}

// Builder factory
Builder mediatrBuilder(BuilderOptions options) => MediatRBuilder(options);
