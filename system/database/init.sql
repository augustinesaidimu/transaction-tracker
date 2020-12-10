
CREATE DATABASE database_name
GO

CREATE LOGIN hospital WITH PASSWORD = 'hospital_124'
GO

USE database_name;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'hospital')
BEGIN
    CREATE USER [hospital] FOR LOGIN [hospital]
    EXEC sp_addrolemember N'db_owner', N'hospital'
END;
GO


