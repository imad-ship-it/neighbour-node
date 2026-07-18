import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:neighbor_node/core/errors/failures.dart';
import 'package:neighbor_node/features/nodes/domain/entities/node_entity.dart';
import 'package:neighbor_node/features/nodes/domain/repositories/nodes_repository.dart';
import 'package:neighbor_node/features/nodes/domain/usecases/get_nearby_nodes.dart';
import 'package:neighbor_node/features/nodes/presentation/bloc/node_bloc.dart';

import 'node_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NodesRepository>()])
void main() {
  late MockNodesRepository repository;

  const testNode = NodeEntity(
    id: 1,
    name: 'Block C Storeroom',
    address: 'Block C, F-7, Islamabad',
    lat: 33.7096,
    lng: 73.0505,
    rating: 4.5,
    isOpenNow: true,
    distanceMeters: 111.2,
  );

  setUp(() {
    repository = MockNodesRepository();
  });

  NodeBloc buildBloc() => NodeBloc(nearbyNodes: GetNearbyNodes(repository));

  group('LoadNearbyNodes', () {
    blocTest<NodeBloc, NodeState>(
      'emits [NodesLoading, NodesLoaded] when the query succeeds',
      build: () {
        when(repository.getNearbyNodes(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          radiusMeters: anyNamed('radiusMeters'),
        )).thenAnswer((_) async => const Right([testNode]));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const LoadNearbyNodes(lat: 33.7086, lng: 73.0505)),
      expect: () => const [
        NodesLoading(),
        NodesLoaded([testNode]),
      ],
    );

    blocTest<NodeBloc, NodeState>(
      'passes the coordinates and radius through to the repository',
      build: () {
        when(repository.getNearbyNodes(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          radiusMeters: anyNamed('radiusMeters'),
        )).thenAnswer((_) async => const Right([]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(
        const LoadNearbyNodes(lat: 1.5, lng: 2.5, radiusMeters: 750),
      ),
      verify: (_) {
        verify(repository.getNearbyNodes(lat: 1.5, lng: 2.5, radiusMeters: 750))
            .called(1);
      },
    );

    blocTest<NodeBloc, NodeState>(
      'emits [NodesLoading, NodesError] when the query fails',
      build: () {
        when(repository.getNearbyNodes(
          lat: anyNamed('lat'),
          lng: anyNamed('lng'),
          radiusMeters: anyNamed('radiusMeters'),
        )).thenAnswer((_) async => const Left(NetworkFailure()));
        return buildBloc();
      },
      act: (bloc) =>
          bloc.add(const LoadNearbyNodes(lat: 33.7086, lng: 73.0505)),
      expect: () => const [
        NodesLoading(),
        NodesError('Check your internet connection and try again.'),
      ],
    );
  });
}
