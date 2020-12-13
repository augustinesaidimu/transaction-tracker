-- --  Create Database --
-- CREATE DATABASE SuperWholeSales;
-- GO

-- USE SuperWholeSales;
-- GO

-- -- Town  --
CREATE TABLE  Town(
     town_id INT IDENTITY(1,1),
     name VARCHAR(255) NOT NULL,

     CONSTRAINT PK_Town PRIMARY KEY (town_id),
);

-- -- Address  --
CREATE TABLE  Address(
     address_id INT IDENTITY(1,1),
     establishment TEXT NOT NULL,
     landmark TEXT NOT NULL,
     town INT NOT NULL,

     CONSTRAINT PK_Address PRIMARY KEY (address_id),
     CONSTRAINT FK_Address_Town FOREIGN KEY (town) REFERENCES Town (town_id),
);

-- -- Firms --
CREATE TABLE  Firm (
    firm_id INT IDENTITY(1,1),
    name VARCHAR(25) NOT NULL,
    phone VARCHAR(24) NOT NULL,
    email VARCHAR(50) NOT NULL,
    address INT NOT NULL,

    CONSTRAINT PK_Firm PRIMARY KEY (firm_id),
    CONSTRAINT FK_Firm_Address FOREIGN KEY (address) REFERENCES Address (address_id),
);

CREATE INDEX IX_Firm_Address ON Firm(address);
CREATE INDEX IX_Firm_Email ON Firm(email);
CREATE INDEX IX_Firm_Phone ON Firm(phone);

-- -- Account  --
CREATE TABLE  Account(
    account_id INT IDENTITY(1,1),
    owner INT,
    name VARCHAR(255) NOT NULL,

    CONSTRAINT PK_Account PRIMARY KEY (account_id),
    CONSTRAINT FK_Account_Owner FOREIGN KEY (owner) REFERENCES Firm (firm_id),
);

-- -- Record_Type  --
CREATE TABLE  Record_Type(
     entry_number INT IDENTITY(1,1),
     description VARCHAR(50) NOT NULL,

     CONSTRAINT PK_Record_Type PRIMARY KEY (entry_number),
);

-- -- Transaction_Records  --
CREATE TABLE  Transaction_Records(
     entry_number INT IDENTITY(1,1),
     account INT NOT NULL,
     amount DECIMAL(19,2) NOT NULL,
     transaction_type INT NOT NULL,
     date DATE NOT NULL,

     CONSTRAINT PK_Transaction_Records PRIMARY KEY (entry_number),
     CONSTRAINT FK_Transaction_Records_Account FOREIGN KEY (account) REFERENCES Account (account_id),
     CONSTRAINT FK_Transaction_Records_Record_Type FOREIGN KEY (transaction_type) REFERENCES Record_Type (entry_number),
);
CREATE INDEX IX_Transaction_Records_Date ON Transaction_Records(date);
CREATE INDEX IX_Transaction_Records_Amount ON Transaction_Records(amount);

-- -- Category  --
CREATE TABLE  Goods_Category(
     category_id INT IDENTITY(1,1),
     category_name VARCHAR(255) NOT NULL,
     parent_category INT,

     CONSTRAINT PK_Category PRIMARY KEY (category_id),
);

-- -- Goods  --
CREATE TABLE  Goods(
     item_id INT IDENTITY(1,1),
     name VARCHAR(255) NOT NULL,
     category INT NOT NULL,
     unit_buying_price DECIMAL(19,2) NOT NULL,
     unit_selling_price DECIMAL(19,2) NOT NULL,

     CONSTRAINT PK_Goods PRIMARY KEY (item_id),
     CONSTRAINT FK_Goods_Category FOREIGN KEY (category) REFERENCES Goods_Category (category_id),
);

-- -- Credit  --
CREATE TABLE  Credit(
     entry_id INT IDENTITY(1,1),
     creditor INT NOT NULL,
     debtor INT NOT NULL,
     total_amount DECIMAL(19, 5) NOT NULL,
     paid_amount DECIMAL(19, 5) NOT NULL,
     due_date DATE NOT NULL,

     CONSTRAINT PK_Credit PRIMARY KEY (entry_id),
     CONSTRAINT FK_Credit_Creditor FOREIGN KEY (creditor) REFERENCES Account (account_id),
     CONSTRAINT FK_Credit_Debtor FOREIGN KEY (debtor) REFERENCES Account (account_id),
);
GO

-- -- Purchases  --
CREATE TABLE  Purchases(
     purchase_id INT IDENTITY(1,1),
     item INT NOT NULL,
     quantity INT NOT NULL,
     manufactured_on DATE NOT NULL,
     expires_on DATE NOT NULL,
     purchased_on DATE NOT NULL,
     purchased_from INT NOT NULL,
     on_credit INT NOT NULL,

     CONSTRAINT PK_Purchases PRIMARY KEY (purchase_id),
     CONSTRAINT FK_Purchases_Goods FOREIGN KEY (item) REFERENCES Goods (item_id),
     CONSTRAINT FK_Purchases_Origin FOREIGN KEY (purchased_from) REFERENCES Account (account_id),
);
CREATE INDEX IX_Purchases_Goods ON Purchases(item);
CREATE INDEX IX_Purchases_Origin ON Purchases(purchased_from);

