//
//  AutoExceptions.m
//  Hachidori
//
//  Created by Tail Red on 1/31/15.
//  Copyright 2015 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import "AutoExceptions.h"
#import <EasyNSURLConnection/EasyNSURLConnection.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import "Utility.h"

@implementation AutoExceptions
#pragma mark Importing Exceptions and Auto Exceptions
+ (void)importToCoreData{
    MAL_Updater_OS_XAppDelegate *delegate = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    // Check Exceptions
    NSArray *oexceptions = [[NSUserDefaults standardUserDefaults] objectForKey:@"exceptions"];
    if (oexceptions.count > 0) {
        NSLog(@"Importing Exception List");
        NSFetchRequest *allExceptions = [[NSFetchRequest alloc] init];
        allExceptions.entity = [NSEntityDescription entityForName:@"Exceptions" inManagedObjectContext:moc];
        NSError *error = nil;
        NSArray *exceptions = [moc executeFetchRequest:allExceptions error:&error];
        for (NSDictionary *d in oexceptions) {
            NSString *title = d[@"detectedtitle"];
            BOOL exists = false;
            for (NSManagedObject *entry in exceptions) {
                if ([title isEqualToString:(NSString *)[entry valueForKey:@"detectedTitle"]]) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                NSString *correcttitle = (NSString *)d[@"correcttitle"];
                NSString *showid = (NSString *)d[@"showid"];
                // Add Exceptions to Core Data
                NSManagedObject *obj = [NSEntityDescription
                                        insertNewObjectForEntityForName:@"Exceptions"
                                        inManagedObjectContext: moc];
                // Set values in the new record
                [obj setValue:title forKey:@"detectedTitle"];
                [obj setValue:correcttitle forKey:@"correctTitle"];
                [obj setValue:showid forKey:@"id"];
                [obj setValue:@0 forKey:@"episodeOffset"];
                [obj setValue:@0 forKey:@"episodethreshold"];
            }
        }
        //Save
        [moc save:&error];
        // Erase exceptions data from preferences
        [[NSUserDefaults standardUserDefaults] setObject:[[NSMutableArray alloc] init] forKey:@"exceptions"];
    }
}
+ (void)updateAutoExceptions{
    // This method retrieves the auto exceptions JSON and import new entries
    NSURL *url = [NSURL URLWithString:@"https://exceptions.ateliershiori.moe"];
    EasyNSURLConnection *request = [[EasyNSURLConnection alloc] initWithURL:url];
    [Utility setUserAgent:request];
    //Ignore Cookies
    [request setUseCookies:NO];
    //Test API
    [request startRequest];
    // Get Status Code
    long statusCode = [request getStatusCode];
    switch (statusCode) {
        case 200:{
            NSLog(@"Updating Auto Exceptions!");
            if (![[NSUserDefaults standardUserDefaults] valueForKey:@"updatedaexceptions"]) {
                [AutoExceptions clearAutoExceptions];
                [[NSUserDefaults standardUserDefaults] setObject:@(true)forKey:@"updatedaexceptions"];
            }
            //Parse and Import
            NSData *jsonData = request.response.responsedata;
            NSError *error = nil;
            NSArray *a;
            @try {
                a = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
            }
            @catch (NSException *e) {
                NSLog(@"Unable to refresh auto exceptions database: %@", e);
                return;
            }
            MAL_Updater_OS_XAppDelegate *delegate = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
            NSManagedObjectContext *moc = delegate.managedObjectContext;
            [moc performBlockAndWait:^{
                for (NSDictionary *d in a) {
                    NSString *detectedtitle = d[@"detectedtitle"];
                    NSString *group = d[@"group"];
                    NSString *correcttitle = d[@"correcttitle"];
                    bool iszeroepisode = ((NSNumber *)d[@"iszeroepisode"]).boolValue;
                    int offset = ((NSNumber *)d[@"offset"]).intValue;
                    NSError *derror = nil;
                    NSManagedObject *obj = [self checkAutoExceptionsEntry:detectedtitle group:group correcttitle:correcttitle zeroepisode:iszeroepisode offset:offset];
                    if (obj) {
                        // Update Entry
                        [obj setValue:d[@"offset"] forKey:@"episodeOffset"];
                        [obj setValue:d[@"threshold"] forKey:@"episodethreshold"];
                    }
                    else {
                        // Add Entry to Auto Exceptions
                        obj = [NSEntityDescription
                               insertNewObjectForEntityForName:@"AutoExceptions"
                               inManagedObjectContext: moc];
                        // Set values in the new record
                        [obj setValue:detectedtitle forKey:@"detectedTitle"];
                        [obj setValue:correcttitle forKey:@"correctTitle"]; // Use Universal Correct Title
                        [obj setValue:d[@"offset"] forKey:@"episodeOffset"];
                        [obj setValue:d[@"threshold"] forKey:@"episodethreshold"];
                        [obj setValue:group forKey:@"group"];
                        [obj setValue:@(iszeroepisode) forKey:@"iszeroepisode"];
                        [obj setValue:d[@"mappedepisode"] forKey:@"mappedepisode"];
                    }
                    //Save
                    [moc save:&derror];
                }
            }];
            // Set the last updated date
            [[NSUserDefaults standardUserDefaults] setValue:[NSDate date] forKey:@"ExceptionsLastUpdated"];
            break;
        }
        default:
            NSLog(@"Auto Exceptions List Update Failed!");
            break;
    }
}
+ (void)clearAutoExceptions{
    // Remove All cache data from Auto Exceptions
    MAL_Updater_OS_XAppDelegate *delegate = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    NSFetchRequest *allExceptions = [[NSFetchRequest alloc] init];
    allExceptions.entity = [NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc];
    
    NSError *error = nil;
    NSArray *exceptions = [moc executeFetchRequest:allExceptions error:&error];
    //error handling goes here
    for (NSManagedObject *exception in exceptions) {
        [moc deleteObject:exception];
    }
    error = nil;
    [moc save:&error];
}
+ (NSManagedObject *)checkAutoExceptionsEntry:(NSString *)ctitle
                                       group:(NSString *)group
                                correcttitle:(NSString *)correcttitle
                                 zeroepisode:(bool)zeroepisode
                                      offset:(int)offset{
    // Return existing offline queue item
    NSError *error;
    MAL_Updater_OS_XAppDelegate *delegate = (MAL_Updater_OS_XAppDelegate *)[NSApplication sharedApplication].delegate;
    NSManagedObjectContext *moc = delegate.managedObjectContext;
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(detectedTitle ==[c] %@) AND (correctTitle == %@) AND (group ==[c] %@) AND (iszeroepisode == %i) AND (episodeOffset == %i)", ctitle,correcttitle, group, zeroepisode, offset] ;
    NSFetchRequest *exfetch = [[NSFetchRequest alloc] init];
    exfetch.entity = [NSEntityDescription entityForName:@"AutoExceptions" inManagedObjectContext:moc];
    exfetch.predicate = predicate;
    NSArray *exceptions = [moc executeFetchRequest:exfetch error:&error];
    if (exceptions.count > 0) {
        return (NSManagedObject *)exceptions[0];
    }
    return nil;
}

@end
