// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'StoryFun';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonNoData => 'No data';

  @override
  String get commonNo => 'No';

  @override
  String get commonYes => 'Yes';

  @override
  String get publishDrama => 'Post Drama';

  @override
  String get publishVideo => 'Post Video';

  @override
  String get publishVideoUploadTitle => 'Upload video file';

  @override
  String get publishVideoFileHint =>
      'Supports mp4, flv, wmv, mkv, avi, mov and webm. Maximum 2GB';

  @override
  String get publishVideoChooseFile => 'Choose file';

  @override
  String get publishVideoChangeFile => 'Replace file';

  @override
  String get publishVideoChooseSource => 'Choose video source';

  @override
  String get publishVideoChooseFromGallery => 'Choose from gallery';

  @override
  String get publishVideoChooseFromFiles => 'Choose from files';

  @override
  String get publishVideoPreparing => 'Preparing video…';

  @override
  String get publishVideoCoverTitle => 'Video cover';

  @override
  String get publishVideoChangeCover => 'Replace cover';

  @override
  String get publishVideoCoverHint => 'JPG/PNG, up to 5MB';

  @override
  String get publishVideoDescriptionLabel => 'Description';

  @override
  String get publishVideoRequired => '(Required)';

  @override
  String get publishVideoDescriptionHint =>
      'Add a description (up to 200 characters)';

  @override
  String get publishVideoSaveDraft => 'Save draft';

  @override
  String get publishVideoDraftEditModeNotSupported =>
      'Cannot save draft in edit mode';

  @override
  String get publishVideoDraftNothingToSave => 'Nothing to save';

  @override
  String get publishVideoNext => 'Next';

  @override
  String get publishVideoCoverCropTitle => 'Crop video cover';

  @override
  String get publishVideoVideoTooLarge =>
      'This video is over 2GB. Please choose a smaller video';

  @override
  String get publishVideoVideoPickFailed =>
      'Could not select the video. Try again';

  @override
  String get publishVideoInsufficientStorage =>
      'Not enough device storage to prepare this video';

  @override
  String get publishVideoPermissionDenied =>
      'Could not access this video. Check photo or file permissions';

  @override
  String get publishVideoSourceUnavailable =>
      'This video is temporarily unavailable. Download cloud files and try again';

  @override
  String get publishVideoPrepareFailed =>
      'Could not prepare the video. Try again or choose it from Files';

  @override
  String get publishVideoMetadataUnavailable =>
      'Could not read the video details. Choose another file';

  @override
  String get publishVideoCoverTooLarge => 'The cover image cannot exceed 5MB';

  @override
  String get publishVideoCoverUnsupportedFormat =>
      'Only JPG/PNG images are supported';

  @override
  String get publishVideoCoverPickFailed =>
      'Could not select the cover. Try again';

  @override
  String get publishVideoUploadSessionFailed =>
      'Could not create an upload session. Try again';

  @override
  String get publishVideoPublishedSuccess => 'Video posted';

  @override
  String get publishVideoUpdatedSuccess => 'Video updated';

  @override
  String get publishActorIp => 'Launch IP';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonOk => 'Got it';

  @override
  String get commonNotice => 'Notice';

  @override
  String get commonRetry => 'Retry';

  @override
  String get publicProfileLikedEmpty => 'No liked dramas yet';

  @override
  String get profileTabDramas => 'Dramas';

  @override
  String get profileTabWorks => 'Works';

  @override
  String get profileTabActorIp => 'Character IP';

  @override
  String dramaUnlockConfirmLabel(String price, String currency) {
    return 'Unlock for $price $currency';
  }

  @override
  String dramaAllEpisodes(int count) {
    return 'All $count episodes';
  }

  @override
  String dramaAllEpisodesFull(Object count) {
    return 'All $count episodes';
  }

  @override
  String get dramaLoading => 'Loading dramas...';

  @override
  String get dramaEmpty => 'No dramas available';

  @override
  String get dramaRefresh => 'Refresh';

  @override
  String get navTheater => 'Theater';

  @override
  String get navHome => 'Home';

  @override
  String get theaterTabShortDrama => 'Drama';

  @override
  String get theaterTabRecommend => 'For You';

  @override
  String get playerWatchFullDrama => 'Watch full drama';

  @override
  String get playerStoryPerHourUnit => 'STORY/h';

  @override
  String get navNft => 'IP Market';

  @override
  String get navNftIp => 'Character IP';

  @override
  String watchFullDramaEpisodes(int count) {
    return 'Watch Drama · $count Ep Total';
  }

  @override
  String get navCreate => 'Create';

  @override
  String get navProfile => 'Profile';

  @override
  String get navMy => 'Manager';

  @override
  String get aboutTitle => 'About Us';

  @override
  String get aboutVision => 'AI · Web3 · Protocol';

  @override
  String get aboutVisionDesc =>
      'Driven by three forces, transforming passive narrative experiences into active generation.';

  @override
  String get aboutAiDesc => 'Your ideas automatically turn into stories';

  @override
  String get aboutWeb3Desc => 'Your creations belong to you forever';

  @override
  String get aboutProtocolDesc => 'Your stories can continue infinitely';

  @override
  String get aboutIdentityTitle => 'Your Narrative Identity';

  @override
  String get aboutIdentityDesc =>
      'You are a narrative universe unfolding in yourself';

  @override
  String get aboutIdentityCreator => 'Creator';

  @override
  String get aboutIdentityCreatorDesc =>
      'Actively writing one\'s own narrative';

  @override
  String get aboutIdentityWitness => 'Witness';

  @override
  String get aboutIdentityWitnessDesc =>
      'Participating in and validating other narratives';

  @override
  String get aboutIdentityCoCreator => 'Co-creator';

  @override
  String get aboutIdentityCoCreatorDesc =>
      'Entering and rewriting the narrative structure';

  @override
  String get aboutIdentitySpreader => 'Spreader';

  @override
  String get aboutIdentitySpreaderDesc =>
      'Spreading narratives you find valuable';

  @override
  String get aboutTokenomicsTitle => 'STORY: Narrative Rights Token';

  @override
  String get aboutTokenomicsDesc =>
      'Become a co-producer of AI dramas, restructuring the revenue distribution of the film industry.';

  @override
  String get aboutTokenomicsGov => 'Governance';

  @override
  String get aboutTokenomicsGovDesc =>
      'Vote to decide the genre and direction of the next AI drama';

  @override
  String get aboutTokenomicsRevenue => 'Revenue Sharing';

  @override
  String get aboutTokenomicsRevenueDesc =>
      'Share platform subscriptions, copyright licensing, and merchandise sales dividends';

  @override
  String get aboutTokenomicsAccess => 'Access';

  @override
  String get aboutTokenomicsAccessDesc =>
      'Sneak peek of the latest episodes, unlock exclusive content';

  @override
  String get aboutStakingTitle => 'Staking Dividends';

  @override
  String get aboutStakingDesc =>
      'Drama NFT · Character NFT · STORY → Stake for dividends';

  @override
  String get aboutStakingDrama => 'Drama NFT Staking';

  @override
  String get aboutStakingDramaDesc => 'Drama Creator · Receive dividends';

  @override
  String get aboutStakingActor => 'Character NFT Staking';

  @override
  String get aboutStakingActorDesc =>
      'Character stars in drama · Receive dividends';

  @override
  String get aboutStakingStory => 'STORY Staking';

  @override
  String get aboutStakingStoryDesc => 'Stake to drama · Share revenue';

  @override
  String get aboutHeroTitle => 'Create Your Own Story';

  @override
  String get aboutHeroDesc =>
      'Your life is not a script to be experienced, but a narrative being written by you';

  @override
  String get loginTitle => 'Email Login';

  @override
  String get loginSubtitle =>
      'Login via Privy Email OTP, which will automatically create a Solana embedded wallet.';

  @override
  String get loginPlaceholder => 'Enter your email address';

  @override
  String get loginEmailHintFormat => 'your@email.com';

  @override
  String get loginVerificationFailed => 'Verification failed';

  @override
  String get loginNeedCodeFirst => 'Please request a verification code first';

  @override
  String get loginCreateWalletFailed => 'Failed to create wallet';

  @override
  String get loginGetTokenFailed => 'Failed to get access token';

  @override
  String get loginPrivyUnavailable =>
      'Login service is unavailable. Please restart the app and try again';

  @override
  String get loginSendCodeFailed =>
      'Failed to send verification code. Please try again later';

  @override
  String get loginTooManyRequests =>
      'Too many requests. Please wait and try again';

  @override
  String get loginVerificationSuccessful => 'Verification successful';

  @override
  String get loginSendCode => 'Get Code';

  @override
  String get loginSendingCode => 'Sending...';

  @override
  String get loginCodePlaceholder => 'Enter 6-digit verification code';

  @override
  String get loginSubmit => 'Login';

  @override
  String get loginSubmitting => 'Logging in...';

  @override
  String get loginEmailRequired => 'Please enter your email';

  @override
  String get loginCodeRequired => 'Please enter verification code';

  @override
  String get loginSuccess => 'Login Successful';

  @override
  String get loginErrorPrefix => 'Login failed: ';

  @override
  String loginCodeSent(String email) {
    return 'Verification code has been sent to $email';
  }

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginCodeLabel => 'Verification Code';

  @override
  String get loginVerifying => 'Verifying, please wait...';

  @override
  String get loginVerifyAndSubmit => 'Verify and Login';

  @override
  String get loginChangeEmail => 'Change Email';

  @override
  String get loginNotNow => 'Not Now';

  @override
  String get loginInvalidEmail => 'Please enter a valid email address';

  @override
  String get profileTitle => 'Agent';

  @override
  String get profileNotLoggedIn => 'Not Logged In';

  @override
  String get profileClickLogin => 'Login / Register';

  @override
  String get profileMyWallet => 'My Wallet';

  @override
  String get profileWallet => 'Wallet';

  @override
  String get profileTradeStory => 'Trade STORY';

  @override
  String get profileWalletCreating => 'Creating...';

  @override
  String get walletNetworkSolana => 'Solana';

  @override
  String get walletNetworkEvm => 'EVM';

  @override
  String get profileEarnings => 'Earnings';

  @override
  String get profileMyNft => 'My NFTs';

  @override
  String get profileMyFavorites => 'My Favorites';

  @override
  String get profileWatchHistory => 'Watch History';

  @override
  String get profileCreatorCatalog => 'Creators';

  @override
  String get profileIdentityAuth => 'Identity Verification';

  @override
  String get profileAccountSecurity => 'Account Security';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileAboutUs => 'About Us';

  @override
  String get profileHelpFeedback => 'Help & Feedback';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileLogoutConfirm => 'Are you sure to log out?';

  @override
  String get profileLogoutSuccess => 'Logged out successfully';

  @override
  String get mainPressBackAgainToExit => 'Press back again to exit';

  @override
  String get languageSelectTitle => 'Select Language';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search dramas, works, characters, users...';

  @override
  String get searchEmpty => 'No related content';

  @override
  String get searchNoData => 'No related content';

  @override
  String get searchPlaceholder => 'Search dramas, works, characters, users...';

  @override
  String get theaterSearchPlaceholder =>
      'Search dramas, works, characters, users...';

  @override
  String get searchHistory => 'Recent searches';

  @override
  String get searchClear => 'Clear history';

  @override
  String get searchAction => 'Search';

  @override
  String get searchHistoryCleared => 'Search history cleared';

  @override
  String get searchKeywordTooShort => 'Enter at least 2 characters';

  @override
  String get searchTabDramas => 'Dramas';

  @override
  String get searchTabWorks => 'Works';

  @override
  String get searchTabActors => 'Character IP';

  @override
  String get searchTabUsers => 'Users';

  @override
  String searchEpisodeNo(int episodeNo) {
    return 'Ep. $episodeNo';
  }

  @override
  String searchMinutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String searchHoursAgo(int count) {
    return '$count hr ago';
  }

  @override
  String searchDaysAgo(int count) {
    return '$count days ago';
  }

  @override
  String searchDramasCount(int count) {
    return 'Dramas ($count)';
  }

  @override
  String searchActorsCount(int count) {
    return 'Characters ($count)';
  }

  @override
  String searchDramaEpisodesWithCast(int count, String actors) {
    return 'All $count episodes | Cast: $actors';
  }

  @override
  String get nftTitle => 'NFT Character Square';

  @override
  String get nftLoading => 'Loading Character IPs...';

  @override
  String get nftEmpty => 'No Character IPs';

  @override
  String get nftRefresh => 'Refresh';

  @override
  String nftIdPrefix(String id) {
    return 'ID: #$id';
  }

  @override
  String get nftRarity => 'Rarity';

  @override
  String get nftStatusStaked => 'Staked';

  @override
  String get nftStatusIdle => 'Idle';

  @override
  String get nftPrice => 'Price';

  @override
  String get dramaDetailTitle => 'Drama Detail';

  @override
  String get dramaDetailLoading => 'Loading…';

  @override
  String get dramaDetailRetry => 'Retry';

  @override
  String get dramaDetailEpisodeList => 'Episodes';

  @override
  String get dramaDetailSynopsis => 'Synopsis';

  @override
  String get dramaDetailExpand => 'Expand';

  @override
  String get dramaDetailCollapse => 'Collapse';

  @override
  String get dramaDetailTabIntro => 'Intro';

  @override
  String get dramaDetailTabEpisodes => 'Episodes';

  @override
  String get dramaDetailTabComments => 'Comments';

  @override
  String get dramaDetailTabRoles => 'Character IP';

  @override
  String get dramaDetailSignMoreCharacterIps => 'Sign more character IPs';

  @override
  String get dramaDetailCharactersEmpty => 'No character IPs bound yet';

  @override
  String dramaDetailRoleSalary(String amount) {
    return 'Salary $amount';
  }

  @override
  String dramaDetailRoleSalaryPerHour(String amount) {
    return 'Salary $amount STORY/h';
  }

  @override
  String get dramaDetailRoleUnbound => 'Unbound';

  @override
  String get dramaCastActorsTitle => 'Cast character IPs';

  @override
  String dramaDetailCompletion(String count) {
    return '$count completed views';
  }

  @override
  String dramaDetailHeat(String count) {
    return '$count heat';
  }

  @override
  String dramaDetailTotalEpisodes(int count) {
    return '$count Episodes';
  }

  @override
  String get dramaDetailRatingTitle => 'Rate this Drama';

  @override
  String get dramaDetailWantToRate => 'Rate this';

  @override
  String get dramaDetailNotRated => 'Not rated';

  @override
  String get dramaDetailCompletionLabel => 'Completed Views';

  @override
  String get dramaDetailHeatLabel => 'Heat';

  @override
  String get dramaDetailSynopsisLead => 'Synopsis: ';

  @override
  String get dramaDetailRatingEmpty => 'Your rating: --';

  @override
  String dramaDetailRatingValue(int rating) {
    return 'Your rating: $rating';
  }

  @override
  String get dramaDetailRatingConfirm => 'Confirm Rating';

  @override
  String dramaDetailRatingSuccess(int rating) {
    return 'Rated successfully: $rating stars!';
  }

  @override
  String get dramaDetailSelectEpisodeHint =>
      'Select an episode to start playback';

  @override
  String get dramaFavorited => 'Favorited';

  @override
  String get dramaUnfavorited => 'Unfavorited';

  @override
  String get dramaLiked => 'Liked';

  @override
  String get dramaUnliked => 'Unliked';

  @override
  String get playerFollowed => 'Followed';

  @override
  String get playerUnfollowed => 'Unfollowed';

  @override
  String get errorNetwork => 'Network error, please try again later';

  @override
  String get errorTimeout => 'Request timed out, please try again';

  @override
  String get errorParse => 'Failed to parse response data';

  @override
  String get errorUnauthorized => 'Please log in first';

  @override
  String get authSessionExpired =>
      'Your session has expired. Please sign in again';

  @override
  String get errorNotFound => 'Resource not found';

  @override
  String get iapOrderInFlight =>
      'You have an unfinished order for this item, please try again later';

  @override
  String get errorOperationFailed => 'Operation failed';

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
  String get uploadErrorFileTypeNotAllowed =>
      'This video format is not supported. Choose another file';

  @override
  String get uploadErrorFileSizeExceeded =>
      'The file is too large. Choose another file';

  @override
  String get uploadErrorMultipartInvalid =>
      'The upload record expired. Upload the video again';

  @override
  String get uploadStatusWaitingNetwork => 'Waiting for network...';

  @override
  String get uploadStatusMerging => 'Merging video...';

  @override
  String get uploadActionPause => 'Pause';

  @override
  String get uploadActionResume => 'Resume upload';

  @override
  String get uploadCellularDialogMessage =>
      'You are not on Wi-Fi. Continue uploading over mobile data?';

  @override
  String get errorInvalidRoleId =>
      'Invalid character ID. Please refresh the page and try again.';

  @override
  String get errorInvalidRoleNftAssetId =>
      'Invalid character NFT assetId. Please refresh the page and try again.';

  @override
  String get errorInvalidRoleCollectionAssetId =>
      'Invalid character collection assetId. Please refresh the page and try again.';

  @override
  String get roleNftLabelUnknown => 'RoleNFT#Unknown';

  @override
  String roleNftLabel(String prefix) {
    return 'RoleNFT#$prefix';
  }

  @override
  String errorBusiness(String message) {
    return 'Operation failed: $message';
  }

  @override
  String errorUnknown(String message) {
    return 'An unknown error occurred: $message';
  }

  @override
  String errorNotSupported(String message) {
    return 'Operation not supported: $message';
  }

  @override
  String get playerEpisodeSelect => 'Episodes';

  @override
  String get playerPlayFailed => 'Playback failed';

  @override
  String get playerDramaUnavailable => 'This drama is unavailable';

  @override
  String get playerContentUnavailable =>
      'This content is not published or is no longer available';

  @override
  String get creatorWorkNotFound =>
      'This work does not exist and cannot be viewed';

  @override
  String get creatorWorkNotPublished =>
      'This work is not published and cannot be viewed yet';

  @override
  String get creatorOfflineReasonUnavailable =>
      'No delisting reason is available';

  @override
  String get playerTapRetry => 'Tap to retry';

  @override
  String playerEpisodeTotal(int count) {
    return '$count episodes';
  }

  @override
  String playerEpisodeLabel(int episodeNo) {
    return 'Episode $episodeNo';
  }

  @override
  String get playerLike => 'Like';

  @override
  String get playerComment => 'Comment';

  @override
  String get playerFavorite => 'Favorite';

  @override
  String get playerShare => 'Share';

  @override
  String playerShareDramaEpisode(
    String title,
    int episodeNo,
    String description,
    String url,
  ) {
    return '$title | Ep.$episodeNo: $description $url. Watch beautiful AI short dramas on StoryFun.';
  }

  @override
  String playerShareDramaEpisodeNoDesc(
    String title,
    int episodeNo,
    String url,
  ) {
    return '$title | Ep.$episodeNo $url. Watch beautiful AI short dramas on StoryFun.';
  }

  @override
  String playerShareShortVideo(String description, String url) {
    return '$description $url. Watch beautiful short videos on StoryFun.';
  }

  @override
  String playerShareShortVideoNoDesc(String url) {
    return '$url. Watch beautiful short videos on StoryFun.';
  }

  @override
  String playerShareDrama(String title, String url) {
    return '$title $url. Watch beautiful AI short dramas on StoryFun.';
  }

  @override
  String playerShareDramaNoTitle(String url) {
    return '$url. Watch beautiful AI short dramas on StoryFun.';
  }

  @override
  String playerRatingLabel(String rating) {
    return '$rating pts';
  }

  @override
  String get loginOrSignUp => 'Log in or Sign up';

  @override
  String get loginEnterCode => 'Enter confirmation code';

  @override
  String loginCheckEmailDesc(String email) {
    return 'Please check $email for an email from privy.io and enter your code below.';
  }

  @override
  String loginResendCountdown(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get loginResendBtn => 'Resend';

  @override
  String get loginProtectedByPrivy => 'Protected by Privy';

  @override
  String get loginAgreeLead => 'I agree to the';

  @override
  String get loginAgreeAnd => 'and';

  @override
  String get loginAgreeConfirmLead => 'By clicking Confirm, you agree to the';

  @override
  String get loginAgreeRequired =>
      'Please agree to the Terms of Service and Privacy Policy first';

  @override
  String get deletingAccountPending => 'Account pending deletion';

  @override
  String get deletingAccountCancelDeletion => 'Cancel account deletion';

  @override
  String get deletingAccountGoBack => 'Go back';

  @override
  String get drawerEmailAccount => 'Email account';

  @override
  String get drawerClickToLogin => 'Click to log in';

  @override
  String get drawerBuyStory => 'Trade STORY';

  @override
  String get drawerDeposit => 'Deposit';

  @override
  String get drawerWithdraw => 'Withdraw';

  @override
  String get drawerNotifications => 'Notifications';

  @override
  String get drawerNoNotifications => 'No notifications';

  @override
  String get notificationTabSystem => 'System';

  @override
  String get notificationTabInteraction => 'Activity';

  @override
  String get notificationTagIpSign => 'Character IP signed';

  @override
  String get notificationTagRoleManagement => 'Character management';

  @override
  String get notificationTagShowRevenue => 'Performance earnings';

  @override
  String get notificationTagLike => 'Like';

  @override
  String get notificationTagFavorite => 'Favorite';

  @override
  String notificationSignedActor(String user, String actor) {
    return '@$user signed character IP $actor';
  }

  @override
  String notificationShareEarned(String amount) {
    return 'You earned a $amount share';
  }

  @override
  String notificationStaminaLow(String actor) {
    return '$actor is out of stamina. Refill or let them rest';
  }

  @override
  String notificationCurrentStamina(String value) {
    return 'Current stamina $value';
  }

  @override
  String notificationShowEnded(String range) {
    return '$range performance ended';
  }

  @override
  String notificationIncomeEarned(String amount) {
    return 'You earned $amount';
  }

  @override
  String get notificationActionClaim => 'Claim';

  @override
  String get notificationActionRefill => 'Refill';

  @override
  String get notificationInteractionLikedVideo => 'Liked your video';

  @override
  String notificationInteractionLikedDrama(String title) {
    return 'Liked your short drama “$title”';
  }

  @override
  String get notificationInteractionFavoritedVideo => 'Saved your video';

  @override
  String notificationInteractionFavoritedDrama(String title) {
    return 'Saved your short drama “$title”';
  }

  @override
  String notificationInteractionCommented(String content) {
    return 'Commented: $content';
  }

  @override
  String get notificationInteractionFollowedYou => 'Followed you';

  @override
  String get notificationActionMutualFollow => 'Mutual';

  @override
  String get notificationActionFollow => 'Follow';

  @override
  String get notificationDelete => 'Delete';

  @override
  String get notificationDeleteFailed =>
      'Failed to delete, please try again later';

  @override
  String get notificationRealtimeReceived => 'You received a new notification';

  @override
  String drawerEpisodeProgress(int current, int total) {
    return '$current/$total episodes';
  }

  @override
  String drawerNotificationSignedActor(String actor, String target) {
    return '$actor signed character IP $target';
  }

  @override
  String drawerNotificationLikedVideo(String actor) {
    return '$actor liked your video';
  }

  @override
  String drawerNotificationFavoritedDrama(String actor, String target) {
    return '$actor saved your short drama $target';
  }

  @override
  String get depositTitle => 'Deposit';

  @override
  String get insufficientBalanceTitle => 'Insufficient Balance';

  @override
  String insufficientBalanceDetail(String currency, String amount) {
    return '$currency balance is insufficient, you are short $amount $currency';
  }

  @override
  String get insufficientBalancePrompt => 'Go to recharge?';

  @override
  String get insufficientBalanceRecharge => 'Recharge';

  @override
  String get depositDesc =>
      'Please transfer tokens from an exchange or another wallet to the address below. The balance will update automatically once credited.';

  @override
  String get depositToken => 'Token';

  @override
  String get depositNetwork => 'Network';

  @override
  String get depositNetworkNote =>
      'Please confirm the transfer network. Using the wrong network may result in loss of assets.';

  @override
  String get depositAddress => 'Deposit Address';

  @override
  String get depositAddressCopied => 'Address copied to clipboard';

  @override
  String get depositSend => 'Send';

  @override
  String get depositReceive => 'Receive';

  @override
  String get depositConvertNote =>
      'Send tokens to this address and they will be automatically converted to USDC in your Story.fun account.';

  @override
  String depositMinNote(String minAmount, String token) {
    return 'Minimum deposit: $minAmount $token';
  }

  @override
  String depositExchangeRateNote(String rate) {
    return 'Current exchange rate is $rate. Credited amount = deposit × $rate';
  }

  @override
  String get depositWarning =>
      'Only deposit the selected token on the selected network. Other assets cannot be recovered.\nPlease confirm the transfer network; network errors may result in asset loss.';

  @override
  String get withdrawTitle => 'Withdraw';

  @override
  String get withdrawBalance => 'Withdrawable Balance';

  @override
  String get withdrawToken => 'Token';

  @override
  String get withdrawAddress => 'Withdrawal Address';

  @override
  String get withdrawAddressHint =>
      'Please enter or paste Solana recipient address';

  @override
  String get withdrawAddressHintEvm =>
      'Please enter or paste an EVM recipient address';

  @override
  String get withdrawInvalidEvmAddress => 'Please enter a valid EVM address';

  @override
  String get withdrawInvalidSolanaAddress =>
      'Please enter a valid Solana address';

  @override
  String get withdrawEvmGasNote =>
      'EVM withdrawals require enough native tokens for gas. The transfer is sent directly on-chain.';

  @override
  String get withdrawEvmFailed =>
      'EVM withdrawal failed. Please try again later.';

  @override
  String get withdrawAddressNote =>
      'Please confirm the address is correct. Once transferred, it cannot be recalled.';

  @override
  String get withdrawNetwork => 'Network';

  @override
  String get withdrawAmount => 'Amount';

  @override
  String get withdrawAmountHint => 'Enter withdrawal amount';

  @override
  String get withdrawMax => 'Max';

  @override
  String withdrawAvailableBalance(String balance, String token) {
    return 'Balance $balance $token';
  }

  @override
  String withdrawMinWarning(String minAmount, String token) {
    return 'Min withdrawal: $minAmount $token\nPlease check the address and network carefully; transactions cannot be recalled.';
  }

  @override
  String get withdrawConfirm => 'Confirm Withdraw';

  @override
  String get withdrawAll => 'All';

  @override
  String withdrawMinAmountError(String minAmt, String token) {
    return 'Minimum withdrawal amount is $minAmt $token';
  }

  @override
  String get withdrawExceedBalanceError =>
      'Withdrawal amount cannot exceed available balance';

  @override
  String get withdrawSameAsWalletError =>
      'Withdrawal address cannot be the same as your wallet address';

  @override
  String get withdrawConfirmTitle => 'Confirm Withdrawal';

  @override
  String withdrawConfirmMessage(String amount, String token, String address) {
    return 'Are you sure you want to withdraw $amount $token to the following Solana address?\n\n$address';
  }

  @override
  String get withdrawSuccessToast =>
      'Withdrawal request submitted successfully!';

  @override
  String get withdrawFailedToast => 'Withdrawal failed. Please try again.';

  @override
  String withdrawErrorToast(String error) {
    return 'An error occurred during withdrawal: $error';
  }

  @override
  String withdrawAddressHintWithToken(String token) {
    return 'Enter recipient $token wallet address';
  }

  @override
  String get withdrawFee => 'Fee';

  @override
  String withdrawFeeValue(String fee, String token) {
    return '$fee $token';
  }

  @override
  String withdrawMinAmount(String minAmount, String token) {
    return 'Min withdrawal: $minAmount $token';
  }

  @override
  String withdrawMaxAmount(String maxAmount, String token) {
    return 'Maximum withdrawal amount: $maxAmount $token';
  }

  @override
  String get withdrawSponsorSigning => 'Signing transaction...';

  @override
  String get withdrawSponsorSubmitting => 'Submitting on-chain transaction...';

  @override
  String get withdrawSponsorSuccess => 'Withdrawal submitted successfully!';

  @override
  String get withdrawSponsorFailed =>
      'Transaction submission failed. Please try again.';

  @override
  String get withdrawOrderProcessing => 'Order processing';

  @override
  String get withdrawOrderSuccess => 'Order completed';

  @override
  String get withdrawOrderFailed => 'Order failed';

  @override
  String withdrawOrderStatus(String status) {
    return 'Order status: $status';
  }

  @override
  String get qrScannerTitle => 'Scan QR Code';

  @override
  String get qrScannerHint => 'Align QR code within the frame to scan';

  @override
  String get drawerProfile => 'Personal Center';

  @override
  String get drawerCreatorManagement => 'Creator Management';

  @override
  String get drawerInvite => 'Invite';

  @override
  String get inviteTitle => 'Invite Friends';

  @override
  String get inviteTotalPeople => 'Total Invitees';

  @override
  String get inviteTotalRewards => 'Total Invitation Rewards';

  @override
  String get inviteWeeklyPool => 'Weekly Invite Reward Pool';

  @override
  String get inviteViewHistory => 'View Records';

  @override
  String get inviteShareSection => 'Share your invite link or code';

  @override
  String get inviteLinkSection => 'Invitation Link';

  @override
  String get inviteLinkSubtitle =>
      'Friends register through your link, sign contract and dispatch characters, and you will get extra STORY rewards';

  @override
  String get inviteCodeLabel => 'Invite Code';

  @override
  String get inviteCopyButton => 'Copy Link';

  @override
  String get inviteCopiedSuccess => 'Invitation link copied to clipboard!';

  @override
  String get inviteCodeCopiedSuccess => 'Invite code copied to clipboard!';

  @override
  String get inviteInvitedLabel => 'Invited';

  @override
  String get inviteRewardLabel => 'Rewards';

  @override
  String get inviteBindCode => 'Bind invite code';

  @override
  String get inviteBindCodePromptHint =>
      'You can bind it later on the Invite page';

  @override
  String get inviteBindCodePlaceholder => 'Enter invite code';

  @override
  String get inviteBindConfirm => 'Confirm';

  @override
  String get inviteBindSuccess => 'Invite code bound successfully';

  @override
  String get inviteBindCodeInvalid => 'Invalid invite code';

  @override
  String get inviteBindCodeAlreadyBound =>
      'This account has already bound an invite code';

  @override
  String get inviteRulesSection => 'Invitation Rules';

  @override
  String get inviteFaqPoolTitle => 'What is the weekly invite reward pool?';

  @override
  String get inviteFaqPoolBody =>
      'The weekly invite reward pool is an independent pool set up for invite activity. It rewards invite actions in the current week and is not deducted from invitees\' earnings. The pool has a weekly payout cap; after the cap is reached, payouts are scaled down by share. Statistics reset every Monday.';

  @override
  String get inviteFaqSettlementTitle => 'When are invite rewards settled?';

  @override
  String get inviteFaqSettlementBody =>
      'Invite rewards are settled in the same cycle as agent salaries: stats cut off every Monday at 00:00 (UTC). After settlement, claim them on the Rewards page.';

  @override
  String get inviteRuleSourceTitle => 'Source of Rewards';

  @override
  String get inviteRuleSourceSubtitle => 'Independent Invitation Sub-pool';

  @override
  String get inviteRuleSourceBody =>
      'Invitation rewards come from an independent invitation sub-pool in the NFT mining pool (accounting for 25% of the total mining pool), which is not deducted from the invitee\'s earnings. The invitation sub-pool has an independent weekly cap, and will be scaled down proportionally based on share after reaching the cap.';

  @override
  String get inviteRuleBaseTitle => 'Calculation Base';

  @override
  String get inviteRuleBaseSubtitle => 'By Actual STORY Received';

  @override
  String get inviteRuleBaseBody =>
      'Rewards are calculated based on the actual STORY received by the invitee in this period, not on nominal output. The STORY mined by the invitee themselves is not affected, and the invitation reward is paid extra.';

  @override
  String get inviteRuleLevelTitle => 'Reward Scope';

  @override
  String get inviteRuleLevelSubtitle => 'Direct invites only';

  @override
  String get inviteRuleLevelBody =>
      'Invitation rewards are paid only for users you invite directly. There is no multi-level or indirect commission.';

  @override
  String get inviteRuleConditionTitle => 'Validity Condition';

  @override
  String get inviteRuleConditionSubtitle =>
      'Only active downlines generate rewards';

  @override
  String inviteRuleConditionBody(String currency) {
    return 'The invitee must have actually mined STORY or made $currency payments to be counted as an active downline. Empty registrations do not generate rewards. The invitation relationship cannot be changed once established.';
  }

  @override
  String get drawerTxHistory => 'Transaction History';

  @override
  String get drawerFinanceDashboard => 'Finance Dashboard';

  @override
  String get financeDashboardComingSoon =>
      'Finance Dashboard is coming soon. Stay tuned.';

  @override
  String get financeDashboardPageTitle => 'Platform Finance Dashboard';

  @override
  String financeDashboardTotalUsdcIncome(String currency) {
    return 'Total $currency Income';
  }

  @override
  String get financeDashboardTotalStoryReleased => 'Total STORY Released';

  @override
  String financeDashboardTabUsdcIncome(String currency) {
    return '$currency Income Details';
  }

  @override
  String get financeDashboardTabVaultFunds => 'Vault fund accumulation';

  @override
  String get financeDashboardTabStoryRelease => 'STORY Release Overview';

  @override
  String get financeDashboardFeeMint => 'Signing fee';

  @override
  String get financeDashboardFeeRoyalty => 'Secondary Royalty';

  @override
  String get financeDashboardFeeItemPurchase => 'Purchase Items';

  @override
  String get financeDashboardFeeTx => 'Transaction Fee';

  @override
  String get financeDashboardLedgerBizSigningFee => 'Signing Fee';

  @override
  String get financeDashboardLedgerBizManualCredit => 'Manual Credit';

  @override
  String get financeDashboardLedgerBizManualDebit => 'Manual Debit';

  @override
  String get financeDashboardLedgerBizStaminaPurchase => 'Stamina Purchase Fee';

  @override
  String get financeDashboardLedgerBizSynthesisUpgrade =>
      'Synthesis Upgrade Fee';

  @override
  String get financeDashboardLedgerBizTransactionFee => 'Transaction Fee';

  @override
  String financeDashboardRecentUsdcLedger(String currency) {
    return 'Recent $currency Income';
  }

  @override
  String get financeDashboardViewMore => 'View More';

  @override
  String get financeDashboardTotalVaultFunds => 'Total Vault Funds';

  @override
  String get financeDashboardCoveredActorIp => 'Covered Character IP';

  @override
  String get financeDashboardActorVaultRanking => 'Character IP Vault ranking';

  @override
  String get storyReleaseTabAllocation => 'STORY Allocation';

  @override
  String get storyReleaseTabMiningRelease => 'Recent Mining Release';

  @override
  String get storyReleaseFieldPeriod => 'Period';

  @override
  String get storyReleaseFieldHardLimit => 'Weekly Hard Cap';

  @override
  String get storyReleaseFieldMiningRewards => 'Staking Mining';

  @override
  String get storyReleaseFieldInviteRewards => 'Invite Mining';

  @override
  String get storyReleaseFieldUsageRate => 'Usage Rate';

  @override
  String get storyReleaseFieldTarget => 'Allocation Target';

  @override
  String get storyReleaseFieldRatio => 'Ratio';

  @override
  String get storyReleaseFieldAmount => 'Amount';

  @override
  String get storyReleaseFieldReleased => 'Released';

  @override
  String get storyReleaseFieldProgress => 'Release Progress';

  @override
  String get storyReleaseCategoryNftMiningPool => 'NFT Mining Pool';

  @override
  String get storyReleaseCategoryTeam => 'Team';

  @override
  String get storyReleaseCategoryInvestors => 'Investors';

  @override
  String get storyReleaseCategoryLiquidity => 'Launchpad + Liquidity';

  @override
  String get storyReleaseCategoryTreasury => 'Treasury';

  @override
  String get storyReleaseCategoryMarketOps => 'Market Operations';

  @override
  String storyReleaseTotalSupplyBadge(String total) {
    return 'Total $total STORY';
  }

  @override
  String get drawerWhitepaper => 'Whitepaper';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonLoadFailed => 'Failed to load';

  @override
  String get commonNone => 'None';

  @override
  String get commonUntitled => 'Untitled';

  @override
  String get actorDetailTitle => 'Actor Home';

  @override
  String get actorDetailCastDramas => 'Cast Dramas';

  @override
  String get actorDetailTabCast => 'Cast';

  @override
  String get actorDetailTabInfo => 'Info';

  @override
  String get actorDetailNoCastRecords => 'No cast records';

  @override
  String get actorBondingCurve => 'Bonding Curve';

  @override
  String get actorContractAddress => 'Contract Address';

  @override
  String get actorCurrentPosition => 'Current Position';

  @override
  String actorCurrentPrice(String price, String currency) {
    return 'Current Price $price $currency';
  }

  @override
  String get actorFloorPrice => 'Floor Price';

  @override
  String get actorGoTrade => 'Trade';

  @override
  String get profileWalletTrade => 'Trade';

  @override
  String get actorHeatCoefficient => 'Heat coefficient';

  @override
  String get actorIpPower => 'IP Salary';

  @override
  String get actorPayMax => 'Max';

  @override
  String get actorPayUpgradeTitle => 'Salary upgrade rules';

  @override
  String get actorPayUpgradeReachHint =>
      'Current completed views of dramas this IP appears in can support upgrading to';

  @override
  String actorPayUpgradeCompletions(String count) {
    return '$count completed views';
  }

  @override
  String actorPayUpgradeMultiplier(String value) {
    return 'Salary ×$value';
  }

  @override
  String actorPayTitle(String name) {
    return '$name · Salary';
  }

  @override
  String get actorLv1PayHint => 'Sign to get a Lv.1 character';

  @override
  String get actorLv1PayFormula =>
      'Lv.1 salary = Price coefficient × Heat coefficient';

  @override
  String actorLv1PayEquals(String value) {
    return '=$value';
  }

  @override
  String actorIpPowerTitle(String name) {
    return '$name · IP Salary';
  }

  @override
  String get actorIpPowerFormula =>
      'IP Salary = Price coefficient × Heat coefficient × Trust1';

  @override
  String get actorPriceCoefficient => 'Price Coefficient';

  @override
  String actorPriceCoefficientValue(String value) {
    return 'Price Coefficient $value';
  }

  @override
  String get actorPriceCoefficientHelpA11y => 'View price coefficient details';

  @override
  String get actorPriceUnitName => 'Points';

  @override
  String get actorPriceCoefficientDialogFormulaLe100 => 'Coefficient = P0 ÷ 10';

  @override
  String get actorPriceCoefficientDialogDescLe100 => 'Linear growth';

  @override
  String actorPriceCoefficientDialogTitleGt100(String currency) {
    return 'P0 > 10 $currency';
  }

  @override
  String get actorPriceCoefficientDialogFormulaGt100 =>
      'Coefficient = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]';

  @override
  String get actorPriceCoefficientDialogDescGt100 =>
      'Growth slows, capped at 1.6';

  @override
  String actorPriceCoefficientDialogTitleLe100(String currency) {
    return 'P0 ≤ 10 $currency';
  }

  @override
  String actorPriceCoefficientFactorDesc(String currency1, String currency2) {
    return 'P0 ≤ 10 $currency1 coefficient = P0/10 (linear growth)\nP0 > 10 $currency2 → coefficient = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6] (asymptotic cap 1.6)';
  }

  @override
  String get actorHeatCoefficientFactorDesc =>
      'Character IP 30-day heat multiplier, based on engagement such as completed views, likes, and saves';

  @override
  String get actorTrustFactorDesc => 'Platform risk coefficient, default 1.0';

  @override
  String get actorStatCompletion => 'Completed Views';

  @override
  String get actorIdCopied => 'ID copied';

  @override
  String actorInitialPrice(String price, String currency) {
    return 'Initial Price: $price $currency';
  }

  @override
  String actorIpLabel(String label) {
    return 'Actor IP $label';
  }

  @override
  String get actorIssueInfo => 'Launch details';

  @override
  String actorIssuer(String name) {
    return 'Launcher $name';
  }

  @override
  String actorMintedCount(int minted, int maxSupply) {
    return 'Minted $minted/$maxSupply';
  }

  @override
  String get actorPriceCurve => 'Price Curve';

  @override
  String get actorSign => 'Sign';

  @override
  String get actorConfirmSign => 'Confirm signing';

  @override
  String get actorSignPriceLabel => 'Signing price';

  @override
  String get actorSignPriceDescription =>
      'Signing price rises automatically as more characters are signed. Early signers get better rates.';

  @override
  String get actorSignPriceFormula =>
      'Formula: Price = Initial Price × 5^(Signed Count ÷ Total Supply)';

  @override
  String actorPriceAxisLabel(String currency) {
    return 'Price ($currency)';
  }

  @override
  String get actorSignedCountAxisLabel => 'Signed count';

  @override
  String actorSignRemainingCount(int count) {
    return '$count remaining';
  }

  @override
  String get actorSignSoldOut => 'Sold out';

  @override
  String actorSignSupplySummary(String total, String remaining) {
    return 'Total $total · Remaining $remaining';
  }

  @override
  String get actorPricingFixed => 'Fixed Price';

  @override
  String get actorPricingCurve => 'Curve Price';

  @override
  String get actorPriceCurveDisclaimer =>
      'The initial price does not represent the platform\'s valuation; an upward trend on the chart does not indicate a rise in secondary market prices; and the platform does not guarantee returns.';

  @override
  String get actorPriceStatInitialPrice => 'Starting Price';

  @override
  String get actorPriceStatCurrentPrice => 'Current Price';

  @override
  String get actorPriceStatTailPrice => 'Reserve Price';

  @override
  String get actorPriceStatTotalSupply => 'Total supply';

  @override
  String get actorPriceStatSigned => 'Signed';

  @override
  String get actorPriceStatRemaining => 'Remaining';

  @override
  String get actorPricingType => 'Pricing Type';

  @override
  String get contentBadgeOfficialIssue => 'Official launch';

  @override
  String get contentBadgeCommunityIssue => 'Community launch';

  @override
  String get contentBadgePartnerIssue => 'Partner launch';

  @override
  String get contentBadgeVerifiedIssue => 'Launch by verified creators';

  @override
  String get contentBadgeOfficialDrama => 'Official Drama';

  @override
  String get contentBadgeCommunityDrama => 'Community Drama';

  @override
  String get contentBadgePartnerDrama => 'Partner Drama';

  @override
  String get contentBadgeVerifiedDrama => 'Verified Creator Drama';

  @override
  String get actorIpCopied => 'Copied';

  @override
  String get actorRiskIp => 'Risk IP';

  @override
  String get actorRiskIpDescription =>
      'This character IP has an abnormal trust coefficient; mining weight will be affected.';

  @override
  String get actorIpVault => 'Character IP Vault';

  @override
  String get actorIpVaultDescription =>
      '30% of signing revenue is automatically allocated to the character\'s IP vault to support the long-term development of the IP ecosystem. Similarly, 30% of secondary-market royalty revenue is also allocated to the vault, creating a sustainable funding pool. In Version 1, the vault only provides data visualization and is not yet open for distribution.';

  @override
  String get actorIpVaultSignIncomePrefix => 'Signing revenue · Accumulated ';

  @override
  String get actorIpVaultSecondaryRoyaltyPrefix =>
      'Secondary Royalty · Accumulated ';

  @override
  String get actorFixedPriceDialogDesc =>
      'This character IP uses fixed pricing. Every sign is settled at the same price regardless of sales volume.';

  @override
  String get actorCurvePriceDialogDesc =>
      'Price rises automatically with signed count along the bonding curve. Early signers get better prices.';

  @override
  String get actorFixedPriceNote1 =>
      'After the launcher sets a fixed price, all signings settle at that price.';

  @override
  String get actorFixedPriceNote2 =>
      'Price does not increase as more characters are signed.';

  @override
  String get actorFixedPriceNote3 =>
      'Suitable for buyers who want predictable costs';

  @override
  String get actorIssueFixedPriceDesc =>
      'This character IP uses fixed pricing. All signings settle at the fixed price and do not change with sales volume.';

  @override
  String get actorSignSlippageNote =>
      '1% slippage protection is enabled. The transaction will be canceled if the price exceeds the limit.';

  @override
  String get actorSignSuccessTitle => 'Signed!';

  @override
  String actorSignSuccessMessage(String name) {
    return 'Character \"$name\" signed successfully';
  }

  @override
  String actorSignSuccessNftId(String nftId) {
    return 'NFT ID: $nftId';
  }

  @override
  String get actorSignChainConfigMissing =>
      'On-chain configuration is incomplete. Please try again later.';

  @override
  String get actorSignPriceSoldOut => 'Signing price · Sold out';

  @override
  String actorSignPriceRemaining(int count) {
    return 'Signing price · $count remaining';
  }

  @override
  String actorSignedCount(int count) {
    return 'Signed $count';
  }

  @override
  String get actorStatusLabelOffline => 'Offline';

  @override
  String get actorStatusLabelOnline => 'Online';

  @override
  String get actorStatusLabelPending => 'Pending';

  @override
  String get actorStatusLabelRejected => 'Rejected';

  @override
  String get actorTotalSupply => 'Total supply';

  @override
  String get commentsAnonymous => 'Anonymous';

  @override
  String get commentsEmpty => 'No comments yet';

  @override
  String get commentsHint => 'Post a great comment...';

  @override
  String get commentsInvalidContent => 'Please enter valid content';

  @override
  String get commentsReply => 'Reply';

  @override
  String commentsViewReplies(int count) {
    return 'View $count replies';
  }

  @override
  String get commentsCollapseReplies => 'Collapse';

  @override
  String get commentsViewMoreReplies => 'Show more';

  @override
  String commentsReplyHint(String nickname) {
    return 'Reply to $nickname';
  }

  @override
  String get commentsDeleteCommentTitle => 'Delete this comment?';

  @override
  String get commentsDeleteReplyTitle => 'Delete this reply?';

  @override
  String get commentTagAuthor => 'Author';

  @override
  String get commentTagMe => 'Me';

  @override
  String get commentTagFriend => 'Friend';

  @override
  String get commentTagFan => 'Fan';

  @override
  String get commentTagFirst => 'First';

  @override
  String get commentTagAuthorLiked => 'Author liked';

  @override
  String commentsReplyTo(String nickname) {
    return 'Reply to @$nickname: ';
  }

  @override
  String get commentsReplyCommentNotExists => 'Comment does not exist';

  @override
  String get commentsBlockedByMe =>
      'This user is on your blocklist, you cannot comment';

  @override
  String get commentsBlockedByTarget =>
      'You cannot comment on this user due to their settings';

  @override
  String get commentsTabComments => 'Comments';

  @override
  String get commentsTabAllComments => 'All comments';

  @override
  String get commentsTabDramas => 'Dramas';

  @override
  String get commentsTabActors => 'Characters';

  @override
  String get timeJustNow => 'just now';

  @override
  String get timeYesterday => 'yesterday';

  @override
  String get timeDayBeforeYesterday => 'the day before yesterday';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String commentsTitle(int count) {
    return 'Comments ($count)';
  }

  @override
  String get createActorTitle => 'Create Character';

  @override
  String get createActorHeroTitle => 'Mint Character NFT';

  @override
  String get createActorHeroSubtitle =>
      'Create exclusive AI characters, bind profit sharing to participate in dramas';

  @override
  String get createActorNameLabel => 'Character Name';

  @override
  String get createActorNameHint => 'Enter character name';

  @override
  String get createActorBioLabel => 'Character Bio';

  @override
  String get createActorBioHint => 'Describe character background';

  @override
  String get createActorGenderLabel => 'Gender';

  @override
  String get createActorGenderMale => 'Male';

  @override
  String get createActorGenderFemale => 'Female';

  @override
  String get createActorMintParams => 'NFT Mint Parameters';

  @override
  String get createActorTokenStandard => 'Token Standard';

  @override
  String get createActorChain => 'Chain';

  @override
  String get createActorMinHolding => 'Min Holding';

  @override
  String get createActorMintNft => 'Mint NFT';

  @override
  String get createActorIpTitle => 'Issue Character IP';

  @override
  String get createActorIpSubtitle =>
      'After issuing a character IP, you can sign characters under it and deploy them to earn rewards.';

  @override
  String get createActorSelectMaterial => 'Select character material';

  @override
  String get createActorDreamOsBadge => 'Go to DreamOS';

  @override
  String get createActorSelectMaterialDesc =>
      'Open DreamOS project → Create character → Enter Story.fun to issue IP';

  @override
  String get createActorSelectButton => 'Select character';

  @override
  String get createActorNameLabelNew => 'Character name';

  @override
  String get createActorNamePlaceholder => 'Enter character name';

  @override
  String get createActorBioLabelNew => 'Bio';

  @override
  String get createActorBioPlaceholder =>
      'Please enter the character IP introduction.';

  @override
  String get createActorParamsTitle => 'Character IP issuance parameters';

  @override
  String get createActorParamsSubtitle =>
      'Set character IP issuance parameters. They cannot be changed after launch.';

  @override
  String get createActorTotalSupplyLabel => 'Total supply';

  @override
  String get createActorTotalSupplyDesc => 'Total supply range is 100 - 5,000.';

  @override
  String get createActorTotalSupplyPlaceholder => '100 - 5,000';

  @override
  String get createActorPricingFixed => 'Fixed price';

  @override
  String get createActorPricingCurve => 'Curve price';

  @override
  String createActorFixedPriceLabel(String currency) {
    return 'Fixed Price ($currency)';
  }

  @override
  String createActorInitialPriceLabel(String currency) {
    return 'Initial Price ($currency)';
  }

  @override
  String get createActorFixedPricePlaceholder => '10 - 1,000';

  @override
  String get createActorFixedPriceDesc =>
      'Each character is purchased at a fixed price that does not change with sales volume.';

  @override
  String get createActorInitialPricePlaceholder => '10 - 1,000';

  @override
  String get createActorInitialPriceDesc =>
      'Initial price is the bonding-curve start price. Each signed character raises the price by P = P₀ × 5^(signed/total). Early signers get better deals.';

  @override
  String get createActorFormIncomplete =>
      'Please complete the character assets, name, bio, and launch parameters first.';

  @override
  String get createActorValidationNameRequired => 'Please enter character name';

  @override
  String get createActorValidationNameTooLong =>
      'Character name must be 20 characters or fewer';

  @override
  String get createActorValidationBioRequired => 'Please enter bio';

  @override
  String get createActorValidationBioTooLong =>
      'Bio must be 500 characters or fewer';

  @override
  String get createActorValidationTotalSupplyRequired =>
      'Please enter a valid total NFT supply';

  @override
  String get createActorValidationTotalSupplyPositiveInteger =>
      'Total NFT supply must be a positive integer';

  @override
  String get createActorValidationTotalSupplyRange =>
      'Total character supply must be between 100 and 5,000';

  @override
  String get createActorValidationPriceRequired =>
      'Please enter a valid Mint price';

  @override
  String get createActorValidationPriceInvalid =>
      'Mint price must be at least 10 and not exceed 1,000';

  @override
  String get createActorValidationPriceMaxDecimals =>
      'Mint price can have at most 2 decimal places';

  @override
  String get createActorSelectMaterialRequired =>
      'Please select character material';

  @override
  String get createActorCancelButton => 'Cancel';

  @override
  String get createActorConfirmButton => 'Confirm launch';

  @override
  String get createActorIssueFee => 'Fee';

  @override
  String createActorSuccessTitle(String name) {
    return '$name · Launch successful!';
  }

  @override
  String createActorSuccessDesc(String id) {
    return 'Character IP $id';
  }

  @override
  String get createActorSuccessTip =>
      'Issuers also need to sign to obtain this character~';

  @override
  String get createActorCloseButton => 'Maybe later';

  @override
  String get createActorViewButton => 'Go sign';

  @override
  String get createActorEmptyTitle =>
      'You haven\'t created any NFT launch yet that meets the criteria and is automatically generated by the system in DreamOS.';

  @override
  String get createActorGotoDreamOs => 'Go to DreamOS';

  @override
  String get createActorSearchPlaceholder => 'Search character materials';

  @override
  String get createActorInvalidOrderId =>
      'The Character IP order number is invalid. Please refresh and try again';

  @override
  String get createDramaTitle => 'Create Drama';

  @override
  String get createDramaTitleLabel => 'Drama Title';

  @override
  String get createDramaTitleHint => 'Enter drama name';

  @override
  String get createDramaSynopsisLabel => 'Synopsis';

  @override
  String get createDramaSynopsisHint =>
      'What kind of story is it... (up to 1000 characters)';

  @override
  String get createDramaAiSettings => 'AI Generation Settings';

  @override
  String get createDramaVisualStyle => 'Visual Style';

  @override
  String get createDramaVisualStyleRealistic => 'Realistic';

  @override
  String get createDramaEpisodeDuration => 'Episode Duration';

  @override
  String get createDramaEpisodeDurationValue => '3-5 min';

  @override
  String get createDramaTotalEpisodes => 'Total Episodes';

  @override
  String get createDramaTotalEpisodesValue => '8 episodes';

  @override
  String get createDramaGenreLabel => 'Genre';

  @override
  String get createDramaGenreDrama => 'Drama';

  @override
  String get createDramaGenreComedy => 'Comedy';

  @override
  String get createDramaGenreAction => 'Action';

  @override
  String get createDramaGenreRomance => 'Romance';

  @override
  String get createDramaGenreSciFi => 'Sci-Fi';

  @override
  String get createDramaGenreMystery => 'Mystery';

  @override
  String get createDramaGenreHorror => 'Horror';

  @override
  String get createDramaGenreAnimation => 'Animation';

  @override
  String get createDramaHeroTitle => 'AI Drama Creation';

  @override
  String get createDramaHeroSubtitle =>
      'One-click generation of your next hit drama';

  @override
  String get createDramaStartGeneration => 'Start Generation';

  @override
  String get creatorDramaManagementTab => 'Drama Management';

  @override
  String get creatorDramaNftTab => 'Drama NFT';

  @override
  String get creatorHeaderSubtitle => 'Posting, reviewing, and minting dramas.';

  @override
  String get creatorV2Subtitle => 'Post and manage dramas and videos.';

  @override
  String creatorV2DramaTabCount(int count) {
    return 'Dramas ($count)';
  }

  @override
  String creatorV2VideoTabCount(int count) {
    return 'Videos ($count)';
  }

  @override
  String get creatorV2NoVideos => 'No videos yet';

  @override
  String get creatorLoginPrompt => 'Log in to view your creations';

  @override
  String get creatorNoCreatedActors => 'No created characters';

  @override
  String get creatorNoPublishedDramas => 'No posted dramas';

  @override
  String get creatorOwnedNftCount => 'Owned NFTs';

  @override
  String get creatorCreateDrama => 'Create Drama';

  @override
  String get creatorPublishNewDrama => 'Post New Drama';

  @override
  String get creatorPublishedDramas => 'Posted Dramas';

  @override
  String get creatorReviewFilterAll => 'All';

  @override
  String get creatorReviewFilterApproved => 'Approved';

  @override
  String get creatorReviewFilterPending => 'Pending';

  @override
  String get creatorReviewFilterRejected => 'Rejected';

  @override
  String get creatorReviewFilterOffline => 'Delisted';

  @override
  String get creatorDramaOtherReason => 'Other reason';

  @override
  String get creatorDramaStatusOnline => 'Approved';

  @override
  String get creatorDramaStatusPendingReview => 'Pending Review';

  @override
  String get creatorDramaStatusReviewRejected => 'Not Passed';

  @override
  String get creatorDramaStatusPendingOnline => 'Pending Online';

  @override
  String creatorDramaAuditReason(Object reason) {
    return 'Rejection reason: $reason';
  }

  @override
  String get creatorDramaNftMinted => 'Minted';

  @override
  String creatorDramaEpisodeCount(int count) {
    return '$count episodes';
  }

  @override
  String get creatorDramaEdit => 'Edit';

  @override
  String get creatorDramaDelete => 'Delete';

  @override
  String get creatorActorDelete => 'Delete Character';

  @override
  String get creatorDeleteDramaConfirm =>
      'Are you sure you want to delete this drama?';

  @override
  String get creatorDeleteVideoConfirmTitle => 'Confirm Video Deletion';

  @override
  String creatorDeleteVideoConfirmMessage(String name) {
    return 'Are you sure you want to delete “$name”?\nThis action cannot be undone.';
  }

  @override
  String get creatorDeleteActorConfirm =>
      'Are you sure you want to delete this character?';

  @override
  String get creatorDeleting => 'Deleting...';

  @override
  String get creatorNoDramas => 'No dramas';

  @override
  String get creatorNoNfts => 'No drama NFTs yet';

  @override
  String get creatorsComingSoon => 'Coming Soon';

  @override
  String get creatorsHeroSubtitle => 'Discover outstanding creators';

  @override
  String get creatorsHeroTitle => 'Creators';

  @override
  String get dramaBatchUnlockAll => 'Unlock All';

  @override
  String dramaBatchUnlockDiscount(String discount) {
    return 'Batch unlock discount $discount%';
  }

  @override
  String get dramaBatchUnlockSubtitle =>
      'Unlock all episodes at once for a better deal';

  @override
  String get dramaBatchUnlockSuccess =>
      'Unlock successful, please start watching';

  @override
  String get dramaDetailAllFree => 'All Free';

  @override
  String dramaDetailBoundActors(int count) {
    return '$count characters bound';
  }

  @override
  String dramaDetailEpisodeCount(int count) {
    return '$count episodes';
  }

  @override
  String get dramaDetailEpisodePrice => 'Episode Price';

  @override
  String get dramaDetailFree => 'Free';

  @override
  String dramaDetailFreeEpisodes(int count) {
    return 'First $count free';
  }

  @override
  String get dramaDetailMainCharacters => 'Main Roles';

  @override
  String get dramaDetailNftMinted => 'NFT Minted';

  @override
  String get dramaDetailNoEpisodes => 'No episodes';

  @override
  String get dramaDetailPaid => 'Paid';

  @override
  String get dramaDetailPendingActor => 'Pending character';

  @override
  String get dramaDetailRoleCount => 'Roles';

  @override
  String get dramaUnlockFailedRetry => 'Unlock failed, please retry';

  @override
  String get dramaUnlockFetchTimeout =>
      'Playback address fetch timeout, please retry';

  @override
  String get dramaUnlockLoginRequired => 'Please log in to unlock episodes';

  @override
  String dramaUnlockMessage(
    int epNo,
    String price,
    String discount,
    String currency,
  ) {
    return 'Episode $epNo requires payment to unlock\nPrice: $price $currency\nBatch unlock discount: $discount';
  }

  @override
  String get dramaUnlockSuccessFetching =>
      'Unlock successful, fetching playback address...';

  @override
  String get dramaUnlockTitle => 'Unlock Episode';

  @override
  String get editActorTitle => 'Edit Character';

  @override
  String get editDramaTitle => 'Edit Drama';

  @override
  String get editVideoTitle => 'Edit Video';

  @override
  String get editSaveChanges => 'Save Changes';

  @override
  String get editProfileTitle => 'Edit Profile';

  @override
  String get editNicknameLabel => 'Nickname';

  @override
  String get editRoleNameLabel => 'Username';

  @override
  String get editNicknameHint => 'Enter your nickname';

  @override
  String get editNicknameRequired => 'Please enter a nickname';

  @override
  String get editProfileBioLabel => 'Bio';

  @override
  String get editProfileBioHint => 'Please enter bio';

  @override
  String get editProfileEmailLabel => 'Email address';

  @override
  String get editAvatarCropTitle => 'Crop Avatar';

  @override
  String get profileUpdateSuccess => 'Profile updated';

  @override
  String incomeClaimAmount(String amount, String currency) {
    return 'Claim $amount $currency';
  }

  @override
  String get incomeClaimFailed => 'Claim failed';

  @override
  String incomeClaimMessage(String amount, String currency) {
    return 'Claimable amount: $amount $currency\nEarnings will be transferred to your wallet balance';
  }

  @override
  String get incomeClaimSuccess => 'Claim successful';

  @override
  String get incomeClaimTitle => 'Claim Earnings';

  @override
  String get incomeConfirmClaim => 'Confirm Claim';

  @override
  String get incomeHistoryTab => 'History';

  @override
  String get incomeInviteHeroSubtitle =>
      'Invite friends to consume and interact, the more active the invitee the higher the reward';

  @override
  String get incomeInviteHeroTitle => 'Invite Friends for Rebates';

  @override
  String get incomeInviteNoRecords => 'No rebate records';

  @override
  String get incomeInvitePaidUnlockDesc => 'Friends pay to unlock episodes';

  @override
  String get incomeInvitePaidUnlockTitle => 'Paid Unlock';

  @override
  String get incomeInviteRecords => 'Rebate Records';

  @override
  String get incomeInviteRegisterDesc =>
      'Friends register via your referral link';

  @override
  String get incomeInviteRegisterTitle => 'Invite Registration';

  @override
  String get incomeInviteRules => 'Rebate Rules';

  @override
  String get incomeInviteShareLink => 'Share Invite Link';

  @override
  String get incomeInviteStakeDesc => 'Friends stake NFTs or STORY';

  @override
  String get incomeInviteStakeTitle => 'Staking Investment';

  @override
  String get incomeInviteTab => 'Invite Rebates';

  @override
  String get incomeInviteWatchDesc => 'Friends watch dramas to earn points';

  @override
  String get incomeInviteWatchTitle => 'Watch Dramas';

  @override
  String get incomeNoHistory => 'No history records';

  @override
  String get incomeNoRecords => 'No earnings records';

  @override
  String get incomeNothingToClaim => 'Nothing to claim';

  @override
  String get incomeOverviewTab => 'Overview';

  @override
  String get incomePendingClaim => 'Pending Claim';

  @override
  String get incomeRecords => 'Earnings Records';

  @override
  String get incomeThisMonth => 'This Month';

  @override
  String get incomeToday => 'Today';

  @override
  String get incomeTotalEarnings => 'Total Earnings';

  @override
  String get incomeCumulativeStory => 'Cumulative STORY';

  @override
  String incomeCumulativeUsdc(String currency) {
    return 'Cumulative $currency';
  }

  @override
  String get incomeClaimableStory => 'Claimable STORY';

  @override
  String incomeClaimableUsdc(String currency) {
    return 'Claimable $currency';
  }

  @override
  String get incomeSettlingStory => 'My Salary';

  @override
  String get incomeSettlingHint => 'Settling; claimable after arrival';

  @override
  String get incomeHelpTotalStoryDesc =>
      'The total amount of STORY accumulated across all historical cycles (including both claimed and unclaimed amounts).';

  @override
  String incomeHelpTotalUsdcDesc(String currency) {
    return 'Cumulative $currency revenue from signing fees and secondary royalties for all historical characters.';
  }

  @override
  String get incomeHelpSettlingStoryDesc =>
      'Automatically converted to STORY after system settlement';

  @override
  String get incomeHelpClaimableStoryDesc =>
      'Settled STORY can be withdrawn to your personal wallet.';

  @override
  String incomeHelpClaimableUsdcDesc(String currency) {
    return 'Settled $currency can be withdrawn to your personal wallet.';
  }

  @override
  String get incomeFilterAll => 'All';

  @override
  String get incomeFilterMining => 'Mining';

  @override
  String get incomeFilterInvite => 'Invite';

  @override
  String get incomeMiningReward => 'Mining Reward';

  @override
  String get incomeInviteReward => 'Invite Reward';

  @override
  String get incomeUsdcActorSignShare => 'Character signing share';

  @override
  String get incomeClaimNoWallet => 'Please bind your wallet first';

  @override
  String incomeClaimCurrencyTitle(String currency) {
    return 'Claim $currency';
  }

  @override
  String incomeClaimWithdrawMessage(
    String amount,
    String currency,
    String address,
  ) {
    return 'Confirm withdrawing $amount $currency to your Solana wallet?\nRecipient: $address';
  }

  @override
  String get incomeClaimWithdrawConfirm => 'Confirm Withdraw';

  @override
  String get incomeClaimWithdrawSubmitted => 'Withdrawal successful';

  @override
  String get incomeClaimWithdrawFailed => 'Withdrawal failed, please retry';

  @override
  String get incomeClaimAction => 'Claim';

  @override
  String get nftCreateActorIp => 'Create Character IP';

  @override
  String get nftHeaderSubtitle =>
      'Explore and collect exclusive Character NFTs';

  @override
  String get nftHeaderTitle => 'Character NFT Square';

  @override
  String get nftSearchHint => 'Search dramas, works, characters, users...';

  @override
  String get actorHowToPlayTitle => 'How to Leverage Character IPs';

  @override
  String get actorHowToPlayHelpTooltip => 'Game Instructions';

  @override
  String get actorHowToPlaySignTab => 'Signed IPs';

  @override
  String get actorHowToPlaySignSubtitle => 'Earn salary passively';

  @override
  String get actorHowToPlayIssueTab => 'Launch IP';

  @override
  String get actorHowToPlayIssueSubtitle => 'Monetizing Your Creative Work';

  @override
  String get actorHowToPlaySignPositioning =>
      'Positioning: Zero creative barriers, easy and steady returns';

  @override
  String get actorHowToPlaySignAudience =>
      'Ordinary users who don’t want to create content but want to earn STORY rewards with minimal effort';

  @override
  String get actorHowToPlaySignGuide =>
      'Sign high-heat, high-salary character IPs, then schedule performances on the Agent page to earn.';

  @override
  String get actorHowToPlaySignRightsTitle => 'Dual Benefits';

  @override
  String get actorHowToPlaySignRightPerform =>
      'Schedule performances to earn STORY tokens on an ongoing basis';

  @override
  String get actorHowToPlaySignRightTrade =>
      'Character IPs are tradable, allowing you to earn premium returns';

  @override
  String get actorHowToPlayIssuePositioning =>
      'Positioning: create and launch, multiple revenue streams, long-term IP appreciation';

  @override
  String get actorHowToPlayIssueAudience =>
      'Creators with creative talent who want to monetize through character IPs and short videos';

  @override
  String get actorHowToPlayIssueGuide =>
      'Launch character IPs, pair them with AI short dramas, boost their heat, and raise IP salary and revenue';

  @override
  String get actorHowToPlayIssueRightsTitle => 'Triple Benefits';

  @override
  String get actorHowToPlayIssueRightSignLabel => 'Signing share:';

  @override
  String get actorHowToPlayIssueRightSign =>
      'When your own IP is signed, you receive a 40% share';

  @override
  String get actorHowToPlayIssueRightPerformLabel =>
      'Proceeds from the performance:';

  @override
  String get actorHowToPlayIssueRightPerform =>
      'Sign your own IP and earn STORY through performances';

  @override
  String get actorHowToPlayIssueRightValueLabel => 'Added Value:';

  @override
  String get actorHowToPlayIssueRightValue =>
      'IPs are tradable; the higher the heat, the higher the premium.';

  @override
  String get actorHowToPlayAudienceTitle => 'Target Audience';

  @override
  String get actorHowToPlayGuideTitle => 'Game Guide';

  @override
  String get actorHowToPlayCreateHint =>
      'Use DreamOS to generate character IPs and AI short dramas with a single click, efficiently producing high-quality content';

  @override
  String get actorHowToPlayCreateCta => 'Let\'s Get Creative';

  @override
  String get nftSignInDevelopment => 'Function not yet available';

  @override
  String get nftSortCompleted => 'Completed Views';

  @override
  String get nftSortHeat => 'Heat';

  @override
  String get nftSortIpPower => 'IP Salary';

  @override
  String get nftSortLowestPrice => 'Price';

  @override
  String get nftSortLv1Pay => 'Salary';

  @override
  String get nftSortMaxPay => 'Max salary';

  @override
  String get nftTradeUnavailable => 'Trading not yet available';

  @override
  String playerEpisodeBarCompleted(int count) {
    return 'All $count episodes · Completed';
  }

  @override
  String playerEpisodeSynopsis(int episodeNo, String synopsis) {
    return 'Ep $episodeNo | $synopsis';
  }

  @override
  String get playerPlayFailedRetry => 'Playback failed, please retry later';

  @override
  String get publicProfileDramas => 'Dramas';

  @override
  String get publicProfileEmpty => 'No public content';

  @override
  String get publicProfileBlock => 'Block';

  @override
  String get publicProfileUnblock => 'Unblock';

  @override
  String get publicProfileBlockedByMeContent =>
      'You blocked this user, so you can\'t view their content';

  @override
  String get publicProfileBlockedContent =>
      'This user blocked you, so you can\'t view their content';

  @override
  String get publicProfileBlockConfirmTitle => 'Block this user?';

  @override
  String get publicProfileBlockConfirmMessage =>
      'After blocking, you won\'t be able to view this user\'s works.';

  @override
  String get publicProfileBlockSuccess => 'User blocked';

  @override
  String get publicProfileUnblockSuccess => 'User unblocked';

  @override
  String get publicProfileFollowers => 'Followers';

  @override
  String get publicProfileFollowing => 'Following';

  @override
  String get followTabMutual => 'Mutual';

  @override
  String get profileLikesReceived => 'Likes';

  @override
  String profileLikesReceivedDialogMessage(int count) {
    return 'You\'ve received $count likes — thanks for sharing your work!';
  }

  @override
  String get profileTabLikes => 'Liked';

  @override
  String get profileTabFavorites => 'Favorites';

  @override
  String get profileWalletTitle => 'Wallet';

  @override
  String get profileAddressCopied => 'Address copied';

  @override
  String get followActionFollow => 'Follow';

  @override
  String get followActionFollowBack => 'Follow back';

  @override
  String get followActionFollowing => 'Following';

  @override
  String get followBlockedByMe =>
      'This user is on your blocklist, you cannot follow';

  @override
  String get followBlockedByTarget =>
      'You cannot follow this user due to their settings';

  @override
  String get likeBlockedByMe =>
      'This user is on your blocklist, you cannot like';

  @override
  String get likeBlockedByTarget =>
      'You cannot like this work due to the creator\'s settings';

  @override
  String get favoriteBlockedByMe =>
      'This user is on your blocklist, you cannot favorite';

  @override
  String get favoriteBlockedByTarget =>
      'You cannot favorite this work due to the creator\'s settings';

  @override
  String get ratingBlockedByMe =>
      'This user is on your blocklist, you cannot rate';

  @override
  String get ratingBlockedByTarget =>
      'You cannot rate this drama due to the creator\'s settings';

  @override
  String get followActionMutual => 'Mutual';

  @override
  String get followUnfollowTitle => 'Unfollow';

  @override
  String followUnfollowMessage(String handle) {
    return 'Stop following $handle?';
  }

  @override
  String get followUnfollowNo => 'No';

  @override
  String get followUnfollowYes => 'Yes';

  @override
  String get followListEmpty => 'No users yet';

  @override
  String get followFollowingEmpty =>
      'Not following anyone yet. Discover interesting creators~';

  @override
  String get followFollowingEmptyCta => 'Explore';

  @override
  String get followFollowingEmptyGuest => 'Not following anyone';

  @override
  String get followFollowersEmpty =>
      'No followers yet. Post a work to get more exposure~';

  @override
  String get followFollowersEmptyCta => 'Post';

  @override
  String get followFollowersEmptyGuest => 'No followers yet';

  @override
  String get followMutualsEmpty => 'No mutual follows yet';

  @override
  String get followMutualsSelfOnly => 'Mutual follows are only visible to you';

  @override
  String get followRelationsSelfOnly => 'Follow lists are only visible to you';

  @override
  String get followMoreTitle => 'More';

  @override
  String get followRemoveFollower => 'Remove follower';

  @override
  String get followRemoveFollowerSuccess => 'Removed. They won’t be notified';

  @override
  String get followUserHandleFallback => '@user';

  @override
  String get publicProfileTitle => 'User Profile';

  @override
  String publicProfileUserFallback(String id) {
    return 'User #$id';
  }

  @override
  String get watchHistoryEmpty => 'No watch history';

  @override
  String get watchHistoryClearTitle => 'Clear watch history';

  @override
  String get watchHistoryClearMessage =>
      'Are you sure you want to clear all watch history? This action cannot be undone.';

  @override
  String get watchHistoryClearConfirm => 'Confirm';

  @override
  String get gamePageTitle => 'Agent';

  @override
  String get gamePageSubtitle =>
      'Manage your characters, deploy them for earnings.';

  @override
  String get gameRiskAccount => 'Risk Account';

  @override
  String get gameRiskAccountDescription =>
      'This account has an abnormal trust coefficient; mining weight will be affected.';

  @override
  String get gameWeeklyStats => 'Weekly Stats';

  @override
  String get gameDeployedActors => 'Deployed Characters';

  @override
  String get gameMyActors => 'My Characters';

  @override
  String get gameComingSoon => 'Coming Soon';

  @override
  String get gameSignActor => 'Sign characters';

  @override
  String get gameGoProduce => 'Go Produce';

  @override
  String get gameWorkingActors => 'Characters on Deployment';

  @override
  String get gameWeekPool => 'Weekly Reward Pool (STORY)';

  @override
  String get gameWeekNominalOutput => 'Weekly Nominal Output (STORY)';

  @override
  String get gameWeekEstimatedOutput => 'Weekly Estimated Output (STORY)';

  @override
  String get gameMiningRules => 'Mining Rules';

  @override
  String get agentV2RulesTitle => 'Operations';

  @override
  String get agentV2RulesSummary =>
      'Sign characters and schedule performances to earn STORY every hour.\nUpgrade characters to multiply their hourly salary.\nRefill stamina promptly so production never stops.\nSettlement begins every Monday at 00:00 (UTC); claim it on the Earnings page.';

  @override
  String get agentV2RulesHowToPlay => 'How It Works';

  @override
  String get agentV2RulesStartTitle => 'How do characters start earning?';

  @override
  String get agentV2RulesStartDescription =>
      'Schedule an available character to perform. Each hour consumes 1 stamina and produces STORY based on their salary.\nProduced STORY is settled at the end of each cycle and can then be claimed on the Earnings page.';

  @override
  String get agentV2RulesStaminaTitle => 'How is stamina managed?';

  @override
  String agentV2RulesStaminaDescription(int staminaLimit) {
    return 'Performing: consumes 1 stamina per hour and produces the normal salary\nDepleted: production pauses at 0 and requires attention\nResting: restores 1 stamina per hour but pauses salary\nRefill (paid): instantly restores $staminaLimit and resumes production';
  }

  @override
  String get agentV2RulesBatchTitle => 'Can I perform actions in bulk?';

  @override
  String get agentV2RulesBatchDescription =>
      'Yes. Use Perform All, Refill All, or Rest All at the bottom of the page to apply an action to every character in a performance slot.';

  @override
  String get agentV2RulesEarnings => 'Earnings';

  @override
  String get agentV2RulesSalaryTitle => 'How is salary calculated?';

  @override
  String get agentV2RulesSalaryDescription =>
      'The higher the tier, the pricier the character, and the more popular the drama, the higher the hourly salary.';

  @override
  String get agentV2RulesSalaryFormula =>
      'Hourly salary per card = Character Salary × 1 STORY';

  @override
  String get agentV2RulesRolePowerFormula =>
      'Character salary = Lv.1 character salary × Salary coefficient';

  @override
  String get agentV2RulesIpSalaryFormula =>
      'Lv.1 character salary = Price coefficient × Heat coefficient';

  @override
  String get agentV2RulesCoefficientTitle => 'Coefficient Details';

  @override
  String agentV2RulesSalaryExample(String currency) {
    return 'Lin Mengyao · Lv3 Lead · P0=120$currency (price coefficient ≈1.5046) · heat 3.5\n→ Hourly salary = 5.0 × 1.5046 × 3.5 × 1 = 26.3 STORY\nAs an Lv1 Extra, she would earn only ≈5.3 STORY per hour — upgrading to Lv3 multiplies it fivefold.';
  }

  @override
  String get agentV2RulesSettlementTitle => 'When is settlement?';

  @override
  String get agentV2RulesSettlementDescription =>
      'Each performance cycle lasts 7 days and closes every Monday at 00:00 (UTC). After system settlement, this period\'s salary is automatically converted to STORY and can be claimed on the Earnings page.';

  @override
  String get agentV2RulesSettlementExample =>
      'Assume this week\'s reward pool is 100,000 STORY:\nCase A: Only you produce 134 across the platform → you receive 134; the remainder is not distributed\nCase B: Network output is 250,000 → 100,000 ÷ 250,000 = 40%, so your nominal output is scaled to 40%\nCase C: Someone would receive 6,000 after scaling, but the cap is 5,000 → only 5,000 is distributed';

  @override
  String get agentV2RulesStronger => 'Getting Stronger';

  @override
  String get agentV2RulesUpgradeTitle => 'How do I upgrade a character?';

  @override
  String get agentV2RulesUpgradeDescription =>
      'Requirements: consume 2 duplicates of the same IP and level + meet the IP drama\'s cumulative completed-view target\nLv1→Lv2: ≥10,000 completed views · Salary: 1→3\nLv2→Lv3: ≥50,000 completed views · Salary: 3→9\nLv3→Lv4: ≥200,000 completed views · Salary: 9→27\nLv4→Lv5: ≥1M completed views · Salary: 27→81';

  @override
  String get agentV2RulesPerforming => 'Performing';

  @override
  String get agentV2RulesNormalSalary => 'Normal salary';

  @override
  String get agentV2RulesSalaryCoefficient =>
      'Salary coefficient: Lv1=1 · Lv2=3 · Lv3=9 · Lv4=27 · Lv5=81';

  @override
  String agentV2RulesPriceCoefficientDescription(
    String currency1,
    String currency2,
  ) {
    return 'Price coefficient (launch price P0):\n  • P0 ≤ 100$currency1 → Coefficient = P0 ÷ 100 (linear increase)\n  • P0 > 100$currency2 → Coefficient = 1.6 × (P0/100)¹.³ / [(P0/100)¹.³ + 0.6] (asymptotic upper bound 1.6)';
  }

  @override
  String get agentV2RulesTrust2 => 'Trust2';

  @override
  String get agentV2RulesTrust2Factor => 'Platform Trust2';

  @override
  String get agentV2RulesSettlementCase1 =>
      'Actual payout = nominal output; unused capacity expires';

  @override
  String get agentV2RulesSettlementCase2 =>
      'Proportional scaling: your actual payout = your nominal output × (reward pool ÷ network output)';

  @override
  String get gameSettlementRecords => 'Weekly Settlement';

  @override
  String get gameFilterComputingPower => 'Salary';

  @override
  String get gameFilterLevel => 'Level';

  @override
  String get gameFilterHeat => 'Heat';

  @override
  String get gameFilterStamina => 'Stamina';

  @override
  String get gameHeatCoef => 'Heat coefficient';

  @override
  String get gameMiningCoef => 'Mining Coef.';

  @override
  String get gameActorPower => 'Character Salary';

  @override
  String get gameActorPowerDetailTitle => 'Character Salary Details';

  @override
  String get gameActorPowerFormula =>
      'Character Salary = IP Salary × Mining Coefficient × CP Coefficient × Trust2';

  @override
  String get gameActorPowerIpFormula =>
      'IP Salary = Price coefficient × Heat coefficient × Trust1';

  @override
  String get gameActorPowerHourlyOutput => 'Hourly output';

  @override
  String get gameCpCoefficient => 'CP Coefficient';

  @override
  String get gameTrust2 => 'Trust2';

  @override
  String get gameWeeklyNominalOutputLabel => 'Weekly Nominal Output';

  @override
  String get gameRoundNominalOutputLabel => 'Round Nominal Output';

  @override
  String get gameSupplement => 'Supplement';

  @override
  String get gameRest => 'Rest';

  @override
  String get gameDeploy => 'Deploy';

  @override
  String get gameDeployActor => 'Deploy character';

  @override
  String get gameStatusIdle => 'Idle';

  @override
  String get gameStatusMining => 'Mining';

  @override
  String gameActorIpLabel(String id) {
    return 'Character IP $id';
  }

  @override
  String gameStaminaProgress(String current, String max) {
    return '$current/$max';
  }

  @override
  String get gameStaminaMechanismTitle => 'Stamina mechanics';

  @override
  String gameStaminaMechanismDesc(String currency) {
    return 'Deployed characters consume 1 stamina point per hour. They stop generating earnings when their stamina is depleted, and recover stamina automatically while resting. You can use $currency to refill stamina instantly.';
  }

  @override
  String get gameStaminaMechanismAction => 'Got it';

  @override
  String gameLevelBadge(String level) {
    return 'Lv$level';
  }

  @override
  String get gameEmptyDeployed => 'No characters currently deployed';

  @override
  String get gameEmptyMyActors => 'No characters yet. Sign one to get started.';

  @override
  String get gameDeployConfirmTitle => 'Deploy this character?';

  @override
  String get gameRestConfirmTitle => 'Rest this character?';

  @override
  String get gameRestConfirmDesc =>
      'Mining output pauses while the character rests; stamina recovers over time.';

  @override
  String get gameRestConfirmAction => 'Confirm Rest';

  @override
  String get gameRestSuccessToast => 'Rest started';

  @override
  String get gameDeploySlotFull => 'Deploy slots are full (max 5)';

  @override
  String get gameRefillTitle => 'Refill stamina';

  @override
  String get gameRefillCurrentStamina => 'Current stamina';

  @override
  String get gameRefillCost => 'Refill cost';

  @override
  String get gameRefillConfirm => 'Refill all stamina';

  @override
  String get gameRefillSuccess => 'Stamina refilled';

  @override
  String get gameRefillFailed => 'Failed to refill stamina, please try again';

  @override
  String gameInsufficientUsdc(String currency) {
    return 'Insufficient $currency balance';
  }

  @override
  String get walletInsufficientStory => 'Insufficient STORY balance';

  @override
  String get gameSupplementComingSoon => 'Stamina refill coming soon';

  @override
  String get gameStatHelpWeekPoolTitle => 'Weekly Reward Pool';

  @override
  String get gameStatHelpWeekPoolSubtitle =>
      'The weekly hard distribution cap for STORY mining';

  @override
  String get gameStatHelpWeekTotalPool => 'Total weekly reward pool';

  @override
  String get gameStatHelpWeekTotalPoolValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeekStakePool => 'Staking reward pool this week (75%)';

  @override
  String get gameStatHelpWeekStakePoolValue => '1,586,538 STORY';

  @override
  String get gameStatHelpWeekInvitePool => 'Invite reward pool this week (25%)';

  @override
  String get gameStatHelpWeekInvitePoolValue => '528,846 STORY';

  @override
  String get gameStatHelpInitialHardCap => 'Initial weekly hard cap';

  @override
  String get gameStatHelpInitialHardCapValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeeklyDecay => 'Weekly decay factor';

  @override
  String get gameStatHelpWeeklyDecayValue => '× 0.99572';

  @override
  String get gameStatHelpWeeklyDistributionFormula =>
      'Weekly actual distribution = min(total network nominal output, weekly hard cap)';

  @override
  String get gameStatHelpUnusedQuotaNote =>
      'Unused quota is not launched, returned, or compensated';

  @override
  String get gameStatHelpNominalTitle => 'Weekly Nominal Output';

  @override
  String get gameStatHelpNominalSummary =>
      'Sum of weekly nominal output across all my characters';

  @override
  String get gameStatHelpNominalSummaryHint =>
      'See below for the per-card formula';

  @override
  String get gameStatHelpNominalFormula =>
      'Per-card nominal output = Per-card hourly weight × R_base × Effective mining duration';

  @override
  String get gameStatHelpHourlyWeight => 'Per-card hourly weight';

  @override
  String get gameStatHelpHourlyWeightValue => '= Character Salary';

  @override
  String get gameStatHelpActorPower => 'Character Salary';

  @override
  String get gameStatHelpActorPowerValue =>
      '= IP Salary × Mining Coefficient × CP Coefficient × Trust2';

  @override
  String get gameStatHelpCpCoef => 'CP coefficient';

  @override
  String get gameStatHelpRBase => 'R_base';

  @override
  String get gameStatHelpRBaseValue => '1 STORY / unit weight / hour';

  @override
  String get gameStatHelpEffectiveDuration => 'Effective mining duration';

  @override
  String get gameStatHelpEffectiveDurationValue =>
      'Accumulated duration while deployed with stamina > 0';

  @override
  String get gameStatHelpActualTitle => 'Estimated Output for This Week';

  @override
  String get gameStatHelpActualSubtitle =>
      'Estimated output is constrained by the weekly hard cap and per-address cap; actual rewards settle at week end';

  @override
  String get gameStatHelpIfNominalLte =>
      'If total network nominal output ≤ weekly hard cap:';

  @override
  String get gameStatHelpUserActualEqNominal =>
      'User actual = user nominal output';

  @override
  String get gameStatHelpIfNominalGt =>
      'If total network nominal output > weekly hard cap:';

  @override
  String get gameStatHelpUserActualFormula =>
      'User actual = user nominal output × weekly hard cap / total network nominal output';

  @override
  String get gameStatHelpAddressCap => 'Per-address weekly cap';

  @override
  String get gameStatHelpAddressCapValue =>
      'Each address can claim at most 5% of the weekly hard cap';

  @override
  String get theaterCategoryAll => 'All';

  @override
  String get theaterCategoryAncient => 'Ancient';

  @override
  String get theaterCategoryFinance => 'Finance';

  @override
  String get theaterCategorySuspense => 'Suspense';

  @override
  String get theaterCategorySciFi => 'Sci-Fi';

  @override
  String get theaterCategoryRealStory => 'Real Story';

  @override
  String get theaterCategoryUrban => 'Urban';

  @override
  String get theaterSortHottest => 'Hottest';

  @override
  String get theaterSortNewest => 'Newest';

  @override
  String get theaterSortTopRated => 'Top Rated';

  @override
  String get theaterSortCompletedView => 'Most Completed';

  @override
  String theaterPlayCount(String count) {
    return '$count plays';
  }

  @override
  String get createDramaBasicInfo => 'Basic Info';

  @override
  String get createDramaEpisodes => 'Episode Management';

  @override
  String get createDramaRoles => 'Bind IP';

  @override
  String get createDramaCover => 'Cover';

  @override
  String get createDramaCoverUpload => 'Upload';

  @override
  String get createDramaCoverPlaceholder => 'Supports JPG/PNG, up to 5MB';

  @override
  String get createDramaCoverCropTitle => 'Crop Cover';

  @override
  String get createDramaName => 'Drama Title';

  @override
  String get createDramaNameHint => 'Please enter drama title';

  @override
  String get createDramaSynopsis => 'Synopsis';

  @override
  String get createDramaTags => 'Tags';

  @override
  String get createDramaTagsHint =>
      'Type tag and press enter to add (e.g. Love, Comedy)';

  @override
  String get createDramaTagsLoading => 'Loading tags…';

  @override
  String get createDramaTagsEmpty => 'No tags available';

  @override
  String get createDramaTagsRetry => 'Retry';

  @override
  String get createDramaUploadDesc =>
      'Click to upload; episodes will be auto-sorted by video name after submission.';

  @override
  String get createDramaEpisodesDesc =>
      'Batch upload video files; the system auto-generates the episode list sorted by filename. Supports drag-to-reorder, deletion, and title editing.';

  @override
  String get createDramaVideoFileTypeHint =>
      'Supported formats: mp4, flv, wmv, asf, mkv, avi, rm, rmvb, mpg, mpeg, mov, webm. Max file size 2GB.';

  @override
  String get createDramaUploadVideo => 'Upload Video';

  @override
  String get createDramaVideoEmpty => 'No videos added yet';

  @override
  String get createDramaVideoPickFailed => 'Failed to pick video';

  @override
  String get createDramaVideoAnyTooLarge =>
      'One or more videos exceed 2GB, please adjust and retry';

  @override
  String get createDramaVideoStatusUploading => 'Uploading';

  @override
  String get createDramaVideoStatusPaused => 'Upload paused';

  @override
  String get createDramaVideoStatusDone => 'Upload complete';

  @override
  String get createDramaEpisodeDescriptionHint => 'Episode description';

  @override
  String get createDramaVideoStatusFailed => 'Upload failed';

  @override
  String get createDramaVideoTooLarge =>
      'Video size cannot exceed 2GB and cannot be uploaded.';

  @override
  String get createDramaVideoUploadComplete => 'All videos uploaded';

  @override
  String createDramaVideoUploadFailed(String name) {
    return '$name upload failed';
  }

  @override
  String createDramaVideoPickOverflow(int count, int overflow) {
    return 'You can add up to $count more episodes. $overflow extra were skipped.';
  }

  @override
  String createDramaAddedVideos(String count) {
    return 'Added videos ($count files)';
  }

  @override
  String createDramaAddedVideosCount(String count) {
    return '($count files)';
  }

  @override
  String get createDramaAddedVideosLabel => 'Added videos';

  @override
  String get createDramaRolesDesc =>
      'Create roles for the drama, set role name, avatar, and brief bio.';

  @override
  String get createDramaRolesRule1 =>
      'Each drama can bind up to 5 Character IPs. New IPs can be added within 7 days of going live; bindings cannot be removed or replaced after publishing.';

  @override
  String get createDramaRolesRule2 =>
      'Once bound, the Character IP is linked to the drama\'s completion and popularity data for upgrades and STORY rewards.';

  @override
  String get createDramaRolesExpireTime => 'Deadline';

  @override
  String get createDramaRolesRule3 =>
      'Binding an IP is optional; you can publish without one.';

  @override
  String get createDramaAddRole => 'Add Role';

  @override
  String get createDramaBindActor => 'Cast Character';

  @override
  String get createDramaRoleActing => 'Cast Character';

  @override
  String get createDramaSelectActor => 'Select Character';

  @override
  String get createDramaBindActorTitle => 'Select Character IP';

  @override
  String createDramaBindIpSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get createDramaBindIpEmpty => 'No data';

  @override
  String get createDramaBindIpMarketplace => 'Go to Character IP Market';

  @override
  String get createDramaBindIpConfirm => 'Confirm binding';

  @override
  String createDramaBindActorSubtitle(String roleName) {
    return 'Select a character IP to play “$roleName”';
  }

  @override
  String createDramaBindActorOwnedCount(int count) {
    return 'You own $count Character IPs';
  }

  @override
  String createDramaBindActorIpLabel(String code) {
    return 'Character IP $code';
  }

  @override
  String get createDramaBindActorBoundTag => 'Bound';

  @override
  String get createDramaBindIpRemove => 'Remove';

  @override
  String createDramaBindActorBoundToast(String name) {
    return 'Bound $name';
  }

  @override
  String get createDramaBindActorUnbind => 'Unbind';

  @override
  String get createDramaBindActorExpired =>
      'The 7-day binding window has expired. New Character IP bindings cannot be added.';

  @override
  String get createDramaBindActorEmptyTitle => 'No Character IP to bind';

  @override
  String get createDramaBindActorEmptyDesc =>
      'You need to own a Character IP before binding it to a character';

  @override
  String get createDramaBindActorGotoCreate => 'Create Character';

  @override
  String get createDramaPrevStep => 'Back';

  @override
  String get createDramaNextStep => 'Next';

  @override
  String get createDramaSubmit => 'Post';

  @override
  String get createDramaRoleNameLabel => 'Role Name';

  @override
  String get createDramaRoleNameHint => 'Enter role name';

  @override
  String get createDramaRoleNameRequired => 'Please enter the role name';

  @override
  String get createDramaRoleBioLabel => 'Role Bio';

  @override
  String get createDramaRoleBioHint => 'Enter role bio';

  @override
  String get createDramaRoleBioRequired => 'Role bio is required';

  @override
  String get createDramaRoleAddTitle => 'Add Role';

  @override
  String get createDramaRoleEditTitle => 'Edit Role';

  @override
  String get createDramaRoleUploadAvatar => 'Upload Avatar';

  @override
  String get createDramaRoleSave => 'Save';

  @override
  String get createDramaRoleDeleteConfirm => 'Delete this character?';

  @override
  String createDramaVideoDeleteConfirm(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get createDramaVideoDeleteTitle => 'Delete Video';

  @override
  String get createDramaVideoPreviewUnavailable =>
      'Previously uploaded videos cannot be previewed at this time';

  @override
  String get createDramaRoleEmpty => 'No roles added yet';

  @override
  String get createDramaRoleBindComingSoon => 'Role binding is coming soon';

  @override
  String get createDramaRoleAvatarCropTitle => 'Crop Role Avatar';

  @override
  String get createDramaRoleAvatarUploadFailed => 'Role Avatar upload failed';

  @override
  String get createDramaPublishedSuccess => 'Posted successfully';

  @override
  String get createDramaDraftRestored => 'Restored your unfinished draft';

  @override
  String get createDramaDraftClear => 'Clear data';

  @override
  String get createDramaDraftDiscard => 'Discard and return';

  @override
  String get createDramaDraftSave => 'Save draft';

  @override
  String get createDramaEditLoading => 'Loading...';

  @override
  String get createDramaEditLoadError =>
      'Failed to load drama info, please retry';

  @override
  String get createDramaSubmitValidationTitle => 'Please enter the drama title';

  @override
  String get createDramaSubmitValidationCover => 'Please upload a cover image';

  @override
  String get createDramaSubmitValidationVideos =>
      'Please upload at least one video';

  @override
  String get createDramaSubmitValidationSession =>
      'Upload session invalid, please re-upload videos';

  @override
  String get createDramaUploadSessionFailed =>
      'Failed to create upload session';

  @override
  String get createDramaSubmitValidationRoles => 'Please add at least one role';

  @override
  String get createDramaStep1TitleRequired => 'Please enter the drama title';

  @override
  String get createDramaStep1SynopsisRequired => 'Please enter the synopsis';

  @override
  String get createDramaStep1CoverRequired => 'Please add a cover';

  @override
  String get createDramaStep1TagsRequired => 'Please select tags';

  @override
  String get createDramaEpisodeDescriptionRequired =>
      'Please enter the episode description';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsUI => 'Interface';

  @override
  String get settingsAppVersion => 'Version';

  @override
  String get settingsVersionLatestToast => 'You are on the latest version';

  @override
  String get settingsVersionCheckFailed =>
      'Couldn\'t check for updates. Please try again later.';

  @override
  String get appVersionUpdateTitle => 'New Version Available';

  @override
  String get appVersionUpdateContentsLabel => 'What\'s new:';

  @override
  String get appVersionUpdateConfirm => 'Update Now';

  @override
  String get appVersionUpdateLater => 'Maybe Later';

  @override
  String get settingsTermsOfService => 'Terms of Service';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsDeleteAccount => 'Delete Account';

  @override
  String settingsDeleteAccountConfirm(String deadline) {
    return 'Your account will be deleted at $deadline. During this period, you can log in again to cancel the account deletion.';
  }

  @override
  String get settingsDeleteAccountSuccess =>
      'Account deletion request submitted';

  @override
  String get settingsClearCache => 'Clear Cache';

  @override
  String get settingsNetworkInspector => 'Network Inspector';

  @override
  String get settingsClearCacheConfirm => 'Are you sure to clear cache?';

  @override
  String get miningRulesHowToPlay => 'How Dispatch Mining Works';

  @override
  String get miningRulesFlowSubtitle =>
      'Understand the process from dispatching to earning rewards at a glance';

  @override
  String get miningRulesSection1Title => 'Dispatch';

  @override
  String get miningRulesSection1Desc =>
      'Dispatch idle characters into the 5 slots below to start automatic mining and produce STORY.';

  @override
  String get miningRulesSection1Bullet1 =>
      'Up to 5 characters can be dispatched at the same time';

  @override
  String get miningRulesSection1Bullet2 =>
      'Multiple cards of the same Character IP can be dispatched together';

  @override
  String get miningRulesSection1Bullet3 =>
      'Consumes 1 stamina per hour after dispatch. Keeps producing while stamina > 0, stops when stamina = 0';

  @override
  String get miningRulesSection2Title => 'Output Formula';

  @override
  String get miningRulesSection2Desc =>
      'Hourly output for each card is calculated as follows:';

  @override
  String get miningRulesSection2Formula =>
      'Per-card hourly output = Character Salary × 1 STORY';

  @override
  String get miningRulesSection2FactorsTitle => 'Where:';

  @override
  String get miningRulesSection2Factor1 =>
      'Character Salary = IP Salary × Mining Coefficient × CP Coefficient × Trust2';

  @override
  String get miningRulesSection2Factor2 =>
      'IP Salary = Price coefficient × Heat coefficient × Trust1';

  @override
  String get miningRulesSection2Factor3 =>
      'Mining Coefficient — Higher tier, larger coefficient. Lv1=1.0 → Lv2=2.2 → Lv3=5.0 → Lv4=11 → Lv5=24';

  @override
  String miningRulesSection2Factor4(String currency1, String currency2) {
    return 'Price coefficient — launch price P0: P0≤10$currency1 linear growth · P0>10$currency2 approaching a cap of 1.6';
  }

  @override
  String get miningRulesSection2Factor5 =>
      'Heat coefficient — the better the recent drama performance, the higher the heat (completed views, likes, saves, comments)';

  @override
  String get miningRulesSection2Factor6 =>
      'CP Coefficient — Not open yet; Trust defaults to 1.0';

  @override
  String miningRulesSection2StaminaText(int staminaLimit) {
    return 'Stamina only matters as on/off: $staminaLimit and 1 stamina yield the same hourly output.';
  }

  @override
  String get miningRulesSection2ExampleTitle => 'Example';

  @override
  String miningRulesSection2ExampleDesc(String currency) {
    return 'Lin Mengyao · Lv3 Lead · P0=12$currency (price coefficient ≈1.0859) · heat 3.5\n→ Hourly output = 5.0 × 1.0859 × 3.5 × 1 = 19.00325 STORY';
  }

  @override
  String get miningRulesCoefTableTitle => 'Coefficient details';

  @override
  String get miningRulesCoefColCoef => 'Coefficient';

  @override
  String get miningRulesCoefColFactor => 'Determined by';

  @override
  String get miningRulesCoefColDesc => 'Details';

  @override
  String get miningRulesCoefMining => 'Mining Coefficient';

  @override
  String get miningRulesCoefPrice => 'Price Coefficient';

  @override
  String get miningRulesCoefHeat => 'Heat coefficient';

  @override
  String get miningRulesCoefCp => 'CP Coefficient';

  @override
  String get miningRulesCoefTrust => 'Trust';

  @override
  String get miningRulesCoefMiningFactor => 'Tier';

  @override
  String get miningRulesCoefPriceFactor => 'Launch price P0';

  @override
  String get miningRulesCoefHeatFactor => 'Recent drama performance';

  @override
  String get miningRulesCoefCpFactor => '-';

  @override
  String get miningRulesCoefTrustFactor => 'Platform risk control';

  @override
  String get miningRulesCoefMiningDesc =>
      'Lv1=1.0 · Lv2=2.2 · Lv3=5.0 · Lv4=11 · Lv5=24';

  @override
  String miningRulesCoefPriceDesc(String currency1, String currency2) {
    return 'Linear when P0≤10$currency1 · asymptotic cap 1.6 when P0>10$currency2';
  }

  @override
  String get miningRulesCoefHeatDesc =>
      'Heat coefficient: the more completed views, likes, saves, and ratings for dramas featuring the character IP, the higher the heat';

  @override
  String get miningRulesCoefCpDesc => 'Not open yet';

  @override
  String get miningRulesCoefTrustDesc => 'Defaults to 1.0';

  @override
  String get miningRulesSection3Title => 'Settlement Distribution';

  @override
  String get miningRulesSection3Desc =>
      'Every week the platform has a total reward pool (weekly hard cap), starting at about 2,115,385 STORY, then decreasing each week (weekly × 0.99572).';

  @override
  String get miningRulesSettleColCondition => 'Condition';

  @override
  String get miningRulesSettleColRule => 'Distribution rule';

  @override
  String get miningRulesSection3Case1Title =>
      'Network nominal output ≤ weekly hard cap';

  @override
  String get miningRulesSection3Case1Desc =>
      'Everyone receives the full amount; leftovers are not launched or topped up';

  @override
  String get miningRulesSection3Case2Title =>
      'Network nominal output > weekly hard cap';

  @override
  String get miningRulesSection3Case2Desc =>
      'Proportional scaling: your actual = your nominal × reward pool ÷ network output';

  @override
  String get miningRulesSection3Case3Title =>
      'Single address exceeds 5% of the reward pool';

  @override
  String get miningRulesSection3Case3Desc =>
      'The excess is not launched, returned, or compensated';

  @override
  String get miningRulesSection3ExampleDesc =>
      'Assume the weekly reward pool is 100,000 STORY:\nCase A: Only you produce 134 → you get 134; the rest is not issued\nCase B: Network output 250,000 → scaled to 40%\nCase C: After scaling someone should get 6,000, but the cap is 5,000 → only 5,000 is issued';

  @override
  String get miningRulesSection4Title => 'Stamina Management';

  @override
  String get miningRulesTableStatus => 'Status';

  @override
  String get miningRulesTableStaminaChange => 'Stamina Change';

  @override
  String get miningRulesTableOutput => 'Output';

  @override
  String get miningRulesStatusMining => 'Dispatched (Mining)';

  @override
  String get miningRulesStaminaMining => '-1 per hour';

  @override
  String get miningRulesOutputNormal => 'Normal Output';

  @override
  String get miningRulesStatusZeroStamina => 'Stamina Depleted';

  @override
  String get miningRulesStaminaZeroStamina => 'No change';

  @override
  String get miningRulesOutputZero => 'Zero Output';

  @override
  String get miningRulesStatusResting => 'Recalled & Resting';

  @override
  String get miningRulesStaminaResting => '+1 per hour (auto-restore)';

  @override
  String get miningRulesOutputPaused => 'Paused Output';

  @override
  String get miningRulesStatusPaidRefill => 'Refill Stamina (Paid)';

  @override
  String miningRulesStaminaPaidRefill(int staminaLimit) {
    return 'Instantly refill to $staminaLimit';
  }

  @override
  String get miningRulesOutputRestored => 'Restored Output';

  @override
  String get miningRulesSection4TipsTitle => 'Stamina refill notes';

  @override
  String get miningRulesSection4Tip1 =>
      'Can only refill fully at once; cannot buy 10 points only';

  @override
  String get miningRulesSection4Tip2 =>
      'Price depends only on tier, not remaining stamina';

  @override
  String get miningRulesSection4Tip3 =>
      'The closer to 0, the better the value — same price buys the most mining time';

  @override
  String get miningRulesSection4PriceTitle => 'Refill prices';

  @override
  String get miningRulesPriceTableTier => 'Tier';

  @override
  String get miningRulesPriceTableFullRefill => 'Full Refill';

  @override
  String get miningRulesLv1 => 'Lv1 Extra';

  @override
  String get miningRulesLv2 => 'Lv2 Supporting';

  @override
  String get miningRulesLv3 => 'Lv3 Protagonist';

  @override
  String get miningRulesLv4 => 'Lv4 Superstar';

  @override
  String get miningRulesLv5 => 'Lv5 Top Tier';

  @override
  String get gameActorLevelName1 => 'Extra';

  @override
  String get gameActorLevelName2 => 'Supporting';

  @override
  String get gameActorLevelName3 => 'Protagonist';

  @override
  String get gameActorLevelName4 => 'Superstar';

  @override
  String get gameActorLevelName5 => 'Top Tier';

  @override
  String miningRulesLv1Price(String currency) {
    return '10 $currency';
  }

  @override
  String miningRulesLv2Price(String currency) {
    return '20 $currency';
  }

  @override
  String miningRulesLv3Price(String currency) {
    return '50 $currency';
  }

  @override
  String miningRulesLv4Price(String currency) {
    return '130 $currency';
  }

  @override
  String miningRulesLv5Price(String currency) {
    return '320 $currency';
  }

  @override
  String get miningRulesSection5Title => 'Upgrade Tier';

  @override
  String get miningRulesSection5Desc =>
      '3 cards of the same character and tier + synthesis fee + cumulative completed views target for that character = upgrade 1 level. After upgrading, the mining coefficient surges and hourly output multiplies.';

  @override
  String get miningRulesUpgradePathSubtitle => 'Upgrade path';

  @override
  String get miningRulesUpgradeColPath => 'Upgrade path';

  @override
  String get miningRulesUpgradeColHeat =>
      'Cumulative Completed Views Threshold';

  @override
  String get miningRulesUpgradeColFee => 'Synthesis fee';

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
  String get miningRulesSummaryTitle => 'Summary in One Sentence';

  @override
  String get miningRulesSummaryDesc =>
      'Dispatch → Produce → Watch stamina → Collect. Refill or rest when stamina runs low; heat grows with the character\'s drama performance, and upgrading boosts output.';

  @override
  String get playerNotInterested => 'Not interested';

  @override
  String get playerNotInterestedDone =>
      'Feedback received. We\'ll show fewer videos like this';

  @override
  String get playerClearScreen => 'Clear screen';

  @override
  String get playerAutoPlay => 'Auto play';

  @override
  String get playerReport => 'Report';

  @override
  String get playerReportSuccess => 'Reported successfully';

  @override
  String get commentReportSuccess =>
      'Submitted successfully, we\'ll process it shortly';

  @override
  String get reportSuccessTitle =>
      'Submitted successfully. We\'ll review it soon';

  @override
  String get reportSuccessThanks =>
      'Thanks for helping keep the community safe!';

  @override
  String get reportSuccessAlsoYouCan => 'You can also';

  @override
  String get reportSuccessDone => 'Done';

  @override
  String get reportReduceRecommend => 'See less';

  @override
  String get reportReduceRecommendDone => 'We\'ll show less';

  @override
  String get reportSuccessContentFallback => 'This content';

  @override
  String get reportDescription => 'Report Description';

  @override
  String get reportDescriptionPlaceholder => 'Describe the details (Optional)';

  @override
  String get reportReasonPorn => 'Pornography & Vulgarity';

  @override
  String get reportReasonIllegal => 'Illegal or Criminal';

  @override
  String get reportReasonSensitive => 'Sensitive Content';

  @override
  String get reportReasonGambling => 'Gambling or Violence';

  @override
  String get reportReasonMinors => 'Harm to Minors';

  @override
  String get reportReasonCopyright => 'Copyright Infringement';

  @override
  String get reportReasonQuality => 'Quality Issue';

  @override
  String get reportReasonNotLike => 'I don\'t like it';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get gameUpgrade => 'Upgrade';

  @override
  String get gameUpgradeTitle => 'Level Upgrade';

  @override
  String get gameUpgradeCurrentLevel => 'Current Level';

  @override
  String get gameUpgradeTargetLevel => 'Target Level';

  @override
  String get gameUpgradeHeatThreshold => 'Drama Completed Views';

  @override
  String get gameUpgradeRequiredCount => 'Consume Same-IP Characters';

  @override
  String get gameUpgradeFee => 'Upgrade Fee';

  @override
  String get gameUpgradeNextLevelReq => 'Next Level Requirements';

  @override
  String get gameUpgradeBeforeAfter => 'Before and After Upgrade';

  @override
  String get gameUpgradeSelectMaterialDesc =>
      'Select same IP same level characters to consume';

  @override
  String gameUpgradeMaterialCount(int current, int required) {
    return '$current/$required';
  }

  @override
  String gameUpgradeToLevel(int level, String levelName) {
    return 'Upgrade to Lv$level $levelName';
  }

  @override
  String gameUpgradeSelectMaterialLabel(int current, int required) {
    return 'Select Materials ($current/$required)';
  }

  @override
  String gameUpgradeSelectMaterials(int count) {
    return 'Please select $count materials';
  }

  @override
  String get gameUpgradeConfirm => 'Confirm Upgrade';

  @override
  String get gameUpgradeSuccess => 'Upgrade successful';

  @override
  String get gameUpgradeFailed => 'Upgrade failed, please try again';

  @override
  String get gameUpgradeInsufficientMaterials => 'Insufficient materials';

  @override
  String get gameUpgradeNoMaterials =>
      'No available materials of the same IP and level';

  @override
  String get creatorDramaStatusMinted => 'Minted';

  @override
  String get creatorDramaStatusOffline => 'Delisted';

  @override
  String get creatorDramaStatusUnavailable => 'Temporarily Unavailable';

  @override
  String get creatorMintDramaNft => 'Mint Drama NFT';

  @override
  String get creatorMintConfirmDesc =>
      'Confirm minting this drama as an on-chain NFT. After minting, this drama will generate STORY mining rewards.';

  @override
  String get creatorMintFee => 'Minting Fee';

  @override
  String creatorMintInsufficientUsdc(String currency1, String currency2) {
    return 'Insufficient $currency1 balance. On-chain launch requires at least 1 $currency2';
  }

  @override
  String get creatorMintInvalidDramaId => 'Invalid drama ID';

  @override
  String get creatorMintInProgress => 'Minting in progress, please wait';

  @override
  String get creatorMintWalletNotReady =>
      'Solana wallet address is not ready. Please log in again';

  @override
  String get creatorMintDigestEmpty =>
      'Launch signature data is empty. Please try again later.';

  @override
  String get creatorMintWalletMismatch =>
      'Mint wallet does not match the current wallet. Please log in again';

  @override
  String get creatorMintSuccess => 'Minting Successful!';

  @override
  String creatorMintDramaOnChain(String name) {
    return 'Drama NFT for \"$name\" has been minted on-chain';
  }

  @override
  String creatorMintNftNumber(String id) {
    return 'NFT Number: $id';
  }

  @override
  String get creatorMintTxHash => 'Transaction Hash: ';

  @override
  String get gameSelectActor => 'Select Character to Deploy';

  @override
  String get gameSelectActorDesc => 'Select an idle character to dispatch';

  @override
  String get agentV2SchedulePerformance => 'Perform';

  @override
  String get agentV2PerformAllTitle => 'Perform All';

  @override
  String get agentV2PerformAllDescription =>
      'Characters with higher salary will fill available performance slots first';

  @override
  String get agentV2PerformAllFailed =>
      'One-tap performance failed. Please try again';

  @override
  String get agentV2PerformAllSuccess => 'One-tap performance successful';

  @override
  String agentV2PerformAllDepletedResult(int successCount, int depletedCount) {
    return '$successCount successfully scheduled, $depletedCount unable to perform due to depleted stamina';
  }

  @override
  String get agentV2RestAllSuccess => 'One-tap rest successful';

  @override
  String agentV2PerformAllCount(int count) {
    return '$count characters';
  }

  @override
  String get agentV2TodoTitle => 'To-do';

  @override
  String agentV2TodoVacancies(int count) {
    return '$count performance slot(s) available';
  }

  @override
  String agentV2TodoStaminaDepleted(String name) {
    return '$name has 0 stamina and stopped working';
  }

  @override
  String get agentV2TodoPerform => 'Perform';

  @override
  String get agentV2TodoRefill => 'Refill';

  @override
  String get agentV2TodoHealthy => 'Performances normal · Stamina sufficient';

  @override
  String get agentV2CandidateActorsTitle => 'Candidate Characters';

  @override
  String get agentV2CandidateActorsDescription =>
      'Resting characters recover 1 stamina per hour';

  @override
  String get agentV2UpgradeableActorsTitle => 'Upgrade Characters';

  @override
  String get agentV2UpgradeableActorsEmpty =>
      'No characters available to upgrade';

  @override
  String get agentV2NoActors => 'No characters';

  @override
  String get agentV2UpgradeNow => 'Upgrade Now';

  @override
  String get agentV2UpgradeCompletion => 'Completed Views';

  @override
  String get agentV2UpgradeMaterials => 'Characters';

  @override
  String agentV2UpgradeRequirementsTitle(String name) {
    return 'Upgrade $name';
  }

  @override
  String agentV2UpgradeCompletionRemaining(int count) {
    return '$count more completed views needed';
  }

  @override
  String get agentV2UpgradeCompletionHint =>
      'Watch dramas featuring this character, or create a new drama for them, to increase completed views';

  @override
  String get agentV2UpgradeWatchDramas => 'Watch Their Dramas';

  @override
  String get agentV2UpgradeCreateDrama => 'Create a Drama';

  @override
  String agentV2UpgradeMaterialsRemaining(int count) {
    return '$count more same-IP, same-level characters needed';
  }

  @override
  String agentV2UpgradeMaterialsHint(String name) {
    return 'Sign more “$name” characters from the character profile';
  }

  @override
  String get agentV2UpgradeGetActors => 'Get Characters';

  @override
  String agentV2UpgradeActorsSyncing(int count) {
    return '$count new character(s) syncing; upgrade requirements updated';
  }

  @override
  String get agentV2UpgradeConfirmSelectMaterials =>
      'Select same-IP, same-level characters to consume';

  @override
  String get agentV2UpgradeConfirmSalaryLabel => 'Salary';

  @override
  String get agentV2SalaryDetailTitle => 'Character salary';

  @override
  String get agentV2SalaryHourly => 'Hourly salary';

  @override
  String get agentV2SalaryUnit => 'STORY / hour';

  @override
  String get agentV2SalaryFormula =>
      'Character salary = IP salary × Salary coefficient × CP coefficient × Trust2';

  @override
  String get agentV2SalaryFormulaLv1 =>
      'Lv.1 character salary = Price coefficient × Heat coefficient';

  @override
  String agentV2SalaryFormulaLevel(int level) {
    return 'Lv.$level salary = Lv.1 salary × Salary coefficient';
  }

  @override
  String get agentV2SalaryLv1Pay => 'Lv.1 salary';

  @override
  String get agentV2SalaryCoefficient => 'Salary coefficient';

  @override
  String agentV2SalaryCoefficientWithLevel(int level, String roleName) {
    return 'Salary coefficient (Lv.$level $roleName)';
  }

  @override
  String get agentV2SalaryCpCoefficient => 'CP Coefficient';

  @override
  String get agentV2PerformanceConfirmDescription =>
      'This character automatically earns salary while performing. Each hour of performing consumes 1 stamina point; when stamina runs out, it stops earning.';

  @override
  String get agentV2PerformanceConfirmTitle => 'Schedule performance';

  @override
  String get agentV2PerformanceZeroFeePrefix =>
      'This character\'s IP currently has ';

  @override
  String get agentV2PerformanceZeroFeeHighlight => 'zero salary';

  @override
  String get agentV2PerformanceZeroFeeSuffix =>
      ', so performing will not generate earnings. Performing also consumes 1 stamina per hour. Continue anyway?';

  @override
  String get agentV2PerformanceScheduledSuccess => 'Performance scheduled';

  @override
  String get agentV2PerformanceSlotsFull =>
      'Performance slots are full (max 5)';

  @override
  String get gameDeployStaminaDepleted =>
      'Stamina depleted. Refill stamina before performing';

  @override
  String get agentMoreRules => 'Rules';

  @override
  String get agentMoreSalaryAndPool => 'Salary & reward pool';

  @override
  String get agentV2WeeklySalaryTitle => 'Level Up · Perform · Earn Salary';

  @override
  String get agentV2WeeklySalaryLabel => 'This week\'s salary';

  @override
  String get gameDeployConfirmDesc =>
      'This character will automatically participate in staking mining and continuously generate STORY earnings for you. Note: 1 stamina point is consumed at the start of every hour. Earnings stop when stamina is depleted.';

  @override
  String get gameRecallConfirm => 'Confirm Recall';

  @override
  String get gameRecallDesc =>
      'Recalling this character will pause drama production rewards, but current stamina is unaffected.';

  @override
  String get actorStatCompletionTitle => 'Completed Views';

  @override
  String get actorStatCompletionDesc =>
      'Total completed views across all dramas this character has appeared in';

  @override
  String get actorStatHeatTitle => 'Heat';

  @override
  String get actorStatHeatDesc =>
      'Total heat of all short dramas featuring this character IP over the past 30 days';

  @override
  String get actorStatIpPowerTitle => 'IP Salary';

  @override
  String get actorStatIpPowerDesc =>
      'IP Salary = Price coefficient × Heat coefficient × Trust1';

  @override
  String get dramaFavoriteLabel => 'Favorite';

  @override
  String get dramaRatingLabel => 'Rating';

  @override
  String get dramaUnnamed => 'Untitled';

  @override
  String get videoNotReady => 'Video not ready, please try again later';

  @override
  String get inviteDirectSubordinates => 'Invited Users';

  @override
  String inviteTotalCount(int count) {
    return 'Total: $count users';
  }

  @override
  String get inviteTotalLabel => 'Total Users';

  @override
  String get inviteActiveLabel => 'Active Users';

  @override
  String get invitePendingLabel => 'Pending Activation';

  @override
  String get inviteEmpty => 'No subordinate users yet';

  @override
  String inviteRegisteredAt(String date) {
    return 'Registered on $date';
  }

  @override
  String get gameUpgradeMaxLevel => 'Maximum tier reached';

  @override
  String get listNoMoreData => 'No more data';

  @override
  String get iapSheetTitle => 'Buy Points';

  @override
  String get iapSheetSubtitle =>
      'Points are used for in-app services such as signing roles';

  @override
  String get iapBalance => 'Balance';

  @override
  String get iapConfirmPurchase => 'Confirm Purchase';

  @override
  String get iapPurchaseSuccess => 'Purchase successful';

  @override
  String get iapPurchaseFailed => 'Purchase failed, please try again';

  @override
  String get iapPurchaseFailedTitle => 'Purchase failed';

  @override
  String get iapCrediting => 'Crediting in progress, please wait';

  @override
  String get iapNoProducts => 'No products available';

  @override
  String get iapSuccessConfirm => 'OK';

  @override
  String iapGainedPoints(String value) {
    return '+$value';
  }

  @override
  String iapPointsCount(int count) {
    return '$count points';
  }

  @override
  String get gameBatchRefillTransactionTooLarge =>
      'Batch refill transaction is too large. Reduce the number of actors and try again.';

  @override
  String get agentV2RefillTitle => 'Refill stamina';

  @override
  String get agentV2RefillCost => 'Cost';

  @override
  String get agentV2RefillActorButton => 'This character';

  @override
  String get agentV2RefillAllActors => 'Refill all performing characters';

  @override
  String agentV2RefillActorCount(int count) {
    return '$count characters';
  }

  @override
  String get agentV2RefillAllButton => 'Refill all';

  @override
  String get agentV2RefillOr => 'or';

  @override
  String get agentV2RestAll => 'Rest all';

  @override
  String agentV2RestActorCount(int count) {
    return '$count characters';
  }

  @override
  String get salaryPoolRateUnit => 'STORY / hr';

  @override
  String get salaryPoolDecayInfo => 'Weekly decay factor ×0.99572';

  @override
  String get salaryPoolStakeLabel => 'Performance Reward Pool (75%)';

  @override
  String get salaryPoolInviteLabel => 'Invite Reward Pool (25%)';

  @override
  String get salaryPoolRule1Title => 'Total nominal output ≤ weekly hard cap:';

  @override
  String get salaryPoolRule2Title => 'Total nominal output > weekly hard cap:';

  @override
  String get salaryPoolRule2Body =>
      'Actual payout = user nominal output × (weekly hard cap ÷ total nominal output)';

  @override
  String get agentV3WeeklySalary => 'Weekly salary';

  @override
  String get agentV3PerformAll => 'Perform all';

  @override
  String get agentV3RestAll => 'Rest all';

  @override
  String get agentV3RestAllDescription =>
      'Recall all performing characters to stop stamina consumption and earnings';

  @override
  String get agentV3RefillAll => 'Refill all';

  @override
  String get agentV3RefillAllDescription =>
      'Fully refill performing characters\' stamina';

  @override
  String get agentV3RefillCost => 'Uses';

  @override
  String get agentV3RefillNoActors => 'No characters need a stamina refill';

  @override
  String get agentV3SignActor => 'Sign characters';

  @override
  String get agentV3Todo => 'Tasks';

  @override
  String get agentV3Upgrade => 'Upgrade';

  @override
  String agentV3UpgradeMaterialHint(int count) {
    return 'Upgrading requires consuming $count characters with the same IP and level';
  }

  @override
  String get agentV3Waiting => 'Waiting';

  @override
  String get agentV3WaitingActorsTitle => 'Waiting Characters';

  @override
  String get agentV3WaitingActorsDescription =>
      'Resting characters recover 1 stamina per hour';

  @override
  String get agentV3Recycle => 'Recycle';

  @override
  String get agentV3RecycleActorsTitle => 'Recycle Characters';

  @override
  String get agentV3RecyclePerforming => 'Performing';

  @override
  String get agentV3RecycleReceive => 'You will receive';

  @override
  String get agentV3RecyclePermanentWarning =>
      'This character will be permanently destroyed and cannot be recovered';

  @override
  String get agentV3RecycleConfirm => 'Confirm destruction';

  @override
  String get agentV3RecycleConfirmAgain => 'Tap again to destroy';

  @override
  String get agentV3RecycleSubmitted => 'Character recycled successfully';

  @override
  String get agentV3RecycleEstimateUnavailable =>
      'Recycle estimate is unavailable. Please try again';

  @override
  String get agentV3EnergyPack => 'Energy Pack';

  @override
  String get agentV3EnergyPackDescription =>
      'Fully restores character stamina, consumed according to character level.';

  @override
  String get agentV3TrainingManual => 'Training Manual';

  @override
  String get agentV3TrainingManualDescription =>
      'Character upgrade material, consumed according to the character\'s level when upgrading.';

  @override
  String get agentV3PurchaseButton => 'Buy';

  @override
  String agentV3PurchaseWalletBalance(String balance, String currency) {
    return 'Balance $balance $currency';
  }

  @override
  String agentV3PurchaseTitle(String item) {
    return 'Buy $item';
  }

  @override
  String get agentV3PurchaseUnitPrice => 'Unit price';

  @override
  String get agentV3PurchaseQuantity => 'Quantity';

  @override
  String get agentV3PurchaseTotal => 'Total';

  @override
  String get agentV3PurchaseConfirm => 'Confirm payment';

  @override
  String get agentV3PurchaseUnavailable =>
      'Item purchases are not available in this environment';

  @override
  String get agentV3PurchaseConfigUnavailable =>
      'Item pricing is unavailable. Please try again later';

  @override
  String get agentV3PurchaseSubmitted =>
      'Purchase successful. Added to your Item Backpack (Agent page)';

  @override
  String get agentV3PurchaseCreditPending =>
      'Energy packs are still being credited. Please try again shortly';

  @override
  String get agentV3PurchaseCrediting => 'Crediting';

  @override
  String agentV3PurchaseBalance(String count) {
    return 'Owned: $count';
  }

  @override
  String get agentV3RefillTitle => 'Refill stamina';

  @override
  String agentV3RefillLevelCost(String level) {
    return 'Lv.$level uses';
  }

  @override
  String get agentV3RefillAvailable => 'Available';

  @override
  String get agentV3RefillUse => 'Use';

  @override
  String get agentV3RefillSuccess => 'Stamina refilled';

  @override
  String agentV3RefillAllSuccess(int actorCount, String packCount) {
    return 'Refilled stamina for $actorCount characters (used $packCount stamina packs)';
  }

  @override
  String get agentV3RefillConfigUnavailable =>
      'Stamina pack usage is unavailable';

  @override
  String get agentV3RefillInsufficient => 'Not enough stamina packs';
}
