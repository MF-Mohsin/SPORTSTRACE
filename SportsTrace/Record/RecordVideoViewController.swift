/// Copyright (c) 2020 Razeware LLC


import UIKit
import AVFoundation
import CoreData
import AVKit

var isNewvideo = false

class RecordVideoViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    @IBOutlet var topView : UIView!
    @IBOutlet var lblNotFound : UILabel!

   var listArr: NSArray!
      
      var videolist: UICollectionView!
       
       override func viewDidLoad() {
           super.viewDidLoad()
                
          setupCollectionview()
        
       }
       
       override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)
           
//           if isNewvideo {
//               isNewvideo = false
               getListdata()
//           }
           
       }
       
   @IBAction func btnBack(_ sender: UIButton) {
    self.navigationController?.popViewController(animated: true)
    }

    
    func setupCollectionview(){
       
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
            layout.sectionInset = UIEdgeInsets(top:5, left: 5, bottom: 5, right: 5)
            layout.sectionHeadersPinToVisibleBounds = true
             
        let screenSize: CGRect = UIScreen.main.bounds

        videolist = UICollectionView(frame: CGRect(x:0,y:topView.frame.origin.y + topView.frame.size.height + 3,width: self.view.frame.size.width,height:screenSize.height * 0.7), collectionViewLayout: layout)
            videolist.register(UINib(nibName: "CustomCell", bundle: nil), forCellWithReuseIdentifier: "Cell")
            videolist.backgroundColor = UIColor.darkGray
            videolist.delegate = self
            videolist.dataSource = self
       //     videolist.backgroundColor = UIColor.clear
              layout.headerReferenceSize = CGSize(width:      self.videolist.frame.size.width, height: 50)

              self.videolist.register(SectionHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: "header")
              
              self.view.addSubview(videolist)
        
           //   getListdata()
    }
     
    
       func getListdata()  {
           /////////// Getting list of videos from coredata ///////
           guard let appDelegate =
               UIApplication.shared.delegate as? AppDelegate else {
                   return
           }
           let managedContext = appDelegate.persistentContainer.viewContext
           let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
           let entity = NSEntityDescription.entity(forEntityName: "Videos", in: managedContext)
           fetchRequest.entity = entity
           fetchRequest.returnsObjectsAsFaults = false
           listArr = try? managedContext.fetch(fetchRequest) as NSArray
        
        if listArr.count == 0{
            self.lblNotFound.isHidden = false
        } else {
            self.lblNotFound.isHidden = true
        }
        
        self.view.bringSubviewToFront(self.lblNotFound)
        
           videolist.reloadData()
       }
       
       
       func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
           return listArr.count
       }
       
       func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
           let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CustomCell
           
           let vid_entity = listArr.object(at: indexPath.row) as! Videos
           let videoPath = Common().getVideoPathFromDocumentDirectory(vid_entity.video_id)
           let videoUrl = Common().GetVideoUrl(path: videoPath)
           let img = Common().getThumbnailImage(forUrl: videoUrl)
           
            let deleteButton = UIButton(frame: CGRect(x:140, y:5, width:30,height:30))
            deleteButton.setImage(UIImage(named: "delete"), for: UIControl.State.normal)
            deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: UIControl.Event.touchUpInside)
            deleteButton.tag = indexPath.row
            cell.addSubview(deleteButton)
                
           let asset = AVURLAsset(url: videoUrl)
           cell.durationLbl.text = asset.duration.durationText
           print(asset.duration.durationText)
           if img != nil {
               cell.imageview.image = img
           }
           else{
   //            cell.imageview.image = UIImage(named: "")
           }
           
           return cell
       }
       
       func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
           let size = (self.view.frame.size.width-20)/2
           return CGSize(width: size, height: size)
       }
       
       func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
           let vid_entity = listArr.object(at: indexPath.row) as! Videos
           let videoPath = Common().getVideoPathFromDocumentDirectory(vid_entity.video_id)
           let videoUrl = Common().GetVideoUrl(path: videoPath)

           let player = AVPlayer(url: videoUrl)
           let playerViewController = AVPlayerViewController()
           playerViewController.player = player
           self.present(playerViewController, animated: true) {
               playerViewController.player!.play()
           }

       }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
             let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "header", for: indexPath) as! SectionHeader
             sectionHeader.label.text = "Recorded Videos:"
             return sectionHeader
        } else { //No footer in this case but can add option for that
             return UICollectionReusableView()
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 40)
    }
    
    @IBAction func deleteButtonTapped(_sender : UIButton) -> Void {
        
        let vid_entity = listArr.object(at: _sender.tag) as! Videos
        let videoPath = Common().getVideoPathFromDocumentDirectory(vid_entity.video_id)

        let videoUrlNew = Common().GetVideoUrl(path: videoPath)
        let pathString = videoUrlNew.path // String
        
        if FileManager.default.fileExists(atPath: pathString) {
            do {
                try FileManager.default.removeItem(atPath: pathString)
                print("video removed")

            } catch {
                print("an error during a removing")
            }
        }
        
        guard let appDelegate =
          UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
     //   let vid_entity = listArr.object(at: _sender.tag) as! Videos
        let managedContext = appDelegate.persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "Videos") // Find this name in your .xcdatamodeld file
        managedContext.delete(vid_entity as NSManagedObject)

        do {
            try managedContext.save()
        } catch _ {
            
        }
        
        getListdata()
        
    }

    
}


class SectionHeader: UICollectionReusableView {
     var label: UILabel = {
         let label: UILabel = UILabel()
         label.textColor = .white
         label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
         label.sizeToFit()
         label.font = UIFont(name:"Copperplate", size:18.0)
 
         return label
     }()

     override init(frame: CGRect) {
         super.init(frame: frame)

         addSubview(label)

         label.translatesAutoresizingMaskIntoConstraints = false
         label.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
         label.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 5).isActive = true
         label.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


