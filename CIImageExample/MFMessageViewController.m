//
//  MFMessageViewController.m
//  CIImageExample
//
//  Created by IYNMac on 14/4/17.
//  Copyright © 2017年 IYNMac. All rights reserved.
//

#import "MFMessageViewController.h"
#import <AVFoundation/AVFoundation.h>

const float kTimedDifference = 0.5; // unit is s

@interface MFMessageViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>

@property (strong, nonatomic) AVCaptureSession  *session;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoOutput;
@property (strong, nonatomic) AVCaptureAudioDataOutput *audioOutput;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) AVCaptureConnection *videoConnection;
@property (strong, nonatomic) AVCaptureConnection *audioConnection;

@end

@implementation MFMessageViewController{
    
    dispatch_queue_t _videoQueue, _audioQueue;
    unsigned long int currentTime;
}

- (void)messageCompose{
    
    
}

- (void)captureSessionConfigure{
    
    // 初始化 AVCaptureSession
    _session = [[AVCaptureSession alloc] init];
    
    // 配置采集输入源（摄像头）
    NSError *error = nil;
    
    // 获得一个采集设备，例如前置/后置摄像头
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    /*videoDevice = [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInDualCamera
                                                     mediaType:AVMediaTypeVideo
                                                      position:AVCaptureDevicePositionFront];*/
    AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    
    // 用设备初始化一个采集的输入对象
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    if (error) {
        NSLog(@"Error getting video input device: %@", error.description);
    }
    if ([_session canAddInput:videoInput]) {
        [_session addInput:videoInput]; // 添加到Session
    }
    
    AVCaptureDeviceInput *audioInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
    if (error) {
        NSLog(@"Error getting audio input device: %@", error.description);
    }
    if ([_session canAddInput:audioInput]) {
        [_session addInput:audioInput]; // 添加到Session
    }
    
    // 配置采集输出，即我们取得视频图像的接口
    _videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    
    // 配置输出视频图像格式
    NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    
    _videoOutput.videoSettings = captureSettings;
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];  // 添加到Session
    }
    
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    if ([_session canAddOutput:_audioOutput]) {
        [_session addOutput:_audioOutput];  // 添加到Session
    }
    
    // 保存Connection，用于在SampleBufferDelegate中判断数据来源（是Video/Audio？）
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
    _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    // 设置预览时的视频缩放方式
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    // 设置视频的朝向
    [[_previewLayer connection] setVideoOrientation:AVCaptureVideoOrientationPortrait];
    
    _previewLayer.frame = self.view.layer.bounds;
    [self.view.layer addSublayer:_previewLayer];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
    // 这里的sampleBuffer就是采集到的数据了，但它是Video还是Audio的数据，得根据connection来判断
    if (connection == _videoConnection) {  // Video

        CMTime time = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        
        void * baseAddress = CVPixelBufferGetBaseAddressOfPlane(imageBuffer,0);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef quartzImage = CGBitmapContextCreateImage(context);
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        
        int value = abs((int) (currentTime - time.value/time.timescale));
        
        if (value >= kTimedDifference) {
            
            [self createFaceDetectorWithImage:[CIImage imageWithCGImage:quartzImage]];
            currentTime = time.value/time.timescale;
            NSLog(@"presentation timestamp  value = %.2f",(float)time.value/time.timescale);
        }
        
        CGImageRelease(quartzImage);
        
    } else if (connection == _audioConnection) {  // Audio
        
        //NSLog(@"这里获得audio sampleBuffer，做进一步处理（编码AAC）");
    }
}

- (void)createFaceDetectorWithImage:(CIImage *)image{
    
    CIContext *context = [CIContext context];
    NSDictionary *options = @{CIDetectorAccuracy : CIDetectorAccuracyHigh};
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:options];

    NSArray *features = [detector featuresInImage:image options:NULL];
    for (CIFaceFeature *f in features){
        
        NSLog(@"%@",NSStringFromCGRect(f.bounds));
        
        if (f.hasLeftEyePosition) {
            //NSLog(@"Left eye %g %g", f.leftEyePosition.x, f.leftEyePosition.y);
        }
        if (f.hasRightEyePosition) {
            //NSLog(@"Right eye %g %g", f.rightEyePosition.x, f.rightEyePosition.y);
        }
        if (f.hasMouthPosition) {
            //NSLog(@"Mouth %g %g", f.mouthPosition.x, f.mouthPosition.y);
        }
    }
}


- (void)switchCameraTapped:(id)sender{
    
    //Change camera source
    if (!_session) return;
    
    [_session beginConfiguration];
    
    AVCaptureDeviceInput *currentCameraInput;
    
    // Remove current (video) input
    for (AVCaptureDeviceInput *input in _session.inputs) {
        if ([input.device hasMediaType:AVMediaTypeVideo]) {
            [_session removeInput:input];
            
            currentCameraInput = input;
            break;
        }
    }
    
    if (!currentCameraInput) return;
    
    // Switch device position
    AVCaptureDevicePosition captureDevicePosition = AVCaptureDevicePositionUnspecified;
    if (currentCameraInput.device.position == AVCaptureDevicePositionBack) {
        captureDevicePosition = AVCaptureDevicePositionFront;
    } else {
        captureDevicePosition = AVCaptureDevicePositionBack;
    }
    
    // Select new camera
    AVCaptureDevice *newCamera;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    
    for (AVCaptureDevice *captureDevice in devices) {
        if (captureDevice.position == captureDevicePosition) {
            newCamera = captureDevice;
        }
    }
    
    if (!newCamera) return;
    
    // Add new camera input
    NSError *error;
    AVCaptureDeviceInput *newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:newCamera error:&error];
    if (!error && [_session canAddInput:newVideoInput]) {
        [_session addInput:newVideoInput];
    }
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    [_session commitConfiguration];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self captureSessionConfigure];
    
    // 启动 Session
    [_session startRunning];
    
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"switch"
                                                                  style:UIBarButtonItemStyleDone
                                                                 target:self
                                                                 action:@selector(switchCameraTapped:)];
    self.navigationItem.rightBarButtonItem = rightItem;
}

- (void)viewWillLayoutSubviews{
    
    [super viewWillLayoutSubviews];
    
    _previewLayer.frame = self.view.layer.bounds;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
