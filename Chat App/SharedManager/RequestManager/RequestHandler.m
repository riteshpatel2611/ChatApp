//
//  RequestHandler.m
//  XMPPChat
//
//  Created by Amit on 19/10/16.
//  Copyright © 2016 com.fxbytes. All rights reserved.
//

#import "RequestHandler.h"
#import <UIKit/UIKit.h>
#import "RequestQueue.h"
#import "ImageCache.h"

#define URL_BASE @"https://fxbytes.com/Client/openfire/api/"
#define TIMEOUTSECONDS 120
#define URL_BASE_CHAT   @"https://stagingadmin.myxplor.com/chatapi/"

@implementation RequestHandler

+(instancetype)sharedHandler {
    
    static RequestHandler* handler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
	  
	  handler = [[RequestHandler alloc] init];
    });
    return handler;
}

+ (NSString *)generateJSONForDictionary:(NSDictionary *)params {
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:&error];
    
    if (!jsonData) {
        NSLog(@"[CHAT] - ERROR GENERATING JSON PARAMS: [%@]", error);
        return @"";
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        NSLog(@"[CHAT] - JSON input parameters: %@", jsonString);
        return jsonString;
    }
}

+ (NSMutableURLRequest *)generateJSONURLRequestParams:(NSString *)params {
    
    NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", URL_BASE]] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:TIMEOUTSECONDS];
    
    NSString *msgLength = [NSString stringWithFormat:@"%lu", (unsigned long)[params length]];
    
    [theRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [theRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [theRequest addValue:msgLength forHTTPHeaderField:@"Content-Length"];
    [theRequest setHTTPMethod:@"POST"];
    [theRequest setHTTPBody:[params dataUsingEncoding:NSUTF8StringEncoding]];
    
    return theRequest;
}

- (void)sendJSONRequestWithParams:(NSMutableDictionary *)params URL:(NSString *)url handler:(void (^)(BOOL, NSDictionary *))completionBlock; {
    
    NSURLRequest *request = [RequestHandler generateJSONURLRequestParams:[RequestHandler generateJSONForDictionary:params]];
    
    NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
    
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
//        NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//        NSLog(@"dataString-->%@",dataString);
        if (data.length > 0 && error == nil) {
            
            error = nil;
            NSDictionary *rootObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (rootObject) {
                    completionBlock(YES, rootObject);
                } else {
                    completionBlock(NO, error.userInfo);
                }
            });
        } else {
            completionBlock(NO, error.userInfo);
        }
    }];
}

- (void)uploadImage:(UIImage *)img Handler:(void (^)(BOOL, NSData *))completionBlock {
    
    NSString *strUrl = URL_BASE;//[NSString stringWithFormat:@"%@%@",URL_BASE,URL_UPLOAD_IMAGE];
    
    NSString* modifiedUrl = [strUrl
				     stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:modifiedUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TIMEOUTSECONDS];

    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"action\"\r\n\r\n%@", @"upload_image"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"upload\"; filename=\"%@.png\"\r\n", @"image"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:UIImagePNGRepresentation(img)];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:body];
    
    NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
    
    [NSURLConnection sendAsynchronousRequest:request
						   queue:operationQueue
				   completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *error) {
	   
	   if (error == nil) {
		 completionBlock(YES, data);
	   } else {
		 
           [NSURLConnection sendAsynchronousRequest:request
								queue:operationQueue
						completionHandler:
		  ^(NSURLResponse *response, NSData *data, NSError *error) {
			
			if (error == nil) {
			    
			    completionBlock(YES, data);
			    
			} else {
			   
			    [NSURLConnection sendAsynchronousRequest:request
									   queue:operationQueue
							   completionHandler:
			     ^(NSURLResponse *response, NSData *data, NSError *error) {
				   
				   if (error == nil) {
					 completionBlock(YES, data);
				   } else {
					 
					 completionBlock(NO, nil);
				   }
				   
			     }];
			}
		  }];
	   }
     }];
}

