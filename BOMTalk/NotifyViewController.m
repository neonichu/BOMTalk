//
//  NotifyViewController.m
//  BOMTalk
//
//  Created by Oliver Michalak on 26.04.13.
//  Copyright (c) 2013 Oliver Michalak. All rights reserved.
//

#import "NotifyViewController.h"
#import "BOMTalk.h"

#define kGameStart (301)
#define kGameBall (302)
#define kGameCheck (303)
#define kGameHit (304)
#define kGameMissed (305)

#define kXFactor (3.0)

@interface NotifyViewController ()
@property (assign, nonatomic) int counter;
@property (strong, nonatomic) NSTimer *timer;
@property (assign, nonatomic) CGPoint vector;
@property (assign, nonatomic) BOOL asServer;	// neither server nor client means local game
@property (assign, nonatomic) BOOL asClient;
@property (assign, nonatomic) BOOL waitingForClient;
@property (assign, nonatomic) CGFloat clientRacket;
@end

@implementation NotifyViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	srandom(time(NULL));
	_slideView.value = 0.5;
	[self slide];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.05 target:self selector:@selector(update:) userInfo:nil repeats:YES];
	[self reset];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTalk:) name:kBOMTalkUpdateNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(errorTalk:) name:kBOMTalkFailedNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedTalk:) name:kBOMTalkDidConnectNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTalk:) name:kBOMTalkReceivedNotification object:nil];
	BOMTalk *talker = [BOMTalk sharedTalk];
	[talker startInMode:GKSessionModePeer];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[[NSNotificationCenter defaultCenter] removeObserver: self];
	[[BOMTalk sharedTalk] stop];
}

- (void) viewDidUnload {
	[_timer invalidate];
	_timer = nil;
	_ballView = nil;
	_racketView = nil;
	_slideView = nil;
	_areaView = nil;
	_listView = nil;
	[super viewDidUnload];
}

- (void) updateTalk: (NSNotification*) notification {
	[_listView reloadData];
}

- (void) errorTalk: (NSNotification*) notification {
	_listView.hidden = NO;
	[self reset];
}

- (void) connectedTalk: (NSNotification*) notification {
	DLog(@"connected");
	BOMTalkPeer *peer = notification.object;
	_listView.hidden = YES;
	_asServer = YES;
	[[BOMTalk sharedTalk] sendMessage:kGameStart toPeer:peer];
}

- (void) receivedTalk: (NSNotification*) notification {
	DLog(@"received %@", notification);
	BOMTalk *talker = [BOMTalk sharedTalk];
	BOMTalkPeer *peer = notification.object[@"peer"];
	NSNumber *message = notification.object[@"messageID"];
//	id data = notification.object[@"data"];
	switch (message.integerValue) {
		case kGameStart:
			[self reset];
			_listView.hidden = YES;
			_asServer = NO;
			_asClient = YES;
			break;
		case kGameBall:
			DLog(@"balled");
			_ballView.center = CGPointMake([notification.object[@"data"][@"x"] floatValue], [notification.object[@"data"][@"y"] floatValue]);
			break;
		case kGameCheck:
			[talker sendMessage: kGameHit toPeer:peer];
			break;
		case kGameHit:
			_vector.y -= 1;	// increase speed
			_vector.y *= -1;
			[self update:nil];
			break;
		case kGameMissed:
			break;
	}
	_listView.hidden = YES;
	[[BOMTalk sharedTalk] sendMessage:kGameStart toPeer:peer];
}

- (void) reset {
	_ballView.center = CGPointMake(CGRectGetMidX(self.view.frame), CGRectGetMinY(_areaView.frame));
	_vector = CGPointMake ((0.1 + kXFactor * (CGFloat)(random() % 100) / 100.0) * (random() % 10 >= 5 ? 1 : -1), 2);
	self.title = [NSString stringWithFormat:@"Pong: %d", _counter];
	_asServer = _asClient = NO;
}

- (void) update:(NSNotification*) notification {
	if (!_listView.hidden || _asClient || _waitingForClient)
		return;
	CGPoint pos = CGPointMake(_ballView.center.x + _vector.x, _ballView.center.y + _vector.y);
	if (!CGRectContainsPoint(_areaView.frame, pos)) {
		if (pos.x < CGRectGetMinX(_areaView.frame) || pos.x > CGRectGetMaxX(_areaView.frame)) {
			_vector.x *= -1;
			pos = CGPointMake(_ballView.center.x + _vector.x, _ballView.center.y + _vector.y);
		}
		if (pos.y < CGRectGetMinY(_areaView.frame)) {
			if (_asServer) {
				_waitingForClient = YES;
				[[BOMTalk sharedTalk] sendToAllMessage:kGameCheck withData: @{@"x": [NSNumber numberWithFloat:pos.x], @"y": [NSNumber numberWithFloat:pos.y]}];
				return;
			}
			else {
				_vector.y -= 1;	// increase speed
				_vector.y *= -1;
				pos = CGPointMake(_ballView.center.x + _vector.x, _ballView.center.y + _vector.y);
			}
		}
		if (pos.y > CGRectGetMaxY(_areaView.frame)) {
			if (CGRectContainsPoint(_racketView.frame, CGPointMake (pos.x, pos.y + CGRectGetHeight(_ballView.frame) / 2.0))) {
				_vector.y = MIN(CGRectGetHeight(_racketView.frame), _vector.y + 1);	// increase speed
				_vector.y *= -1;
				_vector.x += kXFactor * (pos.x - CGRectGetMinX(_racketView.frame) - CGRectGetWidth(_racketView.frame) / 2.0) / (CGRectGetWidth(_racketView.frame) / 2.0);
				pos = CGPointMake(_ballView.center.x + _vector.x, _ballView.center.y + _vector.y);
			}
			else {
				[self reset];
				return;
			}
		}
	}
	_ballView.center = pos;
	if (_asServer)
		[[BOMTalk sharedTalk] sendToAllMessage:kGameBall withData: @{@"x": [NSNumber numberWithFloat:_ballView.center.x], @"y": [NSNumber numberWithFloat:_ballView.center.y]}];
}

- (IBAction) slide {
	_racketView.frame = CGRectMake(_slideView.value * (self.view.frame.size.width - _racketView.frame.size.width), CGRectGetMaxY(_areaView.frame) + CGRectGetHeight(_ballView.frame)/2.0, _racketView.frame.size.width, _racketView.frame.size.height);
}

#pragma mark table view delegates

- (NSInteger) tableView:(UITableView*) tableView numberOfRowsInSection:(NSInteger) section {
	return [BOMTalk sharedTalk].peerList.count;
}

- (UITableViewCell*) tableView:(UITableView*) tableView cellForRowAtIndexPath:(NSIndexPath*) indexPath {
	DLog(@"%@, %d", [BOMTalk sharedTalk].peerList, indexPath.row);
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PeerCell"];
	if (!cell)
		cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PeerCell"];
	BOMTalkPeer *peer = [BOMTalk sharedTalk].peerList[indexPath.row];
	cell.textLabel.text = peer.name;
	return cell;
}

- (void) tableView:(UITableView*) tableView didSelectRowAtIndexPath:(NSIndexPath*) indexPath {
	BOMTalk *talker = [BOMTalk sharedTalk];
	BOMTalkPeer *peer = talker.peerList[indexPath.row];
	if (peer.state == BOMTalkPeerStateConnected) {
		_listView.hidden = YES;
		[talker sendMessage:kGameStart toPeer:peer];
		_asServer = YES;
		_asClient = NO;
	}
	else
		[talker connectToPeer: peer];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
