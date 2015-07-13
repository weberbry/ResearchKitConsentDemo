//
//  ConsentDocument.m
//  ResearchKitConsentDemo
//
//  Created by Bryan Weber on 7/13/15.
//  Copyright (c) 2015 Intrepid Pursuits. All rights reserved.
//

#import "ConsentDocument.h"

@implementation ConsentDocument

- (instancetype)init {
    self = [super init];
    if (self) {
        [self configureConsentDocument];
    }
    return self;
}

- (void)configureConsentDocument {
    NSArray *sectionDataParsedFromInputFile = [self parseConsentDateFromInputFile];
    NSArray *sections = [self createConsentSectionsFromSectionData:sectionDataParsedFromInputFile];
    [self createConsentDocumentWithSection:sections];
}

- (NSArray *)parseConsentDateFromInputFile {
    NSString *resource = [[NSBundle mainBundle] pathForResource:@"ConsentText" ofType:@"json"];
    NSData *consentData = [NSData dataWithContentsOfFile:resource];
    NSDictionary *parsedConsentData = [NSJSONSerialization JSONObjectWithData:consentData options:NSJSONReadingMutableContainers error:nil];
    
    return parsedConsentData[@"sections"];
}

- (NSArray *)createConsentSectionsFromSectionData:(NSArray *)sections {
    NSMutableArray *consentSections = [NSMutableArray new];
    for (NSDictionary *section in sections) {
        ORKConsentSection *consentSection = [self createConsentSectionFromConsentData:section];
        [consentSections addObject:consentSection];
    }
    return consentSections;
}

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

- (void)createConsentDocumentWithSection:(NSArray *)sections {
    self.title = @"Demo Consent";
    self.sections = sections;
    
    ORKConsentSignature *signture = [ORKConsentSignature new];
    self.signatures = @[signture];
}


@end
