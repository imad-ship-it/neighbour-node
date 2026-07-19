import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:neighbor_node/core/errors/failures.dart';
import 'package:neighbor_node/features/items/domain/entities/item_entity.dart';
import 'package:neighbor_node/features/items/domain/repositories/items_repository.dart';
import 'package:neighbor_node/features/items/domain/usecases/get_nearby_items.dart';
import 'package:neighbor_node/features/items/presentation/bloc/items_bloc.dart';

import 'items_bloc_test.mocks.dart';

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
    distanceMeters: 120,
  );

  setUp(() {
    repository = MockItemsRepository();
  });

  ItemsBloc buildBloc() => ItemsBloc(nearbyItems: GetNearbyItems(repository));

  PostExpectation<Future<Either<Failure, List<ItemEntity>>>> whenNearby() =>
      when(repository.getNearbyItems(
        lat: anyNamed('lat'),
        lng: anyNamed('lng'),
        radiusMeters: anyNamed('radiusMeters'),
        category: anyNamed('category'),
        maxRate: anyNamed('maxRate'),
        storageType: anyNamed('storageType'),
      ));

  group('LoadNearbyItems', () {
    blocTest<ItemsBloc, ItemsState>(
      'emits [Loading, Loaded] and always queries PERSONAL items only',
      build: () {
        whenNearby().thenAnswer((_) async => const Right([drill]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadNearbyItems(
        lat: 33.7,
        lng: 73.05,
        category: 'TOOLS',
        maxRate: 1000,
      )),
      expect: () => const [
        ItemsLoading(),
        ItemsLoaded([drill]),
      ],
      verify: (_) {
        verify(repository.getNearbyItems(
          lat: 33.7,
          lng: 73.05,
          radiusMeters: 5000,
          category: 'TOOLS',
          maxRate: 1000,
          storageType: 'PERSONAL',
        )).called(1);
      },
    );

    blocTest<ItemsBloc, ItemsState>(
      'emits [Loading, Error] on failure',
      build: () {
        whenNearby().thenAnswer((_) async => const Left(NetworkFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadNearbyItems(lat: 33.7, lng: 73.05)),
      expect: () => const [
        ItemsLoading(),
        ItemsError('Check your internet connection and try again.'),
      ],
    );
  });
}
