//
//  ReportViewController.m
//  MAPLocation
//
//  Created by 魏唯隆 on 2019/4/8.
//  Copyright © 2019 魏唯隆. All rights reserved.
//

#import "ReportViewController.h"

#import <AMapTrackKit/AMapTrackKit.h>
#import <MAMapKit/MAMapKit.h>

@interface ReportViewController ()<AMapTrackManagerDelegate, MAMapViewDelegate>

@property (nonatomic, strong) AMapTrackManager *trackManager;
@property (nonatomic, strong) MAMapView *mapView;
@end

@implementation ReportViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initMapView];
    [self setupReport];
}

- (void)setupReport {
    AMapTrackManagerOptions *option = [[AMapTrackManagerOptions alloc] init];
    option.serviceID = kAMapTrackServiceID;
    
    //初始化AMapTrackManager
    self.trackManager = [[AMapTrackManager alloc] initWithOptions:option];
    self.trackManager.delegate = self;
    
    // 配置猎鹰SDK
    [self.trackManager setAllowsBackgroundLocationUpdates:YES];
    [self.trackManager setPausesLocationUpdatesAutomatically:NO];
    /**
     定位信息的采集周期，单位秒，有效值范围[1, 60]。
     定位信息的上传周期，单位秒，有效值范围[5, 3000]
     */
    [self.trackManager changeGatherAndPackTimeInterval:2 packTimeInterval:2];
    // 配置本地缓存大小,默认最多缓存50MB数据
    [self.trackManager setLocalCacheMaxSize:50];
}
- (void)initMapView {
    if (self.mapView == nil) {
        self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, KScreenHeight)];
        [self.mapView setDelegate:self];
        [self.mapView setZoomLevel:13.0];
        [self.mapView setShowsUserLocation:YES];
        [self.mapView setUserTrackingMode:MAUserTrackingModeFollow];
        
        [self.view insertSubview:self.mapView atIndex:0];
    }
}

- (IBAction)reprotLocation:(UIButton *)sender {
    sender.selected = !sender.selected;
    
    if(sender.selected){
        //开始服务
        AMapTrackManagerServiceOption *serviceOption = [[AMapTrackManagerServiceOption alloc] init];
        serviceOption.terminalID = kAMapTrackTerminalID;
        
        [self.trackManager startServiceWithOptions:serviceOption];
    }else {
        [self.trackManager stopService];
    }
}
//service 开启结果回调
- (void)onStartService:(AMapTrackErrorCode)errorCode {
    if (errorCode == AMapTrackErrorOK) {
        //开始服务成功，继续开启收集上报
        [self.trackManager startGatherAndPack];
    } else {
        //开始服务失败
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.label.text = @"开始服务失败";
        [hud hideAnimated:YES afterDelay:1];
    }
}

//gather 开启结果回调
- (void)onStartGatherAndPack:(AMapTrackErrorCode)errorCode {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    if (errorCode == AMapTrackErrorOK) {
        //开始采集成功
        hud.label.text = @"开始采集成功";
    } else {
        //开始采集失败
        hud.label.text = @"开始采集失败";
    }
    [hud hideAnimated:YES afterDelay:1];
}

@end
