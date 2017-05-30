//
//  ImageCache.m
//  Kidi
//
//  Created by Developer on 10/03/14.
//  Copyright (c) 2014 Xplor. All rights reserved.
//

#import "ImageCache.h"
#import <CommonCrypto/CommonDigest.h>

@implementation ImageCache

static ImageCache *_sharedImageCache = nil;


- (id)init
{
    if ((self = [super init]))
    {
        _data = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

#pragma mark -
#pragma Class Methods

+ (ImageCache *)sharedImageCache
{
    if (!_sharedImageCache)
    {
        _sharedImageCache = [[ImageCache alloc] init];
    }
    
    return _sharedImageCache;
}

- (NSString *)imageDir
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    if ([paths count] > 0)
    {
        NSString *documentDirectory = [paths objectAtIndex:0];
        NSString *imageDirectory = [documentDirectory stringByAppendingPathComponent:@"began_image"];
        
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if ([fileManager fileExistsAtPath:imageDirectory] == NO)
        {
            [fileManager createDirectoryAtPath:imageDirectory withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        return imageDirectory;
    }
    return nil;
}

- (NSString *) MD5String:(NSString *)str
{
    const char *cStr = [str UTF8String];
    unsigned char result[16];
    CC_MD5( cStr, (int)strlen(cStr), result );
    // This is the md5 call
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

- (NSString *)pathForName:(NSString *)name
{
    NSString *filePath = [name lowercaseString];
    return [NSString stringWithFormat:@"%@/%@", [self imageDir], filePath];
}

- (BOOL)isImageExistsInCache:(NSString *)url
{
    NSString *sName = [self MD5String:url];
    NSString *sPath = [self pathForName:sName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    return [fileManager fileExistsAtPath:sPath];
}

- (void)storeImage:(UIImage *)image forUrl:(NSString *)url
{
    if (image != nil)
    {
        NSData *data = UIImagePNGRepresentation(image);//UIImageJPEGRepresentation(image, 1.0);
        
        if (data != nil)
        {
            NSString *sName = [self MD5String:url];
            NSString *path = [self pathForName:sName];
            [data writeToFile:path atomically:YES];
            //[_data setValue:image forKey:name];
        }
    }
}

- (UIImage *)imageForUrl:(NSString *)url
{
    UIImage *image = nil;
    
    NSString *sName = [self MD5String:url];
    image = [_data valueForKey:sName];
    
    if (image)
    {
        return image;
    }
    else
    {
        return [UIImage imageWithContentsOfFile:[self pathForName:sName]];
    }
}

- (void)removeImage:(NSString *)url
{
    NSString *sName = [self MD5String:url];
    NSString *sPath = [self pathForName:sName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:sPath])
    {
        [fileManager removeItemAtPath:sPath error:nil];
    }
}

- (void)clearCache
{
    NSString *sImageDir = [self imageDir];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:sImageDir])
    {
        [fileManager removeItemAtPath:sImageDir error:nil];
    }
}

@end
