/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

SELECT ppl.PersonID, ppl.FullName
FROM [Application].People ppl
WHERE (IsSalesperson = 1) AND NOT EXISTS (
	SELECT * 
	FROM Sales.Invoices inv
	WHERE (inv.SalespersonPersonID = ppl.PersonID)
		AND (inv.InvoiceDate = '2015-07-04'))

; WITH SalesPeople AS (SELECT SalespersonPersonID 
	FROM Sales.Invoices
	WHERE InvoiceDate = '2015-07-04')
SELECT ppl.PersonID, ppl.FullName
FROM [Application].People ppl
WHERE (IsSalesperson = 1) AND (ppl.PersonID NOT IN (SELECT SalespersonPersonID FROM SalesPeople))

/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

SELECT StockItemID, StockItemName, UnitPrice
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT MIN(UnitPrice) FROM Warehouse.StockItems)

; WITH MinUnitPrice (MinPrice) AS (
	SELECT MIN(UnitPrice) FROM Warehouse.StockItems)
SELECT StockItemID, StockItemName, UnitPrice
FROM Warehouse.StockItems
WHERE UnitPrice = (SELECT MinPrice FROM MinUnitPrice)

/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

SELECT * 
FROM Sales.Customers cst
WHERE cst.CustomerID IN (
	SELECT TOP(5) CustomerID 
	FROM Sales.CustomerTransactions
	ORDER BY TransactionAmount DESC)

; WITH MaxTransAmount (CustomerId, TransactionAmount) AS (
	SELECT TOP(5) CustomerId, TransactionAmount
	FROM Sales.CustomerTransactions 
	ORDER BY TransactionAmount DESC)
SELECT mta.TransactionAmount, cst.*
FROM Sales.Customers cst
JOIN MaxTransAmount mta ON cst.CustomerID = mta.CustomerId
ORDER BY mta.TransactionAmount DESC

/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

SELECT DISTINCT ct.CityID, ct.CityName, CitInfo.Picker
FROM Application.Cities ct
JOIN (
	SELECT cst.DeliveryCityID, OrdInfo.Picker 
	FROM Sales.Customers cst
	JOIN (
		SELECT ord.CustomerID, ISNULL(ppl.FullName, 'Unknown') Picker
		FROM Sales.Orders ord
		JOIN (
			SELECT orl.OrderID
			FROM Sales.OrderLines orl
			JOIN (
				SELECT TOP (3) StockItemID
				FROM Warehouse.StockItems
				ORDER BY UnitPrice DESC
				) ExpIt ON orl.StockItemID = ExpIt.StockItemID
			) ExpOrd ON ord.OrderId = ExpOrd.OrderID
		LEFT JOIN Application.People ppl ON Ord.PickedByPersonID = ppl.PersonID
		) OrdInfo ON cst.CustomerID = OrdInfo.CustomerID		
	) CitInfo ON CitInfo.DeliveryCityID = ct.CityID

; WITH MostExpensiveItems (StockItemID) AS (
	SELECT TOP (3) StockItemID
	FROM Warehouse.StockItems
	ORDER BY UnitPrice DESC)
, OrderIdsWithMostExpensiveItems (OrderId) AS (
	SELECT orl.OrderID
	FROM Sales.OrderLines orl
	JOIN MostExpensiveItems ExpIt ON orl.StockItemID = ExpIt.StockItemID)
, OrderInfoWithMostExpensiveItems (CustomerID, PickerId) AS (
	SELECT ord.CustomerID, Ord.PickedByPersonID PickerId
	FROM Sales.Orders ord
	JOIN OrderIdsWithMostExpensiveItems ExpOrd ON ord.OrderId = ExpOrd.OrderID)
, CitiesIdsAndPickerIds (CityId, PickerId) AS (
	SELECT cst.DeliveryCityID, oi.PickerId 
	FROM Sales.Customers cst
	JOIN OrderInfoWithMostExpensiveItems oi ON oi.CustomerID = cst.CustomerID)
SELECT ct.CityID, ct.CityName, ISNULL(ppl.FullName, 'Unknown') PickerName
FROM CitiesIdsAndPickerIds cpi
JOIN Application.Cities ct ON cpi.CityId = ct.CityID
LEFT JOIN Application.People ppl ON cpi.PickerId = ppl.PersonID
ORDER BY CityName, CityID, PickerName

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --
-- Запрос выбирает покупки на общую сумму более 27000, 
-- сортирует их по убыванию общей суммы, 
-- выводит Id покупки, дату, имя продавца, общую сумму покупки, 
-- и общую сумму уже собранных товаров заказа

; WITH SalesTotals (InvoiceId, TotalSumm) AS (
	SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000)
, PickedOrders (OrderId) AS (
	SELECT Orders.OrderId 
	FROM Sales.Orders
	WHERE Orders.PickingCompletedWhen IS NOT NULL)
, PickedTotals (OrderId, TotalPickedSumm) AS (
	SELECT OrderId, SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
	FROM Sales.OrderLines
	GROUP BY OrderLines.OrderId)
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	People.FullName AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	PickedTotals.TotalPickedSumm AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN SalesTotals ON Invoices.InvoiceID = SalesTotals.InvoiceID
	JOIN Application.People ON People.PersonID = Invoices.SalespersonPersonID
	LEFT JOIN PickedOrders ON PickedOrders.OrderId = Invoices.OrderID
	LEFT JOIN PickedTotals ON PickedOrders.OrderId = PickedTotals.OrderID
ORDER BY TotalSumm DESC

-- Как мне кажется, стало более читаемо, но если верить действительному плану выполнения,
-- быстрее не стало, хотя что-то изменилось. К сожалению, даже после занятия по планам
-- эти диаграммы мне ничего не говорят, поэтому я не понимаю, как можно ускорить выполнение
-- данного запроса. Надеюсь на Вашу помощь в данном вопросе.