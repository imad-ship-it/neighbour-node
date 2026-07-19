import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:neighbor_node/core/errors/failures.dart';
import 'package:neighbor_node/features/items/domain/entities/item_entity.dart';
import 'package:neighbor_node/features/items/domain/repositories/items_repository.dart';
import 'package:neighbor_node/features/items/domain/usecases/create_item.dart';
import 'package:neighbor_node/features/items/presentation/bloc/add_item_bloc.dart';

import 'add_item_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ItemsRepository>()])
void main() {
  late MockItemsRepository repository;

  const personalItem = ItemEntity(
    id: 1,
    title: 'DeWalt Power Drill',
    category: 'TOOLS',
    condition: 'GOOD',
    dailyRate: 500,
    depositAmount: 2000,
    storageType: 'PERSONAL',
    listingStatus: 'ACTIVE',
    isAvailable: true,
    lat: 33.7,
    lng: 73.05,
  );

  const donatedItem = ItemEntity(
    id: 2,
    title: 'Cricket Bat',
    category: 'SPORTS',
    condition: 'FAIR',
    dailyRate: 150,
    depositAmount: 500,
    storageType: 'NODE',
    listingStatus: 'PENDING_DONATION',
    isAvailable: true,
    lat: 33.7,
    lng: 73.05,
    nodeId: 1,
  );

  const params = CreateItemParams(
    title: 'DeWalt Power Drill',
    description: '',
    category: 'TOOLS',
    condition: 'GOOD',
    dailyRate: '500.00',
    depositAmount: '2000.00',
  );

  setUp(() {
    repository = MockItemsRepository();
  });

  AddItemBloc buildBloc() => AddItemBloc(submitItem: CreateItem(repository));

  PostExpectation<Future<Either<Failure, ItemEntity>>> whenCreate() =>
      when(repository.createItem(
        title: anyNamed('title'),
        description: anyNamed('description'),
        category: anyNamed('category'),
        condition: anyNamed('condition'),
        dailyRate: anyNamed('dailyRate'),
        depositAmount: anyNamed('depositAmount'),
        nodeId: anyNamed('nodeId'),
        imagePaths: anyNamed('imagePaths'),
      ));

  group('AddItemSubmitted', () {
    blocTest<AddItemBloc, AddItemState>(
      'personal item -> Success with isDonation false',
      build: () {
        whenCreate().thenAnswer((_) async => const Right(personalItem));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AddItemSubmitted(params)),
      expect: () => const [
        AddItemSubmitting(),
        AddItemSuccess(personalItem),
      ],
      verify: (bloc) {
        expect((bloc.state as AddItemSuccess).isDonation, isFalse);
      },
    );

    blocTest<AddItemBloc, AddItemState>(
      'donation -> Success with isDonation true',
      build: () {
        whenCreate().thenAnswer((_) async => const Right(donatedItem));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AddItemSubmitted(params)),
      expect: () => const [
        AddItemSubmitting(),
        AddItemSuccess(donatedItem),
      ],
      verify: (bloc) {
        expect((bloc.state as AddItemSuccess).isDonation, isTrue);
      },
    );

    blocTest<AddItemBloc, AddItemState>(
      'surfaces DRF field errors on validation failure',
      build: () {
        whenCreate().thenAnswer(
          (_) async => const Left(ValidationFailure(
            'Invalid input.',
            {
              'daily_rate': ['Ensure this value is greater than 0.'],
            },
          )),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const AddItemSubmitted(params)),
      expect: () => const [
        AddItemSubmitting(),
        AddItemFailure(
          'Invalid input.',
          fieldErrors: {
            'daily_rate': ['Ensure this value is greater than 0.'],
          },
        ),
      ],
    );
  });
}
