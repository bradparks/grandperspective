#import "DirectoryItem.h"



@interface SpecialDirectoryItem : DirectoryItem {
}
@end

@implementation SpecialDirectoryItem
- (BOOL) isSpecial { return YES; }
@end


@implementation DirectoryItem

+ (DirectoryItem *)specialDirectoryItemWithName:(NSString *)nameVal
                     parent:(DirectoryItem *)parentVal {
  return [[[SpecialDirectoryItem alloc] initWithName: nameVal 
                                          parent: parentVal] autorelease];
}


- (void) dealloc {
  [contents release];

  [super dealloc];
}


- (void) setDirectoryContents:(Item*)contentsVal size:(ITEM_SIZE)dirSize {
  NSAssert(contents == nil, @"Contents should only be set once.");
  
  contents = [contentsVal retain];
  size = dirSize;
}


- (NSString*) description {
  return [NSString stringWithFormat:@"DirectoryItem(%@, %qu, %@)", name, size,
                     [contents description]];
}


- (BOOL) isPlainFile {
  return NO;
}

- (Item*) getContents {
  return contents;
}

@end
