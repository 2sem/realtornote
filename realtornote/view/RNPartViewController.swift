//
//  RNPartViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 26..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
import FirebaseAnalytics

protocol RNPartViewControllerDelegate : NSObjectProtocol{
    func partViewController(_ partViewController: RNPartViewController, didChangeFontSize size: CGFloat);
    
    func partViewControllerMoveLeft(_ partViewController: RNPartViewController);
    func partViewControllerMoveRight(_ partViewController: RNPartViewController);
}

class RNPartViewController: UIViewController, UITextViewDelegate, UISearchBarDelegate {

    class constraints{
        static let HIDE_SEARCH_BAR = "HIDE_SEARCH_BAR";
        static let SHOW_SEARCH_BAR = "SHOW_SEARCH_BAR";
        static let CONTENT_BOTTOM = "CONTENT_BOTTOM";
    }
    
    var modelController : RNModelController{
        get{
            return RNModelController.shared;
        }
    }
    
    var subjectViewController : RNSubjectViewController?{
        get{
            return self.presentingViewController as? RNSubjectViewController;
        }
    }
    
    var part : RNPartInfo!;
    static var contentFontSize : CGFloat?;
    var paragraphs : [LSDocumentRecognizer.LSDocumentParagraph] = [];
    
    var delegate : RNPartViewControllerDelegate?;
    
    //var constraint_hide_search_bar : NSLayoutConstraint?;
    @IBOutlet var constraint_hide_search_bar: NSLayoutConstraint!
    var constraint_show_search_bar : NSLayoutConstraint?;
    //var constraint_content_bottom : NSLayoutConstraint?;
    @IBOutlet var constraint_content_bottom: NSLayoutConstraint!
    
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentView: UITextView!
    @IBOutlet weak var bookButton: UIButton!
    @IBOutlet weak var searchButton: UIButton!
    @IBOutlet weak var searchBar: UISearchBar!
    
    static let bookOnImage = UIImage(named: "icon_book_on")?.withRenderingMode(.alwaysTemplate);
    static let bookOffImage = UIImage(named: "icon_book_off")?.withRenderingMode(.alwaysTemplate);
    
    override func viewWillAppear(_ animated: Bool) {
        //self.contentView.scrollRectToVisible(CGRect.zero, animated: false);
        if RNPartViewController.contentFontSize != nil{
            self.contentView.font = self.contentView.font?.withSize(RNPartViewController.contentFontSize!);
        }
        
        /*if let lastChapter = RNDefaults.LastChapter[Int(self.part.seq)]{
            
        }*/
        
        LSDefaults.setLastPart(chapter: Int(self.part.chapter?.no ?? 0), value: Int(self.part.seq));
        
        /*var lastOffsets = RNDefaults.LastContentOffset;
        lastOffsets[Int(self.part.chapter?.no ?? 0)] = 0;
        RNDefaults.LastContentOffset = lastOffsets;*/
        
        self.searchBar.showsCancelButton = true;
        self.toggleFavorite(self.modelController.isExistFavorite(self.part));
        self.bookButton.isHidden = self.navigationController?.visibleViewController === self;
    }
    
    var maxFontSize : CGFloat = 30;
    var minFontSize : CGFloat = 14;
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        DispatchQueue.main.async{
            self.paragraphs = LSDocumentRecognizer.shared.recognize(doc: self.part.content ?? "");
            //, symbols: [LSDocumentRecognizer.LSDocumentParagraph.IndexType]);
            
            self.titleLabel.text = "\(self.part?.seq ?? 0). \(self.part?.name ?? "")";
            //self.contentView.text = self.part.content;
            self.contentView.text = LSDocumentRecognizer.shared.toString(self.paragraphs);
            //self.contentView.text = self.part.content ?? "";
            
            self.loadOffset();
            self.contentView.isScrollEnabled = true;
        }
        //CGPoint.init()
        //self.contentView.contentOffset = CGPoint.init(x: self.contentView.contentInset.left, y: self.contentView.contentInset.top);
        self.contentView.isScrollEnabled = false;
        
        self.navigationItem.title = "\(part?.seq ?? 0). \(part?.name ?? "")";
        
