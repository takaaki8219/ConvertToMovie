//
//  ViewController.m
//  ConvertToMovie
//
//  Created by Takaaki Kakinuma on 2012/12/04.
//  Copyright (c) 2012年 Takaaki Kakinuma. All rights reserved.
//

#import "ViewController.h"

#import <CoreMedia/CoreMedia.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreFoundation/CoreFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface ViewController ()
{
    NSArray *testImageArray;
    MPMoviePlayerController *player;
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

    UIButton *movieButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    movieButton.frame = CGRectMake(80, 0, 80, 80);
    [movieButton addTarget:self action:@selector(pushMovieButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:movieButton];
}

#pragma mark movie button action
- (void)pushMovieButton:(UIButton *)sender
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/movie.mp4"]];
    player = [[MPMoviePlayerController alloc] initWithContentURL:[NSURL fileURLWithPath:path]];
    [player.view setFrame:CGRectMake(0, 80, 320, 380)];
    player.scalingMode = MPMovieScalingModeAspectFit;
    [self.view addSubview:player.view];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishPreload:) name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification object:player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishPlayback:) name:MPMoviePlayerPlaybackDidFinishNotification object:player];
    
    [player prepareToPlay];
}

#pragma mark movie action
- (void)finishPreload:(NSNotification *)aNotification {
    player = [aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMediaPlaybackIsPreparedToPlayDidChangeNotification
                                                  object:player];
    [player play];
}

- (void)finishPlayback:(NSNotification *)aNotification {
    player = [aNotification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMoviePlayerPlaybackDidFinishNotification
                                                  object:player];
    [player stop];
}

#pragma mark convert to movie from images
- (void)pushButton:(UIButton *)sender
{
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"Documents/movie.mp4"]];
    if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
        NSLog(@"%@", path);
        [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        NSLog(@"deleted");
        if ( [[NSFileManager defaultManager] fileExistsAtPath:path] ) {
            NSLog(@"Why??");
        }else {
            NSLog(@"completed");
        }
    }
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
    
    [self writeImageAsMovie:testImageArray toPath:path size:CGSizeMake(280, 280) duration:00.1]; //durationの意味がない...
}

#pragma mark 
-(void)writeImageAsMovie:(NSArray *)array toPath:(NSString *)path size:(CGSize)size duration:(CGFloat)duration
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
    CVPixelBufferPoolCreatePixelBuffer (NULL, adaptor.pixelBufferPool, &buffer);
    
    int i = 0;
    int wait = 0;
    int frameRate = 100;
    while (true)
    {
        if ( writerInput.readyForMoreMediaData ) {
            NSLog(@"inside for loop %d",i);
//            CMTime frameTime = CMTimeMake(10, 10);
//            CMTime lastTime = CMTimeMake((i-0)*10*i, 10);
//    //        CMTime frameTime = CMTimeMake(1800, 600);
//    //        CMTime lastTime = CMTimeMake((i-1) * 10, 600);
//            NSLog (@"%lf(%lld,%d) - %lf(%lld,%d)", CMTimeGetSeconds(lastTime), lastTime.value, lastTime.timescale, CMTimeGetSeconds(frameTime), frameTime.value, frameTime.timescale);
//    //        CMTime presentTime = CMTimeRangeMake(lastTime, frameTime);//
//            CMTime presentTime = CMTimeAdd(lastTime, frameTime); //movie全体の時間調整(たぶん)
            
            CMTime presentTime = CMTimeMake(i * frameRate * duration, frameRate);
//            NSLog (@"%lf(%lld,%d)", CMTimeGetSeconds(presentTime), presentTime.value, presentTime.timescale);
            
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
                if ( [[AVAssetWriter class] instancesRespondToSelector:@selector(finishWritingWithCompletionHandler:)] ) {
                    [videoWriter finishWritingWithCompletionHandler:^{
                        NSLog(@"動画保存完了");
                    }];
                }else {
                    [videoWriter finishWriting];
                }
                
                CVPixelBufferPoolRelease(adaptor.pixelBufferPool);
                NSLog (@"Done");
                break;
            }
            
            wait = 0;
        }else if ( wait == 0 ) {
            NSLog(@"wait");
            wait++;
        }else if ( wait++ >= 1000000000 ) {
            NSLog(@"Ummm...");
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
