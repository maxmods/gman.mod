SuperStrict
Rem 
ZIP structure at
http://www.pkware.com/documents/casestudies/APPNOTE.TXT
EndRem

Rem
bbdoc: Zip Engine
End Rem
Module gman.zipengine

ModuleInfo "Version: 2.11"
ModuleInfo "Author: gman, Bruce A Henderson"
ModuleInfo "License: Public Domain"
ModuleInfo "Credit: This mod makes use if the ZLib C functions by Gilles Vollant (http://www.winimage.com/zLibDll/unzip.html)"
ModuleInfo "Credit: This mod was initially created by Thomas Mayer"
ModuleInfo "Credit: Smurftra for his DateTime functions (http://www.blitzbasic.com/codearcs/codearcs.php?code=1726)"
ModuleInfo "History: 2.11"
ModuleInfo "History: Updated for bmx-ng."
ModuleInfo "History: 2009/02/27 GG - Updated central directory scan routine to be faster"
ModuleInfo "History: 2009/02/15 GG - converted to scan central headers instead of local headers"
ModuleInfo "History: 2009/02/15 GG - Added stream wrapper for ZipEngine"
ModuleInfo "History: 2009/02/10 GG - fixed AddStream() bug found by peterigz"
ModuleInfo "History: 2007/07/17 GG - changed to gman.ZipEngine"
ModuleInfo "History: 2006/07/15 GG - fixed filecount not counting added files (reported by Lomat)"
ModuleInfo "History: 2006/07/15 GG - added datetime stamps to zipped file information (reported by Grisu)"
ModuleInfo "History: 2006/07/15 GG - added AddStream() method to allow adding a stream as a file"
ModuleInfo "History: 2005/12/17 GG - added clearing of filename and filelist in closezip()"
ModuleInfo "History: 2005/12/14 GG - fixed bug in readFileList() where it was trying to read from an empty (new) file"
ModuleInfo "History: 2005/12/14 GG - changed to SuperStrict and fixed all missing declarations"
ModuleInfo "History: 2005/12/07 GG - created new ZipRamStream and updated extractfile() to use new stream"
ModuleInfo "History: 2005/12/05 GG - updated to be compatible with BMAX v1.14"
ModuleInfo "History: 2005/11/14 GG - updated to be compatible with BMAX v1.12"

Import Pub.ZLib
Import BRL.RamStream
Import BRL.System
Import "zip.c"
Import "unzip.c"
Import "ioapi.c"
Import "bmxsupport.c"

Rem
bbdoc: Append Modes
End Rem
Const APPEND_STATUS_CREATE:Int			= 0
Const APPEND_STATUS_CREATEAFTER:Int		= 1
Const APPEND_STATUS_ADDINZIP:Int		= 2

Rem
bbdoc: Compression methods
End Rem
Const Z_DEFLATED:Int					= 8

Rem
bbdoc: Compression levels
End Rem
Const Z_NO_COMPRESSION:Int				= 0
Const Z_BEST_SPEED:Int				= 1
Const Z_BEST_COMPRESSION:Int			= 9
Const Z_DEFAULT_COMPRESSION:Int		= -1

Rem
bbdoc: Compare modes
End Rem
Const UNZ_CASE_CHECK:Int				= 1
Const UNZ_NO_CASE_CHECK:Int			= 2

Rem
bbdoc: Result Codes
End Rem
Const UNZ_OK:Int						= 0
Const UNZ_END_OF_LIST_OF_FILE:Int		= -100
Const UNZ_EOF:Int						= 0
Const UNZ_PARAMERROR:Int				= -102
Const UNZ_BADZIPFILE:Int				= -103
Const UNZ_INTERNALERROR:Int			= -104
Const UNZ_CRCERROR:Int				= -105

Extern

Rem
bbdoc: Open new zip file (returns zipFile pointer)
End Rem
Function zipOpen:Byte Ptr( fileName$z, append:Int )

Rem
bbdoc: Closes an open zip file
End Rem
Function zipClose( zipFilePtr:Byte Ptr, archiveName$z )

