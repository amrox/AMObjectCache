
#import <Foundation/Foundation.h>

@interface AMObjectCache : NSObject

@property (assign) NSUInteger capacity;

- (id)initWithCapacity:(NSUInteger)capacity;

- (void)setObject:(id)object forKey:(NSString *)key;
- (id)objectForKey:(NSString *)key;
- (void)removeObjectForKey:(NSString *)key;

- (NSArray *)allKeys;

- (void)empty;

@end
