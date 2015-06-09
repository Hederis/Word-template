Attribute VB_Name = "AttachTemplateMacro"
Option Explicit

Sub zz_AttachStyleTemplate()


''''''''''''''''''''''''''''''''
'''created by Matt Retzer  - matthew.retzer@macmillan.com
'''version 2.1.1
'''updated 4/8/2015 by Erica Warren: changing download URL to new Confluence server: confluence.macmillan.com
'''updated 4/1/2015 by Erica Warren: Adding zz_AttachCoverTemplate sub and editing other subs to only download the template that is being attached.
'''updated 2/3/15 by Erica Warren: Changed PCupdateCheck and MacUpdateCheck to functions that return false if the template should NOT be attached.
'''updated 1/30 by Erica Warren: added PCupdateCheck sub
'''updated 1/30 by Matt Retzer: added MacupdateCheck sub & shell and wait function, updated Mac template file path


Dim TheOS As String
Dim myFile As String
Dim template As String
Dim myFilePC As String
Dim currentUser As String
Dim myFileMac As String
Dim versionDoc As String


TheOS = System.OperatingSystem
template = "macmillan.dotm"
versionDoc = "versions"
myFilePC = Environ("PROGRAMDATA") & "\MacmillanStyleTemplate\" & template

'Set template path according to OS
If Not TheOS Like "*Mac*" Then
                                   'I am Windows
    If PCupdateCheck(template, versionDoc) = False Then
        Exit Sub
    Else
        myFile = myFilePC
    End If
    
Else                             'I am a Mac
    If MacUpdateCheck(template, versionDoc) = False Then
        Exit Sub
    Else
        currentUser = MacScript("tell application " & Chr(34) & "System Events" & Chr(34) & Chr(13) & "return (name of current user)" & Chr(13) & "end tell")
        myFile = "Macintosh HD:Users:" & currentUser & ":Documents:MacmillanStyleTemplate:" & template
    End If
End If
    
    'Check that file exists
    If FileOrDirExists(myFile) = True Then
    
        'Apply template with Styles
        With ActiveDocument
            .UpdateStylesOnOpen = True
            .AttachedTemplate = myFile
        End With
    Else
        MsgBox "There was a problem attaching the template to your document." & vbNewLine & vbNewLine & _
                "Please contact workflows@macmillan.com for assistance.", vbCritical, "Oh no!"
    End If
    
End Sub
Sub zz_AttachBoundMSTemplate()

Dim TheOS As String
Dim myFile As String
Dim template As String
Dim myFilePC As String
Dim currentUser As String
Dim myFileMac As String
Dim versionDoc As String


TheOS = System.OperatingSystem
template = "macmillan_NoColor.dotm"
versionDoc = "versions"
myFilePC = Environ("PROGRAMDATA") & "\MacmillanStyleTemplate\" & template

'Set template path according to OS
If Not TheOS Like "*Mac*" Then
                                   'I am Windows
    If PCupdateCheck(template, versionDoc) = False Then
        Exit Sub
    Else
        myFile = myFilePC
    End If
    
Else                             'I am a Mac
    If MacUpdateCheck(template, versionDoc) = False Then
        Exit Sub
    Else
        currentUser = MacScript("tell application " & Chr(34) & "System Events" & Chr(34) & Chr(13) & "return (name of current user)" & Chr(13) & "end tell")
        myFile = "Macintosh HD:Users:" & currentUser & ":Documents:MacmillanStyleTemplate:" & template
    End If
End If

    If FileOrDirExists(myFile) = True Then
    
        'Apply template with Styles
        With ActiveDocument
            .UpdateStylesOnOpen = True
            .AttachedTemplate = myFile
        End With
    Else
        MsgBox "There was a problem attaching the template to your document." & vbNewLine & vbNewLine & _
                "Please contact workflows@macmillan.com for assistance.", vbCritical, "Oh no!"
    End If
    
End Sub
Sub zz_AttachCoverTemplate()

Dim TheOS As String
Dim myFile As String
Dim template As String
Dim myFilePC As String
Dim currentUser As String
Dim myFileMac As String
Dim versionDoc As String


TheOS = System.OperatingSystem
template = "MacmillanCoverCopy.dotm"
versionDoc = "CoverVersion"
myFilePC = Environ("PROGRAMDATA") & "\MacmillanStyleTemplate\" & template

'Set template path according to OS
If Not TheOS Like "*Mac*" Then
                                   'I am Windows
    If PCupdateCheck(template, versionDoc) = False Then
        Exit Sub
    Else
        myFile = myFilePC
    End If
    
Else                             'I am a Mac
    If MacUpdateCheck(template, versionDoc) = False Then
        Exit Sub
    Else
        currentUser = MacScript("tell application " & Chr(34) & "System Events" & Chr(34) & Chr(13) & "return (name of current user)" & Chr(13) & "end tell")
        myFile = "Macintosh HD:Users:" & currentUser & ":Documents:MacmillanStyleTemplate:" & template
    End If
End If

    If FileOrDirExists(myFile) = True Then
    
        'Apply template with Styles
        With ActiveDocument
            .UpdateStylesOnOpen = True
            .AttachedTemplate = myFile
        End With
    Else
        MsgBox "There was a problem attaching the template to your document." & vbNewLine & vbNewLine & _
                "Please contact workflows@macmillan.com for assistance.", vbCritical, "Oh no!"
    End If
    
End Sub

'''created by Matt Retzer  - matthew.retzer@macmillan.com
'''update by Erica Warren - erica.warren@macmillan.com
'''version 1.0
'''updated 2/3/15 by Erica Warren: added more error handling, message prompt to update, more events logged'
''' updated 2/2/2015:   PC version downloads both templates
'''                     error handling for when template is open (changed PC Sub to Function)
''' updated 1/30/2015: PC version works with macmillan.dotm & macmillan_NoColor.dotm

