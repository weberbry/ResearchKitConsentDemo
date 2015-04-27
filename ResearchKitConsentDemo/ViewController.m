//
//  ViewController.m
//  ResearchKitConsentDemo
//
//  Created by Bryan Weber on 4/24/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "ViewController.h"
#import <ResearchKit/ResearchKit.h>

@interface ViewController () <ORKTaskViewControllerDelegate>

@property (strong, nonatomic) ORKConsentDocument *consentDocument;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

// This method triggers the creations of the ORKTaskViewController and display the ORKTaskViewController.
// The ORKTaskViewController is a single view controller capable of displaying both the visual and review consent steps.
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    //Step 1: Create a ORKConsentDocument
    NSArray *sectionDataParsedFromInputFile = [self parseConsentDateFromInputFile];
    NSArray *sections = [self createConsentSectionsFromSectionData:sectionDataParsedFromInputFile];
    [self createConsentDocumentWithSection:sections];
    
    //Step 2: Create a ORKOrderedTask
    ORKOrderedTask *orderedTask = [self configureTask];
    
    //Step 3: Configuring a ORKTaskViewController based on the ORKOrderedTask
    ORKTaskViewController *taskViewController = [[ORKTaskViewController alloc] init];
    taskViewController.task = orderedTask;
    taskViewController.delegate = self;
    [self presentViewController:taskViewController animated:YES completion:nil];
}

// Data for the content document can be provided to your app in a number of ways. In this demo I simply included a local JSON file, ConsentText.json.
// This method parses the ContentText.json and returns an array of dictionary containing data for each consent step.
- (NSArray *)parseConsentDateFromInputFile {
    NSString *resource = [[NSBundle mainBundle] pathForResource:@"ConsentText" ofType:@"json"];
    NSData *consentData = [NSData dataWithContentsOfFile:resource];
    NSDictionary *parsedConsentData = [NSJSONSerialization JSONObjectWithData:consentData options:NSJSONReadingMutableContainers error:nil];
    
    return parsedConsentData[@"sections"];
}

// Each step section within the ORKConsentDocument is defined by an ORKConsentSection.
// This method utilizes the array of dictionaries generated from parsing ConsentText.json to generate an array of ORKConsentSection objects.
- (NSArray *)createConsentSectionsFromSectionData:(NSArray *)sections {
    NSMutableArray *consentSections = [NSMutableArray new];
    for (NSDictionary *section in sections) {
        ORKConsentSection *consentSection = [self createConsentSectionFromConsentData:section];
        [consentSections addObject:consentSection];
    }
    return consentSections;
}

// This method creates a ORKConsentSection from each provided dictionary
- (ORKConsentSection *)createConsentSectionFromConsentData:(NSDictionary *)consentData {
    ORKConsentSectionType sectionType = [[consentData objectForKey:@"sectionType"] integerValue];
    NSString *title = [consentData objectForKey:@"sectionTitle"];
    NSString *summary = [consentData objectForKey:@"sectionSummary"];
    NSString *detail = [consentData objectForKey:@"sectionDetail"];
    
    ORKConsentSection *section = [[ORKConsentSection alloc] initWithType:sectionType];
    section.title = title;
    section.summary = summary;
    section.htmlContent = detail;
        
    return section;
}

// A ORKConsentDocument is primarily defined by the array of ORKConsentSection objects in the section property.
// This method creates the ORKConsentDocument and assigns thes section property.
// This method also refines the signature requirements of the consent, providing a single signature object to the ORKConsentDocument
- (void)createConsentDocumentWithSection:(NSArray *)sections {
    self.consentDocument = [ORKConsentDocument new];
    self.consentDocument.title = @"Demo Consent";
    self.consentDocument.sections = sections;
    
    ORKConsentSignature *signture = [ORKConsentSignature new];
    self.consentDocument.signatures = @[signture];
}

// This method creates an ORKOrderedTask consisting of two steps, a visual and a review step.
- (ORKOrderedTask *)configureTask {
    ORKVisualConsentStep *visualConsentStep = [self createVisualContentStepForConsentDocument:self.consentDocument];
    ORKConsentReviewStep *consentReviewStep = [self createConsentReviewStep];
    return [[ORKOrderedTask alloc] initWithIdentifier:@"consent" steps:@[visualConsentStep, consentReviewStep]];
}

// This method utilizes the ORKConsentDocument to create the ORKVisualConsentStep.
- (ORKVisualConsentStep *)createVisualContentStepForConsentDocument:(ORKConsentDocument*)document {
    return [[ORKVisualConsentStep alloc] initWithIdentifier:@"visualConsent" document:document];
}

// This method utilizes the ORKConsentDocument to create the ORKConsentReviewStep and adds the confirmation text.
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

//Step 4: Handling the results from the ORKTaskViewControllerDelegate
// This is the Only required delegate method for the ORKTaskViewController.
// If the user completes the consent flow, this method extracts data from the ORKTaskViewController and creates a PDF for the consent, including all consent text and user's signature.
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