Rem
bbdoc: Open a file inside the zip file
End Rem
Function zipOpenNewFileInZip( zipFilePtr:Byte Ptr, fileName$z, zip_fileinfo:Byte Ptr, ..
							extrafield_local:Byte Ptr, size_extrafield_local:Int, ..
							extrafield_global:Byte Ptr, size_extrafield_global:Int, ..
							comment$z, compressionMethod:Int, ..
							level:Int )
							
Rem
bbdoc: Open a file inside the zip file using a password
End Rem
Function zipOpenNewFileWithPassword( zipFilePtr:Byte Ptr, fileName$z, zip_fileinfo:Byte Ptr, ..
							extrafield_local:Byte Ptr, size_extrafield_local:Int, ..
							extrafield_global:Byte Ptr, size_extrafield_global:Int, ..
							comment$z, compressionMethod:Int, ..
							level:Int, password$z )

Rem
bbdoc: Write into a zip file
End Rem
Function zipWriteInFileInZip( zipFilePtr:Byte Ptr, buffer:Byte Ptr, bufferLength:Int )

Rem
bbdoc: Open a zip file for unzip
End Rem
Function unzOpen:Byte Ptr( zipFileName$z )

Rem
bbdoc: Return status of desired file and sets the unzipped focus to it
End Rem
Function unzLocateFile:Int( zipFilePtr:Byte Ptr, fileName$z, caseCheck:Int )

Rem
bbdoc: Opens the currently focused file
End Rem
Function unzOpenCurrentFile:Int( zipFilePtr:Byte Ptr )

Rem
bbdoc: Opens the currently focused file using a password
End Rem
Function unzOpenCurrentFilePassword:Int(file:Byte Ptr, password$z)

Rem
bbdoc: Gets info about the current file
End Rem
Function unzGetCurrentFileSize:Int( zipFilePtr:Byte Ptr )

Rem
bbdoc: Read current file, returns number of bytes
End Rem
Function unzReadCurrentFile:Int( zipFilePtr:Byte Ptr, buffer:Byte Ptr, size:Int )

Rem
bbdoc: Close current file
End Rem
Function unzCloseCurrentFile( zipFilePtr:Byte Ptr )

Rem
bbdoc: Close unzip zip file
End Rem
Function unzClose( zipFilePtr:Byte Ptr )

Rem
  Give the current position in uncompressed data
EndRem
?bmxng
Function unztell:Long( zipFilePtr:Byte Ptr )
?Not bmxng
Function unztell:Int( zipFilePtr:Byte Ptr )
?

Rem
  return 1 if the end of file was reached, 0 elsewhere
EndRem
Function unzeof:Int( zipFilePtr:Byte Ptr )

Rem 
	Get the current file offset
EndRem
Function unzGetOffset:Long( zipFilePtr:Byte Ptr)

Rem
	Set the current file offset
EndRem
Function unzSetOffset:Int( zipFilePtr:Byte Ptr, pos:Long )

EndExtern

Type ZipFile Abstract
	Field m_name:String
	Field m_zipFileList:TZipFileList=Null

	Rem
		bbdoc: Stores information about the files in a zip file into a list
	End Rem	
	Method readFileList()
		clearFileList()
		If m_name.length>0 And FileSize(m_name)>0 ' check to make sure the file isnt empty
			Local read:TStream=ReadFile(m_name)
			If read<>Null
				m_zipFileList=TZipFileList.Create(read,False,False)
				CloseStream(read)
			EndIf	
		EndIf
	EndMethod
	
	Rem
		bbdoc: Clears the stored list of file information
	End Rem	
	Method clearFileList()
		m_zipFileList=Null
	EndMethod
	
	Rem
		bbdoc: Returns the # of files contained in the zip file
	End Rem	
	Method getFileCount:Int()
		If m_zipFileList Then Return m_zipFileList.getFileCount() Else Return 0
	EndMethod

	Rem
		bbdoc: Stores the name of the current zip file
	End Rem		
	Method setName(zipName:String)
		m_name=zipName
	EndMethod
	
	Rem
		bbdoc: Returns the name of the name of the zip
	End Rem		
	Method getName:String()
		Return m_name
	EndMethod

	Rem
		bbdoc: Returns the SZipFileEntry object information for a file entry in the ZIP 
	End Rem
	Method getFileInfo:SZipFileEntry(index:Int)
		Return m_zipFileList.getFileInfo(index)
	EndMethod

	Rem
		bbdoc: Locates a file entry by name and returns its SZipFileEntry
	EndRem
	Method getFileInfoByName:SZipFileEntry(simpleFilename:String)
		Return m_zipFileList.findFile(simpleFilename)
	EndMethod

