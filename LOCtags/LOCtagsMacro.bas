Attribute VB_Name = "LOCtagsMacro"
Option Explicit
Option Base 1
Dim activeRng As Range

Sub TagMSforCIP()
' This is the sub to call from a button in the template.
    UserForm1.LabelProgress.Width = 0
    UserForm1.LabelDesc = "Starting macro..."
    UserForm1.Show
End Sub
Private Sub ProgressBar(pctDone As Single, eventCaption As String)

With UserForm1
    .FrameProgress.Caption = Format(pctDone, "0%")
    .LabelProgress.Width = pctDone * .FrameProgress.Width
    .LabelDesc.Caption = eventCaption
End With

End Sub
Sub LibraryOfCongressTags()
'This sub must remain public as it is called from the UserForm (progress bar)

'''''''''''''''''''''''''''''''''
'''created by Matt Retzer  - matthew.retzer@macmillan.com
'''2/25/15
'''Version 1.6
'''Updated: 4/14/15: adding progress bar
'''Updated: 4/13/15: adding content control handling for PC
'''Updated: 3/4/15 : revised chapter numbering loop for performance, edited ELC styles and added tag for ELC with no end styles
'''Updated: 3/8/15 : switching to Whole word searches for the 4 items with closing tags
'''                           : & allowing for ^m Page Break check/fix to get </ch> inline with final chapter text
'''         3/10/15 : revamped ELC </ch> again to make it inline.
'''                 : used same method to make cp, tp, toc and sp closing tags inline-- match whole words broke with hyperlinks
'''         3/24/15 : re-did ELC in case of atax or other styles present early in manuscript ; uses while loop to scan for first backmatter style that
'''                 is not eventually followed by <ch#> or <tp> tag
''''''''''''''''''''''''''''''

'-----------run preliminary error checks------------
Call ProgressBar(0.1, "Checking Macmillan Style Template...")

Dim exitOnError As Boolean
Dim skipChapterTags As Boolean
exitOnError = zz_errorChecksB()
skipChapterTags = volumestylecheck()

If exitOnError <> False Then
Call zz_clearFindB
Unload UserForm1        'To close progress bar if exiting sub
Exit Sub
End If

'-----------the rest of the macro------------
Application.DisplayStatusBar = True
Application.ScreenUpdating = False

'----------remove content controls from PC---
' can't remove from Mac, breaks whole sub--
Dim TheOS As String
TheOS = System.OperatingSystem

If Not TheOS Like "*Mac*" Then
Call ClearContentControls
End If

Call ProgressBar(0.2, "Adding tags for Title page...")

Application.StatusBar = "Adding tags for Title page...": DoEvents
Call tagTitlePage
Call zz_clearFindB

Call ProgressBar(0.3, "Adding tags for Copyright page...")

Application.StatusBar = "Adding tags for Copyright page": DoEvents
Call tagCopyrightPage
Call zz_clearFindB

Call ProgressBar(0.4, "Adding tags for Series page...")

Application.StatusBar = "Adding tags for Series page": DoEvents
Call tagSeriesPage
Call zz_clearFindB

Call ProgressBar(0.5, "Adding tags for Table of Contents...")

Application.StatusBar = "Adding tags for Table of Contents": DoEvents
Call tagTOC
Call zz_clearFindB



If skipChapterTags = False Then
    Call ProgressBar(0.6, "Adding tags for chapters...")
    Application.StatusBar = "Adding tags for Chapter beginnings": DoEvents
    Call tagChapterHeads
    Call zz_clearFindB
    
    Application.StatusBar = "Adding tag for end last chapter": DoEvents
    Call tagEndLastChapter
    Call zz_clearFindB
End If

Call ProgressBar(0.7, "Saving as text document...")

Application.StatusBar = "Saving as text document": DoEvents
Call SaveAsTextFile

Call ProgressBar(0.8, "Running tag check & generating report...")

Application.StatusBar = "Running tag check & generating report": DoEvents
Call zz_TagReport

Call ProgressBar(0.9, "Cleaning up file...")

Application.StatusBar = "Cleaning up file": DoEvents
Call cleanFile
Call zz_clearFindB

Call ProgressBar(0.99, "Finishing up...")

Application.ScreenUpdating = True
Application.ScreenRefresh

'If skipChapterTags = True Then
'    MsgBox "Library of Congress tagging is complete except for Chapter tags." & vbNewLine & vbNewLine & "Chapter tags will need to be manually applied."
'End If

Unload UserForm1        'To close progress bar if exiting sub; UserForm1.Hide triggers activation again on Mac
End Sub

Private Sub tagChapterHeads()

Set activeRng = ActiveDocument.Range
Dim CHstylesArray(3) As String                                   ' number of items in array should be declared here
Dim i As Long
Dim chTag As Integer

CHstylesArray(1) = "Chap Number (cn)"
CHstylesArray(2) = "Chap Title (ct)"
CHstylesArray(3) = "Chap Title Nonprinting (ctnp)"

For i = 1 To UBound(CHstylesArray())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = ""
  .Replacement.Text = "`CH|^&|CH`"
  .Wrap = wdFindContinue
  .Format = True
  .Style = CHstylesArray(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = True
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

Call zz_clearFindB

Dim CHfauxTags(4) As String         ' number of items in arrays should be declared here
Dim CHLOCtags(4) As String

CHfauxTags(1) = "`CH||CH`"
CHfauxTags(2) = "|CH``CH|"
CHfauxTags(3) = "|CH`"
CHfauxTags(4) = "`CH|"
                                                   
CHLOCtags(1) = ""
CHLOCtags(2) = ""
CHLOCtags(3) = ""
CHLOCtags(4) = "<ch>"

For i = 1 To UBound(CHfauxTags())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = CHfauxTags(i)
  .Replacement.Text = CHLOCtags(i)
  .Wrap = wdFindContinue
  .Format = False
  .Forward = True
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

'adapted from fumei's Range find here: http://www.vbaexpress.com/forum/showthread.php?41244-Loop-until-not-found
chTag = 1

With activeRng.Find
.Text = "<ch>"
Do While .Execute(Forward:=True) = True
With activeRng
.MoveEnd unit:=wdCharacter, Count:=-1
.InsertAfter (chTag)
.Collapse direction:=wdCollapseEnd
.Move unit:=wdCharacter, Count:=1
End With
chTag = chTag + 1
Loop
End With

'previous chapter number tag method (too slow)
'Dim chapNum As Integer
'Dim chapNumString As String
'chapNum = 1
'chapNumString = "<ch" & chapNum & ">"
'
''this is borrowed form here:  http://stackoverflow.com/questions/11234358/word-2007-macro-to-automatically-number-items-in-a-document
'Do While InStr(ActiveDocument.Content, "<ch>") > 0
'    chapNumString = "<ch" & chapNum & ">"
'    With ActiveDocument.Content.Find
'        .ClearFormatting
'        .Text = "<ch>"
'        .Execute Replace:=wdReplaceOne, ReplaceWith:=chapNumString, Forward:=True
'    End With
'    chapNum = chapNum + 1
'Loop

End Sub



Private Sub tagTitlePage()

'to update this for a different tag, replace all in procedure for the two char tag, eg: TP->CH ; this will update array variables too
'update styles array manually, and Dim'd stylesarray length,
'update the LOC tags to match LOC:  http://www.loc.gov/publish/cip/techinfo/formattingecip.html#tags
''' NOTE:  if you are tagging something only at the beginning or end (eg chapter heads), obviously you need to touch up the second loop

