//
//  main.m
//  AMObjectCacheDemo
//
//  Created by Andy Mroczkowski on 9/23/11.
//  Copyright 2011 MindSnacks. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AMObjectCache.h"

int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    AMObjectCache* cache = [[AMObjectCache alloc] initWithCapacity:2];
    
    [cache setObject:@"one" forKey:@"one"];
    [cache setObject:@"two" forKey:@"two"];
    [cache setObject:@"three" forKey:@"three"];

    // since the capacity is 2, @"one should have been evicted"
    NSLog(@"keys:%@", [cache allKeys] );
    
    // access "two" so its more recently used
    [cache objectForKey:@"two"];
    
    // add "four"
    [cache setObject:@"four" forKey:@"four"];
    
    // "three" should be evicted
    NSLog(@"keys:%@", [cache allKeys] );
    
    [pool drain];
    return 0;
}

