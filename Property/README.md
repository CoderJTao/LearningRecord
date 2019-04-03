## 前言
![](https://github.com/CoderJTao/LearningRecord/blob/master/Property/property_MindNode.jpg)

## 一、@property的本质

当我们写下@property NSObject *name时，编译器帮我们做了以下几件事:

* 创建实例变量_name
* 声明name属性的setter、getter方法
* 实现name属性的setter、getter方法

所以我们可以看出@property的本质是：

```
@property = ivar + getter + setter;
```

也就是说使用@property时, 系统会自动创建实例变量及其setter和getter方法;

---

## 二、@property的常见关键字

### 读写权限

* readwrite（可读可写），系统默认的属性。

* readonly（只读），当声明了这个属性，系统不会为其生成getter方法，当你希望暴露出来的属性不能被外界修改时使用。

### 原子性

* atomic 和 nonatomic 用来决定编译器生成的getter和setter是否为原子操作。

* atomic： 会保证系统生成的 getter/setter 操作的完整性，不受其他线程影响。getter 还是能得到一个完好无损的对象（可以保证数据的完整性），但这个对象在多线程的情况下是不能确定的。举例如下：

```
@interface ViewController ()
@property(atomic, strong) NSString *testStr;
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.testStr = @"JiangT";
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    // getter
    NSBlockOperation *oper1 =[NSBlockOperation blockOperationWithBlock:^{
        NSLog(self.testStr);
    }];
    
    // setter
    NSBlockOperation *oper2 = [NSBlockOperation blockOperationWithBlock:^{
        self.testStr = @"change one";
    }];
    
    // setter
    NSBlockOperation *oper3 = [NSBlockOperation blockOperationWithBlock:^{
        self.testStr = @"change two";
    }];
    
    // setter
    NSBlockOperation *oper4 = [NSBlockOperation blockOperationWithBlock:^{
        self.testStr = @"change three";
    }];
    
    // setter
    NSBlockOperation *oper5 = [NSBlockOperation blockOperationWithBlock:^{
        self.testStr = @"change four";
    }];
    
    //创建队列
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    [queue addOperations:@[oper1, oper2, oper3, oper4, oper5] waitUntilFinished:NO];
}
@end

---输出结果：---
AtomicDemo[52660:1647356] change two
AtomicDemo[52660:1647356] change four
AtomicDemo[52660:1647356] change four
AtomicDemo[52660:1647354] change two
AtomicDemo[52660:1647354] change four
AtomicDemo[52660:1647354] change four
AtomicDemo[52660:1647356] change four
```
	
如果线程 A 调了 getter，与此同时线程 B 、线程 C 都调了 setter。那最后线程 A get 到的值，有3种	 可能：可能是 B、C set 之前原始的值，也可能是 B set 的值，也可能是 C set 的值。同时，最终这个属性的值，可能是 B set 的值，也有可能是 C set 的值。所以atomic可并不能保证对象的线程安全。
	
也就是说：如果有多个线程同时调用setter的话，不会出现某一个线程执行完setter全部语句之前，另一个线程开始执行setter情况，相当于函数头尾加了锁一样，每次只能有一个线程调用对象的setter方法，所以可以保证数据的完整性。
	
**结论：** atomic所说的线程安全只是保证了getter和setter存取方法的线程安全，并不能保证整个对象是线程安全的。

* nonatomic：就没有这个保证了，nonatomic返回你的对象可能就不是完整的value。因此，在多线程的环境下原子操作是非常必要的，否则有可能会引起错误的结果。但仅仅使用atomic并不会使得对象线程安全，我们还要为对象线程添加lock来确保线程的安全。

* nonatomic的速度要比atomic的快。atomic是Objc使用的一种线程保护技术，这种机制是耗费系统资源的，所以在iPhone这种小型设备上，我们基本上都是使用nonatomic，而对象的线程安全问题则由程序员代码控制。


### 引用计数

#### strong 及 retain

* strong

    * 强引用，其存亡直接决定了所指向对象的存亡。使用该特性实例变量在赋值时，会释放旧值同时设置新值，对对象产生一个强引用，即引用计数+1。如果不存在指向一个对象的引用，并且此对象不再显示在列表中，则此对象会被从内存中释放。适用于一般OC对象。

* retaine

    * 一般情况下等同于ARC环境下的strong修饰符，但是在修饰block对象时，retain相当于assign，而strong相当于copy。
    * 生成符合内存管理的set方法（release旧值，retain新值），适用于OC对象的成员变量。



#### assign 及 unsafe_unretained
永远指向某内存地址，如果该内存被释放了，自己就会成为野指针。

* assign

    * 这个修饰词是直接赋值的意思 , 整型/浮点型等数据类型都用这个词修饰。
    * 如果没有使用 weak strong retain copy 修饰 , 那么默认就是使用 assign 了。
    * 修饰对象类型时，不改变其引用计数。
    * 如果用来修饰对象属性 , 那么当对象被销毁后指针是不会指向 nil 的。 所以会出现野指针错误。

* unsafe_unretained

    * unsafe_unretained与assign类似，但是用于对象类型，从字面意思上，也能看到，它是不安全，也不会强引用对象，所以它跟weak很相似，跟weak的区别在于当指向的对象被释放时，属性不会被置为nil，所以是不安全的。

#### copy

**浅拷贝**：只是将对象内存地址多了一个引用，也就是说，拷贝结束之后，两个对象的值不仅相同，而且对象所指的内存地址都是一样的。

**深拷贝**：拷贝一个对象的具体内容，拷贝结束之后，两个对象的值虽然是相同的，但是指向的内存地址是不同的。两个对象之间也互不影响，互不干扰。
    

* 在非集合类对象中，对不可变对象进行copy操作，只仅仅是指针复制——浅复制，进行mutableCopy操作，是内容复制——深复制。

* 对于不可变的集合类对象进行copy操作，只是改变了指针，其内存地址并没有发生变化；进行mutableCopy操作，内存地址发生了变化，但是其中的元素内存地址并没有发生变化。

* 对于可变集合类对象，不管是进行copy操作还是mutableCopy操作，其内存地址都发生了变化，但是其中的元素内存地址都没有发生变化，属于单层深拷贝。

<font color="red">使用注意：</font>

> 1. 当将一个可变对象分别赋值给两个使用不同修饰词的属性后，改变可变对象的内容，使用strong修饰的会跟随着改变，但使用copy修饰的没有改变内容。

```
@interface test()
 
@property(nonatomic, strong) NSMutableString *strStrong;
@property(nonatomic, copy) NSMutableString *strCopy;
 
@end
 
/********************* test.m **********************/
NSMutableString *string = [NSMutableString stringWithFormat:@"abc"];

self.strStrong = str;    
self.strCopy = str;
    
[self.strStrong appendString:@"def"];
[self.strCopy appendString:@"def"];// 在这一行会crash
```

<div align="center">
<img src="https://github.com/CoderJTao/LearningRecord/blob/master/Property/property_copy.jpg" height="147" width="310" >
 </div>

因为copy是复制出一个不可变的对象，在不可变对象上运行可变对象的方法，就会找不到执行方法。


#### weak

##### 1、作用
* weak 必须用于 OC 对象
* 表示的是一个弱引用，这个引用不会增加对象的引用计数。
* 在所指向的对象被释放之后，weak指针会被置为nil。
* 用于解决循环引用。例如：delegate属性常用weak修饰。
    
##### 2、原理

Runtime维护了一个weak表，用于存储指向某个对象的所有weak指针。weak表其实是一个hash表，K
ey是所指对象的地址，value是weak指针的地址（这个地址的值是所指对象指针的地址）数组。

为什么value是数组？因为一个对象可能被多个弱引用指针指向。

![](https://github.com/CoderJTao/LearningRecord/blob/master/Property/property_weak.jpg)

1. **初始化时：**

    runtime会调用objc_initWeak函数，objc_initWeak函数会初始化一个新的weak指针指向对象的地址。
    
2. **添加引用时：**

    objc_initWeak函数会调用 objc_storeWeak() 函数， objc_storeWeak() 的作用是更新指针指向，创建对应的弱引用表。

3. **释放时：**

    调用clearDeallocating函数。clearDeallocating函数首先根据对象地址获取所有weak指针地址的数组，然后遍历这个数组把其中的数据设为nil，最后把这个entry从weak表中删除，最后清理对象的记录。

> 思考题：IBOutlet连出来的视图属性为什么可以被设置成weak?
>
> 因为父控件的subViews数组已经对它有一个强引用。
>
> 所以：当自身已经对它进行一次强引用,没有必要再强引用一次,此时也会使用 weak。






