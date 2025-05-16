import 'dart:async';

import 'package:build/build.dart';
import 'package:cqrs_mediatr_flutter/annotations/command_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/annotations/main_mediatr_file.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_list_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_paged_list_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_result_patern_model.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:path/path.dart' as path;

class MediatrCreator extends Generator {
  final BuilderOptions options;

  MediatrCreator(this.options);

  @override
  Future<String?> generate(LibraryReader library, BuildStep buildStep) async {
    if (!library
        .annotatedWith(TypeChecker.fromRuntime(MainMediatrFile))
        .isNotEmpty) {
      return null; // MainMediatrFile ile işaretlenmiş değilse atla
    }

    // var mainPartFile =
    //     library
    //         .annotatedWith(TypeChecker.fromRuntime(MainMediatrFile))
    //         .firstOrNull;

    // var partSourceName =
    //     'part of \'${mainPartFile?.element.source?.shortName}\'';

    final assetIds = await buildStep.findAssets(Glob('lib/**/*.dart')).toList();

    AnnotatedElement? commandResultFile = await _getCommandAnnotatedElement(
      assetIds,
      buildStep,
    );

    if (commandResultFile == null) {
      return null; // CommandResultPaternModel ile işaretlenmiş değilse atla
    }
    log.info('Command Result File Name: ${commandResultFile.element.name}');

    AnnotatedElement? queryListResultFile = await _getQueryListAnnotatedElement(
      assetIds,
      buildStep,
    );

    if (queryListResultFile == null) {
      return null; // QueryListResultPaternModel ile işaretlenmiş değilse atla
    }

    log.info(
      'Query List Result File Name: ${queryListResultFile.element.name}',
    );

    var queryResultFile = await _getQueryAnnotatedElement(assetIds, buildStep);

    if (queryResultFile == null) {
      return null;
    }
    log.info('Query Result File Name: ${queryResultFile.element.name}');
    var queryPagedResultFile = await _getQueryPagedListAnnotatedElement(
      assetIds,
      buildStep,
    );

    if (queryPagedResultFile == null) {
      return null; // QueryPagedListResultPaternModel ile işaretlenmiş değilse atla
    }
    List<String> imports = <String>[];

    log.info('Query Paged Result File Name: ${queryResultFile.element.name}');

    var commandResultFileImportPath = _convertPathToImport(
      uri: _getClassFullPath(commandResultFile)!,
      buildStep: buildStep,
    );
    if (!imports.any((e) => e == 'import \'$commandResultFileImportPath\';')) {
      imports.add('import \'$commandResultFileImportPath\';');
    }

    log.info('Command Result Import Content: $commandResultFileImportPath');

    var queryResultFileImportPath = _convertPathToImport(
      uri: _getClassFullPath(queryResultFile)!,
      buildStep: buildStep,
    );
    if (!imports.any((e) => e == 'import \'$queryResultFileImportPath\';')) {
      imports.add('import \'$queryResultFileImportPath\';');
    }

    log.info('Query Result Import Content: $queryResultFileImportPath');

    var queryListResultFileImportPath = _convertPathToImport(
      uri: _getClassFullPath(queryListResultFile)!,
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
      uri: _getClassFullPath(queryPagedResultFile)!,
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

    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');

    imports.forEach(buffer.writeln);

    buffer.writeln('abstract class IBaseCommand<TResult> {}');

    buffer.writeln('abstract class IBaseQuery<TResult> {}');

    buffer.writeln('// Abstract Main Class Generated');

    buffer.writeln('abstract class IBaseHandler {}');

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
      'abstract class IAsyncQuery<TResult> extends IBaseCommand<Future<TResult>> {}',
    );

    buffer.writeln('// Type Defination Region');

    buffer.writeln(
      'typedef _InstanceFactoryChecker<TResult,Command extends IBaseCommand<TResult>> = _ICommandHandler<Command, TResult> Function();',
    );

    buffer.writeln(
      'typedef _InstanceFactoryCheckerQuery<TResult,Command extends IBaseQuery<TResult>> = _IQueryHandler<Command, TResult> Function();',
    );

    buffer.writeln(
      'typedef _InstanceFactoryCheckerQueryList<TResult,Command extends IQueryList<TResult>> = _IQueryListHandler<Command, TResult> Function();',
    );

    buffer.writeln(
      'typedef _InstanceFactoryCheckerQueryPagedList<TResult,Command extends IQueryPagedList<TResult>> = _IQueryPagedListHandler<Command, TResult> Function();',
    );

    buffer.writeln(
      'typedef InstanceFactory<T extends IBaseHandler> = T Function();',
    );

    buffer.writeln(
      '// Handler Abstract Class Type Defination And Abstract Handle Method Generation.',
    );

    buffer
      ..writeln(
        'abstract class _ICommandHandler<Command extends IBaseCommand<TResult>, TResult>',
      )
      ..writeln('    extends IBaseHandler {')
      ..writeln(
        'Future<${commandResultFile.element.name}<TResult>> handle(Command command);',
      )
      ..writeln('}');

    buffer
      ..writeln(
        'abstract class _IQueryHandler<Command extends IBaseQuery<TResult>, TResult>',
      )
      ..writeln('extends IBaseHandler {')
      ..writeln(
        'Future<${queryResultFile.element.name}<TResult>> handle(Command query);',
      )
      ..writeln('}');

    buffer
      ..writeln(
        'abstract class _IQueryListHandler<Command extends IBaseQuery<TResult>, TResult>',
      )
      ..writeln('extends IBaseHandler {')
      ..writeln(
        'Future<${queryListResultFile.element.name}<TResult>> handle(Command query);',
      )
      ..writeln('}');

    buffer
      ..writeln(
        'abstract class _IQueryPagedListHandler<Command extends IBaseQuery<TResult>, TResult>',
      )
      ..writeln('extends IBaseHandler {')
      ..writeln(
        'Future<${queryPagedResultFile.element.name}<TResult>> handle(Command query);',
      )
      ..writeln('}');

    buffer
      ..writeln(
        'abstract class ICommandHandler<Command extends IBaseCommand<TResult>, TResult>',
      )
      ..writeln('    extends _ICommandHandler<Command, TResult> {}');
    buffer
      ..writeln(
        'abstract class IAsyncCommandHandler<Command extends IAsyncCommand>',
      )
      ..writeln('    extends _ICommandHandler<Command, Future> {}');

    buffer
      ..writeln(
        'abstract class IQueryHandler<Query extends IQuery<TResult>, TResult>',
      )
      ..writeln('    extends _IQueryHandler<Query, TResult> {}');

    buffer
      ..writeln(
        'abstract class IQueryListHandler<Query extends IQueryList<TResult>, TResult>',
      )
      ..writeln('    extends _IQueryListHandler<Query, TResult> {}');

    buffer
      ..writeln(
        'abstract class IQueryPagedListHandler<Query extends IQueryPagedList<TResult>, TResult>',
      )
      ..writeln('    extends _IQueryPagedListHandler<Query, TResult> {}');

    buffer
      ..writeln(
        'abstract class IAsyncQueryHandler<Query extends IAsyncQuery<TResult>, TResult>',
      )
      ..writeln('extends _ICommandHandler<Query, Future<TResult>> {}');

    buffer.writeln('// Mediatr Main Process Class Generation...');

    buffer
      ..writeln('class MediatR {')
      ..writeln('static MediatR? _instance;')
      ..writeln('static MediatR get instance => _instance ??= MediatR();')
      ..writeln('final Set<InstanceFactory<IBaseHandler>> _commands =')
      ..writeln('<InstanceFactory<IBaseHandler>>{};')
      ..writeln('')
      ..writeln(
        'void registerCommandHandler<TResult,Command extends IBaseCommand<TResult>,Handler extends _ICommandHandler<Command, TResult>>(InstanceFactory<Handler> handler) {',
      )
      ..writeln(
        'var handlers = _commands.whereType<InstanceFactory<Handler>>();',
      )
      ..writeln('if (handlers.isEmpty) {')
      ..writeln('_commands.add(handler);')
      ..writeln('}')
      ..writeln('}')
      ..writeln('')
      ..writeln(
        'void registerQueryHandler<TResult,Command extends IBaseQuery<TResult>,Handler extends _IQueryHandler<Command, TResult>>(InstanceFactory<Handler> handler) {',
      )
      ..writeln(
        'var handlers = _commands.whereType<InstanceFactory<Handler>>();',
      )
      ..writeln('if (handlers.isEmpty) {')
      ..writeln('_commands.add(handler);')
      ..writeln('}')
      ..writeln('}')
      ..writeln('')
      ..writeln(
        'void registerQueryListHandler<TResult,Command extends IBaseQuery<TResult>,Handler extends _IQueryListHandler<Command, TResult>>(InstanceFactory<Handler> handler) {',
      )
      ..writeln(
        'var handlers = _commands.whereType<InstanceFactory<Handler>>();',
      )
      ..writeln('if (handlers.isEmpty) {')
      ..writeln('_commands.add(handler);')
      ..writeln('}')
      ..writeln('}')
      ..writeln('')
      ..writeln(
        'void registerQueryPagedListHandler<TResult,Command extends IBaseQuery<TResult>,Handler extends _IQueryPagedListHandler<Command, TResult>>(InstanceFactory<Handler> handler) {',
      )
      ..writeln(
        'var handlers = _commands.whereType<InstanceFactory<Handler>>();',
      )
      ..writeln('if (handlers.isEmpty) {')
      ..writeln('_commands.add(handler);')
      ..writeln('}')
      ..writeln('}')
      ..writeln('')
      ..writeln('Future<${queryResultFile.element.name}<TResult>>')
      ..writeln('query<Query extends IQuery<TResult>, TResult>(Query query) {')
      ..writeln('var handlers =')
      ..writeln(' _commands')
      ..writeln(
        ' .whereType<InstanceFactory<_IQueryHandler<Query, TResult>>>()',
      )
      ..writeln(' .cast<_InstanceFactoryCheckerQuery<TResult, Query>>();')
      ..writeln('if (handlers.isEmpty) {')
      ..writeln('throw Exception(')
      ..writeln(
        '"You must register query handler for \${query.runtimeType} before calling this function",',
      )
      ..writeln(');')
      ..writeln(' }')
      ..writeln(' return handlers.first.call().handle(query);')
      ..writeln('}')
      ..writeln('')
      ..writeln(' Future<${queryListResultFile.element.name}<TResult>>')
      ..writeln(
        'queryList<Query extends IQueryList<TResult>, TResult>(Query query) {',
      )
      ..writeln('var handlers =')
      ..writeln(' _commands')
      ..writeln(
        ' .whereType<InstanceFactory<_IQueryListHandler<Query, TResult>>>()',
      )
      ..writeln('.cast<_InstanceFactoryCheckerQueryList<TResult, Query>>();')
      ..writeln('if (handlers.isEmpty) {')
      ..writeln('throw Exception(')
      ..writeln(
        '"You must register query handler for \${query.runtimeType} before calling this function",',
      )
      ..writeln(');')
      ..writeln('}')
      ..writeln('return handlers.first.call().handle(query);')
      ..writeln('}')
      ..writeln('')
      ..writeln('Future<${queryPagedResultFile.element.name}<TResult>>')
      ..writeln(
        'queryPagedList<Query extends IQueryPagedList<TResult>, TResult>(Query query) {',
      )
      ..writeln('var handlers =')
      ..writeln(
        ' _commands.whereType<InstanceFactory<_IQueryPagedListHandler<Query, TResult>>>().cast<_InstanceFactoryCheckerQueryPagedList<TResult, Query>>();',
      )
      ..writeln('if (handlers.isEmpty) {')
      ..writeln('throw Exception(')
      ..writeln(
        '"You must register query handler for \${query.runtimeType} before calling this function"',
      )
      ..writeln(');')
      ..writeln('}')
      ..writeln('return handlers.first.call().handle(query);')
      ..writeln('}')
      ..writeln('')
      ..writeln('Future<${commandResultFile.element.name}<TResult>>')
      ..writeln(
        'command<Command extends ICommand<TResult>, TResult>(Command query) async {',
      )
      ..writeln(' var handlers =')
      ..writeln(
        ' _commands.whereType<InstanceFactory<_ICommandHandler<Command, TResult>>>().cast<_InstanceFactoryChecker<TResult, Command>>();',
      )
      ..writeln(' if (handlers.isEmpty) {')
      ..writeln('throw Exception(')
      ..writeln(
        '"You must register query handler for \${query.runtimeType} before calling this function",',
      )
      ..writeln(');')
      ..writeln('}')
      ..writeln('return await handlers.first.call().handle(query);')
      ..writeln('}')
      ..writeln('')
      ..writeln('void clearHandlers() {')
      ..writeln('_commands.clear();')
      ..writeln('}')
      ..writeln('')
      ..writeln('void removeHandlers<T extends IBaseHandler>() {')
      ..writeln(
        ' _commands.removeWhere((element) => element is InstanceFactory<T>);',
      )
      ..writeln('}')
      ..writeln(
        'void removeHandler<T extends IBaseHandler>(InstanceFactory<T> handler) {',
      )
      ..writeln('_commands.remove(handler);')
      ..writeln('}')
      ..writeln('')
      ..writeln(
        'Iterable<InstanceFactory<T>> getHandler<T extends IBaseHandler>() {',
      )
      ..writeln('return _commands.whereType<InstanceFactory<T>>();')
      ..writeln('}')
      ..writeln('')
      ..writeln(
        'Iterable<_InstanceFactoryChecker<TResult, Command>> getHandlersFor<',
      )
      ..writeln(
        'TResult,Command extends IBaseCommand<TResult>>(Command command) {return _commands.whereType<_InstanceFactoryChecker<TResult, Command>>();}',
      )
      ..writeln('')
      ..writeln('}');
    log.info('complate main class');
    return buffer.toString();
  }

