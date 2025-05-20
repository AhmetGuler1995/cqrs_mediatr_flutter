// Generated code - do not modify
// CQRS MediatR implementation for Flutter
// Generated on: 2025-05-20 16:38:47.514020

import 'dart:async';
import 'package:cqrs_mediatr_flutter/example/generic_result/result.dart';

// Base Command and Query Classes
abstract class IBaseCommand<TResult> {}

abstract class IBaseQuery<TResult> {}

// Abstract Main Class
abstract class IBaseHandler {}

// Command and Query Types
abstract class ICommand<TResult> extends IBaseCommand<TResult> {}

abstract class IAsyncCommand extends IBaseCommand<Future> {}

abstract class IQuery<TResult> extends IBaseQuery<TResult> {}

abstract class IQueryList<TResult> extends IBaseQuery<TResult> {}

abstract class IQueryPagedList<TResult> extends IBaseQuery<TResult> {}

abstract class IAsyncQuery<TResult> extends IBaseCommand<Future<TResult>> {}

// Type Definitions
typedef _InstanceFactoryChecker<
  TResult,
  Command extends IBaseCommand<TResult>
> = _ICommandHandler<Command, TResult> Function();
typedef _InstanceFactoryCheckerQuery<
  TResult,
  Command extends IBaseQuery<TResult>
> = _IQueryHandler<Command, TResult> Function();
typedef _InstanceFactoryCheckerQueryList<
  TResult,
  Command extends IQueryList<TResult>
> = _IQueryListHandler<Command, TResult> Function();
typedef _InstanceFactoryCheckerQueryPagedList<
  TResult,
  Command extends IQueryPagedList<TResult>
> = _IQueryPagedListHandler<Command, TResult> Function();
typedef InstanceFactory<T extends IBaseHandler> = T Function();

// Handler Abstract Classes
abstract class _ICommandHandler<Command extends IBaseCommand<TResult>, TResult>
    extends IBaseHandler {
  Future<Result<TResult>> handle(Command command);
}

abstract class _IQueryHandler<Command extends IBaseQuery<TResult>, TResult>
    extends IBaseHandler {
  Future<Result<TResult>> handle(Command query);
}

abstract class _IQueryListHandler<Command extends IBaseQuery<TResult>, TResult>
    extends IBaseHandler {
  Future<Result<TResult>> handle(Command query);
}

abstract class _IQueryPagedListHandler<
  Command extends IBaseQuery<TResult>,
  TResult
>
    extends IBaseHandler {
  Future<Result<TResult>> handle(Command query);
}

// Concrete Handler Classes
abstract class ICommandHandler<Command extends IBaseCommand<TResult>, TResult>
    extends _ICommandHandler<Command, TResult> {}

abstract class IAsyncCommandHandler<Command extends IAsyncCommand>
    extends _ICommandHandler<Command, Future> {}

abstract class IQueryHandler<Query extends IQuery<TResult>, TResult>
    extends _IQueryHandler<Query, TResult> {}

abstract class IQueryListHandler<Query extends IQueryList<TResult>, TResult>
    extends _IQueryListHandler<Query, TResult> {}

abstract class IQueryPagedListHandler<
  Query extends IQueryPagedList<TResult>,
  TResult
>
    extends _IQueryPagedListHandler<Query, TResult> {}

abstract class IAsyncQueryHandler<Query extends IAsyncQuery<TResult>, TResult>
    extends _ICommandHandler<Query, Future<TResult>> {}

// MediatR Main Process Class
class MediatR {
  static MediatR? _instance;
  static MediatR get instance => _instance ??= MediatR();
  final Set<InstanceFactory<IBaseHandler>> _commands =
      <InstanceFactory<IBaseHandler>>{};

  void registerCommandHandler<
    TResult,
    Command extends IBaseCommand<TResult>,
    Handler extends _ICommandHandler<Command, TResult>
  >(InstanceFactory<Handler> handler) {
    var handlers = _commands.whereType<InstanceFactory<Handler>>();
    if (handlers.isEmpty) {
      _commands.add(handler);
    }
  }

