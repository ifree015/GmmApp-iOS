//
//  AlertViewController.swift
//  GmmApp
//
//  Created by GwangHyeok Yu on 2023/09/21.
//

import Foundation
import UIKit

/**
 * reference: https://ios-development.tistory.com/244
 *
 * <code>
 * showPopup(title: "App Update 알림", message: "새 버전(1.0.2)의 App을 설치하시겠습니까?", rightActionTitle: "설치")
 * </code>
 */
class PopupViewController: UIViewController {
    private var titleIcon: String?
    private var titleText: String?
    private var messageText: String?
    private var attributedMessageText: NSAttributedString?
    
    private var titleStackView: UIStackView?
    private var messageStackView: UIStackView?
    private var contentView: UIView?
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.shared.getBackgroundColor2()
        //        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        
        /// 팝업이 등장할 때(viewWillAppear)에서 containerView.transform = .identity로 하여 애니메이션 효과 주는 용도
        //view.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        
        return view
    }()
    
    private lazy var containerStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 12.0
        view.alignment = .center
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        //view.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMinXMinYCorner, .layerMaxXMinYCorner)
        //view.backgroundColor = Theme.shared.getBackgroundColor2(self)
        
        return view
    }()
    
    private lazy var buttonStackView: UIStackView = {
        let view = UIStackView()
        if contentView == nil {
            view.isLayoutMarginsRelativeArrangement = true
            view.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
            view.spacing = 12.0
        } else {
            view.spacing = 14.0
        }
        view.distribution = .fillEqually
        
        return view
    }()
    
    func setTitleStackView() {
        guard let titleText = titleText else { return }
        
        let view = UIStackView()
        view.isLayoutMarginsRelativeArrangement = true
        view.layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        view.backgroundColor = Theme.shared.getBackgroundColor(color: titleIcon ?? "secondary")
        view.distribution = .fill
        view.alignment = .leading
        
        let label = UILabel()
        if let titleIcon = titleIcon {
            let iconName: String
            switch titleIcon {
            case "error":
                iconName = "exclamationmark.circle"
            case "success":
                iconName = "checkmark.circle"
            case "warning":
                iconName = "exclamationmark.triangle"
            case "info", "secondary":
                iconName = "info.circle"
            default:
                iconName = titleIcon
            }
            let attachment = NSTextAttachment()
            attachment.image = UIImage(systemName: iconName)?.withTintColor(Theme.shared.getTextColor(), renderingMode: .alwaysOriginal)
            attachment.bounds = .init(x: 0, y: -6, width: 22, height: 22)
            let attributedString = NSMutableAttributedString(attributedString: NSAttributedString(attachment: attachment))
            attributedString.append(NSAttributedString(string: "  " + titleText))
            label.attributedText = attributedString
        } else {
            label.text = titleText
        }
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18.0)
        label.numberOfLines = 0
        label.textColor = Theme.shared.getTextColor()
        
        view.addArrangedSubview(label)
        titleStackView = view
    }
    
    func setMessageStackView(){
        guard messageText != nil || attributedMessageText != nil else {
            return
        }
        
        let view = UIStackView()
        view.isLayoutMarginsRelativeArrangement = true
        if titleText == nil {
            view.layoutMargins = UIEdgeInsets(top: 24, left: 12, bottom: 6, right: 12)
        } else {
            view.layoutMargins = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        }
        view.alignment = .leading
        let label = UILabel()
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 16.0)
        label.textColor = .gray
        label.numberOfLines = 0
        
        if let attributedMessageText = attributedMessageText {
            label.attributedText = attributedMessageText
        } else {
            label.text = messageText
        }
        
        view.addArrangedSubview(label)
        messageStackView = view
    }
    
    public func addActionToButton(title: String? = nil,
                                  titleColor: UIColor = .white,
                                  backgroundColor: UIColor = .systemBlue,
                                  completion: (() -> Void)? = nil) {
        var configuration = UIButton.Configuration.filled()
        var titleAttribute = AttributedString.init(title ?? "")
        titleAttribute.font = .systemFont(ofSize: 16.0, weight: .bold)
        configuration.attributedTitle = titleAttribute
        configuration.baseForegroundColor = titleColor
        configuration.baseBackgroundColor = backgroundColor
        
        let button = UIButton(configuration: configuration, primaryAction: UIAction { _ in
            self.dismiss(animated: false, completion: completion)
        })
        
        buttonStackView.addArrangedSubview(button)
    }
    
    public func addActionButton(_ button: UIButton, completion: (() -> Void)? = nil) {
        button.addAction(UIAction { _ in
            self.dismiss(animated: false, completion: completion)
        }, for: .touchUpInside)
        
        buttonStackView.addArrangedSubview(button)
    }
    
    convenience init(titleIcon: String? = nil, titleText: String? = nil,
                     messageText: String? = nil,
                     attributedMessageText: NSAttributedString? = nil) {
        self.init()
        
        self.titleIcon = titleIcon
        self.titleText = titleText
        self.messageText = messageText
        self.attributedMessageText = attributedMessageText
        /// present 시 fullScreen (화면을 덮도록 설정) -> 설정 안하면 pageSheet 형태 (위가 좀 남아서 밑에 깔린 뷰가 보이는 형태)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    convenience init(contentView: UIView) {
        self.init()
        
        self.containerView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        self.contentView = contentView
        modalPresentationStyle = .overFullScreen
        //        modalTransitionStyle = .coverVertical
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // curveEaseOut: 시작은 천천히, 끝날 땐 빠르게
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseOut) { [weak self] in
            self?.containerView.transform = .identity
            self?.containerView.isHidden = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // curveEaseIn: 시작은 빠르게, 끝날 땐 천천히
        UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseIn) { [weak self] in
//            self?.containerView.transform = .identity
            self?.containerView.isHidden = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        addSubviews()
        makeConstraints()
    }
    
    private func setupViews() {
        view.addSubview(containerView)
        containerView.addSubview(containerStackView)
        view.backgroundColor = .black.withAlphaComponent(0.2)
    }
    
    private func addSubviews() {
        view.addSubview(containerStackView)
        
        if let contentView = contentView {
            containerStackView.addArrangedSubview(contentView)
        } else {
            setTitleStackView()
            if let titleStackView = titleStackView {
                containerStackView.addArrangedSubview(titleStackView)
            }
            setMessageStackView()
            if let messageStackView = messageStackView {
                containerStackView.addArrangedSubview(messageStackView)
            }
        }
        
        containerStackView.addArrangedSubview(buttonStackView)
    }
    
    private func makeConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerStackView.translatesAutoresizingMaskIntoConstraints = false
        buttonStackView.translatesAutoresizingMaskIntoConstraints = false
        
        if contentView != nil {
            NSLayoutConstraint.activate([
                containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 26),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -26),
                containerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 32),
                containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -32),
                
                containerStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 24),
                containerStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 24),
                containerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),
                containerStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -24),
                
                buttonStackView.heightAnchor.constraint(equalToConstant: 48),
                buttonStackView.widthAnchor.constraint(equalTo: containerStackView.widthAnchor)
            ])
        } else {
            NSLayoutConstraint.activate([
                containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
                containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
                containerView.topAnchor.constraint(greaterThanOrEqualTo: view.topAnchor, constant: 32),
                containerView.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -32),
                
                containerStackView.topAnchor.constraint(equalTo: containerView.topAnchor),
                containerStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                containerStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                containerStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                
                buttonStackView.heightAnchor.constraint(equalToConstant: 60),
                buttonStackView.widthAnchor.constraint(equalTo: containerStackView.widthAnchor)
            ])
            
            titleStackView?.leadingAnchor.constraint(equalTo: containerStackView.leadingAnchor).isActive = true
            titleStackView?.trailingAnchor.constraint(equalTo: containerStackView.trailingAnchor).isActive = true
            messageStackView?.widthAnchor.constraint(equalTo: containerStackView.widthAnchor).isActive = true
        }
    }
}

