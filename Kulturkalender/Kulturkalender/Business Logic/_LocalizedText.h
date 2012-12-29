//
//  _LocalizedText.h
//  Kulturkalender
//
//  Created by Christian Rasmussen on 29.12.12.
//  Copyright (c) 2012 Under Dusken. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface _LocalizedText : NSManagedObject

@property (nonatomic, retain) NSString * language;
@property (nonatomic, retain) NSString * text;

@end