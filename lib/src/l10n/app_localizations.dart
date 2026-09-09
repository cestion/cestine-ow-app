import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('ja'),
    Locale('ko'),
    Locale('tr'),
    Locale('vi'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'StoryFun'**
  String get appName;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get commonNoData;

  /// No description provided for @commonNo.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get commonNo;

  /// No description provided for @commonYes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get commonYes;

  /// No description provided for @publishDrama.
  ///
  /// In zh, this message translates to:
  /// **'发布短剧'**
  String get publishDrama;

  /// No description provided for @publishVideo.
  ///
  /// In zh, this message translates to:
  /// **'发布视频'**
  String get publishVideo;

  /// No description provided for @publishVideoUploadTitle.
  ///
  /// In zh, this message translates to:
  /// **'上传视频文件'**
  String get publishVideoUploadTitle;

  /// No description provided for @publishVideoFileHint.
  ///
  /// In zh, this message translates to:
  /// **'支持 mp4、flv、wmv、mkv、avi、mov、webm 等格式，文件不超过 2GB'**
  String get publishVideoFileHint;

  /// No description provided for @publishVideoChooseFile.
  ///
  /// In zh, this message translates to:
  /// **'选择文件'**
  String get publishVideoChooseFile;

  /// No description provided for @publishVideoChangeFile.
  ///
  /// In zh, this message translates to:
  /// **'更换文件'**
  String get publishVideoChangeFile;

  /// No description provided for @publishVideoChooseSource.
  ///
  /// In zh, this message translates to:
  /// **'选择视频来源'**
  String get publishVideoChooseSource;

  /// No description provided for @publishVideoChooseFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册选择'**
  String get publishVideoChooseFromGallery;

  /// No description provided for @publishVideoChooseFromFiles.
  ///
  /// In zh, this message translates to:
  /// **'从文件选择'**
  String get publishVideoChooseFromFiles;

  /// No description provided for @publishVideoPreparing.
  ///
  /// In zh, this message translates to:
  /// **'正在准备视频…'**
  String get publishVideoPreparing;

  /// No description provided for @publishVideoCoverTitle.
  ///
  /// In zh, this message translates to:
  /// **'视频封面'**
  String get publishVideoCoverTitle;

  /// No description provided for @publishVideoChangeCover.
  ///
  /// In zh, this message translates to:
  /// **'更换封面'**
  String get publishVideoChangeCover;

  /// No description provided for @publishVideoCoverHint.
  ///
  /// In zh, this message translates to:
  /// **'支持 JPG/PNG，不超过 5MB'**
  String get publishVideoCoverHint;

  /// No description provided for @publishVideoDescriptionLabel.
  ///
  /// In zh, this message translates to:
  /// **'描述'**
  String get publishVideoDescriptionLabel;

  /// No description provided for @publishVideoRequired.
  ///
  /// In zh, this message translates to:
  /// **'（必填）'**
  String get publishVideoRequired;

  /// No description provided for @publishVideoDescriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'添加作品描述（最多200字）'**
  String get publishVideoDescriptionHint;

  /// No description provided for @publishVideoSaveDraft.
  ///
  /// In zh, this message translates to:
  /// **'保存草稿'**
  String get publishVideoSaveDraft;

  /// No description provided for @publishVideoDraftEditModeNotSupported.
  ///
  /// In zh, this message translates to:
  /// **'编辑模式下不能保存草稿'**
  String get publishVideoDraftEditModeNotSupported;

  /// No description provided for @publishVideoDraftNothingToSave.
  ///
  /// In zh, this message translates to:
  /// **'没有可保存的内容'**
  String get publishVideoDraftNothingToSave;

  /// No description provided for @publishVideoNext.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get publishVideoNext;

  /// No description provided for @publishVideoCoverCropTitle.
  ///
  /// In zh, this message translates to:
  /// **'裁剪视频封面'**
  String get publishVideoCoverCropTitle;

  /// No description provided for @publishVideoVideoTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'该视频超过 2GB，暂不支持上传，请选择较小的视频'**
  String get publishVideoVideoTooLarge;

  /// No description provided for @publishVideoVideoPickFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择视频失败，请重试'**
  String get publishVideoVideoPickFailed;

  /// No description provided for @publishVideoInsufficientStorage.
  ///
  /// In zh, this message translates to:
  /// **'设备剩余空间不足，无法准备该视频'**
  String get publishVideoInsufficientStorage;

  /// No description provided for @publishVideoPermissionDenied.
  ///
  /// In zh, this message translates to:
  /// **'无法访问该视频，请检查相册或文件权限'**
  String get publishVideoPermissionDenied;

  /// No description provided for @publishVideoSourceUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'该视频暂时无法读取，请确认云端文件已下载后重试'**
  String get publishVideoSourceUnavailable;

  /// No description provided for @publishVideoPrepareFailed.
  ///
  /// In zh, this message translates to:
  /// **'视频准备失败，请重试或从文件选择'**
  String get publishVideoPrepareFailed;

  /// No description provided for @publishVideoMetadataUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'无法读取视频信息，请选择其他文件'**
  String get publishVideoMetadataUnavailable;

  /// No description provided for @publishVideoCoverTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'封面图片不能超过 5MB'**
  String get publishVideoCoverTooLarge;

  /// No description provided for @publishVideoCoverUnsupportedFormat.
  ///
  /// In zh, this message translates to:
  /// **'仅支持 JPG/PNG 格式的图片'**
  String get publishVideoCoverUnsupportedFormat;

  /// No description provided for @publishVideoCoverPickFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择封面失败，请重试'**
  String get publishVideoCoverPickFailed;

  /// No description provided for @publishVideoUploadSessionFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建上传会话失败，请重试'**
  String get publishVideoUploadSessionFailed;

  /// No description provided for @publishVideoPublishedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'视频发布成功'**
  String get publishVideoPublishedSuccess;

  /// No description provided for @publishVideoUpdatedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'视频修改成功'**
  String get publishVideoUpdatedSuccess;

  /// No description provided for @publishActorIp.
  ///
  /// In zh, this message translates to:
  /// **'发布IP'**
  String get publishActorIp;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get commonConfirm;

  /// No description provided for @commonOk.
  ///
  /// In zh, this message translates to:
  /// **'我知道了'**
  String get commonOk;

  /// No description provided for @commonNotice.
  ///
  /// In zh, this message translates to:
  /// **'提示'**
  String get commonNotice;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @publicProfileLikedEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无点赞的短剧'**
  String get publicProfileLikedEmpty;

  /// No description provided for @profileTabDramas.
  ///
  /// In zh, this message translates to:
  /// **'短剧'**
  String get profileTabDramas;

  /// No description provided for @profileTabWorks.
  ///
  /// In zh, this message translates to:
  /// **'作品'**
  String get profileTabWorks;

  /// No description provided for @profileTabActorIp.
  ///
  /// In zh, this message translates to:
  /// **'角色IP'**
  String get profileTabActorIp;

  /// No description provided for @dramaUnlockConfirmLabel.
  ///
  /// In zh, this message translates to:
  /// **'{price} {currency} 解锁'**
  String dramaUnlockConfirmLabel(String price, String currency);

  /// No description provided for @dramaAllEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 集'**
  String dramaAllEpisodes(int count);

  /// No description provided for @dramaAllEpisodesFull.
  ///
  /// In zh, this message translates to:
  /// **'全{count}集'**
  String dramaAllEpisodesFull(Object count);

  /// No description provided for @dramaLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载精选短剧中...'**
  String get dramaLoading;

  /// No description provided for @dramaEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无短剧'**
  String get dramaEmpty;

  /// No description provided for @dramaRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get dramaRefresh;

  /// No description provided for @navTheater.
  ///
  /// In zh, this message translates to:
  /// **'剧场'**
  String get navTheater;

  /// No description provided for @navHome.
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get navHome;

  /// No description provided for @theaterTabShortDrama.
  ///
  /// In zh, this message translates to:
  /// **'短剧'**
  String get theaterTabShortDrama;

  /// No description provided for @theaterTabRecommend.
  ///
  /// In zh, this message translates to:
  /// **'推荐'**
  String get theaterTabRecommend;

  /// No description provided for @playerWatchFullDrama.
  ///
  /// In zh, this message translates to:
  /// **'观看完整短剧'**
  String get playerWatchFullDrama;

  /// No description provided for @playerStoryPerHourUnit.
  ///
  /// In zh, this message translates to:
  /// **'STORY/h'**
  String get playerStoryPerHourUnit;

  /// No description provided for @navNft.
  ///
  /// In zh, this message translates to:
  /// **'IP市场'**
  String get navNft;

  /// No description provided for @navNftIp.
  ///
  /// In zh, this message translates to:
  /// **'角色IP'**
  String get navNftIp;

  /// No description provided for @watchFullDramaEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'观看完整短剧 · 全{count}集'**
  String watchFullDramaEpisodes(int count);

  /// No description provided for @navCreate.
  ///
  /// In zh, this message translates to:
  /// **'创作'**
  String get navCreate;

  /// No description provided for @navProfile.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get navProfile;

  /// No description provided for @navMy.
  ///
  /// In zh, this message translates to:
  /// **'经纪人'**
  String get navMy;

  /// No description provided for @aboutTitle.
  ///
  /// In zh, this message translates to:
  /// **'关于我们'**
  String get aboutTitle;

  /// No description provided for @aboutVision.
  ///
  /// In zh, this message translates to:
  /// **'AI · Web3 · 协议'**
  String get aboutVision;

  /// No description provided for @aboutVisionDesc.
  ///
  /// In zh, this message translates to:
  /// **'三种力量驱动，将叙事从被动体验转化为主动生成'**
  String get aboutVisionDesc;

  /// No description provided for @aboutAiDesc.
  ///
  /// In zh, this message translates to:
  /// **'你的想法，自动变成故事'**
  String get aboutAiDesc;

  /// No description provided for @aboutWeb3Desc.
  ///
  /// In zh, this message translates to:
  /// **'你的创作，永远属于你'**
  String get aboutWeb3Desc;

  /// No description provided for @aboutProtocolDesc.
  ///
  /// In zh, this message translates to:
  /// **'你的故事，可以无限延续'**
  String get aboutProtocolDesc;

  /// No description provided for @aboutIdentityTitle.
  ///
  /// In zh, this message translates to:
  /// **'你的叙事身份'**
  String get aboutIdentityTitle;

  /// No description provided for @aboutIdentityDesc.
  ///
  /// In zh, this message translates to:
  /// **'你本身，就是一个正在展开的叙事宇宙'**
  String get aboutIdentityDesc;

  /// No description provided for @aboutIdentityCreator.
  ///
  /// In zh, this message translates to:
  /// **'创造者'**
  String get aboutIdentityCreator;

  /// No description provided for @aboutIdentityCreatorDesc.
  ///
  /// In zh, this message translates to:
  /// **'主动书写自身的叙事'**
  String get aboutIdentityCreatorDesc;

  /// No description provided for @aboutIdentityWitness.
  ///
  /// In zh, this message translates to:
  /// **'见证者'**
  String get aboutIdentityWitness;

  /// No description provided for @aboutIdentityWitnessDesc.
  ///
  /// In zh, this message translates to:
  /// **'参与并验证他人叙事'**
  String get aboutIdentityWitnessDesc;

  /// No description provided for @aboutIdentityCoCreator.
  ///
  /// In zh, this message translates to:
  /// **'共创者'**
  String get aboutIdentityCoCreator;

  /// No description provided for @aboutIdentityCoCreatorDesc.
  ///
  /// In zh, this message translates to:
  /// **'进入叙事结构并进行改写'**
  String get aboutIdentityCoCreatorDesc;

  /// No description provided for @aboutIdentitySpreader.
  ///
  /// In zh, this message translates to:
  /// **'传播者'**
  String get aboutIdentitySpreader;

  /// No description provided for @aboutIdentitySpreaderDesc.
  ///
  /// In zh, this message translates to:
  /// **'传播你值得的叙事'**
  String get aboutIdentitySpreaderDesc;

  /// No description provided for @aboutTokenomicsTitle.
  ///
  /// In zh, this message translates to:
  /// **'STORY：叙事权通证'**
  String get aboutTokenomicsTitle;

  /// No description provided for @aboutTokenomicsDesc.
  ///
  /// In zh, this message translates to:
  /// **'成为 AI 短剧的联合出品人，重构影视行业的利益分配格局'**
  String get aboutTokenomicsDesc;

  /// No description provided for @aboutTokenomicsGov.
  ///
  /// In zh, this message translates to:
  /// **'治理权'**
  String get aboutTokenomicsGov;

  /// No description provided for @aboutTokenomicsGovDesc.
  ///
  /// In zh, this message translates to:
  /// **'投票决定下一部 AI 短剧的题材与走向'**
  String get aboutTokenomicsGovDesc;

  /// No description provided for @aboutTokenomicsRevenue.
  ///
  /// In zh, this message translates to:
  /// **'收益权'**
  String get aboutTokenomicsRevenue;

  /// No description provided for @aboutTokenomicsRevenueDesc.
  ///
  /// In zh, this message translates to:
  /// **'分享平台订阅、版权授权及周边销售红利'**
  String get aboutTokenomicsRevenueDesc;

  /// No description provided for @aboutTokenomicsAccess.
  ///
  /// In zh, this message translates to:
  /// **'访问权'**
  String get aboutTokenomicsAccess;

  /// No description provided for @aboutTokenomicsAccessDesc.
  ///
  /// In zh, this message translates to:
  /// **'抢先观看最新剧集，解锁独家内容'**
  String get aboutTokenomicsAccessDesc;

  /// No description provided for @aboutStakingTitle.
  ///
  /// In zh, this message translates to:
  /// **'质押分润'**
  String get aboutStakingTitle;

  /// No description provided for @aboutStakingDesc.
  ///
  /// In zh, this message translates to:
  /// **'短剧 NFT · 角色 NFT · STORY → 质押即享分润'**
  String get aboutStakingDesc;

  /// No description provided for @aboutStakingDrama.
  ///
  /// In zh, this message translates to:
  /// **'短剧 NFT 质押'**
  String get aboutStakingDrama;

  /// No description provided for @aboutStakingDramaDesc.
  ///
  /// In zh, this message translates to:
  /// **'短剧创作者 · 获得分润'**
  String get aboutStakingDramaDesc;

  /// No description provided for @aboutStakingActor.
  ///
  /// In zh, this message translates to:
  /// **'角色 NFT 质押'**
  String get aboutStakingActor;

  /// No description provided for @aboutStakingActorDesc.
  ///
  /// In zh, this message translates to:
  /// **'角色参演短剧 · 获得分润'**
  String get aboutStakingActorDesc;

  /// No description provided for @aboutStakingStory.
  ///
  /// In zh, this message translates to:
  /// **'STORY 质押'**
  String get aboutStakingStory;

  /// No description provided for @aboutStakingStoryDesc.
  ///
  /// In zh, this message translates to:
  /// **'质押到短剧 · 收入分润'**
  String get aboutStakingStoryDesc;

  /// No description provided for @aboutHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'创造属于你的故事'**
  String get aboutHeroTitle;

  /// No description provided for @aboutHeroDesc.
  ///
  /// In zh, this message translates to:
  /// **'你的人生不是被体验的剧本，而是正在被你书写的叙事'**
  String get aboutHeroDesc;

  /// No description provided for @loginTitle.
  ///
  /// In zh, this message translates to:
  /// **'邮箱登录'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'通过 Privy 邮箱 OTP 登录，自动创建 Solana 嵌入式钱包。'**
  String get loginSubtitle;

  /// No description provided for @loginPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'输入邮箱地址'**
  String get loginPlaceholder;

  /// No description provided for @loginEmailHintFormat.
  ///
  /// In zh, this message translates to:
  /// **'请输入邮箱'**
  String get loginEmailHintFormat;

  /// No description provided for @loginVerificationFailed.
  ///
  /// In zh, this message translates to:
  /// **'验证码错误'**
  String get loginVerificationFailed;

  /// No description provided for @loginNeedCodeFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先获取验证码'**
  String get loginNeedCodeFirst;

  /// No description provided for @loginCreateWalletFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建钱包失败'**
  String get loginCreateWalletFailed;

  /// No description provided for @loginGetTokenFailed.
  ///
  /// In zh, this message translates to:
  /// **'获取登录凭证失败'**
  String get loginGetTokenFailed;

  /// No description provided for @loginPrivyUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'登录服务暂不可用，请重启应用后再试'**
  String get loginPrivyUnavailable;

  /// No description provided for @loginSendCodeFailed.
  ///
  /// In zh, this message translates to:
  /// **'验证码发送失败，请稍后重试'**
  String get loginSendCodeFailed;

  /// No description provided for @loginTooManyRequests.
  ///
  /// In zh, this message translates to:
  /// **'请求过于频繁，请稍后再试'**
  String get loginTooManyRequests;

  /// No description provided for @loginVerificationSuccessful.
  ///
  /// In zh, this message translates to:
  /// **'验证成功'**
  String get loginVerificationSuccessful;

  /// No description provided for @loginSendCode.
  ///
  /// In zh, this message translates to:
  /// **'获取验证码'**
  String get loginSendCode;

  /// No description provided for @loginSendingCode.
  ///
  /// In zh, this message translates to:
  /// **'发送中...'**
  String get loginSendingCode;

  /// No description provided for @loginCodePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'输入 6 位验证码'**
  String get loginCodePlaceholder;

  /// No description provided for @loginSubmit.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get loginSubmit;

  /// No description provided for @loginSubmitting.
  ///
  /// In zh, this message translates to:
  /// **'登录中...'**
  String get loginSubmitting;

  /// No description provided for @loginEmailRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入邮箱'**
  String get loginEmailRequired;

  /// No description provided for @loginCodeRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入验证码'**
  String get loginCodeRequired;

  /// No description provided for @loginSuccess.
  ///
  /// In zh, this message translates to:
  /// **'登录成功'**
  String get loginSuccess;

  /// No description provided for @loginErrorPrefix.
  ///
  /// In zh, this message translates to:
  /// **'登录失败：'**
  String get loginErrorPrefix;

  /// No description provided for @loginCodeSent.
  ///
  /// In zh, this message translates to:
  /// **'验证码已发送至 {email}'**
  String loginCodeSent(String email);

  /// No description provided for @loginEmailLabel.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get loginEmailLabel;

  /// No description provided for @loginCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'验证码'**
  String get loginCodeLabel;

  /// No description provided for @loginVerifying.
  ///
  /// In zh, this message translates to:
  /// **'验证中，请稍候...'**
  String get loginVerifying;

  /// No description provided for @loginVerifyAndSubmit.
  ///
  /// In zh, this message translates to:
  /// **'验证并登录'**
  String get loginVerifyAndSubmit;

  /// No description provided for @loginChangeEmail.
  ///
  /// In zh, this message translates to:
  /// **'换个邮箱'**
  String get loginChangeEmail;

  /// No description provided for @loginNotNow.
  ///
  /// In zh, this message translates to:
  /// **'暂不登录'**
  String get loginNotNow;

  /// No description provided for @loginInvalidEmail.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效邮箱'**
  String get loginInvalidEmail;

  /// No description provided for @profileTitle.
  ///
  /// In zh, this message translates to:
  /// **'经纪人'**
  String get profileTitle;

  /// No description provided for @profileNotLoggedIn.
  ///
  /// In zh, this message translates to:
  /// **'未登录'**
  String get profileNotLoggedIn;

  /// No description provided for @profileClickLogin.
  ///
  /// In zh, this message translates to:
  /// **'登录 / 注册'**
  String get profileClickLogin;

  /// No description provided for @profileMyWallet.
  ///
  /// In zh, this message translates to:
  /// **'我的钱包'**
  String get profileMyWallet;

  /// No description provided for @profileWallet.
  ///
  /// In zh, this message translates to:
  /// **'钱包'**
  String get profileWallet;

  /// No description provided for @profileTradeStory.
  ///
  /// In zh, this message translates to:
  /// **'交易 STORY'**
  String get profileTradeStory;

  /// No description provided for @profileWalletCreating.
  ///
  /// In zh, this message translates to:
  /// **'创建中...'**
  String get profileWalletCreating;

  /// No description provided for @walletNetworkSolana.
  ///
  /// In zh, this message translates to:
  /// **'Solana'**
  String get walletNetworkSolana;

  /// No description provided for @walletNetworkEvm.
  ///
  /// In zh, this message translates to:
  /// **'EVM'**
  String get walletNetworkEvm;

  /// No description provided for @profileEarnings.
  ///
  /// In zh, this message translates to:
  /// **'收益'**
  String get profileEarnings;

  /// No description provided for @profileMyNft.
  ///
  /// In zh, this message translates to:
  /// **'我的 NFT'**
  String get profileMyNft;

  /// No description provided for @profileMyFavorites.
  ///
  /// In zh, this message translates to:
  /// **'我的收藏'**
  String get profileMyFavorites;

  /// No description provided for @profileWatchHistory.
  ///
  /// In zh, this message translates to:
  /// **'观看历史'**
  String get profileWatchHistory;

  /// No description provided for @profileCreatorCatalog.
  ///
  /// In zh, this message translates to:
  /// **'创作者目录'**
  String get profileCreatorCatalog;

  /// No description provided for @profileIdentityAuth.
  ///
  /// In zh, this message translates to:
  /// **'实名认证'**
  String get profileIdentityAuth;

  /// No description provided for @profileAccountSecurity.
  ///
  /// In zh, this message translates to:
  /// **'账号安全'**
  String get profileAccountSecurity;

  /// No description provided for @profileLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get profileLanguage;

  /// No description provided for @profileAboutUs.
  ///
  /// In zh, this message translates to:
  /// **'关于我们'**
  String get profileAboutUs;

  /// No description provided for @profileHelpFeedback.
  ///
  /// In zh, this message translates to:
  /// **'帮助与反馈'**
  String get profileHelpFeedback;

  /// No description provided for @profileLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get profileLogout;

  /// No description provided for @profileLogoutConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认要退出登录吗？'**
  String get profileLogoutConfirm;

  /// No description provided for @profileLogoutSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已退出登录'**
  String get profileLogoutSuccess;

  /// No description provided for @mainPressBackAgainToExit.
  ///
  /// In zh, this message translates to:
  /// **'再按一次退出'**
  String get mainPressBackAgainToExit;

  /// No description provided for @languageSelectTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get languageSelectTitle;

  /// No description provided for @languageChinese.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// No description provided for @languageEnglish.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @searchTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索短剧、作品、角色、用户...'**
  String get searchHint;

  /// No description provided for @searchEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无相关内容'**
  String get searchEmpty;

  /// No description provided for @searchNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无相关内容'**
  String get searchNoData;

  /// No description provided for @searchPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'搜索短剧、作品、角色、用户...'**
  String get searchPlaceholder;

  /// No description provided for @theaterSearchPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'搜索短剧、作品、角色、用户...'**
  String get theaterSearchPlaceholder;

  /// No description provided for @searchHistory.
  ///
  /// In zh, this message translates to:
  /// **'最近搜索'**
  String get searchHistory;

  /// No description provided for @searchClear.
  ///
  /// In zh, this message translates to:
  /// **'清空历史'**
  String get searchClear;

  /// No description provided for @searchAction.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get searchAction;

  /// No description provided for @searchHistoryCleared.
  ///
  /// In zh, this message translates to:
  /// **'已清空搜索历史'**
  String get searchHistoryCleared;

  /// No description provided for @searchKeywordTooShort.
  ///
  /// In zh, this message translates to:
  /// **'请输入至少2个字符'**
  String get searchKeywordTooShort;

  /// No description provided for @searchTabDramas.
  ///
  /// In zh, this message translates to:
  /// **'短剧'**
  String get searchTabDramas;

  /// No description provided for @searchTabWorks.
  ///
  /// In zh, this message translates to:
  /// **'作品'**
  String get searchTabWorks;

  /// No description provided for @searchTabActors.
  ///
  /// In zh, this message translates to:
  /// **'角色 IP'**
  String get searchTabActors;

  /// No description provided for @searchTabUsers.
  ///
  /// In zh, this message translates to:
  /// **'用户'**
  String get searchTabUsers;

  /// No description provided for @searchEpisodeNo.
  ///
  /// In zh, this message translates to:
  /// **'第{episodeNo}集'**
  String searchEpisodeNo(int episodeNo);

  /// No description provided for @searchMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 分钟前'**
  String searchMinutesAgo(int count);

  /// No description provided for @searchHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 小时前'**
  String searchHoursAgo(int count);

  /// No description provided for @searchDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count} 天前'**
  String searchDaysAgo(int count);

  /// No description provided for @searchDramasCount.
  ///
  /// In zh, this message translates to:
  /// **'短剧 ({count})'**
  String searchDramasCount(int count);

  /// No description provided for @searchActorsCount.
  ///
  /// In zh, this message translates to:
  /// **'角色 ({count})'**
  String searchActorsCount(int count);

  /// No description provided for @searchDramaEpisodesWithCast.
  ///
  /// In zh, this message translates to:
  /// **'全{count}集 | 参演：{actors}'**
  String searchDramaEpisodesWithCast(int count, String actors);

  /// No description provided for @nftTitle.
  ///
  /// In zh, this message translates to:
  /// **'NFT 角色广场'**
  String get nftTitle;

  /// No description provided for @nftLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载角色 IP 中…'**
  String get nftLoading;

  /// No description provided for @nftEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无角色IP'**
  String get nftEmpty;

  /// No description provided for @nftRefresh.
  ///
  /// In zh, this message translates to:
  /// **'刷新'**
  String get nftRefresh;

  /// No description provided for @nftIdPrefix.
  ///
  /// In zh, this message translates to:
  /// **'编号：#{id}'**
  String nftIdPrefix(String id);

  /// No description provided for @nftRarity.
  ///
  /// In zh, this message translates to:
  /// **'稀有度'**
  String get nftRarity;

  /// No description provided for @nftStatusStaked.
  ///
  /// In zh, this message translates to:
  /// **'已质押'**
  String get nftStatusStaked;

  /// No description provided for @nftStatusIdle.
  ///
  /// In zh, this message translates to:
  /// **'空闲'**
  String get nftStatusIdle;

  /// No description provided for @nftPrice.
  ///
  /// In zh, this message translates to:
  /// **'价格'**
  String get nftPrice;

  /// No description provided for @dramaDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'短剧详情'**
  String get dramaDetailTitle;

  /// No description provided for @dramaDetailLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中…'**
  String get dramaDetailLoading;

  /// No description provided for @dramaDetailRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get dramaDetailRetry;

  /// No description provided for @dramaDetailEpisodeList.
  ///
  /// In zh, this message translates to:
  /// **'剧集列表'**
  String get dramaDetailEpisodeList;

  /// No description provided for @dramaDetailSynopsis.
  ///
  /// In zh, this message translates to:
  /// **'剧情简介'**
  String get dramaDetailSynopsis;

  /// No description provided for @dramaDetailExpand.
  ///
  /// In zh, this message translates to:
  /// **'展开'**
  String get dramaDetailExpand;

  /// No description provided for @dramaDetailCollapse.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get dramaDetailCollapse;

  /// No description provided for @dramaDetailTabIntro.
  ///
  /// In zh, this message translates to:
  /// **'简介'**
  String get dramaDetailTabIntro;

  /// No description provided for @dramaDetailTabEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'选集'**
  String get dramaDetailTabEpisodes;

  /// No description provided for @dramaDetailTabComments.
  ///
  /// In zh, this message translates to:
  /// **'评论'**
  String get dramaDetailTabComments;

  /// No description provided for @dramaDetailTabRoles.
  ///
  /// In zh, this message translates to:
  /// **'角色IP'**
  String get dramaDetailTabRoles;

  /// No description provided for @dramaDetailSignMoreCharacterIps.
  ///
  /// In zh, this message translates to:
  /// **'签约更多角色IP'**
  String get dramaDetailSignMoreCharacterIps;

  /// No description provided for @dramaDetailCharactersEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂未绑定角色IP'**
  String get dramaDetailCharactersEmpty;

  /// No description provided for @dramaDetailRoleSalary.
  ///
  /// In zh, this message translates to:
  /// **'片酬 {amount}'**
  String dramaDetailRoleSalary(String amount);

  /// No description provided for @dramaDetailRoleSalaryPerHour.
  ///
  /// In zh, this message translates to:
  /// **'片酬{amount} STORY/h'**
  String dramaDetailRoleSalaryPerHour(String amount);

  /// No description provided for @dramaDetailRoleUnbound.
  ///
  /// In zh, this message translates to:
  /// **'未绑定'**
  String get dramaDetailRoleUnbound;

  /// No description provided for @dramaCastActorsTitle.
  ///
  /// In zh, this message translates to:
  /// **'参演角色IP'**
  String get dramaCastActorsTitle;

  /// No description provided for @dramaDetailCompletion.
  ///
  /// In zh, this message translates to:
  /// **'{count} 完播'**
  String dramaDetailCompletion(String count);

  /// No description provided for @dramaDetailHeat.
  ///
  /// In zh, this message translates to:
  /// **'{count} 热度'**
  String dramaDetailHeat(String count);

  /// No description provided for @dramaDetailTotalEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'共{count}集'**
  String dramaDetailTotalEpisodes(int count);

  /// No description provided for @dramaDetailRatingTitle.
  ///
  /// In zh, this message translates to:
  /// **'为作品评分'**
  String get dramaDetailRatingTitle;

  /// No description provided for @dramaDetailWantToRate.
  ///
  /// In zh, this message translates to:
  /// **'我要评分'**
  String get dramaDetailWantToRate;

  /// No description provided for @dramaDetailNotRated.
  ///
  /// In zh, this message translates to:
  /// **'未评'**
  String get dramaDetailNotRated;

  /// No description provided for @dramaDetailCompletionLabel.
  ///
  /// In zh, this message translates to:
  /// **'完播'**
  String get dramaDetailCompletionLabel;

  /// No description provided for @dramaDetailHeatLabel.
  ///
  /// In zh, this message translates to:
  /// **'热度'**
  String get dramaDetailHeatLabel;

  /// No description provided for @dramaDetailSynopsisLead.
  ///
  /// In zh, this message translates to:
  /// **'简介：'**
  String get dramaDetailSynopsisLead;

  /// No description provided for @dramaDetailRatingEmpty.
  ///
  /// In zh, this message translates to:
  /// **'您的评分：--'**
  String get dramaDetailRatingEmpty;

  /// No description provided for @dramaDetailRatingValue.
  ///
  /// In zh, this message translates to:
  /// **'您的评分：{rating}'**
  String dramaDetailRatingValue(int rating);

  /// No description provided for @dramaDetailRatingConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认评分'**
  String get dramaDetailRatingConfirm;

  /// No description provided for @dramaDetailRatingSuccess.
  ///
  /// In zh, this message translates to:
  /// **'评分成功：{rating} 分！'**
  String dramaDetailRatingSuccess(int rating);

  /// No description provided for @dramaDetailSelectEpisodeHint.
  ///
  /// In zh, this message translates to:
  /// **'请先选择剧集开始播放'**
  String get dramaDetailSelectEpisodeHint;

  /// No description provided for @dramaFavorited.
  ///
  /// In zh, this message translates to:
  /// **'已收藏'**
  String get dramaFavorited;

  /// No description provided for @dramaUnfavorited.
  ///
  /// In zh, this message translates to:
  /// **'已取消收藏'**
  String get dramaUnfavorited;

  /// No description provided for @dramaLiked.
  ///
  /// In zh, this message translates to:
  /// **'已点赞'**
  String get dramaLiked;

  /// No description provided for @dramaUnliked.
  ///
  /// In zh, this message translates to:
  /// **'已取消点赞'**
  String get dramaUnliked;

  /// No description provided for @playerFollowed.
  ///
  /// In zh, this message translates to:
  /// **'已关注'**
  String get playerFollowed;

  /// No description provided for @playerUnfollowed.
  ///
  /// In zh, this message translates to:
  /// **'已取消关注'**
  String get playerUnfollowed;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络错误，请稍后再试'**
  String get errorNetwork;

  /// No description provided for @errorTimeout.
  ///
  /// In zh, this message translates to:
  /// **'请求超时，请稍后再试'**
  String get errorTimeout;

  /// No description provided for @errorParse.
  ///
  /// In zh, this message translates to:
  /// **'数据解析失败'**
  String get errorParse;

  /// No description provided for @errorUnauthorized.
  ///
  /// In zh, this message translates to:
  /// **'请先登录'**
  String get errorUnauthorized;

  /// No description provided for @authSessionExpired.
  ///
  /// In zh, this message translates to:
  /// **'登录状态已失效，请重新登录'**
  String get authSessionExpired;

  /// No description provided for @errorNotFound.
  ///
  /// In zh, this message translates to:
  /// **'资源不存在'**
  String get errorNotFound;

  /// No description provided for @iapOrderInFlight.
  ///
  /// In zh, this message translates to:
  /// **'该商品有未完成的订单，请稍后再试'**
  String get iapOrderInFlight;

  /// No description provided for @errorOperationFailed.
  ///
  /// In zh, this message translates to:
  /// **'操作失败'**
  String get errorOperationFailed;

  /// No description provided for @uploadErrorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络连接不稳定，请检查网络后重试'**
  String get uploadErrorNetwork;

  /// No description provided for @uploadErrorTimeout.
  ///
  /// In zh, this message translates to:
  /// **'上传超时，请保持 App 在前台并重试'**
  String get uploadErrorTimeout;

  /// No description provided for @uploadErrorSessionExpired.
  ///
  /// In zh, this message translates to:
  /// **'上传凭证已过期，请重新上传'**
  String get uploadErrorSessionExpired;

  /// No description provided for @uploadErrorSessionUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法创建上传任务，请重试'**
  String get uploadErrorSessionUnavailable;

  /// No description provided for @uploadErrorFileMissing.
  ///
  /// In zh, this message translates to:
  /// **'本地视频已被移动或清理，请重新选择'**
  String get uploadErrorFileMissing;

  /// No description provided for @uploadErrorUnauthorized.
  ///
  /// In zh, this message translates to:
  /// **'登录状态或上传权限已失效，请重新登录后重试'**
  String get uploadErrorUnauthorized;

  /// No description provided for @uploadErrorRateLimited.
  ///
  /// In zh, this message translates to:
  /// **'上传请求过于频繁，请稍后重试'**
  String get uploadErrorRateLimited;

  /// No description provided for @uploadErrorRejected.
  ///
  /// In zh, this message translates to:
  /// **'上传服务拒绝了该文件，请确认文件后重试'**
  String get uploadErrorRejected;

  /// No description provided for @uploadErrorServer.
  ///
  /// In zh, this message translates to:
  /// **'上传服务暂时不可用，请稍后重试'**
  String get uploadErrorServer;

  /// No description provided for @uploadErrorInvalidResponse.
  ///
  /// In zh, this message translates to:
  /// **'上传服务返回异常，请稍后重试'**
  String get uploadErrorInvalidResponse;

  /// No description provided for @uploadErrorAccountChanged.
  ///
  /// In zh, this message translates to:
  /// **'登录账号已变化，请在当前账号下重新上传'**
  String get uploadErrorAccountChanged;

  /// No description provided for @uploadErrorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'视频上传失败，请重试'**
  String get uploadErrorUnknown;

  /// No description provided for @uploadErrorFileTypeNotAllowed.
  ///
  /// In zh, this message translates to:
  /// **'不支持该视频格式，请重新选择'**
  String get uploadErrorFileTypeNotAllowed;

  /// No description provided for @uploadErrorFileSizeExceeded.
  ///
  /// In zh, this message translates to:
  /// **'文件过大，请重新选择'**
  String get uploadErrorFileSizeExceeded;

  /// No description provided for @uploadErrorMultipartInvalid.
  ///
  /// In zh, this message translates to:
  /// **'上传记录已失效，请重新上传'**
  String get uploadErrorMultipartInvalid;

  /// No description provided for @uploadStatusWaitingNetwork.
  ///
  /// In zh, this message translates to:
  /// **'等待网络连接...'**
  String get uploadStatusWaitingNetwork;

  /// No description provided for @uploadStatusMerging.
  ///
  /// In zh, this message translates to:
  /// **'正在合并视频...'**
  String get uploadStatusMerging;

  /// No description provided for @uploadActionPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get uploadActionPause;

  /// No description provided for @uploadActionResume.
  ///
  /// In zh, this message translates to:
  /// **'继续上传'**
  String get uploadActionResume;

  /// No description provided for @uploadCellularDialogMessage.
  ///
  /// In zh, this message translates to:
  /// **'当前处于非 WiFi 网络，是否继续使用流量上传视频？'**
  String get uploadCellularDialogMessage;

  /// No description provided for @errorInvalidRoleId.
  ///
  /// In zh, this message translates to:
  /// **'角色 ID 无效，请刷新后重试'**
  String get errorInvalidRoleId;

  /// No description provided for @errorInvalidRoleNftAssetId.
  ///
  /// In zh, this message translates to:
  /// **'角色 NFT assetId 无效，请刷新后重试'**
  String get errorInvalidRoleNftAssetId;

  /// No description provided for @errorInvalidRoleCollectionAssetId.
  ///
  /// In zh, this message translates to:
  /// **'角色合集 assetId 无效，请刷新后重试'**
  String get errorInvalidRoleCollectionAssetId;

  /// No description provided for @roleNftLabelUnknown.
  ///
  /// In zh, this message translates to:
  /// **'角色NFT#未知'**
  String get roleNftLabelUnknown;

  /// No description provided for @roleNftLabel.
  ///
  /// In zh, this message translates to:
  /// **'角色NFT#{prefix}'**
  String roleNftLabel(String prefix);

  /// No description provided for @errorBusiness.
  ///
  /// In zh, this message translates to:
  /// **'操作失败：{message}'**
  String errorBusiness(String message);

  /// No description provided for @errorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'发生未知错误：{message}'**
  String errorUnknown(String message);

  /// No description provided for @errorNotSupported.
  ///
  /// In zh, this message translates to:
  /// **'不支持的操作：{message}'**
  String errorNotSupported(String message);

  /// No description provided for @playerEpisodeSelect.
  ///
  /// In zh, this message translates to:
  /// **'选集'**
  String get playerEpisodeSelect;

  /// No description provided for @playerPlayFailed.
  ///
  /// In zh, this message translates to:
  /// **'播放失败'**
  String get playerPlayFailed;

  /// No description provided for @playerDramaUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂无法播放该剧'**
  String get playerDramaUnavailable;

  /// No description provided for @playerContentUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'该内容暂未上架或已下架'**
  String get playerContentUnavailable;

  /// No description provided for @creatorWorkNotFound.
  ///
  /// In zh, this message translates to:
  /// **'作品不存在，无法查看'**
  String get creatorWorkNotFound;

  /// No description provided for @creatorWorkNotPublished.
  ///
  /// In zh, this message translates to:
  /// **'作品未上架，暂不可查看'**
  String get creatorWorkNotPublished;

  /// No description provided for @creatorOfflineReasonUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂无下架原因'**
  String get creatorOfflineReasonUnavailable;

  /// No description provided for @playerTapRetry.
  ///
  /// In zh, this message translates to:
  /// **'点击重试'**
  String get playerTapRetry;

  /// No description provided for @playerEpisodeTotal.
  ///
  /// In zh, this message translates to:
  /// **'全{count}集'**
  String playerEpisodeTotal(int count);

  /// No description provided for @playerEpisodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'第 {episodeNo} 集'**
  String playerEpisodeLabel(int episodeNo);

  /// No description provided for @playerLike.
  ///
  /// In zh, this message translates to:
  /// **'点赞'**
  String get playerLike;

  /// No description provided for @playerComment.
  ///
  /// In zh, this message translates to:
  /// **'评论'**
  String get playerComment;

  /// No description provided for @playerFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get playerFavorite;

  /// No description provided for @playerShare.
  ///
  /// In zh, this message translates to:
  /// **'分享'**
  String get playerShare;

  /// No description provided for @playerShareDramaEpisode.
  ///
  /// In zh, this message translates to:
  /// **'{title} | 第{episodeNo}集：{description} {url} 。来 StoryFun，观看精美AI短剧。'**
  String playerShareDramaEpisode(
    String title,
    int episodeNo,
    String description,
    String url,
  );

  /// No description provided for @playerShareDramaEpisodeNoDesc.
  ///
  /// In zh, this message translates to:
  /// **'{title} | 第{episodeNo}集 {url} 。来 StoryFun，观看精美AI短剧。'**
  String playerShareDramaEpisodeNoDesc(String title, int episodeNo, String url);

  /// No description provided for @playerShareShortVideo.
  ///
  /// In zh, this message translates to:
  /// **'{description} {url}。来 StoryFun，观看精美短视频。'**
  String playerShareShortVideo(String description, String url);

  /// No description provided for @playerShareShortVideoNoDesc.
  ///
  /// In zh, this message translates to:
  /// **'{url}。来 StoryFun，观看精美短视频。'**
  String playerShareShortVideoNoDesc(String url);

  /// No description provided for @playerShareDrama.
  ///
  /// In zh, this message translates to:
  /// **'{title} {url} 。来 StoryFun，观看精美AI短剧。'**
  String playerShareDrama(String title, String url);

  /// No description provided for @playerShareDramaNoTitle.
  ///
  /// In zh, this message translates to:
  /// **'{url} 。来 StoryFun，观看精美AI短剧。'**
  String playerShareDramaNoTitle(String url);

  /// No description provided for @playerRatingLabel.
  ///
  /// In zh, this message translates to:
  /// **'{rating} 分'**
  String playerRatingLabel(String rating);

  /// No description provided for @loginOrSignUp.
  ///
  /// In zh, this message translates to:
  /// **'登录或注册'**
  String get loginOrSignUp;

  /// No description provided for @loginEnterCode.
  ///
  /// In zh, this message translates to:
  /// **'输入验证码'**
  String get loginEnterCode;

  /// No description provided for @loginCheckEmailDesc.
  ///
  /// In zh, this message translates to:
  /// **'请检查 {email} 收到的由 privy.io 发送的邮件，并在下方输入验证码。'**
  String loginCheckEmailDesc(String email);

  /// No description provided for @loginResendCountdown.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒后重新发送'**
  String loginResendCountdown(int seconds);

  /// No description provided for @loginResendBtn.
  ///
  /// In zh, this message translates to:
  /// **'重新发送'**
  String get loginResendBtn;

  /// No description provided for @loginProtectedByPrivy.
  ///
  /// In zh, this message translates to:
  /// **'由 Privy 提供安全保护'**
  String get loginProtectedByPrivy;

  /// No description provided for @loginAgreeLead.
  ///
  /// In zh, this message translates to:
  /// **'我已同意'**
  String get loginAgreeLead;

  /// No description provided for @loginAgreeAnd.
  ///
  /// In zh, this message translates to:
  /// **'和'**
  String get loginAgreeAnd;

  /// No description provided for @loginAgreeConfirmLead.
  ///
  /// In zh, this message translates to:
  /// **'点击确定，代表您已同意'**
  String get loginAgreeConfirmLead;

  /// No description provided for @loginAgreeRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先同意服务条款和隐私政策'**
  String get loginAgreeRequired;

  /// No description provided for @deletingAccountPending.
  ///
  /// In zh, this message translates to:
  /// **'账户等待删除中'**
  String get deletingAccountPending;

  /// No description provided for @deletingAccountCancelDeletion.
  ///
  /// In zh, this message translates to:
  /// **'撤销删除账户'**
  String get deletingAccountCancelDeletion;

  /// No description provided for @deletingAccountGoBack.
  ///
  /// In zh, this message translates to:
  /// **'回退'**
  String get deletingAccountGoBack;

  /// No description provided for @drawerEmailAccount.
  ///
  /// In zh, this message translates to:
  /// **'邮箱账户'**
  String get drawerEmailAccount;

  /// No description provided for @drawerClickToLogin.
  ///
  /// In zh, this message translates to:
  /// **'点击登录账户'**
  String get drawerClickToLogin;

  /// No description provided for @drawerBuyStory.
  ///
  /// In zh, this message translates to:
  /// **'交易 STORY'**
  String get drawerBuyStory;

  /// No description provided for @drawerDeposit.
  ///
  /// In zh, this message translates to:
  /// **'充值'**
  String get drawerDeposit;

  /// No description provided for @drawerWithdraw.
  ///
  /// In zh, this message translates to:
  /// **'提现'**
  String get drawerWithdraw;

  /// No description provided for @drawerNotifications.
  ///
  /// In zh, this message translates to:
  /// **'通知消息'**
  String get drawerNotifications;

  /// No description provided for @drawerNoNotifications.
  ///
  /// In zh, this message translates to:
  /// **'暂无新消息'**
  String get drawerNoNotifications;

  /// No description provided for @notificationTabSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get notificationTabSystem;

  /// No description provided for @notificationTabInteraction.
  ///
  /// In zh, this message translates to:
  /// **'互动'**
  String get notificationTabInteraction;

  /// No description provided for @notificationTagIpSign.
  ///
  /// In zh, this message translates to:
  /// **'签约角色IP'**
  String get notificationTagIpSign;

  /// No description provided for @notificationTagRoleManagement.
  ///
  /// In zh, this message translates to:
  /// **'角色管理'**
  String get notificationTagRoleManagement;

  /// No description provided for @notificationTagShowRevenue.
  ///
  /// In zh, this message translates to:
  /// **'演出收益'**
  String get notificationTagShowRevenue;

  /// No description provided for @notificationTagLike.
  ///
  /// In zh, this message translates to:
  /// **'点赞'**
  String get notificationTagLike;

  /// No description provided for @notificationTagFavorite.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get notificationTagFavorite;

  /// No description provided for @notificationSignedActor.
  ///
  /// In zh, this message translates to:
  /// **'@{user} 签约了角色IP {actor}'**
  String notificationSignedActor(String user, String actor);

  /// No description provided for @notificationShareEarned.
  ///
  /// In zh, this message translates to:
  /// **'你获得分成 {amount}'**
  String notificationShareEarned(String amount);

  /// No description provided for @notificationStaminaLow.
  ///
  /// In zh, this message translates to:
  /// **'{actor} 体力不足，尽快补充体力或休息'**
  String notificationStaminaLow(String actor);

  /// No description provided for @notificationCurrentStamina.
  ///
  /// In zh, this message translates to:
  /// **'当前体力 {value}'**
  String notificationCurrentStamina(String value);

  /// No description provided for @notificationShowEnded.
  ///
  /// In zh, this message translates to:
  /// **'{range} 演出结束'**
  String notificationShowEnded(String range);

  /// No description provided for @notificationIncomeEarned.
  ///
  /// In zh, this message translates to:
  /// **'你获得收益 {amount}'**
  String notificationIncomeEarned(String amount);

  /// No description provided for @notificationActionClaim.
  ///
  /// In zh, this message translates to:
  /// **'领取'**
  String get notificationActionClaim;

  /// No description provided for @notificationActionRefill.
  ///
  /// In zh, this message translates to:
  /// **'补充'**
  String get notificationActionRefill;

  /// No description provided for @notificationInteractionLikedVideo.
  ///
  /// In zh, this message translates to:
  /// **'赞了你的视频'**
  String get notificationInteractionLikedVideo;

  /// No description provided for @notificationInteractionLikedDrama.
  ///
  /// In zh, this message translates to:
  /// **'赞了你的短剧《{title}》'**
  String notificationInteractionLikedDrama(String title);

  /// No description provided for @notificationInteractionFavoritedVideo.
  ///
  /// In zh, this message translates to:
  /// **'收藏了你的视频'**
  String get notificationInteractionFavoritedVideo;

  /// No description provided for @notificationInteractionFavoritedDrama.
  ///
  /// In zh, this message translates to:
  /// **'收藏了你的短剧《{title}》'**
  String notificationInteractionFavoritedDrama(String title);

  /// No description provided for @notificationInteractionCommented.
  ///
  /// In zh, this message translates to:
  /// **'评论了你：{content}'**
  String notificationInteractionCommented(String content);

  /// No description provided for @notificationInteractionFollowedYou.
  ///
  /// In zh, this message translates to:
  /// **'关注了你'**
  String get notificationInteractionFollowedYou;

  /// No description provided for @notificationActionMutualFollow.
  ///
  /// In zh, this message translates to:
  /// **'互关'**
  String get notificationActionMutualFollow;

  /// No description provided for @notificationActionFollow.
  ///
  /// In zh, this message translates to:
  /// **'关注'**
  String get notificationActionFollow;

  /// No description provided for @notificationDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get notificationDelete;

  /// No description provided for @notificationDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败，请稍后再试'**
  String get notificationDeleteFailed;

  /// No description provided for @notificationRealtimeReceived.
  ///
  /// In zh, this message translates to:
  /// **'收到一条新通知'**
  String get notificationRealtimeReceived;

  /// No description provided for @drawerEpisodeProgress.
  ///
  /// In zh, this message translates to:
  /// **'{current}/{total}集'**
  String drawerEpisodeProgress(int current, int total);

  /// No description provided for @drawerNotificationSignedActor.
  ///
  /// In zh, this message translates to:
  /// **'{actor} 签约了角色IP {target}'**
  String drawerNotificationSignedActor(String actor, String target);

  /// No description provided for @drawerNotificationLikedVideo.
  ///
  /// In zh, this message translates to:
  /// **'{actor} 赞了你的视频'**
  String drawerNotificationLikedVideo(String actor);

  /// No description provided for @drawerNotificationFavoritedDrama.
  ///
  /// In zh, this message translates to:
  /// **'{actor} 收藏了你的短剧 {target}'**
  String drawerNotificationFavoritedDrama(String actor, String target);

  /// No description provided for @depositTitle.
  ///
  /// In zh, this message translates to:
  /// **'充值'**
  String get depositTitle;

  /// No description provided for @insufficientBalanceTitle.
  ///
  /// In zh, this message translates to:
  /// **'余额不足'**
  String get insufficientBalanceTitle;

  /// No description provided for @insufficientBalanceDetail.
  ///
  /// In zh, this message translates to:
  /// **'{currency} 余额不足，你还差 {amount} {currency}'**
  String insufficientBalanceDetail(String currency, String amount);

  /// No description provided for @insufficientBalancePrompt.
  ///
  /// In zh, this message translates to:
  /// **'是否前往充值？'**
  String get insufficientBalancePrompt;

  /// No description provided for @insufficientBalanceRecharge.
  ///
  /// In zh, this message translates to:
  /// **'去充值'**
  String get insufficientBalanceRecharge;

  /// No description provided for @depositDesc.
  ///
  /// In zh, this message translates to:
  /// **'请从交易所或其他钱包向下方地址转账，确认到账后余额会自动更新。'**
  String get depositDesc;

  /// No description provided for @depositToken.
  ///
  /// In zh, this message translates to:
  /// **'币种'**
  String get depositToken;

  /// No description provided for @depositNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络'**
  String get depositNetwork;

  /// No description provided for @depositNetworkNote.
  ///
  /// In zh, this message translates to:
  /// **'请确认转账网络，网络错误可能导致资产丢失'**
  String get depositNetworkNote;

  /// No description provided for @depositAddress.
  ///
  /// In zh, this message translates to:
  /// **'充值地址'**
  String get depositAddress;

  /// No description provided for @depositAddressCopied.
  ///
  /// In zh, this message translates to:
  /// **'地址已复制到剪贴板'**
  String get depositAddressCopied;

  /// No description provided for @depositSend.
  ///
  /// In zh, this message translates to:
  /// **'发送'**
  String get depositSend;

  /// No description provided for @depositReceive.
  ///
  /// In zh, this message translates to:
  /// **'接收'**
  String get depositReceive;

  /// No description provided for @depositConvertNote.
  ///
  /// In zh, this message translates to:
  /// **'将代币发送到这个地址，它将自动在你的 Story.fun 账户中兑换成USDC'**
  String get depositConvertNote;

  /// No description provided for @depositMinNote.
  ///
  /// In zh, this message translates to:
  /// **'最小充值金额：{minAmount} {token}'**
  String depositMinNote(String minAmount, String token);

  /// No description provided for @depositExchangeRateNote.
  ///
  /// In zh, this message translates to:
  /// **'当前兑换汇率为 {rate}，实际到账金额 = 充值金额 × {rate}'**
  String depositExchangeRateNote(String rate);

  /// No description provided for @depositWarning.
  ///
  /// In zh, this message translates to:
  /// **'请仅转入所选网络上的所选币种，其他资产将无法找回\n请确认转账网络，网络错误可能导致资产丢失'**
  String get depositWarning;

  /// No description provided for @withdrawTitle.
  ///
  /// In zh, this message translates to:
  /// **'提现'**
  String get withdrawTitle;

  /// No description provided for @withdrawBalance.
  ///
  /// In zh, this message translates to:
  /// **'可提现余额'**
  String get withdrawBalance;

  /// No description provided for @withdrawToken.
  ///
  /// In zh, this message translates to:
  /// **'币种'**
  String get withdrawToken;

  /// No description provided for @withdrawAddress.
  ///
  /// In zh, this message translates to:
  /// **'提现地址'**
  String get withdrawAddress;

  /// No description provided for @withdrawAddressHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入或粘贴 Solana 接收地址'**
  String get withdrawAddressHint;

  /// No description provided for @withdrawAddressHintEvm.
  ///
  /// In zh, this message translates to:
  /// **'请输入或粘贴 EVM 接收地址'**
  String get withdrawAddressHintEvm;

  /// No description provided for @withdrawInvalidEvmAddress.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的 EVM 地址'**
  String get withdrawInvalidEvmAddress;

  /// No description provided for @withdrawInvalidSolanaAddress.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的 Solana 地址'**
  String get withdrawInvalidSolanaAddress;

  /// No description provided for @withdrawEvmGasNote.
  ///
  /// In zh, this message translates to:
  /// **'EVM 提现需钱包内有足够的原生代币支付 Gas，交易将直接在链上发起。'**
  String get withdrawEvmGasNote;

  /// No description provided for @withdrawEvmFailed.
  ///
  /// In zh, this message translates to:
  /// **'EVM 提现失败，请稍后重试'**
  String get withdrawEvmFailed;

  /// No description provided for @withdrawAddressNote.
  ///
  /// In zh, this message translates to:
  /// **'请确认地址正确，转账后无法撤回'**
  String get withdrawAddressNote;

  /// No description provided for @withdrawNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络'**
  String get withdrawNetwork;

  /// No description provided for @withdrawAmount.
  ///
  /// In zh, this message translates to:
  /// **'金额'**
  String get withdrawAmount;

  /// No description provided for @withdrawAmountHint.
  ///
  /// In zh, this message translates to:
  /// **'输入提现金额'**
  String get withdrawAmountHint;

  /// No description provided for @withdrawMax.
  ///
  /// In zh, this message translates to:
  /// **'最大'**
  String get withdrawMax;

  /// No description provided for @withdrawAvailableBalance.
  ///
  /// In zh, this message translates to:
  /// **'余额 {balance} {token}'**
  String withdrawAvailableBalance(String balance, String token);

  /// No description provided for @withdrawMinWarning.
  ///
  /// In zh, this message translates to:
  /// **'最小提现金额：{minAmount} {token}\n请仔细核对提现地址和网络，转账后无法撤回'**
  String withdrawMinWarning(String minAmount, String token);

  /// No description provided for @withdrawConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认提现'**
  String get withdrawConfirm;

  /// No description provided for @withdrawAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get withdrawAll;

  /// No description provided for @withdrawMinAmountError.
  ///
  /// In zh, this message translates to:
  /// **'最小提现金额为 {minAmt} {token}'**
  String withdrawMinAmountError(String minAmt, String token);

  /// No description provided for @withdrawExceedBalanceError.
  ///
  /// In zh, this message translates to:
  /// **'提现金额不能超过可用余额'**
  String get withdrawExceedBalanceError;

  /// No description provided for @withdrawSameAsWalletError.
  ///
  /// In zh, this message translates to:
  /// **'提现地址不能与当前钱包地址相同'**
  String get withdrawSameAsWalletError;

  /// No description provided for @withdrawConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认提现'**
  String get withdrawConfirmTitle;

  /// No description provided for @withdrawConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定提取 {amount} {token} 到以下 Solana 接收地址吗？\n\n{address}'**
  String withdrawConfirmMessage(String amount, String token, String address);

  /// No description provided for @withdrawSuccessToast.
  ///
  /// In zh, this message translates to:
  /// **'提现指令已提交成功！'**
  String get withdrawSuccessToast;

  /// No description provided for @withdrawFailedToast.
  ///
  /// In zh, this message translates to:
  /// **'提现失败，请重试'**
  String get withdrawFailedToast;

  /// No description provided for @withdrawErrorToast.
  ///
  /// In zh, this message translates to:
  /// **'提现发生错误: {error}'**
  String withdrawErrorToast(String error);

  /// No description provided for @withdrawAddressHintWithToken.
  ///
  /// In zh, this message translates to:
  /// **'输入接收 {token} 的钱包地址'**
  String withdrawAddressHintWithToken(String token);

  /// No description provided for @withdrawFee.
  ///
  /// In zh, this message translates to:
  /// **'手续费'**
  String get withdrawFee;

  /// No description provided for @withdrawFeeValue.
  ///
  /// In zh, this message translates to:
  /// **'{fee} {token}'**
  String withdrawFeeValue(String fee, String token);

  /// No description provided for @withdrawMinAmount.
  ///
  /// In zh, this message translates to:
  /// **'最低提币量：{minAmount} {token}'**
  String withdrawMinAmount(String minAmount, String token);

  /// No description provided for @withdrawMaxAmount.
  ///
  /// In zh, this message translates to:
  /// **'最大提现金额：{maxAmount} {token}'**
  String withdrawMaxAmount(String maxAmount, String token);

  /// No description provided for @withdrawSponsorSigning.
  ///
  /// In zh, this message translates to:
  /// **'签名交易中...'**
  String get withdrawSponsorSigning;

  /// No description provided for @withdrawSponsorSubmitting.
  ///
  /// In zh, this message translates to:
  /// **'提交链上交易中...'**
  String get withdrawSponsorSubmitting;

  /// No description provided for @withdrawSponsorSuccess.
  ///
  /// In zh, this message translates to:
  /// **'提现交易已提交成功！'**
  String get withdrawSponsorSuccess;

  /// No description provided for @withdrawSponsorFailed.
  ///
  /// In zh, this message translates to:
  /// **'交易提交失败，请重试'**
  String get withdrawSponsorFailed;

  /// No description provided for @withdrawOrderProcessing.
  ///
  /// In zh, this message translates to:
  /// **'订单处理中'**
  String get withdrawOrderProcessing;

  /// No description provided for @withdrawOrderSuccess.
  ///
  /// In zh, this message translates to:
  /// **'订单已完成'**
  String get withdrawOrderSuccess;

  /// No description provided for @withdrawOrderFailed.
  ///
  /// In zh, this message translates to:
  /// **'订单处理失败'**
  String get withdrawOrderFailed;

  /// No description provided for @withdrawOrderStatus.
  ///
  /// In zh, this message translates to:
  /// **'订单状态：{status}'**
  String withdrawOrderStatus(String status);

  /// No description provided for @qrScannerTitle.
  ///
  /// In zh, this message translates to:
  /// **'扫描二维码'**
  String get qrScannerTitle;

  /// No description provided for @qrScannerHint.
  ///
  /// In zh, this message translates to:
  /// **'将二维码放入框内扫描'**
  String get qrScannerHint;

  /// No description provided for @drawerProfile.
  ///
  /// In zh, this message translates to:
  /// **'个人中心'**
  String get drawerProfile;

  /// No description provided for @drawerCreatorManagement.
  ///
  /// In zh, this message translates to:
  /// **'创作管理'**
  String get drawerCreatorManagement;

  /// No description provided for @drawerInvite.
  ///
  /// In zh, this message translates to:
  /// **'邀请'**
  String get drawerInvite;

  /// No description provided for @inviteTitle.
  ///
  /// In zh, this message translates to:
  /// **'邀请好友'**
  String get inviteTitle;

  /// No description provided for @inviteTotalPeople.
  ///
  /// In zh, this message translates to:
  /// **'累计邀请人数'**
  String get inviteTotalPeople;

  /// No description provided for @inviteTotalRewards.
  ///
  /// In zh, this message translates to:
  /// **'累计邀请收益'**
  String get inviteTotalRewards;

  /// No description provided for @inviteWeeklyPool.
  ///
  /// In zh, this message translates to:
  /// **'本周邀请奖池'**
  String get inviteWeeklyPool;

  /// No description provided for @inviteViewHistory.
  ///
  /// In zh, this message translates to:
  /// **'查看收益记录'**
  String get inviteViewHistory;

  /// No description provided for @inviteShareSection.
  ///
  /// In zh, this message translates to:
  /// **'分享专属邀请链接或邀请码'**
  String get inviteShareSection;

  /// No description provided for @inviteLinkSection.
  ///
  /// In zh, this message translates to:
  /// **'邀请链接'**
  String get inviteLinkSection;

  /// No description provided for @inviteLinkSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'好友通过你的链接注册，签约并派遣角色，你将获得额外 STORY 奖励'**
  String get inviteLinkSubtitle;

  /// No description provided for @inviteCodeLabel.
  ///
  /// In zh, this message translates to:
  /// **'邀请码'**
  String get inviteCodeLabel;

  /// No description provided for @inviteCopyButton.
  ///
  /// In zh, this message translates to:
  /// **'复制链接'**
  String get inviteCopyButton;

  /// No description provided for @inviteCopiedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'邀请链接已复制到剪贴板！'**
  String get inviteCopiedSuccess;

  /// No description provided for @inviteCodeCopiedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'邀请码已复制到剪贴板！'**
  String get inviteCodeCopiedSuccess;

  /// No description provided for @inviteInvitedLabel.
  ///
  /// In zh, this message translates to:
  /// **'已邀请'**
  String get inviteInvitedLabel;

  /// No description provided for @inviteRewardLabel.
  ///
  /// In zh, this message translates to:
  /// **'收益'**
  String get inviteRewardLabel;

  /// No description provided for @inviteBindCode.
  ///
  /// In zh, this message translates to:
  /// **'绑定邀请码'**
  String get inviteBindCode;

  /// No description provided for @inviteBindCodePromptHint.
  ///
  /// In zh, this message translates to:
  /// **'跳过后可在邀请页绑定'**
  String get inviteBindCodePromptHint;

  /// No description provided for @inviteBindCodePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'输入邀请码'**
  String get inviteBindCodePlaceholder;

  /// No description provided for @inviteBindConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get inviteBindConfirm;

  /// No description provided for @inviteBindSuccess.
  ///
  /// In zh, this message translates to:
  /// **'邀请码绑定成功'**
  String get inviteBindSuccess;

  /// No description provided for @inviteBindCodeInvalid.
  ///
  /// In zh, this message translates to:
  /// **'邀请码无效'**
  String get inviteBindCodeInvalid;

  /// No description provided for @inviteBindCodeAlreadyBound.
  ///
  /// In zh, this message translates to:
  /// **'该账号已绑定邀请码'**
  String get inviteBindCodeAlreadyBound;

  /// No description provided for @inviteRulesSection.
  ///
  /// In zh, this message translates to:
  /// **'邀请规则'**
  String get inviteRulesSection;

  /// No description provided for @inviteFaqPoolTitle.
  ///
  /// In zh, this message translates to:
  /// **'每周邀请奖池是什么？'**
  String get inviteFaqPoolTitle;

  /// No description provided for @inviteFaqPoolBody.
  ///
  /// In zh, this message translates to:
  /// **'每周邀请奖池是平台为邀请活动设立的独立奖励池，用于奖励当周邀请行为，不会从被邀请人收益中扣除。奖池设有周发放上限，触顶后按份额等比缩减，每周一重新统计发放。'**
  String get inviteFaqPoolBody;

  /// No description provided for @inviteFaqSettlementTitle.
  ///
  /// In zh, this message translates to:
  /// **'邀请奖励什么时候结算？'**
  String get inviteFaqSettlementTitle;

  /// No description provided for @inviteFaqSettlementBody.
  ///
  /// In zh, this message translates to:
  /// **'邀请奖励与经纪人页面的片酬在同一周期统一结算：每周一 00:00 (UTC) 截止统计，结算后可前往收益页领取。'**
  String get inviteFaqSettlementBody;

  /// No description provided for @inviteRuleSourceTitle.
  ///
  /// In zh, this message translates to:
  /// **'奖励来源'**
  String get inviteRuleSourceTitle;

  /// No description provided for @inviteRuleSourceSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'独立邀请子池'**
  String get inviteRuleSourceSubtitle;

  /// No description provided for @inviteRuleSourceBody.
  ///
  /// In zh, this message translates to:
  /// **'邀请奖励来自 NFT 挖矿池中独立的邀请子池（占总挖矿池 25%），不从被邀请人收益中扣除。邀请子池有独立周硬顶，触顶后按份额等比缩减。'**
  String get inviteRuleSourceBody;

  /// No description provided for @inviteRuleBaseTitle.
  ///
  /// In zh, this message translates to:
  /// **'计算基数'**
  String get inviteRuleBaseTitle;

  /// No description provided for @inviteRuleBaseSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'按实得 STORY'**
  String get inviteRuleBaseSubtitle;

  /// No description provided for @inviteRuleBaseBody.
  ///
  /// In zh, this message translates to:
  /// **'奖励按被邀请人本期实际到手的 STORY 计算，不按名义产出计算。被邀请人自己挖到的 STORY 不受影响，邀请奖励是额外发放。'**
  String get inviteRuleBaseBody;

  /// No description provided for @inviteRuleLevelTitle.
  ///
  /// In zh, this message translates to:
  /// **'奖励范围'**
  String get inviteRuleLevelTitle;

  /// No description provided for @inviteRuleLevelSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'仅直接邀请'**
  String get inviteRuleLevelSubtitle;

  /// No description provided for @inviteRuleLevelBody.
  ///
  /// In zh, this message translates to:
  /// **'邀请奖励仅发放给你直接邀请的用户，不设二级及以上间接返佣。'**
  String get inviteRuleLevelBody;

  /// No description provided for @inviteRuleConditionTitle.
  ///
  /// In zh, this message translates to:
  /// **'有效条件'**
  String get inviteRuleConditionTitle;

  /// No description provided for @inviteRuleConditionSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'有效下线才能产生奖励'**
  String get inviteRuleConditionSubtitle;

  /// No description provided for @inviteRuleConditionBody.
  ///
  /// In zh, this message translates to:
  /// **'被邀请人实际挖到过 STORY，或发生过 {currency} 付费，才计为有效下线。空号注册不产生奖励。邀请关系一经建立不可更改。'**
  String inviteRuleConditionBody(String currency);

  /// No description provided for @drawerTxHistory.
  ///
  /// In zh, this message translates to:
  /// **'交易记录'**
  String get drawerTxHistory;

  /// No description provided for @drawerFinanceDashboard.
  ///
  /// In zh, this message translates to:
  /// **'资金看板'**
  String get drawerFinanceDashboard;

  /// No description provided for @financeDashboardComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'资金看板即将上线，敬请期待'**
  String get financeDashboardComingSoon;

  /// No description provided for @financeDashboardPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'平台资金看板'**
  String get financeDashboardPageTitle;

  /// No description provided for @financeDashboardTotalUsdcIncome.
  ///
  /// In zh, this message translates to:
  /// **'{currency} 总收入'**
  String financeDashboardTotalUsdcIncome(String currency);

  /// No description provided for @financeDashboardTotalStoryReleased.
  ///
  /// In zh, this message translates to:
  /// **'STORY 总释放'**
  String get financeDashboardTotalStoryReleased;

  /// No description provided for @financeDashboardTabUsdcIncome.
  ///
  /// In zh, this message translates to:
  /// **'{currency} 收入明细'**
  String financeDashboardTabUsdcIncome(String currency);

  /// No description provided for @financeDashboardTabVaultFunds.
  ///
  /// In zh, this message translates to:
  /// **'金库资金沉淀'**
  String get financeDashboardTabVaultFunds;

  /// No description provided for @financeDashboardTabStoryRelease.
  ///
  /// In zh, this message translates to:
  /// **'STORY 释放概览'**
  String get financeDashboardTabStoryRelease;

  /// No description provided for @financeDashboardFeeMint.
  ///
  /// In zh, this message translates to:
  /// **'签约费'**
  String get financeDashboardFeeMint;

  /// No description provided for @financeDashboardFeeRoyalty.
  ///
  /// In zh, this message translates to:
  /// **'二级版税'**
  String get financeDashboardFeeRoyalty;

  /// No description provided for @financeDashboardFeeItemPurchase.
  ///
  /// In zh, this message translates to:
  /// **'购买道具'**
  String get financeDashboardFeeItemPurchase;

  /// No description provided for @financeDashboardFeeTx.
  ///
  /// In zh, this message translates to:
  /// **'手续费'**
  String get financeDashboardFeeTx;

  /// No description provided for @financeDashboardLedgerBizSigningFee.
  ///
  /// In zh, this message translates to:
  /// **'签约费'**
  String get financeDashboardLedgerBizSigningFee;

  /// No description provided for @financeDashboardLedgerBizManualCredit.
  ///
  /// In zh, this message translates to:
  /// **'人工加款'**
  String get financeDashboardLedgerBizManualCredit;

  /// No description provided for @financeDashboardLedgerBizManualDebit.
  ///
  /// In zh, this message translates to:
  /// **'人工扣款'**
  String get financeDashboardLedgerBizManualDebit;

  /// No description provided for @financeDashboardLedgerBizStaminaPurchase.
  ///
  /// In zh, this message translates to:
  /// **'购买体力费'**
  String get financeDashboardLedgerBizStaminaPurchase;

  /// No description provided for @financeDashboardLedgerBizSynthesisUpgrade.
  ///
  /// In zh, this message translates to:
  /// **'合成升级费'**
  String get financeDashboardLedgerBizSynthesisUpgrade;

  /// No description provided for @financeDashboardLedgerBizTransactionFee.
  ///
  /// In zh, this message translates to:
  /// **'手续费'**
  String get financeDashboardLedgerBizTransactionFee;

  /// No description provided for @financeDashboardRecentUsdcLedger.
  ///
  /// In zh, this message translates to:
  /// **'近期 {currency} 收入流水'**
  String financeDashboardRecentUsdcLedger(String currency);

  /// No description provided for @financeDashboardViewMore.
  ///
  /// In zh, this message translates to:
  /// **'查看更多'**
  String get financeDashboardViewMore;

  /// No description provided for @financeDashboardTotalVaultFunds.
  ///
  /// In zh, this message translates to:
  /// **'总资金'**
  String get financeDashboardTotalVaultFunds;

  /// No description provided for @financeDashboardCoveredActorIp.
  ///
  /// In zh, this message translates to:
  /// **'覆盖角色IP'**
  String get financeDashboardCoveredActorIp;

  /// No description provided for @financeDashboardActorVaultRanking.
  ///
  /// In zh, this message translates to:
  /// **'角色IP金库排行'**
  String get financeDashboardActorVaultRanking;

  /// No description provided for @storyReleaseTabAllocation.
  ///
  /// In zh, this message translates to:
  /// **'STORY 总量分配'**
  String get storyReleaseTabAllocation;

  /// No description provided for @storyReleaseTabMiningRelease.
  ///
  /// In zh, this message translates to:
  /// **'近期挖矿释放'**
  String get storyReleaseTabMiningRelease;

  /// No description provided for @storyReleaseFieldPeriod.
  ///
  /// In zh, this message translates to:
  /// **'周期'**
  String get storyReleaseFieldPeriod;

  /// No description provided for @storyReleaseFieldHardLimit.
  ///
  /// In zh, this message translates to:
  /// **'周硬顶'**
  String get storyReleaseFieldHardLimit;

  /// No description provided for @storyReleaseFieldMiningRewards.
  ///
  /// In zh, this message translates to:
  /// **'质押挖矿'**
  String get storyReleaseFieldMiningRewards;

  /// No description provided for @storyReleaseFieldInviteRewards.
  ///
  /// In zh, this message translates to:
  /// **'邀请挖矿'**
  String get storyReleaseFieldInviteRewards;

  /// No description provided for @storyReleaseFieldUsageRate.
  ///
  /// In zh, this message translates to:
  /// **'使用率'**
  String get storyReleaseFieldUsageRate;

  /// No description provided for @storyReleaseFieldTarget.
  ///
  /// In zh, this message translates to:
  /// **'分配对象'**
  String get storyReleaseFieldTarget;

  /// No description provided for @storyReleaseFieldRatio.
  ///
  /// In zh, this message translates to:
  /// **'比例'**
  String get storyReleaseFieldRatio;

  /// No description provided for @storyReleaseFieldAmount.
  ///
  /// In zh, this message translates to:
  /// **'数量'**
  String get storyReleaseFieldAmount;

  /// No description provided for @storyReleaseFieldReleased.
  ///
  /// In zh, this message translates to:
  /// **'已释放'**
  String get storyReleaseFieldReleased;

  /// No description provided for @storyReleaseFieldProgress.
  ///
  /// In zh, this message translates to:
  /// **'释放进度'**
  String get storyReleaseFieldProgress;

  /// No description provided for @storyReleaseCategoryNftMiningPool.
  ///
  /// In zh, this message translates to:
  /// **'NFT 挖矿池'**
  String get storyReleaseCategoryNftMiningPool;

  /// No description provided for @storyReleaseCategoryTeam.
  ///
  /// In zh, this message translates to:
  /// **'团队'**
  String get storyReleaseCategoryTeam;

  /// No description provided for @storyReleaseCategoryInvestors.
  ///
  /// In zh, this message translates to:
  /// **'投资人'**
  String get storyReleaseCategoryInvestors;

  /// No description provided for @storyReleaseCategoryLiquidity.
  ///
  /// In zh, this message translates to:
  /// **'Launchpad + 流动性'**
  String get storyReleaseCategoryLiquidity;

  /// No description provided for @storyReleaseCategoryTreasury.
  ///
  /// In zh, this message translates to:
  /// **'国库'**
  String get storyReleaseCategoryTreasury;

  /// No description provided for @storyReleaseCategoryMarketOps.
  ///
  /// In zh, this message translates to:
  /// **'市场运营'**
  String get storyReleaseCategoryMarketOps;

  /// No description provided for @storyReleaseTotalSupplyBadge.
  ///
  /// In zh, this message translates to:
  /// **'总量 {total} STORY'**
  String storyReleaseTotalSupplyBadge(String total);

  /// No description provided for @drawerWhitepaper.
  ///
  /// In zh, this message translates to:
  /// **'白皮书'**
  String get drawerWhitepaper;

  /// No description provided for @drawerSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get drawerSettings;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get commonLoadFailed;

  /// No description provided for @commonNone.
  ///
  /// In zh, this message translates to:
  /// **'未命名'**
  String get commonNone;

  /// No description provided for @commonUntitled.
  ///
  /// In zh, this message translates to:
  /// **'未命名'**
  String get commonUntitled;

  /// No description provided for @actorDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'演员主页'**
  String get actorDetailTitle;

  /// No description provided for @actorDetailCastDramas.
  ///
  /// In zh, this message translates to:
  /// **'参演短剧'**
  String get actorDetailCastDramas;

  /// No description provided for @actorDetailTabCast.
  ///
  /// In zh, this message translates to:
  /// **'参演'**
  String get actorDetailTabCast;

  /// No description provided for @actorDetailTabInfo.
  ///
  /// In zh, this message translates to:
  /// **'信息'**
  String get actorDetailTabInfo;

  /// No description provided for @actorDetailNoCastRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无参演记录'**
  String get actorDetailNoCastRecords;

  /// No description provided for @actorBondingCurve.
  ///
  /// In zh, this message translates to:
  /// **'价格联合曲线'**
  String get actorBondingCurve;

  /// No description provided for @actorContractAddress.
  ///
  /// In zh, this message translates to:
  /// **'合约地址'**
  String get actorContractAddress;

  /// No description provided for @actorCurrentPosition.
  ///
  /// In zh, this message translates to:
  /// **'当前位置'**
  String get actorCurrentPosition;

  /// No description provided for @actorCurrentPrice.
  ///
  /// In zh, this message translates to:
  /// **'当前价格 {price} {currency}'**
  String actorCurrentPrice(String price, String currency);

  /// No description provided for @actorFloorPrice.
  ///
  /// In zh, this message translates to:
  /// **'地板价'**
  String get actorFloorPrice;

  /// No description provided for @actorGoTrade.
  ///
  /// In zh, this message translates to:
  /// **'去交易'**
  String get actorGoTrade;

  /// No description provided for @profileWalletTrade.
  ///
  /// In zh, this message translates to:
  /// **'交易'**
  String get profileWalletTrade;

  /// No description provided for @actorHeatCoefficient.
  ///
  /// In zh, this message translates to:
  /// **'热度系数'**
  String get actorHeatCoefficient;

  /// No description provided for @actorIpPower.
  ///
  /// In zh, this message translates to:
  /// **'IP片酬'**
  String get actorIpPower;

  /// No description provided for @actorPayMax.
  ///
  /// In zh, this message translates to:
  /// **'最高'**
  String get actorPayMax;

  /// No description provided for @actorPayUpgradeTitle.
  ///
  /// In zh, this message translates to:
  /// **'片酬升级规则'**
  String get actorPayUpgradeTitle;

  /// No description provided for @actorPayUpgradeReachHint.
  ///
  /// In zh, this message translates to:
  /// **'该IP参演短剧的当前完播数可支持角色升级至'**
  String get actorPayUpgradeReachHint;

  /// No description provided for @actorPayUpgradeCompletions.
  ///
  /// In zh, this message translates to:
  /// **'{count} 完播'**
  String actorPayUpgradeCompletions(String count);

  /// No description provided for @actorPayUpgradeMultiplier.
  ///
  /// In zh, this message translates to:
  /// **'片酬 ×{value}'**
  String actorPayUpgradeMultiplier(String value);

  /// No description provided for @actorPayTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 片酬'**
  String actorPayTitle(String name);

  /// No description provided for @actorLv1PayHint.
  ///
  /// In zh, this message translates to:
  /// **'签约即可获得Lv.1角色'**
  String get actorLv1PayHint;

  /// No description provided for @actorLv1PayFormula.
  ///
  /// In zh, this message translates to:
  /// **'Lv.1片酬=价格系数×热度系数'**
  String get actorLv1PayFormula;

  /// No description provided for @actorLv1PayEquals.
  ///
  /// In zh, this message translates to:
  /// **'={value}'**
  String actorLv1PayEquals(String value);

  /// No description provided for @actorIpPowerTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} · IP片酬'**
  String actorIpPowerTitle(String name);

  /// No description provided for @actorIpPowerFormula.
  ///
  /// In zh, this message translates to:
  /// **'IP片酬 = 价格系数 × 热度系数 × Trust1'**
  String get actorIpPowerFormula;

  /// No description provided for @actorPriceCoefficient.
  ///
  /// In zh, this message translates to:
  /// **'价格系数'**
  String get actorPriceCoefficient;

  /// No description provided for @actorPriceCoefficientValue.
  ///
  /// In zh, this message translates to:
  /// **'价格系数 {value}'**
  String actorPriceCoefficientValue(String value);

  /// No description provided for @actorPriceCoefficientHelpA11y.
  ///
  /// In zh, this message translates to:
  /// **'查看价格系数说明'**
  String get actorPriceCoefficientHelpA11y;

  /// No description provided for @actorPriceUnitName.
  ///
  /// In zh, this message translates to:
  /// **'点数'**
  String get actorPriceUnitName;

  /// No description provided for @actorPriceCoefficientDialogFormulaLe100.
  ///
  /// In zh, this message translates to:
  /// **'系数 = P0 ÷ 10'**
  String get actorPriceCoefficientDialogFormulaLe100;

  /// No description provided for @actorPriceCoefficientDialogDescLe100.
  ///
  /// In zh, this message translates to:
  /// **'线性增长'**
  String get actorPriceCoefficientDialogDescLe100;

  /// No description provided for @actorPriceCoefficientDialogTitleGt100.
  ///
  /// In zh, this message translates to:
  /// **'P0 > 10 {currency}'**
  String actorPriceCoefficientDialogTitleGt100(String currency);

  /// No description provided for @actorPriceCoefficientDialogFormulaGt100.
  ///
  /// In zh, this message translates to:
  /// **'系数 = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]'**
  String get actorPriceCoefficientDialogFormulaGt100;

  /// No description provided for @actorPriceCoefficientDialogDescGt100.
  ///
  /// In zh, this message translates to:
  /// **'增速渐缓，上限 1.6'**
  String get actorPriceCoefficientDialogDescGt100;

  /// No description provided for @actorPriceCoefficientDialogTitleLe100.
  ///
  /// In zh, this message translates to:
  /// **'P0 ≤ 10 {currency}'**
  String actorPriceCoefficientDialogTitleLe100(String currency);

  /// No description provided for @actorPriceCoefficientFactorDesc.
  ///
  /// In zh, this message translates to:
  /// **'P0 ≤ 10 {currency1} 系数= P0/10（线性增长）\nP0 > 10 {currency2} → 系数 = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]（渐近上限 1.6）'**
  String actorPriceCoefficientFactorDesc(String currency1, String currency2);

  /// No description provided for @actorHeatCoefficientFactorDesc.
  ///
  /// In zh, this message translates to:
  /// **'角色IP 近30天热度乘子，取决于短剧完播、点赞、收藏等互动表现'**
  String get actorHeatCoefficientFactorDesc;

  /// No description provided for @actorTrustFactorDesc.
  ///
  /// In zh, this message translates to:
  /// **'平台风控系数，默认值为 1.0'**
  String get actorTrustFactorDesc;

  /// No description provided for @actorStatCompletion.
  ///
  /// In zh, this message translates to:
  /// **'完播'**
  String get actorStatCompletion;

  /// No description provided for @actorIdCopied.
  ///
  /// In zh, this message translates to:
  /// **'编号已复制'**
  String get actorIdCopied;

  /// No description provided for @actorInitialPrice.
  ///
  /// In zh, this message translates to:
  /// **'初始价格：{price} {currency}'**
  String actorInitialPrice(String price, String currency);

  /// No description provided for @actorIpLabel.
  ///
  /// In zh, this message translates to:
  /// **'演员 IP {label}'**
  String actorIpLabel(String label);

  /// No description provided for @actorIssueInfo.
  ///
  /// In zh, this message translates to:
  /// **'发行信息'**
  String get actorIssueInfo;

  /// No description provided for @actorIssuer.
  ///
  /// In zh, this message translates to:
  /// **'发行者 {name}'**
  String actorIssuer(String name);

  /// No description provided for @actorMintedCount.
  ///
  /// In zh, this message translates to:
  /// **'已铸造 {minted}/{maxSupply}'**
  String actorMintedCount(int minted, int maxSupply);

  /// No description provided for @actorPriceCurve.
  ///
  /// In zh, this message translates to:
  /// **'价格曲线'**
  String get actorPriceCurve;

  /// No description provided for @actorSign.
  ///
  /// In zh, this message translates to:
  /// **'签约'**
  String get actorSign;

  /// No description provided for @actorConfirmSign.
  ///
  /// In zh, this message translates to:
  /// **'确认签约'**
  String get actorConfirmSign;

  /// No description provided for @actorSignPriceLabel.
  ///
  /// In zh, this message translates to:
  /// **'签约价格'**
  String get actorSignPriceLabel;

  /// No description provided for @actorSignPriceDescription.
  ///
  /// In zh, this message translates to:
  /// **'签约价格随已签约数自动上涨，早期签约更优惠'**
  String get actorSignPriceDescription;

  /// No description provided for @actorSignPriceFormula.
  ///
  /// In zh, this message translates to:
  /// **'公式：价格 = 初始价格 × 5^(已签约数 ÷ 发行总量)'**
  String get actorSignPriceFormula;

  /// No description provided for @actorPriceAxisLabel.
  ///
  /// In zh, this message translates to:
  /// **'价格（{currency}）'**
  String actorPriceAxisLabel(String currency);

  /// No description provided for @actorSignedCountAxisLabel.
  ///
  /// In zh, this message translates to:
  /// **'已签约数'**
  String get actorSignedCountAxisLabel;

  /// No description provided for @actorSignRemainingCount.
  ///
  /// In zh, this message translates to:
  /// **'剩余{count}个'**
  String actorSignRemainingCount(int count);

  /// No description provided for @actorSignSoldOut.
  ///
  /// In zh, this message translates to:
  /// **'已售罄'**
  String get actorSignSoldOut;

  /// No description provided for @actorSignSupplySummary.
  ///
  /// In zh, this message translates to:
  /// **'总发行 {total} · 剩余 {remaining}'**
  String actorSignSupplySummary(String total, String remaining);

  /// No description provided for @actorPricingFixed.
  ///
  /// In zh, this message translates to:
  /// **'固定价格'**
  String get actorPricingFixed;

  /// No description provided for @actorPricingCurve.
  ///
  /// In zh, this message translates to:
  /// **'曲线价格'**
  String get actorPricingCurve;

  /// No description provided for @actorPriceCurveDisclaimer.
  ///
  /// In zh, this message translates to:
  /// **'初始价格不代表平台估值，曲线上涨不代表二级价格上涨，平台不承诺收益。'**
  String get actorPriceCurveDisclaimer;

  /// No description provided for @actorPriceStatInitialPrice.
  ///
  /// In zh, this message translates to:
  /// **'初始价格'**
  String get actorPriceStatInitialPrice;

  /// No description provided for @actorPriceStatCurrentPrice.
  ///
  /// In zh, this message translates to:
  /// **'当前价格'**
  String get actorPriceStatCurrentPrice;

  /// No description provided for @actorPriceStatTailPrice.
  ///
  /// In zh, this message translates to:
  /// **'尾价'**
  String get actorPriceStatTailPrice;

  /// No description provided for @actorPriceStatTotalSupply.
  ///
  /// In zh, this message translates to:
  /// **'总发行量'**
  String get actorPriceStatTotalSupply;

  /// No description provided for @actorPriceStatSigned.
  ///
  /// In zh, this message translates to:
  /// **'已签约'**
  String get actorPriceStatSigned;

  /// No description provided for @actorPriceStatRemaining.
  ///
  /// In zh, this message translates to:
  /// **'剩余'**
  String get actorPriceStatRemaining;

  /// No description provided for @actorPricingType.
  ///
  /// In zh, this message translates to:
  /// **'定价类型'**
  String get actorPricingType;

  /// No description provided for @contentBadgeOfficialIssue.
  ///
  /// In zh, this message translates to:
  /// **'官方发行'**
  String get contentBadgeOfficialIssue;

  /// No description provided for @contentBadgeCommunityIssue.
  ///
  /// In zh, this message translates to:
  /// **'社区发行'**
  String get contentBadgeCommunityIssue;

  /// No description provided for @contentBadgePartnerIssue.
  ///
  /// In zh, this message translates to:
  /// **'合作方发行'**
  String get contentBadgePartnerIssue;

  /// No description provided for @contentBadgeVerifiedIssue.
  ///
  /// In zh, this message translates to:
  /// **'认证创作者发行'**
  String get contentBadgeVerifiedIssue;

  /// No description provided for @contentBadgeOfficialDrama.
  ///
  /// In zh, this message translates to:
  /// **'官方短剧'**
  String get contentBadgeOfficialDrama;

  /// No description provided for @contentBadgeCommunityDrama.
  ///
  /// In zh, this message translates to:
  /// **'社区短剧'**
  String get contentBadgeCommunityDrama;

  /// No description provided for @contentBadgePartnerDrama.
  ///
  /// In zh, this message translates to:
  /// **'合作方短剧'**
  String get contentBadgePartnerDrama;

  /// No description provided for @contentBadgeVerifiedDrama.
  ///
  /// In zh, this message translates to:
  /// **'认证创作者短剧'**
  String get contentBadgeVerifiedDrama;

  /// No description provided for @actorIpCopied.
  ///
  /// In zh, this message translates to:
  /// **'复制成功'**
  String get actorIpCopied;

  /// No description provided for @actorRiskIp.
  ///
  /// In zh, this message translates to:
  /// **'风险IP'**
  String get actorRiskIp;

  /// No description provided for @actorRiskIpDescription.
  ///
  /// In zh, this message translates to:
  /// **'该角色IP信任系数异常，挖矿权重将受影响。'**
  String get actorRiskIpDescription;

  /// No description provided for @actorIpVault.
  ///
  /// In zh, this message translates to:
  /// **'角色IP金库'**
  String get actorIpVault;

  /// No description provided for @actorIpVaultDescription.
  ///
  /// In zh, this message translates to:
  /// **'签约收入的 30% 自动沉淀至角色IP金库，用于支撑 IP 生态的长期发展。二级市场版税收入的 30% 同样归入金库，形成持续资金蓄水池。V1 版本金库仅提供数据展示，暂不开放分配。'**
  String get actorIpVaultDescription;

  /// No description provided for @actorIpVaultSignIncomePrefix.
  ///
  /// In zh, this message translates to:
  /// **'签约收入 · 沉淀 '**
  String get actorIpVaultSignIncomePrefix;

  /// No description provided for @actorIpVaultSecondaryRoyaltyPrefix.
  ///
  /// In zh, this message translates to:
  /// **'二级版税 · 沉淀 '**
  String get actorIpVaultSecondaryRoyaltyPrefix;

  /// No description provided for @actorFixedPriceDialogDesc.
  ///
  /// In zh, this message translates to:
  /// **'该角色IP采用固定价格模式，每个角色都以统一价格签约，销量变化不影响价格'**
  String get actorFixedPriceDialogDesc;

  /// No description provided for @actorCurvePriceDialogDesc.
  ///
  /// In zh, this message translates to:
  /// **'价格按联合曲线公式随已签约数自动上涨，早期签约更优惠'**
  String get actorCurvePriceDialogDesc;

  /// No description provided for @actorFixedPriceNote1.
  ///
  /// In zh, this message translates to:
  /// **'发行者设定固定价格后，所有签约均按此价格结算'**
  String get actorFixedPriceNote1;

  /// No description provided for @actorFixedPriceNote2.
  ///
  /// In zh, this message translates to:
  /// **'不会因已签约数增加而价格上涨'**
  String get actorFixedPriceNote2;

  /// No description provided for @actorFixedPriceNote3.
  ///
  /// In zh, this message translates to:
  /// **'适合希望锁定成本的买家'**
  String get actorFixedPriceNote3;

  /// No description provided for @actorIssueFixedPriceDesc.
  ///
  /// In zh, this message translates to:
  /// **'该角色IP采用固定价格模式，所有签约均按固定价格结算，不随销量变化。'**
  String get actorIssueFixedPriceDesc;

  /// No description provided for @actorSignSlippageNote.
  ///
  /// In zh, this message translates to:
  /// **'已开启 1% 滑点保护，价格超出时将取消交易'**
  String get actorSignSlippageNote;

  /// No description provided for @actorSignSuccessTitle.
  ///
  /// In zh, this message translates to:
  /// **'签约成功！'**
  String get actorSignSuccessTitle;

  /// No description provided for @actorSignSuccessMessage.
  ///
  /// In zh, this message translates to:
  /// **'角色「{name}」签约成功'**
  String actorSignSuccessMessage(String name);

  /// No description provided for @actorSignSuccessNftId.
  ///
  /// In zh, this message translates to:
  /// **'NFT编号：{nftId}'**
  String actorSignSuccessNftId(String nftId);

  /// No description provided for @actorSignChainConfigMissing.
  ///
  /// In zh, this message translates to:
  /// **'链上配置不完整，请稍后重试'**
  String get actorSignChainConfigMissing;

  /// No description provided for @actorSignPriceSoldOut.
  ///
  /// In zh, this message translates to:
  /// **'签约价格 · 已售罄'**
  String get actorSignPriceSoldOut;

  /// No description provided for @actorSignPriceRemaining.
  ///
  /// In zh, this message translates to:
  /// **'签约价格 · 剩余{count}个'**
  String actorSignPriceRemaining(int count);

  /// No description provided for @actorSignedCount.
  ///
  /// In zh, this message translates to:
  /// **'已签约 {count}'**
  String actorSignedCount(int count);

  /// No description provided for @actorStatusLabelOffline.
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get actorStatusLabelOffline;

  /// No description provided for @actorStatusLabelOnline.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get actorStatusLabelOnline;

  /// No description provided for @actorStatusLabelPending.
  ///
  /// In zh, this message translates to:
  /// **'审核中'**
  String get actorStatusLabelPending;

  /// No description provided for @actorStatusLabelRejected.
  ///
  /// In zh, this message translates to:
  /// **'已拒绝'**
  String get actorStatusLabelRejected;

  /// No description provided for @actorTotalSupply.
  ///
  /// In zh, this message translates to:
  /// **'发行总量'**
  String get actorTotalSupply;

  /// No description provided for @commentsAnonymous.
  ///
  /// In zh, this message translates to:
  /// **'匿名用户'**
  String get commentsAnonymous;

  /// No description provided for @commentsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无评论'**
  String get commentsEmpty;

  /// No description provided for @commentsHint.
  ///
  /// In zh, this message translates to:
  /// **'发布精彩评论...'**
  String get commentsHint;

  /// No description provided for @commentsInvalidContent.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效内容'**
  String get commentsInvalidContent;

  /// No description provided for @commentsReply.
  ///
  /// In zh, this message translates to:
  /// **'回复'**
  String get commentsReply;

  /// No description provided for @commentsViewReplies.
  ///
  /// In zh, this message translates to:
  /// **'查看 {count} 条回复'**
  String commentsViewReplies(int count);

  /// No description provided for @commentsCollapseReplies.
  ///
  /// In zh, this message translates to:
  /// **'收起'**
  String get commentsCollapseReplies;

  /// No description provided for @commentsViewMoreReplies.
  ///
  /// In zh, this message translates to:
  /// **'展开更多'**
  String get commentsViewMoreReplies;

  /// No description provided for @commentsReplyHint.
  ///
  /// In zh, this message translates to:
  /// **'回复 {nickname}'**
  String commentsReplyHint(String nickname);

  /// No description provided for @commentsDeleteCommentTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这条评论？'**
  String get commentsDeleteCommentTitle;

  /// No description provided for @commentsDeleteReplyTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除这条回复？'**
  String get commentsDeleteReplyTitle;

  /// No description provided for @commentTagAuthor.
  ///
  /// In zh, this message translates to:
  /// **'作者'**
  String get commentTagAuthor;

  /// No description provided for @commentTagMe.
  ///
  /// In zh, this message translates to:
  /// **'我'**
  String get commentTagMe;

  /// No description provided for @commentTagFriend.
  ///
  /// In zh, this message translates to:
  /// **'你的好友'**
  String get commentTagFriend;

  /// No description provided for @commentTagFan.
  ///
  /// In zh, this message translates to:
  /// **'你的粉丝'**
  String get commentTagFan;

  /// No description provided for @commentTagFirst.
  ///
  /// In zh, this message translates to:
  /// **'首评'**
  String get commentTagFirst;

  /// No description provided for @commentTagAuthorLiked.
  ///
  /// In zh, this message translates to:
  /// **'作者赞过'**
  String get commentTagAuthorLiked;

  /// No description provided for @commentsReplyTo.
  ///
  /// In zh, this message translates to:
  /// **'回复 @{nickname}：'**
  String commentsReplyTo(String nickname);

  /// No description provided for @commentsReplyCommentNotExists.
  ///
  /// In zh, this message translates to:
  /// **'评论不存在'**
  String get commentsReplyCommentNotExists;

  /// No description provided for @commentsBlockedByMe.
  ///
  /// In zh, this message translates to:
  /// **'黑名单用户，无法评论'**
  String get commentsBlockedByMe;

  /// No description provided for @commentsBlockedByTarget.
  ///
  /// In zh, this message translates to:
  /// **'由于对方设置，你无法评论TA'**
  String get commentsBlockedByTarget;

  /// No description provided for @commentsTabComments.
  ///
  /// In zh, this message translates to:
  /// **'评论'**
  String get commentsTabComments;

  /// No description provided for @commentsTabAllComments.
  ///
  /// In zh, this message translates to:
  /// **'全部评论'**
  String get commentsTabAllComments;

  /// No description provided for @commentsTabDramas.
  ///
  /// In zh, this message translates to:
  /// **'短剧'**
  String get commentsTabDramas;

  /// No description provided for @commentsTabActors.
  ///
  /// In zh, this message translates to:
  /// **'角色'**
  String get commentsTabActors;

  /// No description provided for @timeJustNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get timeJustNow;

  /// No description provided for @timeYesterday.
  ///
  /// In zh, this message translates to:
  /// **'昨天'**
  String get timeYesterday;

  /// No description provided for @timeDayBeforeYesterday.
  ///
  /// In zh, this message translates to:
  /// **'前天'**
  String get timeDayBeforeYesterday;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count}分钟前'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count}小时前'**
  String timeHoursAgo(int count);

  /// No description provided for @timeDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{count}天前'**
  String timeDaysAgo(int count);

  /// No description provided for @commentsTitle.
  ///
  /// In zh, this message translates to:
  /// **'评论 ({count})'**
  String commentsTitle(int count);

  /// No description provided for @createActorTitle.
  ///
  /// In zh, this message translates to:
  /// **'创建角色'**
  String get createActorTitle;

  /// No description provided for @createActorHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'铸造角色 NFT'**
  String get createActorHeroTitle;

  /// No description provided for @createActorHeroSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'创建专属 AI 角色，绑定分润参与短剧'**
  String get createActorHeroSubtitle;

  /// No description provided for @createActorNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'角色名称'**
  String get createActorNameLabel;

  /// No description provided for @createActorNameHint.
  ///
  /// In zh, this message translates to:
  /// **'输入角色名称'**
  String get createActorNameHint;

  /// No description provided for @createActorBioLabel.
  ///
  /// In zh, this message translates to:
  /// **'角色简介'**
  String get createActorBioLabel;

  /// No description provided for @createActorBioHint.
  ///
  /// In zh, this message translates to:
  /// **'描述角色背景'**
  String get createActorBioHint;

  /// No description provided for @createActorGenderLabel.
  ///
  /// In zh, this message translates to:
  /// **'性别'**
  String get createActorGenderLabel;

  /// No description provided for @createActorGenderMale.
  ///
  /// In zh, this message translates to:
  /// **'男'**
  String get createActorGenderMale;

  /// No description provided for @createActorGenderFemale.
  ///
  /// In zh, this message translates to:
  /// **'女'**
  String get createActorGenderFemale;

  /// No description provided for @createActorMintParams.
  ///
  /// In zh, this message translates to:
  /// **'NFT 铸造参数'**
  String get createActorMintParams;

  /// No description provided for @createActorTokenStandard.
  ///
  /// In zh, this message translates to:
  /// **'Token 标准'**
  String get createActorTokenStandard;

  /// No description provided for @createActorChain.
  ///
  /// In zh, this message translates to:
  /// **'链'**
  String get createActorChain;

  /// No description provided for @createActorMinHolding.
  ///
  /// In zh, this message translates to:
  /// **'最低持仓门槛'**
  String get createActorMinHolding;

  /// No description provided for @createActorMintNft.
  ///
  /// In zh, this message translates to:
  /// **'铸造 NFT'**
  String get createActorMintNft;

  /// No description provided for @createActorIpTitle.
  ///
  /// In zh, this message translates to:
  /// **'发行角色 IP'**
  String get createActorIpTitle;

  /// No description provided for @createActorIpSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'发行一个角色 IP 之后可在该 IP 下签约角色，角色可派遣产生收益。'**
  String get createActorIpSubtitle;

  /// No description provided for @createActorSelectMaterial.
  ///
  /// In zh, this message translates to:
  /// **'选择角色素材'**
  String get createActorSelectMaterial;

  /// No description provided for @createActorDreamOsBadge.
  ///
  /// In zh, this message translates to:
  /// **'前往 DreamOS'**
  String get createActorDreamOsBadge;

  /// No description provided for @createActorSelectMaterialDesc.
  ///
  /// In zh, this message translates to:
  /// **'进入DreamOS项目 → 创建角色 → 进入StoryFun发行 IP'**
  String get createActorSelectMaterialDesc;

  /// No description provided for @createActorSelectButton.
  ///
  /// In zh, this message translates to:
  /// **'选择角色'**
  String get createActorSelectButton;

  /// No description provided for @createActorNameLabelNew.
  ///
  /// In zh, this message translates to:
  /// **'角色姓名'**
  String get createActorNameLabelNew;

  /// No description provided for @createActorNamePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'输入角色姓名'**
  String get createActorNamePlaceholder;

  /// No description provided for @createActorBioLabelNew.
  ///
  /// In zh, this message translates to:
  /// **'简介'**
  String get createActorBioLabelNew;

  /// No description provided for @createActorBioPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'请输入角色 IP 介绍'**
  String get createActorBioPlaceholder;

  /// No description provided for @createActorParamsTitle.
  ///
  /// In zh, this message translates to:
  /// **'角色 IP 发行参数'**
  String get createActorParamsTitle;

  /// No description provided for @createActorParamsSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'设定角色 IP 的发行参数，发行后不可修改。'**
  String get createActorParamsSubtitle;

  /// No description provided for @createActorTotalSupplyLabel.
  ///
  /// In zh, this message translates to:
  /// **'角色发行总量'**
  String get createActorTotalSupplyLabel;

  /// No description provided for @createActorTotalSupplyDesc.
  ///
  /// In zh, this message translates to:
  /// **'发行总量范围为 100 - 5,000。'**
  String get createActorTotalSupplyDesc;

  /// No description provided for @createActorTotalSupplyPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'100 - 5,000'**
  String get createActorTotalSupplyPlaceholder;

  /// No description provided for @createActorPricingFixed.
  ///
  /// In zh, this message translates to:
  /// **'固定价格'**
  String get createActorPricingFixed;

  /// No description provided for @createActorPricingCurve.
  ///
  /// In zh, this message translates to:
  /// **'曲线价格'**
  String get createActorPricingCurve;

  /// No description provided for @createActorFixedPriceLabel.
  ///
  /// In zh, this message translates to:
  /// **'固定价格（{currency}）'**
  String createActorFixedPriceLabel(String currency);

  /// No description provided for @createActorInitialPriceLabel.
  ///
  /// In zh, this message translates to:
  /// **'初始价格（{currency}）'**
  String createActorInitialPriceLabel(String currency);

  /// No description provided for @createActorFixedPricePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'10 - 1,000'**
  String get createActorFixedPricePlaceholder;

  /// No description provided for @createActorFixedPriceDesc.
  ///
  /// In zh, this message translates to:
  /// **'每个角色都以固定不变的价格购买，不会随销量变化。'**
  String get createActorFixedPriceDesc;

  /// No description provided for @createActorInitialPricePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'10 - 1,000'**
  String get createActorInitialPricePlaceholder;

  /// No description provided for @createActorInitialPriceDesc.
  ///
  /// In zh, this message translates to:
  /// **'初始价格为联合曲线起始价，每签约一个角色，价格按公式 P = P₀ × 5^(已签约数/发行总量) 自动上涨，早期签约更优惠。'**
  String get createActorInitialPriceDesc;

  /// No description provided for @createActorFormIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'请先完成角色素材、姓名、简介和发行参数填写'**
  String get createActorFormIncomplete;

  /// No description provided for @createActorValidationNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入角色姓名'**
  String get createActorValidationNameRequired;

  /// No description provided for @createActorValidationNameTooLong.
  ///
  /// In zh, this message translates to:
  /// **'角色姓名不超过20字'**
  String get createActorValidationNameTooLong;

  /// No description provided for @createActorValidationBioRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入简介'**
  String get createActorValidationBioRequired;

  /// No description provided for @createActorValidationBioTooLong.
  ///
  /// In zh, this message translates to:
  /// **'简介不超过500字'**
  String get createActorValidationBioTooLong;

  /// No description provided for @createActorValidationTotalSupplyRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的NFT发行总量'**
  String get createActorValidationTotalSupplyRequired;

  /// No description provided for @createActorValidationTotalSupplyPositiveInteger.
  ///
  /// In zh, this message translates to:
  /// **'NFT发行总量须为正整数'**
  String get createActorValidationTotalSupplyPositiveInteger;

  /// No description provided for @createActorValidationTotalSupplyRange.
  ///
  /// In zh, this message translates to:
  /// **'角色发行总量须在100到5000之间'**
  String get createActorValidationTotalSupplyRange;

  /// No description provided for @createActorValidationPriceRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效的Mint价格'**
  String get createActorValidationPriceRequired;

  /// No description provided for @createActorValidationPriceInvalid.
  ///
  /// In zh, this message translates to:
  /// **'Mint价格须大于等于10且不超过1,000'**
  String get createActorValidationPriceInvalid;

  /// No description provided for @createActorValidationPriceMaxDecimals.
  ///
  /// In zh, this message translates to:
  /// **'Mint价格最多保留两位小数'**
  String get createActorValidationPriceMaxDecimals;

  /// No description provided for @createActorSelectMaterialRequired.
  ///
  /// In zh, this message translates to:
  /// **'请选择角色素材'**
  String get createActorSelectMaterialRequired;

  /// No description provided for @createActorCancelButton.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get createActorCancelButton;

  /// No description provided for @createActorConfirmButton.
  ///
  /// In zh, this message translates to:
  /// **'确定发行'**
  String get createActorConfirmButton;

  /// No description provided for @createActorIssueFee.
  ///
  /// In zh, this message translates to:
  /// **'手续费'**
  String get createActorIssueFee;

  /// No description provided for @createActorSuccessTitle.
  ///
  /// In zh, this message translates to:
  /// **'{name} · 发行成功！'**
  String createActorSuccessTitle(String name);

  /// No description provided for @createActorSuccessDesc.
  ///
  /// In zh, this message translates to:
  /// **'角色 IP {id}'**
  String createActorSuccessDesc(String id);

  /// No description provided for @createActorSuccessTip.
  ///
  /// In zh, this message translates to:
  /// **'发行者也需要签约才能获得该角色哦～'**
  String get createActorSuccessTip;

  /// No description provided for @createActorCloseButton.
  ///
  /// In zh, this message translates to:
  /// **'稍后再说'**
  String get createActorCloseButton;

  /// No description provided for @createActorViewButton.
  ///
  /// In zh, this message translates to:
  /// **'去签约'**
  String get createActorViewButton;

  /// No description provided for @createActorEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'您还没有在 DreamOS 中创建满足条件、由系统在 DreamOS 自动生成的 NFT 发行。'**
  String get createActorEmptyTitle;

  /// No description provided for @createActorGotoDreamOs.
  ///
  /// In zh, this message translates to:
  /// **'前往 DreamOS 创建'**
  String get createActorGotoDreamOs;

  /// No description provided for @createActorSearchPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'搜索角色素材'**
  String get createActorSearchPlaceholder;

  /// No description provided for @createActorInvalidOrderId.
  ///
  /// In zh, this message translates to:
  /// **'角色IP订单编号无效，请刷新后重试'**
  String get createActorInvalidOrderId;

  /// No description provided for @createDramaTitle.
  ///
  /// In zh, this message translates to:
  /// **'创建短剧'**
  String get createDramaTitle;

  /// No description provided for @createDramaTitleLabel.
  ///
  /// In zh, this message translates to:
  /// **'短剧标题'**
  String get createDramaTitleLabel;

  /// No description provided for @createDramaTitleHint.
  ///
  /// In zh, this message translates to:
  /// **'输入短剧名称'**
  String get createDramaTitleHint;

  /// No description provided for @createDramaSynopsisLabel.
  ///
  /// In zh, this message translates to:
  /// **'剧情简介'**
  String get createDramaSynopsisLabel;

  /// No description provided for @createDramaSynopsisHint.
  ///
  /// In zh, this message translates to:
  /// **'讲述一个什么样的故事...（最多1000字）'**
  String get createDramaSynopsisHint;

  /// No description provided for @createDramaAiSettings.
  ///
  /// In zh, this message translates to:
  /// **'AI 生成设置'**
  String get createDramaAiSettings;

  /// No description provided for @createDramaVisualStyle.
  ///
  /// In zh, this message translates to:
  /// **'画面风格'**
  String get createDramaVisualStyle;

  /// No description provided for @createDramaVisualStyleRealistic.
  ///
  /// In zh, this message translates to:
  /// **'写实'**
  String get createDramaVisualStyleRealistic;

  /// No description provided for @createDramaEpisodeDuration.
  ///
  /// In zh, this message translates to:
  /// **'每集时长'**
  String get createDramaEpisodeDuration;

  /// No description provided for @createDramaEpisodeDurationValue.
  ///
  /// In zh, this message translates to:
  /// **'3-5 分钟'**
  String get createDramaEpisodeDurationValue;

  /// No description provided for @createDramaTotalEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'总集数'**
  String get createDramaTotalEpisodes;

  /// No description provided for @createDramaTotalEpisodesValue.
  ///
  /// In zh, this message translates to:
  /// **'8 集'**
  String get createDramaTotalEpisodesValue;

  /// No description provided for @createDramaGenreLabel.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get createDramaGenreLabel;

  /// No description provided for @createDramaGenreDrama.
  ///
  /// In zh, this message translates to:
  /// **'剧情'**
  String get createDramaGenreDrama;

  /// No description provided for @createDramaGenreComedy.
  ///
  /// In zh, this message translates to:
  /// **'喜剧'**
  String get createDramaGenreComedy;

  /// No description provided for @createDramaGenreAction.
  ///
  /// In zh, this message translates to:
  /// **'动作'**
  String get createDramaGenreAction;

  /// No description provided for @createDramaGenreRomance.
  ///
  /// In zh, this message translates to:
  /// **'爱情'**
  String get createDramaGenreRomance;

  /// No description provided for @createDramaGenreSciFi.
  ///
  /// In zh, this message translates to:
  /// **'科幻'**
  String get createDramaGenreSciFi;

  /// No description provided for @createDramaGenreMystery.
  ///
  /// In zh, this message translates to:
  /// **'悬疑'**
  String get createDramaGenreMystery;

  /// No description provided for @createDramaGenreHorror.
  ///
  /// In zh, this message translates to:
  /// **'恐怖'**
  String get createDramaGenreHorror;

  /// No description provided for @createDramaGenreAnimation.
  ///
  /// In zh, this message translates to:
  /// **'动画'**
  String get createDramaGenreAnimation;

  /// No description provided for @createDramaHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 短剧创作'**
  String get createDramaHeroTitle;

  /// No description provided for @createDramaHeroSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'一键生成属于你的爆款短剧'**
  String get createDramaHeroSubtitle;

  /// No description provided for @createDramaStartGeneration.
  ///
  /// In zh, this message translates to:
  /// **'开始生成'**
  String get createDramaStartGeneration;

  /// No description provided for @creatorDramaManagementTab.
  ///
  /// In zh, this message translates to:
  /// **'短剧管理'**
  String get creatorDramaManagementTab;

  /// No description provided for @creatorDramaNftTab.
  ///
  /// In zh, this message translates to:
  /// **'短剧NFT'**
  String get creatorDramaNftTab;

  /// No description provided for @creatorHeaderSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'短剧的发布、审核与铸造。'**
  String get creatorHeaderSubtitle;

  /// No description provided for @creatorV2Subtitle.
  ///
  /// In zh, this message translates to:
  /// **'短剧/视频的发布与管理。'**
  String get creatorV2Subtitle;

  /// No description provided for @creatorV2DramaTabCount.
  ///
  /// In zh, this message translates to:
  /// **'短剧（{count}）'**
  String creatorV2DramaTabCount(int count);

  /// No description provided for @creatorV2VideoTabCount.
  ///
  /// In zh, this message translates to:
  /// **'视频（{count}）'**
  String creatorV2VideoTabCount(int count);

  /// No description provided for @creatorV2NoVideos.
  ///
  /// In zh, this message translates to:
  /// **'暂无视频'**
  String get creatorV2NoVideos;

  /// No description provided for @creatorLoginPrompt.
  ///
  /// In zh, this message translates to:
  /// **'登录后查看你的创作'**
  String get creatorLoginPrompt;

  /// No description provided for @creatorNoCreatedActors.
  ///
  /// In zh, this message translates to:
  /// **'暂无创建的角色'**
  String get creatorNoCreatedActors;

  /// No description provided for @creatorNoPublishedDramas.
  ///
  /// In zh, this message translates to:
  /// **'暂无发布的短剧'**
  String get creatorNoPublishedDramas;

  /// No description provided for @creatorOwnedNftCount.
  ///
  /// In zh, this message translates to:
  /// **'持有NFT数'**
  String get creatorOwnedNftCount;

  /// No description provided for @creatorCreateDrama.
  ///
  /// In zh, this message translates to:
  /// **'创作短剧'**
  String get creatorCreateDrama;

  /// No description provided for @creatorPublishNewDrama.
  ///
  /// In zh, this message translates to:
  /// **'发布新短剧'**
  String get creatorPublishNewDrama;

  /// No description provided for @creatorPublishedDramas.
  ///
  /// In zh, this message translates to:
  /// **'发布短剧'**
  String get creatorPublishedDramas;

  /// No description provided for @creatorReviewFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get creatorReviewFilterAll;

  /// No description provided for @creatorReviewFilterApproved.
  ///
  /// In zh, this message translates to:
  /// **'已通过'**
  String get creatorReviewFilterApproved;

  /// No description provided for @creatorReviewFilterPending.
  ///
  /// In zh, this message translates to:
  /// **'审核中'**
  String get creatorReviewFilterPending;

  /// No description provided for @creatorReviewFilterRejected.
  ///
  /// In zh, this message translates to:
  /// **'未通过'**
  String get creatorReviewFilterRejected;

  /// No description provided for @creatorReviewFilterOffline.
  ///
  /// In zh, this message translates to:
  /// **'已下架'**
  String get creatorReviewFilterOffline;

  /// No description provided for @creatorDramaOtherReason.
  ///
  /// In zh, this message translates to:
  /// **'其他原因'**
  String get creatorDramaOtherReason;

  /// No description provided for @creatorDramaStatusOnline.
  ///
  /// In zh, this message translates to:
  /// **'已通过'**
  String get creatorDramaStatusOnline;

  /// No description provided for @creatorDramaStatusPendingReview.
  ///
  /// In zh, this message translates to:
  /// **'等待审核'**
  String get creatorDramaStatusPendingReview;

  /// No description provided for @creatorDramaStatusReviewRejected.
  ///
  /// In zh, this message translates to:
  /// **'未通过'**
  String get creatorDramaStatusReviewRejected;

  /// No description provided for @creatorDramaStatusPendingOnline.
  ///
  /// In zh, this message translates to:
  /// **'待上线'**
  String get creatorDramaStatusPendingOnline;

  /// No description provided for @creatorDramaAuditReason.
  ///
  /// In zh, this message translates to:
  /// **'未通过审核原因：{reason}'**
  String creatorDramaAuditReason(Object reason);

  /// No description provided for @creatorDramaNftMinted.
  ///
  /// In zh, this message translates to:
  /// **'已铸造'**
  String get creatorDramaNftMinted;

  /// No description provided for @creatorDramaEpisodeCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 集'**
  String creatorDramaEpisodeCount(int count);

  /// No description provided for @creatorDramaEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get creatorDramaEdit;

  /// No description provided for @creatorDramaDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get creatorDramaDelete;

  /// No description provided for @creatorActorDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除角色'**
  String get creatorActorDelete;

  /// No description provided for @creatorDeleteDramaConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除该短剧吗？'**
  String get creatorDeleteDramaConfirm;

  /// No description provided for @creatorDeleteVideoConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除视频确认'**
  String get creatorDeleteVideoConfirmTitle;

  /// No description provided for @creatorDeleteVideoConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'您确定要删除 “{name}” 吗？\n此操作无法撤销'**
  String creatorDeleteVideoConfirmMessage(String name);

  /// No description provided for @creatorDeleteActorConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除该角色吗？'**
  String get creatorDeleteActorConfirm;

  /// No description provided for @creatorDeleting.
  ///
  /// In zh, this message translates to:
  /// **'删除中...'**
  String get creatorDeleting;

  /// No description provided for @creatorNoDramas.
  ///
  /// In zh, this message translates to:
  /// **'暂无短剧'**
  String get creatorNoDramas;

  /// No description provided for @creatorNoNfts.
  ///
  /// In zh, this message translates to:
  /// **'暂无短剧NFT'**
  String get creatorNoNfts;

  /// No description provided for @creatorsComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'创作者目录即将上线'**
  String get creatorsComingSoon;

  /// No description provided for @creatorsHeroSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'发现优秀创作者'**
  String get creatorsHeroSubtitle;

  /// No description provided for @creatorsHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'创作者目录'**
  String get creatorsHeroTitle;

  /// No description provided for @dramaBatchUnlockAll.
  ///
  /// In zh, this message translates to:
  /// **'解锁全部'**
  String get dramaBatchUnlockAll;

  /// No description provided for @dramaBatchUnlockDiscount.
  ///
  /// In zh, this message translates to:
  /// **'批量解锁优惠 {discount}%'**
  String dramaBatchUnlockDiscount(String discount);

  /// No description provided for @dramaBatchUnlockSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'一次性解锁全部剧集更划算'**
  String get dramaBatchUnlockSubtitle;

  /// No description provided for @dramaBatchUnlockSuccess.
  ///
  /// In zh, this message translates to:
  /// **'解锁成功，请开始观看'**
  String get dramaBatchUnlockSuccess;

  /// No description provided for @dramaDetailAllFree.
  ///
  /// In zh, this message translates to:
  /// **'全集免费'**
  String get dramaDetailAllFree;

  /// No description provided for @dramaDetailBoundActors.
  ///
  /// In zh, this message translates to:
  /// **'{count} 角色绑定'**
  String dramaDetailBoundActors(int count);

  /// No description provided for @dramaDetailEpisodeCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 集'**
  String dramaDetailEpisodeCount(int count);

  /// No description provided for @dramaDetailEpisodePrice.
  ///
  /// In zh, this message translates to:
  /// **'单集价格'**
  String get dramaDetailEpisodePrice;

  /// No description provided for @dramaDetailFree.
  ///
  /// In zh, this message translates to:
  /// **'免费'**
  String get dramaDetailFree;

  /// No description provided for @dramaDetailFreeEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'前 {count} 集免费'**
  String dramaDetailFreeEpisodes(int count);

  /// No description provided for @dramaDetailMainCharacters.
  ///
  /// In zh, this message translates to:
  /// **'主要人物'**
  String get dramaDetailMainCharacters;

  /// No description provided for @dramaDetailNftMinted.
  ///
  /// In zh, this message translates to:
  /// **'NFT 已铸造'**
  String get dramaDetailNftMinted;

  /// No description provided for @dramaDetailNoEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'暂无剧集'**
  String get dramaDetailNoEpisodes;

  /// No description provided for @dramaDetailPaid.
  ///
  /// In zh, this message translates to:
  /// **'付费'**
  String get dramaDetailPaid;

  /// No description provided for @dramaDetailPendingActor.
  ///
  /// In zh, this message translates to:
  /// **'待定角色'**
  String get dramaDetailPendingActor;

  /// No description provided for @dramaDetailRoleCount.
  ///
  /// In zh, this message translates to:
  /// **'人物数'**
  String get dramaDetailRoleCount;

  /// No description provided for @dramaUnlockFailedRetry.
  ///
  /// In zh, this message translates to:
  /// **'解锁失败，请重试'**
  String get dramaUnlockFailedRetry;

  /// No description provided for @dramaUnlockFetchTimeout.
  ///
  /// In zh, this message translates to:
  /// **'获取播放地址超时，请重试'**
  String get dramaUnlockFetchTimeout;

  /// No description provided for @dramaUnlockLoginRequired.
  ///
  /// In zh, this message translates to:
  /// **'请先登录后再解锁剧集'**
  String get dramaUnlockLoginRequired;

  /// No description provided for @dramaUnlockMessage.
  ///
  /// In zh, this message translates to:
  /// **'第 {epNo} 集需要付费解锁\n单价：{price} {currency}\n批量解锁优惠：{discount}'**
  String dramaUnlockMessage(
    int epNo,
    String price,
    String discount,
    String currency,
  );

  /// No description provided for @dramaUnlockSuccessFetching.
  ///
  /// In zh, this message translates to:
  /// **'解锁成功，正在获取播放地址...'**
  String get dramaUnlockSuccessFetching;

  /// No description provided for @dramaUnlockTitle.
  ///
  /// In zh, this message translates to:
  /// **'解锁剧集'**
  String get dramaUnlockTitle;

  /// No description provided for @editActorTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑角色'**
  String get editActorTitle;

  /// No description provided for @editDramaTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑短剧'**
  String get editDramaTitle;

  /// No description provided for @editVideoTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑视频'**
  String get editVideoTitle;

  /// No description provided for @editSaveChanges.
  ///
  /// In zh, this message translates to:
  /// **'保存修改'**
  String get editSaveChanges;

  /// No description provided for @editProfileTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑资料'**
  String get editProfileTitle;

  /// No description provided for @editNicknameLabel.
  ///
  /// In zh, this message translates to:
  /// **'昵称'**
  String get editNicknameLabel;

  /// No description provided for @editRoleNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get editRoleNameLabel;

  /// No description provided for @editNicknameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入昵称'**
  String get editNicknameHint;

  /// No description provided for @editNicknameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入昵称'**
  String get editNicknameRequired;

  /// No description provided for @editProfileBioLabel.
  ///
  /// In zh, this message translates to:
  /// **'简介'**
  String get editProfileBioLabel;

  /// No description provided for @editProfileBioHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入简介'**
  String get editProfileBioHint;

  /// No description provided for @editProfileEmailLabel.
  ///
  /// In zh, this message translates to:
  /// **'邮箱地址'**
  String get editProfileEmailLabel;

  /// No description provided for @editAvatarCropTitle.
  ///
  /// In zh, this message translates to:
  /// **'裁剪头像'**
  String get editAvatarCropTitle;

  /// No description provided for @profileUpdateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'资料更新成功'**
  String get profileUpdateSuccess;

  /// No description provided for @incomeClaimAmount.
  ///
  /// In zh, this message translates to:
  /// **'领取 {amount} {currency}'**
  String incomeClaimAmount(String amount, String currency);

  /// No description provided for @incomeClaimFailed.
  ///
  /// In zh, this message translates to:
  /// **'领取失败'**
  String get incomeClaimFailed;

  /// No description provided for @incomeClaimMessage.
  ///
  /// In zh, this message translates to:
  /// **'可领取金额：{amount} {currency}\n收益将直接转入您的钱包余额'**
  String incomeClaimMessage(String amount, String currency);

  /// No description provided for @incomeClaimSuccess.
  ///
  /// In zh, this message translates to:
  /// **'领取成功'**
  String get incomeClaimSuccess;

  /// No description provided for @incomeClaimTitle.
  ///
  /// In zh, this message translates to:
  /// **'领取收益'**
  String get incomeClaimTitle;

  /// No description provided for @incomeConfirmClaim.
  ///
  /// In zh, this message translates to:
  /// **'确认领取'**
  String get incomeConfirmClaim;

  /// No description provided for @incomeHistoryTab.
  ///
  /// In zh, this message translates to:
  /// **'收益历史'**
  String get incomeHistoryTab;

  /// No description provided for @incomeInviteHeroSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'邀请好友消费和互动，被邀人活跃度越高奖励越多'**
  String get incomeInviteHeroSubtitle;

  /// No description provided for @incomeInviteHeroTitle.
  ///
  /// In zh, this message translates to:
  /// **'邀请好友赚返利'**
  String get incomeInviteHeroTitle;

  /// No description provided for @incomeInviteNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无返利记录'**
  String get incomeInviteNoRecords;

  /// No description provided for @incomeInvitePaidUnlockDesc.
  ///
  /// In zh, this message translates to:
  /// **'好友付费解锁剧集'**
  String get incomeInvitePaidUnlockDesc;

  /// No description provided for @incomeInvitePaidUnlockTitle.
  ///
  /// In zh, this message translates to:
  /// **'付费解锁'**
  String get incomeInvitePaidUnlockTitle;

  /// No description provided for @incomeInviteRecords.
  ///
  /// In zh, this message translates to:
  /// **'返利记录'**
  String get incomeInviteRecords;

  /// No description provided for @incomeInviteRegisterDesc.
  ///
  /// In zh, this message translates to:
  /// **'好友通过链接注册账号'**
  String get incomeInviteRegisterDesc;

  /// No description provided for @incomeInviteRegisterTitle.
  ///
  /// In zh, this message translates to:
  /// **'邀请注册'**
  String get incomeInviteRegisterTitle;

  /// No description provided for @incomeInviteRules.
  ///
  /// In zh, this message translates to:
  /// **'返利规则'**
  String get incomeInviteRules;

  /// No description provided for @incomeInviteShareLink.
  ///
  /// In zh, this message translates to:
  /// **'分享邀请链接'**
  String get incomeInviteShareLink;

  /// No description provided for @incomeInviteStakeDesc.
  ///
  /// In zh, this message translates to:
  /// **'好友质押 NFT 或 STORY'**
  String get incomeInviteStakeDesc;

  /// No description provided for @incomeInviteStakeTitle.
  ///
  /// In zh, this message translates to:
  /// **'质押投资'**
  String get incomeInviteStakeTitle;

  /// No description provided for @incomeInviteTab.
  ///
  /// In zh, this message translates to:
  /// **'邀请返利'**
  String get incomeInviteTab;

  /// No description provided for @incomeInviteWatchDesc.
  ///
  /// In zh, this message translates to:
  /// **'好友观看短剧获取积分'**
  String get incomeInviteWatchDesc;

  /// No description provided for @incomeInviteWatchTitle.
  ///
  /// In zh, this message translates to:
  /// **'观看短剧'**
  String get incomeInviteWatchTitle;

  /// No description provided for @incomeNoHistory.
  ///
  /// In zh, this message translates to:
  /// **'暂无收益历史'**
  String get incomeNoHistory;

  /// No description provided for @incomeNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无收益记录'**
  String get incomeNoRecords;

  /// No description provided for @incomeNothingToClaim.
  ///
  /// In zh, this message translates to:
  /// **'暂无可领取金额'**
  String get incomeNothingToClaim;

  /// No description provided for @incomeOverviewTab.
  ///
  /// In zh, this message translates to:
  /// **'收益总览'**
  String get incomeOverviewTab;

  /// No description provided for @incomePendingClaim.
  ///
  /// In zh, this message translates to:
  /// **'待领取'**
  String get incomePendingClaim;

  /// No description provided for @incomeRecords.
  ///
  /// In zh, this message translates to:
  /// **'收益记录'**
  String get incomeRecords;

  /// No description provided for @incomeThisMonth.
  ///
  /// In zh, this message translates to:
  /// **'本月'**
  String get incomeThisMonth;

  /// No description provided for @incomeToday.
  ///
  /// In zh, this message translates to:
  /// **'今日'**
  String get incomeToday;

  /// No description provided for @incomeTotalEarnings.
  ///
  /// In zh, this message translates to:
  /// **'累计收益'**
  String get incomeTotalEarnings;

  /// No description provided for @incomeCumulativeStory.
  ///
  /// In zh, this message translates to:
  /// **'累计 STORY'**
  String get incomeCumulativeStory;

  /// No description provided for @incomeCumulativeUsdc.
  ///
  /// In zh, this message translates to:
  /// **'累计 {currency}'**
  String incomeCumulativeUsdc(String currency);

  /// No description provided for @incomeClaimableStory.
  ///
  /// In zh, this message translates to:
  /// **'可领取 STORY'**
  String get incomeClaimableStory;

  /// No description provided for @incomeClaimableUsdc.
  ///
  /// In zh, this message translates to:
  /// **'可领取 {currency}'**
  String incomeClaimableUsdc(String currency);

  /// No description provided for @incomeSettlingStory.
  ///
  /// In zh, this message translates to:
  /// **'我的片酬'**
  String get incomeSettlingStory;

  /// No description provided for @incomeSettlingHint.
  ///
  /// In zh, this message translates to:
  /// **'结算中，到账后可领取'**
  String get incomeSettlingHint;

  /// No description provided for @incomeHelpTotalStoryDesc.
  ///
  /// In zh, this message translates to:
  /// **'历史所有周期累计获得的 STORY 总量（含已领取和未领取）。'**
  String get incomeHelpTotalStoryDesc;

  /// No description provided for @incomeHelpTotalUsdcDesc.
  ///
  /// In zh, this message translates to:
  /// **'历史所有角色签约分成、二级版税的累计 {currency} 收入。'**
  String incomeHelpTotalUsdcDesc(String currency);

  /// No description provided for @incomeHelpSettlingStoryDesc.
  ///
  /// In zh, this message translates to:
  /// **'系统结算后自动兑换为 STORY'**
  String get incomeHelpSettlingStoryDesc;

  /// No description provided for @incomeHelpClaimableStoryDesc.
  ///
  /// In zh, this message translates to:
  /// **'已结算的 STORY，可领取至个人钱包。'**
  String get incomeHelpClaimableStoryDesc;

  /// No description provided for @incomeHelpClaimableUsdcDesc.
  ///
  /// In zh, this message translates to:
  /// **'已结算的 {currency}，可领取至个人钱包。'**
  String incomeHelpClaimableUsdcDesc(String currency);

  /// No description provided for @incomeFilterAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get incomeFilterAll;

  /// No description provided for @incomeFilterMining.
  ///
  /// In zh, this message translates to:
  /// **'派遣收益'**
  String get incomeFilterMining;

  /// No description provided for @incomeFilterInvite.
  ///
  /// In zh, this message translates to:
  /// **'邀请收益'**
  String get incomeFilterInvite;

  /// No description provided for @incomeMiningReward.
  ///
  /// In zh, this message translates to:
  /// **'派遣收益'**
  String get incomeMiningReward;

  /// No description provided for @incomeInviteReward.
  ///
  /// In zh, this message translates to:
  /// **'邀请收益'**
  String get incomeInviteReward;

  /// No description provided for @incomeUsdcActorSignShare.
  ///
  /// In zh, this message translates to:
  /// **'角色签约分成'**
  String get incomeUsdcActorSignShare;

  /// No description provided for @incomeClaimNoWallet.
  ///
  /// In zh, this message translates to:
  /// **'请先绑定钱包'**
  String get incomeClaimNoWallet;

  /// No description provided for @incomeClaimCurrencyTitle.
  ///
  /// In zh, this message translates to:
  /// **'领取 {currency}'**
  String incomeClaimCurrencyTitle(String currency);

  /// No description provided for @incomeClaimWithdrawMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定提取 {amount} {currency} 到您的 Solana 钱包吗？\n收款地址: {address}'**
  String incomeClaimWithdrawMessage(
    String amount,
    String currency,
    String address,
  );

  /// No description provided for @incomeClaimWithdrawConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认提取'**
  String get incomeClaimWithdrawConfirm;

  /// No description provided for @incomeClaimWithdrawSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'提现成功'**
  String get incomeClaimWithdrawSubmitted;

  /// No description provided for @incomeClaimWithdrawFailed.
  ///
  /// In zh, this message translates to:
  /// **'领取提取失败，请重试'**
  String get incomeClaimWithdrawFailed;

  /// No description provided for @incomeClaimAction.
  ///
  /// In zh, this message translates to:
  /// **'领取'**
  String get incomeClaimAction;

  /// No description provided for @nftCreateActorIp.
  ///
  /// In zh, this message translates to:
  /// **'创建角色IP'**
  String get nftCreateActorIp;

  /// No description provided for @nftHeaderSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'浏览和收藏专属角色 NFT'**
  String get nftHeaderSubtitle;

  /// No description provided for @nftHeaderTitle.
  ///
  /// In zh, this message translates to:
  /// **'角色 NFT 广场'**
  String get nftHeaderTitle;

  /// No description provided for @nftSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索短剧、作品、角色、用户...'**
  String get nftSearchHint;

  /// No description provided for @actorHowToPlayTitle.
  ///
  /// In zh, this message translates to:
  /// **'角色 IP 怎么玩'**
  String get actorHowToPlayTitle;

  /// No description provided for @actorHowToPlayHelpTooltip.
  ///
  /// In zh, this message translates to:
  /// **'玩法说明'**
  String get actorHowToPlayHelpTooltip;

  /// No description provided for @actorHowToPlaySignTab.
  ///
  /// In zh, this message translates to:
  /// **'签约IP'**
  String get actorHowToPlaySignTab;

  /// No description provided for @actorHowToPlaySignSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'坐享片酬'**
  String get actorHowToPlaySignSubtitle;

  /// No description provided for @actorHowToPlayIssueTab.
  ///
  /// In zh, this message translates to:
  /// **'发行IP'**
  String get actorHowToPlayIssueTab;

  /// No description provided for @actorHowToPlayIssueSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'创作变现'**
  String get actorHowToPlayIssueSubtitle;

  /// No description provided for @actorHowToPlaySignPositioning.
  ///
  /// In zh, this message translates to:
  /// **'定位：零创作门槛，轻松稳赚收益'**
  String get actorHowToPlaySignPositioning;

  /// No description provided for @actorHowToPlaySignAudience.
  ///
  /// In zh, this message translates to:
  /// **'不想创作，想低门槛赚 STORY 收益的普通用户'**
  String get actorHowToPlaySignAudience;

  /// No description provided for @actorHowToPlaySignGuide.
  ///
  /// In zh, this message translates to:
  /// **'签约高热度高片酬角色 IP，在经纪人页面安排演出即可获利'**
  String get actorHowToPlaySignGuide;

  /// No description provided for @actorHowToPlaySignRightsTitle.
  ///
  /// In zh, this message translates to:
  /// **'双重收益'**
  String get actorHowToPlaySignRightsTitle;

  /// No description provided for @actorHowToPlaySignRightPerform.
  ///
  /// In zh, this message translates to:
  /// **'安排演出，持续赚取 STORY 代币'**
  String get actorHowToPlaySignRightPerform;

  /// No description provided for @actorHowToPlaySignRightTrade.
  ///
  /// In zh, this message translates to:
  /// **'角色 IP 可交易，赚取溢价收益'**
  String get actorHowToPlaySignRightTrade;

  /// No description provided for @actorHowToPlayIssuePositioning.
  ///
  /// In zh, this message translates to:
  /// **'定位：创作发行，多重收益，IP 长期增值'**
  String get actorHowToPlayIssuePositioning;

  /// No description provided for @actorHowToPlayIssueAudience.
  ///
  /// In zh, this message translates to:
  /// **'有创作能力，想靠角色 IP、短剧变现的创作者'**
  String get actorHowToPlayIssueAudience;

  /// No description provided for @actorHowToPlayIssueGuide.
  ///
  /// In zh, this message translates to:
  /// **'发行角色 IP，绑定 AI 短剧，提升作品热度，拉高 IP 片酬与收益'**
  String get actorHowToPlayIssueGuide;

  /// No description provided for @actorHowToPlayIssueRightsTitle.
  ///
  /// In zh, this message translates to:
  /// **'三重收益'**
  String get actorHowToPlayIssueRightsTitle;

  /// No description provided for @actorHowToPlayIssueRightSignLabel.
  ///
  /// In zh, this message translates to:
  /// **'签约分成：'**
  String get actorHowToPlayIssueRightSignLabel;

  /// No description provided for @actorHowToPlayIssueRightSign.
  ///
  /// In zh, this message translates to:
  /// **'自有 IP 被签约，享 40% 分成'**
  String get actorHowToPlayIssueRightSign;

  /// No description provided for @actorHowToPlayIssueRightPerformLabel.
  ///
  /// In zh, this message translates to:
  /// **'演出收益：'**
  String get actorHowToPlayIssueRightPerformLabel;

  /// No description provided for @actorHowToPlayIssueRightPerform.
  ///
  /// In zh, this message translates to:
  /// **'签约自家 IP，演出赚 STORY'**
  String get actorHowToPlayIssueRightPerform;

  /// No description provided for @actorHowToPlayIssueRightValueLabel.
  ///
  /// In zh, this message translates to:
  /// **'价值增值：'**
  String get actorHowToPlayIssueRightValueLabel;

  /// No description provided for @actorHowToPlayIssueRightValue.
  ///
  /// In zh, this message translates to:
  /// **'IP 可交易，热度越高溢价越高'**
  String get actorHowToPlayIssueRightValue;

  /// No description provided for @actorHowToPlayAudienceTitle.
  ///
  /// In zh, this message translates to:
  /// **'适合人群'**
  String get actorHowToPlayAudienceTitle;

  /// No description provided for @actorHowToPlayGuideTitle.
  ///
  /// In zh, this message translates to:
  /// **'玩法指南'**
  String get actorHowToPlayGuideTitle;

  /// No description provided for @actorHowToPlayCreateHint.
  ///
  /// In zh, this message translates to:
  /// **'可用 DreamOS 一键生成角色 IP 与 AI 短剧，高效产出优质内容'**
  String get actorHowToPlayCreateHint;

  /// No description provided for @actorHowToPlayCreateCta.
  ///
  /// In zh, this message translates to:
  /// **'去创作'**
  String get actorHowToPlayCreateCta;

  /// No description provided for @nftSignInDevelopment.
  ///
  /// In zh, this message translates to:
  /// **'功能暂未开放'**
  String get nftSignInDevelopment;

  /// No description provided for @nftSortCompleted.
  ///
  /// In zh, this message translates to:
  /// **'完播'**
  String get nftSortCompleted;

  /// No description provided for @nftSortHeat.
  ///
  /// In zh, this message translates to:
  /// **'热度'**
  String get nftSortHeat;

  /// No description provided for @nftSortIpPower.
  ///
  /// In zh, this message translates to:
  /// **'IP片酬'**
  String get nftSortIpPower;

  /// No description provided for @nftSortLowestPrice.
  ///
  /// In zh, this message translates to:
  /// **'价格'**
  String get nftSortLowestPrice;

  /// No description provided for @nftSortLv1Pay.
  ///
  /// In zh, this message translates to:
  /// **'片酬'**
  String get nftSortLv1Pay;

  /// No description provided for @nftSortMaxPay.
  ///
  /// In zh, this message translates to:
  /// **'最高片酬'**
  String get nftSortMaxPay;

  /// No description provided for @nftTradeUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'交易暂未开放'**
  String get nftTradeUnavailable;

  /// No description provided for @playerEpisodeBarCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完结 · 全{count}集'**
  String playerEpisodeBarCompleted(int count);

  /// No description provided for @playerEpisodeSynopsis.
  ///
  /// In zh, this message translates to:
  /// **'第 {episodeNo} 集｜{synopsis}'**
  String playerEpisodeSynopsis(int episodeNo, String synopsis);

  /// No description provided for @playerPlayFailedRetry.
  ///
  /// In zh, this message translates to:
  /// **'播放失败，请稍后重试'**
  String get playerPlayFailedRetry;

  /// No description provided for @publicProfileDramas.
  ///
  /// In zh, this message translates to:
  /// **'短剧'**
  String get publicProfileDramas;

  /// No description provided for @publicProfileEmpty.
  ///
  /// In zh, this message translates to:
  /// **'该用户暂无公开内容'**
  String get publicProfileEmpty;

  /// No description provided for @publicProfileBlock.
  ///
  /// In zh, this message translates to:
  /// **'拉黑'**
  String get publicProfileBlock;

  /// No description provided for @publicProfileUnblock.
  ///
  /// In zh, this message translates to:
  /// **'解除拉黑'**
  String get publicProfileUnblock;

  /// No description provided for @publicProfileBlockedByMeContent.
  ///
  /// In zh, this message translates to:
  /// **'你已拉黑对方，无法查看TA的内容'**
  String get publicProfileBlockedByMeContent;

  /// No description provided for @publicProfileBlockedContent.
  ///
  /// In zh, this message translates to:
  /// **'对方已将你拉黑，你无法查看TA的内容'**
  String get publicProfileBlockedContent;

  /// No description provided for @publicProfileBlockConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认拉黑'**
  String get publicProfileBlockConfirmTitle;

  /// No description provided for @publicProfileBlockConfirmMessage.
  ///
  /// In zh, this message translates to:
  /// **'拉黑后，你将无法查看对方的作品。'**
  String get publicProfileBlockConfirmMessage;

  /// No description provided for @publicProfileBlockSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已拉黑'**
  String get publicProfileBlockSuccess;

  /// No description provided for @publicProfileUnblockSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已解除拉黑'**
  String get publicProfileUnblockSuccess;

  /// No description provided for @publicProfileFollowers.
  ///
  /// In zh, this message translates to:
  /// **'粉丝'**
  String get publicProfileFollowers;

  /// No description provided for @publicProfileFollowing.
  ///
  /// In zh, this message translates to:
  /// **'关注'**
  String get publicProfileFollowing;

  /// No description provided for @followTabMutual.
  ///
  /// In zh, this message translates to:
  /// **'互关'**
  String get followTabMutual;

  /// No description provided for @profileLikesReceived.
  ///
  /// In zh, this message translates to:
  /// **'获赞'**
  String get profileLikesReceived;

  /// No description provided for @profileLikesReceivedDialogMessage.
  ///
  /// In zh, this message translates to:
  /// **'你已累计获得 {count} 个赞，感谢你的精彩创作！'**
  String profileLikesReceivedDialogMessage(int count);

  /// No description provided for @profileTabLikes.
  ///
  /// In zh, this message translates to:
  /// **'点赞'**
  String get profileTabLikes;

  /// No description provided for @profileTabFavorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get profileTabFavorites;

  /// No description provided for @profileWalletTitle.
  ///
  /// In zh, this message translates to:
  /// **'钱包'**
  String get profileWalletTitle;

  /// No description provided for @profileAddressCopied.
  ///
  /// In zh, this message translates to:
  /// **'地址已复制'**
  String get profileAddressCopied;

  /// No description provided for @followActionFollow.
  ///
  /// In zh, this message translates to:
  /// **'关注'**
  String get followActionFollow;

  /// No description provided for @followActionFollowBack.
  ///
  /// In zh, this message translates to:
  /// **'回关'**
  String get followActionFollowBack;

  /// No description provided for @followActionFollowing.
  ///
  /// In zh, this message translates to:
  /// **'已关注'**
  String get followActionFollowing;

  /// No description provided for @followBlockedByMe.
  ///
  /// In zh, this message translates to:
  /// **'黑名单用户，无法关注'**
  String get followBlockedByMe;

  /// No description provided for @followBlockedByTarget.
  ///
  /// In zh, this message translates to:
  /// **'由于对方设置，你无法关注TA'**
  String get followBlockedByTarget;

  /// No description provided for @likeBlockedByMe.
  ///
  /// In zh, this message translates to:
  /// **'黑名单用户，无法点赞'**
  String get likeBlockedByMe;

  /// No description provided for @likeBlockedByTarget.
  ///
  /// In zh, this message translates to:
  /// **'由于对方设置，你无法点赞'**
  String get likeBlockedByTarget;

  /// No description provided for @favoriteBlockedByMe.
  ///
  /// In zh, this message translates to:
  /// **'黑名单用户，无法收藏'**
  String get favoriteBlockedByMe;

  /// No description provided for @favoriteBlockedByTarget.
  ///
  /// In zh, this message translates to:
  /// **'由于对方设置，你无法收藏'**
  String get favoriteBlockedByTarget;

  /// No description provided for @ratingBlockedByMe.
  ///
  /// In zh, this message translates to:
  /// **'黑名单用户，无法评分'**
  String get ratingBlockedByMe;

  /// No description provided for @ratingBlockedByTarget.
  ///
  /// In zh, this message translates to:
  /// **'由于对方设置，你无法评分'**
  String get ratingBlockedByTarget;

  /// No description provided for @followActionMutual.
  ///
  /// In zh, this message translates to:
  /// **'互相关注'**
  String get followActionMutual;

  /// No description provided for @followUnfollowTitle.
  ///
  /// In zh, this message translates to:
  /// **'取消关注'**
  String get followUnfollowTitle;

  /// No description provided for @followUnfollowMessage.
  ///
  /// In zh, this message translates to:
  /// **'确认不再关注 {handle} 吗？'**
  String followUnfollowMessage(String handle);

  /// No description provided for @followUnfollowNo.
  ///
  /// In zh, this message translates to:
  /// **'否'**
  String get followUnfollowNo;

  /// No description provided for @followUnfollowYes.
  ///
  /// In zh, this message translates to:
  /// **'是'**
  String get followUnfollowYes;

  /// No description provided for @followListEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无用户'**
  String get followListEmpty;

  /// No description provided for @followFollowingEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无关注，去发现有趣的创作者吧～'**
  String get followFollowingEmpty;

  /// No description provided for @followFollowingEmptyCta.
  ///
  /// In zh, this message translates to:
  /// **'去看看'**
  String get followFollowingEmptyCta;

  /// No description provided for @followFollowingEmptyGuest.
  ///
  /// In zh, this message translates to:
  /// **'暂无关注'**
  String get followFollowingEmptyGuest;

  /// No description provided for @followFollowersEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无粉丝，去发布作品提升曝光吧～'**
  String get followFollowersEmpty;

  /// No description provided for @followFollowersEmptyCta.
  ///
  /// In zh, this message translates to:
  /// **'去发布'**
  String get followFollowersEmptyCta;

  /// No description provided for @followFollowersEmptyGuest.
  ///
  /// In zh, this message translates to:
  /// **'暂无粉丝'**
  String get followFollowersEmptyGuest;

  /// No description provided for @followMutualsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无互关好友'**
  String get followMutualsEmpty;

  /// No description provided for @followMutualsSelfOnly.
  ///
  /// In zh, this message translates to:
  /// **'互关列表仅本人可见'**
  String get followMutualsSelfOnly;

  /// No description provided for @followRelationsSelfOnly.
  ///
  /// In zh, this message translates to:
  /// **'关系列表仅本人可见'**
  String get followRelationsSelfOnly;

  /// No description provided for @followMoreTitle.
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get followMoreTitle;

  /// No description provided for @followRemoveFollower.
  ///
  /// In zh, this message translates to:
  /// **'移除粉丝'**
  String get followRemoveFollower;

  /// No description provided for @followRemoveFollowerSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已移除，对方不会收到通知'**
  String get followRemoveFollowerSuccess;

  /// No description provided for @followUserHandleFallback.
  ///
  /// In zh, this message translates to:
  /// **'@用户'**
  String get followUserHandleFallback;

  /// No description provided for @publicProfileTitle.
  ///
  /// In zh, this message translates to:
  /// **'用户主页'**
  String get publicProfileTitle;

  /// No description provided for @publicProfileUserFallback.
  ///
  /// In zh, this message translates to:
  /// **'用户 #{id}'**
  String publicProfileUserFallback(String id);

  /// No description provided for @watchHistoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无观看记录'**
  String get watchHistoryEmpty;

  /// No description provided for @watchHistoryClearTitle.
  ///
  /// In zh, this message translates to:
  /// **'清空观看历史'**
  String get watchHistoryClearTitle;

  /// No description provided for @watchHistoryClearMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要清空所有观看历史吗？此操作无法撤销。'**
  String get watchHistoryClearMessage;

  /// No description provided for @watchHistoryClearConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get watchHistoryClearConfirm;

  /// No description provided for @gamePageTitle.
  ///
  /// In zh, this message translates to:
  /// **'经纪人'**
  String get gamePageTitle;

  /// No description provided for @gamePageSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'管理你的角色，派遣产生收益。'**
  String get gamePageSubtitle;

  /// No description provided for @gameRiskAccount.
  ///
  /// In zh, this message translates to:
  /// **'风险账户'**
  String get gameRiskAccount;

  /// No description provided for @gameRiskAccountDescription.
  ///
  /// In zh, this message translates to:
  /// **'该账户信任系数异常，挖矿权重将受影响。'**
  String get gameRiskAccountDescription;

  /// No description provided for @gameWeeklyStats.
  ///
  /// In zh, this message translates to:
  /// **'本周数据'**
  String get gameWeeklyStats;

  /// No description provided for @gameDeployedActors.
  ///
  /// In zh, this message translates to:
  /// **'已派遣角色'**
  String get gameDeployedActors;

  /// No description provided for @gameMyActors.
  ///
  /// In zh, this message translates to:
  /// **'我的角色'**
  String get gameMyActors;

  /// No description provided for @gameComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'即将上线'**
  String get gameComingSoon;

  /// No description provided for @gameSignActor.
  ///
  /// In zh, this message translates to:
  /// **'签约角色'**
  String get gameSignActor;

  /// No description provided for @gameGoProduce.
  ///
  /// In zh, this message translates to:
  /// **'去拍剧'**
  String get gameGoProduce;

  /// No description provided for @gameWorkingActors.
  ///
  /// In zh, this message translates to:
  /// **'派遣中的角色'**
  String get gameWorkingActors;

  /// No description provided for @gameWeekPool.
  ///
  /// In zh, this message translates to:
  /// **'本周奖池 (STORY)'**
  String get gameWeekPool;

  /// No description provided for @gameWeekNominalOutput.
  ///
  /// In zh, this message translates to:
  /// **'本周名义产出 (STORY)'**
  String get gameWeekNominalOutput;

  /// No description provided for @gameWeekEstimatedOutput.
  ///
  /// In zh, this message translates to:
  /// **'本周预估产出 (STORY)'**
  String get gameWeekEstimatedOutput;

  /// No description provided for @gameMiningRules.
  ///
  /// In zh, this message translates to:
  /// **'挖矿规则'**
  String get gameMiningRules;

  /// No description provided for @agentV2RulesTitle.
  ///
  /// In zh, this message translates to:
  /// **'经营玩法'**
  String get agentV2RulesTitle;

  /// No description provided for @agentV2RulesSummary.
  ///
  /// In zh, this message translates to:
  /// **'签约角色、安排演出，每小时获得 STORY。\n升级角色，成倍提升每小时片酬。\n体力耗尽时及时补充，产出不间断。\n每周一 00:00 (UTC) 开始结算本期收益，前往收益页领取。'**
  String get agentV2RulesSummary;

  /// No description provided for @agentV2RulesHowToPlay.
  ///
  /// In zh, this message translates to:
  /// **'怎么玩'**
  String get agentV2RulesHowToPlay;

  /// No description provided for @agentV2RulesStartTitle.
  ///
  /// In zh, this message translates to:
  /// **'怎么让角色开始赚钱？'**
  String get agentV2RulesStartTitle;

  /// No description provided for @agentV2RulesStartDescription.
  ///
  /// In zh, this message translates to:
  /// **'安排候场角色演出，每小时消耗1点体力并根据片酬产出 STORY。\n产出的STORY在每期结束时统一结算，结算后可前往收益页面领取。'**
  String get agentV2RulesStartDescription;

  /// No description provided for @agentV2RulesStaminaTitle.
  ///
  /// In zh, this message translates to:
  /// **'体力怎么管理？'**
  String get agentV2RulesStaminaTitle;

  /// No description provided for @agentV2RulesStaminaDescription.
  ///
  /// In zh, this message translates to:
  /// **'演出中：每小时消耗 1 点体力，正常产出片酬\n体力耗尽：产出暂停为 0，需要及时处理\n休息：每小时自动恢复 1 点体力，但暂停片酬\n补充体力（付费）：瞬间回满 {staminaLimit}，立即恢复产出'**
  String agentV2RulesStaminaDescription(int staminaLimit);

  /// No description provided for @agentV2RulesBatchTitle.
  ///
  /// In zh, this message translates to:
  /// **'可以批量操作吗？'**
  String get agentV2RulesBatchTitle;

  /// No description provided for @agentV2RulesBatchDescription.
  ///
  /// In zh, this message translates to:
  /// **'可以。页面底部提供一键演出、一键补充、一键休息，对在演位上的所有角色批量执行。'**
  String get agentV2RulesBatchDescription;

  /// No description provided for @agentV2RulesEarnings.
  ///
  /// In zh, this message translates to:
  /// **'能赚多少'**
  String get agentV2RulesEarnings;

  /// No description provided for @agentV2RulesSalaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'片酬怎么算？'**
  String get agentV2RulesSalaryTitle;

  /// No description provided for @agentV2RulesSalaryDescription.
  ///
  /// In zh, this message translates to:
  /// **'咖位越高、角色越贵、短剧越火，每小时片酬就越高。'**
  String get agentV2RulesSalaryDescription;

  /// No description provided for @agentV2RulesSalaryFormula.
  ///
  /// In zh, this message translates to:
  /// **'单卡小时片酬 = 角色片酬 × 1 STORY'**
  String get agentV2RulesSalaryFormula;

  /// No description provided for @agentV2RulesRolePowerFormula.
  ///
  /// In zh, this message translates to:
  /// **'角色片酬 = Lv.1 角色片酬 × 片酬系数'**
  String get agentV2RulesRolePowerFormula;

  /// No description provided for @agentV2RulesIpSalaryFormula.
  ///
  /// In zh, this message translates to:
  /// **'Lv.1 角色片酬 = 价格系数 × 热度系数'**
  String get agentV2RulesIpSalaryFormula;

  /// No description provided for @agentV2RulesCoefficientTitle.
  ///
  /// In zh, this message translates to:
  /// **'系数说明'**
  String get agentV2RulesCoefficientTitle;

  /// No description provided for @agentV2RulesSalaryExample.
  ///
  /// In zh, this message translates to:
  /// **'林梦瑶 Lv3 主角 · P0=120{currency}（价格系数 ≈1.5046）· 热度 3.5\n→ 每小时片酬 = 5.0 × 1.5046 × 3.5 × 1 = 26.3 STORY\n如果只是 Lv1 群演，每小时仅 ≈5.3 STORY——升到 Lv3 涨了 5 倍'**
  String agentV2RulesSalaryExample(String currency);

  /// No description provided for @agentV2RulesSettlementTitle.
  ///
  /// In zh, this message translates to:
  /// **'什么时候结算？'**
  String get agentV2RulesSettlementTitle;

  /// No description provided for @agentV2RulesSettlementDescription.
  ///
  /// In zh, this message translates to:
  /// **'每 7 天为一个演出周期，每周一 00:00 (UTC) 截止。系统结算完毕后，本期片酬自动兑换为STORY，可前往收益页面领取。'**
  String get agentV2RulesSettlementDescription;

  /// No description provided for @agentV2RulesSettlementExample.
  ///
  /// In zh, this message translates to:
  /// **'假设本周奖池 100,000 STORY：\n情况 A：全平台只有你产出 134 → 你拿 134，剩下不发放\n情况 B：全网产出 250,000 → 100,000 ÷ 250,000 = 40%，你的名义产出打四折\n情况 C：缩放后某人应得 6,000，但上限 5,000 → 只发 5,000'**
  String get agentV2RulesSettlementExample;

  /// No description provided for @agentV2RulesStronger.
  ///
  /// In zh, this message translates to:
  /// **'怎么变强'**
  String get agentV2RulesStronger;

  /// No description provided for @agentV2RulesUpgradeTitle.
  ///
  /// In zh, this message translates to:
  /// **'怎么升级角色？'**
  String get agentV2RulesUpgradeTitle;

  /// No description provided for @agentV2RulesUpgradeDescription.
  ///
  /// In zh, this message translates to:
  /// **'升级条件：消耗 2 张同IP同等级分身 + IP参演短剧累计完播数达标\nLv1→Lv2：≥1万完播 · 片酬 1→3\nLv2→Lv3：≥5万完播 · 片酬 3→9\nLv3→Lv4：≥20万完播 · 片酬 9→27\nLv4→Lv5：≥100万完播 · 片酬 27→81'**
  String get agentV2RulesUpgradeDescription;

  /// No description provided for @agentV2RulesPerforming.
  ///
  /// In zh, this message translates to:
  /// **'演出中'**
  String get agentV2RulesPerforming;

  /// No description provided for @agentV2RulesNormalSalary.
  ///
  /// In zh, this message translates to:
  /// **'正常片酬'**
  String get agentV2RulesNormalSalary;

  /// No description provided for @agentV2RulesSalaryCoefficient.
  ///
  /// In zh, this message translates to:
  /// **'片酬系数：Lv1=1 · Lv2=3 · Lv3=9 · Lv4=27 · Lv5=81'**
  String get agentV2RulesSalaryCoefficient;

  /// No description provided for @agentV2RulesPriceCoefficientDescription.
  ///
  /// In zh, this message translates to:
  /// **'价格系数（发行价 P0）：\n  • P0 ≤ 100{currency1} → 系数 = P0 ÷ 100（线性增长）\n  • P0 > 100{currency2} → 系数 = 1.6 × (P0/100)1.3 / [(P0/100)1.3 + 0.6]（渐近上限 1.6）'**
  String agentV2RulesPriceCoefficientDescription(
    String currency1,
    String currency2,
  );

  /// No description provided for @agentV2RulesTrust2.
  ///
  /// In zh, this message translates to:
  /// **'Trust2'**
  String get agentV2RulesTrust2;

  /// No description provided for @agentV2RulesTrust2Factor.
  ///
  /// In zh, this message translates to:
  /// **'平台Trust2'**
  String get agentV2RulesTrust2Factor;

  /// No description provided for @agentV2RulesSettlementCase1.
  ///
  /// In zh, this message translates to:
  /// **'实发 = 名义产出，剩余额度作废'**
  String get agentV2RulesSettlementCase1;

  /// No description provided for @agentV2RulesSettlementCase2.
  ///
  /// In zh, this message translates to:
  /// **'等比缩放：你实得 = 你的名义产出 × (奖池 ÷ 全网产出)'**
  String get agentV2RulesSettlementCase2;

  /// No description provided for @gameSettlementRecords.
  ///
  /// In zh, this message translates to:
  /// **'每周结算记录'**
  String get gameSettlementRecords;

  /// No description provided for @gameFilterComputingPower.
  ///
  /// In zh, this message translates to:
  /// **'片酬'**
  String get gameFilterComputingPower;

  /// No description provided for @gameFilterLevel.
  ///
  /// In zh, this message translates to:
  /// **'等级'**
  String get gameFilterLevel;

  /// No description provided for @gameFilterHeat.
  ///
  /// In zh, this message translates to:
  /// **'热度'**
  String get gameFilterHeat;

  /// No description provided for @gameFilterStamina.
  ///
  /// In zh, this message translates to:
  /// **'体力'**
  String get gameFilterStamina;

  /// No description provided for @gameHeatCoef.
  ///
  /// In zh, this message translates to:
  /// **'热度系数'**
  String get gameHeatCoef;

  /// No description provided for @gameMiningCoef.
  ///
  /// In zh, this message translates to:
  /// **'挖矿系数'**
  String get gameMiningCoef;

  /// No description provided for @gameActorPower.
  ///
  /// In zh, this message translates to:
  /// **'角色片酬'**
  String get gameActorPower;

  /// No description provided for @gameActorPowerDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'角色片酬详情'**
  String get gameActorPowerDetailTitle;

  /// No description provided for @gameActorPowerFormula.
  ///
  /// In zh, this message translates to:
  /// **'角色片酬 = IP片酬 × 挖矿系数 × CP系数 × Trust2'**
  String get gameActorPowerFormula;

  /// No description provided for @gameActorPowerIpFormula.
  ///
  /// In zh, this message translates to:
  /// **'IP片酬 = 价格系数 × 热度系数 × Trust1'**
  String get gameActorPowerIpFormula;

  /// No description provided for @gameActorPowerHourlyOutput.
  ///
  /// In zh, this message translates to:
  /// **'每小时产出'**
  String get gameActorPowerHourlyOutput;

  /// No description provided for @gameCpCoefficient.
  ///
  /// In zh, this message translates to:
  /// **'CP 系数'**
  String get gameCpCoefficient;

  /// No description provided for @gameTrust2.
  ///
  /// In zh, this message translates to:
  /// **'Trust2'**
  String get gameTrust2;

  /// No description provided for @gameWeeklyNominalOutputLabel.
  ///
  /// In zh, this message translates to:
  /// **'本周名义产出'**
  String get gameWeeklyNominalOutputLabel;

  /// No description provided for @gameRoundNominalOutputLabel.
  ///
  /// In zh, this message translates to:
  /// **'本局名义产出'**
  String get gameRoundNominalOutputLabel;

  /// No description provided for @gameSupplement.
  ///
  /// In zh, this message translates to:
  /// **'补充'**
  String get gameSupplement;

  /// No description provided for @gameRest.
  ///
  /// In zh, this message translates to:
  /// **'休息'**
  String get gameRest;

  /// No description provided for @gameDeploy.
  ///
  /// In zh, this message translates to:
  /// **'派遣'**
  String get gameDeploy;

  /// No description provided for @gameDeployActor.
  ///
  /// In zh, this message translates to:
  /// **'派遣角色'**
  String get gameDeployActor;

  /// No description provided for @gameStatusIdle.
  ///
  /// In zh, this message translates to:
  /// **'闲置'**
  String get gameStatusIdle;

  /// No description provided for @gameStatusMining.
  ///
  /// In zh, this message translates to:
  /// **'挖矿中'**
  String get gameStatusMining;

  /// No description provided for @gameActorIpLabel.
  ///
  /// In zh, this message translates to:
  /// **'角色IP {id}'**
  String gameActorIpLabel(String id);

  /// No description provided for @gameStaminaProgress.
  ///
  /// In zh, this message translates to:
  /// **'{current}/{max}'**
  String gameStaminaProgress(String current, String max);

  /// No description provided for @gameStaminaMechanismTitle.
  ///
  /// In zh, this message translates to:
  /// **'体力机制'**
  String get gameStaminaMechanismTitle;

  /// No description provided for @gameStaminaMechanismDesc.
  ///
  /// In zh, this message translates to:
  /// **'派遣中的角色每小时消耗 1 点体力。体力耗尽后停止产出，休息时自动恢复。可用 {currency} 即时补充体力。'**
  String gameStaminaMechanismDesc(String currency);

  /// No description provided for @gameStaminaMechanismAction.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get gameStaminaMechanismAction;

  /// No description provided for @gameLevelBadge.
  ///
  /// In zh, this message translates to:
  /// **'Lv{level}'**
  String gameLevelBadge(String level);

  /// No description provided for @gameEmptyDeployed.
  ///
  /// In zh, this message translates to:
  /// **'暂无派遣中的角色'**
  String get gameEmptyDeployed;

  /// No description provided for @gameEmptyMyActors.
  ///
  /// In zh, this message translates to:
  /// **'暂无角色，去签约吧'**
  String get gameEmptyMyActors;

  /// No description provided for @gameDeployConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认派遣该角色？'**
  String get gameDeployConfirmTitle;

  /// No description provided for @gameRestConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认让该角色休息？'**
  String get gameRestConfirmTitle;

  /// No description provided for @gameRestConfirmDesc.
  ///
  /// In zh, this message translates to:
  /// **'角色休息期间暂停挖矿产出，体力会随时间恢复。'**
  String get gameRestConfirmDesc;

  /// No description provided for @gameRestConfirmAction.
  ///
  /// In zh, this message translates to:
  /// **'确认休息'**
  String get gameRestConfirmAction;

  /// No description provided for @gameRestSuccessToast.
  ///
  /// In zh, this message translates to:
  /// **'休息成功'**
  String get gameRestSuccessToast;

  /// No description provided for @gameDeploySlotFull.
  ///
  /// In zh, this message translates to:
  /// **'派遣槽位已满（最多 5 位）'**
  String get gameDeploySlotFull;

  /// No description provided for @gameRefillTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复体力'**
  String get gameRefillTitle;

  /// No description provided for @gameRefillCurrentStamina.
  ///
  /// In zh, this message translates to:
  /// **'当前体力'**
  String get gameRefillCurrentStamina;

  /// No description provided for @gameRefillCost.
  ///
  /// In zh, this message translates to:
  /// **'恢复费用'**
  String get gameRefillCost;

  /// No description provided for @gameRefillConfirm.
  ///
  /// In zh, this message translates to:
  /// **'恢复全部体力'**
  String get gameRefillConfirm;

  /// No description provided for @gameRefillSuccess.
  ///
  /// In zh, this message translates to:
  /// **'恢复体力成功'**
  String get gameRefillSuccess;

  /// No description provided for @gameRefillFailed.
  ///
  /// In zh, this message translates to:
  /// **'恢复体力失败，请重试'**
  String get gameRefillFailed;

  /// No description provided for @gameInsufficientUsdc.
  ///
  /// In zh, this message translates to:
  /// **'{currency} 余额不足'**
  String gameInsufficientUsdc(String currency);

  /// No description provided for @walletInsufficientStory.
  ///
  /// In zh, this message translates to:
  /// **'STORY 余额不足'**
  String get walletInsufficientStory;

  /// No description provided for @gameSupplementComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'补充体力功能即将上线'**
  String get gameSupplementComingSoon;

  /// No description provided for @gameStatHelpWeekPoolTitle.
  ///
  /// In zh, this message translates to:
  /// **'本周奖池'**
  String get gameStatHelpWeekPoolTitle;

  /// No description provided for @gameStatHelpWeekPoolSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'即 STORY 挖矿的每周硬性发放上限（周硬顶）'**
  String get gameStatHelpWeekPoolSubtitle;

  /// No description provided for @gameStatHelpWeekTotalPool.
  ///
  /// In zh, this message translates to:
  /// **'本周总奖池'**
  String get gameStatHelpWeekTotalPool;

  /// No description provided for @gameStatHelpWeekTotalPoolValue.
  ///
  /// In zh, this message translates to:
  /// **'2,115,385 STORY'**
  String get gameStatHelpWeekTotalPoolValue;

  /// No description provided for @gameStatHelpWeekStakePool.
  ///
  /// In zh, this message translates to:
  /// **'本周质押奖池（75%）'**
  String get gameStatHelpWeekStakePool;

  /// No description provided for @gameStatHelpWeekStakePoolValue.
  ///
  /// In zh, this message translates to:
  /// **'1,586,538 STORY'**
  String get gameStatHelpWeekStakePoolValue;

  /// No description provided for @gameStatHelpWeekInvitePool.
  ///
  /// In zh, this message translates to:
  /// **'本周邀请奖池（25%）'**
  String get gameStatHelpWeekInvitePool;

  /// No description provided for @gameStatHelpWeekInvitePoolValue.
  ///
  /// In zh, this message translates to:
  /// **'528,846 STORY'**
  String get gameStatHelpWeekInvitePoolValue;

  /// No description provided for @gameStatHelpInitialHardCap.
  ///
  /// In zh, this message translates to:
  /// **'初始周硬顶'**
  String get gameStatHelpInitialHardCap;

  /// No description provided for @gameStatHelpInitialHardCapValue.
  ///
  /// In zh, this message translates to:
  /// **'2,115,385 STORY'**
  String get gameStatHelpInitialHardCapValue;

  /// No description provided for @gameStatHelpWeeklyDecay.
  ///
  /// In zh, this message translates to:
  /// **'周衰减系数'**
  String get gameStatHelpWeeklyDecay;

  /// No description provided for @gameStatHelpWeeklyDecayValue.
  ///
  /// In zh, this message translates to:
  /// **'× 0.99572'**
  String get gameStatHelpWeeklyDecayValue;

  /// No description provided for @gameStatHelpWeeklyDistributionFormula.
  ///
  /// In zh, this message translates to:
  /// **'每周实际发放 = min(全网名义产出, 当周硬顶)'**
  String get gameStatHelpWeeklyDistributionFormula;

  /// No description provided for @gameStatHelpUnusedQuotaNote.
  ///
  /// In zh, this message translates to:
  /// **'未发出的剩余额度不发放、不回流、不补分'**
  String get gameStatHelpUnusedQuotaNote;

  /// No description provided for @gameStatHelpNominalTitle.
  ///
  /// In zh, this message translates to:
  /// **'本周名义产出'**
  String get gameStatHelpNominalTitle;

  /// No description provided for @gameStatHelpNominalSummary.
  ///
  /// In zh, this message translates to:
  /// **'我的所有角色的周累计名义产出累加'**
  String get gameStatHelpNominalSummary;

  /// No description provided for @gameStatHelpNominalSummaryHint.
  ///
  /// In zh, this message translates to:
  /// **'单卡公式见下方说明'**
  String get gameStatHelpNominalSummaryHint;

  /// No description provided for @gameStatHelpNominalFormula.
  ///
  /// In zh, this message translates to:
  /// **'单卡名义产出 = 单卡小时权重 × R_base × 有效挖矿时长'**
  String get gameStatHelpNominalFormula;

  /// No description provided for @gameStatHelpHourlyWeight.
  ///
  /// In zh, this message translates to:
  /// **'单卡小时权重'**
  String get gameStatHelpHourlyWeight;

  /// No description provided for @gameStatHelpHourlyWeightValue.
  ///
  /// In zh, this message translates to:
  /// **'= 角色片酬'**
  String get gameStatHelpHourlyWeightValue;

  /// No description provided for @gameStatHelpActorPower.
  ///
  /// In zh, this message translates to:
  /// **'角色片酬'**
  String get gameStatHelpActorPower;

  /// No description provided for @gameStatHelpActorPowerValue.
  ///
  /// In zh, this message translates to:
  /// **'= IP片酬 × 挖矿系数 × CP系数 × Trust2'**
  String get gameStatHelpActorPowerValue;

  /// No description provided for @gameStatHelpCpCoef.
  ///
  /// In zh, this message translates to:
  /// **'CP 系数'**
  String get gameStatHelpCpCoef;

  /// No description provided for @gameStatHelpRBase.
  ///
  /// In zh, this message translates to:
  /// **'R_base'**
  String get gameStatHelpRBase;

  /// No description provided for @gameStatHelpRBaseValue.
  ///
  /// In zh, this message translates to:
  /// **'1 STORY / 单位权重 / 小时'**
  String get gameStatHelpRBaseValue;

  /// No description provided for @gameStatHelpEffectiveDuration.
  ///
  /// In zh, this message translates to:
  /// **'有效挖矿时长'**
  String get gameStatHelpEffectiveDuration;

  /// No description provided for @gameStatHelpEffectiveDurationValue.
  ///
  /// In zh, this message translates to:
  /// **'质押中且体力 > 0 的累计时长'**
  String get gameStatHelpEffectiveDurationValue;

  /// No description provided for @gameStatHelpActualTitle.
  ///
  /// In zh, this message translates to:
  /// **'本周预估产出'**
  String get gameStatHelpActualTitle;

  /// No description provided for @gameStatHelpActualSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'预估产出受周硬顶和单地址封顶约束，本周结束时产生实际收益'**
  String get gameStatHelpActualSubtitle;

  /// No description provided for @gameStatHelpIfNominalLte.
  ///
  /// In zh, this message translates to:
  /// **'若全网名义产出 ≤ 当周硬顶：'**
  String get gameStatHelpIfNominalLte;

  /// No description provided for @gameStatHelpUserActualEqNominal.
  ///
  /// In zh, this message translates to:
  /// **'用户实得 = 用户名义产出'**
  String get gameStatHelpUserActualEqNominal;

  /// No description provided for @gameStatHelpIfNominalGt.
  ///
  /// In zh, this message translates to:
  /// **'若全网名义产出 > 当周硬顶：'**
  String get gameStatHelpIfNominalGt;

  /// No description provided for @gameStatHelpUserActualFormula.
  ///
  /// In zh, this message translates to:
  /// **'用户实得 = 用户名义产出 × 当周硬顶 / 全网名义产出'**
  String get gameStatHelpUserActualFormula;

  /// No description provided for @gameStatHelpAddressCap.
  ///
  /// In zh, this message translates to:
  /// **'单地址周封顶'**
  String get gameStatHelpAddressCap;

  /// No description provided for @gameStatHelpAddressCapValue.
  ///
  /// In zh, this message translates to:
  /// **'单个地址每周最多领取当周硬顶的 5%'**
  String get gameStatHelpAddressCapValue;

  /// No description provided for @theaterCategoryAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get theaterCategoryAll;

  /// No description provided for @theaterCategoryAncient.
  ///
  /// In zh, this message translates to:
  /// **'古风'**
  String get theaterCategoryAncient;

  /// No description provided for @theaterCategoryFinance.
  ///
  /// In zh, this message translates to:
  /// **'金融'**
  String get theaterCategoryFinance;

  /// No description provided for @theaterCategorySuspense.
  ///
  /// In zh, this message translates to:
  /// **'悬疑'**
  String get theaterCategorySuspense;

  /// No description provided for @theaterCategorySciFi.
  ///
  /// In zh, this message translates to:
  /// **'科幻'**
  String get theaterCategorySciFi;

  /// No description provided for @theaterCategoryRealStory.
  ///
  /// In zh, this message translates to:
  /// **'真实改编'**
  String get theaterCategoryRealStory;

  /// No description provided for @theaterCategoryUrban.
  ///
  /// In zh, this message translates to:
  /// **'都市'**
  String get theaterCategoryUrban;

  /// No description provided for @theaterSortHottest.
  ///
  /// In zh, this message translates to:
  /// **'最热'**
  String get theaterSortHottest;

  /// No description provided for @theaterSortNewest.
  ///
  /// In zh, this message translates to:
  /// **'最新'**
  String get theaterSortNewest;

  /// No description provided for @theaterSortTopRated.
  ///
  /// In zh, this message translates to:
  /// **'最高收藏'**
  String get theaterSortTopRated;

  /// No description provided for @theaterSortCompletedView.
  ///
  /// In zh, this message translates to:
  /// **'最高完播'**
  String get theaterSortCompletedView;

  /// No description provided for @theaterPlayCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 次播放'**
  String theaterPlayCount(String count);

  /// No description provided for @createDramaBasicInfo.
  ///
  /// In zh, this message translates to:
  /// **'基本信息'**
  String get createDramaBasicInfo;

  /// No description provided for @createDramaEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'剧集管理'**
  String get createDramaEpisodes;

  /// No description provided for @createDramaRoles.
  ///
  /// In zh, this message translates to:
  /// **'绑定 IP'**
  String get createDramaRoles;

  /// No description provided for @createDramaCover.
  ///
  /// In zh, this message translates to:
  /// **'封面'**
  String get createDramaCover;

  /// No description provided for @createDramaCoverUpload.
  ///
  /// In zh, this message translates to:
  /// **'上传'**
  String get createDramaCoverUpload;

  /// No description provided for @createDramaCoverPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'支持 JPG/PNG，不超过 5MB'**
  String get createDramaCoverPlaceholder;

  /// No description provided for @createDramaCoverCropTitle.
  ///
  /// In zh, this message translates to:
  /// **'裁剪封面'**
  String get createDramaCoverCropTitle;

  /// No description provided for @createDramaName.
  ///
  /// In zh, this message translates to:
  /// **'短剧标题'**
  String get createDramaName;

  /// No description provided for @createDramaNameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入短剧标题'**
  String get createDramaNameHint;

  /// No description provided for @createDramaSynopsis.
  ///
  /// In zh, this message translates to:
  /// **'简介'**
  String get createDramaSynopsis;

  /// No description provided for @createDramaTags.
  ///
  /// In zh, this message translates to:
  /// **'标签'**
  String get createDramaTags;

  /// No description provided for @createDramaTagsHint.
  ///
  /// In zh, this message translates to:
  /// **'输入标签并按回车添加 (如: 爱情, 喜剧)'**
  String get createDramaTagsHint;

  /// No description provided for @createDramaTagsLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载标签中…'**
  String get createDramaTagsLoading;

  /// No description provided for @createDramaTagsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无可用标签'**
  String get createDramaTagsEmpty;

  /// No description provided for @createDramaTagsRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get createDramaTagsRetry;

  /// No description provided for @createDramaUploadDesc.
  ///
  /// In zh, this message translates to:
  /// **'点击上传，提交后会按视频名称自动排序'**
  String get createDramaUploadDesc;

  /// No description provided for @createDramaEpisodesDesc.
  ///
  /// In zh, this message translates to:
  /// **'批量上传视频文件，系统将自动按文件名排序生成剧集列表。支持拖拽排序、删除、编辑标题等操作。'**
  String get createDramaEpisodesDesc;

  /// No description provided for @createDramaVideoFileTypeHint.
  ///
  /// In zh, this message translates to:
  /// **'限制文件类型 mp4, flv, wmv, asf, mkv, avi, rm, rmvb, mpg, mpeg, mov, webm 文件大小不超过2GB'**
  String get createDramaVideoFileTypeHint;

  /// No description provided for @createDramaUploadVideo.
  ///
  /// In zh, this message translates to:
  /// **'上传视频'**
  String get createDramaUploadVideo;

  /// No description provided for @createDramaVideoEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有添加视频'**
  String get createDramaVideoEmpty;

  /// No description provided for @createDramaVideoPickFailed.
  ///
  /// In zh, this message translates to:
  /// **'选择视频失败'**
  String get createDramaVideoPickFailed;

  /// No description provided for @createDramaVideoAnyTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'所选视频中有文件超过2GB, 请调整后重新上传'**
  String get createDramaVideoAnyTooLarge;

  /// No description provided for @createDramaVideoStatusUploading.
  ///
  /// In zh, this message translates to:
  /// **'上传中'**
  String get createDramaVideoStatusUploading;

  /// No description provided for @createDramaVideoStatusPaused.
  ///
  /// In zh, this message translates to:
  /// **'上传已暂停'**
  String get createDramaVideoStatusPaused;

  /// No description provided for @createDramaVideoStatusDone.
  ///
  /// In zh, this message translates to:
  /// **'上传完成'**
  String get createDramaVideoStatusDone;

  /// No description provided for @createDramaEpisodeDescriptionHint.
  ///
  /// In zh, this message translates to:
  /// **'分集描述'**
  String get createDramaEpisodeDescriptionHint;

  /// No description provided for @createDramaVideoStatusFailed.
  ///
  /// In zh, this message translates to:
  /// **'上传失败'**
  String get createDramaVideoStatusFailed;

  /// No description provided for @createDramaVideoTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'视频大小不能超过 2GB，无法上传'**
  String get createDramaVideoTooLarge;

  /// No description provided for @createDramaVideoUploadComplete.
  ///
  /// In zh, this message translates to:
  /// **'全部视频上传完成'**
  String get createDramaVideoUploadComplete;

  /// No description provided for @createDramaVideoUploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'{name} 上传失败'**
  String createDramaVideoUploadFailed(String name);

  /// No description provided for @createDramaVideoPickOverflow.
  ///
  /// In zh, this message translates to:
  /// **'最多只能再添加 {count} 集视频，多出的 {overflow} 个未加入'**
  String createDramaVideoPickOverflow(int count, int overflow);

  /// No description provided for @createDramaAddedVideos.
  ///
  /// In zh, this message translates to:
  /// **'已添加的视频 ({count} 个文件)'**
  String createDramaAddedVideos(String count);

  /// No description provided for @createDramaAddedVideosCount.
  ///
  /// In zh, this message translates to:
  /// **'({count} 个文件)'**
  String createDramaAddedVideosCount(String count);

  /// No description provided for @createDramaAddedVideosLabel.
  ///
  /// In zh, this message translates to:
  /// **'已添加的视频'**
  String get createDramaAddedVideosLabel;

  /// No description provided for @createDramaRolesDesc.
  ///
  /// In zh, this message translates to:
  /// **'为短剧创建人物，设定人物名称、头像与性格简介。'**
  String get createDramaRolesDesc;

  /// No description provided for @createDramaRolesRule1.
  ///
  /// In zh, this message translates to:
  /// **'每部短剧最多绑定 5 个角色 IP，上架 7 天内可新增，发布后不可解除或更换。'**
  String get createDramaRolesRule1;

  /// 绑定角色 IP 后，完播与热度数据的关联说明。
  ///
  /// In zh, this message translates to:
  /// **'绑定后，角色IP将关联短剧的完播和热度数据，用于升级角色和产出STORY。'**
  String get createDramaRolesRule2;

  /// No description provided for @createDramaRolesExpireTime.
  ///
  /// In zh, this message translates to:
  /// **'截止时间'**
  String get createDramaRolesExpireTime;

  /// No description provided for @createDramaRolesRule3.
  ///
  /// In zh, this message translates to:
  /// **'绑定 IP 为选填，可不绑定直接发布。'**
  String get createDramaRolesRule3;

  /// No description provided for @createDramaAddRole.
  ///
  /// In zh, this message translates to:
  /// **'添加人物'**
  String get createDramaAddRole;

  /// No description provided for @createDramaBindActor.
  ///
  /// In zh, this message translates to:
  /// **'角色参演'**
  String get createDramaBindActor;

  /// No description provided for @createDramaRoleActing.
  ///
  /// In zh, this message translates to:
  /// **'角色参演'**
  String get createDramaRoleActing;

  /// No description provided for @createDramaSelectActor.
  ///
  /// In zh, this message translates to:
  /// **'选择角色'**
  String get createDramaSelectActor;

  /// No description provided for @createDramaBindActorTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择角色 IP'**
  String get createDramaBindActorTitle;

  /// No description provided for @createDramaBindIpSelectedCount.
  ///
  /// In zh, this message translates to:
  /// **'已选 {count} 个'**
  String createDramaBindIpSelectedCount(int count);

  /// No description provided for @createDramaBindIpEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get createDramaBindIpEmpty;

  /// No description provided for @createDramaBindIpMarketplace.
  ///
  /// In zh, this message translates to:
  /// **'前往角色IP市场'**
  String get createDramaBindIpMarketplace;

  /// No description provided for @createDramaBindIpConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认绑定'**
  String get createDramaBindIpConfirm;

  /// No description provided for @createDramaBindActorSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'选择一名角色IP来饰演「{roleName}」'**
  String createDramaBindActorSubtitle(String roleName);

  /// No description provided for @createDramaBindActorOwnedCount.
  ///
  /// In zh, this message translates to:
  /// **'持有 {count} 个角色IP'**
  String createDramaBindActorOwnedCount(int count);

  /// No description provided for @createDramaBindActorIpLabel.
  ///
  /// In zh, this message translates to:
  /// **'角色IP {code}'**
  String createDramaBindActorIpLabel(String code);

  /// No description provided for @createDramaBindActorBoundTag.
  ///
  /// In zh, this message translates to:
  /// **'已绑定'**
  String get createDramaBindActorBoundTag;

  /// No description provided for @createDramaBindIpRemove.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get createDramaBindIpRemove;

  /// No description provided for @createDramaBindActorBoundToast.
  ///
  /// In zh, this message translates to:
  /// **'已绑定 {name}'**
  String createDramaBindActorBoundToast(String name);

  /// No description provided for @createDramaBindActorUnbind.
  ///
  /// In zh, this message translates to:
  /// **'解除绑定'**
  String get createDramaBindActorUnbind;

  /// No description provided for @createDramaBindActorExpired.
  ///
  /// In zh, this message translates to:
  /// **'已超过 7天窗口期，不可新增绑定角色IP'**
  String get createDramaBindActorExpired;

  /// No description provided for @createDramaBindActorEmptyTitle.
  ///
  /// In zh, this message translates to:
  /// **'暂无可绑定的角色IP'**
  String get createDramaBindActorEmptyTitle;

  /// No description provided for @createDramaBindActorEmptyDesc.
  ///
  /// In zh, this message translates to:
  /// **'你需要先持有角色IP才能绑定到人物'**
  String get createDramaBindActorEmptyDesc;

  /// No description provided for @createDramaBindActorGotoCreate.
  ///
  /// In zh, this message translates to:
  /// **'去创建角色'**
  String get createDramaBindActorGotoCreate;

  /// No description provided for @createDramaPrevStep.
  ///
  /// In zh, this message translates to:
  /// **'上一步'**
  String get createDramaPrevStep;

  /// No description provided for @createDramaNextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get createDramaNextStep;

  /// No description provided for @createDramaSubmit.
  ///
  /// In zh, this message translates to:
  /// **'发布'**
  String get createDramaSubmit;

  /// No description provided for @createDramaRoleNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'人物名称'**
  String get createDramaRoleNameLabel;

  /// No description provided for @createDramaRoleNameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入人物名称'**
  String get createDramaRoleNameHint;

  /// No description provided for @createDramaRoleNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入人物名'**
  String get createDramaRoleNameRequired;

  /// No description provided for @createDramaRoleBioLabel.
  ///
  /// In zh, this message translates to:
  /// **'简介'**
  String get createDramaRoleBioLabel;

  /// No description provided for @createDramaRoleBioHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入人物简介'**
  String get createDramaRoleBioHint;

  /// No description provided for @createDramaRoleBioRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入人物简介'**
  String get createDramaRoleBioRequired;

  /// No description provided for @createDramaRoleAddTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加人物'**
  String get createDramaRoleAddTitle;

  /// No description provided for @createDramaRoleEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑人物'**
  String get createDramaRoleEditTitle;

  /// No description provided for @createDramaRoleUploadAvatar.
  ///
  /// In zh, this message translates to:
  /// **'上传头像'**
  String get createDramaRoleUploadAvatar;

  /// No description provided for @createDramaRoleSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get createDramaRoleSave;

  /// No description provided for @createDramaRoleDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除该人物？'**
  String get createDramaRoleDeleteConfirm;

  /// No description provided for @createDramaVideoDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除“{name}”吗？'**
  String createDramaVideoDeleteConfirm(String name);

  /// No description provided for @createDramaVideoDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除视频'**
  String get createDramaVideoDeleteTitle;

  /// No description provided for @createDramaVideoPreviewUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'历史上传视频，暂不支持播放预览'**
  String get createDramaVideoPreviewUnavailable;

  /// No description provided for @createDramaRoleEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂未添加人物'**
  String get createDramaRoleEmpty;

  /// No description provided for @createDramaRoleBindComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'绑定角色功能即将上线'**
  String get createDramaRoleBindComingSoon;

  /// No description provided for @createDramaRoleAvatarCropTitle.
  ///
  /// In zh, this message translates to:
  /// **'裁剪人物头像'**
  String get createDramaRoleAvatarCropTitle;

  /// No description provided for @createDramaRoleAvatarUploadFailed.
  ///
  /// In zh, this message translates to:
  /// **'人物头像上传失败'**
  String get createDramaRoleAvatarUploadFailed;

  /// No description provided for @createDramaPublishedSuccess.
  ///
  /// In zh, this message translates to:
  /// **'发布成功'**
  String get createDramaPublishedSuccess;

  /// No description provided for @createDramaDraftRestored.
  ///
  /// In zh, this message translates to:
  /// **'已同步草稿数据'**
  String get createDramaDraftRestored;

  /// No description provided for @createDramaDraftClear.
  ///
  /// In zh, this message translates to:
  /// **'清除数据'**
  String get createDramaDraftClear;

  /// No description provided for @createDramaDraftDiscard.
  ///
  /// In zh, this message translates to:
  /// **'不保存返回'**
  String get createDramaDraftDiscard;

  /// No description provided for @createDramaDraftSave.
  ///
  /// In zh, this message translates to:
  /// **'存草稿'**
  String get createDramaDraftSave;

  /// No description provided for @createDramaEditLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get createDramaEditLoading;

  /// No description provided for @createDramaEditLoadError.
  ///
  /// In zh, this message translates to:
  /// **'加载短剧信息失败，请重试'**
  String get createDramaEditLoadError;

  /// No description provided for @createDramaSubmitValidationTitle.
  ///
  /// In zh, this message translates to:
  /// **'请填写短剧标题'**
  String get createDramaSubmitValidationTitle;

  /// No description provided for @createDramaSubmitValidationCover.
  ///
  /// In zh, this message translates to:
  /// **'请上传封面图'**
  String get createDramaSubmitValidationCover;

  /// No description provided for @createDramaSubmitValidationVideos.
  ///
  /// In zh, this message translates to:
  /// **'请至少上传一个视频'**
  String get createDramaSubmitValidationVideos;

  /// No description provided for @createDramaSubmitValidationSession.
  ///
  /// In zh, this message translates to:
  /// **'上传会话异常，请重新上传视频'**
  String get createDramaSubmitValidationSession;

  /// No description provided for @createDramaUploadSessionFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建上传会话失败'**
  String get createDramaUploadSessionFailed;

  /// No description provided for @createDramaSubmitValidationRoles.
  ///
  /// In zh, this message translates to:
  /// **'请至少添加一个人物'**
  String get createDramaSubmitValidationRoles;

  /// No description provided for @createDramaStep1TitleRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入短剧标题'**
  String get createDramaStep1TitleRequired;

  /// No description provided for @createDramaStep1SynopsisRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入简介'**
  String get createDramaStep1SynopsisRequired;

  /// No description provided for @createDramaStep1CoverRequired.
  ///
  /// In zh, this message translates to:
  /// **'请添加封面'**
  String get createDramaStep1CoverRequired;

  /// No description provided for @createDramaStep1TagsRequired.
  ///
  /// In zh, this message translates to:
  /// **'请选择标签'**
  String get createDramaStep1TagsRequired;

  /// No description provided for @createDramaEpisodeDescriptionRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入分集描述'**
  String get createDramaEpisodeDescriptionRequired;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In zh, this message translates to:
  /// **'主题'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In zh, this message translates to:
  /// **'日间'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In zh, this message translates to:
  /// **'夜间'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In zh, this message translates to:
  /// **'系统'**
  String get settingsThemeSystem;

  /// No description provided for @settingsUI.
  ///
  /// In zh, this message translates to:
  /// **'界面'**
  String get settingsUI;

  /// No description provided for @settingsAppVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get settingsAppVersion;

  /// No description provided for @settingsVersionLatestToast.
  ///
  /// In zh, this message translates to:
  /// **'当前版本为最新版本'**
  String get settingsVersionLatestToast;

  /// No description provided for @settingsVersionCheckFailed.
  ///
  /// In zh, this message translates to:
  /// **'版本检查失败，请稍后再试'**
  String get settingsVersionCheckFailed;

  /// No description provided for @appVersionUpdateTitle.
  ///
  /// In zh, this message translates to:
  /// **'发现新版本'**
  String get appVersionUpdateTitle;

  /// No description provided for @appVersionUpdateContentsLabel.
  ///
  /// In zh, this message translates to:
  /// **'更新内容：'**
  String get appVersionUpdateContentsLabel;

  /// No description provided for @appVersionUpdateConfirm.
  ///
  /// In zh, this message translates to:
  /// **'立即更新'**
  String get appVersionUpdateConfirm;

  /// No description provided for @appVersionUpdateLater.
  ///
  /// In zh, this message translates to:
  /// **'以后再说'**
  String get appVersionUpdateLater;

  /// No description provided for @settingsTermsOfService.
  ///
  /// In zh, this message translates to:
  /// **'服务条款'**
  String get settingsTermsOfService;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In zh, this message translates to:
  /// **'删除账户'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountConfirm.
  ///
  /// In zh, this message translates to:
  /// **'您的账户将在 {deadline} 被删除。在此时间内，您可以再次登录以取消账户删除。'**
  String settingsDeleteAccountConfirm(String deadline);

  /// No description provided for @settingsDeleteAccountSuccess.
  ///
  /// In zh, this message translates to:
  /// **'删除账户申请已提交'**
  String get settingsDeleteAccountSuccess;

  /// No description provided for @settingsClearCache.
  ///
  /// In zh, this message translates to:
  /// **'清理缓存'**
  String get settingsClearCache;

  /// No description provided for @settingsNetworkInspector.
  ///
  /// In zh, this message translates to:
  /// **'网络请求'**
  String get settingsNetworkInspector;

  /// No description provided for @settingsClearCacheConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认要清理缓存吗？'**
  String get settingsClearCacheConfirm;

  /// No description provided for @miningRulesHowToPlay.
  ///
  /// In zh, this message translates to:
  /// **'派遣挖矿怎么玩'**
  String get miningRulesHowToPlay;

  /// No description provided for @miningRulesFlowSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'一张图看懂从派人到领钱的全流程'**
  String get miningRulesFlowSubtitle;

  /// No description provided for @miningRulesSection1Title.
  ///
  /// In zh, this message translates to:
  /// **'派遣'**
  String get miningRulesSection1Title;

  /// No description provided for @miningRulesSection1Desc.
  ///
  /// In zh, this message translates to:
  /// **'把空闲的角色「派遣」到下面的 5 个槽位里，他就开始自动挖矿、产出 STORY。'**
  String get miningRulesSection1Desc;

  /// No description provided for @miningRulesSection1Bullet1.
  ///
  /// In zh, this message translates to:
  /// **'每人最多同时派遣 5 位角色'**
  String get miningRulesSection1Bullet1;

  /// No description provided for @miningRulesSection1Bullet2.
  ///
  /// In zh, this message translates to:
  /// **'同一个角色IP也可以多张卡一起派遣'**
  String get miningRulesSection1Bullet2;

  /// No description provided for @miningRulesSection1Bullet3.
  ///
  /// In zh, this message translates to:
  /// **'派遣后每小时消耗 1 点体力，体力 > 0 就一直产出，体力 = 0 就停工'**
  String get miningRulesSection1Bullet3;

  /// No description provided for @miningRulesSection2Title.
  ///
  /// In zh, this message translates to:
  /// **'产出公式'**
  String get miningRulesSection2Title;

  /// No description provided for @miningRulesSection2Desc.
  ///
  /// In zh, this message translates to:
  /// **'每张卡每小时的产出是这样算的：'**
  String get miningRulesSection2Desc;

  /// No description provided for @miningRulesSection2Formula.
  ///
  /// In zh, this message translates to:
  /// **'单卡小时产出 = 角色片酬 × 1 STORY'**
  String get miningRulesSection2Formula;

  /// No description provided for @miningRulesSection2FactorsTitle.
  ///
  /// In zh, this message translates to:
  /// **'其中：'**
  String get miningRulesSection2FactorsTitle;

  /// No description provided for @miningRulesSection2Factor1.
  ///
  /// In zh, this message translates to:
  /// **'角色片酬= IP片酬 × 挖矿系数 × CP系数 × Trust2'**
  String get miningRulesSection2Factor1;

  /// No description provided for @miningRulesSection2Factor2.
  ///
  /// In zh, this message translates to:
  /// **'IP 片酬= 价格系数 × 热度系数 × Trust1'**
  String get miningRulesSection2Factor2;

  /// No description provided for @miningRulesSection2Factor3.
  ///
  /// In zh, this message translates to:
  /// **'挖矿系数——咖位越高系数越大。Lv1=1.0 → Lv2=2.2 → Lv3=5.0 → Lv4=11 → Lv5=24'**
  String get miningRulesSection2Factor3;

  /// No description provided for @miningRulesSection2Factor4.
  ///
  /// In zh, this message translates to:
  /// **'价格系数——发行价 P0：P0≤10{currency1} 线性增长 · P0>10{currency2} 渐近上限 1.6'**
  String miningRulesSection2Factor4(String currency1, String currency2);

  /// No description provided for @miningRulesSection2Factor5.
  ///
  /// In zh, this message translates to:
  /// **'热度系数——近期剧表现越好热度越高（完播、点赞、收藏、评论）'**
  String get miningRulesSection2Factor5;

  /// No description provided for @miningRulesSection2Factor6.
  ///
  /// In zh, this message translates to:
  /// **'CP 系数——暂未开放；Trust 默认 1.0'**
  String get miningRulesSection2Factor6;

  /// No description provided for @miningRulesSection2StaminaText.
  ///
  /// In zh, this message translates to:
  /// **'体力只看\"有没有\"：{staminaLimit} 点和 1 点体力的每小时产出一样多。'**
  String miningRulesSection2StaminaText(int staminaLimit);

  /// No description provided for @miningRulesSection2ExampleTitle.
  ///
  /// In zh, this message translates to:
  /// **'示例'**
  String get miningRulesSection2ExampleTitle;

  /// No description provided for @miningRulesSection2ExampleDesc.
  ///
  /// In zh, this message translates to:
  /// **'林梦瑶 Lv3 主角 · P0=12{currency}（价格系数 ≈1.0859）· 热度 3.5\n→ 每小时产出 = 5.0 × 1.0859 × 3.5 × 1 = 19.00325 STORY'**
  String miningRulesSection2ExampleDesc(String currency);

  /// No description provided for @miningRulesCoefTableTitle.
  ///
  /// In zh, this message translates to:
  /// **'各系数说明'**
  String get miningRulesCoefTableTitle;

  /// No description provided for @miningRulesCoefColCoef.
  ///
  /// In zh, this message translates to:
  /// **'系数'**
  String get miningRulesCoefColCoef;

  /// No description provided for @miningRulesCoefColFactor.
  ///
  /// In zh, this message translates to:
  /// **'决定因素'**
  String get miningRulesCoefColFactor;

  /// No description provided for @miningRulesCoefColDesc.
  ///
  /// In zh, this message translates to:
  /// **'说明'**
  String get miningRulesCoefColDesc;

  /// No description provided for @miningRulesCoefMining.
  ///
  /// In zh, this message translates to:
  /// **'挖矿系数'**
  String get miningRulesCoefMining;

  /// No description provided for @miningRulesCoefPrice.
  ///
  /// In zh, this message translates to:
  /// **'价格系数'**
  String get miningRulesCoefPrice;

  /// No description provided for @miningRulesCoefHeat.
  ///
  /// In zh, this message translates to:
  /// **'热度系数'**
  String get miningRulesCoefHeat;

  /// No description provided for @miningRulesCoefCp.
  ///
  /// In zh, this message translates to:
  /// **'CP 系数'**
  String get miningRulesCoefCp;

  /// No description provided for @miningRulesCoefTrust.
  ///
  /// In zh, this message translates to:
  /// **'Trust'**
  String get miningRulesCoefTrust;

  /// No description provided for @miningRulesCoefMiningFactor.
  ///
  /// In zh, this message translates to:
  /// **'咖位'**
  String get miningRulesCoefMiningFactor;

  /// No description provided for @miningRulesCoefPriceFactor.
  ///
  /// In zh, this message translates to:
  /// **'发行价 P0'**
  String get miningRulesCoefPriceFactor;

  /// No description provided for @miningRulesCoefHeatFactor.
  ///
  /// In zh, this message translates to:
  /// **'近期剧表现'**
  String get miningRulesCoefHeatFactor;

  /// No description provided for @miningRulesCoefCpFactor.
  ///
  /// In zh, this message translates to:
  /// **'-'**
  String get miningRulesCoefCpFactor;

  /// No description provided for @miningRulesCoefTrustFactor.
  ///
  /// In zh, this message translates to:
  /// **'平台风控'**
  String get miningRulesCoefTrustFactor;

  /// No description provided for @miningRulesCoefMiningDesc.
  ///
  /// In zh, this message translates to:
  /// **'Lv1=1.0 · Lv2=2.2 · Lv3=5.0 · Lv4=11 · Lv5=24'**
  String get miningRulesCoefMiningDesc;

  /// No description provided for @miningRulesCoefPriceDesc.
  ///
  /// In zh, this message translates to:
  /// **'P0≤10{currency1} 线性增长 · P0>10{currency2} 渐近上限 1.6'**
  String miningRulesCoefPriceDesc(String currency1, String currency2);

  /// No description provided for @miningRulesCoefHeatDesc.
  ///
  /// In zh, this message translates to:
  /// **'热度系数：角色IP参演短剧的完播、点赞、收藏、评分越多，热度越高'**
  String get miningRulesCoefHeatDesc;

  /// No description provided for @miningRulesCoefCpDesc.
  ///
  /// In zh, this message translates to:
  /// **'暂未开放'**
  String get miningRulesCoefCpDesc;

  /// No description provided for @miningRulesCoefTrustDesc.
  ///
  /// In zh, this message translates to:
  /// **'默认 1.0'**
  String get miningRulesCoefTrustDesc;

  /// No description provided for @miningRulesSection3Title.
  ///
  /// In zh, this message translates to:
  /// **'结算分配'**
  String get miningRulesSection3Title;

  /// No description provided for @miningRulesSection3Desc.
  ///
  /// In zh, this message translates to:
  /// **'每周全平台有一个总奖池（周硬顶），初始约 2,115,385 STORY，之后逐周递减（每周 × 0.99572）。'**
  String get miningRulesSection3Desc;

  /// No description provided for @miningRulesSettleColCondition.
  ///
  /// In zh, this message translates to:
  /// **'条件'**
  String get miningRulesSettleColCondition;

  /// No description provided for @miningRulesSettleColRule.
  ///
  /// In zh, this message translates to:
  /// **'分配规则'**
  String get miningRulesSettleColRule;

  /// No description provided for @miningRulesSection3Case1Title.
  ///
  /// In zh, this message translates to:
  /// **'全网名义产出 ≤ 当周硬顶'**
  String get miningRulesSection3Case1Title;

  /// No description provided for @miningRulesSection3Case1Desc.
  ///
  /// In zh, this message translates to:
  /// **'每人照单全收，剩余部分不发、不补'**
  String get miningRulesSection3Case1Desc;

  /// No description provided for @miningRulesSection3Case2Title.
  ///
  /// In zh, this message translates to:
  /// **'全网名义产出 > 当周硬顶'**
  String get miningRulesSection3Case2Title;

  /// No description provided for @miningRulesSection3Case2Desc.
  ///
  /// In zh, this message translates to:
  /// **'等比缩放：你实得 = 你的名义产出 × 奖池 ÷ 全网产出'**
  String get miningRulesSection3Case2Desc;

  /// No description provided for @miningRulesSection3Case3Title.
  ///
  /// In zh, this message translates to:
  /// **'单地址超过奖池 5%'**
  String get miningRulesSection3Case3Title;

  /// No description provided for @miningRulesSection3Case3Desc.
  ///
  /// In zh, this message translates to:
  /// **'超出部分不发，不回流，不补分'**
  String get miningRulesSection3Case3Desc;

  /// No description provided for @miningRulesSection3ExampleDesc.
  ///
  /// In zh, this message translates to:
  /// **'假设本周奖池 100,000 STORY：\n情况 A：全平台只有你产出 134 → 你拿 134，剩下不发放\n情况 B：全网产出 250,000 → 等比缩放到 40%\n情况 C：缩放后某人应得 6,000，但上限 5,000 → 只发 5,000'**
  String get miningRulesSection3ExampleDesc;

  /// No description provided for @miningRulesSection4Title.
  ///
  /// In zh, this message translates to:
  /// **'体力管理'**
  String get miningRulesSection4Title;

  /// No description provided for @miningRulesTableStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get miningRulesTableStatus;

  /// No description provided for @miningRulesTableStaminaChange.
  ///
  /// In zh, this message translates to:
  /// **'体力变化'**
  String get miningRulesTableStaminaChange;

  /// No description provided for @miningRulesTableOutput.
  ///
  /// In zh, this message translates to:
  /// **'产出'**
  String get miningRulesTableOutput;

  /// No description provided for @miningRulesStatusMining.
  ///
  /// In zh, this message translates to:
  /// **'派遣中（挖矿）'**
  String get miningRulesStatusMining;

  /// No description provided for @miningRulesStaminaMining.
  ///
  /// In zh, this message translates to:
  /// **'每小时 -1'**
  String get miningRulesStaminaMining;

  /// No description provided for @miningRulesOutputNormal.
  ///
  /// In zh, this message translates to:
  /// **'正常产出'**
  String get miningRulesOutputNormal;

  /// No description provided for @miningRulesStatusZeroStamina.
  ///
  /// In zh, this message translates to:
  /// **'体力耗尽'**
  String get miningRulesStatusZeroStamina;

  /// No description provided for @miningRulesStaminaZeroStamina.
  ///
  /// In zh, this message translates to:
  /// **'不再变化'**
  String get miningRulesStaminaZeroStamina;

  /// No description provided for @miningRulesOutputZero.
  ///
  /// In zh, this message translates to:
  /// **'产出为 0'**
  String get miningRulesOutputZero;

  /// No description provided for @miningRulesStatusResting.
  ///
  /// In zh, this message translates to:
  /// **'召回休息'**
  String get miningRulesStatusResting;

  /// No description provided for @miningRulesStaminaResting.
  ///
  /// In zh, this message translates to:
  /// **'每小时 +1（自动恢复）'**
  String get miningRulesStaminaResting;

  /// No description provided for @miningRulesOutputPaused.
  ///
  /// In zh, this message translates to:
  /// **'暂停产出'**
  String get miningRulesOutputPaused;

  /// No description provided for @miningRulesStatusPaidRefill.
  ///
  /// In zh, this message translates to:
  /// **'补充体力（付费）'**
  String get miningRulesStatusPaidRefill;

  /// No description provided for @miningRulesStaminaPaidRefill.
  ///
  /// In zh, this message translates to:
  /// **'瞬间回满 {staminaLimit}'**
  String miningRulesStaminaPaidRefill(int staminaLimit);

  /// No description provided for @miningRulesOutputRestored.
  ///
  /// In zh, this message translates to:
  /// **'恢复产出'**
  String get miningRulesOutputRestored;

  /// No description provided for @miningRulesSection4TipsTitle.
  ///
  /// In zh, this message translates to:
  /// **'补充体力须知'**
  String get miningRulesSection4TipsTitle;

  /// No description provided for @miningRulesSection4Tip1.
  ///
  /// In zh, this message translates to:
  /// **'只能一键加满，不能只买 10 点'**
  String get miningRulesSection4Tip1;

  /// No description provided for @miningRulesSection4Tip2.
  ///
  /// In zh, this message translates to:
  /// **'价格只看咖位，与剩余体力无关'**
  String get miningRulesSection4Tip2;

  /// No description provided for @miningRulesSection4Tip3.
  ///
  /// In zh, this message translates to:
  /// **'越靠近 0 补充越划算——同样价格买到最多的挖矿时长'**
  String get miningRulesSection4Tip3;

  /// No description provided for @miningRulesSection4PriceTitle.
  ///
  /// In zh, this message translates to:
  /// **'补充价格'**
  String get miningRulesSection4PriceTitle;

  /// No description provided for @miningRulesPriceTableTier.
  ///
  /// In zh, this message translates to:
  /// **'咖位'**
  String get miningRulesPriceTableTier;

  /// No description provided for @miningRulesPriceTableFullRefill.
  ///
  /// In zh, this message translates to:
  /// **'一键加满'**
  String get miningRulesPriceTableFullRefill;

  /// No description provided for @miningRulesLv1.
  ///
  /// In zh, this message translates to:
  /// **'Lv1 群演'**
  String get miningRulesLv1;

  /// No description provided for @miningRulesLv2.
  ///
  /// In zh, this message translates to:
  /// **'Lv2 配角'**
  String get miningRulesLv2;

  /// No description provided for @miningRulesLv3.
  ///
  /// In zh, this message translates to:
  /// **'Lv3 主角'**
  String get miningRulesLv3;

  /// No description provided for @miningRulesLv4.
  ///
  /// In zh, this message translates to:
  /// **'Lv4 巨星'**
  String get miningRulesLv4;

  /// No description provided for @miningRulesLv5.
  ///
  /// In zh, this message translates to:
  /// **'Lv5 顶流'**
  String get miningRulesLv5;

  /// No description provided for @gameActorLevelName1.
  ///
  /// In zh, this message translates to:
  /// **'群演'**
  String get gameActorLevelName1;

  /// No description provided for @gameActorLevelName2.
  ///
  /// In zh, this message translates to:
  /// **'配角'**
  String get gameActorLevelName2;

  /// No description provided for @gameActorLevelName3.
  ///
  /// In zh, this message translates to:
  /// **'主角'**
  String get gameActorLevelName3;

  /// No description provided for @gameActorLevelName4.
  ///
  /// In zh, this message translates to:
  /// **'巨星'**
  String get gameActorLevelName4;

  /// No description provided for @gameActorLevelName5.
  ///
  /// In zh, this message translates to:
  /// **'顶流'**
  String get gameActorLevelName5;

  /// No description provided for @miningRulesLv1Price.
  ///
  /// In zh, this message translates to:
  /// **'10 {currency}'**
  String miningRulesLv1Price(String currency);

  /// No description provided for @miningRulesLv2Price.
  ///
  /// In zh, this message translates to:
  /// **'20 {currency}'**
  String miningRulesLv2Price(String currency);

  /// No description provided for @miningRulesLv3Price.
  ///
  /// In zh, this message translates to:
  /// **'50 {currency}'**
  String miningRulesLv3Price(String currency);

  /// No description provided for @miningRulesLv4Price.
  ///
  /// In zh, this message translates to:
  /// **'130 {currency}'**
  String miningRulesLv4Price(String currency);

  /// No description provided for @miningRulesLv5Price.
  ///
  /// In zh, this message translates to:
  /// **'320 {currency}'**
  String miningRulesLv5Price(String currency);

  /// No description provided for @miningRulesSection5Title.
  ///
  /// In zh, this message translates to:
  /// **'升级咖位'**
  String get miningRulesSection5Title;

  /// No description provided for @miningRulesSection5Desc.
  ///
  /// In zh, this message translates to:
  /// **'3 张同角色同咖位的卡 + 合成费 + 该角色累计完播达标 = 升 1 级。升级后挖矿系数暴涨，每小时产出翻倍甚至翻几倍。'**
  String get miningRulesSection5Desc;

  /// No description provided for @miningRulesUpgradePathSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'升级路径'**
  String get miningRulesUpgradePathSubtitle;

  /// No description provided for @miningRulesUpgradeColPath.
  ///
  /// In zh, this message translates to:
  /// **'升级路径'**
  String get miningRulesUpgradeColPath;

  /// No description provided for @miningRulesUpgradeColHeat.
  ///
  /// In zh, this message translates to:
  /// **'累计完播门槛'**
  String get miningRulesUpgradeColHeat;

  /// No description provided for @miningRulesUpgradeColFee.
  ///
  /// In zh, this message translates to:
  /// **'合成费'**
  String get miningRulesUpgradeColFee;

  /// No description provided for @miningRulesUpgradePath12.
  ///
  /// In zh, this message translates to:
  /// **'Lv1 → Lv2'**
  String get miningRulesUpgradePath12;

  /// No description provided for @miningRulesUpgradePath23.
  ///
  /// In zh, this message translates to:
  /// **'Lv2 → Lv3'**
  String get miningRulesUpgradePath23;

  /// No description provided for @miningRulesUpgradePath34.
  ///
  /// In zh, this message translates to:
  /// **'Lv3 → Lv4'**
  String get miningRulesUpgradePath34;

  /// No description provided for @miningRulesUpgradePath45.
  ///
  /// In zh, this message translates to:
  /// **'Lv4 → Lv5'**
  String get miningRulesUpgradePath45;

  /// No description provided for @miningRulesUpgradeHeat12.
  ///
  /// In zh, this message translates to:
  /// **'≥ 10,000'**
  String get miningRulesUpgradeHeat12;

  /// No description provided for @miningRulesUpgradeHeat23.
  ///
  /// In zh, this message translates to:
  /// **'≥ 50,000'**
  String get miningRulesUpgradeHeat23;

  /// No description provided for @miningRulesUpgradeHeat34.
  ///
  /// In zh, this message translates to:
  /// **'≥ 200,000'**
  String get miningRulesUpgradeHeat34;

  /// No description provided for @miningRulesUpgradeHeat45.
  ///
  /// In zh, this message translates to:
  /// **'≥ 1,000,000'**
  String get miningRulesUpgradeHeat45;

  /// No description provided for @miningRulesUpgradeFee12.
  ///
  /// In zh, this message translates to:
  /// **'10 {currency}'**
  String miningRulesUpgradeFee12(String currency);

  /// No description provided for @miningRulesUpgradeFee23.
  ///
  /// In zh, this message translates to:
  /// **'20 {currency}'**
  String miningRulesUpgradeFee23(String currency);

  /// No description provided for @miningRulesUpgradeFee34.
  ///
  /// In zh, this message translates to:
  /// **'40 {currency}'**
  String miningRulesUpgradeFee34(String currency);

  /// No description provided for @miningRulesUpgradeFee45.
  ///
  /// In zh, this message translates to:
  /// **'80 {currency}'**
  String miningRulesUpgradeFee45(String currency);

  /// No description provided for @miningRulesSummaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'一句话总结'**
  String get miningRulesSummaryTitle;

  /// No description provided for @miningRulesSummaryDesc.
  ///
  /// In zh, this message translates to:
  /// **'派人 → 产出 → 盯体力 → 领钱。体力快没了就补充或召回休息，热度靠角色的剧表现提升，升级让产出起飞。'**
  String get miningRulesSummaryDesc;

  /// No description provided for @playerNotInterested.
  ///
  /// In zh, this message translates to:
  /// **'不感兴趣'**
  String get playerNotInterested;

  /// No description provided for @playerNotInterestedDone.
  ///
  /// In zh, this message translates to:
  /// **'已反馈，将减少此类推荐'**
  String get playerNotInterestedDone;

  /// No description provided for @playerClearScreen.
  ///
  /// In zh, this message translates to:
  /// **'清屏'**
  String get playerClearScreen;

  /// No description provided for @playerAutoPlay.
  ///
  /// In zh, this message translates to:
  /// **'连播'**
  String get playerAutoPlay;

  /// No description provided for @playerReport.
  ///
  /// In zh, this message translates to:
  /// **'举报'**
  String get playerReport;

  /// No description provided for @playerReportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'举报成功'**
  String get playerReportSuccess;

  /// No description provided for @commentReportSuccess.
  ///
  /// In zh, this message translates to:
  /// **'提交成功，将为你尽快受理'**
  String get commentReportSuccess;

  /// No description provided for @reportSuccessTitle.
  ///
  /// In zh, this message translates to:
  /// **'提交成功，我们将尽快受理'**
  String get reportSuccessTitle;

  /// No description provided for @reportSuccessThanks.
  ///
  /// In zh, this message translates to:
  /// **'感谢您对社区安全做的贡献！'**
  String get reportSuccessThanks;

  /// No description provided for @reportSuccessAlsoYouCan.
  ///
  /// In zh, this message translates to:
  /// **'同时你可以'**
  String get reportSuccessAlsoYouCan;

  /// No description provided for @reportSuccessDone.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get reportSuccessDone;

  /// No description provided for @reportReduceRecommend.
  ///
  /// In zh, this message translates to:
  /// **'减少推荐'**
  String get reportReduceRecommend;

  /// No description provided for @reportReduceRecommendDone.
  ///
  /// In zh, this message translates to:
  /// **'已减少推荐'**
  String get reportReduceRecommendDone;

  /// No description provided for @reportSuccessContentFallback.
  ///
  /// In zh, this message translates to:
  /// **'该内容'**
  String get reportSuccessContentFallback;

  /// No description provided for @reportDescription.
  ///
  /// In zh, this message translates to:
  /// **'举报描述'**
  String get reportDescription;

  /// No description provided for @reportDescriptionPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'请描述具体原因（选填）'**
  String get reportDescriptionPlaceholder;

  /// No description provided for @reportReasonPorn.
  ///
  /// In zh, this message translates to:
  /// **'低俗色情'**
  String get reportReasonPorn;

  /// No description provided for @reportReasonIllegal.
  ///
  /// In zh, this message translates to:
  /// **'涉嫌违法犯罪'**
  String get reportReasonIllegal;

  /// No description provided for @reportReasonSensitive.
  ///
  /// In zh, this message translates to:
  /// **'内容敏感'**
  String get reportReasonSensitive;

  /// No description provided for @reportReasonGambling.
  ///
  /// In zh, this message translates to:
  /// **'涉黑赌博'**
  String get reportReasonGambling;

  /// No description provided for @reportReasonMinors.
  ///
  /// In zh, this message translates to:
  /// **'侵害未成年人'**
  String get reportReasonMinors;

  /// No description provided for @reportReasonCopyright.
  ///
  /// In zh, this message translates to:
  /// **'侵权投诉'**
  String get reportReasonCopyright;

  /// No description provided for @reportReasonQuality.
  ///
  /// In zh, this message translates to:
  /// **'质量问题'**
  String get reportReasonQuality;

  /// No description provided for @reportReasonNotLike.
  ///
  /// In zh, this message translates to:
  /// **'我不喜欢'**
  String get reportReasonNotLike;

  /// No description provided for @reportReasonOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get reportReasonOther;

  /// No description provided for @gameUpgrade.
  ///
  /// In zh, this message translates to:
  /// **'升级'**
  String get gameUpgrade;

  /// No description provided for @gameUpgradeTitle.
  ///
  /// In zh, this message translates to:
  /// **'咖位升级'**
  String get gameUpgradeTitle;

  /// No description provided for @gameUpgradeCurrentLevel.
  ///
  /// In zh, this message translates to:
  /// **'当前等级'**
  String get gameUpgradeCurrentLevel;

  /// No description provided for @gameUpgradeTargetLevel.
  ///
  /// In zh, this message translates to:
  /// **'目标等级'**
  String get gameUpgradeTargetLevel;

  /// No description provided for @gameUpgradeHeatThreshold.
  ///
  /// In zh, this message translates to:
  /// **'参演短剧累计完播'**
  String get gameUpgradeHeatThreshold;

  /// No description provided for @gameUpgradeRequiredCount.
  ///
  /// In zh, this message translates to:
  /// **'消耗同IP同等级角色'**
  String get gameUpgradeRequiredCount;

  /// No description provided for @gameUpgradeFee.
  ///
  /// In zh, this message translates to:
  /// **'升级费用'**
  String get gameUpgradeFee;

  /// No description provided for @gameUpgradeNextLevelReq.
  ///
  /// In zh, this message translates to:
  /// **'下一级升级要求'**
  String get gameUpgradeNextLevelReq;

  /// No description provided for @gameUpgradeBeforeAfter.
  ///
  /// In zh, this message translates to:
  /// **'升级前后对比'**
  String get gameUpgradeBeforeAfter;

  /// No description provided for @gameUpgradeSelectMaterialDesc.
  ///
  /// In zh, this message translates to:
  /// **'选择要消耗的同IP同等级角色'**
  String get gameUpgradeSelectMaterialDesc;

  /// No description provided for @gameUpgradeMaterialCount.
  ///
  /// In zh, this message translates to:
  /// **'{current}/{required}'**
  String gameUpgradeMaterialCount(int current, int required);

  /// No description provided for @gameUpgradeToLevel.
  ///
  /// In zh, this message translates to:
  /// **'升级到 Lv{level} {levelName}'**
  String gameUpgradeToLevel(int level, String levelName);

  /// No description provided for @gameUpgradeSelectMaterialLabel.
  ///
  /// In zh, this message translates to:
  /// **'选择材料 ({current}/{required})'**
  String gameUpgradeSelectMaterialLabel(int current, int required);

  /// No description provided for @gameUpgradeSelectMaterials.
  ///
  /// In zh, this message translates to:
  /// **'请选择 {count} 个材料'**
  String gameUpgradeSelectMaterials(int count);

  /// No description provided for @gameUpgradeConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认升级'**
  String get gameUpgradeConfirm;

  /// No description provided for @gameUpgradeSuccess.
  ///
  /// In zh, this message translates to:
  /// **'升级成功'**
  String get gameUpgradeSuccess;

  /// No description provided for @gameUpgradeFailed.
  ///
  /// In zh, this message translates to:
  /// **'升级失败，请重试'**
  String get gameUpgradeFailed;

  /// No description provided for @gameUpgradeInsufficientMaterials.
  ///
  /// In zh, this message translates to:
  /// **'材料不足'**
  String get gameUpgradeInsufficientMaterials;

  /// No description provided for @gameUpgradeNoMaterials.
  ///
  /// In zh, this message translates to:
  /// **'没有可消耗的同IP同等级角色'**
  String get gameUpgradeNoMaterials;

  /// No description provided for @creatorDramaStatusMinted.
  ///
  /// In zh, this message translates to:
  /// **'已铸造'**
  String get creatorDramaStatusMinted;

  /// No description provided for @creatorDramaStatusOffline.
  ///
  /// In zh, this message translates to:
  /// **'已下架'**
  String get creatorDramaStatusOffline;

  /// No description provided for @creatorDramaStatusUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'暂不可操作'**
  String get creatorDramaStatusUnavailable;

  /// No description provided for @creatorMintDramaNft.
  ///
  /// In zh, this message translates to:
  /// **'铸造短剧NFT'**
  String get creatorMintDramaNft;

  /// No description provided for @creatorMintConfirmDesc.
  ///
  /// In zh, this message translates to:
  /// **'确认铸造该短剧为链上 NFT，铸造后该短剧将可产生 STORY 挖矿收益。'**
  String get creatorMintConfirmDesc;

  /// No description provided for @creatorMintFee.
  ///
  /// In zh, this message translates to:
  /// **'铸造手续费'**
  String get creatorMintFee;

  /// No description provided for @creatorMintInsufficientUsdc.
  ///
  /// In zh, this message translates to:
  /// **'{currency1} 余额不足，链上发行需要至少 1 {currency2}'**
  String creatorMintInsufficientUsdc(String currency1, String currency2);

  /// No description provided for @creatorMintInvalidDramaId.
  ///
  /// In zh, this message translates to:
  /// **'短剧 ID 无效'**
  String get creatorMintInvalidDramaId;

  /// No description provided for @creatorMintInProgress.
  ///
  /// In zh, this message translates to:
  /// **'铸造进行中，请稍候'**
  String get creatorMintInProgress;

  /// No description provided for @creatorMintWalletNotReady.
  ///
  /// In zh, this message translates to:
  /// **'Solana 钱包地址未就绪，请重新登录'**
  String get creatorMintWalletNotReady;

  /// No description provided for @creatorMintDigestEmpty.
  ///
  /// In zh, this message translates to:
  /// **'发行签名数据为空，请稍后重试'**
  String get creatorMintDigestEmpty;

  /// No description provided for @creatorMintWalletMismatch.
  ///
  /// In zh, this message translates to:
  /// **'铸造钱包与当前钱包不一致，请重新登录'**
  String get creatorMintWalletMismatch;

  /// No description provided for @creatorMintSuccess.
  ///
  /// In zh, this message translates to:
  /// **'铸造成功！'**
  String get creatorMintSuccess;

  /// No description provided for @creatorMintDramaOnChain.
  ///
  /// In zh, this message translates to:
  /// **'《{name}》短剧NFT已上链'**
  String creatorMintDramaOnChain(String name);

  /// No description provided for @creatorMintNftNumber.
  ///
  /// In zh, this message translates to:
  /// **'NFT编号：{id}'**
  String creatorMintNftNumber(String id);

  /// No description provided for @creatorMintTxHash.
  ///
  /// In zh, this message translates to:
  /// **'交易哈希：'**
  String get creatorMintTxHash;

  /// No description provided for @gameSelectActor.
  ///
  /// In zh, this message translates to:
  /// **'选择派遣角色'**
  String get gameSelectActor;

  /// No description provided for @gameSelectActorDesc.
  ///
  /// In zh, this message translates to:
  /// **'选择一位空闲中的角色进行派遣'**
  String get gameSelectActorDesc;

  /// No description provided for @agentV2SchedulePerformance.
  ///
  /// In zh, this message translates to:
  /// **'演出'**
  String get agentV2SchedulePerformance;

  /// No description provided for @agentV2PerformAllTitle.
  ///
  /// In zh, this message translates to:
  /// **'一键演出'**
  String get agentV2PerformAllTitle;

  /// No description provided for @agentV2PerformAllDescription.
  ///
  /// In zh, this message translates to:
  /// **'将按片酬从高到低安排到空在演位'**
  String get agentV2PerformAllDescription;

  /// No description provided for @agentV2PerformAllFailed.
  ///
  /// In zh, this message translates to:
  /// **'一键演出失败，请重试'**
  String get agentV2PerformAllFailed;

  /// No description provided for @agentV2PerformAllSuccess.
  ///
  /// In zh, this message translates to:
  /// **'一键演出成功'**
  String get agentV2PerformAllSuccess;

  /// No description provided for @agentV2PerformAllDepletedResult.
  ///
  /// In zh, this message translates to:
  /// **'{successCount}位演出成功，{depletedCount}位体力耗尽暂无法演出'**
  String agentV2PerformAllDepletedResult(int successCount, int depletedCount);

  /// No description provided for @agentV2RestAllSuccess.
  ///
  /// In zh, this message translates to:
  /// **'一键休息成功'**
  String get agentV2RestAllSuccess;

  /// No description provided for @agentV2PerformAllCount.
  ///
  /// In zh, this message translates to:
  /// **'{count}个角色'**
  String agentV2PerformAllCount(int count);

  /// No description provided for @agentV2TodoTitle.
  ///
  /// In zh, this message translates to:
  /// **'待办'**
  String get agentV2TodoTitle;

  /// No description provided for @agentV2TodoVacancies.
  ///
  /// In zh, this message translates to:
  /// **'还有 {count} 个在演位空缺'**
  String agentV2TodoVacancies(int count);

  /// No description provided for @agentV2TodoStaminaDepleted.
  ///
  /// In zh, this message translates to:
  /// **'{name} 体力仅剩 0，已停工'**
  String agentV2TodoStaminaDepleted(String name);

  /// No description provided for @agentV2TodoPerform.
  ///
  /// In zh, this message translates to:
  /// **'去演出'**
  String get agentV2TodoPerform;

  /// No description provided for @agentV2TodoRefill.
  ///
  /// In zh, this message translates to:
  /// **'去补充'**
  String get agentV2TodoRefill;

  /// No description provided for @agentV2TodoHealthy.
  ///
  /// In zh, this message translates to:
  /// **'演出正常 · 体力充足'**
  String get agentV2TodoHealthy;

  /// No description provided for @agentV2CandidateActorsTitle.
  ///
  /// In zh, this message translates to:
  /// **'候选角色'**
  String get agentV2CandidateActorsTitle;

  /// No description provided for @agentV2CandidateActorsDescription.
  ///
  /// In zh, this message translates to:
  /// **'休息中的角色每小时恢复1点体力'**
  String get agentV2CandidateActorsDescription;

  /// No description provided for @agentV2UpgradeableActorsTitle.
  ///
  /// In zh, this message translates to:
  /// **'升级角色'**
  String get agentV2UpgradeableActorsTitle;

  /// No description provided for @agentV2UpgradeableActorsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无可升级角色'**
  String get agentV2UpgradeableActorsEmpty;

  /// No description provided for @agentV2NoActors.
  ///
  /// In zh, this message translates to:
  /// **'暂无角色'**
  String get agentV2NoActors;

  /// No description provided for @agentV2UpgradeNow.
  ///
  /// In zh, this message translates to:
  /// **'立即升级'**
  String get agentV2UpgradeNow;

  /// No description provided for @agentV2UpgradeCompletion.
  ///
  /// In zh, this message translates to:
  /// **'完播'**
  String get agentV2UpgradeCompletion;

  /// No description provided for @agentV2UpgradeMaterials.
  ///
  /// In zh, this message translates to:
  /// **'角色'**
  String get agentV2UpgradeMaterials;

  /// No description provided for @agentV2UpgradeRequirementsTitle.
  ///
  /// In zh, this message translates to:
  /// **'升级 {name}'**
  String agentV2UpgradeRequirementsTitle(String name);

  /// No description provided for @agentV2UpgradeCompletionRemaining.
  ///
  /// In zh, this message translates to:
  /// **'还需 {count} 完播'**
  String agentV2UpgradeCompletionRemaining(int count);

  /// No description provided for @agentV2UpgradeCompletionHint.
  ///
  /// In zh, this message translates to:
  /// **'观看该角色参演的短剧，或为它创作新剧，都可提升完播'**
  String get agentV2UpgradeCompletionHint;

  /// No description provided for @agentV2UpgradeWatchDramas.
  ///
  /// In zh, this message translates to:
  /// **'看参演短剧'**
  String get agentV2UpgradeWatchDramas;

  /// No description provided for @agentV2UpgradeCreateDrama.
  ///
  /// In zh, this message translates to:
  /// **'去创作短剧'**
  String get agentV2UpgradeCreateDrama;

  /// No description provided for @agentV2UpgradeMaterialsRemaining.
  ///
  /// In zh, this message translates to:
  /// **'还需 {count} 张同IP同等级角色'**
  String agentV2UpgradeMaterialsRemaining(int count);

  /// No description provided for @agentV2UpgradeMaterialsHint.
  ///
  /// In zh, this message translates to:
  /// **'去角色主页签约更多「{name}」'**
  String agentV2UpgradeMaterialsHint(String name);

  /// No description provided for @agentV2UpgradeGetActors.
  ///
  /// In zh, this message translates to:
  /// **'去获取角色'**
  String get agentV2UpgradeGetActors;

  /// No description provided for @agentV2UpgradeActorsSyncing.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个新角色同步中，升级条件已更新'**
  String agentV2UpgradeActorsSyncing(int count);

  /// No description provided for @agentV2UpgradeConfirmSelectMaterials.
  ///
  /// In zh, this message translates to:
  /// **'选择要消耗的同IP同等级演员'**
  String get agentV2UpgradeConfirmSelectMaterials;

  /// No description provided for @agentV2UpgradeConfirmSalaryLabel.
  ///
  /// In zh, this message translates to:
  /// **'片酬'**
  String get agentV2UpgradeConfirmSalaryLabel;

  /// No description provided for @agentV2SalaryDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'角色片酬'**
  String get agentV2SalaryDetailTitle;

  /// No description provided for @agentV2SalaryHourly.
  ///
  /// In zh, this message translates to:
  /// **'每小时片酬'**
  String get agentV2SalaryHourly;

  /// No description provided for @agentV2SalaryUnit.
  ///
  /// In zh, this message translates to:
  /// **'STORY / 小时'**
  String get agentV2SalaryUnit;

  /// No description provided for @agentV2SalaryFormula.
  ///
  /// In zh, this message translates to:
  /// **'角色片酬 = IP片酬 × 片酬系数 × CP系数 × Trust2'**
  String get agentV2SalaryFormula;

  /// No description provided for @agentV2SalaryFormulaLv1.
  ///
  /// In zh, this message translates to:
  /// **'Lv.1 角色片酬 = 价格系数 × 热度系数'**
  String get agentV2SalaryFormulaLv1;

  /// No description provided for @agentV2SalaryFormulaLevel.
  ///
  /// In zh, this message translates to:
  /// **'Lv.{level}片酬 = Lv.1片酬 × 片酬系数'**
  String agentV2SalaryFormulaLevel(int level);

  /// No description provided for @agentV2SalaryLv1Pay.
  ///
  /// In zh, this message translates to:
  /// **'Lv.1 片酬'**
  String get agentV2SalaryLv1Pay;

  /// No description provided for @agentV2SalaryCoefficient.
  ///
  /// In zh, this message translates to:
  /// **'片酬系数'**
  String get agentV2SalaryCoefficient;

  /// No description provided for @agentV2SalaryCoefficientWithLevel.
  ///
  /// In zh, this message translates to:
  /// **'片酬系数（Lv.{level} {roleName}）'**
  String agentV2SalaryCoefficientWithLevel(int level, String roleName);

  /// No description provided for @agentV2SalaryCpCoefficient.
  ///
  /// In zh, this message translates to:
  /// **'CP 系数'**
  String get agentV2SalaryCpCoefficient;

  /// No description provided for @agentV2PerformanceConfirmDescription.
  ///
  /// In zh, this message translates to:
  /// **'该角色演出时自动产生片酬收益。演出中每小时消耗 1 点体力，体力耗尽则停止产出。'**
  String get agentV2PerformanceConfirmDescription;

  /// No description provided for @agentV2PerformanceConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'安排演出'**
  String get agentV2PerformanceConfirmTitle;

  /// No description provided for @agentV2PerformanceZeroFeePrefix.
  ///
  /// In zh, this message translates to:
  /// **'该角色IP当前'**
  String get agentV2PerformanceZeroFeePrefix;

  /// No description provided for @agentV2PerformanceZeroFeeHighlight.
  ///
  /// In zh, this message translates to:
  /// **'片酬为0'**
  String get agentV2PerformanceZeroFeeHighlight;

  /// No description provided for @agentV2PerformanceZeroFeeSuffix.
  ///
  /// In zh, this message translates to:
  /// **'，演出不会产生收益。且演出中每小时消耗 1 点体力，是否仍要继续？'**
  String get agentV2PerformanceZeroFeeSuffix;

  /// No description provided for @agentV2PerformanceScheduledSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已安排演出'**
  String get agentV2PerformanceScheduledSuccess;

  /// No description provided for @agentV2PerformanceSlotsFull.
  ///
  /// In zh, this message translates to:
  /// **'演出位已满(最多5个)'**
  String get agentV2PerformanceSlotsFull;

  /// No description provided for @gameDeployStaminaDepleted.
  ///
  /// In zh, this message translates to:
  /// **'体力已耗尽，补充体力后可演出'**
  String get gameDeployStaminaDepleted;

  /// No description provided for @agentMoreRules.
  ///
  /// In zh, this message translates to:
  /// **'规则'**
  String get agentMoreRules;

  /// No description provided for @agentMoreSalaryAndPool.
  ///
  /// In zh, this message translates to:
  /// **'片酬与奖池'**
  String get agentMoreSalaryAndPool;

  /// No description provided for @agentV2WeeklySalaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'升级·演出·赚片酬'**
  String get agentV2WeeklySalaryTitle;

  /// No description provided for @agentV2WeeklySalaryLabel.
  ///
  /// In zh, this message translates to:
  /// **'本周片酬'**
  String get agentV2WeeklySalaryLabel;

  /// No description provided for @gameDeployConfirmDesc.
  ///
  /// In zh, this message translates to:
  /// **'该角色将自动进行质押挖矿，持续为你产出 STORY 收益。注意：每个整点消耗 1 点体力，体力耗尽则停止产出。'**
  String get gameDeployConfirmDesc;

  /// No description provided for @gameRecallConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认召回'**
  String get gameRecallConfirm;

  /// No description provided for @gameRecallDesc.
  ///
  /// In zh, this message translates to:
  /// **'召回此角色将暂停短剧的生产收益，且当前体力不受影响。'**
  String get gameRecallDesc;

  /// No description provided for @actorStatCompletionTitle.
  ///
  /// In zh, this message translates to:
  /// **'完播'**
  String get actorStatCompletionTitle;

  /// No description provided for @actorStatCompletionDesc.
  ///
  /// In zh, this message translates to:
  /// **'该角色IP参演的所有短剧的完播次数之和'**
  String get actorStatCompletionDesc;

  /// No description provided for @actorStatHeatTitle.
  ///
  /// In zh, this message translates to:
  /// **'热度'**
  String get actorStatHeatTitle;

  /// No description provided for @actorStatHeatDesc.
  ///
  /// In zh, this message translates to:
  /// **'该角色IP参演的所有短剧最近30天的热度之和'**
  String get actorStatHeatDesc;

  /// No description provided for @actorStatIpPowerTitle.
  ///
  /// In zh, this message translates to:
  /// **'IP片酬'**
  String get actorStatIpPowerTitle;

  /// No description provided for @actorStatIpPowerDesc.
  ///
  /// In zh, this message translates to:
  /// **'IP片酬 = 价格系数 × 热度系数 × Trust1'**
  String get actorStatIpPowerDesc;

  /// No description provided for @dramaFavoriteLabel.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get dramaFavoriteLabel;

  /// No description provided for @dramaRatingLabel.
  ///
  /// In zh, this message translates to:
  /// **'评分'**
  String get dramaRatingLabel;

  /// No description provided for @dramaUnnamed.
  ///
  /// In zh, this message translates to:
  /// **'未命名'**
  String get dramaUnnamed;

  /// No description provided for @videoNotReady.
  ///
  /// In zh, this message translates to:
  /// **'视频尚未就绪，请稍后'**
  String get videoNotReady;

  /// No description provided for @inviteDirectSubordinates.
  ///
  /// In zh, this message translates to:
  /// **'已邀请用户'**
  String get inviteDirectSubordinates;

  /// No description provided for @inviteTotalCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 人'**
  String inviteTotalCount(int count);

  /// No description provided for @inviteTotalLabel.
  ///
  /// In zh, this message translates to:
  /// **'总人数'**
  String get inviteTotalLabel;

  /// No description provided for @inviteActiveLabel.
  ///
  /// In zh, this message translates to:
  /// **'有效用户'**
  String get inviteActiveLabel;

  /// No description provided for @invitePendingLabel.
  ///
  /// In zh, this message translates to:
  /// **'待激活'**
  String get invitePendingLabel;

  /// No description provided for @inviteEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无下级用户'**
  String get inviteEmpty;

  /// No description provided for @inviteRegisteredAt.
  ///
  /// In zh, this message translates to:
  /// **'注册于 {date}'**
  String inviteRegisteredAt(String date);

  /// No description provided for @gameUpgradeMaxLevel.
  ///
  /// In zh, this message translates to:
  /// **'已达到顶级咖位'**
  String get gameUpgradeMaxLevel;

  /// No description provided for @listNoMoreData.
  ///
  /// In zh, this message translates to:
  /// **'没有更多数据了'**
  String get listNoMoreData;

  /// No description provided for @iapSheetTitle.
  ///
  /// In zh, this message translates to:
  /// **'购买点数'**
  String get iapSheetTitle;

  /// No description provided for @iapSheetSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'点数用于签约角色等 APP 内服务'**
  String get iapSheetSubtitle;

  /// No description provided for @iapBalance.
  ///
  /// In zh, this message translates to:
  /// **'余额'**
  String get iapBalance;

  /// No description provided for @iapConfirmPurchase.
  ///
  /// In zh, this message translates to:
  /// **'确认购买'**
  String get iapConfirmPurchase;

  /// No description provided for @iapPurchaseSuccess.
  ///
  /// In zh, this message translates to:
  /// **'购买成功'**
  String get iapPurchaseSuccess;

  /// No description provided for @iapPurchaseFailed.
  ///
  /// In zh, this message translates to:
  /// **'购买失败，请稍后重试'**
  String get iapPurchaseFailed;

  /// No description provided for @iapPurchaseFailedTitle.
  ///
  /// In zh, this message translates to:
  /// **'购买失败'**
  String get iapPurchaseFailedTitle;

  /// No description provided for @iapCrediting.
  ///
  /// In zh, this message translates to:
  /// **'到账处理中，请稍候'**
  String get iapCrediting;

  /// No description provided for @iapNoProducts.
  ///
  /// In zh, this message translates to:
  /// **'暂无可购买商品'**
  String get iapNoProducts;

  /// No description provided for @iapSuccessConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get iapSuccessConfirm;

  /// No description provided for @iapGainedPoints.
  ///
  /// In zh, this message translates to:
  /// **'+{value}'**
  String iapGainedPoints(String value);

  /// No description provided for @iapPointsCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 点数'**
  String iapPointsCount(int count);

  /// No description provided for @gameBatchRefillTransactionTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'批量补充交易数据过大，请减少演员数量后重试'**
  String get gameBatchRefillTransactionTooLarge;

  /// No description provided for @agentV2RefillTitle.
  ///
  /// In zh, this message translates to:
  /// **'补充体力'**
  String get agentV2RefillTitle;

  /// No description provided for @agentV2RefillCost.
  ///
  /// In zh, this message translates to:
  /// **'花费'**
  String get agentV2RefillCost;

  /// No description provided for @agentV2RefillActorButton.
  ///
  /// In zh, this message translates to:
  /// **'该角色'**
  String get agentV2RefillActorButton;

  /// No description provided for @agentV2RefillAllActors.
  ///
  /// In zh, this message translates to:
  /// **'补充全部演出中角色'**
  String get agentV2RefillAllActors;

  /// No description provided for @agentV2RefillActorCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 位'**
  String agentV2RefillActorCount(int count);

  /// No description provided for @agentV2RefillAllButton.
  ///
  /// In zh, this message translates to:
  /// **'全部补充'**
  String get agentV2RefillAllButton;

  /// No description provided for @agentV2RefillOr.
  ///
  /// In zh, this message translates to:
  /// **'或'**
  String get agentV2RefillOr;

  /// No description provided for @agentV2RestAll.
  ///
  /// In zh, this message translates to:
  /// **'全部休息'**
  String get agentV2RestAll;

  /// No description provided for @agentV2RestActorCount.
  ///
  /// In zh, this message translates to:
  /// **'{count}位'**
  String agentV2RestActorCount(int count);

  /// No description provided for @salaryPoolRateUnit.
  ///
  /// In zh, this message translates to:
  /// **'STORY / 小时'**
  String get salaryPoolRateUnit;

  /// No description provided for @salaryPoolDecayInfo.
  ///
  /// In zh, this message translates to:
  /// **'周衰减系数 ×0.99572'**
  String get salaryPoolDecayInfo;

  /// No description provided for @salaryPoolStakeLabel.
  ///
  /// In zh, this message translates to:
  /// **'演出奖池（75%）'**
  String get salaryPoolStakeLabel;

  /// No description provided for @salaryPoolInviteLabel.
  ///
  /// In zh, this message translates to:
  /// **'邀请奖池（25%）'**
  String get salaryPoolInviteLabel;

  /// No description provided for @salaryPoolRule1Title.
  ///
  /// In zh, this message translates to:
  /// **'全网名义产出 ≤ 当周硬顶：'**
  String get salaryPoolRule1Title;

  /// No description provided for @salaryPoolRule2Title.
  ///
  /// In zh, this message translates to:
  /// **'全网名义产出 > 当周硬顶：'**
  String get salaryPoolRule2Title;

  /// No description provided for @salaryPoolRule2Body.
  ///
  /// In zh, this message translates to:
  /// **'用户实得 = 用户名义产出 ×（当周硬顶 ÷ 全网名义产出）'**
  String get salaryPoolRule2Body;

  /// No description provided for @agentV3WeeklySalary.
  ///
  /// In zh, this message translates to:
  /// **'本周片酬'**
  String get agentV3WeeklySalary;

  /// No description provided for @agentV3PerformAll.
  ///
  /// In zh, this message translates to:
  /// **'一键演出'**
  String get agentV3PerformAll;

  /// No description provided for @agentV3RestAll.
  ///
  /// In zh, this message translates to:
  /// **'一键休息'**
  String get agentV3RestAll;

  /// No description provided for @agentV3RestAllDescription.
  ///
  /// In zh, this message translates to:
  /// **'将召回全部在演角色，停止消耗体力与产出'**
  String get agentV3RestAllDescription;

  /// No description provided for @agentV3RefillAll.
  ///
  /// In zh, this message translates to:
  /// **'一键补充'**
  String get agentV3RefillAll;

  /// No description provided for @agentV3RefillAllDescription.
  ///
  /// In zh, this message translates to:
  /// **'补满演出中角色的体力'**
  String get agentV3RefillAllDescription;

  /// No description provided for @agentV3RefillCost.
  ///
  /// In zh, this message translates to:
  /// **'消耗'**
  String get agentV3RefillCost;

  /// No description provided for @agentV3RefillNoActors.
  ///
  /// In zh, this message translates to:
  /// **'暂无需要补充体力的角色'**
  String get agentV3RefillNoActors;

  /// No description provided for @agentV3SignActor.
  ///
  /// In zh, this message translates to:
  /// **'签约角色'**
  String get agentV3SignActor;

  /// No description provided for @agentV3Todo.
  ///
  /// In zh, this message translates to:
  /// **'待办'**
  String get agentV3Todo;

  /// No description provided for @agentV3Upgrade.
  ///
  /// In zh, this message translates to:
  /// **'升级'**
  String get agentV3Upgrade;

  /// No description provided for @agentV3UpgradeMaterialHint.
  ///
  /// In zh, this message translates to:
  /// **'升级需消耗 {count} 张同IP同等级角色'**
  String agentV3UpgradeMaterialHint(int count);

  /// No description provided for @agentV3Waiting.
  ///
  /// In zh, this message translates to:
  /// **'候场'**
  String get agentV3Waiting;

  /// No description provided for @agentV3WaitingActorsTitle.
  ///
  /// In zh, this message translates to:
  /// **'候场角色'**
  String get agentV3WaitingActorsTitle;

  /// No description provided for @agentV3WaitingActorsDescription.
  ///
  /// In zh, this message translates to:
  /// **'休息中的角色每小时恢复1点体力'**
  String get agentV3WaitingActorsDescription;

  /// No description provided for @agentV3Recycle.
  ///
  /// In zh, this message translates to:
  /// **'回收'**
  String get agentV3Recycle;

  /// No description provided for @agentV3RecycleActorsTitle.
  ///
  /// In zh, this message translates to:
  /// **'角色回收'**
  String get agentV3RecycleActorsTitle;

  /// No description provided for @agentV3RecyclePerforming.
  ///
  /// In zh, this message translates to:
  /// **'演出中'**
  String get agentV3RecyclePerforming;

  /// No description provided for @agentV3RecycleReceive.
  ///
  /// In zh, this message translates to:
  /// **'你将获得'**
  String get agentV3RecycleReceive;

  /// No description provided for @agentV3RecyclePermanentWarning.
  ///
  /// In zh, this message translates to:
  /// **'角色将被永久销毁，不可恢复'**
  String get agentV3RecyclePermanentWarning;

  /// No description provided for @agentV3RecycleConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认销毁'**
  String get agentV3RecycleConfirm;

  /// No description provided for @agentV3RecycleConfirmAgain.
  ///
  /// In zh, this message translates to:
  /// **'再次点击销毁'**
  String get agentV3RecycleConfirmAgain;

  /// No description provided for @agentV3RecycleSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'角色回收成功'**
  String get agentV3RecycleSubmitted;

  /// No description provided for @agentV3RecycleEstimateUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'回收预估暂不可用，请重试'**
  String get agentV3RecycleEstimateUnavailable;

  /// No description provided for @agentV3EnergyPack.
  ///
  /// In zh, this message translates to:
  /// **'体力补给包'**
  String get agentV3EnergyPack;

  /// No description provided for @agentV3EnergyPackDescription.
  ///
  /// In zh, this message translates to:
  /// **'补满角色体力，按角色等级消耗。'**
  String get agentV3EnergyPackDescription;

  /// No description provided for @agentV3TrainingManual.
  ///
  /// In zh, this message translates to:
  /// **'训练手册'**
  String get agentV3TrainingManual;

  /// No description provided for @agentV3TrainingManualDescription.
  ///
  /// In zh, this message translates to:
  /// **'角色升级材料，升级时按角色等级消耗。'**
  String get agentV3TrainingManualDescription;

  /// No description provided for @agentV3PurchaseButton.
  ///
  /// In zh, this message translates to:
  /// **'购买'**
  String get agentV3PurchaseButton;

  /// No description provided for @agentV3PurchaseWalletBalance.
  ///
  /// In zh, this message translates to:
  /// **'余额 {balance} {currency}'**
  String agentV3PurchaseWalletBalance(String balance, String currency);

  /// No description provided for @agentV3PurchaseTitle.
  ///
  /// In zh, this message translates to:
  /// **'购买{item}'**
  String agentV3PurchaseTitle(String item);

  /// No description provided for @agentV3PurchaseUnitPrice.
  ///
  /// In zh, this message translates to:
  /// **'单价'**
  String get agentV3PurchaseUnitPrice;

  /// No description provided for @agentV3PurchaseQuantity.
  ///
  /// In zh, this message translates to:
  /// **'数量'**
  String get agentV3PurchaseQuantity;

  /// No description provided for @agentV3PurchaseTotal.
  ///
  /// In zh, this message translates to:
  /// **'合计'**
  String get agentV3PurchaseTotal;

  /// No description provided for @agentV3PurchaseConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认支付'**
  String get agentV3PurchaseConfirm;

  /// No description provided for @agentV3PurchaseUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'当前环境暂未开放道具购买'**
  String get agentV3PurchaseUnavailable;

  /// No description provided for @agentV3PurchaseConfigUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'道具价格暂不可用，请稍后重试'**
  String get agentV3PurchaseConfigUnavailable;

  /// No description provided for @agentV3PurchaseSubmitted.
  ///
  /// In zh, this message translates to:
  /// **'购买成功，已放入道具背包（经纪人页面）'**
  String get agentV3PurchaseSubmitted;

  /// No description provided for @agentV3PurchaseCreditPending.
  ///
  /// In zh, this message translates to:
  /// **'体力包仍在入账，请稍后重试'**
  String get agentV3PurchaseCreditPending;

  /// No description provided for @agentV3PurchaseCrediting.
  ///
  /// In zh, this message translates to:
  /// **'扫链入账中'**
  String get agentV3PurchaseCrediting;

  /// No description provided for @agentV3PurchaseBalance.
  ///
  /// In zh, this message translates to:
  /// **'当前持有：{count}'**
  String agentV3PurchaseBalance(String count);

  /// No description provided for @agentV3RefillTitle.
  ///
  /// In zh, this message translates to:
  /// **'补满体力'**
  String get agentV3RefillTitle;

  /// No description provided for @agentV3RefillLevelCost.
  ///
  /// In zh, this message translates to:
  /// **'Lv.{level} 消耗'**
  String agentV3RefillLevelCost(String level);

  /// No description provided for @agentV3RefillAvailable.
  ///
  /// In zh, this message translates to:
  /// **'可用'**
  String get agentV3RefillAvailable;

  /// No description provided for @agentV3RefillUse.
  ///
  /// In zh, this message translates to:
  /// **'使用'**
  String get agentV3RefillUse;

  /// No description provided for @agentV3RefillSuccess.
  ///
  /// In zh, this message translates to:
  /// **'体力已补满'**
  String get agentV3RefillSuccess;

  /// No description provided for @agentV3RefillAllSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已补充 {actorCount} 位角色的体力（消耗补给包 {packCount}）'**
  String agentV3RefillAllSuccess(int actorCount, String packCount);

  /// No description provided for @agentV3RefillConfigUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'体力包消耗配置暂不可用'**
  String get agentV3RefillConfigUnavailable;

  /// No description provided for @agentV3RefillInsufficient.
  ///
  /// In zh, this message translates to:
  /// **'体力包余额不足'**
  String get agentV3RefillInsufficient;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'en',
    'es',
    'ja',
    'ko',
    'tr',
    'vi',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'tr':
      return AppLocalizationsTr();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
