//
//  CommontWebViewController.m
//  WebViewTest
//
//  Created by Marshal on 2021/5/8.
//

#import "CommontWebViewController.h"
#import <WebKit/WebKit.h>
#import <WebViewJavascriptBridge/WebViewJavascriptBridge.h>

@interface CommontWebViewController ()<UIWebViewDelegate, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>

@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) WKWebView *wkWebView;

@property (nonatomic, strong) WebViewJavascriptBridge *wjb;

@end

@implementation CommontWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initUIWebView];
//    [self initWKWebView];
    
    self.wjb = [WebViewJavascriptBridge bridgeForWebView:self.webView];
    // 如果你要在VC中实现UIWebView的代理方法,就设置代理，否则省略
    [self.wjb setWebViewDelegate:self];
    
    [self.wjb registerHandler:@"jsCallsOC" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"data == %@ -- %@",data,responseCallback);
    }];
}

- (void)initUIWebView {
    self.webView = [[UIWebView alloc] initWithFrame:self.view.frame];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"index.html" withExtension:nil];
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    
    self.webView.delegate = self;
}

- (void)initWKWebView {
    NSString *jScript = @"var meta = document.createElement('meta'); meta.setAttribute('name', 'viewport'); meta.setAttribute('content', 'width=device-width'); document.getElementsByTagName('head')[0].appendChild(meta);";
    WKUserScript *wkUScript = [[WKUserScript alloc] initWithSource:jScript injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
    WKUserContentController *wkUController = [[WKUserContentController alloc] init];
    [wkUController addUserScript:wkUScript];
    
    WKWebViewConfiguration *wkWebConfig = [[WKWebViewConfiguration alloc] init];
    wkWebConfig.userContentController = wkUController;
    
    _wkWebView = [[WKWebView alloc]initWithFrame:self.view.frame configuration:wkWebConfig];
    _wkWebView.UIDelegate = self;
    _wkWebView.navigationDelegate = self;
    _wkWebView.allowsBackForwardNavigationGestures = YES;
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"index.html" withExtension:nil];
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:15];
    [_wkWebView loadRequest:request];
    
    [self.view addSubview:_wkWebView];
}

//设置给js调用的handler,方便调用
- (void)registerJShandle {
    [self.wjb registerHandler:@"jsCallsOC" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"data == %@ -- %@",data,responseCallback);
        responseCallback(@"测试数据"); //回调数据response
    }];
    [self.wjb registerHandler:@"jsCallsOC1" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"data == %@ -- %@",data,responseCallback);
        responseCallback(@"测试数据"); //回调数据response
    }];
}

- (void)callJSHandle {
    [self.wjb callHandler:@"OCCallJS" data:@"测试数据哈" responseCallback:^(id responseData) {
        NSLog(@"responseData == %@",responseData);
    }];
    [self.wjb callHandler:@"OCCallJS1" data:@"测试数据哈" responseCallback:^(id responseData) {
        NSLog(@"responseData == %@",responseData);
    }];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
