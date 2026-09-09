import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/services/solana/generated/story_program.g.dart';

void main() {
  group('StoryContractMetadata', () {
    const developmentProgramId = '6w1itXjxKn79S6WzR3tY6nkF7rx5DDJbYkH12a7uFyTk';
    const testProgramId = 'CJEnSe9eJ3s8qLQNdWrcHQpp6199s4NohcBBHZ3UeRQL';
    const productionProgramId = '7vGTZBAqjk9mArEnj1bZ7aRvAkeoksAcrzB7aEtzb8g1';

    test('allows development and test deployments on protocol v2', () {
      expect(StoryContractMetadata.protocolVersions['development'], 2);
      expect(StoryContractMetadata.protocolVersions['test'], 2);
      expect(
        StoryContractMetadata.isAllowedProgramId(developmentProgramId),
        isTrue,
      );
      expect(StoryContractMetadata.isAllowedProgramId(testProgramId), isTrue);
    });

    test('keeps the protocol v1 production deployment blocked', () {
      expect(StoryContractMetadata.protocolVersions['production'], 1);
      expect(
        StoryContractMetadata.isKnownProgramId(productionProgramId),
        isTrue,
      );
      expect(
        StoryContractMetadata.isAllowedProgramId(productionProgramId),
        isFalse,
      );
    });

    test('records the deployed test IDL checksum', () {
      expect(
        StoryContractMetadata.idlSha256ByEnvironment['test'],
        '2c664599e31572b9e685f3a72bae1a6b087d0a4490ed20670fd30e9590b2c02b',
      );
    });
  });
}