EndType

Type ZipWriter Extends ZipFile
	Field m_zipFile:Byte Ptr = Null
	Field m_compressionLevel:Int = Z_DEFAULT_COMPRESSION
	
	Rem
		bbdoc: Opens a zip file for writing
	End Rem
	Method OpenZip:Int( name:String, append:Int )
		If ( append ) Then
			m_zipFile = zipOpen( name, APPEND_STATUS_ADDINZIP )
		Else
			m_zipFile = zipOpen( name, APPEND_STATUS_CREATE )
		End If
		
		If ( m_zipFile ) Then
			setName(name)  ' store the name
			readFileList() ' read in the file information
			Return True
		Else
			Return False
		End If
	End Method

	Rem
		bbdoc: Set level of compression
	End Rem
	Method SetCompressionLevel( level:Int )
		If ( m_zipFile ) Then
			m_compressionLevel = level
		End If
	End Method

	Rem
		bbdoc: Adds a file to the zip
	End Rem
	Method AddFile( fileName:String, password:String="" )
		If ( m_zipFile ) Then
			Local inFile:TStream = OpenFile( fileName )
			
			If ( inFile ) Then
?bmxng
				Local inSize:Long = StreamSize(inFile)
				Local ftime:Long = FileTime(fileName)
?Not bmxng
				Local inSize:Int = StreamSize(inFile)
				Local ftime:Int = FileTime(fileName)
?
				Local pointer : Int Ptr = Int Ptr(localtime_(Varptr(ftime)))

				' populate the info structure with datetime
				Local info:zip_fileinfo=New zip_fileinfo
				info.tmz_date.tm_sec=pointer[0]
				info.tmz_date.tm_min=pointer[1]
				info.tmz_date.tm_hour=pointer[2]
				info.tmz_date.tm_mday=pointer[3]
				info.tmz_date.tm_mon=pointer[4]
				info.tmz_date.tm_year=(pointer[5]+1900)

				' create the bank for passing the structure to the C func
				Local info_b:TBank=info.getBank()

				If password.length=0
					' Open the test.txt as a new entry inside the zip
					zipOpenNewFileInZip( m_zipFile, fileName, BankBuf(info_b), Null, Null, Null, Null, Null, ..
										Z_DEFLATED, m_compressionLevel )
				Else
					' Open the test.txt as a new entry inside the zip
					zipOpenNewFileWithPassword( m_zipFile, fileName, BankBuf(info_b), Null, Null, Null, Null, Null, ..
										Z_DEFLATED, m_compressionLevel, password )
				EndIf

				' Write the file into the zip
				zipWriteInFileInZip( m_zipFile, LoadByteArray(inFile), inSize )
				
				' add this file to the file list
				Local entry:SZipFileEntry=SZipFileEntry.Create()
				entry.zipFileName=fileName
				entry.simpleFileName=StripDir(fileName)
				entry.path=ExtractDir(fileName)

				If Not m_zipFileList Then m_zipFileList=New TZipFileList
				m_zipFileList.FileList.AddLast(entry)				
			End If			
		End If
	End Method

	Rem
		bbdoc: Adds a file to the zip from a stream
	End Rem
	Method AddStream( data:TStream, fileName:String, password:String="" )
		If ( m_zipFile ) Then
		
			Local inFile:TStream = data
			
			If ( inFile ) Then
				' reset to beginning
				SeekStream(inFile, 0)

				Local TDate:String = CurrentDate()
				Local TTime:String = CurrentTime()
