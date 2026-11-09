import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:kawalo_mobile/core/error/failures.dart';
import 'package:kawalo_mobile/core/widgets/app_user_filter_bottom_sheet.dart';
import 'package:kawalo_mobile/features/group/domain/entities/group_member_entity.dart';
import 'package:kawalo_mobile/features/group/presentation/group_member_filter_options.dart';

void main() {
  const member = GroupMemberEntity(
    email: 'budi@example.com',
    name: 'Budi',
    profilePic: 'https://example.com/budi.png',
  );

  test('toFilterOption copies email, name and profile picture', () {
    expect(
      member.toFilterOption(),
      const UserFilterOption(
        email: 'budi@example.com',
        name: 'Budi',
        profilePic: 'https://example.com/budi.png',
      ),
    );
  });

  test('loadGroupMemberFilterOptions maps every member on success', () async {
    final result = await loadGroupMemberFilterOptions(
      () async => const Right([member]),
    );

    expect(result.getOrElse((_) => []).map((o) => o.email), [member.email]);
  });

  test('loadGroupMemberFilterOptions keeps the failure untouched', () async {
    const failure = NoInternetFailure();

    final result = await loadGroupMemberFilterOptions(
      () async => const Left(failure),
    );

    expect(result, const Left<Failure, List<UserFilterOption>>(failure));
  });
}
