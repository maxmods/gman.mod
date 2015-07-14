Framework BRL.Basic

Rem
	ZipDemo
	Written by Thomas Mayer
	
	Notes:
	Demonstration of the zipping files up into an archive and then getting them back
	using zipEngine
End Rem

Import gman.zipengine

Main() 'Call our entry point

Function Main()
	' Create our zipwriter object
	Local zwObject:ZipWriter = New ZipWriter
	Local zrObject:ZipReader = New ZipReader

	' Example 1
	' Open the zip up for creation.  We pass
	' false in to tell the ZipWriter that we do
	' not wish to append
	If ( zwObject.OpenZip("data.zip", False) ) Then
		zwObject.AddFile("testdata.txt")
		zwObject.AddFile("zipdemo.bmx")
		zwObject.CloseZip()
	End If

	' Example 2
	' Open the zip file we just created and extract
	' a file
	If ( zrObject.OpenZip("data.zip") ) Then
		zrObject.ExtractFileToDisk("testdata.txt", "extracted_testdata.txt")
		zrObject.ExtractFileToDisk("zipdemo.bmx", "extracted_zipdemo.bmx")
		zrObject.CloseZip()
	End If

	' Example 3
	Local fileBuffer:TRamStream = Null
	' Open the zip file we just created and extract
	' a file to ram
	If ( zrObject.OpenZip("data.zip") ) Then
		fileBuffer = zrObject.ExtractFile("testdata.txt")
		zrObject.CloseZip()
	End If

	' Password Example 1
	' Open the zip up for creation.  We pass
	' false in to tell the ZipWriter that we do
	' not wish to append
	If ( zwObject.OpenZip("data_pass.zip", False) ) Then
		zwObject.AddFile("testdata.txt", "gman")
		zwObject.AddFile("zipdemo.bmx", "gman")
		zwObject.CloseZip()
	End If

	' Password Example 2
	' Open the zip file we just created and extract
	' a file
	If ( zrObject.OpenZip("data_pass.zip") ) Then
		Print("filecount: "+zrObject.getFileCount())
		
		' display file information
		For Local i:Int=0 To zrObject.getFileCount()-1
			Print("filename: "+zrObject.getFileInfo(i).zipFileName)
			Print("  simplefilename: "+zrObject.getFileInfo(i).simpleFileName)
			Print("  path: "+zrObject.getFileInfo(i).path)
			Print("  orig size: "+zrObject.getFileInfo(i).header.DataDescriptor.uncompressedsize)
			Print("  comp size: "+zrObject.getFileInfo(i).header.DataDescriptor.compressedsize)
		Next

		zrObject.ExtractFileToDisk("testdata.txt", "extracted_testdata_pass.txt", False, "gman")
		zrObject.ExtractFileToDisk("zipdemo.bmx", "extracted_zipdemo_pass.bmx", False, "gman")
		zrObject.CloseZip()
	End If
	
	' Password Example 3
	fileBuffer = Null
	' Open the zip file we just created and extract
	' a file to ram
	If ( zrObject.OpenZip("data_pass.zip") ) Then
		fileBuffer = zrObject.ExtractFile("testdata.txt", False, "gman")
		zrObject.CloseZip()
	End If

	' Example 4
	' write the buffer from #3 back into the zip
	If ( zwObject.OpenZip("data_pass.zip",True) ) Then
		zwObject.AddStream(fileBuffer,"testdata_stream.txt","gman")
		zwObject.CloseZip()
	End If		

	' Example 5
	' Open the zip and extract the ram file to disk
	' a file
	If ( zrObject.OpenZip("data_pass.zip") ) Then
		zrObject.ExtractFileToDisk("testdata_stream.txt", "extracted_testdata_stream.txt", False, "gman")
		zrObject.CloseZip()
	End If
	
	' Stream Wrapper Example 1
	Local zipstream:TStream = OpenStream("zipe::data_pass.zip::testdata_stream.txt::gman")
	If zipstream Then 
		Print("stream size: " + zipstream.Size())
	EndIf
	
End Function
	
