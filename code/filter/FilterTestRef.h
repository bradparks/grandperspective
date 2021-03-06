#import <Cocoa/Cocoa.h>

/* A test that is part of a Filter. Instances of this object are immutable.
 * However, instances of the MutableFilterTestRef subclass are not.
 */
@interface FilterTestRef : NSObject {
  NSString  *name;

  // Is the test inverted?
  BOOL  inverted;
}

+ (id) filterTestWithName:(NSString *)name;
+ (id) filterTestWithName:(NSString *)name inverted:(BOOL) inverted;

/* Creates a filter from a dictionary as generated by -dictionaryForObject.
 */
+ (FilterTestRef *)filterTestRefFromDictionary:(NSDictionary *)dict;

- (id) initWithName:(NSString *)name;
- (id) initWithName:(NSString *)name inverted:(BOOL) inverted;

- (NSString *)name;
- (BOOL) isInverted;

/* Returns a dictionary that represents the object. It can be used for storing 
 * the object to preferences.
 */
- (NSDictionary *)dictionaryForObject;

@end
