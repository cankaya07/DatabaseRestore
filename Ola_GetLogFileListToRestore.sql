USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Ola_GetLogFileListToRestore](
@BackupPath nvarchar(4000)='',
@LastImportedFile varchar(4000)='',
@Prefix varchar(100)='',
@DBName nvarchar(200)=''
) 
AS
SET NOCOUNT ON
IF OBJECT_ID(N'tempdb..#FileList') IS NOT NULL DROP TABLE #FileList;
CREATE TABLE #FileList
(
    BackupFile NVARCHAR(400),
	depth int,
	[file] int,
	BackupPath varchar(4000) null
);

DECLARE @sql NVARCHAR(MAX) = N''

SELECT @sql+=
'INSERT INTO #FileList (BackupFile,depth,[file])
EXEC master.sys.xp_dirtree '''+value+@DBName+'\'+@Prefix+''',0,1; update #FileList set BackupPath='''+value+''' where BackupPath is null;'
FROM STRING_SPLIT(@BackupPath,',')

 
exec(@sql); 


--http://cc.davelozinski.com/sql/fastest-way-to-insert-new-records-where-one-doesnt-already-exist
INSERT INTO AGRestore_FileList (BackupFile,depth,[file],BackupPath,DbName)
SELECT #FileList.BackupFile, #FileList.depth, #FileList.[file], #FileList.BackupPath,@DBName
FROM #FileList
LEFT JOIN AGRestore_FileList (NOLOCK) on AGRestore_FileList.BackupFile = #FileList.BackupFile
WHERE AGRestore_FileList.BackupFile is null and #FileList.[file]=1 and #FileList.BackupFile>@LastImportedFile 
ORDER BY BackupFile DESC

DROP TABLE #FileList;

DELETE from AGRestore_FileList Where [file]=0 and DbName=@DBName


update AGRestore_FileList set
	BackupDate = convert(datetime,STUFF(STUFF(REPLACE(SUBSTRING(BackupFile, (LEN(BackupFile)-14-charindex('.', reverse(BackupFile))),15),'_',' '), 12, 0, ':'), 15, 0, ':')),
 	BackupTypeText =REPLACE(REPLACE(REVERSE(SUBSTRING(REVERSE(BackupFile),21,4)),'_',''),'ONLY','FULL_COPY_ONLY')
WHERE
	[file]=1 and DbName=@DBName

	 
DELETE FROM AGRestore_FileList where BackupTypeText IS NULL and DbName=@DBName

 
 RAISERROR('Files loaded', 0, 1);
--exec dbo.GetLogFileListToRestore