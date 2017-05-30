//
//  ImageCache.h
//  Kidi
//
//  Created by Developer on 10/03/14.
//  Copyright (c) 2014 Xplor. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageCache : NSObject
{
    
@private
    NSMutableDictionary *_data;
}

+ (ImageCache *)sharedImageCache;

- (BOOL)isImageExistsInCache:(NSString *)url;

- (void)storeImage:(UIImage *)image forUrl:(NSString *)url;

- (NSString *)pathForName:(NSString *)name;

- (UIImage *)imageForUrl:(NSString *)url;

- (void)removeImage:(NSString *)url;

- (void)clearCache;

@end
