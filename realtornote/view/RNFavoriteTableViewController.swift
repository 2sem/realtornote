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

    var subjects : [RNSubjectInfo] = [];
    var favoritesForSubjects : [[RNFavoriteInfo]] = [[]];
    var favorites : [RNFavoriteInfo] = [];

    var modelController : RNModelController{
        get{
            return RNModelController.shared;
        }
    }
    
    var partToMove : RNPartInfo!;
    
    enum SortType : Int{
        case no = 0
        case subject = 1
    }
    
    var sortType : SortType{
        return SortType.init(rawValue: self.sortSegmentControl?.selectedSegmentIndex ?? 0) ?? .no;
    }
    
    @IBOutlet weak var sortSegmentControl: UISegmentedControl!
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.sortSegmentControl?.selectedSegmentIndex = LSDefaults.FavoriteSortType;
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.setScreenName(for: self);
        guard self.favorites.isEmpty else{
            return;
        }
        
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
    
    func refresh(){
        
        
        switch self.sortType {
        case .no:
            self.favorites = self.modelController.loadFavoritesByNo();
            break;
        case .subject:
            self.subjects = [];
            self.favoritesForSubjects = [];
            self.modelController.loadFavoritesBySubjectNo().forEach { (fav) in
                guard let subject = fav.part?.chapter?.subject else{
                    return;
                }
                
                var subjectIndex : Int = self.subjects.index(of: subject) ?? self.subjects.count;
                
                if !self.subjects.contains(subject){
                    self.favoritesForSubjects.append([]);
                    self.subjects.append(subject);
                }
                
                
                guard subjectIndex < self.favoritesForSubjects.count else{
                    return;
                }
                self.favoritesForSubjects[subjectIndex].append(fav);
                //favorites.append(<#T##newElement: RNFavoriteInfo##RNFavoriteInfo#>)
            }
            break;
        }
        
        
        self.tableView.reloadData();
    }

    @IBAction func onChangeSortType(_ segmentControl: UISegmentedControl) {
        LSDefaults.FavoriteSortType = segmentControl.selectedSegmentIndex;
        self.refresh();
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.sortType == .no ? 1 : self.subjects.count;
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.sortType == .no ? self.favorites.count : self.favoritesForSubjects[section].count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RNFavoriteTableViewController.CellID, for: indexPath) as? RNFavoriteTableViewCell;

        // Configure the cell...
        cell?.sortType = self.sortType;
        cell?.favor = self.sortType == .no ? self.favorites[indexPath.row] : self.favoritesForSubjects[indexPath.section][indexPath.row];

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
            
            tableView.beginUpdates();
            switch self.sortType {
            case .no:
                if let favorite = cell.favor{
                    self.favorites.remove(favorite, where: { $0 == $1 });
                    self.modelController.removeFavorite(favorite);
                }
                self.modelController.saveChanges();
                tableView.deleteRows(at: [indexPath], with: .fade);
                break;
            case .subject:
                if let favorite = cell.favor{
                    self.favoritesForSubjects[indexPath.section].remove(favorite, where: { $0 == $1 });
                    self.modelController.removeFavorite(favorite);
                }
                
                if self.favoritesForSubjects[indexPath.section].isEmpty{
                    self.favoritesForSubjects.remove(at: indexPath.section);
                    self.subjects.remove(at: indexPath.section);
                    tableView.deleteSections([indexPath.section], with: .automatic);
                }else{
                    tableView.deleteRows(at: [indexPath], with: .fade);
                }
                self.modelController.saveChanges();
                break;
            }
            
            tableView.endUpdates();
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.sortType == .no ? nil : self.subjects[section].name;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.hidesBottomBarWhenPushed = false;
        let favorite : RNFavoriteInfo = self.sortType == .no ? self.favorites[indexPath.row] : self.favoritesForSubjects[indexPath.section][indexPath.row];
        
        self.partToMove = favorite.part;
        
        AppDelegate.sharedGADManager?.show(unit: .full) { [weak self](unit, ad) in
            self?.navigationController?.popViewController(animated: true);
        }
        
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
