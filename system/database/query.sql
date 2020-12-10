-- -- 1. How much did the company make in sales for year 2020. --
BEGIN
    DECLARE @YEAR INT;
    SET @YEAR = 2020;
    WITH Totals AS (
        SELECT SUM(s.quantity * g.unit_buying_price)  as purchases,
               SUM(s.quantity * g.unit_selling_price) as sales
        FROM Sales s
                 JOIN Goods g ON s.item = g.item_id
        WHERE (SELECT Year(s.sale_date)) = @YEAR
    )
    SELECT t.purchases             as [Total Purchases],
           t.sales                 as [Total Sales],
           (t.sales - t.purchases) AS [Total Profit]
    FROM Totals t;
END;
GO;

-- -- 2. How much money did the company make in sales between the period 1 January 2020 and 31 July 2020 --
BEGIN
    DECLARE @START_DATE DATE;
    DECLARE @END_DATE DATE;
    DECLARE @TOTAL_PURCHASES DECIMAL(19, 2);
    DECLARE @TOTAL_SALES DECIMAL(19, 2);

    SET @START_DATE = '2020-01-01';
    SET @END_DATE = '2020-07-31';

    SELECT @TOTAL_PURCHASES = SUM(s.quantity * g.unit_buying_price),
           @TOTAL_SALES = SUM(s.quantity * g.unit_selling_price)
    FROM Sales s
             JOIN Goods g ON s.item = g.item_id
    WHERE s.sale_date >= @START_DATE
      AND s.sale_date <= @END_DATE;

    SELECT @TOTAL_PURCHASES                  as [Total Purchases],
           @TOTAL_SALES                      as [Total Sales],
           (@TOTAL_SALES - @TOTAL_PURCHASES) AS [Total Profit];
END;
GO;

-- -- 3. List the total amount customers spent on purchases --
BEGIN
    DECLARE @MAX_SPENT DECIMAL(19, 2);

    SELECT @MAX_SPENT = MAX(s.quantity * g.unit_selling_price)
    FROM Sales s
             INNER JOIN Goods g on g.item_id = s.item
             INNER JOIN Account on s.customer = Account.account_id
             INNER JOIN Firm f on Account.owner = F.firm_id;

    SELECT DISTINCT f.name                              as Firm,
                    (s.quantity * g.unit_selling_price) as [Amount Spent]
    FROM Sales s
             INNER JOIN Goods g on g.item_id = s.item
             INNER JOIN Account on s.customer = Account.account_id
             INNER JOIN Firm f on Account.owner = F.firm_id
    WHERE Account.owner <> 1
    ORDER BY [Amount Spent]
END;
GO;

-- -- 4. Which customers owe the company money and how much --
BEGIN
    SELECT F.name         As Firm,
           C.total_amount AS [Amount Owed],
           C.due_date     AS [Due Date]
    FROM Credit C
             INNER JOIN Account A on A.account_id = C.debtor
             INNER JOIN Firm F on F.firm_id = A.owner
    WHERE a.owner <> 1
    ORDER BY [Due Date]
END;
GO;

-- -- 5. Whom does the company owe and how much. --
BEGIN
    SELECT F.name         As Firm,
           C.total_amount AS [Amount Owed],
           A.name         as Account,
           C.due_date     AS [Due Date]
    FROM Credit C
             INNER JOIN Account A on A.account_id = C.creditor
             INNER JOIN Firm F on F.firm_id = A.owner
    WHERE A.owner <> 1
    ORDER BY [Due Date]
END;
GO;

-- -- 6. How many times was each product sold --
BEGIN
    SELECT g.name      as Item,
           SUM(s.item) as [Times Sold]
    FROM Sales s
             INNER JOIN Goods g on g.item_id = s.item
             INNER JOIN Account on s.customer = Account.account_id
             INNER JOIN Firm f on Account.owner = F.firm_id
    GROUP BY g.name
    ORDER BY [Times Sold];
END;
GO;

-- -- 7. Show the Sale history
BEGIN
    SELECT s.sale_date                         as [Date of Sale],
           c.category_name                     as Category,
           g.name                              as [Item Name],
           s.quantity                          as [Quantity Sold],
           g.unit_selling_price                as [Unit Selling Price],
           (s.quantity * g.unit_selling_price) as [Total Sale Value],
           a.name                              as [Sold To]
    FROM Goods g
             INNER JOIN Goods_Category c on c.category_id = g.category
             Inner Join Sales s on g.item_id = s.item
             INNER JOIN Account A on A.account_id = s.customer
             INNER JOIN Firm F on F.firm_id = A.owner
END;
GO;

-- -- 8. Show the purchase History --
BEGIN
    SELECT p.purchased_on                     as [Date of Purchase],
           c.category_name                    as Category,
           g.name                             as [Item Name],
           g.unit_buying_price                as [Unit Buying Price],
           (p.quantity * g.unit_buying_price) as [Total Purchase Value],
           f.name                             as [Purchased From]
    FROM Goods g
             INNER JOIN Goods_Category c on c.category_id = g.category
             Inner Join Purchases P on g.item_id = P.item
             INNER JOIN Account A on A.account_id = P.purchased_from
             Inner Join Firm F on F.firm_id = A.owner

END;
GO;

-- -- 9. From which Supplier does the company buy Goods --
BEGIN
    DECLARE @MAX_SPENT DECIMAL(19, 2);

    SELECT @MAX_SPENT = MAX(p.item * g.unit_buying_price)
    FROM Purchases p
             INNER JOIN Goods g on g.item_id = p.item
             INNER JOIN Account on p.purchased_from = Account.account_id
             INNER JOIN Firm f on Account.owner = F.firm_id;

    SELECT DISTINCT f.name                             as Firm,
                    g.name                             as Item,
                    c.category_name                    as Category,
                    (p.quantity * g.unit_buying_price) as [Amount Spent]
    FROM Purchases p
             INNER JOIN Goods g on g.item_id = p.item
             INNER JOIN Account on p.purchased_from = Account.account_id
             Inner Join Goods_Category c on c.category_id = g.category
             INNER JOIN Firm f on Account.owner = F.firm_id

    WHERE (p.item * g.unit_selling_price) >= @MAX_SPENT
END;
GO;

-- -- 10. How much Goods were sold in the month of January 2020 --
BEGIN
    DECLARE @START_DATE DATE;
    DECLARE @END_DATE DATE;

    SET @START_DATE = '2020-01-01';
    SET @END_DATE = '2020-01-31';

    SELECT DISTINCT f.name                              as Firm,
                    g.name                              as Item,
                    c.category_name                     as Category,
                    (s.quantity * g.unit_selling_price) as [Amount Spent]
    FROM Sales s
             INNER JOIN Goods g on g.item_id = s.item
             INNER JOIN Account on s.customer = Account.account_id
             Inner Join Goods_Category c on c.category_id = g.category
             INNER JOIN Firm f on Account.owner = F.firm_id

    WHERE s.sale_date >= @START_DATE
      AND s.sale_date <= @END_DATE;

END;
GO;