        self.searchBar.delegate = self;
        self.constraint_hide_search_bar = self.view.constraints.first(where: { (cst) -> Bool in
            return cst.identifier == constraints.HIDE_SEARCH_BAR;
        })
        self.constraint_show_search_bar = self.titleView.topAnchor.constraint(equalTo: self.searchBar.bottomAnchor);
        self.constraint_show_search_bar?.isActive = false;
        
        self.constraint_content_bottom = self.view.constraints.first(where: { (cst) -> Bool in
            return cst.identifier == constraints.CONTENT_BOTTOM;
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.setScreenName(for: self);
        Analytics.logLeesamEvent(.selectPart, parameters: [:]);
        //self.contentView.scrollRectToVisible(CGRect.zero, animated: false);
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(noti:)), name: UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(noti:)), name: UIResponder.keyboardWillHideNotification, object: nil);
        
        //GADInterstialManager.shared?.show();
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        if self.constraint_show_search_bar?.isActive ?? false{
            if !self.searchRanges.isEmpty{
                self.contentView.text = self.contentView.attributedText.string;
            }
            self.showSearchBar(false);
        }
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil);
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadOffset(){
        let y = LSDefaults.getLastContentOffset(Int(self.part?.no ?? 0));
        self.contentView.contentOffset = CGPoint(x: self.contentView.contentInset.left, y: CGFloat(y) + self.contentView.contentInset.top);
    }
    
    func toggleFavorite(_ on : Bool){
        if on{
            self.bookButton.setImage(RNPartViewController.bookOnImage, for: .normal);
        }else{
            self.bookButton.setImage(RNPartViewController.bookOffImage, for: .normal);
        }
    }
    
    func showSearchBar(_ visible : Bool){
        if visible{
            self.constraint_hide_search_bar?.isActive = false;
            self.constraint_show_search_bar?.isActive = true;
        }else{
            self.constraint_show_search_bar?.isActive = false;
            self.constraint_hide_search_bar?.isActive = true;
        }
        
        if visible{
            self.navigationController?.isNavigationBarHidden = true;
        }
        
        UIView.animate(withDuration: 0.5, animations: {
        self.view.layoutIfNeeded();
            if visible{
                self.searchBar.becomeFirstResponder();
            }else{
                self.searchBar.resignFirstResponder();
                self.navigationController?.isNavigationBarHidden = false;
            }
        }) { (result) in
        }
    }
    @IBAction func onShowSearchBar(_ button: UIButton) {
        Analytics.logLeesamEvent(.openSearch, parameters: [:]);
//        AppDelegate.sharedGADManager?.show(unit: .full) { [weak self](unit, ad, result) in
            self.showSearchBar(true);
//        }
    }
    
    @IBAction func onFavor(_ sender: UIButton) {
        if let favor = self.modelController.findFavorite(self.part){
            self.modelController.removeFavorite(favor);
            self.toggleFavorite(false);
            Analytics.logLeesamEvent(.offFavorite, parameters: [:]);
            //act.image = favOffImage;
        }
        else{
            self.modelController.createFavorite(self.part);
            self.toggleFavorite(true);
            Analytics.logLeesamEvent(.onFavorite, parameters: [:]);
            //act.image = favOnImage;
        }
        
        self.modelController.saveChanges();
    }
    
    @IBAction func onPinch(_ gesture: UIPinchGestureRecognizer) {
        var fontSize = self.contentView.font?.pointSize ?? 0.0;
        if gesture.velocity > 0{
            Analytics.logLeesamEvent(.zoomIn, parameters: [:]);
            fontSize = min(self.maxFontSize, fontSize + 1);
        }else{
            Analytics.logLeesamEvent(.zoomOut, parameters: [:]);
            fontSize = max(self.minFontSize, fontSize - 1);
        }
        
        self.contentView.font = self.contentView.font?.withSize(fontSize);
        RNPartViewController.contentFontSize = fontSize;
        self.delegate?.partViewController(self, didChangeFontSize: RNPartViewController.contentFontSize!);
    }
    
    @IBAction func onDoubleTap(_ gesture: UITapGestureRecognizer) {
        guard let contentView = self.contentView else{
            return;
        }
        
        let pos = gesture.location(in: contentView);
        if pos.x < contentView.frame.size.width/2{ //left
            print("double tap left");
            self.delegate?.partViewControllerMoveLeft(self);
        }else{ //right
            print("double tap right");
            self.delegate?.partViewControllerMoveRight(self);
        }
    }
    
    // MARK: UISearchBarDelegate
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.showSearchBar(false);
        if self.contentView.attributedText != nil{
            self.contentView.text = self.contentView.attributedText.string;
        }
    }
    
    var blockedContent : NSMutableAttributedString?;
    var searchIndex : Int = -1;
    var searchRanges : [NSRange] = [];
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        do{
            let regex = try NSRegularExpression.init(pattern: searchText, options: .caseInsensitive);
            let matches = regex.matches(in: self.contentView.text, options: [], range: self.contentView.text.fullRange);
            self.blockedContent = NSMutableAttributedString.init(string: self.contentView.text);

            self.searchRanges = matches.map{ (result) -> NSRange in
                return result.range;
            };
            for (i, range) in self.searchRanges.enumerated(){
                if i <= 0{
                    self.blockedContent?.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.green, range: range);
                    self.searchIndex = 0;
                }else{
                    self.blockedContent?.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.yellow, range: range);
                }
                //self.contentView.attributedText.add
            }
            
            self.contentView.attributedText = self.blockedContent;
            Analytics.logLeesamEvent(.search, parameters: [:]);
        }catch{}
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard self.searchRanges.count > 1 else{
            return;
        }
        
        self.blockedContent?.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.yellow, range: self.searchRanges[self.searchIndex]);
        
        self.searchIndex = self.searchIndex + 1;
        if self.searchIndex >= self.searchRanges.count{
            self.searchIndex = 0;
        }
        
        let newRange = self.searchRanges[self.searchIndex];
        self.blockedContent?.addAttribute(NSAttributedString.Key.backgroundColor, value: UIColor.green, range: newRange);
        self.contentView.attributedText = self.blockedContent;
        
        self.contentView.scrollRangeToVisible(newRange);
    }
    
    /// MARK: keyboard notification
    var keyboardEnabled = false;
    @objc func keyboardWillShow(noti: NSNotification){
        print("keyboard will show move view to upper -- \(noti.object.debugDescription)");
        //        if self.nativeTextView.isFirstResponder {
        if !keyboardEnabled {
            keyboardEnabled = true;
            //            self.viewContainer.frame.origin.y -= 180;
            let keyboardframe = noti.keyboardFrame;
            
            // - self.bottomBannerView.frame.height
            let screenView = UIApplication.shared.keyWindow?.rootViewController?.view;
            let screenFrame = screenView!.convert(screenView!.bounds, to: nil);
            let contentFrame = self.contentView.convert(self.contentView.bounds, to: screenView);
            let contentBottomOffset = screenFrame.maxY - contentFrame.maxY;
            //self.constraint_content_bottom?.constant = contentBottomOffset - frame.height;
            self.constraint_content_bottom?.constant = -(keyboardframe.height - contentBottomOffset);
            //self.contentView.textContainerInset.bottom = -(frame.height - contentBottomOffset);
        };
        //native y -= (keyboard height - bottom banner height)
        // keyboard top == native bottom
        //        }
    }
    
    @objc func keyboardWillHide(noti: Notification){
        print("keyboard will hide move view to lower  -- \(noti.object.debugDescription)");
        //        if self.nativeTextView.isFirstResponder{
        
        //        }
        //&&
        if keyboardEnabled {
            keyboardEnabled = false;
            //            self.viewContainer.frame.origin.y += 180;
            self.constraint_content_bottom?.constant = 0;
        };
    }
    
    // MARK: UITextViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //print("part scroll. part[\(Int(self.part.no))] offset[\(scrollView.contentOffset.y)]")
        LSDefaults.setLastContentOffSet(part: Int(self.part.no), value: Float(self.contentView.contentOffset.y));
        // scrollView.contentOffset.y
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RNPartViewController : UIGestureRecognizerDelegate{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true;
    }
}
