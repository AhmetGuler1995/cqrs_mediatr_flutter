import 'package:cqrs_mediatr_flutter/annotations/command_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_list_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_paged_list_result_patern_model.dart';
import 'package:cqrs_mediatr_flutter/annotations/query_result_patern_model.dart';

@CommandResultPaternModel()
@QueryListResultPaternModel()
@QueryResultPaternModel()
@QueryPagedListResultPaternModel()
class Result<T> {
  bool? success;
  T? item;
  Result({this.success, this.item});
}
