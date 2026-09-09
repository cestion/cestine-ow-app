// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'StoryFun';

  @override
  String get commonCancel => '취소';

  @override
  String get commonNoData => '데이터가 없습니다';

  @override
  String get commonNo => '아니요';

  @override
  String get commonYes => '예';

  @override
  String get publishDrama => '드라마 게시';

  @override
  String get publishVideo => '동영상 게시';

  @override
  String get publishVideoUploadTitle => '동영상 파일 업로드';

  @override
  String get publishVideoFileHint =>
      'mp4, flv, wmv, mkv, avi, mov, webm 지원, 최대 2GB';

  @override
  String get publishVideoChooseFile => '파일 선택';

  @override
  String get publishVideoChangeFile => '파일 변경';

  @override
  String get publishVideoChooseSource => '동영상 가져올 위치 선택';

  @override
  String get publishVideoChooseFromGallery => '갤러리에서 선택';

  @override
  String get publishVideoChooseFromFiles => '파일에서 선택';

  @override
  String get publishVideoPreparing => '동영상 준비 중…';

  @override
  String get publishVideoCoverTitle => '동영상 커버';

  @override
  String get publishVideoChangeCover => '커버 변경';

  @override
  String get publishVideoCoverHint => 'JPG/PNG, 최대 5MB';

  @override
  String get publishVideoDescriptionLabel => '설명';

  @override
  String get publishVideoRequired => '(필수)';

  @override
  String get publishVideoDescriptionHint => '작품 설명 추가(최대 200자)';

  @override
  String get publishVideoSaveDraft => '초안 저장';

  @override
  String get publishVideoDraftEditModeNotSupported => '편집 모드에서는 초안을 저장할 수 없습니다';

  @override
  String get publishVideoDraftNothingToSave => '저장할 내용이 없습니다';

  @override
  String get publishVideoNext => '다음';

  @override
  String get publishVideoCoverCropTitle => '동영상 커버 자르기';

  @override
  String get publishVideoVideoTooLarge => '동영상 파일은 2GB를 초과할 수 없습니다';

  @override
  String get publishVideoVideoPickFailed => '동영상을 선택하지 못했습니다. 다시 시도해 주세요';

  @override
  String get publishVideoInsufficientStorage => '동영상을 준비할 기기 저장 공간이 부족합니다';

  @override
  String get publishVideoPermissionDenied =>
      '동영상에 접근할 수 없습니다. 사진 또는 파일 권한을 확인해 주세요';

  @override
  String get publishVideoSourceUnavailable =>
      '현재 이 동영상을 읽을 수 없습니다. 클라우드 파일을 다운로드한 후 다시 시도해 주세요';

  @override
  String get publishVideoPrepareFailed =>
      '동영상을 준비하지 못했습니다. 다시 시도하거나 파일에서 선택해 주세요';

  @override
  String get publishVideoMetadataUnavailable =>
      '동영상 정보를 읽을 수 없습니다. 다른 파일을 선택해 주세요';

  @override
  String get publishVideoCoverTooLarge => '커버 이미지는 5MB를 초과할 수 없습니다';

  @override
  String get publishVideoCoverUnsupportedFormat => 'JPG/PNG 이미지만 지원됩니다';

  @override
  String get publishVideoCoverPickFailed => '커버를 선택하지 못했습니다. 다시 시도해 주세요';

  @override
  String get publishVideoUploadSessionFailed => '업로드 세션을 만들지 못했습니다. 다시 시도해 주세요';

  @override
  String get publishVideoPublishedSuccess => '동영상이 게시되었습니다';

  @override
  String get publishVideoUpdatedSuccess => '동영상이 수정되었습니다';

  @override
  String get publishActorIp => 'IP 발행';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonOk => '확인';

  @override
  String get commonNotice => '안내';

  @override
  String get commonRetry => '다시 시도';

  @override
  String get publicProfileLikedEmpty => '좋아요한 드라마가 없습니다';

  @override
  String get profileTabDramas => '숏드라마';

  @override
  String get profileTabWorks => '작품';

  @override
  String get profileTabActorIp => '캐릭터 IP';

  @override
  String dramaUnlockConfirmLabel(String price, String currency) {
    return '$price $currency로 잠금 해제';
  }

  @override
  String dramaAllEpisodes(int count) {
    return '$count화';
  }

  @override
  String dramaAllEpisodesFull(Object count) {
    return '전체 $count화';
  }

  @override
  String get dramaLoading => '인기 드라마 불러오는 중...';

  @override
  String get dramaEmpty => '현재 단편 드라마가 없습니다';

  @override
  String get dramaRefresh => '새로고침';

  @override
  String get navTheater => '극장';

  @override
  String get navHome => '홈';

  @override
  String get theaterTabShortDrama => '드라마';

  @override
  String get theaterTabRecommend => '추천';

  @override
  String get playerWatchFullDrama => '전체 단편 시청';

  @override
  String get playerStoryPerHourUnit => 'STORY/h';

  @override
  String get navNft => 'IP 마켓';

  @override
  String get navNftIp => '캐릭터 IP';

  @override
  String watchFullDramaEpisodes(int count) {
    return '드라마 보기 · 총 $count부';
  }

  @override
  String get navCreate => '창작';

  @override
  String get navProfile => '내 정보';

  @override
  String get navMy => '매니저';

  @override
  String get aboutTitle => '회사 소개';

  @override
  String get aboutVision => 'AI · 웹3 · 프로토콜';

  @override
  String get aboutVisionDesc => '세 가지 동력이 작용하여, 서사를 수동적인 경험에서 능동적인 창작으로 전환한다';

  @override
  String get aboutAiDesc => '당신의 생각이 저절로 이야기로 변합니다';

  @override
  String get aboutWeb3Desc => '당신의 창작물은 언제나 당신의 것입니다';

  @override
  String get aboutProtocolDesc => '당신의 이야기는 끝없이 이어질 수 있습니다';

  @override
  String get aboutIdentityTitle => '당신의 서사적 정체성';

  @override
  String get aboutIdentityDesc => '당신 그 자체가 펼쳐지고 있는 이야기의 세계입니다';

  @override
  String get aboutIdentityCreator => '창조자';

  @override
  String get aboutIdentityCreatorDesc => '자신의 이야기를 주도적으로 써 내려가다';

  @override
  String get aboutIdentityWitness => '목격자';

  @override
  String get aboutIdentityWitnessDesc => '타인의 이야기에 동참하고 이를 검증하다';

  @override
  String get aboutIdentityCoCreator => '공동 창시자';

  @override
  String get aboutIdentityCoCreatorDesc => '서사 구조에 들어가 재구성하기';

  @override
  String get aboutIdentitySpreader => '전파자';

  @override
  String get aboutIdentitySpreaderDesc => '당신이 마땅히 받아야 할 이야기를 전하세요';

  @override
  String get aboutTokenomicsTitle => 'STORY: 서사권 토큰';

  @override
  String get aboutTokenomicsDesc =>
      'AI 단편 드라마의 공동 프로듀서가 되어 영화 산업의 이익 배분을 재구성하세요.';

  @override
  String get aboutTokenomicsGov => '통치권';

  @override
  String get aboutTokenomicsGovDesc => '투표를 통해 다음 AI 단편의 주제와 전개 방향을 결정합니다';

  @override
  String get aboutTokenomicsRevenue => '수익권';

  @override
  String get aboutTokenomicsRevenueDesc => '공유 플랫폼 구독, 저작권 라이선스 및 굿즈 판매 수익';

  @override
  String get aboutTokenomicsAccess => '접근 권한';

  @override
  String get aboutTokenomicsAccessDesc => '최신 에피소드를 가장 먼저 시청하고, 독점 콘텐츠를 만나보세요';

  @override
  String get aboutStakingTitle => '담보 수익 분배';

  @override
  String get aboutStakingDesc => '드라마 NFT · 캐릭터 NFT · STORY → 스테이크로 배당금 획득';

  @override
  String get aboutStakingDrama => '드라마 NFT 스테이킹';

  @override
  String get aboutStakingDramaDesc => '단편 드라마 제작자 · 수익 분배';

  @override
  String get aboutStakingActor => '캐릭터 NFT 스테이킹';

  @override
  String get aboutStakingActorDesc => '역할이 단편 드라마에 출연 · 수익 분배 받기';

  @override
  String get aboutStakingStory => 'STORY 스테이킹';

  @override
  String get aboutStakingStoryDesc => '숏폼 콘텐츠에 콘텐츠 제공 · 수익 분배';

  @override
  String get aboutHeroTitle => '나만의 이야기를 만들어라';

  @override
  String get aboutHeroDesc => '너의 삶은 경험받을 스크립트가 아니라 네가 쓰고 있는 서사입니다';

  @override
  String get loginTitle => '이메일 로그인';

  @override
  String get loginSubtitle =>
      'Privy 이메일 OTP로 로그인하여 Solana 임베디드 월렛을 자동으로 생성합니다.';

  @override
  String get loginPlaceholder => '이메일 주소를 입력해 주세요';

  @override
  String get loginEmailHintFormat => '이메일을 입력해 주세요';

  @override
  String get loginVerificationFailed => '인증에 실패했습니다';

  @override
  String get loginNeedCodeFirst => '먼저 인증 코드를 받아 주세요';

  @override
  String get loginCreateWalletFailed => '지갑 생성에 실패했습니다';

  @override
  String get loginGetTokenFailed => '액세스 토큰을 가져오지 못했습니다';

  @override
  String get loginPrivyUnavailable =>
      '로그인 서비스를 사용할 수 없습니다. 앱을 다시 시작한 후 시도해 주세요';

  @override
  String get loginSendCodeFailed => '인증 코드 전송에 실패했습니다. 나중에 다시 시도해 주세요';

  @override
  String get loginTooManyRequests => '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요';

  @override
  String get loginVerificationSuccessful => '인증에 성공했습니다';

  @override
  String get loginSendCode => '코드 받기';

  @override
  String get loginSendingCode => '전송 중...';

  @override
  String get loginCodePlaceholder => '6자리 인증 코드를 입력해 주세요';

  @override
  String get loginSubmit => '로그인';

  @override
  String get loginSubmitting => '로그인 중...';

  @override
  String get loginEmailRequired => '이메일을 입력해 주세요';

  @override
  String get loginCodeRequired => '인증 코드를 입력해 주세요';

  @override
  String get loginSuccess => '로그인 성공';

  @override
  String get loginErrorPrefix => '로그인 실패: ';

  @override
  String loginCodeSent(String email) {
    return '인증 코드가 $email로 전송되었습니다';
  }

  @override
  String get loginEmailLabel => '이메일';

  @override
  String get loginCodeLabel => '인증 코드';

  @override
  String get loginVerifying => '인증 중입니다. 잠시만 기다려 주세요...';

  @override
  String get loginVerifyAndSubmit => '인증 후 로그인';

  @override
  String get loginChangeEmail => '이메일 변경';

  @override
  String get loginNotNow => '나중에 하기';

  @override
  String get loginInvalidEmail => '유효한 이메일 주소를 입력해 주세요';

  @override
  String get profileTitle => '에이전트';

  @override
  String get profileNotLoggedIn => '로그인 안 됨';

  @override
  String get profileClickLogin => '로그인 / 회원가입';

  @override
  String get profileMyWallet => '내 지갑';

  @override
  String get profileWallet => '지갑';

  @override
  String get profileTradeStory => 'STORY 거래';

  @override
  String get profileWalletCreating => '생성 중...';

  @override
  String get walletNetworkSolana => 'Solana';

  @override
  String get walletNetworkEvm => 'EVM';

  @override
  String get profileEarnings => '수익';

  @override
  String get profileMyNft => '내 NFT';

  @override
  String get profileMyFavorites => '즐겨찾기';

  @override
  String get profileWatchHistory => '시청 기록';

  @override
  String get profileCreatorCatalog => '크리에이터';

  @override
  String get profileIdentityAuth => '본인 인증';

  @override
  String get profileAccountSecurity => '계정 보안';

  @override
  String get profileLanguage => '언어';

  @override
  String get profileAboutUs => '회사 소개';

  @override
  String get profileHelpFeedback => '도움말 및 피드백';

  @override
  String get profileLogout => '로그아웃';

  @override
  String get profileLogoutConfirm => '로그아웃하시겠습니까?';

  @override
  String get profileLogoutSuccess => '로그아웃되었습니다';

  @override
  String get mainPressBackAgainToExit => '종료하려면 뒤로 버튼을 한 번 더 누르세요';

  @override
  String get languageSelectTitle => '언어 선택';

  @override
  String get languageChinese => '중국어(간체)';

  @override
  String get languageEnglish => '영어';

  @override
  String get searchTitle => '검색';

  @override
  String get searchHint => '숏드라마, 작품, 역할, 사용자 검색...';

  @override
  String get searchEmpty => '관련 콘텐츠가 없습니다';

  @override
  String get searchNoData => '관련 콘텐츠가 없습니다';

  @override
  String get searchPlaceholder => '숏드라마, 작품, 역할, 사용자 검색...';

  @override
  String get theaterSearchPlaceholder => '숏드라마, 작품, 역할, 사용자 검색...';

  @override
  String get searchHistory => '최근 검색';

  @override
  String get searchClear => '기록 지우기';

  @override
  String get searchAction => '검색';

  @override
  String get searchHistoryCleared => '검색 기록이 삭제되었습니다';

  @override
  String get searchKeywordTooShort => '최소 2자 이상 입력하세요';

  @override
  String get searchTabDramas => '숏드라마';

  @override
  String get searchTabWorks => '작품';

  @override
  String get searchTabActors => '캐릭터 IP';

  @override
  String get searchTabUsers => '사용자';

  @override
  String searchEpisodeNo(int episodeNo) {
    return '$episodeNo화';
  }

  @override
  String searchMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String searchHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String searchDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String searchDramasCount(int count) {
    return '드라마 ($count)';
  }

  @override
  String searchActorsCount(int count) {
    return '역할 ($count)';
  }

  @override
  String searchDramaEpisodesWithCast(int count, String actors) {
    return '전체 $count화 | 출연: $actors';
  }

  @override
  String get nftTitle => 'NFT 역할 광장';

  @override
  String get nftLoading => '캐릭터 IP 로딩 중...';

  @override
  String get nftEmpty => '캐릭터 IP가 없습니다';

  @override
  String get nftRefresh => '새로고침';

  @override
  String nftIdPrefix(String id) {
    return 'ID: #$id';
  }

  @override
  String get nftRarity => '레어리티';

  @override
  String get nftStatusStaked => '담보로 제공됨';

  @override
  String get nftStatusIdle => '대기 중';

  @override
  String get nftPrice => '가격';

  @override
  String get dramaDetailTitle => '드라마 상세';

  @override
  String get dramaDetailLoading => '로딩 중…';

  @override
  String get dramaDetailRetry => '다시 시도';

  @override
  String get dramaDetailEpisodeList => '드라마 목록';

  @override
  String get dramaDetailSynopsis => '줄거리';

  @override
  String get dramaDetailExpand => '펼치기';

  @override
  String get dramaDetailCollapse => '접기';

  @override
  String get dramaDetailTabIntro => '소개';

  @override
  String get dramaDetailTabEpisodes => '선집';

  @override
  String get dramaDetailTabComments => '댓글';

  @override
  String get dramaDetailTabRoles => '캐릭터 IP';

  @override
  String get dramaDetailSignMoreCharacterIps => '더 많은 캐릭터 IP 계약하기';

  @override
  String get dramaDetailCharactersEmpty => '아직 연결된 캐릭터 IP가 없습니다';

  @override
  String dramaDetailRoleSalary(String amount) {
    return '출연료 $amount';
  }

  @override
  String dramaDetailRoleSalaryPerHour(String amount) {
    return '출연료$amount STORY/h';
  }

  @override
  String get dramaDetailRoleUnbound => '미연결';

  @override
  String get dramaCastActorsTitle => '출연 캐릭터 IP';

  @override
  String dramaDetailCompletion(String count) {
    return '$count 완주';
  }

  @override
  String dramaDetailHeat(String count) {
    return '$count 히트';
  }

  @override
  String dramaDetailTotalEpisodes(int count) {
    return '$count 회차';
  }

  @override
  String get dramaDetailRatingTitle => '작품에 점수 매기기';

  @override
  String get dramaDetailWantToRate => '평가하기';

  @override
  String get dramaDetailNotRated => '미평가';

  @override
  String get dramaDetailCompletionLabel => '완주';

  @override
  String get dramaDetailHeatLabel => '히트';

  @override
  String get dramaDetailSynopsisLead => '줄거리: ';

  @override
  String get dramaDetailRatingEmpty => '내 평점: --';

  @override
  String dramaDetailRatingValue(int rating) {
    return '내 평점: $rating';
  }

  @override
  String get dramaDetailRatingConfirm => '평점 확인';

  @override
  String dramaDetailRatingSuccess(int rating) {
    return '평점 등록 성공: $rating점!';
  }

  @override
  String get dramaDetailSelectEpisodeHint => '회차를 선택하여 재생을 시작하세요';

  @override
  String get dramaFavorited => '즐겨찾기에 추가됨';

  @override
  String get dramaUnfavorited => '즐겨찾기에서 삭제됨';

  @override
  String get dramaLiked => '좋아요';

  @override
  String get dramaUnliked => '좋아요 취소';

  @override
  String get playerFollowed => '팔로우했습니다';

  @override
  String get playerUnfollowed => '팔로우를 취소했습니다';

  @override
  String get errorNetwork => '네트워크 오류, 나중에 다시 시도해 주세요';

  @override
  String get errorTimeout => '요청 시간이 초과되었습니다, 다시 시도해 주세요';

  @override
  String get errorParse => '응답 데이터 파싱에 실패했습니다';

  @override
  String get errorUnauthorized => '먼저 로그인해 주세요';

  @override
  String get authSessionExpired => '로그인 상태가 만료되었습니다. 다시 로그인해 주세요';

  @override
  String get errorNotFound => '리소스를 찾을 수 없습니다';

  @override
  String get iapOrderInFlight => '이 상품에 완료되지 않은 주문이 있습니다. 나중에 다시 시도해 주세요';

  @override
  String get errorOperationFailed => '작업에 실패했습니다';

  @override
  String get uploadErrorNetwork =>
      'The network is unstable. Check your connection and try again';

  @override
  String get uploadErrorTimeout =>
      'Upload timed out. Keep the app open and try again';

  @override
  String get uploadErrorSessionExpired =>
      'The upload credentials expired. Upload the file again';

  @override
  String get uploadErrorSessionUnavailable =>
      'An upload task could not be created. Try again';

  @override
  String get uploadErrorFileMissing =>
      'The local video was moved or removed. Select it again';

  @override
  String get uploadErrorUnauthorized =>
      'Your login or upload permission expired. Sign in and try again';

  @override
  String get uploadErrorRateLimited =>
      'Too many upload requests. Try again shortly';

  @override
  String get uploadErrorRejected =>
      'The upload service rejected this file. Check it and try again';

  @override
  String get uploadErrorServer =>
      'The upload service is temporarily unavailable. Try again later';

  @override
  String get uploadErrorInvalidResponse =>
      'The upload service returned an invalid response. Try again later';

  @override
  String get uploadErrorAccountChanged =>
      'The signed-in account changed. Upload again with the current account';

  @override
  String get uploadErrorUnknown => 'The video could not be uploaded. Try again';

  @override
  String get uploadErrorFileTypeNotAllowed => '不支持该视频格式，请重新选择';

  @override
  String get uploadErrorFileSizeExceeded => '文件过大，请重新选择';

  @override
  String get uploadErrorMultipartInvalid => '上传记录已失效，请重新上传';

  @override
  String get uploadStatusWaitingNetwork => '等待网络连接...';

  @override
  String get uploadStatusMerging => '正在合并视频...';

  @override
  String get uploadActionPause => '暂停';

  @override
  String get uploadActionResume => '继续上传';

  @override
  String get uploadCellularDialogMessage => '当前处于非 WiFi 网络，是否继续使用流量上传视频？';

  @override
  String get errorInvalidRoleId =>
      '캐릭터 ID가 유효하지 않습니다. 페이지를 새로고침한 후 다시 시도해 주세요.';

  @override
  String get errorInvalidRoleNftAssetId =>
      '캐릭터 NFT assetId가 유효하지 않습니다. 페이지를 새로고침한 후 다시 시도해 주세요.';

  @override
  String get errorInvalidRoleCollectionAssetId =>
      '캐릭터 컬렉션 assetId가 유효하지 않습니다. 페이지를 새로고침한 후 다시 시도해 주세요.';

  @override
  String get roleNftLabelUnknown => 'RoleNFT#Unknown';

  @override
  String roleNftLabel(String prefix) {
    return 'RoleNFT#$prefix';
  }

  @override
  String errorBusiness(String message) {
    return '작업 실패: $message';
  }

  @override
  String errorUnknown(String message) {
    return '알 수 없는 오류가 발생했습니다: $message';
  }

  @override
  String errorNotSupported(String message) {
    return '지원되지 않는 작업: $message';
  }

  @override
  String get playerEpisodeSelect => '선집';

  @override
  String get playerPlayFailed => '재생에 실패했습니다';

  @override
  String get playerDramaUnavailable => '이 드라마는 재생할 수 없어요';

  @override
  String get playerContentUnavailable => '이 콘텐츠는 게시되지 않았거나 더 이상 이용할 수 없습니다';

  @override
  String get creatorWorkNotFound => '작품이 존재하지 않아 볼 수 없습니다';

  @override
  String get creatorWorkNotPublished => '작품이 게시되지 않아 아직 볼 수 없습니다';

  @override
  String get creatorOfflineReasonUnavailable => '게시 중단 사유가 없습니다';

  @override
  String get playerTapRetry => '탭하여 다시 시도';

  @override
  String playerEpisodeTotal(int count) {
    return '총 $count화';
  }

  @override
  String playerEpisodeLabel(int episodeNo) {
    return '$episodeNo회차';
  }

  @override
  String get playerLike => '좋아요';

  @override
  String get playerComment => '댓글';

  @override
  String get playerFavorite => '즐겨찾기';

  @override
  String get playerShare => '공유';

  @override
  String playerShareDramaEpisode(
    String title,
    int episodeNo,
    String description,
    String url,
  ) {
    return '$title | $episodeNo화: $description $url . StoryFun에서 멋진 AI 숏드라마를 시청하세요.';
  }

  @override
  String playerShareDramaEpisodeNoDesc(
    String title,
    int episodeNo,
    String url,
  ) {
    return '$title | $episodeNo화 $url . StoryFun에서 멋진 AI 숏드라마를 시청하세요.';
  }

  @override
  String playerShareShortVideo(String description, String url) {
    return '$description $url. StoryFun에서 멋진 숏폼 영상을 시청하세요.';
  }

  @override
  String playerShareShortVideoNoDesc(String url) {
    return '$url. StoryFun에서 멋진 숏폼 영상을 시청하세요.';
  }

  @override
  String playerShareDrama(String title, String url) {
    return '$title $url . StoryFun에서 멋진 AI 숏드라마를 시청하세요.';
  }

  @override
  String playerShareDramaNoTitle(String url) {
    return '$url . StoryFun에서 멋진 AI 숏드라마를 시청하세요.';
  }

  @override
  String playerRatingLabel(String rating) {
    return '$rating 포인트';
  }

  @override
  String get loginOrSignUp => '로그인 또는 회원가입';

  @override
  String get loginEnterCode => '인증 코드 입력';

  @override
  String loginCheckEmailDesc(String email) {
    return '$email에서 privy.io의 이메일을 확인하고 아래에 코드를 입력해 주세요.';
  }

  @override
  String loginResendCountdown(int seconds) {
    return '코드 재전송 $seconds초';
  }

  @override
  String get loginResendBtn => '재전송';

  @override
  String get loginProtectedByPrivy => 'Privy로 보호됨';

  @override
  String get loginAgreeLead => '다음에 동의합니다';

  @override
  String get loginAgreeAnd => '및';

  @override
  String get loginAgreeConfirmLead => '확인을 누르면 다음에 동의한 것으로 간주됩니다';

  @override
  String get loginAgreeRequired => '먼저 서비스 약관과 개인정보 처리방침에 동의해 주세요';

  @override
  String get deletingAccountPending => '계정 삭제 대기 중';

  @override
  String get deletingAccountCancelDeletion => '계정 삭제 취소';

  @override
  String get deletingAccountGoBack => '뒤로';

  @override
  String get drawerEmailAccount => '이메일 계정';

  @override
  String get drawerClickToLogin => '탭하여 로그인';

  @override
  String get drawerBuyStory => 'STORY 거래';

  @override
  String get drawerDeposit => '충전';

  @override
  String get drawerWithdraw => '출금';

  @override
  String get drawerNotifications => '알림';

  @override
  String get drawerNoNotifications => '알림이 없습니다';

  @override
  String get notificationTabSystem => '시스템';

  @override
  String get notificationTabInteraction => '활동';

  @override
  String get notificationTagIpSign => '캐릭터 IP 계약';

  @override
  String get notificationTagRoleManagement => '캐릭터 관리';

  @override
  String get notificationTagShowRevenue => '공연 수익';

  @override
  String get notificationTagLike => '좋아요';

  @override
  String get notificationTagFavorite => '즐겨찾기';

  @override
  String notificationSignedActor(String user, String actor) {
    return '@$user님이 캐릭터 IP $actor와 계약했습니다';
  }

  @override
  String notificationShareEarned(String amount) {
    return '분배금 $amount을 획득했습니다';
  }

  @override
  String notificationStaminaLow(String actor) {
    return '\'$actor의 체력이 부족합니다. 충전하거나 쉬게 해 주세요\'';
  }

  @override
  String notificationCurrentStamina(String value) {
    return '현재 체력 $value';
  }

  @override
  String notificationShowEnded(String range) {
    return '$range 공연이 종료되었습니다';
  }

  @override
  String notificationIncomeEarned(String amount) {
    return '수익 $amount을 획득했습니다';
  }

  @override
  String get notificationActionClaim => '받기';

  @override
  String get notificationActionRefill => '충전';

  @override
  String get notificationInteractionLikedVideo => '내 동영상을 좋아합니다';

  @override
  String notificationInteractionLikedDrama(String title) {
    return '내 숏드라마 ‘$title’을 좋아합니다';
  }

  @override
  String get notificationInteractionFavoritedVideo => '내 동영상을 저장했습니다';

  @override
  String notificationInteractionFavoritedDrama(String title) {
    return '내 숏드라마 ‘$title’을 저장했습니다';
  }

  @override
  String notificationInteractionCommented(String content) {
    return '댓글을 남겼습니다: $content';
  }

  @override
  String get notificationInteractionFollowedYou => '나를 팔로우했습니다';

  @override
  String get notificationActionMutualFollow => '맞팔';

  @override
  String get notificationActionFollow => '팔로우';

  @override
  String get notificationDelete => '삭제';

  @override
  String get notificationDeleteFailed => '삭제하지 못했습니다. 잠시 후 다시 시도해 주세요';

  @override
  String get notificationRealtimeReceived => '새 알림이 도착했습니다';

  @override
  String drawerEpisodeProgress(int current, int total) {
    return '$current/$total회';
  }

  @override
  String drawerNotificationSignedActor(String actor, String target) {
    return '$actor님이 캐릭터 IP $target와 계약했습니다';
  }

  @override
  String drawerNotificationLikedVideo(String actor) {
    return '$actor님이 내 동영상을 좋아합니다';
  }

  @override
  String drawerNotificationFavoritedDrama(String actor, String target) {
    return '$actor님이 내 숏드라마 $target을 저장했습니다';
  }

  @override
  String get depositTitle => '충전';

  @override
  String get insufficientBalanceTitle => '잔액 부족';

  @override
  String insufficientBalanceDetail(String currency, String amount) {
    return '$currency 잔액이 부족합니다. $amount $currency가 더 필요합니다';
  }

  @override
  String get insufficientBalancePrompt => '충전하시겠습니까?';

  @override
  String get insufficientBalanceRecharge => '충전하기';

  @override
  String get depositDesc =>
      '거래소나 다른 지갑에서 아래 주소로 전송해 주세요. 입금이 확인되면 잔액이 자동으로 업데이트됩니다.';

  @override
  String get depositToken => '통화';

  @override
  String get depositNetwork => '네트워크';

  @override
  String get depositNetworkNote =>
      '전송 네트워크를 확인해 주세요. 잘못된 네트워크로 전송하면 자산이 손실될 수 있습니다.';

  @override
  String get depositAddress => '입금 주소';

  @override
  String get depositAddressCopied => '주소가 클립보드에 복사되었습니다';

  @override
  String get depositSend => '보내기';

  @override
  String get depositReceive => '받기';

  @override
  String get depositConvertNote =>
      '이 주소로 토큰을 보내면 Story.fun 계정에서 자동으로 USDC로 전환됩니다.';

  @override
  String depositMinNote(String minAmount, String token) {
    return '최소 입금액: $minAmount $token';
  }

  @override
  String depositExchangeRateNote(String rate) {
    return '현재 환율은 $rate입니다. 실제 입금액 = 입금액 × $rate';
  }

  @override
  String get depositWarning =>
      '선택한 네트워크의 선택한 토큰만 입금하세요. 다른 자산은 복구할 수 없습니다.\n전송 네트워크를 확인해 주세요. 네트워크 오류로 자산이 손실될 수 있습니다.';

  @override
  String get withdrawTitle => '출금';

  @override
  String get withdrawBalance => '출금 가능 잔액';

  @override
  String get withdrawToken => '통화';

  @override
  String get withdrawAddress => '출금 주소';

  @override
  String get withdrawAddressHint => 'Solana 수신 주소를 입력하거나 붙여넣어 주세요';

  @override
  String get withdrawAddressHintEvm => 'EVM 수신 주소를 입력하거나 붙여넣어 주세요';

  @override
  String get withdrawInvalidEvmAddress => '유효한 EVM 주소를 입력해 주세요';

  @override
  String get withdrawInvalidSolanaAddress => '유효한 Solana 주소를 입력해 주세요';

  @override
  String get withdrawEvmGasNote =>
      'EVM 출금에는 가스비용으로 쓸 네이티브 토큰이 필요합니다. 거래는 온체인으로 바로 전송됩니다.';

  @override
  String get withdrawEvmFailed => 'EVM 출금에 실패했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get withdrawAddressNote => '주소가 정확한지 확인해 주십시오. 입금 후에는 환불이 불가능합니다.';

  @override
  String get withdrawNetwork => '네트워크';

  @override
  String get withdrawAmount => '금액';

  @override
  String get withdrawAmountHint => '출금 금액을 입력해 주세요';

  @override
  String get withdrawMax => '최대';

  @override
  String withdrawAvailableBalance(String balance, String token) {
    return '잔액 $balance $token';
  }

  @override
  String withdrawMinWarning(String minAmount, String token) {
    return '최소 출금: $minAmount $token\n주소와 네트워크를 신중히 확인해 주세요. 거래는 취소할 수 없습니다.';
  }

  @override
  String get withdrawConfirm => '출금 확인';

  @override
  String get withdrawAll => '전체';

  @override
  String withdrawMinAmountError(String minAmt, String token) {
    return '최소 출금 금액은 $minAmt $token입니다';
  }

  @override
  String get withdrawExceedBalanceError => '출금 금액은 사용 가능한 잔액을 초과할 수 없습니다';

  @override
  String get withdrawSameAsWalletError => '출금 주소는 현재 지갑 주소와 같을 수 없습니다';

  @override
  String get withdrawConfirmTitle => '출금 확인';

  @override
  String withdrawConfirmMessage(String amount, String token, String address) {
    return '다음 Solana 주소로 $amount $token를 출금하시겠습니까?\n\n$address';
  }

  @override
  String get withdrawSuccessToast => '출금 요청이 성공적으로 제출되었습니다!';

  @override
  String get withdrawFailedToast => '출금에 실패했습니다. 다시 시도해 주세요.';

  @override
  String withdrawErrorToast(String error) {
    return '출금 중 오류가 발생했습니다: $error';
  }

  @override
  String withdrawAddressHintWithToken(String token) {
    return '$token을 수신할 지갑 주소를 입력하세요';
  }

  @override
  String get withdrawFee => '수수료';

  @override
  String withdrawFeeValue(String fee, String token) {
    return '$fee $token';
  }

  @override
  String withdrawMinAmount(String minAmount, String token) {
    return '최소 출금: $minAmount $token';
  }

  @override
  String withdrawMaxAmount(String maxAmount, String token) {
    return '최대 출금 금액: $maxAmount $token';
  }

  @override
  String get withdrawSponsorSigning => '트랜잭션 서명 중...';

  @override
  String get withdrawSponsorSubmitting => '온체인 트랜잭션 제출 중...';

  @override
  String get withdrawSponsorSuccess => '출금이 성공적으로 제출되었습니다!';

  @override
  String get withdrawSponsorFailed => '트랜잭션 제출에 실패했습니다. 다시 시도해 주세요.';

  @override
  String get withdrawOrderProcessing => '주문 처리 중';

  @override
  String get withdrawOrderSuccess => '주문 완료';

  @override
  String get withdrawOrderFailed => '주문 실패';

  @override
  String withdrawOrderStatus(String status) {
    return '주문 상태: $status';
  }

  @override
  String get qrScannerTitle => 'QR 코드 스캔';

  @override
  String get qrScannerHint => 'QR 코드를 프레임 안에 맞추어 스캔';

  @override
  String get drawerProfile => '내 계정';

  @override
  String get drawerCreatorManagement => '크리에이터 관리';

  @override
  String get drawerInvite => '초대';

  @override
  String get inviteTitle => '친구 초대';

  @override
  String get inviteTotalPeople => '누적 초대 인원';

  @override
  String get inviteTotalRewards => '총 초대 보상';

  @override
  String get inviteWeeklyPool => '이번 주 초대 보상 풀';

  @override
  String get inviteViewHistory => '수익 내역 보기';

  @override
  String get inviteShareSection => '전용 초대 링크 또는 초대 코드를 공유하세요';

  @override
  String get inviteLinkSection => '초대 링크';

  @override
  String get inviteLinkSubtitle =>
      '친구가 귀하의 링크로 가입하고, 캐릭터를 계약한 뒤 파견하면 귀하에게 추가 STORY 보상이 지급됩니다.';

  @override
  String get inviteCodeLabel => '초대 코드';

  @override
  String get inviteCopyButton => '링크 복사';

  @override
  String get inviteCopiedSuccess => '초대 링크가 클립보드에 복사되었습니다!';

  @override
  String get inviteCodeCopiedSuccess => '초대 코드가 클립보드에 복사되었습니다!';

  @override
  String get inviteInvitedLabel => '초대됨';

  @override
  String get inviteRewardLabel => '수익';

  @override
  String get inviteBindCode => '초대 코드 연결';

  @override
  String get inviteBindCodePromptHint => '건너뛴 후 초대 페이지에서 바인딩할 수 있습니다';

  @override
  String get inviteBindCodePlaceholder => '초대 코드 입력';

  @override
  String get inviteBindConfirm => '확인';

  @override
  String get inviteBindSuccess => '초대 코드가 연결되었습니다';

  @override
  String get inviteBindCodeInvalid => '초대 코드가 유효하지 않습니다';

  @override
  String get inviteBindCodeAlreadyBound => '이 계정은 이미 초대 코드를 연결했습니다';

  @override
  String get inviteRulesSection => '초대 규칙';

  @override
  String get inviteFaqPoolTitle => '주간 초대 보상 풀이란?';

  @override
  String get inviteFaqPoolBody =>
      '주간 초대 보상 풀은 초대 활동을 위해 마련된 독립 보상 풀입니다. 해당 주의 초대 행위에 대해 보상하며, 피초대자의 수익에서 차감되지 않습니다. 풀에는 주간 지급 상한이 있으며, 상한 도달 후 지분에 따라 비례 축소됩니다. 통계는 매주 월요일에 다시 집계됩니다.';

  @override
  String get inviteFaqSettlementTitle => '초대 보상은 언제 정산되나요?';

  @override
  String get inviteFaqSettlementBody =>
      '초대 보상은 에이전트 페이지의 출연료와 같은 주기로 일괄 정산됩니다. 매주 월요일 00:00 (UTC)에 집계가 마감되며, 정산 후 수익 페이지에서 수령할 수 있습니다.';

  @override
  String get inviteRuleSourceTitle => '보상 출처';

  @override
  String get inviteRuleSourceSubtitle => '독립된 하위 풀 초대';

  @override
  String get inviteRuleSourceBody =>
      '초대 보상은 NFT 채굴 풀 내의 독립된 초대 하위 풀(전체 채굴 풀의 25% 차지)에서 지급되며, 초대받은 사람의 수익에서 공제되지 않습니다. 초대 하위 풀에는 별도의 주간 상한선이 적용되며, 상한선에 도달하면 지분 비율에 따라 비례하여 감소합니다.';

  @override
  String get inviteRuleBaseTitle => '계산 기수';

  @override
  String get inviteRuleBaseSubtitle => '실제 수령액 기준 STORY';

  @override
  String get inviteRuleBaseBody =>
      '보상은 초대받은 사람이 해당 기간에 실제로 수령한 STORY를 기준으로 산정되며, 명목상 생산량을 기준으로 산정되지 않습니다. 초대받은 사람이 직접 채굴한 STORY에는 영향을 미치지 않으며, 초대 보상은 별도로 지급됩니다.';

  @override
  String get inviteRuleLevelTitle => '보상 범위';

  @override
  String get inviteRuleLevelSubtitle => '직접 초대만';

  @override
  String get inviteRuleLevelBody =>
      '초대 보상은 직접 초대한 사용자에게만 지급됩니다. 다단계 또는 간접 커미션은 없습니다.';

  @override
  String get inviteRuleConditionTitle => '유효 조건';

  @override
  String get inviteRuleConditionSubtitle => '실제 오프라인 활동 시에만 보상이 지급됩니다';

  @override
  String inviteRuleConditionBody(String currency) {
    return '초대받은 사람이 실제로 STORY를 채굴했거나 $currency 결제가 발생한 경우에만 유효한 하위 회원으로 인정됩니다. 유령 계정으로 등록한 경우 보상이 지급되지 않습니다. 초대 관계는 일단 설정되면 변경할 수 없습니다.';
  }

  @override
  String get drawerTxHistory => '거래 내역';

  @override
  String get drawerFinanceDashboard => '자금 대시보드';

  @override
  String get financeDashboardComingSoon => '자금 대시보드가 곧 출시될 예정입니다. 기대해 주세요.';

  @override
  String get financeDashboardPageTitle => '플랫폼 자금 대시보드';

  @override
  String financeDashboardTotalUsdcIncome(String currency) {
    return '총 USDC 수입';
  }

  @override
  String get financeDashboardTotalStoryReleased => '총 STORY 릴리스';

  @override
  String financeDashboardTabUsdcIncome(String currency) {
    return 'USDC 수입 상세';
  }

  @override
  String get financeDashboardTabVaultFunds => '금고 자금 누적';

  @override
  String get financeDashboardTabStoryRelease => 'STORY 릴리스 개요';

  @override
  String get financeDashboardFeeMint => '계약 수수료';

  @override
  String get financeDashboardFeeRoyalty => '2차 로열티';

  @override
  String get financeDashboardFeeItemPurchase => '아이템 구매';

  @override
  String get financeDashboardFeeTx => '거래 수수료';

  @override
  String get financeDashboardLedgerBizSigningFee => '계약 수수료';

  @override
  String get financeDashboardLedgerBizManualCredit => '수동 입금';

  @override
  String get financeDashboardLedgerBizManualDebit => '수동 차감';

  @override
  String get financeDashboardLedgerBizStaminaPurchase => '체력 구매 비용';

  @override
  String get financeDashboardLedgerBizSynthesisUpgrade => '합성 업그레이드 비용';

  @override
  String get financeDashboardLedgerBizTransactionFee => '거래 수수료';

  @override
  String financeDashboardRecentUsdcLedger(String currency) {
    return '최근 USDC 수입 내역';
  }

  @override
  String get financeDashboardViewMore => '더 보기';

  @override
  String get financeDashboardTotalVaultFunds => '총 금고 자금';

  @override
  String get financeDashboardCoveredActorIp => '대상 캐릭터 IP';

  @override
  String get financeDashboardActorVaultRanking => '캐릭터 IP 금고 순위';

  @override
  String get storyReleaseTabAllocation => 'STORY 총량 배분';

  @override
  String get storyReleaseTabMiningRelease => '최근 채굴 릴리스';

  @override
  String get storyReleaseFieldPeriod => '기간';

  @override
  String get storyReleaseFieldHardLimit => '주간 상한';

  @override
  String get storyReleaseFieldMiningRewards => '스테이킹 채굴';

  @override
  String get storyReleaseFieldInviteRewards => '초대 채굴';

  @override
  String get storyReleaseFieldUsageRate => '사용률';

  @override
  String get storyReleaseFieldTarget => '할당 대상';

  @override
  String get storyReleaseFieldRatio => '비율';

  @override
  String get storyReleaseFieldAmount => '수량';

  @override
  String get storyReleaseFieldReleased => '릴리스 완료';

  @override
  String get storyReleaseFieldProgress => '릴리스 진행률';

  @override
  String get storyReleaseCategoryNftMiningPool => 'NFT 채굴 풀';

  @override
  String get storyReleaseCategoryTeam => '팀';

  @override
  String get storyReleaseCategoryInvestors => '투자자';

  @override
  String get storyReleaseCategoryLiquidity => 'Launchpad + 유동성';

  @override
  String get storyReleaseCategoryTreasury => '재무 금고';

  @override
  String get storyReleaseCategoryMarketOps => '시장 운영';

  @override
  String storyReleaseTotalSupplyBadge(String total) {
    return '총량 $total STORY';
  }

  @override
  String get drawerWhitepaper => '백서';

  @override
  String get drawerSettings => '설정';

  @override
  String get commonClose => '닫기';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonLoadFailed => '로딩 실패';

  @override
  String get commonNone => '없음';

  @override
  String get commonUntitled => '제목 없음';

  @override
  String get actorDetailTitle => '배우 홈';

  @override
  String get actorDetailCastDramas => '단편 연극 출연';

  @override
  String get actorDetailTabCast => '출연';

  @override
  String get actorDetailTabInfo => '정보';

  @override
  String get actorDetailNoCastRecords => '출연 기록이 없습니다';

  @override
  String get actorBondingCurve => '가격 결합 곡선';

  @override
  String get actorContractAddress => '계약 주소';

  @override
  String get actorCurrentPosition => '현재 위치';

  @override
  String actorCurrentPrice(String price, String currency) {
    return '현재 가격 $price $currency';
  }

  @override
  String get actorFloorPrice => '최저가';

  @override
  String get actorGoTrade => '거래하기';

  @override
  String get profileWalletTrade => '거래하기';

  @override
  String get actorHeatCoefficient => '히트 계수';

  @override
  String get actorIpPower => 'IP 출연료';

  @override
  String get actorPayMax => '최대';

  @override
  String get actorPayUpgradeTitle => '출연료 인상 규칙';

  @override
  String get actorPayUpgradeReachHint =>
      '이 IP가 출연한 숏드라마의 현재 완주 수는 역할을 다음 레벨까지 업그레이드할 수 있습니다';

  @override
  String actorPayUpgradeCompletions(String count) {
    return '$count 완주';
  }

  @override
  String actorPayUpgradeMultiplier(String value) {
    return '출연료 ×$value';
  }

  @override
  String actorPayTitle(String name) {
    return '$name · 출연료';
  }

  @override
  String get actorLv1PayHint => '계약하면 Lv.1 캐릭터를 획득할 수 있습니다';

  @override
  String get actorLv1PayFormula => 'Lv.1 출연료 = 가격 계수 × 히트 계수';

  @override
  String actorLv1PayEquals(String value) {
    return '=$value';
  }

  @override
  String actorIpPowerTitle(String name) {
    return '$name · IP 출연료';
  }

  @override
  String get actorIpPowerFormula => 'IP 출연료 = 가격 계수 × 히트 계수 × Trust1';

  @override
  String get actorPriceCoefficient => '가격 계수';

  @override
  String actorPriceCoefficientValue(String value) {
    return '가격 계수 $value';
  }

  @override
  String get actorPriceCoefficientHelpA11y => '가격 계수 설명 보기';

  @override
  String get actorPriceUnitName => '포인트';

  @override
  String get actorPriceCoefficientDialogFormulaLe100 => '계수 = P0 ÷ 10';

  @override
  String get actorPriceCoefficientDialogDescLe100 => '선형 증가';

  @override
  String actorPriceCoefficientDialogTitleGt100(String currency) {
    return 'P0 > 10 $currency';
  }

  @override
  String get actorPriceCoefficientDialogFormulaGt100 =>
      '계수 = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]';

  @override
  String get actorPriceCoefficientDialogDescGt100 => '증가 속도가 완만해지며, 상한은 1.6';

  @override
  String actorPriceCoefficientDialogTitleLe100(String currency) {
    return 'P0 ≤ 10 $currency';
  }

  @override
  String actorPriceCoefficientFactorDesc(String currency1, String currency2) {
    return 'P0 ≤ 10 $currency1 계수= P0/10（선형 증가）\nP0 > 10 $currency2 → 계수 = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]（점근 상한 1.6）';
  }

  @override
  String get actorHeatCoefficientFactorDesc =>
      '캐릭터 IP의 최근 30일 히트 배수. 단편 드라마 완주, 좋아요, 즐겨찾기 등 상호작용에 따라 결정됩니다';

  @override
  String get actorTrustFactorDesc => '플랫폼 리스크 관리 계수, 기본값은 1.0';

  @override
  String get actorStatCompletion => '완주';

  @override
  String get actorIdCopied => '번호가 복사되었습니다';

  @override
  String actorInitialPrice(String price, String currency) {
    return '초기 가격: $price $currency';
  }

  @override
  String actorIpLabel(String label) {
    return '캐릭터 IP $label';
  }

  @override
  String get actorIssueInfo => '출시 정보';

  @override
  String actorIssuer(String name) {
    return '출시자 $name';
  }

  @override
  String actorMintedCount(int minted, int maxSupply) {
    return '발행 완료 $minted/$maxSupply';
  }

  @override
  String get actorPriceCurve => '가격 곡선';

  @override
  String get actorSign => '계약하기';

  @override
  String get actorConfirmSign => '계약 확인';

  @override
  String get actorSignPriceLabel => '계약 가격';

  @override
  String get actorSignPriceDescription =>
      '계약 수가 늘어남에 따라 계약 가격이 자동으로 상승합니다. 일찍 계약할수록 더 유리합니다.';

  @override
  String get actorSignPriceFormula => '공식: 가격 = 초기 가격 × 5^(계약 수 ÷ 총 발행량)';

  @override
  String actorPriceAxisLabel(String currency) {
    return '가격 ($currency)';
  }

  @override
  String get actorSignedCountAxisLabel => '계약 수';

  @override
  String actorSignRemainingCount(int count) {
    return '$count개 남았습니다';
  }

  @override
  String get actorSignSoldOut => '매진되었습니다';

  @override
  String actorSignSupplySummary(String total, String remaining) {
    return '총 출시 $total · 잔여 $remaining';
  }

  @override
  String get actorPricingFixed => '고정 가격';

  @override
  String get actorPricingCurve => '곡선 가격';

  @override
  String get actorPriceCurveDisclaimer =>
      '초기 가격은 플랫폼의 기업 가치를 나타내는 것이 아니며, 곡선의 상승이 2차 시장 가격의 상승을 의미하는 것도 아니며, 플랫폼은 수익을 보장하지 않습니다.';

  @override
  String get actorPriceStatInitialPrice => '초기 가격';

  @override
  String get actorPriceStatCurrentPrice => '현재 가격';

  @override
  String get actorPriceStatTailPrice => '낙찰가';

  @override
  String get actorPriceStatTotalSupply => '총 발행량';

  @override
  String get actorPriceStatSigned => '계약 완료';

  @override
  String get actorPriceStatRemaining => '남은';

  @override
  String get actorPricingType => '가격 책정 유형';

  @override
  String get contentBadgeOfficialIssue => '공식 출시';

  @override
  String get contentBadgeCommunityIssue => '커뮤니티 출시';

  @override
  String get contentBadgePartnerIssue => '파트너 출시';

  @override
  String get contentBadgeVerifiedIssue => '인증 크리에이터 출시';

  @override
  String get contentBadgeOfficialDrama => '공식 단편 드라마';

  @override
  String get contentBadgeCommunityDrama => '동네 단편 드라마';

  @override
  String get contentBadgePartnerDrama => '파트너사와의 단편 드라마';

  @override
  String get contentBadgeVerifiedDrama => '인증된 크리에이터의 단편 드라마';

  @override
  String get actorIpCopied => '복사 성공';

  @override
  String get actorRiskIp => '위험 IP';

  @override
  String get actorRiskIpDescription =>
      '이 캐릭터 IP의 신뢰 계수가 비정상입니다. 마이닝 가중치에 영향을 줍니다.';

  @override
  String get actorIpVault => '캐릭터 IP 금고';

  @override
  String get actorIpVaultDescription =>
      '계약 수익의 30%는 캐릭터 IP 금고로 자동 적립되어 IP 생태계의 장기적인 발전을 뒷받침합니다. 2차 시장 로열티 수익의 30%도 동일하게 금고에 적립되어 지속적인 자금 풀을 형성합니다. V1 버전 금고는 데이터 조회 기능만 제공하며, 당분간 배분은 진행되지 않습니다.';

  @override
  String get actorIpVaultSignIncomePrefix => '계약 수익 · 적립 ';

  @override
  String get actorIpVaultSecondaryRoyaltyPrefix => '2차 로열티 · 누적 ';

  @override
  String get actorFixedPriceDialogDesc =>
      '이 캐릭터 IP는 고정 가격 모델을 채택하며, 모든 캐릭터가 동일한 가격으로 계약되므로 판매량 변동에 따라 가격이 변동되지 않습니다.';

  @override
  String get actorCurvePriceDialogDesc =>
      '가격은 결합 곡선 공식에 따라 계약 수에 맞춰 자동으로 상승합니다. 일찍 계약할수록 더 유리합니다.';

  @override
  String get actorFixedPriceNote1 => '출시자가 고정 가격을 설정하면, 모든 계약은 해당 가격으로 정산됩니다.';

  @override
  String get actorFixedPriceNote2 => '계약 수가 늘어나도 가격이 오르지 않습니다.';

  @override
  String get actorFixedPriceNote3 => '비용을 고정하고자 하는 구매자에게 적합합니다';

  @override
  String get actorIssueFixedPriceDesc =>
      '해당 캐릭터 IP는 고정 가격 방식을 채택하며, 모든 계약은 판매량에 관계없이 고정 가격으로 정산됩니다.';

  @override
  String get actorSignSlippageNote =>
      '1% 슬리피지 보호 기능이 활성화되었으며, 가격이 이 범위를 벗어나면 거래가 취소됩니다.';

  @override
  String get actorSignSuccessTitle => '계약 완료!';

  @override
  String actorSignSuccessMessage(String name) {
    return '캐릭터 「$name」 계약이 완료되었습니다';
  }

  @override
  String actorSignSuccessNftId(String nftId) {
    return 'NFT 번호: $nftId';
  }

  @override
  String get actorSignChainConfigMissing => '온체인 설정이 불완전합니다. 나중에 다시 시도해 주세요.';

  @override
  String get actorSignPriceSoldOut => '계약 가격 · 매진';

  @override
  String actorSignPriceRemaining(int count) {
    return '계약 가격 · 재고 $count개';
  }

  @override
  String actorSignedCount(int count) {
    return '계약 체결 건수$count';
  }

  @override
  String get actorStatusLabelOffline => '오프라인';

  @override
  String get actorStatusLabelOnline => '온라인';

  @override
  String get actorStatusLabelPending => '검토 중';

  @override
  String get actorStatusLabelRejected => '거부됨';

  @override
  String get actorTotalSupply => '총 발행량';

  @override
  String get commentsAnonymous => '익명 사용자';

  @override
  String get commentsEmpty => '아직 댓글이 없습니다';

  @override
  String get commentsHint => '멋진 댓글을 작성...';

  @override
  String get commentsInvalidContent => '유효한 내용을 입력해 주세요';

  @override
  String get commentsReply => '답글';

  @override
  String commentsViewReplies(int count) {
    return '답글 $count개 보기';
  }

  @override
  String get commentsCollapseReplies => '접기';

  @override
  String get commentsViewMoreReplies => '더 보기';

  @override
  String commentsReplyHint(String nickname) {
    return '$nickname에게 답글';
  }

  @override
  String get commentsDeleteCommentTitle => '이 댓글을 삭제하시겠습니까?';

  @override
  String get commentsDeleteReplyTitle => '이 답글을 삭제하시겠습니까?';

  @override
  String get commentTagAuthor => '작가';

  @override
  String get commentTagMe => '나';

  @override
  String get commentTagFriend => '내 친구';

  @override
  String get commentTagFan => '내 팔로워';

  @override
  String get commentTagFirst => '첫 댓글';

  @override
  String get commentTagAuthorLiked => '작가가 좋아요';

  @override
  String commentsReplyTo(String nickname) {
    return '@$nickname에게 답글: ';
  }

  @override
  String get commentsReplyCommentNotExists => '댓글이 존재하지 않습니다';

  @override
  String get commentsBlockedByMe => '블랙리스트 사용자이므로 댓글을 달 수 없습니다';

  @override
  String get commentsBlockedByTarget => '상대방의 설정으로 인해 댓글을 달 수 없습니다';

  @override
  String get commentsTabComments => '댓글';

  @override
  String get commentsTabAllComments => '전체 댓글';

  @override
  String get commentsTabDramas => '단편 드라마';

  @override
  String get commentsTabActors => '캐릭터';

  @override
  String get timeJustNow => '방금 전';

  @override
  String get timeYesterday => '어제';

  @override
  String get timeDayBeforeYesterday => '그저께';

  @override
  String timeMinutesAgo(int count) {
    return '$count분 전';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count시간 전';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count일 전';
  }

  @override
  String commentsTitle(int count) {
    return '댓글 ($count)';
  }

  @override
  String get createActorTitle => '역할 만들기';

  @override
  String get createActorHeroTitle => '캐릭터 NFT 발행';

  @override
  String get createActorHeroSubtitle => '독점 AI 역할을 만들고 수익 배분을 연결하여 드라마에 참여';

  @override
  String get createActorNameLabel => '역할 이름';

  @override
  String get createActorNameHint => '역할 이름을 입력하세요';

  @override
  String get createActorBioLabel => '역할 소개';

  @override
  String get createActorBioHint => '캐릭터의 배경을 설명하세요';

  @override
  String get createActorGenderLabel => '성별';

  @override
  String get createActorGenderMale => '남자';

  @override
  String get createActorGenderFemale => '여성';

  @override
  String get createActorMintParams => 'NFT 발행 매개변수';

  @override
  String get createActorTokenStandard => '토큰 표준';

  @override
  String get createActorChain => '체인';

  @override
  String get createActorMinHolding => '최소 보유량';

  @override
  String get createActorMintNft => 'NFT 발행';

  @override
  String get createActorIpTitle => '캐릭터 IP 출시';

  @override
  String get createActorIpSubtitle =>
      '캐릭터 IP를 출시한 후 해당 IP 아래에서 캐릭터를 계약할 수 있으며, 계약한 캐릭터를 파견하여 수익을 창출할 수 있습니다.';

  @override
  String get createActorSelectMaterial => '역할 자료 선택';

  @override
  String get createActorDreamOsBadge => 'DreamOS로 이동';

  @override
  String get createActorSelectMaterialDesc =>
      'DreamOS 프로젝트 진입 → 캐릭터 생성 → Story.fun에서 IP 발행';

  @override
  String get createActorSelectButton => '역할 선택';

  @override
  String get createActorNameLabelNew => '역할 이름';

  @override
  String get createActorNamePlaceholder => '역할 이름 입력';

  @override
  String get createActorBioLabelNew => '소개';

  @override
  String get createActorBioPlaceholder => '캐릭터 IP 소개를 입력해 주세요';

  @override
  String get createActorParamsTitle => '캐릭터 IP 출시 매개변수';

  @override
  String get createActorParamsSubtitle =>
      '캐릭터 IP 출시 매개변수를 설정합니다. 출시 후에는 수정할 수 없습니다.';

  @override
  String get createActorTotalSupplyLabel => '캐릭터 총 발행량';

  @override
  String get createActorTotalSupplyDesc => '총 발행량 범위: 100 - 5,000.';

  @override
  String get createActorTotalSupplyPlaceholder => '100 - 5,000';

  @override
  String get createActorPricingFixed => '고정 가격';

  @override
  String get createActorPricingCurve => '곡선 가격';

  @override
  String createActorFixedPriceLabel(String currency) {
    return '고정 가격  ($currency)';
  }

  @override
  String createActorInitialPriceLabel(String currency) {
    return '초기 가격 ($currency)';
  }

  @override
  String get createActorFixedPricePlaceholder => '10 - 1,000';

  @override
  String get createActorFixedPriceDesc =>
      '모든 캐릭터는 고정된 가격으로 구매되며, 판매량에 따라 변동되지 않습니다.';

  @override
  String get createActorInitialPricePlaceholder => '10 - 1,000';

  @override
  String get createActorInitialPriceDesc =>
      '초기 가격은 결합 곡선의 시작 가격입니다. 캐릭터를 1명 계약할 때마다 가격은 P = P₀ × 5^(계약 수 ÷ 총 발행량) 공식에 따라 자동으로 상승하므로, 일찍 계약할수록 더 유리합니다.';

  @override
  String get createActorFormIncomplete => '먼저 캐릭터 소재, 이름, 소개, 출시 매개변수를 입력해 주세요';

  @override
  String get createActorValidationNameRequired => '역할 이름을 입력해 주세요';

  @override
  String get createActorValidationNameTooLong => '캐릭터 이름은 20자 이하여야 합니다';

  @override
  String get createActorValidationBioRequired => '소개를 입력해 주세요';

  @override
  String get createActorValidationBioTooLong => '소개는 500자 이하여야 합니다';

  @override
  String get createActorValidationTotalSupplyRequired =>
      '유효한 NFT 총 발행량을 입력해 주세요';

  @override
  String get createActorValidationTotalSupplyPositiveInteger =>
      'NFT 총 발행량은 양의 정수여야 합니다';

  @override
  String get createActorValidationTotalSupplyRange =>
      '캐릭터 총 발행량은 100~5,000 사이여야 합니다';

  @override
  String get createActorValidationPriceRequired => '유효한 발행 가격을 입력해 주세요';

  @override
  String get createActorValidationPriceInvalid =>
      'Mint 가격은 10 이상 1,000 이하여야 합니다';

  @override
  String get createActorValidationPriceMaxDecimals =>
      '발행 가격은 소수점 이하 2자리까지 가능합니다';

  @override
  String get createActorSelectMaterialRequired => '캐릭터 소재를 선택해 주세요';

  @override
  String get createActorCancelButton => '취소';

  @override
  String get createActorConfirmButton => '출시 확정';

  @override
  String get createActorIssueFee => '수수료';

  @override
  String createActorSuccessTitle(String name) {
    return '$name · 출시 성공!';
  }

  @override
  String createActorSuccessDesc(String id) {
    return '캐릭터 IP $id';
  }

  @override
  String get createActorSuccessTip => '발행자도 계약해야 이 캐릭터를 얻을 수 있어요~';

  @override
  String get createActorCloseButton => '나중에';

  @override
  String get createActorViewButton => '계약하기';

  @override
  String get createActorEmptyTitle =>
      '아직 DreamOS에서 조건을 충족하고 시스템이 자동 생성한 NFT 출시가 없습니다.';

  @override
  String get createActorGotoDreamOs => 'DreamOS로 이동하여 생성하기';

  @override
  String get createActorSearchPlaceholder => '캐릭터 소재 검색';

  @override
  String get createActorInvalidOrderId =>
      '캐릭터 IP 주문 번호가 유효하지 않습니다. 새로고침 후 다시 시도해 주세요';

  @override
  String get createDramaTitle => '드라마 만들기';

  @override
  String get createDramaTitleLabel => '단편 드라마 제목';

  @override
  String get createDramaTitleHint => '드라마 이름을 입력하세요';

  @override
  String get createDramaSynopsisLabel => '줄거리';

  @override
  String get createDramaSynopsisHint => '어떤 이야기를 다룰 것인가... (최대 1,000자)';

  @override
  String get createDramaAiSettings => 'AI 생성 설정';

  @override
  String get createDramaVisualStyle => '비주얼 스타일';

  @override
  String get createDramaVisualStyleRealistic => '실사';

  @override
  String get createDramaEpisodeDuration => '회차 시간';

  @override
  String get createDramaEpisodeDurationValue => '3-5분';

  @override
  String get createDramaTotalEpisodes => '총 회차';

  @override
  String get createDramaTotalEpisodesValue => '8회';

  @override
  String get createDramaGenreLabel => '유형';

  @override
  String get createDramaGenreDrama => '드라마';

  @override
  String get createDramaGenreComedy => '코미디';

  @override
  String get createDramaGenreAction => '액션';

  @override
  String get createDramaGenreRomance => '로맨스';

  @override
  String get createDramaGenreSciFi => '공상과학';

  @override
  String get createDramaGenreMystery => '미스터리';

  @override
  String get createDramaGenreHorror => '호러';

  @override
  String get createDramaGenreAnimation => '애니메이션';

  @override
  String get createDramaHeroTitle => 'AI 드라마 제작';

  @override
  String get createDramaHeroSubtitle => '원클릭으로 다음 히트 드라마 생성';

  @override
  String get createDramaStartGeneration => '생성 시작';

  @override
  String get creatorDramaManagementTab => '단편 드라마 관리';

  @override
  String get creatorDramaNftTab => '숏폼 영상 NFT';

  @override
  String get creatorHeaderSubtitle => '단편 드라마 게시, 검토 및 제작.';

  @override
  String get creatorV2Subtitle => '숏드라마/동영상 게시 및 관리.';

  @override
  String creatorV2DramaTabCount(int count) {
    return '숏드라마($count)';
  }

  @override
  String creatorV2VideoTabCount(int count) {
    return '동영상($count)';
  }

  @override
  String get creatorV2NoVideos => '동영상이 없습니다';

  @override
  String get creatorLoginPrompt => '로그인하여 크리에이션을 확인하세요';

  @override
  String get creatorNoCreatedActors => '만든 역할이 없습니다';

  @override
  String get creatorNoPublishedDramas => '게시한 드라마가 없습니다';

  @override
  String get creatorOwnedNftCount => '보유 중인 NFT 수';

  @override
  String get creatorCreateDrama => '드라마 제작';

  @override
  String get creatorPublishNewDrama => '새로운 단편 드라마 게시';

  @override
  String get creatorPublishedDramas => '단편 드라마 게시';

  @override
  String get creatorReviewFilterAll => '전체';

  @override
  String get creatorReviewFilterApproved => '통과됨';

  @override
  String get creatorReviewFilterPending => '검토 중';

  @override
  String get creatorReviewFilterRejected => '불합격';

  @override
  String get creatorReviewFilterOffline => '게시 중단';

  @override
  String get creatorDramaOtherReason => '기타 사유';

  @override
  String get creatorDramaStatusOnline => '통과됨';

  @override
  String get creatorDramaStatusPendingReview => '심사 중';

  @override
  String get creatorDramaStatusReviewRejected => '불합격';

  @override
  String get creatorDramaStatusPendingOnline => '온라인 대기 중';

  @override
  String creatorDramaAuditReason(Object reason) {
    return '심사 불합격 사유: $reason';
  }

  @override
  String get creatorDramaNftMinted => '이미 주조됨';

  @override
  String creatorDramaEpisodeCount(int count) {
    return '$count 편';
  }

  @override
  String get creatorDramaEdit => '편집';

  @override
  String get creatorDramaDelete => '삭제';

  @override
  String get creatorActorDelete => '역할 삭제';

  @override
  String get creatorDeleteDramaConfirm => '이 단편 영상을 삭제하시겠습니까?';

  @override
  String get creatorDeleteVideoConfirmTitle => '동영상 삭제 확인';

  @override
  String creatorDeleteVideoConfirmMessage(String name) {
    return '“$name”을(를) 삭제하시겠습니까?\n이 작업은 취소할 수 없습니다.';
  }

  @override
  String get creatorDeleteActorConfirm => '이 캐릭터를 삭제하시겠습니까?';

  @override
  String get creatorDeleting => '삭제 중...';

  @override
  String get creatorNoDramas => '현재 단편 드라마가 없습니다';

  @override
  String get creatorNoNfts => '현재 단편 드라마 NFT는 없습니다.';

  @override
  String get creatorsComingSoon => '출시 예정';

  @override
  String get creatorsHeroSubtitle => '뛰어난 크리에이터를 발견하세요';

  @override
  String get creatorsHeroTitle => '크리에이터';

  @override
  String get dramaBatchUnlockAll => '모두 해제';

  @override
  String dramaBatchUnlockDiscount(String discount) {
    return '일괄 해제 할인 $discount%';
  }

  @override
  String get dramaBatchUnlockSubtitle => '모든 회차를 한 번에 해제하여 더 저렴하게';

  @override
  String get dramaBatchUnlockSuccess => '해제 성공, 시청을 시작하세요';

  @override
  String get dramaDetailAllFree => '모두 무료';

  @override
  String dramaDetailBoundActors(int count) {
    return '$count명의 역할 연결됨';
  }

  @override
  String dramaDetailEpisodeCount(int count) {
    return '$count 편';
  }

  @override
  String get dramaDetailEpisodePrice => '회당 가격';

  @override
  String get dramaDetailFree => '무료';

  @override
  String dramaDetailFreeEpisodes(int count) {
    return '첫 $count화 무료';
  }

  @override
  String get dramaDetailMainCharacters => '주요 역할';

  @override
  String get dramaDetailNftMinted => 'NFT 발행됨';

  @override
  String get dramaDetailNoEpisodes => '회차가 없습니다';

  @override
  String get dramaDetailPaid => '유료';

  @override
  String get dramaDetailPendingActor => '캐릭터 미정';

  @override
  String get dramaDetailRoleCount => '캐릭터 수';

  @override
  String get dramaUnlockFailedRetry => '해제에 실패했습니다, 다시 시도해 주세요';

  @override
  String get dramaUnlockFetchTimeout => '재생 주소 가져오기 시간 초과, 다시 시도해 주세요';

  @override
  String get dramaUnlockLoginRequired => '회차를 해제하려면 로그인해 주세요';

  @override
  String dramaUnlockMessage(
    int epNo,
    String price,
    String discount,
    String currency,
  ) {
    return '$epNo화는 해제에 결제가 필요합니다\n가격: $price $currency\n일괄 해제 할인: $discount';
  }

  @override
  String get dramaUnlockSuccessFetching => '해제 성공, 재생 주소 가져오는 중...';

  @override
  String get dramaUnlockTitle => '에피소드 잠금 해제';

  @override
  String get editActorTitle => '역할 편집';

  @override
  String get editDramaTitle => '단편 드라마 편집';

  @override
  String get editVideoTitle => '동영상 편집';

  @override
  String get editSaveChanges => '변경 사항 저장';

  @override
  String get editProfileTitle => '프로필 편집';

  @override
  String get editNicknameLabel => '닉네임';

  @override
  String get editRoleNameLabel => '사용자 이름';

  @override
  String get editNicknameHint => '닉네임을 입력하세요';

  @override
  String get editNicknameRequired => '닉네임을 입력해 주세요';

  @override
  String get editProfileBioLabel => '소개';

  @override
  String get editProfileBioHint => '소개를 입력해 주세요';

  @override
  String get editProfileEmailLabel => '이메일 주소';

  @override
  String get editAvatarCropTitle => '아바타 자르기';

  @override
  String get profileUpdateSuccess => '프로필이 업데이트되었습니다';

  @override
  String incomeClaimAmount(String amount, String currency) {
    return '$amount $currency 청구';
  }

  @override
  String get incomeClaimFailed => '청구 실패';

  @override
  String incomeClaimMessage(String amount, String currency) {
    return '청구 가능 금액: $amount $currency\n수익이 지갑 잔액으로 이체됩니다';
  }

  @override
  String get incomeClaimSuccess => '청구 성공';

  @override
  String get incomeClaimTitle => '수익 수령';

  @override
  String get incomeConfirmClaim => '수령 확인';

  @override
  String get incomeHistoryTab => '기록';

  @override
  String get incomeInviteHeroSubtitle =>
      '친구를 초대하여 소비와 인터랙션을 유도하고, 초대자가 활발할수록 보상이 높아집니다';

  @override
  String get incomeInviteHeroTitle => '친구 초대하여 캐시백 받기';

  @override
  String get incomeInviteNoRecords => '캐시백 기록이 없습니다';

  @override
  String get incomeInvitePaidUnlockDesc => '친구가 회차 해제에 결제';

  @override
  String get incomeInvitePaidUnlockTitle => '유료 해제';

  @override
  String get incomeInviteRecords => '캐시백 기록';

  @override
  String get incomeInviteRegisterDesc => '친구가 추천 링크를 통해 가입';

  @override
  String get incomeInviteRegisterTitle => '초대 가입';

  @override
  String get incomeInviteRules => '캐시백 규칙';

  @override
  String get incomeInviteShareLink => '초대 링크 공유';

  @override
  String get incomeInviteStakeDesc => '친구가 NFT 또는 STORY를 스테이킹';

  @override
  String get incomeInviteStakeTitle => '스테이킹 투자';

  @override
  String get incomeInviteTab => '초대 캐시백';

  @override
  String get incomeInviteWatchDesc => '친구가 드라마를 시청하여 포인트 획득';

  @override
  String get incomeInviteWatchTitle => '드라마 시청';

  @override
  String get incomeNoHistory => '기록이 없습니다';

  @override
  String get incomeNoRecords => '수익 기록이 없습니다';

  @override
  String get incomeNothingToClaim => '청구할 것이 없습니다';

  @override
  String get incomeOverviewTab => '개요';

  @override
  String get incomePendingClaim => '청구 대기';

  @override
  String get incomeRecords => '수익 기록';

  @override
  String get incomeThisMonth => '이번 달';

  @override
  String get incomeToday => '오늘';

  @override
  String get incomeTotalEarnings => '누적 수익';

  @override
  String get incomeCumulativeStory => '누적 STORY';

  @override
  String incomeCumulativeUsdc(String currency) {
    return '누적 $currency';
  }

  @override
  String get incomeClaimableStory => 'STORY 수령 가능';

  @override
  String incomeClaimableUsdc(String currency) {
    return '$currency를 수령할 수 있습니다';
  }

  @override
  String get incomeSettlingStory => '내 출연료';

  @override
  String get incomeSettlingHint => '정산 중; 도착 후 청구 가능';

  @override
  String get incomeHelpTotalStoryDesc =>
      '역사의 모든 주기 동안 누적된 STORY 총량(수령한 분량과 미수령한 분량 포함).';

  @override
  String incomeHelpTotalUsdcDesc(String currency) {
    return '역대 모든 캐릭터의 계약 수익 분배 및 2차 로열티로 발생한 누적 $currency 수익.';
  }

  @override
  String get incomeHelpSettlingStoryDesc => '시스템 정산 후 자동으로 STORY로 교환됩니다';

  @override
  String get incomeHelpClaimableStoryDesc =>
      '결제가 완료된 STORY는 개인 지갑으로 수령할 수 있습니다.';

  @override
  String incomeHelpClaimableUsdcDesc(String currency) {
    return '정산된 $currency는 개인 지갑으로 수령할 수 있습니다.';
  }

  @override
  String get incomeFilterAll => '전체';

  @override
  String get incomeFilterMining => '파견 수익';

  @override
  String get incomeFilterInvite => '초대 수익';

  @override
  String get incomeMiningReward => '파견 수익';

  @override
  String get incomeInviteReward => '초대 수익';

  @override
  String get incomeUsdcActorSignShare => '캐릭터 계약 수익 분배';

  @override
  String get incomeClaimNoWallet => '먼저 지갑을 연결해 주세요';

  @override
  String incomeClaimCurrencyTitle(String currency) {
    return '$currency 청구';
  }

  @override
  String incomeClaimWithdrawMessage(
    String amount,
    String currency,
    String address,
  ) {
    return 'Solana 지갑으로 $amount $currency를 출금하시겠습니까?\n수신자: $address';
  }

  @override
  String get incomeClaimWithdrawConfirm => '출금 확인';

  @override
  String get incomeClaimWithdrawSubmitted => '출금 성공!';

  @override
  String get incomeClaimWithdrawFailed => '출금 실패, 다시 시도해 주세요';

  @override
  String get incomeClaimAction => '수령';

  @override
  String get nftCreateActorIp => '캐릭터 IP 생성';

  @override
  String get nftHeaderSubtitle => '독점 캐릭터 NFT를 탐색하고 수집하세요';

  @override
  String get nftHeaderTitle => '캐릭터 NFT 광장';

  @override
  String get nftSearchHint => '숏드라마, 작품, 역할, 사용자 검색...';

  @override
  String get actorHowToPlayTitle => '캐릭터 IP는 어떻게 활용하나요?';

  @override
  String get actorHowToPlayHelpTooltip => '게임 방법 안내';

  @override
  String get actorHowToPlaySignTab => '계약 IP';

  @override
  String get actorHowToPlaySignSubtitle => '출연료 자동 수령';

  @override
  String get actorHowToPlayIssueTab => 'IP 출시';

  @override
  String get actorHowToPlayIssueSubtitle => '창작을 통한 수익 창출';

  @override
  String get actorHowToPlaySignPositioning =>
      '포지셔닝: 창작 진입 장벽 제로, 손쉽게 안정적인 수익 창출';

  @override
  String get actorHowToPlaySignAudience =>
      '창작은 하고 싶지 않고, 진입 장벽이 낮은 방법으로 STORY 수익을 얻고 싶은 일반 사용자';

  @override
  String get actorHowToPlaySignGuide =>
      '히트가 높고 출연료가 높은 캐릭터 IP와 계약한 후, 에이전트 페이지에서 출연을 예약하기만 하면 수익을 얻을 수 있습니다';

  @override
  String get actorHowToPlaySignRightsTitle => '이중 수익';

  @override
  String get actorHowToPlaySignRightPerform =>
      '공연을 기획하고, 지속적으로 STORY 토큰을 획득하세요';

  @override
  String get actorHowToPlaySignRightTrade =>
      '캐릭터 IP는 거래가 가능하며, 프리미엄 수익을 창출할 수 있습니다.';

  @override
  String get actorHowToPlayIssuePositioning =>
      '포지셔닝: 창작·출시, 다중 수익, IP 장기 가치 상승';

  @override
  String get actorHowToPlayIssueAudience =>
      '창작 능력이 있으며, 캐릭터 IP나 숏폼 콘텐츠를 통해 수익을 창출하고자 하는 크리에이터';

  @override
  String get actorHowToPlayIssueGuide =>
      '캐릭터 IP를 출시하고 AI 단편 드라마와 연계해 작품 히트를 높여 IP 출연료와 수익을 끌어올립니다';

  @override
  String get actorHowToPlayIssueRightsTitle => '3중 수익';

  @override
  String get actorHowToPlayIssueRightSignLabel => '계약 수익 분배:';

  @override
  String get actorHowToPlayIssueRightSign => '자체 IP가 계약되면 40% 수익 분배를 받습니다';

  @override
  String get actorHowToPlayIssueRightPerformLabel => '공연 수익:';

  @override
  String get actorHowToPlayIssueRightPerform => '자체 IP와 계약하고, 공연으로 STORY를 벌기';

  @override
  String get actorHowToPlayIssueRightValueLabel => '부가가치:';

  @override
  String get actorHowToPlayIssueRightValue =>
      'IP는 거래 가능하며, 히트가 높을수록 프리미엄도 높아집니다';

  @override
  String get actorHowToPlayAudienceTitle => '적합한 대상';

  @override
  String get actorHowToPlayGuideTitle => '플레이 가이드';

  @override
  String get actorHowToPlayCreateHint =>
      'DreamOS를 사용하면 한 번의 클릭으로 캐릭터 IP와 AI 단편 드라마를 생성하여, 고품질 콘텐츠를 효율적으로 제작할 수 있습니다.';

  @override
  String get actorHowToPlayCreateCta => '창작하기';

  @override
  String get nftSignInDevelopment => '이 기능은 아직 제공되지 않습니다.';

  @override
  String get nftSortCompleted => '완주';

  @override
  String get nftSortHeat => '히트';

  @override
  String get nftSortIpPower => 'IP 출연료';

  @override
  String get nftSortLowestPrice => '가격';

  @override
  String get nftSortLv1Pay => '출연료';

  @override
  String get nftSortMaxPay => '최대 출연료';

  @override
  String get nftTradeUnavailable => '거래는 아직 이용할 수 없습니다';

  @override
  String playerEpisodeBarCompleted(int count) {
    return '전 $count화 · 완료';
  }

  @override
  String playerEpisodeSynopsis(int episodeNo, String synopsis) {
    return '$episodeNo화 | $synopsis';
  }

  @override
  String get playerPlayFailedRetry => '재생 실패, 나중에 다시 시도해 주세요';

  @override
  String get publicProfileDramas => '단편 드라마';

  @override
  String get publicProfileEmpty => '공개 콘텐츠가 없습니다';

  @override
  String get publicProfileBlock => '차단';

  @override
  String get publicProfileUnblock => '차단 해제';

  @override
  String get publicProfileBlockedByMeContent => '이 사용자를 차단하여 콘텐츠를 볼 수 없습니다';

  @override
  String get publicProfileBlockedContent => '이 사용자에게 차단되어 콘텐츠를 볼 수 없습니다';

  @override
  String get publicProfileBlockConfirmTitle => '이 사용자를 차단할까요?';

  @override
  String get publicProfileBlockConfirmMessage => '차단하면 상대방의 작품을 볼 수 없습니다.';

  @override
  String get publicProfileBlockSuccess => '차단했습니다';

  @override
  String get publicProfileUnblockSuccess => '차단을 해제했습니다';

  @override
  String get publicProfileFollowers => '팔로워';

  @override
  String get publicProfileFollowing => '팔로잉';

  @override
  String get followTabMutual => '맞팔';

  @override
  String get profileLikesReceived => '좋아요';

  @override
  String profileLikesReceivedDialogMessage(int count) {
    return '총 $count개의 좋아요를 받았습니다. 멋진 작품을 함께해주세요!';
  }

  @override
  String get profileTabLikes => '좋아요';

  @override
  String get profileTabFavorites => '즐겨찾기';

  @override
  String get profileWalletTitle => '지갑';

  @override
  String get profileAddressCopied => '주소가 복사되었습니다';

  @override
  String get followActionFollow => '팔로우';

  @override
  String get followActionFollowBack => '맞팔하기';

  @override
  String get followActionFollowing => '팔로잉';

  @override
  String get followBlockedByMe => '블랙리스트 사용자이므로 팔로우할 수 없습니다';

  @override
  String get followBlockedByTarget => '상대방의 설정으로 인해 팔로우할 수 없습니다';

  @override
  String get likeBlockedByMe => '블랙리스트 사용자이므로 좋아요를 누를 수 없습니다';

  @override
  String get likeBlockedByTarget => '상대방의 설정으로 인해 좋아요를 누를 수 없습니다';

  @override
  String get favoriteBlockedByMe => '블랙리스트 사용자이므로 즐겨찾기할 수 없습니다';

  @override
  String get favoriteBlockedByTarget => '상대방의 설정으로 인해 즐겨찾기할 수 없습니다';

  @override
  String get ratingBlockedByMe => '블랙리스트 사용자이므로 평가할 수 없습니다';

  @override
  String get ratingBlockedByTarget => '상대방의 설정으로 인해 평가할 수 없습니다';

  @override
  String get followActionMutual => '맞팔';

  @override
  String get followUnfollowTitle => '언팔로우';

  @override
  String followUnfollowMessage(String handle) {
    return '$handle님을 언팔로우할까요?';
  }

  @override
  String get followUnfollowNo => '아니요';

  @override
  String get followUnfollowYes => '예';

  @override
  String get followListEmpty => '사용자가 없습니다';

  @override
  String get followFollowingEmpty => '아직 팔로우한 사용자가 없어요. 흥미로운 크리에이터를 찾아보세요~';

  @override
  String get followFollowingEmptyCta => '둘러보기';

  @override
  String get followFollowingEmptyGuest => '팔로우 없음';

  @override
  String get followFollowersEmpty => '아직 팔로워가 없어요. 작품을 게시해 노출을 늘려보세요~';

  @override
  String get followFollowersEmptyCta => '게시하기';

  @override
  String get followFollowersEmptyGuest => '팔로워 없음';

  @override
  String get followMutualsEmpty => '아직 맞팔 친구가 없어요';

  @override
  String get followMutualsSelfOnly => '맞팔 목록은 본인만 볼 수 있습니다';

  @override
  String get followRelationsSelfOnly => '관계 목록은 본인만 볼 수 있습니다';

  @override
  String get followMoreTitle => '더보기';

  @override
  String get followRemoveFollower => '팔로워 삭제';

  @override
  String get followRemoveFollowerSuccess => '삭제되었습니다. 상대에게는 알림이 가지 않습니다';

  @override
  String get followUserHandleFallback => '@사용자';

  @override
  String get publicProfileTitle => '사용자 프로필';

  @override
  String publicProfileUserFallback(String id) {
    return '사용자 #$id';
  }

  @override
  String get watchHistoryEmpty => '시청 기록이 없습니다';

  @override
  String get watchHistoryClearTitle => '시청 기록 지우기';

  @override
  String get watchHistoryClearMessage => '모든 시청 기록을 지우시겠습니까? 이 작업은 취소할 수 없습니다.';

  @override
  String get watchHistoryClearConfirm => '확인';

  @override
  String get gamePageTitle => '에이전트';

  @override
  String get gamePageSubtitle => '역할을 관리하고, 수익을 창출할 수 있도록 배정하세요.';

  @override
  String get gameRiskAccount => '위험 계정';

  @override
  String get gameRiskAccountDescription =>
      '이 계정의 신뢰 계수가 비정상입니다. 마이닝 가중치에 영향을 줍니다.';

  @override
  String get gameWeeklyStats => '주간 통계';

  @override
  String get gameDeployedActors => '배치된 역할';

  @override
  String get gameMyActors => '내가 맡은 역할';

  @override
  String get gameComingSoon => '출시 예정';

  @override
  String get gameSignActor => '캐릭터 계약';

  @override
  String get gameGoProduce => '드라마 촬영하러 가다';

  @override
  String get gameWorkingActors => '출연 중인 역할';

  @override
  String get gameWeekPool => '이번 주 보상 풀 (STORY)';

  @override
  String get gameWeekNominalOutput => '이번 주 명목 생산량 (STORY)';

  @override
  String get gameWeekEstimatedOutput => '이번 주 예상 산출량 (STORY)';

  @override
  String get gameMiningRules => '채굴 규칙';

  @override
  String get agentV2RulesTitle => '운영 플레이';

  @override
  String get agentV2RulesSummary =>
      '캐릭터와 계약하고 공연을 배치하면 매시간 STORY를 획득합니다.\n캐릭터를 업그레이드하면 시간당 출연료가 배수로 증가합니다.\n체력이 소진되면 즉시 보충해 생산이 중단되지 않게 하세요.\n매주 월요일 00:00(UTC)에 해당 주기 수익 정산이 시작되며 수익 페이지에서 수령할 수 있습니다.';

  @override
  String get agentV2RulesHowToPlay => '이용 방법';

  @override
  String get agentV2RulesStartTitle => '캐릭터가 수익을 올리게 하려면?';

  @override
  String get agentV2RulesStartDescription =>
      '대기 중인 캐릭터를 공연에 배치하면 매시간 체력 1을 소모하고 출연료에 따라 STORY를 생산합니다.\n생산된 STORY는 각 주기 종료 시 일괄 정산되며 정산 후 수익 페이지에서 수령할 수 있습니다.';

  @override
  String get agentV2RulesStaminaTitle => '체력은 어떻게 관리하나요?';

  @override
  String agentV2RulesStaminaDescription(int staminaLimit) {
    return '공연 중: 매시간 체력 1을 소모하고 정상 출연료 생산\n체력 소진: 생산이 0으로 중단되므로 즉시 조치 필요\n휴식: 매시간 체력 1을 자동 회복하지만 출연료 생산 중단\n체력 보충(유료): 즉시 $staminaLimit까지 완전히 회복하고 생산 재개';
  }

  @override
  String get agentV2RulesBatchTitle => '일괄 작업이 가능한가요?';

  @override
  String get agentV2RulesBatchDescription =>
      '네. 페이지 하단의 전체 공연, 전체 보충, 전체 휴식을 사용해 공연 슬롯의 모든 캐릭터에게 한 번에 작업을 적용할 수 있습니다.';

  @override
  String get agentV2RulesEarnings => '예상 수익';

  @override
  String get agentV2RulesSalaryTitle => '출연료는 어떻게 계산되나요?';

  @override
  String get agentV2RulesSalaryDescription =>
      '등급이 높고 캐릭터 가치가 높으며 숏드라마가 인기일수록 시간당 출연료가 더 높아집니다.';

  @override
  String get agentV2RulesSalaryFormula => '카드당 시간 출연료 = 캐릭터 출연료 × 1 STORY';

  @override
  String get agentV2RulesRolePowerFormula => '캐릭터 출연료 = Lv.1 캐릭터 출연료 × 출연료 계수';

  @override
  String get agentV2RulesIpSalaryFormula => 'Lv.1 캐릭터 출연료 = 가격 계수 × 인기도 계수';

  @override
  String get agentV2RulesCoefficientTitle => '계수 설명';

  @override
  String agentV2RulesSalaryExample(String currency) {
    return '린멍야오 · Lv3 주연 · P0=120$currency(가격 계수 ≈1.5046) · 히트 3.5\n→ 시간당 출연료 = 5.0 × 1.5046 × 3.5 × 1 = 26.3 STORY\nLv1 단역이라면 시간당 약 5.3 STORY에 불과하지만 Lv3로 올리면 5배가 됩니다.';
  }

  @override
  String get agentV2RulesSettlementTitle => '언제 정산되나요?';

  @override
  String get agentV2RulesSettlementDescription =>
      '공연 주기는 7일이며, 매주 월요일 00:00(UTC)에 마감됩니다. 시스템 정산이 끝나면 이번 주기 출연료가 자동으로 STORY로 교환되며, 수익 페이지에서 수령할 수 있습니다.';

  @override
  String get agentV2RulesSettlementExample =>
      '이번 주 보상 풀이 100,000 STORY라고 가정하면:\n사례 A: 플랫폼 전체에서 나만 134 생산 → 134를 받고 나머지는 지급되지 않음\n사례 B: 전체 네트워크 생산량 250,000 → 100,000 ÷ 250,000 = 40%, 명목 생산량이 40%로 조정됨\n사례 C: 조정 후 6,000을 받아야 하지만 상한이 5,000이면 5,000만 지급됨';

  @override
  String get agentV2RulesStronger => '강해지는 방법';

  @override
  String get agentV2RulesUpgradeTitle => '캐릭터를 어떻게 업그레이드하나요?';

  @override
  String get agentV2RulesUpgradeDescription =>
      '조건: 동일 IP·동일 레벨 복제 카드 2장 소모 + IP 출연 드라마의 누적 완주 수 기준 달성\nLv1→Lv2: 완주 1만 회 이상 · 출연료 1→3\nLv2→Lv3: 완주 5만 회 이상 · 출연료 3→9\nLv3→Lv4: 완주 20만 회 이상 · 출연료 9→27\nLv4→Lv5: 완주 100만 회 이상 · 출연료 27→81';

  @override
  String get agentV2RulesPerforming => '공연 중';

  @override
  String get agentV2RulesNormalSalary => '일반 출연료';

  @override
  String get agentV2RulesSalaryCoefficient =>
      '출연료 계수: Lv1=1 · Lv2=3 · Lv3=9 · Lv4=27 · Lv5=81';

  @override
  String agentV2RulesPriceCoefficientDescription(
    String currency1,
    String currency2,
  ) {
    return '가격 계수(발행가 P0):\n  • P0 ≤ 100$currency1 → 계수 = P0 ÷ 100 (선형 증가)\n  • P0 > 100$currency2 → 계수 = 1.6 × (P0/100)¹.³ / [(P0/100)¹.³ + 0.6] (점근적 상한 1.6)';
  }

  @override
  String get agentV2RulesTrust2 => 'Trust2';

  @override
  String get agentV2RulesTrust2Factor => '플랫폼 Trust2';

  @override
  String get agentV2RulesSettlementCase1 => '실제 지급액 = 명목 생산량, 남은 한도는 소멸';

  @override
  String get agentV2RulesSettlementCase2 =>
      '비례 조정: 실제 수령액 = 명목 생산량 × (보상 풀 ÷ 전체 네트워크 생산량)';

  @override
  String get gameSettlementRecords => '주간 정산 내역';

  @override
  String get gameFilterComputingPower => '출연료';

  @override
  String get gameFilterLevel => '레벨';

  @override
  String get gameFilterHeat => '히트';

  @override
  String get gameFilterStamina => '체력';

  @override
  String get gameHeatCoef => '히트 계수';

  @override
  String get gameMiningCoef => '채굴 계수';

  @override
  String get gameActorPower => '캐릭터 출연료';

  @override
  String get gameActorPowerDetailTitle => '캐릭터 출연료 상세';

  @override
  String get gameActorPowerFormula =>
      '캐릭터 출연료 = IP 출연료 × 채굴 계수 × CP 계수 × Trust2';

  @override
  String get gameActorPowerIpFormula => 'IP 출연료 = 가격 계수 × 히트 계수 × Trust1';

  @override
  String get gameActorPowerHourlyOutput => '시간당 산출';

  @override
  String get gameCpCoefficient => 'CP 계수';

  @override
  String get gameTrust2 => 'Trust2';

  @override
  String get gameWeeklyNominalOutputLabel => '이번 주 명목 생산량';

  @override
  String get gameRoundNominalOutputLabel => '기간 nominal 출력';

  @override
  String get gameSupplement => '추가';

  @override
  String get gameRest => '휴식';

  @override
  String get gameDeploy => '파견';

  @override
  String get gameDeployActor => '캐릭터 캐스팅';

  @override
  String get gameStatusIdle => '미사용';

  @override
  String get gameStatusMining => '채굴 중';

  @override
  String gameActorIpLabel(String id) {
    return '캐릭터 IP $id';
  }

  @override
  String gameStaminaProgress(String current, String max) {
    return '$current/$max';
  }

  @override
  String get gameStaminaMechanismTitle => '체력 시스템';

  @override
  String gameStaminaMechanismDesc(String currency) {
    return '파견 중인 역할는 매시간 체력 1포인트를 소모합니다. 체력이 모두 소진되면 수익 생성이 중단되며, 휴식 중에는 자동으로 회복됩니다. $currency를 사용해 체력을 즉시 보충할 수 있습니다.';
  }

  @override
  String get gameStaminaMechanismAction => '알겠습니다';

  @override
  String gameLevelBadge(String level) {
    return 'Lv$level';
  }

  @override
  String get gameEmptyDeployed => '현재 배치된 역할이 없습니다';

  @override
  String get gameEmptyMyActors => '아직 캐릭터가 없습니다. 계약하고 시작하세요.';

  @override
  String get gameDeployConfirmTitle => '이 캐릭터를 배치하시겠습니까?';

  @override
  String get gameRestConfirmTitle => '이 캐릭터를 휴식시키시겠습니까?';

  @override
  String get gameRestConfirmDesc =>
      '캐릭터가 휴식하는 동안 채굴 보상이 일시 중지되며, 체력은 시간이 지남에 따라 회복됩니다.';

  @override
  String get gameRestConfirmAction => '휴식 확인';

  @override
  String get gameRestSuccessToast => '휴식 시작';

  @override
  String get gameDeploySlotFull => '배치 슬롯이 가득 찼습니다 (최대 5)';

  @override
  String get gameRefillTitle => '체력 회복';

  @override
  String get gameRefillCurrentStamina => '현재 체력';

  @override
  String get gameRefillCost => '복구 비용';

  @override
  String get gameRefillConfirm => '체력을 모두 회복하다';

  @override
  String get gameRefillSuccess => '체력 회복 성공';

  @override
  String get gameRefillFailed => '체력 회복에 실패했습니다. 다시 시도해 주세요.';

  @override
  String gameInsufficientUsdc(String currency) {
    return '$currency 잔액이 부족합니다';
  }

  @override
  String get walletInsufficientStory => 'STORY 잔액이 부족합니다';

  @override
  String get gameSupplementComingSoon => '체력 충전은 곧 출시됩니다';

  @override
  String get gameStatHelpWeekPoolTitle => '이번 주 보상 풀';

  @override
  String get gameStatHelpWeekPoolSubtitle =>
      '즉, STORY 채굴의 주간 고정 지급 상한선(주간 상한선)';

  @override
  String get gameStatHelpWeekTotalPool => '이번 주 총 보상 풀';

  @override
  String get gameStatHelpWeekTotalPoolValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeekStakePool => '이번 주 스테이킹 보상 풀(75%)';

  @override
  String get gameStatHelpWeekStakePoolValue => '1,586,538 STORY';

  @override
  String get gameStatHelpWeekInvitePool => '이번 주 초대 보상 풀(25%)';

  @override
  String get gameStatHelpWeekInvitePoolValue => '528,846 STORY';

  @override
  String get gameStatHelpInitialHardCap => '초기 주 하드탑';

  @override
  String get gameStatHelpInitialHardCapValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeeklyDecay => '주간 감쇠 계수';

  @override
  String get gameStatHelpWeeklyDecayValue => '× 0.99572';

  @override
  String get gameStatHelpWeeklyDistributionFormula =>
      '주간 실제 지급량 = min(전체 네트워크 명목 생산량, 해당 주 상한선)';

  @override
  String get gameStatHelpUnusedQuotaNote =>
      '미사용 잔여 할당량은 지급되지 않으며, 환원되지 않고, 점수도 보충되지 않습니다.';

  @override
  String get gameStatHelpNominalTitle => '이번 주 명목 생산량';

  @override
  String get gameStatHelpNominalSummary => '내 모든 역할의 주간 누적 명목 생산량 합계';

  @override
  String get gameStatHelpNominalSummaryHint => '단일 카드 공식은 아래 설명을 참조하십시오.';

  @override
  String get gameStatHelpNominalFormula =>
      '카드당 명목 생산량 = 카드당 시간 가중치 × R_base × 유효 채굴 시간';

  @override
  String get gameStatHelpHourlyWeight => '단일 카드 시간 가중치';

  @override
  String get gameStatHelpHourlyWeightValue => '= 캐릭터 출연료';

  @override
  String get gameStatHelpActorPower => '캐릭터 출연료';

  @override
  String get gameStatHelpActorPowerValue => '= IP 출연료 × 채굴 계수 × CP 계수 × Trust2';

  @override
  String get gameStatHelpCpCoef => 'CP 계수';

  @override
  String get gameStatHelpRBase => 'R_base';

  @override
  String get gameStatHelpRBaseValue => '1 STORY / 단위 가중치 / 시간';

  @override
  String get gameStatHelpEffectiveDuration => '유효 채굴 시간';

  @override
  String get gameStatHelpEffectiveDurationValue =>
      '담보로 설정된 상태에서 체력이 0보다 큰 상태의 누적 시간';

  @override
  String get gameStatHelpActualTitle => '이번 주 예상 생산량';

  @override
  String get gameStatHelpActualSubtitle =>
      '예상 생산량은 주간 상한선과 단일 주소 상한선의 제약을 받으며, 주가 끝날 때 실제 수익이 확정됩니다';

  @override
  String get gameStatHelpIfNominalLte => '전체 네트워크의 명목 생산량이 해당 주의 상한선 이하인 경우:';

  @override
  String get gameStatHelpUserActualEqNominal => '사용자 실제 수령액 = 사용자 명목 생산량';

  @override
  String get gameStatHelpIfNominalGt => '전체 네트워크의 명목 생산량이 해당 주의 상한선을 초과할 경우:';

  @override
  String get gameStatHelpUserActualFormula =>
      '사용자 실제 수령액 = 사용자 명목 생산량 × 해당 주 상한선 / 전체 네트워크 명목 생산량';

  @override
  String get gameStatHelpAddressCap => '주당 최대 한도';

  @override
  String get gameStatHelpAddressCapValue =>
      '개별 주소당 매주 해당 주의 상한선의 최대 5%까지 수령할 수 있습니다.';

  @override
  String get theaterCategoryAll => '전체';

  @override
  String get theaterCategoryAncient => '사극';

  @override
  String get theaterCategoryFinance => '금융';

  @override
  String get theaterCategorySuspense => '서스펜스';

  @override
  String get theaterCategorySciFi => '공상과학';

  @override
  String get theaterCategoryRealStory => '실화를 바탕으로 한';

  @override
  String get theaterCategoryUrban => '도시';

  @override
  String get theaterSortHottest => '가장 인기 있는';

  @override
  String get theaterSortNewest => '최신';

  @override
  String get theaterSortTopRated => '가장 많이 저장된 항목';

  @override
  String get theaterSortCompletedView => '최다 완주';

  @override
  String theaterPlayCount(String count) {
    return '$count 재생';
  }

  @override
  String get createDramaBasicInfo => '기본 정보';

  @override
  String get createDramaEpisodes => '드라마 관리';

  @override
  String get createDramaRoles => 'IP 연결';

  @override
  String get createDramaCover => '표지';

  @override
  String get createDramaCoverUpload => '업로드';

  @override
  String get createDramaCoverPlaceholder => 'JPG/PNG 지원, 최대 5MB';

  @override
  String get createDramaCoverCropTitle => '커버 이미지 자르기';

  @override
  String get createDramaName => '단편 드라마 제목';

  @override
  String get createDramaNameHint => '단편 드라마 제목을 입력해 주세요';

  @override
  String get createDramaSynopsis => '소개';

  @override
  String get createDramaTags => '태그';

  @override
  String get createDramaTagsHint => '태그를 입력하고 Enter로 추가 (예: 로맨스, 코미디)';

  @override
  String get createDramaTagsLoading => '태그 로딩 중…';

  @override
  String get createDramaTagsEmpty => '사용 가능한 태그가 없습니다';

  @override
  String get createDramaTagsRetry => '다시 시도';

  @override
  String get createDramaUploadDesc => '‘업로드’를 클릭하면, 제출 후 동영상 이름 순으로 자동 정렬됩니다.';

  @override
  String get createDramaEpisodesDesc =>
      '동영상 파일을 일괄 업로드하면 시스템이 파일 이름 순서대로 에피소드 목록을 자동으로 생성합니다. 드래그 앤 드롭으로 정렬, 삭제, 제목 편집 등의 작업을 수행할 수 있습니다.';

  @override
  String get createDramaVideoFileTypeHint =>
      '지원 형식: mp4, flv, wmv, asf, mkv, avi, rm, rmvb, mpg, mpeg, mov, webm. 최대 파일 크기 2GB.';

  @override
  String get createDramaUploadVideo => '동영상 업로드';

  @override
  String get createDramaVideoEmpty => '아직 추가된 동영상이 없습니다';

  @override
  String get createDramaVideoPickFailed => '동영상 선택에 실패했습니다';

  @override
  String get createDramaVideoAnyTooLarge =>
      '2GB를 초과하는 비디오가 있습니다. 조정 후 다시 시도해 주세요';

  @override
  String get createDramaVideoStatusUploading => '업로드 중';

  @override
  String get createDramaVideoStatusPaused => '업로드 일시 중지';

  @override
  String get createDramaVideoStatusDone => '업로드 완료';

  @override
  String get createDramaEpisodeDescriptionHint => '에피소드 소개';

  @override
  String get createDramaVideoStatusFailed => '업로드 실패';

  @override
  String get createDramaVideoTooLarge => '동영상 크기는 2GB를 초과할 수 없으며 업로드할 수 없습니다';

  @override
  String get createDramaVideoUploadComplete => '모든 동영상이 업로드되었습니다';

  @override
  String createDramaVideoUploadFailed(String name) {
    return '$name 업로드 실패';
  }

  @override
  String createDramaVideoPickOverflow(int count, int overflow) {
    return '최대 $count개의 회차를 더 추가할 수 있습니다. $overflow개가 초과되어 건너뜁니다.';
  }

  @override
  String createDramaAddedVideos(String count) {
    return '추가된 동영상 ($count개 파일)';
  }

  @override
  String createDramaAddedVideosCount(String count) {
    return '($count개 파일)';
  }

  @override
  String get createDramaAddedVideosLabel => '추가된 동영상';

  @override
  String get createDramaRolesDesc =>
      '단편 드라마의 역할을 생성하고, 역할 이름, 프로필 사진 및 성격 소개를 설정합니다.';

  @override
  String get createDramaRolesRule1 =>
      '각 숏드라마에는 최대 5개의 캐릭터 IP를 연결할 수 있습니다. 공개 후 7일 이내에 추가할 수 있으며, 공개 후에는 해제하거나 교체할 수 없습니다.';

  @override
  String get createDramaRolesRule2 =>
      '연결된 캐릭터 IP에는 드라마의 완주 및 인기 데이터가 연동되어 캐릭터 업그레이드와 STORY 보상에 사용됩니다.';

  @override
  String get createDramaRolesExpireTime => '마감 시간';

  @override
  String get createDramaRolesRule3 => 'IP 연결은 선택 사항이며 연결하지 않고도 공개할 수 있습니다.';

  @override
  String get createDramaAddRole => '역할 추가';

  @override
  String get createDramaBindActor => '출연 역할';

  @override
  String get createDramaRoleActing => '출연 역할';

  @override
  String get createDramaSelectActor => '역할 선택';

  @override
  String get createDramaBindActorTitle => '캐릭터 IP 선택';

  @override
  String createDramaBindIpSelectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get createDramaBindIpEmpty => '데이터가 없습니다';

  @override
  String get createDramaBindIpMarketplace => '캐릭터 IP 마켓으로 이동';

  @override
  String get createDramaBindIpConfirm => '연결 확인';

  @override
  String createDramaBindActorSubtitle(String roleName) {
    return '“$roleName” 역을 맡을 캐릭터 IP를 선택하세요';
  }

  @override
  String createDramaBindActorOwnedCount(int count) {
    return '$count개의 캐릭터 IP를 보유하고 있습니다';
  }

  @override
  String createDramaBindActorIpLabel(String code) {
    return '캐릭터 IP $code';
  }

  @override
  String get createDramaBindActorBoundTag => '연동됨';

  @override
  String get createDramaBindIpRemove => '제거';

  @override
  String createDramaBindActorBoundToast(String name) {
    return '$name 연결됨';
  }

  @override
  String get createDramaBindActorUnbind => '연결 해제';

  @override
  String get createDramaBindActorExpired =>
      '7일 바인딩 기간이 만료되어 새 캐릭터 IP를 바인딩할 수 없습니다';

  @override
  String get createDramaBindActorEmptyTitle => '연결할 캐릭터 IP가 없습니다';

  @override
  String get createDramaBindActorEmptyDesc => '역할에 연결하기 전에 캐릭터 IP를 보유해야 합니다';

  @override
  String get createDramaBindActorGotoCreate => '역할 만들기';

  @override
  String get createDramaPrevStep => '이전 단계';

  @override
  String get createDramaNextStep => '다음 단계';

  @override
  String get createDramaSubmit => '게시';

  @override
  String get createDramaRoleNameLabel => '역할 이름';

  @override
  String get createDramaRoleNameHint => '역할 이름을 입력해 주세요';

  @override
  String get createDramaRoleNameRequired => '역할 이름을 입력해 주세요';

  @override
  String get createDramaRoleBioLabel => '역할 소개';

  @override
  String get createDramaRoleBioHint => '역할 소개를 입력해 주세요';

  @override
  String get createDramaRoleBioRequired => '역할 소개를 입력해 주세요';

  @override
  String get createDramaRoleAddTitle => '역할 추가';

  @override
  String get createDramaRoleEditTitle => '역할 편집';

  @override
  String get createDramaRoleUploadAvatar => '프로필 사진 업로드';

  @override
  String get createDramaRoleSave => '저장';

  @override
  String get createDramaRoleDeleteConfirm => '이 캐릭터를 삭제하시겠습니까?';

  @override
  String createDramaVideoDeleteConfirm(String name) {
    return '\"$name\"을(를) 삭제하시겠습니까?';
  }

  @override
  String get createDramaVideoDeleteTitle => '동영상 삭제';

  @override
  String get createDramaVideoPreviewUnavailable =>
      '이전에 업로드한 동영상은 현재 미리 볼 수 없습니다';

  @override
  String get createDramaRoleEmpty => '아직 추가된 역할이 없습니다';

  @override
  String get createDramaRoleBindComingSoon => '역할 연결은 곧 출시됩니다';

  @override
  String get createDramaRoleAvatarCropTitle => '역할 아바타 자르기';

  @override
  String get createDramaRoleAvatarUploadFailed => '역할 아바타 업로드 실패';

  @override
  String get createDramaPublishedSuccess => '게시되었습니다';

  @override
  String get createDramaDraftRestored => '미완성 초안이 복원되었습니다';

  @override
  String get createDramaDraftClear => '데이터 지우기';

  @override
  String get createDramaDraftDiscard => '저장하지 않고 돌아가기';

  @override
  String get createDramaDraftSave => '초안 저장';

  @override
  String get createDramaEditLoading => '로딩 중...';

  @override
  String get createDramaEditLoadError => '드라마 정보 로딩 실패, 다시 시도해 주세요';

  @override
  String get createDramaSubmitValidationTitle => '드라마 제목을 입력해 주세요';

  @override
  String get createDramaSubmitValidationCover => '커버 이미지를 업로드해 주세요';

  @override
  String get createDramaSubmitValidationVideos => '최소 1개의 동영상을 업로드해 주세요';

  @override
  String get createDramaSubmitValidationSession =>
      '업로드 세션이 유효하지 않습니다, 동영상을 다시 업로드해 주세요';

  @override
  String get createDramaUploadSessionFailed => '업로드 세션 생성에 실패했습니다';

  @override
  String get createDramaSubmitValidationRoles => '최소 1개의 역할을 추가해 주세요';

  @override
  String get createDramaStep1TitleRequired => '단편 드라마 제목을 입력해 주세요';

  @override
  String get createDramaStep1SynopsisRequired => '소개 내용을 입력해 주세요';

  @override
  String get createDramaStep1CoverRequired => '커버를 추가해 주세요';

  @override
  String get createDramaStep1TagsRequired => '태그를 선택해 주세요';

  @override
  String get createDramaEpisodeDescriptionRequired => '에피소드 소개를 입력해 주세요';

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsTheme => '테마';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsThemeSystem => '시스템';

  @override
  String get settingsUI => '인터페이스';

  @override
  String get settingsAppVersion => '버전';

  @override
  String get settingsVersionLatestToast => '최신 버전을 사용하고 있습니다';

  @override
  String get settingsVersionCheckFailed => '버전 확인에 실패했습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get appVersionUpdateTitle => '새 버전이 있습니다';

  @override
  String get appVersionUpdateContentsLabel => '업데이트 내용:';

  @override
  String get appVersionUpdateConfirm => '지금 업데이트';

  @override
  String get appVersionUpdateLater => '나중에';

  @override
  String get settingsTermsOfService => '서비스 약관';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsDeleteAccount => '계정 삭제';

  @override
  String settingsDeleteAccountConfirm(String deadline) {
    return '계정이 $deadline에 삭제됩니다. 이 기간 내에 다시 로그인하면 계정 삭제를 취소할 수 있습니다.';
  }

  @override
  String get settingsDeleteAccountSuccess => '계정 삭제 신청이 제출되었습니다';

  @override
  String get settingsClearCache => '캐시 지우기';

  @override
  String get settingsNetworkInspector => '네트워크 인스펙터';

  @override
  String get settingsClearCacheConfirm => '캐시를 지우시겠습니까?';

  @override
  String get miningRulesHowToPlay => '파밍 파견은 어떻게 하나요?';

  @override
  String get miningRulesFlowSubtitle =>
      '한 장의 그림으로 인력 파견부터 급여 수령까지의 전체 과정을 한눈에 파악하기';

  @override
  String get miningRulesSection1Title => '1. 사람을 보내서 광산을 개발하게 한다';

  @override
  String get miningRulesSection1Desc =>
      '유휴 상태인 역할을 아래의 5개 슬롯에 ‘배치’하면, 그 역할이 자동으로 채굴을 시작하여 STORY를 생산합니다.';

  @override
  String get miningRulesSection1Bullet1 => '1인당 동시에 최대 5명의 역할을 파견할 수 있습니다.';

  @override
  String get miningRulesSection1Bullet2 =>
      '동일한 캐릭터 IP에 대해 여러 장의 카드를 동시에 배정할 수도 있습니다.';

  @override
  String get miningRulesSection1Bullet3 =>
      '파견 후 매 1시간마다 ⚡체력 1을 소모하며, 체력이 0보다 크면 계속 생산하고, 체력이 0이면 생산이 중단됩니다.';

  @override
  String get miningRulesSection2Title => '2. 계산, 산출 공식';

  @override
  String get miningRulesSection2Desc => '카드 한 장당 시간당 생산량은 다음과 같이 계산됩니다:';

  @override
  String get miningRulesSection2Formula => '1카드 시간당 출력 = 캐릭터 출연료 × 1 STORY';

  @override
  String get miningRulesSection2FactorsTitle => '세 가지 결정 요인:';

  @override
  String get miningRulesSection2Factor1 =>
      '채굴 계수 — 등급이 높을수록 계수가 커집니다. Lv1=1.0 → Lv2=2.2 → Lv3=5.0 → Lv4=11 → Lv5=24';

  @override
  String get miningRulesSection2Factor2 => 'IP 출연료 = 가격 계수 × 히트 계수 × Trust1';

  @override
  String get miningRulesSection2Factor3 =>
      'R_base——고정값, 현재 1 STORY이며, 추후 플랫폼에서 수동으로 조정될 수 있음';

  @override
  String miningRulesSection2Factor4(String currency1, String currency2) {
    return '가격 계수——발행가 P0: P0≤10$currency1 선형 증가 · P0>10$currency2 상한 1.6에 근접';
  }

  @override
  String get miningRulesSection2Factor5 =>
      '인기 계수——최근 드라마 성과가 좋을수록 인기가 높아집니다(완주, 좋아요, 저장, 댓글)';

  @override
  String get miningRulesSection2Factor6 => 'CP 계수——현재 미지원; Trust 기본값 1.0';

  @override
  String miningRulesSection2StaminaText(int staminaLimit) {
    return '체력은 ‘있는지 없는지’만 중요할 뿐, 얼마나 남았는지는 중요하지 않습니다. 체력이 $staminaLimit점이든 1점이든 시간당 생산량은 동일하며, 체력은 채굴 중인지 아닌지만을 따집니다.';
  }

  @override
  String get miningRulesSection2ExampleTitle => '예를 들어:';

  @override
  String miningRulesSection2ExampleDesc(String currency) {
    return '린멍야오 · Lv3 주연 · P0=12$currency(가격 계수 ≈1.0859) · 히트 3.5\n→ 시간당 생산량 = 5.0 × 1.0859 × 3.5 × 1 = 19.00325 STORY';
  }

  @override
  String get miningRulesCoefTableTitle => '계수 상세';

  @override
  String get miningRulesCoefColCoef => '계수';

  @override
  String get miningRulesCoefColFactor => '결정 요인';

  @override
  String get miningRulesCoefColDesc => '상세';

  @override
  String get miningRulesCoefMining => '채굴 계수';

  @override
  String get miningRulesCoefPrice => '가격 계수';

  @override
  String get miningRulesCoefHeat => '히트 계수';

  @override
  String get miningRulesCoefCp => 'CP 계수';

  @override
  String get miningRulesCoefTrust => 'Trust';

  @override
  String get miningRulesCoefMiningFactor => '등급';

  @override
  String get miningRulesCoefPriceFactor => '출시가 P0';

  @override
  String get miningRulesCoefHeatFactor => '최근 드라마 성과';

  @override
  String get miningRulesCoefCpFactor => '-';

  @override
  String get miningRulesCoefTrustFactor => '플랫폼 위험 관리';

  @override
  String get miningRulesCoefMiningDesc =>
      'Lv1=1.0 · Lv2=2.2 · Lv3=5.0 · Lv4=11 · Lv5=24';

  @override
  String miningRulesCoefPriceDesc(String currency1, String currency2) {
    return 'P0≤10$currency1에서 선형 증가 · P0>10$currency2에서 상한 1.6에 근접';
  }

  @override
  String get miningRulesCoefHeatDesc =>
      '인기도 계수: 캐릭터 IP 출연 드라마의 완주, 좋아요, 저장, 평점이 많을수록 인기도가 높아집니다';

  @override
  String get miningRulesCoefCpDesc => '현재 미지원';

  @override
  String get miningRulesCoefTrustDesc => '기본값 1.0';

  @override
  String get miningRulesSection3Title => '3. 돈을 지급하지만, 상한선이 있다';

  @override
  String get miningRulesSection3Desc =>
      '매주 플랫폼 전체에서 총 보상 풀(주간 하드 캡)이 설정되며, 약 2,115,385 STORY에서 시작하여 매주 감소합니다(주 × 0.99572). 보상 분배는 세 가지 경우로 나뉩니다:';

  @override
  String get miningRulesSettleColCondition => '조건';

  @override
  String get miningRulesSettleColRule => '분배 규칙';

  @override
  String get miningRulesSection3Case1Title => '전 플랫폼 명목 생산량 ≤ 이번 주 상금 풀';

  @override
  String get miningRulesSection3Case1Desc =>
      '모든 참가자는 명단에 기재된 대로 전액을 수령하며, 남은 상금은 지급되지 않으며 보충되지도 않습니다.';

  @override
  String get miningRulesSection3Case2Title => '전 플랫폼 명목 생산량 &gt; 이번 주 상금 풀';

  @override
  String get miningRulesSection3Case2Desc =>
      '비례 조정: 실제 수익 = 명목 생산량 × 보상 풀 ÷ 전체 플랫폼 생산량';

  @override
  String get miningRulesSection3Case3Title => '단일 주소가 보상 풀의 5%를 초과함';

  @override
  String get miningRulesSection3Case3Desc =>
      '초과분은 지급하지 않으며, 환원되지 않고, 점수도 보충되지 않습니다.';

  @override
  String get miningRulesSection3ExampleDesc =>
      '주간 보상 풀이 100,000 STORY라고 가정:\n케이스 A: 플랫폼에 본인만 있고, 주간 134를 생산 → 134를 획득, 나머지 99,866은 분배되지 않음\n케이스 B: 플랫폼 전체 출력이 250,000이면, 모두 40%로 스케일링 (100,000÷250,000)\n케이스 C: 특정인의 비례 보상이 6,000이지만, 1주소당 상한이 5,000 → 5,000만 분배';

  @override
  String get miningRulesSection4Title => '4. 체력을 잘 관리해야 계속 채굴할 수 있다';

  @override
  String get miningRulesTableStatus => '상태';

  @override
  String get miningRulesTableStaminaChange => '체력 변화';

  @override
  String get miningRulesTableOutput => '산출물';

  @override
  String get miningRulesStatusMining => '파견 중 (채굴)';

  @override
  String get miningRulesStaminaMining => '시간당 -1';

  @override
  String get miningRulesOutputNormal => '정상적인 생산량';

  @override
  String get miningRulesStatusZeroStamina => '체력 = 0';

  @override
  String get miningRulesStaminaZeroStamina => '더 이상 변하지 않는다';

  @override
  String get miningRulesOutputZero => '출력값은 0입니다.';

  @override
  String get miningRulesStatusResting => '휴식 시간';

  @override
  String get miningRulesStaminaResting => '시간당 +1 (자동 회복)';

  @override
  String get miningRulesOutputPaused => '생산 일시 중단';

  @override
  String get miningRulesStatusPaidRefill => '체력 보충 (유료)';

  @override
  String miningRulesStaminaPaidRefill(int staminaLimit) {
    return '순간적으로 $staminaLimit까지 회복';
  }

  @override
  String get miningRulesOutputRestored => '생산 재개';

  @override
  String get miningRulesSection4TipsTitle => '체력을 보충하는 데 관한 3가지 사항:';

  @override
  String get miningRulesSection4Tip1 =>
      '한 번의 클릭으로 최대량만 충전할 수 있으며, 10포인트만 구매할 수는 없습니다.';

  @override
  String get miningRulesSection4Tip2 =>
      '가격은 캐릭터의 등급만 보고, 남은 체력은 고려하지 않습니다. 체력이 0일 때 최대치로 채우는 것과 체력이 100일 때 최대치로 채우는 데 드는 비용은 똑같습니다.';

  @override
  String get miningRulesSection4Tip3 =>
      '0에 가까울수록 보충하는 것이 더 유리합니다——같은 비용을 지불하고도 가장 많은 추가 채굴 시간을 확보할 수 있습니다';

  @override
  String get miningRulesSection4PriceTitle => '각 등급별 추가 가격:';

  @override
  String get miningRulesPriceTableTier => '지위';

  @override
  String get miningRulesPriceTableFullRefill => '한 번의 클릭으로 가득 채우기';

  @override
  String get miningRulesLv1 => 'Lv1 엑스트라';

  @override
  String get miningRulesLv2 => 'Lv2 조연';

  @override
  String get miningRulesLv3 => 'Lv3 주인공';

  @override
  String get miningRulesLv4 => 'Lv4 슈퍼스타';

  @override
  String get miningRulesLv5 => 'Lv5 최정상';

  @override
  String get gameActorLevelName1 => '엑스트라';

  @override
  String get gameActorLevelName2 => '조연';

  @override
  String get gameActorLevelName3 => '주연';

  @override
  String get gameActorLevelName4 => '슈퍼스타';

  @override
  String get gameActorLevelName5 => '탑 티어';

  @override
  String miningRulesLv1Price(String currency) {
    return '15 $currency';
  }

  @override
  String miningRulesLv2Price(String currency) {
    return '36 $currency';
  }

  @override
  String miningRulesLv3Price(String currency) {
    return '87 $currency';
  }

  @override
  String miningRulesLv4Price(String currency) {
    return '208 $currency';
  }

  @override
  String miningRulesLv5Price(String currency) {
    return '465 $currency';
  }

  @override
  String get miningRulesSection5Title => '5. 등급을 올려 더 많은 수익을 올리세요';

  @override
  String get miningRulesSection5Desc =>
      '동급 캐릭터 카드 3장 + 합성 비용 + 해당 캐릭터의 누적 완주 목표 달성 = 1레벨 상승. 레벨 업 후 채굴 계수가 급증하여 시간당 생산량이 두 배, 심지어 몇 배로 늘어납니다.';

  @override
  String get miningRulesUpgradePathSubtitle => '업그레이드 경로';

  @override
  String get miningRulesUpgradeColPath => '업그레이드 경로';

  @override
  String get miningRulesUpgradeColHeat => '누적 완주 기준';

  @override
  String get miningRulesUpgradeColFee => '합성 수수료';

  @override
  String get miningRulesUpgradePath12 => 'Lv1 → Lv2';

  @override
  String get miningRulesUpgradePath23 => 'Lv2 → Lv3';

  @override
  String get miningRulesUpgradePath34 => 'Lv3 → Lv4';

  @override
  String get miningRulesUpgradePath45 => 'Lv4 → Lv5';

  @override
  String get miningRulesUpgradeHeat12 => '≥ 10,000';

  @override
  String get miningRulesUpgradeHeat23 => '≥ 50,000';

  @override
  String get miningRulesUpgradeHeat34 => '≥ 200,000';

  @override
  String get miningRulesUpgradeHeat45 => '≥ 1,000,000';

  @override
  String miningRulesUpgradeFee12(String currency) {
    return '10 $currency';
  }

  @override
  String miningRulesUpgradeFee23(String currency) {
    return '20 $currency';
  }

  @override
  String miningRulesUpgradeFee34(String currency) {
    return '40 $currency';
  }

  @override
  String miningRulesUpgradeFee45(String currency) {
    return '80 $currency';
  }

  @override
  String get miningRulesSummaryTitle => '한 마디로 요약하면';

  @override
  String get miningRulesSummaryDesc =>
      '파견 → 생산 → 체력 확인 → 수령. 체력이 얼마 안 남으면 보충하거나 불러와 휴식시키세요. 히트는 캐릭터의 드라마 성과로 올라가며, 업그레이드하면 생산이 비약적으로 늘어납니다.';

  @override
  String get playerNotInterested => '관심 없음';

  @override
  String get playerNotInterestedDone => '피드백이 반영되었습니다. 비슷한 영상을 줄이겠습니다';

  @override
  String get playerClearScreen => '화면 정리';

  @override
  String get playerAutoPlay => '연속 재생';

  @override
  String get playerReport => '신고';

  @override
  String get playerReportSuccess => '신고 완료';

  @override
  String get commentReportSuccess => '제출되었습니다. 곧 처리해 드리겠습니다';

  @override
  String get reportSuccessTitle => '제출되었습니다. 곧 처리해 드리겠습니다';

  @override
  String get reportSuccessThanks => '커뮤니티 안전에 기여해 주셔서 감사합니다!';

  @override
  String get reportSuccessAlsoYouCan => '또한 다음을 할 수 있습니다';

  @override
  String get reportSuccessDone => '완료';

  @override
  String get reportReduceRecommend => '추천 줄이기';

  @override
  String get reportReduceRecommendDone => '추천을 줄였습니다';

  @override
  String get reportSuccessContentFallback => '이 콘텐츠';

  @override
  String get reportDescription => '신고 내용';

  @override
  String get reportDescriptionPlaceholder => '상세 내용을 기술하세요 (선택사항)';

  @override
  String get reportReasonPorn => '포르노 및 음란물';

  @override
  String get reportReasonIllegal => '불법 또는 범죄';

  @override
  String get reportReasonSensitive => '민감한 콘텐츠';

  @override
  String get reportReasonGambling => '도박 또는 폭력';

  @override
  String get reportReasonMinors => '미해자 유해';

  @override
  String get reportReasonCopyright => '저작권 침해';

  @override
  String get reportReasonQuality => '품질 문제';

  @override
  String get reportReasonNotLike => '마음에 들지 않아요';

  @override
  String get reportReasonOther => '기타';

  @override
  String get gameUpgrade => '업그레이드';

  @override
  String get gameUpgradeTitle => '레벨 업그레이드';

  @override
  String get gameUpgradeCurrentLevel => '현재 레벨';

  @override
  String get gameUpgradeTargetLevel => '목표 레벨';

  @override
  String get gameUpgradeHeatThreshold => '드라마 누적 완주';

  @override
  String get gameUpgradeRequiredCount => '동일 IP 동일 레벨 역할 소모';

  @override
  String get gameUpgradeFee => '업그레이드 비용';

  @override
  String get gameUpgradeNextLevelReq => '다음 레벨 업그레이드 조건';

  @override
  String get gameUpgradeBeforeAfter => '업그레이드 전후 비교';

  @override
  String get gameUpgradeSelectMaterialDesc => '소모할 동일 IP 동일 레벨 역할 선택';

  @override
  String gameUpgradeMaterialCount(int current, int required) {
    return '$current/$required';
  }

  @override
  String gameUpgradeToLevel(int level, String levelName) {
    return 'Lv$level $levelName로 업그레이드';
  }

  @override
  String gameUpgradeSelectMaterialLabel(int current, int required) {
    return '재료 선택 ($current/$required)';
  }

  @override
  String gameUpgradeSelectMaterials(int count) {
    return '$count개의 재료를 선택하세요';
  }

  @override
  String get gameUpgradeConfirm => '업그레이드 확인';

  @override
  String get gameUpgradeSuccess => '업그레이드 성공';

  @override
  String get gameUpgradeFailed => '업그레이드 실패, 다시 시도해주세요';

  @override
  String get gameUpgradeInsufficientMaterials => '재료 부족';

  @override
  String get gameUpgradeNoMaterials => '소모 가능한 동일 IP 동일 레벨의 역할이 없습니다';

  @override
  String get creatorDramaStatusMinted => '민팅 완료';

  @override
  String get creatorDramaStatusOffline => '하차됨';

  @override
  String get creatorDramaStatusUnavailable => '일시적으로 사용 불가';

  @override
  String get creatorMintDramaNft => '드라마 NFT 민팅';

  @override
  String get creatorMintConfirmDesc =>
      '이 드라마를 온체인 NFT로 민팅합니다. 민팅 후 이 드라마는 STORY 마이닝 보상을 생성합니다.';

  @override
  String get creatorMintFee => '민팅 수수료';

  @override
  String creatorMintInsufficientUsdc(String currency1, String currency2) {
    return '$currency1 잔액이 부족합니다. 온체인 출시에는 최소 1 $currency2가 필요합니다.';
  }

  @override
  String get creatorMintInvalidDramaId => '잘못된 드라마 ID입니다';

  @override
  String get creatorMintInProgress => '민팅이 진행 중입니다. 잠시만 기다려 주세요';

  @override
  String get creatorMintWalletNotReady =>
      'Solana 지갑 주소가 준비되지 않았습니다. 다시 로그인해 주세요';

  @override
  String get creatorMintDigestEmpty => '출시 서명 데이터가 비어 있습니다. 잠시 후 다시 시도해 주세요.';

  @override
  String get creatorMintWalletMismatch =>
      '민팅 지갑이 현재 지갑과 일치하지 않습니다. 다시 로그인해 주세요';

  @override
  String get creatorMintSuccess => '민팅 성공!';

  @override
  String creatorMintDramaOnChain(String name) {
    return '드라마 NFT 「$name」이(가) 온체인에 민팅되었습니다';
  }

  @override
  String creatorMintNftNumber(String id) {
    return 'NFT 번호: $id';
  }

  @override
  String get creatorMintTxHash => '트랜잭션 해시: ';

  @override
  String get gameSelectActor => '파견할 역할 선택';

  @override
  String get gameSelectActorDesc => '대기 중인 캐릭터를 한 명 선택하여 파견하세요';

  @override
  String get agentV2SchedulePerformance => '공연';

  @override
  String get agentV2PerformAllTitle => '한 번에 공연';

  @override
  String get agentV2PerformAllDescription => '출연료가 높은 순서대로 빈 공연 슬롯에 배치합니다';

  @override
  String get agentV2PerformAllFailed => '원탭 공연에 실패했습니다. 다시 시도해 주세요';

  @override
  String get agentV2PerformAllSuccess => '한 번에 공연에 성공했습니다';

  @override
  String agentV2PerformAllDepletedResult(int successCount, int depletedCount) {
    return '$successCount명 공연 성공, $depletedCount명은 체력 소진으로 공연할 수 없습니다';
  }

  @override
  String get agentV2RestAllSuccess => '한 번에 휴식에 성공했습니다';

  @override
  String agentV2PerformAllCount(int count) {
    return '캐릭터 $count명';
  }

  @override
  String get agentV2TodoTitle => '할 일';

  @override
  String agentV2TodoVacancies(int count) {
    return '공연 자리 $count개가 비어 있습니다';
  }

  @override
  String agentV2TodoStaminaDepleted(String name) {
    return '$name의 체력이 0이 되어 작업을 중단했습니다';
  }

  @override
  String get agentV2TodoPerform => '공연하기';

  @override
  String get agentV2TodoRefill => '보충하기';

  @override
  String get agentV2TodoHealthy => '공연 정상 · 체력 충분';

  @override
  String get agentV2CandidateActorsTitle => '후보 역할';

  @override
  String get agentV2CandidateActorsDescription => '휴식 중인 역할은 시간당 체력을 1 회복합니다';

  @override
  String get agentV2UpgradeableActorsTitle => '역할 업그레이드';

  @override
  String get agentV2UpgradeableActorsEmpty => '업그레이드할 수 있는 역할이 없습니다';

  @override
  String get agentV2NoActors => '역할이 없습니다';

  @override
  String get agentV2UpgradeNow => '지금 업그레이드';

  @override
  String get agentV2UpgradeCompletion => '완주';

  @override
  String get agentV2UpgradeMaterials => '역할';

  @override
  String agentV2UpgradeRequirementsTitle(String name) {
    return '$name 업그레이드';
  }

  @override
  String agentV2UpgradeCompletionRemaining(int count) {
    return '완주 $count회가 더 필요합니다';
  }

  @override
  String get agentV2UpgradeCompletionHint =>
      '이 캐릭터가 출연한 드라마를 시청하거나 새 드라마를 제작하면 완주 수가 증가합니다';

  @override
  String get agentV2UpgradeWatchDramas => '출연 드라마 보기';

  @override
  String get agentV2UpgradeCreateDrama => '드라마 제작하기';

  @override
  String agentV2UpgradeMaterialsRemaining(int count) {
    return '동일 IP·동일 레벨 역할이 $count개 더 필요합니다';
  }

  @override
  String agentV2UpgradeMaterialsHint(String name) {
    return '캐릭터 프로필에서 ‘$name’을 더 계약하세요';
  }

  @override
  String get agentV2UpgradeGetActors => '역할 획득하기';

  @override
  String agentV2UpgradeActorsSyncing(int count) {
    return '새 캐릭터 $count개를 동기화하는 중입니다. 업그레이드 조건이 업데이트되었습니다';
  }

  @override
  String get agentV2UpgradeConfirmSelectMaterials =>
      '소모할 동일 IP·동일 레벨 캐릭터를 선택하세요';

  @override
  String get agentV2UpgradeConfirmSalaryLabel => '출연료';

  @override
  String get agentV2SalaryDetailTitle => '캐릭터 출연료';

  @override
  String get agentV2SalaryHourly => '시간당 출연료';

  @override
  String get agentV2SalaryUnit => 'STORY / 시간';

  @override
  String get agentV2SalaryFormula =>
      '캐릭터 출연료 = IP 출연료 × 출연료 계수 × CP 계수 × Trust2';

  @override
  String get agentV2SalaryFormulaLv1 => 'Lv.1 캐릭터 출연료 = 가격 계수 × 히트 계수';

  @override
  String agentV2SalaryFormulaLevel(int level) {
    return 'Lv.$level 출연료 = Lv.1 출연료 × 출연료 계수';
  }

  @override
  String get agentV2SalaryLv1Pay => 'Lv.1 출연료';

  @override
  String get agentV2SalaryCoefficient => '출연료 계수';

  @override
  String agentV2SalaryCoefficientWithLevel(int level, String roleName) {
    return '출연료 계수 (Lv.$level $roleName)';
  }

  @override
  String get agentV2SalaryCpCoefficient => 'CP 계수';

  @override
  String get agentV2PerformanceConfirmDescription =>
      '이 캐릭터는 공연 시 자동으로 출연료를 얻습니다. 공연 중에는 시간당 체력 1이 소모되며, 체력이 소진되면 수익 발생이 중단됩니다.';

  @override
  String get agentV2PerformanceConfirmTitle => '공연 배치';

  @override
  String get agentV2PerformanceZeroFeePrefix => '해당 캐릭터 IP는 현재 ';

  @override
  String get agentV2PerformanceZeroFeeHighlight => '출연료가 0';

  @override
  String get agentV2PerformanceZeroFeeSuffix =>
      '이므로 공연으로 수익이 발생하지 않습니다. 또한 공연 중에는 시간당 체력 1이 소모됩니다. 그래도 계속하시겠습니까?';

  @override
  String get agentV2PerformanceScheduledSuccess => '공연이 예약되었습니다';

  @override
  String get agentV2PerformanceSlotsFull => '공연 슬롯이 가득 찼습니다(최대 5개)';

  @override
  String get gameDeployStaminaDepleted => '체력이 소진되었습니다. 체력을 보충한 후 공연할 수 있습니다';

  @override
  String get agentMoreRules => '규칙';

  @override
  String get agentMoreSalaryAndPool => '출연료와 보상 풀';

  @override
  String get agentV2WeeklySalaryTitle => '레벨업 · 공연 · 출연료 벌기';

  @override
  String get agentV2WeeklySalaryLabel => '이번 주 출연료';

  @override
  String get gameDeployConfirmDesc =>
      '이 캐릭터는 자동으로 스테이킹 채굴에 참여하여 지속적으로 STORY 수익을 생성합니다. 참고: 매 정각마다 체력 1포인트가 소모되며, 체력이 모두 소진되면 수익 생성이 중단됩니다.';

  @override
  String get gameRecallConfirm => '소환 확인';

  @override
  String get gameRecallDesc =>
      '이 캐릭터를 소환하면 드라마 생산 보상이 일시 중지되지만, 현재 체력에는 영향을 미치지 않습니다.';

  @override
  String get actorStatCompletionTitle => '완주';

  @override
  String get actorStatCompletionDesc => '이 캐릭터가 출연한 모든 드라마의 완주 횟수 합계';

  @override
  String get actorStatHeatTitle => '히트';

  @override
  String get actorStatHeatDesc => '이 캐릭터 IP가 출연한 모든 단편 드라마의 최근 30일 히트 합계';

  @override
  String get actorStatIpPowerTitle => 'IP 출연료';

  @override
  String get actorStatIpPowerDesc => 'IP 출연료 = 가격 계수 × 히트 계수 × Trust1';

  @override
  String get dramaFavoriteLabel => '찜';

  @override
  String get dramaRatingLabel => '평점';

  @override
  String get dramaUnnamed => '제목 없음';

  @override
  String get videoNotReady => '비디오가 아직 준비되지 않았습니다. 잠시 후 다시 시도해 주세요';

  @override
  String get inviteDirectSubordinates => '초대한 사용자';

  @override
  String inviteTotalCount(int count) {
    return '총 $count명';
  }

  @override
  String get inviteTotalLabel => '총 인원';

  @override
  String get inviteActiveLabel => '활성 사용자';

  @override
  String get invitePendingLabel => '활성화 대기';

  @override
  String get inviteEmpty => '하위 사용자가 없습니다';

  @override
  String inviteRegisteredAt(String date) {
    return '$date에 등록';
  }

  @override
  String get gameUpgradeMaxLevel => '최대 등급에 도달했습니다';

  @override
  String get listNoMoreData => '더 이상 데이터가 없습니다';

  @override
  String get iapSheetTitle => '포인트 구매';

  @override
  String get iapSheetSubtitle => '포인트는 캐릭터 계약 등 앱 내 서비스에 사용됩니다';

  @override
  String get iapBalance => '잔액';

  @override
  String get iapConfirmPurchase => '구매 확인';

  @override
  String get iapPurchaseSuccess => '구매 완료';

  @override
  String get iapPurchaseFailed => '구매에 실패했습니다. 나중에 다시 시도해 주세요';

  @override
  String get iapPurchaseFailedTitle => '구매 실패';

  @override
  String get iapCrediting => '입금 처리 중입니다. 잠시 기다려 주세요';

  @override
  String get iapNoProducts => '구매할 수 있는 상품이 없습니다';

  @override
  String get iapSuccessConfirm => '확인';

  @override
  String iapGainedPoints(String value) {
    return '+$value';
  }

  @override
  String iapPointsCount(int count) {
    return '$count 포인트';
  }

  @override
  String get gameBatchRefillTransactionTooLarge =>
      '일괄 체력 회복 트랜잭션이 너무 큽니다. 배우 수를 줄인 후 다시 시도해 주세요.';

  @override
  String get agentV2RefillTitle => '체력 보충';

  @override
  String get agentV2RefillCost => '비용';

  @override
  String get agentV2RefillActorButton => '이 캐릭터';

  @override
  String get agentV2RefillAllActors => '공연 중인 모든 캐릭터 보충';

  @override
  String agentV2RefillActorCount(int count) {
    return '$count명';
  }

  @override
  String get agentV2RefillAllButton => '모두 보충';

  @override
  String get agentV2RefillOr => '또는';

  @override
  String get agentV2RestAll => '모두 휴식';

  @override
  String agentV2RestActorCount(int count) {
    return '$count명';
  }

  @override
  String get salaryPoolRateUnit => 'STORY / 시간';

  @override
  String get salaryPoolDecayInfo => '주간 감쇠 계수 ×0.99572';

  @override
  String get salaryPoolStakeLabel => '공연 보상 풀(75%)';

  @override
  String get salaryPoolInviteLabel => '초대 보상 풀(25%)';

  @override
  String get salaryPoolRule1Title => '전체 명목 산출량 ≤ 주간 상한:';

  @override
  String get salaryPoolRule2Title => '전체 명목 산출량 > 주간 상한:';

  @override
  String get salaryPoolRule2Body => '실제 지급액 = 사용자 명목 산출량 × (주간 상한 ÷ 전체 명목 산출량)';

  @override
  String get agentV3WeeklySalary => '이번 주 출연료';

  @override
  String get agentV3PerformAll => '일괄 공연';

  @override
  String get agentV3RestAll => '일괄 휴식';

  @override
  String get agentV3RestAllDescription =>
      '공연 중인 모든 캐릭터를 불러와 체력 소모와 보상 획득을 중지합니다';

  @override
  String get agentV3RefillAll => '일괄 보충';

  @override
  String get agentV3RefillAllDescription => '공연 중인 캐릭터의 체력을 모두 채웁니다';

  @override
  String get agentV3RefillCost => '소모';

  @override
  String get agentV3RefillNoActors => '체력 보충이 필요한 캐릭터가 없습니다';

  @override
  String get agentV3SignActor => '캐릭터 계약';

  @override
  String get agentV3Todo => '할 일';

  @override
  String get agentV3Upgrade => '업그레이드';

  @override
  String agentV3UpgradeMaterialHint(int count) {
    return '업그레이드하려면 동일한 IP와 레벨의 캐릭터 $count개가 필요합니다';
  }

  @override
  String get agentV3Waiting => '대기';

  @override
  String get agentV3WaitingActorsTitle => '대기 중인 캐릭터';

  @override
  String get agentV3WaitingActorsDescription => '휴식 중인 캐릭터는 시간당 스태미나를 1 회복합니다';

  @override
  String get agentV3Recycle => '회수';

  @override
  String get agentV3RecycleActorsTitle => '캐릭터 회수';

  @override
  String get agentV3RecyclePerforming => '출연 중';

  @override
  String get agentV3RecycleReceive => '받게 될 보상';

  @override
  String get agentV3RecyclePermanentWarning => '캐릭터가 영구적으로 소각되며 복구할 수 없습니다';

  @override
  String get agentV3RecycleConfirm => '소각 확인';

  @override
  String get agentV3RecycleConfirmAgain => '다시 눌러 소각';

  @override
  String get agentV3RecycleSubmitted => '캐릭터 회수에 성공했습니다';

  @override
  String get agentV3RecycleEstimateUnavailable =>
      '회수 예상치를 불러올 수 없습니다. 다시 시도해 주세요';

  @override
  String get agentV3EnergyPack => '에너지 보급 팩';

  @override
  String get agentV3EnergyPackDescription =>
      '캐릭터의 체력을 모두 회복하며, 캐릭터 레벨에 따라 소모됩니다.';

  @override
  String get agentV3TrainingManual => '훈련 교본';

  @override
  String get agentV3TrainingManualDescription =>
      '캐릭터 업그레이드 재료이며, 업그레이드 시 캐릭터 레벨에 따라 소모됩니다.';

  @override
  String get agentV3PurchaseButton => '구매';

  @override
  String agentV3PurchaseWalletBalance(String balance, String currency) {
    return '잔액 $balance $currency';
  }

  @override
  String agentV3PurchaseTitle(String item) {
    return '$item 구매';
  }

  @override
  String get agentV3PurchaseUnitPrice => '단가';

  @override
  String get agentV3PurchaseQuantity => '수량';

  @override
  String get agentV3PurchaseTotal => '합계';

  @override
  String get agentV3PurchaseConfirm => '결제 확인';

  @override
  String get agentV3PurchaseUnavailable => '현재 환경에서는 아이템을 구매할 수 없습니다';

  @override
  String get agentV3PurchaseConfigUnavailable =>
      '아이템 가격을 불러올 수 없습니다. 잠시 후 다시 시도해 주세요';

  @override
  String get agentV3PurchaseSubmitted =>
      '구매가 완료되었습니다. 아이템 가방(에이전트 페이지)에 보관되었습니다';

  @override
  String get agentV3PurchaseCreditPending =>
      '체력 팩이 아직 지급 중입니다. 잠시 후 다시 시도해 주세요';

  @override
  String get agentV3PurchaseCrediting => '온체인 확인 및 지급 중';

  @override
  String agentV3PurchaseBalance(String count) {
    return '현재 보유: $count';
  }

  @override
  String get agentV3RefillTitle => '스태미나 완전 회복';

  @override
  String agentV3RefillLevelCost(String level) {
    return 'Lv.$level 소모';
  }

  @override
  String get agentV3RefillAvailable => '사용 가능';

  @override
  String get agentV3RefillUse => '사용';

  @override
  String get agentV3RefillSuccess => '스태미나를 모두 회복했습니다';

  @override
  String agentV3RefillAllSuccess(int actorCount, String packCount) {
    return '캐릭터 $actorCount명의 체력을 보충했습니다(보급 팩 $packCount개 소모)';
  }

  @override
  String get agentV3RefillConfigUnavailable => '스태미나 팩 소모 설정을 사용할 수 없습니다';

  @override
  String get agentV3RefillInsufficient => '스태미나 팩이 부족합니다';
}
