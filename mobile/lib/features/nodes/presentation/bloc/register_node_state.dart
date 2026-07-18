part of 'register_node_bloc.dart';

sealed class RegisterNodeState extends Equatable {
  const RegisterNodeState();

  @override
  List<Object?> get props => const [];
}

class RegisterNodeInitial extends RegisterNodeState {
  const RegisterNodeInitial();
}

class RegisterNodeSubmitting extends RegisterNodeState {
  const RegisterNodeSubmitting();
}

class RegisterNodeSuccess extends RegisterNodeState {
  const RegisterNodeSuccess(this.node);

  final NodeDetailEntity node;

  @override
  List<Object?> get props => [node];
}

class RegisterNodeFailure extends RegisterNodeState {
  const RegisterNodeFailure(this.message, {this.fieldErrors = const {}});

  final String message;

  /// DRF per-field validation messages (e.g. `{"operating_hours": [...]}`)
  /// — shown under the matching form fields.
  final Map<String, List<String>> fieldErrors;

  String? fieldError(String field) =>
      fieldErrors[field]?.isNotEmpty == true ? fieldErrors[field]!.first : null;

  @override
  List<Object?> get props => [message, fieldErrors];
}
