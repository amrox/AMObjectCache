
#import "AMObjectCache.h"


NSUInteger const kAMObjectCacheDefaultSize = 45;


typedef struct AMObjectCacheListNode
{
    NSString *key;
    id value;
    struct AMObjectCacheListNode *prev;
    struct AMObjectCacheListNode *next;
} AMObjectCacheListNode;


static AMObjectCacheListNode *newListNode()
{
	AMObjectCacheListNode *node = calloc( 1, sizeof(AMObjectCacheListNode) );
	return node;
}


static void freeListNode( AMObjectCacheListNode *node )
{
	[node->key release];
	[node->value release];

	node->key = nil;
	node->value = nil;
	
	free( node );
}


@interface AMObjectCache ()
@property (assign) AMObjectCacheListNode* cacheListHead;
@property (assign) AMObjectCacheListNode* cacheListTail;
@property (retain) NSMutableDictionary* cacheDict;
@end

@implementation AMObjectCache

@synthesize capacity = _capacity;
@synthesize cacheDict = _cacheDict;
@synthesize cacheListHead = _cacheListHead;
@synthesize cacheListTail = _cacheListTail;

- (id)initWithCapacity:(NSUInteger)capacity
{
	self = [super init];
	if (self != nil)
	{
		self.capacity = capacity;
		self.cacheDict = [[[NSMutableDictionary alloc] initWithCapacity:self.capacity] autorelease];

#if TARGET_OS_IPHONE
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didReceiveMemoryWarning)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
#endif
	}
	return self;
}


- (id)init
{
	return [self initWithCapacity:kAMObjectCacheDefaultSize];
}


- (void)dealloc
{
#if TARGET_OS_IPHONE
    [[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
	[self empty];
	[_cacheDict release];
	[super dealloc];
}


- (void) _removeLastObject
{
    self.cacheListTail = self.cacheListTail->prev;
    [self.cacheDict removeObjectForKey:self.cacheListTail->next->key];
    freeListNode( self.cacheListTail->next );
    self.cacheListTail->next = NULL;
}


- (void)setObject:(id)object forKey:(NSString *)key
{
    @synchronized(self)
    {
        NSAssert( key, @"key is nil" );
        
        AMObjectCacheListNode *newNode = newListNode();
        newNode->key = [key retain];
        newNode->value = [object retain];
        
        if( self.cacheListHead )
        {
            newNode->next = self.cacheListHead;
            self.cacheListHead->prev = newNode;
        }
        else
        {
            // this is the first object so we need to set the tail
            self.cacheListTail = newNode;		
        }
        
        self.cacheListHead = newNode;
        
        NSValue *value = [NSValue valueWithPointer:newNode];
        [self.cacheDict setObject:value forKey:key];
        
        while( self.cacheDict.count > self.capacity )
        {
            [self _removeLastObject];
        }
    }
}


- (id)objectForKey:(NSString *)key
{
    @synchronized(self)
    {
        NSValue *value = [self.cacheDict objectForKey:key];
        if( value )
        {
            AMObjectCacheListNode *node = [value pointerValue];
            if( node != self.cacheListHead )
            {
                AMObjectCacheListNode *prev = node->prev;
                AMObjectCacheListNode *next = node->next;
                
                // fix the tail
                if( node == self.cacheListTail )
                    self.cacheListTail = prev;
                
                // switch in the new head
                node->next = self.cacheListHead;
                node->prev = NULL;
                self.cacheListHead->prev = node;
                self.cacheListHead = node;
                
                // close the gap between prev an next
                // if this wasn't the head, we always have a prev
                prev->next = next;
                // but we might not have a next
                if( next )
                    next->prev = prev;
            }
            
            return  node->value;
        }
    }
	return nil;
}


- (void)removeObjectForKey:(NSString *)key
{
    @synchronized(self)
    {
        NSValue *value = [self.cacheDict objectForKey:key];
        if( value )
        {
            AMObjectCacheListNode *node = [value pointerValue];
            if( node->prev )
                node->prev->next = node->next;
            if( node->next )
                node->next->prev = node->prev;
            
            [self.cacheDict removeObjectForKey:key];
            freeListNode( node );
        }
    }
}


- (void)empty
{
    @synchronized(self)
    {
        for( NSValue *value in self.cacheDict.allValues )
        {
            freeListNode( [value pointerValue] );
        }        
        
        self.cacheDict = [[[NSMutableDictionary alloc] initWithCapacity:self.capacity] autorelease];
        
        self.cacheListHead = NULL;
        self.cacheListTail = NULL;
    }
}


- (NSArray *)allKeys
{
	return [self.cacheDict allKeys];
}


- (void) didReceiveMemoryWarning
{
    // empty half the cache
    
    NSUInteger countToRemove = [self.cacheDict count] / 2;
    
    for( NSUInteger i=0; i<countToRemove; i++ )
    {
        [self _removeLastObject];
    }    
}

@end
