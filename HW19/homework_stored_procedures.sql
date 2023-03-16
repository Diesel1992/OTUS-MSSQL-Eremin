/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "12 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters;

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

GO

CREATE OR ALTER FUNCTION Sales.fGetCustomerNameWithMostExpensiveInvoice()
RETURNS TABLE 
AS
RETURN 
(
	select top(1) Customers.CustomerName
	from Sales.Invoices with (readcommitted) -- Единоразовый запрос на чтение без транзакций, поэтому нужно предотвратить лишь аномалию Dirty read
	join Sales.InvoiceLines with (readcommitted) on InvoiceLines.InvoiceID = Invoices.InvoiceID
	join Sales.Customers with (readcommitted) on Customers.CustomerID = Invoices.CustomerID
	group by Customers.CustomerName
	-- Так как нужно вывести покупателя с наибольшой суммой покупкИ (одной), то группируем ещё и по покупкам (если по всем покупкам - закомментировать)
	, Invoices.InvoiceID
	order by Sum(InvoiceLines.UnitPrice * InvoiceLines.Quantity) Desc
)

GO

Select *
from Sales.fGetCustomerNameWithMostExpensiveInvoice()

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

GO

CREATE OR ALTER PROCEDURE Sales.pCalcCustomerSumOfInvoices @ACustomerID int
AS
BEGIN 
	select Sum(InvoiceLines.UnitPrice * InvoiceLines.Quantity) CustomerInvoicesSum
	-- Так как нужно вывести покупателя с общей суммой покупкОК (всех), то не группируем 
	--, Invoices.InvoiceID
	from Sales.Invoices with (readcommitted) -- Единоразовый запрос на чтение без транзакций, поэтому нужно предотвратить лишь аномалию Dirty read
	join Sales.InvoiceLines with (readcommitted) on InvoiceLines.InvoiceID = Invoices.InvoiceID
	where Invoices.CustomerID = @ACustomerID
	-- Так как нужно вывести покупателя с общей суммой покупкОК (всех), то не группируем 
	--group by Invoices.InvoiceID
END

GO

EXEC Sales.pCalcCustomerSumOfInvoices @ACustomerID = 1003

/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/


GO

CREATE OR ALTER FUNCTION Sales.fGetCustomerInvoicesSum (@ACustomerID int)
RETURNS TABLE 
AS
RETURN 
	select Sum(InvoiceLines.UnitPrice * InvoiceLines.Quantity) CustomerInvoiceSum
	-- Так как нужно вывести суммы покупкОК (всех), то группируем 
	, Invoices.InvoiceID
	from Sales.Invoices with (readcommitted) -- Единоразовый запрос на чтение без транзакций, поэтому нужно предотвратить лишь аномалию Dirty read
	join Sales.InvoiceLines with (readcommitted) on InvoiceLines.InvoiceID = Invoices.InvoiceID
	where Invoices.CustomerID = @ACustomerID
	-- Так как нужно вывести суммы покупкОК (всех), то группируем
	group by Invoices.InvoiceID

GO

GO

CREATE OR ALTER PROCEDURE Sales.pGetCustomerInvoicesSum @ACustomerID int
AS
BEGIN 
	select Sum(InvoiceLines.UnitPrice * InvoiceLines.Quantity) CustomerInvoiceSum
	-- Так как нужно вывести суммы покупкОК (всех), то группируем 
	, Invoices.InvoiceID
	from Sales.Invoices with (readcommitted) -- Единоразовый запрос на чтение без транзакций, поэтому нужно предотвратить лишь аномалию Dirty read
	join Sales.InvoiceLines with (readcommitted) on InvoiceLines.InvoiceID = Invoices.InvoiceID
	where Invoices.CustomerID = @ACustomerID
	-- Так как нужно вывести суммы покупкОК (всех), то группируем
	group by Invoices.InvoiceID
END

GO

SET STATISTICS TIME ON

EXEC Sales.pGetCustomerInvoicesSum @ACustomerID = 1003
select *
from Sales.fGetCustomerInvoicesSum(1003)

-- Разницы в производительности нет, так как они используют одинаковый план запроса

/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

select Customers.CustomerName
, CustSums.InvoiceID
, CustSums.CustomerInvoiceSum
from Sales.Customers with (readcommitted) -- Единоразовый запрос на чтение без транзакций, поэтому нужно предотвратить лишь аномалию Dirty read
outer apply Sales.fGetCustomerInvoicesSum(Customers.CustomerID) CustSums
order by Customers.CustomerName, CustomerInvoiceSum desc

/*
5) Опционально. Во всех процедурах укажите какой уровень изоляции транзакций вы бы использовали и почему. 
*/
