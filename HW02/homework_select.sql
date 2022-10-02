/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID, StockItemName
FROM Warehouse.StockItems
WHERE (StockItemName LIKE '%urgent%') OR (StockItemName LIKE 'Animal%')

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

SELECT sup.SupplierID, sup.SupplierName
FROM Purchasing.Suppliers sup
LEFT JOIN Purchasing.PurchaseOrders ord ON sup.SupplierID = ord.SupplierID
WHERE ord.SupplierID IS NULL

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

SELECT --DISTINCT -- Нельзя использовать, так как сортируем по полю, которое не выбирается. Как быть?
	ord.OrderID,
	CONVERT(NVARCHAR(10), ord.OrderDate, 104) OrderDate,
	DATENAME(MONTH, ord.OrderDate) OrderMonth,
	DATEPART(QUARTER, ord.OrderDate) OrderQuarter, 
	(DATEPART(MONTH, ord.OrderDate) - 1) / 4 + 1 OrderThird,
	cus.CustomerName
FROM Sales.Orders ord
JOIN Sales.OrderLines ol ON ord.OrderID = ol.OrderID
JOIN Sales.Customers cus ON ord.CustomerID = cus.CustomerID
WHERE ((ol.UnitPrice > 100) OR (ol.Quantity > 20)) AND (ord.PickingCompletedWhen IS NOT NULL)
ORDER BY OrderQuarter, OrderThird, ord.OrderDate

-- постраничный вывод
DECLARE 
	@pagesize BIGINT = 100, -- Размер страницы
	@pagenum  BIGINT = 11;  -- Номер страницы
SELECT --DISTINCT -- Нельзя использовать, так как сортируем по полю, которое не выбирается. Как быть?
	ord.OrderID,
	CONVERT(NVARCHAR(10), ord.OrderDate, 104) OrderDate,
	DATENAME(MONTH, ord.OrderDate) OrderMonth,
	DATEPART(QUARTER, ord.OrderDate) OrderQuarter, 
	(DATEPART(MONTH, ord.OrderDate) - 1) / 4 + 1 OrderThird,
	cus.CustomerName
FROM Sales.Orders ord
JOIN Sales.OrderLines ol ON ord.OrderID = ol.OrderID
JOIN Sales.Customers cus ON ord.CustomerID = cus.CustomerID
WHERE ((ol.UnitPrice > 100) OR (ol.Quantity > 20)) AND (ord.PickingCompletedWhen IS NOT NULL)
ORDER BY OrderQuarter, OrderThird, ord.OrderDate
OFFSET (@pagenum - 1) * @pagesize ROWS FETCH NEXT @pagesize ROWS ONLY; -- когда нужно указывать FETCH NEXT, а когда FETCH FIRST?

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

SELECT 
	dm.DeliveryMethodName,
	ord.ExpectedDeliveryDate,
	sup.SupplierName,
	ppl.FullName
FROM Purchasing.PurchaseOrders ord
JOIN Purchasing.Suppliers sup ON ord.SupplierID = sup.SupplierID
JOIN Application.DeliveryMethods dm ON ord.DeliveryMethodID = dm.DeliveryMethodID
JOIN Application.People ppl ON ord.ContactPersonID = ppl.PersonID
WHERE (ord.ExpectedDeliveryDate BETWEEN '2013-01-01' AND '2013-01-31') 
	AND ((dm.DeliveryMethodName = 'Air Freight') OR (dm.DeliveryMethodName = 'Refrigerated Air Freight'))
	AND (ord.IsOrderFinalized = 1)

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

SELECT TOP(10)
	cus.CustomerName ClientName,
	ppl.FullName EmployeeName
FROM Sales.Invoices inv
JOIN Sales.Customers cus ON inv.CustomerID = cus.CustomerID
JOIN Application.People ppl ON inv.SalespersonPersonID = ppl.PersonID
ORDER BY inv.InvoiceDate DESC

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

SELECT DISTINCT 
	cus.CustomerID, 
	cus.CustomerName,
	cus.PhoneNumber
FROM Sales.Invoices inv
JOIN Sales.InvoiceLines inl ON inv.InvoiceID = inl.InvoiceID
JOIN Warehouse.StockItems sit ON inl.StockItemID = sit.StockItemID
JOIN Sales.Customers cus ON inv.CustomerID = cus.CustomerID
WHERE sit.StockItemName = 'Chocolate frogs 250g'