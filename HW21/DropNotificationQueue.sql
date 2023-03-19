USE ACS

drop trigger PassEventInsertTrigger

drop procedure dbo.SendPassEventToNotificationQueue

drop service [//ACS/SB/NotificationService]

drop queue [dbo].[ACSNotificationQueue]

drop procedure dbo.CreateNotificationForNewPassEvent

drop service [//ACS/SB/PassEventSenderService]

drop queue [dbo].[ACSPassEventSenderQueue]

drop procedure dbo.ConfirmNewNotifications

drop contract [//ACS/SB/PassEventContract]

drop message type [//ACS/SB/PassEventRequestMessage]

drop message type [//ACS/SB/PassEventReplyMessage]