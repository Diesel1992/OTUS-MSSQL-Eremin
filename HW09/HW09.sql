Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

INSERT INTO Sales.Customers (
	CustomerName, 
	BillToCustomerID, 
	CustomerCategoryID, 
	PrimaryContactPersonID, 
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	AccountOpenedDate,
	StandardDiscountPercentage,
	IsStatementSent,
	IsOnCreditHold,
	PaymentDays,
	PhoneNumber,
	FaxNumber,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryPostalCode,
	PostalAddressLine1,
	PostalPostalCode,
	LastEditedBy)
VALUES 
	(N'Детский мир', 1, 8, 1, 1, 1, 1, '2010-01-01', 10, 1, 0, 3, '88005553535', '88005553535', 'www.leningradspb.ru',
	N'Советский союз', '123456', N'РФ', '654321',	9),
	(N'Взрослый мир', 1, 8, 1, 1, 1, 1, '2010-01-01', 10, 1, 0, 3, '88005553535', '88005553535', 'www.leningradspb.ru',
	N'Советский союз', '123456', N'РФ', '654321',	9),
	(N'Подростковый мир', 1, 8, 1, 1, 1, 1, '2010-01-01', 10, 1, 0, 3, '88005553535', '88005553535', 'www.leningradspb.ru',
	N'Советский союз', '123456', N'РФ', '654321',	9),
	(N'Престарелый мир', 1, 8, 1, 1, 1, 1, '2010-01-01', 10, 1, 0, 3, '88005553535', '88005553535', 'www.leningradspb.ru',
	N'Советский союз', '123456',	N'РФ', '654321',	9),
	(N'Универсальный мир', 1, 8, 1, 1, 1, 1, '2010-01-01', 10, 1, 0, 3, '88005553535', '88005553535', 'www.leningradspb.ru',
	N'Советский союз', '123456',	N'РФ', '654321',	9)

/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

DELETE 
FROM Sales.Customers
WHERE CustomerName = N'Детский мир'
--WHERE PhoneNumber = '88005553535' 

/*
3. Изменить одну запись, из добавленных через UPDATE
*/

UPDATE Sales.Customers
SET DeliveryPostalCode = '111111'
WHERE CustomerName = N'Престарелый мир'

/*
4. Написать MERGE, который вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/

MERGE Sales.Customers
USING (VALUES (N'Универсальный мир', 1, 8, 1, 1, 1, 1, '2010-01-01', 10, 1, 0, 3, '88005553535', '88005553535', 'www.leningradspb.ru',
	N'Советский союз', '666666',	N'РФ', '654321',	9)) AS NewCustomer (
	CustomerName, 
	BillToCustomerID, 
	CustomerCategoryID, 
	PrimaryContactPersonID, 
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	AccountOpenedDate,
	StandardDiscountPercentage,
	IsStatementSent,
	IsOnCreditHold,
	PaymentDays,
	PhoneNumber,
	FaxNumber,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryPostalCode,
	PostalAddressLine1,
	PostalPostalCode,
	LastEditedBy)
	ON Customers.CustomerName = NewCustomer.CustomerName
WHEN MATCHED THEN
	UPDATE SET Customers.DeliveryPostalCode = NewCustomer.DeliveryPostalCode
WHEN NOT MATCHED THEN
	INSERT (
	CustomerName, 
	BillToCustomerID, 
	CustomerCategoryID, 
	PrimaryContactPersonID, 
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	AccountOpenedDate,
	StandardDiscountPercentage,
	IsStatementSent,
	IsOnCreditHold,
	PaymentDays,
	PhoneNumber,
	FaxNumber,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryPostalCode,
	PostalAddressLine1,
	PostalPostalCode,
	LastEditedBy)
	VALUES (
	CustomerName, 
	BillToCustomerID, 
	CustomerCategoryID, 
	PrimaryContactPersonID, 
	DeliveryMethodID,
	DeliveryCityID,
	PostalCityID,
	AccountOpenedDate,
	StandardDiscountPercentage,
	IsStatementSent,
	IsOnCreditHold,
	PaymentDays,
	PhoneNumber,
	FaxNumber,
	WebsiteURL,
	DeliveryAddressLine1,
	DeliveryPostalCode,
	PostalAddressLine1,
	PostalPostalCode,
	LastEditedBy);

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

EXEC sp_configure 'show advanced options', 1;  
GO  
-- To update the currently configured value for advanced options.  
RECONFIGURE;  
GO  
-- To enable the feature.  
EXEC sp_configure 'xp_cmdshell', 1;  
GO  
-- To update the currently configured value for this feature.  
RECONFIGURE;  
GO 

exec master..xp_cmdshell 'bcp "[WideWorldImporters].[Sales].[Customers]" out "C:\Temp\Customers.txt" -T -w -t,,,'

SELECT * INTO Sales.Customers_Copy
FROM Sales.Customers
WHERE 1=2

BULK INSERT [WideWorldImporters].[Sales].[Customers_Copy]
				FROM "C:\Temp\Customers.txt"
				WITH 
					(
					BATCHSIZE = 1000, 
					DATAFILETYPE = 'widechar',
					FIELDTERMINATOR = ',,,',
					ROWTERMINATOR ='\n',
					KEEPNULLS,
					TABLOCK        
					);

SELECT *
FROM Sales.Customers_Copy

DROP TABLE Sales.Customers_Copy

SELECT *
FROM Sales.Customers
WHERE PhoneNumber = '88005553535'

DELETE 
FROM Sales.Customers
WHERE PhoneNumber = '88005553535' 