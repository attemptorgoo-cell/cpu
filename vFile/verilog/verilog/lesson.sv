//课堂的内容，与项目无关
class className;
//    header h; 这header是个类
    function new();
    endfunction //new()

    function className copy();      
        copy = new();
        copy.address = this.address;//?//
        
    endfunction
endclass //className

className c;//句柄悬空，没有空间，是一个安全的指针
className b;

//如果是b = new c 这样b的h就指向c的h？想干嘛什么copy浅复制，（不会复制空间）
//如果想要里面的也指向空间？

//实例化的是句柄，用new了之后才有空间
c = new();//构造了一个空间，让c去指向

b = c;//把c的地址给了b，这样他们都指向了c
//这个时候c的内存没有句柄指向，会自动回收这个空间

//后面再b= new，b就指向了new，
//但是c的空间不变
b = null;
//b不再指向对象

//当对b的h变化的时候，c的h也会变化？我服啦想干嘛，就是class里面又class，里面那个是指向同一个

d = b.copy();//调用了内部的函数..




//------------------------------------------------------------------------------------------------------
//静态变量与常规变量
class
    static int a = 0;
endclass
全类共享




//封装
local,protected,public          //只需要了解接口
//派生  水果------>香蕉   
//只能父类句柄指向子类句柄
class className extends superClass;
    function new();
        
    endfunction //new()
endclass //className extends superClass
class className extends superClass;
    function new();
        
    endfunction //new()
endclass //className extends superClass


//多态
可以用父类的句柄来引用子类的对象
father = son
水果可以补充维生素c,因为柠檬可以补充。

