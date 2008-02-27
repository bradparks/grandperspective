#import "UniformTypeInventory.h"

#import "FileItem.h"
#import "UniformType.h"



NSString  *UniformTypeAddedEvent = @"uniformTypeAdded";

NSString  *UniformTypeKey = @"uniformType";


@interface UniformTypeInventory (PrivateMethods) 

- (void) postNotification: (NSNotification *)notification;

- (UniformType *)createUniformTypeForIdentifier: (NSString *)uti;

@end


@implementation UniformTypeInventory

+ (UniformTypeInventory *)defaultUniformTypeInventory {
  static UniformTypeInventory
    *defaultUniformTypeInventoryInstance = nil;

  if (defaultUniformTypeInventoryInstance==nil) {
    defaultUniformTypeInventoryInstance = [[UniformTypeInventory alloc] init];
  }
  
  return defaultUniformTypeInventoryInstance;
}


// Overrides super's designated initialiser.
- (id) init {
  if (self = [super init]) {
    typeForExtension = [[NSMutableDictionary alloc] initWithCapacity: 32];
    untypedExtensions = [[NSMutableSet alloc] initWithCapacity: 32];
    typeForUTI = [[NSMutableDictionary alloc] initWithCapacity: 32];
    childrenForUTI = [[NSMutableDictionary alloc] initWithCapacity: 32];
    parentlessTypes = [[NSMutableSet alloc] initWithCapacity: 8];
  }
  
  return self;
}

- (void) dealloc {
  [typeForExtension release];
  [untypedExtensions release];
  [typeForUTI release];
  [childrenForUTI release];
  [parentlessTypes release];
    
  [super dealloc];
}


- (NSEnumerator *)uniformTypeEnumerator {
  return [typeForUTI objectEnumerator];
}


- (UniformType *)uniformTypeForExtension: (NSString *)ext {  
  UniformType  *type = [typeForExtension objectForKey: ext];
  if (type != nil) {
    // The extension was already encountered, and corresponds to a valid UTI.
    return type;
  }
  
  if ([untypedExtensions containsObject: ext]) {
    // The extension was already encountered, and has no proper UTI associated
    // with it.
    return nil;
  }

  NSString  *uti = 
    (NSString*) UTTypeCreatePreferredIdentifierForTag
                  (kUTTagClassFilenameExtension, (CFStringRef)ext, NULL); 
    // TODO: Use "kUTTypeData" in Mac OS X 10.4 and up.  

  if ([uti hasPrefix: @"dyn."]) {
    [untypedExtensions addObject: ext];
    return nil;
  }
  else {
    type = [self uniformTypeForIdentifier: uti];
    
    if (type != nil) {
      // It is possible that a UTI has been registered for an extension, but
      // that the corresponding UniformType could not be created (because no
      // further information could be established). That is why it is checked 
      // that the type is not nil.
      
      [typeForExtension setObject: type forKey: ext];
    }
    
    return type;
  }
}

- (UniformType *)uniformTypeForIdentifier: (NSString *)uti {
  id  type = [typeForUTI objectForKey: uti];

  if (type == self) {
    // Encountered cycle in the type conformance relationships. Breaking the 
    // loop and avoiding infinite recursion by returning "nil".
    return nil;
  }

  if (type != nil) {
    // It has already been registered
    return type;
  }

  // Temporarily associate "self" with the UTI to mark that the type is 
  // currently being created. This is done to guard against infinite
  // recursion should there be a cycle in the type-conformance relationsships.
  [typeForUTI setObject: self forKey: uti];
  type = [self createUniformTypeForIdentifier: uti];

  if (type == nil) {
    // No uniform type could be created for the UTI
    [typeForUTI removeObjectForKey: uti];
    return nil;
  }
  
  [typeForUTI setObject: type forKey: uti];
  [childrenForUTI setObject: [NSArray array] forKey: uti];
  
  // Register it as a child for each parent
  NSEnumerator  *parentEnum = [[type parentTypes] objectEnumerator];
  UniformType  *parentType;
  while (parentType = [parentEnum nextObject]) {
    NSString  *parentUTI = [parentType uniformTypeIdentifier];
    NSArray  *children = [childrenForUTI objectForKey: parentUTI];
    
    [childrenForUTI setObject: [children arrayByAddingObject: type] 
                      forKey: parentUTI];
  }
  
  // Notify interested observers
  NSNotification  *notification = 
    [NSNotification notificationWithName: UniformTypeAddedEvent 
                      object: self
                      userInfo: [NSDictionary dictionaryWithObject: type
                                                forKey: UniformTypeKey]];
  [self performSelectorOnMainThread: @selector(postNotification:)
          withObject: notification waitUntilDone: NO];
  
  return type;
}

