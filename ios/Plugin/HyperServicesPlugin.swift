/*
 * Copyright (c) Juspay Technologies.
 *
 * This source code is licensed under the AGPL 3.0 license found in the
 * LICENSE file in the root directory of this source tree.
 */

import Foundation
import Capacitor
import HyperSDK

@objc(HyperServicesPlugin)
public class HyperServicesPlugin: CAPPlugin {

    public let identifier = "HyperServicesPlugin"
    public let jsName = "HyperServices"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "createHyperServices", returnType: CAPPluginReturnNone),
        CAPPluginMethod(name: "isInitialised", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "preFetch", returnType: CAPPluginReturnNone),
        CAPPluginMethod(name: "initiate", returnType: CAPPluginReturnNone),
        CAPPluginMethod(name: "process", returnType: CAPPluginReturnNone),
        CAPPluginMethod(name: "processWithViewController", returnType: CAPPluginReturnNone),
        CAPPluginMethod(name: "terminate", returnType: CAPPluginReturnNone),
        CAPPluginMethod(name: "updateBaseViewController", returnType: CAPPluginReturnNone),
        CAPPluginMethod(name: "onBackPressed", returnType: CAPPluginReturnNone),
        CAPPluginMethod(name: "isNull", returnType: CAPPluginReturnPromise)
    ]

    var hyperInstance: HyperServices!
    var widgetContainerView: UIView?
    var widgetContainerTopConstraint: NSLayoutConstraint?
    var widgetContainerBaseTopInset: CGFloat = 0
    var widgetKeyboardObservers: [NSObjectProtocol] = []

    func removeWidgetContainer() {
        widgetContainerView?.removeFromSuperview()
        widgetContainerView = nil
        widgetContainerTopConstraint = nil
        widgetContainerBaseTopInset = 0
    }

    func removeKeyboardObservers() {
        for observer in widgetKeyboardObservers {
            NotificationCenter.default.removeObserver(observer)
        }
        widgetKeyboardObservers.removeAll()
    }

    func syncWidgetContainerWithKeyboard(container: UIView, parentView: UIView, notification: Notification) {
        parentView.layoutIfNeeded()

        let animationDuration =
            notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let animationCurve =
            notification.userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
            ?? UInt(UIView.AnimationCurve.easeInOut.rawValue)
        let keyboardFrameValue =
            notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue

        let overlap: CGFloat
        if let keyboardFrameValue {
            let keyboardFrame = parentView.convert(keyboardFrameValue.cgRectValue, from: nil)
            let containerBottom = widgetContainerBaseTopInset + container.bounds.height
            overlap = max(0, containerBottom - keyboardFrame.minY)
        } else {
            overlap = 0
        }

        widgetContainerTopConstraint?.constant = widgetContainerBaseTopInset - overlap

        UIView.animate(
            withDuration: animationDuration,
            delay: 0,
            options: [UIView.AnimationOptions(rawValue: animationCurve << 16), .beginFromCurrentState]
        ) {
            parentView.layoutIfNeeded()
        }
    }

    func observeKeyboard(for container: UIView, in parentView: UIView) {
        removeKeyboardObservers()

        let center = NotificationCenter.default
        let notificationNames = [
            UIResponder.keyboardWillChangeFrameNotification,
            UIResponder.keyboardWillHideNotification
        ]

        widgetKeyboardObservers = notificationNames.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self, weak parentView, weak container] notification in
                guard let self, let parentView, let container else { return }
                self.syncWidgetContainerWithKeyboard(container: container, parentView: parentView, notification: notification)
            }
        }
    }

    @objc func createHyperServices(_ call: CAPPluginCall) {
        if hyperInstance == nil {
            hyperInstance = HyperServices()
        }
        call.resolve()
    }

    @objc func preFetch(_ call: CAPPluginCall) {
        let payload = call.options
        if (payload) != nil {
            print(payload ?? "")
            DispatchQueue.main.sync {
                HyperServices.preFetch(payload!)
            }
            call.resolve()
            return
        }
        call.reject("Missing prefetch payload", nil, nil, nil)
    }

    @objc func initiate(_ call: CAPPluginCall) {
        var topController: UIViewController!
        let payload = call.options
        if self.hyperInstance == nil {
            call.reject("Create a Hyper SDK Instance before calling Initiate", nil, nil, nil)
            return
        }
        if payload != nil && (payload?.keys.count)! > 0 {
            DispatchQueue.main.sync {
                topController = topViewController
                self.hyperInstance.initiate(topController, payload: payload!, callback: { [self] response in
                    self.notifyListeners("HyperEvent", data: response)
                })
            }
        }
        call.resolve()
    }

    @objc func isInitialised(_ call: CAPPluginCall) {
        if hyperInstance == nil {
            call.reject("Create a Hyper SDK Instance before calling isInitialised", nil, nil, nil)
            return
        }
        call.resolve(["isInitialised": self.hyperInstance.isInitialised()])
    }

    @objc func process(_ call: CAPPluginCall) {
        if hyperInstance == nil {
            call.reject("Create a Hyper SDK Instance before calling process", nil, nil, nil)
            return
        }
        if !hyperInstance.isInitialised() {
            call.reject("Initiate should be done before calling process", nil, nil, nil)
            return
        }
        if let payload = call.options {
            if (payload.keys.count) > 0 {
                var missingRect = false
                DispatchQueue.main.sync {
                    var modifiedPayload = payload

                    // Payment Widget: create native container matching the div's position
                    if var hyperPayload = modifiedPayload["payload"] as? [String: Any],
                       var fragmentViewGroups = hyperPayload["fragmentViewGroups"] as? [String: Any],
                       fragmentViewGroups["paymentWidget"] != nil,
                       let parentView = self.bridge?.viewController?.view {
                        guard let rectDict = hyperPayload["paymentWidgetRect"] as? [String: Any] else {
                            missingRect = true
                            return
                        }
                        self.removeKeyboardObservers()
                        self.removeWidgetContainer()
                        let container = UIView()
                        container.translatesAutoresizingMaskIntoConstraints = false

                        parentView.addSubview(container)
                        self.widgetContainerView = container

                        let originX = CGFloat((rectDict["x"] as? NSNumber)?.doubleValue ?? 0)
                        let originY = CGFloat((rectDict["y"] as? NSNumber)?.doubleValue ?? 0)
                        let width = CGFloat((rectDict["width"] as? NSNumber)?.doubleValue ?? Double(parentView.bounds.width))
                        let height = CGFloat((rectDict["height"] as? NSNumber)?.doubleValue ?? 0)
                        let topConstraint = container.topAnchor.constraint(equalTo: parentView.topAnchor, constant: originY)
                        var constraints = [
                            container.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: originX),
                            topConstraint,
                            container.widthAnchor.constraint(equalToConstant: width)
                        ]
                        if height > 0 {
                            constraints.append(container.heightAnchor.constraint(equalToConstant: height))
                        }
                        NSLayoutConstraint.activate(constraints)
                        self.widgetContainerTopConstraint = topConstraint
                        self.widgetContainerBaseTopInset = y
                        self.observeKeyboard(for: container, in: parentView)

                        fragmentViewGroups["paymentWidget"] = container
                        hyperPayload["fragmentViewGroups"] = fragmentViewGroups
                        modifiedPayload["payload"] = hyperPayload
                    }

                    self.hyperInstance.shouldUseViewController = false
                    self.hyperInstance.process(modifiedPayload)
                }
                if missingRect {
                    call.reject("paymentWidgetRect is required for payment widget", nil, nil, nil)
                    return
                }
                call.resolve()
                return
            }
        }
        call.reject("Invalid process payload", nil, nil, nil)
    }

    @objc func processWithViewController(_ call: CAPPluginCall) {
        if hyperInstance == nil {
            call.reject("Create a Hyper SDK Instance before calling process", nil, nil, nil)
            return
        }
        if !hyperInstance.isInitialised() {
            call.reject("Initiate should be done before calling process", nil, nil, nil)
            return
        }
        if let payload = call.options {
            if (payload.keys.count) > 0 {
                DispatchQueue.main.sync {
                    self.hyperInstance.shouldUseViewController = true
                    self.hyperInstance.process(payload)
                }
                call.resolve()
                return
            }
        }
        call.reject("Invalid process payload", nil, nil, nil)
    }

    @objc func terminate(_ call: CAPPluginCall) {
        removeKeyboardObservers()
        DispatchQueue.main.async {
            self.removeWidgetContainer()
        }
        if self.hyperInstance != nil {
            self.hyperInstance.terminate()
        }
        self.hyperInstance = nil
        call.resolve()
    }

    @objc func updateBaseViewController(_ call: CAPPluginCall) {
        if (self.hyperInstance != nil) && self.hyperInstance.isInitialised() {
            self.hyperInstance.baseViewController = self.topViewController
        }
    }

    var topViewController: UIViewController? {
        return self.topViewControllerWithRootViewController(viewController: UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController)
    }

    func topViewControllerWithRootViewController(viewController: UIViewController?) -> UIViewController? {
        if viewController is UITabBarController {
            let tabBarController = viewController as? UITabBarController
            return topViewControllerWithRootViewController(viewController: tabBarController?.selectedViewController)
        } else if viewController is UINavigationController {
            let navContObj = viewController as? UINavigationController
            return self.topViewControllerWithRootViewController(viewController: navContObj?.visibleViewController)
        } else if (viewController?.presentedViewController != nil) && !(viewController?.presentedViewController?.isBeingDismissed != nil) {
            let presentedViewController = viewController?.presentedViewController
            return self.topViewControllerWithRootViewController(viewController: presentedViewController)
        } else {
            for view in viewController?.view.subviews ?? [] {
                let subViewController = view.next
                if subViewController != nil && (subViewController is UIViewController) {
                    if (subViewController as? UIViewController)?.presentedViewController != nil && !(subViewController?.inputViewController?.presentedViewController?.isBeingDismissed ?? false) {
                        return topViewControllerWithRootViewController(viewController: (subViewController as? UIViewController)?.presentedViewController)
                    }
                }
            }
            return viewController
        }
    }

    @objc func onBackPressed(_ call: CAPPluginCall) {
        call.unimplemented("Not implemented on IOS as IOS does not have hardware back press.")
    }

    @objc func isNull(_ call: CAPPluginCall) {
        call.resolve(["isNull": self.hyperInstance == nil])
    }
}
