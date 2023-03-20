-- Включаем Service Broker
USE master

ALTER DATABASE ACS

SET ENABLE_BROKER WITH NO_WAIT; -- Не помогает, всё равно зависает

ALTER DATABASE ACS SET TRUSTWORTHY ON;

ALTER AUTHORIZATION    
   ON DATABASE::ACS TO [sa];
GO

-- Задаём типы сообщений
USE ACS
-- For Request
CREATE MESSAGE TYPE 
-- По какому принципу мы задаём имя типа?
[//ACS/SB/PassEventRequestMessage]
VALIDATION=WELL_FORMED_XML;
-- For Reply
CREATE MESSAGE TYPE
-- По какому принципу мы задаём имя типа?
[//ACS/SB/PassEventReplyMessage]
VALIDATION=WELL_FORMED_XML; 

-- Задаём контракт
CREATE CONTRACT [//ACS/SB/PassEventContract]
      ([//ACS/SB/PassEventRequestMessage]
         SENT BY INITIATOR,
       [//ACS/SB/PassEventReplyMessage]
         SENT BY TARGET
      );

GO

-- Создаём очереди
CREATE QUEUE ACSNotificationQueue;

CREATE SERVICE [//ACS/SB/NotificationService]
       ON QUEUE ACSNotificationQueue
       ([//ACS/SB/PassEventContract]);

CREATE QUEUE ACSPassEventSenderQueue;

CREATE SERVICE [//ACS/SB/PassEventSenderService]
       ON QUEUE ACSPassEventSenderQueue
       ([//ACS/SB/PassEventContract]);

GO

-- Создаем процедуру отправки нового события прохода в очередь оповещений
CREATE OR ALTER PROCEDURE dbo.SendPassEventToNotificationQueue
	@PassEventId INT
AS
BEGIN
	SET NOCOUNT ON;

    --Sending a Request Message to the Target	
	DECLARE @InitDlgHandle UNIQUEIDENTIFIER;
	DECLARE @RequestMessage NVARCHAR(4000);
	
	BEGIN TRAN 

	--Prepare the Message
	SELECT @RequestMessage = (SELECT Id PassEventId
							  FROM dbo.PassEvent AS PassEvent
							  WHERE Id = @PassEventId
							  FOR XML AUTO, root('RequestMessage')); 
	
	--Determine the Initiator Service, Target Service and the Contract 
	BEGIN DIALOG @InitDlgHandle
	FROM SERVICE
	[//ACS/SB/PassEventSenderService]
	TO SERVICE
	'//ACS/SB/NotificationService'
	ON CONTRACT
	[//ACS/SB/PassEventContract]
	WITH ENCRYPTION=OFF; 

	--Send the Message
	SEND ON CONVERSATION @InitDlgHandle 
	MESSAGE TYPE
	[//ACS/SB/PassEventRequestMessage]
	(@RequestMessage);
	
	--SELECT @RequestMessage AS SentRequestMessage;
	
	COMMIT TRAN 
END

GO

-- Создаем процедуру создания оповещений из очереди новых проходов
CREATE OR ALTER PROCEDURE dbo.CreateNotificationForNewPassEvent
AS
BEGIN

	DECLARE @TargetDlgHandle UNIQUEIDENTIFIER,
			@Message NVARCHAR(4000),
			@MessageType Sysname,
			@ReplyMessage NVARCHAR(4000),
			@ReplyMessageName Sysname,
			@PassEventId INT,
			@xml XML; 
	
	BEGIN TRAN; 

	--Receive message from Initiator
	RECEIVE TOP(1)
		@TargetDlgHandle = Conversation_Handle,
		@Message = Message_Body,
		@MessageType = Message_Type_Name
	FROM dbo.ACSNotificationQueue; 

	--SELECT @Message;

	SET @xml = CAST(@Message AS XML);

	SELECT @PassEventId = xmlPassEvent.PassEvent.value('@PassEventId','INT')
	FROM @xml.nodes('/RequestMessage/PassEvent') as xmlPassEvent(PassEvent);

	Insert into Notification (PassEventId
	, NotificationChannelId
	)
	select PassEvent.Id
	, NotPers.NotificationChannelId
	from PassEvent
	join NotificationChannelForPersonPass NotPers on NotPers.PersonId = PassEvent.PersonId
	where PassEvent.Id = @PassEventId

	--SELECT @Message AS ReceivedRequestMessage, @MessageType; 
	
	-- Confirm and Send a reply
	IF @MessageType=N'//ACS/SB/PassEventRequestMessage'
	BEGIN
		SET @ReplyMessage =N'<ReplyMessage>Notifications created.</ReplyMessage>'; 
	
		SEND ON CONVERSATION @TargetDlgHandle
		MESSAGE TYPE
		[//ACS/SB/PassEventReplyMessage]
		(@ReplyMessage);
		END CONVERSATION @TargetDlgHandle;
	END 
	
	--SELECT @ReplyMessage AS SentReplyMessage; 

	COMMIT TRAN;
END

GO

-- Создаем процедуру подтверждения создания новых оповещений
CREATE OR ALTER PROCEDURE dbo.ConfirmNewNotifications
AS
BEGIN
	--Receiving Reply Message from the Target.	
	DECLARE @InitiatorReplyDlgHandle UNIQUEIDENTIFIER,
			@ReplyReceivedMessage NVARCHAR(1000) 
	
	BEGIN TRAN; 

		RECEIVE TOP(1) @InitiatorReplyDlgHandle=Conversation_Handle
			, @ReplyReceivedMessage=Message_Body
		FROM dbo.ACSPassEventSenderQueue; 
		
		END CONVERSATION @InitiatorReplyDlgHandle; 
		
		--SELECT @ReplyReceivedMessage AS ReceivedRepliedMessage; 

	COMMIT TRAN; 
END

GO 

-- Настраиваем очереди
ALTER QUEUE [dbo].[ACSPassEventSenderQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF) 
	, ACTIVATION (   STATUS = ON ,
        PROCEDURE_NAME = dbo.ConfirmNewNotifications, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO

ALTER QUEUE [dbo].[ACSNotificationQueue] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = OFF)
	, ACTIVATION (  STATUS = ON ,
        PROCEDURE_NAME = dbo.CreateNotificationForNewPassEvent, MAX_QUEUE_READERS = 1, EXECUTE AS OWNER) ; 

GO

/* Для проверки
exec SendPassEventToNotificationQueue @PassEventId = 1

SELECT * 
FROM dbo.ACSNotificationQueue;

exec dbo.CreateNotificationForNewPassEvent

SELECT TOP (1000) [Id]
      ,[PassEventId]
      ,[NotificationStatusId]
      ,[NotificationChannelId]
      ,[StatusUpdateTime]
  FROM [ACS].[dbo].[Notification]

SELECT * 
FROM dbo.ACSPassEventSenderQueue;

exec dbo.ConfirmNewNotifications

*/

GO

-- Создаем триггер на новые события прохода
create or alter trigger PassEventInsertTrigger on PassEvent after insert as
begin
  declare @PassEventId int
  declare PassEventCursor cursor fast_forward for
    select Id
    from inserted
	order by Id

  open PassEventCursor

  FETCH NEXT FROM PassEventCursor   
  INTO @PassEventId
  
  WHILE @@FETCH_STATUS = 0  
  BEGIN  
    Exec SendPassEventToNotificationQueue @PassEventId
    FETCH NEXT FROM PassEventCursor   
    INTO @PassEventId
  END   
  CLOSE PassEventCursor;  
  DEALLOCATE PassEventCursor;  
end

-- Заполняем таблицу проходов
exec FillPassEventForPerson @PersonId = 3, @PassSourceId = 1, @DaysCount = 14

-- Получаем статистику
declare @StartDate date = DateAdd(day, -6, getdate()) 
declare @RootDeptId int = 1

select DeptName [Класс]
, PassDate [Дата]
, IncomedPeopleCount [Количество посетивших людей]
, AllPeopleCount [Общее количество людей]
, IncomedPercent [Процент посетивших людей] 
from PassStatistic
where (ParentDepartmentId = @RootDeptId or DeptId = @RootDeptId)
  and PassDate >= @StartDate