extension UIViewController {
    func showPopup(icon: String? = nil,
                   title: String? = nil,
                   message: String? = nil,
                   attributedMessage: NSAttributedString? = nil,
                   leftActionTitle: String? = nil,
                   rightActionTitle: String = "확인",
                   leftActionCompletion: (() -> Void)? = nil,
                   rightActionCompletion: (() -> Void)? = nil) {
        let popupViewController = PopupViewController(titleIcon: icon, titleText: title,
                                                      messageText: message,
                                                      attributedMessageText: attributedMessage)
        if let leftActionTitle = leftActionTitle {
            popupViewController.addActionToButton(title: leftActionTitle, titleColor: Theme.shared.getTextColor(), backgroundColor: Theme.shared.getPrimaryBackgroundColor()
                                                  , completion: leftActionCompletion)
        }
        popupViewController.addActionToButton(title: rightActionTitle, titleColor: Theme.shared.getTextColor(), backgroundColor: Theme.shared.getPrimaryBackgroundColor()
                                              , completion: rightActionCompletion)
        
        present(popupViewController, animated: true, completion: nil)
    }
    
    func showPopup(icon: String? = nil,
                   title: String? = nil,
                   message: String? = nil,
                   attributedMessage: NSAttributedString? = nil,
                   leftActionButton: UIButton? = nil,
                   rightActionButton: UIButton,
                   leftActionCompletion: (() -> Void)? = nil,
                   rightActionCompletion: (() -> Void)? = nil) {
        let popupViewController = PopupViewController(titleIcon: icon, titleText: title,
                                                      messageText: message,
                                                      attributedMessageText: attributedMessage)
        if let leftActionButton = leftActionButton {
            popupViewController.addActionButton(leftActionButton, completion: leftActionCompletion)
        }
        popupViewController.addActionButton(rightActionButton, completion: rightActionCompletion)
        
        present(popupViewController, animated: true, completion: nil)
    }
    
