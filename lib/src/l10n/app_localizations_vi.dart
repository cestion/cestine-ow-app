// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'StoryFun';

  @override
  String get commonCancel => 'Hủy';

  @override
  String get commonNoData => 'Chưa có dữ liệu';

  @override
  String get commonNo => 'Không';

  @override
  String get commonYes => 'Có';

  @override
  String get publishDrama => 'Đăng phim ngắn';

  @override
  String get publishVideo => 'Đăng video';

  @override
  String get publishVideoUploadTitle => 'Tải tệp video lên';

  @override
  String get publishVideoFileHint =>
      'Hỗ trợ mp4, flv, wmv, mkv, avi, mov và webm. Tối đa 2GB';

  @override
  String get publishVideoChooseFile => 'Chọn tệp';

  @override
  String get publishVideoChangeFile => 'Đổi tệp';

  @override
  String get publishVideoChooseSource => 'Chọn nguồn video';

  @override
  String get publishVideoChooseFromGallery => 'Chọn từ thư viện';

  @override
  String get publishVideoChooseFromFiles => 'Chọn từ tệp';

  @override
  String get publishVideoPreparing => 'Đang chuẩn bị video…';

  @override
  String get publishVideoCoverTitle => 'Ảnh bìa video';

  @override
  String get publishVideoChangeCover => 'Đổi ảnh bìa';

  @override
  String get publishVideoCoverHint => 'JPG/PNG, tối đa 5MB';

  @override
  String get publishVideoDescriptionLabel => 'Mô tả';

  @override
  String get publishVideoRequired => '(Bắt buộc)';

  @override
  String get publishVideoDescriptionHint => 'Thêm mô tả (tối đa 200 ký tự)';

  @override
  String get publishVideoSaveDraft => 'Lưu bản nháp';

  @override
  String get publishVideoDraftEditModeNotSupported =>
      'Không thể lưu bản nháp ở chế độ chỉnh sửa';

  @override
  String get publishVideoDraftNothingToSave => 'Không có nội dung để lưu';

  @override
  String get publishVideoNext => 'Tiếp theo';

  @override
  String get publishVideoCoverCropTitle => 'Cắt ảnh bìa video';

  @override
  String get publishVideoVideoTooLarge => 'Tệp video không được vượt quá 2GB';

  @override
  String get publishVideoVideoPickFailed =>
      'Không thể chọn video. Vui lòng thử lại';

  @override
  String get publishVideoInsufficientStorage =>
      'Thiết bị không đủ dung lượng để chuẩn bị video này';

  @override
  String get publishVideoPermissionDenied =>
      'Không thể truy cập video. Hãy kiểm tra quyền ảnh hoặc tệp';

  @override
  String get publishVideoSourceUnavailable =>
      'Video này tạm thời không khả dụng. Hãy tải tệp đám mây xuống rồi thử lại';

  @override
  String get publishVideoPrepareFailed =>
      'Không thể chuẩn bị video. Hãy thử lại hoặc chọn từ Tệp';

  @override
  String get publishVideoMetadataUnavailable =>
      'Không thể đọc thông tin video. Hãy chọn tệp khác';

  @override
  String get publishVideoCoverTooLarge => 'Ảnh bìa không được vượt quá 5MB';

  @override
  String get publishVideoCoverUnsupportedFormat => 'Chỉ hỗ trợ ảnh JPG/PNG';

  @override
  String get publishVideoCoverPickFailed =>
      'Không thể chọn ảnh bìa. Vui lòng thử lại';

  @override
  String get publishVideoUploadSessionFailed => 'Không thể tạo phiên tải lên';

  @override
  String get publishVideoPublishedSuccess => 'Đã đăng video';

  @override
  String get publishVideoUpdatedSuccess => 'Đã cập nhật video';

  @override
  String get publishActorIp => 'Phát hành IP';

  @override
  String get commonConfirm => 'Xác nhận';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotice => 'Thông báo';

  @override
  String get commonRetry => 'Thử lại';

  @override
  String get publicProfileLikedEmpty => 'Chưa có phim đã thích';

  @override
  String get profileTabDramas => 'Phim ngắn';

  @override
  String get profileTabWorks => 'Tác phẩm';

  @override
  String get profileTabActorIp => 'IP nhân vật';

  @override
  String dramaUnlockConfirmLabel(String price, String currency) {
    return 'Mở khóa với $price $currency';
  }

  @override
  String dramaAllEpisodes(int count) {
    return '$count tập';
  }

  @override
  String dramaAllEpisodesFull(Object count) {
    return 'Tất cả $count tập';
  }

  @override
  String get dramaLoading => 'Đang tải phim nổi bật...';

  @override
  String get dramaEmpty => 'Hiện chưa có phim ngắn';

  @override
  String get dramaRefresh => 'Làm mới';

  @override
  String get navTheater => 'Nhà hát';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get theaterTabShortDrama => 'Phim ngắn';

  @override
  String get theaterTabRecommend => 'Đề xuất';

  @override
  String get playerWatchFullDrama => 'Xem trọn bộ';

  @override
  String get playerStoryPerHourUnit => 'STORY/h';

  @override
  String get navNft => 'Thị trường IP';

  @override
  String get navNftIp => 'Nhân vật IP';

  @override
  String watchFullDramaEpisodes(int count) {
    return 'Xem phim · Tổng $count tập';
  }

  @override
  String get navCreate => 'Sáng tác';

  @override
  String get navProfile => 'Cá nhân';

  @override
  String get navMy => 'Quản lý';

  @override
  String get aboutTitle => 'Về chúng tôi';

  @override
  String get aboutVision => 'Trí tuệ nhân tạo · Web3 · Giao thức';

  @override
  String get aboutVisionDesc =>
      'Ba động lực thúc đẩy, biến trải nghiệm kể chuyện từ thụ động thành chủ động';

  @override
  String get aboutAiDesc =>
      'Những ý tưởng của bạn sẽ tự động biến thành câu chuyện';

  @override
  String get aboutWeb3Desc => 'Tác phẩm của bạn sẽ mãi mãi thuộc về bạn';

  @override
  String get aboutProtocolDesc => 'Câu chuyện của bạn có thể tiếp diễn mãi mãi';

  @override
  String get aboutIdentityTitle => 'Bản sắc kể chuyện của bạn';

  @override
  String get aboutIdentityDesc =>
      'Bản thân bạn chính là một vũ trụ câu chuyện đang dần mở ra';

  @override
  String get aboutIdentityCreator => 'Người sáng tạo';

  @override
  String get aboutIdentityCreatorDesc =>
      'Tự chủ trong việc viết nên câu chuyện của chính mình';

  @override
  String get aboutIdentityWitness => 'Người chứng kiến';

  @override
  String get aboutIdentityWitnessDesc =>
      'Tham gia và xác thực câu chuyện của người khác';

  @override
  String get aboutIdentityCoCreator => 'Người đồng sáng lập';

  @override
  String get aboutIdentityCoCreatorDesc =>
      'Xây dựng cấu trúc câu chuyện và tiến hành viết lại';

  @override
  String get aboutIdentitySpreader => 'Người truyền bá';

  @override
  String get aboutIdentitySpreaderDesc =>
      'Hãy lan tỏa câu chuyện xứng đáng với bạn';

  @override
  String get aboutTokenomicsTitle => 'STORY: Token Quyền Kể Chuyện';

  @override
  String get aboutTokenomicsDesc =>
      'Trở thành đồng sản xuất phim ngắn AI, tái cấu trúc phân phối lợi nhuận trong ngành điện ảnh.';

  @override
  String get aboutTokenomicsGov => 'Quyền quản lý';

  @override
  String get aboutTokenomicsGovDesc =>
      'Hãy bỏ phiếu để quyết định chủ đề và hướng đi cho bộ phim ngắn về AI tiếp theo';

  @override
  String get aboutTokenomicsRevenue => 'Quyền hưởng lợi';

  @override
  String get aboutTokenomicsRevenueDesc =>
      'Lợi nhuận từ đăng ký nền tảng chia sẻ, cấp phép bản quyền và bán các sản phẩm liên quan';

  @override
  String get aboutTokenomicsAccess => 'Quyền truy cập';

  @override
  String get aboutTokenomicsAccessDesc =>
      'Xem trước các tập mới nhất, mở khóa nội dung độc quyền';

  @override
  String get aboutStakingTitle => 'Chia sẻ lợi nhuận từ thế chấp';

  @override
  String get aboutStakingDesc =>
      'Phim NFT · Nhân vật NFT · STORY → Cược để nhận cổ tức';

  @override
  String get aboutStakingDrama => 'Cược phim NFT';

  @override
  String get aboutStakingDramaDesc =>
      'Người sáng tạo phim ngắn · Nhận chia sẻ doanh thu';

  @override
  String get aboutStakingActor => 'Cược nhân vật NFT';

  @override
  String get aboutStakingActorDesc =>
      'Role tham gia các vở kịch ngắn · Nhận hoa hồng';

  @override
  String get aboutStakingStory => 'Cược STORY';

  @override
  String get aboutStakingStoryDesc =>
      'Đăng tải lên các video ngắn · Chia sẻ doanh thu';

  @override
  String get aboutHeroTitle => 'Tạo Câu Chuyện Của Riêng Bạn';

  @override
  String get aboutHeroDesc =>
      'Cuộc đời bạn không phải là kịch bản để trải nghiệm, mà là câu chuyện bạn đang viết';

  @override
  String get loginTitle => 'Đăng nhập bằng email';

  @override
  String get loginSubtitle =>
      'Đăng nhập qua OTP email Privy, tự động tạo ví nhúng Solana.';

  @override
  String get loginPlaceholder => 'Nhập địa chỉ email của bạn';

  @override
  String get loginEmailHintFormat => 'ban@email.com';

  @override
  String get loginVerificationFailed => 'Xác minh thất bại';

  @override
  String get loginNeedCodeFirst => 'Vui lòng yêu cầu mã xác minh trước';

  @override
  String get loginCreateWalletFailed => 'Không tạo được ví';

  @override
  String get loginGetTokenFailed => 'Không lấy được access token';

  @override
  String get loginPrivyUnavailable =>
      'Dịch vụ đăng nhập tạm thời không khả dụng. Vui lòng khởi động lại ứng dụng và thử lại';

  @override
  String get loginSendCodeFailed =>
      'Gửi mã xác minh thất bại. Vui lòng thử lại sau';

  @override
  String get loginTooManyRequests =>
      'Quá nhiều yêu cầu. Vui lòng đợi rồi thử lại';

  @override
  String get loginVerificationSuccessful => 'Xác minh thành công';

  @override
  String get loginSendCode => 'Nhận mã';

  @override
  String get loginSendingCode => 'Đang gửi...';

  @override
  String get loginCodePlaceholder => 'Nhập mã xác minh 6 chữ số';

  @override
  String get loginSubmit => 'Đăng nhập';

  @override
  String get loginSubmitting => 'Đang đăng nhập...';

  @override
  String get loginEmailRequired => 'Vui lòng nhập email';

  @override
  String get loginCodeRequired => 'Vui lòng nhập mã xác minh';

  @override
  String get loginSuccess => 'Đăng nhập thành công';

  @override
  String get loginErrorPrefix => 'Đăng nhập thất bại: ';

  @override
  String loginCodeSent(String email) {
    return 'Mã xác minh đã được gửi đến $email';
  }

  @override
  String get loginEmailLabel => 'Email';

  @override
  String get loginCodeLabel => 'Mã xác minh';

  @override
  String get loginVerifying => 'Đang xác minh, vui lòng chờ...';

  @override
  String get loginVerifyAndSubmit => 'Xác minh và Đăng nhập';

  @override
  String get loginChangeEmail => 'Đổi Email';

  @override
  String get loginNotNow => 'Không phải bây giờ';

  @override
  String get loginInvalidEmail => 'Vui lòng nhập địa chỉ email hợp lệ';

  @override
  String get profileTitle => 'Đại diện';

  @override
  String get profileNotLoggedIn => 'Chưa đăng nhập';

  @override
  String get profileClickLogin => 'Đăng nhập / Đăng ký';

  @override
  String get profileMyWallet => 'Ví của tôi';

  @override
  String get profileWallet => 'Ví';

  @override
  String get profileTradeStory => 'Giao dịch STORY';

  @override
  String get profileWalletCreating => 'Đang tạo...';

  @override
  String get walletNetworkSolana => 'Solana';

  @override
  String get walletNetworkEvm => 'EVM';

  @override
  String get profileEarnings => 'Lợi nhuận';

  @override
  String get profileMyNft => 'NFT của tôi';

  @override
  String get profileMyFavorites => 'Yêu thích';

  @override
  String get profileWatchHistory => 'Lịch sử xem';

  @override
  String get profileCreatorCatalog => 'Nhà sáng tạo';

  @override
  String get profileIdentityAuth => 'Xác minh danh tính';

  @override
  String get profileAccountSecurity => 'Bảo mật tài khoản';

  @override
  String get profileLanguage => 'Ngôn ngữ';

  @override
  String get profileAboutUs => 'Về chúng tôi';

  @override
  String get profileHelpFeedback => 'Trợ giúp & Phản hồi';

  @override
  String get profileLogout => 'Đăng xuất';

  @override
  String get profileLogoutConfirm => 'Bạn có chắc chắn muốn đăng xuất?';

  @override
  String get profileLogoutSuccess => 'Đăng xuất thành công';

  @override
  String get mainPressBackAgainToExit => 'Nhấn quay lại lần nữa để thoát';

  @override
  String get languageSelectTitle => 'Chọn ngôn ngữ';

  @override
  String get languageChinese => 'Tiếng Trung giản thể';

  @override
  String get languageEnglish => 'Tiếng Anh';

  @override
  String get searchTitle => 'Tìm kiếm';

  @override
  String get searchHint => 'Tìm phim ngắn, tác phẩm, vai, người dùng...';

  @override
  String get searchEmpty => 'Không có nội dung liên quan';

  @override
  String get searchNoData => 'Không có nội dung liên quan';

  @override
  String get searchPlaceholder => 'Tìm phim ngắn, tác phẩm, vai, người dùng...';

  @override
  String get theaterSearchPlaceholder =>
      'Tìm phim ngắn, tác phẩm, vai, người dùng...';

  @override
  String get searchHistory => 'Tìm kiếm gần đây';

  @override
  String get searchClear => 'Xóa lịch sử';

  @override
  String get searchAction => 'Tìm';

  @override
  String get searchHistoryCleared => 'Đã xóa lịch sử tìm kiếm';

  @override
  String get searchKeywordTooShort => 'Nhập ít nhất 2 ký tự';

  @override
  String get searchTabDramas => 'Phim ngắn';

  @override
  String get searchTabWorks => 'Tác phẩm';

  @override
  String get searchTabActors => 'Nhân vật IP';

  @override
  String get searchTabUsers => 'Người dùng';

  @override
  String searchEpisodeNo(int episodeNo) {
    return 'Tập $episodeNo';
  }

  @override
  String searchMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String searchHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String searchDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String searchDramasCount(int count) {
    return 'Phim ($count)';
  }

  @override
  String searchActorsCount(int count) {
    return 'Role ($count)';
  }

  @override
  String searchDramaEpisodesWithCast(int count, String actors) {
    return '$count tập | Cast: $actors';
  }

  @override
  String get nftTitle => 'Quảng trường Role NFT';

  @override
  String get nftLoading => 'Đang tải IP nhân vật...';

  @override
  String get nftEmpty => 'Không có IP nhân vật';

  @override
  String get nftRefresh => 'Làm mới';

  @override
  String nftIdPrefix(String id) {
    return 'ID: #$id';
  }

  @override
  String get nftRarity => 'Hiếm';

  @override
  String get nftStatusStaked => 'Đã được thế chấp';

  @override
  String get nftStatusIdle => 'Nhàn rỗi';

  @override
  String get nftPrice => 'Giá';

  @override
  String get dramaDetailTitle => 'Chi tiết phim';

  @override
  String get dramaDetailLoading => 'Đang tải…';

  @override
  String get dramaDetailRetry => 'Thử lại';

  @override
  String get dramaDetailEpisodeList => 'Danh sách các tập phim';

  @override
  String get dramaDetailSynopsis => 'Tóm tắt';

  @override
  String get dramaDetailExpand => 'Mở rộng';

  @override
  String get dramaDetailCollapse => 'Thu gọn';

  @override
  String get dramaDetailTabIntro => 'Giới thiệu';

  @override
  String get dramaDetailTabEpisodes => 'Tuyển tập';

  @override
  String get dramaDetailTabComments => 'Bình luận';

  @override
  String get dramaDetailTabRoles => 'IP nhân vật';

  @override
  String get dramaDetailSignMoreCharacterIps => 'Ký thêm IP nhân vật';

  @override
  String get dramaDetailCharactersEmpty => 'Chưa liên kết IP nhân vật';

  @override
  String dramaDetailRoleSalary(String amount) {
    return 'Cát-xê $amount';
  }

  @override
  String dramaDetailRoleSalaryPerHour(String amount) {
    return 'Cát-xê $amount STORY/h';
  }

  @override
  String get dramaDetailRoleUnbound => 'Chưa liên kết';

  @override
  String get dramaCastActorsTitle => 'IP nhân vật trong phim';

  @override
  String dramaDetailCompletion(String count) {
    return '$count lượt xem hết';
  }

  @override
  String dramaDetailHeat(String count) {
    return '$count độ hot';
  }

  @override
  String dramaDetailTotalEpisodes(int count) {
    return '$count tập';
  }

  @override
  String get dramaDetailRatingTitle => 'Đánh giá tác phẩm';

  @override
  String get dramaDetailWantToRate => 'Tôi muốn đánh giá';

  @override
  String get dramaDetailNotRated => 'Chưa đánh giá';

  @override
  String get dramaDetailCompletionLabel => 'Xem hết';

  @override
  String get dramaDetailHeatLabel => 'Độ hot';

  @override
  String get dramaDetailSynopsisLead => 'Tóm tắt: ';

  @override
  String get dramaDetailRatingEmpty => 'Đánh giá của bạn: --';

  @override
  String dramaDetailRatingValue(int rating) {
    return 'Đánh giá của bạn: $rating';
  }

  @override
  String get dramaDetailRatingConfirm => 'Xác nhận đánh giá';

  @override
  String dramaDetailRatingSuccess(int rating) {
    return 'Đánh giá thành công: $rating sao!';
  }

  @override
  String get dramaDetailSelectEpisodeHint => 'Chọn tập để bắt đầu phát';

  @override
  String get dramaFavorited => 'Đã thêm vào yêu thích';

  @override
  String get dramaUnfavorited => 'Đã xóa khỏi yêu thích';

  @override
  String get dramaLiked => 'Đã thích';

  @override
  String get dramaUnliked => 'Bỏ thích';

  @override
  String get playerFollowed => 'Đã theo dõi';

  @override
  String get playerUnfollowed => 'Đã bỏ theo dõi';

  @override
  String get errorNetwork => 'Lỗi mạng, vui lòng thử lại sau';

  @override
  String get errorTimeout => 'Yêu cầu đã hết thời gian, vui lòng thử lại';

  @override
  String get errorParse => 'Không thể phân tích dữ liệu phản hồi';

  @override
  String get errorUnauthorized => 'Vui lòng đăng nhập trước';

  @override
  String get authSessionExpired =>
      'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';

  @override
  String get errorNotFound => 'Không tìm thấy tài nguyên';

  @override
  String get iapOrderInFlight =>
      'Bạn có đơn hàng chưa hoàn thành cho mục này, vui lòng thử lại sau';

  @override
  String get errorOperationFailed => 'Thao tác thất bại';

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
      'ID nhân vật không hợp lệ. Vui lòng làm mới trang và thử lại.';

  @override
  String get errorInvalidRoleNftAssetId =>
      'assetId NFT nhân vật không hợp lệ. Vui lòng làm mới trang và thử lại.';

  @override
  String get errorInvalidRoleCollectionAssetId =>
      'assetId bộ sưu tập nhân vật không hợp lệ. Vui lòng làm mới trang và thử lại.';

  @override
  String get roleNftLabelUnknown => 'RoleNFT#Unknown';

  @override
  String roleNftLabel(String prefix) {
    return 'RoleNFT#$prefix';
  }

  @override
  String errorBusiness(String message) {
    return 'Thao tác thất bại: $message';
  }

  @override
  String errorUnknown(String message) {
    return 'Đã xảy ra lỗi không xác định: $message';
  }

  @override
  String errorNotSupported(String message) {
    return 'Thao tác không được hỗ trợ: $message';
  }

  @override
  String get playerEpisodeSelect => 'Tuyển tập';

  @override
  String get playerPlayFailed => 'Phát không thành công';

  @override
  String get playerDramaUnavailable => 'Không thể phát bộ phim này';

  @override
  String get playerContentUnavailable =>
      'Nội dung này chưa được phát hành hoặc không còn khả dụng';

  @override
  String get creatorWorkNotFound => 'Tác phẩm không tồn tại nên không thể xem';

  @override
  String get creatorWorkNotPublished =>
      'Tác phẩm chưa được phát hành nên hiện chưa thể xem';

  @override
  String get creatorOfflineReasonUnavailable => 'Không có lý do gỡ xuống';

  @override
  String get playerTapRetry => 'Nhấn để thử lại';

  @override
  String playerEpisodeTotal(int count) {
    return 'Tổng $count tập';
  }

  @override
  String playerEpisodeLabel(int episodeNo) {
    return 'Tập $episodeNo';
  }

  @override
  String get playerLike => 'Thích';

  @override
  String get playerComment => 'Bình luận';

  @override
  String get playerFavorite => 'Thêm vào danh sách yêu thích';

  @override
  String get playerShare => 'Chia sẻ';

  @override
  String playerShareDramaEpisode(
    String title,
    int episodeNo,
    String description,
    String url,
  ) {
    return '$title | Tập $episodeNo: $description $url . Xem phim ngắn AI đẹp trên StoryFun.';
  }

  @override
  String playerShareDramaEpisodeNoDesc(
    String title,
    int episodeNo,
    String url,
  ) {
    return '$title | Tập $episodeNo $url . Xem phim ngắn AI đẹp trên StoryFun.';
  }

  @override
  String playerShareShortVideo(String description, String url) {
    return '$description $url. Xem video ngắn đẹp trên StoryFun.';
  }

  @override
  String playerShareShortVideoNoDesc(String url) {
    return '$url. Xem video ngắn đẹp trên StoryFun.';
  }

  @override
  String playerShareDrama(String title, String url) {
    return '$title $url . Xem phim ngắn AI đẹp trên StoryFun.';
  }

  @override
  String playerShareDramaNoTitle(String url) {
    return '$url . Xem phim ngắn AI đẹp trên StoryFun.';
  }

  @override
  String playerRatingLabel(String rating) {
    return '$rating điểm';
  }

  @override
  String get loginOrSignUp => 'Đăng nhập hoặc Đăng ký';

  @override
  String get loginEnterCode => 'Nhập mã xác nhận';

  @override
  String loginCheckEmailDesc(String email) {
    return 'Vui lòng kiểm tra $email để tìm email từ privy.io và nhập mã bên dưới.';
  }

  @override
  String loginResendCountdown(int seconds) {
    return 'Gửi lại mã sau ${seconds}s';
  }

  @override
  String get loginResendBtn => 'Gửi lại';

  @override
  String get loginProtectedByPrivy => 'Được bảo vệ bởi Privy';

  @override
  String get loginAgreeLead => 'Tôi đã đồng ý với';

  @override
  String get loginAgreeAnd => 'và';

  @override
  String get loginAgreeConfirmLead => 'Nhấn Xác nhận nghĩa là bạn đồng ý với';

  @override
  String get loginAgreeRequired =>
      'Vui lòng đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư trước';

  @override
  String get deletingAccountPending => 'Tài khoản đang chờ xóa';

  @override
  String get deletingAccountCancelDeletion => 'Hủy xóa tài khoản';

  @override
  String get deletingAccountGoBack => 'Quay lại';

  @override
  String get drawerEmailAccount => 'Tài khoản email';

  @override
  String get drawerClickToLogin => 'Nhấn để đăng nhập';

  @override
  String get drawerBuyStory => 'Giao dịch STORY';

  @override
  String get drawerDeposit => 'Nạp tiền';

  @override
  String get drawerWithdraw => 'Rút tiền';

  @override
  String get drawerNotifications => 'Thông báo';

  @override
  String get drawerNoNotifications => 'Không có thông báo';

  @override
  String get notificationTabSystem => 'Hệ thống';

  @override
  String get notificationTabInteraction => 'Tương tác';

  @override
  String get notificationTagIpSign => 'Ký IP nhân vật';

  @override
  String get notificationTagRoleManagement => 'Quản lý nhân vật';

  @override
  String get notificationTagShowRevenue => 'Thu nhập biểu diễn';

  @override
  String get notificationTagLike => 'Thích';

  @override
  String get notificationTagFavorite => 'Yêu thích';

  @override
  String notificationSignedActor(String user, String actor) {
    return '@$user đã ký IP nhân vật $actor';
  }

  @override
  String notificationShareEarned(String amount) {
    return 'Bạn nhận được phần chia $amount';
  }

  @override
  String notificationStaminaLow(String actor) {
    return '$actor đã hết thể lực. Hãy bổ sung hoặc cho nghỉ';
  }

  @override
  String notificationCurrentStamina(String value) {
    return 'Thể lực hiện tại $value';
  }

  @override
  String notificationShowEnded(String range) {
    return 'Buổi diễn $range đã kết thúc';
  }

  @override
  String notificationIncomeEarned(String amount) {
    return 'Bạn nhận được $amount';
  }

  @override
  String get notificationActionClaim => 'Nhận';

  @override
  String get notificationActionRefill => 'Bổ sung';

  @override
  String get notificationInteractionLikedVideo => 'Đã thích video của bạn';

  @override
  String notificationInteractionLikedDrama(String title) {
    return 'Đã thích phim ngắn “$title” của bạn';
  }

  @override
  String get notificationInteractionFavoritedVideo => 'Đã lưu video của bạn';

  @override
  String notificationInteractionFavoritedDrama(String title) {
    return 'Đã lưu phim ngắn “$title” của bạn';
  }

  @override
  String notificationInteractionCommented(String content) {
    return 'Đã bình luận: $content';
  }

  @override
  String get notificationInteractionFollowedYou => 'Đã theo dõi bạn';

  @override
  String get notificationActionMutualFollow => 'Theo dõi nhau';

  @override
  String get notificationActionFollow => 'Theo dõi';

  @override
  String get notificationDelete => 'Xóa';

  @override
  String get notificationDeleteFailed =>
      'Xóa không thành công. Vui lòng thử lại sau';

  @override
  String get notificationRealtimeReceived => 'Bạn có một thông báo mới';

  @override
  String drawerEpisodeProgress(int current, int total) {
    return '$current/$total tập';
  }

  @override
  String drawerNotificationSignedActor(String actor, String target) {
    return '$actor đã ký IP nhân vật $target';
  }

  @override
  String drawerNotificationLikedVideo(String actor) {
    return '$actor đã thích video của bạn';
  }

  @override
  String drawerNotificationFavoritedDrama(String actor, String target) {
    return '$actor đã lưu phim ngắn $target của bạn';
  }

  @override
  String get depositTitle => 'Nạp tiền';

  @override
  String get insufficientBalanceTitle => 'Số dư không đủ';

  @override
  String insufficientBalanceDetail(String currency, String amount) {
    return 'Số dư $currency không đủ, bạn còn thiếu $amount $currency';
  }

  @override
  String get insufficientBalancePrompt => 'Chuyển đến nạp tiền?';

  @override
  String get insufficientBalanceRecharge => 'Nạp tiền';

  @override
  String get depositDesc =>
      'Vui lòng chuyển token từ sàn giao dịch hoặc ví khác đến địa chỉ bên dưới. Số dư sẽ tự động cập nhật sau khi ghi nhận vào tài khoản.';

  @override
  String get depositToken => 'Token';

  @override
  String get depositNetwork => 'Mạng';

  @override
  String get depositNetworkNote =>
      'Vui lòng xác nhận mạng chuyển khoản. Sai mạng có thể dẫn đến mất tài sản.';

  @override
  String get depositAddress => 'Địa chỉ nạp tiền';

  @override
  String get depositAddressCopied => 'Đã sao chép địa chỉ vào bộ nhớ tạm';

  @override
  String get depositSend => 'Gửi';

  @override
  String get depositReceive => 'Nhận';

  @override
  String get depositConvertNote =>
      'Gửi token đến địa chỉ này, chúng sẽ được tự động quy đổi thành USDC trong tài khoản Story.fun của bạn.';

  @override
  String depositMinNote(String minAmount, String token) {
    return 'Số tiền nạp tối thiểu: $minAmount $token';
  }

  @override
  String depositExchangeRateNote(String rate) {
    return 'Tỷ giá hiện tại là $rate. Số tiền thực nhận = số tiền nạp × $rate';
  }

  @override
  String get depositWarning =>
      'Chỉ nạp token đã chọn trên mạng đã chọn. Tài sản khác không thể khôi phục.\nVui lòng xác nhận mạng chuyển; lỗi mạng có thể dẫn đến mất tài sản.';

  @override
  String get withdrawTitle => 'Rút tiền';

  @override
  String get withdrawBalance => 'Số dư có thể rút';

  @override
  String get withdrawToken => 'Token';

  @override
  String get withdrawAddress => 'Địa chỉ rút tiền';

  @override
  String get withdrawAddressHint =>
      'Vui lòng nhập hoặc dán địa chỉ người nhận Solana';

  @override
  String get withdrawAddressHintEvm =>
      'Vui lòng nhập hoặc dán địa chỉ nhận EVM';

  @override
  String get withdrawInvalidEvmAddress => 'Vui lòng nhập địa chỉ EVM hợp lệ';

  @override
  String get withdrawInvalidSolanaAddress =>
      'Vui lòng nhập địa chỉ Solana hợp lệ';

  @override
  String get withdrawEvmGasNote =>
      'Rút EVM cần đủ token gốc để trả gas. Giao dịch được gửi trực tiếp trên chuỗi.';

  @override
  String get withdrawEvmFailed => 'Rút EVM thất bại. Vui lòng thử lại sau.';

  @override
  String get withdrawAddressNote =>
      'Vui lòng kiểm tra lại địa chỉ đã chính xác chưa, vì sau khi chuyển khoản sẽ không thể hủy lại được';

  @override
  String get withdrawNetwork => 'Mạng';

  @override
  String get withdrawAmount => 'Số tiền';

  @override
  String get withdrawAmountHint => 'Nhập số tiền rút';

  @override
  String get withdrawMax => 'Tối đa';

  @override
  String withdrawAvailableBalance(String balance, String token) {
    return 'Số dư $balance $token';
  }

  @override
  String withdrawMinWarning(String minAmount, String token) {
    return 'Rút tối thiểu: $minAmount $token\nVui lòng kiểm tra kỹ địa chỉ và mạng; giao dịch không thể hoàn tác.';
  }

  @override
  String get withdrawConfirm => 'Xác nhận rút tiền';

  @override
  String get withdrawAll => 'Tất cả';

  @override
  String withdrawMinAmountError(String minAmt, String token) {
    return 'Số tiền rút tối thiểu là $minAmt $token';
  }

  @override
  String get withdrawExceedBalanceError =>
      'Số tiền rút không được vượt quá số dư khả dụng';

  @override
  String get withdrawSameAsWalletError =>
      'Địa chỉ rút tiền không được trùng với địa chỉ ví hiện tại';

  @override
  String get withdrawConfirmTitle => 'Xác nhận rút tiền';

  @override
  String withdrawConfirmMessage(String amount, String token, String address) {
    return 'Bạn có chắc muốn rút $amount $token đến địa chỉ Solana sau không?\n\n$address';
  }

  @override
  String get withdrawSuccessToast => 'Yêu cầu rút tiền đã được gửi thành công!';

  @override
  String get withdrawFailedToast => 'Rút tiền thất bại. Vui lòng thử lại.';

  @override
  String withdrawErrorToast(String error) {
    return 'Đã xảy ra lỗi khi rút tiền: $error';
  }

  @override
  String withdrawAddressHintWithToken(String token) {
    return 'Nhập địa chỉ ví nhận $token';
  }

  @override
  String get withdrawFee => 'Phí dịch vụ';

  @override
  String withdrawFeeValue(String fee, String token) {
    return '$fee $token';
  }

  @override
  String withdrawMinAmount(String minAmount, String token) {
    return 'Rút tối thiểu: $minAmount $token';
  }

  @override
  String withdrawMaxAmount(String maxAmount, String token) {
    return 'Số tiền rút tối đa: $maxAmount $token';
  }

  @override
  String get withdrawSponsorSigning => 'Đang ký giao dịch...';

  @override
  String get withdrawSponsorSubmitting => 'Đang gửi giao dịch trên chuỗi...';

  @override
  String get withdrawSponsorSuccess => 'Rút tiền đã được gửi thành công!';

  @override
  String get withdrawSponsorFailed =>
      'Gửi giao dịch thất bại. Vui lòng thử lại.';

  @override
  String get withdrawOrderProcessing => 'Đang xử lý đơn hàng';

  @override
  String get withdrawOrderSuccess => 'Đơn hàng hoàn thành';

  @override
  String get withdrawOrderFailed => 'Đơn hàng thất bại';

  @override
  String withdrawOrderStatus(String status) {
    return 'Trạng thái đơn hàng: $status';
  }

  @override
  String get qrScannerTitle => 'Quét mã QR';

  @override
  String get qrScannerHint => 'Canh chỉnh mã QR trong khung để quét';

  @override
  String get drawerProfile => 'Trang cá nhân';

  @override
  String get drawerCreatorManagement => 'Quản lý sáng tạo';

  @override
  String get drawerInvite => 'Lời mời';

  @override
  String get inviteTitle => 'Mời bạn bè';

  @override
  String get inviteTotalPeople => 'Tổng số người được mời';

  @override
  String get inviteTotalRewards => 'Tổng phần thưởng mời';

  @override
  String get inviteWeeklyPool => 'Quỹ thưởng mời tham gia tuần này';

  @override
  String get inviteViewHistory => 'Xem lịch sử thu nhập';

  @override
  String get inviteShareSection => 'Chia sẻ liên kết mời hoặc mã mời của bạn';

  @override
  String get inviteLinkSection => 'Liên kết mời';

  @override
  String get inviteLinkSubtitle =>
      'Khi bạn bè đăng ký qua liên kết của bạn, ký và điều động nhân vật, bạn sẽ nhận được phần thưởng STORY bổ sung.';

  @override
  String get inviteCodeLabel => 'Mã mời';

  @override
  String get inviteCopyButton => 'Sao chép liên kết';

  @override
  String get inviteCopiedSuccess => 'Đã sao chép liên kết mời vào bộ nhớ tạm!';

  @override
  String get inviteCodeCopiedSuccess => 'Đã sao chép mã mời vào bộ nhớ tạm!';

  @override
  String get inviteInvitedLabel => 'Đã mời';

  @override
  String get inviteRewardLabel => 'Phần thưởng';

  @override
  String get inviteBindCode => 'Liên kết mã mời';

  @override
  String get inviteBindCodePromptHint =>
      'Bạn có thể liên kết sau trong trang Mời';

  @override
  String get inviteBindCodePlaceholder => 'Nhập mã mời';

  @override
  String get inviteBindConfirm => 'Xác nhận';

  @override
  String get inviteBindSuccess => 'Liên kết mã mời thành công';

  @override
  String get inviteBindCodeInvalid => 'Mã mời không hợp lệ';

  @override
  String get inviteBindCodeAlreadyBound => 'Tài khoản này đã liên kết mã mời';

  @override
  String get inviteRulesSection => 'Quy định về việc mời';

  @override
  String get inviteFaqPoolTitle => 'Quỹ thưởng mời hàng tuần là gì?';

  @override
  String get inviteFaqPoolBody =>
      'Quỹ thưởng mời hàng tuần là quỹ thưởng độc lập dành cho hoạt động mời. Nó thưởng cho hành vi mời trong tuần hiện tại và không bị trừ từ thu nhập của người được mời. Quỹ có hạn mức chi trả hàng tuần; khi đạt hạn mức, phần thưởng sẽ được giảm theo tỷ lệ sở hữu. Thống kê được thiết lập lại vào thứ Hai hàng tuần.';

  @override
  String get inviteFaqSettlementTitle =>
      'Phần thưởng mời được quyết toán khi nào?';

  @override
  String get inviteFaqSettlementBody =>
      'Phần thưởng mời được quyết toán cùng chu kỳ với thù lao trên trang môi giới: thống kê chốt vào 00:00 (UTC) mỗi thứ Hai. Sau khi quyết toán, bạn có thể nhận trên trang Thu nhập.';

  @override
  String get inviteRuleSourceTitle => 'Nguồn thưởng';

  @override
  String get inviteRuleSourceSubtitle => 'Hồ con được mời độc lập';

  @override
  String get inviteRuleSourceBody =>
      'Phần thưởng giới thiệu đến từ một nhóm con giới thiệu độc lập trong nhóm khai thác NFT (chiếm 25% tổng nhóm khai thác), và không bị khấu trừ từ thu nhập của người được giới thiệu. Nhóm con giới thiệu này có mức trần hàng tuần riêng biệt; khi đạt đến mức trần, phần thưởng sẽ được giảm theo tỷ lệ tương ứng với tỷ lệ sở hữu.';

  @override
  String get inviteRuleBaseTitle => 'Cơ sở tính toán';

  @override
  String get inviteRuleBaseSubtitle => 'Theo thực tế STORY';

  @override
  String get inviteRuleBaseBody =>
      'Phần thưởng được tính dựa trên số STORY mà người được mời thực tế nhận được trong kỳ này, chứ không tính theo sản lượng danh nghĩa. Số STORY mà người được mời tự khai thác sẽ không bị ảnh hưởng; phần thưởng giới thiệu sẽ được trao thêm.';

  @override
  String get inviteRuleLevelTitle => 'Phạm vi phần thưởng';

  @override
  String get inviteRuleLevelSubtitle => 'Chỉ lời mời trực tiếp';

  @override
  String get inviteRuleLevelBody =>
      'Phần thưởng mời chỉ được trả cho người dùng bạn mời trực tiếp. Không có hoa hồng nhiều cấp hoặc gián tiếp.';

  @override
  String get inviteRuleConditionTitle => 'Điều kiện có hiệu lực';

  @override
  String get inviteRuleConditionSubtitle =>
      'Chỉ khi người dùng ngừng hoạt động một cách hợp lệ thì mới nhận được phần thưởng';

  @override
  String inviteRuleConditionBody(String currency) {
    return 'Người được mời chỉ được tính là thành viên cấp dưới hợp lệ khi thực sự đã khai thác được STORY hoặc đã thực hiện giao dịch thanh toán bằng $currency. Việc đăng ký bằng số điện thoại ảo sẽ không mang lại phần thưởng. Mối quan hệ giới thiệu một khi đã được thiết lập sẽ không thể thay đổi.';
  }

  @override
  String get drawerTxHistory => 'Lịch sử giao dịch';

  @override
  String get drawerFinanceDashboard => 'Bảng Tài chính';

  @override
  String get financeDashboardComingSoon =>
      'Bảng Tài chính sắp ra mắt. Hãy chờ đón.';

  @override
  String get financeDashboardPageTitle => 'Bảng tài chính nền tảng';

  @override
  String financeDashboardTotalUsdcIncome(String currency) {
    return 'Tổng thu nhập USDC';
  }

  @override
  String get financeDashboardTotalStoryReleased => 'Tổng STORY đã phân phối';

  @override
  String financeDashboardTabUsdcIncome(String currency) {
    return 'Chi tiết thu nhập USDC';
  }

  @override
  String get financeDashboardTabVaultFunds => 'Tích lũy quỹ kho';

  @override
  String get financeDashboardTabStoryRelease => 'Tổng quan phân phối STORY';

  @override
  String get financeDashboardFeeMint => 'Phí ký hợp đồng';

  @override
  String get financeDashboardFeeRoyalty => 'Tiền bản quyền thứ cấp';

  @override
  String get financeDashboardFeeItemPurchase => 'Mua vật phẩm';

  @override
  String get financeDashboardFeeTx => 'Phí giao dịch';

  @override
  String get financeDashboardLedgerBizSigningFee => 'Phí ký';

  @override
  String get financeDashboardLedgerBizManualCredit => 'Cộng tiền thủ công';

  @override
  String get financeDashboardLedgerBizManualDebit => 'Trừ tiền thủ công';

  @override
  String get financeDashboardLedgerBizStaminaPurchase => 'Phí mua thể lực';

  @override
  String get financeDashboardLedgerBizSynthesisUpgrade =>
      'Phí nâng cấp hợp thành';

  @override
  String get financeDashboardLedgerBizTransactionFee => 'Phí giao dịch';

  @override
  String financeDashboardRecentUsdcLedger(String currency) {
    return 'Thu nhập USDC gần đây';
  }

  @override
  String get financeDashboardViewMore => 'Xem thêm';

  @override
  String get financeDashboardTotalVaultFunds => 'Tổng quỹ kho';

  @override
  String get financeDashboardCoveredActorIp => 'IP nhân vật được hỗ trợ';

  @override
  String get financeDashboardActorVaultRanking => 'Xếp hạng kho IP nhân vật';

  @override
  String get storyReleaseTabAllocation => 'Phân bổ tổng STORY';

  @override
  String get storyReleaseTabMiningRelease => 'Phân phối khai thác gần đây';

  @override
  String get storyReleaseFieldPeriod => 'Chu kỳ';

  @override
  String get storyReleaseFieldHardLimit => 'Trần cứng theo tuần';

  @override
  String get storyReleaseFieldMiningRewards => 'Khai thác staking';

  @override
  String get storyReleaseFieldInviteRewards => 'Khai thác qua lời mời';

  @override
  String get storyReleaseFieldUsageRate => 'Tỷ lệ sử dụng';

  @override
  String get storyReleaseFieldTarget => 'Đối tượng phân bổ';

  @override
  String get storyReleaseFieldRatio => 'Tỷ lệ';

  @override
  String get storyReleaseFieldAmount => 'Số lượng';

  @override
  String get storyReleaseFieldReleased => 'Đã phân phối';

  @override
  String get storyReleaseFieldProgress => 'Tiến độ phân phối';

  @override
  String get storyReleaseCategoryNftMiningPool => 'Quỹ khai thác NFT';

  @override
  String get storyReleaseCategoryTeam => 'Đội ngũ';

  @override
  String get storyReleaseCategoryInvestors => 'Nhà đầu tư';

  @override
  String get storyReleaseCategoryLiquidity => 'Launchpad + Thanh khoản';

  @override
  String get storyReleaseCategoryTreasury => 'Kho bạc';

  @override
  String get storyReleaseCategoryMarketOps => 'Vận hành thị trường';

  @override
  String storyReleaseTotalSupplyBadge(String total) {
    return 'Tổng $total STORY';
  }

  @override
  String get drawerWhitepaper => 'Sách trắng';

  @override
  String get drawerSettings => 'Cài đặt';

  @override
  String get commonClose => 'Đóng';

  @override
  String get commonDelete => 'Xóa';

  @override
  String get commonLoadFailed => 'Không tải được';

  @override
  String get commonNone => 'Không có';

  @override
  String get commonUntitled => 'Không có tiêu đề';

  @override
  String get actorDetailTitle => 'Trang diễn viên';

  @override
  String get actorDetailCastDramas => 'Tham gia diễn xuất trong vở kịch ngắn';

  @override
  String get actorDetailTabCast => 'Tham gia';

  @override
  String get actorDetailTabInfo => 'Thông tin';

  @override
  String get actorDetailNoCastRecords => 'Chưa có lịch sử đóng phim';

  @override
  String get actorBondingCurve => 'Đường cong giá tổng hợp';

  @override
  String get actorContractAddress => 'Địa chỉ hợp đồng';

  @override
  String get actorCurrentPosition => 'Vị trí hiện tại';

  @override
  String actorCurrentPrice(String price, String currency) {
    return 'Giá hiện tại $price $currency';
  }

  @override
  String get actorFloorPrice => 'Giá sàn';

  @override
  String get actorGoTrade => 'Giao dịch';

  @override
  String get profileWalletTrade => 'Giao dịch';

  @override
  String get actorHeatCoefficient => 'Hệ số độ hot';

  @override
  String get actorIpPower => 'Cát-xê IP';

  @override
  String get actorPayMax => 'Tối đa';

  @override
  String get actorPayUpgradeTitle => 'Quy tắc nâng cát-xê';

  @override
  String get actorPayUpgradeReachHint =>
      'Số lượt xem hết hiện tại của phim ngắn IP này tham gia có thể hỗ trợ nâng cấp vai lên';

  @override
  String actorPayUpgradeCompletions(String count) {
    return '$count lượt xem hết';
  }

  @override
  String actorPayUpgradeMultiplier(String value) {
    return 'Cát-xê ×$value';
  }

  @override
  String actorPayTitle(String name) {
    return '$name · Cát-xê';
  }

  @override
  String get actorLv1PayHint => 'Ký để nhận nhân vật Lv.1';

  @override
  String get actorLv1PayFormula => 'Cát-xê Lv.1 = Hệ số giá × Hệ số độ hot';

  @override
  String actorLv1PayEquals(String value) {
    return '=$value';
  }

  @override
  String actorIpPowerTitle(String name) {
    return '$name · Cát-xê IP';
  }

  @override
  String get actorIpPowerFormula =>
      'Cát-xê IP = Hệ số giá × Hệ số độ hot × Trust1';

  @override
  String get actorPriceCoefficient => 'Hệ số giá';

  @override
  String actorPriceCoefficientValue(String value) {
    return 'Hệ số giá $value';
  }

  @override
  String get actorPriceCoefficientHelpA11y => 'Xem giải thích hệ số giá';

  @override
  String get actorPriceUnitName => 'Điểm';

  @override
  String get actorPriceCoefficientDialogFormulaLe100 => 'Hệ số = P0 ÷ 10';

  @override
  String get actorPriceCoefficientDialogDescLe100 => 'Tăng tuyến tính';

  @override
  String actorPriceCoefficientDialogTitleGt100(String currency) {
    return 'P0 > 10 $currency';
  }

  @override
  String get actorPriceCoefficientDialogFormulaGt100 =>
      'Hệ số = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]';

  @override
  String get actorPriceCoefficientDialogDescGt100 =>
      'Tăng chậm dần, giới hạn trên 1.6';

  @override
  String actorPriceCoefficientDialogTitleLe100(String currency) {
    return 'P0 ≤ 10 $currency';
  }

  @override
  String actorPriceCoefficientFactorDesc(String currency1, String currency2) {
    return 'P0 ≤ 10 $currency1 hệ số = P0/10 (tăng tuyến tính)\nP0 > 10 $currency2 → hệ số = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6] (giới hạn tiệm cận 1.6)';
  }

  @override
  String get actorHeatCoefficientFactorDesc =>
      'Hệ số nhân độ hot 30 ngày gần nhất của IP nhân vật, dựa trên các tương tác như xem hết phim ngắn, lượt thích, lượt lưu';

  @override
  String get actorTrustFactorDesc =>
      'Hệ số kiểm soát rủi ro của nền tảng, mặc định là 1.0';

  @override
  String get actorStatCompletion => 'Xem hết';

  @override
  String get actorIdCopied => 'Mã số đã được sao chép';

  @override
  String actorInitialPrice(String price, String currency) {
    return 'Giá ban đầu: $price $currency';
  }

  @override
  String actorIpLabel(String label) {
    return 'Nhân vật IP $label';
  }

  @override
  String get actorIssueInfo => 'Thông tin ra mắt';

  @override
  String actorIssuer(String name) {
    return 'Người ra mắt $name';
  }

  @override
  String actorMintedCount(int minted, int maxSupply) {
    return 'Đã đúc $minted/$maxSupply';
  }

  @override
  String get actorPriceCurve => 'Đường cong giá';

  @override
  String get actorSign => 'Ký';

  @override
  String get actorConfirmSign => 'Xác nhận ký';

  @override
  String get actorSignPriceLabel => 'Giá ký';

  @override
  String get actorSignPriceDescription =>
      'Giá ký tự động tăng theo số lượng đã ký; ký sớm sẽ được giá ưu đãi hơn.';

  @override
  String get actorSignPriceFormula =>
      'Công thức: Giá = Giá ban đầu × 5^(Số lượng đã ký ÷ Tổng lượng phát hành)';

  @override
  String actorPriceAxisLabel(String currency) {
    return 'Giá ($currency)';
  }

  @override
  String get actorSignedCountAxisLabel => 'Số lượng đã ký';

  @override
  String actorSignRemainingCount(int count) {
    return 'Còn lại $count cái';
  }

  @override
  String get actorSignSoldOut => 'Đã bán hết';

  @override
  String actorSignSupplySummary(String total, String remaining) {
    return 'Tổng phát hành $total · Còn lại $remaining';
  }

  @override
  String get actorPricingFixed => 'Giá cố định';

  @override
  String get actorPricingCurve => 'Giá đường cong';

  @override
  String get actorPriceCurveDisclaimer =>
      'Giá ban đầu không phản ánh mức định giá của nền tảng; sự tăng trưởng trên biểu đồ không đồng nghĩa với việc giá trên thị trường thứ cấp tăng; nền tảng không cam kết mang lại lợi nhuận.';

  @override
  String get actorPriceStatInitialPrice => 'Giá ban đầu';

  @override
  String get actorPriceStatCurrentPrice => 'Giá hiện tại';

  @override
  String get actorPriceStatTailPrice => 'Giá chốt';

  @override
  String get actorPriceStatTotalSupply => 'Tổng phát hành';

  @override
  String get actorPriceStatSigned => 'Đã ký';

  @override
  String get actorPriceStatRemaining => 'Còn lại';

  @override
  String get actorPricingType => 'Loại định giá';

  @override
  String get contentBadgeOfficialIssue => 'Ra mắt chính thức';

  @override
  String get contentBadgeCommunityIssue => 'Ra mắt cộng đồng';

  @override
  String get contentBadgePartnerIssue => 'Ra mắt bởi đối tác';

  @override
  String get contentBadgeVerifiedIssue => 'Ra mắt bởi tác giả đã xác thực';

  @override
  String get contentBadgeOfficialDrama => 'Phim ngắn chính thức';

  @override
  String get contentBadgeCommunityDrama => 'Phim ngắn cộng đồng';

  @override
  String get contentBadgePartnerDrama => 'Phim ngắn hợp tác';

  @override
  String get contentBadgeVerifiedDrama =>
      'Các video ngắn của các nhà sáng tạo đã được xác thực';

  @override
  String get actorIpCopied => 'Sao chép thành công';

  @override
  String get actorRiskIp => 'IP rủi ro';

  @override
  String get actorRiskIpDescription =>
      'Nhân vật IP này có hệ số trust bất thường; trọng số khai thác sẽ bị ảnh hưởng.';

  @override
  String get actorIpVault => 'Kho IP nhân vật';

  @override
  String get actorIpVaultDescription =>
      '30% doanh thu ký được tự động chuyển vào Kho IP của nhân vật, nhằm hỗ trợ sự phát triển lâu dài của hệ sinh thái IP. 30% doanh thu từ tiền bản quyền trên thị trường thứ cấp cũng được chuyển vào Kho này, tạo thành nguồn vốn dự trữ bền vững. Kho trong phiên bản V1 hiện chỉ cung cấp chức năng hiển thị dữ liệu và chưa mở chức năng phân phối.';

  @override
  String get actorIpVaultSignIncomePrefix => 'Doanh thu ký · Tích lũy ';

  @override
  String get actorIpVaultSecondaryRoyaltyPrefix =>
      'Tiền bản quyền cấp hai · Tích lũy ';

  @override
  String get actorFixedPriceDialogDesc =>
      'Mô hình IP nhân vật này áp dụng cơ chế giá cố định, mỗi nhân vật đều ký với mức giá thống nhất, và biến động doanh số không ảnh hưởng đến giá';

  @override
  String get actorCurvePriceDialogDesc =>
      'Giá tự động tăng theo công thức đường cong kết hợp dựa trên số lượng đã ký; ký sớm sẽ được giá ưu đãi hơn';

  @override
  String get actorFixedPriceNote1 =>
      'Sau khi người ra mắt đặt giá cố định, mọi giao dịch ký đều được thanh toán theo mức giá này.';

  @override
  String get actorFixedPriceNote2 =>
      'Giá sẽ không tăng dù số lượng đã ký có tăng lên';

  @override
  String get actorFixedPriceNote3 =>
      'Phù hợp với những người mua muốn kiểm soát chi phí';

  @override
  String get actorIssueFixedPriceDesc =>
      'IP của nhân vật này áp dụng mô hình giá cố định; tất cả các giao dịch ký đều được thanh toán theo mức giá cố định, không thay đổi theo doanh số bán hàng.';

  @override
  String get actorSignSlippageNote =>
      'Chức năng bảo vệ chênh lệch giá 1% đã được kích hoạt; giao dịch sẽ bị hủy nếu giá vượt quá mức này';

  @override
  String get actorSignSuccessTitle => 'Đã ký thành công!';

  @override
  String actorSignSuccessMessage(String name) {
    return 'Đã ký thành công nhân vật 「$name」';
  }

  @override
  String actorSignSuccessNftId(String nftId) {
    return 'Mã NFT: $nftId';
  }

  @override
  String get actorSignChainConfigMissing =>
      'Cấu trúc trên chuỗi chưa hoàn chỉnh. Vui lòng thử lại sau.';

  @override
  String get actorSignPriceSoldOut => 'Giá ký · Đã bán hết';

  @override
  String actorSignPriceRemaining(int count) {
    return 'Giá ký · Còn lại $count';
  }

  @override
  String actorSignedCount(int count) {
    return 'Đã ký hợp đồng $count';
  }

  @override
  String get actorStatusLabelOffline => 'Ngoại tuyến';

  @override
  String get actorStatusLabelOnline => 'Trực tuyến';

  @override
  String get actorStatusLabelPending => 'Đang được xem xét';

  @override
  String get actorStatusLabelRejected => 'Bị từ chối';

  @override
  String get actorTotalSupply => 'Tổng phát hành';

  @override
  String get commentsAnonymous => 'Người dùng ẩn danh';

  @override
  String get commentsEmpty => 'Chưa có bình luận';

  @override
  String get commentsHint => 'Đăng bình luận hay...';

  @override
  String get commentsInvalidContent => 'Vui lòng nhập nội dung hợp lệ';

  @override
  String get commentsReply => 'Trả lời';

  @override
  String commentsViewReplies(int count) {
    return 'Xem $count trả lời';
  }

  @override
  String get commentsCollapseReplies => 'Thu gọn';

  @override
  String get commentsViewMoreReplies => 'Xem thêm';

  @override
  String commentsReplyHint(String nickname) {
    return 'Trả lời $nickname';
  }

  @override
  String get commentsDeleteCommentTitle => 'Xóa bình luận này?';

  @override
  String get commentsDeleteReplyTitle => 'Xóa trả lời này?';

  @override
  String get commentTagAuthor => 'Tác giả';

  @override
  String get commentTagMe => 'Tôi';

  @override
  String get commentTagFriend => 'Bạn của bạn';

  @override
  String get commentTagFan => 'Người theo dõi của bạn';

  @override
  String get commentTagFirst => 'Bình luận đầu tiên';

  @override
  String get commentTagAuthorLiked => 'Tác giả đã thích';

  @override
  String commentsReplyTo(String nickname) {
    return 'Trả lời @$nickname: ';
  }

  @override
  String get commentsReplyCommentNotExists => 'Bình luận không tồn tại';

  @override
  String get commentsBlockedByMe =>
      'Người dùng nằm trong danh sách đen, bạn không thể bình luận';

  @override
  String get commentsBlockedByTarget =>
      'Do cài đặt của người đó, bạn không thể bình luận';

  @override
  String get commentsTabComments => 'Bình luận';

  @override
  String get commentsTabAllComments => 'Tất cả bình luận';

  @override
  String get commentsTabDramas => 'Phim ngắn';

  @override
  String get commentsTabActors => 'Nhân vật';

  @override
  String get timeJustNow => 'vừa xong';

  @override
  String get timeYesterday => 'hôm qua';

  @override
  String get timeDayBeforeYesterday => 'hôm kia';

  @override
  String timeMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String commentsTitle(int count) {
    return 'Bình luận ($count)';
  }

  @override
  String get createActorTitle => 'Tạo role';

  @override
  String get createActorHeroTitle => 'Đúc NFT nhân vật';

  @override
  String get createActorHeroSubtitle =>
      'Tạo role AI độc quyền, liên kết chia sẻ lợi nhuận để tham gia phim';

  @override
  String get createActorNameLabel => 'Tên role';

  @override
  String get createActorNameHint => 'Nhập tên role';

  @override
  String get createActorBioLabel => 'Tiểu sử role';

  @override
  String get createActorBioHint => 'Mô tả nền tảng nhân vật';

  @override
  String get createActorGenderLabel => 'Giới tính';

  @override
  String get createActorGenderMale => 'Nam';

  @override
  String get createActorGenderFemale => 'Nữ';

  @override
  String get createActorMintParams => 'Tham số đúc NFT';

  @override
  String get createActorTokenStandard => 'Tiêu chuẩn Token';

  @override
  String get createActorChain => 'Chuỗi';

  @override
  String get createActorMinHolding => 'Sở hữu tối thiểu';

  @override
  String get createActorMintNft => 'Đúc NFT';

  @override
  String get createActorIpTitle => 'Ra mắt IP nhân vật';

  @override
  String get createActorIpSubtitle =>
      'Sau khi ra mắt một IP nhân vật, bạn có thể ký các nhân vật thuộc IP đó, và các nhân vật này có thể được điều động để tạo doanh thu.';

  @override
  String get createActorSelectMaterial => 'Chọn tài liệu về role';

  @override
  String get createActorDreamOsBadge => 'Đến DreamOS';

  @override
  String get createActorSelectMaterialDesc =>
      'Vào dự án DreamOS → Tạo nhân vật → Vào Story.fun để phát hành IP';

  @override
  String get createActorSelectButton => 'Chọn role';

  @override
  String get createActorNameLabelNew => 'Tên role';

  @override
  String get createActorNamePlaceholder => 'Nhập tên role';

  @override
  String get createActorBioLabelNew => 'Giới thiệu';

  @override
  String get createActorBioPlaceholder =>
      'Vui lòng nhập phần giới thiệu về Nhân vật IP';

  @override
  String get createActorParamsTitle => 'Thông số ra mắt IP nhân vật';

  @override
  String get createActorParamsSubtitle =>
      'Đặt thông số ra mắt IP nhân vật. Không thể thay đổi sau khi ra mắt.';

  @override
  String get createActorTotalSupplyLabel => 'Tổng phát hành nhân vật';

  @override
  String get createActorTotalSupplyDesc =>
      'Phạm vi tổng phát hành: 100 - 5.000.';

  @override
  String get createActorTotalSupplyPlaceholder => '100 - 5,000';

  @override
  String get createActorPricingFixed => 'Giá cố định';

  @override
  String get createActorPricingCurve => 'Giá đường cong';

  @override
  String createActorFixedPriceLabel(String currency) {
    return 'Giá cố định ($currency)';
  }

  @override
  String createActorInitialPriceLabel(String currency) {
    return 'Giá ban đầu ($currency)';
  }

  @override
  String get createActorFixedPricePlaceholder => '10 - 1,000';

  @override
  String get createActorFixedPriceDesc =>
      'Mỗi nhân vật đều được mua với mức giá cố định, không thay đổi theo doanh số bán hàng.';

  @override
  String get createActorInitialPricePlaceholder => '10 - 1,000';

  @override
  String get createActorInitialPriceDesc =>
      'Giá ban đầu là giá khởi điểm của đường cong kết hợp. Mỗi khi ký một nhân vật, giá sẽ tự động tăng theo công thức P = P₀ × 5^(số lượng đã ký ÷ tổng lượng phát hành). Ký sớm sẽ được giá ưu đãi hơn.';

  @override
  String get createActorFormIncomplete =>
      'Vui lòng hoàn thành nguồn nhân vật, tên, giới thiệu và thông số ra mắt trước';

  @override
  String get createActorValidationNameRequired => 'Vui lòng nhập tên role';

  @override
  String get createActorValidationNameTooLong =>
      'Tên nhân vật phải từ 20 ký tự trở xuống';

  @override
  String get createActorValidationBioRequired => 'Vui lòng nhập tiểu sử';

  @override
  String get createActorValidationBioTooLong =>
      'Tiểu sử phải từ 500 ký tự trở xuống';

  @override
  String get createActorValidationTotalSupplyRequired =>
      'Vui lòng nhập tổng số lượng NFT phát hành hợp lệ';

  @override
  String get createActorValidationTotalSupplyPositiveInteger =>
      'Tổng số lượng NFT phát hành phải là số nguyên dương';

  @override
  String get createActorValidationTotalSupplyRange =>
      'Tổng phát hành nhân vật phải từ 100 đến 5.000';

  @override
  String get createActorValidationPriceRequired =>
      'Vui lòng nhập giá đúc hợp lệ';

  @override
  String get createActorValidationPriceInvalid =>
      'Giá Mint phải lớn hơn hoặc bằng 10 và không vượt quá 1.000';

  @override
  String get createActorValidationPriceMaxDecimals =>
      'Giá đúc tối đa 2 chữ số thập phân';

  @override
  String get createActorSelectMaterialRequired =>
      'Vui lòng chọn tài liệu nhân vật';

  @override
  String get createActorCancelButton => 'Hủy';

  @override
  String get createActorConfirmButton => 'Xác nhận ra mắt';

  @override
  String get createActorIssueFee => 'Phí';

  @override
  String createActorSuccessTitle(String name) {
    return '$name · Ra mắt thành công!';
  }

  @override
  String createActorSuccessDesc(String id) {
    return 'IP nhân vật $id';
  }

  @override
  String get createActorSuccessTip =>
      'Người phát hành cũng cần ký hợp đồng để nhận nhân vật này~';

  @override
  String get createActorCloseButton => 'Để sau';

  @override
  String get createActorViewButton => 'Đi ký';

  @override
  String get createActorEmptyTitle =>
      'Bạn chưa có đợt ra mắt NFT nào đủ điều kiện do hệ thống tự động tạo trong DreamOS.';

  @override
  String get createActorGotoDreamOs => 'Truy cập DreamOS để tạo';

  @override
  String get createActorSearchPlaceholder => 'Tìm kiếm tài liệu nhân vật';

  @override
  String get createActorInvalidOrderId =>
      'Mã đơn hàng IP của nhân vật không hợp lệ, vui lòng làm mới và thử lại';

  @override
  String get createDramaTitle => 'Tạo phim';

  @override
  String get createDramaTitleLabel => 'Tên vở kịch ngắn';

  @override
  String get createDramaTitleHint => 'Nhập tên phim';

  @override
  String get createDramaSynopsisLabel => 'Tóm tắt';

  @override
  String get createDramaSynopsisHint =>
      'Hãy kể một câu chuyện như thế nào... (tối đa 1.000 từ)';

  @override
  String get createDramaAiSettings => 'Cài đặt tạo AI';

  @override
  String get createDramaVisualStyle => 'Phong cách hình ảnh';

  @override
  String get createDramaVisualStyleRealistic => 'Thực tế';

  @override
  String get createDramaEpisodeDuration => 'Thời lượng tập';

  @override
  String get createDramaEpisodeDurationValue => '3-5 phút';

  @override
  String get createDramaTotalEpisodes => 'Tổng số tập';

  @override
  String get createDramaTotalEpisodesValue => '8 tập';

  @override
  String get createDramaGenreLabel => 'Loại';

  @override
  String get createDramaGenreDrama => 'Phim truyền hình';

  @override
  String get createDramaGenreComedy => 'Phim hài';

  @override
  String get createDramaGenreAction => 'Hành động';

  @override
  String get createDramaGenreRomance => 'Lãng mạn';

  @override
  String get createDramaGenreSciFi => 'Khoa học viễn tưởng';

  @override
  String get createDramaGenreMystery => 'Kịch tính';

  @override
  String get createDramaGenreHorror => 'Kinh dị';

  @override
  String get createDramaGenreAnimation => 'Hoạt hình';

  @override
  String get createDramaHeroTitle => 'Sản xuất phim AI';

  @override
  String get createDramaHeroSubtitle =>
      'Tạo một cú hit tiếp theo chỉ với một cú nhấp chuột';

  @override
  String get createDramaStartGeneration => 'Bắt đầu tạo';

  @override
  String get creatorDramaManagementTab => 'Quản lý các vở kịch ngắn';

  @override
  String get creatorDramaNftTab => 'NFT phim ngắn';

  @override
  String get creatorHeaderSubtitle =>
      'Việc đăng, kiểm duyệt và tạo ra các tiểu phẩm.';

  @override
  String get creatorV2Subtitle => 'Đăng và quản lý phim ngắn/video.';

  @override
  String creatorV2DramaTabCount(int count) {
    return 'Phim ngắn ($count)';
  }

  @override
  String creatorV2VideoTabCount(int count) {
    return 'Video ($count)';
  }

  @override
  String get creatorV2NoVideos => 'Chưa có video';

  @override
  String get creatorLoginPrompt => 'Đăng nhập để xem sáng tạo của bạn';

  @override
  String get creatorNoCreatedActors => 'Chưa có role đã tạo';

  @override
  String get creatorNoPublishedDramas => 'Chưa có phim đã xuất bản';

  @override
  String get creatorOwnedNftCount => 'Số lượng NFT đang sở hữu';

  @override
  String get creatorCreateDrama => 'Tạo phim';

  @override
  String get creatorPublishNewDrama => 'Đăng phim ngắn mới';

  @override
  String get creatorPublishedDramas => 'Đăng phim ngắn';

  @override
  String get creatorReviewFilterAll => 'Tất cả';

  @override
  String get creatorReviewFilterApproved => 'Đã được thông qua';

  @override
  String get creatorReviewFilterPending => 'Đang được xem xét';

  @override
  String get creatorReviewFilterRejected => 'Không đạt';

  @override
  String get creatorReviewFilterOffline => 'Đã gỡ xuống';

  @override
  String get creatorDramaOtherReason => 'Lý do khác';

  @override
  String get creatorDramaStatusOnline => 'Đã được thông qua';

  @override
  String get creatorDramaStatusPendingReview => 'Đang chờ duyệt';

  @override
  String get creatorDramaStatusReviewRejected => 'Không đạt';

  @override
  String get creatorDramaStatusPendingOnline => 'Chờ xuất bản';

  @override
  String creatorDramaAuditReason(Object reason) {
    return 'Lý do không duyệt: $reason';
  }

  @override
  String get creatorDramaNftMinted => 'Đã đúc';

  @override
  String creatorDramaEpisodeCount(int count) {
    return '$count tập';
  }

  @override
  String get creatorDramaEdit => 'Chỉnh sửa';

  @override
  String get creatorDramaDelete => 'Xóa';

  @override
  String get creatorActorDelete => 'Xóa role';

  @override
  String get creatorDeleteDramaConfirm =>
      'Bạn có chắc chắn muốn xóa đoạn phim ngắn này không?';

  @override
  String get creatorDeleteVideoConfirmTitle => 'Xác nhận xóa video';

  @override
  String creatorDeleteVideoConfirmMessage(String name) {
    return 'Bạn có chắc muốn xóa “$name” không?\nKhông thể hoàn tác thao tác này.';
  }

  @override
  String get creatorDeleteActorConfirm =>
      'Bạn có chắc chắn muốn xóa nhân vật này không?';

  @override
  String get creatorDeleting => 'Đang xóa...';

  @override
  String get creatorNoDramas => 'Hiện chưa có phim ngắn';

  @override
  String get creatorNoNfts => 'Hiện chưa có NFT cho các vở kịch ngắn';

  @override
  String get creatorsComingSoon => 'Sắp ra mắt';

  @override
  String get creatorsHeroSubtitle => 'Khám phá các nhà sáng tạo nổi bật';

  @override
  String get creatorsHeroTitle => 'Nhà sáng tạo';

  @override
  String get dramaBatchUnlockAll => 'Mở khóa tất cả';

  @override
  String dramaBatchUnlockDiscount(String discount) {
    return 'Giảm giá mở khóa hàng loạt $discount%';
  }

  @override
  String get dramaBatchUnlockSubtitle =>
      'Mở khóa tất cả tập cùng lúc để có ưu đãi tốt hơn';

  @override
  String get dramaBatchUnlockSuccess =>
      'Mở khóa thành công, vui lòng bắt đầu xem';

  @override
  String get dramaDetailAllFree => 'Tất cả miễn phí';

  @override
  String dramaDetailBoundActors(int count) {
    return '$count role đã liên kết';
  }

  @override
  String dramaDetailEpisodeCount(int count) {
    return '$count tập';
  }

  @override
  String get dramaDetailEpisodePrice => 'Giá mỗi tập';

  @override
  String get dramaDetailFree => 'Miễn phí';

  @override
  String dramaDetailFreeEpisodes(int count) {
    return '$count tập đầu miễn phí';
  }

  @override
  String get dramaDetailMainCharacters => 'Vai chính';

  @override
  String get dramaDetailNftMinted => 'NFT đã đúc';

  @override
  String get dramaDetailNoEpisodes => 'Chưa có tập';

  @override
  String get dramaDetailPaid => 'Trả phí';

  @override
  String get dramaDetailPendingActor => 'Nhân vật chờ xác định';

  @override
  String get dramaDetailRoleCount => 'Vai diễn';

  @override
  String get dramaUnlockFailedRetry => 'Mở khóa thất bại, vui lòng thử lại';

  @override
  String get dramaUnlockFetchTimeout =>
      'Hết thời gian lấy địa chỉ phát, vui lòng thử lại';

  @override
  String get dramaUnlockLoginRequired => 'Vui lòng đăng nhập để mở khóa tập';

  @override
  String dramaUnlockMessage(
    int epNo,
    String price,
    String discount,
    String currency,
  ) {
    return 'Tập $epNo yêu cầu thanh toán để mở khóa\nGiá: $price $currency\nGiảm giá mở khóa hàng loạt: $discount';
  }

  @override
  String get dramaUnlockSuccessFetching =>
      'Mở khóa thành công, đang lấy địa chỉ phát...';

  @override
  String get dramaUnlockTitle => 'Mở khóa tập phim';

  @override
  String get editActorTitle => 'Chỉnh sửa role';

  @override
  String get editDramaTitle => 'Chỉnh sửa tiểu phẩm';

  @override
  String get editVideoTitle => 'Chỉnh sửa video';

  @override
  String get editSaveChanges => 'Lưu thay đổi';

  @override
  String get editProfileTitle => 'Chỉnh sửa hồ sơ';

  @override
  String get editNicknameLabel => 'Tên hiển thị';

  @override
  String get editRoleNameLabel => 'Tên người dùng';

  @override
  String get editNicknameHint => 'Nhập tên hiển thị';

  @override
  String get editNicknameRequired => 'Vui lòng nhập tên hiển thị';

  @override
  String get editProfileBioLabel => 'Tiểu sử';

  @override
  String get editProfileBioHint => 'Vui lòng nhập tiểu sử';

  @override
  String get editProfileEmailLabel => 'Địa chỉ email';

  @override
  String get editAvatarCropTitle => 'Cắt ảnh đại diện';

  @override
  String get profileUpdateSuccess => 'Hồ sơ đã cập nhật';

  @override
  String incomeClaimAmount(String amount, String currency) {
    return 'Nhận $amount $currency';
  }

  @override
  String get incomeClaimFailed => 'Nhận thất bại';

  @override
  String incomeClaimMessage(String amount, String currency) {
    return 'Số tiền có thể nhận: $amount $currency\nThu nhập sẽ được chuyển vào số dư ví';
  }

  @override
  String get incomeClaimSuccess => 'Nhận thành công';

  @override
  String get incomeClaimTitle => 'Nhận lợi nhuận';

  @override
  String get incomeConfirmClaim => 'Xác nhận đã nhận';

  @override
  String get incomeHistoryTab => 'Lịch sử';

  @override
  String get incomeInviteHeroSubtitle =>
      'Mời bạn bè tiêu dùng và tương tác, càng hoạt động tích cực phần thưởng càng cao';

  @override
  String get incomeInviteHeroTitle => 'Mời bạn bè để nhận hoàn tiền';

  @override
  String get incomeInviteNoRecords => 'Chưa có bản ghi hoàn tiền';

  @override
  String get incomeInvitePaidUnlockDesc => 'Bạn bè thanh toán để mở khóa tập';

  @override
  String get incomeInvitePaidUnlockTitle => 'Mở khóa có phí';

  @override
  String get incomeInviteRecords => 'Bản ghi hoàn tiền';

  @override
  String get incomeInviteRegisterDesc =>
      'Bạn bè đăng ký qua liên kết giới thiệu của bạn';

  @override
  String get incomeInviteRegisterTitle => 'Đăng ký qua mời';

  @override
  String get incomeInviteRules => 'Quy tắc hoàn tiền';

  @override
  String get incomeInviteShareLink => 'Chia sẻ liên kết mời';

  @override
  String get incomeInviteStakeDesc => 'Bạn bè stake NFT hoặc STORY';

  @override
  String get incomeInviteStakeTitle => 'Đầu tư stake';

  @override
  String get incomeInviteTab => 'Hoàn tiền mời';

  @override
  String get incomeInviteWatchDesc => 'Bạn bè xem phim để kiếm điểm';

  @override
  String get incomeInviteWatchTitle => 'Xem phim';

  @override
  String get incomeNoHistory => 'Chưa có lịch sử';

  @override
  String get incomeNoRecords => 'Chưa có bản ghi thu nhập';

  @override
  String get incomeNothingToClaim => 'Không có gì để nhận';

  @override
  String get incomeOverviewTab => 'Tổng quan';

  @override
  String get incomePendingClaim => 'Đang chờ nhận';

  @override
  String get incomeRecords => 'Bản ghi thu nhập';

  @override
  String get incomeThisMonth => 'Tháng này';

  @override
  String get incomeToday => 'Hôm nay';

  @override
  String get incomeTotalEarnings => 'Tổng lợi nhuận';

  @override
  String get incomeCumulativeStory => 'Tổng hợp STORY';

  @override
  String incomeCumulativeUsdc(String currency) {
    return 'Tổng số $currency';
  }

  @override
  String get incomeClaimableStory => 'Có thể nhận STORY';

  @override
  String incomeClaimableUsdc(String currency) {
    return 'Có thể nhận $currency';
  }

  @override
  String get incomeSettlingStory => 'Cát-xê của tôi';

  @override
  String get incomeSettlingHint => 'Đang quyết toán; có thể nhận sau khi nhận';

  @override
  String get incomeHelpTotalStoryDesc =>
      'Tổng số STORY tích lũy được trong tất cả các chu kỳ lịch sử (bao gồm cả số đã nhận và chưa nhận).';

  @override
  String incomeHelpTotalUsdcDesc(String currency) {
    return 'Tổng doanh thu tích lũy bằng $currency từ tiền hoa hồng ký kết hợp đồng và tiền bản quyền cấp hai của tất cả các nhân vật trong lịch sử.';
  }

  @override
  String get incomeHelpSettlingStoryDesc =>
      'Tự động đổi thành STORY sau khi hệ thống quyết toán';

  @override
  String get incomeHelpClaimableStoryDesc =>
      'Các STORY đã được thanh toán có thể được rút về ví cá nhân.';

  @override
  String incomeHelpClaimableUsdcDesc(String currency) {
    return '$currency đã được thanh toán có thể được rút về ví cá nhân.';
  }

  @override
  String get incomeFilterAll => 'Tất cả';

  @override
  String get incomeFilterMining => 'Doanh thu từ việc phái cử nhân sự';

  @override
  String get incomeFilterInvite => 'Thu nhập từ việc mời người tham gia';

  @override
  String get incomeMiningReward => 'Doanh thu từ việc phái cử nhân sự';

  @override
  String get incomeInviteReward => 'Thu nhập từ việc mời người tham gia';

  @override
  String get incomeUsdcActorSignShare => 'Chia sẻ doanh thu ký nhân vật';

  @override
  String get incomeClaimNoWallet => 'Vui lòng liên kết ví trước';

  @override
  String incomeClaimCurrencyTitle(String currency) {
    return 'Nhận $currency';
  }

  @override
  String incomeClaimWithdrawMessage(
    String amount,
    String currency,
    String address,
  ) {
    return 'Xác nhận rút $amount $currency vào ví Solana?\nNgười nhận: $address';
  }

  @override
  String get incomeClaimWithdrawConfirm => 'Xác nhận rút';

  @override
  String get incomeClaimWithdrawSubmitted => 'Rút tiền thành công!';

  @override
  String get incomeClaimWithdrawFailed => 'Rút thất bại, vui lòng thử lại';

  @override
  String get incomeClaimAction => 'Nhận';

  @override
  String get nftCreateActorIp => 'Tạo thương hiệu cá nhân cho nhân vật';

  @override
  String get nftHeaderSubtitle => 'Khám phá và sưu tầm nhân vật NFT độc quyền';

  @override
  String get nftHeaderTitle => 'Quảng trường Nhân vật NFT';

  @override
  String get nftSearchHint => 'Tìm phim ngắn, tác phẩm, vai, người dùng...';

  @override
  String get actorHowToPlayTitle => 'Cách chơi IP nhân vật';

  @override
  String get actorHowToPlayHelpTooltip => 'Hướng dẫn cách chơi';

  @override
  String get actorHowToPlaySignTab => 'IP đã ký';

  @override
  String get actorHowToPlaySignSubtitle => 'Nhận cát-xê thụ động';

  @override
  String get actorHowToPlayIssueTab => 'Ra mắt IP';

  @override
  String get actorHowToPlayIssueSubtitle => 'Biến sáng tạo thành thu nhập';

  @override
  String get actorHowToPlaySignPositioning =>
      'Định vị: Không có rào cản sáng tạo, dễ dàng kiếm lợi nhuận ổn định';

  @override
  String get actorHowToPlaySignAudience =>
      'Những người dùng thông thường không muốn sáng tạo, mà chỉ muốn kiếm thu nhập từ STORY một cách dễ dàng';

  @override
  String get actorHowToPlaySignGuide =>
      'Ký các IP nhân vật có độ hot cao và cát-xê cao, chỉ cần xếp lịch biểu diễn trên trang Đại lý là có thể thu lợi';

  @override
  String get actorHowToPlaySignRightsTitle => 'Lợi ích kép';

  @override
  String get actorHowToPlaySignRightPerform =>
      'Tổ chức các buổi biểu diễn để liên tục kiếm được token STORY';

  @override
  String get actorHowToPlaySignRightTrade =>
      'IP nhân vật có thể giao dịch, mang lại lợi nhuận chênh lệch giá';

  @override
  String get actorHowToPlayIssuePositioning =>
      'Định vị: sáng tạo và ra mắt, đa nguồn thu nhập, IP tăng giá dài hạn';

  @override
  String get actorHowToPlayIssueAudience =>
      'Các nhà sáng tạo có khả năng sáng tạo và mong muốn kiếm tiền từ các nhân vật IP và các video ngắn';

  @override
  String get actorHowToPlayIssueGuide =>
      'Ra mắt IP nhân vật, kết hợp với tiểu phẩm AI, nâng độ hot của tác phẩm, từ đó tăng cát-xê và doanh thu từ IP';

  @override
  String get actorHowToPlayIssueRightsTitle => 'Lợi ích ba mặt';

  @override
  String get actorHowToPlayIssueRightSignLabel => 'Chia sẻ doanh thu ký:';

  @override
  String get actorHowToPlayIssueRightSign =>
      'Khi IP của bạn được ký, bạn nhận 40% hoa hồng';

  @override
  String get actorHowToPlayIssueRightPerformLabel =>
      'Doanh thu từ buổi biểu diễn:';

  @override
  String get actorHowToPlayIssueRightPerform =>
      'Ký IP của chính mình, kiếm STORY từ biểu diễn';

  @override
  String get actorHowToPlayIssueRightValueLabel => 'Tăng giá trị:';

  @override
  String get actorHowToPlayIssueRightValue =>
      'IP có thể giao dịch; độ hot càng cao thì mức chênh lệch giá càng lớn';

  @override
  String get actorHowToPlayAudienceTitle => 'Đối tượng phù hợp';

  @override
  String get actorHowToPlayGuideTitle => 'Hướng dẫn cách chơi';

  @override
  String get actorHowToPlayCreateHint =>
      'Bạn có thể sử dụng DreamOS để tạo IP nhân vật và các tiểu phẩm AI chỉ bằng một cú nhấp chuột, từ đó sản xuất nội dung chất lượng cao một cách hiệu quả';

  @override
  String get actorHowToPlayCreateCta => 'Hãy sáng tạo';

  @override
  String get nftSignInDevelopment => 'Tính năng này hiện chưa được kích hoạt';

  @override
  String get nftSortCompleted => 'Xem hết';

  @override
  String get nftSortHeat => 'Độ hot';

  @override
  String get nftSortIpPower => 'Cát-xê IP';

  @override
  String get nftSortLowestPrice => 'Giá';

  @override
  String get nftSortLv1Pay => 'Cát-xê';

  @override
  String get nftSortMaxPay => 'Cát-xê tối đa';

  @override
  String get nftTradeUnavailable => 'Giao dịch chưa khả dụng';

  @override
  String playerEpisodeBarCompleted(int count) {
    return 'Tất cả $count tập · Hoàn thành';
  }

  @override
  String playerEpisodeSynopsis(int episodeNo, String synopsis) {
    return 'Tập $episodeNo | $synopsis';
  }

  @override
  String get playerPlayFailedRetry => 'Phát thất bại, vui lòng thử lại sau';

  @override
  String get publicProfileDramas => 'Phim ngắn';

  @override
  String get publicProfileEmpty => 'Chưa có nội dung công khai';

  @override
  String get publicProfileBlock => 'Chặn';

  @override
  String get publicProfileUnblock => 'Bỏ chặn';

  @override
  String get publicProfileBlockedByMeContent =>
      'Bạn đã chặn người dùng này nên không thể xem nội dung của họ';

  @override
  String get publicProfileBlockedContent =>
      'Người dùng này đã chặn bạn nên bạn không thể xem nội dung của họ';

  @override
  String get publicProfileBlockConfirmTitle => 'Chặn người dùng này?';

  @override
  String get publicProfileBlockConfirmMessage =>
      'Sau khi chặn, bạn sẽ không thể xem tác phẩm của người dùng này.';

  @override
  String get publicProfileBlockSuccess => 'Đã chặn người dùng';

  @override
  String get publicProfileUnblockSuccess => 'Đã bỏ chặn người dùng';

  @override
  String get publicProfileFollowers => 'Người theo dõi';

  @override
  String get publicProfileFollowing => 'Theo dõi';

  @override
  String get followTabMutual => 'Bạn bè';

  @override
  String get profileLikesReceived => 'Lượt thích';

  @override
  String profileLikesReceivedDialogMessage(int count) {
    return 'Bạn đã nhận được $count lượt thích. Cảm ơn những tác phẩm tuyệt vời của bạn!';
  }

  @override
  String get profileTabLikes => 'Đã thích';

  @override
  String get profileTabFavorites => 'Yêu thích';

  @override
  String get profileWalletTitle => 'Ví';

  @override
  String get profileAddressCopied => 'Đã sao chép địa chỉ';

  @override
  String get followActionFollow => 'Theo dõi';

  @override
  String get followActionFollowBack => 'Theo dõi lại';

  @override
  String get followActionFollowing => 'Đang theo dõi';

  @override
  String get followBlockedByMe =>
      'Người dùng nằm trong danh sách đen, bạn không thể theo dõi';

  @override
  String get followBlockedByTarget =>
      'Do cài đặt của người đó, bạn không thể theo dõi';

  @override
  String get likeBlockedByMe =>
      'Người dùng nằm trong danh sách đen, bạn không thể thích';

  @override
  String get likeBlockedByTarget =>
      'Do cài đặt của người đó, bạn không thể thích';

  @override
  String get favoriteBlockedByMe =>
      'Người dùng nằm trong danh sách đen, bạn không thể lưu';

  @override
  String get favoriteBlockedByTarget =>
      'Do cài đặt của người đó, bạn không thể lưu';

  @override
  String get ratingBlockedByMe =>
      'Người dùng nằm trong danh sách đen, bạn không thể đánh giá';

  @override
  String get ratingBlockedByTarget =>
      'Do cài đặt của người đó, bạn không thể đánh giá';

  @override
  String get followActionMutual => 'Bạn bè';

  @override
  String get followUnfollowTitle => 'Bỏ theo dõi';

  @override
  String followUnfollowMessage(String handle) {
    return 'Ngừng theo dõi $handle?';
  }

  @override
  String get followUnfollowNo => 'Không';

  @override
  String get followUnfollowYes => 'Có';

  @override
  String get followListEmpty => 'Chưa có người dùng';

  @override
  String get followFollowingEmpty =>
      'Chưa theo dõi ai. Khám phá những nhà sáng tạo thú vị nhé~';

  @override
  String get followFollowingEmptyCta => 'Đi xem';

  @override
  String get followFollowingEmptyGuest => 'Chưa theo dõi ai';

  @override
  String get followFollowersEmpty =>
      'Chưa có người theo dõi. Đăng tác phẩm để tăng độ phủ sóng nhé~';

  @override
  String get followFollowersEmptyCta => 'Đăng ngay';

  @override
  String get followFollowersEmptyGuest => 'Chưa có người theo dõi';

  @override
  String get followMutualsEmpty => 'Chưa có bạn bè theo dõi lẫn nhau';

  @override
  String get followMutualsSelfOnly => 'Danh sách bạn bè chỉ bạn mới xem được';

  @override
  String get followRelationsSelfOnly =>
      'Danh sách quan hệ chỉ bạn mới xem được';

  @override
  String get followMoreTitle => 'Thêm';

  @override
  String get followRemoveFollower => 'Gỡ người theo dõi';

  @override
  String get followRemoveFollowerSuccess =>
      'Đã gỡ. Đối phương sẽ không nhận thông báo';

  @override
  String get followUserHandleFallback => '@người dùng';

  @override
  String get publicProfileTitle => 'Hồ sơ người dùng';

  @override
  String publicProfileUserFallback(String id) {
    return 'Người dùng #$id';
  }

  @override
  String get watchHistoryEmpty => 'Chưa có lịch sử xem';

  @override
  String get watchHistoryClearTitle => 'Xóa lịch sử xem';

  @override
  String get watchHistoryClearMessage =>
      'Bạn có chắc muốn xóa toàn bộ lịch sử xem không? Không thể hoàn tác thao tác này.';

  @override
  String get watchHistoryClearConfirm => 'Xác nhận';

  @override
  String get gamePageTitle => 'Đại diện';

  @override
  String get gamePageSubtitle =>
      'Quản lý dàn role của bạn, phân công nhiệm vụ để tạo ra doanh thu.';

  @override
  String get gameRiskAccount => 'Tài khoản rủi ro';

  @override
  String get gameRiskAccountDescription =>
      'Tài khoản này có hệ số tin cậy bất thường; trọng số khai thác sẽ bị ảnh hưởng.';

  @override
  String get gameWeeklyStats => 'Thống kê tuần';

  @override
  String get gameDeployedActors => 'Role đã triển khai';

  @override
  String get gameMyActors => 'Role của tôi';

  @override
  String get gameComingSoon => 'Sắp ra mắt';

  @override
  String get gameSignActor => 'Ký nhân vật';

  @override
  String get gameGoProduce => 'Đi quay phim';

  @override
  String get gameWorkingActors => 'Các role đang được điều động';

  @override
  String get gameWeekPool => 'Quỹ thưởng tuần này (STORY)';

  @override
  String get gameWeekNominalOutput =>
      'Sản lượng danh nghĩa trong tuần này (STORY)';

  @override
  String get gameWeekEstimatedOutput => 'Dự báo sản lượng tuần này (STORY)';

  @override
  String get gameMiningRules => 'Quy tắc khai thác';

  @override
  String get agentV2RulesTitle => 'Cách vận hành';

  @override
  String get agentV2RulesSummary =>
      'Ký nhân vật và sắp xếp biểu diễn để nhận STORY mỗi giờ.\nNâng cấp nhân vật để tăng nhiều lần cát-xê theo giờ.\nHồi thể lực kịp thời để sản lượng không bị gián đoạn.\nQuyết toán thu nhập của kỳ bắt đầu lúc 00:00 thứ Hai hằng tuần (UTC); nhận tại trang Thu nhập.';

  @override
  String get agentV2RulesHowToPlay => 'Cách hoạt động';

  @override
  String get agentV2RulesStartTitle =>
      'Làm sao để nhân vật bắt đầu kiếm thu nhập?';

  @override
  String get agentV2RulesStartDescription =>
      'Sắp xếp nhân vật đang chờ biểu diễn. Mỗi giờ tiêu hao 1 thể lực và tạo STORY theo mức cát-xê.\nSTORY đã tạo được quyết toán chung khi kết thúc mỗi kỳ và có thể nhận tại trang Thu nhập sau khi quyết toán.';

  @override
  String get agentV2RulesStaminaTitle => 'Quản lý thể lực thế nào?';

  @override
  String agentV2RulesStaminaDescription(int staminaLimit) {
    return 'Đang biểu diễn: tiêu hao 1 thể lực mỗi giờ và tạo cát-xê bình thường\nHết thể lực: sản lượng dừng ở 0 và cần xử lý kịp thời\nNghỉ: tự động hồi 1 thể lực mỗi giờ nhưng tạm dừng cát-xê\nHồi thể lực (trả phí): lập tức hồi đầy $staminaLimit và tiếp tục sản xuất';
  }

  @override
  String get agentV2RulesBatchTitle => 'Có thể thao tác hàng loạt không?';

  @override
  String get agentV2RulesBatchDescription =>
      'Có. Dùng Biểu diễn tất cả, Hồi tất cả hoặc Nghỉ tất cả ở cuối trang để áp dụng thao tác cho mọi nhân vật trong các vị trí biểu diễn.';

  @override
  String get agentV2RulesEarnings => 'Thu nhập';

  @override
  String get agentV2RulesSalaryTitle => 'Cát-xê được tính như thế nào?';

  @override
  String get agentV2RulesSalaryDescription =>
      'Càng nổi tiếng, vai diễn càng đắt giá, phim ngắn càng hot thì cát-xê mỗi giờ càng cao.';

  @override
  String get agentV2RulesSalaryFormula =>
      'Cát-xê mỗi giờ của một thẻ = Cát-xê nhân vật × 1 STORY';

  @override
  String get agentV2RulesRolePowerFormula =>
      'Cát-xê nhân vật = Cát-xê nhân vật Lv.1 × Hệ số cát-xê';

  @override
  String get agentV2RulesIpSalaryFormula =>
      'Cát-xê nhân vật Lv.1 = Hệ số giá × Hệ số độ hot';

  @override
  String get agentV2RulesCoefficientTitle => 'Chi tiết hệ số';

  @override
  String agentV2RulesSalaryExample(String currency) {
    return 'Lin Mengyao · Vai chính Lv3 · P0=120$currency (hệ số giá ≈1.5046) · độ hot 3.5\n→ Cát-xê mỗi giờ = 5.0 × 1.5046 × 3.5 × 1 = 26.3 STORY\nNếu chỉ là vai quần chúng Lv1, cát-xê mỗi giờ chỉ ≈5.3 STORY — lên Lv3 giúp tăng gấp 5 lần.';
  }

  @override
  String get agentV2RulesSettlementTitle => 'Khi nào quyết toán?';

  @override
  String get agentV2RulesSettlementDescription =>
      'Mỗi chu kỳ diễn xuất dài 7 ngày, chốt vào 00:00 thứ Hai hằng tuần (UTC). Sau khi hệ thống quyết toán xong, cát-xê kỳ này được tự động đổi thành STORY và có thể nhận tại trang Thu nhập.';

  @override
  String get agentV2RulesSettlementExample =>
      'Giả sử quỹ thưởng tuần này là 100,000 STORY:\nTrường hợp A: Chỉ bạn tạo ra 134 trên toàn nền tảng → bạn nhận 134, phần còn lại không được phân phối\nTrường hợp B: Tổng sản lượng mạng là 250,000 → 100,000 ÷ 250,000 = 40%, sản lượng danh nghĩa của bạn được điều chỉnh còn 40%\nTrường hợp C: Sau điều chỉnh, một người đáng lẽ nhận 6,000 nhưng giới hạn là 5,000 → chỉ phân phối 5,000';

  @override
  String get agentV2RulesStronger => 'Cách mạnh hơn';

  @override
  String get agentV2RulesUpgradeTitle => 'Làm sao nâng cấp nhân vật?';

  @override
  String get agentV2RulesUpgradeDescription =>
      'Điều kiện: tiêu hao 2 bản sao cùng IP và cùng cấp + đạt mục tiêu lượt xem hết tích lũy của phim có IP tham gia\nCấp 1 → Cấp 2: ≥ 10.000 lượt xem hết · Cát-xê 1 → 3\nCấp 2 → Cấp 3: ≥ 50.000 lượt xem hết · Cát-xê 3 → 9\nCấp 3 → Cấp 4: ≥ 200.000 lượt xem hết · Cát-xê 9 → 27\nCấp 4 → Cấp 5: ≥ 1 triệu lượt xem hết · Cát-xê 27 → 81';

  @override
  String get agentV2RulesPerforming => 'Đang biểu diễn';

  @override
  String get agentV2RulesNormalSalary => 'Cát-xê bình thường';

  @override
  String get agentV2RulesSalaryCoefficient =>
      'Hệ số cát-xê: Lv1=1 · Lv2=3 · Lv3=9 · Lv4=27 · Lv5=81';

  @override
  String agentV2RulesPriceCoefficientDescription(
    String currency1,
    String currency2,
  ) {
    return 'Hệ số giá (giá phát hành P0):\n  • P0 ≤ 100$currency1 → Hệ số = P0 ÷ 100 (tăng tuyến tính)\n  • P0 > 100$currency2 → Hệ số = 1,6 × (P0/100)¹.³ / [(P0/100)¹.³ + 0,6] (giới hạn trên tiệm cận là 1,6)';
  }

  @override
  String get agentV2RulesTrust2 => 'Trust2';

  @override
  String get agentV2RulesTrust2Factor => 'Trust2 của nền tảng';

  @override
  String get agentV2RulesSettlementCase1 =>
      'Chi trả thực tế = sản lượng danh nghĩa; hạn mức chưa dùng sẽ hết hiệu lực';

  @override
  String get agentV2RulesSettlementCase2 =>
      'Điều chỉnh theo tỷ lệ: số thực nhận = sản lượng danh nghĩa × (quỹ thưởng ÷ tổng sản lượng mạng)';

  @override
  String get gameSettlementRecords => 'Bản ghi chép thanh toán hàng tuần';

  @override
  String get gameFilterComputingPower => 'Cát-xê';

  @override
  String get gameFilterLevel => 'Cấp độ';

  @override
  String get gameFilterHeat => 'Độ hot';

  @override
  String get gameFilterStamina => 'Thể lực';

  @override
  String get gameHeatCoef => 'Hệ số độ hot';

  @override
  String get gameMiningCoef => 'Hệ số khai thác';

  @override
  String get gameActorPower => 'Cát-xê nhân vật';

  @override
  String get gameActorPowerDetailTitle => 'Chi tiết cát-xê nhân vật';

  @override
  String get gameActorPowerFormula =>
      'Cát-xê nhân vật = Cát-xê IP × Hệ số khai thác × Hệ số CP × Trust2';

  @override
  String get gameActorPowerIpFormula =>
      'Cát-xê IP = Hệ số giá × Hệ số độ hot × Trust1';

  @override
  String get gameActorPowerHourlyOutput => 'Sản lượng mỗi giờ';

  @override
  String get gameCpCoefficient => 'Hệ số CP';

  @override
  String get gameTrust2 => 'Trust2';

  @override
  String get gameWeeklyNominalOutputLabel =>
      'Sản lượng danh nghĩa trong tuần này';

  @override
  String get gameRoundNominalOutputLabel => 'Đầu ra nominal kỳ';

  @override
  String get gameSupplement => 'Bổ sung';

  @override
  String get gameRest => 'Nghỉ ngơi';

  @override
  String get gameDeploy => 'Phái cử';

  @override
  String get gameDeployActor => 'Tuyển chọn nhân vật';

  @override
  String get gameStatusIdle => 'Không sử dụng';

  @override
  String get gameStatusMining => 'Đang khai thác';

  @override
  String gameActorIpLabel(String id) {
    return 'Nhân vật IP $id';
  }

  @override
  String gameStaminaProgress(String current, String max) {
    return '$current/$max';
  }

  @override
  String get gameStaminaMechanismTitle => 'Cơ chế thể lực';

  @override
  String gameStaminaMechanismDesc(String currency) {
    return 'Role đang được triển khai sẽ tiêu hao 1 điểm thể lực mỗi giờ. Khi hết thể lực, việc tạo lợi nhuận sẽ dừng lại và thể lực tự động hồi phục trong lúc nghỉ ngơi. Bạn có thể dùng $currency để bổ sung thể lực ngay lập tức.';
  }

  @override
  String get gameStaminaMechanismAction => 'Đã hiểu';

  @override
  String gameLevelBadge(String level) {
    return 'Lv$level';
  }

  @override
  String get gameEmptyDeployed => 'Chưa có role nào được triển khai';

  @override
  String get gameEmptyMyActors =>
      'Chưa có nhân vật. Hãy ký một nhân vật để bắt đầu.';

  @override
  String get gameDeployConfirmTitle => 'Triển khai nhân vật này?';

  @override
  String get gameRestConfirmTitle => 'Cho nhân vật này nghỉ ngơi?';

  @override
  String get gameRestConfirmDesc =>
      'Khai thác tạm dừng khi nhân vật nghỉ; thể lực hồi phục theo thời gian.';

  @override
  String get gameRestConfirmAction => 'Xác nhận nghỉ';

  @override
  String get gameRestSuccessToast => 'Đã bắt đầu nghỉ';

  @override
  String get gameDeploySlotFull => 'Slot triển khai đã đầy (tối đa 5)';

  @override
  String get gameRefillTitle => 'Phục hồi thể lực';

  @override
  String get gameRefillCurrentStamina => 'Thể lực hiện tại';

  @override
  String get gameRefillCost => 'Chi phí khôi phục';

  @override
  String get gameRefillConfirm => 'Phục hồi toàn bộ thể lực';

  @override
  String get gameRefillSuccess => 'Đã phục hồi thể lực thành công';

  @override
  String get gameRefillFailed => 'Không thể phục hồi thể lực, vui lòng thử lại';

  @override
  String gameInsufficientUsdc(String currency) {
    return 'Số dư $currency không đủ';
  }

  @override
  String get walletInsufficientStory => 'Số dư STORY không đủ';

  @override
  String get gameSupplementComingSoon => 'Nạp thể lực sắp ra mắt';

  @override
  String get gameStatHelpWeekPoolTitle => 'Quỹ thưởng tuần này';

  @override
  String get gameStatHelpWeekPoolSubtitle =>
      'Tức là mức trần phân phối bắt buộc hàng tuần của hoạt động khai thác STORY (mức trần hàng tuần)';

  @override
  String get gameStatHelpWeekTotalPool => 'Tổng quỹ thưởng tuần này';

  @override
  String get gameStatHelpWeekTotalPoolValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeekStakePool => 'Quỹ thưởng stake tuần này (75%)';

  @override
  String get gameStatHelpWeekStakePoolValue => '1,586,538 STORY';

  @override
  String get gameStatHelpWeekInvitePool => 'Quỹ thưởng mời tuần này (25%)';

  @override
  String get gameStatHelpWeekInvitePoolValue => '528,846 STORY';

  @override
  String get gameStatHelpInitialHardCap => 'Mui cứng phiên bản ban đầu';

  @override
  String get gameStatHelpInitialHardCapValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeeklyDecay => 'Hệ số suy giảm theo tuần';

  @override
  String get gameStatHelpWeeklyDecayValue => '× 0.99572';

  @override
  String get gameStatHelpWeeklyDistributionFormula =>
      'Số lượng thực tế được phân phối hàng tuần = min(sản lượng danh nghĩa toàn mạng, mức trần cố định của tuần đó)';

  @override
  String get gameStatHelpUnusedQuotaNote =>
      'Phần hạn mức còn lại chưa được phân bổ sẽ không được cấp, không được thu hồi và không được bù đắp';

  @override
  String get gameStatHelpNominalTitle => 'Sản lượng danh nghĩa tuần này';

  @override
  String get gameStatHelpNominalSummary =>
      'Tổng sản lượng danh nghĩa lũy kế theo tuần của tất cả vai diễn của tôi';

  @override
  String get gameStatHelpNominalSummaryHint =>
      'Công thức cho thẻ đơn được nêu trong phần giải thích bên dưới';

  @override
  String get gameStatHelpNominalFormula =>
      'Sản lượng danh nghĩa mỗi thẻ = Trọng số giờ mỗi thẻ × R_base × Thời gian khai thác hiệu quả';

  @override
  String get gameStatHelpHourlyWeight => 'Hệ số trọng số theo giờ cho mỗi thẻ';

  @override
  String get gameStatHelpHourlyWeightValue => '= Cát-xê nhân vật';

  @override
  String get gameStatHelpActorPower => 'Cát-xê nhân vật';

  @override
  String get gameStatHelpActorPowerValue =>
      '= Cát-xê IP × Hệ số khai thác × Hệ số CP × Trust2';

  @override
  String get gameStatHelpCpCoef => 'Hệ số CP';

  @override
  String get gameStatHelpRBase => 'R_base';

  @override
  String get gameStatHelpRBaseValue => '1 STORY / Hệ số trọng số đơn vị / Giờ';

  @override
  String get gameStatHelpEffectiveDuration => 'Thời gian khai thác hiệu quả';

  @override
  String get gameStatHelpEffectiveDurationValue =>
      'Tổng thời gian đang thế chấp và có chỉ số Thể lực &gt; 0';

  @override
  String get gameStatHelpActualTitle => 'Dự báo sản lượng trong tuần này';

  @override
  String get gameStatHelpActualSubtitle =>
      'Sản lượng ước tính bị giới hạn bởi mức trần tuần và mức trần mỗi địa chỉ; lợi nhuận thực tế được chốt khi kết thúc tuần';

  @override
  String get gameStatHelpIfNominalLte =>
      'Nếu sản lượng danh nghĩa trên toàn mạng ≤ mức trần cố định của tuần đó:';

  @override
  String get gameStatHelpUserActualEqNominal =>
      'Thu nhập thực tế của người dùng = Sản lượng danh nghĩa của người dùng';

  @override
  String get gameStatHelpIfNominalGt =>
      'Nếu sản lượng danh nghĩa trên toàn mạng &gt; mức trần của tuần đó:';

  @override
  String get gameStatHelpUserActualFormula =>
      'Số lượng thực tế người dùng nhận được = Sản lượng danh nghĩa của người dùng × Giới hạn tối đa của tuần đó / Sản lượng danh nghĩa toàn mạng';

  @override
  String get gameStatHelpAddressCap => 'Giới hạn hàng tuần cho mỗi địa chỉ';

  @override
  String get gameStatHelpAddressCapValue =>
      'Mỗi địa chỉ chỉ được nhận tối đa 5% mức trần của tuần đó mỗi tuần';

  @override
  String get theaterCategoryAll => 'Tất cả';

  @override
  String get theaterCategoryAncient => 'Cổ trang';

  @override
  String get theaterCategoryFinance => 'Tài chính';

  @override
  String get theaterCategorySuspense => 'Ly kỳ';

  @override
  String get theaterCategorySciFi => 'Khoa học viễn tưởng';

  @override
  String get theaterCategoryRealStory => 'Dựa trên câu chuyện có thật';

  @override
  String get theaterCategoryUrban => 'Thành phố';

  @override
  String get theaterSortHottest => 'Nổi bật nhất';

  @override
  String get theaterSortNewest => 'Mới nhất';

  @override
  String get theaterSortTopRated => 'Được yêu thích nhất';

  @override
  String get theaterSortCompletedView => 'Hoàn thành nhiều nhất';

  @override
  String theaterPlayCount(String count) {
    return '$count lượt phát';
  }

  @override
  String get createDramaBasicInfo => 'Thông tin cơ bản';

  @override
  String get createDramaEpisodes => 'Quản lý bộ phim';

  @override
  String get createDramaRoles => 'Liên kết IP';

  @override
  String get createDramaCover => 'Bìa';

  @override
  String get createDramaCoverUpload => 'Tải lên';

  @override
  String get createDramaCoverPlaceholder => 'Hỗ trợ JPG/PNG, tối đa 5MB';

  @override
  String get createDramaCoverCropTitle => 'Cắt ảnh bìa';

  @override
  String get createDramaName => 'Tên vở kịch ngắn';

  @override
  String get createDramaNameHint => 'Vui lòng nhập tiêu đề vở kịch ngắn';

  @override
  String get createDramaSynopsis => 'Giới thiệu';

  @override
  String get createDramaTags => 'Thẻ';

  @override
  String get createDramaTagsHint =>
      'Nhập tag và nhấn Enter để thêm (VD: Tình yêu, Hài hước)';

  @override
  String get createDramaTagsLoading => 'Đang tải tag…';

  @override
  String get createDramaTagsEmpty => 'Không có tag khả dụng';

  @override
  String get createDramaTagsRetry => 'Thử lại';

  @override
  String get createDramaUploadDesc =>
      'Nhấp vào \"Tải lên\"; sau khi gửi, các video sẽ được sắp xếp tự động theo tên';

  @override
  String get createDramaEpisodesDesc =>
      'Khi tải lên hàng loạt các tệp video, hệ thống sẽ tự động sắp xếp theo tên tệp để tạo danh sách các tập phim. Hỗ trợ các thao tác như kéo thả để sắp xếp, xóa và chỉnh sửa tiêu đề.';

  @override
  String get createDramaVideoFileTypeHint =>
      'Định dạng hỗ trợ: mp4, flv, wmv, asf, mkv, avi, rm, rmvb, mpg, mpeg, mov, webm. Kích thước tối đa 2GB.';

  @override
  String get createDramaUploadVideo => 'Tải lên video';

  @override
  String get createDramaVideoEmpty => 'Chưa thêm video nào';

  @override
  String get createDramaVideoPickFailed => 'Lỗi chọn video';

  @override
  String get createDramaVideoAnyTooLarge =>
      'Có video vượt quá 2GB, vui lòng điều chỉnh và thử lại';

  @override
  String get createDramaVideoStatusUploading => 'Đang tải lên';

  @override
  String get createDramaVideoStatusPaused => 'Đã tạm dừng tải lên';

  @override
  String get createDramaVideoStatusDone => 'Đã tải lên thành công';

  @override
  String get createDramaEpisodeDescriptionHint => 'Mô tả tập phim';

  @override
  String get createDramaVideoStatusFailed => 'Tải lên không thành công';

  @override
  String get createDramaVideoTooLarge =>
      'Kích thước video không được vượt quá 2GB và không thể tải lên';

  @override
  String get createDramaVideoUploadComplete => 'Tất cả video đã tải lên';

  @override
  String createDramaVideoUploadFailed(String name) {
    return 'Tải lên $name thất bại';
  }

  @override
  String createDramaVideoPickOverflow(int count, int overflow) {
    return 'Bạn có thể thêm tối đa $count tập nữa. $overflow tập thừa đã bị bỏ qua.';
  }

  @override
  String createDramaAddedVideos(String count) {
    return 'Video đã thêm ($count tệp)';
  }

  @override
  String createDramaAddedVideosCount(String count) {
    return '($count tệp)';
  }

  @override
  String get createDramaAddedVideosLabel => 'Video đã được thêm vào';

  @override
  String get createDramaRolesDesc =>
      'Tạo vai diễn cho phim ngắn, đặt tên vai, ảnh đại diện và mô tả tính cách.';

  @override
  String get createDramaRolesRule1 =>
      'Mỗi phim ngắn có thể liên kết tối đa 5 IP nhân vật. Có thể thêm trong vòng 7 ngày sau khi phát hành; sau đó không thể gỡ hoặc thay thế.';

  @override
  String get createDramaRolesRule2 =>
      'Sau khi liên kết, IP nhân vật sẽ gắn với dữ liệu xem hết và độ phổ biến của phim để nâng cấp và nhận thưởng STORY.';

  @override
  String get createDramaRolesExpireTime => 'Thời hạn cuối';

  @override
  String get createDramaRolesRule3 =>
      'Liên kết IP là tùy chọn; bạn có thể phát hành mà không cần liên kết.';

  @override
  String get createDramaAddRole => 'Thêm vai diễn';

  @override
  String get createDramaBindActor => 'Vai diễn tham gia';

  @override
  String get createDramaRoleActing => 'Vai diễn tham gia';

  @override
  String get createDramaSelectActor => 'Chọn role';

  @override
  String get createDramaBindActorTitle => 'Chọn Nhân vật IP';

  @override
  String createDramaBindIpSelectedCount(int count) {
    return 'Đã chọn $count';
  }

  @override
  String get createDramaBindIpEmpty => 'Chưa có dữ liệu';

  @override
  String get createDramaBindIpMarketplace => 'Đến chợ IP nhân vật';

  @override
  String get createDramaBindIpConfirm => 'Xác nhận liên kết';

  @override
  String createDramaBindActorSubtitle(String roleName) {
    return 'Chọn một Nhân vật IP để đóng vai “$roleName”';
  }

  @override
  String createDramaBindActorOwnedCount(int count) {
    return 'Sở hữu $count địa chỉ IP của nhân vật';
  }

  @override
  String createDramaBindActorIpLabel(String code) {
    return 'Nhân vật IP $code';
  }

  @override
  String get createDramaBindActorBoundTag => 'Đã được liên kết';

  @override
  String get createDramaBindIpRemove => 'Gỡ bỏ';

  @override
  String createDramaBindActorBoundToast(String name) {
    return 'Đã liên kết $name';
  }

  @override
  String get createDramaBindActorUnbind => 'Hủy liên kết';

  @override
  String get createDramaBindActorExpired =>
      'Đã quá thời hạn liên kết 7 ngày, không thể liên kết thêm IP nhân vật mới';

  @override
  String get createDramaBindActorEmptyTitle =>
      'Không có Nhân vật IP để liên kết';

  @override
  String get createDramaBindActorEmptyDesc =>
      'Bạn cần sở hữu Nhân vật IP trước khi liên kết với vai diễn';

  @override
  String get createDramaBindActorGotoCreate => 'Tạo role';

  @override
  String get createDramaPrevStep => 'Bước trước';

  @override
  String get createDramaNextStep => 'Bước tiếp theo';

  @override
  String get createDramaSubmit => 'Đăng';

  @override
  String get createDramaRoleNameLabel => 'Tên vai diễn';

  @override
  String get createDramaRoleNameHint => 'Vui lòng nhập tên vai diễn';

  @override
  String get createDramaRoleNameRequired => 'Vui lòng nhập tên vai diễn';

  @override
  String get createDramaRoleBioLabel => 'Giới thiệu vai';

  @override
  String get createDramaRoleBioHint => 'Vui lòng nhập phần giới thiệu vai diễn';

  @override
  String get createDramaRoleBioRequired => 'Giới thiệu vai diễn là bắt buộc';

  @override
  String get createDramaRoleAddTitle => 'Thêm vai diễn';

  @override
  String get createDramaRoleEditTitle => 'Chỉnh sửa vai diễn';

  @override
  String get createDramaRoleUploadAvatar => 'Tải ảnh đại diện lên';

  @override
  String get createDramaRoleSave => 'Lưu';

  @override
  String get createDramaRoleDeleteConfirm => 'Xóa nhân vật này?';

  @override
  String createDramaVideoDeleteConfirm(String name) {
    return 'Xóa \"$name\"?';
  }

  @override
  String get createDramaVideoDeleteTitle => 'Xóa video';

  @override
  String get createDramaVideoPreviewUnavailable =>
      'Hiện chưa thể xem trước các video đã tải lên trước đó';

  @override
  String get createDramaRoleEmpty => 'Chưa thêm vai diễn nào';

  @override
  String get createDramaRoleBindComingSoon => 'Liên kết role sắp ra mắt';

  @override
  String get createDramaRoleAvatarCropTitle => 'Cắt ảnh đại diện vai diễn';

  @override
  String get createDramaRoleAvatarUploadFailed =>
      'Tải lên ảnh đại diện vai diễn thất bại';

  @override
  String get createDramaPublishedSuccess => 'Đăng thành công';

  @override
  String get createDramaDraftRestored =>
      'Đã khôi phục bản nháp chưa hoàn thành';

  @override
  String get createDramaDraftClear => 'Xóa dữ liệu';

  @override
  String get createDramaDraftDiscard => 'Quay lại không lưu';

  @override
  String get createDramaDraftSave => 'Lưu bản nháp';

  @override
  String get createDramaEditLoading => 'Đang tải...';

  @override
  String get createDramaEditLoadError =>
      'Không thể tải thông tin phim, vui lòng thử lại';

  @override
  String get createDramaSubmitValidationTitle => 'Vui lòng nhập tiêu đề phim';

  @override
  String get createDramaSubmitValidationCover => 'Vui lòng tải lên ảnh bìa';

  @override
  String get createDramaSubmitValidationVideos =>
      'Vui lòng tải lên ít nhất một video';

  @override
  String get createDramaSubmitValidationSession =>
      'Phiên tải lên không hợp lệ, vui lòng tải lại video';

  @override
  String get createDramaUploadSessionFailed => 'Không thể tạo phiên tải lên';

  @override
  String get createDramaSubmitValidationRoles =>
      'Vui lòng thêm ít nhất một vai diễn';

  @override
  String get createDramaStep1TitleRequired =>
      'Vui lòng nhập tiêu đề vở kịch ngắn';

  @override
  String get createDramaStep1SynopsisRequired =>
      'Vui lòng nhập phần giới thiệu';

  @override
  String get createDramaStep1CoverRequired => 'Vui lòng thêm ảnh bìa';

  @override
  String get createDramaStep1TagsRequired => 'Vui lòng chọn tag';

  @override
  String get createDramaEpisodeDescriptionRequired =>
      'Vui lòng nhập mô tả tập phim';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsTheme => 'Giao diện';

  @override
  String get settingsThemeLight => 'Sáng';

  @override
  String get settingsThemeDark => 'Tối';

  @override
  String get settingsThemeSystem => 'Hệ thống';

  @override
  String get settingsUI => 'Giao diện';

  @override
  String get settingsAppVersion => 'Phiên bản';

  @override
  String get settingsVersionLatestToast => 'Bạn đang dùng phiên bản mới nhất';

  @override
  String get settingsVersionCheckFailed =>
      'Không kiểm tra được phiên bản. Vui lòng thử lại sau.';

  @override
  String get appVersionUpdateTitle => 'Có phiên bản mới';

  @override
  String get appVersionUpdateContentsLabel => 'Nội dung cập nhật:';

  @override
  String get appVersionUpdateConfirm => 'Cập nhật ngay';

  @override
  String get appVersionUpdateLater => 'Để sau';

  @override
  String get settingsTermsOfService => 'Điều khoản dịch vụ';

  @override
  String get settingsPrivacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String get settingsDeleteAccount => 'Xóa tài khoản';

  @override
  String settingsDeleteAccountConfirm(String deadline) {
    return 'Tài khoản của bạn sẽ bị xóa vào $deadline. Trong thời gian này, bạn có thể đăng nhập lại để hủy xóa tài khoản.';
  }

  @override
  String get settingsDeleteAccountSuccess =>
      'Yêu cầu xóa tài khoản đã được gửi';

  @override
  String get settingsClearCache => 'Xóa bộ nhớ đệm';

  @override
  String get settingsNetworkInspector => 'Kiểm tra mạng';

  @override
  String get settingsClearCacheConfirm =>
      'Bạn có chắc chắn muốn xóa bộ nhớ đệm?';

  @override
  String get miningRulesHowToPlay => 'Cách chơi chế độ \"Phái cử khai thác\"';

  @override
  String get miningRulesFlowSubtitle =>
      'Hiểu rõ toàn bộ quy trình từ khi cử người đi đến khi nhận tiền chỉ qua một hình ảnh';

  @override
  String get miningRulesSection1Title => '1. Cử người đi khai thác';

  @override
  String get miningRulesSection1Desc =>
      'Hãy “phân công” các role rảnh rỗi vào 5 vị trí dưới đây, và họ sẽ tự động khai thác, tạo ra STORY.';

  @override
  String get miningRulesSection1Bullet1 =>
      'Mỗi người chỉ được cử tối đa 5 role cùng lúc';

  @override
  String get miningRulesSection1Bullet2 =>
      'Một Nhân vật IP có thể được sử dụng để phân công nhiều thẻ cùng lúc';

  @override
  String get miningRulesSection1Bullet3 =>
      'Sau khi triển khai, cứ mỗi 1 giờ sẽ tiêu hao 1 điểm ⚡thể lực; nếu thể lực &gt; 0 thì sẽ tiếp tục sản xuất, còn nếu thể lực = 0 thì sẽ ngừng hoạt động';

  @override
  String get miningRulesSection2Title =>
      '2. Tính toán, công thức tính sản lượng';

  @override
  String get miningRulesSection2Desc =>
      'Sản lượng mỗi giờ của mỗi thẻ được tính như sau:';

  @override
  String get miningRulesSection2Formula =>
      'Đầu ra mỗi giờ mỗi thẻ = Cát-xê nhân vật × 1 STORY';

  @override
  String get miningRulesSection2FactorsTitle => 'Ba yếu tố quyết định:';

  @override
  String get miningRulesSection2Factor1 =>
      'Hệ số khai thác — Cấp độ càng cao thì hệ số càng lớn. Cấp 1 = 1,0 → Cấp 2 = 2,2 → Cấp 3 = 5,0 → Cấp 4 = 11 → Cấp 5 = 24';

  @override
  String get miningRulesSection2Factor2 =>
      'Cát-xê IP = Hệ số giá × Hệ số độ hot × Trust1';

  @override
  String get miningRulesSection2Factor3 =>
      'R_base — Giá trị cố định, hiện tại là 1 STORY; nền tảng có thể điều chỉnh thủ công sau này';

  @override
  String miningRulesSection2Factor4(String currency1, String currency2) {
    return 'Hệ số giá — giá phát hành P0: P0≤10$currency1 tăng tuyến tính · P0>10$currency2 tiến dần đến mức trần 1,6';
  }

  @override
  String get miningRulesSection2Factor5 =>
      'Hệ số độ nổi tiếng — thành tích phim gần đây càng tốt thì độ nổi tiếng càng cao (lượt xem hết, lượt thích, lưu và bình luận)';

  @override
  String get miningRulesSection2Factor6 =>
      'Hệ số CP — chưa mở; Trust mặc định là 1,0';

  @override
  String miningRulesSection2StaminaText(int staminaLimit) {
    return 'Thể lực chỉ phụ thuộc vào việc “có hay không”, chứ không phụ thuộc vào mức còn lại: $staminaLimit điểm thể lực và 1 điểm thể lực đều mang lại sản lượng như nhau mỗi giờ; điều quan trọng là bạn có đang khai thác hay không.';
  }

  @override
  String get miningRulesSection2ExampleTitle => 'Ví dụ như:';

  @override
  String miningRulesSection2ExampleDesc(String currency) {
    return 'Lin Mengyao · Vai chính Lv3 · P0=12$currency (hệ số giá ≈1.0859) · độ hot 3.5\n→ Sản lượng mỗi giờ = 5.0 × 1.0859 × 3.5 × 1 = 19.00325 STORY';
  }

  @override
  String get miningRulesCoefTableTitle => 'Chi tiết hệ số';

  @override
  String get miningRulesCoefColCoef => 'Hệ số';

  @override
  String get miningRulesCoefColFactor => 'Yếu tố quyết định';

  @override
  String get miningRulesCoefColDesc => 'Chi tiết';

  @override
  String get miningRulesCoefMining => 'Hệ số khai thác';

  @override
  String get miningRulesCoefPrice => 'Hệ số giá';

  @override
  String get miningRulesCoefHeat => 'Hệ số độ hot';

  @override
  String get miningRulesCoefCp => 'Hệ số CP';

  @override
  String get miningRulesCoefTrust => 'Trust';

  @override
  String get miningRulesCoefMiningFactor => 'Cấp độ';

  @override
  String get miningRulesCoefPriceFactor => 'Giá ra mắt P0';

  @override
  String get miningRulesCoefHeatFactor => 'Thành tích phim gần đây';

  @override
  String get miningRulesCoefCpFactor => '-';

  @override
  String get miningRulesCoefTrustFactor => 'Kiểm soát rủi ro nền tảng';

  @override
  String get miningRulesCoefMiningDesc =>
      'Lv1=1.0 · Lv2=2.2 · Lv3=5.0 · Lv4=11 · Lv5=24';

  @override
  String miningRulesCoefPriceDesc(String currency1, String currency2) {
    return 'Tuyến tính khi P0≤10$currency1 · tiệm cận mức trần 1,6 khi P0>10$currency2';
  }

  @override
  String get miningRulesCoefHeatDesc =>
      'Hệ số độ hot: phim có IP nhân vật tham gia càng nhiều lượt xem hết, thích, lưu và đánh giá thì độ hot càng cao';

  @override
  String get miningRulesCoefCpDesc => 'Chưa mở';

  @override
  String get miningRulesCoefTrustDesc => 'Mặc định là 1,0';

  @override
  String get miningRulesSection3Title =>
      '3. Phát tiền, nhưng có giới hạn tối đa';

  @override
  String get miningRulesSection3Desc =>
      'Mỗi tuần toàn nền tảng có tổng quỹ thưởng (giới hạn cứng hàng tuần), bắt đầu khoảng 2.115.385 STORY, giảm dần mỗi tuần (hàng tuần × 0.99572). Phân bổ thưởng chia thành ba trường hợp:';

  @override
  String get miningRulesSettleColCondition => 'Điều kiện';

  @override
  String get miningRulesSettleColRule => 'Quy tắc phân phối';

  @override
  String get miningRulesSection3Case1Title =>
      'Sản lượng danh nghĩa trên tất cả các nền tảng ≤ Tổng giải thưởng của tuần này';

  @override
  String get miningRulesSection3Case1Desc =>
      'Mỗi người sẽ nhận toàn bộ số tiền theo danh sách; phần giải thưởng còn lại sẽ không được trao và cũng không được bù đắp';

  @override
  String get miningRulesSection3Case2Title =>
      'Sản lượng danh nghĩa trên tất cả các nền tảng &gt; Quỹ thưởng tuần này';

  @override
  String get miningRulesSection3Case2Desc =>
      'Tỷ lệ thu nhỏ theo tỷ lệ: Sản lượng thực tế của bạn = Sản lượng danh nghĩa của bạn × Quỹ thưởng ÷ Tổng sản lượng toàn nền tảng';

  @override
  String get miningRulesSection3Case3Title =>
      'Một địa chỉ duy nhất chiếm hơn 5% tổng quỹ thưởng';

  @override
  String get miningRulesSection3Case3Desc =>
      'Phần vượt quá sẽ không được phát, không được hoàn lại và không được bù điểm';

  @override
  String get miningRulesSection3ExampleDesc =>
      'Giả sử quỹ thưởng hàng tuần là 100.000 STORY:\nTrường hợp A: Bạn là người duy nhất trên nền tảng, sản xuất 134 trong một tuần → Nhận 134, phần còn lại 99.866 không được phân bổ\nTrường hợp B: Tổng sản lượng nền tảng là 250.000, mọi người được tỷ lệ 40% (100.000÷250.000)\nTrường hợp C: Phần thưởng tỷ lệ là 6.000, nhưng giới hạn mỗi địa chỉ là 5.000 → Chỉ phân bổ 5.000';

  @override
  String get miningRulesSection4Title =>
      '4. Phải quản lý tốt thể lực thì mới có thể tiếp tục đào được';

  @override
  String get miningRulesTableStatus => 'Trạng thái';

  @override
  String get miningRulesTableStaminaChange => 'Sự thay đổi về thể lực';

  @override
  String get miningRulesTableOutput => 'Sản phẩm';

  @override
  String get miningRulesStatusMining => 'Đang khai thác';

  @override
  String get miningRulesStaminaMining => '-1 mỗi giờ';

  @override
  String get miningRulesOutputNormal => 'Sản lượng bình thường';

  @override
  String get miningRulesStatusZeroStamina => 'Thể lực = 0';

  @override
  String get miningRulesStaminaZeroStamina => 'Không còn thay đổi nữa';

  @override
  String get miningRulesOutputZero => 'Kết quả là 0';

  @override
  String get miningRulesStatusResting => 'Ngừng hoạt động để nghỉ ngơi';

  @override
  String get miningRulesStaminaResting => '+1 mỗi giờ (tự động phục hồi)';

  @override
  String get miningRulesOutputPaused => 'Tạm ngừng sản xuất';

  @override
  String get miningRulesStatusPaidRefill => 'Bổ sung thể lực (trả phí)';

  @override
  String miningRulesStaminaPaidRefill(int staminaLimit) {
    return 'Nạp đầy ngay lập tức $staminaLimit';
  }

  @override
  String get miningRulesOutputRestored => 'Khôi phục sản lượng';

  @override
  String get miningRulesSection4TipsTitle =>
      '3 điều cần biết về việc bổ sung thể lực:';

  @override
  String get miningRulesSection4Tip1 =>
      'Chỉ có thể nạp đầy bằng một cú nhấp chuột, không thể chỉ mua 10 điểm';

  @override
  String get miningRulesSection4Tip2 =>
      'Giá chỉ phụ thuộc vào cấp độ, không phụ thuộc vào lượng thể lực còn lại. Dù nạp đầy khi thể lực là 0 hay khi thể lực là 100, số tiền phải trả đều như nhau.';

  @override
  String get miningRulesSection4Tip3 =>
      'Càng gần 0 thì việc nạp thêm càng tiết kiệm — với cùng một khoản tiền, bạn sẽ nhận được thời gian khai thác mới nhiều nhất';

  @override
  String get miningRulesSection4PriceTitle => 'Giá bổ sung cho từng hạng:';

  @override
  String get miningRulesPriceTableTier => 'Vị thế';

  @override
  String get miningRulesPriceTableFullRefill =>
      'Đổ đầy chỉ với một cú nhấp chuột';

  @override
  String get miningRulesLv1 => 'Cấp 1: Quần chúng';

  @override
  String get miningRulesLv2 => 'Cấp 2 - Nhân vật phụ';

  @override
  String get miningRulesLv3 => 'Cấp 3 - Nhân vật chính';

  @override
  String get miningRulesLv4 => 'Cấp 4: Siêu sao';

  @override
  String get miningRulesLv5 => 'Cấp 5 – Siêu sao hàng đầu';

  @override
  String get gameActorLevelName1 => 'Phụ';

  @override
  String get gameActorLevelName2 => 'Vai phụ';

  @override
  String get gameActorLevelName3 => 'Vai chính';

  @override
  String get gameActorLevelName4 => 'Siêu sao';

  @override
  String get gameActorLevelName5 => 'Hạng nhất';

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
  String get miningRulesSection5Title =>
      '5. Nâng cao vị thế, kiếm được nhiều tiền hơn';

  @override
  String get miningRulesSection5Desc =>
      '3 thẻ của nhân vật cùng đẳng cấp + phí tổng hợp + nhân vật đó đạt chỉ tiêu lượt xem hết tích lũy = thăng 1 cấp. Sau khi thăng cấp, hệ số khai thác tăng vọt, sản lượng mỗi giờ tăng gấp đôi hoặc thậm chí gấp nhiều lần.';

  @override
  String get miningRulesUpgradePathSubtitle => 'Lộ trình nâng cấp';

  @override
  String get miningRulesUpgradeColPath => 'Lộ trình nâng cấp';

  @override
  String get miningRulesUpgradeColHeat => 'Ngưỡng lượt xem hết tích lũy';

  @override
  String get miningRulesUpgradeColFee => 'Phí hợp thành';

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
  String get miningRulesSummaryTitle => 'Tóm tắt trong một câu';

  @override
  String get miningRulesSummaryDesc =>
      'Điều phái → Sản xuất → Theo dõi thể lực → Nhận tiền. Khi thể lực sắp hết, hãy bổ sung hoặc gọi về nghỉ ngơi; độ hot tăng nhờ thành tích phim của nhân vật, nâng cấp giúp sản lượng bứt phá.';

  @override
  String get playerNotInterested => 'Không quan tâm';

  @override
  String get playerNotInterestedDone =>
      'Đã nhận phản hồi của bạn. Chúng tôi sẽ ít đề xuất nội dung tương tự';

  @override
  String get playerClearScreen => 'Xóa màn hình';

  @override
  String get playerAutoPlay => 'Phát liên tục';

  @override
  String get playerReport => 'Báo cáo';

  @override
  String get playerReportSuccess => 'Đã báo cáo thành công';

  @override
  String get commentReportSuccess =>
      'Đã gửi thành công, chúng tôi sẽ xử lý sớm';

  @override
  String get reportSuccessTitle => 'Gửi thành công, chúng tôi sẽ xử lý sớm';

  @override
  String get reportSuccessThanks =>
      'Cảm ơn bạn đã góp phần giữ cộng đồng an toàn!';

  @override
  String get reportSuccessAlsoYouCan => 'Bạn cũng có thể';

  @override
  String get reportSuccessDone => 'Xong';

  @override
  String get reportReduceRecommend => 'Giảm đề xuất';

  @override
  String get reportReduceRecommendDone => 'Đã giảm đề xuất';

  @override
  String get reportSuccessContentFallback => 'Nội dung này';

  @override
  String get reportDescription => 'Mô tả báo cáo';

  @override
  String get reportDescriptionPlaceholder => 'Mô tả chi tiết (Tùy chọn)';

  @override
  String get reportReasonPorn => 'Khiêu dâm & tục tĩu';

  @override
  String get reportReasonIllegal => 'Bất hợp pháp hoặc Hình sự';

  @override
  String get reportReasonSensitive => 'Nội dung nhạy cảm';

  @override
  String get reportReasonGambling => 'Đánh bạc hoặc Bạo lực';

  @override
  String get reportReasonMinors => 'Gây hại cho Trẻ vị thành niên';

  @override
  String get reportReasonCopyright => 'Vi phạm Bản quyền';

  @override
  String get reportReasonQuality => 'Vấn đề Chất lượng';

  @override
  String get reportReasonNotLike => 'Tôi không thích';

  @override
  String get reportReasonOther => 'Khác';

  @override
  String get gameUpgrade => 'Nâng cấp';

  @override
  String get gameUpgradeTitle => 'Nâng cấp cấp độ';

  @override
  String get gameUpgradeCurrentLevel => 'Cấp độ hiện tại';

  @override
  String get gameUpgradeTargetLevel => 'Cấp độ mục tiêu';

  @override
  String get gameUpgradeHeatThreshold => 'Lượt xem hết drama tích lũy';

  @override
  String get gameUpgradeRequiredCount => 'Tiêu thụ role cùng IP cùng cấp';

  @override
  String get gameUpgradeFee => 'Phí nâng cấp';

  @override
  String get gameUpgradeNextLevelReq => 'Yêu cầu cấp độ tiếp theo';

  @override
  String get gameUpgradeBeforeAfter => 'So sánh trước và sau nâng cấp';

  @override
  String get gameUpgradeSelectMaterialDesc =>
      'Chọn role cùng IP cùng cấp để tiêu thụ';

  @override
  String gameUpgradeMaterialCount(int current, int required) {
    return '$current/$required';
  }

  @override
  String gameUpgradeToLevel(int level, String levelName) {
    return 'Nâng cấp lên Lv$level $levelName';
  }

  @override
  String gameUpgradeSelectMaterialLabel(int current, int required) {
    return 'Chọn vật liệu ($current/$required)';
  }

  @override
  String gameUpgradeSelectMaterials(int count) {
    return 'Vui lòng chọn $count vật liệu';
  }

  @override
  String get gameUpgradeConfirm => 'Xác nhận nâng cấp';

  @override
  String get gameUpgradeSuccess => 'Nâng cấp thành công';

  @override
  String get gameUpgradeFailed => 'Nâng cấp thất bại, vui lòng thử lại';

  @override
  String get gameUpgradeInsufficientMaterials => 'Không đủ vật liệu';

  @override
  String get gameUpgradeNoMaterials =>
      'Không có role cùng IP và cấp độ để tiêu hao';

  @override
  String get creatorDramaStatusMinted => 'Đã đúc';

  @override
  String get creatorDramaStatusOffline => 'Đã gỡ';

  @override
  String get creatorDramaStatusUnavailable => 'Tạm thời không khả dụng';

  @override
  String get creatorMintDramaNft => 'Đúc NFT phim';

  @override
  String get creatorMintConfirmDesc =>
      'Xác nhận đúc phim này thành NFT trên chuỗi. Sau khi đúc, phim này sẽ tạo ra phần thưởng khai thác STORY.';

  @override
  String get creatorMintFee => 'Phí đúc';

  @override
  String creatorMintInsufficientUsdc(String currency1, String currency2) {
    return 'Số dư $currency1 không đủ. Ra mắt on-chain cần ít nhất 1 $currency2.';
  }

  @override
  String get creatorMintInvalidDramaId => 'ID phim không hợp lệ';

  @override
  String get creatorMintInProgress => 'Đang đúc, vui lòng chờ';

  @override
  String get creatorMintWalletNotReady =>
      'Địa chỉ ví Solana chưa sẵn sàng. Vui lòng đăng nhập lại';

  @override
  String get creatorMintDigestEmpty =>
      'Dữ liệu chữ ký ra mắt trống, vui lòng thử lại sau';

  @override
  String get creatorMintWalletMismatch =>
      'Ví đúc không khớp với ví hiện tại. Vui lòng đăng nhập lại';

  @override
  String get creatorMintSuccess => 'Đúc thành công!';

  @override
  String creatorMintDramaOnChain(String name) {
    return 'NFT phim \"$name\" đã được đúc lên chuỗi';
  }

  @override
  String creatorMintNftNumber(String id) {
    return 'Số NFT: $id';
  }

  @override
  String get creatorMintTxHash => 'Mã giao dịch: ';

  @override
  String get gameSelectActor => 'Chọn role triển khai';

  @override
  String get gameSelectActorDesc => 'Chọn một nhân vật đang rảnh để cử đi';

  @override
  String get agentV2SchedulePerformance => 'Biểu diễn';

  @override
  String get agentV2PerformAllTitle => 'Tự động biểu diễn';

  @override
  String get agentV2PerformAllDescription =>
      'Nhân vật có cát-xê cao hơn sẽ được xếp vào vị trí trống trước';

  @override
  String get agentV2PerformAllFailed =>
      'Biểu diễn một chạm thất bại. Vui lòng thử lại';

  @override
  String get agentV2PerformAllSuccess => 'Biểu diễn một chạm thành công';

  @override
  String agentV2PerformAllDepletedResult(int successCount, int depletedCount) {
    return '$successCount diễn viên biểu diễn thành công, $depletedCount diễn viên tạm thời không thể biểu diễn do hết thể lực';
  }

  @override
  String get agentV2RestAllSuccess => 'Nghỉ một chạm thành công';

  @override
  String agentV2PerformAllCount(int count) {
    return '$count nhân vật';
  }

  @override
  String get agentV2TodoTitle => 'Việc cần làm';

  @override
  String agentV2TodoVacancies(int count) {
    return 'Còn $count vị trí biểu diễn trống';
  }

  @override
  String agentV2TodoStaminaDepleted(String name) {
    return '$name đã hết năng lượng (0) và ngừng làm việc';
  }

  @override
  String get agentV2TodoPerform => 'Biểu diễn';

  @override
  String get agentV2TodoRefill => 'Bổ sung';

  @override
  String get agentV2TodoHealthy => 'Biểu diễn bình thường · Đủ thể lực';

  @override
  String get agentV2CandidateActorsTitle => 'Vai diễn ứng viên';

  @override
  String get agentV2CandidateActorsDescription =>
      'Vai diễn đang nghỉ hồi 1 thể lực mỗi giờ';

  @override
  String get agentV2UpgradeableActorsTitle => 'Nâng cấp vai diễn';

  @override
  String get agentV2UpgradeableActorsEmpty => 'Không có vai diễn để nâng cấp';

  @override
  String get agentV2NoActors => 'Chưa có vai diễn';

  @override
  String get agentV2UpgradeNow => 'Nâng cấp ngay';

  @override
  String get agentV2UpgradeCompletion => 'Lượt xem hết';

  @override
  String get agentV2UpgradeMaterials => 'Vai diễn';

  @override
  String agentV2UpgradeRequirementsTitle(String name) {
    return 'Nâng cấp $name';
  }

  @override
  String agentV2UpgradeCompletionRemaining(int count) {
    return 'Cần thêm $count lượt xem hết';
  }

  @override
  String get agentV2UpgradeCompletionHint =>
      'Xem phim có nhân vật này hoặc tạo phim mới cho họ để tăng lượt xem hết';

  @override
  String get agentV2UpgradeWatchDramas => 'Xem phim đã tham gia';

  @override
  String get agentV2UpgradeCreateDrama => 'Tạo phim ngắn';

  @override
  String agentV2UpgradeMaterialsRemaining(int count) {
    return 'Cần thêm $count vai cùng IP và cùng cấp';
  }

  @override
  String agentV2UpgradeMaterialsHint(String name) {
    return 'Ký thêm nhân vật “$name” từ trang nhân vật';
  }

  @override
  String get agentV2UpgradeGetActors => 'Nhận vai diễn';

  @override
  String agentV2UpgradeActorsSyncing(int count) {
    return 'Đang đồng bộ $count nhân vật mới; điều kiện nâng cấp đã được cập nhật';
  }

  @override
  String get agentV2UpgradeConfirmSelectMaterials =>
      'Chọn nhân vật cùng IP và cấp độ để tiêu hao';

  @override
  String get agentV2UpgradeConfirmSalaryLabel => 'Cát-xê';

  @override
  String get agentV2SalaryDetailTitle => 'Chi tiết cát-xê nhân vật';

  @override
  String get agentV2SalaryHourly => 'Cát-xê mỗi giờ';

  @override
  String get agentV2SalaryUnit => 'STORY / giờ';

  @override
  String get agentV2SalaryFormula =>
      'Cát-xê nhân vật = Cát-xê IP × Hệ số cát-xê × Hệ số CP × Trust2';

  @override
  String get agentV2SalaryFormulaLv1 =>
      'Cát-xê nhân vật cấp 1 = Hệ số giá × Hệ số độ hot';

  @override
  String agentV2SalaryFormulaLevel(int level) {
    return 'Cát-xê cấp $level = Cát-xê cấp 1 × Hệ số cát-xê';
  }

  @override
  String get agentV2SalaryLv1Pay => 'Lv.1 Cát-xê';

  @override
  String get agentV2SalaryCoefficient => 'Hệ số cát-xê';

  @override
  String agentV2SalaryCoefficientWithLevel(int level, String roleName) {
    return 'Hệ số cát-xê (Lv.$level $roleName)';
  }

  @override
  String get agentV2SalaryCpCoefficient => 'Hệ số CP';

  @override
  String get agentV2PerformanceConfirmDescription =>
      'Nhân vật này tự động kiếm cát-xê khi biểu diễn. Mỗi giờ biểu diễn tiêu hao 1 điểm thể lực; khi hết thể lực sẽ ngừng kiếm thu nhập.';

  @override
  String get agentV2PerformanceConfirmTitle => 'Sắp xếp biểu diễn';

  @override
  String get agentV2PerformanceZeroFeePrefix => 'IP của nhân vật này hiện ';

  @override
  String get agentV2PerformanceZeroFeeHighlight => 'cát-xê là 0';

  @override
  String get agentV2PerformanceZeroFeeSuffix =>
      ', buổi biểu diễn sẽ không mang lại doanh thu. Ngoài ra mỗi giờ biểu diễn tiêu tốn 1 điểm thể lực. Bạn có muốn tiếp tục không?';

  @override
  String get agentV2PerformanceScheduledSuccess => 'Đã sắp xếp biểu diễn';

  @override
  String get agentV2PerformanceSlotsFull =>
      'Các vị trí biểu diễn đã đầy (tối đa 5)';

  @override
  String get gameDeployStaminaDepleted =>
      'Thể lực đã cạn. Hãy bổ sung thể lực trước khi biểu diễn';

  @override
  String get agentMoreRules => 'Quy tắc';

  @override
  String get agentMoreSalaryAndPool => 'Cát-xê và quỹ thưởng';

  @override
  String get agentV2WeeklySalaryTitle => 'Lên cấp · Biểu diễn · Kiếm cát-xê';

  @override
  String get agentV2WeeklySalaryLabel => 'Cát-xê tuần này';

  @override
  String get gameDeployConfirmDesc =>
      'Nhân vật này sẽ tự động tham gia khai thác staking và liên tục tạo lợi nhuận STORY cho bạn. Lưu ý: Mỗi đầu giờ sẽ tiêu hao 1 điểm thể lực. Khi hết thể lực, việc tạo lợi nhuận sẽ dừng lại.';

  @override
  String get gameRecallConfirm => 'Xác nhận triệu hồi';

  @override
  String get gameRecallDesc =>
      'Triệu hồi nhân vật này sẽ tạm dừng phần thưởng sản xuất phim, nhưng thể lực hiện tại không bị ảnh hưởng.';

  @override
  String get actorStatCompletionTitle => 'Lượt xem hết';

  @override
  String get actorStatCompletionDesc =>
      'Tổng số lượt xem hết trên tất cả các phim mà nhân vật này tham gia';

  @override
  String get actorStatHeatTitle => 'Độ hot';

  @override
  String get actorStatHeatDesc =>
      'Tổng độ hot trong 30 ngày gần nhất của tất cả phim ngắn mà IP nhân vật này tham gia';

  @override
  String get actorStatIpPowerTitle => 'Cát-xê IP';

  @override
  String get actorStatIpPowerDesc =>
      'Cát-xê IP = Hệ số giá × Hệ số độ nổi tiếng × Trust1';

  @override
  String get dramaFavoriteLabel => 'Yêu thích';

  @override
  String get dramaRatingLabel => 'Đánh giá';

  @override
  String get dramaUnnamed => 'Chưa đặt tên';

  @override
  String get videoNotReady => 'Video chưa sẵn sàng, vui lòng thử lại sau';

  @override
  String get inviteDirectSubordinates => 'Người dùng đã mời';

  @override
  String inviteTotalCount(int count) {
    return 'Tổng cộng: $count người dùng';
  }

  @override
  String get inviteTotalLabel => 'Tổng số người dùng';

  @override
  String get inviteActiveLabel => 'Người dùng hoạt động';

  @override
  String get invitePendingLabel => 'Chờ kích hoạt';

  @override
  String get inviteEmpty => 'Chưa có người dùng cấp dưới';

  @override
  String inviteRegisteredAt(String date) {
    return 'Đăng ký vào $date';
  }

  @override
  String get gameUpgradeMaxLevel => 'Đã đạt cấp độ cao nhất';

  @override
  String get listNoMoreData => 'Không còn dữ liệu';

  @override
  String get iapSheetTitle => 'Mua điểm';

  @override
  String get iapSheetSubtitle =>
      'Điểm được dùng cho các dịch vụ trong ứng dụng như ký hợp đồng nhân vật';

  @override
  String get iapBalance => 'Số dư';

  @override
  String get iapConfirmPurchase => 'Xác nhận mua';

  @override
  String get iapPurchaseSuccess => 'Mua thành công';

  @override
  String get iapPurchaseFailed => 'Mua thất bại, vui lòng thử lại';

  @override
  String get iapPurchaseFailedTitle => 'Mua thất bại';

  @override
  String get iapCrediting => 'Đang xử lý ghi có, vui lòng chờ';

  @override
  String get iapNoProducts => 'Không có sản phẩm nào khả dụng';

  @override
  String get iapSuccessConfirm => 'OK';

  @override
  String iapGainedPoints(String value) {
    return '+$value';
  }

  @override
  String iapPointsCount(int count) {
    return '$count điểm';
  }

  @override
  String get gameBatchRefillTransactionTooLarge =>
      'Giao dịch phục hồi thể lực hàng loạt quá lớn. Hãy giảm số diễn viên và thử lại.';

  @override
  String get agentV2RefillTitle => 'Bổ sung thể lực';

  @override
  String get agentV2RefillCost => 'Chi phí';

  @override
  String get agentV2RefillActorButton => 'Nhân vật này';

  @override
  String get agentV2RefillAllActors => 'Bổ sung cho tất cả nhân vật đang diễn';

  @override
  String agentV2RefillActorCount(int count) {
    return '$count nhân vật';
  }

  @override
  String get agentV2RefillAllButton => 'Bổ sung tất cả';

  @override
  String get agentV2RefillOr => 'hoặc';

  @override
  String get agentV2RestAll => 'Nghỉ tất cả';

  @override
  String agentV2RestActorCount(int count) {
    return '$count nhân vật';
  }

  @override
  String get salaryPoolRateUnit => 'STORY / giờ';

  @override
  String get salaryPoolDecayInfo => 'Hệ số suy giảm theo tuần ×0.99572';

  @override
  String get salaryPoolStakeLabel => 'Quỹ thưởng biểu diễn (75%)';

  @override
  String get salaryPoolInviteLabel => 'Quỹ thưởng mời tham gia (25%)';

  @override
  String get salaryPoolRule1Title =>
      'Tổng sản lượng danh nghĩa ≤ trần cứng theo tuần:';

  @override
  String get salaryPoolRule2Title =>
      'Tổng sản lượng danh nghĩa > trần cứng theo tuần:';

  @override
  String get salaryPoolRule2Body =>
      'Thực nhận của người dùng = sản lượng danh nghĩa người dùng × (trần cứng theo tuần ÷ tổng sản lượng danh nghĩa toàn mạng)';

  @override
  String get agentV3WeeklySalary => 'Cát-xê tuần';

  @override
  String get agentV3PerformAll => 'Diễn tất cả';

  @override
  String get agentV3RestAll => 'Nghỉ tất cả';

  @override
  String get agentV3RestAllDescription =>
      'Thu hồi tất cả nhân vật đang biểu diễn để dừng tiêu hao thể lực và sản lượng';

  @override
  String get agentV3RefillAll => 'Bổ sung tất cả';

  @override
  String get agentV3RefillAllDescription =>
      'Nạp đầy thể lực cho các nhân vật đang diễn';

  @override
  String get agentV3RefillCost => 'Tiêu hao';

  @override
  String get agentV3RefillNoActors =>
      'Không có nhân vật nào cần bổ sung thể lực';

  @override
  String get agentV3SignActor => 'Ký nhân vật';

  @override
  String get agentV3Todo => 'Việc cần làm';

  @override
  String get agentV3Upgrade => 'Nâng cấp';

  @override
  String agentV3UpgradeMaterialHint(int count) {
    return 'Nâng cấp cần tiêu hao $count nhân vật cùng IP và cấp độ';
  }

  @override
  String get agentV3Waiting => 'Chờ diễn';

  @override
  String get agentV3WaitingActorsTitle => 'Nhân vật chờ';

  @override
  String get agentV3WaitingActorsDescription =>
      'Nhân vật đang nghỉ hồi 1 thể lực mỗi giờ';

  @override
  String get agentV3Recycle => 'Thu hồi';

  @override
  String get agentV3RecycleActorsTitle => 'Thu hồi nhân vật';

  @override
  String get agentV3RecyclePerforming => 'Đang diễn';

  @override
  String get agentV3RecycleReceive => 'Bạn sẽ nhận được';

  @override
  String get agentV3RecyclePermanentWarning =>
      'Nhân vật sẽ bị tiêu hủy vĩnh viễn và không thể khôi phục';

  @override
  String get agentV3RecycleConfirm => 'Xác nhận tiêu hủy';

  @override
  String get agentV3RecycleConfirmAgain => 'Nhấn lần nữa để tiêu hủy';

  @override
  String get agentV3RecycleSubmitted => 'Thu hồi nhân vật thành công';

  @override
  String get agentV3RecycleEstimateUnavailable =>
      'Không thể lấy ước tính thu hồi. Vui lòng thử lại';

  @override
  String get agentV3EnergyPack => 'Gói hồi thể lực';

  @override
  String get agentV3EnergyPackDescription =>
      'Hồi đầy thể lực nhân vật, được tiêu hao theo cấp nhân vật.';

  @override
  String get agentV3TrainingManual => 'Sổ tay huấn luyện';

  @override
  String get agentV3TrainingManualDescription =>
      'Nguyên liệu nâng cấp nhân vật, được tiêu hao theo cấp nhân vật khi nâng cấp.';

  @override
  String get agentV3PurchaseButton => 'Mua';

  @override
  String agentV3PurchaseWalletBalance(String balance, String currency) {
    return 'Số dư $balance $currency';
  }

  @override
  String agentV3PurchaseTitle(String item) {
    return 'Mua $item';
  }

  @override
  String get agentV3PurchaseUnitPrice => 'Đơn giá';

  @override
  String get agentV3PurchaseQuantity => 'Số lượng';

  @override
  String get agentV3PurchaseTotal => 'Tổng cộng';

  @override
  String get agentV3PurchaseConfirm => 'Xác nhận thanh toán';

  @override
  String get agentV3PurchaseUnavailable =>
      'Môi trường hiện tại chưa hỗ trợ mua vật phẩm';

  @override
  String get agentV3PurchaseConfigUnavailable =>
      'Giá vật phẩm hiện không khả dụng. Vui lòng thử lại sau';

  @override
  String get agentV3PurchaseSubmitted =>
      'Mua thành công. Đã thêm vào túi vật phẩm (trang Đại diện)';

  @override
  String get agentV3PurchaseCreditPending =>
      'Gói thể lực vẫn đang được ghi có. Vui lòng thử lại sau';

  @override
  String get agentV3PurchaseCrediting => 'Đang quét chuỗi và ghi có';

  @override
  String agentV3PurchaseBalance(String count) {
    return 'Đang có: $count';
  }

  @override
  String get agentV3RefillTitle => 'Hồi đầy thể lực';

  @override
  String agentV3RefillLevelCost(String level) {
    return 'Lv.$level tiêu hao';
  }

  @override
  String get agentV3RefillAvailable => 'Khả dụng';

  @override
  String get agentV3RefillUse => 'Sử dụng';

  @override
  String get agentV3RefillSuccess => 'Đã hồi đầy thể lực';

  @override
  String agentV3RefillAllSuccess(int actorCount, String packCount) {
    return 'Đã bổ sung thể lực cho $actorCount nhân vật (đã dùng $packCount gói thể lực)';
  }

  @override
  String get agentV3RefillConfigUnavailable =>
      'Cấu hình tiêu hao gói thể lực không khả dụng';

  @override
  String get agentV3RefillInsufficient => 'Không đủ gói thể lực';
}
