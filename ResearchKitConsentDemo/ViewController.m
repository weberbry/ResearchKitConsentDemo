//
//  ViewController.m
//  ResearchKitConsentDemo
//
//  Created by Bryan Weber on 4/24/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "ViewController.h"
#import <ResearchKit/ResearchKit.h>
#import "ConsentDocument.h"

@interface ViewController () <ORKTaskViewControllerDelegate>

@property (strong, nonatomic) ORKConsentDocument *consentDocument;

@end

@implementation ViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.consentDocument = [ConsentDocument new];
    
    ORKOrderedTask *orderedTask = [self configureTask];
    
    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] init];
    taskViewController.task = orderedTask;
    taskViewController.delegate = self;
    [self presentViewController:taskViewController animated:YES completion:nil];
}

- (ORKOrderedTask *)configureTask {
    ORKVisualConsentStep *visualConsentStep = [self createVisualContentStepForConsentDocument:self.consentDocument];
    ORKConsentReviewStep *consentReviewStep = [self createConsentReviewStep];
    return [[ORKOrderedTask alloc] initWithIdentifier:@"consent" steps:@[visualConsentStep, consentReviewStep]];
}

- (ORKVisualConsentStep *)createVisualContentStepForConsentDocument:(ORKConsentDocument*)document {
    return [[ORKVisualConsentStep alloc] initWithIdentifier:@"visualConsent" document:document];
}

- (ORKConsentReviewStep *)createConsentReviewStep {
    ORKConsentReviewStep *reviewStep =
    [[ORKConsentReviewStep alloc] initWithIdentifier:@"consentReviewIdentifier"
                                           signature:self.consentDocument.signatures.firstObject
                                          inDocument:self.consentDocument];
    reviewStep.text = @"Confirmation";
    reviewStep.reasonForConsent = @"I confirm that I consent to join this study";
    return reviewStep;
}

#pragma mark - ORKTaskViewControllerDelegate

- (void)taskViewController:(ORKTaskViewController *)taskViewController
       didFinishWithReason:(ORKTaskViewControllerFinishReason)reason
                     error:(NSError *)error {
    switch (reason) {
        case ORKTaskViewControllerFinishReasonCompleted: {
            ORKConsentSignatureResult *signatureResult = (ORKConsentSignatureResult *)[[[taskViewController result] stepResultForStepIdentifier:@"consentReviewIdentifier"] firstResult];
            
            if (signatureResult.signature.signatureImage) {
                signatureResult.signature.title = [NSString stringWithFormat:@"%@ %@", signatureResult.signature.givenName, signatureResult.signature.familyName];
                [signatureResult applyToDocument:self.consentDocument];
                
                [self.consentDocument makePDFWithCompletionHandler:^(NSData * pdfFile, NSError * error) {
                    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
                    NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Consent.pdf"];
                    [pdfFile writeToFile:filePath options:NSDataWritingAtomic error:nil];
                    [self dismissViewControllerAnimated:YES completion:nil];
                }];
            }
        }
            break;
        default:
            break;
    }
}

@end
