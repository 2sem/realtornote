//
//  GADNativeTableViewCell.swift
//  realtornote
//
//  Created by 영준 이 on 2020/07/26.
//  Copyright © 2020 leesam. All rights reserved.
//

import UIKit
import GoogleMobileAds

class GADNativeTableViewCell: UITableViewCell {
    #if DEBUG
    let gadUnit : String = "ca-app-pub-3940256099942544/3986624511";
    #else
    let gadUnit : String = "ca-app-pub-9684378399371172/5214599479";
    #endif
    
    weak var rootViewController : UIViewController?;
    var gadLoader : AdLoader?;
    var tapGesture : UITapGestureRecognizer!;
    
    @IBOutlet weak var nativeAdView: NativeAdView!
    @IBOutlet weak var mediaView: MediaView!
    var mediaViewRatioConstraint: NSLayoutConstraint?
    @IBOutlet var mediaViewLeadingConstraints: [NSLayoutConstraint]!
    
    @IBOutlet weak var defaultImageView: UIImageView!
    @IBOutlet var imageViewLeadingConstraints: [NSLayoutConstraint]!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        self.loadDeveloper();
        self.tapGesture = UITapGestureRecognizer.init(target: self, action: #selector(self.openAds(_:)));
        self.nativeAdView.addGestureRecognizer(self.tapGesture);
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func loadAds(){
        self.gadLoader = AdLoader(adUnitID: self.gadUnit,
                                     rootViewController: self.rootViewController,
                                     adTypes: [ .native ],
                                     options: []);
        self.gadLoader?.delegate = self;
        
        let req = Request();
        
        // remove 'test'
        let extras = Extras();
        extras.additionalParameters = ["suppress_test_label" : "1"]
        req.register(extras)
        
        self.gadLoader?.load(req);
    }
    
    func loadDeveloper(){
        if let header = self.nativeAdView?.headlineView as? UILabel{
            header.text = "관련주식검색기".localized();
            header.isHidden = false;
        }
        if let body = self.nativeAdView?.bodyView as? UILabel{
            body.text = "15년 주식 경력의 개발자가 직접 운영 ".localized();
            body.isHidden = false;
        }
        if let advertiser = self.nativeAdView?.advertiserView as? UILabel{
            //advertiser.text = "개발자".localized();
            advertiser.isHidden = true;
        }
        //self.nativeAdView?.starRatingView?.isHidden = true;// nativeAd.starRating == nil;
        if let button = self.nativeAdView?.callToActionView as? UIButton{
            button.setTitle("ads action".localized(), for: .normal);
            button.isHidden = false;
        }
        if let imageView = self.defaultImageView{
            imageView.image = #imageLiteral(resourceName: "othreapp");
            self.defaultImageView.isHidden = false
            self.mediaView.isHidden = true
            
            NSLayoutConstraint.deactivate(self.mediaViewLeadingConstraints)
            NSLayoutConstraint.activate(self.imageViewLeadingConstraints)
        }
        self.nativeAdView?.iconView?.isHidden = false;
        
        self.nativeAdView?.isUserInteractionEnabled = false;
        //self.nativeAdView.isHidden = true;
    }
    
    @objc func openAds(_ gesture : UITapGestureRecognizer){
        guard let url = URL.init(string: "https://apps.apple.com/us/developer/young-jun-lee/id1225480114") else{
            return;
        }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil);
       //UIApplication.shared.open(url, options: [ : false], completionHandler: nil);
    }
}

extension GADNativeTableViewCell : NativeAdLoaderDelegate
{
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        print("\(#function)");
        self.nativeAdView?.nativeAd = nativeAd;
        
        if let header = nativeAdView.headlineView as? UILabel{
            header.text = nativeAd.headline;
        }
        self.nativeAdView?.advertiserView?.isHidden = nativeAd.advertiser == nil;
        //self.nativeAdView?.starRatingView?.isHidden = true;// nativeAd.starRating == nil;
        if let button = nativeAdView.callToActionView as? UIButton{
            button.setTitle(nativeAd.callToAction, for: .normal);
        }
        self.nativeAdView?.callToActionView?.isHidden = nativeAd.callToAction == nil;
        
        if let iconView = nativeAdView.iconView as? UIImageView, let icon = nativeAd.icon?.image{
            iconView.image = icon;
            print("[\(#function)] icon[\(icon)]")
            iconView.isHidden = false;
        }
        
        if let mediaView = self.mediaView{
            mediaView.mediaContent = nativeAd.mediaContent
            mediaView.widthAnchor.constraint(equalTo: mediaView.heightAnchor, multiplier: nativeAd.mediaContent.aspectRatio).isActive = true
            mediaView.isHidden = false;
            
            
            self.defaultImageView.isHidden = true;
            NSLayoutConstraint.deactivate(self.imageViewLeadingConstraints)
            NSLayoutConstraint.activate(self.mediaViewLeadingConstraints)
        }
        
        if let body = nativeAdView.bodyView as? UILabel{
            body.text = nativeAd.body;
        }
        self.nativeAdView.bodyView?.isHidden = nativeAd.body == nil;
        self.nativeAdView?.isUserInteractionEnabled = true;
        
        self.tapGesture.isEnabled = false;
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("\(#function) \(error)");
        self.loadDeveloper();
        self.tapGesture.isEnabled = true;
    }
}
