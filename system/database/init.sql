
CREATE DATABASE database_name
GO

CREATE LOGIN login WITH PASSWORD = 'password'
GO

USE database_name;
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'login')
BEGIN
    CREATE USER [user] FOR LOGIN [login]
    EXEC sp_addrolemember N'db_owner', N'login'
END;
GO


