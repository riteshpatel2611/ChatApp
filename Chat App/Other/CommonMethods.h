//
//  CommonMethods.h
//  ParkingBeaconDemo
//
//  Created by Xplor on 10/7/16.
//  Copyright © 2016 com.Xplor. All rights reserved.
//

#ifndef CommonMethods_h
#define CommonMethods_h

#import <AVFoundation/AVFoundation.h>

inline static id sortArrayWithSortDescriptorKey(NSString * key, id arrayToSort) {
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    arrayToSort = [NSMutableArray arrayWithArray:[arrayToSort sortedArrayUsingDescriptors:sortDescriptors]];
    
    return arrayToSort;
}

inline static BOOL validateEmail(NSString * candidate) {
    
    //    NSString *emailRegex = @"[A-Z0-9a-z._%+]+@[A-Za-z0-9.]+\\.[A-Za-z]{2,4}";
    NSString *emailRegex = @"[A-Z0-9a-z._%+]+@[A-Za-z0-9]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    
    return [emailTest evaluateWithObject:candidate];
}

inline static BOOL validatePassword(NSString *candidate) {
    
    BOOL lowerCaseLetter = NO;
    BOOL upperCaseLetter = NO;
    BOOL digit = NO;
    BOOL specialCharacter = NO;
    
    if([candidate length] >= 8)
    {
        for (int i = 0; i < [candidate length]; i++)
        {
            unichar c = [candidate characterAtIndex:i];
            //NSLog(@"%c", c);
            
            if(!lowerCaseLetter) {
                lowerCaseLetter = [[NSCharacterSet lowercaseLetterCharacterSet] characterIsMember:c];
            }
            if(!upperCaseLetter) {
                upperCaseLetter = [[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:c];
            }
            if(!digit) {
                digit = [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:c];
            }
            if(!specialCharacter) { //!@#$%^&*-_=+.?/><,"'`~\|[]{}‹›•¥£€
                specialCharacter = [[[NSCharacterSet alphanumericCharacterSet] invertedSet] characterIsMember:c];
            }
            
            if(specialCharacter && digit && lowerCaseLetter && upperCaseLetter) {
                return YES;
            }
        }
    } else {
        return NO;
    }
    return NO;
}

inline static void showAlertWithTitleWithoutAction(NSString *title, NSString *message, NSString *cancelButtonTitle) {
    
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:nil cancelButtonTitle:ALERT_BUTTON_TITLE_OK otherButtonTitles:nil];
        [alert show];
    });
}

inline static BOOL isObjectEmpty(id obj)
{
    if (obj == nil)
        return YES;
    if ([obj isEqual:[NSNull null]])
        return YES;
    if ([obj isEqual:@""])
        return YES;
    return NO;
}

inline static BOOL isObjectNotEmpty(id obj){
    return !isObjectEmpty(obj);
}
inline static id getValueFromDictionary(NSDictionary *dictionary,NSString *key)
{
    if (!isObjectEmpty(dictionary))
    {
        if (!isObjectEmpty([dictionary valueForKey:key]))
        {
            return [dictionary valueForKey:key];
        }
    }
    return @"";
}

static inline NSString * applicationDocumentDirectory() {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    
    return basePath;
}

static inline NSString * timeStamp() {
    
    return [NSString stringWithFormat:@"%lld", [@(floor([[NSDate date] timeIntervalSince1970] * 1000)) longLongValue]];
}

inline static BOOL checkForCameraAccess()
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    NSLog(@"auth staus = %ld", (long)authStatus);
    if(authStatus == AVAuthorizationStatusNotDetermined || authStatus == AVAuthorizationStatusAuthorized) {
        return YES;
    }
    else {
        return NO;
    }
}

inline static UIImage* resizeImage(UIImage *image ,CGSize inSize)
{
    UIGraphicsBeginImageContext(inSize);
    [image drawInRect:CGRectMake(0,0,inSize.width,inSize.height)];
    UIImage* imgThumb = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imgThumb;
    
}// resizeImage:

inline static BOOL isImagesEqual(UIImage *image1 ,UIImage *image2){
    NSData *data1 = UIImagePNGRepresentation(image1);
    NSData *data2 = UIImagePNGRepresentation(image2);
    
    return [data1 isEqual:data2];
}

inline static NSString* removeWhiteSpaces(NSString* string){
    return [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

inline static BOOL validateBuddyName(NSString * candidate) {
    
    NSString *buddyNameRegex = @"^(?!.*?[._]{2})[a-zA-Z0-9_.]+$";//@"^[a-zA-Z0-9_.]*$";
    NSPredicate *buddyNameTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", buddyNameRegex];
    return [buddyNameTest evaluateWithObject:candidate];
}

inline static NSString* getUniqueMediaName(){
    
    int iTimeStemp = [[NSDate date] timeIntervalSince1970];
    return [NSString stringWithFormat:@"%@%d",GETUSERID,iTimeStemp];
}
#endif /* CommonMethods_h */
