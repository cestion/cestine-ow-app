// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'StoryFun';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonNoData => 'データがありません';

  @override
  String get commonNo => 'いいえ';

  @override
  String get commonYes => 'はい';

  @override
  String get publishDrama => 'ドラマを投稿';

  @override
  String get publishVideo => '動画を投稿';

  @override
  String get publishVideoUploadTitle => '動画ファイルをアップロード';

  @override
  String get publishVideoFileHint => 'mp4、flv、wmv、mkv、avi、mov、webm、最大2GB';

  @override
  String get publishVideoChooseFile => 'ファイルを選択';

  @override
  String get publishVideoChangeFile => 'ファイルを変更';

  @override
  String get publishVideoChooseSource => '動画の選択元';

  @override
  String get publishVideoChooseFromGallery => '写真ライブラリから選択';

  @override
  String get publishVideoChooseFromFiles => 'ファイルから選択';

  @override
  String get publishVideoPreparing => '動画を準備しています…';

  @override
  String get publishVideoCoverTitle => '動画カバー';

  @override
  String get publishVideoChangeCover => 'カバーを変更';

  @override
  String get publishVideoCoverHint => 'JPG/PNG、最大5MB';

  @override
  String get publishVideoDescriptionLabel => '説明';

  @override
  String get publishVideoRequired => '（必須）';

  @override
  String get publishVideoDescriptionHint => '作品の説明を追加（最大200文字）';

  @override
  String get publishVideoSaveDraft => '下書きを保存';

  @override
  String get publishVideoDraftEditModeNotSupported => '編集モードでは下書きを保存できません';

  @override
  String get publishVideoDraftNothingToSave => '保存できる内容がありません';

  @override
  String get publishVideoNext => '次へ';

  @override
  String get publishVideoCoverCropTitle => '動画カバーを切り抜く';

  @override
  String get publishVideoVideoTooLarge => '動画ファイルは2GB以下にしてください';

  @override
  String get publishVideoVideoPickFailed => '動画を選択できませんでした。もう一度お試しください';

  @override
  String get publishVideoInsufficientStorage => '動画を準備するための空き容量が不足しています';

  @override
  String get publishVideoPermissionDenied =>
      '動画にアクセスできません。写真またはファイルの権限を確認してください';

  @override
  String get publishVideoSourceUnavailable =>
      'この動画は一時的に利用できません。クラウドのファイルをダウンロードしてから再試行してください';

  @override
  String get publishVideoPrepareFailed => '動画を準備できませんでした。再試行するか、ファイルから選択してください';

  @override
  String get publishVideoMetadataUnavailable => '動画情報を読み取れません。別のファイルを選択してください';

  @override
  String get publishVideoCoverTooLarge => 'カバー画像は5MB以下にしてください';

  @override
  String get publishVideoCoverUnsupportedFormat => 'JPG/PNG形式の画像のみ対応しています';

  @override
  String get publishVideoCoverPickFailed => 'カバーを選択できませんでした。もう一度お試しください';

  @override
  String get publishVideoUploadSessionFailed => 'アップロードセッションを作成できませんでした';

  @override
  String get publishVideoPublishedSuccess => '動画を投稿しました';

  @override
  String get publishVideoUpdatedSuccess => '動画を更新しました';

  @override
  String get publishActorIp => 'IPを発行';

  @override
  String get commonConfirm => '確認';

  @override
  String get commonOk => '了解';

  @override
  String get commonNotice => 'お知らせ';

  @override
  String get commonRetry => '再試行';

  @override
  String get publicProfileLikedEmpty => 'いいねした作品はまだありません';

  @override
  String get profileTabDramas => 'ショートドラマ';

  @override
  String get profileTabWorks => '作品';

  @override
  String get profileTabActorIp => 'キャラクターIP';

  @override
  String dramaUnlockConfirmLabel(String price, String currency) {
    return '$price $currencyで解除';
  }

  @override
  String dramaAllEpisodes(int count) {
    return '$countエピソード';
  }

  @override
  String dramaAllEpisodesFull(Object count) {
    return '全$countエピソード';
  }

  @override
  String get dramaLoading => '注目ドラマを読み込み中...';

  @override
  String get dramaEmpty => 'ショートドラマはありません';

  @override
  String get dramaRefresh => '更新';

  @override
  String get navTheater => 'シアター';

  @override
  String get navHome => 'ホーム';

  @override
  String get theaterTabShortDrama => 'ドラマ';

  @override
  String get theaterTabRecommend => 'おすすめ';

  @override
  String get playerWatchFullDrama => 'フル短編を視聴';

  @override
  String get playerStoryPerHourUnit => 'STORY/h';

  @override
  String get navNft => 'IPマーケット';

  @override
  String get navNftIp => 'キャラクターIP';

  @override
  String watchFullDramaEpisodes(int count) {
    return 'ドラマを見る · 全$count話';
  }

  @override
  String get navCreate => '作成';

  @override
  String get navProfile => 'マイページ';

  @override
  String get navMy => 'マネージャー';

  @override
  String get aboutTitle => '私たちについて';

  @override
  String get aboutVision => 'AI・Web3・プロトコル';

  @override
  String get aboutVisionDesc => '3つの力が原動力となり、物語を「受動的な体験」から「能動的な創造」へと変える';

  @override
  String get aboutAiDesc => 'あなたのアイデアが、自動的に物語になる';

  @override
  String get aboutWeb3Desc => 'あなたの作品は、いつまでもあなただけのものです';

  @override
  String get aboutProtocolDesc => 'あなたの物語は、いつまでも続いていきます';

  @override
  String get aboutIdentityTitle => 'あなたの語り手としての立場';

  @override
  String get aboutIdentityDesc => 'あなた自身、まさに展開しつつある物語の世界そのものなのです';

  @override
  String get aboutIdentityCreator => 'クリエイター';

  @override
  String get aboutIdentityCreatorDesc => '自らの物語を自ら紡ぐ';

  @override
  String get aboutIdentityWitness => '証人';

  @override
  String get aboutIdentityWitnessDesc => '他者の物語に参加し、それを検証する';

  @override
  String get aboutIdentityCoCreator => '共同クリエイター';

  @override
  String get aboutIdentityCoCreatorDesc => '物語の構造に入り、書き直す';

  @override
  String get aboutIdentitySpreader => '拡散者';

  @override
  String get aboutIdentitySpreaderDesc => 'あなたにふさわしい物語を広めよう';

  @override
  String get aboutTokenomicsTitle => 'STORY：ストーリーテリング権トークン';

  @override
  String get aboutTokenomicsDesc => 'AI短劇の共同プロデューサーになり、映像業界の利益分配を再構築します。';

  @override
  String get aboutTokenomicsGov => 'ガバナンス';

  @override
  String get aboutTokenomicsGovDesc => '投票で次回のAI短編ドラマのテーマと展開を決定しましょう';

  @override
  String get aboutTokenomicsRevenue => '収益';

  @override
  String get aboutTokenomicsRevenueDesc =>
      'シェアプラットフォームの購読、著作権ライセンス、および関連グッズ販売による収益';

  @override
  String get aboutTokenomicsAccess => 'アクセス権';

  @override
  String get aboutTokenomicsAccessDesc => '最新エピソードをいち早く視聴し、限定コンテンツをアンロック';

  @override
  String get aboutStakingTitle => '担保による利益分配';

  @override
  String get aboutStakingDesc => 'ドラマNFT · キャラクターNFT · STORY → ステークで配当を獲得';

  @override
  String get aboutStakingDrama => 'ドラマNFTステーキング';

  @override
  String get aboutStakingDramaDesc => 'ショートドラマクリエイター・収益分配を受け取る';

  @override
  String get aboutStakingActor => 'キャラクターNFTステーキング';

  @override
  String get aboutStakingActorDesc => 'ロールがショートドラマに出演・収益分配を受け取る';

  @override
  String get aboutStakingStory => 'STORYステーキング';

  @override
  String get aboutStakingStoryDesc => 'ショートドラマへの投稿・収益分配';

  @override
  String get aboutHeroTitle => 'あなただけの物語を創造する';

  @override
  String get aboutHeroDesc => 'あなたの人生は体験される脚本ではなく、あなたが書いている物語です';

  @override
  String get loginTitle => 'メールアドレスでログイン';

  @override
  String get loginSubtitle => 'PrivyメールOTPでログインし、Solana組み込みウォレットを自動作成します。';

  @override
  String get loginPlaceholder => 'メールアドレスを入力してください';

  @override
  String get loginEmailHintFormat => 'メールアドレスを入力';

  @override
  String get loginVerificationFailed => '認証に失敗しました';

  @override
  String get loginNeedCodeFirst => '先に認証コードを取得してください';

  @override
  String get loginCreateWalletFailed => 'ウォレットの作成に失敗しました';

  @override
  String get loginGetTokenFailed => 'アクセストークンの取得に失敗しました';

  @override
  String get loginPrivyUnavailable => 'ログインサービスを利用できません。アプリを再起動してからお試しください';

  @override
  String get loginSendCodeFailed => '認証コードの送信に失敗しました。しばらくしてからもう一度お試しください';

  @override
  String get loginTooManyRequests => 'リクエストが多すぎます。しばらくしてからもう一度お試しください';

  @override
  String get loginVerificationSuccessful => '認証に成功しました';

  @override
  String get loginSendCode => 'コードを取得';

  @override
  String get loginSendingCode => '送信中...';

  @override
  String get loginCodePlaceholder => '6桁の認証コードを入力してください';

  @override
  String get loginSubmit => 'ログイン';

  @override
  String get loginSubmitting => 'ログイン中...';

  @override
  String get loginEmailRequired => 'メールアドレスを入力してください';

  @override
  String get loginCodeRequired => '認証コードを入力してください';

  @override
  String get loginSuccess => 'ログイン成功';

  @override
  String get loginErrorPrefix => 'ログインエラー: ';

  @override
  String loginCodeSent(String email) {
    return '認証コードが$emailに送信されました';
  }

  @override
  String get loginEmailLabel => 'メールアドレス';

  @override
  String get loginCodeLabel => '認証コード';

  @override
  String get loginVerifying => '認証中です。しばらくお待ちください...';

  @override
  String get loginVerifyAndSubmit => '認証してログイン';

  @override
  String get loginChangeEmail => 'メールアドレスを変更';

  @override
  String get loginNotNow => '今はしない';

  @override
  String get loginInvalidEmail => '有効なメールアドレスを入力してください';

  @override
  String get profileTitle => 'エージェント';

  @override
  String get profileNotLoggedIn => '未ログイン';

  @override
  String get profileClickLogin => 'ログイン / 新規登録';

  @override
  String get profileMyWallet => 'マイウォレット';

  @override
  String get profileWallet => 'ウォレット';

  @override
  String get profileTradeStory => 'STORYを取引';

  @override
  String get profileWalletCreating => '作成中...';

  @override
  String get walletNetworkSolana => 'Solana';

  @override
  String get walletNetworkEvm => 'EVM';

  @override
  String get profileEarnings => '収益';

  @override
  String get profileMyNft => 'マイNFT';

  @override
  String get profileMyFavorites => 'お気に入り';

  @override
  String get profileWatchHistory => '視聴履歴';

  @override
  String get profileCreatorCatalog => 'クリエイター';

  @override
  String get profileIdentityAuth => '本人確認';

  @override
  String get profileAccountSecurity => 'アカウントセキュリティ';

  @override
  String get profileLanguage => '言語';

  @override
  String get profileAboutUs => '私たちについて';

  @override
  String get profileHelpFeedback => 'ヘルプとフィードバック';

  @override
  String get profileLogout => 'ログアウト';

  @override
  String get profileLogoutConfirm => 'ログアウトしてもよろしいですか？';

  @override
  String get profileLogoutSuccess => 'ログアウトしました';

  @override
  String get mainPressBackAgainToExit => 'もう一度戻るボタンを押すと終了します';

  @override
  String get languageSelectTitle => '言語を選択';

  @override
  String get languageChinese => '簡体字中国語';

  @override
  String get languageEnglish => '英語';

  @override
  String get searchTitle => '検索';

  @override
  String get searchHint => '短編ドラマ、作品、ロール、ユーザーを検索...';

  @override
  String get searchEmpty => '関連コンテンツがありません';

  @override
  String get searchNoData => '関連コンテンツがありません';

  @override
  String get searchPlaceholder => '短編ドラマ、作品、ロール、ユーザーを検索...';

  @override
  String get theaterSearchPlaceholder => '短編ドラマ、作品、ロール、ユーザーを検索...';

  @override
  String get searchHistory => '最近の検索';

  @override
  String get searchClear => '履歴をクリア';

  @override
  String get searchAction => '検索';

  @override
  String get searchHistoryCleared => '検索履歴をクリアしました';

  @override
  String get searchKeywordTooShort => '2文字以上入力してください';

  @override
  String get searchTabDramas => '短編ドラマ';

  @override
  String get searchTabWorks => '作品';

  @override
  String get searchTabActors => 'キャラクター IP';

  @override
  String get searchTabUsers => 'ユーザー';

  @override
  String searchEpisodeNo(int episodeNo) {
    return '第$episodeNo話';
  }

  @override
  String searchMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String searchHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String searchDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String searchDramasCount(int count) {
    return 'ドラマ ($count)';
  }

  @override
  String searchActorsCount(int count) {
    return 'ロール ($count)';
  }

  @override
  String searchDramaEpisodesWithCast(int count, String actors) {
    return '全$count話 | 出演：$actors';
  }

  @override
  String get nftTitle => 'NFTロール広場';

  @override
  String get nftLoading => 'キャラクターIPを読み込み中...';

  @override
  String get nftEmpty => 'キャラクターIPがありません';

  @override
  String get nftRefresh => '更新';

  @override
  String nftIdPrefix(String id) {
    return 'ID: #$id';
  }

  @override
  String get nftRarity => 'レアリティ';

  @override
  String get nftStatusStaked => '担保に供されている';

  @override
  String get nftStatusIdle => 'アイドル';

  @override
  String get nftPrice => '価格';

  @override
  String get dramaDetailTitle => 'ドラマ詳細';

  @override
  String get dramaDetailLoading => '読み込み中…';

  @override
  String get dramaDetailRetry => '再試行';

  @override
  String get dramaDetailEpisodeList => '番組一覧';

  @override
  String get dramaDetailSynopsis => 'あらすじ';

  @override
  String get dramaDetailExpand => '展開';

  @override
  String get dramaDetailCollapse => '閉じる';

  @override
  String get dramaDetailTabIntro => '概要';

  @override
  String get dramaDetailTabEpisodes => '選集';

  @override
  String get dramaDetailTabComments => 'コメント';

  @override
  String get dramaDetailTabRoles => 'キャラクターIP';

  @override
  String get dramaDetailSignMoreCharacterIps => 'さらにキャラクターIPを契約する';

  @override
  String get dramaDetailCharactersEmpty => 'まだキャラクターIPが紐付けられていません';

  @override
  String dramaDetailRoleSalary(String amount) {
    return 'ギャラ $amount';
  }

  @override
  String dramaDetailRoleSalaryPerHour(String amount) {
    return 'ギャラ$amount STORY/h';
  }

  @override
  String get dramaDetailRoleUnbound => '未契約';

  @override
  String get dramaCastActorsTitle => '出演キャラクターIP';

  @override
  String dramaDetailCompletion(String count) {
    return '$count 完視聴';
  }

  @override
  String dramaDetailHeat(String count) {
    return '$count ヒート';
  }

  @override
  String dramaDetailTotalEpisodes(int count) {
    return '$count 話';
  }

  @override
  String get dramaDetailRatingTitle => '作品に評価をつける';

  @override
  String get dramaDetailWantToRate => '評価する';

  @override
  String get dramaDetailNotRated => '未評価';

  @override
  String get dramaDetailCompletionLabel => '完視聴';

  @override
  String get dramaDetailHeatLabel => 'ヒート';

  @override
  String get dramaDetailSynopsisLead => 'あらすじ：';

  @override
  String get dramaDetailRatingEmpty => 'あなたの評価: --';

  @override
  String dramaDetailRatingValue(int rating) {
    return 'あなたの評価: $rating';
  }

  @override
  String get dramaDetailRatingConfirm => '評価を確定';

  @override
  String dramaDetailRatingSuccess(int rating) {
    return '評価成功: $ratingスター！';
  }

  @override
  String get dramaDetailSelectEpisodeHint => 'エピソードを選択して再生を開始';

  @override
  String get dramaFavorited => 'お気に入りに追加';

  @override
  String get dramaUnfavorited => 'お気に入りから削除';

  @override
  String get dramaLiked => 'いいね！';

  @override
  String get dramaUnliked => 'いいね！取消';

  @override
  String get playerFollowed => 'フォローしました';

  @override
  String get playerUnfollowed => 'フォローを解除しました';

  @override
  String get errorNetwork => 'ネットワークエラー、しばらくしてからもう一度お試しください';

  @override
  String get errorTimeout => 'リクエストがタイムアウトしました、もう一度お試しください';

  @override
  String get errorParse => 'レスポンスデータの解析に失敗しました';

  @override
  String get errorUnauthorized => 'まずログインしてください';

  @override
  String get authSessionExpired => 'ログインの有効期限が切れました。再度ログインしてください';

  @override
  String get errorNotFound => 'リソースが存在しません';

  @override
  String get iapOrderInFlight => 'この商品には未完了の注文があります。後でもう一度お試しください';

  @override
  String get errorOperationFailed => '操作に失敗しました';

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
  String get errorInvalidRoleId => 'キャラクターIDが無効です。ページを更新して、もう一度お試しください。';

  @override
  String get errorInvalidRoleNftAssetId =>
      'キャラクターNFTのassetIdが無効です。ページを更新して、もう一度お試しください。';

  @override
  String get errorInvalidRoleCollectionAssetId =>
      'キャラクターコレクションのassetIdが無効です。ページを更新して、もう一度お試しください。';

  @override
  String get roleNftLabelUnknown => 'RoleNFT#Unknown';

  @override
  String roleNftLabel(String prefix) {
    return 'RoleNFT#$prefix';
  }

  @override
  String errorBusiness(String message) {
    return '操作失敗: $message';
  }

  @override
  String errorUnknown(String message) {
    return '不明なエラーが発生しました: $message';
  }

  @override
  String errorNotSupported(String message) {
    return 'サポートされていない操作です: $message';
  }

  @override
  String get playerEpisodeSelect => '選集';

  @override
  String get playerPlayFailed => '再生に失敗しました';

  @override
  String get playerDramaUnavailable => 'この短編ドラマは再生できません';

  @override
  String get playerContentUnavailable => 'このコンテンツは未公開、または公開が終了しています';

  @override
  String get creatorWorkNotFound => '作品が存在しないため、閲覧できません';

  @override
  String get creatorWorkNotPublished => '作品は未公開のため、現在閲覧できません';

  @override
  String get creatorOfflineReasonUnavailable => '公開停止の理由はありません';

  @override
  String get playerTapRetry => 'タップして再試行';

  @override
  String playerEpisodeTotal(int count) {
    return '全$count話';
  }

  @override
  String playerEpisodeLabel(int episodeNo) {
    return '第$episodeNo話';
  }

  @override
  String get playerLike => '「いいね」';

  @override
  String get playerComment => 'コメント';

  @override
  String get playerFavorite => 'お気に入り';

  @override
  String get playerShare => 'シェア';

  @override
  String playerShareDramaEpisode(
    String title,
    int episodeNo,
    String description,
    String url,
  ) {
    return '$title | 第$episodeNo話：$description $url 。StoryFunで素敵なAI短編ドラマを観よう。';
  }

  @override
  String playerShareDramaEpisodeNoDesc(
    String title,
    int episodeNo,
    String url,
  ) {
    return '$title | 第$episodeNo話 $url 。StoryFunで素敵なAI短編ドラマを観よう。';
  }

  @override
  String playerShareShortVideo(String description, String url) {
    return '$description $url。StoryFunで素敵なショート動画を観よう。';
  }

  @override
  String playerShareShortVideoNoDesc(String url) {
    return '$url。StoryFunで素敵なショート動画を観よう。';
  }

  @override
  String playerShareDrama(String title, String url) {
    return '$title $url 。StoryFunで素敵なAI短編ドラマを観よう。';
  }

  @override
  String playerShareDramaNoTitle(String url) {
    return '$url 。StoryFunで素敵なAI短編ドラマを観よう。';
  }

  @override
  String playerRatingLabel(String rating) {
    return '$rating ポイント';
  }

  @override
  String get loginOrSignUp => 'ログインまたは新規登録';

  @override
  String get loginEnterCode => '確認コードを入力';

  @override
  String loginCheckEmailDesc(String email) {
    return '$emailに送信されたprivy.ioからのメールを確認し、以下にコードを入力してください。';
  }

  @override
  String loginResendCountdown(int seconds) {
    return 'コード再送まで $seconds秒';
  }

  @override
  String get loginResendBtn => '再送信';

  @override
  String get loginProtectedByPrivy => 'Privyで保護されています';

  @override
  String get loginAgreeLead => '同意します';

  @override
  String get loginAgreeAnd => 'および';

  @override
  String get loginAgreeConfirmLead => '確定をタップすると、次に同意したことになります';

  @override
  String get loginAgreeRequired => '先に利用規約とプライバシーポリシーに同意してください';

  @override
  String get deletingAccountPending => 'アカウント削除待ち';

  @override
  String get deletingAccountCancelDeletion => 'アカウント削除を取り消す';

  @override
  String get deletingAccountGoBack => '戻る';

  @override
  String get drawerEmailAccount => 'メールアカウント';

  @override
  String get drawerClickToLogin => 'タップしてログイン';

  @override
  String get drawerBuyStory => 'STORYを取引';

  @override
  String get drawerDeposit => 'チャージ';

  @override
  String get drawerWithdraw => '出金';

  @override
  String get drawerNotifications => '通知';

  @override
  String get drawerNoNotifications => '通知はありません';

  @override
  String get notificationTabSystem => 'システム';

  @override
  String get notificationTabInteraction => 'アクティビティ';

  @override
  String get notificationTagIpSign => 'キャラクターIP契約';

  @override
  String get notificationTagRoleManagement => 'キャラクター管理';

  @override
  String get notificationTagShowRevenue => '公演収益';

  @override
  String get notificationTagLike => 'いいね';

  @override
  String get notificationTagFavorite => 'お気に入り';

  @override
  String notificationSignedActor(String user, String actor) {
    return '@$user がキャラクターIP $actor と契約しました';
  }

  @override
  String notificationShareEarned(String amount) {
    return '分配金 $amountを獲得しました';
  }

  @override
  String notificationStaminaLow(String actor) {
    return '\'$actorの体力が不足しています。補充するか休ませてください\'';
  }

  @override
  String notificationCurrentStamina(String value) {
    return '現在の体力 $value';
  }

  @override
  String notificationShowEnded(String range) {
    return '$rangeの公演が終了しました';
  }

  @override
  String notificationIncomeEarned(String amount) {
    return '収益 $amountを獲得しました';
  }

  @override
  String get notificationActionClaim => '受取';

  @override
  String get notificationActionRefill => '補充';

  @override
  String get notificationInteractionLikedVideo => 'あなたの動画にいいねしました';

  @override
  String notificationInteractionLikedDrama(String title) {
    return '短編ドラマ「$title」にいいねしました';
  }

  @override
  String get notificationInteractionFavoritedVideo => 'あなたの動画を保存しました';

  @override
  String notificationInteractionFavoritedDrama(String title) {
    return '短編ドラマ「$title」を保存しました';
  }

  @override
  String notificationInteractionCommented(String content) {
    return 'コメントしました：$content';
  }

  @override
  String get notificationInteractionFollowedYou => 'あなたをフォローしました';

  @override
  String get notificationActionMutualFollow => '相互';

  @override
  String get notificationActionFollow => 'フォロー';

  @override
  String get notificationDelete => '削除';

  @override
  String get notificationDeleteFailed => '削除できませんでした。しばらくしてからもう一度お試しください';

  @override
  String get notificationRealtimeReceived => '新しい通知が届きました';

  @override
  String drawerEpisodeProgress(int current, int total) {
    return '$current/$total話';
  }

  @override
  String drawerNotificationSignedActor(String actor, String target) {
    return '$actor がキャラクターIP $target と契約しました';
  }

  @override
  String drawerNotificationLikedVideo(String actor) {
    return '$actorがあなたの動画にいいねしました';
  }

  @override
  String drawerNotificationFavoritedDrama(String actor, String target) {
    return '$actorが短編ドラマ $targetを保存しました';
  }

  @override
  String get depositTitle => 'チャージ';

  @override
  String get insufficientBalanceTitle => '残高不足';

  @override
  String insufficientBalanceDetail(String currency, String amount) {
    return '$currency残高が不足しています。あと $amount $currency 必要です';
  }

  @override
  String get insufficientBalancePrompt => 'チャージに移動しますか？';

  @override
  String get insufficientBalanceRecharge => 'チャージへ';

  @override
  String get depositDesc =>
      '取引所や他のウォレットから以下のアドレスに送金してください。入金が確認されると残高は自動的に更新されます。';

  @override
  String get depositToken => '通貨';

  @override
  String get depositNetwork => 'ネットワーク';

  @override
  String get depositNetworkNote =>
      '転送ネットワークを確認してください。ネットワークを間違えると資産を失う可能性があります。';

  @override
  String get depositAddress => 'チャージ先アドレス';

  @override
  String get depositAddressCopied => 'アドレスがクリップボードにコピーされました';

  @override
  String get depositSend => '送信';

  @override
  String get depositReceive => '受取';

  @override
  String get depositConvertNote =>
      'このアドレスにトークンを送金すると、Story.funアカウントで自動的にUSDCに交換されます。';

  @override
  String depositMinNote(String minAmount, String token) {
    return '最低入金額：$minAmount $token';
  }

  @override
  String depositExchangeRateNote(String rate) {
    return '現在の為替レートは $rate です。着金額 = 入金額 × $rate';
  }

  @override
  String get depositWarning =>
      '選択したネットワーク上の選択トークンのみ入金してください。他の資産は復元できません。\n送金ネットワークを確認してください。ネットワークエラーにより資産が失われる可能性があります。';

  @override
  String get withdrawTitle => '出金';

  @override
  String get withdrawBalance => '出金可能残高';

  @override
  String get withdrawToken => '通貨';

  @override
  String get withdrawAddress => '出金先';

  @override
  String get withdrawAddressHint => 'Solana受取アドレスを入力または貼り付けてください';

  @override
  String get withdrawAddressHintEvm => 'EVM受取アドレスを入力または貼り付けてください';

  @override
  String get withdrawInvalidEvmAddress => '有効なEVMアドレスを入力してください';

  @override
  String get withdrawInvalidSolanaAddress => '有効なSolanaアドレスを入力してください';

  @override
  String get withdrawEvmGasNote =>
      'EVM出金にはガス代用のネイティブトークンが必要です。取引はチェーン上で直接送信されます。';

  @override
  String get withdrawEvmFailed => 'EVM出金に失敗しました。しばらくしてから再試行してください。';

  @override
  String get withdrawAddressNote => '住所が正しいかご確認ください。振込後の取り消しはできません。';

  @override
  String get withdrawNetwork => 'ネットワーク';

  @override
  String get withdrawAmount => '金額';

  @override
  String get withdrawAmountHint => '出金額を入力してください';

  @override
  String get withdrawMax => '最大';

  @override
  String withdrawAvailableBalance(String balance, String token) {
    return '残高 $balance $token';
  }

  @override
  String withdrawMinWarning(String minAmount, String token) {
    return '最低出金額: $minAmount $token\nアドレスとネットワークを慎重に確認してください。取引は取り消せません。';
  }

  @override
  String get withdrawConfirm => '出金を確定する';

  @override
  String get withdrawAll => 'すべて';

  @override
  String withdrawMinAmountError(String minAmt, String token) {
    return '最低出金額は $minAmt $token です';
  }

  @override
  String get withdrawExceedBalanceError => '出金額は利用可能残高を exceeded できません';

  @override
  String get withdrawSameAsWalletError => '出金先アドレスは現在のウォレットアドレスと同じにできません';

  @override
  String get withdrawConfirmTitle => '出金を確定する';

  @override
  String withdrawConfirmMessage(String amount, String token, String address) {
    return '以下のSolanaアドレスに $amount $token を出金してもよろしいですか？\n\n$address';
  }

  @override
  String get withdrawSuccessToast => '出金リクエストが正常に送信されました！';

  @override
  String get withdrawFailedToast => '出金に失敗しました。もう一度お試しください。';

  @override
  String withdrawErrorToast(String error) {
    return '出金中にエラーが発生しました: $error';
  }

  @override
  String withdrawAddressHintWithToken(String token) {
    return '$token を受け取るウォレットアドレスを入力してください';
  }

  @override
  String get withdrawFee => '手数料';

  @override
  String withdrawFeeValue(String fee, String token) {
    return '$fee $token';
  }

  @override
  String withdrawMinAmount(String minAmount, String token) {
    return '最低出金額: $minAmount $token';
  }

  @override
  String withdrawMaxAmount(String maxAmount, String token) {
    return '最大出金額: $maxAmount $token';
  }

  @override
  String get withdrawSponsorSigning => 'トランザクション署名中...';

  @override
  String get withdrawSponsorSubmitting => 'オンチェーントランザクション送信中...';

  @override
  String get withdrawSponsorSuccess => '出金が正常に送信されました！';

  @override
  String get withdrawSponsorFailed => 'トランザクション送信に失敗しました。もう一度お試しください。';

  @override
  String get withdrawOrderProcessing => '注文処理中';

  @override
  String get withdrawOrderSuccess => '注文完了';

  @override
  String get withdrawOrderFailed => '注文失敗';

  @override
  String withdrawOrderStatus(String status) {
    return '注文状態: $status';
  }

  @override
  String get qrScannerTitle => 'QRコードスキャン';

  @override
  String get qrScannerHint => 'QRコードをフレーム内に合わせてスキャン';

  @override
  String get drawerProfile => 'マイページ';

  @override
  String get drawerCreatorManagement => 'クリエイター管理';

  @override
  String get drawerInvite => '招待';

  @override
  String get inviteTitle => '友達を招待';

  @override
  String get inviteTotalPeople => '累計招待者数';

  @override
  String get inviteTotalRewards => '招待報酬合計';

  @override
  String get inviteWeeklyPool => '今週の招待報酬プール';

  @override
  String get inviteViewHistory => '収益履歴を確認する';

  @override
  String get inviteShareSection => '専用の招待リンクまたは招待コードを共有';

  @override
  String get inviteLinkSection => '招待リンク';

  @override
  String get inviteLinkSubtitle =>
      '友達があなたのリンクから登録し、キャラクターを契約して派遣すると、追加の STORY 報酬を獲得できます。';

  @override
  String get inviteCodeLabel => '招待コード';

  @override
  String get inviteCopyButton => 'リンクをコピー';

  @override
  String get inviteCopiedSuccess => '招待リンクがクリップボードにコピーされました！';

  @override
  String get inviteCodeCopiedSuccess => '招待コードをクリップボードにコピーしました！';

  @override
  String get inviteInvitedLabel => '招待済み';

  @override
  String get inviteRewardLabel => '報酬';

  @override
  String get inviteBindCode => '招待コードをバインド';

  @override
  String get inviteBindCodePromptHint => 'スキップ後は招待ページでバインドできます';

  @override
  String get inviteBindCodePlaceholder => '招待コードを入力';

  @override
  String get inviteBindConfirm => '確定';

  @override
  String get inviteBindSuccess => '招待コードのバインドに成功しました';

  @override
  String get inviteBindCodeInvalid => '招待コードが無効です';

  @override
  String get inviteBindCodeAlreadyBound => 'このアカウントは既に招待コードを連携済みです';

  @override
  String get inviteRulesSection => '招待ルール';

  @override
  String get inviteFaqPoolTitle => '毎週の招待報酬プールとは？';

  @override
  String get inviteFaqPoolBody =>
      '毎週の招待報酬プールは、招待キャンペーンのために設けられた独立した報酬プールです。当週の招待行為に対して報酬が付与され、被招待者の収益から差し引かれることはありません。プールには週次の配布上限があり、上限到達後は持ち分に応じて按分縮小されます。統計は毎週月曜にリセットされます。';

  @override
  String get inviteFaqSettlementTitle => '招待報酬はいつ清算されますか？';

  @override
  String get inviteFaqSettlementBody =>
      '招待報酬はエージェントページのギャラと同じ周期で一括清算されます。毎週月曜 00:00 (UTC) に集計が締め切られ、清算後は収益ページで受け取れます。';

  @override
  String get inviteRuleSourceTitle => '報奨金の出所';

  @override
  String get inviteRuleSourceSubtitle => '独立したサブプールへの招待';

  @override
  String get inviteRuleSourceBody =>
      '紹介報酬は、NFTマイニングプール内の独立した紹介サブプール（マイニングプール全体の25％を占める）から支払われ、紹介されたユーザーの収益から差し引かれることはありません。紹介サブプールには独立した週間上限が設定されており、上限に達した後は、保有割合に応じて比例的に削減されます。';

  @override
  String get inviteRuleBaseTitle => '計算基数';

  @override
  String get inviteRuleBaseSubtitle => '実体験に基づく STORY';

  @override
  String get inviteRuleBaseBody =>
      '報酬は、招待されたユーザーが当期間に実際に受け取ったSTORYに基づいて計算され、名目上の生産量に基づいて計算されるものではありません。招待されたユーザーが自らマイニングしたSTORYには影響がなく、招待報酬は別途支給されます。';

  @override
  String get inviteRuleLevelTitle => '報酬の範囲';

  @override
  String get inviteRuleLevelSubtitle => '直接招待のみ';

  @override
  String get inviteRuleLevelBody =>
      '招待報酬は、あなたが直接招待したユーザーに対してのみ支払われます。多段階・間接的なコミッションはありません。';

  @override
  String get inviteRuleConditionTitle => '有効条件';

  @override
  String get inviteRuleConditionSubtitle => 'アクティブなダウンラインがあって初めて報酬が発生します';

  @override
  String inviteRuleConditionBody(String currency) {
    return '招待されたユーザーが実際にSTORYをマイニングした、または$currencyでの支払いを行った場合にのみ、有効なダウンラインとしてカウントされます。無効なアカウントでの登録では報酬は発生しません。招待関係は一度確立されると変更できません。';
  }

  @override
  String get drawerTxHistory => '取引履歴';

  @override
  String get drawerFinanceDashboard => '資金ダッシュボード';

  @override
  String get financeDashboardComingSoon => '資金ダッシュボードは近日公開予定です。お楽しみに。';

  @override
  String get financeDashboardPageTitle => 'プラットフォーム資金ダッシュボード';

  @override
  String financeDashboardTotalUsdcIncome(String currency) {
    return 'USDC総収入';
  }

  @override
  String get financeDashboardTotalStoryReleased => 'STORY総リリース量';

  @override
  String financeDashboardTabUsdcIncome(String currency) {
    return 'USDC収入明細';
  }

  @override
  String get financeDashboardTabVaultFunds => '金庫資金の蓄積';

  @override
  String get financeDashboardTabStoryRelease => 'STORYリリース概要';

  @override
  String get financeDashboardFeeMint => '契約料';

  @override
  String get financeDashboardFeeRoyalty => '二次流通ロイヤリティ';

  @override
  String get financeDashboardFeeItemPurchase => 'アイテム購入';

  @override
  String get financeDashboardFeeTx => '取引手数料';

  @override
  String get financeDashboardLedgerBizSigningFee => '契約手数料';

  @override
  String get financeDashboardLedgerBizManualCredit => '手動入金';

  @override
  String get financeDashboardLedgerBizManualDebit => '手動減額';

  @override
  String get financeDashboardLedgerBizStaminaPurchase => '体力購入料';

  @override
  String get financeDashboardLedgerBizSynthesisUpgrade => '合成アップグレード料';

  @override
  String get financeDashboardLedgerBizTransactionFee => '取引手数料';

  @override
  String financeDashboardRecentUsdcLedger(String currency) {
    return '最近のUSDC収入';
  }

  @override
  String get financeDashboardViewMore => 'もっと見る';

  @override
  String get financeDashboardTotalVaultFunds => '金庫資金総額';

  @override
  String get financeDashboardCoveredActorIp => '対象キャラクターIP';

  @override
  String get financeDashboardActorVaultRanking => 'キャラクターIP金庫ランキング';

  @override
  String get storyReleaseTabAllocation => 'STORY総量配分';

  @override
  String get storyReleaseTabMiningRelease => '最近のマイニングリリース';

  @override
  String get storyReleaseFieldPeriod => '期間';

  @override
  String get storyReleaseFieldHardLimit => '週間ハードキャップ';

  @override
  String get storyReleaseFieldMiningRewards => 'ステーキングマイニング';

  @override
  String get storyReleaseFieldInviteRewards => '招待マイニング';

  @override
  String get storyReleaseFieldUsageRate => '使用率';

  @override
  String get storyReleaseFieldTarget => '割当先';

  @override
  String get storyReleaseFieldRatio => '比率';

  @override
  String get storyReleaseFieldAmount => '数量';

  @override
  String get storyReleaseFieldReleased => 'リリース済み';

  @override
  String get storyReleaseFieldProgress => 'リリース進捗';

  @override
  String get storyReleaseCategoryNftMiningPool => 'NFTマイニングプール';

  @override
  String get storyReleaseCategoryTeam => 'チーム';

  @override
  String get storyReleaseCategoryInvestors => '投資家';

  @override
  String get storyReleaseCategoryLiquidity => 'Launchpad + 流動性';

  @override
  String get storyReleaseCategoryTreasury => 'トレジャリー';

  @override
  String get storyReleaseCategoryMarketOps => '市場運営';

  @override
  String storyReleaseTotalSupplyBadge(String total) {
    return '総量 $total STORY';
  }

  @override
  String get drawerWhitepaper => '白書';

  @override
  String get drawerSettings => '設定';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonDelete => '削除';

  @override
  String get commonLoadFailed => '読み込みに失敗しました';

  @override
  String get commonNone => 'なし';

  @override
  String get commonUntitled => '無題';

  @override
  String get actorDetailTitle => '俳優ホーム';

  @override
  String get actorDetailCastDramas => '短編ドラマへの出演';

  @override
  String get actorDetailTabCast => '出演';

  @override
  String get actorDetailTabInfo => '情報';

  @override
  String get actorDetailNoCastRecords => '出演記録がありません';

  @override
  String get actorBondingCurve => '価格の結合曲線';

  @override
  String get actorContractAddress => '契約アドレス';

  @override
  String get actorCurrentPosition => '現在位置';

  @override
  String actorCurrentPrice(String price, String currency) {
    return '現在の価格 $price $currency';
  }

  @override
  String get actorFloorPrice => '最低価格';

  @override
  String get actorGoTrade => '取引する';

  @override
  String get profileWalletTrade => '取引する';

  @override
  String get actorHeatCoefficient => 'ヒート係数';

  @override
  String get actorIpPower => 'IPギャラ';

  @override
  String get actorPayMax => '最大';

  @override
  String get actorPayUpgradeTitle => 'ギャラアップのルール';

  @override
  String get actorPayUpgradeReachHint =>
      'このIPが出演する短編ドラマの現在の完視聴数は、ロールを次のレベルまでアップグレードできます';

  @override
  String actorPayUpgradeCompletions(String count) {
    return '$count 完視聴';
  }

  @override
  String actorPayUpgradeMultiplier(String value) {
    return 'ギャラ ×$value';
  }

  @override
  String actorPayTitle(String name) {
    return '$name · ギャラ';
  }

  @override
  String get actorLv1PayHint => '契約するとLv.1のキャラクターを獲得できます';

  @override
  String get actorLv1PayFormula => 'Lv.1ギャラ = 価格係数 × ヒート係数';

  @override
  String actorLv1PayEquals(String value) {
    return '=$value';
  }

  @override
  String actorIpPowerTitle(String name) {
    return '$name · IPギャラ';
  }

  @override
  String get actorIpPowerFormula => 'IPギャラ = 価格係数 × ヒート係数 × Trust1';

  @override
  String get actorPriceCoefficient => '価格係数';

  @override
  String actorPriceCoefficientValue(String value) {
    return '価格係数 $value';
  }

  @override
  String get actorPriceCoefficientHelpA11y => '価格係数の説明を見る';

  @override
  String get actorPriceUnitName => 'ポイント';

  @override
  String get actorPriceCoefficientDialogFormulaLe100 => '係数 = P0 ÷ 10';

  @override
  String get actorPriceCoefficientDialogDescLe100 => '線形増加';

  @override
  String actorPriceCoefficientDialogTitleGt100(String currency) {
    return 'P0 > 10 $currency';
  }

  @override
  String get actorPriceCoefficientDialogFormulaGt100 =>
      '係数 = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]';

  @override
  String get actorPriceCoefficientDialogDescGt100 => '増加が緩やかになり、上限は 1.6';

  @override
  String actorPriceCoefficientDialogTitleLe100(String currency) {
    return 'P0 ≤ 10 $currency';
  }

  @override
  String actorPriceCoefficientFactorDesc(String currency1, String currency2) {
    return 'P0 ≤ 10 $currency1 係数= P0/10（線形増加）\nP0 > 10 $currency2 → 係数 = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]（漸近上限 1.6）';
  }

  @override
  String get actorHeatCoefficientFactorDesc =>
      'キャラクターIPの直近30日間のヒート乗数。ショートドラマの完視聴、いいね、お気に入りなどのインタラクションに基づきます';

  @override
  String get actorTrustFactorDesc => 'プラットフォームのリスク管理係数。デフォルトは1.0';

  @override
  String get actorStatCompletion => '完視聴';

  @override
  String get actorIdCopied => '番号がコピーされました';

  @override
  String actorInitialPrice(String price, String currency) {
    return '初期価格: $price $currency';
  }

  @override
  String actorIpLabel(String label) {
    return 'キャラクターIP $label';
  }

  @override
  String get actorIssueInfo => '発行情報';

  @override
  String actorIssuer(String name) {
    return '発行者 $name';
  }

  @override
  String actorMintedCount(int minted, int maxSupply) {
    return '鋳造済み $minted/$maxSupply';
  }

  @override
  String get actorPriceCurve => '価格曲線';

  @override
  String get actorSign => '契約する';

  @override
  String get actorConfirmSign => '契約を確認';

  @override
  String get actorSignPriceLabel => '契約価格';

  @override
  String get actorSignPriceDescription =>
      '契約数が増えるにつれて契約価格は自動的に上昇します。早期に契約するほどお得です。';

  @override
  String get actorSignPriceFormula => '計算式：価格 = 初期価格 × 5^(契約数 ÷ 総発行量)';

  @override
  String actorPriceAxisLabel(String currency) {
    return '価格（$currency）';
  }

  @override
  String get actorSignedCountAxisLabel => '契約数';

  @override
  String actorSignRemainingCount(int count) {
    return '残り$count個';
  }

  @override
  String get actorSignSoldOut => '完売しました';

  @override
  String actorSignSupplySummary(String total, String remaining) {
    return '総発行 $total · 残り $remaining';
  }

  @override
  String get actorPricingFixed => '固定価格';

  @override
  String get actorPricingCurve => '曲線価格';

  @override
  String get actorPriceCurveDisclaimer =>
      '初期価格はプラットフォームの評価額を反映するものではありません。曲線の上昇は二次市場での価格上昇を意味するものではなく、当プラットフォームは収益を保証するものではありません。';

  @override
  String get actorPriceStatInitialPrice => '初期価格';

  @override
  String get actorPriceStatCurrentPrice => '現在の価格';

  @override
  String get actorPriceStatTailPrice => '落札価格';

  @override
  String get actorPriceStatTotalSupply => '総発行量';

  @override
  String get actorPriceStatSigned => '契約済み';

  @override
  String get actorPriceStatRemaining => '残り';

  @override
  String get actorPricingType => '価格設定の種類';

  @override
  String get contentBadgeOfficialIssue => '公式発行';

  @override
  String get contentBadgeCommunityIssue => 'コミュニティ発行';

  @override
  String get contentBadgePartnerIssue => '提携先による発行';

  @override
  String get contentBadgeVerifiedIssue => '認定クリエイターによる発行';

  @override
  String get contentBadgeOfficialDrama => '公式ショートドラマ';

  @override
  String get contentBadgeCommunityDrama => 'コミュニティ短編ドラマ';

  @override
  String get contentBadgePartnerDrama => 'パートナー制作のショートドラマ';

  @override
  String get contentBadgeVerifiedDrama => '認定クリエイターによるショートドラマ';

  @override
  String get actorIpCopied => 'コピーに成功しました';

  @override
  String get actorRiskIp => 'リスクIP';

  @override
  String get actorRiskIpDescription => 'このキャラクターIPの信頼係数に異常があります。マイニング重みに影響します。';

  @override
  String get actorIpVault => 'キャラクターIP金庫';

  @override
  String get actorIpVaultDescription =>
      '契約収入の30%は自動的にキャラクターのIP金庫に積み立てられ、IPエコシステムの長期的な発展を支えます。セカンダリーマーケットのロイヤリティ収入の30%も同様に金庫に積み立てられ、持続的な資金プールとなります。V1バージョンの金庫ではデータ表示のみを提供し、現時点では分配は行われません。';

  @override
  String get actorIpVaultSignIncomePrefix => '契約収入・積立 ';

  @override
  String get actorIpVaultSecondaryRoyaltyPrefix => '二次ロイヤリティ・蓄積 ';

  @override
  String get actorFixedPriceDialogDesc =>
      'このキャラクターのIPは固定価格方式を採用しており、各キャラクターは一律の価格で契約され、販売数の変動は価格に影響しません。';

  @override
  String get actorCurvePriceDialogDesc =>
      '価格は結合曲線の公式に従い、契約数に応じて自動的に上昇します。早期に契約するほどお得です。';

  @override
  String get actorFixedPriceNote1 => '発行者が固定価格を設定した後、すべての契約はこの価格で決済されます。';

  @override
  String get actorFixedPriceNote2 => '契約数が増えても価格は上がりません。';

  @override
  String get actorFixedPriceNote3 => 'コストを抑えたい買い手に最適';

  @override
  String get actorIssueFixedPriceDesc =>
      'このキャラクターのIPは固定価格方式を採用しており、すべての契約は固定価格で精算され、販売数による変動はありません。';

  @override
  String get actorSignSlippageNote =>
      '1%のスリッページ保護が有効になっています。価格がこれを超えた場合、取引はキャンセルされます。';

  @override
  String get actorSignSuccessTitle => '契約成立！';

  @override
  String actorSignSuccessMessage(String name) {
    return 'キャラクター「$name」との契約が成立しました';
  }

  @override
  String actorSignSuccessNftId(String nftId) {
    return 'NFT ID：$nftId';
  }

  @override
  String get actorSignChainConfigMissing =>
      'オンチェーン設定が不完全です。しばらくしてからもう一度お試しください。';

  @override
  String get actorSignPriceSoldOut => '契約価格・完売';

  @override
  String actorSignPriceRemaining(int count) {
    return '契約価格・残り$count個';
  }

  @override
  String actorSignedCount(int count) {
    return '契約済み $count';
  }

  @override
  String get actorStatusLabelOffline => 'オフライン';

  @override
  String get actorStatusLabelOnline => 'オンライン';

  @override
  String get actorStatusLabelPending => '審査中';

  @override
  String get actorStatusLabelRejected => '却下';

  @override
  String get actorTotalSupply => '発行総量';

  @override
  String get commentsAnonymous => '匿名ユーザー';

  @override
  String get commentsEmpty => 'まだコメントがありません';

  @override
  String get commentsHint => '素晴らしいコメントを投稿...';

  @override
  String get commentsInvalidContent => '有効な内容を入力してください';

  @override
  String get commentsReply => '返信';

  @override
  String commentsViewReplies(int count) {
    return '$count件の返信を表示';
  }

  @override
  String get commentsCollapseReplies => '折りたたむ';

  @override
  String get commentsViewMoreReplies => 'さらに表示';

  @override
  String commentsReplyHint(String nickname) {
    return '$nickname に返信';
  }

  @override
  String get commentsDeleteCommentTitle => 'このコメントを削除しますか？';

  @override
  String get commentsDeleteReplyTitle => 'この返信を削除しますか？';

  @override
  String get commentTagAuthor => '作者';

  @override
  String get commentTagMe => '私';

  @override
  String get commentTagFriend => 'あなたの友達';

  @override
  String get commentTagFan => 'あなたのフォロワー';

  @override
  String get commentTagFirst => '初コメント';

  @override
  String get commentTagAuthorLiked => '作者がいいね';

  @override
  String commentsReplyTo(String nickname) {
    return '@$nickname に返信: ';
  }

  @override
  String get commentsReplyCommentNotExists => 'コメントが存在しません';

  @override
  String get commentsBlockedByMe => 'ブラックリスト登録済みのユーザーのため、コメントできません';

  @override
  String get commentsBlockedByTarget => '相手側の設定により、コメントできません';

  @override
  String get commentsTabComments => 'コメント';

  @override
  String get commentsTabAllComments => 'すべてのコメント';

  @override
  String get commentsTabDramas => 'ショートドラマ';

  @override
  String get commentsTabActors => 'キャラクター';

  @override
  String get timeJustNow => 'たった今';

  @override
  String get timeYesterday => '昨日';

  @override
  String get timeDayBeforeYesterday => '一昨日';

  @override
  String timeMinutesAgo(int count) {
    return '$count分前';
  }

  @override
  String timeHoursAgo(int count) {
    return '$count時間前';
  }

  @override
  String timeDaysAgo(int count) {
    return '$count日前';
  }

  @override
  String commentsTitle(int count) {
    return 'コメント ($count)';
  }

  @override
  String get createActorTitle => 'ロールを作成';

  @override
  String get createActorHeroTitle => 'キャラクターNFTを鋳造';

  @override
  String get createActorHeroSubtitle => '独占AIロールを作成し、収益分配を紐付けてドラマに参加';

  @override
  String get createActorNameLabel => 'ロール名';

  @override
  String get createActorNameHint => 'ロール名を入力';

  @override
  String get createActorBioLabel => 'ロールプロフィール';

  @override
  String get createActorBioHint => 'キャラクターの背景を説明';

  @override
  String get createActorGenderLabel => '性別';

  @override
  String get createActorGenderMale => '男性';

  @override
  String get createActorGenderFemale => '女性';

  @override
  String get createActorMintParams => 'NFT鋳造パラメータ';

  @override
  String get createActorTokenStandard => 'トークン規格';

  @override
  String get createActorChain => 'チェーン';

  @override
  String get createActorMinHolding => '最小保有量';

  @override
  String get createActorMintNft => 'NFTを鋳造';

  @override
  String get createActorIpTitle => 'キャラクターIPを発行';

  @override
  String get createActorIpSubtitle =>
      'キャラクターIPを発行した後、そのIPの下でキャラクターを契約でき、派遣して収益を得られます。';

  @override
  String get createActorSelectMaterial => 'ロールの素材を選択する';

  @override
  String get createActorDreamOsBadge => 'DreamOS へ';

  @override
  String get createActorSelectMaterialDesc =>
      'DreamOSプロジェクトに入る → キャラクターを作成 → Story.funでIPを発行';

  @override
  String get createActorSelectButton => 'ロールを選択';

  @override
  String get createActorNameLabelNew => 'ロール名';

  @override
  String get createActorNamePlaceholder => 'ロールの名前を入力してください';

  @override
  String get createActorBioLabelNew => '概要';

  @override
  String get createActorBioPlaceholder => 'キャラクターのIP紹介を入力してください';

  @override
  String get createActorParamsTitle => 'キャラクターIP発行パラメータ';

  @override
  String get createActorParamsSubtitle => 'キャラクターIPの発行パラメータを設定します。発行後は変更できません。';

  @override
  String get createActorTotalSupplyLabel => 'キャラクター総発行量';

  @override
  String get createActorTotalSupplyDesc => '発行総量の範囲：100 - 5,000。';

  @override
  String get createActorTotalSupplyPlaceholder => '100 - 5,000';

  @override
  String get createActorPricingFixed => '固定価格';

  @override
  String get createActorPricingCurve => '曲線価格';

  @override
  String createActorFixedPriceLabel(String currency) {
    return '固定価格（$currency）';
  }

  @override
  String createActorInitialPriceLabel(String currency) {
    return '初期価格（$currency）';
  }

  @override
  String get createActorFixedPricePlaceholder => '10 - 1,000';

  @override
  String get createActorFixedPriceDesc =>
      '各キャラクターは固定価格で購入され、販売数に応じて変動することはありません。';

  @override
  String get createActorInitialPricePlaceholder => '10 - 1,000';

  @override
  String get createActorInitialPriceDesc =>
      '初期価格は結合曲線の開始価格です。キャラクターを1体契約するごとに、価格は式 P = P₀ × 5^(契約数 ÷ 総発行量) に従って自動的に上昇します。早期に契約するほどお得になります。';

  @override
  String get createActorFormIncomplete =>
      'まずキャラクター素材、名前、プロフィール、発行パラメータを入力してください';

  @override
  String get createActorValidationNameRequired => 'ロール名を入力してください';

  @override
  String get createActorValidationNameTooLong => 'キャラクター名は20文字以下にしてください';

  @override
  String get createActorValidationBioRequired => 'プロフィールを入力してください';

  @override
  String get createActorValidationBioTooLong => 'プロフィールは500文字以下にしてください';

  @override
  String get createActorValidationTotalSupplyRequired => '有効なNFT発行総数を入力してください';

  @override
  String get createActorValidationTotalSupplyPositiveInteger =>
      'NFT発行総数は正の整数である必要があります';

  @override
  String get createActorValidationTotalSupplyRange =>
      'キャラクター総発行量は100〜5,000の間である必要があります';

  @override
  String get createActorValidationPriceRequired => '有効な鋳造価格を入力してください';

  @override
  String get createActorValidationPriceInvalid =>
      'Mint価格は10以上、1,000以下でなければなりません';

  @override
  String get createActorValidationPriceMaxDecimals => '鋳造価格は小数点以下2桁までです';

  @override
  String get createActorSelectMaterialRequired => 'キャラクター素材を選択してください';

  @override
  String get createActorCancelButton => 'キャンセル';

  @override
  String get createActorConfirmButton => '発行を確定';

  @override
  String get createActorIssueFee => '手数料';

  @override
  String createActorSuccessTitle(String name) {
    return '$name · 発行成功！';
  }

  @override
  String createActorSuccessDesc(String id) {
    return 'キャラクター IP $id';
  }

  @override
  String get createActorSuccessTip => '発行者も契約しないとこのキャラクターは獲得できません～';

  @override
  String get createActorCloseButton => '後で';

  @override
  String get createActorViewButton => '契約する';

  @override
  String get createActorEmptyTitle =>
      'DreamOSで条件を満たし、システムが自動生成したNFT発行をまだ作成していません。';

  @override
  String get createActorGotoDreamOs => 'DreamOS に移動して作成する';

  @override
  String get createActorSearchPlaceholder => 'キャラクター素材を検索';

  @override
  String get createActorInvalidOrderId =>
      'キャラクターのIP注文番号が無効です。ページを更新してからもう一度お試しください';

  @override
  String get createDramaTitle => 'ドラマを作成';

  @override
  String get createDramaTitleLabel => 'ショートドラマのタイトル';

  @override
  String get createDramaTitleHint => 'ドラマ名を入力';

  @override
  String get createDramaSynopsisLabel => 'あらすじ';

  @override
  String get createDramaSynopsisHint => 'どのような物語を描くのか……（最大1000字）';

  @override
  String get createDramaAiSettings => 'AI生成設定';

  @override
  String get createDramaVisualStyle => 'ビジュアルスタイル';

  @override
  String get createDramaVisualStyleRealistic => 'リアル';

  @override
  String get createDramaEpisodeDuration => 'エピソード時間';

  @override
  String get createDramaEpisodeDurationValue => '3-5分';

  @override
  String get createDramaTotalEpisodes => '総エピソード数';

  @override
  String get createDramaTotalEpisodesValue => '8話';

  @override
  String get createDramaGenreLabel => 'タイプ';

  @override
  String get createDramaGenreDrama => 'ドラマ';

  @override
  String get createDramaGenreComedy => 'コメディ';

  @override
  String get createDramaGenreAction => 'アクション';

  @override
  String get createDramaGenreRomance => 'ロマンス';

  @override
  String get createDramaGenreSciFi => 'SF';

  @override
  String get createDramaGenreMystery => 'サスペンス';

  @override
  String get createDramaGenreHorror => 'ホラー';

  @override
  String get createDramaGenreAnimation => 'アニメーション';

  @override
  String get createDramaHeroTitle => 'AIドラマ制作';

  @override
  String get createDramaHeroSubtitle => 'ワンクリックで次のヒットドラマを生成';

  @override
  String get createDramaStartGeneration => '生成を開始';

  @override
  String get creatorDramaManagementTab => 'ショートドラマの管理';

  @override
  String get creatorDramaNftTab => 'ショートドラマNFT';

  @override
  String get creatorHeaderSubtitle => 'ショートドラマの投稿、審査、および制作。';

  @override
  String get creatorV2Subtitle => 'ショートドラマ/動画の投稿と管理。';

  @override
  String creatorV2DramaTabCount(int count) {
    return 'ショートドラマ（$count）';
  }

  @override
  String creatorV2VideoTabCount(int count) {
    return '動画（$count）';
  }

  @override
  String get creatorV2NoVideos => '動画はありません';

  @override
  String get creatorLoginPrompt => 'ログインしてクリエイションを表示';

  @override
  String get creatorNoCreatedActors => '作成したロールがありません';

  @override
  String get creatorNoPublishedDramas => '投稿したドラマがありません';

  @override
  String get creatorOwnedNftCount => 'NFTの保有数';

  @override
  String get creatorCreateDrama => 'ドラマを制作';

  @override
  String get creatorPublishNewDrama => '新しいショートドラマを投稿';

  @override
  String get creatorPublishedDramas => 'ショートドラマを投稿';

  @override
  String get creatorReviewFilterAll => 'すべて';

  @override
  String get creatorReviewFilterApproved => '承認済み';

  @override
  String get creatorReviewFilterPending => '審査中';

  @override
  String get creatorReviewFilterRejected => '不合格';

  @override
  String get creatorReviewFilterOffline => '公開終了';

  @override
  String get creatorDramaOtherReason => 'その他の理由';

  @override
  String get creatorDramaStatusOnline => '承認済み';

  @override
  String get creatorDramaStatusPendingReview => '審査中';

  @override
  String get creatorDramaStatusReviewRejected => '不合格';

  @override
  String get creatorDramaStatusPendingOnline => '公開待ち';

  @override
  String creatorDramaAuditReason(Object reason) {
    return '審査不合格理由：$reason';
  }

  @override
  String get creatorDramaNftMinted => '鋳造済み';

  @override
  String creatorDramaEpisodeCount(int count) {
    return '$count 話';
  }

  @override
  String get creatorDramaEdit => '編集';

  @override
  String get creatorDramaDelete => '削除';

  @override
  String get creatorActorDelete => 'ロールを削除する';

  @override
  String get creatorDeleteDramaConfirm => 'このショートドラマを削除してもよろしいですか？';

  @override
  String get creatorDeleteVideoConfirmTitle => '動画削除の確認';

  @override
  String creatorDeleteVideoConfirmMessage(String name) {
    return '「$name」を削除してもよろしいですか？\nこの操作は元に戻せません。';
  }

  @override
  String get creatorDeleteActorConfirm => 'このキャラクターを削除してもよろしいですか？';

  @override
  String get creatorDeleting => '削除中...';

  @override
  String get creatorNoDramas => 'ショートドラマはありません';

  @override
  String get creatorNoNfts => 'ショートドラマのNFTは現在ありません';

  @override
  String get creatorsComingSoon => '近日公開';

  @override
  String get creatorsHeroSubtitle => '優れたクリエイターを発見';

  @override
  String get creatorsHeroTitle => 'クリエイター';

  @override
  String get dramaBatchUnlockAll => 'すべて解除';

  @override
  String dramaBatchUnlockDiscount(String discount) {
    return '一括解除割引 $discount%';
  }

  @override
  String get dramaBatchUnlockSubtitle => 'すべてのエピソードを一度に解除してお得に';

  @override
  String get dramaBatchUnlockSuccess => '解除成功、視聴を開始してください';

  @override
  String get dramaDetailAllFree => 'すべて無料';

  @override
  String dramaDetailBoundActors(int count) {
    return '$count人のロールが紐付け済み';
  }

  @override
  String dramaDetailEpisodeCount(int count) {
    return '$count 話';
  }

  @override
  String get dramaDetailEpisodePrice => '1回あたりの価格';

  @override
  String get dramaDetailFree => '無料';

  @override
  String dramaDetailFreeEpisodes(int count) {
    return '最初の$count話無料';
  }

  @override
  String get dramaDetailMainCharacters => '主な登場ロール';

  @override
  String get dramaDetailNftMinted => 'NFT鋳造済み';

  @override
  String get dramaDetailNoEpisodes => 'エピソードがありません';

  @override
  String get dramaDetailPaid => '有料';

  @override
  String get dramaDetailPendingActor => '出演ロール未定';

  @override
  String get dramaDetailRoleCount => 'ロール数';

  @override
  String get dramaUnlockFailedRetry => '解除に失敗しました、再試行してください';

  @override
  String get dramaUnlockFetchTimeout => '再生アドレスの取得がタイムアウトしました、再試行してください';

  @override
  String get dramaUnlockLoginRequired => 'エピソードを解除するにはログインしてください';

  @override
  String dramaUnlockMessage(
    int epNo,
    String price,
    String discount,
    String currency,
  ) {
    return 'エピソード$epNoの解除には支払いが必要です\n価格: $price $currency\n一括解除割引: $discount';
  }

  @override
  String get dramaUnlockSuccessFetching => '解除成功、再生アドレスを取得中...';

  @override
  String get dramaUnlockTitle => 'エピソードをアンロック';

  @override
  String get editActorTitle => 'ロールを編集';

  @override
  String get editDramaTitle => 'ショートドラマを編集する';

  @override
  String get editVideoTitle => '動画を編集する';

  @override
  String get editSaveChanges => '変更を保存';

  @override
  String get editProfileTitle => 'プロフィールを編集';

  @override
  String get editNicknameLabel => 'ニックネーム';

  @override
  String get editRoleNameLabel => 'ユーザー名';

  @override
  String get editNicknameHint => 'ニックネームを入力';

  @override
  String get editNicknameRequired => 'ニックネームを入力してください';

  @override
  String get editProfileBioLabel => 'プロフィール';

  @override
  String get editProfileBioHint => 'プロフィールを入力してください';

  @override
  String get editProfileEmailLabel => 'メールアドレス';

  @override
  String get editAvatarCropTitle => 'アバターを切り取り';

  @override
  String get profileUpdateSuccess => 'プロフィールを更新しました';

  @override
  String incomeClaimAmount(String amount, String currency) {
    return '$amount $currencyを請求';
  }

  @override
  String get incomeClaimFailed => '請求に失敗しました';

  @override
  String incomeClaimMessage(String amount, String currency) {
    return '請求可能額: $amount $currency\n収益はウォレット残高に転送されます';
  }

  @override
  String get incomeClaimSuccess => '請求成功';

  @override
  String get incomeClaimTitle => '収益を受け取る';

  @override
  String get incomeConfirmClaim => '受取を確認';

  @override
  String get incomeHistoryTab => '履歴';

  @override
  String get incomeInviteHeroSubtitle =>
      '友達を招待して消費やインタラクションを促し、招待者が活発なほど報酬が高くなります';

  @override
  String get incomeInviteHeroTitle => '友達を招待して還元を受け取る';

  @override
  String get incomeInviteNoRecords => '還元記録がありません';

  @override
  String get incomeInvitePaidUnlockDesc => '友達がエピソードの解除に支払い';

  @override
  String get incomeInvitePaidUnlockTitle => '有料解除';

  @override
  String get incomeInviteRecords => '還元記録';

  @override
  String get incomeInviteRegisterDesc => '友達が紹介リンクで登録';

  @override
  String get incomeInviteRegisterTitle => '招待登録';

  @override
  String get incomeInviteRules => '還元ルール';

  @override
  String get incomeInviteShareLink => '招待リンクを共有';

  @override
  String get incomeInviteStakeDesc => '友達がNFTやSTORYをステーク';

  @override
  String get incomeInviteStakeTitle => 'ステーク投資';

  @override
  String get incomeInviteTab => '招待還元';

  @override
  String get incomeInviteWatchDesc => '友達がドラマを視聴してポイントを獲得';

  @override
  String get incomeInviteWatchTitle => 'ドラマを視聴';

  @override
  String get incomeNoHistory => '履歴記録がありません';

  @override
  String get incomeNoRecords => '収益記録がありません';

  @override
  String get incomeNothingToClaim => '請求するものはありません';

  @override
  String get incomeOverviewTab => '概要';

  @override
  String get incomePendingClaim => '請求待ち';

  @override
  String get incomeRecords => '収益記録';

  @override
  String get incomeThisMonth => '今月';

  @override
  String get incomeToday => '今日';

  @override
  String get incomeTotalEarnings => '累計収益';

  @override
  String get incomeCumulativeStory => '累計 STORY';

  @override
  String incomeCumulativeUsdc(String currency) {
    return '$currencyの累計';
  }

  @override
  String get incomeClaimableStory => 'STORYを受け取れます';

  @override
  String incomeClaimableUsdc(String currency) {
    return '$currencyを受け取ることができます';
  }

  @override
  String get incomeSettlingStory => 'マイギャラ';

  @override
  String get incomeSettlingHint => '決済中；到着後に請求可能';

  @override
  String get incomeHelpTotalStoryDesc =>
      'これまでのすべての期間を通じて獲得した STORY の総量（受け取った分と未受け取り分を含む）。';

  @override
  String incomeHelpTotalUsdcDesc(String currency) {
    return '歴史上のすべてのキャラクターに関する契約に基づく収益分配および二次利用ロイヤリティの累計$currency収入。';
  }

  @override
  String get incomeHelpSettlingStoryDesc => 'システム決済後に自動で STORY に交換されます';

  @override
  String get incomeHelpClaimableStoryDesc =>
      '決済済みのSTORYは、個人のウォレットに受け取ることができます。';

  @override
  String incomeHelpClaimableUsdcDesc(String currency) {
    return '決済済みの$currencyは、個人のウォレットに受け取ることができます。';
  }

  @override
  String get incomeFilterAll => 'すべて';

  @override
  String get incomeFilterMining => '派遣収入';

  @override
  String get incomeFilterInvite => '紹介報酬';

  @override
  String get incomeMiningReward => '派遣収入';

  @override
  String get incomeInviteReward => '紹介報酬';

  @override
  String get incomeUsdcActorSignShare => 'キャラクター契約による収益分配';

  @override
  String get incomeClaimNoWallet => 'まずウォレットを紐付けてください';

  @override
  String incomeClaimCurrencyTitle(String currency) {
    return '$currencyを請求';
  }

  @override
  String incomeClaimWithdrawMessage(
    String amount,
    String currency,
    String address,
  ) {
    return 'Solanaウォレットに $amount $currency を出金してもよろしいですか？\n受取先: $address';
  }

  @override
  String get incomeClaimWithdrawConfirm => '出金を確認';

  @override
  String get incomeClaimWithdrawSubmitted => '出金成功！';

  @override
  String get incomeClaimWithdrawFailed => '出金に失敗しました、再試行してください';

  @override
  String get incomeClaimAction => '受け取る';

  @override
  String get nftCreateActorIp => 'キャラクターIPを発行する';

  @override
  String get nftHeaderSubtitle => '独占的なキャラクターNFTを集めて探索';

  @override
  String get nftHeaderTitle => 'キャラクターNFT広場';

  @override
  String get nftSearchHint => '短編ドラマ、作品、ロール、ユーザーを検索...';

  @override
  String get actorHowToPlayTitle => 'キャラクターIPの活用方法';

  @override
  String get actorHowToPlayHelpTooltip => '遊び方の説明';

  @override
  String get actorHowToPlaySignTab => '契約済みIP';

  @override
  String get actorHowToPlaySignSubtitle => 'ギャラを自動で獲得';

  @override
  String get actorHowToPlayIssueTab => 'IPを発行';

  @override
  String get actorHowToPlayIssueSubtitle => '創作による収益化';

  @override
  String get actorHowToPlaySignPositioning => 'コンセプト：創作のハードルゼロ、手軽に安定した収益を得られる';

  @override
  String get actorHowToPlaySignAudience => '創作はしたくないが、手軽に STORY の収益を得たい一般ユーザー';

  @override
  String get actorHowToPlaySignGuide =>
      '高ヒートで高額なギャラのキャラクターIPと契約し、マネージャーページで出演を手配するだけで収益を得られます';

  @override
  String get actorHowToPlaySignRightsTitle => '二重収益';

  @override
  String get actorHowToPlaySignRightPerform => '公演を手配して、STORYトークンを継続的に獲得する';

  @override
  String get actorHowToPlaySignRightTrade =>
      'キャラクターのIPは取引可能で、プレミアム収益を得ることができます';

  @override
  String get actorHowToPlayIssuePositioning => '位置づけ：創作と発行、複数の収益源、IPの長期的な価値向上';

  @override
  String get actorHowToPlayIssueAudience =>
      '創作能力があり、キャラクターのIPやショートドラマを通じて収益化を図りたいクリエイター';

  @override
  String get actorHowToPlayIssueGuide =>
      'キャラクターIPを発行し、AIショートドラマと連動させて作品のヒートを高め、IPのギャラと収益を引き上げます';

  @override
  String get actorHowToPlayIssueRightsTitle => '三重の収益';

  @override
  String get actorHowToPlayIssueRightSignLabel => '契約による収益分配：';

  @override
  String get actorHowToPlayIssueRightSign => '自分のIPが契約された場合、40%の収益分配を受けられます';

  @override
  String get actorHowToPlayIssueRightPerformLabel => '公演の収益：';

  @override
  String get actorHowToPlayIssueRightPerform => '自分のIPと契約し、出演でSTORYを稼ぐ';

  @override
  String get actorHowToPlayIssueRightValueLabel => '付加価値：';

  @override
  String get actorHowToPlayIssueRightValue =>
      'IPは取引可能で、ヒートが高ければ高いほどプレミアムも高くなります';

  @override
  String get actorHowToPlayAudienceTitle => '対象者';

  @override
  String get actorHowToPlayGuideTitle => '遊び方ガイド';

  @override
  String get actorHowToPlayCreateHint =>
      'DreamOS を使えば、ワンクリックでキャラクターのIPやAIショートドラマを生成でき、高品質なコンテンツを効率的に制作できます';

  @override
  String get actorHowToPlayCreateCta => '創作しよう';

  @override
  String get nftSignInDevelopment => 'この機能は現在利用できません';

  @override
  String get nftSortCompleted => '完視聴';

  @override
  String get nftSortHeat => 'ヒート';

  @override
  String get nftSortIpPower => 'IPギャラ';

  @override
  String get nftSortLowestPrice => '価格';

  @override
  String get nftSortLv1Pay => 'ギャラ';

  @override
  String get nftSortMaxPay => '最大ギャラ';

  @override
  String get nftTradeUnavailable => '取引はまだ利用できません';

  @override
  String playerEpisodeBarCompleted(int count) {
    return '全$count話 · 完了';
  }

  @override
  String playerEpisodeSynopsis(int episodeNo, String synopsis) {
    return '第$episodeNo話 | $synopsis';
  }

  @override
  String get playerPlayFailedRetry => '再生に失敗しました、しばらくしてからもう一度お試しください';

  @override
  String get publicProfileDramas => 'ショートドラマ';

  @override
  String get publicProfileEmpty => '公開コンテンツがありません';

  @override
  String get publicProfileBlock => 'ブロック';

  @override
  String get publicProfileUnblock => 'ブロック解除';

  @override
  String get publicProfileBlockedByMeContent => 'このユーザーをブロックしたため、コンテンツを表示できません';

  @override
  String get publicProfileBlockedContent => 'このユーザーにブロックされたため、コンテンツを表示できません';

  @override
  String get publicProfileBlockConfirmTitle => 'このユーザーをブロックしますか？';

  @override
  String get publicProfileBlockConfirmMessage => 'ブロックすると、相手の作品を表示できなくなります。';

  @override
  String get publicProfileBlockSuccess => 'ブロックしました';

  @override
  String get publicProfileUnblockSuccess => 'ブロックを解除しました';

  @override
  String get publicProfileFollowers => 'フォロワー';

  @override
  String get publicProfileFollowing => 'フォロー';

  @override
  String get followTabMutual => '相互フォロー';

  @override
  String get profileLikesReceived => 'いいね';

  @override
  String profileLikesReceivedDialogMessage(int count) {
    return 'これまでに$count件のいいねを獲得しました。素晴らしい作品をありがとう！';
  }

  @override
  String get profileTabLikes => 'いいね';

  @override
  String get profileTabFavorites => 'お気に入り';

  @override
  String get profileWalletTitle => 'ウォレット';

  @override
  String get profileAddressCopied => 'アドレスをコピーしました';

  @override
  String get followActionFollow => 'フォロー';

  @override
  String get followActionFollowBack => 'フォローバック';

  @override
  String get followActionFollowing => 'フォロー中';

  @override
  String get followBlockedByMe => 'ブラックリスト登録済みのユーザーのため、フォローできません';

  @override
  String get followBlockedByTarget => '相手側の設定により、フォローできません';

  @override
  String get likeBlockedByMe => 'ブラックリスト登録済みのユーザーのため、いいねできません';

  @override
  String get likeBlockedByTarget => '相手側の設定により、いいねできません';

  @override
  String get favoriteBlockedByMe => 'ブラックリスト登録済みのユーザーのため、お気に入りできません';

  @override
  String get favoriteBlockedByTarget => '相手側の設定により、お気に入りできません';

  @override
  String get ratingBlockedByMe => 'ブラックリスト登録済みのユーザーのため、評価できません';

  @override
  String get ratingBlockedByTarget => '相手側の設定により、評価できません';

  @override
  String get followActionMutual => '相互フォロー';

  @override
  String get followUnfollowTitle => 'フォロー解除';

  @override
  String followUnfollowMessage(String handle) {
    return '$handle のフォローを解除しますか？';
  }

  @override
  String get followUnfollowNo => 'いいえ';

  @override
  String get followUnfollowYes => 'はい';

  @override
  String get followListEmpty => 'ユーザーがいません';

  @override
  String get followFollowingEmpty => 'まだフォローしていません。気になるクリエイターを見つけよう～';

  @override
  String get followFollowingEmptyCta => '見てみる';

  @override
  String get followFollowingEmptyGuest => 'フォローなし';

  @override
  String get followFollowersEmpty => 'まだフォロワーがいません。作品を投稿して注目を集めよう～';

  @override
  String get followFollowersEmptyCta => '投稿する';

  @override
  String get followFollowersEmptyGuest => 'フォロワーなし';

  @override
  String get followMutualsEmpty => '相互フォローの友達はまだいません';

  @override
  String get followMutualsSelfOnly => '相互フォロー一覧は本人のみ閲覧できます';

  @override
  String get followRelationsSelfOnly => 'フォロー一覧は本人のみ閲覧できます';

  @override
  String get followMoreTitle => 'その他';

  @override
  String get followRemoveFollower => 'フォロワーを削除';

  @override
  String get followRemoveFollowerSuccess => '削除しました。相手には通知されません';

  @override
  String get followUserHandleFallback => '@ユーザー';

  @override
  String get publicProfileTitle => 'ユーザープロフィール';

  @override
  String publicProfileUserFallback(String id) {
    return 'ユーザー #$id';
  }

  @override
  String get watchHistoryEmpty => '視聴履歴がありません';

  @override
  String get watchHistoryClearTitle => '視聴履歴を消去';

  @override
  String get watchHistoryClearMessage => 'すべての視聴履歴を消去しますか？この操作は元に戻せません。';

  @override
  String get watchHistoryClearConfirm => '確定';

  @override
  String get gamePageTitle => 'エージェント';

  @override
  String get gamePageSubtitle => 'ロールを管理し、派遣して収益を上げよう。';

  @override
  String get gameRiskAccount => 'リスクアカウント';

  @override
  String get gameRiskAccountDescription =>
      'このアカウントの信頼係数に異常があります。マイニング重みに影響します。';

  @override
  String get gameWeeklyStats => '週間統計';

  @override
  String get gameDeployedActors => '配信中のロール';

  @override
  String get gameMyActors => '私のロール';

  @override
  String get gameComingSoon => '近日公開';

  @override
  String get gameSignActor => 'キャラクターを契約';

  @override
  String get gameGoProduce => 'ドラマの撮影に行く';

  @override
  String get gameWorkingActors => '派遣中のロール';

  @override
  String get gameWeekPool => '今週の報酬プール (STORY)';

  @override
  String get gameWeekNominalOutput => '今週の名目生産高 (STORY)';

  @override
  String get gameWeekEstimatedOutput => '今週の予想生産量 (STORY)';

  @override
  String get gameMiningRules => 'マイニングのルール';

  @override
  String get agentV2RulesTitle => '運営プレイ';

  @override
  String get agentV2RulesSummary =>
      'キャラクターと契約して出演を設定すると、1時間ごとにSTORYを獲得できます。\nキャラクターをアップグレードすると、1時間あたりのギャラが倍増します。\n体力が尽きたらすぐに補充し、産出を止めないようにしましょう。\n毎週月曜日 00:00（UTC）に当期収益の精算が始まり、収益ページで受け取れます。';

  @override
  String get agentV2RulesHowToPlay => '遊び方';

  @override
  String get agentV2RulesStartTitle => 'キャラクターに収益を発生させるには？';

  @override
  String get agentV2RulesStartDescription =>
      '待機中のキャラクターを出演させると、1時間ごとに体力を1消費し、ギャラに応じてSTORYを産出します。\n産出されたSTORYは各期終了時に一括精算され、精算後に収益ページで受け取れます。';

  @override
  String get agentV2RulesStaminaTitle => '体力はどう管理する？';

  @override
  String agentV2RulesStaminaDescription(int staminaLimit) {
    return '出演中：1時間ごとに体力を1消費し、通常どおりギャラを産出\n体力切れ：産出が0で停止するため、すぐに対応が必要\n休憩：1時間ごとに体力を1自動回復するが、ギャラは停止\n体力補充（有料）：即座に$staminaLimitまで全回復し、産出を再開';
  }

  @override
  String get agentV2RulesBatchTitle => '一括操作はできますか？';

  @override
  String get agentV2RulesBatchDescription =>
      'はい。ページ下部の「全員出演」「全員補充」「全員休憩」で、出演枠にいるすべてのロールを一括操作できます。';

  @override
  String get agentV2RulesEarnings => '獲得できる収益';

  @override
  String get agentV2RulesSalaryTitle => 'ギャラはどうやって計算されますか？';

  @override
  String get agentV2RulesSalaryDescription =>
      'ランクが高く、キャラクターの価値が高く、ショートドラマの人気が高いほど、1時間あたりのギャラも高くなります。';

  @override
  String get agentV2RulesSalaryFormula => 'カード1枚の時間ギャラ = キャラクターギャラ × 1 STORY';

  @override
  String get agentV2RulesRolePowerFormula =>
      'キャラクターギャラ = Lv.1キャラクターギャラ × ギャラ係数';

  @override
  String get agentV2RulesIpSalaryFormula => 'Lv.1キャラクターギャラ = 価格係数 × ヒート係数';

  @override
  String get agentV2RulesCoefficientTitle => '係数の説明';

  @override
  String agentV2RulesSalaryExample(String currency) {
    return '林夢瑶 · Lv3 主役 · P0=120$currency（価格係数 ≈1.5046）· ヒート 3.5\n→ 時間ギャラ = 5.0 × 1.5046 × 3.5 × 1 = 26.3 STORY\nLv1 エキストラの場合は1時間あたり約5.3 STORYのみ——Lv3への昇格で5倍になります。';
  }

  @override
  String get agentV2RulesSettlementTitle => 'いつ精算されますか？';

  @override
  String get agentV2RulesSettlementDescription =>
      '公演周期は7日間で、毎週月曜日 00:00（UTC）に締め切ります。システム精算完了後、今期のギャラは自動でSTORYに交換され、収益ページで受け取れます。';

  @override
  String get agentV2RulesSettlementExample =>
      '今週の報酬プールが100,000 STORYの場合：\nケースA：プラットフォーム全体であなただけが134を産出 → 134を受け取り、残りは配布されません\nケースB：ネットワーク全体の産出が250,000 → 100,000 ÷ 250,000 = 40%となり、名目産出は40%に縮小\nケースC：縮小後の受取額が6,000でも、上限が5,000なら5,000のみ配布';

  @override
  String get agentV2RulesStronger => '強化方法';

  @override
  String get agentV2RulesUpgradeTitle => 'キャラクターをアップグレードするには？';

  @override
  String get agentV2RulesUpgradeDescription =>
      '条件：同じIP・同じレベルの複製カード2枚を消費 + IP出演ドラマの累計完視聴数を達成\nLv1→Lv2：完視聴1万回以上・ギャラ 1→3\nLv2→Lv3：完視聴5万回以上・ギャラ 3→9\nLv3→Lv4：完視聴20万回以上・ギャラ 9→27\nLv4→Lv5：完視聴100万回以上・ギャラ 27→81';

  @override
  String get agentV2RulesPerforming => '出演中';

  @override
  String get agentV2RulesNormalSalary => '通常ギャラ';

  @override
  String get agentV2RulesSalaryCoefficient =>
      'ギャラ係数：Lv1=1 · Lv2=3 · Lv3=9 · Lv4=27 · Lv5=81';

  @override
  String agentV2RulesPriceCoefficientDescription(
    String currency1,
    String currency2,
  ) {
    return '価格係数（発行価格 P0）：\n  • P0 ≤ 100$currency1 → 係数 = P0 ÷ 100（線形増加）\n  • P0 > 100$currency2 → 係数 = 1.6 × (P0/100)¹.³ / [(P0/100)¹.³ + 0.6]（漸近上限 1.6）';
  }

  @override
  String get agentV2RulesTrust2 => 'Trust2';

  @override
  String get agentV2RulesTrust2Factor => 'プラットフォームTrust2';

  @override
  String get agentV2RulesSettlementCase1 => '実際の配布額 = 名目産出、未使用分は失効';

  @override
  String get agentV2RulesSettlementCase2 =>
      '比例調整：実際の受取額 = 名目産出 ×（報酬プール ÷ ネットワーク全体の産出）';

  @override
  String get gameSettlementRecords => '週次決算記録';

  @override
  String get gameFilterComputingPower => 'ギャラ';

  @override
  String get gameFilterLevel => 'レベル';

  @override
  String get gameFilterHeat => 'ヒート';

  @override
  String get gameFilterStamina => '体力';

  @override
  String get gameHeatCoef => 'ヒート係数';

  @override
  String get gameMiningCoef => 'マイニング係数';

  @override
  String get gameActorPower => 'キャラクターギャラ';

  @override
  String get gameActorPowerDetailTitle => 'キャラクターギャラの詳細';

  @override
  String get gameActorPowerFormula =>
      'キャラクターギャラ = IPギャラ × マイニング係数 × CP係数 × Trust2';

  @override
  String get gameActorPowerIpFormula => 'IPギャラ = 価格係数 × ヒート係数 × Trust1';

  @override
  String get gameActorPowerHourlyOutput => '1時間あたりの産出';

  @override
  String get gameCpCoefficient => 'CP係数';

  @override
  String get gameTrust2 => 'Trust2';

  @override
  String get gameWeeklyNominalOutputLabel => '今週の名目生産高';

  @override
  String get gameRoundNominalOutputLabel => '期間 nominal 出力';

  @override
  String get gameSupplement => '補足';

  @override
  String get gameRest => '休憩';

  @override
  String get gameDeploy => '派遣';

  @override
  String get gameDeployActor => 'キャラクターの派遣';

  @override
  String get gameStatusIdle => '未使用';

  @override
  String get gameStatusMining => 'マイニング中';

  @override
  String gameActorIpLabel(String id) {
    return 'キャラクターIP $id';
  }

  @override
  String gameStaminaProgress(String current, String max) {
    return '$current/$max';
  }

  @override
  String get gameStaminaMechanismTitle => '体力の仕組み';

  @override
  String gameStaminaMechanismDesc(String currency) {
    return '派遣中のロールは1時間ごとに体力を1ポイント消費します。体力がなくなると報酬の獲得が停止し、休息中は自動的に回復します。$currencyを使って体力を即時補充できます。';
  }

  @override
  String get gameStaminaMechanismAction => 'わかりました';

  @override
  String gameLevelBadge(String level) {
    return 'Lv$level';
  }

  @override
  String get gameEmptyDeployed => '現在配信中のロールはいません';

  @override
  String get gameEmptyMyActors => 'まだキャラクターがいません。契約して始めましょう。';

  @override
  String get gameDeployConfirmTitle => 'このキャラクターを派遣しますか？';

  @override
  String get gameRestConfirmTitle => 'このキャラクターを休憩させますか？';

  @override
  String get gameRestConfirmDesc => 'キャラクターの休憩中は採掘報酬が停止し、体力は時間経過で回復します。';

  @override
  String get gameRestConfirmAction => '休憩を確認';

  @override
  String get gameRestSuccessToast => '休憩しました';

  @override
  String get gameDeploySlotFull => '配信スロットが満杯です（最大5）';

  @override
  String get gameRefillTitle => '体力を回復する';

  @override
  String get gameRefillCurrentStamina => '現在の体力';

  @override
  String get gameRefillCost => '復旧費用';

  @override
  String get gameRefillConfirm => '体力をすべて回復する';

  @override
  String get gameRefillSuccess => '体力の回復に成功しました';

  @override
  String get gameRefillFailed => '体力の回復に失敗しました。もう一度お試しください。';

  @override
  String gameInsufficientUsdc(String currency) {
    return '$currencyの残高が不足しています';
  }

  @override
  String get walletInsufficientStory => 'STORYの残高が不足しています';

  @override
  String get gameSupplementComingSoon => '体力回復は近日公開';

  @override
  String get gameStatHelpWeekPoolTitle => '今週の報酬プール';

  @override
  String get gameStatHelpWeekPoolSubtitle =>
      'すなわち、STORYマイニングにおける毎週の固定配布上限（週次上限）';

  @override
  String get gameStatHelpWeekTotalPool => '今週の総報酬プール';

  @override
  String get gameStatHelpWeekTotalPoolValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeekStakePool => '今週のステーキング報酬プール（75%）';

  @override
  String get gameStatHelpWeekStakePoolValue => '1,586,538 STORY';

  @override
  String get gameStatHelpWeekInvitePool => '今週の招待報酬プール（25%）';

  @override
  String get gameStatHelpWeekInvitePoolValue => '528,846 STORY';

  @override
  String get gameStatHelpInitialHardCap => '初期のハードトップ';

  @override
  String get gameStatHelpInitialHardCapValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeeklyDecay => '週減衰係数';

  @override
  String get gameStatHelpWeeklyDecayValue => '× 0.99572';

  @override
  String get gameStatHelpWeeklyDistributionFormula =>
      '週間の実質配布量 = min(ネットワーク全体の名目生産量, 当該週のハードキャップ)';

  @override
  String get gameStatHelpUnusedQuotaNote =>
      '未配布の残枠については、配布せず、戻さず、ポイントの補填も行いません。';

  @override
  String get gameStatHelpNominalTitle => '今週の名目産出';

  @override
  String get gameStatHelpNominalSummary => 'すべてのロールの週間累計名目産出の合計';

  @override
  String get gameStatHelpNominalSummaryHint =>
      'シングルカードの計算式については、以下の説明を参照してください。';

  @override
  String get gameStatHelpNominalFormula =>
      '1枚あたりの名目産出 = 1枚あたりの時間重み × R_base × 有効マイニング時間';

  @override
  String get gameStatHelpHourlyWeight => 'シングルカード時間加重';

  @override
  String get gameStatHelpHourlyWeightValue => '= キャラクターギャラ';

  @override
  String get gameStatHelpActorPower => 'キャラクターギャラ';

  @override
  String get gameStatHelpActorPowerValue => '= IPギャラ × マイニング係数 × CP係数 × Trust2';

  @override
  String get gameStatHelpCpCoef => 'CP係数';

  @override
  String get gameStatHelpRBase => 'R_base';

  @override
  String get gameStatHelpRBaseValue => '1 STORY / 単位重み / 時間';

  @override
  String get gameStatHelpEffectiveDuration => '有効なマイニング時間';

  @override
  String get gameStatHelpEffectiveDurationValue =>
      '担保中であり、かつ体力が 0 より大きい状態の累計時間';

  @override
  String get gameStatHelpActualTitle => '今週の生産見込み';

  @override
  String get gameStatHelpActualSubtitle =>
      '名目産出は週次上限と単一アドレス上限の制約を受け、週末に実際の収益が確定します';

  @override
  String get gameStatHelpIfNominalLte => 'ネットワーク全体の名目生産量が、当該週のハードキャップ以下である場合：';

  @override
  String get gameStatHelpUserActualEqNominal => 'ユーザーの実受取額 ＝ ユーザーの名目生産高';

  @override
  String get gameStatHelpIfNominalGt => 'ネットワーク全体の名目生産量が、その週のハードキャップを上回る場合：';

  @override
  String get gameStatHelpUserActualFormula =>
      'ユーザーの実受取額 = ユーザーの名目生産量 × 当該週のハードキャップ / ネットワーク全体の名目生産量';

  @override
  String get gameStatHelpAddressCap => '1アドレスあたりの週間上限';

  @override
  String get gameStatHelpAddressCapValue =>
      '1つのアドレスにつき、毎週その週のハードキャップの最大5％まで受け取ることができます。';

  @override
  String get theaterCategoryAll => 'すべて';

  @override
  String get theaterCategoryAncient => '時代劇';

  @override
  String get theaterCategoryFinance => '金融';

  @override
  String get theaterCategorySuspense => 'サスペンス';

  @override
  String get theaterCategorySciFi => 'SF';

  @override
  String get theaterCategoryRealStory => '実話に基づく';

  @override
  String get theaterCategoryUrban => '都市';

  @override
  String get theaterSortHottest => '最も人気のある';

  @override
  String get theaterSortNewest => '最新';

  @override
  String get theaterSortTopRated => '最も多くのお気に入り登録';

  @override
  String get theaterSortCompletedView => '最高完走';

  @override
  String theaterPlayCount(String count) {
    return '$count 回再生';
  }

  @override
  String get createDramaBasicInfo => '基本情報';

  @override
  String get createDramaEpisodes => 'ドラマ管理';

  @override
  String get createDramaRoles => 'IPを紐付け';

  @override
  String get createDramaCover => '表紙';

  @override
  String get createDramaCoverUpload => 'アップロード';

  @override
  String get createDramaCoverPlaceholder => 'JPG/PNG対応、最大5MB';

  @override
  String get createDramaCoverCropTitle => 'カバーを切り取り';

  @override
  String get createDramaName => 'ショートドラマのタイトル';

  @override
  String get createDramaNameHint => 'ショートドラマのタイトルを入力してください';

  @override
  String get createDramaSynopsis => '概要';

  @override
  String get createDramaTags => 'タグ';

  @override
  String get createDramaTagsHint => 'タグを入力してEnterで追加（例：ラブ、コメディ）';

  @override
  String get createDramaTagsLoading => 'タグ読み込み中…';

  @override
  String get createDramaTagsEmpty => '利用可能なタグがありません';

  @override
  String get createDramaTagsRetry => '再試行';

  @override
  String get createDramaUploadDesc => '「アップロード」をクリックすると、送信後に動画名順に自動的に並べ替えられます';

  @override
  String get createDramaEpisodesDesc =>
      '動画ファイルを一括アップロードすると、システムが自動的にファイル名順に並べ替えてエピソード一覧を生成します。ドラッグ＆ドロップによる並べ替え、削除、タイトルの編集などの操作が可能です。';

  @override
  String get createDramaVideoFileTypeHint =>
      '対応形式: mp4, flv, wmv, asf, mkv, avi, rm, rmvb, mpg, mpeg, mov, webm。最大ファイルサイズ2GB。';

  @override
  String get createDramaUploadVideo => '動画をアップロードする';

  @override
  String get createDramaVideoEmpty => 'まだ動画が追加されていません';

  @override
  String get createDramaVideoPickFailed => '動画の選択に失敗しました';

  @override
  String get createDramaVideoAnyTooLarge => '2GBを超えるビデオファイルがあります。調整して再選択してください';

  @override
  String get createDramaVideoStatusUploading => 'アップロード中';

  @override
  String get createDramaVideoStatusPaused => 'アップロード一時停止';

  @override
  String get createDramaVideoStatusDone => 'アップロードが完了しました';

  @override
  String get createDramaEpisodeDescriptionHint => 'エピソードの概要';

  @override
  String get createDramaVideoStatusFailed => 'アップロードに失敗しました';

  @override
  String get createDramaVideoTooLarge => '動画サイズは2GBを超えることはできず、アップロードできません';

  @override
  String get createDramaVideoUploadComplete => 'すべての動画がアップロードされました';

  @override
  String createDramaVideoUploadFailed(String name) {
    return '$nameのアップロードに失敗しました';
  }

  @override
  String createDramaVideoPickOverflow(int count, int overflow) {
    return 'さらに$count話追加できます。$overflow件の余分なファイルはスキップされました。';
  }

  @override
  String createDramaAddedVideos(String count) {
    return '追加された動画 ($countファイル)';
  }

  @override
  String createDramaAddedVideosCount(String count) {
    return '($countファイル)';
  }

  @override
  String get createDramaAddedVideosLabel => '追加された動画';

  @override
  String get createDramaRolesDesc => 'ショートドラマのロールを作成し、名前、プロフィール画像、性格設定を決定します。';

  @override
  String get createDramaRolesRule1 =>
      '各ショートドラマには最大5つのキャラクターIPを紐付けできます。公開後7日以内は追加できますが、公開後の解除や変更はできません。';

  @override
  String get createDramaRolesRule2 =>
      '紐付けたキャラクターIPには、ドラマの完走率と人気データが関連付けられ、アップグレードとSTORY報酬に使用されます。';

  @override
  String get createDramaRolesExpireTime => '期限';

  @override
  String get createDramaRolesRule3 => 'IPの紐付けは任意です。紐付けずに公開できます。';

  @override
  String get createDramaAddRole => 'ロールを追加';

  @override
  String get createDramaBindActor => '出演ロール';

  @override
  String get createDramaRoleActing => '出演ロール';

  @override
  String get createDramaSelectActor => 'ロールを選択';

  @override
  String get createDramaBindActorTitle => 'キャラクターのIPを選択';

  @override
  String createDramaBindIpSelectedCount(int count) {
    return '$count件選択済み';
  }

  @override
  String get createDramaBindIpEmpty => 'データがありません';

  @override
  String get createDramaBindIpMarketplace => 'キャラクターIPマーケットへ';

  @override
  String get createDramaBindIpConfirm => '紐付けを確定';

  @override
  String createDramaBindActorSubtitle(String roleName) {
    return '「$roleName」を演じるキャラクターを1人選んでください';
  }

  @override
  String createDramaBindActorOwnedCount(int count) {
    return '$count件のキャラクターのIPを保有しています';
  }

  @override
  String createDramaBindActorIpLabel(String code) {
    return 'キャラクターIP $code';
  }

  @override
  String get createDramaBindActorBoundTag => '連携済み';

  @override
  String get createDramaBindIpRemove => '削除';

  @override
  String createDramaBindActorBoundToast(String name) {
    return '$nameを紐付けました';
  }

  @override
  String get createDramaBindActorUnbind => '紐付け解除';

  @override
  String get createDramaBindActorExpired =>
      '7日間の紐付け期間を過ぎたため、キャラクターIPを新たに紐付けることはできません';

  @override
  String get createDramaBindActorEmptyTitle => '紐付けるキャラクターIPがありません';

  @override
  String get createDramaBindActorEmptyDesc =>
      'ロールに紐付ける前にキャラクターIPを保有している必要があります';

  @override
  String get createDramaBindActorGotoCreate => 'ロールを作成';

  @override
  String get createDramaPrevStep => '前のページ';

  @override
  String get createDramaNextStep => '次のステップ';

  @override
  String get createDramaSubmit => '投稿';

  @override
  String get createDramaRoleNameLabel => 'ロール名';

  @override
  String get createDramaRoleNameHint => 'ロール名を入力してください';

  @override
  String get createDramaRoleNameRequired => 'ロール名を入力してください';

  @override
  String get createDramaRoleBioLabel => 'ロール概要';

  @override
  String get createDramaRoleBioHint => 'ロールのプロフィールを入力してください';

  @override
  String get createDramaRoleBioRequired => 'ロールのプロフィールを入力してください';

  @override
  String get createDramaRoleAddTitle => 'ロールを追加';

  @override
  String get createDramaRoleEditTitle => 'ロールを編集';

  @override
  String get createDramaRoleUploadAvatar => 'プロフィール写真をアップロード';

  @override
  String get createDramaRoleSave => '保存';

  @override
  String get createDramaRoleDeleteConfirm => 'このキャラクターを削除しますか？';

  @override
  String createDramaVideoDeleteConfirm(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get createDramaVideoDeleteTitle => '動画を削除';

  @override
  String get createDramaVideoPreviewUnavailable => '以前にアップロードした動画は現在プレビューできません';

  @override
  String get createDramaRoleEmpty => 'まだロールが追加されていません';

  @override
  String get createDramaRoleBindComingSoon => 'ロールの紐付けは近日公開';

  @override
  String get createDramaRoleAvatarCropTitle => 'ロールアバターを切り取り';

  @override
  String get createDramaRoleAvatarUploadFailed => 'ロールアバターのアップロードに失敗しました';

  @override
  String get createDramaPublishedSuccess => '投稿に成功しました';

  @override
  String get createDramaDraftRestored => '未完成の下書きが復元されました';

  @override
  String get createDramaDraftClear => 'データを消去';

  @override
  String get createDramaDraftDiscard => '保存せず戻る';

  @override
  String get createDramaDraftSave => '下書きを保存';

  @override
  String get createDramaEditLoading => '読み込み中...';

  @override
  String get createDramaEditLoadError => 'ドラマ情報の読み込みに失敗しました、再試行してください';

  @override
  String get createDramaSubmitValidationTitle => 'ドラマタイトルを入力してください';

  @override
  String get createDramaSubmitValidationCover => 'カバー画像をアップロードしてください';

  @override
  String get createDramaSubmitValidationVideos => '少なくとも1つの動画をアップロードしてください';

  @override
  String get createDramaSubmitValidationSession =>
      'アップロードセッションが無効です、動画を再アップロードしてください';

  @override
  String get createDramaUploadSessionFailed => 'アップロードセッションの作成に失敗しました';

  @override
  String get createDramaSubmitValidationRoles => '少なくとも1つのロールを追加してください';

  @override
  String get createDramaStep1TitleRequired => 'ショートドラマのタイトルを入力してください';

  @override
  String get createDramaStep1SynopsisRequired => '自己紹介を入力してください';

  @override
  String get createDramaStep1CoverRequired => 'カバーを追加してください';

  @override
  String get createDramaStep1TagsRequired => 'タグを選択してください';

  @override
  String get createDramaEpisodeDescriptionRequired => 'エピソードの概要を入力してください';

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeSystem => 'システム';

  @override
  String get settingsUI => 'インターフェース';

  @override
  String get settingsAppVersion => 'バージョン';

  @override
  String get settingsVersionLatestToast => '最新バージョンを使用しています';

  @override
  String get settingsVersionCheckFailed => 'バージョン確認に失敗しました。しばらくしてから再度お試しください。';

  @override
  String get appVersionUpdateTitle => '新しいバージョンがあります';

  @override
  String get appVersionUpdateContentsLabel => '更新内容：';

  @override
  String get appVersionUpdateConfirm => '今すぐ更新';

  @override
  String get appVersionUpdateLater => 'あとで';

  @override
  String get settingsTermsOfService => '利用規約';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsDeleteAccount => 'アカウント削除';

  @override
  String settingsDeleteAccountConfirm(String deadline) {
    return 'アカウントは $deadline に削除されます。この期間中に再ログインすると、アカウント削除を取り消せます。';
  }

  @override
  String get settingsDeleteAccountSuccess => 'アカウント削除申請を送信しました';

  @override
  String get settingsClearCache => 'キャッシュをクリア';

  @override
  String get settingsNetworkInspector => 'ネットワークインスペクター';

  @override
  String get settingsClearCacheConfirm => 'キャッシュをクリアしてもよろしいですか？';

  @override
  String get miningRulesHowToPlay => 'マイニングの派遣はどのように行うのか';

  @override
  String get miningRulesFlowSubtitle => '派遣から報酬受け取りまでの全プロセスを1枚の図で理解する';

  @override
  String get miningRulesSection1Title => '1. 人を派遣して、採掘させる';

  @override
  String get miningRulesSection1Desc =>
      '空き状態のキャラクターを以下の5つのスロットに「配置」すると、そのキャラクターは自動的に採掘を開始し、STORYを生成するようになります。';

  @override
  String get miningRulesSection1Bullet1 => '1人につき、同時に最大5人のロールを派遣できます';

  @override
  String get miningRulesSection1Bullet2 =>
      '同じキャラクターのIPに対して、複数のカードを同時に派遣することも可能です';

  @override
  String get miningRulesSection1Bullet3 =>
      '派遣後、1時間ごとに⚡体力が1ポイント消費されます。体力が0より大きい間は生産が継続され、体力が0になると生産が停止します。';

  @override
  String get miningRulesSection2Title => '2. 計算、生産量の算出式';

  @override
  String get miningRulesSection2Desc => '1枚あたりの1時間あたりの生産量は、次のように計算されます：';

  @override
  String get miningRulesSection2Formula => '1カード1時間出力 = キャラクターギャラ × 1 STORY';

  @override
  String get miningRulesSection2FactorsTitle => '3つの決定要因：';

  @override
  String get miningRulesSection2Factor1 =>
      'マイニング係数――ランクが高いほど係数は大きくなる。Lv1=1.0 → Lv2=2.2 → Lv3=5.0 → Lv4=11 → Lv5=24';

  @override
  String get miningRulesSection2Factor2 => 'IPギャラ = 価格係数 × ヒート係数 × Trust1';

  @override
  String get miningRulesSection2Factor3 =>
      'R_base——固定値。現在は 1 STORY ですが、今後プラットフォーム側で手動で調整される可能性があります。';

  @override
  String miningRulesSection2Factor4(String currency1, String currency2) {
    return '価格係数——発行価格P0：P0≤10$currency1は線形に増加 · P0>10$currency2は上限1.6に漸近';
  }

  @override
  String get miningRulesSection2Factor5 =>
      'ヒート係数——最近のドラマ実績が良いほどヒートが高くなります（完視聴、いいね、お気に入り、コメント）';

  @override
  String get miningRulesSection2Factor6 => 'CP係数——現在未提供；Trustの初期値は1.0';

  @override
  String miningRulesSection2StaminaText(int staminaLimit) {
    return '体力は「あるかどうかのみ」が重要で、残量には関係ありません。$staminaLimitポイントでも1ポイントでも、1時間あたりの獲得量は同じです。体力は、採掘しているかどうかだけが重要です。';
  }

  @override
  String get miningRulesSection2ExampleTitle => '例えば：';

  @override
  String miningRulesSection2ExampleDesc(String currency) {
    return '林夢瑶 · Lv3 主役 · P0=12$currency（価格係数 ≈1.0859）· ヒート 3.5\n→ 時間産出 = 5.0 × 1.0859 × 3.5 × 1 = 19.00325 STORY';
  }

  @override
  String get miningRulesCoefTableTitle => '係数の詳細';

  @override
  String get miningRulesCoefColCoef => '係数';

  @override
  String get miningRulesCoefColFactor => '決定要因';

  @override
  String get miningRulesCoefColDesc => '詳細';

  @override
  String get miningRulesCoefMining => 'マイニング係数';

  @override
  String get miningRulesCoefPrice => '価格係数';

  @override
  String get miningRulesCoefHeat => 'ヒート係数';

  @override
  String get miningRulesCoefCp => 'CP係数';

  @override
  String get miningRulesCoefTrust => 'Trust';

  @override
  String get miningRulesCoefMiningFactor => 'レベル';

  @override
  String get miningRulesCoefPriceFactor => '発行価格 P0';

  @override
  String get miningRulesCoefHeatFactor => '最近のドラマ実績';

  @override
  String get miningRulesCoefCpFactor => '-';

  @override
  String get miningRulesCoefTrustFactor => 'プラットフォームのリスク管理';

  @override
  String get miningRulesCoefMiningDesc =>
      'Lv1=1.0 · Lv2=2.2 · Lv3=5.0 · Lv4=11 · Lv5=24';

  @override
  String miningRulesCoefPriceDesc(String currency1, String currency2) {
    return 'P0≤10$currency1では線形に増加 · P0>10$currency2では上限1.6に漸近';
  }

  @override
  String get miningRulesCoefHeatDesc =>
      'ヒート係数：キャラクターIP出演ドラマの完視聴、いいね、お気に入り、評価が多いほどヒートが高くなります';

  @override
  String get miningRulesCoefCpDesc => '現在未提供';

  @override
  String get miningRulesCoefTrustDesc => '初期値は1.0';

  @override
  String get miningRulesSection3Title => '3. お金を支給するが、上限がある';

  @override
  String get miningRulesSection3Desc =>
      '毎週、プラットフォーム全体で総報酬プール（週間ハードキャップ）が設定され、約2,115,385 STORYから始まり、毎週減少します（週 × 0.99572）。報酬分配は3つのケースに分かれます：';

  @override
  String get miningRulesSettleColCondition => '条件';

  @override
  String get miningRulesSettleColRule => '配分ルール';

  @override
  String get miningRulesSection3Case1Title => '全プラットフォームの名目生産量 ≤ 今週の賞金プール';

  @override
  String get miningRulesSection3Case1Desc =>
      '参加者は全員、記載された賞金を全額受け取ります。残りの賞金プールは支給されず、補充も行われません。';

  @override
  String get miningRulesSection3Case2Title => '全プラットフォームの想定生産量 &gt; 今週の賞金プール';

  @override
  String get miningRulesSection3Case2Desc =>
      '比例スケーリング：実際の獲得量 = 名目上の生産量 × 報酬プール ÷ プラットフォーム全体の生産量';

  @override
  String get miningRulesSection3Case3Title => '単一アドレスの報酬プールが報酬プール全体の5%を超えた場合';

  @override
  String get miningRulesSection3Case3Desc => '超過分は付与されず、返還されず、補填もされません';

  @override
  String get miningRulesSection3ExampleDesc =>
      '週間報酬プールが100,000 STORYと仮定：\nケースA: プラットフォームにあなただけがいて、1週間に134を生成 → 134を取得、残り99,866は分配されない\nケースB: プラットフォーム全体の出力が250,000で、全員が40%にスケーリング（100,000÷250,000）\nケースC: 誰かの比例報酬が6,000だが、1アドレスの上限が5,000 → 5,000のみ分配';

  @override
  String get miningRulesSection4Title => '4. 体力をしっかり管理してこそ、ずっと掘り続けられる';

  @override
  String get miningRulesTableStatus => 'ステータス';

  @override
  String get miningRulesTableStaminaChange => '体力の変化';

  @override
  String get miningRulesTableOutput => '成果';

  @override
  String get miningRulesStatusMining => '処理中（マイニング）';

  @override
  String get miningRulesStaminaMining => '1時間あたり -1';

  @override
  String get miningRulesOutputNormal => '通常の生産量';

  @override
  String get miningRulesStatusZeroStamina => '体力 = 0';

  @override
  String get miningRulesStaminaZeroStamina => 'もう変化しない';

  @override
  String get miningRulesOutputZero => '出力は 0 です';

  @override
  String get miningRulesStatusResting => '休憩に戻る';

  @override
  String get miningRulesStaminaResting => '1時間ごとに +1（自動回復）';

  @override
  String get miningRulesOutputPaused => '生産の一時停止';

  @override
  String get miningRulesStatusPaidRefill => '体力を回復する（有料）';

  @override
  String miningRulesStaminaPaidRefill(int staminaLimit) {
    return '瞬時に$staminaLimitまで回復';
  }

  @override
  String get miningRulesOutputRestored => '生産の回復';

  @override
  String get miningRulesSection4TipsTitle => '体力を回復させるための3つのポイント：';

  @override
  String get miningRulesSection4Tip1 =>
      'ワンクリックで満タンにするしかなく、10ポイントだけ購入することはできません';

  @override
  String get miningRulesSection4Tip2 =>
      '価格はランクのみで決まり、残りの体力は考慮されません。体力が0の状態で満タンにするのも、体力が100の状態で満タンにするのも、かかる費用は同じです。';

  @override
  String get miningRulesSection4Tip3 =>
      '0に近づくほど、補充がお得になります――同じ金額で、追加のマイニング時間を最大限に確保できるからです。';

  @override
  String get miningRulesSection4PriceTitle => '各ランクごとの追加料金：';

  @override
  String get miningRulesPriceTableTier => '地位';

  @override
  String get miningRulesPriceTableFullRefill => 'ワンクリックで満タン';

  @override
  String get miningRulesLv1 => 'Lv1 エキストラ';

  @override
  String get miningRulesLv2 => 'Lv2 脇役';

  @override
  String get miningRulesLv3 => 'Lv3 主人公';

  @override
  String get miningRulesLv4 => 'Lv4 スーパースター';

  @override
  String get miningRulesLv5 => 'Lv5 トップスター';

  @override
  String get gameActorLevelName1 => 'エキストラ';

  @override
  String get gameActorLevelName2 => '脇役';

  @override
  String get gameActorLevelName3 => '主役';

  @override
  String get gameActorLevelName4 => 'スーパースター';

  @override
  String get gameActorLevelName5 => 'トップティア';

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
  String get miningRulesSection5Title => '5. ランクアップして、もっと稼ぐ';

  @override
  String get miningRulesSection5Desc =>
      '同格のキャラクターカード3枚 + 合成費用 + 当該キャラクターの累計完視聴数達成 = レベルアップ1段階。レベルアップ後は採掘係数が急上昇し、1時間あたりの生産量が2倍、あるいは数倍になる。';

  @override
  String get miningRulesUpgradePathSubtitle => 'アップグレード経路';

  @override
  String get miningRulesUpgradeColPath => 'アップグレード経路';

  @override
  String get miningRulesUpgradeColHeat => '累計完視聴数条件';

  @override
  String get miningRulesUpgradeColFee => '合成手数料';

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
  String get miningRulesSummaryTitle => '一言でまとめると';

  @override
  String get miningRulesSummaryDesc =>
      '派遣 → 産出 → 体力チェック → 受け取り。体力が少なくなったら補充するか呼び戻して休ませましょう。ヒートはキャラクターのドラマ実績で上がり、アップグレードで産出が飛躍します。';

  @override
  String get playerNotInterested => '興味なし';

  @override
  String get playerNotInterestedDone => 'フィードバックを受け付けました。類似の動画を減らします';

  @override
  String get playerClearScreen => 'クリア画面';

  @override
  String get playerAutoPlay => '連続再生';

  @override
  String get playerReport => '報告';

  @override
  String get playerReportSuccess => '報告しました';

  @override
  String get commentReportSuccess => '送信しました。速やかに対応いたします';

  @override
  String get reportSuccessTitle => '送信完了。速やかに対応いたします';

  @override
  String get reportSuccessThanks => 'コミュニティの安全へのご協力ありがとうございます！';

  @override
  String get reportSuccessAlsoYouCan => '同時にできます';

  @override
  String get reportSuccessDone => '完了';

  @override
  String get reportReduceRecommend => 'おすすめを減らす';

  @override
  String get reportReduceRecommendDone => 'おすすめを減らしました';

  @override
  String get reportSuccessContentFallback => 'このコンテンツ';

  @override
  String get reportDescription => '報告の説明';

  @override
  String get reportDescriptionPlaceholder => '詳細を記述（オプション）';

  @override
  String get reportReasonPorn => 'ポルノとわいせつ';

  @override
  String get reportReasonIllegal => '違法または犯罪';

  @override
  String get reportReasonSensitive => 'センシティブコンテンツ';

  @override
  String get reportReasonGambling => '賭博または暴力';

  @override
  String get reportReasonMinors => '未成年者への有害';

  @override
  String get reportReasonCopyright => '著作権侵害';

  @override
  String get reportReasonQuality => '品質の問題';

  @override
  String get reportReasonNotLike => '好みではない';

  @override
  String get reportReasonOther => 'その他';

  @override
  String get gameUpgrade => 'アップグレード';

  @override
  String get gameUpgradeTitle => 'レベルアップグレード';

  @override
  String get gameUpgradeCurrentLevel => '現在のレベル';

  @override
  String get gameUpgradeTargetLevel => '目標レベル';

  @override
  String get gameUpgradeHeatThreshold => 'ドラマ累計完視聴数';

  @override
  String get gameUpgradeRequiredCount => '同IP同レベルロールを消費';

  @override
  String get gameUpgradeFee => 'アップグレード費用';

  @override
  String get gameUpgradeNextLevelReq => '次のレベルアップ条件';

  @override
  String get gameUpgradeBeforeAfter => 'アップグレード前後の比較';

  @override
  String get gameUpgradeSelectMaterialDesc => '消費する同IP同レベルロールを選択';

  @override
  String gameUpgradeMaterialCount(int current, int required) {
    return '$current/$required';
  }

  @override
  String gameUpgradeToLevel(int level, String levelName) {
    return 'Lv$level $levelNameへアップグレード';
  }

  @override
  String gameUpgradeSelectMaterialLabel(int current, int required) {
    return '材料を選択 ($current/$required)';
  }

  @override
  String gameUpgradeSelectMaterials(int count) {
    return '$count個の材料を選択してください';
  }

  @override
  String get gameUpgradeConfirm => 'アップグレード確認';

  @override
  String get gameUpgradeSuccess => 'アップグレード成功';

  @override
  String get gameUpgradeFailed => 'アップグレード失敗、もう一度お試しください';

  @override
  String get gameUpgradeInsufficientMaterials => '材料が不足しています';

  @override
  String get gameUpgradeNoMaterials => '同じIP・同じレベルの消費可能なロールがいません';

  @override
  String get creatorDramaStatusMinted => 'mint済み';

  @override
  String get creatorDramaStatusOffline => '取り下げ済み';

  @override
  String get creatorDramaStatusUnavailable => '一時的に利用できません';

  @override
  String get creatorMintDramaNft => 'ドラマNFTをmintする';

  @override
  String get creatorMintConfirmDesc =>
      'このドラマをオンチェーンNFTとしてmintすることを確認します。mint後、このドラマはSTORYマイニング報酬を生成します。';

  @override
  String get creatorMintFee => 'mint手数料';

  @override
  String creatorMintInsufficientUsdc(String currency1, String currency2) {
    return '$currency1残高が不足しています。オンチェーン発行には最低1 $currency2が必要です。';
  }

  @override
  String get creatorMintInvalidDramaId => 'ドラマIDが無効です';

  @override
  String get creatorMintInProgress => 'mint処理中です。しばらくお待ちください';

  @override
  String get creatorMintWalletNotReady =>
      'Solanaウォレットアドレスの準備ができていません。再度ログインしてください';

  @override
  String get creatorMintDigestEmpty => '発行署名データが空です。しばらくしてから再度お試しください。';

  @override
  String get creatorMintWalletMismatch =>
      'mintウォレットと現在のウォレットが一致しません。再度ログインしてください';

  @override
  String get creatorMintSuccess => 'mint成功！';

  @override
  String creatorMintDramaOnChain(String name) {
    return '「$name」のドラマNFTがオンチェーンにmintされました';
  }

  @override
  String creatorMintNftNumber(String id) {
    return 'NFT番号：$id';
  }

  @override
  String get creatorMintTxHash => 'トランザクションハッシュ：';

  @override
  String get gameSelectActor => '派遣するロールを選択';

  @override
  String get gameSelectActorDesc => '待機中のキャラクターを1人選択して派遣してください';

  @override
  String get agentV2SchedulePerformance => '出演';

  @override
  String get agentV2PerformAllTitle => '一括出演';

  @override
  String get agentV2PerformAllDescription => 'ギャラの高い順に空いている出演枠へ配置します';

  @override
  String get agentV2PerformAllFailed => '一括公演に失敗しました。もう一度お試しください';

  @override
  String get agentV2PerformAllSuccess => '一括出演に成功しました';

  @override
  String agentV2PerformAllDepletedResult(int successCount, int depletedCount) {
    return '$successCount人が出演成功、$depletedCount人は体力切れのため出演できません';
  }

  @override
  String get agentV2RestAllSuccess => '一括休憩に成功しました';

  @override
  String agentV2PerformAllCount(int count) {
    return '$count人のキャラクター';
  }

  @override
  String get agentV2TodoTitle => 'やること';

  @override
  String agentV2TodoVacancies(int count) {
    return 'あと $count 枠の出演枠が空いています';
  }

  @override
  String agentV2TodoStaminaDepleted(String name) {
    return '$name のスタミナが 0 になり、作業を停止しました';
  }

  @override
  String get agentV2TodoPerform => '出演する';

  @override
  String get agentV2TodoRefill => '補充する';

  @override
  String get agentV2TodoHealthy => '出演正常 · スタミナ十分';

  @override
  String get agentV2CandidateActorsTitle => '候補ロール';

  @override
  String get agentV2CandidateActorsDescription => '休息中のロールは1時間に体力を1回復します';

  @override
  String get agentV2UpgradeableActorsTitle => '役をアップグレード';

  @override
  String get agentV2UpgradeableActorsEmpty => 'アップグレード可能な役はありません';

  @override
  String get agentV2NoActors => 'ロールがいません';

  @override
  String get agentV2UpgradeNow => '今すぐアップグレード';

  @override
  String get agentV2UpgradeCompletion => '完視聴';

  @override
  String get agentV2UpgradeMaterials => '役';

  @override
  String agentV2UpgradeRequirementsTitle(String name) {
    return '$nameをアップグレード';
  }

  @override
  String agentV2UpgradeCompletionRemaining(int count) {
    return 'あと$count回の完視聴が必要です';
  }

  @override
  String get agentV2UpgradeCompletionHint =>
      'このキャラクターが出演するドラマを視聴するか、新しいドラマを制作すると完視聴数が増えます';

  @override
  String get agentV2UpgradeWatchDramas => '出演ドラマを見る';

  @override
  String get agentV2UpgradeCreateDrama => 'ドラマを制作する';

  @override
  String agentV2UpgradeMaterialsRemaining(int count) {
    return '同じIP・同じレベルの役があと$count枚必要です';
  }

  @override
  String agentV2UpgradeMaterialsHint(String name) {
    return 'キャラクターのプロフィールで「$name」をさらに契約してください';
  }

  @override
  String get agentV2UpgradeGetActors => '役を獲得する';

  @override
  String agentV2UpgradeActorsSyncing(int count) {
    return '新しいキャラクター$count件を同期中です。アップグレード条件を更新しました';
  }

  @override
  String get agentV2UpgradeConfirmSelectMaterials => '消費する同IP・同レベルのキャラクターを選択';

  @override
  String get agentV2UpgradeConfirmSalaryLabel => 'ギャラ';

  @override
  String get agentV2SalaryDetailTitle => 'キャラクターギャラ';

  @override
  String get agentV2SalaryHourly => '時間あたりのギャラ';

  @override
  String get agentV2SalaryUnit => 'STORY / 時間';

  @override
  String get agentV2SalaryFormula =>
      'キャラクターギャラ = IPギャラ × ギャラ係数 × CP係数 × Trust2';

  @override
  String get agentV2SalaryFormulaLv1 => 'Lv.1 キャラクターのギャラ = 価格係数 × ヒート係数';

  @override
  String agentV2SalaryFormulaLevel(int level) {
    return 'Lv.$level ギャラ = Lv.1 ギャラ × ギャラ係数';
  }

  @override
  String get agentV2SalaryLv1Pay => 'Lv.1 ギャラ';

  @override
  String get agentV2SalaryCoefficient => 'ギャラ係数';

  @override
  String agentV2SalaryCoefficientWithLevel(int level, String roleName) {
    return 'ギャラ係数（Lv.$level $roleName）';
  }

  @override
  String get agentV2SalaryCpCoefficient => 'CP係数';

  @override
  String get agentV2PerformanceConfirmDescription =>
      'このキャラクターは出演中に自動的にギャラを得ます。出演中は1時間ごとに体力を1ポイント消費し、体力が尽きると収入の発生は停止します。';

  @override
  String get agentV2PerformanceConfirmTitle => '出演を手配';

  @override
  String get agentV2PerformanceZeroFeePrefix => 'このキャラクターのIPは現在';

  @override
  String get agentV2PerformanceZeroFeeHighlight => '出演料は0';

  @override
  String get agentV2PerformanceZeroFeeSuffix =>
      '、この公演では収益は得られません。また、公演中は1時間ごとにスタミナが1ポイント消費されますが、それでも続行しますか？';

  @override
  String get agentV2PerformanceScheduledSuccess => '公演を手配しました';

  @override
  String get agentV2PerformanceSlotsFull => '出演枠が満杯です（最大5枠）';

  @override
  String get gameDeployStaminaDepleted => '体力が尽きています。補充してから出演してください';

  @override
  String get agentMoreRules => 'ルール';

  @override
  String get agentMoreSalaryAndPool => 'ギャラと報酬プール';

  @override
  String get agentV2WeeklySalaryTitle => 'レベルアップ · 出演 · ギャラ獲得';

  @override
  String get agentV2WeeklySalaryLabel => '今週のギャラ';

  @override
  String get gameDeployConfirmDesc =>
      'このキャラクターは自動的にステーキングマイニングを行い、継続的にSTORY報酬を生み出します。注意：毎正時に体力を1ポイント消費し、体力がなくなると報酬の獲得が停止します。';

  @override
  String get gameRecallConfirm => '召還を確認';

  @override
  String get gameRecallDesc => 'このキャラクターを召還するとドラマの生産報酬が一時停止しますが、現在の体力には影響しません。';

  @override
  String get actorStatCompletionTitle => '完視聴';

  @override
  String get actorStatCompletionDesc => 'このキャラクターが出演した全ドラマの完視聴回数の合計';

  @override
  String get actorStatHeatTitle => 'ヒート';

  @override
  String get actorStatHeatDesc => 'このキャラクターIPが出演するすべてのショートドラマの直近30日間のヒート合計';

  @override
  String get actorStatIpPowerTitle => 'IPギャラ';

  @override
  String get actorStatIpPowerDesc => 'IPギャラ = 価格係数 × ヒート係数 × Trust1';

  @override
  String get dramaFavoriteLabel => 'お気に入り';

  @override
  String get dramaRatingLabel => '評価';

  @override
  String get dramaUnnamed => '無題';

  @override
  String get videoNotReady => '動画がまだ準備ができていません。しばらくしてからお試しください';

  @override
  String get inviteDirectSubordinates => '招待済みユーザー';

  @override
  String inviteTotalCount(int count) {
    return '合計 $count 人';
  }

  @override
  String get inviteTotalLabel => '総人数';

  @override
  String get inviteActiveLabel => '有効ユーザー';

  @override
  String get invitePendingLabel => 'アクティベーション待ち';

  @override
  String get inviteEmpty => '下位ユーザーはまだいません';

  @override
  String inviteRegisteredAt(String date) {
    return '$date に登録';
  }

  @override
  String get gameUpgradeMaxLevel => '最大レベルに達しました';

  @override
  String get listNoMoreData => 'これ以上のデータはありません';

  @override
  String get iapSheetTitle => 'ポイントを購入';

  @override
  String get iapSheetSubtitle => 'ポイントはキャラクター契約などのアプリ内サービスに使用します';

  @override
  String get iapBalance => '残高';

  @override
  String get iapConfirmPurchase => '購入を確認';

  @override
  String get iapPurchaseSuccess => '購入しました';

  @override
  String get iapPurchaseFailed => '購入に失敗しました。後でもう一度お試しください';

  @override
  String get iapPurchaseFailedTitle => '購入失敗';

  @override
  String get iapCrediting => '入金処理中です。お待ちください';

  @override
  String get iapNoProducts => '購入できる商品がありません';

  @override
  String get iapSuccessConfirm => 'OK';

  @override
  String iapGainedPoints(String value) {
    return '+$value';
  }

  @override
  String iapPointsCount(int count) {
    return '$count ポイント';
  }

  @override
  String get gameBatchRefillTransactionTooLarge =>
      '一括体力回復トランザクションが大きすぎます。俳優の人数を減らして再試行してください。';

  @override
  String get agentV2RefillTitle => '体力を補充';

  @override
  String get agentV2RefillCost => '費用';

  @override
  String get agentV2RefillActorButton => 'このキャラクター';

  @override
  String get agentV2RefillAllActors => '出演中の全キャラクターに補充';

  @override
  String agentV2RefillActorCount(int count) {
    return '$count人';
  }

  @override
  String get agentV2RefillAllButton => 'すべて補充';

  @override
  String get agentV2RefillOr => 'または';

  @override
  String get agentV2RestAll => '全員休憩';

  @override
  String agentV2RestActorCount(int count) {
    return '$count人';
  }

  @override
  String get salaryPoolRateUnit => 'STORY / 時間';

  @override
  String get salaryPoolDecayInfo => '週間減衰係数 ×0.99572';

  @override
  String get salaryPoolStakeLabel => '出演報酬プール（75%）';

  @override
  String get salaryPoolInviteLabel => '招待報酬プール（25%）';

  @override
  String get salaryPoolRule1Title => '全体の名目産出量 ≤ 週間ハードキャップ：';

  @override
  String get salaryPoolRule2Title => '全体の名目産出量 > 週間ハードキャップ：';

  @override
  String get salaryPoolRule2Body =>
      '実際の支給額 = ユーザーの名目産出量 ×（週間ハードキャップ ÷ 全体の名目産出量）';

  @override
  String get agentV3WeeklySalary => '今週のギャラ';

  @override
  String get agentV3PerformAll => '一括出演';

  @override
  String get agentV3RestAll => '一括休憩';

  @override
  String get agentV3RestAllDescription => '出演中のキャラクターを全員呼び戻し、体力消費と報酬獲得を停止します';

  @override
  String get agentV3RefillAll => '一括補充';

  @override
  String get agentV3RefillAllDescription => '出演中のキャラクターの体力を全回復します';

  @override
  String get agentV3RefillCost => '消費';

  @override
  String get agentV3RefillNoActors => '体力補充が必要なキャラクターはいません';

  @override
  String get agentV3SignActor => 'キャラクター契約';

  @override
  String get agentV3Todo => 'やること';

  @override
  String get agentV3Upgrade => 'アップグレード';

  @override
  String agentV3UpgradeMaterialHint(int count) {
    return '同一IP・同一レベルのキャラクターを$count体消費する必要があります';
  }

  @override
  String get agentV3Waiting => '待機';

  @override
  String get agentV3WaitingActorsTitle => '待機中のキャラクター';

  @override
  String get agentV3WaitingActorsDescription => '休憩中のキャラクターは1時間ごとにスタミナを1回復します';

  @override
  String get agentV3Recycle => '回収';

  @override
  String get agentV3RecycleActorsTitle => 'キャラクター回収';

  @override
  String get agentV3RecyclePerforming => '出演中';

  @override
  String get agentV3RecycleReceive => '受け取るもの';

  @override
  String get agentV3RecyclePermanentWarning => 'キャラクターは永久に破棄され、復元できません';

  @override
  String get agentV3RecycleConfirm => '破棄を確認';

  @override
  String get agentV3RecycleConfirmAgain => 'もう一度タップして破棄';

  @override
  String get agentV3RecycleSubmitted => 'キャラクターの回収に成功しました';

  @override
  String get agentV3RecycleEstimateUnavailable => '回収見積もりを取得できません。再試行してください';

  @override
  String get agentV3EnergyPack => 'スタミナ補給パック';

  @override
  String get agentV3EnergyPackDescription =>
      'キャラクターのスタミナを全回復し、キャラクターレベルに応じて消費されます。';

  @override
  String get agentV3TrainingManual => 'トレーニングマニュアル';

  @override
  String get agentV3TrainingManualDescription =>
      'キャラクターのアップグレード素材。アップグレード時にキャラクターレベルに応じて消費されます。';

  @override
  String get agentV3PurchaseButton => '購入';

  @override
  String agentV3PurchaseWalletBalance(String balance, String currency) {
    return '残高 $balance $currency';
  }

  @override
  String agentV3PurchaseTitle(String item) {
    return '$itemを購入';
  }

  @override
  String get agentV3PurchaseUnitPrice => '単価';

  @override
  String get agentV3PurchaseQuantity => '数量';

  @override
  String get agentV3PurchaseTotal => '合計';

  @override
  String get agentV3PurchaseConfirm => '支払いを確認';

  @override
  String get agentV3PurchaseUnavailable => '現在の環境ではアイテムを購入できません';

  @override
  String get agentV3PurchaseConfigUnavailable =>
      'アイテムの価格を取得できません。後でもう一度お試しください';

  @override
  String get agentV3PurchaseSubmitted => '購入に成功しました。アイテムバッグ（エージェントページ）に追加されました';

  @override
  String get agentV3PurchaseCreditPending =>
      '体力パックはまだ付与中です。しばらくしてからもう一度お試しください';

  @override
  String get agentV3PurchaseCrediting => 'オンチェーン確認・付与中';

  @override
  String agentV3PurchaseBalance(String count) {
    return '現在の所持数：$count';
  }

  @override
  String get agentV3RefillTitle => 'スタミナを満タンにする';

  @override
  String agentV3RefillLevelCost(String level) {
    return 'Lv.$level 消費';
  }

  @override
  String get agentV3RefillAvailable => '利用可能';

  @override
  String get agentV3RefillUse => '使用';

  @override
  String get agentV3RefillSuccess => 'スタミナを満タンにしました';

  @override
  String agentV3RefillAllSuccess(int actorCount, String packCount) {
    return '$actorCount人のキャラクターの体力を補充しました（補給パックを$packCount個消費）';
  }

  @override
  String get agentV3RefillConfigUnavailable => 'スタミナパック消費設定を利用できません';

  @override
  String get agentV3RefillInsufficient => 'スタミナパックが不足しています';
}
