use ACS

--�������� �������� ������
ALTER DATABASE ACS ADD FILEGROUP [QuarterData]
GO

--��������� ���� ��
ALTER DATABASE ACS ADD FILE 
( NAME = N'Quarters', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\DATA\QuarterData.ndf' , 
SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [QuarterData]
GO

--������� ������� ����������������� �� ���������
CREATE PARTITION FUNCTION [fnQuarterPartition](DateTime2) AS RANGE RIGHT FOR VALUES
('20220101','20220401','20220701','20221001');																																																									
GO

-- ��������������, ��������� ��������� �������
CREATE PARTITION SCHEME [schmQuarterPartition] AS PARTITION [fnQuarterPartition] 
ALL TO ([QuarterData])
GO

-- ������� ����������� �������� �����
ALTER TABLE [dbo].[Notification] DROP CONSTRAINT [PassEventForNotification]
GO

-- ������ ��������� ���� ������������
ALTER TABLE dbo.PassEvent DROP CONSTRAINT PK__PassEven__3214EC07B76F511A

ALTER TABLE dbo.PassEvent ADD CONSTRAINT PK__PassEven__3214EC07B76F511A
PRIMARY KEY NONCLUSTERED  (Id)

-- ��������������� �����������
ALTER TABLE [dbo].[Notification]  WITH CHECK ADD CONSTRAINT [PassEventForNotification] FOREIGN KEY([PassEventId])
REFERENCES [dbo].[PassEvent] ([Id])
GO

-- ������� ���������� ������ �� ����� �����������������
Create clustered index PassEventDateTimeIdx on PassEvent(PassDateTime)
 ON [schmQuarterPartition](PassDateTime);

--������� ����� ������� ����������������
select distinct t.name
from sys.partitions p
inner join sys.tables t
	on p.object_id = t.object_id
where p.partition_number <> 1

-- ��������� �������
exec FillPassEventForPerson 3, 2, 300
exec FillPassEventForPerson 2, 2, 400
exec FillPassEventForPerson 1, 2, 100
exec FillPassEventForPerson 4, 2, 200

--������� ��� ��������� �� ���������� �������������� ������
SELECT  $PARTITION.[fnQuarterPartition](PassDateTime) AS Partition
		, COUNT(*) AS [COUNT]
		, MIN(PassDateTime)
		,MAX(PassDateTime) 
FROM PassEvent
GROUP BY $PARTITION.[fnQuarterPartition](PassDateTime)
ORDER BY Partition ; 