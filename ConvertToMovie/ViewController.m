//
//  ViewController.m
//  ConvertToMovie
//
//  Created by Takaaki Kakinuma on 2012/12/04.
//  Copyright (c) 2012年 Takaaki Kakinuma. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
{
    NSArray *testImageArray;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake(0, 0, 80, 80);
    [button addTarget:self action:@selector(pushButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)pushButton:(UIButton *)sender
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/movie.mp4"]];
    testImageArray = [[NSArray alloc] initWithObjects:
                      [UIImage imageNamed:@"dummy00.png"],
                      [UIImage imageNamed:@"dummy01.png"],
                      [UIImage imageNamed:@"dummy02.png"],
                      [UIImage imageNamed:@"dummy03.png"],
                      [UIImage imageNamed:@"dummy04.png"],
                      [UIImage imageNamed:@"dummy05.png"],
                      [UIImage imageNamed:@"dummy06.png"],
                      [UIImage imageNamed:@"dummy07.png"],
                      [UIImage imageNamed:@"dummy08.png"],
                      [UIImage imageNamed:@"dummy09.png"],nil];
    
    [self writeImageAsMovie:testImageArray toPath:path size:CGSizeMake(320, 480) duration:10]; //durationの意味がない...
}

-(void)writeImageAsMovie:(NSArray *)array toPath:(NSString *)path size:(CGSize)size duration:(int)duration
{
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeMPEG4 error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264, AVVideoCodecKey, [NSNumber numberWithInt:size.width], AVVideoWidthKey, [NSNumber numberWithInt:size.height], AVVideoHeightKey, nil];
    AVAssetWriterInput *writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:nil];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    [videoWriter addInput:writerInput];
    
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVPixelBufferRef buffer = NULL;
    buffer = [self pixelBufferFromCGImage:[[array objectAtIndex:0] CGImage] size:CGSizeMake(320, 480)];
    CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    
    [adaptor appendPixelBuffer:buffer withPresentationTime:kCMTimeZero];
    int i = 1;
    while (writerInput.readyForMoreMediaData) // every iteration i add my CGImage to buffer, but after 5th iteration readyForMoreMediaData sets to NO, Why???
    {
        NSLog(@"inside for loop %d",i);
//        CMTime frameTime = CMTimeMake(1, 10);
//        CMTime lastTime = CMTimeMake(i, 100);
        CMTime frameTime = CMTimeMake(1800, 600);
        CMTime lastTime = CMTimeMake(i, 600);
        CMTime presentTime = CMTimeAdd(lastTime, frameTime); //movie全体の時間調整(たぶん)
        
        if (i >= [array count]) {
            buffer = NULL;
        } else {
            buffer = [self pixelBufferFromCGImage:[[array objectAtIndex:i] CGImage] size:CGSizeMake(320, 480)];
        }
        
        if (buffer) {
            // append buffer
            [adaptor appendPixelBuffer:buffer withPresentationTime:presentTime];
            i++;
        } else {
            //Finish the session:
            [writerInput markAsFinished];
            [videoWriter finishWriting];
            
            CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
            NSLog (@"Done");
            break;
        }
    }
}

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image  size:(CGSize)imageSize
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, imageSize.width, imageSize.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, imageSize.width, imageSize.height, 8, 4 * imageSize.width, rgbColorSpace, kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
//    CGContextConcatCTM(context, frameTransform);
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
