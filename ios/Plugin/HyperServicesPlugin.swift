import Foundation
import Capacitor
import HyperSDK

@objc(HyperServicesPlugin)
public class HyperServicesPlugin: CAPPlugin {

    var hyperInstance : HyperServices!

    @objc func createHyperServices(_ call: CAPPluginCall) {
        if (hyperInstance == nil) {
            hyperInstance = HyperServices();
        }
        call.resolve()
    }

    @objc func preFetch(_ call: CAPPluginCall) {
        let payload = call.options;
        if ((payload) != nil) {
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
        var topController : UIViewController!
        let payload = call.options;
        if (self.hyperInstance == nil) {
            call.reject("Create a Hyper SDK Instance before calling Initiate", nil, nil, nil)
            return
        }
        if (payload != nil && (payload?.keys.count)! > 0) {
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
        if (hyperInstance == nil) {
            call.reject("Create a Hyper SDK Instance before calling isInitialised", nil, nil, nil)
            return
        }
        call.resolve(["isInitialised": self.hyperInstance.isInitialised()])
    }

    @objc func process(_ call: CAPPluginCall) {
        if (hyperInstance == nil) {
            call.reject("Create a Hyper SDK Instance before calling process", nil, nil, nil)
            return
        }
        if (!hyperInstance.isInitialised()) {
            call.reject("Initiate should be done before calling process", nil, nil, nil)
            return
        }
        let payload = call.options;
        if (payload != nil && (payload?.keys.count)! > 0) {
            DispatchQueue.main.sync {
                self.hyperInstance.process(payload)
            }
        }
        call.resolve()
    }

    @objc func terminate(_ call: CAPPluginCall) {
        if (self.hyperInstance != nil) {
            self.hyperInstance.terminate()
        }
        self.hyperInstance = nil
        call.resolve()
    }

    @objc func updateBaseViewController(_ call: CAPPluginCall) {
        if ((self.hyperInstance != nil) && self.hyperInstance.isInitialised()) {
            self.hyperInstance.baseViewController = self.topViewController;
        }
    }

    var topViewController: UIViewController? {
        return self.topViewControllerWithRootViewController(viewController: UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController)
    }

    func topViewControllerWithRootViewController (viewController: UIViewController?) -> UIViewController? {
        if viewController is UITabBarController {
            let tabBarController = viewController as? UITabBarController
            return topViewControllerWithRootViewController(viewController: tabBarController?.selectedViewController)
        } else if (viewController is UINavigationController) {
            let navContObj = viewController as? UINavigationController
            return self.topViewControllerWithRootViewController(viewController: navContObj?.visibleViewController)
        } else if ((viewController?.presentedViewController != nil) && !(viewController?.presentedViewController?.isBeingDismissed != nil)) {
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
