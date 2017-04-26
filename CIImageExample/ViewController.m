//
//  ViewController.m
//  CIImageExample
//
//  Created by IYNMac on 28/3/17.
//  Copyright © 2017年 IYNMac. All rights reserved.
//

#import "ViewController.h"
#import <CoreImage/CIDetector.h>
#import "MFMessageViewController.h"
#import "GLEView.h"

static void HSLToRGB(float h, float s, float l, float* outR, float* outG, float* outB)
{
    float			temp1,
    temp2;
    float			temp[3];
    int				i;
    
    // Check for saturation. If there isn't any just return the luminance value for each, which results in gray.
    if(s == 0.0) {
        if(outR)
            *outR = l;
        if(outG)
            *outG = l;
        if(outB)
            *outB = l;
        return;
    }
    
    // Test for luminance and compute temporary values based on luminance and saturation
    if(l < 0.5)
        temp2 = l * (1.0 + s);
    else
        temp2 = l + s - l * s;
    temp1 = 2.0 * l - temp2;
    
    // Compute intermediate values based on hue
    temp[0] = h + 1.0 / 3.0;
    temp[1] = h;
    temp[2] = h - 1.0 / 3.0;
    
    for(i = 0; i < 3; ++i) {
        
        // Adjust the range
        if(temp[i] < 0.0)
            temp[i] += 1.0;
        if(temp[i] > 1.0)
            temp[i] -= 1.0;
        
        
        if(6.0 * temp[i] < 1.0)
            temp[i] = temp1 + (temp2 - temp1) * 6.0 * temp[i];
        else {
            if(2.0 * temp[i] < 1.0)
                temp[i] = temp2;
            else {
                if(3.0 * temp[i] < 2.0)
                    temp[i] = temp1 + (temp2 - temp1) * ((2.0 / 3.0) - temp[i]) * 6.0;
                else
                    temp[i] = temp1;
            }
        }
    }
    
    // Assign temporary values to R, G, B
    if(outR)
        *outR = temp[0];
    if(outG)
        *outG = temp[1];
    if(outB)
        *outB = temp[2];
}


static void RGBToHSL(float r, float g, float b, float* outH, float* outS, float* outL)
{
    r = r/255.0f;
    g = g/255.0f;
    b = b/255.0f;
    
    
    float h,s, l, v, m, vm, r2, g2, b2;
    
    h = 0;
    s = 0;
    l = 0;
    
    v = MAX(r, g);
    v = MAX(v, b);
    m = MIN(r, g);
    m = MIN(m, b);
    
    l = (m+v)/2.0f;
    
    if (l <= 0.0){
        if(outH)
            *outH = h;
        if(outS)
            *outS = s;
        if(outL)
            *outL = l;
        return;
    }
    
    vm = v - m;
    s = vm;
    
    if (s > 0.0f){
        s/= (l <= 0.5f) ? (v + m) : (2.0 - v - m);
    }else{
        if(outH)
            *outH = h;
        if(outS)
            *outS = s;
        if(outL)
            *outL = l;
        return;
    }
    
    r2 = (v - r)/vm;
    g2 = (v - g)/vm;
    b2 = (v - b)/vm;
    
    if (r == v){
        h = (g == m ? 5.0f + b2 : 1.0f - g2);
    }else if (g == v){
        h = (b == m ? 1.0f + r2 : 3.0 - b2);
    }else{
        h = (r == m ? 3.0f + g2 : 5.0f - r2);
    }
    
    h/=6.0f;
    
    if(outH)
        *outH = h;
    if(outS)
        *outS = s;
    if(outL)
        *outL = l;
    
}

@interface ViewController ()

@end

@implementation ViewController{
    
    GLEView *gl_view;
}

// frame duration is 50ms
- (void)createFaceDetectorWithImage:(CIImage *)image{
    
    CIContext *context = [CIContext context];
    NSDictionary *options = @{CIDetectorAccuracy : CIDetectorAccuracyLow};
    
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                              context:context
                                              options:options];
    
    //NSLog(@"properties = %@",image.properties);
    //options = @{CIDetectorImageOrientation : [image.properties[kCGImagePropertyOrientation]]};
    
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