?bmxng
				Local inSize:Long = StreamSize(inFile)
				Local ftime:Long = FileTime(fileName)
?Not bmxng
				Local inSize:Int = StreamSize(inFile)
				Local ftime:Int = FileTime(fileName)
?
				Local pointer:Int Ptr = Int Ptr(localtime_(Varptr(ftime)))

				' populate the info structure with datetime
				Local info:zip_fileinfo=New zip_fileinfo
				info.tmz_date.tm_sec=Int(TTime[7..])
				info.tmz_date.tm_min=Int(TTime[3..6])
				info.tmz_date.tm_hour=Int(TTime[..2])
				info.tmz_date.tm_mday=Int(TDate[..2])
				info.tmz_date.tm_mon="JANFEBMARAPRMAYJUNJULAUGSEPOCTNOVDEC".Find(TDate[3..6].ToUpper()) / 3
				info.tmz_date.tm_year=Int(TDate[TDate.length - 4..])
				
				' create the bank for passing the structure to the C func
				Local info_b:TBank=info.getBank()

				If password.length=0
					' Open the test.txt as a new entry inside the zip
					zipOpenNewFileInZip( m_zipFile, fileName, BankBuf(info_b), Null, Null, Null, Null, Null, ..
										Z_DEFLATED, m_compressionLevel )
				Else
					' Open the test.txt as a new entry inside the zip
					zipOpenNewFileWithPassword( m_zipFile, fileName, BankBuf(info_b), Null, Null, Null, Null, Null, ..
										Z_DEFLATED, m_compressionLevel, password )
				EndIf
		
				' Write the file into the zip
				zipWriteInFileInZip( m_zipFile, LoadByteArray(inFile), inSize )
				
				' add this file to the file list
				Local entry:SZipFileEntry=SZipFileEntry.Create()
				entry.zipFileName=fileName
				entry.simpleFileName=StripDir(fileName)
				entry.path=ExtractDir(fileName)
				
				If Not m_zipFileList Then m_zipFileList=New TZipFileList
				m_zipFileList.FileList.AddLast(entry)				
			End If			
		End If
	End Method

	Rem
		bbdoc: Closes a zip file
	End Rem
	Method CloseZip( description:String = "" )
		If ( m_zipFile ) Then
			zipClose( m_zipFile, description )				
		End If
		setName("") ' clear out the name
		clearFileList() ' clear out the header info
	End Method
End Type

Type ZipReader Extends ZipFile

	Field m_zipFile:Byte Ptr = Null
	
	Rem
		bbdoc: Opens a zip file for reading
	End Rem
	Method OpenZip:Int( name:String )
		m_zipFile = unzOpen( name )
		
		If ( m_zipFile ) Then
			setName(name)  ' store the name
			readFileList() ' read in the file information
			Return True
		Else
			Return False
		End If
	End Method

	Rem
		bbdoc: Extracts a file from the zip to RAM
	End Rem
	Method ExtractFile:TRamStream( fileName:String, caseSensitive:Int = False, password:String="" )
		If ( m_zipFile ) Then
			Local result:Int
			
			If ( caseSensitive ) Then
				result = unzLocateFile( m_zipFile, fileName, UNZ_CASE_CHECK )
			Else
				result = unzLocateFile( m_zipFile, fileName, UNZ_NO_CASE_CHECK )
			End If
					
			If ( result = UNZ_OK ) Then
				If password.length=0
					result = unzOpenCurrentFile( m_zipFile)
				Else
					result = unzOpenCurrentFilePassword( m_zipFile, password)
				EndIf
				
				If ( result = UNZ_OK ) Then
					Local entrySize:Int = unzGetCurrentFileSize( m_zipFile )
					
					Local stream:TRamStream=ZipRamStream.ZCreate(entrySize,True,False)
					Local numberOfBytes:Int = unzReadCurrentFile ( m_zipFile, stream._buf, entrySize )
					
					Return stream
				Else
					Return Null
				End If												
			Else
				Return Null
			End If
		End If
	End Method

	Rem
		bbdoc: Extracts a file from the zip to disk
	End Rem
	Method ExtractFileToDisk( fileName:String, outputFileName:String, caseSensitive:Int = False, password:String="" )
		Local outFile:TStream = WriteFile ( outputFileName )
		Local extractedFile:TRamStream = ExtractFile ( fileName, caseSensitive, password )
		
		If ( outFile And extractedFile ) Then
			CopyStream( extractedFile, outFile )
		End If 

		CloseStream( outFile )
	End Method

	Rem
		bbdoc: Closes a zip file
	End Rem
	Method CloseZip()
		If ( m_zipFile ) Then
			unzClose( m_zipFile )	
		End If
		setName("") ' clear out the name
		clearFileList() ' clear out the header info
	End Method
