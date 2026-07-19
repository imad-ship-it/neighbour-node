import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:neighbor_node/core/errors/failures.dart';
import 'package:neighbor_node/features/items/domain/entities/item_detail_entity.dart';
import 'package:neighbor_node/features/items/domain/repositories/items_repository.dart';
import 'package:neighbor_node/features/items/domain/usecases/get_pending_donations.dart';
import 'package:neighbor_node/features/items/domain/usecases/review_donation.dart';
import 'package:neighbor_node/features/items/presentation/bloc/donation_queue_bloc.dart';
import 'package:neighbor_node/features/nodes/domain/entities/node_detail_entity.dart';
import 'package:neighbor_node/features/nodes/domain/repositories/nodes_repository.dart';

import 'donation_queue_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<ItemsRepository>(), MockSpec<NodesRepository>()])
void main() {
  late MockItemsRepository itemsRepository;
  late MockNodesRepository nodesRepository;

  const donor = NodeManagerEntity(id: 9, displayName: 'Donor', rating: 4);

  const bat = ItemDetailEntity(
    id: 2,
    title: 'Cricket Bat',
    description: '',
    category: 'SPORTS',
    condition: 'FAIR',
    dailyRate: 150,
    depositAmount: 500,
    storageType: 'NODE',
    listingStatus: 'PENDING_DONATION',
    isAvailable: true,
    lat: 33.7,
    lng: 73.05,
    imageUrls: [],
    owner: donor,
    nodeId: 1,
    nodeName: 'E2E Storeroom',
  );

  const books = ItemDetailEntity(
    id: 3,
    title: 'Old Books',
    description: '',
    category: 'BOOKS',
    condition: 'GOOD',
    dailyRate: 50,
    depositAmount: 100,
    storageType: 'NODE',
    listingStatus: 'PENDING_DONATION',
    isAvailable: true,
    lat: 33.7,
    lng: 73.05,
    imageUrls: [],
    owner: donor,
    nodeId: 1,
    nodeName: 'E2E Storeroom',
  );

  setUp(() {
    itemsRepository = MockItemsRepository();
    nodesRepository = MockNodesRepository();
  });

  DonationQueueBloc buildBloc() => DonationQueueBloc(
        pendingDonations: GetPendingDonations(itemsRepository),
        review: ReviewDonation(itemsRepository),
        nodesRepo: nodesRepository,
      );

  group('LoadDonationQueue', () {
    blocTest<DonationQueueBloc, DonationQueueState>(
      'emits [Loading, Loaded] with the node queue',
      build: () {
        when(nodesRepository.getManagedNodeId()).thenAnswer((_) async => 1);
        when(itemsRepository.getPendingDonations(1))
            .thenAnswer((_) async => const Right([bat, books]));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadDonationQueue()),
      expect: () => const [
        DonationQueueLoading(),
        DonationQueueLoaded([bat, books]),
      ],
    );

    blocTest<DonationQueueBloc, DonationQueueState>(
      'emits [Loading, NoNode] when no node id is stored',
      build: () {
        when(nodesRepository.getManagedNodeId())
            .thenAnswer((_) async => null);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadDonationQueue()),
      expect: () => const [
        DonationQueueLoading(),
        DonationQueueNoNode(),
      ],
    );

    blocTest<DonationQueueBloc, DonationQueueState>(
      'emits [Loading, Error] on failure',
      build: () {
        when(nodesRepository.getManagedNodeId()).thenAnswer((_) async => 1);
        when(itemsRepository.getPendingDonations(1))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const LoadDonationQueue()),
      expect: () => const [
        DonationQueueLoading(),
        DonationQueueError('Check your internet connection and try again.'),
      ],
    );
  });

  group('ReviewDonationRequested', () {
    blocTest<DonationQueueBloc, DonationQueueState>(
      'optimistically removes the item and keeps it removed on success',
      build: () {
        when(itemsRepository.reviewDonation(
          itemId: anyNamed('itemId'),
          accept: anyNamed('accept'),
        )).thenAnswer((_) async => const Right(bat));
        return buildBloc();
      },
      seed: () => const DonationQueueLoaded([bat, books]),
      act: (bloc) =>
          bloc.add(const ReviewDonationRequested(itemId: 2, accept: true)),
      expect: () => const [
        DonationQueueLoaded([books]),
      ],
    );

    blocTest<DonationQueueBloc, DonationQueueState>(
      'rolls the item back with a one-shot error on failure',
      build: () {
        when(itemsRepository.reviewDonation(
          itemId: anyNamed('itemId'),
          accept: anyNamed('accept'),
        )).thenAnswer((_) async => const Left(ServerFailure()));
        return buildBloc();
      },
      seed: () => const DonationQueueLoaded([bat, books]),
      act: (bloc) =>
          bloc.add(const ReviewDonationRequested(itemId: 2, accept: false)),
      expect: () => const [
        DonationQueueLoaded([books]),
        DonationQueueLoaded(
          [bat, books],
          error: 'Something went wrong on the server.',
        ),
      ],
    );
  });
}
