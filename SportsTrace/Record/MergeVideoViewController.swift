/// Copyright (c) 2020 Razeware LLC
///

import MediaPlayer
import MobileCoreServices
import Photos
import UIKit

class MergeVideoViewController: UIViewController {
  var firstAsset: AVAsset?
  var secondAsset: AVAsset?
  var audioAsset: AVAsset?
  var loadingAssetOne = false

  @IBOutlet var activityMonitor: UIActivityIndicatorView!

  func exportDidFinish(_ session: AVAssetExportSession) {
    // Cleanup assets
    activityMonitor.stopAnimating()
    firstAsset = nil
    secondAsset = nil
    audioAsset = nil

    guard
      session.status == AVAssetExportSession.Status.completed,
      let outputURL = session.outputURL
      else { return }

    let saveVideoToPhotos = {
    let changes: () -> Void = {
      PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
    }
    PHPhotoLibrary.shared().performChanges(changes) { saved, error in
      DispatchQueue.main.async {
        let success = saved && (error == nil)
        let title = success ? "Success" : "Error"
        let message = success ? "Video saved" : "Failed to save video"

        let alert = UIAlertController(
          title: title,
          message: message,
          preferredStyle: .alert)
        alert.addAction(UIAlertAction(
          title: "OK",
          style: UIAlertAction.Style.cancel,
          handler: nil))
        self.present(alert, animated: true, completion: nil)
      }
    }
    }

    // Ensure permission to access Photo Library
    if PHPhotoLibrary.authorizationStatus() != .authorized {
      PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
          saveVideoToPhotos()
        }
      }
    } else {
      saveVideoToPhotos()
    }
  }

  func savedPhotosAvailable() -> Bool {
    guard !UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum)
      else { return true }

    let alert = UIAlertController(
      title: "Not Available",
      message: "No Saved Album found",
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(
      title: "OK",
      style: UIAlertAction.Style.cancel,
      handler: nil))
    present(alert, animated: true, completion: nil)
    return false
  }

  @IBAction func loadAssetOne(_ sender: AnyObject) {
    if savedPhotosAvailable() {
      loadingAssetOne = true
      VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
    }
  }

  @IBAction func loadAssetTwo(_ sender: AnyObject) {
    if savedPhotosAvailable() {
      loadingAssetOne = false
      VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
    }
  }

  @IBAction func loadAudio(_ sender: AnyObject) {
    let mediaPickerController = MPMediaPickerController(mediaTypes: .any)
    mediaPickerController.delegate = self
    mediaPickerController.prompt = "Select Audio"
    present(mediaPickerController, animated: true, completion: nil)
  }

  // swiftlint:disable:next function_body_length
  @IBAction func merge(_ sender: AnyObject) {
    guard
      let firstAsset = firstAsset,
      let secondAsset = secondAsset
      else { return }

    activityMonitor.startAnimating()

    // 1 - Create AVMutableComposition object. This object
    // will hold your AVMutableCompositionTrack instances.
    let mixComposition = AVMutableComposition()

    // 2 - Create two video tracks
    guard
      let firstTrack = mixComposition.addMutableTrack(
        withMediaType: .video,
        preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
      else { return }

    do {
      try firstTrack.insertTimeRange(
        CMTimeRangeMake(start: .zero, duration: firstAsset.duration),
        of: firstAsset.tracks(withMediaType: .video)[0],
        at: .zero)
    } catch {
      print("Failed to load first track")
      return
    }

    guard
      let secondTrack = mixComposition.addMutableTrack(
        withMediaType: .video,
        preferredTrackID: Int32(kCMPersistentTrackID_Invalid))
      else { return }

    do {
      try secondTrack.insertTimeRange(
        CMTimeRangeMake(start: .zero, duration: secondAsset.duration),
        of: secondAsset.tracks(withMediaType: .video)[0],
        at: firstAsset.duration)
    } catch {
      print("Failed to load second track")
      return
    }

    // 3 - Composition Instructions
    let mainInstruction = AVMutableVideoCompositionInstruction()
    mainInstruction.timeRange = CMTimeRangeMake(
      start: .zero,
      duration: CMTimeAdd(firstAsset.duration, secondAsset.duration))

    // 4 - Set up the instructions — one for each asset
    let firstInstruction = VideoHelper.videoCompositionInstruction(
      firstTrack,
      asset: firstAsset)
    firstInstruction.setOpacity(0.0, at: firstAsset.duration)
    let secondInstruction = VideoHelper.videoCompositionInstruction(
      secondTrack,
      asset: secondAsset)

    // 5 - Add all instructions together and create a mutable video composition
    mainInstruction.layerInstructions = [firstInstruction, secondInstruction]
    let mainComposition = AVMutableVideoComposition()
    mainComposition.instructions = [mainInstruction]
    mainComposition.frameDuration = CMTimeMake(value: 1, timescale: 30)
    mainComposition.renderSize = CGSize(
      width: UIScreen.main.bounds.width,
      height: UIScreen.main.bounds.height)

    // 6 - Audio track
    if let loadedAudioAsset = audioAsset {
      let audioTrack = mixComposition.addMutableTrack(
        withMediaType: .audio,
        preferredTrackID: 0)
      do {
        try audioTrack?.insertTimeRange(
          CMTimeRangeMake(
            start: CMTime.zero,
            duration: CMTimeAdd(
              firstAsset.duration,
              secondAsset.duration)),
          of: loadedAudioAsset.tracks(withMediaType: .audio)[0],
          at: .zero)
      } catch {
        print("Failed to load Audio track")
      }
    }

    // 7 - Get path
    guard
      let documentDirectory = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask).first
      else { return }
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short
    let date = dateFormatter.string(from: Date())
    let url = documentDirectory.appendingPathComponent("mergeVideo-\(date).mov")

    // 8 - Create Exporter
    guard let exporter = AVAssetExportSession(
      asset: mixComposition,
      presetName: AVAssetExportPresetHighestQuality)
      else { return }
    exporter.outputURL = url
    exporter.outputFileType = AVFileType.mov
    exporter.shouldOptimizeForNetworkUse = true
    exporter.videoComposition = mainComposition

    // 9 - Perform the Export
    exporter.exportAsynchronously {
      DispatchQueue.main.async {
        self.exportDidFinish(exporter)
      }
    }
  }
}

