//
//  RNFavoriteTableViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 30..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import Firebase

class RNFavoriteTableViewController: UITableViewController {
    static let CellID = "RNFavoriteTableViewCell";

    var favorites : [RNFavoriteInfo] = [];

    var modelController : RNModelController{
        get{
            return RNModelController.shared;
        }
    }
    
    var partToMove : RNPartInfo!;
    
    override func viewWillAppear(_ animated: Bool) {
        AppDelegate.sharedGADManager?.show(unit: .full);
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.setScreenName(for: self);
        self.favorites = self.modelController.loadFavoritesByNo();
        self.refresh();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard self.partToMove != nil else{
            return;
        }
        
        let tabBar = self.tabBarController as? RNTabBarController;
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            tabBar?.moveToPart(self.partToMove);
        }
    }
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        //self.dismiss(animated: true, completion: nil);
        self.navigationController?.popViewController(animated: true);
    }
    
    func refresh(_ needToScrollTop : Bool = false){
        self.tableView.reloadData();
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.favorites.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RNFavoriteTableViewController.CellID, for: indexPath) as? RNFavoriteTableViewCell;

        // Configure the cell...
        let favor = self.favorites[indexPath.row];
        cell?.favor = favor;

        return cell!
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            guard let cell = tableView.cellForRow(at: indexPath) as? RNFavoriteTableViewCell else{
                return;
            }
            
            self.favorites.remove(at: self.favorites.index(of: cell.favor)!);
            self.modelController.removeFavorite(cell.favor);
            self.modelController.saveChanges();
            tableView.deleteRows(at: [indexPath], with: .fade);
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.hidesBottomBarWhenPushed = false;
        let favorite = self.favorites[indexPath.row];
        self.partToMove = favorite.part;
        self.navigationController?.popViewController(animated: true);
        /*var main = self.tabBarController as? MainViewController;
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            main?.moveToPart(favorite.part!);
        }*/
    }
    
    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let view = segue.destination as? RNPartViewController{
            let part = self.favorites[self.tableView.indexPathForSelectedRow?.row ?? 0].part;
            view.part = part;
        }
    }
}
