//
//  RNPartViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 26..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit

protocol RNPartViewControllerDelegate : NSObjectProtocol{
    func partViewController(_ partViewController: RNPartViewController, didChangeFontSize size: CGFloat);
}

class RNPartViewController: UIViewController, UITextViewDelegate {

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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contentView: UITextView!
    @IBOutlet weak var bookButton: UIButton!
    static let bookOnImage = UIImage(named: "icon_book_on")?.withRenderingMode(.alwaysTemplate);
    static let bookOffImage = UIImage(named: "icon_book_off")?.withRenderingMode(.alwaysTemplate);
    
    override func viewWillAppear(_ animated: Bool) {
        //self.contentView.scrollRectToVisible(CGRect.zero, animated: false);
        if RNPartViewController.contentFontSize != nil{
            self.contentView.font = self.contentView.font?.withSize(RNPartViewController.contentFontSize!);
        }
        
        /*if let lastChapter = RNDefaults.LastChapter[Int(self.part.seq)]{
            
        }*/
        
        RNDefaults.setLastPart(chapter: Int(self.part.chapter?.no ?? 0), value: Int(self.part.seq));
        
        /*var lastOffsets = RNDefaults.LastContentOffset;
        lastOffsets[Int(self.part.chapter?.no ?? 0)] = 0;
        RNDefaults.LastContentOffset = lastOffsets;*/
        
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
            
            self.loadOffset();
            self.contentView.isScrollEnabled = true;
        }
        //CGPoint.init()
        //self.contentView.contentOffset = CGPoint.init(x: self.contentView.contentInset.left, y: self.contentView.contentInset.top);
        self.contentView.isScrollEnabled = false;
        
        self.navigationItem.title = "\(part?.seq ?? 0). \(part?.name ?? "")";
    }
    
    override func viewDidAppear(_ animated: Bool) {
        //self.contentView.scrollRectToVisible(CGRect.zero, animated: false);
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadOffset(){
        var y = RNDefaults.getLastContentOffset(Int(self.part?.no ?? 0));
        self.contentView.contentOffset = CGPoint(x: self.contentView.contentInset.left, y: CGFloat(y) + self.contentView.contentInset.top);
    }
    
    func toggleFavorite(_ on : Bool){
        if on{
            self.bookButton.setImage(RNPartViewController.bookOnImage, for: .normal);
        }else{
            self.bookButton.setImage(RNPartViewController.bookOffImage, for: .normal);
        }
    }
    
    @IBAction func onFavor(_ sender: UIButton) {
        if let favor = self.modelController.findFavorite(self.part){
            self.modelController.removeFavorite(favor);
            self.toggleFavorite(false);
            //act.image = favOffImage;
        }
        else{
            self.modelController.createFavorite(self.part);
            self.toggleFavorite(true);
            //act.image = favOnImage;
        }
        
        self.modelController.saveChanges();
    }
    
    @IBAction func onPinch(_ gesture: UIPinchGestureRecognizer) {
        var fontSize = self.contentView.font?.pointSize ?? 0.0;
        if gesture.velocity > 0{
            fontSize = min(self.maxFontSize, fontSize.adding(1));
        }else{
            fontSize = max(self.minFontSize, fontSize.adding(-1));
        }
        
        self.contentView.font = self.contentView.font?.withSize(fontSize);
        RNPartViewController.contentFontSize = fontSize;
        self.delegate?.partViewController(self, didChangeFontSize: RNPartViewController.contentFontSize!);
    }
    
    // MARK: UITextViewDelegate
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        print("part scroll. part[\(Int(self.part.no))] offset[\(scrollView.contentOffset.y)]")
        RNDefaults.setLastContentOffSet(part: Int(self.part.no), value: Float(self.contentView.contentOffset.y));
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