// MARK: - UIImagePickerControllerDelegate
extension MergeVideoViewController: UIImagePickerControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    dismiss(animated: true, completion: nil)

    guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
      mediaType == (kUTTypeMovie as String),
      let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
      else { return }

    let avAsset = AVAsset(url: url)
    var message = ""
    if loadingAssetOne {
      message = "Video one loaded"
      firstAsset = avAsset
    } else {
      message = "Video two loaded"
      secondAsset = avAsset
    }
    let alert = UIAlertController(
      title: "Asset Loaded",
      message: message,
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(
      title: "OK",
      style: UIAlertAction.Style.cancel,
      handler: nil))
    present(alert, animated: true, completion: nil)
  }
}

// MARK: - UINavigationControllerDelegate
extension MergeVideoViewController: UINavigationControllerDelegate {
}

// MARK: - MPMediaPickerControllerDelegate
extension MergeVideoViewController: MPMediaPickerControllerDelegate {
  func mediaPicker(
    _ mediaPicker: MPMediaPickerController,
    didPickMediaItems mediaItemCollection: MPMediaItemCollection
  ) {
    dismiss(animated: true) {
      let selectedSongs = mediaItemCollection.items
      guard let song = selectedSongs.first else { return }

      let title: String
      let message: String
      if let url = song.value(forProperty: MPMediaItemPropertyAssetURL) as? URL {
        self.audioAsset = AVAsset(url: url)
        title = "Asset Loaded"
        message = "Audio Loaded"
      } else {
        self.audioAsset = nil
        title = "Asset Not Available"
        message = "Audio Not Loaded"
      }

      let alert = UIAlertController(
        title: title,
        message: message,
        preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
      self.present(alert, animated: true, completion: nil)
    }
  }

  func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
    dismiss(animated: true, completion: nil)
  }
}
