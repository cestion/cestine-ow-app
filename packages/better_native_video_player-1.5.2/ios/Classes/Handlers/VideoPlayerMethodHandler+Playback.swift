import Flutter
import UIKit
import AVKit
import AVFoundation
import CoreImage
import MediaPlayer

// Playback commands, disposal, and the periodic time observer.
// Split from VideoPlayerMethodHandler.swift for maintainability;
// all members keep full access to VideoPlayerView state.
extension VideoPlayerView {
    func handlePlay(result: @escaping FlutterResult) {
        // Playing counts as "use" for the total-player LRU cap
        if let controllerIdValue = controllerId {
            SharedPlayerManager.shared.touchController(controllerIdValue)
        }

        // Prepare audio session, Now Playing info, and PiP before playback
        prepareForPlayback()

        npLog("Playing with speed: \(desiredPlaybackSpeed)")
        player?.play()
        // Apply the desired playback speed
        player?.rate = desiredPlaybackSpeed
        npLog("Applied playback rate: \(player?.rate ?? 0)")
        updateNowPlayingPlaybackTime()
        // Play event will be sent automatically by timeControlStatus observer
        result(nil)
    }

    func handlePause(result: @escaping FlutterResult) {
        player?.pause()
        updateNowPlayingPlaybackTime()

        // DON'T disable automatic PiP on pause anymore
        // The system will handle when to trigger automatic PiP based on playback state
        // Disabling it here causes issues when exiting manual PiP (video might pause during transition)
        // and prevents automatic PiP from working afterward
        if #available(iOS 14.2, *) {
            if let controllerIdValue = controllerId {
                npLog("🎬 Video paused, but keeping automatic PiP state unchanged")
            }
        }

