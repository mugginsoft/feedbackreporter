/*
 * Copyright 2008, Torsten Curdt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FRFeedbackReporter.h"
#import "FRFeedbackController.h"
#import "FRCrashLogFinder.h"
#import "FRSystemProfile.h"
#import "NSException+Callstack.h"
#import "FRUploader.h"
#import "FRApplication.h"
#import "FRConstants.h"

#import <uuid/uuid.h>

@implementation FRFeedbackReporter

#pragma mark Construction


+ (FRFeedbackReporter *)sharedReporter
{
    static FRFeedbackReporter *sharedReporter = nil;

    if (sharedReporter == nil) {
        sharedReporter = [[[self class] alloc] init];
    }

    return sharedReporter;
}

#pragma mark Destruction

- (void) dealloc
{
    [feedbackController release];
    
    [super dealloc];
}

#pragma mark Variable Accessors

- (FRFeedbackController*) feedbackController
{
    if (feedbackController == nil) {
        feedbackController = [[FRFeedbackController alloc] init];
    }
    
    return feedbackController;
}

- (id) delegate
{
    return delegate;
}

- (void) setDelegate:(id) pDelegate
{
    delegate = pDelegate;
}


#pragma mark Reports

- (BOOL) reportFeedback
{
    FRFeedbackController *controller = [self feedbackController];

    @synchronized (controller) {
    
        if ([controller isShown]) {
            NSLog(@"Controller already shown");
            return NO;
        }
        
        [controller reset];

        [controller setMessage:[NSString stringWithFormat:
            FRLocalizedString(@"Got a problem with %@?", nil),
            [FRApplication applicationName]]];
        
        [controller setInformativeText:[NSString stringWithFormat:
            FRLocalizedString(@"Send feedback", nil)]];
            
        [controller setType:FR_FEEDBACK];
        
        [controller setDelegate:delegate];
        
        [controller showWindow:self];

    }
    
    return YES;
}

- (BOOL) reportIfCrash
{
    NSDate *lastCrashCheckDate = [[NSUserDefaults standardUserDefaults] valueForKey:KEY_LASTCRASHCHECKDATE];
    
    NSArray *crashFiles = [FRCrashLogFinder findCrashLogsSince:lastCrashCheckDate];

    [[NSUserDefaults standardUserDefaults] setValue: [NSDate date]
                                             forKey: KEY_LASTCRASHCHECKDATE];
    
    if ([crashFiles count] > 0) {
        // NSLog(@"Found new crash files");

        FRFeedbackController *controller = [self feedbackController];

        @synchronized (controller) {
        
            if ([controller isShown]) {
                NSLog(@"Controller already shown");
                return NO;
            }

            [controller reset];

            [controller setMessage:[NSString stringWithFormat:
                FRLocalizedString(@"%@ has recently crashed!", nil),
                [FRApplication applicationName]]];
            
            [controller setInformativeText:[NSString stringWithFormat:                          FRLocalizedString(@"Send feedback", nil)]];
            
            [controller setType:FR_CRASH];

            [controller setDelegate:delegate];

            [controller showWindow:self];

        }
        
        return YES;

    }
    
    return NO;
}

- (BOOL) reportException:(NSException *)exception
{
    FRFeedbackController *controller = [self feedbackController];

    @synchronized (controller) {

        if ([controller isShown]) {
            NSLog(@"Controller already shown");
            return NO;
        }

        [controller reset];
        
        [controller setMessage:[NSString stringWithFormat:
            FRLocalizedString(@"%@ has encountered an exception!", nil),
            [FRApplication applicationName]]];
        
        [controller setInformativeText:[NSString stringWithFormat:FRLocalizedString(@"Send feedback", nil)]];

        [controller setException:[NSString stringWithFormat: @"%@\n\n%@\n\n%@",
                                    [exception name],
                                    [exception reason],
                                    [exception my_callStack] ?:@""]];

        [controller setType:FR_EXCEPTION];

        [controller setDelegate:delegate];

        [controller showWindow:self];

    }
    
    return YES;
}

@end
