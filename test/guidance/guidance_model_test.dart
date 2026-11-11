import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ehsan_pathways/features/guidance/guidance_provider.dart';

/// The fixture is the server's own CounsellingRequest::toApi(true) output,
/// generated from the Laravel model, not typed by hand.
void main() {
  final json = jsonDecode(File('test/fixtures/guidance_thread.json').readAsStringSync())
      as Map<String, dynamic>;

  test('parses a real server thread', () {
    final g = GuidanceRequest.fromJson(json['data'] as Map<String, dynamic>);

    expect(g.reference, matches(RegExp(r'^G-[A-Z2-9]{6}$')));
    expect(g.topic, 'struggles');
    expect(g.responseMode, 'discussion');
    expect(g.adviserName, 'Hassan');
    expect(g.referralNote, 'Please also see a grief counsellor.');
    expect(g.awaitingAdviser, isTrue);
    expect(g.stateLabel, 'With your adviser');
    expect(g.messages, hasLength(3));
    expect(g.messages.first.fromAdviser, isTrue);
    expect(g.messages.first.author, 'Hassan');
    expect(g.messages.last.fromAdviser, isFalse);
  });

  test('every topic the app offers is one the server accepts', () {
    // CounsellingRequest::TOPICS on the server.
    const server = ['marriage', 'family', 'faith', 'finance', 'struggles', 'education', 'parenting', 'other'];
    expect(guidanceTopics.map((t) => t.key).toList(), server);
  });

  test('an unknown topic falls back to Other', () {
    expect(topicFor('astrology').key, 'other');
  });
}