  Future<AnnotatedElement?> _getCommandAnnotatedElement(
    List<AssetId> assetIds,
    BuildStep buildStep,
  ) async {
    AnnotatedElement? commandResultFile;
    String? sourcePath;
    for (var assetId in assetIds) {
      try {
        final otherLibrary = await buildStep.resolver.libraryFor(assetId);
        final otherLibraryReader = LibraryReader(otherLibrary);

        // Bu dosyada CommandResultPaternModel annotation'ı var mı?
        final elements = otherLibraryReader.annotatedWith(
          TypeChecker.fromRuntime(CommandResultPaternModel),
        );

        if (elements.isNotEmpty) {
          commandResultFile = elements.first;
          final element = commandResultFile.element;
          final source = element.source;
          sourcePath = source?.fullName ?? assetId.path;

          log.info('Found CommandResultPaternModel in file: $sourcePath');
          break; // İlk bulduğumuzda döngüden çık
        }
      } catch (e) {
        log.severe('Error analyzing file ${assetId.path}: $e');
      }
    }
    return commandResultFile;
  }

  Future<AnnotatedElement?> _getQueryAnnotatedElement(
    List<AssetId> assetIds,
    BuildStep buildStep,
  ) async {
    AnnotatedElement? commandResultFile;
    String? sourcePath;
    for (var assetId in assetIds) {
      try {
        final otherLibrary = await buildStep.resolver.libraryFor(assetId);
        final otherLibraryReader = LibraryReader(otherLibrary);

        // Bu dosyada CommandResultPaternModel annotation'ı var mı?
        final elements = otherLibraryReader.annotatedWith(
          TypeChecker.fromRuntime(QueryResultPaternModel),
        );

        if (elements.isNotEmpty) {
          commandResultFile = elements.first;
          final element = commandResultFile.element;
          final source = element.source;
          sourcePath = source?.fullName ?? assetId.path;

          log.info('Found CommandResultPaternModel in file: $sourcePath');
          break; // İlk bulduğumuzda döngüden çık
        }
      } catch (e) {
        log.severe('Error analyzing file ${assetId.path}: $e');
      }
    }
    return commandResultFile;
  }

