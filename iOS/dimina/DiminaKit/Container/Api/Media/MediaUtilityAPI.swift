import AVFoundation
import AVKit
import ImageIO
import Photos
import UIKit
import UniformTypeIdentifiers

public final class MediaUtilityAPI: DMPContainerApi {
    @BridgeMethod("getImageInfo")
    var getImageInfo: DMPBridgeMethodHandler = { param, env, callback in
        guard let src = param.getMap().getString(key: "src"), !src.isEmpty else {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "getImageInfo:fail src is required",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        MediaUtilityAPI.loadData(source: src, appId: env.appId) { result in
            switch result {
            case .success(let loaded):
                guard let source = CGImageSourceCreateWithData(loaded.data as CFData, nil),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
                      let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
                      let height = properties[kCGImagePropertyPixelHeight] as? NSNumber else {
                    DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                                  errMsg: "getImageInfo:fail unsupported image",
                                                  completeCarriesResult: true)
                    return
                }
                let orientationValue = (properties[kCGImagePropertyOrientation] as? NSNumber)?.intValue ?? 1
                let type = CGImageSourceGetType(source)
                    .flatMap { UTType($0 as String)?.preferredFilenameExtension } ?? "unknown"
                let response = DMPMap([
                    "width": width.intValue,
                    "height": height.intValue,
                    "path": loaded.path,
                    "orientation": MediaUtilityAPI.imageOrientation(orientationValue),
                    "type": type,
                    "errMsg": "getImageInfo:ok",
                ])
                DMPContainerApi.invokeSuccess(callback: callback, param: response, completeCarriesResult: true)
            case .failure(let error):
                DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                              errMsg: "getImageInfo:fail \(error.localizedDescription)",
                                              completeCarriesResult: true)
            }
        }
        return DMPAsyncResult()
    }

    @BridgeMethod("previewMedia")
    var previewMedia: DMPBridgeMethodHandler = { param, env, callback in
        guard let rawSources = param.getMap().get("sources") as? [[String: Any]], !rawSources.isEmpty else {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "previewMedia:fail sources is required",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        let sources = rawSources.compactMap { value -> DMPMediaPreviewSource? in
            guard let rawURL = value["url"] as? String, !rawURL.isEmpty else { return nil }
            let resolvedURL = MediaUtilityAPI.resolveURL(rawURL, appId: env.appId)
            let poster = (value["poster"] as? String).map { MediaUtilityAPI.resolveURL($0, appId: env.appId) }
            return DMPMediaPreviewSource(url: resolvedURL, type: value["type"] as? String ?? "image", poster: poster)
        }
        guard !sources.isEmpty else {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "previewMedia:fail invalid sources",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        let current = min(max(param.getMap().getInt(key: "current") ?? 0, 0), sources.count - 1)
        DispatchQueue.main.async {
            guard let top = DMPUIManager.getCurrentWindow()?.rootViewController?.topMostViewController() else {
                DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                              errMsg: "previewMedia:fail no view controller",
                                              completeCarriesResult: true)
                return
            }
            top.present(DMPMediaPreviewController(sources: sources, current: current), animated: true) {
                let result = DMPMap(["errMsg": "previewMedia:ok"])
                DMPContainerApi.invokeSuccess(callback: callback, param: result, completeCarriesResult: true)
            }
        }
        return DMPAsyncResult()
    }

    @BridgeMethod("getVideoInfo")
    var getVideoInfo: DMPBridgeMethodHandler = { param, env, callback in
        guard let src = param.getMap().getString(key: "src"), !src.isEmpty else {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "getVideoInfo:fail src is required",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        let url = MediaUtilityAPI.resolveURL(src, appId: env.appId)
        DispatchQueue.global(qos: .userInitiated).async {
            let result = MediaUtilityAPI.videoInfo(url: url)
            DispatchQueue.main.async {
                if let result {
                    result.set("errMsg", "getVideoInfo:ok")
                    DMPContainerApi.invokeSuccess(callback: callback, param: result, completeCarriesResult: true)
                } else {
                    DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                                  errMsg: "getVideoInfo:fail unsupported video",
                                                  completeCarriesResult: true)
                }
            }
        }
        return DMPAsyncResult()
    }

    @BridgeMethod("saveVideoToPhotosAlbum")
    var saveVideoToPhotosAlbum: DMPBridgeMethodHandler = { param, env, callback in
        guard let path = param.getMap().getString(key: "filePath"),
              let localPath = DMPFileUtil.sandboxPathFromVPath(from: path, appId: env.appId),
              FileManager.default.fileExists(atPath: localPath) else {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "saveVideoToPhotosAlbum:fail invalid filePath",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                              errMsg: "saveVideoToPhotosAlbum:fail auth deny",
                                              completeCarriesResult: true)
                return
            }
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: URL(fileURLWithPath: localPath))
            }) { saved, error in
                DispatchQueue.main.async {
                    if saved {
                        let result = DMPMap(["errMsg": "saveVideoToPhotosAlbum:ok"])
                        DMPContainerApi.invokeSuccess(callback: callback, param: result, completeCarriesResult: true)
                    } else {
                        DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                                      errMsg: "saveVideoToPhotosAlbum:fail \(error?.localizedDescription ?? "unknown")",
                                                      completeCarriesResult: true)
                    }
                }
            }
        }
        return DMPAsyncResult()
    }

    @BridgeMethod("compressVideo")
    var compressVideo: DMPBridgeMethodHandler = { param, env, callback in
        let map = param.getMap()
        guard let src = map.getString(key: "src"),
              let localPath = DMPFileUtil.sandboxPathFromVPath(from: src, appId: env.appId),
              FileManager.default.fileExists(atPath: localPath) else {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "compressVideo:fail invalid src",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        let resolution = (map.get("resolution") as? NSNumber)?.doubleValue ?? 1
        guard resolution > 0, resolution <= 1 else {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "compressVideo:fail invalid resolution",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        let quality = map.getString(key: "quality") ?? "medium"
        let bitrate = (map.get("bitrate") as? NSNumber)?.intValue
        let fps = (map.get("fps") as? NSNumber)?.intValue
        if let bitrate, bitrate <= 0 || bitrate > Int.max / 1_000 {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "compressVideo:fail invalid bitrate",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        if let fps, fps <= 0 || fps > Int(Int32.max / 2) {
            DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                          errMsg: "compressVideo:fail invalid fps",
                                          completeCarriesResult: true)
            return DMPAsyncResult()
        }
        let directory = DMPSandboxManager.appTmpResourceDirectoryPath(appId: env.appId)
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        let output = URL(fileURLWithPath: directory).appendingPathComponent("compressed_\(UUID().uuidString).mp4")
        DMPVideoCompressor.compress(
            source: URL(fileURLWithPath: localPath),
            output: output,
            resolution: resolution,
            bitrateKbps: bitrate ?? (quality == "low" ? 1_000 : quality == "high" ? 4_000 : 2_000),
            fps: fps
        ) { error in
            DispatchQueue.main.async {
                if error == nil {
                    let byteSize = (try? output.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    let size = (byteSize + 1023) / 1024
                    let result = DMPMap([
                        "tempFilePath": DMPFileUtil.vPathFromSandboxPath(sandboxPath: output.path, appId: env.appId),
                        "size": size,
                        "errMsg": "compressVideo:ok",
                    ])
                    DMPContainerApi.invokeSuccess(callback: callback, param: result, completeCarriesResult: true)
                } else {
                    try? FileManager.default.removeItem(at: output)
                    DMPContainerApi.invokeFailure(callback: callback, param: nil,
                                                  errMsg: "compressVideo:fail \(error?.localizedDescription ?? "unknown")",
                                                  completeCarriesResult: true)
                }
            }
        }
        return DMPAsyncResult()
    }

    fileprivate static func resolveURL(_ source: String, appId: String) -> URL {
        if let path = DMPFileUtil.sandboxPathFromVPath(from: source, appId: appId) {
            return URL(fileURLWithPath: path)
        }
        if let url = URL(string: source), let scheme = url.scheme, !scheme.isEmpty { return url }
        let relativePath = source
            .split(separator: "?", maxSplits: 1).first.map(String.init)?
            .split(separator: "#", maxSplits: 1).first.map(String.init)?
            .trimmingCharacters(in: CharacterSet(charactersIn: "/")) ?? ""
        let root = URL(fileURLWithPath: DMPSandboxManager.appBundlePath(appId), isDirectory: true)
        let candidates = [relativePath, "main/\(relativePath)"].map {
            root.appendingPathComponent($0).standardizedFileURL
        }.filter { $0.path.hasPrefix(root.standardizedFileURL.path + "/") }
        return candidates.first { FileManager.default.fileExists(atPath: $0.path) }
            ?? candidates.first ?? URL(fileURLWithPath: source)
    }

    private static func loadData(source: String, appId: String,
                                 completion: @escaping (Result<(data: Data, path: String), Error>) -> Void) {
        let url = resolveURL(source, appId: appId)
        if url.isFileURL {
            do {
                completion(.success((try Data(contentsOf: url), source)))
            } catch {
                completion(.failure(error))
            }
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let error { completion(.failure(error)); return }
            guard let data else {
                completion(.failure(NSError(domain: "MediaUtilityAPI", code: 1))); return
            }
            let directory = DMPSandboxManager.appTmpResourceDirectoryPath(appId: appId)
            do {
                try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
                let ext = url.pathExtension.isEmpty ? "img" : url.pathExtension
                let file = URL(fileURLWithPath: directory).appendingPathComponent("image_\(UUID().uuidString).\(ext)")
                try data.write(to: file)
                completion(.success((data, DMPFileUtil.vPathFromSandboxPath(sandboxPath: file.path, appId: appId))))
            } catch { completion(.failure(error)) }
        }.resume()
    }

    private static func imageOrientation(_ value: Int) -> String {
        switch value {
        case 2: return "up-mirrored"
        case 3: return "down"
        case 4: return "down-mirrored"
        case 5: return "left-mirrored"
        case 6: return "right"
        case 7: return "right-mirrored"
        case 8: return "left"
        default: return "up"
        }
    }

    private static func videoInfo(url: URL) -> DMPMap? {
        let asset = AVURLAsset(url: url)
        guard let track = asset.tracks(withMediaType: .video).first else { return nil }
        let transformed = track.naturalSize.applying(track.preferredTransform)
        let rotation = atan2(track.preferredTransform.b, track.preferredTransform.a) * 180 / .pi
        let orientation = abs(rotation - 90) < 1 ? "right" : abs(abs(rotation) - 180) < 1 ? "down"
            : abs(rotation + 90) < 1 ? "left" : "up"
        let size = url.isFileURL ? (((try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0) + 1023) / 1024 : 0
        return DMPMap([
            "duration": CMTimeGetSeconds(asset.duration),
            "width": Int(abs(transformed.width)),
            "height": Int(abs(transformed.height)),
            "orientation": orientation,
            "type": url.pathExtension.lowercased().isEmpty ? "unknown" : url.pathExtension.lowercased(),
            "size": size,
            "bitrate": Int(track.estimatedDataRate / 1000),
            "fps": track.nominalFrameRate,
        ])
    }
}

fileprivate struct DMPMediaPreviewSource {
    let url: URL
    let type: String
    let poster: URL?
}

fileprivate final class DMPMediaPreviewController: UIPageViewController,
                                                    UIPageViewControllerDataSource,
                                                    UIPageViewControllerDelegate {
    private let pages: [UIViewController]

    init(sources: [DMPMediaPreviewSource], current: Int) {
        pages = sources.map { source in
            if source.type == "video" {
                return DMPMediaVideoController(url: source.url, poster: source.poster)
            }
            return DMPMediaImageController(url: source.url)
        }
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal)
        dataSource = self
        delegate = self
        modalPresentationStyle = .fullScreen
        setViewControllers([pages[current]], direction: .forward, animated: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let close = UIButton(type: .system)
        close.setTitle("×", for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 36, weight: .light)
        close.tintColor = .white
        close.addTarget(self, action: #selector(closePreview), for: .touchUpInside)
        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            close.widthAnchor.constraint(equalToConstant: 44),
            close.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (viewControllers?.first as? DMPMediaVideoController)?.play()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseAllVideos()
    }

    @objc private func closePreview() {
        pages.compactMap { $0 as? DMPMediaVideoController }.forEach { $0.releasePlayer() }
        dismiss(animated: true)
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index > 0 else { return nil }
        return pages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = pages.firstIndex(of: viewController), index + 1 < pages.count else { return nil }
        return pages[index + 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        (viewControllers?.first as? DMPMediaVideoController)?.pause()
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {
        pauseAllVideos()
        (viewControllers?.first as? DMPMediaVideoController)?.play()
    }

    private func pauseAllVideos() {
        pages.compactMap { $0 as? DMPMediaVideoController }.forEach { $0.pause() }
    }
}

fileprivate final class DMPMediaVideoController: UIViewController {
    private let url: URL
    private let poster: URL?
    private let playerController = AVPlayerViewController()
    private let posterView = UIImageView()
    private var statusObservation: NSKeyValueObservation?

    init(url: URL, poster: URL?) {
        self.url = url
        self.poster = poster
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let player = AVPlayer(url: url)
        playerController.player = player
        addChild(playerController)
        playerController.view.frame = view.bounds
        playerController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(playerController.view)
        playerController.didMove(toParent: self)

        posterView.frame = view.bounds
        posterView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        posterView.contentMode = .scaleAspectFit
        posterView.backgroundColor = .black
        posterView.isUserInteractionEnabled = false
        view.addSubview(posterView)
        loadPoster()

        statusObservation = player.currentItem?.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard item.status == .readyToPlay else { return }
            DispatchQueue.main.async {
                UIView.animate(withDuration: 0.15) { self?.posterView.alpha = 0 }
            }
        }
    }

    func play() {
        loadViewIfNeeded()
        playerController.player?.play()
    }

    func pause() {
        playerController.player?.pause()
    }

    func releasePlayer() {
        pause()
        statusObservation = nil
        playerController.player?.replaceCurrentItem(with: nil)
        playerController.player = nil
    }

    deinit { releasePlayer() }

    private func loadPoster() {
        guard let poster else {
            posterView.isHidden = true
            return
        }
        if poster.isFileURL {
            posterView.image = UIImage(contentsOfFile: poster.path)
            posterView.isHidden = posterView.image == nil
            return
        }
        URLSession.shared.dataTask(with: poster) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.posterView.image = image }
        }.resume()
    }
}

fileprivate final class DMPMediaImageController: UIViewController {
    private let url: URL
    init(url: URL) { self.url = url; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let imageView = UIImageView(frame: view.bounds)
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        if url.isFileURL {
            imageView.image = UIImage(contentsOfFile: url.path)
        } else {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                guard let data else { return }
                DispatchQueue.main.async { imageView.image = UIImage(data: data) }
            }.resume()
        }
    }
}

fileprivate enum DMPVideoCompressor {
    static func compress(source: URL, output: URL, resolution: Double, bitrateKbps: Int, fps: Int?,
                         completion: @escaping (Error?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try FileManager.default.removeItemIfExists(at: output)
                let asset = AVURLAsset(url: source)
                guard let videoTrack = asset.tracks(withMediaType: .video).first else {
                    throw compressionError("unsupported video")
                }
                let reader = try AVAssetReader(asset: asset)
                let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)

                let sourceWidth = max(2, Int(abs(videoTrack.naturalSize.width)))
                let sourceHeight = max(2, Int(abs(videoTrack.naturalSize.height)))
                let targetWidth = evenDimension(Double(sourceWidth) * resolution)
                let targetHeight = evenDimension(Double(sourceHeight) * resolution)
                let videoOutput = AVAssetReaderTrackOutput(track: videoTrack, outputSettings: [
                    kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
                    kCVPixelBufferWidthKey as String: targetWidth,
                    kCVPixelBufferHeightKey as String: targetHeight,
                    kCVPixelBufferIOSurfacePropertiesKey as String: [:],
                ])
                videoOutput.alwaysCopiesSampleData = false
                guard reader.canAdd(videoOutput) else { throw compressionError("unsupported video output") }
                reader.add(videoOutput)

                var compression: [String: Any] = [
                    AVVideoAverageBitRateKey: bitrateKbps * 1_000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                ]
                if let fps {
                    compression[AVVideoExpectedSourceFrameRateKey] = fps
                    compression[AVVideoMaxKeyFrameIntervalKey] = max(fps * 2, 1)
                }
                let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: [
                    AVVideoCodecKey: AVVideoCodecType.h264,
                    AVVideoWidthKey: targetWidth,
                    AVVideoHeightKey: targetHeight,
                    AVVideoCompressionPropertiesKey: compression,
                ])
                videoInput.expectsMediaDataInRealTime = false
                videoInput.transform = videoTrack.preferredTransform
                guard writer.canAdd(videoInput) else { throw compressionError("unsupported video input") }
                writer.add(videoInput)

                var audioOutput: AVAssetReaderTrackOutput?
                var audioInput: AVAssetWriterInput?
                if let audioTrack = asset.tracks(withMediaType: .audio).first {
                    let output = AVAssetReaderTrackOutput(track: audioTrack, outputSettings: [
                        AVFormatIDKey: kAudioFormatLinearPCM,
                    ])
                    let input = AVAssetWriterInput(mediaType: .audio, outputSettings: [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVEncoderBitRateKey: 128_000,
                        AVSampleRateKey: 44_100,
                        AVNumberOfChannelsKey: 2,
                    ])
                    output.alwaysCopiesSampleData = false
                    if reader.canAdd(output), writer.canAdd(input) {
                        reader.add(output)
                        writer.add(input)
                        audioOutput = output
                        audioInput = input
                    }
                }

                guard writer.startWriting() else {
                    throw writer.error ?? compressionError("cannot start video writer")
                }
                guard reader.startReading() else {
                    throw reader.error ?? compressionError("cannot start video reader")
                }
                writer.startSession(atSourceTime: .zero)

                try drain(reader: reader, writer: writer,
                          videoOutput: videoOutput, videoInput: videoInput,
                          audioOutput: audioOutput, audioInput: audioInput,
                          fps: fps, sourceFPS: videoTrack.nominalFrameRate)
                writer.finishWriting {
                    completion(writer.status == .completed ? nil
                               : writer.error ?? compressionError("video writer failed"))
                }
            } catch {
                try? FileManager.default.removeItem(at: output)
                completion(error)
            }
        }
    }

    private static func drain(reader: AVAssetReader, writer: AVAssetWriter,
                              videoOutput: AVAssetReaderTrackOutput, videoInput: AVAssetWriterInput,
                              audioOutput: AVAssetReaderTrackOutput?, audioInput: AVAssetWriterInput?,
                              fps: Int?, sourceFPS: Float) throws {
        var videoDone = false
        var audioDone = audioOutput == nil || audioInput == nil
        let shouldLimitFPS = fps.map { sourceFPS <= 0 || Float($0) < sourceFPS } ?? false
        let frameInterval = shouldLimitFPS ? CMTime(value: 1, timescale: CMTimeScale(fps!)) : nil
        var lastVideoTime: CMTime?

        while !videoDone || !audioDone {
            if reader.status == .failed { throw reader.error ?? compressionError("video reader failed") }
            if writer.status == .failed { throw writer.error ?? compressionError("video writer failed") }
            var progressed = false

            if !videoDone, videoInput.isReadyForMoreMediaData {
                if let sample = videoOutput.copyNextSampleBuffer() {
                    progressed = true
                    let timestamp = CMSampleBufferGetPresentationTimeStamp(sample)
                    let shouldAppend = frameInterval == nil || lastVideoTime == nil
                        || CMTimeCompare(CMTimeSubtract(timestamp, lastVideoTime!), frameInterval!) >= 0
                    if shouldAppend {
                        guard videoInput.append(sample) else {
                            throw writer.error ?? compressionError("cannot append video frame")
                        }
                        lastVideoTime = timestamp
                    }
                } else {
                    videoDone = true
                    videoInput.markAsFinished()
                }
            }

            if !audioDone, let audioOutput, let audioInput, audioInput.isReadyForMoreMediaData {
                if let sample = audioOutput.copyNextSampleBuffer() {
                    progressed = true
                    guard audioInput.append(sample) else {
                        throw writer.error ?? compressionError("cannot append audio sample")
                    }
                } else {
                    audioDone = true
                    audioInput.markAsFinished()
                }
            }

            if !progressed && (!videoDone || !audioDone) {
                Thread.sleep(forTimeInterval: 0.002)
            }
        }
    }

    private static func evenDimension(_ value: Double) -> Int {
        max(2, Int(value.rounded(.down)) & ~1)
    }

    private static func compressionError(_ message: String) -> NSError {
        NSError(domain: "MediaUtilityAPI.compressVideo", code: 1,
                userInfo: [NSLocalizedDescriptionKey: message])
    }
}

fileprivate extension FileManager {
    func removeItemIfExists(at url: URL) throws {
        if fileExists(atPath: url.path) { try removeItem(at: url) }
    }
}