End Type

' ----------------------------------------------------------------
' the supporting cast
' ----------------------------------------------------------------

Type ZipRamStream Extends TRamStream
	Field _data:Byte[]
	
	Function ZCreate:TRamStream( size:Int,readable:Int,writeable:Int )
		Local stream:ZipRamStream=New ZipRamStream
		stream._data=New Byte[size]
		stream._pos=0
		stream._size=size
		stream._buf=Varptr(stream._data[0])
		stream._read=readable
		stream._write=writeable
		Return stream
	End Function	
EndType

Type TZipFileList

	Field zipFile:TStream
	Field FileList:TList 
	Field IgnoreCase:Int
	Field IgnorePaths:Int

	Method New()
		FileList=New TList
	EndMethod

	Rem
		bbdoc: Creates a new TZipFileList object
	End Rem
	Function Create:TZipFileList(file:TStream,bIgnoreCase:Int,bIgnorePaths:Int)
		If Not file Then Return Null
		
		Local retval:TZipFileList=New TZipFileList
		retval.zipFile = file
		retval.IgnoreCase = bIgnoreCase
		retval.IgnorePaths = bIgnorePaths

		' scan central header
		If Not retval.ScanCentralHeader() Then
			' couldnt read the file
			retval = Null
		Else
			' prepare file index For binary search
			retval.FileList.sort()
		EndIf
		
		Return retval		
	EndFunction
	
	Rem
		bbdoc: Returns count of files in archive
	End Rem
	Method getFileCount:Int()
		Return FileList.Count()
	EndMethod

	Rem
		bbdoc: Returns information about a file entry in the ZIP
	End Rem
	Method getFileInfo:SZipFileEntry(index:Int)
		If index<0 Or index>=FileList.Count() Then RuntimeError "TZipReader.getFileInfo(): Invalid index "+index
		Return SZipFileEntry(FileList.ValueAtIndex(index))
	EndMethod

	Rem
		bbdoc: Locates a file entry by name and returns its SZipFileEntry
	EndRem
	Method findFile:SZipFileEntry(simpleFilename:String)
		Local retval:SZipFileEntry=Null
		
		Local entry:SZipFileEntry=SZipFileEntry.Create()
		entry.simpleFileName = simpleFilename
	
		If (IgnoreCase) Then entry.simpleFileName=entry.simpleFileName.ToLower()
	
		If (IgnorePaths) Then deletePathFromFilename(entry.simpleFileName)

		Local link:TLink=FileList.FindLink(entry)
		
		If link
			retval=SZipFileEntry(link.Value())
		Else
			?Debug
			For Local i:Int=0 To FileList.Count()-1
				If (getFileInfo(i).simpleFileName = entry.simpleFileName)
					DebugLog("File "+entry.simpleFileName+" in archive but Not found.")
					Exit
				EndIf
			Next
			?
		EndIf
		
		Return retval
	EndMethod

	Rem
		bbdoc: Scans the central header for files.  Returns true if successful.
	End Rem
	Method ScanCentralHeader:Int()
		SeekStream(zipFile, 0)
		
		' first check to see if its even a valid ZIP file
		If ReadInt(zipFile) <> $04034b50 Then 
			DebugLog("Invalid ZIP file!")
			Return False
		EndIf
		
		Local header_start:Int = 0
		
		' jump to the end
		SeekStream(zipFile, StreamSize(zipFile) - 4)
		
		' seek the end central directory structure
		While Not StreamPos(zipFile) = 0
			Local sig:Int = ReadInt(zipFile)
			If sig = $06054b50 Then
				' jump to start of central dir location
				SeekStream(zipFile, StreamPos(zipFile) + 12)
				header_start = ReadInt(zipFile)
				Exit				
			Else
				' rewind 3 bytes and try again
				SeekStream(zipFile, StreamPos(zipFile) - 5)
			EndIf
		EndWhile
	
		' if we found the header, then process
		If Not header_start Then 
			DebugLog("unable to locate central directory!")
			Return False
		EndIf
		
		' seek to the start of the central directory
		SeekStream(zipFile, header_start)
		
		While True And Not Eof(zipFile)
			Local entry:SZipFileEntry = SZipFileEntry.Create()
			If entry.header.fill(zipFile) Then
				FileList.AddLast(entry)

				' read filename
				entry.zipFileName = entry.header.FileName			
				extractFilename(entry)								 
			Else
				Exit
			EndIf
		EndWhile
	
		Return True
	EndMethod

	Rem
		bbdoc: Splits filename from zip file into useful filenames And paths
	EndRem
	Method extractFilename(entry:SZipFileEntry)

		' check length of filename
		If Not entry.header.FilenameLength Then Return
	
		' change the case if ignore is on
		If (IgnoreCase) Then entry.zipFileName = entry.zipFileName.ToLower()
	
		' make sure there is a path
		Local thereIsAPath:Int = (ExtractDir(entry.zipFileName) <> "<bad_dir>")
	
		' store just the filename
		entry.simpleFileName = StripDir(entry.zipFileName)
		
		' store an empty path
		If (thereIsAPath) Then entry.path = ExtractDir(entry.zipFileName) Else entry.path=""
	
		' simpleFileName must be zipFileName if not to ignore paths
		If Not IgnorePaths
			entry.simpleFileName = entry.zipFileName  ' thanks To Pr3t3nd3r For this fix
		EndIf
	EndMethod

	Rem
		bbdoc: Deletes the path from a filename
	EndRem
	Method deletePathFromFilename(filename:String Var)
		filename=StripDir(filename)
	EndMethod

