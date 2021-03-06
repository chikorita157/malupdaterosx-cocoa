//
//  DonationWindowController.m
//  MAL Updater OS X
//
//  Created by 桐間紗路 on 2017/01/03.
//  Copyright 2009-2017 MAL Updater OS X Group. All rights reserved. Code licensed under New BSD License
//

#import "DonationWindowController.h"
#import "Utility.h"

@interface DonationWindowController ()

@end

@implementation DonationWindowController

@synthesize name;
@synthesize key;

- (id)init{
    self = [super initWithWindowNibName:@"DonationWindow"];
    if (!self) {
        return nil;
    }
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)validate:(id)sender{
    if (name.stringValue.length > 0 && key.stringValue.length>0) {
        // Check donation key
        int success = [Utility checkDonationKey:key.stringValue name:name.stringValue];
        if (success == 1) {
            [Utility showsheetmessage:@"Registered" explaination:@"Thank you for donating. The donation reminder will no longer appear and exclusive features are unlocked." window:nil];
            // Add to the preferences
            [[NSUserDefaults standardUserDefaults] setObject:name.stringValue forKey:@"donor"];
            [[NSUserDefaults standardUserDefaults] setObject:key.stringValue forKey:@"donatekey"];
            [[NSUserDefaults standardUserDefaults] setObject:@YES forKey:@"donated"];
            //Close Window
            [self.window orderOut:self];
        }
        else if (success == 2) {
            [Utility showsheetmessage:@"No Internet" explaination:@"Make sure you are connected to the internet and try again." window:self.window];
        }
        else {
            [Utility showsheetmessage:@"Invalid Key" explaination:@"Please make sure you copied the name and key exactly from the email." window:self.window];
        }
    }
    else {
            [Utility showsheetmessage:@"Missing Information" explaination:@"Please type in the name and key exactly from the email and try again." window:self.window];
    }
}

- (IBAction)cancel:(id)sender{
    [self.window orderOut:self];
}

- (IBAction)donate:(id)sender{
    // Show Donation Page
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://malupdaterosx.moe/donate/"]];
}

- (IBAction)purchasedonationlicense:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://softwareateliershiori.onfastspring.com/mal-library-mal-updater-os-x-donation-license"]];
    
}

- (IBAction)lookupkey:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://malupdaterosx.moe/lostkey.php"]];
}

@end
