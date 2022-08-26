import Foundation
import Capacitor

/**
 * Please read the Capacitor iOS Plugin Development Guide
 * here: https://capacitorjs.com/docs/plugins/ios
 */
@objc(HyperServicesPlugin)
public class HyperServicesPlugin: CAPPlugin {

    @objc func echo(_ call: CAPPluginCall) {
        let value = call.getString("value") ?? ""

        print(value)

        call.resolve([
            "value": value
        ])
    }
}
