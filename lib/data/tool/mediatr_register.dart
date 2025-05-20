// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:cqrs_mediatr_flutter/data/tool/mediatr.dart';
import 'package:cqrs_mediatr_flutter/example/command/example_command_handler.dart';

class MediatrRegister {
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
}