EndType

' the fields crc-32, compressed size
' And uncompressed size are set To zero in the Local
' header
Const ZIP_INFO_IN_DATA_DESCRIPTOR:Short = $0008  

'/* tm_zip contain date/time info */
Type tm_zip
    Field tm_sec:Int	'/* seconds after the minute - [0,59] */
    Field tm_min:Int    '/* minutes after the hour - [0,59] */
    Field tm_hour:Int   '/* hours since midnight - [0,23] */
    Field tm_mday:Int   '/* day of the month - [1,31] */
    Field tm_mon:Int    '/* months since January - [0,11] */
    Field tm_year:Int   '/* years - [1980..2044] */
EndType
															
Type zip_fileinfo
	Field tmz_date:tm_zip=New tm_zip	'/* date in understandable format           */
	Field dosDate:Long					'/* If dos_date == 0, tmu_date is used      */
	Field internal_fa:Long				'/* internal file attributes        2 bytes */
	Field external_fa:Long				'/* external file attributes        4 bytes */
	
	Method getBank:TBank()
		Local retval:TBank=CreateBank(48)
		
		' tm_zip
		PokeInt(retval,0,tmz_date.tm_sec)
		PokeInt(retval,4,tmz_date.tm_min)
		PokeInt(retval,8,tmz_date.tm_hour)
		PokeInt(retval,12,tmz_date.tm_mday)
		PokeInt(retval,16,tmz_date.tm_mon)
		PokeInt(retval,20,tmz_date.tm_year)

		' fileinfo fields
		PokeLong(retval,24,dosDate)
		PokeLong(retval,32,internal_fa)
		PokeLong(retval,40,external_fa)
						
		Return retval
	EndMethod