Function PCupdateCheck(templateFile As String, versionFile As String)

Dim dirNamePC As String
Dim logFileName As String
Dim logFilePC As String
Dim currentUser As String                   'could set for MAc & PC   Does pre-binding matter?
Dim updateCheck As Boolean
Dim updateFrequency As Integer
Dim logString As String                         'could  set a few values for this up front
Dim lastModDate As Date
Dim currentVersionST As String              'ST=StyleTemplate
Dim installedVersionST As String
Dim localDrive As String
Dim templateFile2 As String
    
PCupdateCheck = True
logFileName = "macmillan_macros.log"
updateCheck = True
updateFrequency = 1         'number of days between update checks
logString = ""
installedVersionST = "(none installed)"         'default
localDrive = Environ("PROGRAMDATA") & "\MacmillanStyleTemplate"             'use variable because not everyone has local drive set as C:
dirNamePC = localDrive & "\log"
logFilePC = dirNamePC & "\" & logFileName
    
    
'''check if logfile exists
If Dir(logFilePC) <> vbNullString Then        '''file exists
    ''get date modified of logfile
    lastModDate = FileDateTime(logFilePC)
        
        '''compare with current date
        If DateDiff("d", lastModDate, Date) < updateFrequency Then
            updateCheck = False                 'has already been checked in "updateFrequency" days
            logString = Now & " -- updateCheck = " & updateCheck & ". Already checked less than " & updateFrequency & " day(s) ago."
        End If
            
Else     '''file does not exist
    
    '''Check if MacmillanStyleTemplate folder exists
    If Dir(localDrive, vbDirectory) = vbNullString Then
        MkDir (localDrive)                  ''create MacmillanStyleTemplate folder
        MkDir (dirNamePC)                   ''create log subfolder because MkDir can't create both at the same time in VBA
        logString = Now & " -- created MacmillanStyleTemplate directory"
    Else ' MacmillanStyleTemplate folder already exists, so just create log folder
        If Dir(dirNamePC, vbDirectory) = vbNullString Then
            MkDir (dirNamePC)
        End If
        logString = Now & " -- created logfile "
    
    End If
    
End If

'check if template file exists at all
If FileOrDirExists(localDrive & "\" & templateFile) = False Then
    updateCheck = True
End If
    
'''run log setup sub
LogInformation logFilePC, logString