    func showPopup(contentView: UIView, leftActionButton: UIButton? = nil, rightActionButton: UIButton, leftActionCompletion: (() -> Void)? = nil,
                   rightActionCompletion: (() -> Void)? = nil) {
        let popupViewController = PopupViewController(contentView: contentView)
        
        if let leftActionButton = leftActionButton {
            popupViewController.addActionButton(leftActionButton, completion: leftActionCompletion)
        }
        popupViewController.addActionButton(rightActionButton, completion: rightActionCompletion)
        
        present(popupViewController, animated: false, completion: nil)
    }
    
    func alertPopup(title: String? = nil, message: String? = nil, attributedMessage: NSAttributedString? = nil, actionTitle: String = "확인") {
        let backgroundColor: UIColor
        if title != nil {
            backgroundColor = Theme.shared.getPrimaryBackgroundColor()
        } else {
            backgroundColor = Theme.shared.getSecondaryBackgroundColor()
        }
        let popupViewController = PopupViewController(titleIcon: "error", titleText: title, messageText: message, attributedMessageText: attributedMessage)
        popupViewController.addActionToButton(title: actionTitle, titleColor: Theme.shared.getTextColor(), backgroundColor: backgroundColor)
        
        present(popupViewController, animated: true, completion: nil)
    }
    
    func informPopup(title: String, message: String? = nil, attributedMessage: NSAttributedString? = nil, leftActionTitle: String? = nil,
                     rightActionTitle: String = "확인", rightActionCompletion: (() -> Void)? = nil) {
        let popupViewController = PopupViewController(titleIcon: "info", titleText: title, messageText: message, attributedMessageText: attributedMessage)
        
        if let leftActionTitle = leftActionTitle {
            popupViewController.addActionToButton(title: leftActionTitle, titleColor: Theme.shared.getTextColor(), backgroundColor: Theme.shared.getSecondaryBackgroundColor())
        }
        popupViewController.addActionToButton(title: rightActionTitle, titleColor: Theme.shared.getTextColor(), backgroundColor: Theme.shared.getSecondaryBackgroundColor(), completion: rightActionCompletion)
        
        present(popupViewController, animated: true, completion: nil)
    }
    
    func confirmPopup(title: String, message: String? = nil, attributedMessage: NSAttributedString? = nil, leftActionTitle: String = "취소",
                      rightActionTitle: String = "확인", rightActionCompletion: (() -> Void)? = nil) {
        let popupViewController = PopupViewController(titleIcon: "secondary", titleText: title, messageText: message, attributedMessageText: attributedMessage)
        
        popupViewController.addActionToButton(title: leftActionTitle, titleColor: Theme.shared.getTextColor(), backgroundColor: Theme.shared.getPrimaryBackgroundColor())
        popupViewController.addActionToButton(title: rightActionTitle, titleColor: Theme.shared.getTextColor(), backgroundColor: Theme.shared.getPrimaryBackgroundColor(), completion: rightActionCompletion)
        
        present(popupViewController, animated: true, completion: nil)
    }
}
