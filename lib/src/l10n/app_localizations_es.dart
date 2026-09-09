// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'StoryFun';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonNoData => 'Sin datos';

  @override
  String get commonNo => 'No';

  @override
  String get commonYes => 'Sí';

  @override
  String get publishDrama => 'Publicar Drama';

  @override
  String get publishVideo => 'Publicar Video';

  @override
  String get publishVideoUploadTitle => 'Subir archivo de vídeo';

  @override
  String get publishVideoFileHint =>
      'Admite mp4, flv, wmv, mkv, avi, mov y webm. Máximo 2GB';

  @override
  String get publishVideoChooseFile => 'Elegir archivo';

  @override
  String get publishVideoChangeFile => 'Cambiar archivo';

  @override
  String get publishVideoChooseSource => 'Elegir origen del vídeo';

  @override
  String get publishVideoChooseFromGallery => 'Elegir de la galería';

  @override
  String get publishVideoChooseFromFiles => 'Elegir de archivos';

  @override
  String get publishVideoPreparing => 'Preparando vídeo…';

  @override
  String get publishVideoCoverTitle => 'Portada del vídeo';

  @override
  String get publishVideoChangeCover => 'Cambiar portada';

  @override
  String get publishVideoCoverHint => 'JPG/PNG, máximo 5MB';

  @override
  String get publishVideoDescriptionLabel => 'Descripción';

  @override
  String get publishVideoRequired => '(Obligatorio)';

  @override
  String get publishVideoDescriptionHint =>
      'Añade una descripción (máximo 200 caracteres)';

  @override
  String get publishVideoSaveDraft => 'Guardar borrador';

  @override
  String get publishVideoDraftEditModeNotSupported =>
      'No se puede guardar el borrador en modo edición';

  @override
  String get publishVideoDraftNothingToSave => 'No hay nada que guardar';

  @override
  String get publishVideoNext => 'Siguiente';

  @override
  String get publishVideoCoverCropTitle => 'Recortar portada del vídeo';

  @override
  String get publishVideoVideoTooLarge =>
      'El archivo de vídeo no puede superar 2GB';

  @override
  String get publishVideoVideoPickFailed =>
      'No se pudo seleccionar el vídeo. Inténtalo de nuevo';

  @override
  String get publishVideoInsufficientStorage =>
      'No hay suficiente espacio en el dispositivo para preparar este vídeo';

  @override
  String get publishVideoPermissionDenied =>
      'No se pudo acceder al vídeo. Revisa los permisos de fotos o archivos';

  @override
  String get publishVideoSourceUnavailable =>
      'Este vídeo no está disponible temporalmente. Descarga el archivo de la nube e inténtalo de nuevo';

  @override
  String get publishVideoPrepareFailed =>
      'No se pudo preparar el vídeo. Inténtalo de nuevo o elígelo desde Archivos';

  @override
  String get publishVideoMetadataUnavailable =>
      'No se pudo leer el vídeo. Elige otro archivo';

  @override
  String get publishVideoCoverTooLarge => 'La portada no puede superar 5MB';

  @override
  String get publishVideoCoverUnsupportedFormat =>
      'Solo se admiten imágenes JPG/PNG';

  @override
  String get publishVideoCoverPickFailed =>
      'No se pudo seleccionar la portada. Inténtalo de nuevo';

  @override
  String get publishVideoUploadSessionFailed =>
      'No se pudo crear la sesión de carga';

  @override
  String get publishVideoPublishedSuccess => 'Vídeo publicado';

  @override
  String get publishVideoUpdatedSuccess => 'Vídeo actualizado';

  @override
  String get publishActorIp => 'Lanzar IP';

  @override
  String get commonConfirm => 'Confirmar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotice => 'Aviso';

  @override
  String get commonRetry => 'Reintentar';

  @override
  String get publicProfileLikedEmpty => 'Aún no hay dramas con me gusta';

  @override
  String get profileTabDramas => 'Dramas';

  @override
  String get profileTabWorks => 'Obras';

  @override
  String get profileTabActorIp => 'IP de personaje';

  @override
  String dramaUnlockConfirmLabel(String price, String currency) {
    return 'Desbloquear por $price $currency';
  }

  @override
  String dramaAllEpisodes(int count) {
    return '$count episodios';
  }

  @override
  String dramaAllEpisodesFull(Object count) {
    return 'Todos los $count episodios';
  }

  @override
  String get dramaLoading => 'Cargando dramas destacados...';

  @override
  String get dramaEmpty => 'Por el momento no hay miniseries';

  @override
  String get dramaRefresh => 'Actualizar';

  @override
  String get navTheater => 'Teatro';

  @override
  String get navHome => 'Inicio';

  @override
  String get theaterTabShortDrama => 'Drama';

  @override
  String get theaterTabRecommend => 'Para Ti';

  @override
  String get playerWatchFullDrama => 'Ver drama completo';

  @override
  String get playerStoryPerHourUnit => 'STORY/h';

  @override
  String get navNft => 'Mercado IP';

  @override
  String get navNftIp => 'IP de personajes';

  @override
  String watchFullDramaEpisodes(int count) {
    return 'Ver Drama · $count Ep total';
  }

  @override
  String get navCreate => 'Creación';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navMy => 'Gestor';

  @override
  String get aboutTitle => 'Sobre nosotros';

  @override
  String get aboutVision => 'IA · Web3 · Protocolos';

  @override
  String get aboutVisionDesc =>
      'Tres fuerzas impulsoras que transforman la narrativa de una experiencia pasiva en una creación activa';

  @override
  String get aboutAiDesc =>
      'Tus ideas se convierten automáticamente en historias';

  @override
  String get aboutWeb3Desc => 'Tus creaciones siempre te pertenecerán';

  @override
  String get aboutProtocolDesc =>
      'Tu historia puede prolongarse indefinidamente';

  @override
  String get aboutIdentityTitle => 'Tu identidad narrativa';

  @override
  String get aboutIdentityDesc =>
      'Tú mismo eres un universo narrativo en desarrollo';

  @override
  String get aboutIdentityCreator => 'Creador';

  @override
  String get aboutIdentityCreatorDesc =>
      'Escribir activamente la propia historia';

  @override
  String get aboutIdentityWitness => 'Testigo';

  @override
  String get aboutIdentityWitnessDesc =>
      'Participar y validar las historias de los demás';

  @override
  String get aboutIdentityCoCreator => 'Colaborador';

  @override
  String get aboutIdentityCoCreatorDesc =>
      'Acceder a la estructura narrativa y reescribirla';

  @override
  String get aboutIdentitySpreader => 'difusor';

  @override
  String get aboutIdentitySpreaderDesc => 'Difunde la historia que te mereces';

  @override
  String get aboutTokenomicsTitle => 'STORY: Token de narratividad';

  @override
  String get aboutTokenomicsDesc =>
      'Conviértete en coproductor de dramas cortos de IA, remodelando la distribución de beneficios en la industria del cine y la televisión.';

  @override
  String get aboutTokenomicsGov => 'derecho de administración';

  @override
  String get aboutTokenomicsGovDesc =>
      'Vota para decidir el tema y el rumbo del próximo cortometraje de IA';

  @override
  String get aboutTokenomicsRevenue => 'derecho a percibir rendimientos';

  @override
  String get aboutTokenomicsRevenueDesc =>
      'Beneficios derivados de las suscripciones a plataformas de intercambio, la concesión de derechos de autor y la venta de productos derivados';

  @override
  String get aboutTokenomicsAccess => 'derechos de acceso';

  @override
  String get aboutTokenomicsAccessDesc =>
      'Ve los últimos episodios antes que nadie y accede a contenido exclusivo';

  @override
  String get aboutStakingTitle =>
      'Participación en los beneficios por pignoración';

  @override
  String get aboutStakingDesc =>
      'Drama NFT · Personaje NFT · STORY → Apuesta para ganar dividendos';

  @override
  String get aboutStakingDrama => 'Apuesta Drama NFT';

  @override
  String get aboutStakingDramaDesc =>
      'Creador de miniseries · Obtener una participación en los ingresos';

  @override
  String get aboutStakingActor => 'Apuesta Personaje NFT';

  @override
  String get aboutStakingActorDesc =>
      'Roles que participan en sketches · Obtener una parte de los ingresos';

  @override
  String get aboutStakingStory => 'Apuesta STORY';

  @override
  String get aboutStakingStoryDesc =>
      'Pignorar en Short Videos · Reparto de ingresos';

  @override
  String get aboutHeroTitle => 'Crea Tu Propia Historia';

  @override
  String get aboutHeroDesc =>
      'Tu vida no es un guión que experimentar, sino una narrativa que estás escribiendo';

  @override
  String get loginTitle => 'Inicio de sesión con correo';

  @override
  String get loginSubtitle =>
      'Inicia sesión con OTP de correo Privy, creando automáticamente una wallet embebida de Solana.';

  @override
  String get loginPlaceholder => 'Ingresa tu dirección de correo electrónico';

  @override
  String get loginEmailHintFormat => 'tu@correo.com';

  @override
  String get loginVerificationFailed => 'Verificación fallida';

  @override
  String get loginNeedCodeFirst => 'Solicita primero un código de verificación';

  @override
  String get loginCreateWalletFailed => 'No se pudo crear la billetera';

  @override
  String get loginGetTokenFailed => 'No se pudo obtener el token de acceso';

  @override
  String get loginPrivyUnavailable =>
      'El servicio de inicio de sesión no está disponible. Reinicia la app e inténtalo de nuevo';

  @override
  String get loginSendCodeFailed =>
      'No se pudo enviar el código de verificación. Inténtalo de nuevo más tarde';

  @override
  String get loginTooManyRequests =>
      'Demasiadas solicitudes. Espera un momento e inténtalo de nuevo';

  @override
  String get loginVerificationSuccessful => 'Verificación exitosa';

  @override
  String get loginSendCode => 'Obtener código';

  @override
  String get loginSendingCode => 'Enviando...';

  @override
  String get loginCodePlaceholder =>
      'Ingresa el código de verificación de 6 dígitos';

  @override
  String get loginSubmit => 'Iniciar sesión';

  @override
  String get loginSubmitting => 'Iniciando sesión...';

  @override
  String get loginEmailRequired => 'Por favor ingresa tu correo electrónico';

  @override
  String get loginCodeRequired => 'Por favor ingresa el código de verificación';

  @override
  String get loginSuccess => 'Inicio de sesión exitoso';

  @override
  String get loginErrorPrefix => 'Error de inicio de sesión: ';

  @override
  String loginCodeSent(String email) {
    return 'El código de verificación ha sido enviado a $email';
  }

  @override
  String get loginEmailLabel => 'Correo electrónico';

  @override
  String get loginCodeLabel => 'Código de verificación';

  @override
  String get loginVerifying => 'Verificando, espere por favor...';

  @override
  String get loginVerifyAndSubmit => 'Verificar e iniciar sesión';

  @override
  String get loginChangeEmail => 'Cambiar correo electrónico';

  @override
  String get loginNotNow => 'Ahora no';

  @override
  String get loginInvalidEmail =>
      'Por favor ingresa un correo electrónico válido';

  @override
  String get profileTitle => 'Agente';

  @override
  String get profileNotLoggedIn => 'No has iniciado sesión';

  @override
  String get profileClickLogin => 'Iniciar sesión / Registrarse';

  @override
  String get profileMyWallet => 'Mi billetera';

  @override
  String get profileWallet => 'Billetera';

  @override
  String get profileTradeStory => 'Operar STORY';

  @override
  String get profileWalletCreating => 'Creando...';

  @override
  String get walletNetworkSolana => 'Solana';

  @override
  String get walletNetworkEvm => 'EVM';

  @override
  String get profileEarnings => 'Ingresos';

  @override
  String get profileMyNft => 'Mis NFTs';

  @override
  String get profileMyFavorites => 'Mis favoritos';

  @override
  String get profileWatchHistory => 'Historial de reproducción';

  @override
  String get profileCreatorCatalog => 'Creadores';

  @override
  String get profileIdentityAuth => 'Verificación de identidad';

  @override
  String get profileAccountSecurity => 'Seguridad de la cuenta';

  @override
  String get profileLanguage => 'Idioma';

  @override
  String get profileAboutUs => 'Sobre nosotros';

  @override
  String get profileHelpFeedback => 'Ayuda y comentarios';

  @override
  String get profileLogout => 'Cerrar sesión';

  @override
  String get profileLogoutConfirm => '¿Estás seguro de cerrar sesión?';

  @override
  String get profileLogoutSuccess => 'Sesión cerrada exitosamente';

  @override
  String get mainPressBackAgainToExit => 'Pulsa Atrás de nuevo para salir';

  @override
  String get languageSelectTitle => 'Seleccionar idioma';

  @override
  String get languageChinese => 'Chino simplificado';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get searchTitle => 'Buscar';

  @override
  String get searchHint => 'Buscar dramas, obras, roles, usuarios...';

  @override
  String get searchEmpty => 'Sin contenido relacionado';

  @override
  String get searchNoData => 'Sin contenido relacionado';

  @override
  String get searchPlaceholder => 'Buscar dramas, obras, roles, usuarios...';

  @override
  String get theaterSearchPlaceholder =>
      'Buscar dramas, obras, roles, usuarios...';

  @override
  String get searchHistory => 'Búsquedas recientes';

  @override
  String get searchClear => 'Borrar historial';

  @override
  String get searchAction => 'Buscar';

  @override
  String get searchHistoryCleared => 'Historial de búsqueda borrado';

  @override
  String get searchKeywordTooShort => 'Introduce al menos 2 caracteres';

  @override
  String get searchTabDramas => 'Dramas';

  @override
  String get searchTabWorks => 'Obras';

  @override
  String get searchTabActors => 'IP de personaje';

  @override
  String get searchTabUsers => 'Usuarios';

  @override
  String searchEpisodeNo(int episodeNo) {
    return 'Ep. $episodeNo';
  }

  @override
  String searchMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String searchHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String searchDaysAgo(int count) {
    return 'hace $count días';
  }

  @override
  String searchDramasCount(int count) {
    return 'Dramas ($count)';
  }

  @override
  String searchActorsCount(int count) {
    return 'Roles ($count)';
  }

  @override
  String searchDramaEpisodesWithCast(int count, String actors) {
    return '$count episodios | Reparto: $actors';
  }

  @override
  String get nftTitle => 'Plaza de Roles NFT';

  @override
  String get nftLoading => 'Cargando IP de personajes...';

  @override
  String get nftEmpty => 'No hay IP de personajes';

  @override
  String get nftRefresh => 'Actualizar';

  @override
  String nftIdPrefix(String id) {
    return 'ID: #$id';
  }

  @override
  String get nftRarity => 'Rareza';

  @override
  String get nftStatusStaked => 'Pignorado';

  @override
  String get nftStatusIdle => 'Inactivo';

  @override
  String get nftPrice => 'Precio';

  @override
  String get dramaDetailTitle => 'Detalle del drama';

  @override
  String get dramaDetailLoading => 'Cargando…';

  @override
  String get dramaDetailRetry => 'Inténtalo de nuevo';

  @override
  String get dramaDetailEpisodeList => 'Lista de series';

  @override
  String get dramaDetailSynopsis => 'Sinopsis';

  @override
  String get dramaDetailExpand => 'Ver más';

  @override
  String get dramaDetailCollapse => 'Cerrar';

  @override
  String get dramaDetailTabIntro => 'Descripción';

  @override
  String get dramaDetailTabEpisodes => 'Antología';

  @override
  String get dramaDetailTabComments => 'Comentarios';

  @override
  String get dramaDetailTabRoles => 'IP del personaje';

  @override
  String get dramaDetailSignMoreCharacterIps =>
      'Contratar más IP de personajes';

  @override
  String get dramaDetailCharactersEmpty =>
      'Aún no hay IP de personajes vinculadas';

  @override
  String dramaDetailRoleSalary(String amount) {
    return 'Salario $amount';
  }

  @override
  String dramaDetailRoleSalaryPerHour(String amount) {
    return 'Salario $amount STORY/h';
  }

  @override
  String get dramaDetailRoleUnbound => 'Sin vincular';

  @override
  String get dramaCastActorsTitle => 'IP de personajes del reparto';

  @override
  String dramaDetailCompletion(String count) {
    return '$count reproducciones completas';
  }

  @override
  String dramaDetailHeat(String count) {
    return '$count popularidad';
  }

  @override
  String dramaDetailTotalEpisodes(int count) {
    return '$count episodios';
  }

  @override
  String get dramaDetailRatingTitle => 'Valorar la obra';

  @override
  String get dramaDetailWantToRate => 'Valorar';

  @override
  String get dramaDetailNotRated => 'Sin valorar';

  @override
  String get dramaDetailCompletionLabel => 'Reproducciones completas';

  @override
  String get dramaDetailHeatLabel => 'Popularidad';

  @override
  String get dramaDetailSynopsisLead => 'Sinopsis: ';

  @override
  String get dramaDetailRatingEmpty => 'Tu valoración: --';

  @override
  String dramaDetailRatingValue(int rating) {
    return 'Tu valoración: $rating';
  }

  @override
  String get dramaDetailRatingConfirm => 'Confirmar valoración';

  @override
  String dramaDetailRatingSuccess(int rating) {
    return 'Valoración exitosa: ¡$rating estrellas!';
  }

  @override
  String get dramaDetailSelectEpisodeHint =>
      'Selecciona un episodio para iniciar la reproducción';

  @override
  String get dramaFavorited => 'Añadido a favoritos';

  @override
  String get dramaUnfavorited => 'Eliminado de favoritos';

  @override
  String get dramaLiked => 'Te gusta';

  @override
  String get dramaUnliked => 'Ya no te gusta';

  @override
  String get playerFollowed => 'Siguiendo';

  @override
  String get playerUnfollowed => 'Dejaste de seguir';

  @override
  String get errorNetwork =>
      'Error de red, por favor intenta de nuevo más tarde';

  @override
  String get errorTimeout =>
      'La solicitud ha expirado, por favor intenta de nuevo';

  @override
  String get errorParse => 'Error al analizar los datos de respuesta';

  @override
  String get errorUnauthorized => 'Por favor inicia sesión primero';

  @override
  String get authSessionExpired =>
      'La sesión ha expirado. Vuelve a iniciar sesión';

  @override
  String get errorNotFound => 'Recurso no encontrado';

  @override
  String get iapOrderInFlight =>
      'Tienes un pedido sin terminar para este artículo, inténtalo más tarde';

  @override
  String get errorOperationFailed => 'Operación fallida';

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
      'ID de personaje no válido. Actualiza la página e inténtalo de nuevo.';

  @override
  String get errorInvalidRoleNftAssetId =>
      'assetId de Personaje NFT no válido. Actualiza la página e inténtalo de nuevo.';

  @override
  String get errorInvalidRoleCollectionAssetId =>
      'assetId de colección de personaje no válido. Actualiza la página e inténtalo de nuevo.';

  @override
  String get roleNftLabelUnknown => 'RoleNFT#Unknown';

  @override
  String roleNftLabel(String prefix) {
    return 'RoleNFT#$prefix';
  }

  @override
  String errorBusiness(String message) {
    return 'Operación fallida: $message';
  }

  @override
  String errorUnknown(String message) {
    return 'Ocurrió un error desconocido: $message';
  }

  @override
  String errorNotSupported(String message) {
    return 'Operación no soportada: $message';
  }

  @override
  String get playerEpisodeSelect => 'Antología';

  @override
  String get playerPlayFailed => 'Reproducción fallida';

  @override
  String get playerDramaUnavailable => 'Este drama no está disponible';

  @override
  String get playerContentUnavailable =>
      'Este contenido no está publicado o ya no está disponible';

  @override
  String get creatorWorkNotFound => 'La obra no existe y no se puede ver';

  @override
  String get creatorWorkNotPublished =>
      'La obra no está publicada y todavía no se puede ver';

  @override
  String get creatorOfflineReasonUnavailable =>
      'No hay motivo de retirada disponible';

  @override
  String get playerTapRetry => 'Toca para reintentar';

  @override
  String playerEpisodeTotal(int count) {
    return '$count episodios en total';
  }

  @override
  String playerEpisodeLabel(int episodeNo) {
    return 'Episodio $episodeNo';
  }

  @override
  String get playerLike => 'Me gusta';

  @override
  String get playerComment => 'Comentarios';

  @override
  String get playerFavorite => 'Añadir a favoritos';

  @override
  String get playerShare => 'Compartir';

  @override
  String playerShareDramaEpisode(
    String title,
    int episodeNo,
    String description,
    String url,
  ) {
    return '$title | Ep. $episodeNo: $description $url. Mira hermosos dramas cortos de IA en StoryFun.';
  }

  @override
  String playerShareDramaEpisodeNoDesc(
    String title,
    int episodeNo,
    String url,
  ) {
    return '$title | Ep. $episodeNo $url. Mira hermosos dramas cortos de IA en StoryFun.';
  }

  @override
  String playerShareShortVideo(String description, String url) {
    return '$description $url. Mira hermosos videos cortos en StoryFun.';
  }

  @override
  String playerShareShortVideoNoDesc(String url) {
    return '$url. Mira hermosos videos cortos en StoryFun.';
  }

  @override
  String playerShareDrama(String title, String url) {
    return '$title $url. Mira hermosos dramas cortos de IA en StoryFun.';
  }

  @override
  String playerShareDramaNoTitle(String url) {
    return '$url. Mira hermosos dramas cortos de IA en StoryFun.';
  }

  @override
  String playerRatingLabel(String rating) {
    return '$rating pts';
  }

  @override
  String get loginOrSignUp => 'Iniciar sesión o Registrarse';

  @override
  String get loginEnterCode => 'Ingresa el código de confirmación';

  @override
  String loginCheckEmailDesc(String email) {
    return 'Por favor revisa $email para un correo de privy.io e ingresa tu código a continuación.';
  }

  @override
  String loginResendCountdown(int seconds) {
    return 'Reenviar código en ${seconds}s';
  }

  @override
  String get loginResendBtn => 'Reenviar';

  @override
  String get loginProtectedByPrivy => 'Protegido por Privy';

  @override
  String get loginAgreeLead => 'Acepto los';

  @override
  String get loginAgreeAnd => 'y la';

  @override
  String get loginAgreeConfirmLead => 'Al pulsar Confirmar, aceptas los';

  @override
  String get loginAgreeRequired =>
      'Primero acepta los Términos de servicio y la Política de privacidad';

  @override
  String get deletingAccountPending => 'Cuenta pendiente de eliminación';

  @override
  String get deletingAccountCancelDeletion => 'Cancelar eliminación de cuenta';

  @override
  String get deletingAccountGoBack => 'Volver';

  @override
  String get drawerEmailAccount => 'Cuenta de correo electrónico';

  @override
  String get drawerClickToLogin => 'Toca para iniciar sesión';

  @override
  String get drawerBuyStory => 'Operar STORY';

  @override
  String get drawerDeposit => 'Recargar';

  @override
  String get drawerWithdraw => 'Retirar fondos';

  @override
  String get drawerNotifications => 'Notificaciones';

  @override
  String get drawerNoNotifications => 'No hay notificaciones';

  @override
  String get notificationTabSystem => 'Sistema';

  @override
  String get notificationTabInteraction => 'Actividad';

  @override
  String get notificationTagIpSign => 'Contrato de IP de personaje';

  @override
  String get notificationTagRoleManagement => 'Gestión de personaje';

  @override
  String get notificationTagShowRevenue => 'Ingresos de actuación';

  @override
  String get notificationTagLike => 'Me gusta';

  @override
  String get notificationTagFavorite => 'Favorito';

  @override
  String notificationSignedActor(String user, String actor) {
    return '@$user contrató la IP de personaje $actor';
  }

  @override
  String notificationShareEarned(String amount) {
    return 'Has ganado una parte de $amount';
  }

  @override
  String notificationStaminaLow(String actor) {
    return 'A $actor le falta energía. Recárgala o deja que descanse';
  }

  @override
  String notificationCurrentStamina(String value) {
    return 'Energía actual $value';
  }

  @override
  String notificationShowEnded(String range) {
    return 'La actuación de $range ha terminado';
  }

  @override
  String notificationIncomeEarned(String amount) {
    return 'Has ganado $amount';
  }

  @override
  String get notificationActionClaim => 'Cobrar';

  @override
  String get notificationActionRefill => 'Recargar';

  @override
  String get notificationInteractionLikedVideo => 'Le gustó tu vídeo';

  @override
  String notificationInteractionLikedDrama(String title) {
    return 'Le gustó tu minidrama «$title»';
  }

  @override
  String get notificationInteractionFavoritedVideo => 'Guardó tu vídeo';

  @override
  String notificationInteractionFavoritedDrama(String title) {
    return 'Guardó tu minidrama «$title»';
  }

  @override
  String notificationInteractionCommented(String content) {
    return 'Comentó: $content';
  }

  @override
  String get notificationInteractionFollowedYou => 'Te siguió';

  @override
  String get notificationActionMutualFollow => 'Mutuo';

  @override
  String get notificationActionFollow => 'Seguir';

  @override
  String get notificationDelete => 'Eliminar';

  @override
  String get notificationDeleteFailed =>
      'No se pudo eliminar. Inténtalo de nuevo más tarde';

  @override
  String get notificationRealtimeReceived =>
      'Has recibido una nueva notificación';

  @override
  String drawerEpisodeProgress(int current, int total) {
    return '$current/$total episodios';
  }

  @override
  String drawerNotificationSignedActor(String actor, String target) {
    return '$actor contrató la IP de personaje $target';
  }

  @override
  String drawerNotificationLikedVideo(String actor) {
    return 'A $actor le gustó tu vídeo';
  }

  @override
  String drawerNotificationFavoritedDrama(String actor, String target) {
    return '$actor guardó tu drama corto $target';
  }

  @override
  String get depositTitle => 'Recargar';

  @override
  String get insufficientBalanceTitle => 'Saldo insuficiente';

  @override
  String insufficientBalanceDetail(String currency, String amount) {
    return 'El saldo de $currency es insuficiente, te faltan $amount $currency';
  }

  @override
  String get insufficientBalancePrompt => '¿Ir a recargar?';

  @override
  String get insufficientBalanceRecharge => 'Recargar';

  @override
  String get depositDesc =>
      'Transfiere tokens desde un exchange u otra billetera a la dirección a continuación. El saldo se actualizará automáticamente una vez acreditado.';

  @override
  String get depositToken => 'Token';

  @override
  String get depositNetwork => 'Red';

  @override
  String get depositNetworkNote =>
      'Confirma la red de transferencia. Usar la red incorrecta puede provocar la pérdida de activos.';

  @override
  String get depositAddress => 'Dirección de recarga';

  @override
  String get depositAddressCopied => 'Dirección copiada al portapapeles';

  @override
  String get depositSend => 'Enviar';

  @override
  String get depositReceive => 'Recibir';

  @override
  String get depositConvertNote =>
      'Envía tokens a esta dirección y se convertirán automáticamente a USDC en tu cuenta de Story.fun.';

  @override
  String depositMinNote(String minAmount, String token) {
    return 'Depósito mínimo: $minAmount $token';
  }

  @override
  String depositExchangeRateNote(String rate) {
    return 'El tipo de cambio actual es $rate. Monto acreditado = depósito × $rate';
  }

  @override
  String get depositWarning =>
      'Deposita solo el token seleccionado en la red seleccionada. Otros activos no se pueden recuperar.\nConfirma la red de transferencia; errores de red pueden resultar en pérdida de activos.';

  @override
  String get withdrawTitle => 'Retirar fondos';

  @override
  String get withdrawBalance => 'Saldo disponible para retirar';

  @override
  String get withdrawToken => 'Token';

  @override
  String get withdrawAddress => 'Dirección para el retiro de fondos';

  @override
  String get withdrawAddressHint =>
      'Por favor ingresa o pega la dirección del destinatario Solana';

  @override
  String get withdrawAddressHintEvm =>
      'Ingresa o pega una dirección de destino EVM';

  @override
  String get withdrawInvalidEvmAddress => 'Introduce una dirección EVM válida';

  @override
  String get withdrawInvalidSolanaAddress =>
      'Introduce una dirección Solana válida';

  @override
  String get withdrawEvmGasNote =>
      'Los retiros EVM requieren tokens nativos suficientes para el gas. La transferencia se envía directamente on-chain.';

  @override
  String get withdrawEvmFailed =>
      'El retiro EVM falló. Inténtalo de nuevo más tarde.';

  @override
  String get withdrawAddressNote =>
      'Comprueba que la dirección sea correcta, ya que una vez realizada la transferencia no se podrá revertir.';

  @override
  String get withdrawNetwork => 'Red';

  @override
  String get withdrawAmount => 'Monto';

  @override
  String get withdrawAmountHint => 'Ingresa el monto a retirar';

  @override
  String get withdrawMax => 'Máx';

  @override
  String withdrawAvailableBalance(String balance, String token) {
    return 'Saldo $balance $token';
  }

  @override
  String withdrawMinWarning(String minAmount, String token) {
    return 'Retiro mínimo: $minAmount $token\nPor favor verifica la dirección y la red cuidadosamente; las transacciones no se pueden revertir.';
  }

  @override
  String get withdrawConfirm => 'Confirmar retirada';

  @override
  String get withdrawAll => 'Todo';

  @override
  String withdrawMinAmountError(String minAmt, String token) {
    return 'El monto mínimo de retiro es $minAmt $token';
  }

  @override
  String get withdrawExceedBalanceError =>
      'El monto a retirar no puede exceder el saldo disponible';

  @override
  String get withdrawSameAsWalletError =>
      'La dirección de retiro no puede ser la misma que la de tu billetera';

  @override
  String get withdrawConfirmTitle => 'Confirmar retirada';

  @override
  String withdrawConfirmMessage(String amount, String token, String address) {
    return '¿Estás seguro de que deseas retirar $amount $token a la siguiente dirección Solana?\n\n$address';
  }

  @override
  String get withdrawSuccessToast =>
      '¡Solicitud de retiro enviada exitosamente!';

  @override
  String get withdrawFailedToast =>
      'Retiro fallido. Por favor intenta de nuevo.';

  @override
  String withdrawErrorToast(String error) {
    return 'Ocurrió un error durante el retiro: $error';
  }

  @override
  String withdrawAddressHintWithToken(String token) {
    return 'Introduce la dirección de monedero que ha recibido $token';
  }

  @override
  String get withdrawFee => 'Comisiones';

  @override
  String withdrawFeeValue(String fee, String token) {
    return '$fee $token';
  }

  @override
  String withdrawMinAmount(String minAmount, String token) {
    return 'Retiro mínimo: $minAmount $token';
  }

  @override
  String withdrawMaxAmount(String maxAmount, String token) {
    return 'Monto máximo de retiro: $maxAmount $token';
  }

  @override
  String get withdrawSponsorSigning => 'Firmando transacción...';

  @override
  String get withdrawSponsorSubmitting => 'Enviando transacción en cadena...';

  @override
  String get withdrawSponsorSuccess => '¡Retiro enviado exitosamente!';

  @override
  String get withdrawSponsorFailed =>
      'Error al enviar la transacción. Por favor intenta de nuevo.';

  @override
  String get withdrawOrderProcessing => 'Procesando orden';

  @override
  String get withdrawOrderSuccess => 'Orden completada';

  @override
  String get withdrawOrderFailed => 'Orden fallida';

  @override
  String withdrawOrderStatus(String status) {
    return 'Estado de la orden: $status';
  }

  @override
  String get qrScannerTitle => 'Escanear código QR';

  @override
  String get qrScannerHint =>
      'Alinea el código QR dentro del marco para escanear';

  @override
  String get drawerProfile => 'Mi cuenta';

  @override
  String get drawerCreatorManagement => 'Gestión de creadores';

  @override
  String get drawerInvite => 'Invitación';

  @override
  String get inviteTitle => 'Invitar amigos';

  @override
  String get inviteTotalPeople => 'Número total de personas invitadas';

  @override
  String get inviteTotalRewards => 'Recompensas totales de invitación';

  @override
  String get inviteWeeklyPool =>
      'Fondo de recompensas por invitaciones de esta semana';

  @override
  String get inviteViewHistory => 'Ver el historial de ingresos';

  @override
  String get inviteShareSection => 'Comparte tu enlace o código de invitación';

  @override
  String get inviteLinkSection => 'Enlace de invitación';

  @override
  String get inviteLinkSubtitle =>
      'Si un amigo se registra con tu enlace, contrata y envía un personaje, recibirás una recompensa extra de STORY.';

  @override
  String get inviteCodeLabel => 'Código de invitación';

  @override
  String get inviteCopyButton => 'Copiar enlace';

  @override
  String get inviteCopiedSuccess =>
      '¡Enlace de invitación copiado al portapapeles!';

  @override
  String get inviteCodeCopiedSuccess =>
      '¡Código de invitación copiado al portapapeles!';

  @override
  String get inviteInvitedLabel => 'Invitados';

  @override
  String get inviteRewardLabel => 'Recompensas';

  @override
  String get inviteBindCode => 'Vincular código de invitación';

  @override
  String get inviteBindCodePromptHint =>
      'Puedes vincularlo más tarde en la página de Invitación';

  @override
  String get inviteBindCodePlaceholder => 'Introduce el código de invitación';

  @override
  String get inviteBindConfirm => 'Confirmar';

  @override
  String get inviteBindSuccess =>
      'Código de invitación vinculado correctamente';

  @override
  String get inviteBindCodeInvalid => 'Código de invitación no válido';

  @override
  String get inviteBindCodeAlreadyBound =>
      'Esta cuenta ya tiene un código de invitación vinculado';

  @override
  String get inviteRulesSection => 'Normas de invitación';

  @override
  String get inviteFaqPoolTitle =>
      '¿Qué es el fondo semanal de recompensas por invitación?';

  @override
  String get inviteFaqPoolBody =>
      'El fondo semanal de recompensas por invitación es un fondo independiente creado para la actividad de invitaciones. Premia las invitaciones de la semana en curso y no se deduce de las ganancias de los invitados. El fondo tiene un tope de pago semanal; al alcanzarlo, los pagos se reducen proporcionalmente según la participación. Las estadísticas se reinician cada lunes.';

  @override
  String get inviteFaqSettlementTitle =>
      '¿Cuándo se liquidan las recompensas por invitación?';

  @override
  String get inviteFaqSettlementBody =>
      'Las recompensas por invitación se liquidan en el mismo ciclo que los salarios de agentes: las estadísticas se cierran cada lunes a las 00:00 (UTC). Tras la liquidación, puedes reclamarlas en la página de Recompensas.';

  @override
  String get inviteRuleSourceTitle => 'Origen de las recompensas';

  @override
  String get inviteRuleSourceSubtitle =>
      'Subconjunto de invitaciones independientes';

  @override
  String get inviteRuleSourceBody =>
      'Las recompensas por invitaciones proceden de un subfondo de invitaciones independiente dentro del fondo común de minería de NFT (que representa el 25 % del fondo común total) y no se deducen de las ganancias de los invitados. El subfondo de invitaciones tiene un límite máximo semanal independiente; una vez alcanzado dicho límite, se reduce proporcionalmente según las participaciones.';

  @override
  String get inviteRuleBaseTitle => 'Base de cálculo';

  @override
  String get inviteRuleBaseSubtitle => 'Según lo recibido STORY';

  @override
  String get inviteRuleBaseBody =>
      'La recompensa se calcula en función de los STORY que la persona invitada haya recibido realmente en este periodo, y no en función de la producción nominal. Los STORY que la persona invitada haya minado por sí misma no se ven afectados; la recompensa por invitación se abona de forma adicional.';

  @override
  String get inviteRuleLevelTitle => 'Alcance de la recompensa';

  @override
  String get inviteRuleLevelSubtitle => 'Solo invitaciones directas';

  @override
  String get inviteRuleLevelBody =>
      'Las recompensas por invitación se pagan solo por los usuarios que invites directamente. No hay comisiones multinivel ni indirectas.';

  @override
  String get inviteRuleConditionTitle => 'Condiciones de validez';

  @override
  String get inviteRuleConditionSubtitle =>
      'Solo las afiliadas activas dan derecho a recibir recompensas';

  @override
  String inviteRuleConditionBody(String currency) {
    return 'Solo se considerará un referido válido si la persona invitada ha minado STORY o ha realizado algún pago con $currency. Los registros con números de teléfono falsos no generan recompensas. Una vez establecida la relación de invitación, esta no se puede modificar.';
  }

  @override
  String get drawerTxHistory => 'Historial de transacciones';

  @override
  String get drawerFinanceDashboard => 'Panel de Finanzas';

  @override
  String get financeDashboardComingSoon =>
      'El Panel de Finanzas arrives pronto. Estén atentos.';

  @override
  String get financeDashboardPageTitle => 'Panel financiero de la plataforma';

  @override
  String financeDashboardTotalUsdcIncome(String currency) {
    return 'Ingresos totales en USDC';
  }

  @override
  String get financeDashboardTotalStoryReleased => 'Total de STORY liberado';

  @override
  String financeDashboardTabUsdcIncome(String currency) {
    return 'Detalles de ingresos en USDC';
  }

  @override
  String get financeDashboardTabVaultFunds =>
      'Acumulación de fondos en bóvedas';

  @override
  String get financeDashboardTabStoryRelease =>
      'Resumen de liberación de STORY';

  @override
  String get financeDashboardFeeMint => 'Comisión de contratación';

  @override
  String get financeDashboardFeeRoyalty => 'Regalías secundarias';

  @override
  String get financeDashboardFeeItemPurchase => 'Compra de objetos';

  @override
  String get financeDashboardFeeTx => 'Comisión de transacción';

  @override
  String get financeDashboardLedgerBizSigningFee => 'Tarifa de contratación';

  @override
  String get financeDashboardLedgerBizManualCredit => 'Abono manual';

  @override
  String get financeDashboardLedgerBizManualDebit => 'Débito manual';

  @override
  String get financeDashboardLedgerBizStaminaPurchase =>
      'Costo de compra de energía';

  @override
  String get financeDashboardLedgerBizSynthesisUpgrade =>
      'Costo de mejora por fusión';

  @override
  String get financeDashboardLedgerBizTransactionFee =>
      'Comisión de transacción';

  @override
  String financeDashboardRecentUsdcLedger(String currency) {
    return 'Ingresos recientes en USDC';
  }

  @override
  String get financeDashboardViewMore => 'Ver más';

  @override
  String get financeDashboardTotalVaultFunds => 'Fondos totales en bóvedas';

  @override
  String get financeDashboardCoveredActorIp => 'IP de personajes incluidos';

  @override
  String get financeDashboardActorVaultRanking =>
      'Clasificación de bóvedas de IP de personajes';

  @override
  String get storyReleaseTabAllocation => 'Asignación total de STORY';

  @override
  String get storyReleaseTabMiningRelease => 'Liberación reciente de minería';

  @override
  String get storyReleaseFieldPeriod => 'Periodo';

  @override
  String get storyReleaseFieldHardLimit => 'Límite semanal';

  @override
  String get storyReleaseFieldMiningRewards => 'Minería por staking';

  @override
  String get storyReleaseFieldInviteRewards => 'Minería por invitación';

  @override
  String get storyReleaseFieldUsageRate => 'Tasa de uso';

  @override
  String get storyReleaseFieldTarget => 'Destino de la asignación';

  @override
  String get storyReleaseFieldRatio => 'Proporción';

  @override
  String get storyReleaseFieldAmount => 'Cantidad';

  @override
  String get storyReleaseFieldReleased => 'Liberado';

  @override
  String get storyReleaseFieldProgress => 'Progreso de liberación';

  @override
  String get storyReleaseCategoryNftMiningPool => 'Fondo de minería NFT';

  @override
  String get storyReleaseCategoryTeam => 'Equipo';

  @override
  String get storyReleaseCategoryInvestors => 'Inversores';

  @override
  String get storyReleaseCategoryLiquidity => 'Launchpad + Liquidez';

  @override
  String get storyReleaseCategoryTreasury => 'Tesorería';

  @override
  String get storyReleaseCategoryMarketOps => 'Operaciones de mercado';

  @override
  String storyReleaseTotalSupplyBadge(String total) {
    return 'Total $total STORY';
  }

  @override
  String get drawerWhitepaper => 'Libro blanco';

  @override
  String get drawerSettings => 'Configuración';

  @override
  String get commonClose => 'Cerrar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonLoadFailed => 'Error al cargar';

  @override
  String get commonNone => 'Ninguno';

  @override
  String get commonUntitled => 'Sin título';

  @override
  String get actorDetailTitle => 'Inicio del actor';

  @override
  String get actorDetailCastDramas => 'Participar en un sketch';

  @override
  String get actorDetailTabCast => 'Participación';

  @override
  String get actorDetailTabInfo => 'Info';

  @override
  String get actorDetailNoCastRecords => 'No hay registros de participación';

  @override
  String get actorBondingCurve => 'Curva conjunta de precios';

  @override
  String get actorContractAddress => 'Dirección del contrato';

  @override
  String get actorCurrentPosition => 'Ubicación actual';

  @override
  String actorCurrentPrice(String price, String currency) {
    return 'Precio actual $price $currency';
  }

  @override
  String get actorFloorPrice => 'Precio mínimo';

  @override
  String get actorGoTrade => 'Comerciar';

  @override
  String get profileWalletTrade => 'Comerciar';

  @override
  String get actorHeatCoefficient => 'Coeficiente de popularidad';

  @override
  String get actorIpPower => 'Salario de IP';

  @override
  String get actorPayMax => 'Máx';

  @override
  String get actorPayUpgradeTitle => 'Reglas de aumento salarial';

  @override
  String get actorPayUpgradeReachHint =>
      'El número actual de reproducciones completas de dramas de este IP permite subir el rol a';

  @override
  String actorPayUpgradeCompletions(String count) {
    return '$count reproducciones completas';
  }

  @override
  String actorPayUpgradeMultiplier(String value) {
    return 'Salario ×$value';
  }

  @override
  String actorPayTitle(String name) {
    return '$name · Salario';
  }

  @override
  String get actorLv1PayHint => 'Contrata para obtener un personaje de nivel 1';

  @override
  String get actorLv1PayFormula =>
      'Salario Lv.1 = Coeficiente de precio × Coeficiente de popularidad';

  @override
  String actorLv1PayEquals(String value) {
    return '=$value';
  }

  @override
  String actorIpPowerTitle(String name) {
    return '$name · Salario de IP';
  }

  @override
  String get actorIpPowerFormula =>
      'Salario de IP = Coeficiente de precio × Coeficiente de popularidad × Trust1';

  @override
  String get actorPriceCoefficient => 'Coeficiente de precio';

  @override
  String actorPriceCoefficientValue(String value) {
    return 'Coeficiente de precio $value';
  }

  @override
  String get actorPriceCoefficientHelpA11y =>
      'Ver detalles del coeficiente de precio';

  @override
  String get actorPriceUnitName => 'Puntos';

  @override
  String get actorPriceCoefficientDialogFormulaLe100 => 'Coeficiente = P0 ÷ 10';

  @override
  String get actorPriceCoefficientDialogDescLe100 => 'Crecimiento lineal';

  @override
  String actorPriceCoefficientDialogTitleGt100(String currency) {
    return 'P0 > 10 $currency';
  }

  @override
  String get actorPriceCoefficientDialogFormulaGt100 =>
      'Coeficiente = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6]';

  @override
  String get actorPriceCoefficientDialogDescGt100 =>
      'El crecimiento se ralentiza, con un tope de 1.6';

  @override
  String actorPriceCoefficientDialogTitleLe100(String currency) {
    return 'P0 ≤ 10 $currency';
  }

  @override
  String actorPriceCoefficientFactorDesc(String currency1, String currency2) {
    return 'P0 ≤ 10 $currency1 coeficiente = P0/10 (crecimiento lineal)\nP0 > 10 $currency2 → coeficiente = 1.6 × (P0/10)^1.3 / [(P0/10)^1.3 + 0.6] (límite asintótico 1.6)';
  }

  @override
  String get actorHeatCoefficientFactorDesc =>
      'Multiplicador de popularidad del IP del personaje en los últimos 30 días, según las interacciones como reproducciones completas, «me gusta» y guardados';

  @override
  String get actorTrustFactorDesc =>
      'Coeficiente de control de riesgos de la plataforma, valor predeterminado 1.0';

  @override
  String get actorStatCompletion => 'Reproducciones completas';

  @override
  String get actorIdCopied => 'El número se ha copiado';

  @override
  String actorInitialPrice(String price, String currency) {
    return 'Precio inicial: $price $currency';
  }

  @override
  String actorIpLabel(String label) {
    return 'Personaje IP $label';
  }

  @override
  String get actorIssueInfo => 'Información de lanzamiento';

  @override
  String actorIssuer(String name) {
    return 'Lanzador $name';
  }

  @override
  String actorMintedCount(int minted, int maxSupply) {
    return 'Acuñado $minted/$maxSupply';
  }

  @override
  String get actorPriceCurve => 'Curva de precios';

  @override
  String get actorSign => 'Contratar';

  @override
  String get actorConfirmSign => 'Confirmar contratación';

  @override
  String get actorSignPriceLabel => 'Precio de contratación';

  @override
  String get actorSignPriceDescription =>
      'El precio de contratación aumenta automáticamente con el número de contratados; contratar antes resulta más ventajoso.';

  @override
  String get actorSignPriceFormula =>
      'Fórmula: Precio = Precio inicial × 5^(Número de contratados ÷ Emisión total)';

  @override
  String actorPriceAxisLabel(String currency) {
    return 'Precio ($currency)';
  }

  @override
  String get actorSignedCountAxisLabel => 'Número de contratados';

  @override
  String actorSignRemainingCount(int count) {
    return 'Quedan $count unidades';
  }

  @override
  String get actorSignSoldOut => 'Agotado';

  @override
  String actorSignSupplySummary(String total, String remaining) {
    return 'Total $total · Restante $remaining';
  }

  @override
  String get actorPricingFixed => 'Precio fijo';

  @override
  String get actorPricingCurve => 'Precio de la curva';

  @override
  String get actorPriceCurveDisclaimer =>
      'El precio inicial no representa la valoración de la plataforma; el aumento de la curva no implica una subida del precio en el mercado secundario; la plataforma no garantiza ninguna rentabilidad.';

  @override
  String get actorPriceStatInitialPrice => 'Precio inicial';

  @override
  String get actorPriceStatCurrentPrice => 'Precio actual';

  @override
  String get actorPriceStatTailPrice => 'Precio de adjudicación';

  @override
  String get actorPriceStatTotalSupply => 'Suministro total';

  @override
  String get actorPriceStatSigned => 'Contratado';

  @override
  String get actorPriceStatRemaining => 'Resto';

  @override
  String get actorPricingType => 'Tipos de fijación de precios';

  @override
  String get contentBadgeOfficialIssue => 'Lanzamiento oficial';

  @override
  String get contentBadgeCommunityIssue => 'Lanzamiento comunitario';

  @override
  String get contentBadgePartnerIssue => 'Lanzamiento de socio';

  @override
  String get contentBadgeVerifiedIssue =>
      'Lanzamiento de creadores verificados';

  @override
  String get contentBadgeOfficialDrama => 'Miniseries oficial';

  @override
  String get contentBadgeCommunityDrama => 'Sketchs de barrio';

  @override
  String get contentBadgePartnerDrama => 'Miniseries de nuestros socios';

  @override
  String get contentBadgeVerifiedDrama =>
      'Seriados cortos de creadores certificados';

  @override
  String get actorIpCopied => 'La copia se ha realizado correctamente';

  @override
  String get actorRiskIp => 'IP de riesgo';

  @override
  String get actorRiskIpDescription =>
      'Este personaje IP tiene un coeficiente de confianza anormal; el peso de minería se verá afectado.';

  @override
  String get actorIpVault => 'Tesorería de IP de personajes';

  @override
  String get actorIpVaultDescription =>
      'El 30% de los ingresos por contratación se deposita automáticamente en la tesorería de la IP del personaje para respaldar el desarrollo a largo plazo del ecosistema de la IP. El 30% de los ingresos por regalías del mercado secundario también se destina a dicha tesorería, creando así una reserva de fondos sostenible. La versión V1 de la tesorería solo ofrece visualización de datos y, por el momento, no permite la distribución de fondos.';

  @override
  String get actorIpVaultSignIncomePrefix =>
      'Ingresos por contratación · Acumulado ';

  @override
  String get actorIpVaultSecondaryRoyaltyPrefix =>
      'Regalías de segundo nivel · Acumulación ';

  @override
  String get actorFixedPriceDialogDesc =>
      'Este modelo de IP de personajes se basa en un precio fijo: cada personaje firma un contrato a un precio único, y las variaciones en las ventas no afectan al precio.';

  @override
  String get actorCurvePriceDialogDesc =>
      'El precio sube automáticamente con el número de contratados según la curva conjunta; contratar antes resulta más ventajoso';

  @override
  String get actorFixedPriceNote1 =>
      'Una vez que el lanzador fija un precio, todas las contrataciones se liquidan a ese precio.';

  @override
  String get actorFixedPriceNote2 =>
      'El precio no aumenta por más personajes que se contraten.';

  @override
  String get actorFixedPriceNote3 =>
      'Ideal para compradores que deseen fijar los costes';

  @override
  String get actorIssueFixedPriceDesc =>
      'La IP de este personaje sigue un modelo de precio fijo: todas las contrataciones se liquidan a un precio fijo, independientemente de las ventas.';

  @override
  String get actorSignSlippageNote =>
      'Se ha activado la protección contra el slippage del 1 %; si el precio supera ese límite, la operación se cancelará.';

  @override
  String get actorSignSuccessTitle => '¡Contratado!';

  @override
  String actorSignSuccessMessage(String name) {
    return 'Personaje «$name» contratado con éxito';
  }

  @override
  String actorSignSuccessNftId(String nftId) {
    return 'N.º de NFT: $nftId';
  }

  @override
  String get actorSignChainConfigMissing =>
      'La configuración en cadena está incompleta. Por favor intenta de nuevo más tarde.';

  @override
  String get actorSignPriceSoldOut => 'Precio de contratación · Agotado';

  @override
  String actorSignPriceRemaining(int count) {
    return 'Precio de contratación · Quedan $count';
  }

  @override
  String actorSignedCount(int count) {
    return 'Ya se han firmado $count';
  }

  @override
  String get actorStatusLabelOffline => 'Desconectado';

  @override
  String get actorStatusLabelOnline => 'Conectado';

  @override
  String get actorStatusLabelPending => 'En revisión';

  @override
  String get actorStatusLabelRejected => 'Rechazado';

  @override
  String get actorTotalSupply => 'Suministro total';

  @override
  String get commentsAnonymous => 'Usuario anónimo';

  @override
  String get commentsEmpty => 'No hay comentarios aún';

  @override
  String get commentsHint => 'Publica un gran comentario...';

  @override
  String get commentsInvalidContent => 'Introduce contenido válido';

  @override
  String get commentsReply => 'Responder';

  @override
  String commentsViewReplies(int count) {
    return 'Ver $count respuestas';
  }

  @override
  String get commentsCollapseReplies => 'Contraer';

  @override
  String get commentsViewMoreReplies => 'Mostrar más';

  @override
  String commentsReplyHint(String nickname) {
    return 'Responder a $nickname';
  }

  @override
  String get commentsDeleteCommentTitle => '¿Eliminar este comentario?';

  @override
  String get commentsDeleteReplyTitle => '¿Eliminar esta respuesta?';

  @override
  String get commentTagAuthor => 'Autor';

  @override
  String get commentTagMe => 'Yo';

  @override
  String get commentTagFriend => 'Tu amigo';

  @override
  String get commentTagFan => 'Tu seguidor';

  @override
  String get commentTagFirst => 'Primer comentario';

  @override
  String get commentTagAuthorLiked => 'Le gusta al autor';

  @override
  String commentsReplyTo(String nickname) {
    return 'Responder a @$nickname: ';
  }

  @override
  String get commentsReplyCommentNotExists => 'El comentario no existe';

  @override
  String get commentsBlockedByMe =>
      'El usuario está en tu lista negra, no puedes comentar';

  @override
  String get commentsBlockedByTarget =>
      'No puedes comentar a este usuario debido a su configuración';

  @override
  String get commentsTabComments => 'Comentarios';

  @override
  String get commentsTabAllComments => 'Todos los comentarios';

  @override
  String get commentsTabDramas => 'Escena corta';

  @override
  String get commentsTabActors => 'Personaje';

  @override
  String get timeJustNow => 'justo ahora';

  @override
  String get timeYesterday => 'ayer';

  @override
  String get timeDayBeforeYesterday => 'anteayer';

  @override
  String timeMinutesAgo(int count) {
    return 'hace $count min';
  }

  @override
  String timeHoursAgo(int count) {
    return 'hace $count h';
  }

  @override
  String timeDaysAgo(int count) {
    return 'hace $count d';
  }

  @override
  String commentsTitle(int count) {
    return 'Comentarios ($count)';
  }

  @override
  String get createActorTitle => 'Crear rol';

  @override
  String get createActorHeroTitle => 'Acuñar NFT de personaje';

  @override
  String get createActorHeroSubtitle =>
      'Crea roles de IA exclusivos, vincula la distribución de ganancias para participar en dramas';

  @override
  String get createActorNameLabel => 'Nombre del rol';

  @override
  String get createActorNameHint => 'Ingresa el nombre del rol';

  @override
  String get createActorBioLabel => 'Biografía del rol';

  @override
  String get createActorBioHint => 'Describe el trasfondo del personaje';

  @override
  String get createActorGenderLabel => 'Género';

  @override
  String get createActorGenderMale => 'Hombre';

  @override
  String get createActorGenderFemale => 'Mujer';

  @override
  String get createActorMintParams => 'Parámetros de acuñación NFT';

  @override
  String get createActorTokenStandard => 'Estándares de tokens';

  @override
  String get createActorChain => 'Cadena';

  @override
  String get createActorMinHolding => 'Tenencia mínima';

  @override
  String get createActorMintNft => 'Acuñar NFT';

  @override
  String get createActorIpTitle => 'Lanzar IP de personaje';

  @override
  String get createActorIpSubtitle =>
      'Tras lanzar la IP de un personaje, se pueden contratar personajes bajo esa IP, y estos pueden enviarse a realizar tareas para generar ingresos.';

  @override
  String get createActorSelectMaterial => 'Seleccionar material de los roles';

  @override
  String get createActorDreamOsBadge => 'Ir a DreamOS';

  @override
  String get createActorSelectMaterialDesc =>
      'Entra en el proyecto DreamOS → Crea un personaje → Entra en Story.fun para emitir IP';

  @override
  String get createActorSelectButton => 'Seleccionar rol';

  @override
  String get createActorNameLabelNew => 'Nombre del rol';

  @override
  String get createActorNamePlaceholder => 'Introduce el nombre del rol';

  @override
  String get createActorBioLabelNew => 'Descripción';

  @override
  String get createActorBioPlaceholder =>
      'Introduce la biografía del personaje';

  @override
  String get createActorParamsTitle =>
      'Parámetros de lanzamiento del IP del personaje';

  @override
  String get createActorParamsSubtitle =>
      'Establece los parámetros de lanzamiento del IP del personaje. No se pueden modificar tras el lanzamiento.';

  @override
  String get createActorTotalSupplyLabel => 'Suministro total de personajes';

  @override
  String get createActorTotalSupplyDesc =>
      'Rango de suministro total: 100 - 5.000.';

  @override
  String get createActorTotalSupplyPlaceholder => '100 - 5,000';

  @override
  String get createActorPricingFixed => 'Precio fijo';

  @override
  String get createActorPricingCurve => 'Precio de la curva';

  @override
  String createActorFixedPriceLabel(String currency) {
    return 'Precio fijo ($currency)';
  }

  @override
  String createActorInitialPriceLabel(String currency) {
    return 'Precio inicial ($currency)';
  }

  @override
  String get createActorFixedPricePlaceholder => '10 - 1,000';

  @override
  String get createActorFixedPriceDesc =>
      'Cada personaje se contrata a un precio fijo que no varía en función de las ventas.';

  @override
  String get createActorInitialPricePlaceholder => '10 - 1,000';

  @override
  String get createActorInitialPriceDesc =>
      'El precio inicial es el precio de partida de la curva conjunta. Por cada personaje contratado, el precio aumenta automáticamente según la fórmula P = P₀ × 5^(número de contratados ÷ emisión total). Contratar pronto resulta más ventajoso.';

  @override
  String get createActorFormIncomplete =>
      'Completa primero los recursos del personaje, el nombre, la biografía y los parámetros de lanzamiento';

  @override
  String get createActorValidationNameRequired =>
      'Por favor ingresa el nombre del rol';

  @override
  String get createActorValidationNameTooLong =>
      'El nombre del personaje debe tener 20 caracteres o menos';

  @override
  String get createActorValidationBioRequired =>
      'Por favor ingresa la biografía';

  @override
  String get createActorValidationBioTooLong =>
      'La biografía debe tener 500 caracteres o menos';

  @override
  String get createActorValidationTotalSupplyRequired =>
      'Introduce un suministro total de NFT válido';

  @override
  String get createActorValidationTotalSupplyPositiveInteger =>
      'El suministro total de NFT debe ser un número entero positivo';

  @override
  String get createActorValidationTotalSupplyRange =>
      'El suministro total de personajes debe estar entre 100 y 5.000';

  @override
  String get createActorValidationPriceRequired =>
      'Por favor ingresa un precio de acuñación válido';

  @override
  String get createActorValidationPriceInvalid =>
      'El precio de Mint debe ser mayor o igual a 10 y no superar 1.000';

  @override
  String get createActorValidationPriceMaxDecimals =>
      'El precio de acuñación puede tener máximo 2 decimales';

  @override
  String get createActorSelectMaterialRequired =>
      'Por favor selecciona el material del personaje';

  @override
  String get createActorCancelButton => 'Cancelar';

  @override
  String get createActorConfirmButton => 'Confirmar lanzamiento';

  @override
  String get createActorIssueFee => 'Tarifa';

  @override
  String createActorSuccessTitle(String name) {
    return '$name · ¡Lanzamiento exitoso!';
  }

  @override
  String createActorSuccessDesc(String id) {
    return 'IP de personaje $id';
  }

  @override
  String get createActorSuccessTip =>
      'El emisor también debe firmar para obtener este personaje~';

  @override
  String get createActorCloseButton => 'Más tarde';

  @override
  String get createActorViewButton => 'Ir a firmar';

  @override
  String get createActorEmptyTitle =>
      'Aún no tienes ningún lanzamiento de NFT que cumpla los requisitos y sea generado automáticamente por el sistema en DreamOS.';

  @override
  String get createActorGotoDreamOs => 'Ir a DreamOS para crear';

  @override
  String get createActorSearchPlaceholder => 'Buscar materiales de personaje';

  @override
  String get createActorInvalidOrderId =>
      'El número de pedido del IP del personaje no es válido. Actualiza e inténtalo de nuevo';

  @override
  String get createDramaTitle => 'Crear drama';

  @override
  String get createDramaTitleLabel => 'Título del cortometraje';

  @override
  String get createDramaTitleHint => 'Ingresa el nombre del drama';

  @override
  String get createDramaSynopsisLabel => 'Sinopsis';

  @override
  String get createDramaSynopsisHint =>
      '¿Qué tipo de historia se cuenta...? (máximo 1000 caracteres)';

  @override
  String get createDramaAiSettings => 'Configuración de generación IA';

  @override
  String get createDramaVisualStyle => 'Estilo visual';

  @override
  String get createDramaVisualStyleRealistic => 'Realista';

  @override
  String get createDramaEpisodeDuration => 'Duración del episodio';

  @override
  String get createDramaEpisodeDurationValue => '3-5 min';

  @override
  String get createDramaTotalEpisodes => 'Episodios totales';

  @override
  String get createDramaTotalEpisodesValue => '8 episodios';

  @override
  String get createDramaGenreLabel => 'Tipo';

  @override
  String get createDramaGenreDrama => 'Drama';

  @override
  String get createDramaGenreComedy => 'Comedia';

  @override
  String get createDramaGenreAction => 'Acción';

  @override
  String get createDramaGenreRomance => 'Romance';

  @override
  String get createDramaGenreSciFi => 'Ciencia ficción';

  @override
  String get createDramaGenreMystery => 'Suspense';

  @override
  String get createDramaGenreHorror => 'Terror';

  @override
  String get createDramaGenreAnimation => 'Animación';

  @override
  String get createDramaHeroTitle => 'Creación de drama IA';

  @override
  String get createDramaHeroSubtitle =>
      'Generación con un clic de tu próximo drama exitoso';

  @override
  String get createDramaStartGeneration => 'Iniciar generación';

  @override
  String get creatorDramaManagementTab => 'Gestión de miniseries';

  @override
  String get creatorDramaNftTab => 'NFT de cortometrajes';

  @override
  String get creatorHeaderSubtitle =>
      'Publicación, revisión y producción de miniseries.';

  @override
  String get creatorV2Subtitle => 'Publica y gestiona miniseries y vídeos.';

  @override
  String creatorV2DramaTabCount(int count) {
    return 'Miniseries ($count)';
  }

  @override
  String creatorV2VideoTabCount(int count) {
    return 'Vídeos ($count)';
  }

  @override
  String get creatorV2NoVideos => 'Todavía no hay vídeos';

  @override
  String get creatorLoginPrompt => 'Inicia sesión para ver tus creaciones';

  @override
  String get creatorNoCreatedActors => 'No hay roles creados';

  @override
  String get creatorNoPublishedDramas => 'No hay dramas publicados';

  @override
  String get creatorOwnedNftCount => 'Número de NFT que posee';

  @override
  String get creatorCreateDrama => 'Crear drama';

  @override
  String get creatorPublishNewDrama => 'Publicar un nuevo cortometraje';

  @override
  String get creatorPublishedDramas => 'Publicar un cortometraje';

  @override
  String get creatorReviewFilterAll => 'Todo';

  @override
  String get creatorReviewFilterApproved => 'Aprobado';

  @override
  String get creatorReviewFilterPending => 'En revisión';

  @override
  String get creatorReviewFilterRejected => 'No aprobado';

  @override
  String get creatorReviewFilterOffline => 'Retirado';

  @override
  String get creatorDramaOtherReason => 'Otro motivo';

  @override
  String get creatorDramaStatusOnline => 'Aprobado';

  @override
  String get creatorDramaStatusPendingReview => 'En revisión';

  @override
  String get creatorDramaStatusReviewRejected => 'No aprobado';

  @override
  String get creatorDramaStatusPendingOnline => 'Pendiente de publicación';

  @override
  String creatorDramaAuditReason(Object reason) {
    return 'Motivo de rechazo: $reason';
  }

  @override
  String get creatorDramaNftMinted => 'Ya se ha fundido';

  @override
  String creatorDramaEpisodeCount(int count) {
    return '$count episodios';
  }

  @override
  String get creatorDramaEdit => 'Editar';

  @override
  String get creatorDramaDelete => 'Eliminar';

  @override
  String get creatorActorDelete => 'Eliminar rol';

  @override
  String get creatorDeleteDramaConfirm => '¿Deseas eliminar este sketch?';

  @override
  String get creatorDeleteVideoConfirmTitle =>
      'Confirmar eliminación del video';

  @override
  String creatorDeleteVideoConfirmMessage(String name) {
    return '¿Seguro que quieres eliminar “$name”?\nEsta acción no se puede deshacer.';
  }

  @override
  String get creatorDeleteActorConfirm => '¿Deseas eliminar a este personaje?';

  @override
  String get creatorDeleting => 'Eliminando...';

  @override
  String get creatorNoDramas => 'Por el momento no hay miniseries';

  @override
  String get creatorNoNfts => 'De momento no hay NFT de miniseries';

  @override
  String get creatorsComingSoon => 'Próximamente';

  @override
  String get creatorsHeroSubtitle => 'Descubre creadores destacados';

  @override
  String get creatorsHeroTitle => 'Creadores';

  @override
  String get dramaBatchUnlockAll => 'Desbloquear todos';

  @override
  String dramaBatchUnlockDiscount(String discount) {
    return 'Descuento por desbloqueo por lotes $discount%';
  }

  @override
  String get dramaBatchUnlockSubtitle =>
      'Desbloquea todos los episodios de una vez para una mejor oferta';

  @override
  String get dramaBatchUnlockSuccess =>
      'Desbloqueo exitoso, por favor comienza a ver';

  @override
  String get dramaDetailAllFree => 'Todos gratis';

  @override
  String dramaDetailBoundActors(int count) {
    return '$count roles vinculados';
  }

  @override
  String dramaDetailEpisodeCount(int count) {
    return '$count episodios';
  }

  @override
  String get dramaDetailEpisodePrice => 'Precio por episodio';

  @override
  String get dramaDetailFree => 'Gratis';

  @override
  String dramaDetailFreeEpisodes(int count) {
    return 'Primeros $count gratis';
  }

  @override
  String get dramaDetailMainCharacters => 'Roles principales';

  @override
  String get dramaDetailNftMinted => 'NFT acuñado';

  @override
  String get dramaDetailNoEpisodes => 'No hay episodios';

  @override
  String get dramaDetailPaid => 'De pago';

  @override
  String get dramaDetailPendingActor => 'Personaje pendiente';

  @override
  String get dramaDetailRoleCount => 'Roles';

  @override
  String get dramaUnlockFailedRetry =>
      'Error al desbloquear, por favor intenta de nuevo';

  @override
  String get dramaUnlockFetchTimeout =>
      'Tiempo de espera agotado al obtener la dirección de reproducción, por favor intenta de nuevo';

  @override
  String get dramaUnlockLoginRequired =>
      'Por favor inicia sesión para desbloquear episodios';

  @override
  String dramaUnlockMessage(
    int epNo,
    String price,
    String discount,
    String currency,
  ) {
    return 'El episodio $epNo requiere pago para desbloquear\nPrecio: $price $currency\nDescuento por lotes: $discount';
  }

  @override
  String get dramaUnlockSuccessFetching =>
      'Desbloqueo exitoso, obteniendo dirección de reproducción...';

  @override
  String get dramaUnlockTitle => 'Desbloquear episodios';

  @override
  String get editActorTitle => 'Editar rol';

  @override
  String get editDramaTitle => 'Editar un sketch';

  @override
  String get editVideoTitle => 'Editar vídeo';

  @override
  String get editSaveChanges => 'Guardar cambios';

  @override
  String get editProfileTitle => 'Editar perfil';

  @override
  String get editNicknameLabel => 'Apodo';

  @override
  String get editRoleNameLabel => 'Nombre de usuario';

  @override
  String get editNicknameHint => 'Ingresa tu apodo';

  @override
  String get editNicknameRequired => 'Por favor ingresa un apodo';

  @override
  String get editProfileBioLabel => 'Biografía';

  @override
  String get editProfileBioHint => 'Por favor ingresa la biografía';

  @override
  String get editProfileEmailLabel => 'Dirección de correo electrónico';

  @override
  String get editAvatarCropTitle => 'Recortar avatar';

  @override
  String get profileUpdateSuccess => 'Perfil actualizado';

  @override
  String incomeClaimAmount(String amount, String currency) {
    return 'Reclamar $amount $currency';
  }

  @override
  String get incomeClaimFailed => 'Reclamación fallida';

  @override
  String incomeClaimMessage(String amount, String currency) {
    return 'Monto reclamable: $amount $currency\nLas ganancias se transferirán a tu saldo de billetera';
  }

  @override
  String get incomeClaimSuccess => 'Reclamación exitosa';

  @override
  String get incomeClaimTitle => 'Cobrar los ingresos';

  @override
  String get incomeConfirmClaim => 'Confirmar recepción';

  @override
  String get incomeHistoryTab => 'Historial';

  @override
  String get incomeInviteHeroSubtitle =>
      'Invita a amigos a consumir e interactuar, cuanto más activo sea el invitado mayor será la recompensa';

  @override
  String get incomeInviteHeroTitle => 'Invita amigos para obtener rebajas';

  @override
  String get incomeInviteNoRecords => 'No hay registros de rebajas';

  @override
  String get incomeInvitePaidUnlockDesc =>
      'Amigos pagan para desbloquear episodios';

  @override
  String get incomeInvitePaidUnlockTitle => 'Desbloqueo de pago';

  @override
  String get incomeInviteRecords => 'Registros de rebajas';

  @override
  String get incomeInviteRegisterDesc =>
      'Amigos se registran a través de tu enlace de referido';

  @override
  String get incomeInviteRegisterTitle => 'Registro por invitación';

  @override
  String get incomeInviteRules => 'Reglas de rebajas';

  @override
  String get incomeInviteShareLink => 'Compartir enlace de invitación';

  @override
  String get incomeInviteStakeDesc => 'Amigos apuestan NFTs o STORY';

  @override
  String get incomeInviteStakeTitle => 'Inversión en staking';

  @override
  String get incomeInviteTab => 'Rebajas por invitación';

  @override
  String get incomeInviteWatchDesc => 'Amigos ven dramas para ganar puntos';

  @override
  String get incomeInviteWatchTitle => 'Ver dramas';

  @override
  String get incomeNoHistory => 'No hay registros de historial';

  @override
  String get incomeNoRecords => 'No hay registros de ganancias';

  @override
  String get incomeNothingToClaim => 'Nada que reclamar';

  @override
  String get incomeOverviewTab => 'Resumen';

  @override
  String get incomePendingClaim => 'Reclamación pendiente';

  @override
  String get incomeRecords => 'Registros de ganancias';

  @override
  String get incomeThisMonth => 'Este mes';

  @override
  String get incomeToday => 'Hoy';

  @override
  String get incomeTotalEarnings => 'Ganancias acumuladas';

  @override
  String get incomeCumulativeStory => 'Acumulado STORY';

  @override
  String incomeCumulativeUsdc(String currency) {
    return '$currency acumulado';
  }

  @override
  String get incomeClaimableStory => 'Se puede recoger STORY';

  @override
  String incomeClaimableUsdc(String currency) {
    return 'Se puede retirar $currency';
  }

  @override
  String get incomeSettlingStory => 'Mi salario';

  @override
  String get incomeSettlingHint =>
      'Liquidando; reclamable después de la llegada';

  @override
  String get incomeHelpTotalStoryDesc =>
      'Cantidad total de STORY acumulada en todos los ciclos históricos (incluidas las ya cobradas y las pendientes de cobrar).';

  @override
  String incomeHelpTotalUsdcDesc(String currency) {
    return 'Ingresos acumulados en $currency procedentes de la participación en los ingresos por contratos y de los derechos de autor secundarios de todos los personajes históricos.';
  }

  @override
  String get incomeHelpSettlingStoryDesc =>
      'Se convierte automáticamente en STORY tras la liquidación del sistema';

  @override
  String get incomeHelpClaimableStoryDesc =>
      'Las STORY ya liquidadas se pueden retirar a tu monedero personal.';

  @override
  String incomeHelpClaimableUsdcDesc(String currency) {
    return 'El $currency ya liquidado se puede retirar a la cartera personal.';
  }

  @override
  String get incomeFilterAll => 'Todo';

  @override
  String get incomeFilterMining => 'Ingresos por cesión de personal';

  @override
  String get incomeFilterInvite => 'Ganancias por invitaciones';

  @override
  String get incomeMiningReward => 'Ingresos por cesión de personal';

  @override
  String get incomeInviteReward => 'Ganancias por invitaciones';

  @override
  String get incomeUsdcActorSignShare =>
      'Participación por contratación de personajes';

  @override
  String get incomeClaimNoWallet => 'Por favor vincula tu billetera primero';

  @override
  String incomeClaimCurrencyTitle(String currency) {
    return 'Reclamar $currency';
  }

  @override
  String incomeClaimWithdrawMessage(
    String amount,
    String currency,
    String address,
  ) {
    return '¿Confirmar retiro de $amount $currency a tu billetera Solana?\nDestinatario: $address';
  }

  @override
  String get incomeClaimWithdrawConfirm => 'Confirmar retiro';

  @override
  String get incomeClaimWithdrawSubmitted => '¡Retiro exitoso!';

  @override
  String get incomeClaimWithdrawFailed =>
      'Retiro fallido, por favor intenta de nuevo';

  @override
  String get incomeClaimAction => 'Recoger';

  @override
  String get nftCreateActorIp => 'Crear IP de personaje';

  @override
  String get nftHeaderSubtitle =>
      'Explora y colecciona personajes NFT exclusivos';

  @override
  String get nftHeaderTitle => 'Plaza de Personajes NFT';

  @override
  String get nftSearchHint => 'Buscar dramas, obras, roles, usuarios...';

  @override
  String get actorHowToPlayTitle => '¿Cómo se juega con los personajes de IP?';

  @override
  String get actorHowToPlayHelpTooltip => 'Instrucciones de juego';

  @override
  String get actorHowToPlaySignTab => 'IP contratadas';

  @override
  String get actorHowToPlaySignSubtitle => 'Ganar salario pasivamente';

  @override
  String get actorHowToPlayIssueTab => 'Lanzar IP';

  @override
  String get actorHowToPlayIssueSubtitle => 'Monetización de la creación';

  @override
  String get actorHowToPlaySignPositioning =>
      'Enfoque: sin requisitos previos para crear contenido, ingresos fáciles y seguros';

  @override
  String get actorHowToPlaySignAudience =>
      'Usuarios normales que no quieren crear contenido, sino obtener ingresos de STORY sin mucho esfuerzo';

  @override
  String get actorHowToPlaySignGuide =>
      'Contrata IP de personajes de alta popularidad y bien pagados; programa actuaciones en la página del Agente y obtén beneficios';

  @override
  String get actorHowToPlaySignRightsTitle => 'Doble beneficio';

  @override
  String get actorHowToPlaySignRightPerform =>
      'Organiza actuaciones y gana tokens STORY de forma continua';

  @override
  String get actorHowToPlaySignRightTrade =>
      'Los personajes son propiedad intelectual negociable, lo que permite obtener beneficios adicionales.';

  @override
  String get actorHowToPlayIssuePositioning =>
      'Posicionamiento: crear y lanzar, múltiples fuentes de ingresos, revalorización de la IP a largo plazo';

  @override
  String get actorHowToPlayIssueAudience =>
      'Creadores con talento creativo que desean monetizar sus personajes y sus series cortas';

  @override
  String get actorHowToPlayIssueGuide =>
      'Lanza IP de personajes, vincúlalas a miniseries con IA, aumenta la popularidad de las obras y eleva el salario y los ingresos de la IP';

  @override
  String get actorHowToPlayIssueRightsTitle => 'Triple beneficio';

  @override
  String get actorHowToPlayIssueRightSignLabel =>
      'Participación por contratación:';

  @override
  String get actorHowToPlayIssueRightSign =>
      'Si contratan tu IP, recibes un 40% de participación';

  @override
  String get actorHowToPlayIssueRightPerformLabel =>
      'Ingresos de la actuación:';

  @override
  String get actorHowToPlayIssueRightPerform =>
      'Contrata tu propia IP y gana STORY con las actuaciones';

  @override
  String get actorHowToPlayIssueRightValueLabel => 'Valor añadido:';

  @override
  String get actorHowToPlayIssueRightValue =>
      'La IP es negociable; cuanto mayor sea la popularidad, mayor será la prima.';

  @override
  String get actorHowToPlayAudienceTitle => 'Público objetivo';

  @override
  String get actorHowToPlayGuideTitle => 'Guía de juego';

  @override
  String get actorHowToPlayCreateHint =>
      'Con DreamOS puedes generar con un solo clic la IP de un personaje y miniseries de IA, lo que te permite producir contenido de alta calidad de forma eficiente.';

  @override
  String get actorHowToPlayCreateCta => 'A crear';

  @override
  String get nftSignInDevelopment => 'Esta función aún no está disponible';

  @override
  String get nftSortCompleted => 'Reproducciones completas';

  @override
  String get nftSortHeat => 'Popularidad';

  @override
  String get nftSortIpPower => 'Salario de IP';

  @override
  String get nftSortLowestPrice => 'Precio';

  @override
  String get nftSortLv1Pay => 'Salario';

  @override
  String get nftSortMaxPay => 'Salario máximo';

  @override
  String get nftTradeUnavailable => 'Comercio aún no disponible';

  @override
  String playerEpisodeBarCompleted(int count) {
    return 'Todos los $count episodios · Completado';
  }

  @override
  String playerEpisodeSynopsis(int episodeNo, String synopsis) {
    return 'Ep $episodeNo | $synopsis';
  }

  @override
  String get playerPlayFailedRetry =>
      'Reproducción fallida, por favor intenta de nuevo más tarde';

  @override
  String get publicProfileDramas => 'Escena corta';

  @override
  String get publicProfileEmpty => 'No hay contenido público';

  @override
  String get publicProfileBlock => 'Bloquear';

  @override
  String get publicProfileUnblock => 'Desbloquear';

  @override
  String get publicProfileBlockedByMeContent =>
      'Has bloqueado a este usuario, por lo que no puedes ver su contenido';

  @override
  String get publicProfileBlockedContent =>
      'Este usuario te ha bloqueado, por lo que no puedes ver su contenido';

  @override
  String get publicProfileBlockConfirmTitle => '¿Bloquear a este usuario?';

  @override
  String get publicProfileBlockConfirmMessage =>
      'Después de bloquearlo, no podrás ver sus obras.';

  @override
  String get publicProfileBlockSuccess => 'Usuario bloqueado';

  @override
  String get publicProfileUnblockSuccess => 'Usuario desbloqueado';

  @override
  String get publicProfileFollowers => 'Seguidores';

  @override
  String get publicProfileFollowing => 'Seguidos';

  @override
  String get followTabMutual => 'Mutuos';

  @override
  String get profileLikesReceived => 'Me gusta';

  @override
  String profileLikesReceivedDialogMessage(int count) {
    return '¡Has recibido $count me gusta! Gracias por tus creaciones.';
  }

  @override
  String get profileTabLikes => 'Me gusta';

  @override
  String get profileTabFavorites => 'Favoritos';

  @override
  String get profileWalletTitle => 'Cartera';

  @override
  String get profileAddressCopied => 'Dirección copiada';

  @override
  String get followActionFollow => 'Seguir';

  @override
  String get followActionFollowBack => 'Seguir también';

  @override
  String get followActionFollowing => 'Siguiendo';

  @override
  String get followBlockedByMe =>
      'El usuario está en tu lista negra, no puedes seguir';

  @override
  String get followBlockedByTarget =>
      'No puedes seguir a este usuario debido a su configuración';

  @override
  String get likeBlockedByMe =>
      'El usuario está en tu lista negra, no puedes dar me gusta';

  @override
  String get likeBlockedByTarget =>
      'No puedes dar me gusta a este contenido debido a la configuración del creador';

  @override
  String get favoriteBlockedByMe =>
      'El usuario está en tu lista negra, no puedes marcar como favorito';

  @override
  String get favoriteBlockedByTarget =>
      'No puedes marcar como favorito este contenido debido a la configuración del creador';

  @override
  String get ratingBlockedByMe =>
      'El usuario está en tu lista negra, no puedes calificar';

  @override
  String get ratingBlockedByTarget =>
      'No puedes calificar este drama debido a la configuración del creador';

  @override
  String get followActionMutual => 'Mutuo';

  @override
  String get followUnfollowTitle => 'Dejar de seguir';

  @override
  String followUnfollowMessage(String handle) {
    return '¿Dejar de seguir a $handle?';
  }

  @override
  String get followUnfollowNo => 'No';

  @override
  String get followUnfollowYes => 'Sí';

  @override
  String get followListEmpty => 'Aún no hay usuarios';

  @override
  String get followFollowingEmpty =>
      'Aún no sigues a nadie. ¡Descubre creadores interesantes!';

  @override
  String get followFollowingEmptyCta => 'Explorar';

  @override
  String get followFollowingEmptyGuest => 'Sin seguidos';

  @override
  String get followFollowersEmpty =>
      'Aún no tienes seguidores. Publica una obra para ganar visibilidad~';

  @override
  String get followFollowersEmptyCta => 'Publicar';

  @override
  String get followFollowersEmptyGuest => 'Sin seguidores';

  @override
  String get followMutualsEmpty => 'Aún no hay seguidores mutuos';

  @override
  String get followMutualsSelfOnly => 'Los mutuos solo son visibles para ti';

  @override
  String get followRelationsSelfOnly =>
      'Las listas de relación solo son visibles para ti';

  @override
  String get followMoreTitle => 'Más';

  @override
  String get followRemoveFollower => 'Eliminar seguidor';

  @override
  String get followRemoveFollowerSuccess =>
      'Eliminado. No recibirán notificación';

  @override
  String get followUserHandleFallback => '@usuario';

  @override
  String get publicProfileTitle => 'Perfil de usuario';

  @override
  String publicProfileUserFallback(String id) {
    return 'Usuario #$id';
  }

  @override
  String get watchHistoryEmpty => 'No hay historial de reproducción';

  @override
  String get watchHistoryClearTitle => 'Borrar historial de reproducción';

  @override
  String get watchHistoryClearMessage =>
      '¿Seguro que quieres borrar todo el historial de reproducción? Esta acción no se puede deshacer.';

  @override
  String get watchHistoryClearConfirm => 'Confirmar';

  @override
  String get gamePageTitle => 'Agente';

  @override
  String get gamePageSubtitle =>
      'Gestiona a tus roles y asignales tareas para generar ingresos.';

  @override
  String get gameRiskAccount => 'Cuenta de riesgo';

  @override
  String get gameRiskAccountDescription =>
      'Esta cuenta tiene un coeficiente de confianza anormal; el peso de minería se verá afectado.';

  @override
  String get gameWeeklyStats => 'Estadísticas semanales';

  @override
  String get gameDeployedActors => 'Roles desplegados';

  @override
  String get gameMyActors => 'Mis roles';

  @override
  String get gameComingSoon => 'Próximamente';

  @override
  String get gameSignActor => 'Contratar personajes';

  @override
  String get gameGoProduce => 'Ir a rodar una serie';

  @override
  String get gameWorkingActors => 'Roles en régimen de cesión temporal';

  @override
  String get gameWeekPool => 'Fondo de recompensas de esta semana (STORY)';

  @override
  String get gameWeekNominalOutput =>
      'Producción nominal de esta semana (STORY)';

  @override
  String get gameWeekEstimatedOutput =>
      'Producción prevista para esta semana (STORY)';

  @override
  String get gameMiningRules => 'Normas de minería';

  @override
  String get agentV2RulesTitle => 'Gestión';

  @override
  String get agentV2RulesSummary =>
      'Contrata personajes y programa actuaciones para obtener STORY cada hora.\nMejora los personajes para multiplicar su salario por hora.\nRecarga la energía a tiempo para que la producción no se detenga.\nLa liquidación del período comienza cada lunes a las 00:00 (UTC); reclámala en la página de Ganancias.';

  @override
  String get agentV2RulesHowToPlay => 'Cómo funciona';

  @override
  String get agentV2RulesStartTitle =>
      '¿Cómo empiezan a generar ganancias los personajes?';

  @override
  String get agentV2RulesStartDescription =>
      'Programa una actuación para un personaje disponible. Cada hora consume 1 punto de energía y produce STORY según su salario.\nEl STORY producido se liquida al final de cada período y puede reclamarse después en la página de Ganancias.';

  @override
  String get agentV2RulesStaminaTitle => '¿Cómo se gestiona la energía?';

  @override
  String agentV2RulesStaminaDescription(int staminaLimit) {
    return 'Actuando: consume 1 punto de energía por hora y genera el salario normal\nSin energía: la producción se detiene en 0 y requiere atención\nDescansando: recupera 1 punto de energía por hora, pero pausa el salario\nRecarga (de pago): recupera al instante hasta $staminaLimit y reanuda la producción';
  }

  @override
  String get agentV2RulesBatchTitle => '¿Puedo realizar acciones en lote?';

  @override
  String get agentV2RulesBatchDescription =>
      'Sí. Usa Actuar todos, Recargar todos o Descansar todos al final de la página para aplicar una acción a todos los personajes de los espacios de actuación.';

  @override
  String get agentV2RulesEarnings => 'Ganancias';

  @override
  String get agentV2RulesSalaryTitle => '¿Cómo se calcula el salario?';

  @override
  String get agentV2RulesSalaryDescription =>
      'Cuanto mayor sea el prestigio, más caro el papel y más popular la miniserie, mayor será el salario por hora.';

  @override
  String get agentV2RulesSalaryFormula =>
      'Salario por hora de cada carta = Salario del personaje × 1 STORY';

  @override
  String get agentV2RulesRolePowerFormula =>
      'Salario del personaje = Salario del personaje Lv.1 × Coeficiente salarial';

  @override
  String get agentV2RulesIpSalaryFormula =>
      'Salario del personaje Lv.1 = Coeficiente de precio × Coeficiente de popularidad';

  @override
  String get agentV2RulesCoefficientTitle => 'Detalles de los coeficientes';

  @override
  String agentV2RulesSalaryExample(String currency) {
    return 'Lin Mengyao · Protagonista Lv3 · P0=120$currency (coeficiente de precio ≈1.5046) · popularidad 3.5\n→ Salario por hora = 5.0 × 1.5046 × 3.5 × 1 = 26.3 STORY\nComo extra Lv1 solo ganaría ≈5.3 STORY por hora; subir a Lv3 multiplica las ganancias por cinco.';
  }

  @override
  String get agentV2RulesSettlementTitle => '¿Cuándo se liquida?';

  @override
  String get agentV2RulesSettlementDescription =>
      'Cada ciclo de actuación dura 7 días y cierra cada lunes a las 00:00 (UTC). Tras la liquidación del sistema, el salario del período se convierte automáticamente en STORY y se puede reclamar en la página de Ganancias.';

  @override
  String get agentV2RulesSettlementExample =>
      'Supongamos que el fondo de recompensas de esta semana es de 100,000 STORY:\nCaso A: Solo tú produces 134 en toda la plataforma → recibes 134 y el resto no se distribuye\nCaso B: La producción de la red es 250,000 → 100,000 ÷ 250,000 = 40%, así que tu producción nominal se reduce al 40%\nCaso C: Tras el ajuste alguien debería recibir 6,000, pero el límite es 5,000 → solo se distribuyen 5,000';

  @override
  String get agentV2RulesStronger => 'Cómo fortalecerse';

  @override
  String get agentV2RulesUpgradeTitle => '¿Cómo mejoro un personaje?';

  @override
  String get agentV2RulesUpgradeDescription =>
      'Requisitos: consume 2 duplicados de la misma IP y nivel + alcanza el objetivo acumulado de reproducciones completas de las series de la IP\nNivel 1 → Nivel 2: ≥ 10 000 reproducciones completas · Salario 1→3\nNivel 2 → Nivel 3: ≥ 50 000 reproducciones completas · Salario 3→9\nNivel 3 → Nivel 4: ≥ 200 000 reproducciones completas · Salario 9→27\nNivel 4 → Nivel 5: ≥ 1 millón de reproducciones completas · Salario 27→81';

  @override
  String get agentV2RulesPerforming => 'Actuando';

  @override
  String get agentV2RulesNormalSalary => 'Salario normal';

  @override
  String get agentV2RulesSalaryCoefficient =>
      'Coeficiente salarial: Lv1=1 · Lv2=3 · Lv3=9 · Lv4=27 · Lv5=81';

  @override
  String agentV2RulesPriceCoefficientDescription(
    String currency1,
    String currency2,
  ) {
    return 'Coeficiente de precio (precio de emisión P0):\n  • P0 ≤ 100 $currency1 → coeficiente = P0 ÷ 100 (crecimiento lineal)\n  • P0 > 100$currency2 → coeficiente = 1,6 × (P0/100)¹.³ / [(P0/100)¹.³ + 0,6] (límite asintótico 1,6)';
  }

  @override
  String get agentV2RulesTrust2 => 'Trust2';

  @override
  String get agentV2RulesTrust2Factor => 'Trust2 de la plataforma';

  @override
  String get agentV2RulesSettlementCase1 =>
      'Pago real = producción nominal; la capacidad no utilizada caduca';

  @override
  String get agentV2RulesSettlementCase2 =>
      'Ajuste proporcional: pago real = producción nominal × (fondo de recompensas ÷ producción de la red)';

  @override
  String get gameSettlementRecords => 'Registro de liquidaciones semanales';

  @override
  String get gameFilterComputingPower => 'Salario';

  @override
  String get gameFilterLevel => 'Nivel';

  @override
  String get gameFilterHeat => 'Popularidad';

  @override
  String get gameFilterStamina => 'Energía';

  @override
  String get gameHeatCoef => 'Coeficiente de popularidad';

  @override
  String get gameMiningCoef => 'Coeficiente de minería';

  @override
  String get gameActorPower => 'Salario del personaje';

  @override
  String get gameActorPowerDetailTitle => 'Detalles del salario del personaje';

  @override
  String get gameActorPowerFormula =>
      'Salario del personaje = Salario de IP × Coeficiente de minería × Coeficiente CP × Trust2';

  @override
  String get gameActorPowerIpFormula =>
      'Salario de IP = Coeficiente de precio × Coeficiente de popularidad × Trust1';

  @override
  String get gameActorPowerHourlyOutput => 'Producción por hora';

  @override
  String get gameCpCoefficient => 'Coeficiente CP';

  @override
  String get gameTrust2 => 'Trust2';

  @override
  String get gameWeeklyNominalOutputLabel =>
      'Producción nominal de esta semana';

  @override
  String get gameRoundNominalOutputLabel => 'Producción nominal del período';

  @override
  String get gameSupplement => 'Añadido';

  @override
  String get gameRest => 'Descanso';

  @override
  String get gameDeploy => 'Envío';

  @override
  String get gameDeployActor => 'Contratación de personajes';

  @override
  String get gameStatusIdle => 'inactivo';

  @override
  String get gameStatusMining => 'Minería en curso';

  @override
  String gameActorIpLabel(String id) {
    return 'Personaje IP $id';
  }

  @override
  String gameStaminaProgress(String current, String max) {
    return '$current/$max';
  }

  @override
  String get gameStaminaMechanismTitle => 'Mecánica de energía';

  @override
  String gameStaminaMechanismDesc(String currency) {
    return 'Los roles desplegados consumen 1 punto de energía por hora. Dejan de generar ganancias cuando se agota su energía y la recuperan automáticamente mientras descansan. Puedes usar $currency para reponer la energía al instante.';
  }

  @override
  String get gameStaminaMechanismAction => 'Entendido';

  @override
  String gameLevelBadge(String level) {
    return 'Nv$level';
  }

  @override
  String get gameEmptyDeployed => 'No hay roles desplegados actualmente';

  @override
  String get gameEmptyMyActors =>
      'Aún no tienes personajes. Contrata uno para comenzar.';

  @override
  String get gameDeployConfirmTitle => '¿Desplegar este personaje?';

  @override
  String get gameRestConfirmTitle => '¿Descansar este personaje?';

  @override
  String get gameRestConfirmDesc =>
      'La minería se pausa mientras el personaje descansa; la energía se recupera con el tiempo.';

  @override
  String get gameRestConfirmAction => 'Confirmar descanso';

  @override
  String get gameRestSuccessToast => 'Descanso iniciado';

  @override
  String get gameDeploySlotFull =>
      'Los espacios de despliegue están llenos (máx 5)';

  @override
  String get gameRefillTitle => 'Recuperar energía';

  @override
  String get gameRefillCurrentStamina => 'Energía actual';

  @override
  String get gameRefillCost => 'Gastos de recuperación';

  @override
  String get gameRefillConfirm => 'Recuperar toda la energía';

  @override
  String get gameRefillSuccess => 'Recuperación de la energía: completada';

  @override
  String get gameRefillFailed =>
      'No se ha podido recuperar la energía. Inténtalo de nuevo.';

  @override
  String gameInsufficientUsdc(String currency) {
    return 'Saldo insuficiente de $currency';
  }

  @override
  String get walletInsufficientStory => 'Saldo insuficiente de STORY';

  @override
  String get gameSupplementComingSoon => 'Recarga de energía próximamente';

  @override
  String get gameStatHelpWeekPoolTitle => 'Fondo de recompensas de esta semana';

  @override
  String get gameStatHelpWeekPoolSubtitle =>
      'Es decir, el límite máximo de distribución semanal obligatorio para la minería de STORY (límite máximo semanal)';

  @override
  String get gameStatHelpWeekTotalPool => 'Fondo de recompensas semanal total';

  @override
  String get gameStatHelpWeekTotalPoolValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeekStakePool =>
      'Fondo de recompensas de staking de esta semana (75%)';

  @override
  String get gameStatHelpWeekStakePoolValue => '1,586,538 STORY';

  @override
  String get gameStatHelpWeekInvitePool =>
      'Fondo de recompensas por invitaciones de esta semana (25%)';

  @override
  String get gameStatHelpWeekInvitePoolValue => '528,846 STORY';

  @override
  String get gameStatHelpInitialHardCap => 'Techo rígido de la primera semana';

  @override
  String get gameStatHelpInitialHardCapValue => '2,115,385 STORY';

  @override
  String get gameStatHelpWeeklyDecay => 'Coeficiente de atenuación semanal';

  @override
  String get gameStatHelpWeeklyDecayValue => '× 0.99572';

  @override
  String get gameStatHelpWeeklyDistributionFormula =>
      'Distribución real semanal = min(producción nominal de toda la red, límite máximo de esa semana)';

  @override
  String get gameStatHelpUnusedQuotaNote =>
      'Las cuotas restantes no asignadas no se concederán, no se recuperarán ni se compensarán con puntos.';

  @override
  String get gameStatHelpNominalTitle => 'Producción nominal de esta semana';

  @override
  String get gameStatHelpNominalSummary =>
      'Suma de la producción nominal semanal de todos mis roles';

  @override
  String get gameStatHelpNominalSummaryHint =>
      'La fórmula para una sola tarjeta se explica a continuación.';

  @override
  String get gameStatHelpNominalFormula =>
      'Producción nominal por tarjeta = Peso horario por tarjeta × R_base × Duración efectiva de minería';

  @override
  String get gameStatHelpHourlyWeight =>
      'Ponderación por hora de una sola tarjeta';

  @override
  String get gameStatHelpHourlyWeightValue => '= Salario del personaje';

  @override
  String get gameStatHelpActorPower => 'Salario del personaje';

  @override
  String get gameStatHelpActorPowerValue =>
      '= Salario IP × Coeficiente de minería × Coeficiente CP × Trust2';

  @override
  String get gameStatHelpCpCoef => 'Coeficiente CP';

  @override
  String get gameStatHelpRBase => 'R_base';

  @override
  String get gameStatHelpRBaseValue => '1 STORY / Ponderación unitaria / Hora';

  @override
  String get gameStatHelpEffectiveDuration => 'Tiempo efectivo de minería';

  @override
  String get gameStatHelpEffectiveDurationValue =>
      'Tiempo total en el que ha estado en prenda y su energía era &gt; 0';

  @override
  String get gameStatHelpActualTitle => 'Producción prevista para esta semana';

  @override
  String get gameStatHelpActualSubtitle =>
      'La producción estimada está limitada por el techo semanal y el límite por dirección; la recompensa real se liquida al final de la semana';

  @override
  String get gameStatHelpIfNominalLte =>
      'Si la producción nominal de toda la red es ≤ al límite máximo de esa semana:';

  @override
  String get gameStatHelpUserActualEqNominal =>
      'Ingresos reales del usuario = Ingresos nominales del usuario';

  @override
  String get gameStatHelpIfNominalGt =>
      'Si la producción nominal de toda la red es superior al límite máximo de esa semana:';

  @override
  String get gameStatHelpUserActualFormula =>
      'Ganancias reales del usuario = Producción nominal del usuario × Límite máximo de la semana / Producción nominal de toda la red';

  @override
  String get gameStatHelpAddressCap => 'Límite semanal por dirección';

  @override
  String get gameStatHelpAddressCapValue =>
      'Cada dirección puede recibir, como máximo, el 5 % del límite máximo semanal de esa misma semana.';

  @override
  String get theaterCategoryAll => 'Todo';

  @override
  String get theaterCategoryAncient => 'Histórico';

  @override
  String get theaterCategoryFinance => 'Finanzas';

  @override
  String get theaterCategorySuspense => 'Suspenso';

  @override
  String get theaterCategorySciFi => 'Ciencia ficción';

  @override
  String get theaterCategoryRealStory => 'Basado en hechos reales';

  @override
  String get theaterCategoryUrban => 'Urbano';

  @override
  String get theaterSortHottest => 'Lo más popular';

  @override
  String get theaterSortNewest => 'Últimas noticias';

  @override
  String get theaterSortTopRated => 'Más guardados';

  @override
  String get theaterSortCompletedView => 'Más completados';

  @override
  String theaterPlayCount(String count) {
    return '$count reproducciones';
  }

  @override
  String get createDramaBasicInfo => 'Información básica';

  @override
  String get createDramaEpisodes => 'Gestión de series';

  @override
  String get createDramaRoles => 'Vincular IP';

  @override
  String get createDramaCover => 'Portada';

  @override
  String get createDramaCoverUpload => 'Subir';

  @override
  String get createDramaCoverPlaceholder => 'Soporta JPG/PNG, hasta 5MB';

  @override
  String get createDramaCoverCropTitle => 'Recortar portada';

  @override
  String get createDramaName => 'Título del cortometraje';

  @override
  String get createDramaNameHint => 'Introduce el título del sketch';

  @override
  String get createDramaSynopsis => 'Descripción';

  @override
  String get createDramaTags => 'Etiqueta';

  @override
  String get createDramaTagsHint =>
      'Escribe una etiqueta y presiona enter para agregar (ej. Amor, Comedia)';

  @override
  String get createDramaTagsLoading => 'Cargando etiquetas…';

  @override
  String get createDramaTagsEmpty => 'No hay etiquetas disponibles';

  @override
  String get createDramaTagsRetry => 'Inténtalo de nuevo';

  @override
  String get createDramaUploadDesc =>
      'Haz clic en «Subir»; una vez enviado, se ordenarán automáticamente por nombre de vídeo.';

  @override
  String get createDramaEpisodesDesc =>
      'Al subir archivos de vídeo de forma masiva, el sistema generará automáticamente una lista de episodios ordenados por nombre de archivo. Se pueden realizar operaciones como ordenar mediante arrastrar y soltar, eliminar y editar títulos.';

  @override
  String get createDramaVideoFileTypeHint =>
      'Formatos soportados: mp4, flv, wmv, asf, mkv, avi, rm, rmvb, mpg, mpeg, mov, webm. Tamaño máximo 2GB.';

  @override
  String get createDramaUploadVideo => 'Subir vídeo';

  @override
  String get createDramaVideoEmpty => 'No se han añadido videos aún';

  @override
  String get createDramaVideoPickFailed => 'Error al seleccionar video';

  @override
  String get createDramaVideoAnyTooLarge =>
      'Uno o más videos superan los 2GB, ajuste e intente de nuevo';

  @override
  String get createDramaVideoStatusUploading => 'Cargando...';

  @override
  String get createDramaVideoStatusPaused => 'Carga en pausa';

  @override
  String get createDramaVideoStatusDone => 'La subida se ha completado';

  @override
  String get createDramaEpisodeDescriptionHint => 'Descripción del episodio';

  @override
  String get createDramaVideoStatusFailed => 'Error al subir el archivo';

  @override
  String get createDramaVideoTooLarge =>
      'El tamaño del video no puede superar los 2 GB y no se puede subir.';

  @override
  String get createDramaVideoUploadComplete => 'Todos los videos subidos';

  @override
  String createDramaVideoUploadFailed(String name) {
    return 'Error al subir $name';
  }

  @override
  String createDramaVideoPickOverflow(int count, int overflow) {
    return 'Puedes agregar hasta $count episodios más. $overflow extras fueron omitidos.';
  }

  @override
  String createDramaAddedVideos(String count) {
    return 'Videos añadidos ($count archivos)';
  }

  @override
  String createDramaAddedVideosCount(String count) {
    return '($count archivos)';
  }

  @override
  String get createDramaAddedVideosLabel => 'Vídeos añadidos';

  @override
  String get createDramaRolesDesc =>
      'Crea roles para el cortometraje y establece su nombre, foto de perfil y breve descripción de su personalidad.';

  @override
  String get createDramaRolesRule1 =>
      'Cada drama puede vincular hasta 5 IP de personajes. Se pueden añadir durante los 7 días posteriores a la publicación; después no se pueden quitar ni sustituir.';

  @override
  String get createDramaRolesRule2 =>
      'Una vez vinculada, la IP del personaje se asocia a los datos de finalización y popularidad del drama para mejoras y recompensas STORY.';

  @override
  String get createDramaRolesExpireTime => 'Fecha límite';

  @override
  String get createDramaRolesRule3 =>
      'Vincular una IP es opcional; puedes publicar sin hacerlo.';

  @override
  String get createDramaAddRole => 'Añadir rol';

  @override
  String get createDramaBindActor => 'Reparto';

  @override
  String get createDramaRoleActing => 'Reparto';

  @override
  String get createDramaSelectActor => 'Seleccionar rol';

  @override
  String get createDramaBindActorTitle => 'Seleccionar personaje IP';

  @override
  String createDramaBindIpSelectedCount(int count) {
    return '$count seleccionados';
  }

  @override
  String get createDramaBindIpEmpty => 'Sin datos';

  @override
  String get createDramaBindIpMarketplace =>
      'Ir al mercado de IP de personajes';

  @override
  String get createDramaBindIpConfirm => 'Confirmar vínculo';

  @override
  String createDramaBindActorSubtitle(String roleName) {
    return 'Elige un personaje para interpretar el papel de «$roleName»';
  }

  @override
  String createDramaBindActorOwnedCount(int count) {
    return 'Posee $count direcciones IP de personajes';
  }

  @override
  String createDramaBindActorIpLabel(String code) {
    return 'Personaje IP $code';
  }

  @override
  String get createDramaBindActorBoundTag => 'Ya está vinculado';

  @override
  String get createDramaBindIpRemove => 'Quitar';

  @override
  String createDramaBindActorBoundToast(String name) {
    return 'Vinculado $name';
  }

  @override
  String get createDramaBindActorUnbind => 'Desvincular';

  @override
  String get createDramaBindActorExpired =>
      'El plazo de vinculación de 7 días ha vencido. No se pueden añadir nuevas vinculaciones de IP de personaje.';

  @override
  String get createDramaBindActorEmptyTitle =>
      'No hay personaje IP para vincular';

  @override
  String get createDramaBindActorEmptyDesc =>
      'Necesitas poseer un Personaje IP antes de vincularlo a un rol';

  @override
  String get createDramaBindActorGotoCreate => 'Crear rol';

  @override
  String get createDramaPrevStep => 'Paso anterior';

  @override
  String get createDramaNextStep => 'Siguiente paso';

  @override
  String get createDramaSubmit => 'Publicar';

  @override
  String get createDramaRoleNameLabel => 'Nombre del rol';

  @override
  String get createDramaRoleNameHint => 'Introduce el nombre del rol';

  @override
  String get createDramaRoleNameRequired =>
      'Por favor ingresa el nombre del rol';

  @override
  String get createDramaRoleBioLabel => 'Descripción del rol';

  @override
  String get createDramaRoleBioHint => 'Introduce la descripción del rol';

  @override
  String get createDramaRoleBioRequired =>
      'La descripción del rol es obligatoria';

  @override
  String get createDramaRoleAddTitle => 'Añadir rol';

  @override
  String get createDramaRoleEditTitle => 'Editar rol';

  @override
  String get createDramaRoleUploadAvatar => 'Subir foto de perfil';

  @override
  String get createDramaRoleSave => 'Guardar';

  @override
  String get createDramaRoleDeleteConfirm => '¿Eliminar este personaje?';

  @override
  String createDramaVideoDeleteConfirm(String name) {
    return '¿Eliminar \"$name\"?';
  }

  @override
  String get createDramaVideoDeleteTitle => 'Eliminar video';

  @override
  String get createDramaVideoPreviewUnavailable =>
      'Los videos subidos anteriormente no se pueden previsualizar por el momento';

  @override
  String get createDramaRoleEmpty => 'No se han añadido roles aún';

  @override
  String get createDramaRoleBindComingSoon =>
      'Vinculación de roles próximamente';

  @override
  String get createDramaRoleAvatarCropTitle => 'Recortar avatar del rol';

  @override
  String get createDramaRoleAvatarUploadFailed =>
      'Error al subir avatar del rol';

  @override
  String get createDramaPublishedSuccess => 'Publicado correctamente';

  @override
  String get createDramaDraftRestored =>
      'Se restauró tu borrador sin finalizar';

  @override
  String get createDramaDraftClear => 'Borrar datos';

  @override
  String get createDramaDraftDiscard => 'Descartar y volver';

  @override
  String get createDramaDraftSave => 'Guardar borrador';

  @override
  String get createDramaEditLoading => 'Cargando...';

  @override
  String get createDramaEditLoadError =>
      'Error al cargar la información del drama, por favor intenta de nuevo';

  @override
  String get createDramaSubmitValidationTitle =>
      'Por favor ingresa el título del drama';

  @override
  String get createDramaSubmitValidationCover =>
      'Por favor sube una imagen de portada';

  @override
  String get createDramaSubmitValidationVideos =>
      'Por favor sube al menos un video';

  @override
  String get createDramaSubmitValidationSession =>
      'Sesión de subida inválida, por favor vuelve a subir los videos';

  @override
  String get createDramaUploadSessionFailed =>
      'Error al crear la sesión de subida';

  @override
  String get createDramaSubmitValidationRoles =>
      'Por favor agrega al menos un rol';

  @override
  String get createDramaStep1TitleRequired => 'Introduce el título del sketch';

  @override
  String get createDramaStep1SynopsisRequired =>
      'Escriba una breve descripción';

  @override
  String get createDramaStep1CoverRequired => 'Por favor agrega una portada';

  @override
  String get createDramaStep1TagsRequired => 'Por favor selecciona etiquetas';

  @override
  String get createDramaEpisodeDescriptionRequired =>
      'Por favor introduce la descripción del episodio';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsThemeLight => 'Claro';

  @override
  String get settingsThemeDark => 'Oscuro';

  @override
  String get settingsThemeSystem => 'Sistema';

  @override
  String get settingsUI => 'Interfaz';

  @override
  String get settingsAppVersion => 'Versión';

  @override
  String get settingsVersionLatestToast => 'Estás en la última versión';

  @override
  String get settingsVersionCheckFailed =>
      'No se pudo comprobar la actualización. Inténtalo de nuevo más tarde.';

  @override
  String get appVersionUpdateTitle => 'Nueva versión disponible';

  @override
  String get appVersionUpdateContentsLabel => 'Contenido de la actualización:';

  @override
  String get appVersionUpdateConfirm => 'Actualizar ahora';

  @override
  String get appVersionUpdateLater => 'Más tarde';

  @override
  String get settingsTermsOfService => 'Términos de servicio';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsDeleteAccount => 'Eliminar cuenta';

  @override
  String settingsDeleteAccountConfirm(String deadline) {
    return 'Tu cuenta se eliminará el $deadline. Durante este período, puedes iniciar sesión de nuevo para cancelar la eliminación de la cuenta.';
  }

  @override
  String get settingsDeleteAccountSuccess =>
      'Solicitud de eliminación de cuenta enviada';

  @override
  String get settingsClearCache => 'Limpiar caché';

  @override
  String get settingsNetworkInspector => 'Inspector de red';

  @override
  String get settingsClearCacheConfirm => '¿Estás seguro de limpiar la caché?';

  @override
  String get miningRulesHowToPlay => '¿Cómo se juega a «Envío de mineros»?';

  @override
  String get miningRulesFlowSubtitle =>
      'Todo el proceso, desde el envío de personal hasta el cobro, explicado en un solo gráfico';

  @override
  String get miningRulesSection1Title =>
      '1. Enviar a alguien a extraer minerales';

  @override
  String get miningRulesSection1Desc =>
      'Si «asignas» a un rol que esté libre a cualquiera de las 5 ranuras siguientes, empezará a minar automáticamente y a generar STORY.';

  @override
  String get miningRulesSection1Bullet1 =>
      'Cada persona puede enviar un máximo de 5 roles a la vez.';

  @override
  String get miningRulesSection1Bullet2 =>
      'Se pueden asignar varias tarjetas a un mismo personaje IP';

  @override
  String get miningRulesSection1Bullet3 =>
      'Cada hora tras su envío se consume 1 punto de ⚡energía; mientras la energía sea &gt; 0, la producción continúa; cuando la energía sea = 0, se detiene la producción.';

  @override
  String get miningRulesSection2Title =>
      '2. Cálculo de beneficios, fórmula de rendimiento';

  @override
  String get miningRulesSection2Desc =>
      'La producción por tarjeta y por hora se calcula de la siguiente manera:';

  @override
  String get miningRulesSection2Formula =>
      'Producción por hora por tarjeta = Salario del personaje × 1 STORY';

  @override
  String get miningRulesSection2FactorsTitle => 'Tres froles determinantes:';

  @override
  String get miningRulesSection2Factor1 =>
      'Coeficiente de minería: cuanto mayor sea el nivel, mayor será el coeficiente. Nivel 1 = 1,0 → Nivel 2 = 2,2 → Nivel 3 = 5,0 → Nivel 4 = 11 → Nivel 5 = 24';

  @override
  String get miningRulesSection2Factor2 =>
      'Salario de IP = Coeficiente de precio × Coeficiente de popularidad × Trust1';

  @override
  String get miningRulesSection2Factor3 =>
      'R_base: valor fijo, actualmente es 1 STORY; es posible que se ajuste manualmente en el futuro.';

  @override
  String miningRulesSection2Factor4(String currency1, String currency2) {
    return 'Coeficiente de precio — precio de emisión P0: crecimiento lineal si P0≤10$currency1 · se aproxima al límite de 1,6 si P0>10$currency2';
  }

  @override
  String get miningRulesSection2Factor5 =>
      'Coeficiente de popularidad — cuanto mejor sea el rendimiento reciente de los dramas, mayor será la popularidad (reproducciones completas, Me gusta, guardados y comentarios)';

  @override
  String get miningRulesSection2Factor6 =>
      'Coeficiente de CP — aún no disponible; Trust tiene un valor predeterminado de 1,0';

  @override
  String miningRulesSection2StaminaText(int staminaLimit) {
    return 'La energía solo se mide por «si la tienes o no», no por cuánta te queda: tanto $staminaLimit puntos como 1 punto de energía producen lo mismo por hora; lo único que importa es si estás minando o no.';
  }

  @override
  String get miningRulesSection2ExampleTitle => 'Por ejemplo:';

  @override
  String miningRulesSection2ExampleDesc(String currency) {
    return 'Lin Mengyao · Protagonista Lv3 · P0=12$currency (coeficiente de precio ≈1.0859) · popularidad 3.5\n→ Producción por hora = 5.0 × 1.0859 × 3.5 × 1 = 19.00325 STORY';
  }

  @override
  String get miningRulesCoefTableTitle => 'Detalles de coeficientes';

  @override
  String get miningRulesCoefColCoef => 'Coeficiente';

  @override
  String get miningRulesCoefColFactor => 'Determinado por';

  @override
  String get miningRulesCoefColDesc => 'Detalles';

  @override
  String get miningRulesCoefMining => 'Coeficiente de minería';

  @override
  String get miningRulesCoefPrice => 'Coeficiente de precio';

  @override
  String get miningRulesCoefHeat => 'Coeficiente de popularidad';

  @override
  String get miningRulesCoefCp => 'Coeficiente de CP';

  @override
  String get miningRulesCoefTrust => 'Trust';

  @override
  String get miningRulesCoefMiningFactor => 'Nivel';

  @override
  String get miningRulesCoefPriceFactor => 'Precio de lanzamiento P0';

  @override
  String get miningRulesCoefHeatFactor => 'Rendimiento reciente de los dramas';

  @override
  String get miningRulesCoefCpFactor => '-';

  @override
  String get miningRulesCoefTrustFactor =>
      'Control de riesgos de la plataforma';

  @override
  String get miningRulesCoefMiningDesc =>
      'Lv1=1.0 · Lv2=2.2 · Lv3=5.0 · Lv4=11 · Lv5=24';

  @override
  String miningRulesCoefPriceDesc(String currency1, String currency2) {
    return 'Lineal si P0≤10$currency1 · límite asintótico de 1,6 si P0>10$currency2';
  }

  @override
  String get miningRulesCoefHeatDesc =>
      'Coeficiente de popularidad: cuantas más reproducciones completas, «me gusta», guardados y valoraciones tengan las series de la IP del personaje, mayor será la popularidad';

  @override
  String get miningRulesCoefCpDesc => 'Aún no disponible';

  @override
  String get miningRulesCoefTrustDesc => 'Valor predeterminado: 1,0';

  @override
  String get miningRulesSection3Title =>
      '3. Se reparte dinero, pero hay un límite máximo';

  @override
  String get miningRulesSection3Desc =>
      'Cada semana toda la plataforma tiene un fondo de recompensas total (límite semanal fijo), comenzando en aproximadamente 2,115,385 STORY, disminuyendo semana a semana (semanal × 0.99572). La distribución de recompensas se divide en tres casos:';

  @override
  String get miningRulesSettleColCondition => 'Condición';

  @override
  String get miningRulesSettleColRule => 'Regla de distribución';

  @override
  String get miningRulesSection3Case1Title =>
      'Producción nominal en todas las plataformas ≤ Bote de esta semana';

  @override
  String get miningRulesSection3Case1Desc =>
      'Cada persona recibirá la cantidad indicada en la lista; el fondo de premios restante no se repartirá ni se completará.';

  @override
  String get miningRulesSection3Case2Title =>
      'Producción nominal en todas las plataformas &gt; Bote de esta semana';

  @override
  String get miningRulesSection3Case2Desc =>
      'Escalado proporcional: tu ganancia real = tu producción nominal × fondo de recompensas ÷ producción total de la plataforma';

  @override
  String get miningRulesSection3Case3Title =>
      'Una sola dirección supera el 5 % del fondo de recompensas';

  @override
  String get miningRulesSection3Case3Desc =>
      'La parte que exceda el límite no se abonará, no se revertirá ni se compensará con puntos adicionales.';

  @override
  String get miningRulesSection3ExampleDesc =>
      'Suponiendo que el fondo de recompensas semanal es 100,000 STORY:\nCaso A: Eres la única persona en la plataforma, y produces 134 en una semana → Obtienes 134, y los 99,866 restantes no se distribuyen\nCaso B: La producción total de la plataforma es 250,000, todos se escalan al 40% (100,000÷250,000)\nCaso C: Las recompensas proporcionales para alguien son 6,000, pero la dirección individual está limitada a 5,000 → Solo se distribuyen 5,000';

  @override
  String get miningRulesSection4Title =>
      '4. Hay que cuidar la energía para poder seguir excavando';

  @override
  String get miningRulesTableStatus => 'Estado';

  @override
  String get miningRulesTableStaminaChange => 'Cambios en la energía';

  @override
  String get miningRulesTableOutput => 'Resultados';

  @override
  String get miningRulesStatusMining => 'En proceso de asignación (minería)';

  @override
  String get miningRulesStaminaMining => 'Por hora -1';

  @override
  String get miningRulesOutputNormal => 'Producción normal';

  @override
  String get miningRulesStatusZeroStamina => 'Energía = 0';

  @override
  String get miningRulesStaminaZeroStamina => 'Ya no cambia';

  @override
  String get miningRulesOutputZero => 'El resultado es 0';

  @override
  String get miningRulesStatusResting => 'Descanso por convocatoria';

  @override
  String get miningRulesStaminaResting =>
      '+1 por hora (recuperación automática)';

  @override
  String get miningRulesOutputPaused => 'Suspender la producción';

  @override
  String get miningRulesStatusPaidRefill => 'Recargar energía (de pago)';

  @override
  String miningRulesStaminaPaidRefill(int staminaLimit) {
    return 'Recarga instantánea de $staminaLimit';
  }

  @override
  String get miningRulesOutputRestored => 'Recuperación de la producción';

  @override
  String get miningRulesSection4TipsTitle =>
      'Tres cosas que debes saber sobre la recuperación de la energía:';

  @override
  String get miningRulesSection4Tip1 =>
      'Solo se puede repostar hasta el máximo con un solo clic; no se puede comprar solo 10 puntos.';

  @override
  String get miningRulesSection4Tip2 =>
      'El precio depende únicamente del nivel, no de la energía que te quede. Cuesta lo mismo recargar al máximo cuando la energía está a 0 que cuando está a 100.';

  @override
  String get miningRulesSection4Tip3 =>
      'Cuanto más se acerque a 0, más rentable es la recarga: por el mismo precio, obtienes el máximo tiempo adicional de minería.';

  @override
  String get miningRulesSection4PriceTitle =>
      'Precios adicionales según el nivel:';

  @override
  String get miningRulesPriceTableTier => 'Importancia';

  @override
  String get miningRulesPriceTableFullRefill =>
      'Llenar el depósito con un solo clic';

  @override
  String get miningRulesLv1 => 'Nivel 1: Figurante';

  @override
  String get miningRulesLv2 => 'Nivel 2: Personaje secundario';

  @override
  String get miningRulesLv3 => 'Nivel 3: Protagonista';

  @override
  String get miningRulesLv4 => 'Nivel 4: Superestrella';

  @override
  String get miningRulesLv5 => 'Nivel 5: Superestrella';

  @override
  String get gameActorLevelName1 => 'Extra';

  @override
  String get gameActorLevelName2 => 'De reparto';

  @override
  String get gameActorLevelName3 => 'Protagonista';

  @override
  String get gameActorLevelName4 => 'Superestrella';

  @override
  String get gameActorLevelName5 => 'Primer nivel';

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
  String get miningRulesSection5Title => '5. Sube de categoría y gana más';

  @override
  String get miningRulesSection5Desc =>
      '3 tarjetas de personajes del mismo nivel + la tarifa de síntesis + alcanzar el objetivo de reproducciones completas acumuladas de dicho personaje = subir 1 nivel. Tras subir de nivel, el coeficiente de minería se dispara y la producción por hora se duplica o incluso se multiplica varias veces.';

  @override
  String get miningRulesUpgradePathSubtitle => 'Ruta de mejora';

  @override
  String get miningRulesUpgradeColPath => 'Ruta de mejora';

  @override
  String get miningRulesUpgradeColHeat =>
      'Umbral de reproducciones completas acumuladas';

  @override
  String get miningRulesUpgradeColFee => 'Comisión de síntesis';

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
  String get miningRulesSummaryTitle => 'Resumen en una frase';

  @override
  String get miningRulesSummaryDesc =>
      'Asigna → Produce → Vigila la energía → Cobra. Cuando la energía esté baja, recárgala o devuelve al personaje a descansar; la popularidad crece con el rendimiento de las series del personaje, y mejorar multiplica la producción.';

  @override
  String get playerNotInterested => 'No me interesa';

  @override
  String get playerNotInterestedDone =>
      'Hemos recibido tu comentario. Mostraremos menos contenido como este';

  @override
  String get playerClearScreen => 'Pantalla limpia';

  @override
  String get playerAutoPlay => 'Reproducción continua';

  @override
  String get playerReport => 'Reportar';

  @override
  String get playerReportSuccess => 'Reportado exitosamente';

  @override
  String get commentReportSuccess =>
      'Enviado con éxito, lo procesaremos pronto';

  @override
  String get reportSuccessTitle => 'Enviado con éxito, lo procesaremos pronto';

  @override
  String get reportSuccessThanks =>
      '¡Gracias por contribuir a la seguridad de la comunidad!';

  @override
  String get reportSuccessAlsoYouCan => 'También puedes';

  @override
  String get reportSuccessDone => 'Listo';

  @override
  String get reportReduceRecommend => 'Ver menos';

  @override
  String get reportReduceRecommendDone => 'Mostraremos menos';

  @override
  String get reportSuccessContentFallback => 'Este contenido';

  @override
  String get reportDescription => 'Descripción del reporte';

  @override
  String get reportDescriptionPlaceholder => 'Describe los detalles (Opcional)';

  @override
  String get reportReasonPorn => 'Pornografía y vulgaridad';

  @override
  String get reportReasonIllegal => 'Ilegal o criminal';

  @override
  String get reportReasonSensitive => 'Contenido sensible';

  @override
  String get reportReasonGambling => 'Juegos de azar o violencia';

  @override
  String get reportReasonMinors => 'Daño a menores';

  @override
  String get reportReasonCopyright => 'Infracción de derechos de autor';

  @override
  String get reportReasonQuality => 'Problema de calidad';

  @override
  String get reportReasonNotLike => 'No me gusta';

  @override
  String get reportReasonOther => 'Otros';

  @override
  String get gameUpgrade => 'Mejorar';

  @override
  String get gameUpgradeTitle => 'Mejora de Nivel';

  @override
  String get gameUpgradeCurrentLevel => 'Nivel Actual';

  @override
  String get gameUpgradeTargetLevel => 'Nivel Objetivo';

  @override
  String get gameUpgradeHeatThreshold =>
      'Reproducciones completas acumuladas de dramas';

  @override
  String get gameUpgradeRequiredCount => 'Consumir roles del mismo IP y nivel';

  @override
  String get gameUpgradeFee => 'Costo de Mejora';

  @override
  String get gameUpgradeNextLevelReq => 'Requisitos del siguiente nivel';

  @override
  String get gameUpgradeBeforeAfter => 'Antes y después de mejorar';

  @override
  String get gameUpgradeSelectMaterialDesc =>
      'Seleccionar roles del mismo IP y nivel para consumir';

  @override
  String gameUpgradeMaterialCount(int current, int required) {
    return '$current/$required';
  }

  @override
  String gameUpgradeToLevel(int level, String levelName) {
    return 'Mejorar a Lv$level $levelName';
  }

  @override
  String gameUpgradeSelectMaterialLabel(int current, int required) {
    return 'Seleccionar Materiales ($current/$required)';
  }

  @override
  String gameUpgradeSelectMaterials(int count) {
    return 'Seleccione $count materiales';
  }

  @override
  String get gameUpgradeConfirm => 'Confirmar Mejora';

  @override
  String get gameUpgradeSuccess => 'Mejora exitosa';

  @override
  String get gameUpgradeFailed => 'Mejora fallida, por favor intente de nuevo';

  @override
  String get gameUpgradeInsufficientMaterials => 'Materiales insuficientes';

  @override
  String get gameUpgradeNoMaterials =>
      'No hay roles del mismo IP y nivel disponibles para consumir';

  @override
  String get creatorDramaStatusMinted => 'Acuñado';

  @override
  String get creatorDramaStatusOffline => 'Retirado';

  @override
  String get creatorDramaStatusUnavailable => 'Temporalmente no disponible';

  @override
  String get creatorMintDramaNft => 'Acuñar NFT del drama';

  @override
  String get creatorMintConfirmDesc =>
      'Confirmar acuñación de este drama como NFT en cadena. Después de acuñar, este drama generará recompensas de minería STORY.';

  @override
  String get creatorMintFee => 'Tarifa de acuñación';

  @override
  String creatorMintInsufficientUsdc(String currency1, String currency2) {
    return 'Saldo $currency1 insuficiente. El lanzamiento en cadena requiere al menos 1 $currency2.';
  }

  @override
  String get creatorMintInvalidDramaId => 'ID de drama no válido';

  @override
  String get creatorMintInProgress => 'Acuñación en curso, por favor espera';

  @override
  String get creatorMintWalletNotReady =>
      'La dirección de la wallet de Solana no está lista. Inicia sesión de nuevo';

  @override
  String get creatorMintDigestEmpty =>
      'Los datos de la firma de lanzamiento están vacíos. Inténtalo de nuevo más tarde.';

  @override
  String get creatorMintWalletMismatch =>
      'La wallet de acuñación no coincide con la wallet actual. Inicia sesión de nuevo';

  @override
  String get creatorMintSuccess => '¡Acuñación exitosa!';

  @override
  String creatorMintDramaOnChain(String name) {
    return 'El NFT del drama \"$name\" ha sido acuñado en cadena';
  }

  @override
  String creatorMintNftNumber(String id) {
    return 'Número de NFT: $id';
  }

  @override
  String get creatorMintTxHash => 'Hash de transacción: ';

  @override
  String get gameSelectActor => 'Seleccionar rol para desplegar';

  @override
  String get gameSelectActorDesc =>
      'Selecciona un personaje inactivo para enviarlo a trabajar';

  @override
  String get agentV2SchedulePerformance => 'Actuar';

  @override
  String get agentV2PerformAllTitle => 'Actuar Todo';

  @override
  String get agentV2PerformAllDescription =>
      'Los personajes con mayor salario ocuparán primero los puestos disponibles';

  @override
  String get agentV2PerformAllFailed =>
      'La actuación con un toque ha fallado. Inténtalo de nuevo';

  @override
  String get agentV2PerformAllSuccess => 'Actuación con un toque completada';

  @override
  String agentV2PerformAllDepletedResult(int successCount, int depletedCount) {
    return '$successCount actuaron correctamente; $depletedCount no pueden actuar por falta de energía';
  }

  @override
  String get agentV2RestAllSuccess => 'Descanso con un toque completado';

  @override
  String agentV2PerformAllCount(int count) {
    return '$count personajes';
  }

  @override
  String get agentV2TodoTitle => 'Pendientes';

  @override
  String agentV2TodoVacancies(int count) {
    return '$count puesto(s) de actuación disponibles';
  }

  @override
  String agentV2TodoStaminaDepleted(String name) {
    return '$name tiene 0 de energía y dejó de trabajar';
  }

  @override
  String get agentV2TodoPerform => 'Actuar';

  @override
  String get agentV2TodoRefill => 'Recargar';

  @override
  String get agentV2TodoHealthy => 'Actuaciones normales · Energía suficiente';

  @override
  String get agentV2CandidateActorsTitle => 'Roles candidatos';

  @override
  String get agentV2CandidateActorsDescription =>
      'Los roles en descanso recuperan 1 punto de energía por hora';

  @override
  String get agentV2UpgradeableActorsTitle => 'Mejorar roles';

  @override
  String get agentV2UpgradeableActorsEmpty =>
      'No hay roles disponibles para mejorar';

  @override
  String get agentV2NoActors => 'No hay roles';

  @override
  String get agentV2UpgradeNow => 'Mejorar ahora';

  @override
  String get agentV2UpgradeCompletion => 'Reproducciones completas';

  @override
  String get agentV2UpgradeMaterials => 'Roles';

  @override
  String agentV2UpgradeRequirementsTitle(String name) {
    return 'Mejorar $name';
  }

  @override
  String agentV2UpgradeCompletionRemaining(int count) {
    return 'Faltan $count reproducciones completas';
  }

  @override
  String get agentV2UpgradeCompletionHint =>
      'Mira dramas con este personaje o crea uno nuevo para aumentar las reproducciones completas';

  @override
  String get agentV2UpgradeWatchDramas => 'Ver sus dramas';

  @override
  String get agentV2UpgradeCreateDrama => 'Crear un drama';

  @override
  String agentV2UpgradeMaterialsRemaining(int count) {
    return 'Faltan $count roles del mismo IP y nivel';
  }

  @override
  String agentV2UpgradeMaterialsHint(String name) {
    return 'Contrata más personajes «$name» desde el perfil del personaje';
  }

  @override
  String get agentV2UpgradeGetActors => 'Obtener roles';

  @override
  String agentV2UpgradeActorsSyncing(int count) {
    return 'Sincronizando $count personaje(s) nuevo(s); se actualizaron los requisitos de mejora';
  }

  @override
  String get agentV2UpgradeConfirmSelectMaterials =>
      'Selecciona personajes del mismo IP y nivel para consumir';

  @override
  String get agentV2UpgradeConfirmSalaryLabel => 'Salario';

  @override
  String get agentV2SalaryDetailTitle => 'Salario del personaje';

  @override
  String get agentV2SalaryHourly => 'Salario por hora';

  @override
  String get agentV2SalaryUnit => 'STORY / hora';

  @override
  String get agentV2SalaryFormula =>
      'Salario del personaje = Salario de IP × Coeficiente salarial × Coeficiente CP × Trust2';

  @override
  String get agentV2SalaryFormulaLv1 =>
      'Salario del personaje Lv.1 = Coeficiente de precio × Coeficiente de popularidad';

  @override
  String agentV2SalaryFormulaLevel(int level) {
    return 'Salario Lv.$level = Salario Lv.1 × Coeficiente salarial';
  }

  @override
  String get agentV2SalaryLv1Pay => 'Salario Lv.1';

  @override
  String get agentV2SalaryCoefficient => 'Coeficiente salarial';

  @override
  String agentV2SalaryCoefficientWithLevel(int level, String roleName) {
    return 'Coeficiente salarial (Lv.$level $roleName)';
  }

  @override
  String get agentV2SalaryCpCoefficient => 'Coeficiente CP';

  @override
  String get agentV2PerformanceConfirmDescription =>
      'Este personaje gana salario automáticamente al actuar. Cada hora de actuación consume 1 punto de energía; cuando la energía se agota, deja de ganar.';

  @override
  String get agentV2PerformanceConfirmTitle => 'Programar actuación';

  @override
  String get agentV2PerformanceZeroFeePrefix =>
      'La IP de este personaje actualmente tiene ';

  @override
  String get agentV2PerformanceZeroFeeHighlight => 'remuneración 0';

  @override
  String get agentV2PerformanceZeroFeeSuffix =>
      ', por lo que la actuación no generará ingresos. Además, durante la actuación se consume 1 punto de energía por hora. ¿Quieres continuar?';

  @override
  String get agentV2PerformanceScheduledSuccess => 'Actuación programada';

  @override
  String get agentV2PerformanceSlotsFull =>
      'Los espacios de actuación están llenos (máx. 5)';

  @override
  String get gameDeployStaminaDepleted =>
      'La energía se ha agotado. Recárgala antes de actuar';

  @override
  String get agentMoreRules => 'Reglas';

  @override
  String get agentMoreSalaryAndPool => 'Salario y fondo de recompensas';

  @override
  String get agentV2WeeklySalaryTitle => 'Subir Nivel · Actuar · Ganar Salario';

  @override
  String get agentV2WeeklySalaryLabel => 'Salario de esta semana';

  @override
  String get gameDeployConfirmDesc =>
      'Este personaje participará automáticamente en la minería mediante staking y generará continuamente ganancias en STORY para ti. Nota: Se consume 1 punto de energía al comienzo de cada hora. La generación de ganancias se detiene cuando se agota la energía.';

  @override
  String get gameRecallConfirm => 'Confirmar retiro';

  @override
  String get gameRecallDesc =>
      'Retirar a este personaje pausará las recompensas de producción de dramas, pero la energía actual no se verá afectada.';

  @override
  String get actorStatCompletionTitle => 'Reproducciones completas';

  @override
  String get actorStatCompletionDesc =>
      'Total de reproducciones completas en todos los dramas en los que ha participado este personaje';

  @override
  String get actorStatHeatTitle => 'Popularidad';

  @override
  String get actorStatHeatDesc =>
      'Popularidad total de los últimos 30 días de todas las miniseries en las que participa este IP de personaje';

  @override
  String get actorStatIpPowerTitle => 'Salario IP';

  @override
  String get actorStatIpPowerDesc =>
      'Salario IP = Coeficiente de precio × Coeficiente de calor × Trust1';

  @override
  String get dramaFavoriteLabel => 'Favorito';

  @override
  String get dramaRatingLabel => 'Calificación';

  @override
  String get dramaUnnamed => 'Sin título';

  @override
  String get videoNotReady =>
      'El video no está listo, por favor inténtalo más tarde';

  @override
  String get inviteDirectSubordinates => 'Usuarios invitados';

  @override
  String inviteTotalCount(int count) {
    return 'Total: $count usuarios';
  }

  @override
  String get inviteTotalLabel => 'Total de usuarios';

  @override
  String get inviteActiveLabel => 'Usuarios activos';

  @override
  String get invitePendingLabel => 'Pendiente de activación';

  @override
  String get inviteEmpty => 'Aún no hay usuarios subordinados';

  @override
  String inviteRegisteredAt(String date) {
    return 'Registrado el $date';
  }

  @override
  String get gameUpgradeMaxLevel => 'Nivel máximo alcanzado';

  @override
  String get listNoMoreData => 'No hay más datos';

  @override
  String get iapSheetTitle => 'Comprar puntos';

  @override
  String get iapSheetSubtitle =>
      'Los puntos se usan para servicios de la app, como firmar personajes';

  @override
  String get iapBalance => 'Saldo';

  @override
  String get iapConfirmPurchase => 'Confirmar compra';

  @override
  String get iapPurchaseSuccess => 'Compra exitosa';

  @override
  String get iapPurchaseFailed => 'Compra fallida, inténtalo de nuevo';

  @override
  String get iapPurchaseFailedTitle => 'Compra fallida';

  @override
  String get iapCrediting => 'Acreditación en curso, espere';

  @override
  String get iapNoProducts => 'No hay productos disponibles';

  @override
  String get iapSuccessConfirm => 'Aceptar';

  @override
  String iapGainedPoints(String value) {
    return '+$value';
  }

  @override
  String iapPointsCount(int count) {
    return '$count puntos';
  }

  @override
  String get gameBatchRefillTransactionTooLarge =>
      'La transacción de recarga por lotes es demasiado grande. Reduce el número de actores e inténtalo de nuevo.';

  @override
  String get agentV2RefillTitle => 'Recargar energía';

  @override
  String get agentV2RefillCost => 'Coste';

  @override
  String get agentV2RefillActorButton => 'Este personaje';

  @override
  String get agentV2RefillAllActors =>
      'Recargar todos los personajes en actuación';

  @override
  String agentV2RefillActorCount(int count) {
    return '$count personajes';
  }

  @override
  String get agentV2RefillAllButton => 'Recargar todos';

  @override
  String get agentV2RefillOr => 'o';

  @override
  String get agentV2RestAll => 'Descansar todos';

  @override
  String agentV2RestActorCount(int count) {
    return '$count personajes';
  }

  @override
  String get salaryPoolRateUnit => 'STORY / hora';

  @override
  String get salaryPoolDecayInfo => 'Factor de reducción semanal ×0,99572';

  @override
  String get salaryPoolStakeLabel => 'Fondo de recompensas por actuación (75%)';

  @override
  String get salaryPoolInviteLabel =>
      'Fondo de recompensas por invitación (25%)';

  @override
  String get salaryPoolRule1Title =>
      'Producción nominal total ≤ límite semanal:';

  @override
  String get salaryPoolRule2Title =>
      'Producción nominal total > límite semanal:';

  @override
  String get salaryPoolRule2Body =>
      'Pago real = producción nominal del usuario × (límite semanal ÷ producción nominal total)';

  @override
  String get agentV3WeeklySalary => 'Salario semanal';

  @override
  String get agentV3PerformAll => 'Actuar todo';

  @override
  String get agentV3RestAll => 'Descansar todos';

  @override
  String get agentV3RestAllDescription =>
      'Retira a todos los personajes en actuación para detener el consumo de energía y las ganancias';

  @override
  String get agentV3RefillAll => 'Recargar todos';

  @override
  String get agentV3RefillAllDescription =>
      'Rellena la energía de los personajes en actuación';

  @override
  String get agentV3RefillCost => 'Consume';

  @override
  String get agentV3RefillNoActors =>
      'Ningún personaje necesita recuperar energía';

  @override
  String get agentV3SignActor => 'Firmar personajes';

  @override
  String get agentV3Todo => 'Tareas';

  @override
  String get agentV3Upgrade => 'Mejorar';

  @override
  String agentV3UpgradeMaterialHint(int count) {
    return 'La mejora consume $count personajes con la misma IP y nivel';
  }

  @override
  String get agentV3Waiting => 'En espera';

  @override
  String get agentV3WaitingActorsTitle => 'Personajes en espera';

  @override
  String get agentV3WaitingActorsDescription =>
      'Los personajes en descanso recuperan 1 de energía por hora';

  @override
  String get agentV3Recycle => 'Reciclar';

  @override
  String get agentV3RecycleActorsTitle => 'Reciclar personajes';

  @override
  String get agentV3RecyclePerforming => 'En actuación';

  @override
  String get agentV3RecycleReceive => 'Recibirás';

  @override
  String get agentV3RecyclePermanentWarning =>
      'El personaje se destruirá permanentemente y no se podrá recuperar';

  @override
  String get agentV3RecycleConfirm => 'Confirmar destrucción';

  @override
  String get agentV3RecycleConfirmAgain => 'Toca de nuevo para destruir';

  @override
  String get agentV3RecycleSubmitted => 'Personaje reciclado correctamente';

  @override
  String get agentV3RecycleEstimateUnavailable =>
      'No se puede obtener la estimación de reciclaje. Inténtalo de nuevo';

  @override
  String get agentV3EnergyPack => 'Paquete de energía';

  @override
  String get agentV3EnergyPackDescription =>
      'Restaura por completo la energía del personaje; se consume según su nivel.';

  @override
  String get agentV3TrainingManual => 'Manual de entrenamiento';

  @override
  String get agentV3TrainingManualDescription =>
      'Material para mejorar personajes; se consume según el nivel del personaje al mejorarlo.';

  @override
  String get agentV3PurchaseButton => 'Comprar';

  @override
  String agentV3PurchaseWalletBalance(String balance, String currency) {
    return 'Saldo $balance $currency';
  }

  @override
  String agentV3PurchaseTitle(String item) {
    return 'Comprar $item';
  }

  @override
  String get agentV3PurchaseUnitPrice => 'Precio unitario';

  @override
  String get agentV3PurchaseQuantity => 'Cantidad';

  @override
  String get agentV3PurchaseTotal => 'Total';

  @override
  String get agentV3PurchaseConfirm => 'Confirmar pago';

  @override
  String get agentV3PurchaseUnavailable =>
      'La compra de artículos no está disponible en este entorno';

  @override
  String get agentV3PurchaseConfigUnavailable =>
      'El precio del artículo no está disponible. Inténtalo de nuevo más tarde';

  @override
  String get agentV3PurchaseSubmitted =>
      'Compra realizada. Se añadió a la mochila de objetos (página del Agente)';

  @override
  String get agentV3PurchaseCreditPending =>
      'Los paquetes de energía aún se están acreditando. Inténtalo de nuevo en breve';

  @override
  String get agentV3PurchaseCrediting => 'Verificando y acreditando';

  @override
  String agentV3PurchaseBalance(String count) {
    return 'Disponible: $count';
  }

  @override
  String get agentV3RefillTitle => 'Rellenar energía';

  @override
  String agentV3RefillLevelCost(String level) {
    return 'Nv.$level consume';
  }

  @override
  String get agentV3RefillAvailable => 'Disponible';

  @override
  String get agentV3RefillUse => 'Usar';

  @override
  String get agentV3RefillSuccess => 'Energía rellenada';

  @override
  String agentV3RefillAllSuccess(int actorCount, String packCount) {
    return 'Se recargó la energía de $actorCount personajes (se usaron $packCount paquetes de energía)';
  }

  @override
  String get agentV3RefillConfigUnavailable =>
      'La configuración de consumo no está disponible';

  @override
  String get agentV3RefillInsufficient =>
      'No hay suficientes paquetes de energía';
}
