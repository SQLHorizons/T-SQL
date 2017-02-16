USE master
go
DECLARE @OriginalSID varchar(32);
DECLARE @ccount tinyint;
DECLARE @FormattedSID varchar(500);
DECLARE @username varchar(500) = 'SVC_TRN_User';
SELECT @OriginalSID = LOWER(REPLACE (CONVERT(VARCHAR(1000), SUSER_SID (@username), 1), '0x', ''));
SET @FormattedSID = @OriginalSID
SET @ccount = 1
WHILE @ccount < 33
BEGIN
       SET @FormattedSID = '"0x' + SUBSTRING(@OriginalSID,@ccount,2) + '",'
       SET @ccount = @ccount + 2
       print @FormattedSID
END
