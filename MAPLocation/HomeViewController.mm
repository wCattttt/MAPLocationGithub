//
//  HomeViewController.m
//  MAPLocation
//
//  Created by 魏唯隆 on 2019/4/8.
//  Copyright © 2019 魏唯隆. All rights reserved.
//

#import "HomeViewController.h"
#import <AMapTrackKit/AMapTrackKit.h>
#import <MAMapKit/MAMapKit.h>

@interface HomeViewController ()<AMapTrackManagerDelegate>
{
    __weak IBOutlet UILabel *_msgLabel;
}
@property (nonatomic, strong) AMapTrackManager *trackManager;
@end

@implementation HomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setupTrack];
}

- (void)setupTrack {
    AMapTrackManagerOptions *option = [[AMapTrackManagerOptions alloc] init];
    option.serviceID = kAMapTrackServiceID;
    //初始化AMapTrackManager
    self.trackManager = [[AMapTrackManager alloc] initWithOptions:option];
    self.trackManager.delegate = self;
    
    //查询终端是否存在
    AMapTrackQueryTerminalRequest *request = [[AMapTrackQueryTerminalRequest alloc] init];
    request.serviceID = self.trackManager.serviceID;
    request.terminalName = [self saveDeviceModel];
    [self.trackManager AMapTrackQueryTerminal:request];
}

//查询终端结果
- (void)onQueryTerminalDone:(AMapTrackQueryTerminalRequest *)request response:(AMapTrackQueryTerminalResponse *)response
{
    //查询成功
    if ([[response terminals] count] > 0) {
        //查询到结果，使用 Terminal ID
        NSString *terminalID = [[[response terminals] firstObject] tid];
        [self saveTerminalId:terminalID];
        //启动上报服务(service id)，参考下一步
    }
    else {
        //查询结果为空，创建新的terminal
        AMapTrackAddTerminalRequest *addRequest = [[AMapTrackAddTerminalRequest alloc] init];
        addRequest.serviceID = self.trackManager.serviceID;
        addRequest.terminalName = [self saveDeviceModel];
        [self.trackManager AMapTrackAddTerminal:addRequest];
    }
}

//创建终端结果
- (void)onAddTerminalDone:(AMapTrackAddTerminalRequest *)request response:(AMapTrackAddTerminalResponse *)response {
    //创建terminal成功
    NSString *terminalID = [response terminalID];
    [self saveTerminalId:terminalID];
    //启动上报服务(service id)，参考下一步
}

//错误回调
- (void)didFailWithError:(NSError *)error associatedRequest:(id)request {
    if ([request isKindOfClass:[AMapTrackQueryTerminalRequest class]]) {
        //查询参数错误
    }
    
    if ([request isKindOfClass:[AMapTrackAddTerminalRequest class]]) {
        //创建terminal失败
    }
    NSLog(@"%@", error);
    
    _msgLabel.text = [NSString stringWithFormat:@"初始化失败"];
}

- (void)saveTerminalId:(NSString *)terminalId {
    [[NSUserDefaults standardUserDefaults] setObject:terminalId forKey:@"terminalId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    _msgLabel.text = [NSString stringWithFormat:@"初始化成功：设备terminalId: %@", terminalId];
}

#pragma mark 获取设备名字
- (NSString *)saveDeviceModel {
    UIDevice *device = [[UIDevice alloc] init];
    NSString *name = device.name;
#warning 根据业务需要改为对应名字
//    return name;  // 设备名可能存在不符合参数格式规范
    return @"myTerminalId";
}

@end
