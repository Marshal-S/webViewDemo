//
//  ViewController.m
//  WebViewTest
//
//  Created by Marshal on 2021/4/29.
//

#import "WebViewController.h"
#import "TestWKWebViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebViewJavascriptBridge.h>

@interface WebViewController ()<UIWebViewDelegate>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) WebViewJavascriptBridge *wjb;

@end

@implementation WebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"index.html" withExtension:nil];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    self.webView.delegate = self;
    
    [self.view addSubview:self.webView];
}

//是否加载相应内容，可以在里面进行拦截相关信息
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NSLog(@"%@", request);
    NSURL *url = request.URL; //url
    NSArray *pathComponents = url.pathComponents; //地址集合
    NSString *scheme = url.scheme; //scheme 开头的标识
    if ([scheme isEqualToString:@"marshal"]) {
        //可以设置路由，根据路由响应拦截内容
        //这样就实现了js调用oc方法，传递参数可以写到后面
        //NSLog(@"%@", url.port);
        if ([url.host isEqualToString:@"getSum"]) {
            [self getSum];
        }else if ([url.host isEqualToString:@"getMessage"]) {
            [self getMessage:webView];
        }else if ([url.host isEqualToString:@"enterWk"]) {
            [self enterWKWebView];
        }
        return NO;
    }
    return true;
}

- (void)enterWKWebView {
    TestWKWebViewController *vc = [[TestWKWebViewController alloc] init];
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)getSum {
    NSLog(@"getSum被调用了");
}

- (void)getMessage:(UIWebView *)webView {
    NSLog(@"getMessage被调用了");
    [webView stringByEvaluatingJavaScriptFromString:@"handleMessage()"];
}

//开始加载
- (void)webViewDidStartLoad:(UIWebView *)webView {
    NSLog(@"开始加载");
}

//加载完毕
- (void)webViewDidFinishLoad:(UIWebView *)webView {
    NSLog(@"加载完毕");
//    [self callJSMethod: webView];
    [self callJSMethodByJSCore];
}

//直接调用js中的方法
- (void)callJSMethod:(UIWebView *)webView {
    //获取网页标题
    NSString *naviTitle = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSLog(@"naviTitle : %@", naviTitle);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //直接调用js正申明的showAlert方法，注意：JS中字符串可以用单引号传递字符串，能避免双引号传递字符串的问题
        [webView stringByEvaluatingJavaScriptFromString:@"showAlert('测试')('帅呆了')"];
    });
}

- (void)callJSMethodByJSCore {
    //获取网页标题
    NSString *naviTitle = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    NSLog(@"naviTitle : %@", naviTitle);
    
    //获取js的上下文对象
    JSContext *jsContext = [self.webView valueForKeyPath:@"documentView.webView.mainFrame.javaScriptContext"];
    //根据上下文对象执行js代码，声明数组对象(var变量提升)
    [jsContext evaluateScript:@"var arr = ['帅仔', '靓仔', '酷仔'];"];
    //直接调用js中的方法
//    [jsContext evaluateScript:@"showAlert('测试')('帅呆了')"];
    //桥接js,保存handleMessage函数
    //注意：如果功能不同，不要和js中的方法名字一样，会覆盖js中的方法(这里会覆盖掉js中的showMessage方法)
    jsContext[@"showMessage"] = ^(id value){
        NSLog(@"展示完毕信息了: %@", value);
        //可以查看变量参数
        NSArray *args = [JSContext currentArguments];
        NSLog(@"args = %@",args);
    };
}

//加载失败
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    NSLog(@"加载失败");
}



@end
