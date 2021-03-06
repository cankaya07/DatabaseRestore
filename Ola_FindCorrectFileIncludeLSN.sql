USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Ola_FindCorrectFileIncludeLSN](

@RedoStartLSN decimal(30)='',
@DBName nvarchar(200)=''
)
AS
SET NOCOUNT ON
DECLARE @HeadersSQL AS NVARCHAR(4000) = N'', --Dynamic insert into #Headers table (deals with varying results from RESTORE FILELISTONLY across different versions)
@sql NVARCHAR(MAX) = N'' --Holds executable SQL commands
 
		
IF OBJECT_ID(N'tempdb..#Headers') IS NOT NULL DROP TABLE #Headers;
CREATE TABLE #Headers
(
    BackupName NVARCHAR(256),
    BackupDescription NVARCHAR(256),
    BackupType NVARCHAR(256),
    ExpirationDate NVARCHAR(256),
    Compressed NVARCHAR(256),
    Position NVARCHAR(256),
    DeviceType NVARCHAR(256),
    UserName NVARCHAR(256),
    ServerName NVARCHAR(256),
    DatabaseName NVARCHAR(256),
    DatabaseVersion NVARCHAR(256),
    DatabaseCreationDate NVARCHAR(256),
    BackupSize NVARCHAR(256),
    FirstLSN NVARCHAR(256),
    LastLSN NVARCHAR(256),
    CheckpointLSN NVARCHAR(256),
    DatabaseBackupLSN NVARCHAR(256),
    BackupStartDate NVARCHAR(256),
    BackupFinishDate NVARCHAR(256),
    SortOrder NVARCHAR(256),
    CodePage NVARCHAR(256),
    UnicodeLocaleId NVARCHAR(256),
    UnicodeComparisonStyle NVARCHAR(256),
    CompatibilityLevel NVARCHAR(256),
    SoftwareVendorId NVARCHAR(256),
    SoftwareVersionMajor NVARCHAR(256),
    SoftwareVersionMinor NVARCHAR(256),
    SoftwareVersionBuild NVARCHAR(256),
    MachineName NVARCHAR(256),
    Flags NVARCHAR(256),
    BindingID NVARCHAR(256),
    RecoveryForkID NVARCHAR(256),
    Collation NVARCHAR(256),
    FamilyGUID NVARCHAR(256),
    HasBulkLoggedData NVARCHAR(256),
    IsSnapshot NVARCHAR(256),
    IsReadOnly NVARCHAR(256),
    IsSingleUser NVARCHAR(256),
    HasBackupChecksums NVARCHAR(256),
    IsDamaged NVARCHAR(256),
    BeginsLogChain NVARCHAR(256),
    HasIncompleteMetaData NVARCHAR(256),
    IsForceOffline NVARCHAR(256),
    IsCopyOnly NVARCHAR(256),
    FirstRecoveryForkID NVARCHAR(256),
    ForkPointLSN NVARCHAR(256),
    RecoveryModel NVARCHAR(256),
    DifferentialBaseLSN NVARCHAR(256),
    DifferentialBaseGUID NVARCHAR(256),
    BackupTypeDescription NVARCHAR(256),
    BackupSetGUID NVARCHAR(256),
    CompressedBackupSize NVARCHAR(256),
    Containment NVARCHAR(256),
    KeyAlgorithm NVARCHAR(32),
    EncryptorThumbprint VARBINARY(20),
    EncryptorType NVARCHAR(32)
);
 
SET @HeadersSQL += 
N'INSERT INTO #Headers WITH (TABLOCK)
  (BackupName, BackupDescription, BackupType, ExpirationDate, Compressed, Position, DeviceType, UserName, ServerName
  ,DatabaseName, DatabaseVersion, DatabaseCreationDate, BackupSize, FirstLSN, LastLSN, CheckpointLSN, DatabaseBackupLSN
  ,BackupStartDate, BackupFinishDate, SortOrder, CodePage, UnicodeLocaleId, UnicodeComparisonStyle, CompatibilityLevel
  ,SoftwareVendorId, SoftwareVersionMajor, SoftwareVersionMinor, SoftwareVersionBuild, MachineName, Flags, BindingID
  ,RecoveryForkID, Collation, FamilyGUID, HasBulkLoggedData, IsSnapshot, IsReadOnly, IsSingleUser, HasBackupChecksums
  ,IsDamaged, BeginsLogChain, HasIncompleteMetaData, IsForceOffline, IsCopyOnly, FirstRecoveryForkID, ForkPointLSN
  ,RecoveryModel, DifferentialBaseLSN, DifferentialBaseGUID, BackupTypeDescription, BackupSetGUID, CompressedBackupSize, Containment, KeyAlgorithm, EncryptorThumbprint, EncryptorType)' + NCHAR(13) + NCHAR(10);

