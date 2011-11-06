//
//  main.m
//  AirLogger
//
//  Created by Sylvain Rebaud on 9/6/11.
//  Copyright 2011 Plutinosoft. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"AirLoggerDelegate");
    [pool release];
    return retVal;
}
