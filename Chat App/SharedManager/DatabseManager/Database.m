//
//  DataBase.m
//
//
//  Created by  Technology Pvt. Ltd. on 2/12/14.
//  Copyright (c) 2014  Technology Pvt. Ltd. All rights reserved.
//

#import "Database.h"

#define DATABSENAME         @"ChatStorage.sqlite"

@interface Database ()

@end

@implementation Database

static sqlite3 *database = nil;

+ (Database *)connection {
    
    static Database *con = nil;
    
    if (con == NULL) {
        
        //database connection
        con = [[Database alloc] init];
        NSFileManager *filemanager = [NSFileManager defaultManager];
        NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) lastObject];
        NSString *strSqlitePath = [appSupportDir stringByAppendingPathComponent:DATABSENAME];
        NSLog(@"strSqlitePath = %@", strSqlitePath);
        int success = [filemanager fileExistsAtPath:appSupportDir isDirectory:NULL];
        
        //If there isn't an App Support Directory yet ...
        if (!success) {
            
            NSError *error = nil;
            //Create one
            if ([filemanager createDirectoryAtPath:appSupportDir withIntermediateDirectories:YES attributes:nil error:&error]) {
                
                if (!error) {
                    
                    NSString *strDefaultPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DATABSENAME];
                    success = [filemanager copyItemAtPath:strDefaultPath toPath:strSqlitePath error:&error];
                    
                    if (!success) {
                        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
                    }
                }
            }
            else {
                // *** OPTIONAL *** Mark the directory as excluded from iCloud backups
                NSURL *url = [NSURL fileURLWithPath:appSupportDir];
                if (![url setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:&error]) {
                    NSLog(@"Error excluding %@ from backup %@", url.lastPathComponent, error.localizedDescription);
                }
                success = [filemanager fileExistsAtPath:strSqlitePath isDirectory:NULL];
            }
        }
        else {
            NSError *error = nil;
            success = [filemanager fileExistsAtPath:strSqlitePath isDirectory:NULL];
            if (!success) {
                NSString *strDefaultPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:DATABSENAME];
                success = [filemanager copyItemAtPath:strDefaultPath toPath:strSqlitePath error:&error];
                
                if (!success) {
                    NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
                }
            }
        }
        
        //file exist at path
        if (success) {
            
            if (sqlite3_open([strSqlitePath UTF8String], &database) == SQLITE_OK) {
                
            } else {
                sqlite3_close(database);
                NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
            }
        }
    }
    return con;
}

// Generalized function of prepare statement
-(void)prepareStatementWithSQL_Query:(const char *)sqlQuery :(sqlite3_stmt **)statement queryPrint:(BOOL)isPrintable
{
    printf("\nQuery = %s\n",sqlQuery);
    if (isPrintable) {
        printf("\nQuery = %s\n",sqlQuery);
    }
    
    if (sqlite3_prepare_v2(database, sqlQuery, -1, &(*statement), NULL) != SQLITE_OK) {
        NSAssert1(0, @"Error: failed to prepare statement with message '%s'.", sqlite3_errmsg(database));
    }
}

#pragma mark - Check table columns

