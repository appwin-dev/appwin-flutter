import AVFoundation
import CoreTransferable
import Foundation
import UniformTypeIdentifiers

/// A video picked in Photos, copied to a temporary file: a camera video can
/// weigh hundreds of MB, too much to hold in memory as `Data`.
struct CommunityPickedMovie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let ext = received.file.pathExtension.isEmpty ? "mov" : received.file.pathExtension
            let copy = FileManager.default.temporaryDirectory
                .appendingPathComponent("appwin-picked-\(UUID().uuidString)")
                .appendingPathExtension(ext)
            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self(url: copy)
        }
    }
}

/// Upload-ready video file and its MIME type.
struct CommunityPreparedVideo {
    let url: URL
    let mimeType: String
    /// The file was re-encoded into a temporary copy the caller deletes.
    let isTemporary: Bool
}

enum CommunityVideoPrepError: Error {
    case noVideoTrack
    case failed(Error?)
}

/// Re-encodes a picked video before upload.
///
/// A phone films in 4K at 40 to 400 MB a minute, over the 75 MB the API accepts
/// for community media, and every feed reader would download it again. H.264
/// at 720p and 30 fps (about 25 MB a minute) plays everywhere, the web
/// dashboard included, and stays sharp on a phone screen. HDR footage is tone
/// mapped to SDR (BT.709) on the way.
enum CommunityVideoPrep {
    struct Options {
        /// Longest side of the output, in pixels.
        var maxSide: CGFloat = 1280
        /// Video bitrate for a 1280x720 frame, scaled with the pixel count.
        var videoBitrate: Int = 3_000_000
        var maxFrameRate: Int32 = 30
        /// Below this size the original goes up untouched.
        var minBytesToCompress: Int = 15 * 1024 * 1024

        static let `default` = Options()
    }

    /// Returns the original when it is small enough or when the re-encoded
    /// copy would not be smaller.
    static func prepare(
        _ source: URL,
        mimeType: String,
        options: Options = .default
    ) async throws -> CommunityPreparedVideo {
        let original = CommunityPreparedVideo(url: source, mimeType: mimeType, isTemporary: false)
        let size = fileSize(source)
        guard size >= options.minBytesToCompress else { return original }

        let output = FileManager.default.temporaryDirectory
            .appendingPathComponent("appwin-video-\(UUID().uuidString)")
            .appendingPathExtension("mp4")
        try await transcode(source, to: output, options: options)
        guard fileSize(output) < size else {
            try? FileManager.default.removeItem(at: output)
            return original
        }
        return CommunityPreparedVideo(url: output, mimeType: "video/mp4", isTemporary: true)
    }

