Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

DECLARE @CustomerNames NVARCHAR(MAX), @Command NVARCHAR(MAX)

SELECT @CustomerNames = ISNULL(@CustomerNames + ', ', '') + QUOTENAME(CustomerName)
FROM Sales.Invoices
JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID
GROUP BY CustomerName
ORDER BY CustomerName

SET @Command = 
'WITH CTE AS (
	SELECT 
		CustomerName,
		DATEADD(MONTH, DATEDIFF(MONTH, 0, Invoices.InvoiceDate), 0) InvoiceMonth,
		InvoiceID
	FROM Sales.Invoices
	JOIN Sales.Customers ON Invoices.CustomerID = Customers.CustomerID)
SELECT 
	CONVERT(nvarchar(10), InvoiceMonth, 104) InvoiceMonthStr, ' + @CustomerNames + '
FROM CTE
PIVOT (COUNT(InvoiceID) FOR CustomerName IN (' + @CustomerNames + ')) AS PivotTable
ORDER BY PivotTable.InvoiceMonth'

EXEC(@Command)
