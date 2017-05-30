//
//  NSDate+Helper.m


#import "NSDate+Helper.h"

@implementation NSDate (Helper)

- (NSString *)composeMessageDate {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if ([self isToday]) {
        [dateFormatter setDateFormat:@"hh:mm a"];
    } else {
        [dateFormatter setDateFormat:@"EEEE, MMM dd, yyyy hh:mm a"];
    }
    return [dateFormatter stringFromDate:self];
}


- (NSString *)composeMessageDateForBuddyList {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    if ([self isToday]) {
        [dateFormatter setDateFormat:@"h:mm a"];
    } else {
        
        [dateFormatter setDateFormat:@"EEEE, MMM dd, yyyy"];
    }
    [dateFormatter setAMSymbol:@"AM"];
    [dateFormatter setPMSymbol:@"PM"];
    return [dateFormatter stringFromDate:self];
}

+ (NSDate *)composeDateFromSring:(NSString *)strDate {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [dateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZ"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    NSDate *date = [dateFormatter dateFromString:strDate];
    return date;
}

- (BOOL)isToday {
    
    NSDateComponents *otherDay = [[NSCalendar currentCalendar] components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];
    NSDateComponents *today = [[NSCalendar currentCalendar] components:NSCalendarUnitEra | NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:[NSDate date]];
    if([today day] == [otherDay day] &&
       [today month] == [otherDay month] &&
       [today year] == [otherDay year] &&
       [today era] == [otherDay era]) {
        return YES;
    }
    return NO;
}

@end
