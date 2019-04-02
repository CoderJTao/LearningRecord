import UIKit

class TestClass: NSObject {
    @objc dynamic var name: String = ""
}

let test = TestClass()

var before_count: UInt32 = 0
let before_lists = class_copyMethodList(object_getClass(test), &before_count)!

print("------被观察前-----")
for i in 0..<before_count {
    let method = before_lists[Int(i)]

    let name = method_getName(method)
    print(name.description)
}

let obj = NSObject()
test.addObserver(obj, forKeyPath: "name", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)

var after_count: UInt32 = 0
let after_lists = class_copyMethodList(object_getClass(test), &after_count)!

print("------被观察后-----")
for i in 0..<after_count {
    let method = after_lists[Int(i)]

    let name = method_getName(method)
    print(name.description)
}

