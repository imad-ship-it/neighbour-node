import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:neighbor_node/core/errors/failures.dart';
import 'package:neighbor_node/features/nodes/domain/entities/node_detail_entity.dart';
import 'package:neighbor_node/features/nodes/domain/repositories/nodes_repository.dart';
import 'package:neighbor_node/features/nodes/domain/usecases/get_node_detail.dart';
import 'package:neighbor_node/features/nodes/presentation/bloc/node_detail_bloc.dart';

import 'node_detail_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NodesRepository>()])
void main() {
  late MockNodesRepository repository;

  const testNode = NodeDetailEntity(
    id: 1,
    name: 'Block C Storeroom',
    description: 'Community storeroom',
    address: 'Block C, F-7, Islamabad',
    lat: 33.7096,
    lng: 73.0505,
    operatingHours: {'mon': '09:00-18:00', 'sun': 'closed'},
    capacity: 20,
    isActive: true,
    rating: 4.5,
    totalTransactions: 12,
    isOpenNow: true,
    photoUrls: ['http://x/1.jpg'],
    manager: NodeManagerEntity(id: 7, displayName: 'Owner', rating: 4.8),
  );

  setUp(() {
    repository = MockNodesRepository();
  });

  NodeDetailBloc buildBloc() =>
      NodeDetailBloc(nodeDetail: GetNodeDetail(repository));

  group('LoadNodeDetail', () {
    blocTest<NodeDetailBloc, NodeDetailState>(
      'emits [NodeDetailLoading, NodeDetailLoaded] on success',
      build: () {
        when(repository.getNode(1))
            .thenAnswer((_) async => const Right(testNode));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadNodeDetail(1)),
      expect: () => const [
        NodeDetailLoading(),
        NodeDetailLoaded(testNode),
      ],
    );

    blocTest<NodeDetailBloc, NodeDetailState>(
      'emits [NodeDetailLoading, NodeDetailError] on failure',
      build: () {
        when(repository.getNode(1))
            .thenAnswer((_) async => const Left(ServerFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadNodeDetail(1)),
      expect: () => const [
        NodeDetailLoading(),
        NodeDetailError('Something went wrong on the server.'),
      ],
    );
  });
}
