USE [MyDB]

IF Object_ID('oha.spGetCustomerAddress') IS NOT NULL
	BEGIN
		PRINT 'Alter stored procedure oha.spGetCustomerAddress';
	END
ELSE
	BEGIN
		RAISERROR ('Stored procedure oha.spGetCustomerAddress missing',18,1);
	END