    static func fileSize(_ url: URL) -> Int {
        (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    }

    /// Output size: the oriented frame fitted in `maxSide`, even sides (H.264).
    static func outputSize(for renderSize: CGSize, maxSide: CGFloat) -> CGSize {
        let longest = max(renderSize.width, renderSize.height)
        let scale = longest > maxSide ? maxSide / longest : 1
        func even(_ value: CGFloat) -> CGFloat { max(2, (value * scale / 2).rounded() * 2) }
        return CGSize(width: even(renderSize.width), height: even(renderSize.height))
    }

    // MARK: - Transcoding

    private static func transcode(_ source: URL, to output: URL, options: Options) async throws {
        let asset = AVURLAsset(url: source)
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw CommunityVideoPrepError.noVideoTrack
        }
        let audioTrack = try await asset.loadTracks(withMediaType: .audio).first

        // The composition applies the track's rotation, so portrait videos stay
        // portrait, caps the frame rate, and converts HDR to BT.709.
        let composition = try await AVMutableVideoComposition.videoComposition(withPropertiesOf: asset)
        composition.colorPrimaries = AVVideoColorPrimaries_ITU_R_709_2
        composition.colorTransferFunction = AVVideoTransferFunction_ITU_R_709_2
        composition.colorYCbCrMatrix = AVVideoYCbCrMatrix_ITU_R_709_2
        let minFrameDuration = CMTime(value: 1, timescale: options.maxFrameRate)
        if CMTimeCompare(composition.frameDuration, minFrameDuration) < 0 {
            composition.frameDuration = minFrameDuration
            // Timed on the source track, the composition would keep every
            // source frame and ignore `frameDuration`.
            composition.sourceTrackIDForFrameTiming = kCMPersistentTrackID_Invalid
        }

        let size = outputSize(for: composition.renderSize, maxSide: options.maxSide)
        let pixels = Double(size.width * size.height)
        let bitrate = Int(Double(options.videoBitrate) * min(1, pixels / (1280 * 720)))

        let reader = try AVAssetReader(asset: asset)
        let writer = try AVAssetWriter(outputURL: output, fileType: .mp4)
        writer.shouldOptimizeForNetworkUse = true

        let videoOutput = AVAssetReaderVideoCompositionOutput(
            videoTracks: [videoTrack],
            videoSettings: [
                kCVPixelBufferPixelFormatTypeKey as String:
                    kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            ]
        )
        videoOutput.videoComposition = composition
        videoOutput.alwaysCopiesSampleData = false
        guard reader.canAdd(videoOutput) else { throw CommunityVideoPrepError.failed(nil) }
        reader.add(videoOutput)

        let videoInput = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: size.width,
                AVVideoHeightKey: size.height,
                AVVideoScalingModeKey: AVVideoScalingModeResizeAspect,
                AVVideoColorPropertiesKey: [
                    AVVideoColorPrimariesKey: AVVideoColorPrimaries_ITU_R_709_2,
                    AVVideoTransferFunctionKey: AVVideoTransferFunction_ITU_R_709_2,
                    AVVideoYCbCrMatrixKey: AVVideoYCbCrMatrix_ITU_R_709_2,
                ],
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: bitrate,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                    AVVideoMaxKeyFrameIntervalKey: Int(options.maxFrameRate) * 2,
                    AVVideoExpectedSourceFrameRateKey: Int(options.maxFrameRate),
                ],
            ]
        )
        videoInput.expectsMediaDataInRealTime = false
        guard writer.canAdd(videoInput) else { throw CommunityVideoPrepError.failed(nil) }
        writer.add(videoInput)

        var audioPair: (AVAssetReaderTrackOutput, AVAssetWriterInput)?
        if let audioTrack {
            // Decoded straight to 44.1 kHz stereo: mono and 5.1 sources both
            // land in the AAC encoder's own layout.
            var stereo = AudioChannelLayout()
            stereo.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo
            let layout = Data(bytes: &stereo, count: MemoryLayout<AudioChannelLayout>.size)
            let audioOutput = AVAssetReaderTrackOutput(
                track: audioTrack,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatLinearPCM,
                    AVSampleRateKey: 44_100,
                    AVNumberOfChannelsKey: 2,
                    AVChannelLayoutKey: layout,
                    AVLinearPCMBitDepthKey: 16,
                    AVLinearPCMIsFloatKey: false,
                    AVLinearPCMIsBigEndianKey: false,
                    AVLinearPCMIsNonInterleaved: false,
                ]
            )
            let audioInput = AVAssetWriterInput(
                mediaType: .audio,
                outputSettings: [
                    AVFormatIDKey: kAudioFormatMPEG4AAC,
                    AVNumberOfChannelsKey: 2,
                    AVSampleRateKey: 44_100,
                    AVChannelLayoutKey: layout,
                    AVEncoderBitRateKey: 128_000,
                ]
            )
            audioInput.expectsMediaDataInRealTime = false
            if reader.canAdd(audioOutput), writer.canAdd(audioInput) {
                reader.add(audioOutput)
                writer.add(audioInput)
                audioPair = (audioOutput, audioInput)
            }
        }

        guard reader.startReading() else { throw CommunityVideoPrepError.failed(reader.error) }
        guard writer.startWriting() else {
            reader.cancelReading()
            throw CommunityVideoPrepError.failed(writer.error)
        }
        writer.startSession(atSourceTime: .zero)

        var tracks = [SamplePump.Track(output: videoOutput, input: videoInput, label: "video")]
        if let (audioOutput, audioInput) = audioPair {
            tracks.append(SamplePump.Track(output: audioOutput, input: audioInput, label: "audio"))
        }
        let pump = SamplePump(reader: reader, tracks: tracks)
        await withTaskCancellationHandler {
            await pump.run()
        } onCancel: {
            pump.cancel()
        }

        if Task.isCancelled || reader.status != .completed {
            let error = reader.error ?? writer.error
            reader.cancelReading()
            writer.cancelWriting()
            try? FileManager.default.removeItem(at: output)
            if Task.isCancelled { throw CancellationError() }
            throw CommunityVideoPrepError.failed(error)
        }
        await writer.finishWriting()
        guard writer.status == .completed else {
            try? FileManager.default.removeItem(at: output)
            throw CommunityVideoPrepError.failed(writer.error)
        }
    }
}

/// Moves samples from the reader outputs to the writer inputs as fast as the
/// encoder takes them, each track on its own queue. AVFoundation objects are
/// not `Sendable`; each track is only touched from its own serial queue.
private final class SamplePump: @unchecked Sendable {
    final class Track: @unchecked Sendable {
        let output: AVAssetReaderOutput
        let input: AVAssetWriterInput
        let label: String
        var finished = false

        init(output: AVAssetReaderOutput, input: AVAssetWriterInput, label: String) {
            self.output = output
            self.input = input
            self.label = label
        }
    }

    private let reader: AVAssetReader
    private let tracks: [Track]

    init(reader: AVAssetReader, tracks: [Track]) {
        self.reader = reader
        self.tracks = tracks
    }

    func run() async {
        await withTaskGroup(of: Void.self) { group in
            for track in tracks {
                group.addTask { await self.copy(track) }
            }
        }
    }

    func cancel() {
        reader.cancelReading()
    }

    private func copy(_ track: Track) async {
        let queue = DispatchQueue(label: "io.appwin.community.video-prep.\(track.label)")
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            track.input.requestMediaDataWhenReady(on: queue) { [self] in
                guard !track.finished else { return }
                while track.input.isReadyForMoreMediaData {
                    guard reader.status == .reading,
                          let sample = track.output.copyNextSampleBuffer(),
                          track.input.append(sample)
                    else {
                        track.finished = true
                        track.input.markAsFinished()
                        continuation.resume()
                        return
                    }
                }
            }
        }
    }
}