'**********************************************************
'updateCheck = True          'For testing and debugging only
'**********************************************************

If updateCheck = False Then
    Exit Function
    
Else ' updateCheck is still True

    'Get version number of installed style template
    Dim pcTemplatePath As String
    
    If Dir(localDrive & "\" & templateFile) = vbNullString Then  ' template file does not exist
        installedVersionST = 0
    Else
        pcTemplatePath = localDrive & "\" & templateFile
        Documents.Open fileName:=pcTemplatePath, ReadOnly:=True, Visible:=False
        installedVersionST = Documents(pcTemplatePath).CustomDocumentProperties("version")
        Documents(pcTemplatePath).Close
    End If
    
    'try to download current version's text file
    Dim myURL As String
    Dim WinHttpReq As Object
    Dim oStream As Object
    Dim templateURL As String
    
    templateURL = "https://confluence.macmillan.com/download/attachments/9044274/"  'this is download link, actual page housing template is http://confluence.macmillan.com/display/PBL/Test
    myURL = templateURL & versionFile

    Set WinHttpReq = CreateObject("Microsoft.XMLHTTP")
    WinHttpReq.Open "GET", myURL, False
    On Error Resume Next
    WinHttpReq.Send

        ' Exit sub if error in connecting to website
        
        If Err.Number <> 0 Then 'HTTP request is not OK
            LogInformation logFilePC, Now & " -- tried to update " & templateFile & "; unable to connect to Confluence website (check network connectivity)"
            PCupdateCheck = True ''still attach old template if can't download new one
            Exit Function
        End If
    On Error GoTo 0

Debug.Print WinHttpReq.Status

    If WinHttpReq.Status = 200 Then  ' 200 = HTTP request is OK
    
        'if connection OK, download file and save to log directory
        myURL = WinHttpReq.responseBody
        Set oStream = CreateObject("ADODB.Stream")
        oStream.Open
        oStream.Type = 1
        oStream.Write WinHttpReq.responseBody
        oStream.SaveToFile dirNamePC & "\" & versionFile, 2 ' 1 = no overwrite, 2 = overwrite
        oStream.Close
        Set oStream = Nothing
        Set WinHttpReq = Nothing
    End If
End If
    
'Get version number of current template
Dim g_strVar As String
g_strVar = ImportVariable(dirNamePC & "\" & versionFile)
currentVersionST = g_strVar
    
'If installed = current
If installedVersionST >= currentVersionST Then
    LogInformation logFilePC, Now & " -- current & installed versions of " & templateFile & " match (current version is " & currentVersionST & ")."
    Exit Function
Else 'installed template is less than current template
    If MsgBox("Your template " & templateFile & " is out of date." & vbNewLine & vbNewLine & "Click OK to update it automatically." & vbNewLine & vbNewLine & "The update should take less than 1 minute.", vbOKCancel, "UPDATE REQUIRED") = vbCancel Then
        LogInformation logFilePC, Now & " -- New " & templateFile & " is available but user canceled update (installed version is " & installedVersionST & "/current version is " & currentVersionST & ")"
        PCupdateCheck = True  ''old template will still attach if user cancels update.
        Exit Function
    End If
    
    'download the template file to log directory
    myURL = templateURL & templateFile
    Set WinHttpReq = CreateObject("Microsoft.XMLHTTP")
    WinHttpReq.Open "GET", myURL, False
    WinHttpReq.Send
    
    If WinHttpReq.Status = 200 Then  ' 200 = HTTP request is OK
        myURL = WinHttpReq.responseBody
        Set oStream = CreateObject("ADODB.Stream")
        oStream.Open
        oStream.Type = 1
        oStream.Write WinHttpReq.responseBody
        oStream.SaveToFile dirNamePC & "\macmillanNew.dotm", 2 ' 1 = no overwrite, 2 = overwrite
        oStream.Close
        Set oStream = Nothing
        Set WinHttpReq = Nothing
    End If
    
    'log the download.
    LogInformation logFilePC, Now & " -- Downloaded new " & templateFile & " Style Template version: " & currentVersionST & "  (Installed version was " & installedVersionST & ")"
            
    'Check if template file is already open/in use
    If FileLocked(localDrive & "\" & templateFile) = True Then 'FileLocked function (below) tries to open file and returns True if error
       If MsgBox("The update cannot be completed because this Macmillan template is in use by another file." & vbNewLine & vbNewLine & "Please close ALL open Word files, then restart Word and attach the template to a new document.", vbOKOnly, "ACTION REQUIRED") = vbOK Then
            Kill dirNamePC & "\macmillanNew.dotm"
            PCupdateCheck = False
            LogInformation logFilePC, Now & " -- old template file " & templateFile & " is locked for editing and can't be deleted. Telling user to close all open Word files and try again."
            Exit Function
        End If
    End If

    'remove existing template file
    If Dir(localDrive & "\" & templateFile) <> vbNullString Then 'File exists
        Kill localDrive & "\" & templateFile
    End If
    
    'Move new file to correct location and rename
    Name dirNamePC & "\macmillanNew.dotm" As localDrive & "\" & templateFile
    
        'Error checking: make sure downloaded file was deleted when renamed
        If Dir(dirNamePC & "\macmillanNew.dotm") <> vbNullString Then 'New file was downloaded but couldn't be moved/renamed. Probably because original template file is open or in use.
            Kill dirNamePC & "\macmillanNew.dotm"
            LogInformation logFilePC, Now & " -- temp downloaded file of " & templateFile & " couldn't be renamed. Update failed."
            MsgBox "There was an error upgrading your template." & vbNewLine & vbNewLine & "Please close ALL open Word files, then restart Word and attach the template to a new document." & vbNewLine & vbNewLine & "If the problem persists, please contact workflows@macmillan.com for help.", , "ACTION REQUIRED"
            Exit Function
        Else 'file was moved correctly, we're OK
            LogInformation logFilePC, Now & " -- Replaced existing " & templateFile & " Style Template."
            MsgBox "The Macmillan Style Template " & templateFile & " has been upgraded to version " & currentVersionST & " on your computer.", , "UPDATE COMPLETED"
        End If
            
End If

End Function

Function MacUpdateCheck(templateFile As String, versionFile As String)
                                                                   
' updated 2/11/15 by Erica Warren: fixed typos.
' updated 2/3/15 by Erica Warren: added more error handling, message prompt to update, more events logged'
           
Dim dirNameBash As String
Dim dirNameMac As String
Dim logFileName As String
Dim logFileMac As String
Dim currentUser As String                   'could set for MAc & PC   Does pre-binding matter?
Dim updateCheck As Boolean
Dim updateFrequency As Integer
Dim logString As String                         'could  set a few values for this up front
Dim lastModDate As Date
Dim cvUrl As String                                 'cvUrl = currentVersionUrl
Dim dlUrl As String                                  'download Url
Dim currentVersionST As String              'ST=StyleTemplate
Dim installedVersionST As String
Dim localDrive As String



'''set update variables
MacUpdateCheck = True
updateCheck = True                                      'default
updateFrequency = 1                                     'number of days between update checks
logString = "created logfile: " & Now               'for first run ; any other outcome results in this string being reset
cvUrl = "https://confluence.macmillan.com/display/PBL/Test"
dlUrl = "https://confluence.macmillan.com/download/attachments/9044274"
installedVersionST = "(none installed)"         'default

'''set Mac vars
'could do currentUSer via shell but OSA is a cleaner command
currentUser = MacScript("tell application " & Chr(34) & "System Events" & Chr(34) & Chr(13) & "return (name of current user)" & Chr(13) & "end tell")
dirNameBash = "/Users/" & currentUser & "/Documents/MacmillanStyleTemplate"
dirNameMac = "Macintosh HD:Users:" & currentUser & ":Documents:MacmillanStyleTemplate:"
logFileName = "macmillan_macros_update.log"
logFileMac = dirNameMac & logFileName
            
'''see when last checked for updates
'''check if logfile exists
    If ShellAndWaitMac("[ -e " & dirNameBash & "/" & logFileName & " ] ; echo $?") = 0 Then                         '''file exists
            '''get date modified of logfile
            lastModDate = FileDateTime(logFileMac)
            '''compare with current date - if not today
            If DateDiff("d", lastModDate, Date) < updateFrequency Then
                   updateCheck = False
                   logString = Now & " -- updateCheck = " & updateCheck & ". Already checked in the last " & updateFrequency & " day(s)."
            Else
                   logString = Now & " -- updateCheck = " & updateCheck
            End If
'''This is either first update or first run ; verify/create directories & create logfile
    Else                                                                                                                         '''file does not exist
            ShellAndWaitMac ("[ -e " & dirNameBash & " ] &>/dev/null || mkdir -p " & dirNameBash)
    End If

'check if template file exists at all
If FileOrDirExists(dirNameMac & templateFile) = False Then
        updateCheck = True
    End If

'''run log setup sub
LogInformation logFileMac, logString

'*******************************************
'updateCheck = True '*******  for DEBUG ONLY
'********************************************

'''Here begins the updating
    If updateCheck = False Then
            Exit Function
    Else
            'check for network.  Skipping domain since we are looking at confluence, but would test ping hbpub.net or mpl.root-domain.org
            If ShellAndWaitMac("ping -o google.com &> /dev/null ; echo $?") <> 0 Then
                    LogInformation logFileMac, Now & " -- tried update; unable to connect to Confluence website (check network connectivity)"
                    Exit Function
            Else
                    'check current Version if it exists, exit if it matches
                    If ShellAndWaitMac("[ -e " & dirNameBash & "/" & templateFile & " ] ; echo $?") = 0 Then
                            currentVersionST = ShellAndWaitMac("curl -s " & cvUrl & " | grep -m 1 macmillan.dotm | awk -F'Version' '{print$2}' | awk '{print$1}'")
                            installedVersionST = ShellAndWaitMac("cp -rfp " & dirNameBash & "/" & templateFile & " /private/tmp/macmillan.zip ; unzip -qu /private/tmp/macmillan.zip -d /private/tmp ; cat /private/tmp/docProps/custom.xml | awk -F'vt:lpwstr' '{print $2}' | tr -d '<>/\\n'")
                            'MsgBox currentVersionST & ", " & installedVersionST     '<-for debug
                            'cleanup tmp
                            ShellAndWaitMac ("rm -f /private/tmp/Macmillan* /private/tmp/macmillan*")
                            If currentVersionST = installedVersionST Then
                                    LogInformation logFileMac, Now & " -- current & installed versions match (" & currentVersionST & ").  Style Template already up to date"
                                    updateCheck = False
                                    Exit Function
                            End If
                    Else
                            'No template present, proceeding with download - getting current version for log
                            currentVersionST = ShellAndWaitMac("curl -s " & cvUrl & " | grep -m 1 macmillan.dotm | awk -F'Version' '{print$2}' | awk '{print$1}'")
                            LogInformation logFileMac, Now & " -- Style Template not present, updateCheck = " & updateCheck & ".  Downloading"
                    End If
            End If
    End If

If MsgBox("Your Macmillan Style Template is out of date." & vbNewLine & vbNewLine & "Click OK to update it automatically." & vbNewLine & vbNewLine & "The update should take less than 1 minute.", vbOKCancel, "UPDATE REQUIRED") = vbCancel Then
    LogInformation logFileMac, Now & " -- New " & templateFile & " is available but user canceled update (installed version is " & installedVersionST & "/current version is " & currentVersionST & ")"
    MacUpdateCheck = True  ''old template will still attach if user cancels update.
    Exit Function
Else
    

'''download first template file to tmp
    ShellAndWaitMac ("rm -f /private/tmp/macmillanNew.dotm ; curl -o /private/tmp/macmillanNew.dotm " & dlUrl & "/" & templateFile)
    LogInformation logFileMac, Now & " -- Downloaded new " & templateFile & " version: " & currentVersionST & ".  (installed version was " & installedVersionST & ")"

        'Check if template file is locked and can't be deleted
    If ShellAndWaitMac("[ -e " & dirNameBash & "/" & templateFile & " ] ; echo $?") = 0 Then ' file exists
        If FileLocked(dirNameMac & templateFile) = True Then
            If MsgBox("The update cannot be completed because the Macmillan template is in use by another file. Please close ALL open Word files then restart Word and attach the template again.", vbOKOnly, "ACTION REQUIRED") = vbOK Then
                MacUpdateCheck = False
                LogInformation logFileMac, Now & " -- old template file is locked for editing and can't be deleted. Telling user to close all open Word files."
                Exit Function
            End If
        Else
            MacUpdateCheck = True
        End If
    End If

'''remove existing template file:  could Kill dirNameMac & "macmillan.dotm"  But Using rm for one liner
    ShellAndWaitMac ("rm -f " & dirNameBash & "/" & templateFile & " >/dev/null")

'''replace existing template file
    Name "Macintosh HD:private:tmp:macmillanNew.dotm" As dirNameMac & templateFile
            
            'Error checking: make sure downloaded file was deleted when renamed
            If ShellAndWaitMac("[ -e " & dirNameBash & "/macmillanNew.dotm" & " ] ; echo $?") = 0 Then ' file exists
                LogInformation logFileMac, Now & " -- temp downloaded file couldn't be renamed. Update failed."
                MsgBox "There was an error upgrading your template." & vbNewLine & vbNewLine & "Please close ALL open Word files, then restart Word and attach the template to a new document." & vbNewLine & "If the problem persists, please contact workflows@macmillan.com for help.", , "ACTION REQUIRED"
                Exit Function
            Else 'file doesn't exist, we're OK
                LogInformation logFileMac, Now & " -- Replaced existing " & templateFile & " Style Template."
            End If
            
    'download Versions file so version is readily visible from client Mac
    ShellAndWaitMac ("rm -f  " & dirNameBash & "/Version-* ; curl -o " & dirNameBash & "/Version-" & templateFile & ".txt " & dlUrl & "/" & versionFile)
    MsgBox "The Macmillan Style Template has been upgraded to version " & currentVersionST & " on your Mac.", , "UPDATE COMPLETED"
    
End If
End Function



Private Sub LogInformation(logFile As String, LogMessage As String)

Dim FileNum As Integer
    FileNum = FreeFile ' next file number
    Open logFile For Append As #FileNum ' creates the file if it doesn't exist
    Print #FileNum, LogMessage ' write information at the end of the text file
    Close #FileNum ' close the file
End Sub



Private Function ImportVariable(strFile As String) As String
 
    Open strFile For Input As #1
    Line Input #1, ImportVariable
    Close #1
 
End Function


Private Function ShellAndWaitMac(cmd As String) As String

Dim result As String
Dim scriptCmd As String ' Macscript command
'
scriptCmd = "do shell script """ & cmd & """"
result = MacScript(scriptCmd) ' result contains stdout, should you care
ShellAndWaitMac = result
End Function

Private Function FileLocked(strFileName As String) As Boolean
   On Error Resume Next
   ' If the file is already opened by another process,
   ' and the specified type of access is not allowed,
   ' the operation fails and an error occurs.
   Open strFileName For Binary Access Read Write Lock Read Write As #1
   Close #1
   ' If an error occurs, the document is currently open.
   If Err.Number <> 0 Then
      FileLocked = True
      Err.Clear
   End If
End Function
Function FileOrDirExists(PathName As String) As Boolean
     ' From here: http://www.vbaexpress.com/kb/getarticle.php?kb_id=559
     'Macro Purpose: Function returns TRUE if the specified file
     '               or folder exists, false if not.
     'PathName     : Supports Windows mapped drives or UNC
     '             : Supports Macintosh paths
     'File usage   : Provide full file path and extension
     'Folder usage : Provide full folder path
     '               Accepts with/without trailing "\" (Windows)
     '               Accepts with/without trailing ":" (Macintosh)
     
    Dim iTemp As Integer
     
     'Ignore errors to allow for error evaluation
    On Error Resume Next
    iTemp = GetAttr(PathName)
     
     'Check if error exists and set response appropriately
    Select Case Err.Number
    Case Is = 0
        FileOrDirExists = True
    Case Else
        FileOrDirExists = False
    End Select
     
     'Resume error checking
    On Error GoTo 0
End Function



