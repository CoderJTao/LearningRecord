## 前言
![目录](https://github.com/CoderJTao/LearningRecord/blob/master/KVC%20Record/KVC_MindNode.png)

## 一、概述
KVC全称是**Key Value Coding**（键值编码），是可以通过对象属性名称（Key）直接对属性值（value）编码（coding）“编码”可以理解为“赋值及访问”。而不需要调用明确的存取方法。这样就可以在运行时动态在访问和修改对象的属性，而不是在编译时确定。

KVC的优势是在没有访问器(setter、getter)方法的类中，此时点语法无法使用。

KVC提供了一种间接访问其属性方法或成员变量的机制，可以通过字符串来访问对应的属性方法或成员变量。

## 二、使用

KVC的定义都是对NSObject的扩展来实现的，Objective-c中有个显式的NSKeyValueCoding类别名，所以对于所有继承了NSObject在类型，都能使用KVC。

在 Swift 中处理 KVC和 Objective-C 中还是有些细微的差别。比如，Objective-C 中所有的类都继承自 NSObject，而 Swift 中却不是，所以我们在 Swift 中需要显式的声明继承自 NSObject。

因为 Swift 中的 Optional 机制，所以 valueForKey 方法返回的是一个 Optional 值，我们还需要对返回值做一次解包处理，才能得到实际的属性值。


#### 1、基本使用
下面是KVC中最常用的几个方法：

```
//直接通过Key来取值
- (nullable id)valueForKey:(NSString *)key; 

//通过Key来设值
- (void)setValue:(nullable id)value forKey:(NSString *)key;

//通过KeyPath来取值
- (nullable id)valueForKeyPath:(NSString *)keyPath;

//通过KeyPath来设值
- (void)setValue:(nullable id)value forKeyPath:(NSString *)keyPath;
```

举例：Book类拥有书名name属性以及author，且author类拥有一个address属性。

```
@interface Author : NSObject
@property(strong, nonatomic) NSString* address;
@end

@implementation Author
@end

@interface Book : NSObject
@property(strong, nonatomic) NSString* name;// 书名
@property(strong, nonatomic) Author* author;// 作者
@end

@implementation Book
@end
```

使用时：

```
//  ViewController.m
#import "ViewController.h"
#import "Book.h"

@interface ViewController ()
@end
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    Book *book = [[Book alloc]init];
    [book setValue:@"Hello world" forKey:@"name"]; // 设置值
    NSLog(@"age=%@",[book valueForKey:@"name"]);  // 取值
    
    // keyPath 方式
    [book setValue:@"ShangHai" forKeyPath:@"author.address"]; // 设置值
    NSLog(@"author.address=%@",[book valueForKeyPath:@"author.address"]);//取值
}

@end
```

#### 2、底层执行机制

* [object setValue:@”value” forKey:@”property”] 

1. 存取器(setter方法)匹配：先寻找与setKey同名的方法。找到直接赋值。[self setProperty:@”value”]。
    
2. 实例变量匹配：寻找与key，_isKey，_key，isKey同名的实例变量，直接赋值。property = value或_property = value等。

3. 找不到,就会直接报错 setValue:forUndefinedKey:报找不到的错误。

如果我们想让这个类禁用KVC，那么重写+ (BOOL)accessInstanceVariablesDirectly方法让其返回NO即可，这样的话如果KVC没有找到set:属性名时，会直接用setValue：forUNdefinedKey：方法。

```
+ (BOOL)accessInstanceVariablesDirectly;
//默认返回YES，表示如果没有找到Set<Key>方法的话，会按照_key，_iskey，key，iskey的顺序搜索成员，设置成NO就不这样搜索
```

* [object valueForKey:@”property”]

1. 访问器(getter方法)匹配：先寻找与key，isKey， getKey (实测还有_key)同名的方法。

2. 实例变量匹配：寻找与key， _key，isKey，_isKey同名的实例变量。

3. 如果还没有找到的话，调用valueForUndefinedKey：。

若value值为BOOL或Int等值类型时，KVC可以自动的将数值或结构体型的数据打包或解包成NSNumber或NSValue对象，以达到适配的目的。

~~~
Ps：swift中使用keyPath的方式，但是仅支持struct

struct Book {
    var name:String
}

var book = Book(name: "Swift")
// set
book[keyPath: name] = "swift4"
// get
let valueOfName = book[keyPath:name]

~~~

#### 3、键值验证
在实际开发中我们获取对一些Key的value值有一些特殊的要求。KVC为我们提供了验证Key对应的Value是否可用的方法：

```
- (BOOL)validateValue:(inoutid*)ioValue forKey:(NSString*)inKey error:(outNSError**)outError;
```

这为我们提供了一次纠错的机会。但是，KVC是不会自动调用键值验证方法的，就是说我们如果想要键值验证则需要手动验证。也就是说，需要自己需要验证的类中重写-(BOOL)-validate<Key>:error:，默认返回Yes。

举例：

```
@implementation Book
- (BOOL)validateName:(id *)value error:(out NSError * _Nullable __autoreleasing *)outError{
    NSString* name = *value;
    name = name.capitalizedString;
    if ([name isEqualToString:@"Not-name"]) {
        return NO;
    }
    return YES;
}
@end
- (void)viewDidLoad {
    [super viewDidLoad];
    
    Book *book = [[Book alloc]init];
    NSError* error;
    NSString *value = @"Not-name"; // result 为 NO 
    //NSString *value = @"BookName";  // result 为 YES
    BOOL result = [book validateValue:&value forKey:@"name" error:&error];
    if (result) {
        NSLog(@"OK");
    } else {
        NSLog(@"NO");
    }
}
```

#### 4、不存在的key及nil值处理

* 处理不存在的key值
    
我们可以考虑重写setValue: forUndefinedKey:方法与valueForUndefinedKey:方法

```
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {

    NSLog(@"您设置的key：[%@]不存在", key);
    NSLog(@"您设置的value为：[%@]", value);

}

- (id)valueForUndefinedKey:(NSString *)key {

    NSLog(@"您访问的key:[%@]不存在", key);
    return nil;

}
```

* value为nil的处理

当程序尝试为某个属性设置nil值时，如果该属性并不接受nil值，那么程序将会自动执行该对象的setNilValueForKey:方法。我们同样可以重写这个方法:

```
- (void)setNilValueForKey:(NSString *)key {
    //对不能接受nil的属性进行处理
    if ([key isEqualToString:@"price"]) {
        //对应你具体的业务来处理
        price = 0;
    }else {
        [super setNilValueForKey:key];
    }
}
```

#### 5、一些函数操作
KVC同时还提供了一些较复杂的函数，主要有下面这些：
* 集合运算符
 
目前总共有五个函数：@avg， @count ， @max ， @min ，@sum5

* 对象运算符

共有两个：@distinctUnionOfObjects 及 @unionOfObjects

它们的返回值都是NSArray。两者的区别在于：前者会去除返回值中重复的数据，后者则将数据全部返回。

举例：

```
@interface Book : NSObject
@property(assign, nonatomic) NSInteger price;
@end

@implementation Book
@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    
    Book *book1 = [Book new];
    book1.price = 40;
    Book *book2 = [Book new];
    book2.price = 20;
    Book *book3 = [Book new];
    book3.price = 30;
    Book *book4 = [Book new];
    book4.price = 10;
    // 价格重复的
    Book *book5 = [Book new];
    book5.price = 10;
    
    NSLog(@"----------集合运算符----------");
    NSArray* arr = @[book1,book2,book3,book4];
    
    NSNumber* sum = [arr valueForKeyPath:@"@sum.price"];
    NSLog(@"sum:%f",sum.floatValue);
    
    NSNumber* avg = [arr valueForKeyPath:@"@avg.price"];
    NSLog(@"avg:%f",avg.floatValue);
    
    NSNumber* count = [arr valueForKeyPath:@"@count"];
    NSLog(@"count:%f",count.floatValue);
    
    NSNumber* min = [arr valueForKeyPath:@"@min.price"];
    NSLog(@"min:%f",min.floatValue);
    
    NSNumber* max = [arr valueForKeyPath:@"@max.price"];
    NSLog(@"max:%f",max.floatValue);
    
    NSLog(@"----------对象操作符----------");
    NSArray* arrBooks = @[book1,book2,book3,book4, book5];
    NSLog(@"distinctUnionOfObjects");
    NSArray* arrDistinct = [arrBooks valueForKeyPath:@"@distinctUnionOfObjects.price"];
    for (NSNumber *price in arrDistinct) {
        NSLog(@"%f",price.floatValue);
    }
    NSLog(@"unionOfObjects");
    NSArray* arrUnion = [arrBooks valueForKeyPath:@"@unionOfObjects.price"];
    for (NSNumber *price in arrUnion) {
        NSLog(@"%f",price.floatValue);
    }
}
@end

---输出结果：---
----------集合运算符----------
sum:100.000000
avg:25.000000
count:4.000000
min:10.000000
max:40.000000

----------对象操作符----------
distinctUnionOfObjects
10.000000
20.000000
30.000000
40.000000
unionOfObjects
40.000000
20.000000
30.000000
10.000000
10.000000
```

## 三、实际应用

#### 1、访问私有变量
对于类里的私有属性，Objective-C是无法直接访问的，但是KVC是可以的。

```
@interface Book : NSObject
{
    NSString * owner;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    Book *book = [Book new];
    
    // 这种访问方式，会直接报错。因为owner是私有属性。
    // book.owner = @"tao"; 
    
    // 利用KVC访问到私有变量
    [book setValue:@"tao" forKey:@"owner"];
    NSLog([book valueForKey:@"owner"]); // 输出 tao
}
@end
```

#### 2、修改一些控件的内部属性
在开发中，我们常常需要对一些控件的某些属性做修改，但是很多UI控件都由很多内部UI控件组合而成的，系统并没有提供这访问这些控件的API，这样我们就无法正常地访问和修改这些控件的样式。但是，KVC可以帮我们解决大部分这种类型的问题。
![](https://github.com/CoderJTao/LearningRecord/blob/master/KVC%20Record/Modify_Properties.png)

#### 3、结合Runtime打造字典转model
可以利用KVC和运行时将字典转换为模型。
具体代码可以[我的Github](https://github.com/CoderJTao/BaseModel)上查看。


## 四、总结
上面的几点就是本人对KVC学习的一些记录，如有不妥之处，请大家多多指正。关于KVC更多更详细的资料，大家可以去到官方文档[Key-Value Coding Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueCoding/index.html)查看学习。

