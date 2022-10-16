/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

WITH MonthTotals (Months, MonthTotal) AS (
	SELECT DATEDIFF(MONTH, 0, InvoiceDate) Months, SUM(InvoiceLines.Quantity*InvoiceLines.UnitPrice) MonthTotal
	FROM Sales.InvoiceLines
	JOIN Sales.Invoices ON InvoiceLines.InvoiceID = Invoices.InvoiceID
	WHERE InvoiceDate >= '2015-01-01'
	GROUP BY DATEDIFF(MONTH, 0, InvoiceDate))
, MonthRunningTotals (Months, MonthRunningTotal) AS (
	SELECT Months, MonthTotal
	FROM MonthTotals
	WHERE Months <= ALL (SELECT Months FROM MonthTotals)
	UNION ALL
	SELECT MonthTotals.Months, MonthRunningTotal + MonthTotal
	FROM MonthTotals
	JOIN MonthRunningTotals ON MonthRunningTotals.Months = MonthTotals.Months - 1)
, InvoiceDays AS (
	SELECT InvoiceDate
	FROM Sales.Invoices
	GROUP BY InvoiceDate)
SELECT InvoiceDate, MonthRunningTotal, DATEPART(YEAR, DATEADD(MONTH, Months, 0)) [Year], DATENAME(MONTH, DATEADD(MONTH, Months, 0)) [Month]
FROM InvoiceDays
JOIN MonthRunningTotals ON DATEDIFF(MONTH, 0, InvoiceDate) = Months
ORDER BY InvoiceDate

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/
WITH MonthTotals (Months, MonthTotal) AS (
	SELECT DATEDIFF(MONTH, 0, InvoiceDate) Months, SUM(InvoiceLines.Quantity*InvoiceLines.UnitPrice) MonthTotal
	FROM Sales.InvoiceLines
	JOIN Sales.Invoices ON InvoiceLines.InvoiceID = Invoices.InvoiceID
	WHERE InvoiceDate >= '2015-01-01'
	GROUP BY DATEDIFF(MONTH, 0, InvoiceDate))
, MonthRunningTotals (Months, MonthRunningTotal) AS (
	SELECT Months, SUM(MonthTotal) OVER(ORDER BY Months) MonthRunningTotal 
	FROM MonthTotals)
, InvoiceDays AS (
	SELECT InvoiceDate
	FROM Sales.Invoices
	GROUP BY InvoiceDate)
SELECT InvoiceDate, MonthRunningTotal, DATEPART(YEAR, DATEADD(MONTH, Months, 0)) [Year], DATENAME(MONTH, DATEADD(MONTH, Months, 0)) [Month]
FROM InvoiceDays
JOIN MonthRunningTotals ON DATEDIFF(MONTH, 0, InvoiceDate) = Months
ORDER BY InvoiceDate

SELECT
	Invoices.InvoiceDate, 
	(SUM(line.Quantity * line.UnitPrice)) as InvoiceSum, 
	SUM(SUM(line.Quantity * line.UnitPrice)) OVER(ORDER BY EOMONTH(Invoices.InvoiceDate) RANGE UNBOUNDED PRECEDING) as RunningTotal
FROM Sales.Invoices
JOIN Sales.InvoiceLines as line on Invoices.InvoiceID=line.InvoiceID
WHERE Invoices.InvoiceDate >= '20150101'
GROUP BY InvoiceDate
ORDER BY InvoiceDate
/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

; WITH MonthItemQuantity AS (
	SELECT
		MONTH(InvoiceDate) [Month], 
		DATENAME(MONTH, DATEADD(MONTH, MONTH(InvoiceDate) - 1, 0)) [MonthName], 
		StockItems.StockItemName,
		SUM(InvoiceLines.Quantity) [MonthQuantity],
		ROW_NUMBER() OVER (PARTITION BY MONTH(InvoiceDate) ORDER BY SUM(InvoiceLines.Quantity) DESC) RowNumber
	FROM Sales.InvoiceLines
	JOIN Warehouse.StockItems ON InvoiceLines.StockItemID = StockItems.StockItemID
	JOIN Sales.Invoices ON InvoiceLines.InvoiceID = Invoices.InvoiceID
	WHERE InvoiceDate BETWEEN '2016-01-01' AND '2016-12-31'
	GROUP BY MONTH(InvoiceDate), StockItems.StockItemName
	)
SELECT [MonthName], StockItemName, [MonthQuantity]
FROM MonthItemQuantity
WHERE RowNumber <= 2
ORDER BY [Month], RowNumber

/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

SELECT StockItemID, StockItemName, Brand, UnitPrice,
	ROW_NUMBER() OVER(PARTITION BY LEFT(StockItemName, 1) ORDER BY StockItemName) RN_Name,
	COUNT(*) OVER() CommonCount,
	COUNT(*) OVER(PARTITION BY LEFT(StockItemName, 1)) FirstSymbolCount,
	LEAD(StockItemID) OVER(ORDER BY StockItemName) NextStockItemID,
	LAG(StockItemID) OVER(ORDER BY StockItemName) PreviousStockItemID,
	LAG(StockItemName, 2, 'No items') OVER(ORDER BY StockItemName) Previous2StockItemName,
	NTILE(30) OVER(ORDER BY TypicalWeightPerUnit) WeightGroup
FROM Warehouse.StockItems
ORDER BY StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

SELECT TOP(1) WITH TIES SalespersonPersonID, People.FullName, Customers.CustomerID, CustomerName, InvoiceDate, 
	SUM(InvoiceLines.Quantity*InvoiceLines.UnitPrice) OVER(PARTITION BY Invoices.InvoiceID) InvoiceTotal
FROM Sales.Invoices
JOIN Sales.InvoiceLines ON Invoices.InvoiceID = InvoiceLines.InvoiceID
JOIN Application.People ON SalespersonPersonID = PersonID
JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
ORDER BY ROW_NUMBER() OVER(PARTITION BY SalespersonPersonID ORDER BY InvoiceDate DESC)

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

; WITH MostExpensiveItems AS (
	SELECT 
		Customers.CustomerID,
		Customers.CustomerName,
		StockItemID,
		UnitPrice,
		Invoices.InvoiceDate,
		ROW_NUMBER() OVER(PARTITION BY Customers.CustomerID ORDER BY UnitPrice DESC) RN_MostExpensive,
		RANK() OVER(PARTITION BY Customers.CustomerID ORDER BY UnitPrice DESC) RNK_MostExpensive,
		DENSE_RANK() OVER(PARTITION BY Customers.CustomerID ORDER BY UnitPrice DESC) DRNK_MostExpensive
	FROM Sales.Invoices
	JOIN Sales.InvoiceLines ON InvoiceLines.InvoiceID = Invoices.InvoiceID
	JOIN Sales.Customers ON Customers.CustomerID = Invoices.CustomerID)
SELECT 
	CustomerID,
	CustomerName,
	StockItemID,
	UnitPrice,
	InvoiceDate
FROM MostExpensiveItems
WHERE (DRNK_MostExpensive <= 2) AND (RN_MostExpensive = RNK_MostExpensive)
ORDER BY CustomerName, RNK_MostExpensive

-- Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 
-- Не понял, какие именно задания нужно сделать с оконными? Они же все сделаны через оконные...