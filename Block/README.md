
## 一、概述
闭包 = 一个函数「或指向函数的指针」+ 该函数执行的外部的上下文变量「也就是自由变量」；

Block实质是Objective-C对闭包的对象实现，简单说来，Block就是对象。

## 二、Block的声明

### 1.有参数有返回值
```
int (^CustomBlock1)(int) = ^int (int a) {
        return a + 1;
    };
```

### 2.有参数无返回值
```
void (^CustomBlock)(int) = ^void (int a) {
    NSLog(@"-有参数无返回值--参数：%d", a);
};

// 也可以简写
void (^CustomBlock1)(int) = ^(int a) {
    NSLog(@"-有参数无返回值--参数：%d", a);
};
```

### 3. 无参数有返回值
```
int (^CustomBlock)(void) = ^int(void) {
    return 1;
};
// 也可以简写
int (^CustomBlock1)(void) = ^int {
    return 1;
};
```

### 4. 无参数无返回值
```
void (^CustomBlock)(void) = ^void (void) {
    NSLog(@"-无参数无返回值--");
};
// 也可以简写
void (^CustomBlock1)(void) = ^(void){
    NSLog(@"-无参数无返回值--");
};

```

### 5. 利用 typedef 声明block
```
// 利用 typedef 声明block
typedef return_type (^BlockTypeName)(var_type);

// 例子1：作属性
@property (nonatomic, copy) BlockTypeName blockName;

// 例子2：作方法参数
- (void)requestForSomething:(Model)model handle:(BlockTypeName)handle;
```

## 三、Block捕获变量及对象

### 1、变量的定义
* 全局变量
    * 函数外面声明
    * 可以跨文件访问
    * 可以在声明时赋上初始值。如果没有赋初始值，系统自动赋值为0
    * 存储位置：既非堆，也非栈，而是专门的【全局（静态）存储区static】！
* 静态变量
    * 函数外面或内部声明（即可修饰原全局变量亦可修饰原局部变量）
    * 仅声明该变量的文件可以访问
    * 可以在声明时赋上初始值。如果没有赋初始值，系统自动赋值为0
    * 存储位置：既非堆，也非栈，而是专门的【全局（静态）存储区static】！
* 局部变量（自动变量）
    * 函数内部声明
    * 仅当函数执行时存在
    * 仅在本文件本函数内可访问
    * 存储位置：自动保存在函数的每次执行的【栈帧】中，并随着函数结束后自动释放，另外，函数每次执行则保存在【栈】中
   

### 2、Block捕获变量

将Objective-C 转 C++的方法

> 1、在OC源文件block.m写好代码。
>
> 2、打开终端，cd到block.m所在文件夹。
>
> 3、输入clang -rewrite-objc block.m，就会在当前文件夹内自动生成对应的block.cpp文件。

**OC代码：**

```
int global_val = 10; // 全局变量
static int static_global_val = 20; // 全局静态变量

int main() {
    typedef void (^MyBlock)(void);
    
    static int static_val = 30; // 静态变量
    int val = 40; // 局部变量
    int val_unuse = 50; // 未使用的局部变量
    
    MyBlock block = ^{
        // 捕获局部变量
        NSLog(@"val------------------%d", val);
        // 修改局部变量  -> 代码编译不通过
        //val = 4000;  
        // 全局变量
        global_val *= 10;
        // 全局静态变量
        static_global_val *= 10;
        // 静态变量
        static_val *= 10;
    };
    val *= 10;
    block();
    NSLog(@"global_val-----------%d", global_val);
    NSLog(@"static_global_val----%d", static_global_val);
    NSLog(@"static_val-----------%d", static_val);
}

---输出结果：---
局部变量：     val------------------40
全局变量：     global_val-----------100
全局静态变量： static_global_val----200
静态变量：     static_val-----------300
```
**C++代码：**

```
int global_val = 10;
static int static_global_val = 20;

struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  int *static_val;  // 静态变量  --> 指针
  int val;          // 局部变量  --> 值
  
  // 在构造函数中，也可以看到 static_val、val被传入
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, int *_static_val, int _val, int flags=0) : static_val(_static_val), val(_val) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  int *static_val = __cself->static_val; // bound by copy
  int val = __cself->val; // bound by copy

        global_val *= 10;
        static_global_val *= 10;
        (*static_val) *= 10;
        NSLog((NSString *)&__NSConstantStringImpl__var_folders_8k_cgm28r0d0bz94xnnrr606rf40000gn_T_block_75d081_mi_0, val);
    }

// 纪录了block结构体大小等信息
static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0)};
int main() {
    ...
}
static struct IMAGE_INFO { unsigned version; unsigned flag; } _OBJC_IMAGE_INFO = { 0, 2 };
```

