//
//  RNFavoriteTableViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 30..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import FirebaseAnalytics

class RNFavoriteTableViewController: UITableViewController {
    class Cells{
        static let `default` = "RNFavoriteTableViewCell";
        static let ads = "ads";
    }
    

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
    
    func isAdsCell(_ indexPath: IndexPath) -> Bool{
        return indexPath.section == 0;
    }
        
    func isAdsSection(_ section: Int) -> Bool{
        return self.needAdsCell && section == 0;
    }
    
    var needAdsCell : Bool{
        get{
            return true;
        }
    }
    
    func realSection(section: Int) -> Int{
        return self.needAdsCell ? section.advanced(by: -1) : section;
    }
    
    func realSubject(section: Int) -> RNSubjectInfo{
        return self.needAdsCell ? self.subjects[section.advanced(by: -1)] : self.subjects[section];
    }
    
    func realFavorites(section: Int) -> [RNFavoriteInfo]{
        return self.needAdsCell ? self.favoritesForSubjects[section.advanced(by: -1)] : self.favoritesForSubjects[section];
    }
    
    @IBOutlet weak var sortSegmentControl: UISegmentedControl!
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.hideExtraRows = true;
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
                
                let subjectIndex : Int = self.subjects.index(of: subject) ?? self.subjects.count;
                
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
        let value = self.sortType == .no ? 1 : self.subjects.count;
        
        return value.advanced(by: self.needAdsCell ? 1 : 0);
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        guard !self.isAdsSection(section) else{
            return 1;
        }
        
        return self.sortType == .no ? self.favorites.count : self.favoritesForSubjects[self.needAdsCell ? section.advanced(by: -1) : section].count;
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell : UITableViewCell! = nil;
        
        guard !self.isAdsCell(indexPath) else{
            if let adsCell = tableView.dequeueReusableCell(withIdentifier: Cells.ads, for: indexPath) as? GADNativeTableViewCell{
                cell = adsCell;
                adsCell.rootViewController = self;
                adsCell.loadAds();
            }
            return cell;
        }
        
        let favorCell : RNFavoriteTableViewCell!;
        //let indexPath : IndexPath = .init(row: indexPath.row, section: indexPath.section.advanced(by: -1));
        favorCell = tableView.dequeueReusableCell(withIdentifier: Cells.default, for: indexPath) as? RNFavoriteTableViewCell;

        
        // Configure the cell...
        favorCell?.sortType = self.sortType;
        favorCell?.favor = self.sortType == .no ? self.favorites[indexPath.row] : self.realFavorites(section: indexPath.section)[indexPath.row];
        cell = favorCell;
        
        return cell!
    }

    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return !self.isAdsSection(indexPath.section);
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard !self.isAdsSection(indexPath.section) else{
            return;
        }
        
        //let indexPath : IndexPath = .init(row: indexPath.row, section: indexPath.section.advanced(by: -1));
        
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
                    self.favoritesForSubjects[self.realSection(section: indexPath.section)].remove(favorite, where: { $0 == $1 });
                    self.modelController.removeFavorite(favorite);
                }
                
                if self.favoritesForSubjects[self.realSection(section: indexPath.section)].isEmpty{
                    self.favoritesForSubjects.remove(at: self.realSection(section: indexPath.section));
                    self.subjects.remove(at: self.realSection(section: indexPath.section));
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
        guard !self.isAdsSection(section) else{
            return nil;
        }
        
        return self.sortType == .no ? nil : self.subjects[self.needAdsCell ? section.advanced(by: -1) : section].name;
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !self.isAdsSection(indexPath.section) else{
            return;
        }
        
        self.hidesBottomBarWhenPushed = false;
        let favorite : RNFavoriteInfo = self.sortType == .no ? self.favorites[indexPath.row] : self.realFavorites(section: indexPath.section)[indexPath.row];
        
        self.partToMove = favorite.part;
        
//        AppDelegate.sharedGADManager?.show(unit: .full) { [weak self](unit, ad, result) in
            self.navigationController?.popViewController(animated: true);
//        }
        
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
//    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
//        AppDelegate.sharedGADManager?.show(unit: .full, completion: nil)
//
//        return false;
//    }

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
