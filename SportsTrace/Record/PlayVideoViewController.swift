/// Copyright (c) 2020 Razeware LLC
///

import AVKit
import MobileCoreServices
import UIKit
import CoreData

class PlayVideoViewController: UIViewController {
  
  var isFirstTime = true
    
    
  @IBAction func playVideo(_ sender: AnyObject) {
    VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
  }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if isFirstTime {
            isFirstTime = false
            VideoHelper.startMediaBrowser(delegate: self, sourceType: .savedPhotosAlbum)
        }
    }
    
}

// MARK: - UIImagePickerControllerDelegate
extension PlayVideoViewController: UIImagePickerControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    // 1
    guard
      let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String,
        mediaType == (kUTTypeMovie as String),
      let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL
      else { return }
    
    // 2
    
    self.saveVideo(outputUrl: url)
    
    dismiss(animated: true) {
      //3
       
     self.navigationController!.popViewController(animated: true)

      let player = AVPlayer(url: url)
      let vcPlayer = AVPlayerViewController()
      vcPlayer.player = player
      self.present(vcPlayer, animated: true, completion: nil)
        
    }
        
  }
    
    func saveVideo(outputUrl: URL) {
        let video_id = NSUUID().uuidString
        let video_data : NSData? = NSData(contentsOf: outputUrl)
        Common().saveVideoInDocumentDirectory(video_id, VideoData: video_data)
        
        
        guard let appDelegate =
            UIApplication.shared.delegate as? AppDelegate else {
                return
        }
        
        //////// saving video id to coredata  ///////
        let managedContext = appDelegate.persistentContainer.viewContext
        let videoEntity = NSEntityDescription.insertNewObject(forEntityName: "Videos", into: managedContext) as! Videos
        videoEntity.video_id = video_id
        try? managedContext.save()
    }

    
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    
    internal func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        dismiss(animated: true, completion: nil)
        
     self.navigationController?.popViewController(animated: true)

    }

    
}

// MARK: - UINavigationControllerDelegate
extension PlayVideoViewController: UINavigationControllerDelegate {
}
