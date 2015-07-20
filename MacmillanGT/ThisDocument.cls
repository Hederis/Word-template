VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ThisDocument"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = True
Option Explicit
Option Base 1

Sub AutoExec()
'=======================================
' By Erica Warren - erica.warren@macmillan.com
'
'===== USE ===============================
' Sets variable names (file names and directories) for Installer sub in FileInstaller module.
'
'===== DEPENDENCIES ========================
' This is part 1 of 2. It calls the Installer sub, which downloads and installs the Macmillan style templates and macros.
' If this is meant to be an installer, it should be called "Document_Open()" and reside in the ThisDocument module in a .docm file.
' If this is meant to be an updater, it should be called "AutoExec()" and reside in the ThisDocument module in a .dotm file,
' and be saved in the STARTUP directory.
'
' Requires FileInstaller and SharedMacros modules be installed in the same template.
        
    ' ======= For testing / debugging ==============
     MsgBox "I am MacmillanGT and I am running!"
    ' ==============================================
    
    Dim blnStaging As Boolean
    Dim blnInstaller As Boolean
    Dim strTemplateName As String
    Dim strFileName() As String
    Dim strFileDir() As String
    
    Dim strPcStyleDir As String
    Dim strPcStartupDir As String
    Dim strMacStyleDir As String
    Dim strMacStartupDir As String
    Dim strMacUser As String
    
'==========================================================================================
    'DEFINE ALL YOUR VARIABLES HERE
    
    'Make sure to switch to FALSE before going live!
    blnStaging = True
    
    'True = standalone installer file, False = daily update checker already installed
    blnInstaller = False
    
    'Plain English name of what you're installing/updating, should be singular
    strTemplateName = "Macmillan Styles"
    
    'Update array lengths and template file names here
    ReDim strFileName(1 To 4)               'Declare number of files here
    ReDim strFileDir(1 To 4)                'And here
    
    'File names you're installing/updating
    'strFileName(1) = "MacmillanGT.dotm"
    strFileName(1) = "GtUpdater.dotm"
    strFileName(2) = "macmillan.dotm"
    strFileName(3) = "macmillan_NoColor.dotm"
    strFileName(4) = "MacmillanCoverCopy.dotm"
    
    ' Enter the home directories for your templates here, for Mac *AND* PC
    #If Mac Then
        strMacUser = MacScript("tell application " & Chr(34) & "System Events" & Chr(34) & Chr(13) & _
                "return (name of current user)" & Chr(13) & "end tell")
        strMacStyleDir = "Macintosh HD:Users:" & strMacUser & ":Documents:MacmillanStyleTemplate"
        strMacStartupDir = "Macintosh HD:Applications:Microsoft Office 2011:Office:Startup:Word"
    #Else
        strPcStyleDir = Environ("PROGRAMDATA") & "\MacmillanStyleTemplate"
        strPcStartupDir = Environ("APPDATA") & "\Microsoft\Word\STARTUP"
    #End If
'=============================================================================================
    
    #If Mac Then
        'strFileDir(1) = strMacStartupDir      'Final directory you're installing file in on a Mac
        strFileDir(1) = strMacStartupDir
        strFileDir(2) = strMacStyleDir
        strFileDir(3) = strMacStyleDir
        strFileDir(4) = strMacStyleDir
    #Else
        'strFileDir(1) = strPcStartupDir      'Final directory you're installing file in on a PC
        strFileDir(1) = strPcStartupDir
        strFileDir(2) = strPcStyleDir
        strFileDir(3) = strPcStyleDir
        strFileDir(4) = strPcStyleDir
    #End If
        
    'Check that same number of file names and directories
    If UBound(strFileName()) <> UBound(strFileDir()) Then
        MsgBox "Number of files for download must match number of directories.", vbCritical, "OOPS!"
        Exit Sub
    End If
    
    'Installer = True if this is for a standalone installation file; False is for a daily update checker
    Call FileInstaller.Installer(Staging:=blnStaging, Installer:=blnInstaller, TemplateName:=strTemplateName, FileName:=strFileName(), FinalDir:=strFileDir())
    
End Sub
