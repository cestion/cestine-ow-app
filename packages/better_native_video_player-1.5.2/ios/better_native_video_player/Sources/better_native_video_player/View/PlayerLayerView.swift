import AVFoundation
import UIKit

/// Bare inline video surface for `lightweightInlineViews`.
///
/// Uses an AVPlayerLayer **sublayer** (not `layerClass`) and syncs
/// `playerLayer.frame` in `layoutSubviews`. Flutter UiKitView +
/// `layerClass` AVPlayerLayer can leave the video visually letterboxed
/// (black gap under the status bar / tiny centered tile).
///
/// Cover-fill is **top-aligned** so a short collapsed band (comment /
/// drama sheet) shows the upper frame (faces) instead of center-crop.
final class PlayerLayerView: UIView {
    let playerLayer = AVPlayerLayer()

    var onFirstFramePresented: (() -> Void)?
    private var readyObservation: NSKeyValueObservation?
    private var wasReadyForDisplay = false

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .black
        clipsToBounds = true
        isOpaque = true
        // `.resize` + a manually cover-sized frame (see layoutSubviews) so we
        // can top-align; `.resizeAspectFill` always center-crops.
        playerLayer.videoGravity = .resize
        playerLayer.backgroundColor = UIColor.black.cgColor
        layer.addSublayer(playerLayer)
        observeReadyForDisplay()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        playerLayer.frame = Self.topAlignedCoverFrame(
            bounds: bounds,
            videoSize: playerLayer.player?.currentItem?.presentationSize
                ?? playerLayer.videoRect.size
        )
        playerLayer.videoGravity = .resize
        CATransaction.commit()
    }

    /// Cover-fill [bounds] at the video aspect, aligned to the top edge.
    static func topAlignedCoverFrame(bounds: CGRect, videoSize: CGSize) -> CGRect {
        let bw = bounds.width
        let bh = bounds.height
        guard bw > 0, bh > 0 else { return bounds }

        let vw = videoSize.width
        let vh = videoSize.height
        // Unknown size: fill bounds; AVPlayerLayer will settle on next layout.
        guard vw > 1, vh > 1 else { return bounds }

        let videoAspect = vw / vh
        let boundsAspect = bw / bh
        if videoAspect < boundsAspect {
            // Relatively taller video — fill width, overflow below.
            let height = bw / videoAspect
            return CGRect(x: 0, y: 0, width: bw, height: height)
        }
        // Relatively wider video — fill height, crop sides.
        let width = bh * videoAspect
        let x = (bw - width) / 2
        return CGRect(x: x, y: 0, width: width, height: bh)
    }

    private func observeReadyForDisplay() {
        readyObservation = playerLayer.observe(
            \.isReadyForDisplay,
            options: [.initial, .new]
        ) { [weak self] layer, _ in
            guard let self = self else { return }
            let ready = layer.isReadyForDisplay
            if ready && !self.wasReadyForDisplay {
                DispatchQueue.main.async {
                    self.onFirstFramePresented?()
                    // Presentation size often becomes valid with first frame.
                    self.setNeedsLayout()
                }
            }
            self.wasReadyForDisplay = ready
        }
    }
}