对于 block 外的变量引用，block默认是将其复制到其数据结构中来实现访问的。也就是说block的自动变量截获只针对block内部使用的自动变量,不使用则不截获,因为截获的自动变量会存储于block的结构体内部, 会导致block体积变大（__main_block_desc_0）。特别要注意的是默认情况下block只能访问不能修改局部变量的值。

#### 捕获局部变量
在Block内部使用了其外部变量，这些变量就会被Block保存。自动变量val虽然被捕获进来了，但是是用 __cself->val来访问的。Block仅仅捕获了val的值，并没有捕获val的内存地址。所以，我们在block外部修改了val的值，在block内部并没有效果。

#### 修改局部变量 
代码编译不通过。默认情况下block只能访问不能修改局部变量的值。因为Block仅仅捕获了val的值，并没有捕获val的内存地址，block内部修改值并不会对外部的val生效。可能基于此原因，O这种写法直接编译错误。

#### 修改全局变量&修改全局静态变量
可以直接访问。全局变量和全局静态变量没有被截获到block里面，它们的访问是不经过block的(见__main_block_func_0)
#### 修改静态变量
通过指针访问。访问静态变量（static_val）时，将静态变量的 **指针** 传递给__main_block_impl_0结构体的构造函数并保存。修改静态变量时，是指针操作，所以可以修改其值。

**总结：** 由上述Block的变量捕获机制，可以总结出下图：

变量类型|是否捕获到Block内部|传递方式
---|---|---
局部变量|是|值传递
局部staic变量|是|指针传递
全局变量|否|直接访问

### 3、Block捕获对象

**OC代码：**

```
int main() {
    typedef void (^MyBlock)(void);

    NSMutableArray *arr = [[NSMutableArray alloc]init];
    
    MyBlock block = ^{
        [arr addObject:@1];
    };
    
    block();
    NSLog(@"arr.count------------%d", (int)arr.count);
}
```

**C++代码：**

```
struct __main_block_impl_0 {
  struct __block_impl impl;
  struct __main_block_desc_0* Desc;
  NSMutableArray *arr;    // 数组对象  --> 指针
  __main_block_impl_0(void *fp, struct __main_block_desc_0 *desc, NSMutableArray *_arr, int flags=0) : arr(_arr) {
    impl.isa = &_NSConcreteStackBlock;
    impl.Flags = flags;
    impl.FuncPtr = fp;
    Desc = desc;
  }
};
static void __main_block_func_0(struct __main_block_impl_0 *__cself) {
  NSMutableArray *arr = __cself->arr; // bound by copy

    ((void (*)(id, SEL, ObjectType _Nonnull))(void *)objc_msgSend)((id)arr, sel_registerName("addObject:"), (id _Nonnull)((NSNumber *(*)(Class, SEL, int))(void *)objc_msgSend)(objc_getClass("NSNumber"), sel_registerName("numberWithInt:"), 1));
}
// 相当于retain操作，将对象赋值在对象类型的结构体成员变量中
static void __main_block_copy_0(struct __main_block_impl_0*dst, struct __main_block_impl_0*src) {_Block_object_assign((void*)&dst->arr, (void*)src->arr, 3/*BLOCK_FIELD_IS_OBJECT*/);}

// 当于release操作
static void __main_block_dispose_0(struct __main_block_impl_0*src) {_Block_object_dispose((void*)src->arr, 3/*BLOCK_FIELD_IS_OBJECT*/);}

static struct __main_block_desc_0 {
  size_t reserved;
  size_t Block_size;
  void (*copy)(struct __main_block_impl_0*, struct __main_block_impl_0*);
  void (*dispose)(struct __main_block_impl_0*);
} __main_block_desc_0_DATA = { 0, sizeof(struct __main_block_impl_0), __main_block_copy_0, __main_block_dispose_0};
int main() {
    ...
}
static struct IMAGE_INFO { unsigned version; unsigned flag; } _OBJC_IMAGE_INFO = { 0, 2 };
```
#### 捕获对象
在block中可以修改对象的值，因为捕获对象时，在__main_block_impl_0中可以看到捕获的是指针。
    
    我们可以看到在捕获对象的源码中多了两个函数 __main_block_copy_0 和 __main_block_dispose_0。
    这两个函数涉及到Block的存储域及copy操作，在下一节中会说明。

