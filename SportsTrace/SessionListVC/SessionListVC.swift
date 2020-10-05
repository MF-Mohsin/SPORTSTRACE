//
//  SessionListVC.swift
//  SportsTrace
//
//  Created by Nishant Shah on 29/09/20.
//  Copyright © 2020 MF. All rights reserved.
//

import UIKit

class SessionListVC: UIViewController,UITableViewDelegate, UITableViewDataSource {
   
    // These strings will be the data for the table view cells
    let sessionArr: [String] = ["Afternoon Swings", "Morning Swings", "Evening Bullpen", "Evening Bullpen", "Evening Bullpen","Afternoon Swings","Afternoon Swings","Afternoon Swings","Afternoon Swings"]
    let cellReuseIdentifier = "cell"
    @IBOutlet var tableView: UITableView!
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.sessionArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:MyCustomCell = self.tableView.dequeueReusableCell(withIdentifier: cellReuseIdentifier) as! MyCustomCell
        
        cell.lblTitle.text = self.sessionArr[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("You tapped cell number \(indexPath.row).")
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
    
        // Do any additional setup after loading the view.
    }

    @IBAction func menuButtonDidClicked(_ sender: Any) {
               sideMenuController?.revealMenu()
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
