//
//  RNSubjectViewController.swift
//  realtornote
//
//  Created by 영준 이 on 2017. 7. 26..
//  Copyright © 2017년 leesam. All rights reserved.
//

import UIKit
//import DownPicker
import DropDown
import FirebaseAnalytics
//import AnimatedGradientView

class RNSubjectViewController: UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    class Segues{
        static let alarm = "alarm";
        static let quiz = "quiz";
        static let favorite = "favorite";
    }
    
    var subject : RNSubjectInfo?;
    var chapter : RNChapterInfo!;
    var chapters : [RNChapterInfo] = [];
    var parts : [RNPartInfo]{
        get{
            return self.chapter.chapterParts.sorted(by: { (left, right) -> Bool in
                return left.seq < right.seq;
            });
        }
    }
    var part : RNPartInfo!{
        /*get{
            return (self.viewControllers?.first as? RNPartViewController)?.part;
        }*/
        didSet{
            var partView : UIViewController?;
            
            guard self.part != nil else{
                return;
            }
            
            if let view = self.partViewControllers[Int(self.part.seq)]{
                partView = view;
                
            }else{
                partView = self.createPartView(self.part);
            }
            
            if self.chapter?.seq != self.part.chapter?.seq{
                /*self.subject?.subjectChapters.sorted(by: { (left, right) -> Bool in
                    return left.seq < right.seq;
                }) ?? [];*/
                guard self.chapter != nil else{
                    return;
                }
                
                //self.chapterPicker.downPicker.selectedIndex = self.chapters.index(of: self.part.chapter!) ?? 0;
                self.chapterDropDown.selectRow(self.chapters.index(of: self.part.chapter!) ?? 0);
                //self.onChapterSelected(self.chapterPicker.downPicker);
            }
            
            let hasViewControllers = self.viewControllers?.isEmpty ?? true;
            self.setViewControllers([partView!], direction: .forward, animated: !hasViewControllers, completion: nil);
        }
    }
    var currentPart : RNPartInfo?{
        guard let partView = self.viewControllers?.first as? RNPartViewController else{
            return nil;
        }
        
        return partView.part;
    }
    var currentPartIndex : Int{
        guard let part = self.currentPart else{
            return 0;
        }
        
        return self.parts.index(of: part) ?? 0;
    }
    var isTransitioning = false;
    var partViewControllers : [Int : RNPartViewController] = [:];
    var partContentFontSize : CGFloat?;
    
    //var chapterPicker : UIDownPicker!;
    lazy var chapterDropDown : DropDown = {
        var value = DropDown();
        value.dataSource = chapters.map{ "\($0.seq.roman). \($0.name ?? "")" }
        value.selectionAction = { [weak self](index, item) in
            guard self?.chapter != self?.chapters[index] else{
                return;
            }
            
            guard let chapter = self?.chapters[index] else{
                return;
            }
            
            Analytics.logLeesamEvent(.selectChapter, parameters: [:]);
            self?.chapter = chapter;
            self?.select(chapter: chapter);
        }
        
        return value;
    }()
    
    var modelController : RNModelController{
        get{
            return RNModelController.shared;
        }
    }
    
    @IBOutlet weak var chapterSelectButton: UIButton!
    var leftButton : UIButton!;
    var rightButton : UIButton!;
    
