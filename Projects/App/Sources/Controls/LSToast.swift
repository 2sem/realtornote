//
//  LSToast.swift
//  realtornote
//
//  Created by 영준 이 on 2020/12/26.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit
import Toast
import SwiftyGif

class LSToast : NSObject{
    static func make(_ message: String?, view: UIView? = nil, duration: TimeInterval = ToastManager.shared.duration, delay: TimeInterval = 0, title: String? = nil, position: ToastPosition = ToastManager.shared.position){
        guard let msg = message, msg.any else{
            return;
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard let root = AppDelegate.sharedWindow?.rootViewController else{
                return;
            }
            
            var viewController : UIViewController? = root.mostTopViewController;
            if let alert = root as? UIAlertController{
                viewController = alert.presentingViewController;
            }else if viewController?.isPopover ?? false{
                viewController = viewController?.presentingViewController;
            }
            
            let targetView = view ?? viewController?.view;
            targetView?.makeToast(msg, duration: duration, position: position, title: title);
            //UIApplication.shared.mostTopViewController?.view?.makeToast(<#T##message: String?##String?#>, duration: <#T##TimeInterval#>, position: <#T##ToastPosition#>, title: <#T##String?#>, image: <#T##UIImage?#>, style: <#T##ToastStyle#>, completion: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>);
            //UIApplication.shared.mostTopViewController?.view?.makeToast(<#T##message: String?##String?#>, duration: <#T##TimeInterval#>, point: <#T##CGPoint#> title: <#T##String?#>, image: <#T##UIImage?#>, style: <#T##ToastStyle#>, completion: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>)
            
        }
    }
    
    static func error(_ error : Error?, position: ToastPosition = ToastManager.shared.position){
        self.make(error?.localizedDescription ?? "", position: position);
    }
    
    static func assertOrToast(_ message : String){
        #if DEBUG
            //assertionFailure(message);
        #endif
        make(message);
    }
    
    static var activityWindow : UIWindow!;
    //static var remakeActivityWindow
    static func activity(_ message: String? = nil, dim: Bool = true, cancelation: SWActivityContainer.SWActivityCancelation? = nil){
        DispatchQueue.main.async {
            //UIApplication.shared.mostTopViewController
            //mostTopViewController?
            AppDelegate.sharedWindow?.rootViewController?.view.makeSiwonActivity(message: message, dim: dim, cancelation: cancelation);
            //.makeToastActivity(.center);
        }
    }
    
    static func hideActivity(_ force: Bool = false){
        DispatchQueue.main.async {
            //UIApplication.shared.mostTopViewController
            guard let root = AppDelegate.sharedWindow?.rootViewController else{
                return;
            }
            
            if let alert = root as? UIAlertController{
                alert.presentingViewController?.view.hideSiwonActivity();
            }else{
                root.view.hideSiwonActivity();
            }
            
            //.hideToastActivity();
        }
    }
}

extension UIView{
    private struct SiwonToastKeys{
        static var activity = "framework.siwonschool.com.toast.activity";
        static var activityReference = "framework.siwonschool.com.toast.activity.reference";
    }
    
    private var siwonActivity : SWActivityContainer?{
        get{
            return self.objcProperty(&SiwonToastKeys.activity) as? SWActivityContainer;
        }
        set(value){
            self.setObjcProperty(&SiwonToastKeys.activity, value: value, policy: .OBJC_ASSOCIATION_RETAIN);
        }
    }
    
    private var siwonActivityReference : Int{
        get{
            return self.objcProperty(&SiwonToastKeys.activityReference) as? Int ?? 0;
        }
        set(value){
            self.setObjcProperty(&SiwonToastKeys.activityReference, value: value, policy: .OBJC_ASSOCIATION_RETAIN);
        }
    }
    
