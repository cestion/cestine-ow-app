// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'StoryFun';

  @override
  String get commonCancel => '取消';

  @override
  String get commonNoData => '暂无数据';

  @override
  String get commonNo => '否';

  @override
  String get commonYes => '是';

  @override
  String get publishDrama => '发布短剧';

  @override
  String get publishVideo => '发布视频';

  @override
  String get publishVideoUploadTitle => '上传视频文件';

  @override
  String get publishVideoFileHint =>
      '支持 mp4、flv、wmv、mkv、avi、mov、webm 等格式，文件不超过 2GB';

  @override
  String get publishVideoChooseFile => '选择文件';

  @override
  String get publishVideoChangeFile => '更换文件';

  @override
  String get publishVideoChooseSource => '选择视频来源';

  @override
  String get publishVideoChooseFromGallery => '从相册选择';

  @override
  String get publishVideoChooseFromFiles => '从文件选择';

  @override
  String get publishVideoPreparing => '正在准备视频…';

  @override
  String get publishVideoCoverTitle => '视频封面';

  @override
  String get publishVideoChangeCover => '更换封面';

  @override
  String get publishVideoCoverHint => '支持 JPG/PNG，不超过 5MB';

  @override
  String get publishVideoDescriptionLabel => '描述';

  @override
  String get publishVideoRequired => '（必填）';

  @override
  String get publishVideoDescriptionHint => '添加作品描述（最多200字）';

  @override
  String get publishVideoSaveDraft => '保存草稿';

  @override
  String get publishVideoDraftEditModeNotSupported => '编辑模式下不能保存草稿';

  @override
  String get publishVideoDraftNothingToSave => '没有可保存的内容';

  @override
  String get publishVideoNext => '下一步';

  @override
  String get publishVideoCoverCropTitle => '裁剪视频封面';

  @override
  String get publishVideoVideoTooLarge => '该视频超过 2GB，暂不支持上传，请选择较小的视频';

  @override
  String get publishVideoVideoPickFailed => '选择视频失败，请重试';

  @override
  String get publishVideoInsufficientStorage => '设备剩余空间不足，无法准备该视频';

  @override
  String get publishVideoPermissionDenied => '无法访问该视频，请检查相册或文件权限';

  @override
  String get publishVideoSourceUnavailable => '该视频暂时无法读取，请确认云端文件已下载后重试';

  @override
  String get publishVideoPrepareFailed => '视频准备失败，请重试或从文件选择';

  @override
  String get publishVideoMetadataUnavailable => '无法读取视频信息，请选择其他文件';

  @override
  String get publishVideoCoverTooLarge => '封面图片不能超过 5MB';

  @override
  String get publishVideoCoverUnsupportedFormat => '仅支持 JPG/PNG 格式的图片';

  @override
  String get publishVideoCoverPickFailed => '选择封面失败，请重试';

  @override
  String get publishVideoUploadSessionFailed => '创建上传会话失败，请重试';

  @override
  String get publishVideoPublishedSuccess => '视频发布成功';

  @override
  String get publishVideoUpdatedSuccess => '视频修改成功';

  @override
  String get publishActorIp => '发布IP';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonOk => '我知道了';

  @override
  String get commonNotice => '提示';

  @override
  String get commonRetry => '重试';

  @override
  String get publicProfileLikedEmpty => '暂无点赞的短剧';

  @override
  String get profileTabDramas => '短剧';

  @override
  String get profileTabWorks => '作品';

  @override
  String get profileTabActorIp => '角色IP';

  @override
  String dramaUnlockConfirmLabel(String price, String currency) {
    return '$price $currency 解锁';
  }

  @override
  String dramaAllEpisodes(int count) {
    return '共 $count 集';
  }

  @override
  String dramaAllEpisodesFull(Object count) {
    return '全$count集';
  }

  @override
  String get dramaLoading => '加载精选短剧中...';

  @override
  String get dramaEmpty => '暂无短剧';

  @override
  String get dramaRefresh => '刷新';

  @override
  String get navTheater => '剧场';

  @override
  String get navHome => '首页';

  @override
  String get theaterTabShortDrama => '短剧';

  @override
  String get theaterTabRecommend => '推荐';

  @override
  String get playerWatchFullDrama => '观看完整短剧';

  @override
  String get playerStoryPerHourUnit => 'STORY/h';

  @override
  String get navNft => 'IP市场';

  @override
  String get navNftIp => '角色IP';

  @override
  String watchFullDramaEpisodes(int count) {
    return '观看完整短剧 · 全$count集';
  }

  @override
  String get navCreate => '创作';

  @override
  String get navProfile => '我';

  @override
  String get navMy => '经纪人';

  @override
  String get aboutTitle => '关于我们';

  @override
  String get aboutVision => 'AI · Web3 · 协议';

  @override
  String get aboutVisionDesc => '三种力量驱动，将叙事从被动体验转化为主动生成';

  @override
  String get aboutAiDesc => '你的想法，自动变成故事';

  @override
  String get aboutWeb3Desc => '你的创作，永远属于你';

  @override
  String get aboutProtocolDesc => '你的故事，可以无限延续';

  @override
  String get aboutIdentityTitle => '你的叙事身份';

  @override
  String get aboutIdentityDesc => '你本身，就是一个正在展开的叙事宇宙';

  @override
  String get aboutIdentityCreator => '创造者';

  @override
  String get aboutIdentityCreatorDesc => '主动书写自身的叙事';

  @override
  String get aboutIdentityWitness => '见证者';

  @override
  String get aboutIdentityWitnessDesc => '参与并验证他人叙事';

  @override
  String get aboutIdentityCoCreator => '共创者';

  @override
  String get aboutIdentityCoCreatorDesc => '进入叙事结构并进行改写';

  @override
  String get aboutIdentitySpreader => '传播者';

  @override
  String get aboutIdentitySpreaderDesc => '传播你值得的叙事';

  @override
  String get aboutTokenomicsTitle => 'STORY：叙事权通证';

  @override
  String get aboutTokenomicsDesc => '成为 AI 短剧的联合出品人，重构影视行业的利益分配格局';

  @override
  String get aboutTokenomicsGov => '治理权';

  @override
  String get aboutTokenomicsGovDesc => '投票决定下一部 AI 短剧的题材与走向';

  @override
  String get aboutTokenomicsRevenue => '收益权';

  @override
  String get aboutTokenomicsRevenueDesc => '分享平台订阅、版权授权及周边销售红利';

  @override
  String get aboutTokenomicsAccess => '访问权';

  @override
  String get aboutTokenomicsAccessDesc => '抢先观看最新剧集，解锁独家内容';

  @override
  String get aboutStakingTitle => '质押分润';

  @override
  String get aboutStakingDesc => '短剧 NFT · 角色 NFT · STORY → 质押即享分润';

  @override
  String get aboutStakingDrama => '短剧 NFT 质押';

  @override
  String get aboutStakingDramaDesc => '短剧创作者 · 获得分润';

  @override
  String get aboutStakingActor => '角色 NFT 质押';

  @override
  String get aboutStakingActorDesc => '角色参演短剧 · 获得分润';

  @override
  String get aboutStakingStory => 'STORY 质押';

  @override
  String get aboutStakingStoryDesc => '质押到短剧 · 收入分润';

  @override
  String get aboutHeroTitle => '创造属于你的故事';

  @override
  String get aboutHeroDesc => '你的人生不是被体验的剧本，而是正在被你书写的叙事';

  @override
  String get loginTitle => '邮箱登录';

  @override
  String get loginSubtitle => '通过 Privy 邮箱 OTP 登录，自动创建 Solana 嵌入式钱包。';

  @override
  String get loginPlaceholder => '输入邮箱地址';

  @override
  String get loginEmailHintFormat => '请输入邮箱';

  @override
  String get loginVerificationFailed => '验证码错误';

  @override
  String get loginNeedCodeFirst => '请先获取验证码';

  @override
  String get loginCreateWalletFailed => '创建钱包失败';

  @override
  String get loginGetTokenFailed => '获取登录凭证失败';

  @override
  String get loginPrivyUnavailable => '登录服务暂不可用，请重启应用后再试';

  @override
  String get loginSendCodeFailed => '验证码发送失败，请稍后重试';

  @override
  String get loginTooManyRequests => '请求过于频繁，请稍后再试';

  @override
  String get loginVerificationSuccessful => '验证成功';

  @override
  String get loginSendCode => '获取验证码';

  @override
  String get loginSendingCode => '发送中...';

  @override
  String get loginCodePlaceholder => '输入 6 位验证码';

  @override
  String get loginSubmit => '登录';

  @override
  String get loginSubmitting => '登录中...';

  @override
  String get loginEmailRequired => '请输入邮箱';

  @override
  String get loginCodeRequired => '请输入验证码';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get loginErrorPrefix => '登录失败：';

  @override
  String loginCodeSent(String email) {
    return '验证码已发送至 $email';
  }

  @override
  String get loginEmailLabel => '邮箱';

  @override
  String get loginCodeLabel => '验证码';

  @override
  String get loginVerifying => '验证中，请稍候...';

  @override
  String get loginVerifyAndSubmit => '验证并登录';

  @override
  String get loginChangeEmail => '换个邮箱';

  @override
  String get loginNotNow => '暂不登录';

  @override
  String get loginInvalidEmail => '请输入有效邮箱';

  @override
  String get profileTitle => '经纪人';

  @override
  String get profileNotLoggedIn => '未登录';

  @override
  String get profileClickLogin => '登录 / 注册';

  @override
  String get profileMyWallet => '我的钱包';

  @override
  String get profileWallet => '钱包';

  @override
  String get profileTradeStory => '交易 STORY';

  @override
  String get profileWalletCreating => '创建中...';

  @override
  String get walletNetworkSolana => 'Solana';

  @override
  String get walletNetworkEvm => 'EVM';

  @override
  String get profileEarnings => '收益';

  @override
  String get profileMyNft => '我的 NFT';

  @override
  String get profileMyFavorites => '我的收藏';

  @override
  String get profileWatchHistory => '观看历史';

  @override
  String get profileCreatorCatalog => '创作者目录';

  @override
  String get profileIdentityAuth => '实名认证';

  @override
  String get profileAccountSecurity => '账号安全';

  @override
  String get profileLanguage => '语言';

  @override
  String get profileAboutUs => '关于我们';

  @override
  String get profileHelpFeedback => '帮助与反馈';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileLogoutConfirm => '确认要退出登录吗？';

  @override
  String get profileLogoutSuccess => '已退出登录';

  @override
  String get mainPressBackAgainToExit => '再按一次退出';

  @override
  String get languageSelectTitle => '选择语言';

  @override
  String get languageChinese => '简体中文';

  @override
  String get languageEnglish => 'English';

  @override
  String get searchTitle => '搜索';

  @override
  String get searchHint => '搜索短剧、作品、角色、用户...';

  @override
  String get searchEmpty => '暂无相关内容';

  @override
  String get searchNoData => '暂无相关内容';

  @override
  String get searchPlaceholder => '搜索短剧、作品、角色、用户...';

  @override
  String get theaterSearchPlaceholder => '搜索短剧、作品、角色、用户...';

  @override
  String get searchHistory => '最近搜索';

  @override
  String get searchClear => '清空历史';

  @override
  String get searchAction => '搜索';

  @override
  String get searchHistoryCleared => '已清空搜索历史';

  @override
  String get searchKeywordTooShort => '请输入至少2个字符';

  @override
  String get searchTabDramas => '短剧';

  @override
  String get searchTabWorks => '作品';

  @override
  String get searchTabActors => '角色 IP';

  @override
  String get searchTabUsers => '用户';

  @override
  String searchEpisodeNo(int episodeNo) {
    return '第$episodeNo集';
  }

  @override
  String searchMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String searchHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String searchDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String searchDramasCount(int count) {
    return '短剧 ($count)';
  }

  @override
  String searchActorsCount(int count) {
    return '角色 ($count)';
  }

  @override
  String searchDramaEpisodesWithCast(int count, String actors) {
    return '全$count集 | 参演：$actors';
  }

  @override
  String get nftTitle => 'NFT 角色广场';

  @override
  String get nftLoading => '加载角色 IP 中…';

  @override
  String get nftEmpty => '暂无角色IP';

  @override
  String get nftRefresh => '刷新';

  @override
  String nftIdPrefix(String id) {
    return '编号：#$id';
  }

  @override
  String get nftRarity => '稀有度';

  @override
  String get nftStatusStaked => '已质押';

  @override
  String get nftStatusIdle => '空闲';

  @override
  String get nftPrice => '价格';

  @override
  String get dramaDetailTitle => '短剧详情';

  @override
  String get dramaDetailLoading => '加载中…';

  @override
  String get dramaDetailRetry => '重试';

  @override
  String get dramaDetailEpisodeList => '剧集列表';

  @override
  String get dramaDetailSynopsis => '剧情简介';

  @override
  String get dramaDetailExpand => '展开';

  @override
  String get dramaDetailCollapse => '收起';

  @override
  String get dramaDetailTabIntro => '简介';

  @override
  String get dramaDetailTabEpisodes => '选集';

  @override
  String get dramaDetailTabComments => '评论';

  @override
  String get dramaDetailTabRoles => '角色IP';

  @override
  String get dramaDetailSignMoreCharacterIps => '签约更多角色IP';

  @override
  String get dramaDetailCharactersEmpty => '暂未绑定角色IP';

  @override
  String dramaDetailRoleSalary(String amount) {
    return '片酬 $amount';
  }

  @override
  String dramaDetailRoleSalaryPerHour(String amount) {
    return '片酬$amount STORY/h';
  }

  @override
  String get dramaDetailRoleUnbound => '未绑定';

  @override
  String get dramaCastActorsTitle => '参演角色IP';

  @override
  String dramaDetailCompletion(String count) {
    return '$count 完播';
  }

  @override
  String dramaDetailHeat(String count) {
    return '$count 热度';
  }

  @override
  String dramaDetailTotalEpisodes(int count) {
    return '共$count集';
  }

  @override
  String get dramaDetailRatingTitle => '为作品评分';

  @override
  String get dramaDetailWantToRate => '我要评分';

  @override
  String get dramaDetailNotRated => '未评';

  @override
  String get dramaDetailCompletionLabel => '完播';

  @override
  String get dramaDetailHeatLabel => '热度';

  @override
  String get dramaDetailSynopsisLead => '简介：';

  @override
  String get dramaDetailRatingEmpty => '您的评分：--';

  @override
  String dramaDetailRatingValue(int rating) {
    return '您的评分：$rating';
  }

  @override
  String get dramaDetailRatingConfirm => '确认评分';

  @override
  String dramaDetailRatingSuccess(int rating) {
    return '评分成功：$rating 分！';
  }

  @override
  String get dramaDetailSelectEpisodeHint => '请先选择剧集开始播放';

  @override
  String get dramaFavorited => '已收藏';

  @override
  String get dramaUnfavorited => '已取消收藏';

  @override
  String get dramaLiked => '已点赞';

  @override
  String get dramaUnliked => '已取消点赞';

  @override
  String get playerFollowed => '已关注';

  @override
  String get playerUnfollowed => '已取消关注';

  @override
  String get errorNetwork => '网络错误，请稍后再试';

  @override
  String get errorTimeout => '请求超时，请稍后再试';

  @override
  String get errorParse => '数据解析失败';

  @override
  String get errorUnauthorized => '请先登录';

  @override
  String get authSessionExpired => '登录状态已失效，请重新登录';

  @override
  String get errorNotFound => '资源不存在';

  @override
  String get iapOrderInFlight => '该商品有未完成的订单，请稍后再试';

  @override
  String get errorOperationFailed => '操作失败';

  @override
  String get uploadErrorNetwork => '网络连接不稳定，请检查网络后重试';

  @override
  String get uploadErrorTimeout => '上传超时，请保持 App 在前台并重试';

  @override
  String get uploadErrorSessionExpired => '上传凭证已过期，请重新上传';

  @override
  String get uploadErrorSessionUnavailable => '暂时无法创建上传任务，请重试';

  @override
  String get uploadErrorFileMissing => '本地视频已被移动或清理，请重新选择';

  @override
  String get uploadErrorUnauthorized => '登录状态或上传权限已失效，请重新登录后重试';

  @override
  String get uploadErrorRateLimited => '上传请求过于频繁，请稍后重试';

  @override
  String get uploadErrorRejected => '上传服务拒绝了该文件，请确认文件后重试';

  @override
  String get uploadErrorServer => '上传服务暂时不可用，请稍后重试';

  @override
  String get uploadErrorInvalidResponse => '上传服务返回异常，请稍后重试';

  @override
  String get uploadErrorAccountChanged => '登录账号已变化，请在当前账号下重新上传';

  @override
  String get uploadErrorUnknown => '视频上传失败，请重试';

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
  String get errorInvalidRoleId => '角色 ID 无效，请刷新后重试';

  @override
  String get errorInvalidRoleNftAssetId => '角色 NFT assetId 无效，请刷新后重试';

  @override
  String get errorInvalidRoleCollectionAssetId => '角色合集 assetId 无效，请刷新后重试';

  @override
  String get roleNftLabelUnknown => '角色NFT#未知';

  @override
  String roleNftLabel(String prefix) {
    return '角色NFT#$prefix';
  }

  @override
  String errorBusiness(String message) {
    return '操作失败：$message';
  }

  @override
  String errorUnknown(String message) {
    return '发生未知错误：$message';
  }

  @override
  String errorNotSupported(String message) {
    return '不支持的操作：$message';
  }

  @override
  String get playerEpisodeSelect => '选集';

  @override
  String get playerPlayFailed => '播放失败';

  @override
  String get playerDramaUnavailable => '暂无法播放该剧';

  @override
  String get playerContentUnavailable => '该内容暂未上架或已下架';

  @override
  String get creatorWorkNotFound => '作品不存在，无法查看';

  @override
  String get creatorWorkNotPublished => '作品未上架，暂不可查看';

  @override
  String get creatorOfflineReasonUnavailable => '暂无下架原因';

  @override
  String get playerTapRetry => '点击重试';

  @override
  String playerEpisodeTotal(int count) {
    return '全$count集';
  }

  @override
  String playerEpisodeLabel(int episodeNo) {
    return '第 $episodeNo 集';
  }

  @override
  String get playerLike => '点赞';

  @override
  String get playerComment => '评论';

  @override
  String get playerFavorite => '收藏';

  @override
  String get playerShare => '分享';

  @override
  String playerShareDramaEpisode(
    String title,
    int episodeNo,
    String description,
    String url,
  ) {
    return '$title | 第$episodeNo集：$description $url 。来 StoryFun，观看精美AI短剧。';
  }

  @override
  String playerShareDramaEpisodeNoDesc(
    String title,
    int episodeNo,
    String url,
  ) {
    return '$title | 第$episodeNo集 $url 。来 StoryFun，观看精美AI短剧。';
  }

  @override
  String playerShareShortVideo(String description, String url) {
    return '$description $url。来 StoryFun，观看精美短视频。';
  }

  @override
  String playerShareShortVideoNoDesc(String url) {
    return '$url。来 StoryFun，观看精美短视频。';
  }

  @override
  String playerShareDrama(String title, String url) {
    return '$title $url 。来 StoryFun，观看精美AI短剧。';
  }

  @override
  String playerShareDramaNoTitle(String url) {
    return '$url 。来 StoryFun，观看精美AI短剧。';
  }

  @override
  String playerRatingLabel(String rating) {
    return '$rating 分';
  }

  @override
  String get loginOrSignUp => '登录或注册';

  @override
  String get loginEnterCode => '输入验证码';

  @override
  String loginCheckEmailDesc(String email) {
    return '请检查 $email 收到的由 privy.io 发送的邮件，并在下方输入验证码。';
  }

  @override
  String loginResendCountdown(int seconds) {
    return '$seconds 秒后重新发送';
  }

  @override
  String get loginResendBtn => '重新发送';

  @override
  String get loginProtectedByPrivy => '由 Privy 提供安全保护';

  @override
  String get loginAgreeLead => '我已同意';

  @override
  String get loginAgreeAnd => '和';

  @override
  String get loginAgreeConfirmLead => '点击确定，代表您已同意';

  @override
  String get loginAgreeRequired => '请先同意服务条款和隐私政策';

  @override
  String get deletingAccountPending => '账户等待删除中';

  @override
  String get deletingAccountCancelDeletion => '撤销删除账户';

  @override
  String get deletingAccountGoBack => '回退';

  @override
  String get drawerEmailAccount => '邮箱账户';

  @override
  String get drawerClickToLogin => '点击登录账户';

  @override
  String get drawerBuyStory => '交易 STORY';

  @override
  String get drawerDeposit => '充值';

  @override
  String get drawerWithdraw => '提现';

  @override
  String get drawerNotifications => '通知消息';

  @override
  String get drawerNoNotifications => '暂无新消息';

  @override
  String get notificationTabSystem => '系统';

  @override
  String get notificationTabInteraction => '互动';

  @override
  String get notificationTagIpSign => '签约角色IP';

  @override
  String get notificationTagRoleManagement => '角色管理';

  @override
  String get notificationTagShowRevenue => '演出收益';

  @override
  String get notificationTagLike => '点赞';

  @override
  String get notificationTagFavorite => '收藏';

  @override
  String notificationSignedActor(String user, String actor) {
    return '@$user 签约了角色IP $actor';
  }

  @override
  String notificationShareEarned(String amount) {
    return '你获得分成 $amount';
  }

  @override
  String notificationStaminaLow(String actor) {
    return '$actor 体力不足，尽快补充体力或休息';
  }

  @override
  String notificationCurrentStamina(String value) {
    return '当前体力 $value';
  }

  @override
  String notificationShowEnded(String range) {
    return '$range 演出结束';
  }

  @override
  String notificationIncomeEarned(String amount) {
    return '你获得收益 $amount';
  }

  @override
  String get notificationActionClaim => '领取';

  @override
  String get notificationActionRefill => '补充';

  @override
  String get notificationInteractionLikedVideo => '赞了你的视频';

  @override
  String notificationInteractionLikedDrama(String title) {
    return '赞了你的短剧《$title》';
  }

  @override
  String get notificationInteractionFavoritedVideo => '收藏了你的视频';

  @override
  String notificationInteractionFavoritedDrama(String title) {
    return '收藏了你的短剧《$title》';
  }

  @override
  String notificationInteractionCommented(String content) {
    return '评论了你：$content';
  }

  @override
  String get notificationInteractionFollowedYou => '关注了你';

  @override
  String get notificationActionMutualFollow => '互关';

  @override
  String get notificationActionFollow => '关注';

  @override
  String get notificationDelete => '删除';

  @override
  String get notificationDeleteFailed => '删除失败，请稍后再试';

  @override
  String get notificationRealtimeReceived => '收到一条新通知';

  @override
  String drawerEpisodeProgress(int current, int total) {
    return '$current/$total集';
  }

  @override
  String drawerNotificationSignedActor(String actor, String target) {
    return '$actor 签约了角色IP $target';
  }

  @override
  String drawerNotificationLikedVideo(String actor) {
    return '$actor 赞了你的视频';
  }

  @override
  String drawerNotificationFavoritedDrama(String actor, String target) {
    return '$actor 收藏了你的短剧 $target';
  }

  @override
  String get depositTitle => '充值';

  @override
  String get insufficientBalanceTitle => '余额不足';

  @override
  String insufficientBalanceDetail(String currency, String amount) {
    return '$currency 余额不足，你还差 $amount $currency';
  }

  @override
  String get insufficientBalancePrompt => '是否前往充值？';

  @override
  String get insufficientBalanceRecharge => '去充值';

  @override
  String get depositDesc => '请从交易所或其他钱包向下方地址转账，确认到账后余额会自动更新。';

  @override
  String get depositToken => '币种';

  @override
  String get depositNetwork => '网络';

  @override
  String get depositNetworkNote => '请确认转账网络，网络错误可能导致资产丢失';

  @override
  String get depositAddress => '充值地址';

  @override
  String get depositAddressCopied => '地址已复制到剪贴板';

  @override
  String get depositSend => '发送';

  @override
  String get depositReceive => '接收';

  @override
  String get depositConvertNote => '将代币发送到这个地址，它将自动在你的 Story.fun 账户中兑换成USDC';

  @override
  String depositMinNote(String minAmount, String token) {
    return '最小充值金额：$minAmount $token';
  }

  @override
  String depositExchangeRateNote(String rate) {
    return '当前兑换汇率为 $rate，实际到账金额 = 充值金额 × $rate';
  }

  @override
  String get depositWarning => '请仅转入所选网络上的所选币种，其他资产将无法找回\n请确认转账网络，网络错误可能导致资产丢失';

  @override
  String get withdrawTitle => '提现';

  @override
  String get withdrawBalance => '可提现余额';

  @override
  String get withdrawToken => '币种';

  @override
  String get withdrawAddress => '提现地址';

  @override
  String get withdrawAddressHint => '请输入或粘贴 Solana 接收地址';

  @override
  String get withdrawAddressHintEvm => '请输入或粘贴 EVM 接收地址';

  @override
  String get withdrawInvalidEvmAddress => '请输入有效的 EVM 地址';

  @override
  String get withdrawInvalidSolanaAddress => '请输入有效的 Solana 地址';

  @override
  String get withdrawEvmGasNote => 'EVM 提现需钱包内有足够的原生代币支付 Gas，交易将直接在链上发起。';

  @override
  String get withdrawEvmFailed => 'EVM 提现失败，请稍后重试';

  @override
  String get withdrawAddressNote => '请确认地址正确，转账后无法撤回';

  @override
  String get withdrawNetwork => '网络';

  @override
  String get withdrawAmount => '金额';

  @override
  String get withdrawAmountHint => '输入提现金额';

  @override
  String get withdrawMax => '最大';

  @override
  String withdrawAvailableBalance(String balance, String token) {
    return '余额 $balance $token';
  }

  @override
  String withdrawMinWarning(String minAmount, String token) {
    return '最小提现金额：$minAmount $token\n请仔细核对提现地址和网络，转账后无法撤回';
  }

  @override
  String get withdrawConfirm => '确认提现';

  @override
  String get withdrawAll => '全部';

  @override
  String withdrawMinAmountError(String minAmt, String token) {
    return '最小提现金额为 $minAmt $token';
  }

  @override
  String get withdrawExceedBalanceError => '提现金额不能超过可用余额';

  @override
  String get withdrawSameAsWalletError => '提现地址不能与当前钱包地址相同';

  @override
  String get withdrawConfirmTitle => '确认提现';

  @override
  String withdrawConfirmMessage(String amount, String token, String address) {
    return '确定提取 $amount $token 到以下 Solana 接收地址吗？\n\n$address';
  }

  @override
  String get withdrawSuccessToast => '提现指令已提交成功！';

  @override
  String get withdrawFailedToast => '提现失败，请重试';

  @override
  String withdrawErrorToast(String error) {
    return '提现发生错误: $error';
  }

  @override
  String withdrawAddressHintWithToken(String token) {
    return '输入接收 $token 的钱包地址';
  }

  @override
  String get withdrawFee => '手续费';

  @override
  String withdrawFeeValue(String fee, String token) {
    return '$fee $token';
  }

  @override
  String withdrawMinAmount(String minAmount, String token) {
    return '最低提币量：$minAmount $token';
  }

  @override
  String withdrawMaxAmount(String maxAmount, String token) {
    return '最大提现金额：$maxAmount $token';
  }

  @override
  String get withdrawSponsorSigning => '签名交易中...';

  @override
  String get withdrawSponsorSubmitting => '提交链上交易中...';

  @override
  String get withdrawSponsorSuccess => '提现交易已提交成功！';

  @override
  String get withdrawSponsorFailed => '交易提交失败，请重试';

  @override
  String get withdrawOrderProcessing => '订单处理中';

  @override
  String get withdrawOrderSuccess => '订单已完成';

  @override
  String get withdrawOrderFailed => '订单处理失败';

  @override
  String withdrawOrderStatus(String status) {
    return '订单状态：$status';
  }

  @override
  String get qrScannerTitle => '扫描二维码';

  @override
  String get qrScannerHint => '将二维码放入框内扫描';

  @override
  String get drawerProfile => '个人中心';

  @override
  String get drawerCreatorManagement => '创作管理';

  @override
  String get drawerInvite => '邀请';

  @override
  String get inviteTitle => '邀请好友';

  @override
  String get inviteTotalPeople => '累计邀请人数';

  @override
  String get inviteTotalRewards => '累计邀请收益';

  @override
  String get inviteWeeklyPool => '本周邀请奖池';

  @override
  String get inviteViewHistory => '查看收益记录';

  @override
  String get inviteShareSection => '分享专属邀请链接或邀请码';

  @override
  String get inviteLinkSection => '邀请链接';

  @override
  String get inviteLinkSubtitle => '好友通过你的链接注册，签约并派遣角色，你将获得额外 STORY 奖励';

  @override
  String get inviteCodeLabel => '邀请码';

  @override
  String get inviteCopyButton => '复制链接';

  @override
  String get inviteCopiedSuccess => '邀请链接已复制到剪贴板！';

  @override
  String get inviteCodeCopiedSuccess => '邀请码已复制到剪贴板！';

  @override
  String get inviteInvitedLabel => '已邀请';

  @override
  String get inviteRewardLabel => '收益';

  @override
  String get inviteBindCode => '绑定邀请码';

  @override
  String get inviteBindCodePromptHint => '跳过后可在邀请页绑定';

  @override
  String get inviteBindCodePlaceholder => '输入邀请码';

  @override
  String get inviteBindConfirm => '确定';

  @override
  String get inviteBindSuccess => '邀请码绑定成功';

  @override
  String get inviteBindCodeInvalid => '邀请码无效';

  @override
  String get inviteBindCodeAlreadyBound => '该账号已绑定邀请码';

  @override
  String get inviteRulesSection => '邀请规则';

  @override
  String get inviteFaqPoolTitle => '每周邀请奖池是什么？';

  @override
  String get inviteFaqPoolBody =>
      '每周邀请奖池是平台为邀请活动设立的独立奖励池，用于奖励当周邀请行为，不会从被邀请人收益中扣除。奖池设有周发放上限，触顶后按份额等比缩减，每周一重新统计发放。';

  @override
  String get inviteFaqSettlementTitle => '邀请奖励什么时候结算？';

  @override
  String get inviteFaqSettlementBody =>
      '邀请奖励与经纪人页面的片酬在同一周期统一结算：每周一 00:00 (UTC) 截止统计，结算后可前往收益页领取。';

  @override
  String get inviteRuleSourceTitle => '奖励来源';

  @override
  String get inviteRuleSourceSubtitle => '独立邀请子池';

  @override
  String get inviteRuleSourceBody =>
      '邀请奖励来自 NFT 挖矿池中独立的邀请子池（占总挖矿池 25%），不从被邀请人收益中扣除。邀请子池有独立周硬顶，触顶后按份额等比缩减。';

  @override
  String get inviteRuleBaseTitle => '计算基数';

  @override
  String get inviteRuleBaseSubtitle => '按实得 STORY';

  @override
  String get inviteRuleBaseBody =>
      '奖励按被邀请人本期实际到手的 STORY 计算，不按名义产出计算。被邀请人自己挖到的 STORY 不受影响，邀请奖励是额外发放。';

  @override
  String get inviteRuleLevelTitle => '奖励范围';

  @override
  String get inviteRuleLevelSubtitle => '仅直接邀请';

  @override
  String get inviteRuleLevelBody => '邀请奖励仅发放给你直接邀请的用户，不设二级及以上间接返佣。';

  @override
  String get inviteRuleConditionTitle => '有效条件';

  @override
  String get inviteRuleConditionSubtitle => '有效下线才能产生奖励';

  @override
  String inviteRuleConditionBody(String currency) {
    return '被邀请人实际挖到过 STORY，或发生过 $currency 付费，才计为有效下线。空号注册不产生奖励。邀请关系一经建立不可更改。';
  }

  @override
  String get drawerTxHistory => '交易记录';

  @override
  String get drawerFinanceDashboard => '资金看板';

  @override
  String get financeDashboardComingSoon => '资金看板即将上线，敬请期待';

  @override
  String get financeDashboardPageTitle => '平台资金看板';

  @override
  String financeDashboardTotalUsdcIncome(String currency) {
    return '$currency 总收入';
  }

  @override
  String get financeDashboardTotalStoryReleased => 'STORY 总释放';

  @override
  String financeDashboardTabUsdcIncome(String currency) {
    return '$currency 收入明细';
  }

  @override
  String get financeDashboardTabVaultFunds => '金库资金沉淀';

  @override
  String get financeDashboardTabStoryRelease => 'STORY 释放概览';

  @override
  String get financeDashboardFeeMint => '签约费';

  @override
  String get financeDashboardFeeRoyalty => '二级版税';

  @override
  String get financeDashboardFeeItemPurchase => '购买道具';

  @override
  String get financeDashboardFeeTx => '手续费';

  @override
  String get financeDashboardLedgerBizSigningFee => '签约费';

  @override
  String get financeDashboardLedgerBizManualCredit => '人工加款';

  @override
  String get financeDashboardLedgerBizManualDebit => '人工扣款';

  @override
  String get financeDashboardLedgerBizStaminaPurchase => '购买体力费';

  @override
  String get financeDashboardLedgerBizSynthesisUpgrade => '合成升级费';

  @override
  String get financeDashboardLedgerBizTransactionFee => '手续费';

  @override
  String financeDashboardRecentUsdcLedger(String currency) {
    return '近期 $currency 收入流水';
  }

  @override
  String get financeDashboardViewMore => '查看更多';

  @override
  String get financeDashboardTotalVaultFunds => '总资金';

  @override
  String get financeDashboardCoveredActorIp => '覆盖角色IP';

  @override
  String get financeDashboardActorVaultRanking => '角色IP金库排行';

  @override
  String get storyReleaseTabAllocation => 'STORY 总量分配';

  @override
  String get storyReleaseTabMiningRelease => '近期挖矿释放';

  @override
  String get storyReleaseFieldPeriod => '周期';

  @override
  String get storyReleaseFieldHardLimit => '周硬顶';

  @override
  String get storyReleaseFieldMiningRewards => '质押挖矿';

  @override
  String get storyReleaseFieldInviteRewards => '邀请挖矿';

  @override
  String get storyReleaseFieldUsageRate => '使用率';

  @override
  String get storyReleaseFieldTarget => '分配对象';

  @override
  String get storyReleaseFieldRatio => '比例';

  @override
  String get storyReleaseFieldAmount => '数量';

  @override
  String get storyReleaseFieldReleased => '已释放';

  @override
  String get storyReleaseFieldProgress => '释放进度';

  @override
  String get storyReleaseCategoryNftMiningPool => 'NFT 挖矿池';

  @override
  String get storyReleaseCategoryTeam => '团队';

  @override
  String get storyReleaseCategoryInvestors => '投资人';

  @override
  String get storyReleaseCategoryLiquidity => 'Launchpad + 流动性';

  @override
  String get storyReleaseCategoryTreasury => '国库';

  @override
  String get storyReleaseCategoryMarketOps => '市场运营';

  @override
  String storyReleaseTotalSupplyBadge(String total) {
    return '总量 $total STORY';
  }

  @override
  String get drawerWhitepaper => '白皮书';

  @override
  String get drawerSettings => '设置';

  @override
  String get commonClose => '关闭';

  @override
  String get commonDelete => '删除';

  @override
  String get commonLoadFailed => '加载失败';

  @override
  String get commonNone => '未命名';

  @override
  String get commonUntitled => '未命名';

  @override
  String get actorDetailTitle => '演员主页';

  @override
  String get actorDetailCastDramas => '参演短剧';

  @override
  String get actorDetailTabCast => '参演';

  @override
  String get actorDetailTabInfo => '信息';

  @override
  String get actorDetailNoCastRecords => '暂无参演记录';

  @override
  String get actorBondingCurve => '价格联合曲线';

  @override
  String get actorContractAddress => '合约地址';

  @override
  String get actorCurrentPosition => '当前位置';

  @override
  String actorCurrentPrice(String price, String currency) {
    return '当前价格 $price $currency';
  }

  @override
  String get actorFloorPrice => '地板价';

  @override
  String get actorGoTrade => '去交易';

  @override
  String get profileWalletTrade => '交易';

  @override
  String get actorHeatCoefficient => '热度系数';

  @override
  String get actorIpPower => 'IP片酬';

  @override
  String get actorPayMax => '最高';

  @override
  String get actorPayUpgradeTitle => '片酬升级规则';

  @override
  String get actorPayUpgradeReachHint => '该IP参演短剧的当前完播数可支持角色升级至';

  @override
  String actorPayUpgradeCompletions(String count) {
    return '$count 完播';
  }

  @override
  String actorPayUpgradeMultiplier(String value) {
    return '片酬 ×$value';
  }

  @override
  String actorPayTitle(String name) {
    return '$name · 片酬';
  }

  @override
  String get actorLv1PayHint => '签约即可获得Lv.1角色';

  @override
  String get actorLv1PayFormula => 'Lv.1片酬=价格系数×热度系数';

  @override
  String actorLv1PayEquals(String value) {
    return '=$value';
  }

  @override
  String actorIpPowerTitle(String name) {
    return '$name · IP片酬';
  }

  @override
  String get actorIpPowerFormula => 'IP片酬 = 价格系数 × 热度系数 × Trust1';

  @override
  String get actorPriceCoefficient => '价格系数';

  @override
  String actorPriceCoefficientValue(String value) {
    return '价格系数 $value';
  }

  @override
  String get actorPriceCoefficientHelpA11y => '查看价格系数说明';

  @override
  String get actorPriceUnitName => '点数';

  @override
  String get actorPriceCoefficientDialogFormulaLe100 => '系数 = P0 ÷ 10';

  @override
  String get actorPriceCoefficientDialogDescLe100 => '线性增长';

  @override
  String actorPriceCoefficientDialogTitleGt100(String currency) {
    return 'P0 > 10 $currency';
  }

  @override
  String get actorPriceCoefficientDialogFormulaGt100 =>
      '系数 = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]';

  @override
  String get actorPriceCoefficientDialogDescGt100 => '增速渐缓，上限 1.6';

  @override
  String actorPriceCoefficientDialogTitleLe100(String currency) {
    return 'P0 ≤ 10 $currency';
  }

  @override
  String actorPriceCoefficientFactorDesc(String currency1, String currency2) {
    return 'P0 ≤ 10 $currency1 系数= P0/10（线性增长）\nP0 > 10 $currency2 → 系数 = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]（渐近上限 1.6）';
  }

  @override
  String get actorHeatCoefficientFactorDesc =>
      '角色IP 近30天热度乘子，取决于短剧完播、点赞、收藏等互动表现';

  @override
  String get actorTrustFactorDesc => '平台风控系数，默认值为 1.0';

  @override
  String get actorStatCompletion => '完播';

  @override
  String get actorIdCopied => '编号已复制';

  @override
  String actorInitialPrice(String price, String currency) {
    return '初始价格：$price $currency';
  }

  @override
  String actorIpLabel(String label) {
    return '演员 IP $label';
  }

  @override
  String get actorIssueInfo => '发行信息';

  @override
  String actorIssuer(String name) {
    return '发行者 $name';
  }

  @override
  String actorMintedCount(int minted, int maxSupply) {
    return '已铸造 $minted/$maxSupply';
  }

  @override
  String get actorPriceCurve => '价格曲线';

  @override
  String get actorSign => '签约';

  @override
  String get actorConfirmSign => '确认签约';

  @override
  String get actorSignPriceLabel => '签约价格';

  @override
  String get actorSignPriceDescription => '签约价格随已签约数自动上涨，早期签约更优惠';

  @override
  String get actorSignPriceFormula => '公式：价格 = 初始价格 × 5^(已签约数 ÷ 发行总量)';

  @override
  String actorPriceAxisLabel(String currency) {
    return '价格（$currency）';
  }

  @override
  String get actorSignedCountAxisLabel => '已签约数';

  @override
  String actorSignRemainingCount(int count) {
    return '剩余$count个';
  }

  @override
  String get actorSignSoldOut => '已售罄';

  @override
  String actorSignSupplySummary(String total, String remaining) {
    return '总发行 $total · 剩余 $remaining';
  }

  @override
  String get actorPricingFixed => '固定价格';

  @override
  String get actorPricingCurve => '曲线价格';

  @override
  String get actorPriceCurveDisclaimer => '初始价格不代表平台估值，曲线上涨不代表二级价格上涨，平台不承诺收益。';

  @override
  String get actorPriceStatInitialPrice => '初始价格';

  @override
  String get actorPriceStatCurrentPrice => '当前价格';

  @override
  String get actorPriceStatTailPrice => '尾价';

  @override
  String get actorPriceStatTotalSupply => '总发行量';

  @override
  String get actorPriceStatSigned => '已签约';

  @override
  String get actorPriceStatRemaining => '剩余';

  @override
  String get actorPricingType => '定价类型';

  @override
  String get contentBadgeOfficialIssue => '官方发行';

  @override
  String get contentBadgeCommunityIssue => '社区发行';

  @override
  String get contentBadgePartnerIssue => '合作方发行';

  @override
  String get contentBadgeVerifiedIssue => '认证创作者发行';

  @override
  String get contentBadgeOfficialDrama => '官方短剧';

  @override
  String get contentBadgeCommunityDrama => '社区短剧';

  @override
  String get contentBadgePartnerDrama => '合作方短剧';

  @override
  String get contentBadgeVerifiedDrama => '认证创作者短剧';

  @override
  String get actorIpCopied => '复制成功';

  @override
  String get actorRiskIp => '风险IP';

  @override
  String get actorRiskIpDescription => '该角色IP信任系数异常，挖矿权重将受影响。';

  @override
  String get actorIpVault => '角色IP金库';

  @override
  String get actorIpVaultDescription =>
      '签约收入的 30% 自动沉淀至角色IP金库，用于支撑 IP 生态的长期发展。二级市场版税收入的 30% 同样归入金库，形成持续资金蓄水池。V1 版本金库仅提供数据展示，暂不开放分配。';

  @override
  String get actorIpVaultSignIncomePrefix => '签约收入 · 沉淀 ';

  @override
  String get actorIpVaultSecondaryRoyaltyPrefix => '二级版税 · 沉淀 ';

  @override
  String get actorFixedPriceDialogDesc =>
      '该角色IP采用固定价格模式，每个角色都以统一价格签约，销量变化不影响价格';

  @override
  String get actorCurvePriceDialogDesc => '价格按联合曲线公式随已签约数自动上涨，早期签约更优惠';

  @override
  String get actorFixedPriceNote1 => '发行者设定固定价格后，所有签约均按此价格结算';

  @override
  String get actorFixedPriceNote2 => '不会因已签约数增加而价格上涨';

  @override
  String get actorFixedPriceNote3 => '适合希望锁定成本的买家';

  @override
  String get actorIssueFixedPriceDesc => '该角色IP采用固定价格模式，所有签约均按固定价格结算，不随销量变化。';

  @override
  String get actorSignSlippageNote => '已开启 1% 滑点保护，价格超出时将取消交易';

  @override
  String get actorSignSuccessTitle => '签约成功！';

  @override
  String actorSignSuccessMessage(String name) {
    return '角色「$name」签约成功';
  }

  @override
  String actorSignSuccessNftId(String nftId) {
    return 'NFT编号：$nftId';
  }

  @override
  String get actorSignChainConfigMissing => '链上配置不完整，请稍后重试';

  @override
  String get actorSignPriceSoldOut => '签约价格 · 已售罄';

  @override
  String actorSignPriceRemaining(int count) {
    return '签约价格 · 剩余$count个';
  }

  @override
  String actorSignedCount(int count) {
    return '已签约 $count';
  }

  @override
  String get actorStatusLabelOffline => '离线';

  @override
  String get actorStatusLabelOnline => '在线';

  @override
  String get actorStatusLabelPending => '审核中';

  @override
  String get actorStatusLabelRejected => '已拒绝';

  @override
  String get actorTotalSupply => '发行总量';

  @override
  String get commentsAnonymous => '匿名用户';

  @override
  String get commentsEmpty => '暂无评论';

  @override
  String get commentsHint => '发布精彩评论...';

  @override
  String get commentsInvalidContent => '请输入有效内容';

  @override
  String get commentsReply => '回复';

  @override
  String commentsViewReplies(int count) {
    return '查看 $count 条回复';
  }

  @override
  String get commentsCollapseReplies => '收起';

  @override
  String get commentsViewMoreReplies => '展开更多';

  @override
  String commentsReplyHint(String nickname) {
    return '回复 $nickname';
  }

  @override
  String get commentsDeleteCommentTitle => '删除这条评论？';

  @override
  String get commentsDeleteReplyTitle => '删除这条回复？';

  @override
  String get commentTagAuthor => '作者';

  @override
  String get commentTagMe => '我';

  @override
  String get commentTagFriend => '你的好友';

  @override
  String get commentTagFan => '你的粉丝';

  @override
  String get commentTagFirst => '首评';

  @override
  String get commentTagAuthorLiked => '作者赞过';

  @override
  String commentsReplyTo(String nickname) {
    return '回复 @$nickname：';
  }

  @override
  String get commentsReplyCommentNotExists => '评论不存在';

  @override
  String get commentsBlockedByMe => '黑名单用户，无法评论';

  @override
  String get commentsBlockedByTarget => '由于对方设置，你无法评论TA';

  @override
  String get commentsTabComments => '评论';

  @override
  String get commentsTabAllComments => '全部评论';

  @override
  String get commentsTabDramas => '短剧';

  @override
  String get commentsTabActors => '角色';

  @override
  String get timeJustNow => '刚刚';

  @override
  String get timeYesterday => '昨天';

  @override
  String get timeDayBeforeYesterday => '前天';

  @override
  String timeMinutesAgo(int count) {
    return '$count分钟前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count小时前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count天前';
  }

  @override
  String commentsTitle(int count) {
    return '评论 ($count)';
  }

  @override
  String get createActorTitle => '创建角色';

  @override
  String get createActorHeroTitle => '铸造角色 NFT';

  @override
  String get createActorHeroSubtitle => '创建专属 AI 角色，绑定分润参与短剧';

  @override
  String get createActorNameLabel => '角色名称';

  @override
  String get createActorNameHint => '输入角色名称';

  @override
  String get createActorBioLabel => '角色简介';

  @override
  String get createActorBioHint => '描述角色背景';

  @override
  String get createActorGenderLabel => '性别';

  @override
  String get createActorGenderMale => '男';

  @override
  String get createActorGenderFemale => '女';

  @override
  String get createActorMintParams => 'NFT 铸造参数';

  @override
  String get createActorTokenStandard => 'Token 标准';

  @override
  String get createActorChain => '链';

  @override
  String get createActorMinHolding => '最低持仓门槛';

  @override
  String get createActorMintNft => '铸造 NFT';

  @override
  String get createActorIpTitle => '发行角色 IP';

  @override
  String get createActorIpSubtitle => '发行一个角色 IP 之后可在该 IP 下签约角色，角色可派遣产生收益。';

  @override
  String get createActorSelectMaterial => '选择角色素材';

  @override
  String get createActorDreamOsBadge => '前往 DreamOS';

  @override
  String get createActorSelectMaterialDesc =>
      '进入DreamOS项目 → 创建角色 → 进入StoryFun发行 IP';

  @override
  String get createActorSelectButton => '选择角色';

  @override
  String get createActorNameLabelNew => '角色姓名';

  @override
  String get createActorNamePlaceholder => '输入角色姓名';

  @override
  String get createActorBioLabelNew => '简介';

  @override
  String get createActorBioPlaceholder => '请输入角色 IP 介绍';

  @override
  String get createActorParamsTitle => '角色 IP 发行参数';

  @override
  String get createActorParamsSubtitle => '设定角色 IP 的发行参数，发行后不可修改。';

  @override
  String get createActorTotalSupplyLabel => '角色发行总量';

  @override
  String get createActorTotalSupplyDesc => '发行总量范围为 100 - 5,000。';

  @override
  String get createActorTotalSupplyPlaceholder => '100 - 5,000';

  @override
  String get createActorPricingFixed => '固定价格';

  @override
  String get createActorPricingCurve => '曲线价格';

  @override
  String createActorFixedPriceLabel(String currency) {
    return '固定价格（$currency）';
  }

  @override
  String createActorInitialPriceLabel(String currency) {
    return '初始价格（$currency）';
  }

  @override
  String get createActorFixedPricePlaceholder => '10 - 1,000';

  @override
  String get createActorFixedPriceDesc => '每个角色都以固定不变的价格购买，不会随销量变化。';

  @override
  String get createActorInitialPricePlaceholder => '10 - 1,000';

  @override
  String get createActorInitialPriceDesc =>
      '初始价格为联合曲线起始价，每签约一个角色，价格按公式 P = P₀ × 5^(已签约数/发行总量) 自动上涨，早期签约更优惠。';

  @override
  String get createActorFormIncomplete => '请先完成角色素材、姓名、简介和发行参数填写';

  @override
  String get createActorValidationNameRequired => '请输入角色姓名';

  @override
  String get createActorValidationNameTooLong => '角色姓名不超过20字';

  @override
  String get createActorValidationBioRequired => '请输入简介';

  @override
  String get createActorValidationBioTooLong => '简介不超过500字';

  @override
  String get createActorValidationTotalSupplyRequired => '请输入有效的NFT发行总量';

  @override
  String get createActorValidationTotalSupplyPositiveInteger => 'NFT发行总量须为正整数';

  @override
  String get createActorValidationTotalSupplyRange => '角色发行总量须在100到5000之间';

  @override
  String get createActorValidationPriceRequired => '请输入有效的Mint价格';

  @override
  String get createActorValidationPriceInvalid => 'Mint价格须大于等于10且不超过1,000';

  @override
  String get createActorValidationPriceMaxDecimals => 'Mint价格最多保留两位小数';

  @override
  String get createActorSelectMaterialRequired => '请选择角色素材';

  @override
  String get createActorCancelButton => '取消';

  @override
  String get createActorConfirmButton => '确定发行';

  @override
  String get createActorIssueFee => '手续费';

  @override
  String createActorSuccessTitle(String name) {
    return '$name · 发行成功！';
  }

  @override
  String createActorSuccessDesc(String id) {
    return '角色 IP $id';
  }

  @override
  String get createActorSuccessTip => '发行者也需要签约才能获得该角色哦～';

  @override
  String get createActorCloseButton => '稍后再说';

  @override
  String get createActorViewButton => '去签约';

  @override
  String get createActorEmptyTitle =>
      '您还没有在 DreamOS 中创建满足条件、由系统在 DreamOS 自动生成的 NFT 发行。';

  @override
  String get createActorGotoDreamOs => '前往 DreamOS 创建';

  @override
  String get createActorSearchPlaceholder => '搜索角色素材';

  @override
  String get createActorInvalidOrderId => '角色IP订单编号无效，请刷新后重试';

  @override
  String get createDramaTitle => '创建短剧';

  @override
  String get createDramaTitleLabel => '短剧标题';

  @override
  String get createDramaTitleHint => '输入短剧名称';

  @override
  String get createDramaSynopsisLabel => '剧情简介';

  @override
  String get createDramaSynopsisHint => '讲述一个什么样的故事...（最多1000字）';

  @override
  String get createDramaAiSettings => 'AI 生成设置';

  @override
  String get createDramaVisualStyle => '画面风格';

  @override
  String get createDramaVisualStyleRealistic => '写实';

  @override
  String get createDramaEpisodeDuration => '每集时长';

  @override
  String get createDramaEpisodeDurationValue => '3-5 分钟';

  @override
  String get createDramaTotalEpisodes => '总集数';

  @override
  String get createDramaTotalEpisodesValue => '8 集';

  @override
  String get createDramaGenreLabel => '类型';

  @override
  String get createDramaGenreDrama => '剧情';

  @override
  String get createDramaGenreComedy => '喜剧';

  @override
  String get createDramaGenreAction => '动作';

  @override
  String get createDramaGenreRomance => '爱情';

  @override
  String get createDramaGenreSciFi => '科幻';

  @override
  String get createDramaGenreMystery => '悬疑';

  @override
  String get createDramaGenreHorror => '恐怖';

  @override
  String get createDramaGenreAnimation => '动画';

  @override
  String get createDramaHeroTitle => 'AI 短剧创作';

  @override
  String get createDramaHeroSubtitle => '一键生成属于你的爆款短剧';

  @override
  String get createDramaStartGeneration => '开始生成';

  @override
  String get creatorDramaManagementTab => '短剧管理';

  @override
  String get creatorDramaNftTab => '短剧NFT';

  @override
  String get creatorHeaderSubtitle => '短剧的发布、审核与铸造。';

  @override
  String get creatorV2Subtitle => '短剧/视频的发布与管理。';

  @override
  String creatorV2DramaTabCount(int count) {
    return '短剧（$count）';
  }

  @override
  String creatorV2VideoTabCount(int count) {
    return '视频（$count）';
  }

  @override
  String get creatorV2NoVideos => '暂无视频';

  @override
  String get creatorLoginPrompt => '登录后查看你的创作';

  @override
  String get creatorNoCreatedActors => '暂无创建的角色';

  @override
  String get creatorNoPublishedDramas => '暂无发布的短剧';

  @override
  String get creatorOwnedNftCount => '持有NFT数';

  @override
  String get creatorCreateDrama => '创作短剧';

  @override
  String get creatorPublishNewDrama => '发布新短剧';

  @override
  String get creatorPublishedDramas => '发布短剧';

  @override
  String get creatorReviewFilterAll => '全部';

  @override
  String get creatorReviewFilterApproved => '已通过';

  @override
  String get creatorReviewFilterPending => '审核中';

  @override
  String get creatorReviewFilterRejected => '未通过';

  @override
  String get creatorReviewFilterOffline => '已下架';

  @override
  String get creatorDramaOtherReason => '其他原因';

  @override
  String get creatorDramaStatusOnline => '已通过';

  @override
  String get creatorDramaStatusPendingReview => '等待审核';

  @override
  String get creatorDramaStatusReviewRejected => '未通过';

  @override
  String get creatorDramaStatusPendingOnline => '待上线';

  @override
  String creatorDramaAuditReason(Object reason) {
    return '未通过审核原因：$reason';
  }

  @override
  String get creatorDramaNftMinted => '已铸造';

  @override
  String creatorDramaEpisodeCount(int count) {
    return '$count 集';
  }

  @override
  String get creatorDramaEdit => '编辑';

  @override
  String get creatorDramaDelete => '删除';

  @override
  String get creatorActorDelete => '删除角色';

  @override
  String get creatorDeleteDramaConfirm => '确定删除该短剧吗？';

  @override
  String get creatorDeleteVideoConfirmTitle => '删除视频确认';

  @override
  String creatorDeleteVideoConfirmMessage(String name) {
    return '您确定要删除 “$name” 吗？\n此操作无法撤销';
  }

  @override
  String get creatorDeleteActorConfirm => '确定删除该角色吗？';

  @override
  String get creatorDeleting => '删除中...';

  @override
  String get creatorNoDramas => '暂无短剧';

  @override
  String get creatorNoNfts => '暂无短剧NFT';

  @override
  String get creatorsComingSoon => '创作者目录即将上线';

  @override
  String get creatorsHeroSubtitle => '发现优秀创作者';

  @override
  String get creatorsHeroTitle => '创作者目录';

  @override
  String get dramaBatchUnlockAll => '解锁全部';

  @override
  String dramaBatchUnlockDiscount(String discount) {
    return '批量解锁优惠 $discount%';
  }

  @override
  String get dramaBatchUnlockSubtitle => '一次性解锁全部剧集更划算';

  @override
  String get dramaBatchUnlockSuccess => '解锁成功，请开始观看';

  @override
  String get dramaDetailAllFree => '全集免费';

  @override
  String dramaDetailBoundActors(int count) {
    return '$count 角色绑定';
  }

  @override
  String dramaDetailEpisodeCount(int count) {
    return '$count 集';
  }

  @override
  String get dramaDetailEpisodePrice => '单集价格';

  @override
  String get dramaDetailFree => '免费';

  @override
  String dramaDetailFreeEpisodes(int count) {
    return '前 $count 集免费';
  }

  @override
  String get dramaDetailMainCharacters => '主要人物';

  @override
  String get dramaDetailNftMinted => 'NFT 已铸造';

  @override
  String get dramaDetailNoEpisodes => '暂无剧集';

  @override
  String get dramaDetailPaid => '付费';

  @override
  String get dramaDetailPendingActor => '待定角色';

  @override
  String get dramaDetailRoleCount => '人物数';

  @override
  String get dramaUnlockFailedRetry => '解锁失败，请重试';

  @override
  String get dramaUnlockFetchTimeout => '获取播放地址超时，请重试';

  @override
  String get dramaUnlockLoginRequired => '请先登录后再解锁剧集';

  @override
  String dramaUnlockMessage(
    int epNo,
    String price,
    String discount,
    String currency,
  ) {
    return '第 $epNo 集需要付费解锁\n单价：$price $currency\n批量解锁优惠：$discount';
  }

  @override
  String get dramaUnlockSuccessFetching => '解锁成功，正在获取播放地址...';

  @override
  String get dramaUnlockTitle => '解锁剧集';

  @override
  String get editActorTitle => '编辑角色';

  @override
  String get editDramaTitle => '编辑短剧';

  @override
  String get editVideoTitle => '编辑视频';

  @override
  String get editSaveChanges => '保存修改';

  @override
  String get editProfileTitle => '编辑资料';

  @override
  String get editNicknameLabel => '昵称';

  @override
  String get editRoleNameLabel => '用户名';

  @override
  String get editNicknameHint => '请输入昵称';

  @override
  String get editNicknameRequired => '请输入昵称';

  @override
  String get editProfileBioLabel => '简介';

  @override
  String get editProfileBioHint => '请输入简介';

  @override
  String get editProfileEmailLabel => '邮箱地址';

  @override
  String get editAvatarCropTitle => '裁剪头像';

  @override
  String get profileUpdateSuccess => '资料更新成功';

  @override
  String incomeClaimAmount(String amount, String currency) {
    return '领取 $amount $currency';
  }

  @override
  String get incomeClaimFailed => '领取失败';

  @override
  String incomeClaimMessage(String amount, String currency) {
    return '可领取金额：$amount $currency\n收益将直接转入您的钱包余额';
  }

  @override
  String get incomeClaimSuccess => '领取成功';

  @override
  String get incomeClaimTitle => '领取收益';

  @override
  String get incomeConfirmClaim => '确认领取';

  @override
  String get incomeHistoryTab => '收益历史';

  @override
  String get incomeInviteHeroSubtitle => '邀请好友消费和互动，被邀人活跃度越高奖励越多';

  @override
  String get incomeInviteHeroTitle => '邀请好友赚返利';

  @override
  String get incomeInviteNoRecords => '暂无返利记录';

  @override
  String get incomeInvitePaidUnlockDesc => '好友付费解锁剧集';

  @override
  String get incomeInvitePaidUnlockTitle => '付费解锁';

  @override
  String get incomeInviteRecords => '返利记录';

  @override
  String get incomeInviteRegisterDesc => '好友通过链接注册账号';

  @override
  String get incomeInviteRegisterTitle => '邀请注册';

  @override
  String get incomeInviteRules => '返利规则';

  @override
  String get incomeInviteShareLink => '分享邀请链接';

  @override
  String get incomeInviteStakeDesc => '好友质押 NFT 或 STORY';

  @override
  String get incomeInviteStakeTitle => '质押投资';

  @override
  String get incomeInviteTab => '邀请返利';

  @override
  String get incomeInviteWatchDesc => '好友观看短剧获取积分';

  @override
  String get incomeInviteWatchTitle => '观看短剧';

  @override
  String get incomeNoHistory => '暂无收益历史';

  @override
  String get incomeNoRecords => '暂无收益记录';

  @override
  String get incomeNothingToClaim => '暂无可领取金额';

  @override
  String get incomeOverviewTab => '收益总览';

  @override
  String get incomePendingClaim => '待领取';

  @override
  String get incomeRecords => '收益记录';

  @override
  String get incomeThisMonth => '本月';

  @override
  String get incomeToday => '今日';

  @override
  String get incomeTotalEarnings => '累计收益';

  @override
  String get incomeCumulativeStory => '累计 STORY';

  @override
  String incomeCumulativeUsdc(String currency) {
    return '累计 $currency';
  }

  @override
  String get incomeClaimableStory => '可领取 STORY';

  @override
  String incomeClaimableUsdc(String currency) {
    return '可领取 $currency';
  }

  @override
  String get incomeSettlingStory => '我的片酬';

  @override
  String get incomeSettlingHint => '结算中，到账后可领取';

  @override
  String get incomeHelpTotalStoryDesc => '历史所有周期累计获得的 STORY 总量（含已领取和未领取）。';

  @override
  String incomeHelpTotalUsdcDesc(String currency) {
    return '历史所有角色签约分成、二级版税的累计 $currency 收入。';
  }

  @override
  String get incomeHelpSettlingStoryDesc => '系统结算后自动兑换为 STORY';

  @override
  String get incomeHelpClaimableStoryDesc => '已结算的 STORY，可领取至个人钱包。';

  @override
  String incomeHelpClaimableUsdcDesc(String currency) {
    return '已结算的 $currency，可领取至个人钱包。';
  }

  @override
  String get incomeFilterAll => '全部';

  @override
  String get incomeFilterMining => '派遣收益';

  @override
  String get incomeFilterInvite => '邀请收益';

  @override
  String get incomeMiningReward => '派遣收益';

  @override
  String get incomeInviteReward => '邀请收益';

  @override
  String get incomeUsdcActorSignShare => '角色签约分成';

  @override
  String get incomeClaimNoWallet => '请先绑定钱包';

  @override
  String incomeClaimCurrencyTitle(String currency) {
    return '领取 $currency';
  }

  @override
  String incomeClaimWithdrawMessage(
    String amount,
    String currency,
    String address,
  ) {
    return '确定提取 $amount $currency 到您的 Solana 钱包吗？\n收款地址: $address';
  }

  @override
  String get incomeClaimWithdrawConfirm => '确认提取';

  @override
  String get incomeClaimWithdrawSubmitted => '提现成功';

  @override
  String get incomeClaimWithdrawFailed => '领取提取失败，请重试';

  @override
  String get incomeClaimAction => '领取';

  @override
  String get nftCreateActorIp => '创建角色IP';

  @override
  String get nftHeaderSubtitle => '浏览和收藏专属角色 NFT';

  @override
  String get nftHeaderTitle => '角色 NFT 广场';

  @override
  String get nftSearchHint => '搜索短剧、作品、角色、用户...';

  @override
  String get actorHowToPlayTitle => '角色 IP 怎么玩';

  @override
  String get actorHowToPlayHelpTooltip => '玩法说明';

  @override
  String get actorHowToPlaySignTab => '签约IP';

  @override
  String get actorHowToPlaySignSubtitle => '坐享片酬';

  @override
  String get actorHowToPlayIssueTab => '发行IP';

  @override
  String get actorHowToPlayIssueSubtitle => '创作变现';

  @override
  String get actorHowToPlaySignPositioning => '定位：零创作门槛，轻松稳赚收益';

  @override
  String get actorHowToPlaySignAudience => '不想创作，想低门槛赚 STORY 收益的普通用户';

  @override
  String get actorHowToPlaySignGuide => '签约高热度高片酬角色 IP，在经纪人页面安排演出即可获利';

  @override
  String get actorHowToPlaySignRightsTitle => '双重收益';

  @override
  String get actorHowToPlaySignRightPerform => '安排演出，持续赚取 STORY 代币';

  @override
  String get actorHowToPlaySignRightTrade => '角色 IP 可交易，赚取溢价收益';

  @override
  String get actorHowToPlayIssuePositioning => '定位：创作发行，多重收益，IP 长期增值';

  @override
  String get actorHowToPlayIssueAudience => '有创作能力，想靠角色 IP、短剧变现的创作者';

  @override
  String get actorHowToPlayIssueGuide => '发行角色 IP，绑定 AI 短剧，提升作品热度，拉高 IP 片酬与收益';

  @override
  String get actorHowToPlayIssueRightsTitle => '三重收益';

  @override
  String get actorHowToPlayIssueRightSignLabel => '签约分成：';

  @override
  String get actorHowToPlayIssueRightSign => '自有 IP 被签约，享 40% 分成';

  @override
  String get actorHowToPlayIssueRightPerformLabel => '演出收益：';

  @override
  String get actorHowToPlayIssueRightPerform => '签约自家 IP，演出赚 STORY';

  @override
  String get actorHowToPlayIssueRightValueLabel => '价值增值：';

  @override
  String get actorHowToPlayIssueRightValue => 'IP 可交易，热度越高溢价越高';

  @override
  String get actorHowToPlayAudienceTitle => '适合人群';

  @override
  String get actorHowToPlayGuideTitle => '玩法指南';

  @override
  String get actorHowToPlayCreateHint =>
      '可用 DreamOS 一键生成角色 IP 与 AI 短剧，高效产出优质内容';

  @override
  String get actorHowToPlayCreateCta => '去创作';

  @override
  String get nftSignInDevelopment => '功能暂未开放';

  @override
  String get nftSortCompleted => '完播';

  @override
  String get nftSortHeat => '热度';

  @override
  String get nftSortIpPower => 'IP片酬';

  @override
  String get nftSortLowestPrice => '价格';

  @override
  String get nftSortLv1Pay => '片酬';

  @override
  String get nftSortMaxPay => '最高片酬';

  @override
  String get nftTradeUnavailable => '交易暂未开放';

  @override
  String playerEpisodeBarCompleted(int count) {
    return '已完结 · 全$count集';
  }

  @override
  String playerEpisodeSynopsis(int episodeNo, String synopsis) {
    return '第 $episodeNo 集｜$synopsis';
  }

  @override
  String get playerPlayFailedRetry => '播放失败，请稍后重试';

  @override
  String get publicProfileDramas => '短剧';

  @override
  String get publicProfileEmpty => '该用户暂无公开内容';

  @override
  String get publicProfileBlock => '拉黑';

  @override
  String get publicProfileUnblock => '解除拉黑';

  @override
  String get publicProfileBlockedByMeContent => '你已拉黑对方，无法查看TA的内容';

  @override
  String get publicProfileBlockedContent => '对方已将你拉黑，你无法查看TA的内容';

  @override
  String get publicProfileBlockConfirmTitle => '确认拉黑';

  @override
  String get publicProfileBlockConfirmMessage => '拉黑后，你将无法查看对方的作品。';

  @override
  String get publicProfileBlockSuccess => '已拉黑';

  @override
  String get publicProfileUnblockSuccess => '已解除拉黑';

  @override
  String get publicProfileFollowers => '粉丝';

  @override
  String get publicProfileFollowing => '关注';

  @override
  String get followTabMutual => '互关';

  @override
  String get profileLikesReceived => '获赞';

  @override
  String profileLikesReceivedDialogMessage(int count) {
    return '你已累计获得 $count 个赞，感谢你的精彩创作！';
  }

  @override
  String get profileTabLikes => '点赞';

  @override
  String get profileTabFavorites => '收藏';

  @override
  String get profileWalletTitle => '钱包';

  @override
  String get profileAddressCopied => '地址已复制';

  @override
  String get followActionFollow => '关注';

  @override
  String get followActionFollowBack => '回关';

  @override
  String get followActionFollowing => '已关注';

  @override
  String get followBlockedByMe => '黑名单用户，无法关注';

  @override
  String get followBlockedByTarget => '由于对方设置，你无法关注TA';

  @override
  String get likeBlockedByMe => '黑名单用户，无法点赞';

  @override
  String get likeBlockedByTarget => '由于对方设置，你无法点赞';

  @override
  String get favoriteBlockedByMe => '黑名单用户，无法收藏';

  @override
  String get favoriteBlockedByTarget => '由于对方设置，你无法收藏';

  @override
  String get ratingBlockedByMe => '黑名单用户，无法评分';

  @override
  String get ratingBlockedByTarget => '由于对方设置，你无法评分';

  @override
  String get followActionMutual => '互相关注';

  @override
  String get followUnfollowTitle => '取消关注';

  @override
  String followUnfollowMessage(String handle) {
    return '确认不再关注 $handle 吗？';
  }

  @override
  String get followUnfollowNo => '否';

  @override
  String get followUnfollowYes => '是';

  @override
  String get followListEmpty => '暂无用户';

  @override
  String get followFollowingEmpty => '暂无关注，去发现有趣的创作者吧～';

  @override
  String get followFollowingEmptyCta => '去看看';

  @override
  String get followFollowingEmptyGuest => '暂无关注';

  @override
  String get followFollowersEmpty => '暂无粉丝，去发布作品提升曝光吧～';

  @override
  String get followFollowersEmptyCta => '去发布';

  @override
  String get followFollowersEmptyGuest => '暂无粉丝';

  @override
  String get followMutualsEmpty => '暂无互关好友';

  @override
  String get followMutualsSelfOnly => '互关列表仅本人可见';

  @override
  String get followRelationsSelfOnly => '关系列表仅本人可见';

  @override
  String get followMoreTitle => '更多';

  @override
  String get followRemoveFollower => '移除粉丝';

  @override
  String get followRemoveFollowerSuccess => '已移除，对方不会收到通知';

  @override
  String get followUserHandleFallback => '@用户';

  @override
  String get publicProfileTitle => '用户主页';

  @override
  String publicProfileUserFallback(String id) {
    return '用户 #$id';
  }

  @override
  String get watchHistoryEmpty => '暂无观看记录';

  @override
  String get watchHistoryClearTitle => '清空观看历史';

  @override
  String get watchHistoryClearMessage => '确定要清空所有观看历史吗？此操作无法撤销。';

  @override
  String get watchHistoryClearConfirm => '确定';

  @override
  String get gamePageTitle => '经纪人';

  @override
  String get gamePageSubtitle => '管理你的角色，派遣产生收益。';

  @override
  String get gameRiskAccount => '风险账户';

  @override
  String get gameRiskAccountDescription => '该账户信任系数异常，挖矿权重将受影响。';

  @override
  String get gameWeeklyStats => '本周数据';

  @override
  String get gameDeployedActors => '已派遣角色';

  @override
  String get gameMyActors => '我的角色';

  @override
  String get gameComingSoon => '即将上线';

  @override
  String get gameSignActor => '签约角色';

  @override
  String get gameGoProduce => '去拍剧';

  @override
  String get gameWorkingActors => '派遣中的角色';

  @override
  String get gameWeekPool => '本周奖池 (STORY)';

  @override
  String get gameWeekNominalOutput => '本周名义产出 (STORY)';

  @override
  String get gameWeekEstimatedOutput => '本周预估产出 (STORY)';

  @override
  String get gameMiningRules => '挖矿规则';

  @override
  String get agentV2RulesTitle => '经营玩法';

  @override
  String get agentV2RulesSummary =>
      '签约角色、安排演出，每小时获得 STORY。\n升级角色，成倍提升每小时片酬。\n体力耗尽时及时补充，产出不间断。\n每周一 00:00 (UTC) 开始结算本期收益，前往收益页领取。';

  @override
  String get agentV2RulesHowToPlay => '怎么玩';

  @override
  String get agentV2RulesStartTitle => '怎么让角色开始赚钱？';

  @override
  String get agentV2RulesStartDescription =>
      '安排候场角色演出，每小时消耗1点体力并根据片酬产出 STORY。\n产出的STORY在每期结束时统一结算，结算后可前往收益页面领取。';

  @override
  String get agentV2RulesStaminaTitle => '体力怎么管理？';

  @override
  String agentV2RulesStaminaDescription(int staminaLimit) {
    return '演出中：每小时消耗 1 点体力，正常产出片酬\n体力耗尽：产出暂停为 0，需要及时处理\n休息：每小时自动恢复 1 点体力，但暂停片酬\n补充体力（付费）：瞬间回满 $staminaLimit，立即恢复产出';
  }

  @override
  String get agentV2RulesBatchTitle => '可以批量操作吗？';

  @override
  String get agentV2RulesBatchDescription =>
      '可以。页面底部提供一键演出、一键补充、一键休息，对在演位上的所有角色批量执行。';

  @override
  String get agentV2RulesEarnings => '能赚多少';

  @override
  String get agentV2RulesSalaryTitle => '片酬怎么算？';

  @override
  String get agentV2RulesSalaryDescription => '咖位越高、角色越贵、短剧越火，每小时片酬就越高。';

  @override
  String get agentV2RulesSalaryFormula => '单卡小时片酬 = 角色片酬 × 1 STORY';

  @override
  String get agentV2RulesRolePowerFormula => '角色片酬 = Lv.1 角色片酬 × 片酬系数';

  @override
  String get agentV2RulesIpSalaryFormula => 'Lv.1 角色片酬 = 价格系数 × 热度系数';

  @override
  String get agentV2RulesCoefficientTitle => '系数说明';

  @override
  String agentV2RulesSalaryExample(String currency) {
    return '林梦瑶 Lv3 主角 · P0=120$currency（价格系数 ≈1.5046）· 热度 3.5\n→ 每小时片酬 = 5.0 × 1.5046 × 3.5 × 1 = 26.3 STORY\n如果只是 Lv1 群演，每小时仅 ≈5.3 STORY——升到 Lv3 涨了 5 倍';
  }

  @override
  String get agentV2RulesSettlementTitle => '什么时候结算？';

  @override
  String get agentV2RulesSettlementDescription =>
      '每 7 天为一个演出周期，每周一 00:00 (UTC) 截止。系统结算完毕后，本期片酬自动兑换为STORY，可前往收益页面领取。';

  @override
  String get agentV2RulesSettlementExample =>
      '假设本周奖池 100,000 STORY：\n情况 A：全平台只有你产出 134 → 你拿 134，剩下不发放\n情况 B：全网产出 250,000 → 100,000 ÷ 250,000 = 40%，你的名义产出打四折\n情况 C：缩放后某人应得 6,000，但上限 5,000 → 只发 5,000';

  @override
  String get agentV2RulesStronger => '怎么变强';

  @override
  String get agentV2RulesUpgradeTitle => '怎么升级角色？';

  @override
  String get agentV2RulesUpgradeDescription =>
      '升级条件：消耗 2 张同IP同等级分身 + IP参演短剧累计完播数达标\nLv1→Lv2：≥1万完播 · 片酬 1→3\nLv2→Lv3：≥5万完播 · 片酬 3→9\nLv3→Lv4：≥20万完播 · 片酬 9→27\nLv4→Lv5：≥100万完播 · 片酬 27→81';

  @override
  String get agentV2RulesPerforming => '演出中';

  @override
  String get agentV2RulesNormalSalary => '正常片酬';

  @override
  String get agentV2RulesSalaryCoefficient =>
      '片酬系数：Lv1=1 · Lv2=3 · Lv3=9 · Lv4=27 · Lv5=81';

  @override
  String agentV2RulesPriceCoefficientDescription(
    String currency1,
    String currency2,
  ) {
    return '价格系数（发行价 P0）：\n  • P0 ≤ 100$currency1 → 系数 = P0 ÷ 100（线性增长）\n  • P0 > 100$currency2 → 系数 = 1.6 × (P0/100)1.3 / [(P0/100)1.3 + 0.6]（渐近上限 1.6）';
  }

  @override
  String get agentV2RulesTrust2 => 'Trust2';

  @override
  String get agentV2RulesTrust2Factor => '平台Trust2';

  @override
  String get agentV2RulesSettlementCase1 => '实发 = 名义产出，剩余额度作废';

  @override
  String get agentV2RulesSettlementCase2 => '等比缩放：你实得 = 你的名义产出 × (奖池 ÷ 全网产出)';

  @override
  String get gameSettlementRecords => '每周结算记录';

  @override
  String get gameFilterComputingPower => '片酬';

  @override
  String get gameFilterLevel => '等级';

  @override
  String get gameFilterHeat => '热度';

  @override
  String get gameFilterStamina => '体力';

  @override
  String get gameHeatCoef => '热度系数';

  @override
  String get gameMiningCoef => '挖矿系数';

  @override
  String get gameActorPower => '角色片酬';

  @override
  String get gameActorPowerDetailTitle => '角色片酬详情';

  @override
  String get gameActorPowerFormula => '角色片酬 = IP片酬 × 挖矿系数 × CP系数 × Trust2';

  @override
  String get gameActorPowerIpFormula => 'IP片酬 = 价格系数 × 热度系数 × Trust1';

  @override
  String get gameActorPowerHourlyOutput => '每小时产出';

  @override
  String get gameCpCoefficient => 'CP 系数';

  @override
  String get gameTrust2 => 'Trust2';

  @override
  String get gameWeeklyNominalOutputLabel => '本周名义产出';

  @override
  String get gameRoundNominalOutputLabel => '本局名义产出';

  @override
  String get gameSupplement => '补充';

  @override
  String get gameRest => '休息';

  @override
  String get gameDeploy => '派遣';

  @override
  String get gameDeployActor => '派遣角色';

  @override
  String get gameStatusIdle => '闲置';

  @override
  String get gameStatusMining => '挖矿中';

  @override
  String gameActorIpLabel(String id) {
    return '角色IP $id';
  }

  @override
  String gameStaminaProgress(String current, String max) {
    return '$current/$max';
  }

  @override
  String get gameStaminaMechanismTitle => '体力机制';

  @override
  String gameStaminaMechanismDesc(String currency) {
    return '派遣中的角色每小时消耗 1 点体力。体力耗尽后停止产出，休息时自动恢复。可用 $currency 即时补充体力。';
  }

  @override
  String get gameStaminaMechanismAction => '知道了';

  @override
  String gameLevelBadge(String level) {
    return 'Lv$level';
  }

  @override
  String get gameEmptyDeployed => '暂无派遣中的角色';

  @override
  String get gameEmptyMyActors => '暂无角色，去签约吧';

  @override
  String get gameDeployConfirmTitle => '确认派遣该角色？';

  @override
  String get gameRestConfirmTitle => '确认让该角色休息？';

  @override
  String get gameRestConfirmDesc => '角色休息期间暂停挖矿产出，体力会随时间恢复。';

  @override
  String get gameRestConfirmAction => '确认休息';

  @override
  String get gameRestSuccessToast => '休息成功';

  @override
  String get gameDeploySlotFull => '派遣槽位已满（最多 5 位）';

  @override
  String get gameRefillTitle => '恢复体力';

  @override
  String get gameRefillCurrentStamina => '当前体力';

  @override
  String get gameRefillCost => '恢复费用';

  @override
  String get gameRefillConfirm => '恢复全部体力';

  @override
  String get gameRefillSuccess => '恢复体力成功';

  @override
  String get gameRefillFailed => '恢复体力失败，请重试';

  @override
  String gameInsufficientUsdc(String currency) {
    return '$currency 余额不足';
  }

  @override
  String get walletInsufficientStory => 'STORY 余额不足';

  @override
  String get gameSupplementComingSoon => '补充体力功能即将上线';

  @override
  String get gameStatHelpWeekPoolTitle => '本周奖池';

  @override
  String get gameStatHelpWeekPoolSubtitle => '即 STORY 挖矿的每周硬性发放上限（周硬顶）';

  @override
  String get gameStatHelpWeekTotalPool => '本周总奖池';

  @override
  String get gameStatHelpWeekTotalPoolValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeekStakePool => '本周质押奖池（75%）';

  @override
  String get gameStatHelpWeekStakePoolValue => '1,586,538 STORY';

  @override
  String get gameStatHelpWeekInvitePool => '本周邀请奖池（25%）';

  @override
  String get gameStatHelpWeekInvitePoolValue => '528,846 STORY';

  @override
  String get gameStatHelpInitialHardCap => '初始周硬顶';

  @override
  String get gameStatHelpInitialHardCapValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeeklyDecay => '周衰减系数';

  @override
  String get gameStatHelpWeeklyDecayValue => '× 0.99572';

  @override
  String get gameStatHelpWeeklyDistributionFormula =>
      '每周实际发放 = min(全网名义产出, 当周硬顶)';

  @override
  String get gameStatHelpUnusedQuotaNote => '未发出的剩余额度不发放、不回流、不补分';

  @override
  String get gameStatHelpNominalTitle => '本周名义产出';

  @override
  String get gameStatHelpNominalSummary => '我的所有角色的周累计名义产出累加';

  @override
  String get gameStatHelpNominalSummaryHint => '单卡公式见下方说明';

  @override
  String get gameStatHelpNominalFormula => '单卡名义产出 = 单卡小时权重 × R_base × 有效挖矿时长';

  @override
  String get gameStatHelpHourlyWeight => '单卡小时权重';

  @override
  String get gameStatHelpHourlyWeightValue => '= 角色片酬';

  @override
  String get gameStatHelpActorPower => '角色片酬';

  @override
  String get gameStatHelpActorPowerValue => '= IP片酬 × 挖矿系数 × CP系数 × Trust2';

  @override
  String get gameStatHelpCpCoef => 'CP 系数';

  @override
  String get gameStatHelpRBase => 'R_base';

  @override
  String get gameStatHelpRBaseValue => '1 STORY / 单位权重 / 小时';

  @override
  String get gameStatHelpEffectiveDuration => '有效挖矿时长';

  @override
  String get gameStatHelpEffectiveDurationValue => '质押中且体力 > 0 的累计时长';

  @override
  String get gameStatHelpActualTitle => '本周预估产出';

  @override
  String get gameStatHelpActualSubtitle => '预估产出受周硬顶和单地址封顶约束，本周结束时产生实际收益';

  @override
  String get gameStatHelpIfNominalLte => '若全网名义产出 ≤ 当周硬顶：';

  @override
  String get gameStatHelpUserActualEqNominal => '用户实得 = 用户名义产出';

  @override
  String get gameStatHelpIfNominalGt => '若全网名义产出 > 当周硬顶：';

  @override
  String get gameStatHelpUserActualFormula => '用户实得 = 用户名义产出 × 当周硬顶 / 全网名义产出';

  @override
  String get gameStatHelpAddressCap => '单地址周封顶';

  @override
  String get gameStatHelpAddressCapValue => '单个地址每周最多领取当周硬顶的 5%';

  @override
  String get theaterCategoryAll => '全部';

  @override
  String get theaterCategoryAncient => '古风';

  @override
  String get theaterCategoryFinance => '金融';

  @override
  String get theaterCategorySuspense => '悬疑';

  @override
  String get theaterCategorySciFi => '科幻';

  @override
  String get theaterCategoryRealStory => '真实改编';

  @override
  String get theaterCategoryUrban => '都市';

  @override
  String get theaterSortHottest => '最热';

  @override
  String get theaterSortNewest => '最新';

  @override
  String get theaterSortTopRated => '最高收藏';

  @override
  String get theaterSortCompletedView => '最高完播';

  @override
  String theaterPlayCount(String count) {
    return '$count 次播放';
  }

  @override
  String get createDramaBasicInfo => '基本信息';

  @override
  String get createDramaEpisodes => '剧集管理';

  @override
  String get createDramaRoles => '绑定 IP';

  @override
  String get createDramaCover => '封面';

  @override
  String get createDramaCoverUpload => '上传';

  @override
  String get createDramaCoverPlaceholder => '支持 JPG/PNG，不超过 5MB';

  @override
  String get createDramaCoverCropTitle => '裁剪封面';

  @override
  String get createDramaName => '短剧标题';

  @override
  String get createDramaNameHint => '请输入短剧标题';

  @override
  String get createDramaSynopsis => '简介';

  @override
  String get createDramaTags => '标签';

  @override
  String get createDramaTagsHint => '输入标签并按回车添加 (如: 爱情, 喜剧)';

  @override
  String get createDramaTagsLoading => '加载标签中…';

  @override
  String get createDramaTagsEmpty => '暂无可用标签';

  @override
  String get createDramaTagsRetry => '重试';

  @override
  String get createDramaUploadDesc => '点击上传，提交后会按视频名称自动排序';

  @override
  String get createDramaEpisodesDesc =>
      '批量上传视频文件，系统将自动按文件名排序生成剧集列表。支持拖拽排序、删除、编辑标题等操作。';

  @override
  String get createDramaVideoFileTypeHint =>
      '限制文件类型 mp4, flv, wmv, asf, mkv, avi, rm, rmvb, mpg, mpeg, mov, webm 文件大小不超过2GB';

  @override
  String get createDramaUploadVideo => '上传视频';

  @override
  String get createDramaVideoEmpty => '还没有添加视频';

  @override
  String get createDramaVideoPickFailed => '选择视频失败';

  @override
  String get createDramaVideoAnyTooLarge => '所选视频中有文件超过2GB, 请调整后重新上传';

  @override
  String get createDramaVideoStatusUploading => '上传中';

  @override
  String get createDramaVideoStatusPaused => '上传已暂停';

  @override
  String get createDramaVideoStatusDone => '上传完成';

  @override
  String get createDramaEpisodeDescriptionHint => '分集描述';

  @override
  String get createDramaVideoStatusFailed => '上传失败';

  @override
  String get createDramaVideoTooLarge => '视频大小不能超过 2GB，无法上传';

  @override
  String get createDramaVideoUploadComplete => '全部视频上传完成';

  @override
  String createDramaVideoUploadFailed(String name) {
    return '$name 上传失败';
  }

  @override
  String createDramaVideoPickOverflow(int count, int overflow) {
    return '最多只能再添加 $count 集视频，多出的 $overflow 个未加入';
  }

  @override
  String createDramaAddedVideos(String count) {
    return '已添加的视频 ($count 个文件)';
  }

  @override
  String createDramaAddedVideosCount(String count) {
    return '($count 个文件)';
  }

  @override
  String get createDramaAddedVideosLabel => '已添加的视频';

  @override
  String get createDramaRolesDesc => '为短剧创建人物，设定人物名称、头像与性格简介。';

  @override
  String get createDramaRolesRule1 =>
      '每部短剧最多绑定 5 个角色 IP，上架 7 天内可新增，发布后不可解除或更换。';

  @override
  String get createDramaRolesRule2 => '绑定后，角色IP将关联短剧的完播和热度数据，用于升级角色和产出STORY。';

  @override
  String get createDramaRolesExpireTime => '截止时间';

  @override
  String get createDramaRolesRule3 => '绑定 IP 为选填，可不绑定直接发布。';

  @override
  String get createDramaAddRole => '添加人物';

  @override
  String get createDramaBindActor => '角色参演';

  @override
  String get createDramaRoleActing => '角色参演';

  @override
  String get createDramaSelectActor => '选择角色';

  @override
  String get createDramaBindActorTitle => '选择角色 IP';

  @override
  String createDramaBindIpSelectedCount(int count) {
    return '已选 $count 个';
  }

  @override
  String get createDramaBindIpEmpty => '暂无数据';

  @override
  String get createDramaBindIpMarketplace => '前往角色IP市场';

  @override
  String get createDramaBindIpConfirm => '确认绑定';

  @override
  String createDramaBindActorSubtitle(String roleName) {
    return '选择一名角色IP来饰演「$roleName」';
  }

  @override
  String createDramaBindActorOwnedCount(int count) {
    return '持有 $count 个角色IP';
  }

  @override
  String createDramaBindActorIpLabel(String code) {
    return '角色IP $code';
  }

  @override
  String get createDramaBindActorBoundTag => '已绑定';

  @override
  String get createDramaBindIpRemove => '移除';

  @override
  String createDramaBindActorBoundToast(String name) {
    return '已绑定 $name';
  }

  @override
  String get createDramaBindActorUnbind => '解除绑定';

  @override
  String get createDramaBindActorExpired => '已超过 7天窗口期，不可新增绑定角色IP';

  @override
  String get createDramaBindActorEmptyTitle => '暂无可绑定的角色IP';

  @override
  String get createDramaBindActorEmptyDesc => '你需要先持有角色IP才能绑定到人物';

  @override
  String get createDramaBindActorGotoCreate => '去创建角色';

  @override
  String get createDramaPrevStep => '上一步';

  @override
  String get createDramaNextStep => '下一步';

  @override
  String get createDramaSubmit => '发布';

  @override
  String get createDramaRoleNameLabel => '人物名称';

  @override
  String get createDramaRoleNameHint => '请输入人物名称';

  @override
  String get createDramaRoleNameRequired => '请输入人物名';

  @override
  String get createDramaRoleBioLabel => '简介';

  @override
  String get createDramaRoleBioHint => '请输入人物简介';

  @override
  String get createDramaRoleBioRequired => '请输入人物简介';

  @override
  String get createDramaRoleAddTitle => '添加人物';

  @override
  String get createDramaRoleEditTitle => '编辑人物';

  @override
  String get createDramaRoleUploadAvatar => '上传头像';

  @override
  String get createDramaRoleSave => '保存';

  @override
  String get createDramaRoleDeleteConfirm => '确定删除该人物？';

  @override
  String createDramaVideoDeleteConfirm(String name) {
    return '确定删除“$name”吗？';
  }

  @override
  String get createDramaVideoDeleteTitle => '删除视频';

  @override
  String get createDramaVideoPreviewUnavailable => '历史上传视频，暂不支持播放预览';

  @override
  String get createDramaRoleEmpty => '暂未添加人物';

  @override
  String get createDramaRoleBindComingSoon => '绑定角色功能即将上线';

  @override
  String get createDramaRoleAvatarCropTitle => '裁剪人物头像';

  @override
  String get createDramaRoleAvatarUploadFailed => '人物头像上传失败';

  @override
  String get createDramaPublishedSuccess => '发布成功';

  @override
  String get createDramaDraftRestored => '已同步草稿数据';

  @override
  String get createDramaDraftClear => '清除数据';

  @override
  String get createDramaDraftDiscard => '不保存返回';

  @override
  String get createDramaDraftSave => '存草稿';

  @override
  String get createDramaEditLoading => '加载中...';

  @override
  String get createDramaEditLoadError => '加载短剧信息失败，请重试';

  @override
  String get createDramaSubmitValidationTitle => '请填写短剧标题';

  @override
  String get createDramaSubmitValidationCover => '请上传封面图';

  @override
  String get createDramaSubmitValidationVideos => '请至少上传一个视频';

  @override
  String get createDramaSubmitValidationSession => '上传会话异常，请重新上传视频';

  @override
  String get createDramaUploadSessionFailed => '创建上传会话失败';

  @override
  String get createDramaSubmitValidationRoles => '请至少添加一个人物';

  @override
  String get createDramaStep1TitleRequired => '请输入短剧标题';

  @override
  String get createDramaStep1SynopsisRequired => '请输入简介';

  @override
  String get createDramaStep1CoverRequired => '请添加封面';

  @override
  String get createDramaStep1TagsRequired => '请选择标签';

  @override
  String get createDramaEpisodeDescriptionRequired => '请输入分集描述';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeLight => '日间';

  @override
  String get settingsThemeDark => '夜间';

  @override
  String get settingsThemeSystem => '系统';

  @override
  String get settingsUI => '界面';

  @override
  String get settingsAppVersion => '版本';

  @override
  String get settingsVersionLatestToast => '当前版本为最新版本';

  @override
  String get settingsVersionCheckFailed => '版本检查失败，请稍后再试';

  @override
  String get appVersionUpdateTitle => '发现新版本';

  @override
  String get appVersionUpdateContentsLabel => '更新内容：';

  @override
  String get appVersionUpdateConfirm => '立即更新';

  @override
  String get appVersionUpdateLater => '以后再说';

  @override
  String get settingsTermsOfService => '服务条款';

  @override
  String get settingsPrivacyPolicy => '隐私政策';

  @override
  String get settingsDeleteAccount => '删除账户';

  @override
  String settingsDeleteAccountConfirm(String deadline) {
    return '您的账户将在 $deadline 被删除。在此时间内，您可以再次登录以取消账户删除。';
  }

  @override
  String get settingsDeleteAccountSuccess => '删除账户申请已提交';

  @override
  String get settingsClearCache => '清理缓存';

  @override
  String get settingsNetworkInspector => '网络请求';

  @override
  String get settingsClearCacheConfirm => '确认要清理缓存吗？';

  @override
  String get miningRulesHowToPlay => '派遣挖矿怎么玩';

  @override
  String get miningRulesFlowSubtitle => '一张图看懂从派人到领钱的全流程';

  @override
  String get miningRulesSection1Title => '派遣';

  @override
  String get miningRulesSection1Desc =>
      '把空闲的角色「派遣」到下面的 5 个槽位里，他就开始自动挖矿、产出 STORY。';

  @override
  String get miningRulesSection1Bullet1 => '每人最多同时派遣 5 位角色';

  @override
  String get miningRulesSection1Bullet2 => '同一个角色IP也可以多张卡一起派遣';

  @override
  String get miningRulesSection1Bullet3 =>
      '派遣后每小时消耗 1 点体力，体力 > 0 就一直产出，体力 = 0 就停工';

  @override
  String get miningRulesSection2Title => '产出公式';

  @override
  String get miningRulesSection2Desc => '每张卡每小时的产出是这样算的：';

  @override
  String get miningRulesSection2Formula => '单卡小时产出 = 角色片酬 × 1 STORY';

  @override
  String get miningRulesSection2FactorsTitle => '其中：';

  @override
  String get miningRulesSection2Factor1 => '角色片酬= IP片酬 × 挖矿系数 × CP系数 × Trust2';

  @override
  String get miningRulesSection2Factor2 => 'IP 片酬= 价格系数 × 热度系数 × Trust1';

  @override
  String get miningRulesSection2Factor3 =>
      '挖矿系数——咖位越高系数越大。Lv1=1.0 → Lv2=2.2 → Lv3=5.0 → Lv4=11 → Lv5=24';

  @override
  String miningRulesSection2Factor4(String currency1, String currency2) {
    return '价格系数——发行价 P0：P0≤10$currency1 线性增长 · P0>10$currency2 渐近上限 1.6';
  }

  @override
  String get miningRulesSection2Factor5 => '热度系数——近期剧表现越好热度越高（完播、点赞、收藏、评论）';

  @override
  String get miningRulesSection2Factor6 => 'CP 系数——暂未开放；Trust 默认 1.0';

  @override
  String miningRulesSection2StaminaText(int staminaLimit) {
    return '体力只看\"有没有\"：$staminaLimit 点和 1 点体力的每小时产出一样多。';
  }

  @override
  String get miningRulesSection2ExampleTitle => '示例';

  @override
  String miningRulesSection2ExampleDesc(String currency) {
    return '林梦瑶 Lv3 主角 · P0=12$currency（价格系数 ≈1.0859）· 热度 3.5\n→ 每小时产出 = 5.0 × 1.0859 × 3.5 × 1 = 19.00325 STORY';
  }

  @override
  String get miningRulesCoefTableTitle => '各系数说明';

  @override
  String get miningRulesCoefColCoef => '系数';

  @override
  String get miningRulesCoefColFactor => '决定因素';

  @override
  String get miningRulesCoefColDesc => '说明';

  @override
  String get miningRulesCoefMining => '挖矿系数';

  @override
  String get miningRulesCoefPrice => '价格系数';

  @override
  String get miningRulesCoefHeat => '热度系数';

  @override
  String get miningRulesCoefCp => 'CP 系数';

  @override
  String get miningRulesCoefTrust => 'Trust';

  @override
  String get miningRulesCoefMiningFactor => '咖位';

  @override
  String get miningRulesCoefPriceFactor => '发行价 P0';

  @override
  String get miningRulesCoefHeatFactor => '近期剧表现';

  @override
  String get miningRulesCoefCpFactor => '-';

  @override
  String get miningRulesCoefTrustFactor => '平台风控';

  @override
  String get miningRulesCoefMiningDesc =>
      'Lv1=1.0 · Lv2=2.2 · Lv3=5.0 · Lv4=11 · Lv5=24';

  @override
  String miningRulesCoefPriceDesc(String currency1, String currency2) {
    return 'P0≤10$currency1 线性增长 · P0>10$currency2 渐近上限 1.6';
  }

  @override
  String get miningRulesCoefHeatDesc => '热度系数：角色IP参演短剧的完播、点赞、收藏、评分越多，热度越高';

  @override
  String get miningRulesCoefCpDesc => '暂未开放';

  @override
  String get miningRulesCoefTrustDesc => '默认 1.0';

  @override
  String get miningRulesSection3Title => '结算分配';

  @override
  String get miningRulesSection3Desc =>
      '每周全平台有一个总奖池（周硬顶），初始约 2,115,385 STORY，之后逐周递减（每周 × 0.99572）。';

  @override
  String get miningRulesSettleColCondition => '条件';

  @override
  String get miningRulesSettleColRule => '分配规则';

  @override
  String get miningRulesSection3Case1Title => '全网名义产出 ≤ 当周硬顶';

  @override
  String get miningRulesSection3Case1Desc => '每人照单全收，剩余部分不发、不补';

  @override
  String get miningRulesSection3Case2Title => '全网名义产出 > 当周硬顶';

  @override
  String get miningRulesSection3Case2Desc => '等比缩放：你实得 = 你的名义产出 × 奖池 ÷ 全网产出';

  @override
  String get miningRulesSection3Case3Title => '单地址超过奖池 5%';

  @override
  String get miningRulesSection3Case3Desc => '超出部分不发，不回流，不补分';

  @override
  String get miningRulesSection3ExampleDesc =>
      '假设本周奖池 100,000 STORY：\n情况 A：全平台只有你产出 134 → 你拿 134，剩下不发放\n情况 B：全网产出 250,000 → 等比缩放到 40%\n情况 C：缩放后某人应得 6,000，但上限 5,000 → 只发 5,000';

  @override
  String get miningRulesSection4Title => '体力管理';

  @override
  String get miningRulesTableStatus => '状态';

  @override
  String get miningRulesTableStaminaChange => '体力变化';

  @override
  String get miningRulesTableOutput => '产出';

  @override
  String get miningRulesStatusMining => '派遣中（挖矿）';

  @override
  String get miningRulesStaminaMining => '每小时 -1';

  @override
  String get miningRulesOutputNormal => '正常产出';

  @override
  String get miningRulesStatusZeroStamina => '体力耗尽';

  @override
  String get miningRulesStaminaZeroStamina => '不再变化';

  @override
  String get miningRulesOutputZero => '产出为 0';

  @override
  String get miningRulesStatusResting => '召回休息';

  @override
  String get miningRulesStaminaResting => '每小时 +1（自动恢复）';

  @override
  String get miningRulesOutputPaused => '暂停产出';

  @override
  String get miningRulesStatusPaidRefill => '补充体力（付费）';

  @override
  String miningRulesStaminaPaidRefill(int staminaLimit) {
    return '瞬间回满 $staminaLimit';
  }

  @override
  String get miningRulesOutputRestored => '恢复产出';

  @override
  String get miningRulesSection4TipsTitle => '补充体力须知';

  @override
  String get miningRulesSection4Tip1 => '只能一键加满，不能只买 10 点';

  @override
  String get miningRulesSection4Tip2 => '价格只看咖位，与剩余体力无关';

  @override
  String get miningRulesSection4Tip3 => '越靠近 0 补充越划算——同样价格买到最多的挖矿时长';

  @override
  String get miningRulesSection4PriceTitle => '补充价格';

  @override
  String get miningRulesPriceTableTier => '咖位';

  @override
  String get miningRulesPriceTableFullRefill => '一键加满';

  @override
  String get miningRulesLv1 => 'Lv1 群演';

  @override
  String get miningRulesLv2 => 'Lv2 配角';

  @override
  String get miningRulesLv3 => 'Lv3 主角';

  @override
  String get miningRulesLv4 => 'Lv4 巨星';

  @override
  String get miningRulesLv5 => 'Lv5 顶流';

  @override
  String get gameActorLevelName1 => '群演';

  @override
  String get gameActorLevelName2 => '配角';

  @override
  String get gameActorLevelName3 => '主角';

  @override
  String get gameActorLevelName4 => '巨星';

  @override
  String get gameActorLevelName5 => '顶流';

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
  String get miningRulesSection5Title => '升级咖位';

  @override
  String get miningRulesSection5Desc =>
      '3 张同角色同咖位的卡 + 合成费 + 该角色累计完播达标 = 升 1 级。升级后挖矿系数暴涨，每小时产出翻倍甚至翻几倍。';

  @override
  String get miningRulesUpgradePathSubtitle => '升级路径';

  @override
  String get miningRulesUpgradeColPath => '升级路径';

  @override
  String get miningRulesUpgradeColHeat => '累计完播门槛';

  @override
  String get miningRulesUpgradeColFee => '合成费';

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
  String get miningRulesSummaryTitle => '一句话总结';

  @override
  String get miningRulesSummaryDesc =>
      '派人 → 产出 → 盯体力 → 领钱。体力快没了就补充或召回休息，热度靠角色的剧表现提升，升级让产出起飞。';

  @override
  String get playerNotInterested => '不感兴趣';

  @override
  String get playerNotInterestedDone => '已反馈，将减少此类推荐';

  @override
  String get playerClearScreen => '清屏';

  @override
  String get playerAutoPlay => '连播';

  @override
  String get playerReport => '举报';

  @override
  String get playerReportSuccess => '举报成功';

  @override
  String get commentReportSuccess => '提交成功，将为你尽快受理';

  @override
  String get reportSuccessTitle => '提交成功，我们将尽快受理';

  @override
  String get reportSuccessThanks => '感谢您对社区安全做的贡献！';

  @override
  String get reportSuccessAlsoYouCan => '同时你可以';

  @override
  String get reportSuccessDone => '完成';

  @override
  String get reportReduceRecommend => '减少推荐';

  @override
  String get reportReduceRecommendDone => '已减少推荐';

  @override
  String get reportSuccessContentFallback => '该内容';

  @override
  String get reportDescription => '举报描述';

  @override
  String get reportDescriptionPlaceholder => '请描述具体原因（选填）';

  @override
  String get reportReasonPorn => '低俗色情';

  @override
  String get reportReasonIllegal => '涉嫌违法犯罪';

  @override
  String get reportReasonSensitive => '内容敏感';

  @override
  String get reportReasonGambling => '涉黑赌博';

  @override
  String get reportReasonMinors => '侵害未成年人';

  @override
  String get reportReasonCopyright => '侵权投诉';

  @override
  String get reportReasonQuality => '质量问题';

  @override
  String get reportReasonNotLike => '我不喜欢';

  @override
  String get reportReasonOther => '其他';

  @override
  String get gameUpgrade => '升级';

  @override
  String get gameUpgradeTitle => '咖位升级';

  @override
  String get gameUpgradeCurrentLevel => '当前等级';

  @override
  String get gameUpgradeTargetLevel => '目标等级';

  @override
  String get gameUpgradeHeatThreshold => '参演短剧累计完播';

  @override
  String get gameUpgradeRequiredCount => '消耗同IP同等级角色';

  @override
  String get gameUpgradeFee => '升级费用';

  @override
  String get gameUpgradeNextLevelReq => '下一级升级要求';

  @override
  String get gameUpgradeBeforeAfter => '升级前后对比';

  @override
  String get gameUpgradeSelectMaterialDesc => '选择要消耗的同IP同等级角色';

  @override
  String gameUpgradeMaterialCount(int current, int required) {
    return '$current/$required';
  }

  @override
  String gameUpgradeToLevel(int level, String levelName) {
    return '升级到 Lv$level $levelName';
  }

  @override
  String gameUpgradeSelectMaterialLabel(int current, int required) {
    return '选择材料 ($current/$required)';
  }

  @override
  String gameUpgradeSelectMaterials(int count) {
    return '请选择 $count 个材料';
  }

  @override
  String get gameUpgradeConfirm => '确认升级';

  @override
  String get gameUpgradeSuccess => '升级成功';

  @override
  String get gameUpgradeFailed => '升级失败，请重试';

  @override
  String get gameUpgradeInsufficientMaterials => '材料不足';

  @override
  String get gameUpgradeNoMaterials => '没有可消耗的同IP同等级角色';

  @override
  String get creatorDramaStatusMinted => '已铸造';

  @override
  String get creatorDramaStatusOffline => '已下架';

  @override
  String get creatorDramaStatusUnavailable => '暂不可操作';

  @override
  String get creatorMintDramaNft => '铸造短剧NFT';

  @override
  String get creatorMintConfirmDesc => '确认铸造该短剧为链上 NFT，铸造后该短剧将可产生 STORY 挖矿收益。';

  @override
  String get creatorMintFee => '铸造手续费';

  @override
  String creatorMintInsufficientUsdc(String currency1, String currency2) {
    return '$currency1 余额不足，链上发行需要至少 1 $currency2';
  }

  @override
  String get creatorMintInvalidDramaId => '短剧 ID 无效';

  @override
  String get creatorMintInProgress => '铸造进行中，请稍候';

  @override
  String get creatorMintWalletNotReady => 'Solana 钱包地址未就绪，请重新登录';

  @override
  String get creatorMintDigestEmpty => '发行签名数据为空，请稍后重试';

  @override
  String get creatorMintWalletMismatch => '铸造钱包与当前钱包不一致，请重新登录';

  @override
  String get creatorMintSuccess => '铸造成功！';

  @override
  String creatorMintDramaOnChain(String name) {
    return '《$name》短剧NFT已上链';
  }

  @override
  String creatorMintNftNumber(String id) {
    return 'NFT编号：$id';
  }

  @override
  String get creatorMintTxHash => '交易哈希：';

  @override
  String get gameSelectActor => '选择派遣角色';

  @override
  String get gameSelectActorDesc => '选择一位空闲中的角色进行派遣';

  @override
  String get agentV2SchedulePerformance => '演出';

  @override
  String get agentV2PerformAllTitle => '一键演出';

  @override
  String get agentV2PerformAllDescription => '将按片酬从高到低安排到空在演位';

  @override
  String get agentV2PerformAllFailed => '一键演出失败，请重试';

  @override
  String get agentV2PerformAllSuccess => '一键演出成功';

  @override
  String agentV2PerformAllDepletedResult(int successCount, int depletedCount) {
    return '$successCount位演出成功，$depletedCount位体力耗尽暂无法演出';
  }

  @override
  String get agentV2RestAllSuccess => '一键休息成功';

  @override
  String agentV2PerformAllCount(int count) {
    return '$count个角色';
  }

  @override
  String get agentV2TodoTitle => '待办';

  @override
  String agentV2TodoVacancies(int count) {
    return '还有 $count 个在演位空缺';
  }

  @override
  String agentV2TodoStaminaDepleted(String name) {
    return '$name 体力仅剩 0，已停工';
  }

  @override
  String get agentV2TodoPerform => '去演出';

  @override
  String get agentV2TodoRefill => '去补充';

  @override
  String get agentV2TodoHealthy => '演出正常 · 体力充足';

  @override
  String get agentV2CandidateActorsTitle => '候选角色';

  @override
  String get agentV2CandidateActorsDescription => '休息中的角色每小时恢复1点体力';

  @override
  String get agentV2UpgradeableActorsTitle => '升级角色';

  @override
  String get agentV2UpgradeableActorsEmpty => '暂无可升级角色';

  @override
  String get agentV2NoActors => '暂无角色';

  @override
  String get agentV2UpgradeNow => '立即升级';

  @override
  String get agentV2UpgradeCompletion => '完播';

  @override
  String get agentV2UpgradeMaterials => '角色';

  @override
  String agentV2UpgradeRequirementsTitle(String name) {
    return '升级 $name';
  }

  @override
  String agentV2UpgradeCompletionRemaining(int count) {
    return '还需 $count 完播';
  }

  @override
  String get agentV2UpgradeCompletionHint => '观看该角色参演的短剧，或为它创作新剧，都可提升完播';

  @override
  String get agentV2UpgradeWatchDramas => '看参演短剧';

  @override
  String get agentV2UpgradeCreateDrama => '去创作短剧';

  @override
  String agentV2UpgradeMaterialsRemaining(int count) {
    return '还需 $count 张同IP同等级角色';
  }

  @override
  String agentV2UpgradeMaterialsHint(String name) {
    return '去角色主页签约更多「$name」';
  }

  @override
  String get agentV2UpgradeGetActors => '去获取角色';

  @override
  String agentV2UpgradeActorsSyncing(int count) {
    return '$count 个新角色同步中，升级条件已更新';
  }

  @override
  String get agentV2UpgradeConfirmSelectMaterials => '选择要消耗的同IP同等级演员';

  @override
  String get agentV2UpgradeConfirmSalaryLabel => '片酬';

  @override
  String get agentV2SalaryDetailTitle => '角色片酬';

  @override
  String get agentV2SalaryHourly => '每小时片酬';

  @override
  String get agentV2SalaryUnit => 'STORY / 小时';

  @override
  String get agentV2SalaryFormula => '角色片酬 = IP片酬 × 片酬系数 × CP系数 × Trust2';

  @override
  String get agentV2SalaryFormulaLv1 => 'Lv.1 角色片酬 = 价格系数 × 热度系数';

  @override
  String agentV2SalaryFormulaLevel(int level) {
    return 'Lv.$level片酬 = Lv.1片酬 × 片酬系数';
  }

  @override
  String get agentV2SalaryLv1Pay => 'Lv.1 片酬';

  @override
  String get agentV2SalaryCoefficient => '片酬系数';

  @override
  String agentV2SalaryCoefficientWithLevel(int level, String roleName) {
    return '片酬系数（Lv.$level $roleName）';
  }

  @override
  String get agentV2SalaryCpCoefficient => 'CP 系数';

  @override
  String get agentV2PerformanceConfirmDescription =>
      '该角色演出时自动产生片酬收益。演出中每小时消耗 1 点体力，体力耗尽则停止产出。';

  @override
  String get agentV2PerformanceConfirmTitle => '安排演出';

  @override
  String get agentV2PerformanceZeroFeePrefix => '该角色IP当前';

  @override
  String get agentV2PerformanceZeroFeeHighlight => '片酬为0';

  @override
  String get agentV2PerformanceZeroFeeSuffix =>
      '，演出不会产生收益。且演出中每小时消耗 1 点体力，是否仍要继续？';

  @override
  String get agentV2PerformanceScheduledSuccess => '已安排演出';

  @override
  String get agentV2PerformanceSlotsFull => '演出位已满(最多5个)';

  @override
  String get gameDeployStaminaDepleted => '体力已耗尽，补充体力后可演出';

  @override
  String get agentMoreRules => '规则';

  @override
  String get agentMoreSalaryAndPool => '片酬与奖池';

  @override
  String get agentV2WeeklySalaryTitle => '升级·演出·赚片酬';

  @override
  String get agentV2WeeklySalaryLabel => '本周片酬';

  @override
  String get gameDeployConfirmDesc =>
      '该角色将自动进行质押挖矿，持续为你产出 STORY 收益。注意：每个整点消耗 1 点体力，体力耗尽则停止产出。';

  @override
  String get gameRecallConfirm => '确认召回';

  @override
  String get gameRecallDesc => '召回此角色将暂停短剧的生产收益，且当前体力不受影响。';

  @override
  String get actorStatCompletionTitle => '完播';

  @override
  String get actorStatCompletionDesc => '该角色IP参演的所有短剧的完播次数之和';

  @override
  String get actorStatHeatTitle => '热度';

  @override
  String get actorStatHeatDesc => '该角色IP参演的所有短剧最近30天的热度之和';

  @override
  String get actorStatIpPowerTitle => 'IP片酬';

  @override
  String get actorStatIpPowerDesc => 'IP片酬 = 价格系数 × 热度系数 × Trust1';

  @override
  String get dramaFavoriteLabel => '收藏';

  @override
  String get dramaRatingLabel => '评分';

  @override
  String get dramaUnnamed => '未命名';

  @override
  String get videoNotReady => '视频尚未就绪，请稍后';

  @override
  String get inviteDirectSubordinates => '已邀请用户';

  @override
  String inviteTotalCount(int count) {
    return '共 $count 人';
  }

  @override
  String get inviteTotalLabel => '总人数';

  @override
  String get inviteActiveLabel => '有效用户';

  @override
  String get invitePendingLabel => '待激活';

  @override
  String get inviteEmpty => '暂无下级用户';

  @override
  String inviteRegisteredAt(String date) {
    return '注册于 $date';
  }

  @override
  String get gameUpgradeMaxLevel => '已达到顶级咖位';

  @override
  String get listNoMoreData => '没有更多数据了';

  @override
  String get iapSheetTitle => '购买点数';

  @override
  String get iapSheetSubtitle => '点数用于签约角色等 APP 内服务';

  @override
  String get iapBalance => '余额';

  @override
  String get iapConfirmPurchase => '确认购买';

  @override
  String get iapPurchaseSuccess => '购买成功';

  @override
  String get iapPurchaseFailed => '购买失败，请稍后重试';

  @override
  String get iapPurchaseFailedTitle => '购买失败';

  @override
  String get iapCrediting => '到账处理中，请稍候';

  @override
  String get iapNoProducts => '暂无可购买商品';

  @override
  String get iapSuccessConfirm => '确定';

  @override
  String iapGainedPoints(String value) {
    return '+$value';
  }

  @override
  String iapPointsCount(int count) {
    return '$count 点数';
  }

  @override
  String get gameBatchRefillTransactionTooLarge => '批量补充交易数据过大，请减少演员数量后重试';

  @override
  String get agentV2RefillTitle => '补充体力';

  @override
  String get agentV2RefillCost => '花费';

  @override
  String get agentV2RefillActorButton => '该角色';

  @override
  String get agentV2RefillAllActors => '补充全部演出中角色';

  @override
  String agentV2RefillActorCount(int count) {
    return '$count 位';
  }

  @override
  String get agentV2RefillAllButton => '全部补充';

  @override
  String get agentV2RefillOr => '或';

  @override
  String get agentV2RestAll => '全部休息';

  @override
  String agentV2RestActorCount(int count) {
    return '$count位';
  }

  @override
  String get salaryPoolRateUnit => 'STORY / 小时';

  @override
  String get salaryPoolDecayInfo => '周衰减系数 ×0.99572';

  @override
  String get salaryPoolStakeLabel => '演出奖池（75%）';

  @override
  String get salaryPoolInviteLabel => '邀请奖池（25%）';

  @override
  String get salaryPoolRule1Title => '全网名义产出 ≤ 当周硬顶：';

  @override
  String get salaryPoolRule2Title => '全网名义产出 > 当周硬顶：';

  @override
  String get salaryPoolRule2Body => '用户实得 = 用户名义产出 ×（当周硬顶 ÷ 全网名义产出）';

  @override
  String get agentV3WeeklySalary => '本周片酬';

  @override
  String get agentV3PerformAll => '一键演出';

  @override
  String get agentV3RestAll => '一键休息';

  @override
  String get agentV3RestAllDescription => '将召回全部在演角色，停止消耗体力与产出';

  @override
  String get agentV3RefillAll => '一键补充';

  @override
  String get agentV3RefillAllDescription => '补满演出中角色的体力';

  @override
  String get agentV3RefillCost => '消耗';

  @override
  String get agentV3RefillNoActors => '暂无需要补充体力的角色';

  @override
  String get agentV3SignActor => '签约角色';

  @override
  String get agentV3Todo => '待办';

  @override
  String get agentV3Upgrade => '升级';

  @override
  String agentV3UpgradeMaterialHint(int count) {
    return '升级需消耗 $count 张同IP同等级角色';
  }

  @override
  String get agentV3Waiting => '候场';

  @override
  String get agentV3WaitingActorsTitle => '候场角色';

  @override
  String get agentV3WaitingActorsDescription => '休息中的角色每小时恢复1点体力';

  @override
  String get agentV3Recycle => '回收';

  @override
  String get agentV3RecycleActorsTitle => '角色回收';

  @override
  String get agentV3RecyclePerforming => '演出中';

  @override
  String get agentV3RecycleReceive => '你将获得';

  @override
  String get agentV3RecyclePermanentWarning => '角色将被永久销毁，不可恢复';

  @override
  String get agentV3RecycleConfirm => '确认销毁';

  @override
  String get agentV3RecycleConfirmAgain => '再次点击销毁';

  @override
  String get agentV3RecycleSubmitted => '角色回收成功';

  @override
  String get agentV3RecycleEstimateUnavailable => '回收预估暂不可用，请重试';

  @override
  String get agentV3EnergyPack => '体力补给包';

  @override
  String get agentV3EnergyPackDescription => '补满角色体力，按角色等级消耗。';

  @override
  String get agentV3TrainingManual => '训练手册';

  @override
  String get agentV3TrainingManualDescription => '角色升级材料，升级时按角色等级消耗。';

  @override
  String get agentV3PurchaseButton => '购买';

  @override
  String agentV3PurchaseWalletBalance(String balance, String currency) {
    return '余额 $balance $currency';
  }

  @override
  String agentV3PurchaseTitle(String item) {
    return '购买$item';
  }

  @override
  String get agentV3PurchaseUnitPrice => '单价';

  @override
  String get agentV3PurchaseQuantity => '数量';

  @override
  String get agentV3PurchaseTotal => '合计';

  @override
  String get agentV3PurchaseConfirm => '确认支付';

  @override
  String get agentV3PurchaseUnavailable => '当前环境暂未开放道具购买';

  @override
  String get agentV3PurchaseConfigUnavailable => '道具价格暂不可用，请稍后重试';

  @override
  String get agentV3PurchaseSubmitted => '购买成功，已放入道具背包（经纪人页面）';

  @override
  String get agentV3PurchaseCreditPending => '体力包仍在入账，请稍后重试';

  @override
  String get agentV3PurchaseCrediting => '扫链入账中';

  @override
  String agentV3PurchaseBalance(String count) {
    return '当前持有：$count';
  }

  @override
  String get agentV3RefillTitle => '补满体力';

  @override
  String agentV3RefillLevelCost(String level) {
    return 'Lv.$level 消耗';
  }

  @override
  String get agentV3RefillAvailable => '可用';

  @override
  String get agentV3RefillUse => '使用';

  @override
  String get agentV3RefillSuccess => '体力已补满';

  @override
  String agentV3RefillAllSuccess(int actorCount, String packCount) {
    return '已补充 $actorCount 位角色的体力（消耗补给包 $packCount）';
  }

  @override
  String get agentV3RefillConfigUnavailable => '体力包消耗配置暂不可用';

  @override
  String get agentV3RefillInsufficient => '体力包余额不足';
}