  void registerQueryHandler<
    TResult,
    Command extends IBaseQuery<TResult>,
    Handler extends _IQueryHandler<Command, TResult>
  >(InstanceFactory<Handler> handler) {
    var handlers = _commands.whereType<InstanceFactory<Handler>>();
    if (handlers.isEmpty) {
      _commands.add(handler);
    }
  }

  void registerQueryListHandler<
    TResult,
    Command extends IBaseQuery<TResult>,
    Handler extends _IQueryListHandler<Command, TResult>
  >(InstanceFactory<Handler> handler) {
    var handlers = _commands.whereType<InstanceFactory<Handler>>();
    if (handlers.isEmpty) {
      _commands.add(handler);
    }
  }

  void registerQueryPagedListHandler<
    TResult,
    Command extends IBaseQuery<TResult>,
    Handler extends _IQueryPagedListHandler<Command, TResult>
  >(InstanceFactory<Handler> handler) {
    var handlers = _commands.whereType<InstanceFactory<Handler>>();
    if (handlers.isEmpty) {
      _commands.add(handler);
    }
  }

  Future<Result<TResult>> query<Query extends IQuery<TResult>, TResult>(
    Query query,
  ) {
    var handlers =
        _commands
            .whereType<InstanceFactory<_IQueryHandler<Query, TResult>>>()
            .cast<_InstanceFactoryCheckerQuery<TResult, Query>>();
    if (handlers.isEmpty) {
      throw Exception(
        "You must register query handler for ${query.runtimeType} before calling this function",
      );
    }
    return handlers.first.call().handle(query);
  }

  Future<Result<TResult>> queryList<Query extends IQueryList<TResult>, TResult>(
    Query query,
  ) {
    var handlers =
        _commands
            .whereType<InstanceFactory<_IQueryListHandler<Query, TResult>>>()
            .cast<_InstanceFactoryCheckerQueryList<TResult, Query>>();
    if (handlers.isEmpty) {
      throw Exception(
        "You must register query handler for ${query.runtimeType} before calling this function",
      );
    }
    return handlers.first.call().handle(query);
  }

  Future<Result<TResult>>
  queryPagedList<Query extends IQueryPagedList<TResult>, TResult>(Query query) {
    var handlers =
        _commands
            .whereType<
              InstanceFactory<_IQueryPagedListHandler<Query, TResult>>
            >()
            .cast<_InstanceFactoryCheckerQueryPagedList<TResult, Query>>();
    if (handlers.isEmpty) {
      throw Exception(
        "You must register query handler for ${query.runtimeType} before calling this function",
      );
    }
    return handlers.first.call().handle(query);
  }

  Future<Result<TResult>> command<Command extends ICommand<TResult>, TResult>(
    Command query,
  ) async {
    var handlers =
        _commands
            .whereType<InstanceFactory<_ICommandHandler<Command, TResult>>>()
            .cast<_InstanceFactoryChecker<TResult, Command>>();
    if (handlers.isEmpty) {
      throw Exception(
        "You must register query handler for ${query.runtimeType} before calling this function",
      );
    }
    return await handlers.first.call().handle(query);
  }

  void clearHandlers() {
    _commands.clear();
  }

  void removeHandlers<T extends IBaseHandler>() {
    _commands.removeWhere((element) => element is InstanceFactory<T>);
  }

  void removeHandler<T extends IBaseHandler>(InstanceFactory<T> handler) {
    _commands.remove(handler);
  }

  Iterable<InstanceFactory<T>> getHandler<T extends IBaseHandler>() {
    return _commands.whereType<InstanceFactory<T>>();
  }

  Iterable<_InstanceFactoryChecker<TResult, Command>> getHandlersFor<
    TResult,
    Command extends IBaseCommand<TResult>
  >(Command command) {
    return _commands.whereType<_InstanceFactoryChecker<TResult, Command>>();
  }
}