  Future<AnnotatedElement?> _getQueryListAnnotatedElement(
    List<AssetId> assetIds,
    BuildStep buildStep,
  ) async {
    AnnotatedElement? commandResultFile;
    String? sourcePath;
    for (var assetId in assetIds) {
      try {
        final otherLibrary = await buildStep.resolver.libraryFor(assetId);
        final otherLibraryReader = LibraryReader(otherLibrary);

        // Bu dosyada CommandResultPaternModel annotation'ı var mı?
        final elements = otherLibraryReader.annotatedWith(
          TypeChecker.fromRuntime(QueryListResultPaternModel),
        );

        if (elements.isNotEmpty) {
          commandResultFile = elements.first;
          final element = commandResultFile.element;
          final source = element.source;
          sourcePath = source?.fullName ?? assetId.path;

          log.info('Found CommandResultPaternModel in file: $sourcePath');
          break; // İlk bulduğumuzda döngüden çık
        }
      } catch (e) {
        log.severe('Error analyzing file ${assetId.path}: $e');
      }
    }
    return commandResultFile;
  }

  Future<AnnotatedElement?> _getQueryPagedListAnnotatedElement(
    List<AssetId> assetIds,
    BuildStep buildStep,
  ) async {
    AnnotatedElement? commandResultFile;
    String? sourcePath;
    for (var assetId in assetIds) {
      try {
        final otherLibrary = await buildStep.resolver.libraryFor(assetId);
        final otherLibraryReader = LibraryReader(otherLibrary);

        // Bu dosyada CommandResultPaternModel annotation'ı var mı?
        final elements = otherLibraryReader.annotatedWith(
          TypeChecker.fromRuntime(QueryPagedListResultPaternModel),
        );

        if (elements.isNotEmpty) {
          commandResultFile = elements.first;
          final element = commandResultFile.element;
          final source = element.source;
          sourcePath = source?.fullName ?? assetId.path;

          log.info('Found CommandResultPaternModel in file: $sourcePath');
          break; // İlk bulduğumuzda döngüden çık
        }
      } catch (e) {
        log.severe('Error analyzing file ${assetId.path}: $e');
      }
    }
    return commandResultFile;
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

Builder mediatorCreateBuilder(BuilderOptions options) {
  final extension =
      options.config['extension'] as String? ?? '.mediatr_create.dart';

  return LibraryBuilder(MediatrCreator(options), generatedExtension: extension);
}