        // Pause event will be sent automatically by timeControlStatus observer
        result(nil)
    }

    func handleSeekTo(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? [String: Any],
           let milliseconds = args["milliseconds"] as? Int {
            let seconds = Double(milliseconds) / 1000.0
            player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 1000)) { _ in
                // Texture views must render the seeked frame even while
                // paused (the engine shows the last copied buffer otherwise)
                self.textureRenderer?.expectFrame()
                self.sendEvent("seek", data: ["position": milliseconds])
                self.updateNowPlayingPlaybackTime()
            }
        }
        result(nil)
    }

    func handleSetVolume(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? [String: Any],
           let volume = args["volume"] as? Double {
            player?.volume = Float(volume)
            // Foreground unmute after backgrounding: re-activate the session so
            // AVPlayer is not left silent with volume=1 while the session is off.
            if volume > 0 {
                prepareAudioSession()
            }
        }
        result(nil)
    }

    func handleSetSpeed(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? [String: Any],
           let speed = args["speed"] as? Double {
            npLog("Setting playback speed to: \(speed)")

            // Store the desired speed
            desiredPlaybackSpeed = Float(speed)

            npLog("Player status: \(player?.timeControlStatus.rawValue ?? -1)")

            // If currently playing, apply the speed immediately
            if player?.timeControlStatus == .playing {
                npLog("Player is playing, applying speed immediately")
                player?.rate = Float(speed)
            } else {
                npLog("Player is not playing, speed will be applied on next play")
            }

            sendEvent("speedChange", data: ["speed": speed])
            result(nil)
        } else {
            result(FlutterError(code: "INVALID_SPEED", message: "Invalid speed value", details: nil))
        }
    }

    func handleSetLooping(call: FlutterMethodCall, result: @escaping FlutterResult) {
        if let args = call.arguments as? [String: Any],
           let looping = args["looping"] as? Bool {
            npLog("Setting looping to: \(looping)")

            // Update the enableLooping property
            enableLooping = looping

            result(nil)
        } else {
            result(FlutterError(code: "INVALID_LOOPING", message: "Invalid looping value", details: nil))
        }
    }

    func handleDispose(result: @escaping FlutterResult) {
        npLog("🗑️ [VideoPlayerMethodHandler] handleDispose called for controllerId: \(String(describing: controllerId))")

        // Pause the player first
        player?.pause()
        npLog("⏸️ [VideoPlayerMethodHandler] Player paused")

        // Clean up DRM handler
        drmHandler?.cleanup()
        drmHandler = nil

        // Clean up remote command ownership (transfer to another view if possible)
        cleanupRemoteCommandOwnership()

        // Remove from shared manager if this is a shared player
        if let controllerId = controllerId {
            npLog("🔄 [VideoPlayerMethodHandler] Calling SharedPlayerManager.removePlayer for controllerId: \(controllerId)")
            SharedPlayerManager.shared.removePlayer(for: controllerId)
            npLog("✅ [VideoPlayerMethodHandler] SharedPlayerManager.removePlayer completed for controllerId: \(controllerId)")
        } else {
            npLog("⚠️ [VideoPlayerMethodHandler] No controllerId - cannot remove from SharedPlayerManager")
        }

        // Clear local player reference
        player = nil
        npLog("🧹 [VideoPlayerMethodHandler] Local player reference cleared")

        sendEvent("stopped")
        result(nil)
    }

    /// Sets up periodic time observer to update Now Playing elapsed time
    func setupPeriodicTimeObserver() {
        // Remove existing observer if any
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }

        // Emit timeUpdate events at the configured interval while playing
        let intervalSeconds = Double(timeUpdateIntervalMs) / 1000.0
        let interval = CMTime(seconds: intervalSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        // Resync Now Playing roughly every 5 seconds regardless of interval
        let nowPlayingResyncEvery = max(1, Int((5000.0 / Double(timeUpdateIntervalMs)).rounded()))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            guard let self = self, let player = self.player, let currentItem = player.currentItem else { return }

            // Resync Now Playing elapsed time only every ~5s: the system
            // extrapolates position from the playback rate, and the
            // play/pause/seek paths push immediate updates. Writing the
            // MPNowPlayingInfoCenter dictionary is an XPC call — doing it
            // every tick per view is wasted work.
            self.nowPlayingResyncTick += 1
            if self.nowPlayingResyncTick >= nowPlayingResyncEvery {
                self.nowPlayingResyncTick = 0
                self.updateNowPlayingPlaybackTime()
            }

            // Get current playback position
            let currentTime = player.currentTime()
            var positionSeconds = CMTimeGetSeconds(currentTime)
            var durationSeconds: Double = 0.0

            // For HLS live streams (indefinite duration), use seekableTimeRanges to get duration
            // Regular VOD content (including VOD HLS) uses the item's duration
            if currentItem.duration.isIndefinite {
                // Live stream - use seekable ranges
                let seekableRanges = currentItem.seekableTimeRanges
                if !seekableRanges.isEmpty {
                    // HLS live stream - calculate duration from seekable range
                    let firstRange = seekableRanges.first!.timeRangeValue
                    let lastRange = seekableRanges.last!.timeRangeValue

                    let rangeStart = firstRange.start
                    let rangeEnd = CMTimeAdd(lastRange.start, lastRange.duration)

                    // Duration is the full seekable window
                    durationSeconds = CMTimeGetSeconds(CMTimeSubtract(rangeEnd, rangeStart))

                    // Position is relative to the start of the seekable window
                    positionSeconds = CMTimeGetSeconds(CMTimeSubtract(currentTime, rangeStart))

                    // Ensure position is within valid range
                    if positionSeconds < 0 {
                        positionSeconds = 0
                    } else if positionSeconds > durationSeconds {
                        positionSeconds = durationSeconds
                    }
                }
            } else {
                // Regular VOD content (including VOD HLS) - use item duration
                let duration = currentItem.duration
                durationSeconds = CMTimeGetSeconds(duration)
            }

            // Get buffered position
            var bufferedSeconds = 0.0
            let loadedRanges = currentItem.loadedTimeRanges
            if !loadedRanges.isEmpty {
                // Get the most recent buffered range
                let bufferedRange = loadedRanges.last!.timeRangeValue
                let bufferedEnd = CMTimeAdd(bufferedRange.start, bufferedRange.duration)
                bufferedSeconds = CMTimeGetSeconds(bufferedEnd)
            }

            // Check if currently buffering
            let isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate

            // Only send event if values are valid (not NaN or Infinity)
            if positionSeconds.isFinite && !positionSeconds.isNaN &&
               durationSeconds.isFinite && !durationSeconds.isNaN && durationSeconds > 0 {
                let position = Int(positionSeconds * 1000) // milliseconds
                let totalDuration = Int(durationSeconds * 1000) // milliseconds
                let bufferedPosition = Int(bufferedSeconds * 1000) // milliseconds

                self.sendEvent("timeUpdate", data: [
                    "position": position,
                    "duration": totalDuration,
                    "bufferedPosition": bufferedPosition,
                    "isBuffering": isBuffering
                ])
            }
        }
    }

    /// Captures the current video frame as JPEG (first-frame cache / posters).
    ///
    /// Prefer the live [AVPlayerItemVideoOutput] — HLS often makes
    /// `AVAssetImageGenerator` fail, and `AVPlayerLayer.render` is black.
    func handleCaptureCurrentFrame(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let maxWidth = (call.arguments as? [String: Any])?["maxWidth"] as? Int ?? 720

        if let data = captureFrameViaVideoOutput(maxWidth: maxWidth) {
            result(FlutterStandardTypedData(bytes: data))
            return
        }
        if let data = captureFrameViaImageGenerator(maxWidth: maxWidth) {
            result(FlutterStandardTypedData(bytes: data))
            return
        }
        result(nil)
    }

    private func captureFrameViaVideoOutput(maxWidth: Int) -> Data? {
        guard let output = frameMonitorOutput else { return nil }
        let hostTime = CACurrentMediaTime()
        let itemTime = output.itemTime(forHostTime: hostTime)
        guard let pixelBuffer = output.copyPixelBuffer(
            forItemTime: itemTime,
            itemTimeForDisplay: nil
        ) else { return nil }

        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = ciImage.extent
        guard extent.width > 1, extent.height > 1 else { return nil }
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: extent) else { return nil }
        var image = UIImage(cgImage: cgImage)
        let maxW = CGFloat(maxWidth)
        if image.size.width > maxW, maxW > 0 {
            let scale = maxW / image.size.width
            let newSize = CGSize(width: maxW, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, true, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            if let scaled = UIGraphicsGetImageFromCurrentImageContext() {
                image = scaled
            }
            UIGraphicsEndImageContext()
        }
        return image.jpegData(compressionQuality: 0.75)
    }

    private func captureFrameViaImageGenerator(maxWidth: Int) -> Data? {
        guard let player = player, let item = player.currentItem else { return nil }
        let generator = AVAssetImageGenerator(asset: item.asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: CGFloat(maxWidth), height: 0)
        generator.requestedTimeToleranceBefore = .positiveInfinity
        generator.requestedTimeToleranceAfter = .positiveInfinity

        let time = player.currentTime()
        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let image = UIImage(cgImage: cgImage)
            return image.jpegData(compressionQuality: 0.75)
        } catch {
            npLog("captureCurrentFrame generator failed: \(error)")
            return nil
        }
    }
}
