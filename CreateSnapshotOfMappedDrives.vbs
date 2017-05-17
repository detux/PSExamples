'*
'*	.NAME
'* 		createSnapShotMapDrive.vbs
'*	.DATE
'*		31/01/2014
'*	.AUTHOR
'*		<author>
'*	.DESCRIPTION
'*		- Creates a folder [WhatAreMySharedDrives] in the current users MY DOCUMENTS.
'*		- Computes the users mapped drives and list them in a datestamped CSV file.		
'*		- Calls a batch file to copy the program which can be used by the current user to restore their mapped drives.
'*		- On consecutive runs, it creates a temp file with the current mapping and compares with the last modified file in the directory.
'*		- If the file has not changed, it will delete the temp CSV file. 
'*		- If the file has changed, it MOVES the file to the [WhatAreMySharedDrives] folder with the currnet datetime stamp.
'*		- Everytime a new file is created, a copy is sent to \\<share name>\MapMyDrive under the current userlogon name.
'*
Const ForWriting = 2

Dim driveLetter, drivePath, dateTime, csvFileName, strSharedDrive
Dim objFSO, objShell, objTMPFile, objCSVFile, wshNetwork
Dim path, file, recentDate, recentFile, tempFile, result, csvFileToCopy, fld

Set wshNetwork = WScript.CreateObject("WScript.Network")
Set objDrives = wshNetwork.EnumNetworkDrives
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set objShell= createobject("Wscript.Shell")

driveLetter = "DL"
drivePath = "NP"
dateTime = now
csvFileName = Day(dateTime) & "-" & Month(dateTime) & "-" & Year(dateTime) & "-" & Hour(dateTime) & Minute(dateTime) & Second(dateTime) & "_" & "MappedDrive.csv"
strFolder = objShell.SpecialFolders("MyDocuments")
strSharedDrive = strFolder & "\WhatAreMySharedDrives"
usrProfile = objShell.ExpandEnvironmentStrings("%UserProfile%")
tempFile = usrProfile & "\tempSD.csv"
userLogonName = wshNetwork.UserName
supportAccToMapping = "\\<share name>\MapMyDrive" & "\" & userLogonName & "\"
copyFileToServer = strSharedDrive & "\" & csvFileName 



Function qq(str)
  qq = Chr(34) & str & Chr(34)
End Function

'* Does a file compare of the 2 files.
Function AreDifferent(f1, f2)
  cmd = "%COMSPEC% /c fc /b " & qq(f1) & " " & qq(f2)
  AreDifferent = CBool(CreateObject("WScript.Shell").Run(cmd, 0, True))
End Function

Sub sharedDrives

If Not objFSO.FolderExists(supportAccToMapping) Then
	objFSO.CreateFolder(supportAccToMapping)
End If
	
If Not objFSO.FolderExists(strSharedDrive) Then
	objFSO.CreateFolder strSharedDrive
	
	'* Creates a CSV file with the mapped drives.
	Set objCSVFile = objFSO.CreateTextFile(strSharedDrive & "\" & csvFileName, ForAppending, True)
	objCSVFile.Write chr(34) & driveLetter & chr(34) & "," & chr(34) & drivePath & chr(34)
	objCSVFile.WriteLine
	For i = 0 to objDrives.Count - 1 Step 2
		objCSVFile.Write chr(34) & objDrives.Item(i) & chr(34) & ","  & chr(34) & objDrives.Item(i+1) & chr(34)
		objCSVFile.WriteLine
	Next
	objCSVFile.Close
	objFSO.CopyFile copyFileToServer, supportAccToMapping
	
Else
	'* EDIT - 02/03/2015
	'* If the user deletes all csv files from the folder intentionally or otherwise, a new csv file with the current mapped drives is generated.
	Set fld = objFSO.GetFolder(strSharedDrive)
	If fld.Files.Count + fld.SubFolders.Count = 0 Then
		Set objCSVFile = objFSO.CreateTextFile(strSharedDrive & "\" & csvFileName, ForAppending, True)
		objCSVFile.Write chr(34) & driveLetter & chr(34) & "," & chr(34) & drivePath & chr(34)
		objCSVFile.WriteLine
		For i = 0 to objDrives.Count - 1 Step 2
			objCSVFile.Write chr(34) & objDrives.Item(i) & chr(34) & ","  & chr(34) & objDrives.Item(i+1) & chr(34)
			objCSVFile.WriteLine
		Next
		objCSVFile.Close
		objFSO.CopyFile copyFileToServer, supportAccToMapping
	End If
	'* Creates the tempfile with the users current mapping.
	Set objTMPFile = objFSO.CreateTextFile(tempFile, ForAppending, True)
	objTMPFile.Write chr(34) & driveLetter & chr(34) & "," & chr(34) & drivePath & chr(34)
	objTMPFile.WriteLine
	For i = 0 to objDrives.Count - 1 Step 2
		objTMPFile.Write chr(34) & objDrives.Item(i) & chr(34) & ","  & chr(34) & objDrives.Item(i+1) & chr(34)
		objTMPFile.WriteLine
	Next
	objTMPFile.Close
	
	'* Checks for the most recent file.
	Set recentFile = Nothing
	For Each file in objFSO.GetFolder(strSharedDrive).Files
		If (recentFile is Nothing) Then
			Set recentFile = file
		ElseIf (file.DateLastModified > recentFile.DateLastModified) Then
			Set recentFile = file
		End If
	Next
	
	'* Calls the file compare function
	result = AreDifferent(recentFile, tempFile)

	If result = 0 Then
		objFSO.DeleteFile(tempFile)
	Else
		objFSO.MoveFile tempFile, strSharedDrive & "\" & csvFileName
		objFSO.CopyFile copyFileToServer, supportAccToMapping
	End If
End If

'* Copies the restore program to the current users MY DOCUMENTS
getTheParent = objFSO.GetParentFolderName(Wscript.ScriptFullName)
objShell.run getTheParent & "\copyFiles.bat", vbhide
End Sub

'* Main - I start from here !!!
'* EDIT - 02/03/2015
'* If no drives are mapped, no CSV files will be generated.
For i = 0 to objDrives.Count - 1 Step 2
    If(Err.Number = 0) Then
		sharedDrives
	ElseIf(Err.Number <> 0) Then
		Wscript.Quit 1
	End If
Next
