//
//  PushViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/08/02.
//

import Foundation
import UIKit
import WebKit
import SnapKit

class ModalViewController: WebViewController {
    var location: String!
    var viewInfo: Dictionary<String, Any> = [:]
    
    var navigationBar: UINavigationBar!
    var navItem: UINavigationItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init view controller
        initViewController()
        
        // 2. init web view
        //        configShared = false
        initWebView()
//        self.webView.scrollView.delegate = self
        
        // 3. webpage loading
        let encodedLocation = location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: AppEnvironment.mainPageURL.absoluteString + encodedLocation)
        urlReqeust = URLRequest(url: url!)
        //        setAuthTokens { [weak self] in
        self.webView.load(urlReqeust)
        //        }
        
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
        }
        
        setNavigationItem()
    }
    
    func setNavigationItem() {
        let navItem = UINavigationItem(title: "")
        
        if let title = viewInfo["title"] as? String, title.count > 0  {
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.textColor = Theme.shared.getNaviBarTintColor(self)
            navItem.leftBarButtonItem = UIBarButtonItem.init(customView: titleLabel)
        }
        
        navItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(goBack))
        
        self.navItem = navItem
        navigationBar.setItems([navItem], animated: false)
    }
    
    func setViewInfo(_ viewInfo: [String : Any]) {
        let condition: ((String, Any)) -> Bool = {
            if $0.0 == "title", let value = $0.1 as? String, value.count > 0 {
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
        if viewInfo["barHidden"] as? Bool ?? false && !self.navigationBar.isHidden {
            self.navigationBar.isHidden = true
            navigationBar.snp.makeConstraints {make in
                make.height.equalTo(0)
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        //        self.navigationController?.isNavigationBarHidden = true
        //        self.navigationController?.hidesBarsOnSwipe = false
    }
}

extension ModalViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        //        debug("\(scrollView.contentOffset)")
        //        if viewInfo["barSwipable"] as? Bool ?? false, scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0 {
        //            if self.navigationController?.isNavigationBarHidden ?? false {
        //                self.navigationController?.setNavigationBarHidden(false, animated: true)
        //            }
        //        }

        if scrollView.contentOffset.y > 0 {
            self.navigationBar.standardAppearance.backgroundColor = Theme.shared.getNaviBarTintBackgroundColor(self)
        } else {
            self.navigationBar.standardAppearance.backgroundColor = Theme.shared.getNaviBarBackgroundColor(self)
        }
    }
}
