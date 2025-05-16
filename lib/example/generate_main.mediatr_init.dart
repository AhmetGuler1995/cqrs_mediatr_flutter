// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// MediatrGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:cqrs_mediatr_flutter/example/generate_main.mediatr_create.dart';
import 'package:cqrs_mediatr_flutter/example/command/example_command_handler.dart';

void registerCommandHandlers() {
  MediatR.instance.registerCommandHandler(() => ExampleCommandHandler());
}

void registerQueryHandlers() {}

void registerQueryListHandlers() {}

void registerQueryPagedListHandlers() {}

void registerAllHandlers() {
  registerCommandHandlers();
  registerQueryHandlers();
  registerQueryListHandlers();
  registerQueryPagedListHandlers();
}