// Implemented for checking whether column name exist in particular table
- (BOOL)doesDatabaseContainNewColumns:(NSString *)tablename strFieldName:(NSString *)fieldName {
    sqlite3_stmt *deleteStatement; // statement created
    const char *sql = [[NSString stringWithFormat:@"SELECT %@ FROM %@", fieldName, tablename] UTF8String];
    
    if (sqlite3_prepare_v2(database, sql, -1, &deleteStatement, NULL) != SQLITE_OK) {
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - Database migration function

// Implemented for migration of data for new release
- (void)migrateSqliteStatments {
    NSMutableArray *arr_sqlQueries = [[NSMutableArray alloc] init];
    
    sqlite3_stmt *sqlStatement; // statement created
    
    //Only write your sql statements above this comment and add to the arr_sqlQueries to execute.
    //execute sql queries.
    for (NSString *createQuery in arr_sqlQueries) {
        
        [self prepareStatementWithSQL_Query:[createQuery UTF8String] :&sqlStatement queryPrint:YES];
        
        sqlite3_step(sqlStatement);
        sqlite3_reset(sqlStatement);
    }
}

#pragma mark -- Insert/ Select/ Update Contacts table

- (void)insertContacts:(NSArray *)contacts {
    
    sqlite3_stmt *sqlStatement = nil;
    char* errorMessage = nil;
    
    @try {
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
        sqlite3_exec(database, "PRAGMA synchronous = OFF", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &errorMessage);
        
        [self prepareStatementWithSQL_Query:"INSERT OR REPLACE INTO Contacts (displayName, avatarPath, contactJId, userJId, status, subscriptionType, isDeleted, user_type, center_id) values (?, ?, ?, ?, ?, ?, ?, ?, ?)" :&sqlStatement queryPrint:YES];
        
        for (NSDictionary *dict in contacts) {
            
            //            NSDictionary *d = [self getContact:dict[@"contactJId"] forUser:dict[@"userJId"]];
            //            if (d != nil && d.count > 0) {
            //
            //                [self updateContact:dict];
            //            } else {
            
            sqlite3_bind_text(sqlStatement, 1, [dict[@"displayName"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(sqlStatement, 2, [dict[@"avatarPath"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(sqlStatement, 3, [dict[@"contactJId"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(sqlStatement, 4, [dict[@"userJId"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(sqlStatement, 5, [dict[@"status"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_text(sqlStatement, 6, [dict[@"subscriptionType"] UTF8String], -1, SQLITE_TRANSIENT);
            sqlite3_bind_int(sqlStatement, 7,  [dict[@"isDeleted"] boolValue]);
            sqlite3_bind_int(sqlStatement, 8,  [dict[@"user_type"] intValue]);
            sqlite3_bind_text(sqlStatement, 9, [dict[@"center_id"] UTF8String], -1, SQLITE_TRANSIENT);
            
            if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
                printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
            }
            sqlite3_clear_bindings(sqlStatement);
            sqlite3_reset(sqlStatement);
            
            
            //            }
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "CREATE  INDEX 'TTC_Stop_Index' ON 'TTC' ('Stop')", NULL, NULL, &errorMessage);
        NSLog(@"%@",[self sqlite3StmtToString:sqlStatement]);
        sqlite3_finalize(sqlStatement);
    }
}

-(NSMutableString*) sqlite3StmtToString:(sqlite3_stmt*) statement
{
    NSMutableString *s = [NSMutableString new];
    [s appendString:@"{\"statement\":["];
    for (int c = 0; c < sqlite3_column_count(statement); c++){
        [s appendFormat:@"{\"column\":\"%@\",\"value\":\"%@\"}",[NSString stringWithUTF8String:(char*)sqlite3_column_name(statement, c)],[NSString stringWithUTF8String:(char*)sqlite3_column_text(statement, c)]];
        if (c < sqlite3_column_count(statement) - 1)
            [s appendString:@","];
    }
    [s appendString:@"]}"];
    return s;
}
- (NSMutableDictionary *)getContact:(NSString *)contactJId forUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableDictionary *contactInfo = nil;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from Contacts WHERE contactJId = '%@' AND userJId = '%@' AND isDeleted = 0", contactJId, userJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            contactInfo = [[NSMutableDictionary alloc] init];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [contactInfo setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            return contactInfo;
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return contactInfo;
    }
}

- (NSMutableArray *)getAllContactsForUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *contacts = [[NSMutableArray alloc] init];
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from Contacts WHERE userJId = '%@' AND isDeleted = 0", userJId];
        
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            NSMutableDictionary *contactInfo = [[NSMutableDictionary alloc] init];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [contactInfo setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [contacts addObject:contactInfo];
        }
        return contacts;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return contacts;
    }
}

- (void)updateContact:(NSDictionary *)dict {
    
    sqlite3_stmt *sqlStatement = nil;
    @try {
        [self prepareStatementWithSQL_Query:"UPDATE Contacts SET displayName = ?, avatarPath = ?, status = ?, subscriptionType = ?, isDeleted = ? WHERE contactJId = ? AND userJId = ?" :&sqlStatement queryPrint:NO];
        
        sqlite3_bind_text(sqlStatement, 1, [dict[@"displayName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 2, [dict[@"avatarPath"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 3, [dict[@"status"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 4, [dict[@"subscriptionType"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(sqlStatement, 5, [dict[@"isDeleted"] boolValue]);
        sqlite3_bind_text(sqlStatement, 6, [dict[@"contactJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 7, [dict[@"userJId"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
    }
}

- (void)updateLastMessageId:(NSString *)messageId forContact:(NSString *)contactJid {
    
    sqlite3_stmt *sqlStatement = nil;
    @try {
        
        NSString *query = [NSString stringWithFormat:@"UPDATE Contacts SET lastMessageId = '%@' WHERE contactJId = '%@'", messageId, contactJid];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
    }
}

- (NSDictionary *)getLastMessageIdOfUser:(NSString *)contactJid {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT lastMessageId from Contacts WHERE contactJId = '%@'", contactJid];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            NSMutableDictionary *message = [NSMutableDictionary dictionary];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [messages addObject:message];
        }
        return [messages lastObject];
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return [messages lastObject];
    }
}

#pragma mark -- Insert/ Select/ Update UserGroups table

- (void)insertUserGroups:(NSArray *)groups {
    
    sqlite3_stmt *sqlStatement = nil;
    char* errorMessage = nil;
    
    [self prepareStatementWithSQL_Query:"INSERT OR REPLACE INTO UserGroups (displayName, groupAvatarPath, groupJId, userJId, isDeleted) values (?, ?, ?, ?, ?)" :&sqlStatement queryPrint:NO];
    
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    sqlite3_exec(database, "PRAGMA synchronous = OFF", NULL, NULL, &errorMessage);
    //sqlite3_exec(database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &errorMessage);
    
    for (NSDictionary *dict in groups) {
        sqlite3_bind_text(sqlStatement, 1, [dict[@"displayName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 2, [dict[@"groupAvatarPath"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 3, [dict[@"groupJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 4, [dict[@"userJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(sqlStatement, 5, [dict[@"isDeleted"] boolValue]);
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
        sqlite3_clear_bindings(sqlStatement);
        sqlite3_reset(sqlStatement);
        
        [self insertUserGroupMembers:dict[@"members"] group:dict[@"groupJId"] user:dict[@"userJId"]];
        //        }
    }
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
    //sqlite3_exec(database, "CREATE  INDEX 'TTC_Stop_Index' ON 'TTC' ('Stop')", NULL, NULL, &errorMessage);
    sqlite3_finalize(sqlStatement);
}

- (NSMutableArray *)getAllGroupsOfUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *groups = [[NSMutableArray alloc] init];
    
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from UserGroups WHERE userJId = '%@'", userJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            NSMutableDictionary *groupInfo = [NSMutableDictionary dictionary];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [groupInfo setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [groups addObject:groupInfo];
        }
        return groups;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return groups;
    }
}

- (NSMutableDictionary *)getGroup:(NSString *)groupJId forUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableDictionary *groupInfo = nil;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from UserGroups WHERE userJId = '%@' AND isDeleted = 0 AND groupJId = '%@'", userJId, groupJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            groupInfo = [[NSMutableDictionary alloc] init];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [groupInfo setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            return groupInfo;
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return groupInfo;
    }
}

- (void)updateGroup:(NSDictionary *)dict {
    
    sqlite3_stmt *sqlStatement = nil;
    @try {
        [self prepareStatementWithSQL_Query:"UPDATE UserGroups SET displayName = ?, groupAvatarPath = ?, isDeleted = ? WHERE groupJId = ? AND userJId = ?" :&sqlStatement queryPrint:NO];
        
        sqlite3_bind_text(sqlStatement, 1, [dict[@"displayName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 2, [dict[@"groupAvatarPath"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(sqlStatement, 3, [dict[@"isDeleted"] boolValue]);
        sqlite3_bind_text(sqlStatement, 4, [dict[@"groupJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 5, [dict[@"userJId"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
    }
}

- (void)updateLastMessageId:(NSString *)messageId forGroup:(NSString *)groupJid {
    
    sqlite3_stmt *sqlStatement = nil;
    @try {
        
        NSString *query = [NSString stringWithFormat:@"UPDATE UserGroups SET lastMessageId = '%@' WHERE groupJId = '%@'", messageId, groupJid];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
    }
}

- (NSDictionary *)getLastMessageIdOfGroup:(NSString *)groupJid {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT lastMessageId from UserGroups WHERE groupJId = '%@'", groupJid];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            NSMutableDictionary *message = [NSMutableDictionary dictionary];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [messages addObject:message];
        }
        return [messages lastObject];
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return [messages lastObject];
    }
}

- (void)insertUserGroupMembers:(NSArray *)members group:(NSString *)groupJId user:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    char* errorMessage = nil;
    
    [self prepareStatementWithSQL_Query:"INSERT OR REPLACE INTO GroupMembers (memberDisplayName, memberJId, isAdmin, groupJId, userJId, isDeleted) values (?, ?, ?, ?, ?, ?)" :&sqlStatement queryPrint:NO];
    
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    sqlite3_exec(database, "PRAGMA synchronous = OFF", NULL, NULL, &errorMessage);
    //sqlite3_exec(database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &errorMessage);
    
    for (NSDictionary *dict in members) {
        
        //        NSDictionary *d = [self getGroup:dict[@"groupJId"] forUser:dict[@"userJId"]];
        //        if (d != nil && d.count > 0) {
        //
        //            [self updateGroup:dict];
        //        } else {
        
        sqlite3_bind_text(sqlStatement, 1, [dict[@"displayName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 2, [dict[@"name"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(sqlStatement, 3, [dict[@"is_admin"] boolValue]);
        sqlite3_bind_text(sqlStatement, 4, [groupJId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 5, [userJId UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(sqlStatement, 6, [dict[@"isDeleted"] boolValue]);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
        sqlite3_clear_bindings(sqlStatement);
        sqlite3_reset(sqlStatement);
        //         }
    }
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
    //sqlite3_exec(database, "CREATE  INDEX 'TTC_Stop_Index' ON 'TTC' ('Stop')", NULL, NULL, &errorMessage);
    sqlite3_finalize(sqlStatement);
}

- (NSMutableArray *)getGroupMembers:(NSString *)groupJId forUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *groupMembers = [[NSMutableArray alloc] init];
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from GroupMembers WHERE groupJId = '%@' AND userJId = '%@' AND isDeleted = 0", groupJId, userJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [dict setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [groupMembers addObject:dict];
        }
        return groupMembers;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return groupMembers;
    }
}

- (NSMutableDictionary *)getGroupMember:(NSString *)groupJId forUser:(NSString *)userJId member:(NSString *)memberJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableDictionary *memberInfo = nil;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from GroupMembers WHERE groupJId = '%@' AND userJId = '%@' AND memberJId = '%@' AND isDeleted = 0", groupJId, userJId, memberJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            memberInfo = [[NSMutableDictionary alloc] init];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [memberInfo setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            return memberInfo;
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return memberInfo;
    }
}

- (void)updateGroupMember:(NSDictionary *)dict {
    
    sqlite3_stmt *sqlStatement = nil;
    @try {
        [self prepareStatementWithSQL_Query:"UPDATE GroupMembers SET memberDisplayName = ?, isAdmin = ?, isDeleted = ? WHERE groupJId = ? AND userJId = ? AND memberJId = ?" :&sqlStatement queryPrint:NO];
        
        sqlite3_bind_text(sqlStatement, 1, [dict[@"memberDisplayName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(sqlStatement, 2, [dict[@"isAdmin"] boolValue]);
        sqlite3_bind_int(sqlStatement, 3, [dict[@"isDeleted"] boolValue]);
        sqlite3_bind_text(sqlStatement, 4, [dict[@"groupJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 5, [dict[@"userJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 6, [dict[@"memberJId"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
    }
}

#pragma mark -- Insert/ Select/ Update Messages table

- (void)insertMessage:(NSDictionary *)dict {
    
    sqlite3_stmt *sqlStatement = nil;
    char* errorMessage = nil;
    
    @try {
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
        sqlite3_exec(database, "PRAGMA synchronous = OFF", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &errorMessage);
        
        [self prepareStatementWithSQL_Query:"INSERT OR REPLACE INTO MessageArchive (isFromMe, messageType, messageStatus, messageDate, message, messageStanza, isGroupMessage, groupJId, bareJId, streamBareJId, mediaId, packetId) values (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)" :&sqlStatement queryPrint:NO];
        
        sqlite3_bind_int(sqlStatement, 1, [dict[@"isFromMe"] boolValue]);
        sqlite3_bind_int(sqlStatement, 2, [dict[@"messageType"] intValue]);
        sqlite3_bind_int(sqlStatement, 3, [dict[@"messageStatus"] intValue]);
        sqlite3_bind_text(sqlStatement, 4, [dict[@"messageDate"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 5, [dict[@"message"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 6, [dict[@"messageStanza"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(sqlStatement, 7, [dict[@"isGroupMessage"] boolValue]);
        sqlite3_bind_text(sqlStatement, 8, [dict[@"groupJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 9, [dict[@"bareJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 10, [dict[@"streamBareJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(sqlStatement, 11, [dict[@"mediaId"] intValue]);
        sqlite3_bind_text(sqlStatement, 12, [dict[@"packetId"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
        sqlite3_clear_bindings(sqlStatement);
        sqlite3_reset(sqlStatement);
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "CREATE  INDEX 'TTC_Stop_Index' ON 'TTC' ('Stop')", NULL, NULL, &errorMessage);
        sqlite3_finalize(sqlStatement);
    }
}

- (NSMutableDictionary *)getMessageWithMessageId:(NSString *)messageId forGroup:(NSString *)groupJId member:(NSString *)memberJId toUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableDictionary *messageDetails = nil;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from MessageArchive WHERE groupJId = '%@' AND bareJId = '%@' AND streamBareJId = '%@' AND packetId = '%@'", groupJId, memberJId, userJId, messageId];//messageStanza LIKE '%%id=\"%@\"%%'
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            messageDetails = [[NSMutableDictionary alloc] init];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [messageDetails setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            return messageDetails;
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messageDetails;
    }
}

- (NSMutableDictionary *)getMessageWithMessageId:(NSString *)messageId forBuddy:(NSString *)buddyJID toUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableDictionary *messageDetails = nil;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from MessageArchive WHERE bareJID = '%@' AND streamBareJId = '%@' AND packetId = '%@'", buddyJID, userJId, messageId];//messageStanza LIKE '%%id=\"%@\"%%'
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            messageDetails = [[NSMutableDictionary alloc] init];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [messageDetails setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            return messageDetails;
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messageDetails;
    }
}
- (void)updateMessageDeliveryStatusForUser:(int)status idVal:(NSString *)idVal forUser:(NSString *)receiverJId sender:(NSString *)senderJId {
    
    sqlite3_stmt *sqlStatement = nil;
    @try {
        
        NSString *queryStr = [NSString stringWithFormat:@"UPDATE MessageArchive SET messageStatus = %d WHERE bareJId = '%@' AND streamBareJId = '%@' AND packetId = '%@'", status, senderJId, receiverJId, idVal];
        
        [self prepareStatementWithSQL_Query:[queryStr UTF8String] :&sqlStatement queryPrint:NO];
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
    }
}

- (void)updateMessageDeliveryStatusForGroup:(int)status idVal:(NSString *)idVal forUser:(NSString *)receiverJId sender:(NSString *)groupJId {
    
    sqlite3_stmt *sqlStatement = nil;
    @try {
        
        NSString *queryStr = [NSString stringWithFormat:@"UPDATE MessageArchive SET messageStatus = %d WHERE groupJId = '%@' AND streamBareJId = '%@' AND packetId = '%@'", status, groupJId, receiverJId, idVal];
        
        [self prepareStatementWithSQL_Query:[queryStr UTF8String] :&sqlStatement queryPrint:NO];
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
    }
}

- (NSMutableArray *)getMessagesOfUser:(NSString *)buddyJId loggedinUser:(NSString *)userJId min:(NSInteger)min max:(NSInteger)max {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    @try {
        //NSString *query = [NSString stringWithFormat:@"SELECT * from MessageArchive WHERE isGroupMessage = 0 AND bareJId = '%@' AND streamBareJId = '%@' AND isDeleted = '0' ORDER BY messageId DESC LIMIT %ld OFFSET %ld", buddyJId, userJId, min, max];
        
        NSString *query = [NSString stringWithFormat:@"SELECT * from MessageArchive WHERE isGroupMessage = 0 AND bareJId = '%@' AND streamBareJId = '%@' AND isDeleted = '0' ORDER BY messageDate ASC", buddyJId, userJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            NSMutableDictionary *message = [NSMutableDictionary dictionary];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [messages addObject:message];
        }
        return messages;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messages;
    }
}

- (NSMutableArray *)getMessagesOfGroup:(NSString *)groupJId loggedinUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from MessageArchive WHERE isGroupMessage = 1 AND groupJId = '%@' AND streamBareJId = '%@' AND isDeleted = '0' ORDER BY messageDate ASC", groupJId, userJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            NSMutableDictionary *message = [NSMutableDictionary dictionary];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [messages addObject:message];
        }
        return messages;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messages;
    }
}

- (NSMutableArray *)getPendingMessagesOfUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from MessageArchive WHERE messageStatus = 0 AND streamBareJId = '%@' AND isDeleted = '0'", userJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            NSMutableDictionary *message = [NSMutableDictionary dictionary];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [messages addObject:message];
        }
        return messages;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messages;
    }
}

- (int)getAllUserMessagesCountloggedinUser:(NSString *)userJId 
{
    
    sqlite3_stmt *sqlStatement = nil;
    int messageCount = 0;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT MessageID FROM MessageArchive, RecentMessageArchive WHERE MessageArchive.streamBareJId = '%@' AND RecentMessageArchive.streamBareJId = '%@' AND MessageArchive.messageDate > RecentMessageArchive.lastSeenTimestamp AND MessageArchive.isFromMe = 0  AND  RecentMessageArchive.isDeleted = 0 AND MessageArchive.isDeleted = 0 GROUP BY MessageID", userJId, userJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        while (sqlite3_step(sqlStatement) == SQLITE_ROW)
        {
            messageCount = messageCount + 1;
        }
        return messageCount;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messageCount;
    }
}

- (NSInteger)getUserMessagesCount:(double)lastSeen :(NSString *)groupJId loggedinUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSInteger messageCount = 0;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT count(*) from MessageArchive WHERE isFromMe = 0 AND isGroupMessage = 0 AND bareJId = '%@' AND streamBareJId = '%@' AND isDeleted = '0' AND messageDate > %f", groupJId, userJId, lastSeen];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                //NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                //                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
                messageCount = [[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] integerValue];
            }
        }
        return messageCount;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messageCount;
    }
}

- (NSInteger)getGroupMessagesCount:(double)lastSeen :(NSString *)groupJId loggedinUser:(NSString *)userJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSInteger messageCount = 0;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT count(*) from MessageArchive WHERE isFromMe = 0 AND isGroupMessage = 1 AND groupJId = '%@' AND streamBareJId = '%@' AND isDeleted = '0' AND messageDate > %f", groupJId, userJId, lastSeen];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                //NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                //                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
                messageCount = [[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] integerValue];
            }
        }
        return messageCount;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messageCount;
    }
}

#pragma mark -- Insert/ Select/ Update RecentMessage table

- (void)insertRecentMessage:(NSMutableDictionary *)messageDetail {
    
    //    sqlite3_stmt *sqlStatement = nil;
    //    char* errorMessage = nil;
    //
    //    [self prepareStatementWithSQL_Query:"INSERT OR REPLACE INTO RecentMessageArchive (recentMessageOutgoing, recentMessageTimestamp, recentMessage, bareJId, streamBareJId) values (?, ?, ?, ?, ?)" :&sqlStatement queryPrint:NO];
    //
    //    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    //    sqlite3_exec(database, "PRAGMA synchronous = OFF", NULL, NULL, &errorMessage);
    //    //sqlite3_exec(database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &errorMessage);
    //
    ////    NSDictionary *d = [self getRecentMessageOf:messageDetail[@"bareJId"] andUser:messageDetail[@"streamBareJId"]];
    ////    if (d != nil && d.count > 0) {
    ////        [messageDetail setValue:d[@"isDeleted"] forKey:@"isDeleted"];
    ////        [messageDetail setValue:d[@"lastSeenTimestamp"] forKey:@"lastSeenTimestamp"];
    ////        [messageDetail setValue:d[@"unreadMessageCount"] forKey:@"unreadMessageCount"];
    ////        [self updateRecentMessage:messageDetail];
    ////    } else {
    //
    //        sqlite3_bind_int(sqlStatement, 1, [messageDetail[@"recentMessageOutgoing"] boolValue]);
    //        sqlite3_bind_text(sqlStatement, 2, [messageDetail[@"recentMessageTimestamp"] UTF8String], -1, SQLITE_TRANSIENT);
    //        sqlite3_bind_text(sqlStatement, 3, [messageDetail[@"recentMessage"] UTF8String], -1, SQLITE_TRANSIENT);
    //        sqlite3_bind_text(sqlStatement, 4, [messageDetail[@"bareJId"] UTF8String], -1, SQLITE_TRANSIENT);
    //        sqlite3_bind_text(sqlStatement, 5, [messageDetail[@"streamBareJId"] UTF8String], -1, SQLITE_TRANSIENT);
    //
    //        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
    //            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
    //        }
    //        sqlite3_clear_bindings(sqlStatement);
    //        sqlite3_reset(sqlStatement);
    ////    }
    //
    //    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
    //    //sqlite3_exec(database, "CREATE  INDEX 'TTC_Stop_Index' ON 'TTC' ('Stop')", NULL, NULL, &errorMessage);
    //    sqlite3_finalize(sqlStatement);
    
    sqlite3_stmt *sqlStatement = nil;
    char* errorMessage = nil;
    
    [self prepareStatementWithSQL_Query:"INSERT INTO RecentMessageArchive (recentMessageOutgoing, recentMessageTimestamp, recentMessage, bareJId, streamBareJId) values (?, ?, ?, ?, ?)" :&sqlStatement queryPrint:NO];
    
    sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    sqlite3_exec(database, "PRAGMA synchronous = OFF", NULL, NULL, &errorMessage);
    //sqlite3_exec(database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &errorMessage);
    
    NSDictionary *d = [self getRecentMessageOf:messageDetail[@"bareJId"] andUser:messageDetail[@"streamBareJId"]];
    if (d != nil && d.count > 0) {
        [messageDetail setValue:d[@"isDeleted"] forKey:@"isDeleted"];
        [messageDetail setValue:d[@"lastSeenTimestamp"] forKey:@"lastSeenTimestamp"];
        [messageDetail setValue:d[@"unreadMessageCount"] forKey:@"unreadMessageCount"];
        [self updateRecentMessage:messageDetail];
    } else {
        
        sqlite3_bind_int(sqlStatement, 1, [messageDetail[@"recentMessageOutgoing"] boolValue]);
        sqlite3_bind_text(sqlStatement, 2, [messageDetail[@"recentMessageTimestamp"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 3, [messageDetail[@"recentMessage"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 4, [messageDetail[@"bareJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 5, [messageDetail[@"streamBareJId"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
        sqlite3_clear_bindings(sqlStatement);
        sqlite3_reset(sqlStatement);
    }
    
    sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
    //sqlite3_exec(database, "CREATE  INDEX 'TTC_Stop_Index' ON 'TTC' ('Stop')", NULL, NULL, &errorMessage);
    sqlite3_finalize(sqlStatement);
}

- (NSMutableDictionary *)getRecentMessageOf:(NSString *)receiverJId andUser:(NSString *)senderJId {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableDictionary *groupInfo = nil;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from RecentMessageArchive WHERE bareJId = '%@' AND streamBareJId = '%@'", receiverJId, senderJId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            groupInfo = [[NSMutableDictionary alloc] init];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [groupInfo setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            return groupInfo;
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return groupInfo;
    }
}

- (void)updateRecentMessage:(NSDictionary *)messageDetail {
    
    sqlite3_stmt *sqlStatement = nil;
    @try {
        [self prepareStatementWithSQL_Query:"UPDATE RecentMessageArchive SET recentMessageOutgoing = ?, recentMessageTimestamp = ?, recentMessage = ?, lastSeenTimestamp = ?, unreadMessageCount = ?, isDeleted = ? WHERE streamBareJId = ? AND bareJId = ?" :&sqlStatement queryPrint:NO];
        
        sqlite3_bind_int(sqlStatement, 1, [messageDetail[@"recentMessageOutgoing"] boolValue]);
        sqlite3_bind_text(sqlStatement, 2, [messageDetail[@"recentMessageTimestamp"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 3, [messageDetail[@"recentMessage"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 4, [messageDetail[@"lastSeenTimestamp"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_int(sqlStatement, 5, [messageDetail[@"unreadMessageCount"] intValue]);
        sqlite3_bind_int(sqlStatement, 6, [messageDetail[@"isDeleted"] intValue]);
        sqlite3_bind_text(sqlStatement, 7, [messageDetail[@"streamBareJId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 8, [messageDetail[@"bareJId"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
    }
}

- (void)insertPendingMessage:(NSDictionary *)dict {
    
    sqlite3_stmt *sqlStatement = nil;
    char* errorMessage = nil;
    
    @try {
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
        sqlite3_exec(database, "PRAGMA synchronous = OFF", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &errorMessage);
        
        [self prepareStatementWithSQL_Query:"INSERT INTO PendingMessageArchive (msgId, msg, imagePath, reciverName, senderName, timeStamp) values (?, ?, ?, ?, ?, ?)" :&sqlStatement queryPrint:NO];
        
        sqlite3_bind_text(sqlStatement, 1, [dict[@"msgId"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 2, [dict[@"msg"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 3, [dict[@"imagePath"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 4, [dict[@"reciverName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 5, [dict[@"senderName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 6, [dict[@"timeStamp"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
        sqlite3_clear_bindings(sqlStatement);
        sqlite3_reset(sqlStatement);
    } @catch (NSException *exception) {
        
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "CREATE  INDEX 'TTC_Stop_Index' ON 'TTC' ('Stop')", NULL, NULL, &errorMessage);
        sqlite3_finalize(sqlStatement);
    }
}

- (NSMutableArray *)getPendingMessagesOfSender:(NSString *)senderJid andReciver:(NSString *)reciverJid {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from PendingMessageArchive WHERE senderName = '%@' AND reciverName = '%@'", senderJid, reciverJid];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            NSMutableDictionary *message = [NSMutableDictionary dictionary];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [messages addObject:message];
        }
        return messages;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messages;
    }
}

- (NSMutableArray *)getPendingMessagesWithID:(NSString *)MsgID {
    
    sqlite3_stmt *sqlStatement = nil;
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT * from PendingMessageArchive WHERE msgId = '%@'", MsgID];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            NSMutableDictionary *message = [NSMutableDictionary dictionary];
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
            }
            [messages addObject:message];
        }
        return messages;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messages;
    }
}

- (void)deletePendingMessage:(NSString *)msgId {
    
    sqlite3_stmt *sqlStatement = nil;
    char* errorMessage = nil;
    
    @try {
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
        sqlite3_exec(database, "PRAGMA synchronous = OFF", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &errorMessage);
        NSString *query = [NSString stringWithFormat:@"DELETE from PendingMessageArchive WHERE msgID = '%@'", msgId];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
        sqlite3_clear_bindings(sqlStatement);
        sqlite3_reset(sqlStatement);
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "CREATE  INDEX 'TTC_Stop_Index' ON 'TTC' ('Stop')", NULL, NULL, &errorMessage);
        sqlite3_finalize(sqlStatement);
    }
}

#pragma mark -- Insert/ Select/ Update Media table

- (NSInteger)insertMediaAndGetMediaID:(NSDictionary *)dict {
    sqlite3_stmt *sqlStatement = nil;
    char* errorMessage = nil;
    
    @try {
        sqlite3_exec(database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
        sqlite3_exec(database, "PRAGMA synchronous = OFF", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "PRAGMA journal_mode = MEMORY", NULL, NULL, &errorMessage);
        
        [self prepareStatementWithSQL_Query:"INSERT INTO Media (mediaType, mediaName, mediaLocalPath, mediaServerPath, mediaSize, mediaDuration, mediaThumbPath) values (?, ?, ?, ?, ?, ?, ?)" :&sqlStatement queryPrint:NO];
        
        sqlite3_bind_int(sqlStatement, 1, [dict[@"mediaType"] boolValue]);
        sqlite3_bind_text(sqlStatement, 2, [dict[@"mediaName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 3, [dict[@"mediaLocalPath"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 4, [dict[@"mediaServerPath"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_double(sqlStatement, 5, [dict[@"mediaSize"] doubleValue]);
        sqlite3_bind_double(sqlStatement, 6, [dict[@"mediaDuration"] doubleValue]);
        sqlite3_bind_text(sqlStatement, 7, [dict[@"mediaThumbPath"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
            return 0;
        }
        sqlite3_clear_bindings(sqlStatement);
        sqlite3_reset(sqlStatement);
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
        return 0;
    } @finally {
        sqlite3_exec(database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
        //sqlite3_exec(database, "CREATE  INDEX 'TTC_Stop_Index' ON 'TTC' ('Stop')", NULL, NULL, &errorMessage);
        sqlite3_finalize(sqlStatement);
        return [self getLastInsertedMediaID];
        NSLog(@"[self getLastInsertedMediaID]-->%ld",[self getLastInsertedMediaID]);
    }
}

- (void)updateMedia:(NSDictionary *)dict {
    
    sqlite3_stmt *sqlStatement = nil;
    @try {
        
        [self prepareStatementWithSQL_Query:"UPDATE Media SET mediaName = ?, mediaLocalPath = ?, mediaSize = ? WHERE mediaServerPath = ?" :&sqlStatement queryPrint:NO];
        
        sqlite3_bind_text(sqlStatement, 1, [dict[@"mediaName"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_text(sqlStatement, 2, [dict[@"mediaLocalPath"] UTF8String], -1, SQLITE_TRANSIENT);
        sqlite3_bind_double(sqlStatement, 3, [dict[@"mediaSize"] doubleValue]);
        sqlite3_bind_text(sqlStatement, 4, [dict[@"mediaServerPath"] UTF8String], -1, SQLITE_TRANSIENT);
        
        if (sqlite3_step(sqlStatement) != SQLITE_DONE) {
            printf("Commit Failed! %s\n,", __PRETTY_FUNCTION__);
        }
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
    }
}
- (NSInteger)getLastInsertedMediaID{
    
    sqlite3_stmt *sqlStatement = nil;
    NSInteger messageCount = 0;
    @try {
        NSString *query = [NSString stringWithFormat:@"SELECT mediaId from Media order by mediaId DESC limit 1"];
        const char *cQuery = [query UTF8String];
        [self prepareStatementWithSQL_Query:cQuery :&sqlStatement queryPrint:NO];
        
        int columnCount = sqlite3_column_count(sqlStatement);
        while (sqlite3_step(sqlStatement) == SQLITE_ROW) {
            
            for (int columnIndex = 0; columnIndex < columnCount ; columnIndex++) {
                
                //NSString *columnName = [NSString stringWithUTF8String:(char *)sqlite3_column_name(sqlStatement, columnIndex)];
                char *dataC = (char *)sqlite3_column_text(sqlStatement, columnIndex);
                //                [message setValue:[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] forKey:columnName];
                messageCount = [[NSString stringWithUTF8String:(dataC == nil ? "": dataC)] integerValue];
            }
        }
        return messageCount;
    } @catch (NSException *exception) {
        NSLog(@"%s exception = %@", __PRETTY_FUNCTION__, exception);
    } @finally {
        sqlite3_finalize(sqlStatement);
        return messageCount;
    }
}

@end