EndType
																	    																
Type SZIPFileDataDescriptor
	Field CRC32:Int
	Field CompressedSize:Int
	Field UncompressedSize:Int
	
	Method fill(data:TStream)
		CRC32 = ReadInt(data)
		CompressedSize = ReadInt(data)
		UncompressedSize = ReadInt(data)
	EndMethod
EndType

Type SZIPCentralFileHeader 
	Field Sig:Int
	Field VersionMadeBy:Short
	Field VersionToExtract:Short
	Field GeneralBitFlag:Short
	Field CompressionMethod:Short
	Field LastModFileTime:Short
	Field LastModFileDate:Short	
	Field DataDescriptor:SZIPFileDataDescriptor
	Field FilenameLength:Short
	Field ExtraFieldLength:Short
	Field CommentLength:Short
	Field DiskNumStart:Short
	Field InternalFileAttributes:Short
	Field ExternalFileAttributes:Int
	Field RelativeOffsetOfLocalHeader:Int
	Field FileName:String
	Field ExtraField:String
	Field FileComment:String
	
	Method New()
		DataDescriptor=New SZIPFileDataDescriptor
	EndMethod

	Method fill:Int(data:TStream)
		Sig = ReadInt(data)
		If Sig <> $02014b50 Then ' not a valid header
			SeekStream(data, StreamPos(data) - 4)
			Return False
		EndIf
		VersionMadeBy = ReadShort(data)
		VersionToExtract = ReadShort(data)
		GeneralBitFlag = ReadShort(data)
		CompressionMethod = ReadShort(data)
		LastModFileTime = ReadShort(data)
		LastModFileDate = ReadShort(data)
		DataDescriptor.fill(data)
		FilenameLength = ReadShort(data)
		ExtraFieldLength = ReadShort(data)
		CommentLength = ReadShort(data)
		DiskNumStart = ReadShort(data)
		InternalFileAttributes = ReadShort(data)
		ExternalFileAttributes = ReadInt(data)
		RelativeOffsetOfLocalHeader = ReadInt(data)
		FileName = ReadString(data, FilenameLength)
		ExtraField = ReadString(data, ExtraFieldLength)
		FileComment = ReadString(data, CommentLength)
		
		Return True
	EndMethod
EndType

Type SZipFileEntry
	Field zipFileName:String
	Field simpleFileName:String
	Field path:String
	Field header:SZIPCentralFileHeader

	Function Create:SZipFileEntry()
		Return New SZipFileEntry
	EndFunction

	Method New()
		header=New SZIPCentralFileHeader
	EndMethod

	Method Less:Int(other:SZipFileEntry)
		Return simpleFileName.Compare(other.simpleFileName)<0
	EndMethod

	Method EqEq:Int(other:SZipFileEntry)
		Return simpleFileName.Compare(other.simpleFileName)=0
	EndMethod
	
	Method Compare:Int(other:Object)
		If SZipFileEntry(other) Return simpleFileName.Compare(SZipFileEntry(other).simpleFileName) Else Return -1
	EndMethod
EndType

' ------------------------------------------------
New TZipEngineStreamFactory

Type TZipEngineStreamFactory Extends TStreamFactory
	Method CreateStream:TStream( url:Object, proto:String, path:String, readable:Int, writeable:Int ) 
		Local stream:TZipEStream = Null	

		If proto = "zipe" Then
			If writeable Or Not readable Then
				DebugLog("WARNING: ZipEngine streams are read-only")
			EndIf
			Local parts:String[] = path.Split("::")
			
			If parts.Dimensions()[0] < 2 Or parts.Dimensions()[0] > 3 Then
				DebugLog("Invalid syntax for URL (ex. zipe::zipfilename::file_in_zip::password)")
			Else 			
				Local zipfile:String = parts[0]
				Local filename:String = parts[1]
				Local password:String = Null
				If parts.Dimensions()[0] = 3 Then 
					password = parts[2]
				EndIf
				
				stream = TZipEStream.Create(zipfile, filename, False, password)
			EndIf			
		EndIf
		
		Return stream
	EndMethod

