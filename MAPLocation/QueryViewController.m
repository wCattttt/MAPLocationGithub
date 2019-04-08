//
//  QueryViewController.m
//  MAPLocation
//
//  Created by 魏唯隆 on 2019/4/8.
//  Copyright © 2019 魏唯隆. All rights reserved.
//

#import "QueryViewController.h"

#import <AMapTrackKit/AMapTrackKit.h>
#import <MAMapKit/MAMapKit.h>

@interface QueryViewController ()<AMapTrackManagerDelegate, MAMapViewDelegate>
{
    NSMutableArray *_annotationData;
    BOOL _isLoction;
}
@property (nonatomic, strong) AMapTrackManager *trackManager;
@property (nonatomic, strong) MAMapView *mapView;

@end

@implementation QueryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _isLoction = NO;
    
    [self initMapView];
    [self setupReport];
    
    [self setupAnnotation];
}

- (void)setupReport {
    AMapTrackManagerOptions *option = [[AMapTrackManagerOptions alloc] init];
    option.serviceID = kAMapTrackServiceID;
    
    //初始化AMapTrackManager
    self.trackManager = [[AMapTrackManager alloc] initWithOptions:option];
    self.trackManager.delegate = self;
    
#warning 可添加多个
    AMapTrackQueryLastPointRequest *request = [[AMapTrackQueryLastPointRequest alloc] init];
    request.serviceID = self.trackManager.serviceID;
    request.terminalID = kAMapTrackTerminalID;
    // 纠偏
//    request.correctionMode = @"denoise=1,mapmatch=1,threshold=0,mode=driving";
    [self.trackManager AMapTrackQueryLastPoint:request];
    
    AMapTrackQueryLastPointRequest *request2 = [[AMapTrackQueryLastPointRequest alloc] init];
    request2.serviceID = self.trackManager.serviceID;
    request2.terminalID = @"";
    /// 指定对应terminalID，调用下面方法即可添加多个实时轨迹
//    [self.trackManager AMapTrackQueryLastPoint:request2];
}

- (void)initMapView {
    if (self.mapView == nil) {
        self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, KScreenWidth, KScreenHeight)];
        [self.mapView setDelegate:self];
        [self.mapView setZoomLevel:13.0];
        [self.mapView setRotateEnabled:NO];
        [self.mapView setShowsUserLocation:NO];
//        [self.mapView setUserTrackingMode:MAUserTrackingModeFollow];
        
        [self.view insertSubview:self.mapView atIndex:0];
    }
}

- (void)setupAnnotation {
    _annotationData = @[].mutableCopy;
    
#warning 设置多个时，数组中添加TerminalID
    NSArray *annotations = @[kAMapTrackTerminalID];
    [annotations enumerateObjectsUsingBlock:^(NSString *annotationTitle, NSUInteger idx, BOOL * _Nonnull stop) {
        MAAnimatedAnnotation *anno = [[MAAnimatedAnnotation alloc] init];
        anno.title = annotationTitle;
        [_annotationData addObject:anno];
    }];
    [self.mapView addAnnotations:_annotationData];
}

#pragma mark 查询实时位置回调
- (void)onQueryLastPointDone:(AMapTrackQueryLastPointRequest *)request response:(AMapTrackQueryLastPointResponse *)response {
    //查询成功
    NSLog(@"onQueryLastPointDone%@", response.formattedDescription);
    
    if(!_isLoction){
        self.mapView.centerCoordinate = response.lastPoint.coordinate;
        _isLoction = YES;
    }
    
    AMapTrackPoint *lastPoint = response.lastPoint;
    CLLocationCoordinate2D *coordinate = malloc(sizeof(CLLocationCoordinate2D));
    CLLocationCoordinate2D *point = &coordinate[0];
    point->latitude = lastPoint.coordinate.latitude;
    point->longitude = lastPoint.coordinate.longitude;
    
    __block MAAnimatedAnnotation *anno;
    [_annotationData enumerateObjectsUsingBlock:^(MAAnimatedAnnotation *annotation, NSUInteger idx, BOOL * _Nonnull stop) {
        if([annotation.title isEqualToString:request.terminalID]){
            anno = annotation;
        }
    }];
    anno.movingDirection = lastPoint.direction;
    
    [anno addMoveAnimationWithKeyCoordinates:coordinate count:1 withDuration:1 withName:anno.title completeCallback:^(BOOL isFinished) {
        if(isFinished){
            [self.trackManager AMapTrackQueryLastPoint:request];
        }
    }];
    
}

- (void)didFailWithError:(NSError *)error associatedRequest:(id)request {
    if ([request isKindOfClass:[AMapTrackQueryLastPointRequest class]]) {
        //查询失败
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.label.text = @"查询失败";
        [hud hideAnimated:YES afterDelay:1];
    }
}

#pragma mark MapView协议设置标注样式
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation {
    NSLog(@"%@", annotation.title);
    if ([annotation isKindOfClass:[MAPointAnnotation class]]) {
        static NSString *pointReuseIndentifier = @"pointReuseIndentifier";
        MAPinAnnotationView *annotationView = (MAPinAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:pointReuseIndentifier];
        if (annotationView == nil)
        {
            annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:pointReuseIndentifier];
        }
        //设置气泡可以弹出，默认为NO
        annotationView.canShowCallout= YES;
        //设置标注动画显示，默认为NO
        annotationView.animatesDrop = YES;
        //设置标注可以拖动，默认为NO
        annotationView.draggable = YES;
        annotationView.pinColor = MAPinAnnotationColorPurple;
        annotationView.image = [UIImage imageNamed:@"car"];
        return annotationView;
    }
    return nil;
}

@end
