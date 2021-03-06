//
//  Recognition.h
//  MAL Updater OS X
//
//  Created by 高町なのは on 2014/11/16.
//  Copyright 2014 Atelier Shiori. All rights reserved. Code licensed under New BSD License
//

#import <Foundation/Foundation.h>
#import <CocoaOniguruma/OnigRegexp.h>
#import <CocoaOniguruma/OnigRegexpUtility.h>
#import <anitomy-osx/anitomy-objc-wrapper.h>

@interface Recognition : NSObject
-(NSDictionary*)recognize:(NSString *)string;
@end
