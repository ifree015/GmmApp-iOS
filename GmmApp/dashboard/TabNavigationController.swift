//
//  NavigationController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/22.
//

import Foundation
import UIKit

/// reference: https://yungsoyu.medium.com/swift-pop-gesture-swipe-back-gesture-%EB%A1%9C-%EB%92%A4%EB%A1%9C%EA%B0%80%EA%B8%B0-%EA%B5%AC%ED%98%84%ED%95%98%EA%B8%B0-7cb2d8f9e814
class TabNavigationController: UINavigationController {
    
    private var duringTransition = false
    private var disabledPopVCs: [UIViewController.Type] = []
    
    override var childForStatusBarStyle: UIViewController? {
        return self.topViewController
    }
    
    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        
        interactivePopGestureRecognizer?.isEnabled = true
        interactivePopGestureRecognizer?.delegate = self
        self.delegate = self
        //self.navigationBar.isHidden = true
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        duringTransition = true
        
        super.pushViewController(viewController, animated: animated)
    }
}

extension TabNavigationController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        self.duringTransition = false
    }
}

extension TabNavigationController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        debug("gestureRecognizerShouldBegin: \(self.viewControllers.count)")
        guard gestureRecognizer == interactivePopGestureRecognizer,
              let topVC = topViewController else {
            return true // default value
        }
        
        return viewControllers.count > 1 && duringTransition == false && isPopGestureEnable(topVC)
    }
    
    private func isPopGestureEnable(_ topVC: UIViewController) -> Bool {
        for vc in disabledPopVCs {
            if String(describing: type(of: topVC)) == String(describing: vc) {
                return false
            }
        }
        return true
    }
}
