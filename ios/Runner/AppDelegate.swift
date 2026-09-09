import Flutter
import AudioToolbox
import KTVHTTPCache
import LinkPresentation
import PhotosUI
import UIKit
import UniformTypeIdentifiers
import WebKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let videoCachePreheater = VideoCachePreheater()
  private let videoFilePicker = NativeVideoFilePicker()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Method channels are registered in didInitializeImplicitFlutterEngine —
    // with FlutterImplicitEngineDelegate, window/rootViewController is often
    // nil here, which caused MissingPluginException for video_cache.
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let cloudfrontChannel = FlutterMethodChannel(
      name: "com.cestine.officeapp/cloudfront",
      binaryMessenger: messenger
    )
    cloudfrontChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleCloudFrontCall(call: call, result: result)
    }
    let videoCacheChannel = FlutterMethodChannel(
      name: "com.cestine.officeapp/video_cache",
      binaryMessenger: messenger
    )
    videoCacheChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleVideoCacheCall(call: call, result: result)
    }
    let numberFormatChannel = FlutterMethodChannel(
      name: "com.cestine.officeapp/number_format",
      binaryMessenger: messenger
    )
    numberFormatChannel.setMethodCallHandler { (call, result) in
      Self.handleNumberFormatCall(call: call, result: result)
    }
    let videoFilePickerChannel = FlutterMethodChannel(
      name: "com.cestine.officeapp/video_file_picker",
      binaryMessenger: messenger
    )
    videoFilePickerChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.videoFilePicker.handle(call: call, result: result)
    }
    let hapticsChannel = FlutterMethodChannel(
      name: "com.cestine.officeapp/haptics",
      binaryMessenger: messenger
    )
    hapticsChannel.setMethodCallHandler { (call, result) in
      Self.handleHapticsCall(call: call, result: result)
    }
    let shareChannel = FlutterMethodChannel(
      name: "com.cestine.officeapp/share",
      binaryMessenger: messenger
    )
    shareChannel.setMethodCallHandler { [weak self] (call, result) in
      self?.handleShareCall(call: call, result: result)
    }
    let deviceChannel = FlutterMethodChannel(
      name: "com.cestine.officeapp/device",
      binaryMessenger: messenger
    )
    deviceChannel.setMethodCallHandler { (call, result) in
      switch call.method {
      case "setKeepScreenOn":
        let keepOn = (call.arguments as? Bool) ?? false
        DispatchQueue.main.async {
          UIApplication.shared.isIdleTimerDisabled = keepOn
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// Hosts [UIActivityViewController] above Flutter PlatformViews so outside
  /// taps on the dimming view dismiss the sheet (UiKitView otherwise steals
  /// hits when share is presented from the Flutter view controller).
  private var shareHostWindow: UIWindow?

  private func handleShareCall(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "shareText":
      guard let args = call.arguments as? [String: Any],
            let text = args["text"] as? String,
            !text.isEmpty
      else {
        result(FlutterError(
          code: "invalid_args",
          message: "text is required",
          details: nil
        ))
        return
      }
      let subject = args["subject"] as? String
      let originX = args["originX"] as? Double
      let originY = args["originY"] as? Double
      let originW = args["originW"] as? Double
      let originH = args["originH"] as? Double
      var origin: CGRect?
      if let originX, let originY, let originW, let originH,
         originW >= 1, originH >= 1 {
        origin = CGRect(x: originX, y: originY, width: originW, height: originH)
      }
      // Subject becomes the share-sheet preview title when LinkPresentation
      // metadata is available.
      presentElevatedShare(
        text: text,
        title: subject,
        origin: origin,
        result: result
      )
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func presentElevatedShare(
    text: String,
    title: String?,
    origin: CGRect?,
    result: @escaping FlutterResult
  ) {
    DispatchQueue.main.async { [weak self] in
      guard let self else {
        result(nil)
        return
      }
      // Tear down any prior host so we never stack share windows.
      self.teardownShareHostWindow()

      let scene = UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }
        ?? UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .first

      let window: UIWindow
      if let scene {
        window = UIWindow(windowScene: scene)
      } else {
        window = UIWindow(frame: UIScreen.main.bounds)
      }
      // Above Flutter's PlatformView touch layer / alert overlays.
      window.windowLevel = .alert + 1
      window.backgroundColor = .clear

      let host = UIViewController()
      host.view.backgroundColor = .clear
      window.rootViewController = host
      window.makeKeyAndVisible()
      self.shareHostWindow = window

      let icon = Self.storyShareAppIcon()
      let item = StoryShareItemSource(text: text, title: title, icon: icon)
      let activity = UIActivityViewController(
        activityItems: [item],
        applicationActivities: nil
      )
      if let popover = activity.popoverPresentationController {
        popover.sourceView = host.view
        if let origin {
          popover.sourceRect = origin
        } else {
          let bounds = host.view.bounds
          popover.sourceRect = CGRect(
            x: bounds.midX,
            y: bounds.midY,
            width: 1,
            height: 1
          )
        }
        popover.permittedArrowDirections = []
      }

      var didFinish = false
      let finish: () -> Void = { [weak self] in
        guard !didFinish else { return }
        didFinish = true
        self?.teardownShareHostWindow()
        result(nil)
      }

      activity.completionWithItemsHandler = { _, _, _, _ in
        DispatchQueue.main.async(execute: finish)
      }

      host.present(activity, animated: true, completion: nil)
    }
  }

  private func teardownShareHostWindow() {
    guard let window = shareHostWindow else { return }
    shareHostWindow = nil
    window.rootViewController?.dismiss(animated: false)
    window.isHidden = true
    window.rootViewController = nil
    // Return key window to Flutter so input / lifecycle stay normal.
    let scene = window.windowScene
      ?? UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first
    let flutterWindow = scene?.windows.first(where: { candidate in
      candidate !== window && !candidate.isHidden
    })
    flutterWindow?.makeKeyAndVisible()
  }

  /// Haptics that still work while AVPlayer holds a movie-playback session.
  private static func handleHapticsCall(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "impact":
      // 1520 = medium peek (works even when UIImpactFeedbackGenerator is muted
      // by an active AVAudioSession movie-playback category).
      AudioServicesPlaySystemSound(1520)
      let generator = UIImpactFeedbackGenerator(style: .medium)
      generator.prepare()
      generator.impactOccurred()
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Reads separators from the current Locale so iOS "Number Format" settings
  /// (independent of app language) are reflected.
  private static func handleNumberFormatCall(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "getSeparators":
      let locale = Locale.autoupdatingCurrent
      result([
        "decimalSeparator": locale.decimalSeparator ?? ".",
        "groupingSeparator": locale.groupingSeparator ?? ",",
      ])
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func handleCloudFrontCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any] else {
      result(FlutterError(code: "invalid_args", message: "missing args", details: nil))
      return
    }
    switch call.method {
    case "applyCookies":
      let policy = args["policy"] as? String ?? ""
      let signature = args["signature"] as? String ?? ""
      let keyPairId = args["keyPairId"] as? String ?? ""
      let mediaUrl = args["mediaAccessUrl"] as? String ?? ""
      let expires = args["expires"] as? Int ?? 0

      if policy.isEmpty || signature.isEmpty || keyPairId.isEmpty || mediaUrl.isEmpty {
        result(FlutterError(code: "invalid_args", message: "missing cookie fields", details: nil))
        return
      }
      guard let url = URL(string: mediaUrl), let host = url.host else {
        result(FlutterError(code: "invalid_url", message: "bad media url", details: nil))
        return
      }
      let domainParts = host.split(separator: ".")
      let cookieDomain: String
      if domainParts.count >= 2 {
        cookieDomain = ".\(domainParts.suffix(2).joined(separator: "."))"
      } else {
        cookieDomain = host
      }

      let storage = HTTPCookieStorage.shared
      let cookieProperties: [[HTTPCookiePropertyKey: Any]] = [
        [
          .domain: cookieDomain,
          .path: "/",
          .secure: "TRUE",
          .name: "CloudFront-Policy",
          .value: policy,
        ],
        [
          .domain: cookieDomain,
          .path: "/",
          .secure: "TRUE",
          .name: "CloudFront-Signature",
          .value: signature,
        ],
        [
          .domain: cookieDomain,
          .path: "/",
          .secure: "TRUE",
          .name: "CloudFront-Key-Pair-Id",
          .value: keyPairId,
        ],
      ]
      for props in cookieProperties {
        if let cookie = HTTPCookie(properties: props) {
          storage.setCookie(cookie)
        }
      }
      result(nil)

    case "clearCookies":
      let mediaUrl = args["mediaAccessUrl"] as? String ?? ""
      if mediaUrl.isEmpty {
        result(nil)
        return
      }
      guard let url = URL(string: mediaUrl), let host = url.host else {
        result(nil)
        return
      }
      Self.clearCloudFrontCookies(for: url, host: host)
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// AVPlayer reads `HTTPCookieStorage.shared`. `deleteCookie` only removes
  /// instances obtained from the store — a newly constructed cookie with the
  /// same name does not match, so leftover CloudFront-Policy cookies survive
  /// and 403 unsigned recommend playback.
  private static func clearCloudFrontCookies(for url: URL, host: String) {
    let names: Set<String> = [
      "CloudFront-Policy",
      "CloudFront-Signature",
      "CloudFront-Key-Pair-Id",
    ]
    let storage = HTTPCookieStorage.shared
    var seen = Set<ObjectIdentifier>()
    var toDelete: [HTTPCookie] = []
    let candidates = (storage.cookies ?? []) + (storage.cookies(for: url) ?? [])
    for cookie in candidates {
      let id = ObjectIdentifier(cookie)
      if seen.contains(id) { continue }
      seen.insert(id)
      guard names.contains(cookie.name) else { continue }
      if cookieMatchesHost(cookie.domain, host: host) {
        toDelete.append(cookie)
      }
    }
    for cookie in toDelete {
      storage.deleteCookie(cookie)
    }
  }

  private static func cookieMatchesHost(_ cookieDomain: String, host: String) -> Bool {
    let domain = cookieDomain.hasPrefix(".")
      ? String(cookieDomain.dropFirst())
      : cookieDomain
    return host == cookieDomain
      || host == domain
      || host.hasSuffix(".\(domain)")
  }

  private func handleVideoCacheCall(call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any] ?? [:]
    switch call.method {
    case "initialize":
      do {
        if !KTVHTTPCache.proxyIsRunning() {
          try KTVHTTPCache.proxyStart()
        }
        let maxBytes = (args["maxCacheBytes"] as? NSNumber)?.int64Value
          ?? 250 * 1024 * 1024
        KTVHTTPCache.cacheSetMaxCacheLength(maxBytes)
        KTVHTTPCache.downloadSetWhitelistHeaderKeys([
          "User-Agent", "Connection", "Accept", "Accept-Encoding",
          "Accept-Language", "Range", "Cookie", "Referer", "Authorization",
        ])
        result(true)
      } catch {
        result(
          FlutterError(
            code: "cache_init_failed",
            message: error.localizedDescription,
            details: nil
          )
        )
      }

    case "proxyUrl":
      guard
        KTVHTTPCache.proxyIsRunning(),
        let value = args["url"] as? String,
        let url = URL(string: value)
      else {
        result(args["url"])
        return
      }
      result(
        KTVHTTPCache.proxyURL(withOriginalURL: url)?.absoluteString
          ?? url.absoluteString
      )

    case "precache":
      guard
        KTVHTTPCache.proxyIsRunning(),
        let value = args["url"] as? String,
        let url = URL(string: value)
      else {
        result(false)
        return
      }
      let headers = args["headers"] as? [String: String] ?? [:]
      let maxBytes = (args["maxBytes"] as? NSNumber)?.intValue ?? 2 * 1024 * 1024
      // Complete only when the warm-up requests finish so the Dart-side
      // concurrency limiter actually bounds parallel downloads.
      videoCachePreheater.warm(url: url, headers: headers, maxBytes: maxBytes) {
        DispatchQueue.main.async { result(true) }
      }

    case "cacheSize":
      result(NSNumber(value: KTVHTTPCache.cacheTotalCacheLength()))

    case "cacheClear":
      KTVHTTPCache.cacheDeleteAllCaches()
      URLCache.shared.removeAllCachedResponses()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Best-effort App Icon for the share-sheet preview header.
  private static func storyShareAppIcon() -> UIImage? {
    let candidates = [
      "Icon-App-1024x1024@1x",
      "Icon-App-60x60@3x",
      "Icon-App-60x60@2x",
      "AppIcon",
    ]
    if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
       let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
       let files = primary["CFBundleIconFiles"] as? [String] {
      for name in files.reversed() {
        if let image = UIImage(named: name) {
          return image.storyShareFilledIcon(side: 240)
        }
      }
    }
    for name in candidates {
      if let image = UIImage(named: name) {
        return image.storyShareFilledIcon(side: 240)
      }
    }
    return nil
  }
}

/// Supplies share text plus LinkPresentation metadata so the sheet preview
/// shows the StoryFun app icon instead of the generic plain-text glyph.
private final class StoryShareItemSource: NSObject, UIActivityItemSource {
  private let text: String
  private let title: String?
  private let icon: UIImage?

  init(text: String, title: String?, icon: UIImage?) {
    self.text = text
    self.title = title
    self.icon = icon
  }

  func activityViewControllerPlaceholderItem(
    _ activityViewController: UIActivityViewController
  ) -> Any {
    text
  }

  func activityViewController(
    _ activityViewController: UIActivityViewController,
    itemForActivityType activityType: UIActivity.ActivityType?
  ) -> Any? {
    text
  }

  @available(iOS 13.0, *)
  func activityViewControllerLinkMetadata(
    _ activityViewController: UIActivityViewController
  ) -> LPLinkMetadata? {
    let metadata = LPLinkMetadata()
    let previewTitle = title?.trimmingCharacters(in: .whitespacesAndNewlines)
    metadata.title = (previewTitle?.isEmpty == false)
      ? previewTitle
      : Self.previewTitle(from: text)
    if let icon {
      metadata.iconProvider = NSItemProvider(object: icon)
    }
    return metadata
  }

  private static func previewTitle(from text: String) -> String {
    let firstLine = text
      .split(separator: "\n", maxSplits: 1, omittingEmptySubsequences: true)
      .first
      .map(String.init) ?? text
    if firstLine.count <= 80 { return firstLine }
    return String(firstLine.prefix(80))
  }
}

private extension UIImage {
  /// Drops transparent or near-white launcher padding around the glyph.
  func storyShareCroppingContentBounds() -> UIImage? {
    guard let cgImage else { return nil }
    let width = cgImage.width
    let height = cgImage.height
    guard width > 1, height > 1 else { return nil }

    let bytesPerPixel = 4
    let bytesPerRow = bytesPerPixel * width
    let byteCount = bytesPerRow * height
    var pixels = [UInt8](repeating: 0, count: byteCount)
    guard let context = CGContext(
      data: &pixels,
      width: width,
      height: height,
      bitsPerComponent: 8,
      bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return nil
    }
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

    func isPadding(_ offset: Int) -> Bool {
      let alpha = pixels[offset + 3]
      if alpha < 16 { return true }
      let r = pixels[offset]
      let g = pixels[offset + 1]
      let b = pixels[offset + 2]
      return r > 235 && g > 235 && b > 235
    }

    var minX = width
    var maxX = 0
    var minY = height
    var maxY = 0
    for y in 0..<height {
      for x in 0..<width {
        let offset = y * bytesPerRow + x * bytesPerPixel
        if isPadding(offset) { continue }
        minX = min(minX, x)
        maxX = max(maxX, x)
        minY = min(minY, y)
        maxY = max(maxY, y)
      }
    }
    guard minX <= maxX, minY <= maxY else { return nil }
    let crop = CGRect(
      x: minX,
      y: minY,
      width: maxX - minX + 1,
      height: maxY - minY + 1
    )
    guard let cropped = cgImage.cropping(to: crop) else { return nil }
    return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
  }

  /// Crops the center square, removing adaptive-launcher inset padding
  /// (~16–24%) baked into generated App Icon assets.
  func storyShareCroppedCenterSquare(insetRatio: CGFloat = 0.24) -> UIImage {
    let edge = min(size.width, size.height)
    guard edge > 1 else { return self }
    let inset = edge * insetRatio
    let cropSide = edge - inset * 2
    guard cropSide > 1 else { return self }
    let originX = (size.width - edge) / 2 + inset
    let originY = (size.height - edge) / 2 + inset
    let cropRect = CGRect(x: originX, y: originY, width: cropSide, height: cropSide)
    guard let cgImage, let cropped = cgImage.cropping(to: cropRect) else {
      return self
    }
    return UIImage(cgImage: cropped, scale: scale, orientation: imageOrientation)
  }

  /// Renders a square icon that aspect-fills the share-sheet preview slot
  /// (~60pt). Crops launcher padding first, then draws opaque edge-to-edge.
  func storyShareFilledIcon(side: CGFloat) -> UIImage {
    let trimmed = storyShareCroppingContentBounds()
      ?? storyShareCroppedCenterSquare()
    let prepared = trimmed
    let size = CGSize(width: side, height: side)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    format.opaque = true
    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    return renderer.image { ctx in
      UIColor.black.setFill()
      ctx.fill(CGRect(origin: .zero, size: size))
      let source =
        prepared.size.width > 0 && prepared.size.height > 0
        ? prepared.size
        : CGSize(width: 1, height: 1)
      let scale = max(side / source.width, side / source.height)
      let drawSize = CGSize(width: source.width * scale, height: source.height * scale)
      let origin = CGPoint(
        x: (side - drawSize.width) / 2,
        y: (side - drawSize.height) / 2
      )
      prepared.draw(in: CGRect(origin: origin, size: drawSize))
    }
  }
}

/// Native size-first video picker used by the publish-video flow.
///
/// The standard Flutter picker copies a selected provider item before Dart can
/// inspect its size. Files are checked before copying, while Photos uses the
/// system's current representation (no transcoding), checks the materialized
/// representation, and performs only the one app-owned copy that the existing
/// metadata/thumbnail/upload stack requires.
private final class NativeVideoFilePicker: NSObject,
  PHPickerViewControllerDelegate, UIDocumentPickerDelegate
{
  private var pendingResult: FlutterResult?
  private var maxBytes: Int64 = 0

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pickVideo" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard pendingResult == nil else {
      result(
        FlutterError(
          code: "already_active",
          message: "A video picker request is already active",
          details: nil
        )
      )
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    let limit = (args["maxBytes"] as? NSNumber)?.int64Value ?? 0
    guard limit > 0 else {
      result(FlutterError(code: "invalid_args", message: "maxBytes must be positive", details: nil))
      return
    }
    guard let presenter = Self.topViewController() else {
      result(
        FlutterError(
          code: "source_unavailable",
          message: "Could not present the video picker",
          details: nil
        )
      )
      return
    }

    pendingResult = result
    maxBytes = limit
    if (args["source"] as? String) == "gallery" {
      var configuration = PHPickerConfiguration(photoLibrary: .shared())
      configuration.selectionLimit = 1
      configuration.filter = .videos
      configuration.preferredAssetRepresentationMode = .current
      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      presenter.present(picker, animated: true)
    } else {
      let picker = UIDocumentPickerViewController(
        forOpeningContentTypes: [.movie],
        asCopy: false
      )
      picker.delegate = self
      picker.allowsMultipleSelection = false
      presenter.present(picker, animated: true)
    }
  }

  func picker(
    _ picker: PHPickerViewController,
    didFinishPicking results: [PHPickerResult]
  ) {
    picker.dismiss(animated: true)
    guard let item = results.first else {
      finishSuccess(["status": "canceled"])
      return
    }
    item.itemProvider.loadFileRepresentation(
      forTypeIdentifier: UTType.movie.identifier
    ) { [weak self] url, error in
      guard let self else { return }
      guard let url else {
        self.finishError(
          code: "source_unavailable",
          message: error?.localizedDescription ?? "The selected video is unavailable"
        )
        return
      }
      self.prepareVideo(at: url, preferredName: item.itemProvider.suggestedName)
    }
  }

  func documentPickerWasCancelled(_: UIDocumentPickerViewController) {
    finishSuccess(["status": "canceled"])
  }

  func documentPicker(
    _: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    guard let url = urls.first else {
      finishSuccess(["status": "canceled"])
      return
    }
    let accessing = url.startAccessingSecurityScopedResource()
    prepareVideo(at: url, preferredName: url.lastPathComponent) {
      if accessing { url.stopAccessingSecurityScopedResource() }
    }
  }

  private func prepareVideo(
    at sourceURL: URL,
    preferredName: String?,
    completion: (() -> Void)? = nil
  ) {
    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      guard let self else { return }
      defer { completion?() }
      do {
        let values = try sourceURL.resourceValues(forKeys: [.fileSizeKey])
        let declaredSize = Int64(values.fileSize ?? 0)
        if declaredSize > self.maxBytes {
          self.finishSuccess(["status": "tooLarge", "sizeBytes": NSNumber(value: declaredSize)])
          return
        }
        if declaredSize > 0, !self.hasCopySpace(for: declaredSize) {
          self.finishError(
            code: "insufficient_storage",
            message: "Not enough device storage to prepare this video"
          )
          return
        }

        let directory = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
          .appendingPathComponent("storyfun_video_picker", isDirectory: true)
          .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(
          at: directory,
          withIntermediateDirectories: true
        )
        let name = Self.safeFileName(
          preferredName ?? sourceURL.lastPathComponent,
          fallbackExtension: sourceURL.pathExtension
        )
        let destination = directory.appendingPathComponent(name)
        do {
          let copied = try self.copyStream(from: sourceURL, to: destination)
          self.finishSuccess([
            "status": "selected",
            "path": destination.path,
            "name": name,
            "sizeBytes": NSNumber(value: declaredSize > 0 ? declaredSize : copied),
          ])
        } catch NativeVideoPickError.tooLarge(let bytes) {
          try? FileManager.default.removeItem(at: directory)
          self.finishSuccess(["status": "tooLarge", "sizeBytes": NSNumber(value: bytes)])
        } catch {
          try? FileManager.default.removeItem(at: directory)
          throw error
        }
      } catch let error as CocoaError where error.code == .fileWriteOutOfSpace {
        self.finishError(code: "insufficient_storage", message: error.localizedDescription)
      } catch {
        let code = self.hasCopySpace(for: 16 * 1024 * 1024)
          ? "copy_failed"
          : "insufficient_storage"
        self.finishError(code: code, message: error.localizedDescription)
      }
    }
  }

  private func copyStream(from source: URL, to destination: URL) throws -> Int64 {
    guard
      let input = InputStream(url: source),
      let output = OutputStream(url: destination, append: false)
    else {
      throw NativeVideoPickError.unreadable
    }
    input.open()
    output.open()
    defer {
      input.close()
      output.close()
    }

    let bufferSize = 1024 * 1024
    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
    defer { buffer.deallocate() }
    var copied: Int64 = 0
    while true {
      let count = input.read(buffer, maxLength: bufferSize)
      if count < 0 { throw input.streamError ?? NativeVideoPickError.unreadable }
      if count == 0 { break }
      copied += Int64(count)
      if copied > maxBytes { throw NativeVideoPickError.tooLarge(copied) }

      var written = 0
      while written < count {
        let result = output.write(buffer.advanced(by: written), maxLength: count - written)
        if result <= 0 { throw output.streamError ?? NativeVideoPickError.unreadable }
        written += result
      }
    }
    return copied
  }

  private func hasCopySpace(for bytes: Int64) -> Bool {
    do {
      let temporary = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
      let values = try temporary.resourceValues(
        forKeys: [.volumeAvailableCapacityForImportantUsageKey]
      )
      guard let available = values.volumeAvailableCapacityForImportantUsage else {
        return true
      }
      return available >= bytes + 64 * 1024 * 1024
    } catch {
      return true
    }
  }

  private func finishSuccess(_ value: [String: Any]) {
    DispatchQueue.main.async { [weak self] in
      guard let self, let result = self.pendingResult else { return }
      self.pendingResult = nil
      result(value)
    }
  }

  private func finishError(code: String, message: String) {
    DispatchQueue.main.async { [weak self] in
      guard let self, let result = self.pendingResult else { return }
      self.pendingResult = nil
      result(FlutterError(code: code, message: message, details: nil))
    }
  }

  private static func safeFileName(_ value: String, fallbackExtension: String) -> String {
    let raw = (value as NSString).lastPathComponent
    let cleaned = raw
      .components(separatedBy: CharacterSet.controlCharacters)
      .joined(separator: "_")
    if !cleaned.isEmpty { return cleaned }
    return fallbackExtension.isEmpty ? "video.mp4" : "video.\(fallbackExtension)"
  }

  private static func topViewController() -> UIViewController? {
    let scene = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .first { $0.activationState == .foregroundActive }
    var controller = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    if let navigation = controller as? UINavigationController {
      return navigation.visibleViewController ?? navigation
    }
    if let tab = controller as? UITabBarController {
      return tab.selectedViewController ?? tab
    }
    return controller
  }
}

private enum NativeVideoPickError: Error {
  case tooLarge(Int64)
  case unreadable
}

/// Warms KTVHTTPCache through its localhost proxy. Playback itself also uses
/// the same proxy, so every AVPlayer range request is persisted and shared by
/// all three feed slots.
private final class VideoCachePreheater {
  private let session: URLSession = {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 15
    configuration.timeoutIntervalForResource = 30
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
    return URLSession(configuration: configuration)
  }()

  func warm(
    url: URL,
    headers: [String: String],
    maxBytes: Int,
    completion: @escaping () -> Void
  ) {
    guard let proxyURL = KTVHTTPCache.proxyURL(withOriginalURL: url) else {
      completion()
      return
    }
    let group = DispatchGroup()
    if url.pathExtension.lowercased().contains("m3u") {
      warmPlaylist(
        proxyURL,
        headers: headers,
        maxBytes: max(256 * 1024, maxBytes),
        depth: 0,
        group: group
      )
    } else {
      request(proxyURL, headers: headers, byteLimit: maxBytes, group: group)
    }
    group.notify(queue: .global(qos: .utility)) { completion() }
  }

  private func warmPlaylist(
    _ url: URL,
    headers: [String: String],
    maxBytes: Int,
    depth: Int,
    group: DispatchGroup
  ) {
    guard depth < 2 else { return }
    var request = URLRequest(url: url)
    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    group.enter()
    session.dataTask(with: request) { [weak self] data, _, _ in
      defer { group.leave() }
      guard
        let self,
        let data,
        let content = String(data: data, encoding: .utf8)
      else { return }
      let lines = content
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty && !$0.hasPrefix("#") }
      guard !lines.isEmpty else { return }

      let resolved = lines.compactMap { URL(string: $0, relativeTo: url)?.absoluteURL }
      if let nested = resolved.first(where: {
        $0.pathExtension.lowercased().contains("m3u")
      }) {
        self.warmPlaylist(
          nested,
          headers: headers,
          maxBytes: maxBytes,
          depth: depth + 1,
          group: group
        )
        return
      }

      // Warm the leading HLS segments. Range requests bound bandwidth and
      // KTVHTTPCache stores the partial ranges for AVPlayer to continue.
      let leading = Array(resolved.prefix(3))
      guard !leading.isEmpty else { return }
      let perSegment = max(256 * 1024, maxBytes / leading.count)
      for segment in leading {
        self.request(segment, headers: headers, byteLimit: perSegment, group: group)
      }
    }.resume()
  }

  private func request(
    _ url: URL,
    headers: [String: String],
    byteLimit: Int,
    group: DispatchGroup
  ) {
    guard byteLimit > 0 else { return }
    var request = URLRequest(url: url)
    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }
    request.setValue("bytes=0-\(byteLimit - 1)", forHTTPHeaderField: "Range")
    group.enter()
    session.dataTask(with: request) { _, _, _ in group.leave() }.resume()
  }
}