-- -- Sales  --
CREATE TABLE  Sales(
     sale_id INT IDENTITY(1,1),
     customer INT NOT NULL,
     item INT NOT NULL,
     quantity INT NOT NULL,
     on_credit INT NOT NULL,
     sale_date DATE NOT NULL,

     CONSTRAINT PK_Sales PRIMARY KEY (sale_id),
     CONSTRAINT FK_Sales_Inventory FOREIGN KEY (item) REFERENCES Goods (item_id),
     CONSTRAINT FK_Sales_Customer FOREIGN KEY (customer) REFERENCES Account (account_id),
);
GO

-- -- Purchases Update Transactions Trigger --
CREATE TRIGGER TR_Purchases_Record_Transaction ON Purchases
AFTER INSERT
AS
    IF (ROWCOUNT_BIG() = 0)
    RETURN;

BEGIN
    INSERT INTO Transaction_Records (account, amount, transaction_type, date)
    VALUES (
        (SELECT account_id from Account WHERE name = 'Purchases'),
        (SELECT
            i.quantity * g.unit_selling_price
            FROM Goods g
            JOIN INSERTED i ON i.item = g.item_id
            WHERE g.item_id = i.item
        ),
        2, -- debit
        (SELECT purchased_on from INSERTED)
    );


    IF ((SELECT on_credit FROM INSERTED) > 0)
    BEGIN
        INSERT INTO Transaction_Records (account, amount, transaction_type, date)
        VALUES (
            (SELECT purchased_from from INSERTED),
            (SELECT
                i.quantity * g.unit_selling_price
                FROM Goods g
                JOIN INSERTED i ON i.item = g.item_id
                WHERE g.item_id = i.item
            ),
            1, -- credit
            (SELECT purchased_on from INSERTED)
        );

        INSERT INTO Credit (creditor, debtor, total_amount, paid_amount, due_date)
        VALUES (
            (SELECT purchased_from from INSERTED),
            (SELECT account_id from Account WHERE name = 'Purchases'),
            (SELECT
                i.quantity * g.unit_selling_price
                FROM Goods g
                JOIN INSERTED i ON i.item = g.item_id
                WHERE g.item_id = i.item
            ),
            0,
            (SELECT DATEADD(DD,30,(SELECT purchased_on from INSERTED)))
        );
    END
    ELSE
    BEGIN
        INSERT INTO Transaction_Records (account, amount, transaction_type, date)
        VALUES (
            (SELECT account_id from Account WHERE name = 'Bank'),
            (SELECT
                i.quantity * g.unit_selling_price
                FROM Goods g
                JOIN INSERTED i ON i.item = g.item_id
                WHERE g.item_id = i.item
            ),
            1, -- credit
            (SELECT purchased_on from INSERTED)
        );
    END
END
GO

-- -- Sales Update Transactions Trigger --
CREATE TRIGGER TR_Sales_Record_Transaction ON Sales
AFTER INSERT
AS
    IF (ROWCOUNT_BIG() = 0)
    RETURN;

    BEGIN
        INSERT INTO Transaction_Records (account, amount, transaction_type, date)
        VALUES (
            (SELECT customer from INSERTED),
            (SELECT
                i.quantity * g.unit_selling_price
                FROM Goods g
                JOIN INSERTED i ON i.item = g.item_id
                WHERE g.item_id = i.item
            ),
            2, -- debit
            (SELECT sale_date from INSERTED)
        )

        INSERT INTO Transaction_Records (account, amount, transaction_type, date)
        VALUES (
            (SELECT account_id from Account WHERE name = 'Sales'),
            (SELECT
                i.quantity * g.unit_selling_price
                FROM Goods g
                JOIN INSERTED i ON i.item = g.item_id
                WHERE g.item_id = i.item
            ),
            1, -- credit
            (SELECT sale_date from INSERTED)
        )

        IF ((SELECT on_credit FROM INSERTED) > 0)
        BEGIN
            INSERT INTO Credit (creditor, debtor, total_amount, paid_amount, due_date)
            VALUES (
                (SELECT account_id from Account WHERE name = 'Sales'),
                (SELECT customer from INSERTED),
                (SELECT
                    i.quantity * g.unit_selling_price
                    FROM Goods g
                    JOIN INSERTED i ON i.item = g.item_id
                    WHERE g.item_id = i.item
                ),
                0,
                (SELECT DATEADD(DD,30,(SELECT sale_date from INSERTED)))
            )
        END
END
GO