- (void)uploadImage:(NSDictionary *)fileDetail withParameters:(NSDictionary *)params  Handler:(void (^)(BOOL, NSDictionary *))completionBlock{
    
    NSString *strUrl = URL_BASE;//[NSString stringWithFormat:@"%@%@",URL_BASE,URL_UPLOAD_IMAGE];
    NSString* modifiedUrl = [strUrl
                             stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:modifiedUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TIMEOUTSECONDS];
   
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    for (NSString *key in params) {
        
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n%@", key, [params valueForKey:key]] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"action\"\r\n\r\n%@", @"save_display_picture"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSArray *keys = [fileDetail allKeys];
    NSString *imageName = keys[0];
    UIImage *image = [fileDetail valueForKey:imageName];
    NSData *imageData = UIImageJPEGRepresentation(image, QUALITY_IMAGE);

    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@.jpg\"\r\n",imageName, imageName] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    [body appendData:[NSData dataWithData:imageData]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request addValue:[NSString stringWithFormat:@"%lu", (unsigned long)[body length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:body ];
    
    NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
    
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:operationQueue
                           completionHandler:
     ^(NSURLResponse *response, NSData *data, NSError *error) {
         
         if (data.length > 0 && error == nil) {
             
             error = nil;
             NSDictionary *rootObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
             
             dispatch_async(dispatch_get_main_queue(), ^{
                 if (rootObject) {
                     completionBlock(YES, rootObject);
                 } else {
                     completionBlock(NO, error.userInfo);
                 }
             });
         } else {
             completionBlock(NO, error.userInfo);
         }
     }];
}

//+ (void)startSyncPendingMessages {
//
//    NSMutableArray *arrPendingMsg = [NSMutableArray arrayWithArray:[XMPPMessageArchiving_PendingMessage_CoreDataObject getAllPendingMessage]];
//    
//    for (XMPPMessageArchiving_PendingMessage_CoreDataObject *obj in arrPendingMsg) {
//	  [self proceedMessage:obj Handler:^(BOOL state, NSData *data, XMPPMessageArchiving_PendingMessage_CoreDataObject *msg) {
//		if (state == YES) {
//		    NSError *error = nil;
//		    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
//		    if (error == nil) {
//			  
//			  UIImage *image = nil;
//			  UIImage *thumbImg = nil;
//			  if ([[NSFileManager defaultManager] fileExistsAtPath:msg.imagePath]) {
//				
//				image = [UIImage imageWithData:[NSData dataWithContentsOfFile:msg.imagePath]];
//				thumbImg = [image resizeForMaxResolution:MAX_IAMGE_THUMB_SIZE];
//				[[NSFileManager defaultManager] removeItemAtPath:msg.imagePath error:nil];
//			  }
//			  [[ImageCache sharedImageCache] storeImage:image forUrl:[dic valueForKey:@"image_path"]];
//			  [[ChatProtocolManager sharedChatManager] sendImage:thumbImg Url:[dic valueForKey:@"image_path"] ToUser:msg.reciverName];
//                [msg deletePendingMessage];
//		    }
//		}
//	  }];
//    }
//}


+ (void)proceedMessage:(NSDictionary *)msg  Handler:(void (^)(BOOL state, NSData *data, NSDictionary *msg))completionBlock {
    
    
    UIImage *img = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:msg[@"imagePath"]]) {
        img = [UIImage imageWithData:[NSData dataWithContentsOfFile:msg[@"imagePath"]]];
    }
    NSString *strUrl = [URL_BASE_CHAT stringByAppendingString:@"upload_image"];
    
    NSString* modifiedUrl = [strUrl
                             stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:modifiedUrl] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:TIMEOUTSECONDS];
    
    [request setHTTPMethod:@"POST"];
    
    NSString *boundary = @"---------------------------14737809831466499882746641449";
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    NSMutableData *body = [NSMutableData data];
    
    
    //    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    //    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"action\"\r\n\r\n%@", @"upload_image"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"upload\"; filename=\"%@.jpg\"\r\n", @"image"] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    [body appendData:UIImageJPEGRepresentation(img, QUALITY_IMAGE)];
    
    [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
    
    
    
    [request addValue:[NSString stringWithFormat:@"%ld", [body length]] forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:body];
    
    [[RequestQueue mainQueue] addRequest:request  ReqiestId:msg[@"msgId"] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error == nil) {
                completionBlock(YES, data, msg);
            } else {
                
                completionBlock(NO, nil, msg);
            }
        });
        
    }];
}

- (void)sendRequestWithParams:(NSMutableDictionary *)params handler:(void (^)(BOOL, NSDictionary *))completionBlock {
    
    NSURLRequest *request = [RequestHandler generateJSONURLRequestParams:[RequestHandler generateJSONForDictionary:params]];
    NSOperationQueue *operationQueue = [NSOperationQueue mainQueue];
    
    [NSURLConnection sendAsynchronousRequest:request queue:operationQueue completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
        
        if (data.length > 0 && error == nil) {
            
            error = nil;
            NSDictionary *rootObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (rootObject) {
                    completionBlock(YES, rootObject);
                } else {
                    completionBlock(NO, error.userInfo);
                }
            });
        } else {
            completionBlock(NO, error.userInfo);
        }
    }];
}

@end
