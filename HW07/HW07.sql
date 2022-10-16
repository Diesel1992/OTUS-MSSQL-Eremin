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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT| Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2       |     2
01.02.2013   |      7             |        3           |      4      |      2       |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

WITH CTE AS (
	SELECT 
		SUBSTRING(CustomerName, CHARINDEX('(', CustomerName) + 1, LEN(CustomerName) - CHARINDEX('(', CustomerName) - 1) DevisionName,
		DATEADD(MONTH, DATEDIFF(MONTH, 0, Invoices.InvoiceDate), 0) InvoiceMonth,
		InvoiceID
	FROM Sales.Invoices
	JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
	WHERE Customers.CustomerID BETWEEN 2 AND 6)
SELECT 
	CONVERT(nvarchar(10), InvoiceMonth, 104) InvoiceMonthStr, [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Sylvanite, MT], [Jessie, ND]
FROM CTE
PIVOT (COUNT(InvoiceID) FOR DevisionName IN (
	[Peeples Valley, AZ], 
	[Medicine Lodge, KS], 
	[Gasport, NY], 
	[Sylvanite, MT], 
	[Jessie, ND])) AS PivotTable
ORDER BY PivotTable.InvoiceMonth

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

WITH CTE AS (
	SELECT CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2
	FROM Sales.Customers
	WHERE CustomerName LIKE 'Tailspin Toys%'
	)
SELECT CustomerName, AddresLine
FROM CTE
UNPIVOT (AddresLine FOR AddressType IN (
	DeliveryAddressLine1, 
	DeliveryAddressLine2, 
	PostalAddressLine1, 
	PostalAddressLine2)) AS UnpivotTable 
ORDER BY CustomerName, AddressType

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

SELECT 
	CountryID,
	CountryName,
	Code
FROM
	(SELECT 
		CountryID, 
		CountryName,
		CONVERT(NVARCHAR(3), IsoNumericCode) AS IsoNumericCode, 
		IsoAlpha3Code
	FROM Application.Countries) AS Countries
UNPIVOT (Code FOR CodeType IN (IsoAlpha3Code, IsoNumericCode)) AS UnpivotTable
ORDER BY CountryID, CodeType 

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

SELECT CustomerID, CustomerName, StockItemID, UnitPrice, InvoiceDate
FROM Sales.Customers
OUTER APPLY (
	SELECT
		StockItemID,
		UnitPrice,
		Invoices.InvoiceDate,
		ROW_NUMBER() OVER(ORDER BY UnitPrice DESC) RN_MostExpensive,
		RANK() OVER(ORDER BY UnitPrice DESC) RNK_MostExpensive,
		DENSE_RANK() OVER(ORDER BY UnitPrice DESC) DRNK_MostExpensive
	FROM Sales.Invoices
	JOIN Sales.InvoiceLines ON InvoiceLines.InvoiceID = Invoices.InvoiceID
	WHERE Invoices.CustomerID = Customers.CustomerID) MostExpensive
WHERE (DRNK_MostExpensive <= 2) AND (RN_MostExpensive = RNK_MostExpensive)
ORDER BY CustomerName, DRNK_MostExpensive
