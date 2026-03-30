#import <Foundation/Foundation.h>

@interface NCNotificationContent : NSObject
@property (nonatomic, copy, readonly) NSString *title;
@property (nonatomic, copy, readonly) NSString *subtitle;
@property (nonatomic, copy, readonly) NSString *message;
@end

@interface NCNotificationRequest : NSObject
@property (nonatomic, copy, readonly) NSString *sectionIdentifier;
@property (nonatomic, readonly) NCNotificationContent *content;
@end

%hook SBNCNotificationDispatcher
- (void)postNotificationRequest:(NCNotificationRequest *)request forDestination:(id)destination {
    NSLog(@"[RCNotifTest] SBNCNotificationDispatcher hit! %@ - %@ - %@", request.sectionIdentifier, request.content.title, request.content.message);
    %orig;
}
%end

%hook NCNotificationDispatcher
- (void)postNotificationRequest:(NCNotificationRequest *)request forDestination:(id)destination {
    NSLog(@"[RCNotifTest] NCNotificationDispatcher hit! %@ - %@ - %@", request.sectionIdentifier, request.content.title, request.content.message);
    %orig;
}
%end
