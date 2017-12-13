----https://www.sqlservercentral.com/Forums/1642213/get-full-path-from-sysxpdirtree
--13.12.2017
Create Proc dbo.Ola_GetBackupFoldersInfo
(
@BackupPath nvarchar(4000)=''
)
AS
BEGIN
DECLARE @sql NVARCHAR(MAX) = N''

--set @BackupPath ='\\10.0.6.117\AlwaysOnExchangeArea\IB06SQLTKL120C$AGSPPORTALFKM,\\10.0.6.117\AlwaysOnExchangeArea\IB06SQLTKL120C$TFSAVG'

	IF OBJECT_id('tempdb..#DirectoryTree') IS NOT NULL
	DROP TABLE #DirectoryTree;

	CREATE TABLE #DirectoryTree (
	   id int idENTITY(1,1)
	   ,subdirectory nvarchar(512)
	   ,depth int
	   ,isfile bit
	   , ParentDirectory int
	   ,flag tinyint default(0));

	SELECT @sql+=
	'INSERT #DirectoryTree (subdirectory,depth,isfile)
	   VALUES ('''+value+''',0,0);
	   INSERT INTO #DirectoryTree (subdirectory,depth,isfile)
	EXEC master.sys.xp_dirtree '''+value+''',0,1; '
	FROM STRING_SPLIT(@BackupPath,',')
	exec (@sql)

 
	UPDATE #DirectoryTree
	   SET ParentDirectory = (
		  SELECT MAX(id) FROM #DirectoryTree
		  WHERE Depth = d.Depth - 1 AND id < d.id   )
	FROM #DirectoryTree d;

	IF OBJECT_id('tempdb..#dirs') IS NOT NULL
	DROP TABLE #dirs;

	-- SEE all with full paths
	WITH dirs AS (
		SELECT
		   id,subdirectory,depth,isfile,ParentDirectory,flag
		   , CAST (null AS NVARCHAR(MAX)) AS container
		   , CAST([subdirectory] AS NVARCHAR(MAX)) AS dpath
	   
		   FROM #DirectoryTree
		   WHERE ParentDirectory IS NULL 
		UNION ALL
		SELECT
		   d.id,d.subdirectory,d.depth,d.isfile,d.ParentDirectory,d.flag
		   , dpath as container
		   , dpath +'\'+d.[subdirectory] 

		FROM #DirectoryTree AS d
		INNER JOIN dirs ON  d.ParentDirectory = dirs.id
	)

	SELECT * into #dirs FROM dirs 
	-- Dir style ordering
	ORDER BY container, isfile, subdirectory
 
	--cleanup
	DROP TABLE #DirectoryTree;

	select 
	d1.subdirectory as MainPath, 
	d3.subdirectory as BackupType, 
	ISNULL(d4.isfile,0) as HasFile ,
	MAX(convert(datetime,STUFF(STUFF(REPLACE(SUBSTRING(d4.subdirectory, (LEN(d4.subdirectory)-14-charindex('.', reverse(d4.subdirectory))),15),'_',' '), 12, 0, ':'), 15, 0, ':'))) as 'Last_CreatedFile_Date',
	d2.subdirectory as DbName
	 from #dirs d1
		INNER JOIN #dirs d2 ON d2.ParentDirectory=d1.id
		INNER JOIN #dirs d3 ON d3.ParentDirectory=d2.id 
		LEFT JOIN #dirs d4 ON d4.ParentDirectory=d3.id and d4.isfile=1-- (d3.isfile IS NULL OR d3.isfile=1)
	where d1.depth=0
	Group by d1.subdirectory,d3.subdirectory,d4.isfile,d2.subdirectory
	order by 5,2


END