SET @HeadersSQL += N'EXEC (''RESTORE HEADERONLY FROM DISK=''''{Path}'''''')';

 
DECLARE @BackupFile varchar(4000), @FullBackupPath varchar(4000)


	DECLARE BackupFiles CURSOR FOR
	select BackupFile,FullBackupPath from AGRestore_FileList (NOLOCK) where 
						BackupTypeText='LOG' 
						and DbName=@DBName 
						AND FirstLSN IS NULL	
				order by BackupDate desc
		
	OPEN BackupFiles;
	print 'we need older file also added tlog our restore list for restore op'
	FETCH NEXT FROM BackupFiles INTO @BackupFile,@FullBackupPath
	WHILE @@FETCH_STATUS = 0
		BEGIN
			select @sql=REPLACE(@HeadersSQL, N'{Path}', @FullBackupPath)
			exec(@sql) 

			--:)
			UPDATE A 
			SET 
			A.BackupName =B.BackupName,
			A.BackupDescription =B.BackupDescription ,
			A.BackupType=B.BackupType ,
			A.ExpirationDate=B.ExpirationDate ,
			A.Compressed=B.Compressed ,
			A.Position=B.Position ,
			A.DeviceType=B.DeviceType ,
			A.UserName=B.UserName ,
			A.ServerName=B.ServerName ,
			A.DatabaseName=B.DatabaseName ,
			A.DatabaseVersion=B.DatabaseVersion ,
			A.DatabaseCreationDate=B.DatabaseCreationDate ,
			A.BackupSize=B.BackupSize ,
			A.FirstLSN=B.FirstLSN ,
			A.LastLSN=B.LastLSN ,
			A.CheckpointLSN=B.CheckpointLSN ,
			A.DatabaseBackupLSN=B.DatabaseBackupLSN ,
			A.BackupStartDate=B.BackupStartDate ,
			A.BackupFinishDate=B.BackupFinishDate ,
			A.SortOrder=B.SortOrder ,
			A.CodePage=B.CodePage ,
			A.UnicodeLocaleId=B.UnicodeLocaleId ,
			A.UnicodeComparisonStyle=B.UnicodeComparisonStyle ,
			A.CompatibilityLevel=B.CompatibilityLevel ,
			A.SoftwareVendorId=B.SoftwareVendorId ,
			A.SoftwareVersionMajor=B.SoftwareVersionMajor ,
			A.SoftwareVersionMinor=B.SoftwareVersionMinor ,
			A.SoftwareVersionBuild=B.SoftwareVersionBuild ,
			A.MachineName=B.MachineName ,
			A.Flags=B.Flags ,
			A.BindingID=B.BindingID ,
			A.RecoveryForkID=B.RecoveryForkID ,
			A.Collation=B.Collation ,
			A.FamilyGUID=B.FamilyGUID ,
			A.HasBulkLoggedData=B.HasBulkLoggedData ,
			A.IsSnapshot=B.IsSnapshot ,
			A.IsReadOnly=B.IsReadOnly ,
			A.IsSingleUser=B.IsSingleUser ,
			A.HasBackupChecksums=B.HasBackupChecksums ,
			A.IsDamaged=B.IsDamaged ,
			A.BeginsLogChain=B.BeginsLogChain ,
			A.HasIncompleteMetaData=B.HasIncompleteMetaData ,
			A.IsForceOffline=B.IsForceOffline ,
			A.IsCopyOnly=B.IsCopyOnly ,
			A.FirstRecoveryForkID=B.FirstRecoveryForkID ,
			A.ForkPointLSN=B.ForkPointLSN ,
			A.RecoveryModel=B.RecoveryModel ,
			A.DifferentialBaseLSN=B.DifferentialBaseLSN ,
			A.DifferentialBaseGUID=B.DifferentialBaseGUID ,
			A.BackupTypeDescription=B.BackupTypeDescription ,
			A.BackupSetGUID=B.BackupSetGUID ,
			A.CompressedBackupSize=B.CompressedBackupSize ,
			A.Containment=B.Containment ,
			A.KeyAlgorithm =B.KeyAlgorithm ,
			A.EncryptorThumbprint =B.EncryptorThumbprint ,
			A.EncryptorType  = B.EncryptorType
			from Dbo.AGRestore_FileList A
			INNER JOIN #Headers B  ON A.FullBackupPath = @FullBackupPath
			Where DbName=@DBName

			DELETE FROM #Headers;
			--we find our tlog file
			IF(select MIN(FirstLSN) from AGRestore_FileList (NOLOCK) where BackupTypeText='LOG' and DbName=@DBName and BackupType=2)<=@RedoStartLSN
			BEGIN
				print 'it has lower lsn numbered tlog file found'
				
				IF EXISTS(select * from AGRestore_FileList (NOLOCK) 
											where BackupTypeText='LOG' 
											and DbName=@DBName 
											and BackupType=2
											AND FirstLSN<@RedoStartLSN
											AND LastLSN>@RedoStartLSN)
				BEGIN
					print 'gotcha we found necessary tlog file'+@BackupFile
				END
				break;
			END
			RAISERROR ('skipped ',0,1) WITH NOWAIT
		
		FETCH NEXT FROM BackupFiles INTO @BackupFile,@FullBackupPath
	END;
	
CLOSE BackupFiles;

DEALLOCATE BackupFiles;  



















 