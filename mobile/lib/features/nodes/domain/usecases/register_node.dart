import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/node_detail_entity.dart';
import '../repositories/nodes_repository.dart';

class RegisterNode implements UseCase<NodeDetailEntity, RegisterNodeParams> {
  const RegisterNode(this._repository);

  final NodesRepository _repository;

  @override
  Future<Either<Failure, NodeDetailEntity>> call(RegisterNodeParams params) =>
      _repository.registerNode(
        name: params.name,
        description: params.description,
        address: params.address,
        lat: params.lat,
        lng: params.lng,
        capacity: params.capacity,
        operatingHours: params.operatingHours,
        photoPaths: params.photoPaths,
      );
}

class RegisterNodeParams extends Equatable {
  const RegisterNodeParams({
    required this.name,
    required this.description,
    required this.address,
    required this.lat,
    required this.lng,
    required this.capacity,
    required this.operatingHours,
    this.photoPaths = const [],
  });

  final String name;
  final String description;
  final String address;
  final double lat;
  final double lng;
  final int capacity;
  final Map<String, String> operatingHours;

  /// Local file paths; the data layer turns them into multipart files.
  final List<String> photoPaths;

  @override
  List<Object?> get props =>
      [name, description, address, lat, lng, capacity, operatingHours, photoPaths];
}
