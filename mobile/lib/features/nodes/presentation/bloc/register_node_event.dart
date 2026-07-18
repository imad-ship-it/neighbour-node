part of 'register_node_bloc.dart';

sealed class RegisterNodeEvent extends Equatable {
  const RegisterNodeEvent();

  @override
  List<Object?> get props => const [];
}

class RegisterNodeSubmitted extends RegisterNodeEvent {
  const RegisterNodeSubmitted({
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
  final List<String> photoPaths;

  @override
  List<Object?> get props =>
      [name, description, address, lat, lng, capacity, operatingHours, photoPaths];
}
