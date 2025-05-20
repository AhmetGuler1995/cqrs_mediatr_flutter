import 'package:cqrs_mediatr_flutter/annotations/command_register_handler.dart';
import 'package:cqrs_mediatr_flutter/data/tool/mediatr.dart';
import 'package:cqrs_mediatr_flutter/example/generic_result/result.dart';

class ExampleCommandRequest extends ICommand<ExampleCommandResponse> {}

class ExampleCommandResponse {}

@CommandRegisterHandler()
class ExampleCommandHandler
    extends ICommandHandler<ExampleCommandRequest, ExampleCommandResponse> {
  @override
  Future<Result<ExampleCommandResponse>> handle(ExampleCommandRequest command) {
    throw UnimplementedError();
  }
}
