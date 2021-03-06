//
//  AdvancedPrefController.h
//  MAL Updater OS X
//
//  Created by Tail Red on 3/21/15.
//
//

#import <Cocoa/Cocoa.h>
#import <MASPreferences/MASPreferences.h>
#import "MAL_Updater_OS_XAppDelegate.h"
#import "MyAnimeList.h"

@interface AdvancedPrefController : NSViewController <MASPreferencesViewController, NSTextFieldDelegate>
@property (strong) IBOutlet NSTextField *APIUrl;
@property (strong) MAL_Updater_OS_XAppDelegate* appdelegate;
@property (strong) IBOutlet NSButton *kodicheck;
@property (strong) IBOutlet NSButton *testapibtn;
@property (strong) IBOutlet NSProgressIndicator *testprogressindicator;

- (id)initwithAppDelegate:(MAL_Updater_OS_XAppDelegate *)adelegate;
- (IBAction)testapi:(id)sender;
- (IBAction)resetapiurl:(id)sender;
@end