    static let DefaultSiwonActivitySize = CGSize.init(width: 55, height: 55);
    static let DefaultSiwonActivityInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8);
    static let DefaultSiwonActivityBackgroundColor = UIColor.white //UIColor.init(r: 242, g: 242, b: 242);
    @discardableResult
    func makeSiwonActivity(message: String? = nil, size : CGSize = DefaultSiwonActivitySize, backgroundColor : UIColor = DefaultSiwonActivityBackgroundColor, insets: UIEdgeInsets = DefaultSiwonActivityInsets, block : Bool = true, full : Bool = true, dim: Bool = true, cancelation: SWActivityContainer.SWActivityCancelation?) -> UIView{
        guard self.siwonActivity == nil else {
            self.siwonActivityReference = self.siwonActivityReference.advanced(by: 1);
            self.siwonActivity?.message = message;
            return self.siwonActivity!;
        }
        
        //let inversedInsets = UIEdgeInsets(top: -insets.top, left: -insets.left, bottom: -insets.bottom, right: -insets.right);
        //let containerSize = UIEdgeInsetsInsetRect(CGRect.init(center: CGPoint.zero, size: size), inversedInsets).size;
        let activityContainer = SWActivityContainer.init(frame: frame, size: size, backgroundColor: backgroundColor, insets: insets, block: block, dim: dim, message: message, cancel: cancelation);
        activityContainer.autoresizingMask = [.flexibleWidth, .flexibleHeight];
        activityContainer.bounds = self.bounds;
        
        self.siwonActivity = activityContainer;
        
        if full, let window = AppDelegate.sharedWindow{
            //SWToast.activityWindow?.resignKey();
            //SWToast.activityWindow?.removeFromSuperview();
            //SWToast.activityWindow = UIWindow.init(frame: keyWindow.frame);
            //let window = SWToast.activityWindow!;
            //window.windowLevel = UIWindowLevelAlert + 1;
            
            window.addSubview(activityContainer);
            //window.bringSubview(toFront: activityContainer);
            //window.makeKeyAndVisible();
            
            activityContainer.translatesAutoresizingMaskIntoConstraints = false;
            activityContainer.leadingAnchor.constraint(equalTo: window.leadingAnchor).isActive = true;
            activityContainer.trailingAnchor.constraint(equalTo: window.trailingAnchor).isActive = true;
            activityContainer.topAnchor.constraint(equalTo: window.topAnchor).isActive = true;
            activityContainer.bottomAnchor.constraint(equalTo: window.bottomAnchor).isActive = true;
        }else{
            self.addSubview(activityContainer);
            self.isUserInteractionEnabled = !block;
        }
        
        self.siwonActivityReference = self.siwonActivityReference.advanced(by: 1);
        return self.siwonActivity!;
    }
    
    func hideSiwonActivity(_ force : Bool = false){
        
        self.siwonActivityReference = self.siwonActivityReference.advanced(by: -1);
        self.isUserInteractionEnabled = true;
        guard force || self.siwonActivityReference <= 0 else{
            
            return;
        }
        
        LSToast.activityWindow?.resignKey();
        LSToast.activityWindow?.removeFromSuperview();
        UIApplication.shared.windows.first?.makeKeyAndVisible();
        //self.isUserInteractionEnabled = true;
        self.siwonActivity?.superview?.isUserInteractionEnabled = true;
        self.siwonActivity?.removeFromSuperview();
        self.siwonActivity = nil;
        self.siwonActivityReference = 0;
    }
}

class SWActivityContainer : UIView{
    typealias SWActivityCancelation = (UIView) -> Void;
    
    var message: String?{
        get{
            return self.messageLabel?.text;
        }
        set(value){
            self.messageLabel?.text = value;
            self.messageLabel?.isHidden = (value ?? "").isEmpty;
        }
    }
    
    var activityFrame : UIView!;
    var tapGesture : UITapGestureRecognizer!;
    var cancelHandler : SWActivityCancelation?;
    var cancelButton : UIButton!;
    var messageLabel : LSLabel!;
    
