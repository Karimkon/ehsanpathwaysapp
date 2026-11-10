import 'package:flutter_test/flutter_test.dart';
import 'package:ehsan_pathways/features/videos/video_provider.dart';

void main() {
  group('VideoFeedPage', () {
    test('reads the cursor meta the server actually sends', () {
      final page = VideoFeedPage.fromJson({
        'success': true,
        'data': [
          {'uuid': 'a', 'title': 'One'},
          {'uuid': 'b', 'title': 'Two'},
        ],
        'meta': {
          'next_cursor': 'eyJrIjoibGF0ZXN0In0.sig',
          'has_more': true,
          'per_page': 24,
          'sort': 'latest',
        },
      });

      expect(page.data.length, 2);
      expect(page.nextCursor, 'eyJrIjoibGF0ZXN0In0.sig');
      expect(page.hasMore, isTrue);
    });

    test('a null cursor means the end even when has_more says otherwise', () {
      // Trusting has_more alone would make loadMore refetch the last page
      // forever.
      final page = VideoFeedPage.fromJson({
        'data': [
          {'uuid': 'a', 'title': 'One'},
        ],
        'meta': {'next_cursor': null, 'has_more': true},
      });

      expect(page.hasMore, isFalse,
          reason: 'no cursor means there is nowhere to go');
    });

    test('survives a response with no meta at all', () {
      final page = VideoFeedPage.fromJson({'data': []});

      expect(page.data, isEmpty);
      expect(page.hasMore, isFalse);
      expect(page.nextCursor, isNull);
    });
  });

  group('VideoListState', () {
    test('knows when it is filtered', () {
      expect(const VideoListState().isFiltered, isFalse);
      expect(const VideoListState(search: 'mercy').isFiltered, isTrue);
      expect(const VideoListState(search: '').isFiltered, isFalse);
      expect(const VideoListState(durationBuckets: [1]).isFiltered, isTrue);
      expect(const VideoListState(types: ['khutbah']).isFiltered, isTrue);
    });

    test('copyWith can actually clear the cursor', () {
      // `cursor ?? this.cursor` can never set it back to null, and reaching
      // the end of the feed has to do exactly that.
      const state = VideoListState(cursor: 'abc', hasMore: true);

      expect(state.copyWith(cursor: null).cursor, 'abc',
          reason: 'passing null alone must not clear it, by design');
      expect(state.copyWith(clearCursor: true).cursor, isNull);
    });

    test('copyWith keeps the filters it was not asked to change', () {
      const state = VideoListState(
        categorySlug: 'seerah',
        scholarSlug: 'someone',
        durationBuckets: [2, 3],
        types: ['lecture'],
        sort: 'popular',
      );

      final next = state.copyWith(isLoadingMore: true);

      expect(next.categorySlug, 'seerah');
      expect(next.scholarSlug, 'someone');
      expect(next.durationBuckets, [2, 3]);
      expect(next.types, ['lecture']);
      expect(next.sort, 'popular');
    });
  });
}
