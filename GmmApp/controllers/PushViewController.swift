//
//  PushViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/08/02.
//

import Foundation
import UIKit
import SnapKit

class PushViewController: WebViewController {
    var location: String!
    var viewInfo: Dictionary<String, Any> = [:]
    
    let NAVIGATION_BAR_HEIGHT: CGFloat = 48.0
    var navigationBar: UINavigationBar!
    var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init view controller
        initViewController()
        
        // 2. init web view
        initWebView()
        
        // 3. webpage loading
        let url = URL(string: AppEnvironment.mainPageURL.absoluteString + location)
        let urlReqeust = URLRequest(url: url!)
        self.webView.load(urlReqeust)
        self.webView.scrollView.delegate = self
        
        // 4. style
        changeUserInterfaceStyle()
        
        // 5. activity indicator
        //        startActivityIndicator()
    }
    
    func initViewController() {
        
        //        self.navigationController?.isNavigationBarHidden = false
        //        self.navigationBar = self.navigationController?.navigationBar
        
        self.navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(navigationBar)
        
        changeNavigationBarAppearance(navigationBar)
        //        navigationBar.isTranslucent = false
        
        navigationBar.snp.makeConstraints { make in
            //$0.top.equalTo(self.view.safeAreaLayoutGuide)
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(navigationBar.snp.top).offset(NAVIGATION_BAR_HEIGHT)
        }
        
        setNavigationItem()
    }
    
    func setNavigationItem() {
        self.navItem = UINavigationItem(title: "")
        
        var isSubTitled = false
        if let title = viewInfo["title"] as? String, title.count > 0  {
            if let subTitle = viewInfo["subTitle"] as? String, subTitle.count > 0 {
                navigationBar.standardAppearance.titlePositionAdjustment = UIOffset(horizontal:0, vertical: 0)
                isSubTitled = true
                let titleView = UIView()
                titleView.clipsToBounds = true
                
                let titleLabel = UILabel()
                titleLabel.text = title
                titleLabel.textAlignment = .center
                titleLabel.textColor = Theme.shared.getNaviBarTintColor(self)
                titleLabel.font = UIFont.systemFont(ofSize: CGFloat(20))
                titleView.addSubview(titleLabel)
                titleLabel.translatesAutoresizingMaskIntoConstraints = false
                titleLabel.snp.makeConstraints { make in
                    //$0.top.equalTo(self.view.safeAreaLayoutGuide)
                    make.top.equalToSuperview().offset((NAVIGATION_BAR_HEIGHT - 24) / 2)
                    make.leading.trailing.equalToSuperview()
                }
                //                titleLabel.alpha = 0
                //                UIView.animate(withDuration: 1, animations: {
                //                    titleLabel.alpha = 1
                //                })
                
                let subTitleLabel = UILabel()
                subTitleLabel.text = subTitle
                subTitleLabel.textAlignment = .center
                subTitleLabel.textColor = Theme.shared.getSubTitleColor(self)
                subTitleLabel.font = UIFont.boldSystemFont(ofSize: CGFloat(16))
                titleView.addSubview(subTitleLabel)
                subTitleLabel.translatesAutoresizingMaskIntoConstraints = false
                subTitleLabel.snp.makeConstraints { make in
                    //$0.top.equalTo(self.view.safeAreaLayoutGuide)
                    make.top.equalTo(titleLabel.snp.bottom).offset(NAVIGATION_BAR_HEIGHT - 20)
                    make.leading.trailing.equalToSuperview()
                }
                
                navItem.titleView = titleView
            } else {
                navigationBar.standardAppearance.titlePositionAdjustment = UIOffset(horizontal:0, vertical: (NAVIGATION_BAR_HEIGHT - (self.navigationController?.navigationBar.frame.size.height ?? 44)) / 2)
                navItem.title = title
            }
        }
        
        navItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(goBack))
        //        var config = UIButton.Configuration.plain()
        //        config.contentInsets = NSDirectionalEdgeInsets(top: NAVIGATION_BAR_HEIGHT - (self.navigationController?.navigationBar.frame.size.height ?? 44), leading: 0, bottom: 0, trailing: 0)
        //        config.imagePlacement = .leading
        //        config.image = UIImage(systemName: "chevron.backward")
        //        config.attributedTitle = AttributedString.init("    ")
        //        let button = UIButton(configuration: config)
        //                button.layer.borderColor = UIColor.red.cgColor
        //                button.layer.borderWidth = 1
        //        button.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        //        navItem.leftBarButtonItem = UIBarButtonItem(customView: button)
        
        navigationBar.setItems([navItem], animated: !isSubTitled)
    }
    
    func setViewInfo(_ viewInfo: [String : Any]) {
        let condition: ((String, Any)) -> Bool = {
            if ($0.0 == "title" || $0.0 == "subTitle"), let value = $0.1 as? String, value.count > 0 {
                return true
            }
            return false
        }
        let viewInfo1 = self.viewInfo.filter(condition) as! [String: String]
        let viewInfo2 = viewInfo.filter(condition) as! [String: String]
        if viewInfo1 == viewInfo2 {
            return
        }
        debug("viewInfo: \(viewInfo2)")
        
        self.viewInfo = viewInfo
        setNavigationItem()
    }
    
    override func initWebView() {
        super.initWebView()
        
        webView.snp.remakeConstraints{ make in
            make.top.equalTo(self.navigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        //        self.navigationController?.isNavigationBarHidden = false
        let barHidden = viewInfo["barHidden"] as? Bool ?? false
        if barHidden {
            self.navigationBar.isHidden = barHidden
            navigationBar.snp.updateConstraints {make in
                make.bottom.equalTo(navigationBar.snp.top).offset(0)
            }
        } else {
            self.navigationBar.isHidden = false
        }
        
        //        if let barSwipable = viewInfo["barSwipable"] as? Bool {
        //            self.navigationController?.hidesBarsOnSwipe = barSwipable
        //        } else {
        //            self.navigationController?.hidesBarsOnSwipe = false
        //        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //        self.navigationController?.isNavigationBarHidden = true
        //        self.navigationController?.hidesBarsOnSwipe = false
    }
}

extension PushViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        debug("\(scrollView.contentOffset)")
        //        if viewInfo["barSwipable"] as? Bool ?? false, scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0 {
        //            if self.navigationController?.isNavigationBarHidden ?? false {
        //                self.navigationController?.setNavigationBarHidden(false, animated: true)
        //            }
        //        }
        
        if let subTitle = viewInfo["subTitle"] as? String, subTitle.count > 0 {
            if scrollView.contentOffset.y > 0 {
                if scrollView.contentOffset.y < (NAVIGATION_BAR_HEIGHT - 8) {
                    self.navItem.titleView?.bounds.origin = .init(x: 0, y: scrollView.contentOffset.y)
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                        self.navItem.titleView?.bounds.origin = .init(x: 0, y: self.NAVIGATION_BAR_HEIGHT)
                    })
                    self.view.layoutIfNeeded()
                }
            } else {
                self.navItem.titleView?.bounds.origin = .init(x: 0, y: 0)
            }
        }
        
        if viewInfo["barSwipable"] as? Bool ?? false {
            if scrollView.contentOffset.y > 0 {
                navigationBar.snp.updateConstraints{ make in
                    if scrollView.contentOffset.y < (NAVIGATION_BAR_HEIGHT - 8) {
                        make.bottom.equalTo(navigationBar.snp.top).offset(NAVIGATION_BAR_HEIGHT - scrollView.contentOffset.y)
                    } else {
                        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
                            make.bottom.equalTo(self.navigationBar.snp.top).offset(-self.NAVIGATION_BAR_HEIGHT)
                        })
                        self.view.layoutIfNeeded()
                    }
                }
            } else {
                navigationBar.snp.updateConstraints{ make in
                    make.bottom.equalTo(navigationBar.snp.top).offset(NAVIGATION_BAR_HEIGHT)
                }
            }
        }
    }
}
