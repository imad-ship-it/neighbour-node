import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:neighbor_node/core/errors/failures.dart';
import 'package:neighbor_node/features/items/domain/entities/item_entity.dart';
import 'package:neighbor_node/features/items/domain/repositories/items_repository.dart';
import 'package:neighbor_node/features/items/domain/usecases/get_my_items.dart';
import 'package:neighbor_node/features/items/domain/usecases/set_item_availability.dart';
import 'package:neighbor_node/features/items/presentation/bloc/my_items_bloc.dart';

import 'my_items_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ItemsRepository>()])
void main() {
  late MockItemsRepository repository;

  const drill = ItemEntity(
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

  const drillUnavailable = ItemEntity(
    id: 1,
    title: 'DeWalt Power Drill',
    category: 'TOOLS',
    condition: 'GOOD',
    dailyRate: 500,
    depositAmount: 2000,
    storageType: 'PERSONAL',
    listingStatus: 'ACTIVE',
    isAvailable: false,
    lat: 33.7,
    lng: 73.05,
  );

  setUp(() {
    repository = MockItemsRepository();
  });

  MyItemsBloc buildBloc() => MyItemsBloc(
        myItems: GetMyItems(repository),
        toggleAvailability: SetItemAvailability(repository),
      );

  group('LoadMyItems', () {
    blocTest<MyItemsBloc, MyItemsState>(
      'emits [Loading, Loaded] on success',
      build: () {
        when(repository.getMyItems())
            .thenAnswer((_) async => const Right([drill]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMyItems()),
      expect: () => const [
        MyItemsLoading(),
        MyItemsLoaded([drill]),
      ],
    );

    blocTest<MyItemsBloc, MyItemsState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(repository.getMyItems())
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadMyItems()),
      expect: () => const [
        MyItemsLoading(),
        MyItemsError('Check your internet connection and try again.'),
      ],
    );
  });

  group('ToggleItemAvailability', () {
    blocTest<MyItemsBloc, MyItemsState>(
      'replaces the item on success',
      build: () {
        when(repository.setItemAvailability(
          itemId: anyNamed('itemId'),
          isAvailable: anyNamed('isAvailable'),
        )).thenAnswer((_) async => const Right(drillUnavailable));
        return buildBloc();
      },
      seed: () => const MyItemsLoaded([drill]),
      act: (bloc) => bloc.add(
        const ToggleItemAvailability(itemId: 1, isAvailable: false),
      ),
      expect: () => const [
        MyItemsLoaded([drillUnavailable]),
      ],
    );

    blocTest<MyItemsBloc, MyItemsState>(
      'keeps the list and carries a one-shot error on failure',
      build: () {
        when(repository.setItemAvailability(
          itemId: anyNamed('itemId'),
          isAvailable: anyNamed('isAvailable'),
        )).thenAnswer((_) async => const Left(ServerFailure()));
        return buildBloc();
      },
      seed: () => const MyItemsLoaded([drill]),
      act: (bloc) => bloc.add(
        const ToggleItemAvailability(itemId: 1, isAvailable: false),
      ),
      expect: () => const [
        MyItemsLoaded([drill], error: 'Something went wrong on the server.'),
      ],
    );
  });
}
