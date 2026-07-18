import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:neighbor_node/core/errors/failures.dart';
import 'package:neighbor_node/features/nodes/domain/entities/node_detail_entity.dart';
import 'package:neighbor_node/features/nodes/domain/repositories/nodes_repository.dart';
import 'package:neighbor_node/features/nodes/domain/usecases/register_node.dart';
import 'package:neighbor_node/features/nodes/presentation/bloc/register_node_bloc.dart';

import 'register_node_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<NodesRepository>()])
void main() {
  late MockNodesRepository repository;

  const createdNode = NodeDetailEntity(
    id: 5,
    name: 'New Node',
    description: '',
    address: 'Somewhere',
    lat: 33.7,
    lng: 73.05,
    operatingHours: {'mon': '09:00-18:00'},
    capacity: 10,
    isActive: false,
    rating: 0,
    totalTransactions: 0,
    isOpenNow: false,
    photoUrls: [],
    manager: NodeManagerEntity(id: 1, displayName: 'Me', rating: 0),
  );

  const submitEvent = RegisterNodeSubmitted(
    name: 'New Node',
    description: '',
    address: 'Somewhere',
    lat: 33.7,
    lng: 73.05,
    capacity: 10,
    operatingHours: {'mon': '09:00-18:00'},
  );

  setUp(() {
    repository = MockNodesRepository();
  });

  RegisterNodeBloc buildBloc() =>
      RegisterNodeBloc(submitNode: RegisterNode(repository));

  PostExpectation<Future<Either<Failure, NodeDetailEntity>>> whenRegister() =>
      when(repository.registerNode(
        name: anyNamed('name'),
        description: anyNamed('description'),
        address: anyNamed('address'),
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        capacity: anyNamed('capacity'),
        operatingHours: anyNamed('operatingHours'),
        photoPaths: anyNamed('photoPaths'),
      ));

  group('RegisterNodeSubmitted', () {
    blocTest<RegisterNodeBloc, RegisterNodeState>(
      'emits [Submitting, Success] when the backend accepts the node',
      build: () {
        whenRegister().thenAnswer((_) async => const Right(createdNode));
        return buildBloc();
      },
      act: (bloc) => bloc.add(submitEvent),
      expect: () => const [
        RegisterNodeSubmitting(),
        RegisterNodeSuccess(createdNode),
      ],
    );

    blocTest<RegisterNodeBloc, RegisterNodeState>(
      'surfaces DRF field errors on validation failure',
      build: () {
        whenRegister().thenAnswer(
          (_) async => const Left(ValidationFailure(
            'Invalid input.',
            {
              'operating_hours': ['Missing day(s): sun.'],
            },
          )),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(submitEvent),
      expect: () => const [
        RegisterNodeSubmitting(),
        RegisterNodeFailure(
          'Invalid input.',
          fieldErrors: {
            'operating_hours': ['Missing day(s): sun.'],
          },
        ),
      ],
    );

    blocTest<RegisterNodeBloc, RegisterNodeState>(
      'emits [Submitting, Failure] on network failure',
      build: () {
        whenRegister().thenAnswer((_) async => const Left(NetworkFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(submitEvent),
      expect: () => const [
        RegisterNodeSubmitting(),
        RegisterNodeFailure('Check your internet connection and try again.'),
      ],
    );
  });
}
