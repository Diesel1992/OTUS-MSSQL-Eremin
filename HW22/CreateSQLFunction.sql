sp_configure 'show advanced options', 1;
GO
RECONFIGURE;
GO
sp_configure 'clr enabled', 1;
GO
RECONFIGURE;
GO

Create ASSEMBLY AlphaNumeric 
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL14.MSSQLSERVER\MSSQL\SQLAlphaNumericSort.dll'
WITH PERMISSION_SET = SAFE;
GO

CREATE FUNCTION [dbo].GetAlphaNumericOrderToken (@str nvarchar(50))
RETURNS nvarchar(60)
AS EXTERNAL NAME [AlphaNumeric].[AlphaNumericSort].[GetAlphaNumericOrderToken];
GO

select *
from Department
order by Name

select *
from Department
order by dbo.GetAlphaNumericOrderToken(Name)