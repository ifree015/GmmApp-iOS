//
//  MainTabViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/07/19.
//

import Foundation
import UIKit

class MainTabBarController: UITabBarController, InitialViewController {
    var initialViewController = false
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        debug("traitCollectionDidChange")
        
        if !Theme.shared.isManualMode() && traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            debug("hasDifferentColorAppearance")
            if let navigationController = self.selectedViewController as? TabNavigationController, let webViewController = navigationController.topViewController as? WebViewController {
                webViewController.view.backgroundColor = Theme.shared.getBackgroundColor(self)
                webViewController.setThemeViewController(viewController: self, themeMode: Theme.shared.getThemeMode())
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        debug("viewDidLoad")
        
        // 1. init app
        GmmApplication.shared.initialize(self)
        
        // 2. animation
        self.delegate = self
        
        // 3. init tabBar Controller
        if (initialViewController) {
            self.tabBar.isHidden = true
        }
        self.selectedIndex = 1
        //        GmmApplication.shared.gggghgtqsendNotification(title: "test", body: "test")
    }
}

// reference: https://gist.github.com/dsoike/caa34a2605306f28c3061efc4920ba13
extension MainTabBarController: UITabBarControllerDelegate {
    
    //    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
    //        debug("\(tabBarController.selectedIndex)")
    //    }
    
    func tabBarController(_ tabBarController: UITabBarController, animationControllerForTransitionFrom fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideTransition(viewControllers: tabBarController.viewControllers)
    }
}

class SlideTransition: NSObject, UIViewControllerAnimatedTransitioning {
    
    let viewControllers: [UIViewController]?
    let transitionDuration: Double = 0.2
    
    init(viewControllers: [UIViewController]?) {
        self.viewControllers = viewControllers
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return TimeInterval(transitionDuration)
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from),
            let fromView = fromVC.view,
            let fromIndex = getIndex(forViewController: fromVC),
            let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to),
            let toView = toVC.view,
            let toIndex = getIndex(forViewController: toVC)
        else {
            transitionContext.completeTransition(false)
            return
        }
        
        let frame = transitionContext.initialFrame(for: fromVC)
        var fromFrameEnd = frame
        var toFrameStart = frame
        fromFrameEnd.origin.x = toIndex > fromIndex ? frame.origin.x - frame.width : frame.origin.x + frame.width
        toFrameStart.origin.x = toIndex > fromIndex ? frame.origin.x + frame.width : frame.origin.x - frame.width
        toView.frame = toFrameStart
        
        DispatchQueue.main.async {
            transitionContext.containerView.addSubview(toView)
            UIView.animate(withDuration: self.transitionDuration, animations: {
                fromView.frame = fromFrameEnd
                toView.frame = frame
            }, completion: {success in
                fromView.removeFromSuperview()
                transitionContext.completeTransition(success)
            })
        }
    }
    
    func getIndex(forViewController vc: UIViewController) -> Int? {
        guard let vcs = self.viewControllers else { return nil }
        for (index, thisVC) in vcs.enumerated() {
            if thisVC == vc { return index }
        }
        return nil
    }
}       
