//
//  TestWKWebViewController.m
//  WebViewTest
//
//  Created by Marshal on 2021/5/6.
//

#import "TestWKWebViewController.h"
#import <WebKit/WebKit.h>

@interface TestWKWebViewController ()<WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) WKWebView *wkWebView;

@end

@implementation TestWKWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    //不加上webView显示大小有问题
    NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];
    
    WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
    wkWebConfig.userContentController = wkUController;
    
    _wkWebView = [[WKWebView alloc]initWithFrame:self.view.frame configuration:wkWebConfig];
    _wkWebView.UIDelegate = self;
    _wkWebView.navigationDelegate = self;
    //使用kvo监听进度
//    [_wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:nil];
    //手势触摸滑动
    _wkWebView.allowsBackForwardNavigationGestures = YES;
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"index.html" withExtension:nil];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
    [_wkWebView loadRequest:request];
    
    [self.view addSubview:_wkWebView];
    
    UIControl *control = [[UIControl alloc] initWithFrame:CGRectMake(0, 300, 100, 100)];
    control.backgroundColor = [UIColor redColor];
    [control addTarget:self action:@selector(onClickToAlert) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:control];
    
    //注册一部分脚本，给当前网页声明变量
    [self.wkWebView evaluateJavaScript:@"var arr = ['帅仔', '靓仔', '酷仔'];" completionHandler:^(id _Nullable returnObject, NSError * _Nullable error) {
        //returnObject 返回值内容
        if (error) {
            NSLog(@"%@", error.localizedDescription); //错误信息
        }
    }];
}

- (void)onClickToAlert {
    [self.wkWebView evaluateJavaScript:@"showAlert('你真的')('帅呆了')" completionHandler:^(id _Nullable returnObject, NSError * _Nullable error) {
        //returnObject 返回值内容
        if (error) {
            NSLog(@"%@", error.localizedDescription); //错误信息
        }
    }];
    
    //下面是测试调用messageHandle方法回调handle中的内容
    //[self.wkWebView evaluateJavaScript:@"messageHandle()" completionHandler:nil];
}


#pragma mark --WKUIDelegate
//可以更改wkWebview里面默认的弹窗，不设置代理，会弹不出来alert
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提醒" message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }]];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    //添加handler
    [self.wkWebView.configuration.userContentController addScriptMessageHandler:self name:@"OCHandleMessage"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    //移除handler，不移除会内存泄露，可以找一个合适的时机直接移除掉handle
    [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:@"OCHandleMessage"];
}

#pragma mark --WKScriptMessageHandler
//可以在这里接收js通过handle传递过来的数据
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
//    NSLog(@"%@ -- %@", message.name, message.body);
    //如果执行完毕要反馈可以反调用js中的方法
    [self.wkWebView evaluateJavaScript:@"showMessage()" completionHandler:^(id _Nullable returnObject, NSError * _Nullable error) {
            
    }];
}


#pragma mark - WKNavigationDelegate
////请求之前，决定是否要跳转:用户点击网页上的链接，需要打开新页面时，将先调用这个方法，跟webView的拦截一样
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = navigationAction.request.URL; //url
    NSArray *pathComponents = url.pathComponents; //地址集合
    NSString *scheme = url.scheme; //scheme 开头的标识
    if ([scheme isEqualToString:@"marshal"]) {
        //可以设置路由，根据路由响应拦截内容
        //这样就实现了js调用oc方法，传递参数可以写到后面
        //NSLog(@"%@", url.port);
        if ([url.host isEqualToString:@"getSum"]) {
            [self getSum];
        }else if ([url.host isEqualToString:@"getMessage"]) {
            
        }else if ([url.host isEqualToString:@"enterWk"]) {
            
        }
        decisionHandler(WKNavigationActionPolicyCancel);
    }else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

- (void)getSum {
    NSLog(@"getSum被调用了");
}

//下面的根据使用可以调用
//接收到相应数据后，决定是否跳转
//- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler;
////页面开始加载时调用
//- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
//// 主机地址被重定向时调用
//- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(null_unspecified WKNavigation *)navigation;
//// 页面加载失败时调用
//- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
//// 当内容开始返回时调用
//- (void)webView:(WKWebView *)webView didCommitNavigation:(null_unspecified WKNavigation *)navigation;
//// 页面加载完毕时调用
//- (void)webView:(WKWebView *)webView didFinishNavigation:(null_unspecified WKNavigation *)navigation;
////跳转失败时调用
//- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error;
//// 如果需要证书验证，与使用AFN进行HTTPS证书验证是一样的
//- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler;
////9.0才能使用，web内容处理中断时会触发
//- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView NS_AVAILABLE(10_11, 9_0);

@end
