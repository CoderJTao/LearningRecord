动态切换 App 的 icon 这个需求，在上一家公司做一款定制 App 时遇到过一次，这次领导说可能需要做，就又做了一次。虽然不是什么很难的知识点，这里也就记录一下自己做的过程吧。

* info.plist 文件编辑
* 更换 Icon
* 静默切换

<!--more-->

## info.plist 文件

为了动态更换 icon，我们需要先配置一下我们项目的 info.plist 文件：

![](/Users/jiangtao/Desktop/plist.jpg)

1. 加入 Icon files(iOS5)，其中会默认有两个 item：
	1. Newsstand Icon
	2. Primary Icon	
2. 我们需要加入我们需要的键——CFBundleAlternateIcons，类型为 Dictionary。
3. 下面再添加一些字典。这里字典的键是你希望更换 Icon 的名称，在下方的 CFBundleIconFiles 数组中，写入需要更换的 Icon 的名称。

**Primary Icon：** 可以设置 App 的主 Icon，一般都不理会。一般主 Icon 在 Assets.xcassets 中设置。

**Newsstand Icon：** 这个设置一般用于在 Newsstand 中显示使用。我们也不需要理会。

这里我们就将 info.plist 编辑完成了，下面我们将对应的图片加入到项目中，这里的图片需要直接加到项目中，不能放在 Assets.xcassets 中。

![](/Users/jiangtao/Desktop/目录.jpg)

## 更换 Icon

在 iOS 10.3，苹果开放了这个 API，可以让我们动态更换我们的 App Icon。

```
// If false, alternate icons are not supported for the current process.
@available(iOS 10.3, *)
open var supportsAlternateIcons: Bool { get }
    
// Pass `nil` to use the primary application icon. The completion handler will be invoked asynchronously on an arbitrary background queue; be sure to dispatch back to the main queue before doing any further UI work.
@available(iOS 10.3, *)
open func setAlternateIconName(_ alternateIconName: String?, completionHandler: ((Error?) -> Void)? = nil)
    
// If `nil`, the primary application icon is being used.
@available(iOS 10.3, *)
open var alternateIconName: String? { get }

```

#### 切换到我们需要的 Icon

```
@IBAction func changeOneClick(_ sender: Any) {
    if UIApplication.shared.supportsAlternateIcons {
        UIApplication.shared.setAlternateIconName("lambot") { (error) in
            if error != nil {
                print("更换icon错误")
            }
        }
    }
}
```

这里的 iconName 直接传入项目中的 icon 名称。这里需要注意的是，项目中的名字、info.plist 中存入的名称以及这里传入的名称需要一致。

#### 重置为原始的 Icon

```
@IBAction func resetClick(_ sender: Any) {
    if UIApplication.shared.supportsAlternateIcons {
        UIApplication.shared.setAlternateIconName(nil) { (error) in
            if error != nil {
                print("更换icon错误")
            }
        }
    }
}
```

如果需要恢复为原始的 icon，只需要在传入 iconName 的地方传入 nil 即可。

![](/Users/jiangtao/Desktop/效果图1.gif)

现在，已经完成了切换 Icon 的功能了。但是每次切换时，都会有一个弹框，下面我们就想办法去掉这个弹框。

## 静默切换

我们可以利用 Runtime 的方法来替换掉弹出提示框的方法。

以前 Method Swizzling 的时候需要在 load 或者 initialize 方法，但是在 Swift 中不能使用了。那就只能自己定义一个了。

```
extension UIViewController {
    public class func initializeMethod() {
        if self != UIViewController.self {
            return
        }
		// Method Swizzling
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
		
		// 因为方法已经交换，这个地方的调用就相当于调用原先系统的 present
        self.jt_present(viewControllerToPresent, animated: flag, completion: completion)
    }
}
```

定义完 UIViewController 的扩展方法后，记得在 AppDelegate 中调用一下。

```
func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    UIViewController.initializeMethod()

    return true
}
```

因为，Swift 中 GCD 之前的 once 函数没有了，这里自己简单定义了一个。

```
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
```

> defer block 里的代码会在函数 return 之前执行，无论函数是从哪个分支 return 的，还是有 throw，还是自然而然走到最后一行。

现在，我们再更换 Icon 的时候，就不会出现弹出框了。

![](/Users/jiangtao/Desktop/效果图2.gif)

## 总结

简单的知识点，时间长了不用也有可能忘记。希望自己能坚持学习，坚持记录，不断成长。

**参考链接：**

[Information Property List Key Reference](https://developer.apple.com/library/archive/documentation/General/Reference/InfoPlistKeyReference/Articles/CoreFoundationKeys.html#//apple_ref/doc/uid/TP40009249-SW18)