- (CIImage *)outputImageFromInputImage:(CIImage *)inputImage
{
    CIFilter *filter = [CIFilter filterWithName:@"CIColorMatrix"
                            withInputParameters: @{
                                                   kCIInputImageKey: inputImage,
                                                   @"inputRVector": [CIVector vectorWithX:-1 Y:0 Z:0],
                                                   @"inputGVector": [CIVector vectorWithX:0 Y:-1 Z:0],
                                                   @"inputBVector": [CIVector vectorWithX:0 Y:0 Z:-1],
                                                   @"inputBiasVector": [CIVector vectorWithX:1 Y:1 Z:1],
                                                   }];
    return filter.outputImage;
}

#define minHueAngle 0
#define maxHueAngle 360

- (CIFilter *)colorCube{
    
    // Allocate memory
    const unsigned int size = 64;
    NSInteger cubeDataSize = (size * size * size * sizeof (float) * 4);
    float *cubeData = (float *)malloc (cubeDataSize);
    float rgb[3], hsv[3], *c = cubeData;
    
    // Populate cube with a simple gradient going from 0 to 1
    for (int z = 0; z < size; z++){
        rgb[2] = ((double)z)/(size-1); // Blue value
        for (int y = 0; y < size; y++){
            rgb[1] = ((double)y)/(size-1); // Green value
            for (int x = 0; x < size; x ++){
                rgb[0] = ((double)x)/(size-1); // Red value
                // Convert RGB to HSV
                // You can find publicly available rgbToHSV functions on the Internet
                RGBToHSL(rgb[0], rgb[1], rgb[2], &hsv[0], &hsv[1], &hsv[2]);
                // Use the hue value to determine which to make transparent
                // The minimum and maximum hue angle depends on
                // the color you want to remove
                float alpha = (hsv[0] > minHueAngle && hsv[0] < maxHueAngle) ? 0.0f: 1.0f;
                // Calculate premultiplied alpha values for the cube
                c[0] = rgb[0] * alpha;
                c[1] = rgb[1] * alpha;
                c[2] = rgb[2] * alpha;
                c[3] = alpha;
                c += 4; // advance our pointer into memory for the next color value
            }
        }
    }
    // Create memory with the cube data
    NSData *data = [NSData dataWithBytesNoCopy:cubeData length:cubeDataSize freeWhenDone:YES];
    CIFilter *colorCube = [CIFilter filterWithName:@"CIColorCube"];
    [colorCube setValue:@(size) forKey:@"inputCubeDimension"];
    // Set data for cube
    [colorCube setValue:data forKey:@"inputCubeData"];

    return colorCube;
}

- (void)imageChanged:(NSTimer *)timer{
    
    NSArray *titls = @[@"lizi.png",@"images-2.jpeg",@"erweima.png"];
    
    @synchronized (self) {
        
        [gl_view processImage:[UIImage imageNamed:titls[rand()%3]]];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    gl_view = [[GLEView alloc] initWithFrame:self.view.frame];
    gl_view.contentScaleFactor = [UIScreen mainScreen].scale;
    self.view = gl_view;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(imageChanged:) userInfo:nil repeats:YES];
    });

    return;
    
    
    [self.navigationController pushViewController:[[MFMessageViewController alloc] init] animated:YES];
    return;
    
    UIImage *image = [UIImage imageNamed:@"lizi.png"];
    UIImage *outImage = [UIImage imageWithCIImage:[self outputImageFromInputImage:[CIImage imageWithCGImage:image.CGImage]]];
    NSLog(@"outImage = %@",outImage);
    
    UIImage *image2 = [UIImage imageNamed:@"images-2.jpeg"];
    CIFilter *cube = [self colorCube];
    [cube setValue:[CIImage imageWithCGImage:image2.CGImage] forKey:kCIInputImageKey];
    CIImage *result = [cube valueForKey:kCIOutputImageKey];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageWithCIImage:result]];
    
    [self createFaceDetectorWithImage:[CIImage imageWithCGImage:image.CGImage]];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        UIView * view = [[[UIApplication sharedApplication] keyWindow] snapshotViewAfterScreenUpdates:YES];
        UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0.0);
        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        self.view.backgroundColor = [UIColor colorWithPatternImage:newImage];
        NSLog(@"newImage = %@",newImage);
    });
}

/* 1. 直播中，给主播定制表情包，生成gif图像 */
/* 2. 直播中，可将页面生成表情+文字的主播画像 */

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
