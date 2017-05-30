//
//  RequestHandler.h
//  XMPPChat
//
//  Created by Amit on 19/10/16.
//  Copyright © 2016 com.fxbytes. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RequestHandler : NSObject

+(instancetype)sharedHandler;

- (void)sendRequestWithParams:(NSMutableDictionary *)params handler:(void (^)(BOOL, NSDictionary *))completionBlock;
- (void)sendJSONRequestWithParams:(NSMutableDictionary *)params URL:(NSString *)url handler:(void (^)(BOOL, NSDictionary *))completionBlock;
- (void)uploadImage:(UIImage *)img Handler:(void (^)(BOOL, NSData *))completionBlock;
- (void)uploadImage:(NSDictionary *)fileDetail withParameters:(NSDictionary *)params  Handler:(void (^)(BOOL, NSDictionary *))completionBlock;

+ (void)startSyncPendingMessages;
+ (void)proceedMessage:(NSDictionary *)msg  Handler:(void (^)(BOOL state, NSData *data, NSDictionary *msg))completionBlock;

@end