//    lazy var animatedLeftGradient : AnimatedGradientView = {
//        var value = AnimatedGradientView.init(frame: self.view.bounds);
//        let bg = "#81d4fa".toUIColor()!;
//
//        value.autoAnimate = false;
//        value.colors = [[.clear, bg, .clear]] //, [black20, black50]
//        value.direction = .left;
//        value.animationDuration = 5.0;
//
//        self.view?.addSubview(value);
//
//        return value;
//    }();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view, typically from a nib.
        if LSDefaults.ContentSize > 0{
            self.partContentFontSize = CGFloat(LSDefaults.ContentSize);
        }
        
        self.navigationItem.title = subject?.name;
        
        let subjectChapters = [RNChapterInfo].init(self.subject?.subjectChapters.map{ $0 } ?? []);
        self.chapters = subjectChapters.sorted(by: { (left, right) -> Bool in
            return left.seq < right.seq;
        }) ?? [];
        /*self.chapterPicker = UIDownPicker(data: chapters.map({ (chp) -> String in
            return "\(chp.seq.roman). \(chp.name ?? "")";
        }));*/
        
        //self.chapterPicker.downPicker.setToolbarDoneButtonText("완료");
        //self.chapterPicker.downPicker.setToolbarCancelButtonText("취소");
        
        if self.chapter == nil{
            if self.part != nil{
                self.chapter = self.part!.chapter;
            }else{
                self.chapter = self.chapters.first(where: { (chapter) -> Bool in
                    return Int(chapter.no) == LSDefaults.LastChapter[Int(self.subject?.no ?? 1).description];
                });
            }
        }
        
        if self.chapter == nil{
            self.chapter = self.chapters.first;
        }
        
        //self.chapterPicker.downPicker.selectedIndex = self.chapters.index(of: self.chapter!) ?? 0;
            
        
        self.chapterSelectButton.setTitle("\(self.chapter.seq.roman). \(self.chapter.name ?? "") ▼", for: .normal);
        //self.chapterPicker.downPicker.addTarget(self, action: #selector(onChapterSelected(_:)), for: .valueChanged);
        //self.view.addSubview(self.chapterPicker);
        self.chapterSelectButton.sizeToFit();
        
        self.delegate = self;
        self.dataSource = self;
        
        if self.part != nil{
            LSDefaults.LastPart[Int((self.part.chapter?.no)!).description] = Int(self.part?.seq ?? 1);
        }
        self.updateParts();
        
        let pageControl = UIPageControl.appearance();
        
        pageControl.backgroundColor = "#81d4fa".toUIColor();
        pageControl.tintColor = "#0288d1".toUIColor();
        self.view.backgroundColor = pageControl.backgroundColor;
        //self.animatedLeftGradient.startAnimating();
        return;
        /*self.leftButton = UIButton();
        self.leftButton.setImage(UIImage.init(named: "icon_left"), for: .normal);
        self.leftButton.isUserInteractionEnabled = false;
        self.view.addSubview(self.leftButton);
        self.leftButton.widthAnchor.constraint(equalToConstant: 44).isActive = true;
        self.leftButton.heightAnchor.constraint(equalToConstant: 25).isActive = true;
        self.leftButton.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true;
        self.leftButton.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true;
        //self.view.bringSubview(toFront: self.leftButton);
        //self.leftButton.tintColor = UIColor.white;
        
        self.rightButton = UIButton();
        self.rightButton.setImage(UIImage.init(named: "icon_right"), for: .normal);
        self.rightButton.isUserInteractionEnabled = false;
        //self.view.bringSubview(toFront: self.rightButton);
        //self.rightButton.tintColor = UIColor.white;
        
        pageControl.addSubview(self.rightButton);
        self.rightButton.heightAnchor.constraint(equalToConstant: 25).isActive = true;
        self.rightButton.widthAnchor.constraint(equalToConstant: 44).isActive = true;
        //self.rightButton.trailingAnchor.constraint(equalTo: pageControl.trailingAnchor).isActive = true;
        //self.rightButton.bottomAnchor.constraint(equalTo: pageControl.bottomAnchor).isActive = true;*/
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        Analytics.setScreenName(for: self);
    }
    
    @IBAction func onShare(_ button: UIBarButtonItem) {
        Analytics.logLeesamEvent(.pressShare, parameters: [:]);
        ReviewManager.shared?.show(true);
    }
    
    func createPartView(_ part : RNPartInfo) -> RNPartViewController{
        let value : RNPartViewController! = self.storyboard?.instantiateViewController(withIdentifier: "RNPartViewController") as? RNPartViewController;
        value.part = part;
        self.partViewControllers[Int(part.seq)] = value;
        value.delegate = self;
        
        return value;
    }
    
    func updateParts(){
        self.partViewControllers = [:];
        self.parts.forEach { (part) in
            self.partViewControllers[Int(part.seq)] = self.createPartView(part);
        }
        
        let storedPart = LSDefaults.LastPart[Int(self.chapter.no).description] ?? 1;
        let view : RNPartViewController! = self.partViewControllers[max(storedPart, 1)];
        //var view : RNPartViewController! = self.createPartView(self.parts.first!);
        //self.partViewControllers[Int(view.part.seq)] = view;
        let hasViewControllers = self.viewControllers?.isEmpty ?? true;
        self.setViewControllers([view], direction: UIPageViewController.NavigationDirection.forward, animated: !hasViewControllers, completion: nil);
        
        LSDefaults.setLastChapter(subject: Int(self.subject?.no ?? 1), value: Int(self.chapter?.no ?? 1));
    }
    
    func select(chapter: RNChapterInfo){
        self.chapterSelectButton.setTitle("\(chapter.seq.roman). \(chapter.name ?? "") ▼", for: .normal);
        self.chapterSelectButton.sizeToFit();
        //refresh
        self.updateParts();
        print("selected \(chapter.name ?? "")");
        AppDelegate.sharedGADManager?.show(unit: .full, completion: nil);
    }
    
    @IBAction func onChangeChapter(_ button: UIButton) {
        //self.chapterPicker.becomeFirstResponder();
        Analytics.logLeesamEvent(.openChapterList, parameters: [:]);
        self.chapterDropDown.anchorView = button;
        self.chapterDropDown.show();
    }
    
    /*@objc func onChapterSelected(_ picker: DownPicker){
        guard self.chapter != self.chapters[picker.selectedIndex] else{
            return;
        }
        
        self.chapter = self.chapters[picker.selectedIndex];
        self.chapterSelectButton.setTitle("\(self.chapter.seq.roman). \(self.chapter.name ?? "") ▼", for: .normal);
        self.chapterSelectButton.sizeToFit();
        //refresh
        self.updateParts();
        print("selected \(self.chapter.name ?? "")");
    }*/
    
    // MARK: UIPageViewControllerDataSource
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var value : RNPartViewController?;
        let partViewController = viewController as? RNPartViewController;
        let part : RNPartInfo! = partViewController?.part;
        
        /*guard part.seq ?? 0 > 1 else{
            return value;
        }*/
        
        var newIndex = Int(part.seq - 1);
        if newIndex < 1{
            newIndex = self.parts.count;
        }
        
        if let view = self.partViewControllers[newIndex]{
            value = view;
        }else{
            value = self.createPartView(self.parts[min(newIndex - 1, self.parts.count - 1)]);
        }
        
        //value?.contentFontSize = self.partContentFontSize;
        return value;
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var value : RNPartViewController?;
        let partViewController = viewController as? RNPartViewController;
        let part : RNPartInfo! = partViewController?.part;

        /*guard Int(part.seq ?? 0) < self.chapter.chapterParts.count else{
            return value;
        }*/
    
        var newIndex = Int(part.seq + 1);
        if newIndex > self.chapter.chapterParts.count{
            newIndex = 1;
        }
        
        if let view = self.partViewControllers[newIndex]{
            value = view;
        }else{
            value = self.createPartView(self.parts[max(0, newIndex - 1)]);
        }
        
        //value?.contentFontSize = self.partContentFontSize;
        return value;
    }
    
    func presentationCount(for pageViewController: UIPageViewController) -> Int {
        return self.parts.count
    }
    
    func presentationIndex(for pageViewController: UIPageViewController) -> Int {
        let view = pageViewController.viewControllers?.first as? RNPartViewController;
        return Int(view!.part.seq - 1);
        //return Int(view?.part.seq ?? 0) - 1;
    }
    
    // MARK: UIPageViewControllerDelegate
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        self.isTransitioning = true;
        print("begin transitioning");
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        self.isTransitioning = false;
        print("end transitioning");
    }
    
    // MARK: - Navigation
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        
        switch identifier {
        case Segues.quiz:
            return true;
        case Segues.alarm:
            return true;
        default:
            self.performSegue(withIdentifier: identifier, sender: sender);
            AppDelegate.sharedGADManager?.show(unit: .full, completion: nil)
            break;
        }
        
        return false;
    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        //Set paragraphs of current part as paragraphs of RNQuestionViewController to create questions
        if let nav = segue.destination as? UINavigationController{
            if let view = nav.viewControllers.first as? RNQuestionViewController{
                Analytics.logLeesamEvent(.startQuiz, parameters: [:]);
                
                let partView = self.viewControllers?.first as? RNPartViewController;
                var paragraphs : [LSDocumentRecognizer.LSDocumentParagraph] = [];
                for paragraph in partView!.paragraphs{
                    paragraphs.append(paragraph)
                    paragraphs.append(contentsOf: paragraph.allParagraphs);
                }
                
                view.questions = RNQuestionInfo.createQuestions(paragraphs);
            }
        }
    }
}