    init(frame: CGRect, size : CGSize = DefaultSiwonActivitySize, backgroundColor : UIColor = DefaultSiwonActivityBackgroundColor, insets: UIEdgeInsets = DefaultSiwonActivityInsets, block : Bool = true, dim : Bool = true, message: String? = nil, cancel : SWActivityCancelation? = nil) {
        //let inversedInsets = UIEdgeInsets(top: -insets.top, left: -insets.left, bottom: -insets.bottom, right: -insets.right);
        //let containerSize = UIEdgeInsetsInsetRect(CGRect.init(center: CGPoint.zero, size: size), inversedInsets).size;
        self.activityFrame = SWActivityFrame.init(size: size, backgroundColor: backgroundColor, insets: insets);
        self.activityFrame.ignoresDarkMode = true;
        super.init(frame: frame);
        self.addSubview(self.activityFrame);
        self.activityFrame.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true;
        self.activityFrame.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true;
        
        if block{
            self.backgroundColor = dim ? UIColor.black.withAlphaComponent(0.3) : UIColor.clear;
            let message = message ?? "";
            self.messageLabel = LSLabel();
            self.messageLabel.topPadding = 4;
            self.messageLabel.bottomPadding = 4;
            self.messageLabel.leftPadding = 8;
            self.messageLabel.rightPadding = 8;
            self.messageLabel.cornerRadius = 8;
            self.messageLabel.textAlignment = .center;
            self.messageLabel.clipsToBounds = true;
            self.messageLabel.translatesAutoresizingMaskIntoConstraints = false;
            self.messageLabel.text = message;
            self.messageLabel.backgroundColor = UIColor.black;
            self.messageLabel.textColor = UIColor.white;
            self.messageLabel.numberOfLines = 0;
            self.addSubview(self.messageLabel);
            
            self.messageLabel.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 1, constant: -32).isActive = true;
            //self.messageLabel.widthAnchor.constraint(equalTo: self.widthAnchor, constant: -32).isActive = true;
            //self.cancelButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 16).isActive = true;
            //self.cancelButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16).isActive = true;
            self.messageLabel.centerXAnchor.constraint(equalTo: self.activityFrame.centerXAnchor).isActive = true;
            self.messageLabel.topAnchor.constraint(equalTo: self.activityFrame.bottomAnchor, constant: 16).isActive = true;
            self.messageLabel?.isHidden = message.isEmpty;
            
            if let cancel = cancel{
                self.cancelHandler = cancel;
                //self.tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.onTap(_:)));
                //self.addGestureRecognizer(self.tapGesture);
                //self.isUserInteractionEnabled = true;
                self.cancelButton = UIButton.init(frame: CGRect.init(origin: CGPoint.zero, size: CGSize.init(width: 44, height: 44)));
                self.cancelButton.addTarget(self, action: #selector(self.onCancel(_:)), for: .touchUpInside);
                self.cancelButton.translatesAutoresizingMaskIntoConstraints = false;
                self.cancelButton.setImage(UIImage.init(named: "btnClose"), for: .normal);
                self.cancelButton.cornerRadius = 22;
                self.cancelButton.backgroundColor = .blue;
                self.cancelButton.setTitleColor(UIColor.white, for: .normal);
                self.cancelButton.tintColor = UIColor.white;
                self.addSubview(self.cancelButton);
                
                self.cancelButton.heightAnchor.constraint(equalToConstant: 44).isActive = true;
                self.cancelButton.widthAnchor.constraint(equalToConstant: 44).isActive = true;
                //self.cancelButton.topAnchor.constraint(equalTo: self.topAnchor, constant: 16).isActive = true;
                //self.cancelButton.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16).isActive = true;
                self.cancelButton.centerXAnchor.constraint(equalTo: self.activityFrame.centerXAnchor).isActive = true;
                if let _ = self.messageLabel{
                    self.cancelButton.topAnchor.constraint(equalTo: self.messageLabel.bottomAnchor, constant: 16).isActive = true;
                }else{
                    self.cancelButton.topAnchor.constraint(equalTo: self.activityFrame.bottomAnchor, constant: 16).isActive = true;
                }
                
            }
        }
        //self.isUserInteractionEnabled = !block;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func onTap(_ gesture : UITapGestureRecognizer){
        self.cancelHandler?(self);
        //self.isUserInteractionEnabled = false;
    }
    
    @IBAction func onCancel(_ button : UIButton){
        self.cancelHandler?(self);
    }
}


class SWActivityFrame : UIView{
    //static let DefaultSiwonActivityInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8);
    
    init(size: CGSize, backgroundColor : UIColor = DefaultSiwonActivityBackgroundColor, insets: UIEdgeInsets = DefaultSiwonActivityInsets) {
        let inversedInsets = UIEdgeInsets(top: -insets.top, left: -insets.left, bottom: -insets.bottom, right: -insets.right);
        let containerSize = CGRect.init(center: CGPoint.zero, size: size).inset(by: inversedInsets).size;
        
        super.init(frame: CGRect.init(origin: CGPoint.zero, size: containerSize));
        
        self.widthAnchor.constraint(equalToConstant: containerSize.width).isActive = true;
        self.heightAnchor.constraint(equalToConstant: containerSize.height).isActive = true;
        
        self.translatesAutoresizingMaskIntoConstraints = false;
        self.backgroundColor = backgroundColor;
        self.layer.cornerRadius = containerSize.width / 2;
        
        // Activity Shadow
        self.layer.shadowColor = #colorLiteral(red: 0.5179998875, green: 0.5180125833, blue: 0.5180057287, alpha: 1)
        self.layer.shadowOffset = CGSize(width: 0, height: 1)
        self.layer.shadowOpacity = 0.5
        self.layer.shadowRadius = 5
        //activityContainer.layer.shadowColor = style.shadowColor.cgColor
        //activityContainer.layer.shadowOpacity = style.shadowOpacity
        //activityContainer.layer.shadowRadius = style.shadowRadius
        //activityContainer.layer.shadowOffset = style.shadowOffset
        
        //create activity
        let activity = SWActivityView.init(frame: CGRect.init(origin: CGPoint.zero, size: size));
        
        self.addSubview(activity);
        
        activity.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: insets.left).isActive = true;
        activity.topAnchor.constraint(equalTo: self.topAnchor, constant: insets.top).isActive = true;
        activity.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -insets.right).isActive = true;
        activity.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -insets.bottom).isActive = true;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SWActivityView : UIImageView{
    static var animationImages : [UIImage] = try! UIImage(gifName: "siwonloading").images ?? [];
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.backgroundColor = UIColor.clear;
        self.animationImages = type(of: self).animationImages;
        
        //activity.loadGif(name: "siwonloading");
        self.animationDuration = 0.5;
        self.startAnimating();
        self.contentMode = .scaleAspectFit;
        self.translatesAutoresizingMaskIntoConstraints = false;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func stop(){
        self.stopAnimating();
    }
    
    func start(){
        self.startAnimating();
    }
}