EndType

Rem
	bbdoc: ZipEngine stream type
	about: ZipEngine has as stream wrapper so that files within the ZIP can be opened using OpenStream().  The 
	format for the url is:
	zipe::zipfilename::file_in_zip::password
	The ::password portion is only required if the ZIP has a password.
EndRem
Type TZipEStream Extends TStream

	Field filename:String
	Field case_sensitive:Int = False
	Field password:String = Null
?bmxng
	Field file_size:Long
?Not bmxng
	Field file_size:Int
?
	Field reader:ZipReader = Null

	Function Create:TZipEStream(zipfile:String, filename:String, case_sensitive:Int = False, password:String = Null)
		Local stream:TZipEStream = New TZipEStream

		stream.reader = New ZipReader
		If stream.reader.OpenZip(zipfile) Then
			stream.filename = filename
			stream.case_sensitive = case_sensitive
			stream.password = password
			
			If Not stream.find_file(True) Then stream = Null			
		Else 
			DebugLog("unable to open zip " + zipfile)
			stream = Null
		EndIf
		
		Return stream
	EndFunction

	Method find_file:Int(perform_test_seek:Int = False)
		If (reader.m_zipFile) Then
			Local result:Int
			
			If (case_sensitive) Then
				result = unzLocateFile(reader.m_zipFile, filename, UNZ_CASE_CHECK)
			Else
				result = unzLocateFile(reader.m_zipFile, filename, UNZ_NO_CASE_CHECK)
			End If
					
			If (result = UNZ_OK) Then
				If Not password Then
					result = unzOpenCurrentFile(reader.m_zipFile)
				Else
					result = unzOpenCurrentFilePassword(reader.m_zipFile, password)
				EndIf
				
				If ( result = UNZ_OK ) Then
					file_size = unzGetCurrentFileSize(reader.m_zipFile)			

					' perform a seek to make sure we can actually read
					If (perform_test_seek And Self.Seek(1) <> 1) Then
						Return False
					Else 
						If perform_test_seek Then Self.Seek(0)
						Return True
					EndIf
				Else
					Return False
				EndIf												
			Else
				Return False
			EndIf
		EndIf
		
		Return False
	EndMethod
	
	Method Eof:Int()
		Return unzeof(reader.m_zipFile)
	End Method

?bmxng
	Method Pos:Long()
?Not bmxng
	Method Pos:Int()
?
		Return unztell(reader.m_zipFile)
	End Method

?bmxng
 	Method Size:Long()
?Not bmxng
 	Method Size:Int()
?
		Return file_size
	End Method

?bmxng
	Method Seek:Long(pos:Long, whence:Int = SEEK_SET_)
		Local current_pos:Long = Self.Pos()
?Not bmxng
	Method Seek:Int(pos:Int)
		Local current_pos:Int = Self.Pos()
?
	
		If current_pos > pos Then 
			' need to reseek the file to get to beginning
			If Not find_file() Then RuntimeError "Unable to find file"
			current_pos = Self.Pos()
		EndIf
		
		Local diff:Long = (pos - current_pos)
		Local buf:Byte[1024]
		While diff > 0
			Local count:Long = Min(1024, diff)
			Self.Read(buf, diff)
			diff :- count
		Wend
	
		Return Self.Pos()
	EndMethod

	Method Flush:Int()
	EndMethod

	Method Close:Int()
		If reader Then reader.CloseZip()
	EndMethod

?bmxng
	Method Read:Long(buf:Byte Ptr, count:Long)
?Not bmxng
	Method Read:Int(buf:Byte Ptr, count:Int)
?
		If Not Self.Eof() Then
			Return unzReadCurrentFile(reader.m_zipFile, buf, count)
		Else 
			Return 0
		EndIf		
	EndMethod

EndType