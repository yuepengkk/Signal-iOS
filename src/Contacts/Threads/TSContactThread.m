//  Created by Frederic Jacobs on 16/11/14.
//  Copyright (c) 2014 Open Whisper Systems. All rights reserved.

#import "TSContactThread.h"
#import "ContactsUpdater.h"
#import "TextSecureKitEnv.h"
#import <YapDatabase/YapDatabaseTransaction.h>

NS_ASSUME_NONNULL_BEGIN

#define TSContactThreadPrefix @"c"

@implementation TSContactThread

- (instancetype)initWithContactId:(NSString *)contactId {
    NSString *uniqueIdentifier = [[self class] threadIdFromContactId:contactId];

    self = [super initWithUniqueId:uniqueIdentifier];

    return self;
}

+ (instancetype)getOrCreateThreadWithContactId:(NSString *)contactId
                                   transaction:(YapDatabaseReadWriteTransaction *)transaction
                                         relay:(nullable NSString *)relay
{
    SignalRecipient *recipient =
        [SignalRecipient recipientWithTextSecureIdentifier:contactId withTransaction:transaction];

    if (!recipient) {
        recipient = [[SignalRecipient alloc] initWithTextSecureIdentifier:contactId relay:relay supportsVoice:YES];

        [[ContactsUpdater sharedUpdater] lookupIdentifier:contactId
            success:^(NSSet<NSString *> *matchedIds) {
            }
            failure:^(NSError *error) {
              DDLogInfo(@"Failed to retreive call status. Will be retreived on next contact intersection.");
            }];
        [recipient saveWithTransaction:transaction];
    }

    return [self getOrCreateThreadWithContactId:contactId transaction:transaction];
}

+ (instancetype)getOrCreateThreadWithContactId:(NSString *)contactId
                                   transaction:(YapDatabaseReadWriteTransaction *)transaction {
    TSContactThread *thread =
        [self fetchObjectWithUniqueID:[self threadIdFromContactId:contactId] transaction:transaction];

    if (!thread) {
        thread = [[TSContactThread alloc] initWithContactId:contactId];
        [thread saveWithTransaction:transaction];
    }

    return thread;
}

- (NSString *)contactIdentifier {
    return [[self class] contactIdFromThreadId:self.uniqueId];
}

- (BOOL)isGroupThread {
    return false;
}

- (NSString *)name {
    NSString *contactId = [self contactIdentifier];
    NSString *name      = [[TextSecureKitEnv sharedEnv].contactsManager nameStringForPhoneIdentifier:contactId];

    if (!name) {
        name = contactId;
    }

    return name;
}

#if TARGET_OS_IPHONE

- (nullable UIImage *)image
{
    UIImage *image = [[TextSecureKitEnv sharedEnv].contactsManager imageForPhoneIdentifier:self.contactIdentifier];
    return image;
}

#endif

+ (NSString *)threadIdFromContactId:(NSString *)contactId {
    return [TSContactThreadPrefix stringByAppendingString:contactId];
}

+ (NSString *)contactIdFromThreadId:(NSString *)threadId {
    return [threadId substringWithRange:NSMakeRange(1, threadId.length - 1)];
}

@end

NS_ASSUME_NONNULL_END