## 四、三种不同类型的Block
* <font size=2>全局Block（_NSConcreteGlobalBlock）：存在于全局内存中, 生命周期从创建到应用程序结束,相当于单例。</font>
* <font size=2>栈Block（_NSConcreteStackBlock）：存在于栈内存中, 超出其作用域则马上被销毁</font>
* <font size=2>堆Block（_NSConcreteMallocBlock）：存在于堆内存中, 是一个带引用计数的对象, 需要自行管理其内存</font>

#### 1、怎么确定Block的类型？
在上述的源码中，可以看到Block的构造函数__main_block_impl_0中的isa指针指向的是&_NSConcreteStackBlock，它表示当前的Block位于栈区中。

Block类型|是否捕获到Block内部
---|:---:|---:
_NSConcreteGlobalBlock|没有用到外界变量或只用到全局变量、静态变量
_NSConcreteStackBlock|只用到外部局部变量、成员属性变量，且没有强指针引用
_NSConcreteMallocBlock|有强指针引用或copy修饰的成员属性引用的block会被复制一份到堆中成为堆Block

#### 2、全局Block（_NSConcreteGlobalBlock）
全局Block的生成条件：
* 定义全局变量的地方有block语法时
```
void(^block)(void) = ^ { NSLog(@"Global Block");};
int main() {
}
```
* Block不截获的自动变量时
```
int(^block)(int count) = ^(int count) {
        return count;
    };
block(2);
```
#### 3、栈Block（_NSConcreteStackBlock）
在生成Block以后，如果这个Block不是全局Block，那么它就是为_NSConcreteStackBlock对象，但是如果其所属的变量作用域名结束，该block就被废弃。在栈上的__block变量也是如此。



#### 4、堆Block（_NSConcreteMallocBlock）
为了解决栈块在其变量作用域结束之后被废弃（释放）的问题，我们需要把Block复制到堆中，延长其生命周期。开启ARC时，大多数情况下编译器会恰当地进行判断是否有需要将Block从栈复制到堆。



Block的复制操作执行的是copy实例方法。不同类型的Block使用copy方法的效果如下表：

Block类型|存储位置|复制效果
---|:---:|---:
_NSConcreteGlobalBlock|程序的数据区域|什么也不做
_NSConcreteStackBlock|栈区|从栈区复制到堆区
_NSConcreteMallocBlock|堆区|引用计数加一

#### 5、copy和dispose
C结构体里不能含有被__strong修饰的变量，因为编译器不知道应该何时初始化和废弃C结构体。但是OC的运行时库能够准确把握Block从栈复制到堆，以及堆上的block被废弃的时机，在实现上是通过__main_block_copy_0函数和__main_block_dispose_0函数进行的


函数|调用时机
---|:---:|---:
copy|栈上的 Block 复制到堆时
dispose|堆上的 Block 被废弃(释放)时

**那么什么时候栈上的Block会被复制到堆上呢？**

* <font size=2>调用Block的copy实例方法时</font>
* <font size=2>Block作为函数返回值返回时</font>
* <font size=2>将Block赋值给附有__strong修饰符id类型的类或Block类型成员变量时</font>
* <font size=2>将方法名中含有usingBlock的Cocoa框架方法或GCD的API中传递Block时</font>

## 五、Block循环引用
如果在Block内部使用__strong修饰符的对象类型的自动变量，那么当Block从栈复制到堆的时候，该对象就会被Block所持有。

```
// self 持有 someBlock 对象
self.someBlock = ^(Type var){
    // 在Block内部，持有self
    [self dosomething];
};
```
#### 解决方式：
* 使用 __weak

```
// weakSelf 对 self进行弱引用
__weak typeof(self) weakSelf = self;

// self 持有 someBlock 对象
self.someBlock = ^(Type var){

    // 在Block内部，持有weakSelf
   [weakSelf dosomething];
};
```

* 使用__block

```
- (instancetype)init {
    self = [super init];
    
    __block id blockSelf = self;  // blockSelf 持有 self
    
    //self持有someBlock
    someBlock = ^{
        NSLog(@"self = %@",blockSelf); //someBlock持有blockSelf
        blockSelf = nil;
    };
    return self;
}

- (void)doSomething() {
    someBlock();
}
```
此时，blockSelf 持有 self， self 持有someBlock， 而someBlock持有blockSelf。此时，三者形成了一个循环。如果doSomething不执行，blockSelf不能置为nil，则无法打破这个循环。


一旦执行了doSomething，则循环被打破，对象也就可以被释放。
