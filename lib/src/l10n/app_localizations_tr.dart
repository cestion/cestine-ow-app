// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'StoryFun';

  @override
  String get commonCancel => 'İptal et';

  @override
  String get commonNoData => 'Veri yok';

  @override
  String get commonNo => 'Hayır';

  @override
  String get commonYes => 'Evet';

  @override
  String get publishDrama => 'Dram Yayınla';

  @override
  String get publishVideo => 'Video Yayınla';

  @override
  String get publishVideoUploadTitle => 'Video dosyası yükle';

  @override
  String get publishVideoFileHint =>
      'mp4, flv, wmv, mkv, avi, mov ve webm desteklenir. En fazla 2GB';

  @override
  String get publishVideoChooseFile => 'Dosya seç';

  @override
  String get publishVideoChangeFile => 'Dosyayı değiştir';

  @override
  String get publishVideoChooseSource => 'Video kaynağını seç';

  @override
  String get publishVideoChooseFromGallery => 'Galeriden seç';

  @override
  String get publishVideoChooseFromFiles => 'Dosyalardan seç';

  @override
  String get publishVideoPreparing => 'Video hazırlanıyor…';

  @override
  String get publishVideoCoverTitle => 'Video kapağı';

  @override
  String get publishVideoChangeCover => 'Kapağı değiştir';

  @override
  String get publishVideoCoverHint => 'JPG/PNG, en fazla 5MB';

  @override
  String get publishVideoDescriptionLabel => 'Açıklama';

  @override
  String get publishVideoRequired => '(Zorunlu)';

  @override
  String get publishVideoDescriptionHint =>
      'Açıklama ekle (en fazla 200 karakter)';

  @override
  String get publishVideoSaveDraft => 'Taslağı kaydet';

  @override
  String get publishVideoDraftEditModeNotSupported =>
      'Düzenleme modunda taslak kaydedilemez';

  @override
  String get publishVideoDraftNothingToSave => 'Kaydedilecek bir şey yok';

  @override
  String get publishVideoNext => 'İleri';

  @override
  String get publishVideoCoverCropTitle => 'Video kapağını kırp';

  @override
  String get publishVideoVideoTooLarge => 'Video dosyası 2GB\'ı aşamaz';

  @override
  String get publishVideoVideoPickFailed => 'Video seçilemedi. Tekrar deneyin';

  @override
  String get publishVideoInsufficientStorage =>
      'Bu videoyu hazırlamak için cihazda yeterli alan yok';

  @override
  String get publishVideoPermissionDenied =>
      'Videoya erişilemedi. Fotoğraf veya dosya izinlerini kontrol edin';

  @override
  String get publishVideoSourceUnavailable =>
      'Bu video şu anda kullanılamıyor. Bulut dosyasını indirip tekrar deneyin';

  @override
  String get publishVideoPrepareFailed =>
      'Video hazırlanamadı. Tekrar deneyin veya Dosyalar\'dan seçin';

  @override
  String get publishVideoMetadataUnavailable =>
      'Video bilgileri okunamadı. Başka bir dosya seçin';

  @override
  String get publishVideoCoverTooLarge => 'Kapak resmi 5MB\'ı aşamaz';

  @override
  String get publishVideoCoverUnsupportedFormat =>
      'Yalnızca JPG/PNG görseller desteklenir';

  @override
  String get publishVideoCoverPickFailed => 'Kapak seçilemedi. Tekrar deneyin';

  @override
  String get publishVideoUploadSessionFailed =>
      'Yükleme oturumu oluşturulamadı';

  @override
  String get publishVideoPublishedSuccess => 'Video yayınlandı';

  @override
  String get publishVideoUpdatedSuccess => 'Video güncellendi';

  @override
  String get publishActorIp => 'IP Çıkışı';

  @override
  String get commonConfirm => 'Onayla';

  @override
  String get commonOk => 'Tamam';

  @override
  String get commonNotice => 'Bilgi';

  @override
  String get commonRetry => 'Yeniden dene';

  @override
  String get publicProfileLikedEmpty => 'Henüz beğenilen dizi yok';

  @override
  String get profileTabDramas => 'Kısa Diziler';

  @override
  String get profileTabWorks => 'Eserler';

  @override
  String get profileTabActorIp => 'Karakter IP';

  @override
  String dramaUnlockConfirmLabel(String price, String currency) {
    return '$price $currency ile kilidi aç';
  }

  @override
  String dramaAllEpisodes(int count) {
    return '$count bölüm';
  }

  @override
  String dramaAllEpisodesFull(Object count) {
    return 'Tüm $count bölüm';
  }

  @override
  String get dramaLoading => 'Öne çıkan diziler yükleniyor...';

  @override
  String get dramaEmpty => 'Şu anda kısa dizi yok';

  @override
  String get dramaRefresh => 'Yenile';

  @override
  String get navTheater => 'Tiyatro';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get theaterTabShortDrama => 'Dram';

  @override
  String get theaterTabRecommend => 'Senin İçin';

  @override
  String get playerWatchFullDrama => 'Tüm dramayı izle';

  @override
  String get playerStoryPerHourUnit => 'STORY/h';

  @override
  String get navNft => 'IP Pazarı';

  @override
  String get navNftIp => 'Karakter IP\'si';

  @override
  String watchFullDramaEpisodes(int count) {
    return 'Dramayı İzle · Toplam $count Böl';
  }

  @override
  String get navCreate => 'Yaratım';

  @override
  String get navProfile => 'Profil';

  @override
  String get navMy => 'Menajer';

  @override
  String get aboutTitle => 'Hakkımızda';

  @override
  String get aboutVision => 'AI · Web3 · Protokol';

  @override
  String get aboutVisionDesc =>
      'Üç itici güç, anlatıyı pasif bir deneyimden aktif bir üretime dönüştürüyor';

  @override
  String get aboutAiDesc => 'Düşüncelerin, kendiliğinden hikayeye dönüşüyor';

  @override
  String get aboutWeb3Desc => 'Yarattıkların, her zaman sana aittir';

  @override
  String get aboutProtocolDesc => 'Hikayen sonsuza dek devam edebilir';

  @override
  String get aboutIdentityTitle => 'Anlatıcı kimliğiniz';

  @override
  String get aboutIdentityDesc =>
      'Sen, başlı başına gelişmekte olan bir hikâye evrenisin';

  @override
  String get aboutIdentityCreator => 'Yaratıcı';

  @override
  String get aboutIdentityCreatorDesc => 'Kendi öyküsünü aktif olarak yazmak';

  @override
  String get aboutIdentityWitness => 'Tanık';

  @override
  String get aboutIdentityWitnessDesc =>
      'Başkalarının anlatılarına katılmak ve bunları doğrulamak';

  @override
  String get aboutIdentityCoCreator => 'Ortak yaratıcı';

  @override
  String get aboutIdentityCoCreatorDesc =>
      'Anlatı yapısına girip yeniden yazmak';

  @override
  String get aboutIdentitySpreader => 'Yaygınlaştırıcı';

  @override
  String get aboutIdentitySpreaderDesc => 'Hak ettiğin hikayeyi anlat';

  @override
  String get aboutTokenomicsTitle => 'STORY: Anlatım Hakkı Token';

  @override
  String get aboutTokenomicsDesc =>
      'Yapay zeka dizilerinin ortak yapımcısı olarak film ve televizyon sektörü kar dağılımını yeniden şekillendirin.';

  @override
  String get aboutTokenomicsGov => 'Yönetim yetkisi';

  @override
  String get aboutTokenomicsGovDesc =>
      'Oylama ile bir sonraki AI kısa dizisinin konusunu ve gidişatını belirleyin';

  @override
  String get aboutTokenomicsRevenue => 'Gelir hakkı';

  @override
  String get aboutTokenomicsRevenueDesc =>
      'Paylaşım platformu abonelikleri, telif hakkı lisansları ve yan ürün satışlarından elde edilen gelir';

  @override
  String get aboutTokenomicsAccess => 'Erişim hakkı';

  @override
  String get aboutTokenomicsAccessDesc =>
      'En yeni bölümleri ilk izleyen siz olun, özel içeriklere erişin';

  @override
  String get aboutStakingTitle => 'Rehin payı';

  @override
  String get aboutStakingDesc =>
      'Dizi NFT · Karakter NFT · STORY → Stake ile temettü kazanın';

  @override
  String get aboutStakingDrama => 'Dizi NFT Stake';

  @override
  String get aboutStakingDramaDesc => 'Kısa dizi yaratıcısı · Gelir paylaşımı';

  @override
  String get aboutStakingActor => 'Karakter NFT Stake';

  @override
  String get aboutStakingActorDesc =>
      'Roller kısa filmlerde rol alır · Gelir payı alır';

  @override
  String get aboutStakingStory => 'STORY Stake';

  @override
  String get aboutStakingStoryDesc =>
      'Kısa videolara yatırım · Gelir paylaşımı';

  @override
  String get aboutHeroTitle => 'Kendi Hikayeni Yarat';

  @override
  String get aboutHeroDesc =>
      'Hayatın deneyimlenecek bir senaryo değil, senin yazdığın bir anlatıdır';

  @override
  String get loginTitle => 'E-posta Girişi';

  @override
  String get loginSubtitle =>
      'Privy e-posta OTP ile giriş yapın, Solana gömülü cüzdanı otomatik oluşturun.';

  @override
  String get loginPlaceholder => 'E-posta adresinizi girin';

  @override
  String get loginEmailHintFormat => 'sizin@eposta.com';

  @override
  String get loginVerificationFailed => 'Doğrulama başarısız';

  @override
  String get loginNeedCodeFirst => 'Lütfen önce bir doğrulama kodu isteyin';

  @override
  String get loginCreateWalletFailed => 'Cüzdan oluşturulamadı';

  @override
  String get loginGetTokenFailed => 'Erişim jetonu alınamadı';

  @override
  String get loginPrivyUnavailable =>
      'Giriş hizmeti kullanılamıyor. Lütfen uygulamayı yeniden başlatıp tekrar deneyin';

  @override
  String get loginSendCodeFailed =>
      'Doğrulama kodu gönderilemedi. Lütfen daha sonra tekrar deneyin';

  @override
  String get loginTooManyRequests =>
      'Çok fazla istek. Lütfen bekleyip tekrar deneyin';

  @override
  String get loginVerificationSuccessful => 'Doğrulama başarılı';

  @override
  String get loginSendCode => 'Kod al';

  @override
  String get loginSendingCode => 'Gönderiliyor...';

  @override
  String get loginCodePlaceholder => '6 haneli doğrulama kodunu girin';

  @override
  String get loginSubmit => 'Giriş yap';

  @override
  String get loginSubmitting => 'Giriş yapılıyor...';

  @override
  String get loginEmailRequired => 'Lütfen e-posta adresinizi girin';

  @override
  String get loginCodeRequired => 'Lütfen doğrulama kodunu girin';

  @override
  String get loginSuccess => 'Giriş başarılı';

  @override
  String get loginErrorPrefix => 'Giriş hatası: ';

  @override
  String loginCodeSent(String email) {
    return 'Doğrulama kodu $email adresine gönderildi';
  }

  @override
  String get loginEmailLabel => 'E-posta';

  @override
  String get loginCodeLabel => 'Doğrulama Kodu';

  @override
  String get loginVerifying => 'Doğrulanıyor, lütfen bekleyin...';

  @override
  String get loginVerifyAndSubmit => 'Doğrula ve Giriş Yap';

  @override
  String get loginChangeEmail => 'E-posta Değiştir';

  @override
  String get loginNotNow => 'Şimdi Değil';

  @override
  String get loginInvalidEmail => 'Lütfen geçerli bir e-posta adresi girin';

  @override
  String get profileTitle => 'Menajer';

  @override
  String get profileNotLoggedIn => 'Giriş Yapılmadı';

  @override
  String get profileClickLogin => 'Giriş Yap / Kayıt Ol';

  @override
  String get profileMyWallet => 'Cüzdanım';

  @override
  String get profileWallet => 'Cüzdan';

  @override
  String get profileTradeStory => 'STORY işlem';

  @override
  String get profileWalletCreating => 'Oluşturuluyor...';

  @override
  String get walletNetworkSolana => 'Solana';

  @override
  String get walletNetworkEvm => 'EVM';

  @override
  String get profileEarnings => 'Gelir';

  @override
  String get profileMyNft => 'NFT\'lerim';

  @override
  String get profileMyFavorites => 'Favorilerim';

  @override
  String get profileWatchHistory => 'İzleme Geçmişi';

  @override
  String get profileCreatorCatalog => 'Yaratıcılar';

  @override
  String get profileIdentityAuth => 'Kimlik Doğrulama';

  @override
  String get profileAccountSecurity => 'Hesap Güvenliği';

  @override
  String get profileLanguage => 'Dil';

  @override
  String get profileAboutUs => 'Hakkımızda';

  @override
  String get profileHelpFeedback => 'Yardım ve Geri Bildirim';

  @override
  String get profileLogout => 'Çıkış Yap';

  @override
  String get profileLogoutConfirm =>
      'Çıkış yapmak istediğinizden emin misiniz?';

  @override
  String get profileLogoutSuccess => 'Başarıyla çıkış yapıldı';

  @override
  String get mainPressBackAgainToExit =>
      'Çıkmak için geri düğmesine tekrar basın';

  @override
  String get languageSelectTitle => 'Dil Seçin';

  @override
  String get languageChinese => 'Basitleştirilmiş Çince';

  @override
  String get languageEnglish => 'İngilizce';

  @override
  String get searchTitle => 'Ara';

  @override
  String get searchHint => 'Dizi, eser, rol, kullanıcı ara...';

  @override
  String get searchEmpty => 'İlgili içerik yok';

  @override
  String get searchNoData => 'İlgili içerik yok';

  @override
  String get searchPlaceholder => 'Dizi, eser, rol, kullanıcı ara...';

  @override
  String get theaterSearchPlaceholder => 'Dizi, eser, rol, kullanıcı ara...';

  @override
  String get searchHistory => 'Son aramalar';

  @override
  String get searchClear => 'Geçmişi temizle';

  @override
  String get searchAction => 'Ara';

  @override
  String get searchHistoryCleared => 'Arama geçmişi temizlendi';

  @override
  String get searchKeywordTooShort => 'En az 2 karakter girin';

  @override
  String get searchTabDramas => 'Diziler';

  @override
  String get searchTabWorks => 'Eserler';

  @override
  String get searchTabActors => 'Karakter IP';

  @override
  String get searchTabUsers => 'Kullanıcılar';

  @override
  String searchEpisodeNo(int episodeNo) {
    return 'Bölüm $episodeNo';
  }

  @override
  String searchMinutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String searchHoursAgo(int count) {
    return '$count sa önce';
  }

  @override
  String searchDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String searchDramasCount(int count) {
    return 'Dramalar ($count)';
  }

  @override
  String searchActorsCount(int count) {
    return 'Roller ($count)';
  }

  @override
  String searchDramaEpisodesWithCast(int count, String actors) {
    return '$count bölüm | Kadro: $actors';
  }

  @override
  String get nftTitle => 'NFT Rol Meydanı';

  @override
  String get nftLoading => 'Karakter IP\'leri yükleniyor...';

  @override
  String get nftEmpty => 'Karakter IP\'si yok';

  @override
  String get nftRefresh => 'Yenile';

  @override
  String nftIdPrefix(String id) {
    return 'ID: #$id';
  }

  @override
  String get nftRarity => 'Nadirlik';

  @override
  String get nftStatusStaked => 'Rehinli';

  @override
  String get nftStatusIdle => 'Boşta';

  @override
  String get nftPrice => 'Fiyat';

  @override
  String get dramaDetailTitle => 'Drama Detayları';

  @override
  String get dramaDetailLoading => 'Yükleniyor…';

  @override
  String get dramaDetailRetry => 'Tekrar dene';

  @override
  String get dramaDetailEpisodeList => 'Dizi Listesi';

  @override
  String get dramaDetailSynopsis => 'Özet';

  @override
  String get dramaDetailExpand => 'Genişlet';

  @override
  String get dramaDetailCollapse => 'Kapat';

  @override
  String get dramaDetailTabIntro => 'Tanıtım';

  @override
  String get dramaDetailTabEpisodes => 'Seçkiler';

  @override
  String get dramaDetailTabComments => 'Yorumlar';

  @override
  String get dramaDetailTabRoles => 'Karakter IP’si';

  @override
  String get dramaDetailSignMoreCharacterIps =>
      'Daha fazla karakter IP\'si imzala';

  @override
  String get dramaDetailCharactersEmpty => 'Henüz bağlı karakter IP\'si yok';

  @override
  String dramaDetailRoleSalary(String amount) {
    return 'Ücret $amount';
  }

  @override
  String dramaDetailRoleSalaryPerHour(String amount) {
    return 'Ücret $amount STORY/saat';
  }

  @override
  String get dramaDetailRoleUnbound => 'Bağlı değil';

  @override
  String get dramaCastActorsTitle => 'Oyuncu karakter IP\'leri';

  @override
  String dramaDetailCompletion(String count) {
    return '$count tam izlenme';
  }

  @override
  String dramaDetailHeat(String count) {
    return '$count popülerlik';
  }

  @override
  String dramaDetailTotalEpisodes(int count) {
    return '$count Bölüm';
  }

  @override
  String get dramaDetailRatingTitle => 'Eseri oy ver';

  @override
  String get dramaDetailWantToRate => 'Puan ver';

  @override
  String get dramaDetailNotRated => 'Puan yok';

  @override
  String get dramaDetailCompletionLabel => 'Tam izlenme';

  @override
  String get dramaDetailHeatLabel => 'Popülerlik';

  @override
  String get dramaDetailSynopsisLead => 'Özet: ';

  @override
  String get dramaDetailRatingEmpty => 'Değerlendirmeniz: --';

  @override
  String dramaDetailRatingValue(int rating) {
    return 'Değerlendirmeniz: $rating';
  }

  @override
  String get dramaDetailRatingConfirm => 'Değerlendirmeyi Onayla';

  @override
  String dramaDetailRatingSuccess(int rating) {
    return 'Değerlendirme başarılı: $rating yıldız!';
  }

  @override
  String get dramaDetailSelectEpisodeHint =>
      'Oynatmayı başlatmak için bir bölüm seçin';

  @override
  String get dramaFavorited => 'Favorilere eklendi';

  @override
  String get dramaUnfavorited => 'Favorilerden kaldırıldı';

  @override
  String get dramaLiked => 'Beğenildi';

  @override
  String get dramaUnliked => 'Beğeni kaldırıldı';

  @override
  String get playerFollowed => 'Takip edildi';

  @override
  String get playerUnfollowed => 'Takipten çıkıldı';

  @override
  String get errorNetwork => 'Ağ hatası, lütfen daha sonra tekrar deneyin';

  @override
  String get errorTimeout =>
      'İstek zaman aşımına uğradı, lütfen tekrar deneyin';

  @override
  String get errorParse => 'Yanıt verileri ayrıştırılamadı';

  @override
  String get errorUnauthorized => 'Lütfen önce giriş yapın';

  @override
  String get authSessionExpired =>
      'Oturum süresi doldu. Lütfen tekrar giriş yapın';

  @override
  String get errorNotFound => 'Kaynak bulunamadı';

  @override
  String get iapOrderInFlight =>
      'Bu ürün için tamamlanmamış bir siparişiniz var, lütfen daha sonra tekrar deneyin';

  @override
  String get errorOperationFailed => 'İşlem başarısız';

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
      'Geçersiz karakter ID\'si. Lütfen sayfayı yenileyin ve tekrar deneyin.';

  @override
  String get errorInvalidRoleNftAssetId =>
      'Geçersiz karakter NFT assetId\'si. Lütfen sayfayı yenileyin ve tekrar deneyin.';

  @override
  String get errorInvalidRoleCollectionAssetId =>
      'Geçersiz karakter koleksiyonu assetId\'si. Lütfen sayfayı yenileyin ve tekrar deneyin.';

  @override
  String get roleNftLabelUnknown => 'RoleNFT#Unknown';

  @override
  String roleNftLabel(String prefix) {
    return 'RoleNFT#$prefix';
  }

  @override
  String errorBusiness(String message) {
    return 'İşlem başarısız: $message';
  }

  @override
  String errorUnknown(String message) {
    return 'Bilinmeyen bir hata oluştu: $message';
  }

  @override
  String errorNotSupported(String message) {
    return 'Desteklenmeyen işlem: $message';
  }

  @override
  String get playerEpisodeSelect => 'Seçkiler';

  @override
  String get playerPlayFailed => 'Oynatma başarısız';

  @override
  String get playerDramaUnavailable => 'Bu dizi oynatılamıyor';

  @override
  String get playerContentUnavailable =>
      'Bu içerik yayınlanmamış veya artık kullanılamıyor';

  @override
  String get creatorWorkNotFound => 'Eser mevcut değil ve görüntülenemiyor';

  @override
  String get creatorWorkNotPublished =>
      'Eser yayınlanmadı ve henüz görüntülenemiyor';

  @override
  String get creatorOfflineReasonUnavailable => 'Yayından kaldırma nedeni yok';

  @override
  String get playerTapRetry => 'Dokunarak yeniden deneyin';

  @override
  String playerEpisodeTotal(int count) {
    return 'Toplam $count bölüm';
  }

  @override
  String playerEpisodeLabel(int episodeNo) {
    return 'Bölüm $episodeNo';
  }

  @override
  String get playerLike => 'Beğen';

  @override
  String get playerComment => 'Yorumlar';

  @override
  String get playerFavorite => 'Favori';

  @override
  String get playerShare => 'Paylaş';

  @override
  String playerShareDramaEpisode(
    String title,
    int episodeNo,
    String description,
    String url,
  ) {
    return '$title | Bölüm $episodeNo: $description $url . StoryFun\'da güzel AI kısa diziler izle.';
  }

  @override
  String playerShareDramaEpisodeNoDesc(
    String title,
    int episodeNo,
    String url,
  ) {
    return '$title | Bölüm $episodeNo $url . StoryFun\'da güzel AI kısa diziler izle.';
  }

  @override
  String playerShareShortVideo(String description, String url) {
    return '$description $url. StoryFun\'da güzel kısa videolar izle.';
  }

  @override
  String playerShareShortVideoNoDesc(String url) {
    return '$url. StoryFun\'da güzel kısa videolar izle.';
  }

  @override
  String playerShareDrama(String title, String url) {
    return '$title $url . StoryFun\'da güzel AI kısa diziler izle.';
  }

  @override
  String playerShareDramaNoTitle(String url) {
    return '$url . StoryFun\'da güzel AI kısa diziler izle.';
  }

  @override
  String playerRatingLabel(String rating) {
    return '$rating puan';
  }

  @override
  String get loginOrSignUp => 'Giriş Yap veya Kayıt Ol';

  @override
  String get loginEnterCode => 'Onay kodunu girin';

  @override
  String loginCheckEmailDesc(String email) {
    return 'Lütfen $email adresinden privy.io e-postasını kontrol edin ve kodu aşağıya girin.';
  }

  @override
  String loginResendCountdown(int seconds) {
    return 'Kodu ${seconds}s içinde yeniden gönder';
  }

  @override
  String get loginResendBtn => 'Yeniden Gönder';

  @override
  String get loginProtectedByPrivy => 'Privy tarafından korunuyor';

  @override
  String get loginAgreeLead => 'Şunları kabul ediyorum:';

  @override
  String get loginAgreeAnd => 've';

  @override
  String get loginAgreeConfirmLead =>
      'Onay’a dokunmak, şunları kabul ettiğiniz anlamına gelir:';

  @override
  String get loginAgreeRequired =>
      'Lütfen önce Hizmet Şartları ve Gizlilik Politikasını kabul edin';

  @override
  String get deletingAccountPending => 'Hesap silinmeyi bekliyor';

  @override
  String get deletingAccountCancelDeletion => 'Hesap silmeyi iptal et';

  @override
  String get deletingAccountGoBack => 'Geri';

  @override
  String get drawerEmailAccount => 'E-posta hesabı';

  @override
  String get drawerClickToLogin => 'Dokunarak giriş yapın';

  @override
  String get drawerBuyStory => 'STORY İşlem';

  @override
  String get drawerDeposit => 'Para yükleme';

  @override
  String get drawerWithdraw => 'Para çekme';

  @override
  String get drawerNotifications => 'Bildirimler';

  @override
  String get drawerNoNotifications => 'Bildirim yok';

  @override
  String get notificationTabSystem => 'Sistem';

  @override
  String get notificationTabInteraction => 'Etkinlik';

  @override
  String get notificationTagIpSign => 'Karakter IP sözleşmesi';

  @override
  String get notificationTagRoleManagement => 'Karakter yönetimi';

  @override
  String get notificationTagShowRevenue => 'Performans kazancı';

  @override
  String get notificationTagLike => 'Beğeni';

  @override
  String get notificationTagFavorite => 'Favori';

  @override
  String notificationSignedActor(String user, String actor) {
    return '@$user, $actor karakter IP\'siyle sözleşme yaptı';
  }

  @override
  String notificationShareEarned(String amount) {
    return '$amount pay kazandınız';
  }

  @override
  String notificationStaminaLow(String actor) {
    return '\'$actor dayanıklılığını tüketti. Yenileyin veya dinlendirin\'';
  }

  @override
  String notificationCurrentStamina(String value) {
    return 'Mevcut dayanıklılık $value';
  }

  @override
  String notificationShowEnded(String range) {
    return '$range performansı sona erdi';
  }

  @override
  String notificationIncomeEarned(String amount) {
    return '$amount kazandınız';
  }

  @override
  String get notificationActionClaim => 'Al';

  @override
  String get notificationActionRefill => 'Yenile';

  @override
  String get notificationInteractionLikedVideo => 'Videonuzu beğendi';

  @override
  String notificationInteractionLikedDrama(String title) {
    return '“$title” kısa dizinizi beğendi';
  }

  @override
  String get notificationInteractionFavoritedVideo => 'Videonuzu kaydetti';

  @override
  String notificationInteractionFavoritedDrama(String title) {
    return '“$title” kısa dizinizi kaydetti';
  }

  @override
  String notificationInteractionCommented(String content) {
    return 'Yorum yaptı: $content';
  }

  @override
  String get notificationInteractionFollowedYou => 'Sizi takip etti';

  @override
  String get notificationActionMutualFollow => 'Karşılıklı';

  @override
  String get notificationActionFollow => 'Takip et';

  @override
  String get notificationDelete => 'Sil';

  @override
  String get notificationDeleteFailed =>
      'Silinemedi. Lütfen daha sonra tekrar deneyin';

  @override
  String get notificationRealtimeReceived => 'Yeni bir bildirim aldınız';

  @override
  String drawerEpisodeProgress(int current, int total) {
    return '$current/$total bölüm';
  }

  @override
  String drawerNotificationSignedActor(String actor, String target) {
    return '$actor, $target karakter IP\'siyle sözleşme yaptı';
  }

  @override
  String drawerNotificationLikedVideo(String actor) {
    return '$actor videonuzu beğendi';
  }

  @override
  String drawerNotificationFavoritedDrama(String actor, String target) {
    return '$actor kısa diziniz $target öğesini kaydetti';
  }

  @override
  String get depositTitle => 'Para yükleme';

  @override
  String get insufficientBalanceTitle => 'Bakiye yetersiz';

  @override
  String insufficientBalanceDetail(String currency, String amount) {
    return '$currency bakiyesi yetersiz, $amount $currency eksik';
  }

  @override
  String get insufficientBalancePrompt => 'Yükleme yapılsın mı?';

  @override
  String get insufficientBalanceRecharge => 'Yükleme yap';

  @override
  String get depositDesc =>
      'Lütfen bir borsadan veya başka bir cüzdandan aşağıdaki adrese transfer edin. Yatırım onaylandıktan sonra bakiye otomatik olarak güncellenir.';

  @override
  String get depositToken => 'Token';

  @override
  String get depositNetwork => 'Ağ';

  @override
  String get depositNetworkNote =>
      'Lütfen transfer ağını doğrulayın. Yanlış ağ kullanımı varlık kaybına yol açabilir.';

  @override
  String get depositAddress => 'Yükleme adresi';

  @override
  String get depositAddressCopied => 'Adres panoya kopyalandı';

  @override
  String get depositSend => 'Gönder';

  @override
  String get depositReceive => 'Al';

  @override
  String get depositConvertNote =>
      'Tokenları bu adrese gönderin, Story.fun hesabınızda otomatik olarak USDC\'ye dönüştürülecektir.';

  @override
  String depositMinNote(String minAmount, String token) {
    return 'Minimum yatırma: $minAmount $token';
  }

  @override
  String depositExchangeRateNote(String rate) {
    return 'Güncel döviz kuru $rate. Hesaba geçen tutar = yatırma × $rate';
  }

  @override
  String get depositWarning =>
      'Yalnızca seçilen ağdaki seçilen tokenı yatırın. Diğer varlıklar kurtarılamaz.\nLütfen aktarım ağını doğrulayın; ağ hataları varlık kaybına neden olabilir.';

  @override
  String get withdrawTitle => 'Para çekme';

  @override
  String get withdrawBalance => 'Çekilebilir bakiye';

  @override
  String get withdrawToken => 'Token';

  @override
  String get withdrawAddress => 'Para çekme adresi';

  @override
  String get withdrawAddressHint =>
      'Lütfen Solana alıcı adresini yapıştırın veya girin';

  @override
  String get withdrawAddressHintEvm =>
      'Lütfen bir EVM alıcı adresi girin veya yapıştırın';

  @override
  String get withdrawInvalidEvmAddress => 'Lütfen geçerli bir EVM adresi girin';

  @override
  String get withdrawInvalidSolanaAddress =>
      'Lütfen geçerli bir Solana adresi girin';

  @override
  String get withdrawEvmGasNote =>
      'EVM çekimleri için gas ücreti olarak yeterli native token gerekir. Transfer doğrudan zincir üzerinde gönderilir.';

  @override
  String get withdrawEvmFailed =>
      'EVM çekimi başarısız oldu. Lütfen daha sonra tekrar deneyin.';

  @override
  String get withdrawAddressNote =>
      'Adresin doğru olduğunu lütfen kontrol edin; para transferi yapıldıktan sonra geri alınamaz.';

  @override
  String get withdrawNetwork => 'Ağ';

  @override
  String get withdrawAmount => 'Tutar';

  @override
  String get withdrawAmountHint => 'Çekim tutarını girin';

  @override
  String get withdrawMax => 'Maks';

  @override
  String withdrawAvailableBalance(String balance, String token) {
    return 'Bakiye $balance $token';
  }

  @override
  String withdrawMinWarning(String minAmount, String token) {
    return 'Minimum çekim: $minAmount $token\nLütfen adresi ve ağı dikkatlice kontrol edin; işlemler geri alınamaz.';
  }

  @override
  String get withdrawConfirm => 'Para çekme işlemini onayla';

  @override
  String get withdrawAll => 'Tümü';

  @override
  String withdrawMinAmountError(String minAmt, String token) {
    return 'Minimum çekim tutarı $minAmt $token';
  }

  @override
  String get withdrawExceedBalanceError =>
      'Çekim tutarı mevcut bakiyeyi aşamaz';

  @override
  String get withdrawSameAsWalletError =>
      'Çekim adresi mevcut cüzdan adresinizle aynı olamaz';

  @override
  String get withdrawConfirmTitle => 'Para çekme işlemini onayla';

  @override
  String withdrawConfirmMessage(String amount, String token, String address) {
    return 'Aşağıdaki Solana adresine $amount $token çekmek istediğinizden emin misiniz?\n\n$address';
  }

  @override
  String get withdrawSuccessToast => 'Çekim talebi başarıyla gönderildi!';

  @override
  String get withdrawFailedToast => 'Çekim başarısız. Lütfen tekrar deneyin.';

  @override
  String withdrawErrorToast(String error) {
    return 'Çekim sırasında bir hata oluştu: $error';
  }

  @override
  String withdrawAddressHintWithToken(String token) {
    return '$token\'i alacak cüzdan adresini girin';
  }

  @override
  String get withdrawFee => 'İşlem ücreti';

  @override
  String withdrawFeeValue(String fee, String token) {
    return '$fee $token';
  }

  @override
  String withdrawMinAmount(String minAmount, String token) {
    return 'Minimum çekim: $minAmount $token';
  }

  @override
  String withdrawMaxAmount(String maxAmount, String token) {
    return 'Maksimum çekim tutarı: $maxAmount $token';
  }

  @override
  String get withdrawSponsorSigning => 'İşlem imzalanıyor...';

  @override
  String get withdrawSponsorSubmitting => 'Zincir üzeri işlem gönderiliyor...';

  @override
  String get withdrawSponsorSuccess => 'Çekim başarıyla gönderildi!';

  @override
  String get withdrawSponsorFailed =>
      'İşlem gönderimi başarısız. Lütfen tekrar deneyin.';

  @override
  String get withdrawOrderProcessing => 'Sipariş işleniyor';

  @override
  String get withdrawOrderSuccess => 'Sipariş tamamlandı';

  @override
  String get withdrawOrderFailed => 'Sipariş başarısız';

  @override
  String withdrawOrderStatus(String status) {
    return 'Sipariş durumu: $status';
  }

  @override
  String get qrScannerTitle => 'QR Kodu Tara';

  @override
  String get qrScannerHint => 'Taramak için QR kodunu çerçeveye hizalayın';

  @override
  String get drawerProfile => 'Kişisel Sayfa';

  @override
  String get drawerCreatorManagement => 'İçerik Yönetimi';

  @override
  String get drawerInvite => 'Davet';

  @override
  String get inviteTitle => 'Arkadaşlarını Davet Et';

  @override
  String get inviteTotalPeople => 'Toplam davet edilen kişi sayısı';

  @override
  String get inviteTotalRewards => 'Toplam Davet Ödülü';

  @override
  String get inviteWeeklyPool => 'Bu Haftanın Davet Ödül havuzu';

  @override
  String get inviteViewHistory => 'Kazanç geçmişini görüntüle';

  @override
  String get inviteShareSection =>
      'Özel davet bağlantını veya davet kodunu paylaş';

  @override
  String get inviteLinkSection => 'Davet bağlantısı';

  @override
  String get inviteLinkSubtitle =>
      'Arkadaşların bağlantın üzerinden kayıt olur, karakter imzalayıp gönderirse ekstra STORY ödülü kazanırsın.';

  @override
  String get inviteCodeLabel => 'Davet Kodu';

  @override
  String get inviteCopyButton => 'Bağlantıyı kopyala';

  @override
  String get inviteCopiedSuccess => 'Davet linki panoya kopyalandı!';

  @override
  String get inviteCodeCopiedSuccess => 'Davet kodu panoya kopyalandı!';

  @override
  String get inviteInvitedLabel => 'Davet edilen';

  @override
  String get inviteRewardLabel => 'Ödüller';

  @override
  String get inviteBindCode => 'Davet kodunu bağla';

  @override
  String get inviteBindCodePromptHint =>
      'Daha sonra Davet sayfasından bağlayabilirsiniz';

  @override
  String get inviteBindCodePlaceholder => 'Davet kodunu girin';

  @override
  String get inviteBindConfirm => 'Onayla';

  @override
  String get inviteBindSuccess => 'Davet kodu başarıyla bağlandı';

  @override
  String get inviteBindCodeInvalid => 'Davet kodu geçersiz';

  @override
  String get inviteBindCodeAlreadyBound =>
      'Bu hesap zaten bir davet koduna bağlı';

  @override
  String get inviteRulesSection => 'Davet Kuralları';

  @override
  String get inviteFaqPoolTitle => 'Haftalık davet ödül havuzu nedir?';

  @override
  String get inviteFaqPoolBody =>
      'Haftalık davet ödül havuzu, davet etkinliği için oluşturulan bağımsız bir ödül havuzudur. Mevcut haftadaki davet eylemlerini ödüllendirir ve davet edilenlerin kazançlarından kesilmez. Havuzun haftalık bir ödeme üst sınırı vardır; sınıra ulaşıldığında ödemeler pay oranına göre orantılı olarak azaltılır. İstatistikler her Pazartesi sıfırlanır.';

  @override
  String get inviteFaqSettlementTitle => 'Davet ödülleri ne zaman ödenir?';

  @override
  String get inviteFaqSettlementBody =>
      'Davet ödülleri, acente sayfasındaki maaşlarla aynı döngüde toplu olarak ödenir: istatistikler her Pazartesi 00:00 (UTC) itibarıyla kapanır. Ödeme sonrası Ödüller sayfasından talep edebilirsiniz.';

  @override
  String get inviteRuleSourceTitle => 'Ödül Kaynağı';

  @override
  String get inviteRuleSourceSubtitle => 'Bağımsız Davet Alt Havuzu';

  @override
  String get inviteRuleSourceBody =>
      'Davet ödülleri, NFT madencilik havuzundaki bağımsız davet alt havuzundan (toplam madencilik havuzunun %25’ini oluşturur) sağlanır ve davet edilen kişinin kazançlarından kesilmez. Davet alt havuzunun bağımsız bir haftalık üst sınırı vardır; bu sınıra ulaşıldığında, pay oranına göre orantılı olarak azaltılır.';

  @override
  String get inviteRuleBaseTitle => 'Hesaplama tabanı';

  @override
  String get inviteRuleBaseSubtitle => 'Gerçekte yaşanan STORY';

  @override
  String get inviteRuleBaseBody =>
      'Ödül, davet edilen kişinin bu dönemde fiilen elde ettiği STORY miktarına göre hesaplanır; nominal üretime göre hesaplanmaz. Davet edilen kişinin kendi kazandığı STORY miktarından bu durum etkilenmez; davet ödülü ek olarak verilir.';

  @override
  String get inviteRuleLevelTitle => 'Ödül kapsamı';

  @override
  String get inviteRuleLevelSubtitle => 'Yalnızca doğrudan davetler';

  @override
  String get inviteRuleLevelBody =>
      'Davet ödülleri yalnızca doğrudan davet ettiğiniz kullanıcılar için ödenir. Çok seviyeli veya dolaylı komisyon yoktur.';

  @override
  String get inviteRuleConditionTitle => 'Geçerlilik Koşulları';

  @override
  String get inviteRuleConditionSubtitle =>
      'Sadece etkin üye sayısından ödül kazanılabilir';

  @override
  String inviteRuleConditionBody(String currency) {
    return 'Davet edilen kişinin gerçekten STORY madenciliği yapmış olması veya $currency ile ödeme yapmış olması gerekir ki, bu durumda geçerli bir alt üye olarak kabul edilir. Geçersiz numaralarla yapılan kayıtlar ödül kazandırmaz. Davet ilişkisi bir kez kurulduktan sonra değiştirilemez.';
  }

  @override
  String get drawerTxHistory => 'İşlem geçmişi';

  @override
  String get drawerFinanceDashboard => 'Finans Paneli';

  @override
  String get financeDashboardComingSoon =>
      'Finans Paneli yakında geliyor. Bizi izleyin.';

  @override
  String get financeDashboardPageTitle => 'Platform finans panosu';

  @override
  String financeDashboardTotalUsdcIncome(String currency) {
    return 'Toplam USDC geliri';
  }

  @override
  String get financeDashboardTotalStoryReleased => 'Dağıtılan toplam STORY';

  @override
  String financeDashboardTabUsdcIncome(String currency) {
    return 'USDC gelir ayrıntıları';
  }

  @override
  String get financeDashboardTabVaultFunds => 'Kasa fonu birikimi';

  @override
  String get financeDashboardTabStoryRelease => 'STORY dağıtım özeti';

  @override
  String get financeDashboardFeeMint => 'Sözleşme ücreti';

  @override
  String get financeDashboardFeeRoyalty => 'İkincil telif';

  @override
  String get financeDashboardFeeItemPurchase => 'Eşya satın alma';

  @override
  String get financeDashboardFeeTx => 'İşlem ücreti';

  @override
  String get financeDashboardLedgerBizSigningFee => 'Sözleşme ücreti';

  @override
  String get financeDashboardLedgerBizManualCredit => 'Manuel bakiye ekleme';

  @override
  String get financeDashboardLedgerBizManualDebit => 'Manuel bakiye düşme';

  @override
  String get financeDashboardLedgerBizStaminaPurchase =>
      'Dayanıklılık satın alma ücreti';

  @override
  String get financeDashboardLedgerBizSynthesisUpgrade =>
      'Birleştirme yükseltme ücreti';

  @override
  String get financeDashboardLedgerBizTransactionFee => 'İşlem ücreti';

  @override
  String financeDashboardRecentUsdcLedger(String currency) {
    return 'Son USDC gelirleri';
  }

  @override
  String get financeDashboardViewMore => 'Daha fazla göster';

  @override
  String get financeDashboardTotalVaultFunds => 'Toplam kasa fonu';

  @override
  String get financeDashboardCoveredActorIp => 'Kapsanan karakter IP\'leri';

  @override
  String get financeDashboardActorVaultRanking =>
      'Karakter IP kasası sıralaması';

  @override
  String get storyReleaseTabAllocation => 'Toplam STORY tahsisi';

  @override
  String get storyReleaseTabMiningRelease => 'Son madencilik dağıtımı';

  @override
  String get storyReleaseFieldPeriod => 'Dönem';

  @override
  String get storyReleaseFieldHardLimit => 'Haftalık üst sınır';

  @override
  String get storyReleaseFieldMiningRewards => 'Stake madenciliği';

  @override
  String get storyReleaseFieldInviteRewards => 'Davet madenciliği';

  @override
  String get storyReleaseFieldUsageRate => 'Kullanım oranı';

  @override
  String get storyReleaseFieldTarget => 'Tahsis hedefi';

  @override
  String get storyReleaseFieldRatio => 'Oran';

  @override
  String get storyReleaseFieldAmount => 'Miktar';

  @override
  String get storyReleaseFieldReleased => 'Dağıtıldı';

  @override
  String get storyReleaseFieldProgress => 'Dağıtım ilerlemesi';

  @override
  String get storyReleaseCategoryNftMiningPool => 'NFT madencilik havuzu';

  @override
  String get storyReleaseCategoryTeam => 'Ekip';

  @override
  String get storyReleaseCategoryInvestors => 'Yatırımcılar';

  @override
  String get storyReleaseCategoryLiquidity => 'Launchpad + Likidite';

  @override
  String get storyReleaseCategoryTreasury => 'Hazine';

  @override
  String get storyReleaseCategoryMarketOps => 'Piyasa operasyonları';

  @override
  String storyReleaseTotalSupplyBadge(String total) {
    return 'Toplam $total STORY';
  }

  @override
  String get drawerWhitepaper => 'Beyaz Kitap';

  @override
  String get drawerSettings => 'Ayarlar';

  @override
  String get commonClose => 'Kapat';

  @override
  String get commonDelete => 'Sil';

  @override
  String get commonLoadFailed => 'Yükleme başarısız';

  @override
  String get commonNone => 'Yok';

  @override
  String get commonUntitled => 'Başlıksız';

  @override
  String get actorDetailTitle => 'Oyuncu Ana Sayfası';

  @override
  String get actorDetailCastDramas => 'Kısa oyunda rol almak';

  @override
  String get actorDetailTabCast => 'Rol';

  @override
  String get actorDetailTabInfo => 'Bilgi';

  @override
  String get actorDetailNoCastRecords => 'Oyunculuk kaydı yok';

  @override
  String get actorBondingCurve => 'Fiyat birleşim eğrisi';

  @override
  String get actorContractAddress => 'Sözleşme adresi';

  @override
  String get actorCurrentPosition => 'Şu anki konum';

  @override
  String actorCurrentPrice(String price, String currency) {
    return 'Şu anki fiyat $price $currency';
  }

  @override
  String get actorFloorPrice => 'En düşük fiyat';

  @override
  String get actorGoTrade => 'İşlem Yap';

  @override
  String get profileWalletTrade => 'İşlem Yap';

  @override
  String get actorHeatCoefficient => 'Popülerlik katsayısı';

  @override
  String get actorIpPower => 'IP Ücreti';

  @override
  String get actorPayMax => 'Maks';

  @override
  String get actorPayUpgradeTitle => 'Ücret artış kuralları';

  @override
  String get actorPayUpgradeReachHint =>
      'Bu IP\'nin yer aldığı kısa dizilerin mevcut tam izlenme sayısı rolü şu seviyeye yükseltebilir';

  @override
  String actorPayUpgradeCompletions(String count) {
    return '$count tam izlenme';
  }

  @override
  String actorPayUpgradeMultiplier(String value) {
    return 'Ücret ×$value';
  }

  @override
  String actorPayTitle(String name) {
    return '$name · Ücret';
  }

  @override
  String get actorLv1PayHint => 'Sözleşme yaparak Lv.1 karakter kazan';

  @override
  String get actorLv1PayFormula =>
      'Lv.1 ücret = Fiyat katsayısı × Popülerlik katsayısı';

  @override
  String actorLv1PayEquals(String value) {
    return '=$value';
  }

  @override
  String actorIpPowerTitle(String name) {
    return '$name · IP Ücreti';
  }

  @override
  String get actorIpPowerFormula =>
      'IP Ücreti = Fiyat katsayısı × Popülerlik katsayısı × Trust1';

  @override
  String get actorPriceCoefficient => 'Fiyat katsayısı';

  @override
  String actorPriceCoefficientValue(String value) {
    return 'Fiyat katsayısı $value';
  }

  @override
  String get actorPriceCoefficientHelpA11y =>
      'Fiyat katsayısı açıklamasını görüntüle';

  @override
  String get actorPriceUnitName => 'Puan';

  @override
  String get actorPriceCoefficientDialogFormulaLe100 => 'Katsayı = P0 ÷ 10';

  @override
  String get actorPriceCoefficientDialogDescLe100 => 'Doğrusal artış';

  @override
  String actorPriceCoefficientDialogTitleGt100(String currency) {
    return 'P0 > 10 $currency';
  }

  @override
  String get actorPriceCoefficientDialogFormulaGt100 =>
      'Katsayı = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]';

  @override
  String get actorPriceCoefficientDialogDescGt100 =>
      'Artış yavaşlar, üst sınır 1.6';

  @override
  String actorPriceCoefficientDialogTitleLe100(String currency) {
    return 'P0 ≤ 10 $currency';
  }

  @override
  String actorPriceCoefficientFactorDesc(String currency1, String currency2) {
    return 'P0 ≤ 10 $currency1 katsayı = P0/10 (doğrusal artış)\nP0 > 10 $currency2 → katsayı = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6] (asimptotik üst sınır 1.6)';
  }

  @override
  String get actorHeatCoefficientFactorDesc =>
      'Karakter IP\'sinin son 30 günlük popülerlik çarpanı; kısa dizilerin tam izlenmesi, beğeniler, favorilere ekleme gibi etkileşimlere bağlıdır';

  @override
  String get actorTrustFactorDesc =>
      'Platform risk kontrol katsayısı, varsayılan değer 1.0';

  @override
  String get actorStatCompletion => 'Tam izlenme';

  @override
  String get actorIdCopied => 'Numara kopyalandı';

  @override
  String actorInitialPrice(String price, String currency) {
    return 'Başlangıç Fiyatı: $price $currency';
  }

  @override
  String actorIpLabel(String label) {
    return 'Karakter IP $label';
  }

  @override
  String get actorIssueInfo => 'Yayınlama bilgileri';

  @override
  String actorIssuer(String name) {
    return 'Yayınlayan $name';
  }

  @override
  String actorMintedCount(int minted, int maxSupply) {
    return 'Basılmış $minted/$maxSupply';
  }

  @override
  String get actorPriceCurve => 'Fiyat eğrisi';

  @override
  String get actorSign => 'Sözleşme';

  @override
  String get actorConfirmSign => 'Sözleşmeyi onayla';

  @override
  String get actorSignPriceLabel => 'Sözleşme fiyatı';

  @override
  String get actorSignPriceDescription =>
      'İmza sayısı arttıkça sözleşme fiyatı otomatik olarak yükselir; erken imza yapanlar daha avantajlı fiyatlardan yararlanır.';

  @override
  String get actorSignPriceFormula =>
      'Formül: Fiyat = Başlangıç fiyatı × 5^(İmzalanan sayı ÷ Toplam arz)';

  @override
  String actorPriceAxisLabel(String currency) {
    return 'Fiyat ($currency)';
  }

  @override
  String get actorSignedCountAxisLabel => 'İmzalanan sayı';

  @override
  String actorSignRemainingCount(int count) {
    return '$count adet kaldı';
  }

  @override
  String get actorSignSoldOut => 'Tükendi';

  @override
  String actorSignSupplySummary(String total, String remaining) {
    return 'Toplam $total · Kalan $remaining';
  }

  @override
  String get actorPricingFixed => 'Sabit fiyat';

  @override
  String get actorPricingCurve => 'Eğri fiyatı';

  @override
  String get actorPriceCurveDisclaimer =>
      'Başlangıç fiyatı, platformun değerlemesini yansıtmaz; grafikteki artış, ikincil piyasadaki fiyat artışını ifade etmez; platform herhangi bir getiri taahhüdünde bulunmaz.';

  @override
  String get actorPriceStatInitialPrice => 'Başlangıç fiyatı';

  @override
  String get actorPriceStatCurrentPrice => 'Güncel fiyat';

  @override
  String get actorPriceStatTailPrice => 'Kapanış fiyatı';

  @override
  String get actorPriceStatTotalSupply => 'Toplam arz';

  @override
  String get actorPriceStatSigned => 'İmzalandı';

  @override
  String get actorPriceStatRemaining => 'Kalan';

  @override
  String get actorPricingType => 'Fiyatlandırma türü';

  @override
  String get contentBadgeOfficialIssue => 'Resmî yayınlama';

  @override
  String get contentBadgeCommunityIssue => 'Topluluk yayınlaması';

  @override
  String get contentBadgePartnerIssue => 'Ortak yayınlama';

  @override
  String get contentBadgeVerifiedIssue =>
      'Doğrulanmış içerik üreticileri yayınlar';

  @override
  String get contentBadgeOfficialDrama => 'Resmi kısa dizi';

  @override
  String get contentBadgeCommunityDrama => 'Mahalle Kısa Tiyatro Oyunu';

  @override
  String get contentBadgePartnerDrama => 'Ortaklarla Hazırlanan Kısa Diziler';

  @override
  String get contentBadgeVerifiedDrama => 'Onaylı Yaratıcıların Kısa Dizileri';

  @override
  String get actorIpCopied => 'Kopyalama işlemi başarıyla tamamlandı';

  @override
  String get actorRiskIp => 'Riskli IP';

  @override
  String get actorRiskIpDescription =>
      'Bu Karakter IP\'sinin güvenilirlik katsayısında anormallik var; madencilik ağırlığı etkilenecektir.';

  @override
  String get actorIpVault => 'Karakter IP Kasası';

  @override
  String get actorIpVaultDescription =>
      'İmza gelirlerinin %30\'u, IP ekosisteminin uzun vadeli gelişimini desteklemek amacıyla otomatik olarak Karakter IP Kasası\'na aktarılır. İkincil piyasa telif gelirlerinin de %30\'u aynı kasaya aktarılır ve böylece sürekli bir fon havuzu oluşturulur. V1 sürümündeki kasa yalnızca veri gösterimi için kullanılır; şimdilik dağıtım yapılmamaktadır.';

  @override
  String get actorIpVaultSignIncomePrefix => 'İmza geliri · Birikim ';

  @override
  String get actorIpVaultSecondaryRoyaltyPrefix =>
      'İkinci Kademe Telif Ücreti · Birikim ';

  @override
  String get actorFixedPriceDialogDesc =>
      'Bu Karakter IP\'si sabit fiyat modelini kullanır; her karakter tek tip bir fiyat üzerinden sözleşme imzalar ve satışlardaki değişiklikler fiyatı etkilemez.';

  @override
  String get actorCurvePriceDialogDesc =>
      'Fiyat, birleşik eğri formülüne göre imzalanan sayıyla birlikte otomatik olarak artar; erken imzalayanlar daha avantajlıdır';

  @override
  String get actorFixedPriceNote1 =>
      'Yayınlayan sabit bir fiyat belirledikten sonra, tüm imzalar bu fiyat üzerinden hesaplanır.';

  @override
  String get actorFixedPriceNote2 =>
      'İmzalanan karakter sayısı artsa bile fiyat yükselmez.';

  @override
  String get actorFixedPriceNote3 =>
      'Maliyetlerini sabit tutmak isteyen alıcılar için uygundur';

  @override
  String get actorIssueFixedPriceDesc =>
      'Bu Karakter IP\'si sabit fiyat modelini kullanır; tüm imzalar sabit fiyat üzerinden hesaplanır ve satışlardaki değişikliklerden etkilenmez.';

  @override
  String get actorSignSlippageNote =>
      '%1 kayma koruması etkinleştirildi; fiyat bu sınırı aştığında işlem iptal edilecektir';

  @override
  String get actorSignSuccessTitle => 'Sözleşme tamamlandı!';

  @override
  String actorSignSuccessMessage(String name) {
    return 'Rol «$name» başarıyla imzalandı';
  }

  @override
  String actorSignSuccessNftId(String nftId) {
    return 'NFT numarası: $nftId';
  }

  @override
  String get actorSignChainConfigMissing =>
      'Zincir üzeri yapılandırma eksik. Lütfen daha sonra tekrar deneyin.';

  @override
  String get actorSignPriceSoldOut => 'Sözleşme fiyatı · Tükendi';

  @override
  String actorSignPriceRemaining(int count) {
    return 'Sözleşme fiyatı · Kalan $count';
  }

  @override
  String actorSignedCount(int count) {
    return 'Sözleşme imzalanmış $count';
  }

  @override
  String get actorStatusLabelOffline => 'Çevrimdışı';

  @override
  String get actorStatusLabelOnline => 'Çevrimiçi';

  @override
  String get actorStatusLabelPending => 'İnceleniyor';

  @override
  String get actorStatusLabelRejected => 'Reddedildi';

  @override
  String get actorTotalSupply => 'Toplam arz';

  @override
  String get commentsAnonymous => 'Anonim kullanıcı';

  @override
  String get commentsEmpty => 'Henüz yorum yok';

  @override
  String get commentsHint => 'Harika bir yorum gönder...';

  @override
  String get commentsInvalidContent => 'Geçerli bir içerik girin';

  @override
  String get commentsReply => 'Yanıtla';

  @override
  String commentsViewReplies(int count) {
    return '$count yanıtı görüntüle';
  }

  @override
  String get commentsCollapseReplies => 'Daralt';

  @override
  String get commentsViewMoreReplies => 'Daha fazla göster';

  @override
  String commentsReplyHint(String nickname) {
    return '$nickname kişisine yanıt ver';
  }

  @override
  String get commentsDeleteCommentTitle => 'Bu yorum silinsin mi?';

  @override
  String get commentsDeleteReplyTitle => 'Bu yanıt silinsin mi?';

  @override
  String get commentTagAuthor => 'Yazar';

  @override
  String get commentTagMe => 'Ben';

  @override
  String get commentTagFriend => 'Arkadaşın';

  @override
  String get commentTagFan => 'Takipçin';

  @override
  String get commentTagFirst => 'İlk yorum';

  @override
  String get commentTagAuthorLiked => 'Yazar beğendi';

  @override
  String commentsReplyTo(String nickname) {
    return '@$nickname kullanıcısına yanıt ver: ';
  }

  @override
  String get commentsReplyCommentNotExists => 'Yorum mevcut değil';

  @override
  String get commentsBlockedByMe =>
      'Bu kullanıcı kara listenizde, yorum yapamazsınız';

  @override
  String get commentsBlockedByTarget =>
      'Bu kullanıcının ayarları nedeniyle yorum yapamazsınız';

  @override
  String get commentsTabComments => 'Yorumlar';

  @override
  String get commentsTabAllComments => 'Tüm yorumlar';

  @override
  String get commentsTabDramas => 'Kısa dizi';

  @override
  String get commentsTabActors => 'Karakter';

  @override
  String get timeJustNow => 'az önce';

  @override
  String get timeYesterday => 'dün';

  @override
  String get timeDayBeforeYesterday => 'evvelsi gün';

  @override
  String timeMinutesAgo(int count) {
    return '$count dk önce';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count sa önce';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count gün önce';
  }

  @override
  String commentsTitle(int count) {
    return 'Yorumlar ($count)';
  }

  @override
  String get createActorTitle => 'Rol Oluştur';

  @override
  String get createActorHeroTitle => 'Karakter NFT\'si Bas';

  @override
  String get createActorHeroSubtitle =>
      'Özel AI roller oluşturun, kâr paylaşımını bağlayarak drama katılımı';

  @override
  String get createActorNameLabel => 'Rol Adı';

  @override
  String get createActorNameHint => 'Rol adını girin';

  @override
  String get createActorBioLabel => 'Rol Biyografisi';

  @override
  String get createActorBioHint => 'Karakterin geçmişini açıklayın';

  @override
  String get createActorGenderLabel => 'Cinsiyet';

  @override
  String get createActorGenderMale => 'Erkek';

  @override
  String get createActorGenderFemale => 'Kadın';

  @override
  String get createActorMintParams => 'NFT Basma Parametreleri';

  @override
  String get createActorTokenStandard => 'Token standardı';

  @override
  String get createActorChain => 'Zincir';

  @override
  String get createActorMinHolding => 'Minimum Tutma';

  @override
  String get createActorMintNft => 'NFT Bas';

  @override
  String get createActorIpTitle => 'Karakter IP yayınla';

  @override
  String get createActorIpSubtitle =>
      'Bir karakter IP\'si yayınlandıktan sonra bu IP kapsamında karakterler imzalanabilir ve görevlendirilerek gelir elde edilebilir.';

  @override
  String get createActorSelectMaterial => 'Rol görsellerini seçin';

  @override
  String get createActorDreamOsBadge => 'DreamOS\'a git';

  @override
  String get createActorSelectMaterialDesc =>
      'DreamOS projesine gir → Karakter oluştur → IP yayınlamak için Story.fun\'a gir';

  @override
  String get createActorSelectButton => 'Rol Seç';

  @override
  String get createActorNameLabelNew => 'Rolün adı';

  @override
  String get createActorNamePlaceholder => 'Rolün adını girin';

  @override
  String get createActorBioLabelNew => 'Tanıtım';

  @override
  String get createActorBioPlaceholder =>
      'Lütfen karakterin IP tanıtımını girin';

  @override
  String get createActorParamsTitle => 'Karakter IP yayınlama parametreleri';

  @override
  String get createActorParamsSubtitle =>
      'Karakter IP yayınlama parametrelerini ayarlayın. Yayınlandıktan sonra değiştirilemez.';

  @override
  String get createActorTotalSupplyLabel => 'Toplam karakter arzı';

  @override
  String get createActorTotalSupplyDesc => 'Toplam arz aralığı: 100 - 5.000.';

  @override
  String get createActorTotalSupplyPlaceholder => '100 - 5,000';

  @override
  String get createActorPricingFixed => 'Sabit fiyat';

  @override
  String get createActorPricingCurve => 'Eğri fiyatı';

  @override
  String createActorFixedPriceLabel(String currency) {
    return 'Sabit fiyat ($currency)';
  }

  @override
  String createActorInitialPriceLabel(String currency) {
    return 'Başlangıç fiyatı ($currency)';
  }

  @override
  String get createActorFixedPricePlaceholder => '10 - 1,000';

  @override
  String get createActorFixedPriceDesc =>
      'Her bir karakter sabit bir fiyattan satın alınır; bu fiyat satış rakamlarına göre değişmez.';

  @override
  String get createActorInitialPricePlaceholder => '10 - 1,000';

  @override
  String get createActorInitialPriceDesc =>
      'Başlangıç fiyatı, birleşik eğrinin başlangıç fiyatıdır. Her karakter imzalandığında fiyat, P = P₀ × 5^(imzalanan sayı ÷ toplam arz) formülüne göre otomatik olarak artar. Erken imzalayanlar daha avantajlı fiyat elde eder.';

  @override
  String get createActorFormIncomplete =>
      'Lütfen önce karakter kaynağını, adı, tanıtımı ve yayınlama parametrelerini doldurun';

  @override
  String get createActorValidationNameRequired => 'Lütfen rol adını girin';

  @override
  String get createActorValidationNameTooLong =>
      'Karakter adı 20 karakter veya daha az olmalıdır';

  @override
  String get createActorValidationBioRequired => 'Lütfen biyografiyi girin';

  @override
  String get createActorValidationBioTooLong =>
      'Biyografi 500 karakter veya daha az olmalıdır';

  @override
  String get createActorValidationTotalSupplyRequired =>
      'Lütfen geçerli bir toplam NFT arzı girin';

  @override
  String get createActorValidationTotalSupplyPositiveInteger =>
      'Toplam NFT arzı pozitif bir tam sayı olmalıdır';

  @override
  String get createActorValidationTotalSupplyRange =>
      'Toplam karakter arzı 100 ile 5.000 arasında olmalıdır';

  @override
  String get createActorValidationPriceRequired =>
      'Lütfen geçerli bir basma fiyatı girin';

  @override
  String get createActorValidationPriceInvalid =>
      'Mint fiyatı en az 10 olmalı ve 1.000\'i aşmamalıdır';

  @override
  String get createActorValidationPriceMaxDecimals =>
      'Basma fiyatı en fazla 2 ondalık basamak olabilir';

  @override
  String get createActorSelectMaterialRequired =>
      'Lütfen karakter materyalini seçin';

  @override
  String get createActorCancelButton => 'İptal et';

  @override
  String get createActorConfirmButton => 'Yayınlamayı onayla';

  @override
  String get createActorIssueFee => 'Ücret';

  @override
  String createActorSuccessTitle(String name) {
    return '$name · Yayınlama başarılı!';
  }

  @override
  String createActorSuccessDesc(String id) {
    return 'Karakter IP $id';
  }

  @override
  String get createActorSuccessTip =>
      'Yayınlayan da bu karakteri almak için imzalamalı~';

  @override
  String get createActorCloseButton => 'Sonra';

  @override
  String get createActorViewButton => 'İmzala';

  @override
  String get createActorEmptyTitle =>
      'DreamOS\'ta sistem tarafından otomatik oluşturulan, koşulları karşılayan bir NFT yayını henüz yok.';

  @override
  String get createActorGotoDreamOs => 'DreamOS\'a gidip oluşturun';

  @override
  String get createActorSearchPlaceholder => 'Karakter materyali ara';

  @override
  String get createActorInvalidOrderId =>
      'Karakter IP sipariş numarası geçersiz. Lütfen yenileyip tekrar deneyin';

  @override
  String get createDramaTitle => 'Drama Oluştur';

  @override
  String get createDramaTitleLabel => 'Kısa dizi başlığı';

  @override
  String get createDramaTitleHint => 'Drama adını girin';

  @override
  String get createDramaSynopsisLabel => 'Özet';

  @override
  String get createDramaSynopsisHint =>
      'Ne tür bir hikaye anlatıyor... (En fazla 1000 karakter)';

  @override
  String get createDramaAiSettings => 'AI Üretim Ayarları';

  @override
  String get createDramaVisualStyle => 'Görsel Stil';

  @override
  String get createDramaVisualStyleRealistic => 'Gerçekçi';

  @override
  String get createDramaEpisodeDuration => 'Bölüm Süresi';

  @override
  String get createDramaEpisodeDurationValue => '3-5 dk';

  @override
  String get createDramaTotalEpisodes => 'Toplam Bölüm';

  @override
  String get createDramaTotalEpisodesValue => '8 bölüm';

  @override
  String get createDramaGenreLabel => 'Tür';

  @override
  String get createDramaGenreDrama => 'Drama';

  @override
  String get createDramaGenreComedy => 'Komedi';

  @override
  String get createDramaGenreAction => 'Aksiyon';

  @override
  String get createDramaGenreRomance => 'Romantik';

  @override
  String get createDramaGenreSciFi => 'Bilim kurgu';

  @override
  String get createDramaGenreMystery => 'Gerilim';

  @override
  String get createDramaGenreHorror => 'Korku';

  @override
  String get createDramaGenreAnimation => 'Animasyon';

  @override
  String get createDramaHeroTitle => 'AI Drama Üretimi';

  @override
  String get createDramaHeroSubtitle =>
      'Bir tıklamayla bir sonraki hit dramınızı üretin';

  @override
  String get createDramaStartGeneration => 'Üretimi Başlat';

  @override
  String get creatorDramaManagementTab => 'Kısa dizilerin yönetimi';

  @override
  String get creatorDramaNftTab => 'Kısa dizi NFT';

  @override
  String get creatorHeaderSubtitle =>
      'Kısa diziler için yayınlama, denetleme ve basım.';

  @override
  String get creatorV2Subtitle =>
      'Kısa dizileri ve videoları yayınlayın ve yönetin.';

  @override
  String creatorV2DramaTabCount(int count) {
    return 'Kısa diziler ($count)';
  }

  @override
  String creatorV2VideoTabCount(int count) {
    return 'Videolar ($count)';
  }

  @override
  String get creatorV2NoVideos => 'Henüz video yok';

  @override
  String get creatorLoginPrompt =>
      'Yaratıklarınızı görüntülemek için giriş yapın';

  @override
  String get creatorNoCreatedActors => 'Oluşturulmuş rol yok';

  @override
  String get creatorNoPublishedDramas => 'Yayınlanmış dizi yok';

  @override
  String get creatorOwnedNftCount => 'Elinde bulunan NFT sayısı';

  @override
  String get creatorCreateDrama => 'Dizi oluştur';

  @override
  String get creatorPublishNewDrama => 'Yeni kısa dizi Yayınla';

  @override
  String get creatorPublishedDramas => 'Kısa dizi yayınla';

  @override
  String get creatorReviewFilterAll => 'Tümü';

  @override
  String get creatorReviewFilterApproved => 'Onaylandı';

  @override
  String get creatorReviewFilterPending => 'İnceleniyor';

  @override
  String get creatorReviewFilterRejected => 'Başarısız';

  @override
  String get creatorReviewFilterOffline => 'Yayından kaldırıldı';

  @override
  String get creatorDramaOtherReason => 'Diğer neden';

  @override
  String get creatorDramaStatusOnline => 'Onaylandı';

  @override
  String get creatorDramaStatusPendingReview => 'İnceleniyor';

  @override
  String get creatorDramaStatusReviewRejected => 'Başarısız';

  @override
  String get creatorDramaStatusPendingOnline => 'Yayın Bekliyor';

  @override
  String creatorDramaAuditReason(Object reason) {
    return 'Red nedeni: $reason';
  }

  @override
  String get creatorDramaNftMinted => 'Döküm tamamlandı';

  @override
  String creatorDramaEpisodeCount(int count) {
    return '$count bölüm';
  }

  @override
  String get creatorDramaEdit => 'Düzenle';

  @override
  String get creatorDramaDelete => 'Sil';

  @override
  String get creatorActorDelete => 'Rolyu sil';

  @override
  String get creatorDeleteDramaConfirm =>
      'Bu kısa videoyu silmek istiyor musunuz?';

  @override
  String get creatorDeleteVideoConfirmTitle => 'Video silme onayı';

  @override
  String creatorDeleteVideoConfirmMessage(String name) {
    return '“$name” videosunu silmek istediğinizden emin misiniz?\nBu işlem geri alınamaz.';
  }

  @override
  String get creatorDeleteActorConfirm =>
      'Bu karakteri silmek istiyor musunuz?';

  @override
  String get creatorDeleting => 'Siliniyor...';

  @override
  String get creatorNoDramas => 'Şu anda kısa dizi yok';

  @override
  String get creatorNoNfts => 'Şu anda kısa dizi NFT\'si bulunmamaktadır';

  @override
  String get creatorsComingSoon => 'Yakında';

  @override
  String get creatorsHeroSubtitle => 'Önde gelen yaratıcıları keşfedin';

  @override
  String get creatorsHeroTitle => 'Yaratıcılar';

  @override
  String get dramaBatchUnlockAll => 'Tümünü Aç';

  @override
  String dramaBatchUnlockDiscount(String discount) {
    return 'Toplu açma indirimi $discount%';
  }

  @override
  String get dramaBatchUnlockSubtitle =>
      'Daha iyi bir anlaşma için tüm bölümleri tek seferde açın';

  @override
  String get dramaBatchUnlockSuccess =>
      'Açma başarılı, lütfen izlemeye başlayın';

  @override
  String get dramaDetailAllFree => 'Tümü Ücretsiz';

  @override
  String dramaDetailBoundActors(int count) {
    return '$count rol bağlı';
  }

  @override
  String dramaDetailEpisodeCount(int count) {
    return '$count bölüm';
  }

  @override
  String get dramaDetailEpisodePrice => 'Tek bölüm fiyatı';

  @override
  String get dramaDetailFree => 'Ücretsiz';

  @override
  String dramaDetailFreeEpisodes(int count) {
    return 'İlk $count ücretsiz';
  }

  @override
  String get dramaDetailMainCharacters => 'Ana Roller';

  @override
  String get dramaDetailNftMinted => 'NFT Basıldı';

  @override
  String get dramaDetailNoEpisodes => 'Bölüm yok';

  @override
  String get dramaDetailPaid => 'Ücretli';

  @override
  String get dramaDetailPendingActor => 'Karakter bekleniyor';

  @override
  String get dramaDetailRoleCount => 'Roller';

  @override
  String get dramaUnlockFailedRetry => 'Açma başarısız, lütfen tekrar deneyin';

  @override
  String get dramaUnlockFetchTimeout =>
      'Oynatma adresi alma zaman aşımı, lütfen tekrar deneyin';

  @override
  String get dramaUnlockLoginRequired =>
      'Bölümleri açmak için lütfen giriş yapın';

  @override
  String dramaUnlockMessage(
    int epNo,
    String price,
    String discount,
    String currency,
  ) {
    return 'Bölüm $epNo açmak için ödeme gerektirir\nFiyat: $price $currency\nToplu açma indirimi: $discount';
  }

  @override
  String get dramaUnlockSuccessFetching =>
      'Açma başarılı, oynatma adresi alınıyor...';

  @override
  String get dramaUnlockTitle => 'Bölümlerin kilidini aç';

  @override
  String get editActorTitle => 'Rolyu düzenle';

  @override
  String get editDramaTitle => 'Kısa oyun düzenleme';

  @override
  String get editVideoTitle => 'Videoyu düzenle';

  @override
  String get editSaveChanges => 'Değişiklikleri kaydet';

  @override
  String get editProfileTitle => 'Profili Düzenle';

  @override
  String get editNicknameLabel => 'Takma ad';

  @override
  String get editRoleNameLabel => 'Kullanıcı adı';

  @override
  String get editNicknameHint => 'Takma adınızı girin';

  @override
  String get editNicknameRequired => 'Lütfen takma ad girin';

  @override
  String get editProfileBioLabel => 'Biyografi';

  @override
  String get editProfileBioHint => 'Lütfen biyografiyi girin';

  @override
  String get editProfileEmailLabel => 'E-posta adresi';

  @override
  String get editAvatarCropTitle => 'Avatarı Kırp';

  @override
  String get profileUpdateSuccess => 'Profil güncellendi';

  @override
  String incomeClaimAmount(String amount, String currency) {
    return '$amount $currency Talep Et';
  }

  @override
  String get incomeClaimFailed => 'Talep başarısız';

  @override
  String incomeClaimMessage(String amount, String currency) {
    return 'Talep edilebilir tutar: $amount $currency\nKazançlar cüzdan bakiyenize aktarılacaktır';
  }

  @override
  String get incomeClaimSuccess => 'Talep başarılı';

  @override
  String get incomeClaimTitle => 'Kazançları almak';

  @override
  String get incomeConfirmClaim => 'Alındığını onayla';

  @override
  String get incomeHistoryTab => 'Geçmiş';

  @override
  String get incomeInviteHeroSubtitle =>
      'Arkadaşlarınızı tüketmeye ve etkileşime davet edin, ne kadar aktif olurlarsa ödül o kadar yüksek olur';

  @override
  String get incomeInviteHeroTitle =>
      'Arkadaşlarınızı Davet Edin, Nakit Para Kazanın';

  @override
  String get incomeInviteNoRecords => 'Nakit para kaydı yok';

  @override
  String get incomeInvitePaidUnlockDesc =>
      'Arkadaşlar bölüm açmak için ödeme yapar';

  @override
  String get incomeInvitePaidUnlockTitle => 'Ücretli Açma';

  @override
  String get incomeInviteRecords => 'Nakit Para Kayıtları';

  @override
  String get incomeInviteRegisterDesc =>
      'Arkadaşlar referans linkinizle kayıt olur';

  @override
  String get incomeInviteRegisterTitle => 'Davet Kaydı';

  @override
  String get incomeInviteRules => 'Nakit Para Kuralları';

  @override
  String get incomeInviteShareLink => 'Davet Linkini Paylaş';

  @override
  String get incomeInviteStakeDesc => 'Arkadaşlar NFT veya STORY stake eder';

  @override
  String get incomeInviteStakeTitle => 'Stake Yatırımı';

  @override
  String get incomeInviteTab => 'Davet Nakit Paras';

  @override
  String get incomeInviteWatchDesc =>
      'Arkadaşlar puan kazanmak için drama izler';

  @override
  String get incomeInviteWatchTitle => 'Drama İzle';

  @override
  String get incomeNoHistory => 'Geçmiş kaydı yok';

  @override
  String get incomeNoRecords => 'Kazanç kaydı yok';

  @override
  String get incomeNothingToClaim => 'Talep edilecek bir şey yok';

  @override
  String get incomeOverviewTab => 'Genel Bakış';

  @override
  String get incomePendingClaim => 'Talep Bekliyor';

  @override
  String get incomeRecords => 'Kazanç Kayıtları';

  @override
  String get incomeThisMonth => 'Bu Ay';

  @override
  String get incomeToday => 'Bugün';

  @override
  String get incomeTotalEarnings => 'Toplam kazanç';

  @override
  String get incomeCumulativeStory => 'Toplam STORY';

  @override
  String incomeCumulativeUsdc(String currency) {
    return 'Toplam $currency';
  }

  @override
  String get incomeClaimableStory => 'STORY\'yi alabilirsiniz';

  @override
  String incomeClaimableUsdc(String currency) {
    return '$currency çekilebilir';
  }

  @override
  String get incomeSettlingStory => 'Ücretim';

  @override
  String get incomeSettlingHint =>
      'Hesaplanıyor; geldikten sonra talep edilebilir';

  @override
  String get incomeHelpTotalStoryDesc =>
      'Tüm dönemler boyunca toplamda kazanılan STORY miktarı (alınan ve alınmamış olanlar dahil).';

  @override
  String incomeHelpTotalUsdcDesc(String currency) {
    return 'Tarih boyunca tüm karakterlerin sözleşme payları ve ikincil telif gelirlerinden elde edilen toplam $currency geliri.';
  }

  @override
  String get incomeHelpSettlingStoryDesc =>
      'Sistem hesaplamasından sonra otomatik olarak STORY’ye dönüştürülür';

  @override
  String get incomeHelpClaimableStoryDesc =>
      'Ödemesi tamamlanmış STORY\'leri kişisel cüzdanınıza aktarabilirsiniz.';

  @override
  String incomeHelpClaimableUsdcDesc(String currency) {
    return 'Hesaplaşması tamamlanmış $currency’leri kişisel cüzdanınıza aktarabilirsiniz.';
  }

  @override
  String get incomeFilterAll => 'Tümü';

  @override
  String get incomeFilterMining => 'Gönderim Geliri';

  @override
  String get incomeFilterInvite => 'Davet Kazancı';

  @override
  String get incomeMiningReward => 'Gönderim Geliri';

  @override
  String get incomeInviteReward => 'Davet Kazancı';

  @override
  String get incomeUsdcActorSignShare => 'Karakter imza gelir payı';

  @override
  String get incomeClaimNoWallet => 'Lütfen önce cüzdanınızı bağlayın';

  @override
  String incomeClaimCurrencyTitle(String currency) {
    return '$currency Talep Et';
  }

  @override
  String incomeClaimWithdrawMessage(
    String amount,
    String currency,
    String address,
  ) {
    return 'Solana cüzdanınıza $amount $currency çekmek istediğinizden emin misiniz?\nAlıcı: $address';
  }

  @override
  String get incomeClaimWithdrawConfirm => 'Çekimi Onayla';

  @override
  String get incomeClaimWithdrawSubmitted => 'Çekim başarılı!';

  @override
  String get incomeClaimWithdrawFailed =>
      'Çekim başarısız, lütfen tekrar deneyin';

  @override
  String get incomeClaimAction => 'Almak';

  @override
  String get nftCreateActorIp => 'Karakter IP Oluştur';

  @override
  String get nftHeaderSubtitle =>
      'Özel karakter NFT\'lerini keşfedin ve toplayın';

  @override
  String get nftHeaderTitle => 'Karakter NFT Meydanı';

  @override
  String get nftSearchHint => 'Dizi, eser, rol, kullanıcı ara...';

  @override
  String get actorHowToPlayTitle => 'Karakter IP’si nasıl oynanır?';

  @override
  String get actorHowToPlayHelpTooltip => 'Oyun Talimatları';

  @override
  String get actorHowToPlaySignTab => 'İmzalanan IP\'ler';

  @override
  String get actorHowToPlaySignSubtitle => 'Pasif olarak ücret kazan';

  @override
  String get actorHowToPlayIssueTab => 'IP yayınla';

  @override
  String get actorHowToPlayIssueSubtitle => 'Yaratıcılıktan Gelir Elde Etme';

  @override
  String get actorHowToPlaySignPositioning =>
      'Hedef kitle: Yaratıcılık konusunda hiçbir engel yok, kolayca ve istikrarlı bir şekilde kazanç elde edin';

  @override
  String get actorHowToPlaySignAudience =>
      'Yaratıcı içerik üretmek istemeyen, STORY gelirini kolayca elde etmek isteyen sıradan kullanıcılar';

  @override
  String get actorHowToPlaySignGuide =>
      'Yüksek popülerliğe ve yüksek ücrete sahip karakter IP\'leri imzala; Ajan sayfasından gösterileri ayarlayarak kazanç elde et';

  @override
  String get actorHowToPlaySignRightsTitle => 'Çifte kazanç';

  @override
  String get actorHowToPlaySignRightPerform =>
      'Gösteri düzenleyin ve sürekli olarak STORY tokeni kazanın';

  @override
  String get actorHowToPlaySignRightTrade =>
      'Karakter IP’leri takas edilebilir ve prim geliri elde edilebilir';

  @override
  String get actorHowToPlayIssuePositioning =>
      'Konumlandırma: yarat ve yayınla, çoklu gelir akışı, uzun vadeli IP değer artışı';

  @override
  String get actorHowToPlayIssueAudience =>
      'Yaratıcı yeteneklere sahip, karakter IP’leri ve kısa diziler yoluyla gelir elde etmek isteyen içerik üreticiler';

  @override
  String get actorHowToPlayIssueGuide =>
      'Karakter IP\'leri yayınlayın, AI kısa dizileriyle eşleştirin, popülerliği artırın ve IP ücretleri ile gelirini yükseltin';

  @override
  String get actorHowToPlayIssueRightsTitle => 'Üçlü getiri';

  @override
  String get actorHowToPlayIssueRightSignLabel => 'İmza gelir payı:';

  @override
  String get actorHowToPlayIssueRightSign =>
      'Kendi IP\'n imzalandığında %40 pay alırsın';

  @override
  String get actorHowToPlayIssueRightPerformLabel => 'Gösteri gelirleri:';

  @override
  String get actorHowToPlayIssueRightPerform =>
      'Kendi IP\'ni imzala, gösterilerle STORY kazan';

  @override
  String get actorHowToPlayIssueRightValueLabel => 'Değer artışı:';

  @override
  String get actorHowToPlayIssueRightValue =>
      'IP\'ler alınıp satılabilir; popülerlik arttıkça prim de artar';

  @override
  String get actorHowToPlayAudienceTitle => 'Uygun Kişiler';

  @override
  String get actorHowToPlayGuideTitle => 'Oyun Kılavuzu';

  @override
  String get actorHowToPlayCreateHint =>
      'DreamOS ile tek bir tıklamayla karakter IP\'leri ve AI kısa dizileri oluşturabilir, yüksek verimlilikle kaliteli içerik üretebilirsiniz';

  @override
  String get actorHowToPlayCreateCta => 'Yaratmaya başla';

  @override
  String get nftSignInDevelopment => 'Bu özellik henüz kullanıma açılmamıştır';

  @override
  String get nftSortCompleted => 'Tam izlenme';

  @override
  String get nftSortHeat => 'Popülerlik';

  @override
  String get nftSortIpPower => 'IP ücreti';

  @override
  String get nftSortLowestPrice => 'Fiyat';

  @override
  String get nftSortLv1Pay => 'Ücret';

  @override
  String get nftSortMaxPay => 'Maksimum ücret';

  @override
  String get nftTradeUnavailable => 'Ticaret henüz mevcut değil';

  @override
  String playerEpisodeBarCompleted(int count) {
    return 'Tüm $count bölüm · Tamamlandı';
  }

  @override
  String playerEpisodeSynopsis(int episodeNo, String synopsis) {
    return 'Bölüm $episodeNo | $synopsis';
  }

  @override
  String get playerPlayFailedRetry =>
      'Oynatma başarısız, lütfen daha sonra tekrar deneyin';

  @override
  String get publicProfileDramas => 'Kısa dizi';

  @override
  String get publicProfileEmpty => 'Herkese açık içerik yok';

  @override
  String get publicProfileBlock => 'Engelle';

  @override
  String get publicProfileUnblock => 'Engeli kaldır';

  @override
  String get publicProfileBlockedByMeContent =>
      'Bu kullanıcıyı engellediğiniz için içeriklerini görüntüleyemezsiniz';

  @override
  String get publicProfileBlockedContent =>
      'Bu kullanıcı sizi engellediği için içeriklerini görüntüleyemezsiniz';

  @override
  String get publicProfileBlockConfirmTitle => 'Bu kullanıcı engellensin mi?';

  @override
  String get publicProfileBlockConfirmMessage =>
      'Engelledikten sonra bu kullanıcının eserlerini görüntüleyemezsiniz.';

  @override
  String get publicProfileBlockSuccess => 'Kullanıcı engellendi';

  @override
  String get publicProfileUnblockSuccess => 'Kullanıcının engeli kaldırıldı';

  @override
  String get publicProfileFollowers => 'Takipçiler';

  @override
  String get publicProfileFollowing => 'Takip';

  @override
  String get followTabMutual => 'Karşılıklı';

  @override
  String get profileLikesReceived => 'Beğeni';

  @override
  String profileLikesReceivedDialogMessage(int count) {
    return '$count beğeni aldın, harika içeriklerin için teşekkürler!';
  }

  @override
  String get profileTabLikes => 'Beğeniler';

  @override
  String get profileTabFavorites => 'Favoriler';

  @override
  String get profileWalletTitle => 'Cüzdan';

  @override
  String get profileAddressCopied => 'Adres kopyalandı';

  @override
  String get followActionFollow => 'Takip et';

  @override
  String get followActionFollowBack => 'Geri takip';

  @override
  String get followActionFollowing => 'Takip ediliyor';

  @override
  String get followBlockedByMe =>
      'Bu kullanıcı kara listenizde, takip edemezsiniz';

  @override
  String get followBlockedByTarget =>
      'Bu kullanıcının ayarları nedeniyle takip edemezsiniz';

  @override
  String get likeBlockedByMe => 'Bu kullanıcı kara listenizde, beğenemezsiniz';

  @override
  String get likeBlockedByTarget =>
      'Bu kullanıcının ayarları nedeniyle beğenemezsiniz';

  @override
  String get favoriteBlockedByMe =>
      'Bu kullanıcı kara listenizde, favorilere ekleyemezsiniz';

  @override
  String get favoriteBlockedByTarget =>
      'Bu kullanıcının ayarları nedeniyle favorilere ekleyemezsiniz';

  @override
  String get ratingBlockedByMe =>
      'Bu kullanıcı kara listenizde, puan veremezsiniz';

  @override
  String get ratingBlockedByTarget =>
      'Bu kullanıcının ayarları nedeniyle puan veremezsiniz';

  @override
  String get followActionMutual => 'Karşılıklı';

  @override
  String get followUnfollowTitle => 'Takipten çık';

  @override
  String followUnfollowMessage(String handle) {
    return '$handle takipten çıkılsın mı?';
  }

  @override
  String get followUnfollowNo => 'Hayır';

  @override
  String get followUnfollowYes => 'Evet';

  @override
  String get followListEmpty => 'Henüz kullanıcı yok';

  @override
  String get followFollowingEmpty =>
      'Henüz kimseyi takip etmiyorsun. İlginç yaratıcıları keşfet~';

  @override
  String get followFollowingEmptyCta => 'Göz at';

  @override
  String get followFollowingEmptyGuest => 'Takip yok';

  @override
  String get followFollowersEmpty =>
      'Henüz takipçin yok. Daha fazla görünürlük için eser yayınla~';

  @override
  String get followFollowersEmptyCta => 'Yayınla';

  @override
  String get followFollowersEmptyGuest => 'Takipçi yok';

  @override
  String get followMutualsEmpty => 'Henüz karşılıklı takip yok';

  @override
  String get followMutualsSelfOnly =>
      'Karşılıklı takip listesini yalnızca siz görebilirsiniz';

  @override
  String get followRelationsSelfOnly =>
      'Takip listelerini yalnızca siz görebilirsiniz';

  @override
  String get followMoreTitle => 'Diğer';

  @override
  String get followRemoveFollower => 'Takipçiyi kaldır';

  @override
  String get followRemoveFollowerSuccess => 'Kaldırıldı. Bildirim gönderilmez';

  @override
  String get followUserHandleFallback => '@kullanıcı';

  @override
  String get publicProfileTitle => 'Kullanıcı Profili';

  @override
  String publicProfileUserFallback(String id) {
    return 'Kullanıcı #$id';
  }

  @override
  String get watchHistoryEmpty => 'İzleme geçmişi yok';

  @override
  String get watchHistoryClearTitle => 'İzleme geçmişini temizle';

  @override
  String get watchHistoryClearMessage =>
      'Tüm izleme geçmişini temizlemek istediğinizden emin misiniz? Bu işlem geri alınamaz.';

  @override
  String get watchHistoryClearConfirm => 'Onayla';

  @override
  String get gamePageTitle => 'Menajer';

  @override
  String get gamePageSubtitle =>
      'Rollerini yönet, görevlendirerek gelir elde et.';

  @override
  String get gameRiskAccount => 'Riskli Hesap';

  @override
  String get gameRiskAccountDescription =>
      'Bu hesabın güven katsayısı anormal; madencilik ağırlığı etkilenecektir.';

  @override
  String get gameWeeklyStats => 'Haftalık İstatistikler';

  @override
  String get gameDeployedActors => 'Dağıtılmış Roller';

  @override
  String get gameMyActors => 'Rollerim';

  @override
  String get gameComingSoon => 'Yakında';

  @override
  String get gameSignActor => 'Karakter imzala';

  @override
  String get gameGoProduce => 'Dizi çekmeye gitmek';

  @override
  String get gameWorkingActors => 'Görevlendirilmiş roller';

  @override
  String get gameWeekPool => 'Bu Haftanın Ödül havuzu (STORY)';

  @override
  String get gameWeekNominalOutput => 'Bu Haftanın Nominal Üretimi (STORY)';

  @override
  String get gameWeekEstimatedOutput => 'Bu Haftanın Tahmini Üretimi (STORY)';

  @override
  String get gameMiningRules => 'Madencilik kuralları';

  @override
  String get agentV2RulesTitle => 'İşletme';

  @override
  String get agentV2RulesSummary =>
      'Karakterlerle sözleşme yapıp performans planlayarak her saat STORY kazanın.\nKarakterleri yükselterek saatlik ücretlerini katlayın.\nÜretimin durmaması için dayanıklılık bittiğinde hemen doldurun.\nDönem kazançlarının hesaplaşması her pazartesi 00:00\'da (UTC) başlar; Kazançlar sayfasından alın.';

  @override
  String get agentV2RulesHowToPlay => 'Nasıl çalışır?';

  @override
  String get agentV2RulesStartTitle => 'Karakterler nasıl kazanmaya başlar?';

  @override
  String get agentV2RulesStartDescription =>
      'Müsait bir karakteri performansa atayın. Her saat 1 dayanıklılık harcar ve ücretine göre STORY üretir.\nÜretilen STORY her dönemin sonunda topluca hesaplanır ve ardından Kazançlar sayfasından alınabilir.';

  @override
  String get agentV2RulesStaminaTitle => 'Dayanıklılık nasıl yönetilir?';

  @override
  String agentV2RulesStaminaDescription(int staminaLimit) {
    return 'Performansta: saatte 1 dayanıklılık harcar ve normal ücret üretir\nDayanıklılık bitti: üretim 0\'da durur ve müdahale gerekir\nDinlenmede: saatte 1 dayanıklılık otomatik yenilenir, ancak ücret durur\nDayanıklılık doldurma (ücretli): anında $staminaLimit seviyesine çıkar ve üretimi sürdürür';
  }

  @override
  String get agentV2RulesBatchTitle => 'Toplu işlem yapabilir miyim?';

  @override
  String get agentV2RulesBatchDescription =>
      'Evet. Performans yuvalarındaki tüm karakterlere işlem uygulamak için sayfanın altındaki Tümünü Oynat, Tümünü Doldur veya Tümünü Dinlendir seçeneklerini kullanın.';

  @override
  String get agentV2RulesEarnings => 'Kazançlar';

  @override
  String get agentV2RulesSalaryTitle => 'Ücret nasıl hesaplanır?';

  @override
  String get agentV2RulesSalaryDescription =>
      'Ün ne kadar yüksekse, rol ne kadar değerliyse ve kısa dizi ne kadar popülerse saatlik ücret o kadar yüksek olur.';

  @override
  String get agentV2RulesSalaryFormula =>
      'Kart başına saatlik ücret = Karakter Ücreti × 1 STORY';

  @override
  String get agentV2RulesRolePowerFormula =>
      'Karakter ücreti = Lv.1 karakter ücreti × Ücret katsayısı';

  @override
  String get agentV2RulesIpSalaryFormula =>
      'Lv.1 karakter ücreti = Fiyat katsayısı × Popülerlik katsayısı';

  @override
  String get agentV2RulesCoefficientTitle => 'Katsayı ayrıntıları';

  @override
  String agentV2RulesSalaryExample(String currency) {
    return 'Lin Mengyao · Lv3 Başrol · P0=120$currency (fiyat katsayısı ≈1.5046) · popülerlik 3.5\n→ Saatlik ücret = 5.0 × 1.5046 × 3.5 × 1 = 26.3 STORY\nLv1 Figüran olsaydı saatte yalnızca ≈5.3 STORY kazanırdı; Lv3\'e yükseltmek kazancı beş kat artırır.';
  }

  @override
  String get agentV2RulesSettlementTitle => 'Ne zaman hesaplanır?';

  @override
  String get agentV2RulesSettlementDescription =>
      'Her performans döngüsü 7 gündür ve her pazartesi 00:00\'da (UTC) kapanır. Sistem hesaplaması tamamlandıktan sonra bu dönemin ücreti otomatik olarak STORY’ye dönüştürülür ve Kazançlar sayfasından alınabilir.';

  @override
  String get agentV2RulesSettlementExample =>
      'Bu haftaki ödül havuzunun 100,000 STORY olduğunu varsayalım:\nDurum A: Platform genelinde yalnızca siz 134 üretirsiniz → 134 alırsınız, kalan dağıtılmaz\nDurum B: Ağ üretimi 250,000 → 100,000 ÷ 250,000 = %40; nominal üretiminiz %40\'a ölçeklenir\nDurum C: Ölçeklemeden sonra birinin 6,000 alması gerekir ancak üst sınır 5,000\'dir → yalnızca 5,000 dağıtılır';

  @override
  String get agentV2RulesStronger => 'Güçlenme';

  @override
  String get agentV2RulesUpgradeTitle => 'Bir karakter nasıl yükseltilir?';

  @override
  String get agentV2RulesUpgradeDescription =>
      'Koşullar: aynı IP ve seviyede 2 kopya tüket + IP\'nin dizilerindeki toplam tam izlenme hedefini karşıla\nSeviye 1 → Seviye 2: ≥10.000 tam izlenme · Ücret 1→3\nSeviye 2 → Seviye 3: ≥50.000 tam izlenme · Ücret 3→9\nSeviye 3 → Seviye 4: ≥200.000 tam izlenme · Ücret 9→27\nSeviye 4 → Seviye 5: ≥1 milyon tam izlenme · Ücret 27→81';

  @override
  String get agentV2RulesPerforming => 'Performansta';

  @override
  String get agentV2RulesNormalSalary => 'Normal ücret';

  @override
  String get agentV2RulesSalaryCoefficient =>
      'Ücret katsayısı: Lv1=1 · Lv2=3 · Lv3=9 · Lv4=27 · Lv5=81';

  @override
  String agentV2RulesPriceCoefficientDescription(
    String currency1,
    String currency2,
  ) {
    return 'Fiyat katsayısı (ihraç fiyatı P0):\n  • P0 ≤ 100$currency1 → Katsayı = P0 ÷ 100 (doğrusal artış)\n  • P0 > 100$currency2 → Katsayı = 1,6 × (P0/100)¹.³ / [(P0/100)¹.³ + 0,6] (asimtotik üst sınır 1,6)';
  }

  @override
  String get agentV2RulesTrust2 => 'Trust2';

  @override
  String get agentV2RulesTrust2Factor => 'Platform Trust2 değeri';

  @override
  String get agentV2RulesSettlementCase1 =>
      'Gerçek ödeme = nominal üretim; kullanılmayan kapasite sona erer';

  @override
  String get agentV2RulesSettlementCase2 =>
      'Orantılı ölçekleme: gerçek ödemeniz = nominal üretiminiz × (ödül havuzu ÷ ağ üretimi)';

  @override
  String get gameSettlementRecords => 'Haftalık Hesap Kapatma Kayıtları';

  @override
  String get gameFilterComputingPower => 'Ücret';

  @override
  String get gameFilterLevel => 'Seviye';

  @override
  String get gameFilterHeat => 'Popülerlik';

  @override
  String get gameFilterStamina => 'Dayanıklılık';

  @override
  String get gameHeatCoef => 'Popülerlik katsayısı';

  @override
  String get gameMiningCoef => 'Madencilik katsayısı';

  @override
  String get gameActorPower => 'Karakter Ücreti';

  @override
  String get gameActorPowerDetailTitle => 'Karakter Ücreti Detayları';

  @override
  String get gameActorPowerFormula =>
      'Karakter Ücreti = IP Ücreti × Madencilik katsayısı × CP katsayısı × Trust2';

  @override
  String get gameActorPowerIpFormula =>
      'IP Ücreti = Fiyat katsayısı × Popülerlik katsayısı × Trust1';

  @override
  String get gameActorPowerHourlyOutput => 'Saatlik çıktı';

  @override
  String get gameCpCoefficient => 'CP katsayısı';

  @override
  String get gameTrust2 => 'Trust2';

  @override
  String get gameWeeklyNominalOutputLabel => 'Bu haftanın nominal üretimi';

  @override
  String get gameRoundNominalOutputLabel => 'Dönem Nominal Çıktı';

  @override
  String get gameSupplement => 'Ek bilgi';

  @override
  String get gameRest => 'Dinlenme';

  @override
  String get gameDeploy => 'Gönderme';

  @override
  String get gameDeployActor => 'Karakter Gönder';

  @override
  String get gameStatusIdle => 'Kullanılmayan';

  @override
  String get gameStatusMining => 'Madencilik devam ediyor';

  @override
  String gameActorIpLabel(String id) {
    return 'Karakter IP $id';
  }

  @override
  String gameStaminaProgress(String current, String max) {
    return '$current/$max';
  }

  @override
  String get gameStaminaMechanismTitle => 'Dayanıklılık sistemi';

  @override
  String gameStaminaMechanismDesc(String currency) {
    return 'Görevlendirilen aktörler saatte 1 dayanıklılık puanı harcar. Dayanıklılık tükendiğinde getiri üretimi durur ve dinlenirken otomatik olarak yenilenir. $currency kullanarak dayanıklılığı anında yenileyebilirsiniz.';
  }

  @override
  String get gameStaminaMechanismAction => 'Anladım';

  @override
  String gameLevelBadge(String level) {
    return 'Sv$level';
  }

  @override
  String get gameEmptyDeployed => 'Şu anda dağıtılmış rol yok';

  @override
  String get gameEmptyMyActors =>
      'Henüz karakteriniz yok. Başlamak için bir karakter imzalayın.';

  @override
  String get gameDeployConfirmTitle => 'Bu karakteri dağıtmak istiyor musunuz?';

  @override
  String get gameRestConfirmTitle =>
      'Bu karakteri dinlendirmek istiyor musunuz?';

  @override
  String get gameRestConfirmDesc =>
      'Karakter dinlenirken madencilik duraklatılır; dayanıklılık zamanla yenilenir.';

  @override
  String get gameRestConfirmAction => 'Dinlenmeyi Onayla';

  @override
  String get gameRestSuccessToast => 'Dinlenme başladı';

  @override
  String get gameDeploySlotFull => 'Dağıtım slotları dolu (maks 5)';

  @override
  String get gameRefillTitle => 'Dayanıklılığını geri kazanmak';

  @override
  String get gameRefillCurrentStamina => 'Şu anki dayanıklılık';

  @override
  String get gameRefillCost => 'Geri kazanım masrafları';

  @override
  String get gameRefillConfirm => 'Tüm dayanıklılığını geri kazan';

  @override
  String get gameRefillSuccess =>
      'Dayanıklılığın geri kazanılması başarılı oldu';

  @override
  String get gameRefillFailed =>
      'Dayanıklılık yenileme işlemi başarısız oldu, lütfen tekrar deneyin';

  @override
  String gameInsufficientUsdc(String currency) {
    return '$currency bakiyesi yetersiz';
  }

  @override
  String get walletInsufficientStory => 'STORY bakiyesi yetersiz';

  @override
  String get gameSupplementComingSoon => 'Dayanıklılık doldurma yakında';

  @override
  String get gameStatHelpWeekPoolTitle => 'Bu Haftanın Ödül havuzu';

  @override
  String get gameStatHelpWeekPoolSubtitle =>
      'Yani, STORY madenciliğinde haftalık zorunlu dağıtım üst sınırı (haftalık üst sınır)';

  @override
  String get gameStatHelpWeekTotalPool => 'Bu haftanın toplam ödül havuzu';

  @override
  String get gameStatHelpWeekTotalPoolValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeekStakePool =>
      'Bu haftanın staking ödül havuzu (%75)';

  @override
  String get gameStatHelpWeekStakePoolValue => '1,586,538 STORY';

  @override
  String get gameStatHelpWeekInvitePool =>
      'Bu haftanın davet ödül havuzu (%25)';

  @override
  String get gameStatHelpWeekInvitePoolValue => '528,846 STORY';

  @override
  String get gameStatHelpInitialHardCap => 'İlk hafta sabit tavan';

  @override
  String get gameStatHelpInitialHardCapValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeeklyDecay => 'Haftalık zayıflama katsayısı';

  @override
  String get gameStatHelpWeeklyDecayValue => '× 0.99572';

  @override
  String get gameStatHelpWeeklyDistributionFormula =>
      'Haftalık fiili dağıtım = min(tüm ağın nominal üretimi, o haftanın üst sınırı)';

  @override
  String get gameStatHelpUnusedQuotaNote =>
      'Kullanılmayan kalan kotalar dağıtılmaz, geri dönmez ve puan olarak telafi edilmez.';

  @override
  String get gameStatHelpNominalTitle => 'Bu Haftanın Nominal Üretimi';

  @override
  String get gameStatHelpNominalSummary =>
      'Tüm rollerimin haftalık toplam nominal üretiminin toplamı';

  @override
  String get gameStatHelpNominalSummaryHint =>
      'Tek kart formülü için aşağıdaki açıklamaya bakınız';

  @override
  String get gameStatHelpNominalFormula =>
      'Kart başına nominal üretim = Kart başına saatlik ağırlık × R_base × Etkili madencilik süresi';

  @override
  String get gameStatHelpHourlyWeight => 'Tek kart saat ağırlığı';

  @override
  String get gameStatHelpHourlyWeightValue => '= Karakter Ücreti';

  @override
  String get gameStatHelpActorPower => 'Karakter Ücreti';

  @override
  String get gameStatHelpActorPowerValue =>
      '= IP Ücreti × Madencilik Katsayısı × CP Katsayısı × Trust2';

  @override
  String get gameStatHelpCpCoef => 'CP katsayısı';

  @override
  String get gameStatHelpRBase => 'R_base';

  @override
  String get gameStatHelpRBaseValue => '1 STORY / Birim ağırlık / Saat';

  @override
  String get gameStatHelpEffectiveDuration => 'Etkili madencilik süresi';

  @override
  String get gameStatHelpEffectiveDurationValue =>
      'Rehin altında olan ve dayanıklılık değeri &gt; 0 olan toplam süre';

  @override
  String get gameStatHelpActualTitle => 'Bu haftaki tahmini üretim';

  @override
  String get gameStatHelpActualSubtitle =>
      'Tahmini üretim haftalık üst sınır ve tek adres üst sınırıyla kısıtlanır; gerçek ödül hafta sonunda oluşur';

  @override
  String get gameStatHelpIfNominalLte =>
      'Eğer ağ genelindeki nominal üretim, o haftanın üst sınırına eşitse veya bu sınırın altındaysa:';

  @override
  String get gameStatHelpUserActualEqNominal =>
      'Kullanıcının eline geçen tutar = Kullanıcının nominal üretimi';

  @override
  String get gameStatHelpIfNominalGt =>
      'Eğer ağ genelindeki nominal üretim &gt; o haftanın üst sınırı ise:';

  @override
  String get gameStatHelpUserActualFormula =>
      'Kullanıcının eline geçen miktar = Kullanıcının nominal üretimi × O haftanın sabit tavanı / Ağın toplam nominal üretimi';

  @override
  String get gameStatHelpAddressCap => 'Tek adres için haftalık üst sınır';

  @override
  String get gameStatHelpAddressCapValue =>
      'Her adres, haftalık olarak o haftanın üst sınırının en fazla %5’ini alabilir.';

  @override
  String get theaterCategoryAll => 'Tümü';

  @override
  String get theaterCategoryAncient => 'Tarihi';

  @override
  String get theaterCategoryFinance => 'Finans';

  @override
  String get theaterCategorySuspense => 'Gerilim';

  @override
  String get theaterCategorySciFi => 'Bilim kurgu';

  @override
  String get theaterCategoryRealStory => 'Gerçek bir olaydan uyarlanmıştır';

  @override
  String get theaterCategoryUrban => 'Şehir';

  @override
  String get theaterSortHottest => 'En popüler';

  @override
  String get theaterSortNewest => 'En son';

  @override
  String get theaterSortTopRated => 'En Çok Eklenenler';

  @override
  String get theaterSortCompletedView => 'En Çok Tamamlanan';

  @override
  String theaterPlayCount(String count) {
    return '$count oynatma';
  }

  @override
  String get createDramaBasicInfo => 'Temel Bilgiler';

  @override
  String get createDramaEpisodes => 'Dizi Yönetimi';

  @override
  String get createDramaRoles => 'IP Bağla';

  @override
  String get createDramaCover => 'Kapak';

  @override
  String get createDramaCoverUpload => 'Yükle';

  @override
  String get createDramaCoverPlaceholder => 'JPG/PNG desteklenir, maks. 5 MB';

  @override
  String get createDramaCoverCropTitle => 'Kapak Kırp';

  @override
  String get createDramaName => 'Kısa dizi başlığı';

  @override
  String get createDramaNameHint => 'Lütfen kısa oyunun adını girin';

  @override
  String get createDramaSynopsis => 'Tanıtım';

  @override
  String get createDramaTags => 'Etiket';

  @override
  String get createDramaTagsHint =>
      'Etiket yazın ve eklemek için Enter\'a basın (ör. Aşk, Komedi)';

  @override
  String get createDramaTagsLoading => 'Etiketler yükleniyor…';

  @override
  String get createDramaTagsEmpty => 'Kullanılabilir etiket yok';

  @override
  String get createDramaTagsRetry => 'Tekrar dene';

  @override
  String get createDramaUploadDesc =>
      '\"Yükle\"ye tıklayın; gönderildikten sonra videolar adlarına göre otomatik olarak sıralanacaktır';

  @override
  String get createDramaEpisodesDesc =>
      'Video dosyalarını toplu olarak yüklediğinizde, sistem dosya adlarına göre otomatik olarak bir bölüm listesi oluşturur. Sürükleyip bırakarak sıralama, silme ve başlık düzenleme gibi işlemleri destekler.';

  @override
  String get createDramaVideoFileTypeHint =>
      'Desteklenen formatlar: mp4, flv, wmv, asf, mkv, avi, rm, rmvb, mpg, mpeg, mov, webm. Maks dosya boyutu 2GB.';

  @override
  String get createDramaUploadVideo => 'Videoyu yükle';

  @override
  String get createDramaVideoEmpty => 'Henüz video eklenmedi';

  @override
  String get createDramaVideoPickFailed => 'Video seçme başarısız';

  @override
  String get createDramaVideoAnyTooLarge =>
      '2GB\'yi aşan video dosyaları var, lütfen düzenleyip yeniden seçin';

  @override
  String get createDramaVideoStatusUploading => 'Yükleniyor';

  @override
  String get createDramaVideoStatusPaused => 'Yükleme duraklatıldı';

  @override
  String get createDramaVideoStatusDone => 'Yükleme tamamlandı';

  @override
  String get createDramaEpisodeDescriptionHint => 'Bölüm açıklaması';

  @override
  String get createDramaVideoStatusFailed => 'Yükleme başarısız';

  @override
  String get createDramaVideoTooLarge =>
      'Video boyutu 2 GB\'ı aşamaz ve yüklenemez';

  @override
  String get createDramaVideoUploadComplete => 'Tüm videolar yüklendi';

  @override
  String createDramaVideoUploadFailed(String name) {
    return '$name yükleme başarısız';
  }

  @override
  String createDramaVideoPickOverflow(int count, int overflow) {
    return 'En fazla $count bölüm daha ekleyebilirsiniz. $overflow fazla atlandı.';
  }

  @override
  String createDramaAddedVideos(String count) {
    return 'Eklenen videolar ($count dosya)';
  }

  @override
  String createDramaAddedVideosCount(String count) {
    return '($count dosya)';
  }

  @override
  String get createDramaAddedVideosLabel => 'Eklenen videolar';

  @override
  String get createDramaRolesDesc =>
      'Kısa dizi için rol oluşturun; rolün adını, profil resmini ve kişilik tanımını belirleyin.';

  @override
  String get createDramaRolesRule1 =>
      'Her kısa diziye en fazla 5 Karakter IP\'si bağlanabilir. Yayından sonraki 7 gün içinde yenileri eklenebilir; sonrasında bağlar kaldırılamaz veya değiştirilemez.';

  @override
  String get createDramaRolesRule2 =>
      'Bağlanan Karakter IP\'si, yükseltmeler ve STORY ödülleri için dizinin tamamlanma ve popülerlik verileriyle ilişkilendirilir.';

  @override
  String get createDramaRolesExpireTime => 'Son kullanma tarihi';

  @override
  String get createDramaRolesRule3 =>
      'IP bağlamak isteğe bağlıdır; bağlamadan da yayınlayabilirsiniz.';

  @override
  String get createDramaAddRole => 'Rol ekle';

  @override
  String get createDramaBindActor => 'Role Katılım';

  @override
  String get createDramaRoleActing => 'Role Katılım';

  @override
  String get createDramaSelectActor => 'Rol Seç';

  @override
  String get createDramaBindActorTitle => 'Karakter IP Seç';

  @override
  String createDramaBindIpSelectedCount(int count) {
    return '$count seçildi';
  }

  @override
  String get createDramaBindIpEmpty => 'Veri yok';

  @override
  String get createDramaBindIpMarketplace => 'Karakter IP Pazarına Git';

  @override
  String get createDramaBindIpConfirm => 'Bağlamayı onayla';

  @override
  String createDramaBindActorSubtitle(String roleName) {
    return '\"$roleName\" rolünü oynayacak bir karakter seçin';
  }

  @override
  String createDramaBindActorOwnedCount(int count) {
    return '$count adet karakter IP\'si bulunuyor';
  }

  @override
  String createDramaBindActorIpLabel(String code) {
    return 'Karakter IP $code';
  }

  @override
  String get createDramaBindActorBoundTag => 'Bağlandı';

  @override
  String get createDramaBindIpRemove => 'Kaldır';

  @override
  String createDramaBindActorBoundToast(String name) {
    return '$name bağlandı';
  }

  @override
  String get createDramaBindActorUnbind => 'Bağlantıyı Kaldır';

  @override
  String get createDramaBindActorExpired =>
      '7 günlük bağlama süresi doldu. Yeni karakter IP bağlantısı eklenemez.';

  @override
  String get createDramaBindActorEmptyTitle => 'Bağlanacak karakter IP\'si yok';

  @override
  String get createDramaBindActorEmptyDesc =>
      'Bir role bağlamadan önce bir Karakter IP\'sine sahip olmanız gerekir';

  @override
  String get createDramaBindActorGotoCreate => 'Rol Oluştur';

  @override
  String get createDramaPrevStep => 'Önceki adım';

  @override
  String get createDramaNextStep => 'Bir sonraki adım';

  @override
  String get createDramaSubmit => 'Yayınla';

  @override
  String get createDramaRoleNameLabel => 'Rol adı';

  @override
  String get createDramaRoleNameHint => 'Lütfen rol adını girin';

  @override
  String get createDramaRoleNameRequired => 'Lütfen rol adını girin';

  @override
  String get createDramaRoleBioLabel => 'Rol Tanıtımı';

  @override
  String get createDramaRoleBioHint => 'Lütfen rol tanıtımını girin';

  @override
  String get createDramaRoleBioRequired => 'Rol tanıtımı gereklidir';

  @override
  String get createDramaRoleAddTitle => 'Rol ekle';

  @override
  String get createDramaRoleEditTitle => 'Rolü Düzenle';

  @override
  String get createDramaRoleUploadAvatar => 'Profil resmini yükle';

  @override
  String get createDramaRoleSave => 'Kaydet';

  @override
  String get createDramaRoleDeleteConfirm =>
      'Bu karakteri silmek istiyor musunuz?';

  @override
  String createDramaVideoDeleteConfirm(String name) {
    return '\"$name\" silinsin mi?';
  }

  @override
  String get createDramaVideoDeleteTitle => 'Videoyu Sil';

  @override
  String get createDramaVideoPreviewUnavailable =>
      'Daha önce yüklenen videolar şu anda önizlenemiyor';

  @override
  String get createDramaRoleEmpty => 'Henüz eklenen rol yok';

  @override
  String get createDramaRoleBindComingSoon => 'Rol bağlama yakında';

  @override
  String get createDramaRoleAvatarCropTitle => 'Rol Avatarını Kırp';

  @override
  String get createDramaRoleAvatarUploadFailed =>
      'Rol avatarı yükleme başarısız';

  @override
  String get createDramaPublishedSuccess => 'Başarıyla yayınlandı';

  @override
  String get createDramaDraftRestored =>
      'Tamamlanmamız taslağınız geri yüklendi';

  @override
  String get createDramaDraftClear => 'Verileri temizle';

  @override
  String get createDramaDraftDiscard => 'Kaydetmeden dön';

  @override
  String get createDramaDraftSave => 'Taslağı kaydet';

  @override
  String get createDramaEditLoading => 'Yükleniyor...';

  @override
  String get createDramaEditLoadError =>
      'Drama bilgisi yüklenemedi, lütfen tekrar deneyin';

  @override
  String get createDramaSubmitValidationTitle => 'Lütfen drama başlığını girin';

  @override
  String get createDramaSubmitValidationCover =>
      'Lütfen bir kapak görseli yükleyin';

  @override
  String get createDramaSubmitValidationVideos =>
      'Lütfen en az bir video yükleyin';

  @override
  String get createDramaSubmitValidationSession =>
      'Yükleme oturumu geçersiz, lütfen videoları tekrar yükleyin';

  @override
  String get createDramaUploadSessionFailed => 'Yükleme oturumu oluşturulamadı';

  @override
  String get createDramaSubmitValidationRoles => 'Lütfen en az bir rol ekleyin';

  @override
  String get createDramaStep1TitleRequired => 'Lütfen kısa oyunun adını girin';

  @override
  String get createDramaStep1SynopsisRequired =>
      'Lütfen kısa bir tanıtım yazısı girin';

  @override
  String get createDramaStep1CoverRequired => 'Lütfen bir kapak ekleyin';

  @override
  String get createDramaStep1TagsRequired => 'Lütfen etiket seçin';

  @override
  String get createDramaEpisodeDescriptionRequired =>
      'Lütfen bölüm açıklamasını girin';

  @override
  String get settingsLanguage => 'Dil';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Açık';

  @override
  String get settingsThemeDark => 'Koyu';

  @override
  String get settingsThemeSystem => 'Sistem';

  @override
  String get settingsUI => 'Arayüz';

  @override
  String get settingsAppVersion => 'Sürüm';

  @override
  String get settingsVersionLatestToast => 'En son sürümü kullanıyorsunuz';

  @override
  String get settingsVersionCheckFailed =>
      'Sürüm kontrolü başarısız. Lütfen daha sonra tekrar deneyin.';

  @override
  String get appVersionUpdateTitle => 'Yeni sürüm mevcut';

  @override
  String get appVersionUpdateContentsLabel => 'Güncelleme içeriği:';

  @override
  String get appVersionUpdateConfirm => 'Şimdi güncelle';

  @override
  String get appVersionUpdateLater => 'Daha sonra';

  @override
  String get settingsTermsOfService => 'Hizmet Şartları';

  @override
  String get settingsPrivacyPolicy => 'Gizlilik Politikası';

  @override
  String get settingsDeleteAccount => 'Hesabı Sil';

  @override
  String settingsDeleteAccountConfirm(String deadline) {
    return 'Hesabınız $deadline tarihinde silinecek. Bu süre içinde tekrar giriş yaparak hesap silmeyi iptal edebilirsiniz.';
  }

  @override
  String get settingsDeleteAccountSuccess => 'Hesap silme talebi gönderildi';

  @override
  String get settingsClearCache => 'Önbelleği Temizle';

  @override
  String get settingsNetworkInspector => 'Ağ Denetleyici';

  @override
  String get settingsClearCacheConfirm =>
      'Önbelleği temizlemek istediğinizden emin misiniz?';

  @override
  String get miningRulesHowToPlay => 'Madencilik görevleri nasıl oynanır?';

  @override
  String get miningRulesFlowSubtitle =>
      'Bir resimle, görevlendirme sürecinden ödeme almaya kadar tüm süreci bir bakışta anlayın';

  @override
  String get miningRulesSection1Title => '1. Birini madencilik yapmaya gönder';

  @override
  String get miningRulesSection1Desc =>
      'Boşta olan rolyu aşağıdaki 5 yuvaya “gönderirseniz”, rol otomatik olarak madencilik yapmaya ve STORY üretmeye başlar.';

  @override
  String get miningRulesSection1Bullet1 =>
      'Her kişi aynı anda en fazla 5 rol gönderebilir';

  @override
  String get miningRulesSection1Bullet2 =>
      'Aynı karakter IP\'sinden birden fazla kart aynı anda görevlendirilebilir';

  @override
  String get miningRulesSection1Bullet3 =>
      'Gönderildikten sonra her 1 saatte bir 1 puan ⚡dayanıklılık tüketir; dayanıklılık &gt; 0 olduğunda üretim devam eder, dayanıklılık = 0 olduğunda üretim durur';

  @override
  String get miningRulesSection2Title => '2. Para hesaplama, verim formülü';

  @override
  String get miningRulesSection2Desc =>
      'Her kartın saatlik üretimi şu şekilde hesaplanır:';

  @override
  String get miningRulesSection2Formula =>
      'Tek Kart Saatlik Çıktı = Karakter Ücreti × 1 STORY';

  @override
  String get miningRulesSection2FactorsTitle => 'Üç belirleyici faktör:';

  @override
  String get miningRulesSection2Factor1 =>
      'Madencilik katsayısı — Seviye ne kadar yüksekse katsayı da o kadar büyük olur. Seviye 1 = 1,0 → Seviye 2 = 2,2 → Seviye 3 = 5,0 → Seviye 4 = 11 → Seviye 5 = 24';

  @override
  String get miningRulesSection2Factor2 =>
      'IP Ücreti = Fiyat katsayısı × Popülerlik katsayısı × Trust1';

  @override
  String get miningRulesSection2Factor3 =>
      'R_base — Sabit değer; şu anda 1 STORY olarak ayarlanmıştır; platformda ilerleyen zamanlarda manuel olarak değiştirilebilir';

  @override
  String miningRulesSection2Factor4(String currency1, String currency2) {
    return 'Fiyat katsayısı — ihraç fiyatı P0: P0≤10$currency1 doğrusal büyüme · P0>10$currency2 için 1,6 üst sınırına yaklaşır';
  }

  @override
  String get miningRulesSection2Factor5 =>
      'Popülerlik katsayısı — son dizi performansı ne kadar iyiyse popülerlik o kadar yüksektir (tam izlenme, beğeni, kaydetme, yorum)';

  @override
  String get miningRulesSection2Factor6 =>
      'CP katsayısı — henüz kullanıma açık değil; Trust varsayılan olarak 1,0\'dır';

  @override
  String miningRulesSection2StaminaText(int staminaLimit) {
    return 'Dayanıklılık, “var mı yok mu”ya bakılır, ne kadar kaldığına bakılmaz: $staminaLimit puanlık dayanıklılık ile 1 puanlık dayanıklılığın saat başına üretimi aynıdır; dayanıklılık, sadece madencilik yapıp yapmadığınıza bağlıdır.';
  }

  @override
  String get miningRulesSection2ExampleTitle => 'Örnek vermek gerekirse:';

  @override
  String miningRulesSection2ExampleDesc(String currency) {
    return 'Lin Mengyao · Lv3 Başrol · P0=12$currency (fiyat katsayısı ≈1.0859) · popülerlik 3.5\n→ Saatlik üretim = 5.0 × 1.0859 × 3.5 × 1 = 19.00325 STORY';
  }

  @override
  String get miningRulesCoefTableTitle => 'Katsayı ayrıntıları';

  @override
  String get miningRulesCoefColCoef => 'Katsayı';

  @override
  String get miningRulesCoefColFactor => 'Belirleyen etken';

  @override
  String get miningRulesCoefColDesc => 'Ayrıntılar';

  @override
  String get miningRulesCoefMining => 'Madencilik katsayısı';

  @override
  String get miningRulesCoefPrice => 'Fiyat katsayısı';

  @override
  String get miningRulesCoefHeat => 'Popülerlik katsayısı';

  @override
  String get miningRulesCoefCp => 'CP katsayısı';

  @override
  String get miningRulesCoefTrust => 'Trust';

  @override
  String get miningRulesCoefMiningFactor => 'Seviye';

  @override
  String get miningRulesCoefPriceFactor => 'Yayın fiyatı P0';

  @override
  String get miningRulesCoefHeatFactor => 'Son dizi performansı';

  @override
  String get miningRulesCoefCpFactor => '-';

  @override
  String get miningRulesCoefTrustFactor => 'Platform risk kontrolü';

  @override
  String get miningRulesCoefMiningDesc =>
      'Lv1=1.0 · Lv2=2.2 · Lv3=5.0 · Lv4=11 · Lv5=24';

  @override
  String miningRulesCoefPriceDesc(String currency1, String currency2) {
    return 'P0≤10$currency1 iken doğrusal · P0>10$currency2 iken 1,6 asimptotik üst sınır';
  }

  @override
  String get miningRulesCoefHeatDesc =>
      'Popülerlik katsayısı: karakter IP\'sinin yer aldığı dizilerde tam izlenme, beğeni, kaydetme ve puan arttıkça popülerlik yükselir';

  @override
  String get miningRulesCoefCpDesc => 'Henüz kullanıma açık değil';

  @override
  String get miningRulesCoefTrustDesc => 'Varsayılan değer 1,0';

  @override
  String get miningRulesSection3Title =>
      '3. Para dağıtılıyor, ancak bir üst sınır var';

  @override
  String get miningRulesSection3Desc =>
      'Her hafta tüm platformda toplam ödül havuzu (haftalık sert kapak) belirlenir, yaklaşık 2.115.385 STORY\'den başlar ve her hafta azalır (haftalık × 0.99572). Ödül dağıtımı üç duruma ayrılır:';

  @override
  String get miningRulesSettleColCondition => 'Koşul';

  @override
  String get miningRulesSettleColRule => 'Dağıtım kuralı';

  @override
  String get miningRulesSection3Case1Title =>
      'Tüm platformların nominal üretimi ≤ Bu haftanın ödül havuzu';

  @override
  String get miningRulesSection3Case1Desc =>
      'Herkes listede belirtilen tutarı tam olarak alır; kalan ödül havuzu dağıtılmaz ve tamamlanmaz.';

  @override
  String get miningRulesSection3Case2Title =>
      'Tüm platformların toplam nominal üretimi &gt; Bu haftanın ödül havuzu';

  @override
  String get miningRulesSection3Case2Desc =>
      'Orantılı ölçeklendirme: Gerçek kazancınız = Nominal üretiminiz × Ödül havuzu ÷ Platformun toplam üretimi';

  @override
  String get miningRulesSection3Case3Title =>
      'Tek bir adresin payı ödül havuzunun %5’ini aşıyor';

  @override
  String get miningRulesSection3Case3Desc =>
      'Aşım kısmı ödenmez, geri aktarılmaz ve puan olarak telafi edilmez';

  @override
  String get miningRulesSection3ExampleDesc =>
      'Haftalık ödül havuzunun 100.000 STORY olduğunu varsayalım:\nDurum A: Platformda tek siz varsınız ve bir haftada 134 üretiyorsunuz → 134 alırsınız, kalan 99.866 dağıtılmaz\nDurum B: Toplam platform çıktısı 250.000, herkes %40\'a ölçeklenir (100.000÷250.000)\nDurum C: Birinin oransal ödülü 6.000 tek adres limiti 5.000 → Yalnızca 5.000 dağıtılır';

  @override
  String get miningRulesSection4Title =>
      '4. Dayanıklılığını iyi idare etmelisin ki kazmaya devam edebilesin';

  @override
  String get miningRulesTableStatus => 'Durum';

  @override
  String get miningRulesTableStaminaChange => 'Dayanıklılıktaki değişiklikler';

  @override
  String get miningRulesTableOutput => 'Çıktı';

  @override
  String get miningRulesStatusMining => 'Gönderiliyor (madencilik)';

  @override
  String get miningRulesStaminaMining => 'Saat başına -1';

  @override
  String get miningRulesOutputNormal => 'Normal üretim';

  @override
  String get miningRulesStatusZeroStamina => 'Dayanıklılık = 0';

  @override
  String get miningRulesStaminaZeroStamina => 'Artık değişmeyecek';

  @override
  String get miningRulesOutputZero => 'Çıktı 0\'dır';

  @override
  String get miningRulesStatusResting => 'Dinlenme molası';

  @override
  String get miningRulesStaminaResting => 'Saat başına +1 (otomatik yenilenir)';

  @override
  String get miningRulesOutputPaused => 'Üretimin askıya alınması';

  @override
  String get miningRulesStatusPaidRefill => 'Dayanıklılık Yenileme (Ücretli)';

  @override
  String miningRulesStaminaPaidRefill(int staminaLimit) {
    return 'Anında $staminaLimit\'e kadar doluyor';
  }

  @override
  String get miningRulesOutputRestored => 'Üretimin yeniden başlatılması';

  @override
  String get miningRulesSection4TipsTitle =>
      'Dayanıklılık takviyesiyle ilgili 3 şey:';

  @override
  String get miningRulesSection4Tip1 =>
      'Sadece tek tuşla tam dolum yapılabilir, sadece 10 puanlık satın alma yapılamaz';

  @override
  String get miningRulesSection4Tip2 =>
      'Fiyat sadece seviyenize göre belirlenir, kalan dayanıklılığınız ne kadar olduğuna bakılmaz. Dayanıklılığınız 0 iken de, 100 iken de tam olarak doldurmak için ödenen para aynıdır.';

  @override
  String get miningRulesSection4Tip3 =>
      '0’a ne kadar yakınsa, ekleme o kadar kârlı olur — aynı parayla en fazla ek madencilik süresi elde edersiniz';

  @override
  String get miningRulesSection4PriceTitle => 'Her seviyenin ek ücretleri:';

  @override
  String get miningRulesPriceTableTier => 'Statü';

  @override
  String get miningRulesPriceTableFullRefill => 'Tek Tıkla Doldur';

  @override
  String get miningRulesLv1 => 'Seviye 1: Figüran';

  @override
  String get miningRulesLv2 => 'Seviye 2 Yardımcı Karakter';

  @override
  String get miningRulesLv3 => 'Seviye 3: Ana Karakter';

  @override
  String get miningRulesLv4 => 'Seviye 4 Süperstar';

  @override
  String get miningRulesLv5 => 'Seviye 5 En Popüler';

  @override
  String get gameActorLevelName1 => 'Ekstra';

  @override
  String get gameActorLevelName2 => 'Yardımcı oyuncu';

  @override
  String get gameActorLevelName3 => 'Başrol';

  @override
  String get gameActorLevelName4 => 'Süperstar';

  @override
  String get gameActorLevelName5 => 'Üst düzey';

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
      '5. Seviyenizi yükseltin, daha fazla kazanın';

  @override
  String get miningRulesSection5Desc =>
      'Aynı seviyedeki 3 karakter kartı + birleştirme ücreti + söz konusu karakterin toplam tam izlenme hedefinin karşılanması = 1 seviye atlama. Seviye atladıktan sonra madencilik katsayısı ani bir artış gösterir ve saatlik üretim iki katına, hatta birkaç katına çıkar.';

  @override
  String get miningRulesUpgradePathSubtitle => 'Yükseltme yolu';

  @override
  String get miningRulesUpgradeColPath => 'Yükseltme yolu';

  @override
  String get miningRulesUpgradeColHeat => 'Birikmiş tam izlenme eşiği';

  @override
  String get miningRulesUpgradeColFee => 'Birleştirme ücreti';

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
  String get miningRulesSummaryTitle => 'Tek cümleyle özetlemek gerekirse';

  @override
  String get miningRulesSummaryDesc =>
      'Görevlendir → Üret → Dayanıklılığı izle → Ödülü al. Dayanıklılık azaldığında doldur veya geri çağırıp dinlendir; popülerlik, karakterin dizi performansıyla yükselir ve yükseltme üretimi katlar.';

  @override
  String get playerNotInterested => 'İlgilenmiyorum';

  @override
  String get playerNotInterestedDone =>
      'Geri bildiriminiz alındı. Buna benzer daha az video göstereceğiz';

  @override
  String get playerClearScreen => 'Ekranı temizle';

  @override
  String get playerAutoPlay => 'Otomatik oynat';

  @override
  String get playerReport => 'Rapor Et';

  @override
  String get playerReportSuccess => 'Başarıyla raporlandı';

  @override
  String get commentReportSuccess =>
      'Başarıyla gönderildi, en kısa sürede işleme alacağız';

  @override
  String get reportSuccessTitle =>
      'Başarıyla gönderildi. En kısa sürede inceleyeceğiz';

  @override
  String get reportSuccessThanks =>
      'Topluluk güvenliğine katkılarınız için teşekkürler!';

  @override
  String get reportSuccessAlsoYouCan => 'Ayrıca şunları yapabilirsiniz';

  @override
  String get reportSuccessDone => 'Tamam';

  @override
  String get reportReduceRecommend => 'Daha az göster';

  @override
  String get reportReduceRecommendDone => 'Daha az gösterilecek';

  @override
  String get reportSuccessContentFallback => 'Bu içerik';

  @override
  String get reportDescription => 'Rapor Açıklaması';

  @override
  String get reportDescriptionPlaceholder =>
      'Detayları açıklayın (İsteğe bağlı)';

  @override
  String get reportReasonPorn => 'Pornografi ve Müstehcenlik';

  @override
  String get reportReasonIllegal => 'Yasa Dışı veya Suç';

  @override
  String get reportReasonSensitive => 'Hassas İçerik';

  @override
  String get reportReasonGambling => 'Kumar veya Şiddet';

  @override
  String get reportReasonMinors => 'Yaş Çocuklara Zarar';

  @override
  String get reportReasonCopyright => 'Telif Hakkı İhlali';

  @override
  String get reportReasonQuality => 'Kalite Sorunu';

  @override
  String get reportReasonNotLike => 'Beğenmedim';

  @override
  String get reportReasonOther => 'Diğer';

  @override
  String get gameUpgrade => 'Yükselt';

  @override
  String get gameUpgradeTitle => 'Seviye Yükseltme';

  @override
  String get gameUpgradeCurrentLevel => 'Mevcut Seviye';

  @override
  String get gameUpgradeTargetLevel => 'Hedef Seviye';

  @override
  String get gameUpgradeHeatThreshold => 'Birikmiş drama tam izlenme sayısı';

  @override
  String get gameUpgradeRequiredCount => 'Aynı IP ve seviye rolleri tüket';

  @override
  String get gameUpgradeFee => 'Yükseltme Ücreti';

  @override
  String get gameUpgradeNextLevelReq => 'Sonraki seviye gereksinimleri';

  @override
  String get gameUpgradeBeforeAfter => 'Yükseltme öncesi ve sonrası';

  @override
  String get gameUpgradeSelectMaterialDesc =>
      'Tüketilecek aynı IP ve seviye rolleri seç';

  @override
  String gameUpgradeMaterialCount(int current, int required) {
    return '$current/$required';
  }

  @override
  String gameUpgradeToLevel(int level, String levelName) {
    return 'Lv$level $levelName seviyesine yükselt';
  }

  @override
  String gameUpgradeSelectMaterialLabel(int current, int required) {
    return 'Malzeme Seç ($current/$required)';
  }

  @override
  String gameUpgradeSelectMaterials(int count) {
    return '$count malzeme seçin';
  }

  @override
  String get gameUpgradeConfirm => 'Yükseltmeyi Onayla';

  @override
  String get gameUpgradeSuccess => 'Yükseltme başarılı';

  @override
  String get gameUpgradeFailed => 'Yükseltme başarısız, lütfen tekrar deneyin';

  @override
  String get gameUpgradeInsufficientMaterials => 'Yetersiz malzeme';

  @override
  String get gameUpgradeNoMaterials =>
      'Tüketilebilir aynı IP ve seviyede aktör bulunamadı';

  @override
  String get creatorDramaStatusMinted => 'Basıldı';

  @override
  String get creatorDramaStatusOffline => 'Kaldırıldı';

  @override
  String get creatorDramaStatusUnavailable => 'Geçici olarak kullanılamıyor';

  @override
  String get creatorMintDramaNft => 'Drama NFT\'si Bas';

  @override
  String get creatorMintConfirmDesc =>
      'Bu dramayı zincir içi NFT olarak basmayı onaylayın. Basıldıktan sonra bu drama STORY madenciliği ödülleri üretecektir.';

  @override
  String get creatorMintFee => 'Basım ücreti';

  @override
  String creatorMintInsufficientUsdc(String currency1, String currency2) {
    return '$currency1 bakiyesi yetersiz. Zincir üzeri yayınlama için en az 1 $currency2 gerekir.';
  }

  @override
  String get creatorMintInvalidDramaId => 'Geçersiz drama kimliği';

  @override
  String get creatorMintInProgress => 'Basım devam ediyor, lütfen bekleyin';

  @override
  String get creatorMintWalletNotReady =>
      'Solana cüzdan adresi hazır değil. Lütfen tekrar giriş yapın';

  @override
  String get creatorMintDigestEmpty =>
      'Yayınlama imza verisi boş. Lütfen biraz sonra tekrar deneyin.';

  @override
  String get creatorMintWalletMismatch =>
      'Basım cüzdanı mevcut cüzdanla eşleşmiyor. Lütfen tekrar giriş yapın';

  @override
  String get creatorMintSuccess => 'Basım başarılı!';

  @override
  String creatorMintDramaOnChain(String name) {
    return '\"$name\" dramasının NFT\'si zincir içine basıldı';
  }

  @override
  String creatorMintNftNumber(String id) {
    return 'NFT Numarası: $id';
  }

  @override
  String get creatorMintTxHash => 'İşlem Hash\'i: ';

  @override
  String get gameSelectActor => 'Dağıtılacak aktörü seçin';

  @override
  String get gameSelectActorDesc =>
      'Boşta olan bir karakter seç ve görevlendir';

  @override
  String get agentV2SchedulePerformance => 'Sahne Al';

  @override
  String get agentV2PerformAllTitle => 'Tek Tıfla Sahne Al';

  @override
  String get agentV2PerformAllDescription =>
      'Ücreti yüksek karakterler boş gösteri yerlerine önce atanır';

  @override
  String get agentV2PerformAllFailed =>
      'Tek dokunuşla gösteri başarısız oldu. Lütfen tekrar deneyin';

  @override
  String get agentV2PerformAllSuccess => 'Tek dokunuşla gösteri başarılı';

  @override
  String agentV2PerformAllDepletedResult(int successCount, int depletedCount) {
    return '$successCount oyuncu başarıyla sahne aldı, $depletedCount oyuncu tükenen enerjisi nedeniyle sahne alamadı';
  }

  @override
  String get agentV2RestAllSuccess => 'Tek dokunuşla dinlendirme başarılı';

  @override
  String agentV2PerformAllCount(int count) {
    return '$count karakter';
  }

  @override
  String get agentV2TodoTitle => 'Yapılacaklar';

  @override
  String agentV2TodoVacancies(int count) {
    return '$count boş gösteri yeri var';
  }

  @override
  String agentV2TodoStaminaDepleted(String name) {
    return '$name 0 enerjiye sahip ve çalışmayı durdurdu';
  }

  @override
  String get agentV2TodoPerform => 'Sahne al';

  @override
  String get agentV2TodoRefill => 'Yenile';

  @override
  String get agentV2TodoHealthy => 'Gösteriler normal · Dayanıklılık yeterli';

  @override
  String get agentV2CandidateActorsTitle => 'Aday roller';

  @override
  String get agentV2CandidateActorsDescription =>
      'Dinlenen roller saatte 1 dayanıklılık puanı yeniler';

  @override
  String get agentV2UpgradeableActorsTitle => 'Rolleri yükselt';

  @override
  String get agentV2UpgradeableActorsEmpty => 'Yükseltilebilecek rol yok';

  @override
  String get agentV2NoActors => 'Rol yok';

  @override
  String get agentV2UpgradeNow => 'Şimdi yükselt';

  @override
  String get agentV2UpgradeCompletion => 'Tam izlenme';

  @override
  String get agentV2UpgradeMaterials => 'Roller';

  @override
  String agentV2UpgradeRequirementsTitle(String name) {
    return '$name rolünü yükselt';
  }

  @override
  String agentV2UpgradeCompletionRemaining(int count) {
    return '$count tam izlenme daha gerekli';
  }

  @override
  String get agentV2UpgradeCompletionHint =>
      'Bu karakterin yer aldığı dizileri izleyin veya tam izlenmeleri artırmak için yeni bir dizi oluşturun';

  @override
  String get agentV2UpgradeWatchDramas => 'Dizilerini izle';

  @override
  String get agentV2UpgradeCreateDrama => 'Dizi oluştur';

  @override
  String agentV2UpgradeMaterialsRemaining(int count) {
    return 'Aynı IP ve seviyede $count rol daha gerekli';
  }

  @override
  String agentV2UpgradeMaterialsHint(String name) {
    return 'Karakter profilinden daha fazla \"$name\" karakteri imzalayın';
  }

  @override
  String get agentV2UpgradeGetActors => 'Rol edin';

  @override
  String agentV2UpgradeActorsSyncing(int count) {
    return '$count yeni karakter eşitleniyor; yükseltme koşulları güncellendi';
  }

  @override
  String get agentV2UpgradeConfirmSelectMaterials =>
      'Tüketilecek aynı IP ve seviyedeki karakterleri seçin';

  @override
  String get agentV2UpgradeConfirmSalaryLabel => 'Ücret';

  @override
  String get agentV2SalaryDetailTitle => 'Karakter ücret ayrıntıları';

  @override
  String get agentV2SalaryHourly => 'Saatlik ücret';

  @override
  String get agentV2SalaryUnit => 'STORY / saat';

  @override
  String get agentV2SalaryFormula =>
      'Karakter ücreti = IP ücreti × Ücret katsayısı × CP katsayısı × Trust2';

  @override
  String get agentV2SalaryFormulaLv1 =>
      'Lv.1 karakter ücreti = Fiyat katsayısı × Popülerlik katsayısı';

  @override
  String agentV2SalaryFormulaLevel(int level) {
    return 'Lv.$level ücret = Lv.1 ücret × Ücret katsayısı';
  }

  @override
  String get agentV2SalaryLv1Pay => 'Lv.1 ücret';

  @override
  String get agentV2SalaryCoefficient => 'Ücret katsayısı';

  @override
  String agentV2SalaryCoefficientWithLevel(int level, String roleName) {
    return 'Ücret katsayısı (Lv.$level $roleName)';
  }

  @override
  String get agentV2SalaryCpCoefficient => 'CP katsayısı';

  @override
  String get agentV2PerformanceConfirmDescription =>
      'Bu karakter, performans sırasında otomatik olarak ücret kazanır. Her saat performans 1 puan dayanıklılık harcar; dayanıklılık bitince kazanç durur.';

  @override
  String get agentV2PerformanceConfirmTitle => 'Performans ayarla';

  @override
  String get agentV2PerformanceZeroFeePrefix => 'Bu karakterin IP\'si şu anda ';

  @override
  String get agentV2PerformanceZeroFeeHighlight => 'ücret 0';

  @override
  String get agentV2PerformanceZeroFeeSuffix =>
      ', bu yüzden gösteri gelir getirmeyecek. Ayrıca gösteri sırasında her saat 1 enerji puanı harcanır. Yine de devam etmek istiyor musun?';

  @override
  String get agentV2PerformanceScheduledSuccess => 'Gösteri planlandı';

  @override
  String get agentV2PerformanceSlotsFull =>
      'Gösteri alanları dolu (en fazla 5)';

  @override
  String get gameDeployStaminaDepleted =>
      'Dayanıklılık tükendi. Gösteriden önce doldurun';

  @override
  String get agentMoreRules => 'Kurallar';

  @override
  String get agentMoreSalaryAndPool => 'Ücret ve ödül havuzu';

  @override
  String get agentV2WeeklySalaryTitle => 'Seviye Atla · Sahne Al · Ücret Kazan';

  @override
  String get agentV2WeeklySalaryLabel => 'Bu haftaki ücret';

  @override
  String get gameDeployConfirmDesc =>
      'Bu karakter otomatik olarak staking madenciliğine katılır ve sizin için sürekli STORY getirisi üretir. Not: Her saat başında 1 dayanıklılık puanı harcanır. Dayanıklılık tükendiğinde getiri üretimi durur.';

  @override
  String get gameRecallConfirm => 'Geri çağırmayı onayla';

  @override
  String get gameRecallDesc =>
      'Bu karakteri geri çağırmak drama üretim ödüllerini duraklatacak ancak mevcut dayanıklılığı etkilemeyecektir.';

  @override
  String get actorStatCompletionTitle => 'Tam izlenme';

  @override
  String get actorStatCompletionDesc =>
      'Bu karakterin rol aldığı tüm dramlardaki toplam tam izlenme sayısı';

  @override
  String get actorStatHeatTitle => 'Popülerlik';

  @override
  String get actorStatHeatDesc =>
      'Bu karakter IP\'sinin yer aldığı tüm kısa dizilerin son 30 günlük toplam popülerliği';

  @override
  String get actorStatIpPowerTitle => 'IP ücreti';

  @override
  String get actorStatIpPowerDesc =>
      'IP ücreti = Fiyat katsayısı × Popülerlik katsayısı × Trust1';

  @override
  String get dramaFavoriteLabel => 'Favori';

  @override
  String get dramaRatingLabel => 'Puan';

  @override
  String get dramaUnnamed => 'İsimsiz';

  @override
  String get videoNotReady =>
      'Video hazır değil, lütfen daha sonra tekrar deneyin';

  @override
  String get inviteDirectSubordinates => 'Davet edilen kullanıcılar';

  @override
  String inviteTotalCount(int count) {
    return 'Toplam: $count kullanıcı';
  }

  @override
  String get inviteTotalLabel => 'Toplam kullanıcı';

  @override
  String get inviteActiveLabel => 'Aktif kullanıcılar';

  @override
  String get invitePendingLabel => 'Aktivasyon bekliyor';

  @override
  String get inviteEmpty => 'Henüz ast kullanıcı yok';

  @override
  String inviteRegisteredAt(String date) {
    return '$date tarihinde kayıt oldu';
  }

  @override
  String get gameUpgradeMaxLevel => 'Maksimum seviyeye ulaşıldı';

  @override
  String get listNoMoreData => 'Daha fazla veri yok';

  @override
  String get iapSheetTitle => 'Puan satın al';

  @override
  String get iapSheetSubtitle =>
      'Puanlar; karakter sözleşmesi gibi uygulama içi hizmetlerde kullanılır';

  @override
  String get iapBalance => 'Bakiye';

  @override
  String get iapConfirmPurchase => 'Satın almayı onayla';

  @override
  String get iapPurchaseSuccess => 'Satın alma başarılı';

  @override
  String get iapPurchaseFailed =>
      'Satın alma başarısız oldu, lütfen tekrar deneyin';

  @override
  String get iapPurchaseFailedTitle => 'Satın alma başarısız';

  @override
  String get iapCrediting => 'Ödeme işleniyor, lütfen bekleyin';

  @override
  String get iapNoProducts => 'Mevcut ürün yok';

  @override
  String get iapSuccessConfirm => 'Tamam';

  @override
  String iapGainedPoints(String value) {
    return '+$value';
  }

  @override
  String iapPointsCount(int count) {
    return '$count puan';
  }

  @override
  String get gameBatchRefillTransactionTooLarge =>
      'Toplu güç yenileme işlemi çok büyük. Oyuncu sayısını azaltıp tekrar deneyin.';

  @override
  String get agentV2RefillTitle => 'Dayanıklılık yenile';

  @override
  String get agentV2RefillCost => 'Maliyet';

  @override
  String get agentV2RefillActorButton => 'Bu karakter';

  @override
  String get agentV2RefillAllActors => 'Sahnedeki tüm karakterleri yenile';

  @override
  String agentV2RefillActorCount(int count) {
    return '$count karakter';
  }

  @override
  String get agentV2RefillAllButton => 'Tümünü yenile';

  @override
  String get agentV2RefillOr => 'veya';

  @override
  String get agentV2RestAll => 'Tümünü dinlendir';

  @override
  String agentV2RestActorCount(int count) {
    return '$count karakter';
  }

  @override
  String get salaryPoolRateUnit => 'STORY / saat';

  @override
  String get salaryPoolDecayInfo => 'Haftalık zayıflama katsayısı ×0.99572';

  @override
  String get salaryPoolStakeLabel => 'Performans Ödül havuzu (%75)';

  @override
  String get salaryPoolInviteLabel => 'Davet Ödül havuzu (%25)';

  @override
  String get salaryPoolRule1Title =>
      'Ağ genelindeki nominal üretim ≤ haftalık üst sınır:';

  @override
  String get salaryPoolRule2Title =>
      'Ağ genelindeki nominal üretim > haftalık üst sınır:';

  @override
  String get salaryPoolRule2Body =>
      'Kullanıcının eline geçen tutar = kullanıcının nominal üretimi × (haftalık üst sınır ÷ ağın toplam nominal üretimi)';

  @override
  String get agentV3WeeklySalary => 'Haftalık ücret';

  @override
  String get agentV3PerformAll => 'Tümünü sahnele';

  @override
  String get agentV3RestAll => 'Tümünü dinlendir';

  @override
  String get agentV3RestAllDescription =>
      'Enerji tüketimini ve kazancı durdurmak için sahnedeki tüm karakterleri geri çağır';

  @override
  String get agentV3RefillAll => 'Tümünü yenile';

  @override
  String get agentV3RefillAllDescription =>
      'Sahnedeki karakterlerin enerjisini tamamen doldur';

  @override
  String get agentV3RefillCost => 'Harcar';

  @override
  String get agentV3RefillNoActors => 'Enerji yenilemesi gereken karakter yok';

  @override
  String get agentV3SignActor => 'Karakter imzala';

  @override
  String get agentV3Todo => 'Yapılacaklar';

  @override
  String get agentV3Upgrade => 'Yükselt';

  @override
  String agentV3UpgradeMaterialHint(int count) {
    return 'Yükseltme, aynı IP ve seviyeye sahip $count karakter tüketir';
  }

  @override
  String get agentV3Waiting => 'Beklemede';

  @override
  String get agentV3WaitingActorsTitle => 'Bekleyen Karakterler';

  @override
  String get agentV3WaitingActorsDescription =>
      'Dinlenen karakterler saatte 1 dayanıklılık yeniler';

  @override
  String get agentV3Recycle => 'Geri dönüştür';

  @override
  String get agentV3RecycleActorsTitle => 'Karakterleri Geri Dönüştür';

  @override
  String get agentV3RecyclePerforming => 'Sahnede';

  @override
  String get agentV3RecycleReceive => 'Şunları alacaksınız';

  @override
  String get agentV3RecyclePermanentWarning =>
      'Karakter kalıcı olarak yok edilecek ve geri alınamayacak';

  @override
  String get agentV3RecycleConfirm => 'Yok etmeyi onayla';

  @override
  String get agentV3RecycleConfirmAgain => 'Yok etmek için tekrar dokun';

  @override
  String get agentV3RecycleSubmitted => 'Karakter başarıyla geri dönüştürüldü';

  @override
  String get agentV3RecycleEstimateUnavailable =>
      'Geri dönüşüm tahmini alınamıyor. Lütfen tekrar deneyin';

  @override
  String get agentV3EnergyPack => 'Enerji paketi';

  @override
  String get agentV3EnergyPackDescription =>
      'Karakter enerjisini tamamen yeniler; karakter seviyesine göre tüketilir.';

  @override
  String get agentV3TrainingManual => 'Eğitim kılavuzu';

  @override
  String get agentV3TrainingManualDescription =>
      'Karakter yükseltme malzemesidir; yükseltme sırasında karakter seviyesine göre tüketilir.';

  @override
  String get agentV3PurchaseButton => 'Satın al';

  @override
  String agentV3PurchaseWalletBalance(String balance, String currency) {
    return 'Bakiye $balance $currency';
  }

  @override
  String agentV3PurchaseTitle(String item) {
    return '$item satın al';
  }

  @override
  String get agentV3PurchaseUnitPrice => 'Birim fiyat';

  @override
  String get agentV3PurchaseQuantity => 'Adet';

  @override
  String get agentV3PurchaseTotal => 'Toplam';

  @override
  String get agentV3PurchaseConfirm => 'Ödemeyi onayla';

  @override
  String get agentV3PurchaseUnavailable =>
      'Bu ortamda öğe satın alma kullanılamıyor';

  @override
  String get agentV3PurchaseConfigUnavailable =>
      'Öğe fiyatı kullanılamıyor. Lütfen daha sonra tekrar deneyin';

  @override
  String get agentV3PurchaseSubmitted =>
      'Satın alma başarılı. Eşya çantasına eklendi (Menajer sayfası)';

  @override
  String get agentV3PurchaseCreditPending =>
      'Enerji paketleri hâlâ aktarılıyor. Lütfen kısa süre sonra tekrar deneyin';

  @override
  String get agentV3PurchaseCrediting => 'Zincir taranıyor ve aktarılıyor';

  @override
  String agentV3PurchaseBalance(String count) {
    return 'Mevcut: $count';
  }

  @override
  String get agentV3RefillTitle => 'Enerjiyi tamamen doldur';

  @override
  String agentV3RefillLevelCost(String level) {
    return 'Sv.$level tüketir';
  }

  @override
  String get agentV3RefillAvailable => 'Kullanılabilir';

  @override
  String get agentV3RefillUse => 'Kullan';

  @override
  String get agentV3RefillSuccess => 'Enerji tamamen dolduruldu';

  @override
  String agentV3RefillAllSuccess(int actorCount, String packCount) {
    return '$actorCount karakterin enerjisi yenilendi ($packCount enerji paketi kullanıldı)';
  }

  @override
  String get agentV3RefillConfigUnavailable =>
      'Enerji paketi tüketim ayarı kullanılamıyor';

  @override
  String get agentV3RefillInsufficient => 'Yeterli enerji paketi yok';
}
