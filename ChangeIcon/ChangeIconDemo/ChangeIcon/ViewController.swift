//
//  ViewController.swift
//  ChangeIcon
//
//  Created by 江涛 on 2019/7/10.
//  Copyright © 2019 江涛. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        let vc = UIViewController()

//        self.present(<#T##viewControllerToPresent: UIViewController##UIViewController#>, animated: <#T##Bool#>, completion: <#T##(() -> Void)?##(() -> Void)?##() -> Void#>)
    }

    // MARK: - reset icon to orignal
    @IBAction func resetClick(_ sender: Any) {
        if UIApplication.shared.supportsAlternateIcons {
            UIApplication.shared.setAlternateIconName(nil) { (error) in
                if error != nil {
                    print("更换icon错误")
                }
            }
        }
    }

    // MARK: - change icon
    @IBAction func changeOneClick(_ sender: Any) {
        if UIApplication.shared.supportsAlternateIcons {
            UIApplication.shared.setAlternateIconName("lambot") { (error) in
                if error != nil {
                    print("更换icon错误")
                }
            }
        }
    }

    // MARK: - change icon from cloud
    @IBAction func cloudClick(_ sender: Any) {
        print("程序运行期间无法修改 info.plist 中 icon 的值。会报 error —— iconName not found in CFBundleAlternateIcons entry.")
    }
}

extension UIViewController {
    public class func initializeMethod() {
        if self != UIViewController.self {
            return
        }

        DispatchQueue.once(token: "ChangeIcon") {
            let orignal = class_getInstanceMethod(self, #selector(UIViewController.present(_:animated:completion:)))
            let swizzling = class_getInstanceMethod(self, #selector(UIViewController.jt_present(_:animated:completion:)))

            if let old = orignal, let new = swizzling {
                method_exchangeImplementations(old, new)
            }
        }
    }

    @objc private func jt_present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        // 在这里判断是否是更换icon时的弹出框
        if viewControllerToPresent is UIAlertController {

            let alertTitle = (viewControllerToPresent as! UIAlertController).title
            let alertMessage = (viewControllerToPresent as! UIAlertController).message

            // 更换icon时的弹出框，这两个string都为nil。
            if alertTitle == nil && alertMessage == nil {
                return
            }
        }

        self.jt_present(viewControllerToPresent, animated: flag, completion: completion)
    }
}

extension DispatchQueue {
    private static var _onceTracker = [String]()
    public class func once(token: String, block: () -> ()) {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        if _onceTracker.contains(token) {
            return
        }
        _onceTracker.append(token)
        block()
    }
}


