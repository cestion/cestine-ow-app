import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/components/nft/actor_price_curve_chart.dart';
import 'package:story_app/src/controller/nft_state.dart';
import 'package:story_app/src/controller/pagination_state.dart';
import 'package:story_app/src/model/actor_collection_model.dart';
import 'package:story_app/src/repositories/actor_repository.dart';

void main() {
  group('getActorBondingCurvePrice', () {
    test('returns 0 when initial price or max supply is invalid', () {
      expect(getActorBondingCurvePrice(0, 10, 100), 0);
      expect(getActorBondingCurvePrice(0.5, 10, 0), 0);
    });

    test('matches web bonding curve at boundaries', () {
      expect(getActorBondingCurvePrice(0.5, 0, 5000), closeTo(0.5, 0.000001));
      final atTail = getActorBondingCurveTailPrice(0.5, 5000);
      expect(atTail, closeTo(2.492961, 0.000001));
    });

    test('builds 81 curve points', () {
      final points = buildActorPriceCurveData(0.01, 5000);
      expect(points, hasLength(81));
      expect(points.first.signed, 0);
      expect(points.last.signed, 5000);
    });
  });

  group('buildActorPriceCurveYTicks', () {
    test('matches web ticks for bonding curve domain', () {
      final ticks = buildActorPriceCurveYTicks(
        initialPrice: 0.5,
        finalPrice: 2.5,
      );
      expect(ticks, [0, 0.5, 1.25, 2.5]);
    });

    test('deduplicates identical tick values', () {
      final ticks = buildActorPriceCurveYTicks(initialPrice: 0, finalPrice: 0);
      expect(ticks, [0]);
    });
  });

  group('resolveActorPriceCurveMaxPrice', () {
    test('keeps tail price when current is within domain', () {
      expect(
        resolveActorPriceCurveMaxPrice(tailPrice: 2.92, currentPrice: 1.71),
        2.92,
      );
    });

    test('extends domain like web ifOverflow=extendDomain when sold out', () {
      const initialPrice = 1.0;
      const maxSupply = 3;
      final tailPrice = getActorBondingCurveTailPrice(initialPrice, maxSupply);
      final soldOutPrice = getActorBondingCurvePrice(
        initialPrice,
        maxSupply,
        maxSupply,
      );

      expect(tailPrice, closeTo(2.924016, 0.000001));
      expect(soldOutPrice, closeTo(4.999997, 0.000001));
      expect(
        resolveActorPriceCurveMaxPrice(
          tailPrice: tailPrice,
          currentPrice: soldOutPrice,
        ),
        soldOutPrice,
      );
    });
  });

  group('NftState.displayItems', () {
    test('re-sorts by display price when priceAsc is active', () {
      const state = NftState(
        pagination: PaginationState(
          items: [
            ActorCollection(
              id: 'high',
              currentPriceUsdc: 10,
              initialPriceUsdc: 10,
            ),
            ActorCollection(
              id: 'low',
              currentPriceUsdc: 1,
              initialPriceUsdc: 1,
            ),
          ],
        ),
      );

      expect(state.displayItems.map((item) => item.id), ['low', 'high']);
    });

    test('keeps API order for heat sort', () {
      const state = NftState(
        sort: ActorCollectionSort.heat,
        pagination: PaginationState(
          items: [
            ActorCollection(id: 'first', heatValue: 100),
            ActorCollection(id: 'second', heatValue: 1),
          ],
        ),
      );

      expect(state.displayItems.map((item) => item.id), ['first', 'second']);
    });
  });
}
