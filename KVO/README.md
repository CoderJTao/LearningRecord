## 前言
[](https://github.com/CoderJTao/LearningRecord/blob/master/KVO/KVO_MindNode.png)
## 一、概述

KVO,即：**Key-Value Observing**，是 Objective-C 对 观察者模式（Observer Pattern）的实现。它提供一种机制，当指定的对象的属性被修改后，观察者就会接受到通知。简单的说就是每次指定的被观察的对象的属性被修改后，KVO就会自动通知相应的观察者了。

## 二、使用

#### 1、基本使用步骤
KVO本质上是基于runtime的动态分发机制，通过key来监听value的值。
OC能够实现监听因为都遵守了NSKeyValueCoding协议。OC所有的类都是继承自NSObject，其默认已经遵守了该协议，但Swift不是基于runtime的。Swift中继承自NSObject的属性处于性能等方面的考虑，默认是关闭动态分发的， 所以无法使用KVO，只有在属性前加 **@objc dynamic** 才会开启运行时，允许监听属性的变化。

> 在Swift3中只需要加上dynamic就可以了，而Swift4以后则还需要@objc

* 注册

```
- (void)addObserver:(NSObject *)observer 
            forKeyPath:(NSString *)keyPath 
            options:(NSKeyValueObservingOptions)options 
            context:(void *)context;
```

<Font color="#ff0000">observer</Font>:观察者，也就是KVO通知的订阅者。订阅着必须实现。  
<Font color="#ff0000">keyPath</Font>：描述将要观察的属性，相对于被观察者。  
<Font color="#ff0000">options</Font>：KVO的一些属性配置；有四个选项。  

~~~
NSKeyValueObservingOptionNew：change字典包括改变后的值
NSKeyValueObservingOptionOld：change字典包括改变前的值
NSKeyValueObservingOptionInitial：注册后立刻触发KVO通知
NSKeyValueObservingOptionPrior：值改变前是否也要通知（这个key决定了是否在改变前改变后通知两次）
~~~

<Font color="#ff0000">context</Font>:上下文，这个会传递到订阅着的函数中，可以为kvo的回调方法传值。是unsafePointer类型，表示不安全的指针类型(因为在Swift手动操作指针，修改内存是一件非常不安全且不考靠的行为)，可以传入一个指针地址。

* 监听 

在观察者内重写这个方法。在属性变化时，观察者则可以在函数内对属性变化做处理。

```
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
```

* 移除

在不用的时候，不要忘记解除注册，否则会导致内存泄露。

```
- (void)removeObserver:(NSObject *)observer 
                forKeyPath:(NSString *)keyPath;
```

举例：

```
class ObservedClass: NSObject {
    // 开启运行时，允许监听属性的变化
    @objc dynamic var name: String = "Original"
    // age 并不会触发KVO
    var age: Int = 18
}

class ViewController: UIViewController {
    var observed = ObservedClass()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observed.addObserver(self, forKeyPath: "age", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        observed.addObserver(self, forKeyPath: "name", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        // 修改属性值，触发KVO
        observed.name = "JiangT"
        observed.age = 22
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("属性改变了")
        print(keyPath)
        print("change字典为：")
        print(change)
    }
}

---输出结果---
属性改变了
Optional("name")
change字典为：
Optional(
[__C.NSKeyValueChangeKey(_rawValue: new): JiangT, 
__C.NSKeyValueChangeKey(_rawValue: kind): 1, 
__C.NSKeyValueChangeKey(_rawValue: old): Original])
```

从上面的代码上可以看到，name和age属性都进行了设置，但是在监听中，只有收到name修改的回调。证明了在swift中默认是关闭动态分发的，所以无法使用KVO。

#### 2、手动KVO 及 禁用KVO
1. 首先，需要手动实现属性的 setter 方法，并在设置操作的前后分别调用 willChangeValueForKey: 和 didChangeValueForKey方法，这两个方法用于通知系统该 key 的属性值即将和已经变更了。
2. 其次，要实现类方法 automaticallyNotifiesObserversForKey，并在其中设置对该 key 不自动发送通知（返回 NO 即可）。这里要注意，对其它非手动实现的 key，要转交给 super 来处理。
3. 如果需要**禁用该类KVO**的话直接automaticallyNotifiesObserversForKey返回NO，实现属性的 setter 方法，不进行调用willChangeValueForKey: 和 didChangeValueForKey方法。

主要方法：

```
open func willChangeValue(forKey key: String)

open func didChangeValue(forKey key: String)

class func automaticallyNotifiesObservers(forKey key: String) -> Bool
```

举例：

```
---被观察类---
class ObservedClass: NSObject {
 
    private var _name: String = "Original"
    @objc dynamic var name: String {
        get {
            return _name
        }
        set (n) {
            self.willChangeValue(forKey: "name")
            _name = n
            self.didChangeValue(forKey: "name")
        }
    }
    
    override class func automaticallyNotifiesObservers(forKey key: String) -> Bool {
        // 设置对该 key 不自动发送通知
        if key == "name" {
            return false
        }
        return super.automaticallyNotifiesObservers(forKey: key)
    }
}

class ViewController: UIViewController {
    var observed = ObservedClass()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        observed.addObserver(self, forKeyPath: "name", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        // 修改属性值，触发KVO
        observed.name = "JiangT"
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        print("属性改变了")
        print(keyPath)
        print("change字典为：")
        print(change)
    }
}

---输出结果---
属性改变了
Optional("name")
change字典为：
Optional([__C.NSKeyValueChangeKey(_rawValue: kind): 1, 
__C.NSKeyValueChangeKey(_rawValue: old): Original, 
__C.NSKeyValueChangeKey(_rawValue: new): JiangT])
```


## 三、实现原理
[Key-Value Observing Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOImplementation.html#//apple_ref/doc/uid/20002307-BAJEAIEE)中原文如下：
>
>Automatic key-value observing is implemented using a technique called isa-swizzling.
>
>The isa pointer, as the name suggests, points to the object's class which maintains a dispatch table. This dispatch table essentially contains pointers to the methods the class implements, among other data.
>
>When an observer is registered for an attribute of an object the isa pointer of the observed object is modified, pointing to an intermediate class rather than at the true class. As a result the value of the isa pointer does not necessarily reflect the actual class of the instance.
>
>You should never rely on the isa pointer to determine class membership. Instead, you should use the class method to determine the class of an object instance.
>
>大致意思为：
>
>苹果使用了一种isa交换的技术，当ObjectA的被观察后，ObjectA对象的isa指针被指向了一个新建的子类NSKVONotifying_ObjectA，且这个子类重写了被观察值的setter方法和class方法，dealloc和_isKVO方法，然后使ObjectA对象的isa指针指向这个新建的类，然后事实上ObjectA变为了NSKVONotifying_ ObjectA的实例对象，执行方法要从这个类的方法列表里找。
>

所以我们可以得到如下结论：

* KVO是基于**runtime**机制实现的。

* 当某个类的属性对象第一次被观察时，系统就会在运行期动态地创建该类的一个派生类(如果原类为**ObservedClass**，那么生成的派生类名为**NSKVONotifying_ObservedClass**)，在这个派生类中重写基类中任何被观察属性的**setter**方法。派生类在被重写的**setter**方法内实现真正的通知机制

* 每个类对象中都有一个**isa**指针指向当前类，当一个类对象的第一次被观察，那么系统会偷偷将**isa**指针指向动态生成的派生类(isa-swizzling，后续Runtime学习记录中展开)，从而在给被监控属性赋值时执行的是派生类的**setter**方法。派生类中还偷偷重写了class方法，让我们误认为还是使用的当前类，从而达到隐藏生成的派生类。

下面咱们用代码验证一下：

```
class ObservedClass: NSObject {
    // 属性观察
    @objc dynamic var normalStr = ""
}

class ViewController: UIViewController {

    var observed = ObservedClass()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // isa    Class    KVODemo.ObservedClass    0x0000000100e8c990
        // isa    Class    NSKVONotifying_KVODemo.ObservedClass    0x00007f9b47403340
        
        print("断点1：-----被观察前-----")
        observed.addObserver(self, forKeyPath: "normalStr", options: [NSKeyValueObservingOptions.new, NSKeyValueObservingOptions.old], context: nil)
        print("断点2：-----被观察后-----")
    }
}
```
在注册观察者前后分别打上断点，查看observed：

* 断点1：
![](https://github.com/CoderJTao/LearningRecord/blob/master/KVO/before_observed.png)
* 断点2：
![](https://github.com/CoderJTao/LearningRecord/blob/master/KVO/after_observed.png)

可以发现：observed在被观察之后对象的isa指针被指向了一个新建的子类NSKVONotifying_ObservedClass。但是，我们打印observed的class信息时，发现返回的还是ObservedClass类型。说明动态创建的派生类NSKVONotifying_ObservedClass重写了class方法来隐藏自身。

下面我们用runtime查看一下派生类中的方法列表

```
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

---------输出结果：---------
------被观察前-----
.cxx_destruct
name
setName:
init
------被观察后-----
setName:
class
dealloc
_isKVOA
```

可以发现：

* 派生类中，在内部重写了class类，用来隐藏自身的存在。
* 重写了被观察属性setter方法，set方法实现内部会顺序调用 willChangeValueForKey 方法、原来的 setter 方法实现、didChangeValueForKey 方法，而 didChangeValueForKey 方法内部又会调用监听器的 observeValueForKeyPath:ofObject:change:context: 监听方法。。

> .cxx_destruct方法原本是为了C++对象析构的，ARC借用了这个方法插入代码实现了自动内存释放的 工作。具体的实现可以查看一下这边文章[ARC下dealloc过程及.cxx_destruct的探究](http://blog.jobbole.com/65028/)。



