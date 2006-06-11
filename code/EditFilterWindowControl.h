#import <Cocoa/Cocoa.h>

@class EditFilterRuleWindowControl;
@class NotifyingDictionary;
@class FileItemTestRepository;


@interface EditFilterWindowControl : NSWindowController {

  IBOutlet NSPopUpButton  *filterActionButton;

  IBOutlet NSTextView  *testDescriptionView;
  IBOutlet NSDrawer  *testDescriptionDrawer;
  
  IBOutlet NSButton  *performFilterButton;

  IBOutlet NSButton  *removeTestFromRepositoryButton;
  IBOutlet NSButton  *editTestInRepositoryButton;

  IBOutlet NSButton  *addTestToFilterButton;
  IBOutlet NSButton  *removeTestFromFilterButton;
  
  IBOutlet NSBrowser  *filterTestsBrowser;
  IBOutlet NSBrowser  *availableTestsBrowser;
  
  NotifyingDictionary  *allTestsByName;
    
  NSMutableArray  *filterTests;
  NSMutableArray  *availableTests;
  NSString  *selectedTestName;
  NSString  *testNameToSelect;
  
  EditFilterRuleWindowControl  *editFilterRuleWindowControl;
}

- (IBAction) cancelFilter:(id)sender;
- (IBAction) performFilter:(id)sender;

- (IBAction) addTestToRepository:(id)sender;
- (IBAction) removeTestFromRepository:(id)sender;
- (IBAction) editTestInRepository:(id)sender;

- (IBAction) addTestToFilter:(id)sender;
- (IBAction) removeTestFromFilter:(id)sender;

- (IBAction) filterActionChanged:(id)sender;
- (IBAction) showTestDescriptionChanged:(id)sender;

- (IBAction) handleTestsBrowserClick:(id)sender;

- (id) initWithTestRepository:(FileItemTestRepository*)testRepository;

@end