Set activeRng = ActiveDocument.Range
Dim TPstylesArray(10) As String                                   ' number of items in array should be declared here
Dim i As Long

TPstylesArray(1) = "Titlepage Author Name (au)"
TPstylesArray(2) = "Titlepage Book Subtitle (stit)"
TPstylesArray(3) = "Titlepage Book Title (tit)"
TPstylesArray(4) = "Titlepage Cities (cit)"
TPstylesArray(5) = "Titlepage Contributor Name (con)"
TPstylesArray(6) = "Titlepage Imprint Line (imp)"
TPstylesArray(7) = "Titlepage Publisher Name (pub)"
TPstylesArray(8) = "Titlepage Reading Line (rl)"
TPstylesArray(9) = "Titlepage Series Title (ser)"
TPstylesArray(10) = "Titlepage Translator Name (tran)"

For i = 1 To UBound(TPstylesArray())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = ""
  .Replacement.Text = "`TP|^&|TP`"
  .Wrap = wdFindContinue
  .Format = True
  .Style = TPstylesArray(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

Call zz_clearFindB

Dim TPfauxTags(3) As String
Dim TPLOCtags(2) As String
Dim directionBool(2) As Boolean

TPfauxTags(1) = "`TP|"
TPfauxTags(2) = "|TP`"
TPfauxTags(3) = "``````"          'this bit is to make sure tagging is inline with last styled paragraph,
                                                    'instead of the tag falling into the following style eblock
TPLOCtags(1) = "<tp>"
TPLOCtags(2) = "``````"

directionBool(1) = True
directionBool(2) = False

For i = 1 To UBound(TPLOCtags())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = TPfauxTags(i)
  .Replacement.Text = TPLOCtags(i)
  .Wrap = wdFindContinue
  .Format = False
  .Forward = directionBool(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceOne
End With
Next

Call zz_clearFindB

With activeRng.Find
    .Text = "``````"
    .Replacement.Text = ""
    .Forward = True
    .Wrap = wdFindContinue
    .Format = False
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
End With

If activeRng.Find.Execute = True Then
    With activeRng.Find
        .Text = "[!^13^m`]"
        .Replacement.Text = "^&</tp>"
        .Forward = False
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = True
        .MatchWildcards = True
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        .Execute Replace:=wdReplaceOne
    End With
End If

Call zz_clearFindB

For i = 1 To UBound(TPfauxTags())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = TPfauxTags(i)
  .Replacement.Text = ""
  .Wrap = wdFindContinue
  .Format = False
  .Forward = True
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

End Sub

Private Sub tagCopyrightPage()

'to update this for a different tag, replace all in procedure two char code, eg: TP->CP
'update styles array manually, and Dim'd stylesarray length, & that's it

Set activeRng = ActiveDocument.Range
Dim CPstylesArray(2) As String                                   ' number of items in array should be declared here
Dim i As Long

CPstylesArray(1) = "Copyright Text double space (crtxd)"
CPstylesArray(2) = "Copyright Text single space (crtx)"

For i = 1 To UBound(CPstylesArray())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = ""
  .Replacement.Text = "`CP|^&|CP`"
  .Wrap = wdFindContinue
  .Format = True
  .Style = CPstylesArray(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

Call zz_clearFindB

Dim CPfauxTags(3) As String
Dim CPLOCtags(2) As String
Dim directionBool(2) As Boolean

CPfauxTags(1) = "`CP|"
CPfauxTags(2) = "|CP`"
CPfauxTags(3) = "``````"          'this bit is to make sure tagging is inline with last styled paragraph,
                                                    'instead of the tag falling into the following style eblock
CPLOCtags(1) = "<cp>"
CPLOCtags(2) = "``````"

directionBool(1) = True
directionBool(2) = False

For i = 1 To UBound(CPLOCtags())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = CPfauxTags(i)
  .Replacement.Text = CPLOCtags(i)
  .Wrap = wdFindContinue
  .Format = False
  .Forward = directionBool(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceOne
End With
Next

Call zz_clearFindB

With activeRng.Find
    .Text = "``````"
    .Replacement.Text = ""
    .Forward = True
    .Wrap = wdFindContinue
    .Format = False
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
End With

If activeRng.Find.Execute = True Then
    With activeRng.Find
        .Text = "[!^13^m`]"
        .Replacement.Text = "^&</cp>"
        .Forward = False
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = True
        .MatchWildcards = True
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        .Execute Replace:=wdReplaceOne
    End With
End If

Call zz_clearFindB

For i = 1 To UBound(CPfauxTags())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = CPfauxTags(i)
  .Replacement.Text = ""
  .Wrap = wdFindContinue
  .Format = False
  .Forward = True
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

Call zz_clearFindB

End Sub


Private Sub tagTOC()

'to update this for a different tag, replace all in procedure two char code, eg: TP->TOC
'update styles array manually, and Dim'd stylesarray length, & that's it

Set activeRng = ActiveDocument.Range
Dim TOCstylesArray(10) As String                                   ' number of items in array should be declared here
Dim i As Long

TOCstylesArray(1) = "TOC Frontmatter Head (cfmh)"
TOCstylesArray(2) = "TOC Author (cau)"
TOCstylesArray(3) = "TOC Part Number  (cpn)"
TOCstylesArray(4) = "TOC Part Title (cpt)"
TOCstylesArray(5) = "TOC Chapter Number (ccn)"
TOCstylesArray(6) = "TOC Chapter Title (cct)"
TOCstylesArray(7) = "TOC Chapter Subtitle (ccst)"
TOCstylesArray(8) = "TOC Level-1 Chapter Head (ch1)"
TOCstylesArray(9) = "TOC Backmatter Head (cbmh)"
TOCstylesArray(10) = "TOC Page Number (cnum)"

For i = 1 To UBound(TOCstylesArray())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = ""
  .Replacement.Text = "`TOC|^&|TOC`"
  .Wrap = wdFindContinue
  .Format = True
  .Style = TOCstylesArray(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

Call zz_clearFindB

Dim TOCfauxTags(3) As String
Dim TOCLOCtags(2) As String
Dim directionBool(2) As Boolean

TOCfauxTags(1) = "`TOC|"
TOCfauxTags(2) = "|TOC`"
TOCfauxTags(3) = "``````"          'this bit is to make sure tagging is inline with last styled paragraph,
                                                    'instead of the tag falling into the following style eblock
TOCLOCtags(1) = "<toc>"
TOCLOCtags(2) = "``````"

directionBool(1) = True
directionBool(2) = False

For i = 1 To UBound(TOCLOCtags())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = TOCfauxTags(i)
  .Replacement.Text = TOCLOCtags(i)
  .Wrap = wdFindContinue
  .Format = False
  .Forward = directionBool(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceOne
End With
Next

Call zz_clearFindB

With activeRng.Find
    .Text = "``````"
    .Replacement.Text = ""
    .Forward = True
    .Wrap = wdFindContinue
    .Format = False
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
End With

If activeRng.Find.Execute = True Then
    With activeRng.Find
        .Text = "[!^13^m`]"
        .Replacement.Text = "^&</toc>"
        .Forward = False
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = True
        .MatchWildcards = True
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        .Execute Replace:=wdReplaceOne
    End With
End If

Call zz_clearFindB

For i = 1 To UBound(TOCfauxTags())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = TOCfauxTags(i)
  .Replacement.Text = ""
  .Wrap = wdFindContinue
  .Format = False
  .Forward = True
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

End Sub

Private Sub tagSeriesPage()

'to update this for a different tag, replace all in procedure two char code, eg: TP->SP
'update styles array manually, and Dim'd stylesarray length, & that's it

Set activeRng = ActiveDocument.Range
Dim SPstylesArray(8) As String                                   ' number of items in array should be declared here
Dim i As Long

SPstylesArray(1) = "Series Page Heading (sh)"
SPstylesArray(2) = "Series Page Text (stx)"
SPstylesArray(3) = "Series Page Text No-Indent (stx1)"
SPstylesArray(4) = "Series Page List of Titles (slt)"
SPstylesArray(5) = "Series Page Author (sau)"
SPstylesArray(6) = "Series Page Subhead 1 (sh1)"
SPstylesArray(7) = "Series Page Subhead 2 (sh2)"
SPstylesArray(8) = "Series Page Subhead 3 (sh3)"

For i = 1 To UBound(SPstylesArray())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = ""
  .Replacement.Text = "`SP|^&|SP`"
  .Wrap = wdFindContinue
  .Format = True
  .Style = SPstylesArray(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

Call zz_clearFindB

Dim SPfauxTags(3) As String
Dim SPLOCtags(2) As String
Dim directionBool(2) As Boolean

SPfauxTags(1) = "`SP|"
SPfauxTags(2) = "|SP`"
SPfauxTags(3) = "``````"          'this bit is to make sure tagging is inline with last styled paragraph,
                                                    'instead of the tag falling into the following style eblock
SPLOCtags(1) = "<sp>"
SPLOCtags(2) = "``````"

directionBool(1) = True
directionBool(2) = False

For i = 1 To UBound(SPLOCtags())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = SPfauxTags(i)
  .Replacement.Text = SPLOCtags(i)
  .Wrap = wdFindContinue
  .Format = False
  .Forward = directionBool(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceOne
End With
Next

Call zz_clearFindB

With activeRng.Find
    .Text = "``````"
    .Replacement.Text = ""
    .Forward = True
    .Wrap = wdFindContinue
    .Format = False
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = False
    .MatchSoundsLike = False
    .MatchAllWordForms = False
End With

If activeRng.Find.Execute = True Then
    With activeRng.Find
        .Text = "[!^13^m`]"
        .Replacement.Text = "^&</sp>"
        .Forward = False
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = True
        .MatchWildcards = True
        .MatchSoundsLike = False
        .MatchAllWordForms = False
        .Execute Replace:=wdReplaceOne
    End With
End If

Call zz_clearFindB

For i = 1 To UBound(SPfauxTags())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = SPfauxTags(i)
  .Replacement.Text = ""
  .Wrap = wdFindContinue
  .Format = False
  .Forward = True
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

End Sub

Private Sub tagEndLastChapter()

Set activeRng = ActiveDocument.Range
Dim ELCstylesArray(9) As String                                   ' number of items in array should be declared here
Dim i As Long

ELCstylesArray(1) = "BM Head (bmh)"
ELCstylesArray(2) = "BM Title (bmt)"
ELCstylesArray(3) = "Appendix Head (aph)"
ELCstylesArray(4) = "Appendix Subhead (apsh)"
ELCstylesArray(5) = "Note Level-1 Subhead (n1)"
ELCstylesArray(6) = "Biblio Level-1 Subhead (b1)"
ELCstylesArray(7) = "About Author Text (atatx)"
ELCstylesArray(8) = "About Author Text No-Indent (atatx1)"
ELCstylesArray(9) = "About Author Text Head (atah)"

For i = 1 To UBound(ELCstylesArray())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = ""
  .Replacement.Text = "``````^&"
  .Wrap = wdFindContinue
  .Format = True
  .Style = ELCstylesArray(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = True
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

Call zz_clearFindB

' Declare vars related to part 2 (loop etc)
Dim testvar As Boolean
Dim testtag As String
Dim q As Long
Dim bookmarkRng As Range
Dim dontTag As Boolean
Dim activeRngB As Range
Set activeRngB = ActiveDocument.Range
dontTag = False
testvar = False
testtag = "\<ch[0-9]{1,}\>"
q = 0

''if <ch> not found, testtag= <tp>
With activeRng.Find
    .Text = testtag
    .Forward = True
    .Wrap = wdFindContinue
    .Format = False
    .MatchCase = False
    .MatchWholeWord = False
    .MatchWildcards = True
    .MatchSoundsLike = False
    .MatchAllWordForms = False
End With
If activeRng.Find.Execute = False Then
    testtag = "\<tp\>"
    With activeRngB.Find
        .Text = testtag
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = True
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    If activeRngB.Find.Execute = False Then
        dontTag = True
    End If
End If

'start loop
Do While testvar = False
Dim activeRngC As Range
Set activeRngC = ActiveDocument.Range

    With activeRngC.Find
        .Text = "``````"
        .Forward = True
        .Wrap = wdFindContinue
        .Format = False
        .MatchCase = False
        .MatchWholeWord = False
        .MatchWildcards = False
        .MatchSoundsLike = False
        .MatchAllWordForms = False
    End With
    ''set range with bookmarks, only search after init tag
    If activeRngC.Find.Execute = True Then
        ActiveDocument.Bookmarks.Add Name:="elcBookmark", Range:=activeRngC
        Set bookmarkRng = ActiveDocument.Range(Start:=ActiveDocument.Bookmarks("elcBookmark").Range.Start, End:=ActiveDocument.Bookmarks("\EndOfDoc").Range.End)
    Else
        Exit Do
    End If
    
    Set activeRng = ActiveDocument.Range
    
    Call zz_clearFindB
    
    'check for <ch> tags afer potential </ch> tag
    With bookmarkRng.Find
        .ClearFormatting
        .Text = testtag
        .Forward = True
        .Wrap = wdFindStop
        .MatchWildcards = True
    End With
    
    If bookmarkRng.Find.Execute = True Then
            'Found one. This one's not it.
            ''Remove first tagged paragraph's tag, will loop
            With activeRng.Find
                .Text = "``````"
                .Replacement.Text = ""
                .Forward = True
                .Wrap = wdFindStop
                .Format = False
                .MatchCase = False
                .MatchWholeWord = False
                .MatchWildcards = False
                .MatchSoundsLike = False
                .MatchAllWordForms = False
                .Execute Replace:=wdReplaceOne
            End With
            q = q + 1
    Else
            ''This one's good, tag it right, set var to exit loop
            With activeRng.Find
                .Text = "``````"
                .Replacement.Text = ""
                .Forward = True
                .Wrap = wdFindContinue
                .Format = False
                .MatchCase = False
                .MatchWholeWord = False
                .MatchWildcards = False
                .MatchSoundsLike = False
                .MatchAllWordForms = False
            End With
            If activeRng.Find.Execute = True Then
                If dontTag = False Then
                    With activeRng.Find
                        .Text = "[!^13^m`]"
                        .Replacement.Text = "^&</ch>"
                        .Forward = False
                        .Wrap = wdFindContinue
                        .Format = False
                        .MatchCase = False
                        .MatchWholeWord = True
                        .MatchWildcards = True
                        .MatchSoundsLike = False
                        .MatchAllWordForms = False
                        .Execute Replace:=wdReplaceOne
                    End With
                End If
            End If
            testvar = True
    End If
        
    If ActiveDocument.Bookmarks.Exists("elcBookmark") = True Then
        ActiveDocument.Bookmarks("elcBookmark").Delete
    End If
    
    If q = 20 Then      'prevent endless loops
        testvar = True
        dontTag = True
    End If

Loop

Call zz_clearFindB

'Get rid of rest of ELC tags
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = "``````"
  .Replacement.Text = ""
  .Wrap = wdFindContinue
  .Format = False
  .Forward = True
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With

'If no </ch> tags exist, add </ch> to the end of the doc
If dontTag = False Then
    With activeRng.Find
      .ClearFormatting
      .Replacement.ClearFormatting
      .Text = "</ch>"
      .Wrap = wdFindContinue
      .Format = False
      .Forward = True
      .MatchCase = False
      .MatchWholeWord = False
      .MatchWildcards = False
      .MatchSoundsLike = False
      .MatchAllWordForms = False
    End With
    If activeRng.Find.Execute = False Then
        Set activeRng = ActiveDocument.Range
        activeRng.InsertAfter "</ch>"
    End If
End If

End Sub
Private Sub SaveAsTextFile()
 
 ' Saves a copy of the document as a text file in the same path as the parent document
    Dim strDocName As String
    Dim docPath As String
    Dim intPos As Integer
    Dim encodingFmt As String
    Dim lineBreak As Boolean

Application.ScreenUpdating = False

'Separate code by OS because ActiveDocument.Path returns file name too
' on Mac but doesn't for PC

#If Mac Then        'For Mac
    If Val(Application.Version) > 14 Then
        
        'Find position of extension in filename
        strDocName = ActiveDocument.Path
        intPos = InStrRev(strDocName, ".")
        
            'Strip off extension and add ".txt" extension
            strDocName = Left(strDocName, intPos - 1)
            strDocName = strDocName & "_CIP.txt"
        
    End If
    
#Else                           'For Windows

    'Find position of extension in filename
    strDocName = ActiveDocument.Name
    docPath = ActiveDocument.Path
    intPos = InStrRev(strDocName, ".")
    
            'Strip off extension and add ".txt" extension
            strDocName = Left(strDocName, intPos - 1)
            strDocName = docPath & "\" & strDocName & "_CIP.txt"
        
#End If

    'Copy text of active document and paste into a new document
    'Because otherwise open document is converted to .txt, and we want it to stay .doc*
    ActiveDocument.Select
    Selection.Copy
    'PasteSpecial because otherwise gives a warning about too many styles being pasted
    Documents.Add.Content.PasteSpecial DataType:=wdPasteText
    
' Set different text encoding based on OS
' And Mac can't create file with line breaks
#If Mac Then
    If Val(Application.Version) > 14 Then
        encodingFmt = msoEncodingMacRoman
        lineBreak = False
    End If
#Else               'For Windows
    encodingFmt = msoEncodingUSASCII
    lineBreak = True
#End If

'Turn off alerts because PC warns before saving with this encoding
Application.DisplayAlerts = wdAlertsNone

    'Save new document as a text file. Encoding/Line Breaks/Substitutions per LOC info
    ActiveDocument.SaveAs FileName:=strDocName, _
        FileFormat:=wdFormatEncodedText, _
        Encoding:=encodingFmt, _
        InsertLineBreaks:=lineBreak, _
        AllowSubstitutions:=True
        
Application.DisplayAlerts = wdAlertsAll
    Documents(strDocName).Close
    
Application.ScreenUpdating = True
    
End Sub



Private Sub cleanFile()
Set activeRng = ActiveDocument.Range
Dim tagsFind(10) As String         ' number of items in arrays should be declared here
Dim a As Long

tagsFind(1) = "\<tp\>"
tagsFind(2) = "\<\/tp\>"
tagsFind(3) = "\<cp\>"
tagsFind(4) = "\<\/cp\>"
tagsFind(5) = "\<sp\>"
tagsFind(6) = "\<\/sp\>"
tagsFind(7) = "\<toc\>"
tagsFind(8) = "\<\/toc\>"
tagsFind(9) = "\<ch*\>"
tagsFind(10) = "\<\/ch\>"

For a = 1 To UBound(tagsFind())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = tagsFind(a)
  .Replacement.Text = ""
  .Wrap = wdFindContinue
  .Format = False
  .Forward = True
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = True
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute Replace:=wdReplaceAll
End With
Next

End Sub
Private Function volumestylecheck()

Set activeRng = ActiveDocument.Range
volumestylecheck = False
Dim VOLstylesArray(2) As String                                   ' number of items in array should be declared here
Dim i As Long
Dim mainDoc As Document
Set mainDoc = ActiveDocument
Dim iReply As Integer

VOLstylesArray(1) = "Volume Number (voln)"
VOLstylesArray(2) = "Volume Title (volt)"

For i = 1 To UBound(VOLstylesArray())
With activeRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = ""
  .Wrap = wdFindContinue
  .Format = True
  .Style = VOLstylesArray(i)
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  If .Execute Then                          'Returns true if text was found.
     iReply = MsgBox(mainDoc & "' contains a 'Volume' paragraph style." & vbNewLine & vbNewLine & _
        "To continue submitting this for Library of Congress ingestion as a single volume (standard tags), click 'YES'." & vbNewLine & vbNewLine & _
        "If submitting as a 'single application for multiple volumes': click 'NO' to proceed with auto-tagging exempting chapter tags (<ch></ch>)." & vbNewLine & _
        "Chapter tags wil unfortunately need to be manually applied in this case." & vbNewLine & vbNewLine & _
        "For further guidance please email macsupport@macmillanusa.com", vbYesNoCancel, "Alert")
    If iReply = vbYes Then
        Exit Function
    ElseIf iReply = vbNo Then
        volumestylecheck = True
        Exit Function
    Else
        End
    End If
  End If
End With
Next

End Function
Private Sub ClearContentControls()
'This is it's own sub because doesn't exist in Mac Word, breaks whole sub if included
Dim cc As ContentControl

For Each cc In ActiveDocument.ContentControls
    cc.Delete
Next

End Sub

Private Sub zz_clearFindB()

Dim clearRng As Range
Set clearRng = ActiveDocument.Words.First

With clearRng.Find
  .ClearFormatting
  .Replacement.ClearFormatting
  .Text = ""
  .Replacement.Text = ""
  .Wrap = wdFindStop
  .Format = False
  .MatchCase = False
  .MatchWholeWord = False
  .MatchWildcards = False
  .MatchSoundsLike = False
  .MatchAllWordForms = False
  .Execute
End With
End Sub


Private Function zz_errorChecksB()                       'kidnapped this whole function from macmillan.dotm
                                                                'adding tag checking to include LOC stuff
zz_errorChecksB = False
Dim mainDoc As Document
Set mainDoc = ActiveDocument
Dim iReply As Integer

'-----make sure Style template is attached
Dim keyStyle As Word.Style
Dim styleCheck As Boolean
On Error Resume Next
Set keyStyle = mainDoc.Styles("span boldface characters (bf)")                '''Style from template to check against
styleCheck = keyStyle Is Nothing
If styleCheck Then
MsgBox "Oops! Required Macmillan style template is not attached.", , "Error"
zz_errorChecksB = True
Exit Function
End If

'-----make sure document is saved
Dim docSaved As Boolean                                                                                                 'v. 3.1 update
docSaved = mainDoc.Saved
If docSaved = False Then
    iReply = MsgBox("Your document '" & mainDoc & "' contains unsaved changes." & vbNewLine & vbNewLine & _
        "Click OK and I will save the document and run the CIP macro." & vbNewLine & vbNewLine & "Click 'Cancel' to exit.", vbOKCancel, "Alert")
    If iReply = vbOK Then
        mainDoc.Save
    Else
        zz_errorChecksB = True
        Exit Function
    End If
End If

'-----test protection
If ActiveDocument.ProtectionType <> wdNoProtection Then
MsgBox "Uh oh ... protection is enabled on document '" & mainDoc & "'." & vbNewLine & "Please unprotect the document and run the macro again." & vbNewLine & vbNewLine & "TIP: If you don't know the protection password, try pasting contents of this file into a new file, and run the macro on that.", , "Error 2"
zz_errorChecksB = True
Exit Function
End If

'-----test if backtick style tag already exists
Set activeRng = ActiveDocument.Range
Application.ScreenUpdating = False

Dim existingTagArray(7) As String                                   ' number of items in array should be declared here
Dim b As Long
Dim foundBad As Boolean
foundBad = False

existingTagArray(1) = "[`|]CH[|`]"
existingTagArray(2) = "`ELC|"
existingTagArray(3) = "[`|]CP[|`]"
existingTagArray(4) = "[`|]TP[|`]"
existingTagArray(5) = "[`|]TOC[|`]"
existingTagArray(6) = "[`|]SP[|`]"
existingTagArray(7) = "``````"

For b = 1 To UBound(existingTagArray())
With activeRng.Find
  .ClearFormatting
  .Text = existingTagArray(b)
  .Wrap = wdFindContinue
  .MatchWildcards = True
End With
If activeRng.Find.Execute Then foundBad = True: Exit For
Next

Application.ScreenUpdating = True
Application.ScreenRefresh
If foundBad = True Then                'If activeRng.Find.Execute Then
    MsgBox "Something went wrong! The LOC tags Macro cannot be run on Document:" & vbNewLine & "'" & mainDoc & "'" _
    & vbNewLine & vbNewLine & "Please contact Digital Workflow group for support, I am sure they will be happy to help.", , "Error Code: 1"
    zz_errorChecksB = True
    Exit Function
End If

'-----test if LOC tags already exists

Dim existingLOCArray(9) As String
Dim c As Long
Dim foundLOC As Boolean
Dim foundLOCitem As String
foundLOC = False
Dim iReplyB As Integer

existingLOCArray(1) = "<sp>"
existingLOCArray(2) = "</sp>"
existingLOCArray(3) = "</ch>"
existingLOCArray(4) = "<cp>"
existingLOCArray(5) = "</cp>"
existingLOCArray(6) = "<toc>"
existingLOCArray(7) = "</toc>"
existingLOCArray(8) = "<tp>"
existingLOCArray(9) = "</tp>"
'existingLOCArray(10) = "<ch[0-9]{1,}>"

For c = 1 To UBound(existingLOCArray())
With activeRng.Find
  .ClearFormatting
  .Text = existingLOCArray(c)
  .Wrap = wdFindContinue
  .MatchWildcards = False
End With
If activeRng.Find.Execute Then
    foundLOC = True
    foundLOCitem = existingLOCArray(c)
    Exit For
End If
Next

'doing it again with wildcards=True, to catch numbered chapters
With activeRng.Find
  .ClearFormatting
  .Text = "<ch[0-9]{1,}>"
  .Wrap = wdFindContinue
  .MatchWildcards = True
End With
If activeRng.Find.Execute Then
    foundLOC = True
    foundLOCitem = "(chapter heading tag, e.g. <ch1>, <ch2>, ... )"
End If

Application.ScreenUpdating = True
Application.ScreenRefresh
If foundLOC = True Then
    MsgBox "Your document: '" & mainDoc & "' already contains at least one Library of Congress tag:" & vbNewLine & vbNewLine & foundLOCitem & vbNewLine & vbNewLine & _
    "This macro may have already been run on this document. To run this macro, you MUST find and remove all existing LOC tags first.", , "Alert"
    zz_errorChecksB = True
    Exit Function
End If

End Function

Private Sub zz_TagReport()

Application.ScreenUpdating = False

Dim activeDoc As Document
Set activeDoc = ActiveDocument
Set activeRng = ActiveDocument.Range
Dim activeDocName As String
Dim activeDocPath As String
Dim LOCreportDoc As String
Dim LOCreportDocAlt As String
Dim TheOS As String
TheOS = System.OperatingSystem
Dim fnum As Integer
activeDocName = Left(activeDoc.Name, InStrRev(activeDoc.Name, ".doc") - 1)
activeDocPath = Replace(activeDoc.Path, activeDoc.Name, "")

'count occurences of all but Chapter Heads
Dim MyDoc As String, txt As String, t As String
Dim LOCtagArray(9) As String
Dim LOCtagCount(9) As Integer
Dim d As Long
MyDoc = ActiveDocument.Range.Text

LOCtagArray(1) = "<tp>"
LOCtagArray(2) = "</tp>"
LOCtagArray(3) = "<cp>"
LOCtagArray(4) = "</cp>"
LOCtagArray(5) = "<sp>"
LOCtagArray(6) = "</sp>"
LOCtagArray(7) = "<toc>"
LOCtagArray(8) = "</toc>"
LOCtagArray(9) = "</ch>"

For d = 1 To UBound(LOCtagArray())
    txt = LOCtagArray(d)
    t = Replace(MyDoc, txt, "")
    LOCtagCount(d) = ((Len(MyDoc) - Len(t)) / Len(txt))
Next

Call zz_clearFindB

Dim chTagCount As Long

'Count occurences of Chapter Heads
With activeRng.Find
  .ClearFormatting
  .Text = "<ch[0-9]{1,}>"
  .MatchWildcards = True
Do While .Execute(Forward:=True) = True
chTagCount = chTagCount + 1
Loop
End With

Call zz_clearFindB

'Prepare error message
Dim errorList As String
errorList = ""
If LOCtagCount(1) = 0 And LOCtagCount(2) = 0 Then errorList = errorList & "ERROR: No Title Page tags found. Title page tags are REQUIRED for LOC submission." & vbNewLine
If LOCtagCount(3) = 0 And LOCtagCount(4) = 0 Then errorList = errorList & "ERROR: No Copyright Page tags found. Copyright page tags are REQUIRED for LOC submission." & vbNewLine
If LOCtagCount(1) > 1 Or LOCtagCount(1) <> LOCtagCount(2) Then errorList = errorList & "ERROR: Problem with Title Page tags: either too many were found or one is missing" & vbNewLine
If LOCtagCount(3) > 1 Or LOCtagCount(3) <> LOCtagCount(4) Then errorList = errorList & "ERROR: Problem with Copyright Page tags: either too many were found or one is missing" & vbNewLine
If LOCtagCount(5) > 1 Or LOCtagCount(5) <> LOCtagCount(6) Then errorList = errorList & "ERROR: Problem with Series Page tags: either too many were found or one is missing" & vbNewLine
If LOCtagCount(7) > 1 Or LOCtagCount(7) <> LOCtagCount(8) Then errorList = errorList & "ERROR: Problem with Table of Contents tags: either too many were found or one is missing" & vbNewLine
If chTagCount = 0 Then errorList = errorList & "WARNING: No Chapter Heading tags were found." & vbNewLine
If LOCtagCount(9) = 0 Then errorList = errorList & "WARNING: No 'End of Last Chapter' tag was found." & vbNewLine

'create text file
LOCreportDoc = activeDocPath & activeDocName & "_LOCtagReport.txt"

''''for 32 char Mc OS bug- could check if this is Mac OS too< PART 1
If Not TheOS Like "*Mac*" Then                      'If Len(activeDocName) > 18 Then        (legacy, does not take path into account)
    LOCreportDoc = activeDocPath & "\" & activeDocName & "_LOCtagReport.txt"
Else
    Dim placeholdDocName As String
    placeholdDocName = "filenamePlacehold_LOCreport.txt"
    LOCreportDocAlt = LOCreportDoc
    LOCreportDoc = "Macintosh HD:private:tmp:" & placeholdDocName
End If
'''end ''''for 32 char Mc OS bug part 1

'set and open file for output
fnum = FreeFile()
Open LOCreportDoc For Output As fnum
If errorList = "" Then
    Print #fnum, "Congratulations!" & vbCr
    Print #fnum, "LOC Tags look good for " & activeDoc.Name & vbCr
    Print #fnum, "See summary below:" & vbCr
    Print #fnum, vbCr
Else
    Print #fnum, "BAD NEWS:" & vbCr
    Print #fnum, vbCr
    Print #fnum, "Problems were found with LOC tags in your document '" & activeDoc.Name & "':" & vbCr
    Print #fnum, vbCr
    Print #fnum, vbCr
    Print #fnum, "------------------------- ERRORS -------------------------" & vbCr
    Print #fnum, errorList
    Print #fnum, vbCr
    Print #fnum, vbCr
End If
    Print #fnum, "------------------------- Tag Summary -------------------------" & vbCr
    Print #fnum, LOCtagCount(1) & "  Title page open tag(s) found <tp>"
    Print #fnum, LOCtagCount(2) & "  Title page close tag(s) found </tp>"
    Print #fnum, LOCtagCount(3) & "  Copyright page open tag(s) found <cp>"
    Print #fnum, LOCtagCount(4) & "  Copyright page close tag(s) found </cp>"
    Print #fnum, LOCtagCount(5) & "  Series page open tag(s) found <sp>"
    Print #fnum, LOCtagCount(6) & "  Series page close tag(s) found </sp>"
    Print #fnum, LOCtagCount(7) & "  Table of Contents open tag(s) found <toc>"
    Print #fnum, LOCtagCount(8) & "  Table of Contents close tag(s) found </toc>"
    Print #fnum, chTagCount & "  Chapter beginning tag(s) found (<ch1>, <ch2>, etc)"
    Print #fnum, LOCtagCount(9) & "  End of last chapter tag(s) found </ch>"
Close #fnum

''''for 32 char Mc OS bug-<PART 2
If LOCreportDocAlt <> "" Then
Name LOCreportDoc As LOCreportDocAlt
End If
''''END for 32 char Mc OS bug-<PART 2

Application.ScreenUpdating = True
Application.ScreenRefresh

'open LOC tags Report for user once it is complete.
Dim Shex As Object

If Not TheOS Like "*Mac*" Then
   Set Shex = CreateObject("Shell.Application")
   Shex.Open (LOCreportDoc)
Else
    MacScript ("tell application ""TextEdit"" " & vbCr & _
    "open " & """" & LOCreportDocAlt & """" & " as alias" & vbCr & _
    "activate" & vbCr & _
    "end tell" & vbCr)
End If

End Sub