- (NSSet *)childrenOfUniformType: (UniformType *)type {
  return [NSSet setWithArray: [childrenForUTI objectForKey: 
                                                [type uniformTypeIdentifier]]];
}


- (void) dumpTypesToLog {
  NSEnumerator  *typesEnum = [self uniformTypeEnumerator];
  UniformType  *type;
  while (type = [typesEnum nextObject]) {
    NSLog(@"Type: %@", [type uniformTypeIdentifier]);
    NSLog(@"  Description: %@", [type description]);

    NSMutableString  *s = [NSMutableString stringWithCapacity: 64];
    NSEnumerator  *typesEnum2 = [[type parentTypes] objectEnumerator];
    UniformType  *type2;
    while (type2 = [typesEnum2 nextObject]) {
      [s appendFormat: @" %@", [type2 uniformTypeIdentifier]];
    }
    NSLog(@"  Parents:%@", s);
    
    [s deleteCharactersInRange: NSMakeRange(0, [s length])];
    typesEnum2 = [[self childrenOfUniformType: type] objectEnumerator];
    while (type2 = [typesEnum2 nextObject]) {
      [s appendFormat: @" %@", [type2 uniformTypeIdentifier]];
    }
    NSLog(@"  Children:%@", s);
  }
}

@end // @implementation UniformTypeInventory


@implementation UniformTypeInventory (PrivateMethods)

- (void) postNotification: (NSNotification *)notification {
  [[NSNotificationCenter defaultCenter] postNotification: notification];
}

- (id) createUniformTypeForIdentifier:  (NSString *)uti {

  NSDictionary  *dict = 
    (NSDictionary*) UTTypeCopyDeclaration( (CFStringRef)uti );
    
  if (dict == nil) {
    // The UTI is not recognized. 
    return nil;
  }

  NSString  *descr = [dict objectForKey: (NSString*)kUTTypeDescriptionKey];
  if (descr == nil) {
    descr = uti;
  }
    
  NSObject  *conforms = [dict objectForKey: (NSString*)kUTTypeConformsToKey];
  NSMutableArray  *parents;
  if ([conforms isKindOfClass: [NSArray class]]) {
    NSArray  *utiArray = (NSArray *)conforms;

    // Create the corresponding array of type objects.
    parents = [NSMutableArray arrayWithCapacity: [utiArray count]];

    NSEnumerator  *utiEnum = [utiArray objectEnumerator];
    NSString  *parentUti;
    while (parentUti = [utiEnum nextObject]) {
      UniformType  *parentType =
         [self uniformTypeForIdentifier: (NSString *)parentUti];
         
      if (parentType != nil) {
        [parents addObject: parentType];
      }
    }
  }
  else if ([conforms isKindOfClass: [NSString class]]) {
    UniformType  *parentType = 
      [self uniformTypeForIdentifier: (NSString *)conforms];
    parents = (parentType != nil) 
                 ? [NSArray arrayWithObject: parentType] : [NSArray array];                                  
  }
  else {
    parents = [NSArray array];
  }

  return [[UniformType alloc] initWithUniformTypeIdentifier: uti 
                                description: descr parents: parents];
}

@end // @implementation UniformTypeInventory (PrivateMethods)