extension RNSubjectViewController : RNPartViewControllerDelegate{
    // MARK: RNPartViewControllerDelegate
    func partViewController(_ partViewController: RNPartViewController, didChangeFontSize size: CGFloat) {
        LSDefaults.ContentSize = Float(size);
    }
    
    func partViewControllerMoveLeft(_ partViewController: RNPartViewController) {
        let firstSeq = self.parts.first?.seq ?? 0;
        let lastSeq = self.parts.last?.seq ?? 0;
        guard !self.isTransitioning, let seq = partViewController.part?.seq.advanced(by: -1) else{
            return;
        }
        
        guard let partView = self.partViewControllers[Int(seq < firstSeq ? lastSeq : seq)] else{
            return;
        }
        
        self.isTransitioning = true;
        self.view?.isUserInteractionEnabled = false;
        DispatchQueue.main.async {[weak self] in
            self?.setViewControllers([partView], direction: .reverse, animated: true){ [weak self](result) in
                self?.view?.isUserInteractionEnabled = true;
                self?.isTransitioning = false;
            }
        }
    }
    
    func partViewControllerMoveRight(_ partViewController: RNPartViewController) {
        let firstSeq = self.parts.first?.seq ?? 0;
        let lastSeq = self.parts.last?.seq ?? 0;
        guard !self.isTransitioning, let seq = partViewController.part?.seq.advanced(by: 1) else{
            return;
        }
        
        guard let partView = self.partViewControllers[Int(seq > lastSeq ? firstSeq : seq)] else{
            return;
        }
        
        self.isTransitioning = true;
        self.view?.isUserInteractionEnabled = false;
        DispatchQueue.main.async { [weak self] in
            self?.setViewControllers([partView], direction: .forward, animated: true){ [weak self](result) in
                self?.view?.isUserInteractionEnabled = true;
                self?.isTransitioning = false;
            }
        }
    }
}
