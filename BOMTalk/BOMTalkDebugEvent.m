//
//  BOMTalkTimelineEvent.m
//  BOMTalk
//
//  Created by Oliver Michalak on 30.04.13.
//  Copyright (c) 2013 Oliver Michalak. All rights reserved.
//

#import "BOMTalkDebugEvent.h"

@implementation BOMTalkDebugEvent

+ (id) eventFromPeer:(BOMTalkPeer*) sourcePeer toPeer:(BOMTalkPeer*) destPeer message: (NSString*) formatString, ... {
	va_list args;
	va_start(args, formatString);
	NSString *message = [[NSString alloc] initWithFormat:formatString arguments:args];
	va_end(args);
	return [[BOMTalkDebugEvent alloc] initWithEventFromPeer:sourcePeer toPeer:destPeer message: message];
}

- (id) initWithEventFromPeer:(BOMTalkPeer*) sourcePeer toPeer:(BOMTalkPeer*) destPeer message: (NSString*) message {
	if ((self = [super init])) {
		_sourcePeer = sourcePeer;
		_destPeer = destPeer;
		_message = message;
		_timestamp = [NSDate dateWithTimeIntervalSinceNow:0];
	}
	return self;
}
@end
