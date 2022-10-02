/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
	YEAR(inv.InvoiceDate) [Year],
	MONTH(inv.InvoiceDate) [Month],
	AVG(inl.UnitPrice) AveragePrice,
	SUM(inl.UnitPrice * inl.Quantity) SummarySales
FROM Sales.Invoices inv
JOIN Sales.InvoiceLines inl ON inv.InvoiceID = inl.InvoiceID
GROUP BY YEAR(inv.InvoiceDate), MONTH(inv.InvoiceDate)
ORDER BY [Year], [Month]

/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
	YEAR(inv.InvoiceDate) [Year],
	MONTH(inv.InvoiceDate) [Month],
	SUM(inl.UnitPrice * inl.Quantity) SummarySales
FROM Sales.Invoices inv
JOIN Sales.InvoiceLines inl ON inv.InvoiceID = inl.InvoiceID
GROUP BY YEAR(inv.InvoiceDate), MONTH(inv.InvoiceDate)
HAVING SUM(inl.UnitPrice * inl.Quantity) > 4600000
ORDER BY [Year], [Month]

/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

SELECT 
	YEAR(inv.InvoiceDate) [Year],
	MONTH(inv.InvoiceDate) [Month],
	sit.StockItemName,
	SUM(inl.UnitPrice * inl.Quantity) SummarySales,
	MIN(inv.InvoiceDate) FirstInvoice,
	SUM(inl.Quantity) MonthQuantity
FROM Sales.Invoices inv
JOIN Sales.InvoiceLines inl ON inv.InvoiceID = inl.InvoiceID
JOIN Warehouse.StockItems sit ON inl.StockItemID = sit.StockItemID
GROUP BY YEAR(inv.InvoiceDate), MONTH(inv.InvoiceDate), sit.StockItemName
HAVING SUM(inl.Quantity) < 50
ORDER BY [Year], [Month]

-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/