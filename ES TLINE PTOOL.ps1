<#
===============================================================================================
 ES TLINE PTOOL  -  Eversource (ES) Transmission Line Photo Tool
 M. J. Electric (a Quanta Services company)
===============================================================================================

 HOW TO RUN
   Right-click the file > "Run with PowerShell"
   - or -  powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\ES TLINE PTOOL.ps1"
   Works in Windows PowerShell 5.1 (built into Windows 10/11) and PowerShell 7+ on Windows.
   No installs needed (uses WinForms + System.Drawing; WPF/WIC only as a fallback for HEIC).

-----------------------------------------------------------------------------------------------
 CONTEXT FOR A FUTURE AI / DEVELOPER (feed this whole file into a fresh context window)
-----------------------------------------------------------------------------------------------
 ORIGINAL REQUEST (from the M. J. Electric user, paraphrased only where needed for ASCII):

   Create a single PowerShell file called "ES TLINE PTOOL". This tool should provide the user
   with a GUI, accept photos, process the photos, and offer to save them to a location for the
   user that saves the processed photos. The processing specification is set out by our
   customer Eversource (ES) (spec text reproduced below).

   The GUI should:
     - Collect the Structure Number (required, integer)
     - Existing or Replacement structure (the old structure, or the new one we replaced/installed)
     - Cross Brace Present (does the structure have a cross brace / cross arm; default present)
     - X-Bracing Present (does the structure have x-bracing; default present)
     - # Ahead Span Anomalies (integer, default 0 - ahead-facing anomaly photos in the set)
     - # Back Span Anomalies (integer, default 0 - back-facing anomaly photos in the set)
     - Photos - let the user drop in their photos (pulled from a phone or camera). Make sure
       they all have GPS EXIF data. They are taken in the order of the customer spec, so the
       tool knows which photo is which. That is why we ask whether cross brace, x-brace and
       anomalies are included - to calculate their numbering.
     - Process Photos button - on click validate input and process.

   For each photo: name it (in order based on spec and user options) and categorize it into
   folders as appropriate. Place the M.J. Electric logo in the top-right corner, no more than
   ~7% (best judgement), keep it transparent, drop the small "A Quanta Services Company" line.
   The logo is baked into this file as base64 (see $LogoBase64 at the bottom of CONFIG).

   Add a black bar to the bottom of the image (rotate images so they appear right side up) and
   center yellow text in the bar:   $FILE NAME // LAT: $LATITUDE // LONG: $LONGITUDE
     Font: Segoe UI Bold   Color: #FFFF00 (changed to #FFEF00 in v13)   Size: adjust to fit
     Alignment: centered vertically and horizontally in the black bar

   Then open a window with the processed photos (in order; later changed to a grid, opening at
   the top) for the user to scroll and verify. At the bottom put a "Save Photos" button that prompts for the folder to save
   the two processed folders in.

   Bake this request and the spec into the file so it can be fed into a fresh context window.

 CUSTOMER SPEC - Eversource, Line 391 - 2024 ACR - Specification, Item 9 Photographic Documentation
   "The Contractor must provide photograph evidence of the structure and surrounding area both
    prior and post replacement. The photographs must be within a line labeled folder and then be
    separated into a folder per structure labeled with that structure number. All photographs
    must have the appropriate tagging with GPS locations. The photograph requirements are:"

   Existing Structure Ahead Span                    Existing Structure Back Span
     100' away looking ahead   (Str # - 1 Before AH)  100' away                 (Str # - 1 Before BK)
     Full structure close up   (Str # - 2 Before AH)  Full structure close up   (Str # - 2 Before BK)
     Cross Arm (if applicable) (Str # - 3 Before)*    Cross Arm (if applicable) (Str # - 3 Before BK)
     X-Bracing (if applicable) (Str # - 4 Before AH)  X-Bracing (if applicable) (Str # - 4 Before BK)
     Left Insulator & attach.  (Str # - 5 Before AH)  Left Insulator & attach.  (Str # - 5 Before BK)
     Middle Insulator & attach.(Str # - 6 Before AH)  Middle Insulator & attach.(Str # - 6 Before BK)
     Right Insulator & attach. (Str # - 7 Before AH)  Right Insulator & attach. (Str # - 7 Before BK)
     Left Static Wire Attach.  (Str # - 8 Before AH)  Left Static Wire Attach.  (Str # - 8 Before BK)
     Right Static Wire Attach. (Str # - 9 Before AH)  Right Static Wire Attach. (Str # - 9 Before BK)
     Picture per Anomaly, i.e. woodpecker hole, rot, broken insulator, etc. (if applicable)
       (Str # - 10 Before AH) (Str # - 11 Before AH) ... (Str # - # Before AH)   [same for BK]
     * spec typo - the tool uses "Before AH" for consistency.

   Replacement Structure Ahead Span / Back Span: identical items 1-9 with "After AH" / "After BK".
   The spec lists NO anomaly photos for replacement structures.

   "Photo documentation shall be uploaded to project SharePoint site prior to requesting payment."
   Pay item 9.1 Photo Documentation, Complete; Each Structure.

-----------------------------------------------------------------------------------------------
 DESIGN DECISIONS / ASSUMPTIONS (change in CONFIG below if the customer clarifies)
-----------------------------------------------------------------------------------------------
  * Shooting order assumed = spec order: whole Ahead (AH) span set first (1..9 then AH
    anomalies), then whole Back (BK) span set (1..9 then BK anomalies).
  * Photos are auto-sorted by EXIF DateTimeOriginal (falls back to file modified time), and the
    user can re-order with Move Up / Move Down. Photo N in the list -> slot N.
  * Numbering keeps the SPEC's fixed slot numbers: if Cross Arm is absent, number 3 is skipped
    (1,2,4,5...). Set RenumberSequential = $true to renumber 1..N with no gaps instead.
  * "Cross Brace Present" in the GUI maps to the spec's "Cross Arm" slot (#3).
  * Anomaly inputs are disabled for Replacement (After) structures, per spec.
    Set AllowAnomaliesOnReplacement = $true to allow them.
  * File name:  "Str <num> - <n> <Before|After> <AH|BK>.jpg"   e.g. "Str 1234 - 5 Before AH.jpg"
    (the spec's "Str #" literally becomes "Str " + the structure number).
    Bar text:   "Str 1234 - 5 Before AH // LAT: 41.123456 // LONG: -72.123456"  (no extension,
    decimal degrees, 6 places, negative = S / W).
  * Folder layout (spec: Line folder > Structure folder). THIS SCRIPT LIVES IN THE PROJECT
    (LINE) PHOTO FOLDER ($ProjectRoot = the script's folder):
        <ProjectRoot>\Str 1234\Existing Structure Ahead Span\Str 1234 - 1 Before AH.jpg ...
        <ProjectRoot>\Str 1234\Existing Structure Back Span\...
        <ProjectRoot>\Str 1234\Replacement Structure Ahead Span\...
        <ProjectRoot>\Str 1234\Replacement Structure Back Span\...
    (v14 - before v14 these folders were "Before AH", "Before BK", "After AH", "After BK")
    Structure folders are matched with regex '^Str\s*#?\s*(\d+)$' (case-insensitive).
  * Save (v11): NO folder prompt. Photos always go to <ProjectRoot>\Str <num>\<span folder> (the
    existing Str folder, numeric match, or a new "Str <num>"). A stage whose folders already
    contain anything cannot be processed or saved again. Nothing is ever overwritten/deleted.

 PROJECT STATUS TAB (v15 layout: header, legend chips with counts, the grid, labelled check
 progress bar. No buttons/boxes. Runs automatically on start - always FULL (EXIF dates) + STRICT -
 and after every save / folder creation; F5 or right-click > Re-check re-runs it.)
  * Scans every "Str ###" folder in $ProjectRoot. Per span folder (internal keys Before AH,
    Before BK, After AH, After BK = folders "Existing/Replacement Structure Ahead/Back Span")
    it checks: folder exists, has photos, every photo is named
    "Str <num> - <n> <Stage> <Span>" for THIS structure, required shots 1,2,5,6,7,8,9 present
    (3 and 4 optional), anomaly numbers 10+ have no gaps. (If RenumberSequential is on: numbers
    must run 1..N with no gaps and N >= 7.)
  * NON-CONFORMING NAMES (v4) - every one is listed by name in the row's Issues / tooltip:
      - Strict naming (always ON since v15; Config.StrictNaming): photo names
        must be exactly "Str 1234 - 5 Before AH.jpg" (case, single spaces, .jpg); the Str folder
        exactly "Str 1234"; span folders exactly "Existing Structure Ahead Span" etc. OFF = lenient (case/spacing
        differences and other supported photo types accepted).
      - Photos named for another structure / span / not matching the pattern.
      - Unexpected folders inside a Str folder, and any sub-folder inside a span folder.
      - Loose photos directly in a Str folder (by name).
      - Other file types (videos, docs, RAW, ...) anywhere in a Str folder. OS junk
        (desktop.ini, thumbs.db, .DS_Store, ~$ temp files, hidden/system files) is ignored
        - see Config.IgnoreFileNames.
      - Project-level folders not named "Str ####" and photos loose in the project folder appear
        as PURPLE "Naming Issue" rows (sorted last, excluded from the % statistics, counted
        separately). Config.IgnoreProjectFolders lists folder names that should not be flagged.
      Any naming issue makes a structure "Needs Attention" (even if all shots are present).
  * Status rules (from the user):
      Not Started        - structure folder has no photos at all
      Partially Complete - both Existing Structure span folders valid, no Replacement photos yet
      Complete           - all four folders valid
      Needs Attention    - anything else (missing shots, misnamed files/folders, extra files,
                           half-done After, ...)
      Naming Issue       - (purple) a project-level folder/photo that is not a "Str ####" folder
  * Shows Before / After dates taken (EXIF DateTimeOriginal, else file modified date), photo
    counts per folder and issues (hover a row for the full list). The legend chips show the count
    per status. (v15 removed the statistics boxes, overall-progress bar, and all export/print.)
  * Double-click a row (or right-click > Process this structure) to load it into the Process tab
    (Existing if Not Started, Replacement if Partially Complete). Right-click also has Open
    structure folder / Open project folder / Re-check all (F5) / Stop the status check.
  * PERFORMANCE (projects can have 400-600 structures): the check runs in a BACKGROUND
    runspace ($ScanFunctionsText + $ScanWorkerText) that pushes one result per structure into a
    ConcurrentQueue; a 300 ms WinForms timer drains it and updates rows in place, so the GUI
    never freezes. Always runs on start; F5 / right-click re-runs or stops it. Only one check at
    a time (a request during a check queues one re-run). Config.DeepCheck ($true, the standard
    since v15) reads EXIF dates; with it $false only file LastWriteTime is used (this tool sets
    it to DateTaken when saving). The deep check skips
    cloud-only OneDrive/SharePoint placeholders (attributes Offline/RecallOnDataAccess) so it
    never triggers downloads.
  * Last results are cached in %LOCALAPPDATA%\ES_TLINE_PTOOL\status_<md5 of project path>.clixml
    (NOT in the project folder) and shown immediately on start while the new check runs.

 USER INSTRUCTIONS
  * Plain-language instructions live in $InstructionsText (just below this header) and are
    shown in the app's "Instructions" tab. Update them whenever behaviour changes.

 NOTE FOR AI ASSISTANTS EDITING THIS FILE
  * After every change, give the user a FULL summary of the app and all of its functions
    (not just the diff). Keep this header (request, spec, decisions, history) up to date.
  * Keep the file pure ASCII (Windows PowerShell 5.1 reads BOM-less files as ANSI).
  * Beware "$var:" inside double-quoted strings (PowerShell drive syntax) - use "${var}:".

 CUSTOMISING (logo.png / settings.txt) - added in 0.1
  * Logo: Config.LogoFile (default "logo.png") in the PROJECT folder replaces the built-in logo
    (Get-LogoPath / Get-Logo; unreadable file -> built-in). Also shown in the app header.
  * settings.txt in the project folder: "Name = value" lines, # comments (also trailing " #"),
    $SettingDefs maps each name to a CONFIG key + validation. Names: LogoFile, LogoPosition,
    LogoSize, LogoMargin, LogoOpacity, BarPosition, BarHeight, BarColor, TextColor, Font,
    FontBold, TextAlign, TextWidth, TextFormat ({NAME} {STRUCTURE} {LAT} {LONG} {DATE}),
    CoordDecimals, JpegQuality. Import-UserSettings resets to defaults then applies the file; it
    runs at start, on every Process Photos click, and when the Instructions tab opens. Invalid
    lines are ignored with a warning pop-up. Instructions tab: "Create / Open settings.txt"
    (template $SettingsTemplate, every line commented out; FileMode.CreateNew - never
    overwrites). The configured logo file in the project root is not flagged as a loose photo.

 VERSIONING / UPDATES
  * Repo: https://github.com/drewtoma/ES-TLINE-PTOOL (branch main). Config.ToolVersion is the
    version of THIS file. For every release: bump ToolVersion here, update version.txt in the
    repo to the same number, and upload the script as "ES TLINE PTOOL.ps1".
  * On start the tool reads version.txt (fallback: the ToolVersion line of the script on GitHub)
    in the background; if newer it offers:
      - "Update now" (one click + confirm; Invoke-SelfUpdate): downloads to
        %LOCALAPPDATA%\ES_TLINE_PTOOL\update\, verifies version + PowerShell syntax + size,
        backs up the current script to ...\update\backup\, copies the new script over the
        running one, unblocks it, restarts it with -ExecutionPolicy Bypass, and opens the README
        #updating page. The new version shows "updated from vX" (marker file just-updated.txt).
        THIS IS THE ONLY PLACE THE TOOL REPLACES A FILE (its own script, only on user request).
      - "Download only" (new folder in Downloads), "Open update page" (README #updating), "Later".
    Set Config.UpdateCheck = $false to turn it off.

 REVISION HISTORY
  v1  Initial tool: GUI, GPS check, naming/numbering, logo, caption bar, preview, save.
  v2  Names/bar text use "Str <num> - ..." ; structure folders are "Str <num>" ; save prompt
      defaults to the structure folder in the project folder ; new Project Status tab that
      scans all "Str ###" folders on start (Not Started / Partially Complete / Complete /
      Needs Attention) with before/after dates and % complete statistics.
  v3  Instructions tab + $InstructionsText section ; status check moved to a background
      runspace with live-updating rows, Stop button, quick/deep modes and a cached last
      result ; AutoCheckOnStart setting ; saved photos' modified date = date taken.
  0.2 Release: everything below marked "0.1 (update)" / "0.1 (fix)" - one-click Update now,
      custom logo.png + settings.txt, and the empty-folder "Scan error" fix.
  0.1 (fix) Empty structure folders showed "Scan error: You cannot call a method on a null-valued
      expression" instead of Not Started (v25 project index: "$x = if..else { @() }" gives $null).
  0.1 (update) Custom logo file + settings.txt (see CUSTOMISING).
  0.1 (update) One-click "Update now" added to the update window (see VERSIONING / UPDATES).
  0.1 FIRST VERSIONED RELEASE (= internal build v26). Version shown in the title bar and header;
      update check against GitHub (see VERSIONING / UPDATES). Internal build numbers below
      (v1-v25) are development history before versioning.
  v25 Faster status check:
      - Get-ProjectIndex lists every file and folder in the project ONCE; each structure is
        checked from that index instead of being listed again (falls back per structure if a
        folder can't be read).
      - Read-ExifDateFast reads only the first 128 KB of each JPEG and parses the EXIF header
        for the date taken (GDI+ full read only as a fallback).
      - Photo dates are remembered in %LOCALAPPDATA%\ES_TLINE_PTOOL\dates_<project>.txt keyed by
        path + size + modified time, so unchanged photos are never re-read. The file is the
        tool's own cache (rewritten after each completed check, keeps only photos seen).
      - The check panel shows "Listing all project folders..." during the walk.
  v24 GPS shown in the photo list (and now the preview caption) uses the SAME format as the photo
      caption (Format-Coord: 6 decimals). Previously the list rounded to 5 decimals, so it
      didn't quite match the coordinates printed on the photo.
  v23 Re-ordering: the list order IS the naming/processing order (photo N -> slot N). Move Up /
      Move Down work on one or several selected photos (Ctrl+Up/Down too); rows can be DRAGGED
      to a new position inside the list (custom drag format 'ES_PTOOL_ROWS', Move-PhotosTo); the
      status line says where the photo moved, e.g. "Moved IMG_0003.JPG to #4 Str 1234 - 4 Before
      AH". Once re-ordered by hand ($script:ManualOrder), adding more photos appends them at the
      end instead of re-sorting; Sort by Time asks before undoing a hand-made order.
  v22 Status check UI: while a check runs, an overlay covers the Project Status screen with a
      centred card - "Checking project folders", the folder currently being checked
      ($Sync.Current, set by the worker), progress bar, "N of M folders (x%) - m:ss elapsed",
      and a Stop button. The old bottom progress strip is gone; the grid runs to the bottom and
      the last-check result ("Last checked ... (N folders, s)") sits top-right of the header.
      Failures pop up a message. Other tabs stay usable during the check.
  v21 Process Photos page tidied: left column 310 px wide with consistent spacing ("Structure #",
      "Photo set", anomaly counts side by side); bottom strip has a separator, then the status
      text stacked over the progress bar, vertically centred on the Process Photos button;
      shooting-order box rewritten (no spec wording, tab-aligned numbered list, "Before you
      process" tips) and its bottom lines up with the list buttons.
  v20 Dates shown as "Nov 19, 2026" (ranges "Nov 3 - Nov 5, 2026", list "Nov 19, 2026 8:52:10 AM")
      in the status grid, photo list and status-check line. When Replacement (After) is chosen,
      Cross Brace / X-Bracing are ticked from the structure's saved Existing (Before) photos
      (shot #3 / #4 present?) - Get-BeforeBracing / Set-BracingFromBefore; checkbox text shows
      "- from Before"; applied once per structure, user can still change it.
  v19 Process Photos list: all columns centred (hidden 0-width first column, like the status grid).
  v18 Rotate Left / Rotate Right / Reset centred under the preview photo. List column "Rot"
      renamed "Rotation" and shows the manual rotation as Right 90 / 180 / Left 90 (blank = none).
  v17 Move Up / Move Down (Move-Photo): the moved photo stays selected+focused and the preview
      refreshes immediately with its new name/shot; Ctrl+Up / Ctrl+Down shortcuts; any list
      rebuild (remove, sort, option changes) also refreshes the preview.
  v16 Create Structure Folders: after folders are created the app switches straight to the
      Project Status tab (no success pop-up; failures still pop up).
  v15 Project Status tab cleaned up: grid is the focus and fills the tab; colour legend redesigned
      as status chips with live counts (+ hint line); REMOVED the two statistics boxes, overall
      progress bar, every bottom button/checkbox, and all export/print code (Export Issues,
      Export Table, Print). Status check is always the full (EXIF dates) + strict check.
      Actions moved to double-click / right-click menu / F5. Labelled "Status check:" progress
      bar. Issues column stretches to fill the grid (no blank column at the right).
  v14 Span FOLDERS renamed to the spec's section titles ($SpanFolderNames):
        Before AH -> "Existing Structure Ahead Span"     Before BK -> "Existing Structure Back Span"
        After AH  -> "Replacement Structure Ahead Span"  After BK  -> "Replacement Structure Back Span"
      File names are unchanged ("Str 1234 - 5 Before AH.jpg"). Internal keys stay 'Before AH' etc.
      Status check flags folders still using the old short names ("rename it to ..."); the tool
      never renames them itself. The Before/After lock also looks at the old short names.
  v13 Status page: "Export Table..." (whole table to CSV, never overwrites) and "Print..." (writes a
      NEW printable HTML report to %TEMP% - stats boxes, legend, colour-coded centred table,
      landscape - opens it in the default browser with the print dialog; print or Save as PDF).
      Process tab defaults to Existing (Before) whenever the structure # changes / form resets,
      or Replacement (After) if Before is already saved (Update-StageLock, $script:LockStr).
      Brand yellow changed to #FFEF00 everywhere (UI buttons/headers, report, and the photo
      caption text - Config.TextColor; the spec originally said #FFFF00).
  v12 Status page: FIXED the two statistics boxes (a v4 edit made them always count 0 rows);
      they are now read-only text boxes, update live during the check, and show any error
      instead of going blank. Status table text centred in every column (hidden 0-width first
      column, since WinForms can't centre column 0). Process tab: removed the duplicate
      "Rotate 90" list button - rotate only from the preview pane. After Save the review window
      closes and the Process form clears automatically (saved location shown in the status line).
  v11 SAFETY: the tool NEVER deletes, moves or overwrites files/folders. Processing happens in
      memory (no temp folders); Save writes only to <ProjectRoot>\Str <num>\<Stage> AH|BK (no
      folder picker) using FileMode.CreateNew; if "<Stage> AH"/"<Stage> BK" already contain
      anything, that stage is locked: its radio button is disabled ("- already saved"), Process
      refuses, and Save refuses (Test-StageLocked). Empty folders do not lock. Full-size view in
      the review window is an in-app viewer (Show-FullImage). Export Issues refuses to overwrite a
      CSV; Create Structure Folders skips existing folders; the error log is appended to.
      Only exception: the tool's own status cache in %LOCALAPPDATA% is replaced on each check.
  v10 Review window: photos shown in a GRID of cards (picture + name + shot + source), grouped by
      folder headers, columns adapt to window width (~430 px per card); window opens scrolled to
      the TOP; the only "Save Photos..." button is in a footer at the END of the grid (removed from
      the bottom bar, which now has Close/Done + info), so users scroll past every photo first.
  v9  Process tab left column: photo-count box auto-sizes to its content (no clipping on small
      screens / high DPI); shooting order moved into a scrollable, formatted box ($rtbHelp) that
      fills the space down to the progress bar so it never covers the status text.
  v8  Removed the "also create span folders" option from Create Structure Folders.
  v7  "Create Structure Folders" tab (left of Instructions): multi-line box, one structure number
      per line (also spaces/commas, "Str 12"/"#12", ranges "20-25" up to 2000 wide, leading zeros
      kept as typed); non-sequential numbers are fine (e.g. 8 10 12 13 15). Live preview of new /
      already-existing (numeric match, skipped) / not-understood entries; confirm before creating
      (only the empty "Str ####" folder is made - span folders are created when photos are saved); refreshes the status check afterwards. The app
      opens on this tab when the project has no Str folders.
  v6  Main window and review window open MAXIMIZED ; window icon = M.J. logo ($IconBase64,
      multi-size .ico, Quanta line removed) ; Process tab has a Photo preview pane (selected
      photo shown upright incl. manual rotation; Rotate Left / Rotate Right / Reset; preview
      thumbnails cached on the photo object, debounced on selection) ; list + preview share the
      width via Set-ProcLayout ; re-applied v1 fixes that had been lost from later builds
      (@(Get-SelectedIdx) wrapping, PropertyItem creation via RuntimeHelpers, EXIF date check,
      [double] arg for FormatConvertedBitmap).
  v5  Startup fixes: error trap (message box + %TEMP%\ES_TLINE_PTOOL_error.txt + console waits),
      status-cache file name no longer uses MD5 (crashed on FIPS-enforced corporate PCs),
      status check start wrapped in try/catch, troubleshooting steps for script-blocking policy.
  v4  Non-conforming name detection: strict naming option (default on), unexpected folders and
      sub-folders, other file types, loose photos listed by name, purple "Naming Issue" rows for
      project-level folders/photos that aren't "Str ####", "Export Issues..." CSV button.
  * Output JPEGs keep the original EXIF (GPS, date, camera) with Orientation reset to 1 because
    pixels are physically rotated. GPS tags are (re)written so every output is GPS-tagged.
  * Logo width = LogoWidthPct (7%) of the image's LONGER side, top-right, small margin.
  * Black bar height = BarHeightPct of the image's SHORTER side; it is ADDED below the photo
    (photo content is not covered). Text auto-shrinks to fit.
  * Images whose camera orientation sensor was wrong (common when shooting straight up a pole)
    can be fixed before processing: select the photo, check the Photo preview pane, and use
    Rotate Left / Rotate Right / Reset (the only rotate controls). Rotation applies to all
    selected photos.
  * HEIC (iPhone "High Efficiency") is best-effort via Windows WIC and needs the HEIF/HEVC
    extensions. Recommended: iPhone Settings > Camera > Formats > "Most Compatible" (JPEG).
  * Phones connected by USB (MTP) often can't be dragged from directly - copy photos to the PC
    first, then drop the files or the folder.
  * Processed photos are held in memory and only written to the structure folder on Save.
===============================================================================================
#>

#region ------------------------------------- USER INSTRUCTIONS --------------------------------
# Shown in the app's "Instructions" tab. Edit here to change what users see. Keep it ASCII.
$InstructionsText = @'
ES TLINE PTOOL - USER INSTRUCTIONS
==================================

WHAT IT DOES
  Renames, stamps and files structure photos to meet Eversource's photo
  documentation spec (Item 9): logo top-right, black caption bar with the
  file name and GPS, one folder per structure, Before/After and AH/BK folders.

ONE-TIME SETUP
  1. Put "ES TLINE PTOOL.ps1" in the project (line) photo folder, e.g.
        ...\Line 391\ES TLINE PTOOL.ps1
        ...\Line 391\Str 1234\Existing Structure Ahead Span\...
  2. Right-click the file > "Run with PowerShell".
     If Windows blocks it: right-click > Properties > tick "Unblock" > OK.
     (Windows only. On a Mac, run it inside a Windows virtual machine.)
  3. On the phone/camera: turn ON location (GPS) for the camera.
     iPhone: Settings > Camera > Formats > "Most Compatible" (JPEG).

IN THE FIELD - SHOOT IN THIS ORDER (one structure at a time)
  Ahead span (AH), standing ahead of the structure:
     1  100 ft away looking along the span
     2  Full structure close up
     3  Cross arm / cross brace     (skip if the structure has none)
     4  X-bracing                   (skip if the structure has none)
     5  Left insulator and attachments
     6  Middle insulator and attachments
     7  Right insulator and attachments
     8  Left static wire attachment
     9  Right static wire attachment
     10, 11, ...  One photo per anomaly (woodpecker hole, rot, broken
                  insulator...) - EXISTING structures only
  Back span (BK): repeat the same list from the back side, then BK anomalies.
  Existing structure = "Before" photos. Replacement (new) = "After" photos.
  Write down how many AH and BK anomalies you shot.

PROCESSING PHOTOS  (Process Photos tab)
  1. Copy the photos from the phone/camera to the PC (dragging straight
     from a plugged-in phone usually does not work).
  2. Enter the Structure # (numbers only, e.g. 1234 -> files "Str 1234 - ...").
  3. Existing (Before) is picked for you - or Replacement (After) if the
     Before photos are already saved. Change it if needed.
  4. Untick Cross Brace / X-Bracing if the structure doesn't have them.
     For Replacement (After) photos these are set for you from the saved
     Before photos (shows "- from Before"); change them if the new
     structure is different.
  5. Enter the number of Ahead and Back anomaly photos (Existing only).
  6. Drag the photos (or their folder) onto the yellow box / list, or click
     "Add Photos...". They are sorted by the time they were taken.
  7. Click each photo in the list - it appears in the Photo preview on the
     right with the name it will get. Check the "Will be named" and "Shot"
     columns match the picture. Double-click to open the original.
       - Wrong order?        the list order is the order photos are named
                             and processed. Select a photo (or several) and
                             click Move Up / Move Down (Ctrl+Up / Ctrl+Down),
                             or simply DRAG the row to where it belongs.
                             The status line and preview show its new name.
                             Adding more photos later keeps your order (new
                             ones go at the end); Sort by Time resets it.
       - Sideways photo?     select it > Rotate Left / Rotate Right under the
                             preview (Reset undoes it). Works on several
                             selected photos at once.
       - Extra/bad photo?    select it > Remove (or press Delete)
     The box on the left shows expected vs loaded photos and missing GPS.
  8. Click "Process Photos". Any problem (missing structure #, wrong photo
     count, photos without GPS) is listed so you can fix it.
  9. A review window opens at the top, with the photos in a grid grouped by
     folder. Scroll down through every photo and check the name, that it is
     upright, the logo, and the GPS text in the black bar. Double-click a
     photo to see it full size.
 10. At the bottom of the grid, click "Save Photos..." and confirm. Photos
     always go into this structure's folder:
        Str 1234\Existing Structure Ahead Span
        Str 1234\Existing Structure Back Span
     (or Replacement Structure Ahead Span / Back Span for After photos)
     There is no folder to pick - the "Str ####" folder is created if needed.
 11. The review window closes and the form clears automatically, ready for
     the next structure. The status line shows where the photos were saved.
  Nothing is written to the project folder until you click Save.

  SAFETY - the tool never deletes, moves or overwrites your photos or
  folders (the only file it ever replaces is its own script, and only when
  you click "Update now"):
  - Once Before (or After) photos are saved for a structure, that choice is
    greyed out ("- already saved") and can't be processed or saved again.
  - To redo a set, move the old span folders (e.g. "Existing Structure
    Ahead Span" / "Back Span") out of the structure folder yourself first
    (empty folders are fine).
  - Your original photos are only read, never changed.

CREATE STRUCTURE FOLDERS  (Create Structure Folders tab)
  - Use this at the start of a project so every structure shows on the
    Project Status tab (as Not Started) - opens automatically if the
    project has no structure folders yet.
  - Type or paste structure numbers, one per line (a column copied from
    Excel works). Numbers do not need to be in order or consecutive:
        8
        10
        12
        13
        15
    You can also type 8, 10, 12 on one line, or a range like 20-25.
  - The right side shows what will be created, which already exist
    (skipped - nothing is ever overwritten) and anything not understood.
  - Only the empty "Str ####" folders are created. The span folders
    (Existing/Replacement Structure Ahead/Back Span) are added
    automatically when you save photos.
  - Click "Create Folders" and confirm. You are taken straight back to the
    Project Status tab, where the new structures appear as Not Started.

PROJECT STATUS  (Project Status tab - opens first)
  - Lists every "Str ####" folder with its status:
       Not Started         no photos yet (grey)
       Partially Complete  Existing (Before) ahead + back done, no
                           Replacement (After) photos yet (amber)
       Complete            all four span folders done (green)
       Needs Attention     something is missing or misnamed (red) -
                           hover over the row to see exactly what.
       Naming Issue        a folder in the project folder that is not
                           named "Str ####", or photos dumped loose in the
                           project folder (purple, listed last).
  - The coloured boxes above the table show how many structures have each
    status (hover one for what it means).
  - The table shows the dates Before/After photos were taken, photo counts
    per folder and any issues.
  - A full, strict check runs every time the tool opens, after every save
    and after creating folders (or press F5). While it runs, a "Checking
    project folders" panel covers this screen showing the folder being
    checked, a progress bar and how far along it is - click Stop to end it
    early. You can keep using the Process Photos tab meanwhile. When it
    finishes, the time of the last check shows at the top right.
    It never downloads OneDrive "online-only" files.
  - Double-click a structure to start processing it: Not Started loads as
    Existing, Partially Complete as Replacement.
  - Right-click a structure for: Process this structure, Open structure
    folder, Open project folder, Re-check all structures, Stop the check.
  - NAMING CHECKS: the check lists, by name, every photo or folder that
    doesn't follow the ES format - photos named for another structure or
    span, copies like "(1)", extra folders, loose photos, videos/documents/
    other files in a structure folder. Any of these turns a structure red.
  - Names must match the ES format exactly, e.g.
        Str 1234\Existing Structure Ahead Span\Str 1234 - 5 Before AH.jpg
    (capitals, single spaces, .jpg).
  - Create empty "Str ####" folders for every structure on the line to
    track not-started structures too.

UPDATING
  - When the tool opens it checks GitHub for a newer version. If there is
    one, a window offers:
      Update now        - one click: downloads, checks and installs the new
                          version (a backup of the old one is kept), then
                          restarts the tool and opens the update page.
      Download only     - saves the new file to a new folder in Downloads.
      Open update page  - the update instructions on GitHub.
      Later             - ask again next time.
  - Updating by hand: close the tool, copy the new "ES TLINE PTOOL.ps1"
    into the project folder replacing the old one, unblock it (right-click
    > Properties > Unblock), then run it. Photos and folders are not affected.
  - Update page: https://github.com/drewtoma/ES-TLINE-PTOOL#updating

TROUBLESHOOTING
  - Window flashes and closes / red text: an error box now explains it and
    the details are saved to %TEMP%\ES_TLINE_PTOOL_error.txt. If nothing
    shows at all, Windows is blocking scripts - run it from PowerShell:
      1. Open the Start menu, type "PowerShell", open "Windows PowerShell".
      2. Type:  cd "<path of the project folder>"   and press Enter.
      3. Type:  powershell -NoProfile -ExecutionPolicy Bypass -File ".\ES TLINE PTOOL.ps1"
    If it says scripts are disabled "by Group Policy", ask IT to allow it.
    Also: right-click the file > Properties > tick "Unblock" > OK.
  - "NO GPS data": the camera's location was off. Retake, or get the
    original from the phone (some apps/messages strip GPS).
  - Photo count mismatch: check Cross Brace / X-Bracing ticks and the
    anomaly counts, or remove extra photos.
  - HEIC photos won't open: set the iPhone to "Most Compatible", or install
    the HEIF + HEVC extensions from the Microsoft Store.
  - Logo / look: see CUSTOMISING below.

CUSTOMISING (optional)
  - Logo: put "logo.png" in the project folder (next to this script) and it
    is used on photos instead of the built-in M. J. Electric logo. A PNG
    with a transparent background works best.
  - settings.txt: click "Create settings.txt" at the bottom of this tab. It
    makes a template in the project folder and opens it in Notepad. Remove
    the # at the start of a line and change its value, e.g.
        LogoSize = 9
        TextColor = #FFFFFF
    You can change: logo file, position, size, margin and opacity; bar
    position, height and colour; text colour, font, bold, alignment, width
    and format; coordinate decimals; JPEG quality.
  - Changes apply the next time you click Process Photos. Photos already
    saved are not changed. Bad lines are ignored and you are told which.
  - The defaults match the Eversource photo spec - check before changing.
'@
#endregion

#region ------------------------------------- ERROR HANDLER ------------------------------------
# Any error that would stop the tool is shown in a message box, written to
# %TEMP%\ES_TLINE_PTOOL_error.txt, and the console waits for Enter instead of closing.
trap {
    $err = $_
    $msg = "ES TLINE PTOOL stopped because of an error:`r`n`r`n$($err.Exception.Message)`r`n`r`n" +
    "Line $($err.InvocationInfo.ScriptLineNumber): $("$($err.InvocationInfo.Line)".Trim())"
    $log = Join-Path ([System.IO.Path]::GetTempPath()) 'ES_TLINE_PTOOL_error.txt'
    try { Add-Content -LiteralPath $log -Value ((Get-Date).ToString('yyyy-MM-dd HH:mm:ss') + '  ' + $msg + "`r`n`r`nPowerShell $($PSVersionTable.PSVersion)`r`n" + ($err | Out-String)) } catch {}
    Write-Host ''
    Write-Host $msg -ForegroundColor Red
    Write-Host "`r`nDetails saved to: $log" -ForegroundColor Yellow
    try {
        Add-Type -AssemblyName System.Windows.Forms
        [void][System.Windows.Forms.MessageBox]::Show("$msg`r`n`r`nDetails saved to:`r`n$log", 'ES TLINE PTOOL - error', 'OK', 'Error')
    } catch {}
    try { [void](Read-Host "`r`nPress Enter to close") } catch {}
    break
}
#endregion

#region ------------------------------------- CONFIG -------------------------------------------
$Config = [ordered]@{
    ToolName                    = 'ES TLINE PTOOL'
    # ---- Version / updates (bump ToolVersion AND version.txt in the repo for every release) ----
    ToolVersion                 = '0.2'
    UpdateCheck                 = $true    # check GitHub for a newer version when the tool opens
    RepoUrl                     = 'https://github.com/drewtoma/ES-TLINE-PTOOL'
    UpdateHelpUrl               = 'https://github.com/drewtoma/ES-TLINE-PTOOL#updating'
    VersionUrl                  = 'https://raw.githubusercontent.com/drewtoma/ES-TLINE-PTOOL/main/version.txt'
    ScriptUrl                   = 'https://raw.githubusercontent.com/drewtoma/ES-TLINE-PTOOL/main/ES%20TLINE%20PTOOL.ps1'
    RenumberSequential          = $false   # $false = spec slot numbers (skip 3/4 if absent)
    AllowAnomaliesOnReplacement = $false
    LogoWidthPct                = 0.07     # of the image's longer side
    LogoMarginPct               = 0.015    # of the image's shorter side
    BarHeightPct                = 0.05     # of the image's shorter side
    BarMinPx                    = 40
    TextMaxWidthPct             = 0.96     # text may use this much of the bar width
    FontName                    = 'Segoe UI'
    TextColor                   = '#FFEF00'   # caption text on photos (spec originally #FFFF00)
    BarColor                    = '#000000'
    JpegQuality                 = 92
    # ---- more photo-stamp settings (all can be changed per project in settings.txt) ----
    LogoFile                    = 'logo.png'  # in the project folder; built-in logo if missing
    LogoPosition                = 'TopRight'  # TopRight | TopLeft | BottomRight | BottomLeft | None
    LogoOpacity                 = 100         # 0-100
    BarPosition                 = 'Bottom'    # Bottom | Top (the bar is ADDED - never covers the photo)
    FontBold                    = $true
    TextAlign                   = 'Center'    # Center | Left | Right
    TextFormat                  = '{NAME} // LAT: {LAT} // LONG: {LONG}'
    CoordDecimals               = 6
    PreviewWidth                = 1000     # px width of preview thumbnails
    HeicApplyExifOrientation    = $false   # WIC may already orient HEIC; use Rotate Left/Right if needed
    DeepCheck                   = $true    # status check reads photo dates from EXIF (full check)
    StrictNaming                = $true    # status check is always strict: exact "Str 1234 - 5 Before AH.jpg" (case, spaces, .jpg)
    IgnoreProjectFolders        = @()      # project-level folder names NOT to flag, e.g. @('Reports', 'Admin')
    IgnoreFileNames             = @('desktop.ini', 'thumbs.db', '.ds_store', 'ehthumbs.db')  # never reported (lower case)
    Extensions                  = @('.jpg', '.jpeg', '.png', '.tif', '.tiff', '.heic', '.heif')
}

# Spec slot definitions (number -> description). 3 = Cross Arm, 4 = X-Bracing (optional).
$SpecSlots = @(
    [pscustomobject]@{ N = 1; Desc = "100' away (looking along span)" }
    [pscustomobject]@{ N = 2; Desc = 'Full structure close up' }
    [pscustomobject]@{ N = 3; Desc = 'Cross Arm / Cross Brace' }
    [pscustomobject]@{ N = 4; Desc = 'X-Bracing' }
    [pscustomobject]@{ N = 5; Desc = 'Left insulator and attachments' }
    [pscustomobject]@{ N = 6; Desc = 'Middle insulator and attachments' }
    [pscustomobject]@{ N = 7; Desc = 'Right insulator and attachments' }
    [pscustomobject]@{ N = 8; Desc = 'Left static wire attachment' }
    [pscustomobject]@{ N = 9; Desc = 'Right static wire attachment' }
)

# M. J. Electric logo (transparent PNG, Quanta line removed). A "logo.png" placed next to this
# script overrides it.
# Window icon: same logo, square, multi-size .ico (16-64 px).
$IconBase64 = @'
AAABAAcAEBAAAAAAIAAoBAAAdgAAABQUAAAAACAAaAYAAJ4EAAAYGAAAAAAgACgJAAAGCwAAICAAAAAAIAAoEAAALhQAACgoAAAAACAAKBkAAFYkAAAwMAAA
AAAgACgkAAB+PQAAQEAAAAAAIAAoQAAApmEAACgAAAAQAAAAIAAAAAEAIAAAAAAAAAQAAMQOAADEDgAAAAAAAAAAAAAAAAAAB0dHIAZQVyYGSVAmBldXJgZD
SSYGV10mBlddJgZXXSYGUFcmBlBQJgZDSSYGSVAmBldXJgc/RyAAAAAAA5ymmQHGzPMByNP2AcnU9wHCzfgBzdn4AcDL+AG+yfgBwMv4AcbR+AHF0PgBztv4
AcrV9wHH0vYBxczzA5mhmQHDzv8AmqP/AMzY/wDt/P8A1uP/AN/t/wC3wf8A1uP/AL/K/wDCzv8A3On/AMrX/wCxvP8Apq//ANHd/wHQ3f8Bytb9ALW9/gCu
uf4A3+z+ALnE/gC1wP4AxM/+ALbB/gCvuv4A1+T+AKiy/gCfqP4AmKH+AKex/gCyuv4Bytf9AbzI/wAZGv8AAAD/AJ+o/wAOD/8ADQ7/AJmj/wAAAP8AJyr/
ANbk/wAFBf8ABgf/AGZs/wAAAP8ADAz/Aay2/wG2wf8AExT/AAEB/wCgqf8AFBX/ABIT/wCWn/8AAQH/ACgr/wDT4P8ABgb/AAwN/wCkrf8AAAD/AAcI/wGl
r/8Bt8L/ABQV/wAAAP8AoKn/ABMU/wAREv8Al6D/AAAA/wAoK/8A1OH/AAkJ/wAND/8AmKH/AAAA/wAICf8BprD/AbfC/wAUFf8AAAD/AKCp/wATFP8AERL/
AJeg/wAAAP8AKCv/ANPg/wAAAP8AAAH/AJmh/wAAAP8ACAn/Aaaw/wG3wv8AFBX/AAAA/wCgqf8AExT/ABES/wCXoP8AAAD/ACcq/wDZ5v8ANjn/ADw+/wCh
qv8AAAD/AAgJ/wGmsP8Bt8L/ABQV/wAAAP8An6j/ABMU/wAREv8Al6D/AAAA/wAiJP8A7v3/APT//wD///8AvMj/AAAA/wAKC/8BprD/AbfC/wAUFf8AAAD/
AJ+o/wATFP8AERL/AJeg/wAAAP8AIiT/AO38/wDu/f8A+v7/ALvH/wAAAP8ACgv/Aaaw/wG3wv8AFBX/AAAA/wCdpv8AExT/ABES/wCVnv8AAAD/ACIk/wDt
/P8A7/7/APv//wC7x/8AAAD/AAoL/wGmsP8BtsH9ABQV/gABAf8AqLL/ABUW/wATFP8AoKr/AAEB/wAjJf8A7Pv/AO79/wD6/v8Ausb/AAEB/wAKC/4Bpa/9
AcHM/wAVFv8AAAD/AHB3/wAICP8ABgf/AGtx/wAAAP8AHR//APP//wD1//8A////AL/L/wAAAP8ACgv/AbC7/wOirKABp6z3AZaf+gGQmPsBlp77AZae+wGR
mfsBlp/7AZ+p+wHZ5vsB2uf7Ad3n+wHM1/sBlp/6AaOo9wOdp6AAAAAABoKJJwWiqCwFqK0sBZ6kLQWepC0FpKotBZmkLQWNmS0FSUktBUlJLQVESS0FXFws
BaKoLAaJjycAAAAAKAAAABQAAAAoAAAAAQAgAAAAAABABgAAxA4AAMQOAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAA
AAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAgAAAAAAAAAAA1NXQAK3v8ACxs7UArrF1AK5xNUCusbVAr3H1QK7xtUCucTVArjD1QK6xdUCu8bV
ArnE1QK6xdUCvsnVAsHN1QLAzNQCxMzUAqyyvwRZXT8CsbzuAMnS/wCtt/8A6vj/AOTy/wDAzP8A+f//AMPO/wDQ3f8Ay9f/AMHM/wDb6P8Azdn/AOf1/wDc
6f8AzNj/AMLO/wDAy/8A4uv/Aq+67gLE0P8Aoav8AJef/QDs+v0A6/r9AMjU/QD5//0AqLH9AMTQ/QDh7v0Atb/9AMLN/QDDzv0A1+T9ALXA/QCps/0Ao6z9
AKqz/QDb5fwCx9L/AsrW/gDR2v8AqrT/ALS//wDj8f8Asr3/ALO9/wDDzv8Aw8//ALG8/wCkrv8A4vD/AL7J/wChq/8AoKn/AJih/wCqtP8Aq7T/AL3F/wLL
1/4C0d3/AEJG/wAAAP8ACgr/AL/L/wAMDf8AAAD/AHmB/wBxef8AAAD/AAAA/wDd6/8AbXP/AAAA/wABAf8AZWv/AAkJ/wAAAP8ALjH/AsXR/wLN2f8AOz7/
AAIC/wATFP8Awc3/ABYX/wACAv8AeoL/AHN7/wACAv8AAgL/ANzq/wBvdf8AAQH/AAkJ/wDF0f8AHR7/AAIC/wAnKf8CwMv/As7a/wA9Qf8AAAD/ABES/wDB
zP8AFBb/AAAA/wB6gv8Ac3v/AAAA/wABAf8A3Or/AG91/wAAAP8ACAj/ALS//wAaG/8AAAD/ACgr/wLBzP8Cztr/ADxA/wAAAP8AERL/AMHM/wAUFv8AAAD/
AHqC/wBze/8AAAD/AAEB/wDc6v8AcHb/AAEB/wAJCf8At8L/ABob/wAAAP8AKCr/AsHM/wLO2v8APED/AAAA/wAREv8Awcz/ABQW/wAAAP8AeoL/AHN7/wAA
AP8AAQH/ANzq/wBtc/8AAAD/AAQE/wC2wf8AGhv/AAAA/wAoKv8Cwcz/As7a/wA8QP8AAAD/ABES/wDBzP8AFBb/AAAA/wB6gv8Ac3v/AAAA/wABAf8A2+n/
AHd9/wAODv8AFhf/ALnE/wAZGv8AAAD/ACgq/wLBzP8Cztr/ADw//wAAAP8AERH/AMDL/wAVFv8AAAD/AHqC/wBze/8AAAD/AAUF/wDN2f8A7fT/ANro/wDi
7P8A2+n/ABIT/wAAAP8AKCr/AsHM/wLO2v8APD//AAAA/wAREf8AwMv/ABUW/wAAAP8AeoL/AHN7/wAAAP8ABQX/AMzY/wD7//8A8v//APn//wDf7f8AERL/
AAAA/wAoKv8Cwcz/As7a/wA8P/8AAAD/ABER/wDAy/8AFRb/AAAA/wB6gv8Ac3v/AAAA/wAFBf8AzNj/APf+/wDs+/8A8/7/AN7s/wAREv8AAAD/ACgq/wLB
zP8Cztr/ADw//wAAAP8AERH/AMDL/wAVFv8AAAD/AHqC/wBze/8AAAD/AAUF/wDM2P8A+P//AO38/wD0//8A3uz/ABES/wAAAP8AKCr/AsHM/wLN2f4APkH/
AAIC/wATE/8Awc3/ABcY/wACAv8AfIT/AHV9/wACAv8ABwf/AMzY/wD4//8A7fz/APT//wDe7P8AExT/AAIC/wAqLP8CwMv+AtHe/wAuMf0AAAD9AAQE/QC4
w/0ACQn9AAAA/QBwd/0AaXD9AAAA/QAAAP0AyNT9APb9/QDr+v0A8v39ANvp/QAFBf0AAAD9ABob/QLEz/8Cv8vxAIWL/wA4O/8APkL/AGBm/wA9Qf8AOTz/
AFJX/wBRVv8AOTz/ADs+/wDh7/8A////AP3//wD///8A8P//AEdL/wA4O/8AdHj/ArjD8QNdYEcCv8bIAsfP2wLBzdwCucPcAsLN3ALDztwCvMjcAr7I3ALD
ztwCws7cAsHM3ALAzNwCwMzcAsDM3ALBzNwCws3cAsfP2wK/xsgDYGRHAAAAAAAAAAAAAAAHAAAABgAAAAYAAAAGAAAABgAAAAYAAAAGAAAABgAAAAYAAAAG
AAAABgAAAAYAAAAGAAAABgAAAAYAAAAHAAAAAAAAAAAoAAAAGAAAADAAAAABACAAAAAAAAAJAADEDgAAxA4AAAAAAAAAAAAAAAICAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgIAAAAABgRxeHADo6ai
A56lowOWnqQDm6SkA6CppAOVnaQDmaOkA52mpAOdpqQDnqakA56mpAObo6QDm6OkA6CnpAOWoKQDmaGkA5igpAOZo6QDmqSjA6OmogR2fXAAAAAGA4GJpwHk
7/8A5/L/AOLw/wD6//8A5fP/ANjk/wD+//8A7v3/ANvo/wDi7/8A3On/AN3r/wDk8v8A6vj/ANfl/wD4//8A8P7/APX//wDs+/8A7vz/AN/q/wHW4f8Dho6n
AsXQ/wCtuPwAcnf7AJig+wDx9vsA2OX7AJmh+wD3+PsApa/7ALzH+wCttvsAztv7AJOb+wDN2fsArLb7ANvg+wDJ1vsAucX7AJuk+wCVnfsAjJT7AK65+wDn
6/wCu8b/AsfS/gCvuP8Avcj/ALO9/wD///8A6/r/AMrW/wD///8AxtL/ALnD/wDN2P8A+P//ALS//wDP2v8AvMf/ANTe/wDK1v8AuMP/ALrF/wC2wP8AusX/
AMLN/wDY3v8Cv8r+AsLN/wDo8P8AqrX/AKew/wC1wP8A6ff/AKq1/wCnsf8AqbP/ANzp/wCxvP8AqLL/AKOt/wDR3v8A6vj/AJym/wChqv8An6j/AJOc/wCh
qv8Arrj/AJ+p/wDZ4f8CxdD/AtHd/wB6gf8AAAD/AAAA/wAkJv8A2OX/AAAA/wAAAP8AAAD/ANDd/wAbHf8AAAD/AAAA/wCirP8A4O7/AAAA/wAAAP8AAAD/
AFpf/wASE/8AAAD/AAAA/wBbYf8Cztr/AtHd/wBvdf8AAwP/AAMD/wAwMv8A2eb/AA0O/wADA/8ACwz/AM/c/wAnKv8AAwP/AAID/wClr/8A4O7/AAME/wAC
A/8AAgL/ANrn/wBCRv8AAgP/AAID/wBQVf8CzNj/AtHd/wByeP8AAAD/AAAA/wAtL/8A2OX/AAoL/wAAAP8ACQn/AM/c/wAlKP8AAAD/AAAA/wCkrv8A4O7/
AAEB/wAAAP8AAAD/AMbS/wA6Pv8AAAD/AAAA/wBTWP8CzNj/AtHd/wBxd/8AAAD/AAAA/wAtL/8A2OX/AAoL/wAAAP8ACQn/AM/c/wAlKP8AAAD/AAAA/wCk
rv8A4O7/AAEB/wAAAP8AAAD/AMnV/wA7P/8AAAD/AAAA/wBSV/8CzNj/AtHd/wBxd/8AAAD/AAAA/wAtL/8A2OX/AAoL/wAAAP8ACQn/AM/c/wAlKP8AAAD/
AAAA/wCkrv8A4O7/AAEB/wAAAP8AAAD/AMnV/wA7P/8AAAD/AAAA/wBSV/8CzNj/AtHd/wBxd/8AAAD/AAAA/wAtL/8A2OX/AAoL/wAAAP8ACQn/AM/c/wAl
KP8AAAD/AAAA/wCkrv8A4O7/AAID/wABAv8AAgL/AMnV/wA7P/8AAAD/AAAA/wBSV/8CzNj/AtHd/wBxd/8AAAD/AAAA/wAtL/8A2OX/AAoL/wAAAP8ACQn/
AM/c/wAlKP8AAAD/AAAA/wCkrv8A3+7/AAAA/wAAAP8AAAD/AMjU/wA7P/8AAAD/AAAA/wBSV/8CzNj/AtHd/wBxd/8AAAD/AAAA/wAsL/8A2OX/AAsL/wAA
AP8ACQn/AM/c/wAlKP8AAAD/AAAA/wCfqP8A+Pv/ALfB/wC5xP8AuMP/AOz1/wA0N/8AAAD/AAAA/wBSV/8CzNj/AtHd/wBxd/8AAAD/AAAA/wAsL/8A2OX/
AAsL/wAAAP8ACQn/AM/c/wAlKP8AAAD/AAAA/wCdpv8A////APn//wD8//8A+///APj//wAyM/8AAAD/AAAA/wBSV/8CzNj/AtHd/wBxd/8AAAD/AAAA/wAs
L/8A2OX/AAsL/wAAAP8ACQn/AM/c/wAlKP8AAAD/AAAA/wCdpv8A////AOr4/wDt/P8A7Pv/APb//wAyNP8AAAD/AAAA/wBSV/8CzNj/AtHd/wBxd/8AAAD/
AAAA/wAsL/8A2OX/AAsL/wAAAP8ACQn/AM/c/wAlKP8AAAD/AAAA/wCdpv8A////AO37/wDw//8A7/7/APb//wAyNP8AAAD/AAAA/wBSV/8CzNj/AtHd/wBx
d/8AAAD/AAAA/wAsL/8A2OX/AAsL/wAAAP8ACQn/AM/c/wAlKP8AAAD/AAAA/wCdpv8A////AO37/wDw//8A7/7/APb//wAyNP8AAAD/AAAA/wBSV/8CzNj/
AtHd/wBxd/8AAAD/AAAA/wArLv8A1eH/AAsL/wAAAP8ACQn/AMzZ/wAkJ/8AAAD/AAAA/wCdpv8A////AO37/wDw//8A7/7/APb//wAyNP8AAAD/AAAA/wBS
V/8CzNj/AtHd/gBwdv8ABAT/AAME/wAyNf8A6ff/ABAQ/wAEBP8ADQ7/AOHv/wArL/8ABAT/AAQE/wCep/8A////AO37/wDw//8A7/7/APb//wA1N/8ABAT/
AAQE/wBRVv8Cy9f+AtLe/wB0e/sAAAD8AAAA/AAGB/wAc3n8AAAA/AAAAPwAAAD8AG50/AADA/wAAAD8AAAA/ACUnfwA//38AOv5/ADu/fwA7fz8APT9/AAh
IvwAAAD8AAAA/ABUWfsCztr/Ao2UrwHg6v8Aoqj/AJ+o/wCcpf8AkJn/AJ6n/wCeqP8Anqf/AJGZ/wCcpf8AoKn/AJ6n/wDg7f8A////AP///wD///8A////
AP///wCzvv8Anqf/AKCn/wHU3v8CjpevAAAACgR9g3wCuL2uArK9rgK0vq8Ct8OvArO9rwKzva8Cs72vArfBrwK0vq8Cs72vArO9rwKjra8CmqSvApukrwKb
pK8Cm6SvApqkrwKuua8CtL6uAri9rgSCiHsAAAAKAAICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAgIAKAAAACAAAABAAAAAAQAgAAAAAAAAEAAAxA4AAMQOAAAAAAAAAAAAAAAAAAEA//8CAAICAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAICAAD//wIAAAABAAICAAAAAAAGAAAlBAAANwQAADcEAAA4BAQAOAQAADgEAAA4BAAAOAQEADgEAAA4BAAAOAQAADgEAAA4BAAAOAQA
ADgEAAA4BAAAOAQAADgEAAA4BAAAOAQAADgEAAA4BAAAOAQAADgEAAA4BAAANwQAADcGAAAlAAAAAAABAgAAAAAPBG1zqgPEyP0C0t3/AtHd/wLR3v8Cy9f/
AtTg/wLU4f8C0Nz/AsrX/wLS3v8C09//AtDc/wLV4f8C0t7/AtPf/wLT3/8Cztr/AtHe/wLV4v8Cztr/AtDc/wLO2v8C0Nz/As3Z/wLT3/8Cz9v/AtLc/wPH
zP0Eb3WqAAAADgRla6QB6Pb/ANrk/gDU4v4A0+D+ANLf/gD9//4Avsn+AMHM/gDb6P4A///+ANLf/gDAzP4A2uf+ALzH/gDI0v4AzNj+AMDL/gDl8v4A1eH+
ALG8/gDu+/4A3+3+AOr5/gDf7f4A8P/+AMvX/gDl8v4A0t/+ALjA/gHo8/8EZWmkA6u1+gDf7fwAfoX+AH6E/wCSmv8A3er/AO/9/wDY5f8AjJP/AN3q/wD6
/f8AlZ3/ALfB/wDY5f8AkZj/AO/v/wCLkv8Avsn/ANPf/wCgqf8A19//AOLp/wCqtf8Aztr/AJ6o/wCMlP8ArLb/AI+X/wCqtP8A09z+AObu/AOosvoDtL7/
ANbk/wBma/8AsLr/AGdt/wD4//8A7fz/APT//wCTnP8A6/r/APj7/wCSmv8AsLr/ANvo/wCYoP8A////AIeO/wC2wf8A1+T/AKKr/wDh6P8A4Of/AJ+o/wDG
0v8Ak5z/AJmi/wCRmf8Ai5P/AKmz/wDf6P8A5e7/A6+6/wOvuf8A5u//ALnE/wD5//8AuMP/AP///wD3//8A7/7/ANfj/wD+//8A////ANXi/wC5w/8A2ub/
ANzp/wD///8A0Nz/AMXQ/wDg7v8Ax9P/ALjE/wDi8P8AucP/AMjU/wDO2/8Ay9f/ANnm/wDl8/8A1uL/ALC6/wDq8P8Drrj/A6iy/wD///8Awcz/AJKb/wCe
qP8AkJn/AMXR/wDs+/8AmKH/AJGZ/wCQmf8Al6D/AO/9/wDCzv8Alp//AJKc/wCXoP8AqrT/APf//wDn9f8AmaL/AJWe/wCZov8Al6D/AIqT/wCNlf8AmKH/
AJaf/wCWn/8AsLn/AP///wOps/8DsLr/AOTw/wAAAP8AAAD/AAAA/wAAAP8AfYT/AOb0/wAAAP8AAAD/AAAA/wAAAP8A3uv/AGtx/wAAAP8AAAD/AAAA/wAl
J/8A////AMbS/wAAAP8AAAD/AAAA/wAAAP8AMzX/ACIj/wAAAP8AAAD/AAAA/wAAAP8AxdH/A7fB/wO0vv8A2Ob/AAAA/wAEBP8ACQn/AAQE/wCFjf8A5/X/
AAcI/wAEBP8ABAT/AAQE/wDh7v8Adn3/AAQE/wAKC/8ABAT/ADY5/wD///8Ay9f/AAUF/wAEBP8ABgb/AAQE/wDa5/8Apq//AAQE/wAICP8ABwf/AAIC/wC0
v/8DusX/A7O9/wDa5/8AAQH/AAAA/wAFBf8AAAD/AIKJ/wDn9f8AAwT/AAAA/wAAAP8AAAD/AOHu/wB0e/8AAAD/AAYH/wAAAP8AMzb/AP///wDK1v8AAQH/
AAAA/wACAv8AAAD/AMfT/wCXn/8AAAD/AAQE/wADA/8AAAD/ALjD/wO5xP8Ds73/ANrn/wAAAP8AAAD/AAUF/wAAAP8Agon/AOf1/wADBP8AAAD/AAAA/wAA
AP8A4e7/AHR7/wAAAP8ABgf/AAAA/wAzNv8A////AMrW/wABAf8AAAD/AAIC/wAAAP8Aytb/AJmh/wAAAP8ABAT/AAMD/wAAAP8At8L/A7nE/wOzvf8A2uf/
AAAA/wAAAP8ABQX/AAAA/wCCif8A5/X/AAME/wAAAP8AAAD/AAAA/wDh7v8AdHv/AAAA/wAGB/8AAAD/ADM2/wD///8Aytb/AAEB/wAAAP8AAgL/AAAA/wDK
1v8AmaH/AAAA/wAEBP8AAwP/AAAA/wC3wv8DucT/A7O9/wDa5/8AAAD/AAAA/wAFBf8AAAD/AIKJ/wDn9f8AAwT/AAAA/wAAAP8AAAD/AOHu/wB0e/8AAAD/
AAYH/wAAAP8AMzb/AP///wDK1v8AAQH/AAAA/wACAv8AAAD/AMrW/wCZof8AAAD/AAQE/wADA/8AAAD/ALfC/wO5xP8Ds73/ANrn/wAAAP8AAAD/AAUF/wAA
AP8Agon/AOf1/wADBP8AAAD/AAAA/wAAAP8A4e7/AHR7/wAAAP8ABgf/AAAA/wAzNv8A////AMrW/wABAf8AAAD/AAIC/wAAAP8Aytb/AJmh/wAAAP8ABAT/
AAMD/wAAAP8At8L/A7nE/wOzvf8A2uf/AAAA/wAAAP8ABQX/AAAA/wCCif8A5/X/AAME/wAAAP8AAAD/AAAA/wDh7v8AdHv/AAAA/wAGB/8AAAD/ADM2/wD/
//8Ay9f/AAUF/wAEBP8ABgb/AAQE/wDL1/8AmaH/AAAA/wAEBP8AAwP/AAAA/wC3wv8DucT/A7O9/wDa5/8AAAD/AAAA/wAFBf8AAAD/AIKJ/wDn9f8AAwT/
AAAA/wAAAP8AAAD/AOHu/wB0e/8AAAD/AAYH/wAAAP8AMzb/AP///wDI0/8AAAD/AAAA/wAAAP8AAAD/AMbT/wCaov8AAAD/AAQE/wADA/8AAAD/ALfC/wO5
xP8Ds73/ANrn/wAAAP8AAAD/AAUF/wAAAP8AgYn/AOf1/wADBP8AAAD/AAAA/wAAAP8A4e7/AHR7/wAAAP8ABgf/AAAA/wA0N/8A/P//ANjl/wBbYP8AW1//
AFxh/wBZXf8A3ub/AJSd/wAAAP8ABAT/AAMD/wAAAP8At8L/A7nE/wOzvf8A2uf/AAAA/wAAAP8ABQX/AAAA/wCAiP8A5/X/AAME/wAAAP8AAAD/AAAA/wDh
7v8AdHv/AAAA/wAGB/8AAAD/ADU4/wD2//8A8f//AP///wD///8A////APv//wD///8AjJT/AAAA/wAEBP8AAwP/AAAA/wC3wv8DucT/A7O9/wDa5/8AAAD/
AAAA/wAFBf8AAAD/AICI/wDn9f8AAwT/AAAA/wAAAP8AAAD/AOHu/wB0e/8AAAD/AAYH/wAAAP8ANTj/APf//wDu/f8A7Pv/AOz7/wDt+/8A6ff/AP7+/wCN
lf8AAAD/AAQE/wADA/8AAAD/ALfC/wO5xP8Ds73/ANrn/wAAAP8AAAD/AAUF/wAAAP8AgIj/AOf1/wADBP8AAAD/AAAA/wAAAP8A4e7/AHR7/wAAAP8ABgf/
AAAA/wA1OP8A9///AO/+/wDw//8A8P//APD//wDs+/8A////AI2V/wAAAP8ABAT/AAMD/wAAAP8At8L/A7nE/wOzvf8A2uf/AAAA/wAAAP8ABQX/AAAA/wCA
iP8A5/X/AAME/wAAAP8AAAD/AAAA/wDh7v8AdHv/AAAA/wAGB/8AAAD/ADU4/wD3//8A7/7/APD//wDw//8A8P//AOz7/wD///8AjZX/AAAA/wAEBP8AAwP/
AAAA/wC3wv8DucT/A7O9/wDa5/8AAAD/AAAA/wAFBf8AAAD/AICI/wDn9f8AAwT/AAAA/wAAAP8AAAD/AOHu/wB0e/8AAAD/AAYH/wAAAP8ANTj/APf//wDv
/v8A8P//APD//wDw//8A7Pv/AP///wCNlf8AAAD/AAQE/wADA/8AAAD/ALfC/wO5xP8Ds73/ANrn/wAAAP8AAAD/AAUF/wAAAP8AgIj/AOf1/wADBP8AAAD/
AAAA/wAAAP8A4e7/AHR7/wAAAP8ABgf/AAAA/wA1OP8A9///AO/+/wDw//8A8P//APD//wDs+/8A////AI2V/wAAAP8ABAT/AAMD/wAAAP8At8L/A7nE/wOz
vf8A2uf/AAAA/wAAAP8ABQX/AAAA/wCAiP8A5/X/AAME/wAAAP8AAAD/AAAA/wDh7v8AdHv/AAAA/wAGB/8AAAD/ADU4/wD3//8A7/7/APD//wDw//8A8P//
AOz7/wD///8AjZX/AAAA/wAEBP8AAwP/AAAA/wC3wv8DucT/A7K8/wDa5/8AAAD/AAAA/wAFBf8AAAD/AH2E/wDj8f8AAwT/AAAA/wAAAP8AAAD/AN3q/wBy
ef8AAAD/AAYH/wAAAP8ANTj/APf//wDv/v8A8P//APD//wDw//8A7Pv/AP///wCNlf8AAAD/AAQE/wADA/8AAAD/ALfC/wO4w/8DtL7/ANjl/wACAv8ABAT/
AAkJ/wAEBP8AjJT/APz//wAHCP8ABAT/AAQE/wAEBP8A9f//AICI/wAEBP8ACgv/AAQE/wA4O/8A9///AO/+/wDw//8A8P//APD//wDs+/8A////AI+X/wAE
BP8ACAj/AAcH/wADBP8AtcD/A7rF/wOstvwA4+/8AAAA/gAAAP8AAAD/AAAA/wAtL/8AYWf/AAAA/wAAAP8AAAD/AAAA/wBeY/8AKCr/AAAA/wAAAP8AAAD/
ACYo/wD2/f8A7fz/AO/9/wDv/f8A7/3/AOr5/wD//f8AhIz/AAAA/wAAAP8AAAD/AAAA/gDBzPwDs738BGNprgH8//8Apa38AHF3/QB0evwAc3n8AGlv/ABi
Z/wAcnn8AHN5/ABzefwAc3n8AGJo/ABqcPwAc3n8AHR6/AByefwAkJj8APz//AD4//wA+P/8APj//AD4//wA9v/8AP///ADCzfwAcnn8AHZ9/ABwd/0Akpf8
Afb//wRmbK4AAAAVBHN7uALY3f8C6PT/Auf1/wLo9v8C6vj/Auz6/wLo9v8C6Pb/Auj2/wLo9v8C7Pn/Aur4/wLo9v8C6PX/Auj2/wLk8v8C1uP/Atfj/wLX
4/8C1+P/Atfj/wLX5P8C1uP/At7r/wLo9v8C5/X/Auj0/wLa3/8Edn23AAAAFQABAQAAAAAABQAAMgcSDkUHDgtFBw4ORgcODkYHDg5GBw4ORgcODkYHDg5G
Bw4ORgcODkYHDg5GBw4ORgcODkYHDg5GBxISRgcdHUYHHR1GBx0dRgcdHUYHHR1GBx0dRgcdHUYHFRVGBw4ORgcODkUHEg5FBQAAMgAAAAAAAQEAAAAAAQD/
/wEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP//AQAAAAEoAAAAKAAAAFAAAAABACAAAAAAAAAZAADEDgAAxA4AAAAAAAAAAAAAAAAAAAAAAAEAPz8EAP//AwD/
/wIA//8CAP//AgD//wIA//8CAP//AgD//wIA//8CAP//AgD//wIA//8CAP//AgD//wIA//8CAP//AgD//wIA//8CAP//AgD//wIA//8CAP//AgD//wIA//8C
AP//AgD//wIA//8CAP//AgD//wIA//8CAP//AgD//wIA//8CAP//AwA/PwQAAAABAAAAAAAAAAEAAgIAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAICAAAAAAEAAgIAAAAACQQjJXMEZmi1BWxxvwVrcMAFa3DABWxywAVscsAFa2/ABWtwwAVrcMAFbHLABW5zwAVr
cMAFa3DABWtwwAVrcMAFam/ABWtwwAVrcMAFa2/ABWtwwAVscsAFa3DABWtwwAVrcMAFbnPABWtwwAVuc8AFa3DABWxywAVrcMAFa3DABWtwwAVtcb8EZmi1
BCMlcwAAAAkAAgIAAAAAEwVgZccD6e7/Af///wH///8B////Af///wH///8B////Af///wH///8B////Af///wH+//8B////Af///wH///8B////Af///wH/
//8B////Af///wH///8B////Af///wH///8B////Af3//wH///8B/v//Af///wH///8B////Af///wH///8B////Af///wPs8f8FYGXGAAAAEwQ8QJ8C7/j/
ANDZ+QDH0/wAwMv8AMjU/ACstvwA5fP8AOz3/ACTm/wArLb8ALnD/ADk8vwA9v/8ALC7/ACfqPwAt8D8AMPO/ACXoPwAtL38ALvG/ACbpPwAqLH8AOn3/AC0
vvwAlqD8AMjT/AD1/fwAtsH8APH//AC8yPwA7fv8AMLN/AC6xfwA1+T8AMnV/ACWn/wAxMv5Au/4/wQ8QJ8DhIz0AP///QCMlf4Ah47/AHmA/wCOlf8Aytb/
APH8/wDq+P8A3ub/AH6F/wDN2v8A7vv/APr//wB/h/8Aw83/APHy/wCYof8Ar7j/APX0/wCNlf8Arrf/AO3t/wC7xv8AmaL/AOPp/wCxu/8A9v3/AHqA/wDy
/f8AjJX/AKqz/wCPl/8AuML/AJGZ/wCUnP8A5+z/AKiy/gD7//0Dh4/0BJWd/wD+/v8Ag4r/AIyU/wCps/8AanD/AO78/wDz//8A7/7/AP3//wCLk/8A5PP/
APL//wD6//8Ag4v/AKKr/wD4/f8Ao6z/AL/K/wD///8AlZ3/AJGZ/wDw8/8Aq7X/ALbA/wD///8A7vz/APr//wCLk/8A/v//AI6X/wCWnv8AlZ3/AK64/wCH
jv8Aoqz/AP///wDv/v8A+/7/BJef/wSSmf8A////AGJo/wCao/8A1eL/AD5B/wDp+P8A7fv/AO38/wD2/v8Aho7/ANzp/wDu+/8A9fv/AIGI/wCvuP8A2Nn/
AJyl/wC5w/8A+/v/AJGZ/wCbo/8Azs7/ANTg/wCOlv8ArbX/AJ6m/wDN0f8AY2j/AMbO/wCFjf8AtL7/AJae/wCQmP8ArLb/AJae/wCxt/8Aj5f/APn//wSV
nf8ElZz/AP3//wDZ5/8A+P//AP///wDn9f8A////AP///wDy//8A8///APP//wD///8A////AP///wDu/P8AyNT/ANbk/wD3//8A+v//AP///wD0//8A2eX/
AM/c/wD0//8A3+3/ANDd/wD///8A4u//ANzo/wDh7v8A8f//ANjk/wDz//8A/v//APv//wD7//8Aztv/AOb0/wD+//8ElJz/BJSc/wD9//8A6fb/AIyU/wB5
gP8AgIj/AHmA/wB6gf8A5PL/AOXz/wB+hf8AeYD/AHmA/wB4gP8AfYX/AOz6/wDi8P8Ae4L/AHuC/wB4gP8AfYT/AIKJ/wDZ5v8A9v7/AN7s/wCEi/8AeoH/
AICI/wCCif8AgIj/AHZ9/wB4gP8AfIP/AHqB/wB7gv8Ae4L/AIuT/wDV4v8A/f//BJSc/wSRmf8A////AG50/wAAAP8AAAD/AAAA/wAAAP8AAAD/ANXi/wDY
5f8AAAD/AAAA/wAAAP8AAAD/AAAA/wDT3v8Aw9D/AAAA/wAAAP8AAAD/AAAA/wAAAP8Aq7b/AP///wC/yf8AAAD/AAAA/wAAAP8AAAD/AAAA/wAQEP8AGhv/
AAAA/wAAAP8AAAD/AAAA/wAAAP8AOjz/AP///wSTm/8Ekpn/AP///wBSV/8ABAT/AAgI/wAFBf8ABAT/AAYG/wDY5f8A2uf/AAgI/wAEBP8ABQX/AAQE/wAE
BP8A1uL/AMjV/wAEBP8ABQX/AAQE/wAGBv8ABAT/ALK9/wD///8AxM//AAQE/wAEBP8ABQX/AAYH/wAEBP8AucP/APP//wAPD/8ABAT/AAUF/wAGBv8ABAT/
ACMl/wD+//8ElZ3/BJKZ/wD///8AV1z/AAAA/wAEBP8AAQH/AAAA/wABAf8A1uP/ANro/wAEBP8AAAD/AAEB/wAAAP8AAAD/ANbi/wDH1P8AAAD/AAEB/wAA
AP8AAgL/AAAA/wCxvP8A////AMPO/wAAAP8AAAD/AAEB/wACA/8AAAD/ALK8/wDq+f8ACwv/AAAA/wABAf8AAgL/AAAA/wAnKf8A/v//BJWd/wSSmf8A////
AFZb/wAAAP8ABAT/AAEB/wAAAP8AAQH/ANXi/wDa6P8ABAT/AAAA/wABAf8AAAD/AAAA/wDW4v8Ax9T/AAAA/wABAf8AAAD/AAIC/wAAAP8Asbz/AP///wDD
zv8AAAD/AAAA/wABAf8AAgP/AAAA/wCyvP8A6/n/AAsL/wAAAP8AAQH/AAIC/wAAAP8AJij/AP7//wSVnf8Ekpn/AP///wBWW/8AAAD/AAQE/wABAf8AAAD/
AAEB/wDV4v8A2uj/AAQE/wAAAP8AAQH/AAAA/wAAAP8A1uL/AMfU/wAAAP8AAQH/AAAA/wACAv8AAAD/ALG8/wD///8Aw87/AAAA/wAAAP8AAQH/AAID/wAA
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
/P8A8P//APD//wDw//8A8P//AO/+/wD1//8A3er/AA4P/wAAAP8AAQH/AAIC/wAAAP8AJij/AP7//wSVnf8EkZj/AP///wBXXP8AAAD/AAQE/wABAf8AAAD/
AAAA/wDP3P8A2OX/AAME/wAAAP8AAQH/AAAA/wAAAP8A09//AMTR/wAAAP8AAQH/AAAA/wACAv8AAAD/ALS+/wD9//8A7fz/APD//wDw//8A8P//APD//wDv
/v8A9f//AN3q/wAOD/8AAAD/AAEB/wACAv8AAAD/ACcp/wD+//8ElJz/BJOa/wD+/v8AVVn/AAME/wAHB/8ABAT/AAMD/wADA/8A4/H/AO37/wAGCP8AAwP/
AAQE/wADA/8AAwP/AOf0/wDX5f8AAwP/AAQE/wADA/8ABQX/AAMD/wC1v/8A/f//AO38/wDw//8A8P//APD//wDw//8A7/7/APX//wDd6v8AERL/AAMD/wAE
BP8ABQX/AAME/wAmKP8A/f7/BJef/wOFjPYA///9AFxi/wAAAP8AAAD/AAAA/wAAAP8AAAD/AEFF/wBESP8AAAD/AAAA/wAAAP8AAAD/AAAA/wBDRv8APUD/
AAAA/wAAAP8AAAD/AAAA/wAAAP8AsLr/AP7//wDt/P8A8P//APD//wDw//8A8P//AO/+/wD1//8A3On/AAAB/wAAAP8AAAD/AAAA/wAAAP8AKCr/AP///QOI
kPYEQ0aqAvT8/wDe5vkAVlv9AEhM/QBIS/0AR0v9AEdL/QA5PP0AODv9AEdL/QBHS/0AR0v9AEdL/QBHS/0AOTz9ADo9/QBHS/0AR0v9AEdL/QBJTP0AR0r9
AMTP/QD2/P0A6/r9AO38/QDt/P0A7fz9AO38/QDt+/0A8fz9AODu/QBRVf0AR0v9AEhM/QBJTP0ATFH9AMLJ+QL2/f8EQkWqAAAAGgRqcdUC9Pn/Af///wD/
//8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wD///8A////
AP///wD///8A////AP///wD///8A////AP///wD///8A////AP///wL4/f8EanHVAAAAGgACAgAAAAASBTQ6hwNzdMcEeH7RBHd90QR4ftIEeH7SBHh+0gR4
ftIEeH7SBHh+0gR4ftIEeH7SBHh+0gR4ftIEeH7SBHh+0gR4ftIEeH7SBHh+0gR4ftIEeoDSBHuB0gR6gdIEeoHSBHqB0gR6gdIEeoHSBHqB0gR7gdIEeoDS
BHh+0gR4ftIEd33RBHl/0ANzdccFNDiHAAAAEgACAgAAAAABAAICAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAACAgAAAAABAAAAAAAAAAEAf38EAP//AQAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAE
BAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAP//AQB/fwQAAAABAAAAACgAAAAwAAAA
YAAAAAEAIAAAAAAAACQAAMQOAADEDgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAA
AAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAE
AAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAIAAAAAAAAAAAAAAAAAAAAAAAAAAQD//wIABAQAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAAB
AQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEA
AAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAABAQAAAQEAAAEBAAAEBAAA//8CAAAAAQAAAAAAAAABAAICAAAAAAAAAAAnAwAATAYAAFAGAABRBgAAUQYA
AFEGAABRBgAAUQYAAFEGAABRBgAAUQYAAFEGAABRBgAAUQYAAFEGAABRBgAAUQYAAFEGAABRBgAAUQYAAFEGAABRBgAAUQYAAFEGAABRBgAAUQYAAFEGAABR
BgAAUQYAAFEGAABRBgAAUQYAAFEGAABRBgAAUQYAAFEGAABRBgAAUQYAAFEGAABQAwAATAAAACcAAAAAAAICAAAAAAEAAgIAAAAAGwU4PLAEk5b7BLvC/wS9
x/8Evcf/BLzH/wS9x/8Evsn/BL3I/wS9x/8EvMf/BL3H/wS9yP8Evsn/BL7J/wS8xv8Evcf/BL3H/wS+yP8EvMb/BL3H/wS9yP8Evcf/BLzH/wS9yP8Evsj/
BL7I/wS8xv8Evsj/BLzG/wS+yf8Evsj/BLzH/wS+yf8Evcf/BL3I/wS9yP8Evcf/BL3H/wS9yP8Evcf/A7zD/wSSlfoFODywAAAAGgACAgAAAAAUBFFU1gP0
+f8A///+AP///AD///wA///8AP///AD///wA/P/8AP///AD///wA///8AP///AD///wA/P/8AP3//AD///wA///8AP///AD///wA///8AP///AD///wA///8
AP///AD///wA///8AP///AD///wA///8AP///AD8//wA///8AP///AD8//wA///8AP///AD///wA///8AP///AD///wA///8AP///AD///4D9vv/BE9U1gAA
ABQFICGXA+Pt/wDe5vkAtsL/ALfC/wC9yP8Avsn/AKCq/wC4w/8A9vz/ANTf/wB4fv8AmqL/ALC6/wC/yv8A9vz/APL8/wCTm/8AjJP/AJGZ/wDS3v8AjpX/
AI+X/wCkrP8AvMf/AH6F/wCSmP8Ar7f/AO32/wCWnv8AjJL/AKSu/wD1/P8A1+T/AKWv/wD3/P8Arrn/ANHe/wDf7f8ApK7/ALS//wDW4/8Axs//AImR/wCG
jf8A5+z5A9/p/wUgIZcEZmzsAP///QC1wf4Ajpb/AHd9/wCCif8AiZD/ALbB/wDo7/8A8v7/AODu/wDp6/8AdXv/ALnF/wDr8v8A8f3/APX//wBrcf8A4O3/
APH5/wDk8f8AaW7/AOXy/wD49/8AmKH/AJ2l/wD8/f8A9vj/AJyk/wCao/8A9/n/AI6W/wDt9/8Azdr/AHJ4/wD///8AgIj/AMTQ/wCQmP8Au8b/AJGZ/wCt
tv8Ad37/AO/0/wC5xP8AqrX+AP///QRlbOwEf4X/AP7+/wDE0P8Ab3X/AKCp/wCcpP8AcHX/ANPg/wD8//8A7v7/APD//wD///8AhIz/AM3b/wD8//8A7fz/
APj//wBrcf8AkZn/AM7Y/wDu+v8Adnz/APD//wD///8Apa7/AGpw/wCwtP8A/f//AH2D/wDT3/8A+v//AP///wD5//8Azdv/AH2E/wD+//8AjZb/AHV6/wBc
YP8A0tv/AJ2l/wCSmv8AkZn/AP///wD6//8A+v//APz+/wSBh/8FfoT/AP///wDI1f8ALjH/AM3Z/wC6xf8AMDL/ANbj/wD2/v8A7/7/AOz7/wD+/v8AeoH/
AMbT/wD5//8A7v3/APb//wBrcP8A0d7/AO/4/wDo9f8AbHH/AO78/wD///8AmqP/AJOb/wDw8v8A/f//AJOc/wClrv8A////AKCo/wDv+f8Aztv/AHR6/wD/
//8Ag4v/ALjD/wDe6/8AcHf/AI+W/wCpsv8AeH//APr//wDI0/8AtcD/AP7//wV9g/8FfoT/AP///wDS3v8AW2D/AOv5/wDe7P8AVlv/ANzp/wDx+/8A7fv/
AO79/wD6/v8AnKX/ANDd/wDz+/8A6vn/APP7/wCGjf8AlZz/AJ6k/wDX5P8Alp7/AOr4/wD3+/8AtcD/AHuB/wCcn/8Awcn/AOry/wCLkv8Ai5D/AJyl/wDO
2P8Ah43/AGpv/wCprv8Aoqv/AISK/wCNlP8AxM3/AKav/wDR3f8At8D/AIaO/wCBiP8Az9j/AP7//wV+hf8FgIb/AP3//wDt/f8A////AP///wD///8A////
AP///wD///8A/P//AO///wDy//8A////AP///wD///8A////AP///wD///8A7/7/AOv6/wD9//8A////AP///wD///8A////AP///wD2//8A7Pz/APP//wD5
//8A9///AP///wD///8A////AP///wD8//8A////AP///wD///8A////AP///wD///8A////APr//wD///8A9P//AP3//wWAhv8FgIb/APz//wD1//8AuMP/
AGds/wBiZ/8AX2X/AGNo/wBhZv8AipH/APn//wDb6P8AYmf/AGFm/wBiZ/8AYWf/AGFn/wBgZf8A2OT/APn//wB8g/8AYGX/AGJo/wBhZ/8AYmj/AGFm/wCP
l/8A9///APT+/wDS3v8AY2n/AGBl/wBiZ/8AYmf/AGBm/wBiaP8AXWL/AF1i/wBfZf8AX2X/AGBm/wBhZv8AYGb/AGRp/wCZov8A8v3/APz//wWAhv8Ff4X/
AP7//wDa5f8ADAz/AAAA/wAAAP8AAAD/AAAA/wAAAP8AODr/AP///wDL1v8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8Aw87/AP///wAfIv8AAAD/AAAA/wAA
AP8AAAD/AAAA/wA/Q/8A/P//APn//wC9xv8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAIC/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AqrP/
AP///wV9g/8FfYT/AP///wC/y/8AAAD/AAQE/wAEBP8ABAT/AAcH/wAEBP8AR0r/AP///wDO2v8ABwf/AAQE/wAFBf8ABAT/AAQE/wAEBP8Ax9L/AP7//wAw
M/8ABAT/AAYG/wAEBP8ABwf/AAQE/wBOUv8A+///APj//wDBy/8ABAT/AAUF/wAEBP8ABAT/AAcH/wAEBP8AmJ//APLz/wBWW/8ABAT/AAcI/wAEBP8ABAT/
AAgI/wACAv8AhIv/AP///wV8gv8FfYT/AP///wDDzv8AAQH/AAAA/wAAAP8AAAD/AAMD/wAAAP8AQ0f/AP///wDN2f8AAwP/AAAA/wABAf8AAAD/AAAA/wAA
AP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APj//wDAyv8AAAD/AAEB/wAAAP8AAAD/AAMD/wAAAP8Aoan/AP///wBZX/8AAAD/
AAQE/wAAAP8AAAD/AAQE/wAAAP8AiZD/AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AQUT/AP///wDN2f8AAwP/AAAA/wAB
Af8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APj//wDAyv8AAAD/AAEB/wAAAP8AAAD/AAMD/wAAAP8AnaX/
AP7+/wBYXf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AQUT/AP///wDN
2f8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APj//wDAyv8AAAD/AAEB/wAAAP8AAAD/
AAMD/wAAAP8Anqb/AP///wBYXf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAA
AP8AQUT/AP///wDN2f8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APj//wDAyv8AAAD/
AAEB/wAAAP8AAAD/AAMD/wAAAP8Anqb/AP///wBYXf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAA
AP8AAAD/AAMD/wAAAP8AQUT/AP///wDN2f8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///
APj//wDAyv8AAAD/AAEB/wAAAP8AAAD/AAMD/wAAAP8Anqb/AP///wBYXf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDC
zf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AQUT/AP///wDN2f8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/
AAAA/wBLT/8A+///APj//wDAyv8AAAD/AAEB/wAAAP8AAAD/AAMD/wAAAP8Anqb/AP///wBYXf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8
gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AQUT/AP///wDN2f8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/
AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APj//wDAyv8AAAD/AAEB/wAAAP8AAAD/AAMD/wAAAP8Anqb/AP///wBYXf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAA
AP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AQUT/AP///wDN2f8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/
AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APj//wDAyv8AAAD/AAEB/wAAAP8AAAD/AAMD/wAAAP8Anqb/AP///wBYXf8AAAD/AAQE/wAA
AP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AQUT/AP///wDN2f8AAwP/AAAA/wABAf8AAAD/
AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APj//wDAyv8AAAD/AAEB/wAAAP8AAAD/AAMD/wAAAP8Anqb/AP///wBY
Xf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AQUT/AP///wDN2f8AAwP/
AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APj//wDAyv8AAAD/AAEB/wAAAP8AAAD/AAMD/wAA
AP8Anqb/AP///wBYXf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AQUT/
AP///wDN2f8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APj//wDBy/8ABAT/AAUF/wAE
BP8ABAT/AAcH/wAEBP8An6f/AP///wBYXf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/
AAMD/wAAAP8AQUT/AP///wDN2f8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A+///APn//wC9
xv8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AmKD/AP///wBYXf8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/
AAAA/wAAAP8AAAD/AAMD/wAAAP8AQEP/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBL
T/8A/P//APL9/wDb6P8Ah47/AIiP/wCHj/8Ah4//AImQ/wCHjv8Aytb/AP///wBaX/8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/
AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AP0L/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAA
AP8AAwP/AAAA/wBLT/8A/f//AOz8/wDz//8A////AP///wD///8A////AP///wD///8A8v//AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//
AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AP0L/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAt
MP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDv/v8A7Pv/AOz7/wDs+/8A7Pv/AOz7/wDs+/8A6/r/AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/
AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AP0L/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAA
AP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7Pv/AP///wBbYP8AAAD/
AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AP0L/AP///wDN2v8AAwP/AAAA/wAB
Af8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7Pv/
AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AP0L/AP///wDN
2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDw//8A8P//APD//wDw//8A8P//
APD//wDw//8A7Pv/AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAA
AP8AP0L/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDw//8A8P//
APD//wDw//8A8P//APD//wDw//8A7Pv/AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAA
AP8AAAD/AAMD/wAAAP8AP0L/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//
AO38/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7Pv/AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDC
zf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AP0L/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/
AAAA/wBLT/8A/f//AO38/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7Pv/AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8
gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AP0L/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/
AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7Pv/AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAA
AP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AP0L/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/
AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7Pv/AP///wBbYP8AAAD/AAQE/wAA
AP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8AP0L/AP///wDN2v8AAwP/AAAA/wABAf8AAAD/
AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7Pv/AP///wBb
YP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8APUD/AP///wDN2v8AAwP/
AAAA/wABAf8AAAD/AAAA/wAAAP8AxtH/AP7//wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDw//8A8P//APD//wDw//8A8P//APD//wDw
//8A7Pv/AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiI//AP///wV8gv8FfYT/AP///wDCzf8AAAD/AAAA/wAAAP8AAAD/AAMD/wAAAP8APD//
AP39/wDL2P8AAwP/AAAA/wABAf8AAAD/AAAA/wAAAP8AxM//APz9/wAtMP8AAAD/AAIC/wAAAP8AAwP/AAAA/wBLT/8A/f//AO38/wDw//8A8P//APD//wDw
//8A8P//APD//wDw//8A7Pv/AP///wBbYP8AAAD/AAQE/wAAAP8AAAD/AAQE/wAAAP8AiZD/AP///wV8gv8EfoX/AP7+/wDAy/8AAQH/AAID/wACAv8AAgL/
AAUF/wACAv8AQkX/AP///wDY5f8ABQb/AAIC/wADA/8AAgL/AAIC/wACAv8A0dz/AP///wAxNP8AAgL/AAQE/wACAv8ABQX/AAIC/wBNUf8A/f//AO38/wDw
//8A8P//APD//wDw//8A8P//APD//wDw//8A7Pv/AP///wBcYf8AAgL/AAYG/wACAv8AAgL/AAYH/wADA/8Ahoz/AP7+/wR9g/8Ea3DwAP///gDO2/4AAAD/
AAAA/wAAAP8AAAD/AAAA/wAAAP8ABgb/ADg5/wAsLv8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AKiz/ADg5/wACAv8AAAD/AAAA/wAAAP8AAAD/AAAA/wBE
SP8A/v//AO38/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7Pv/AP///wBVWf8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AlqD+AP///gRpbvAEKiuj
A+Pv/wD///oAho7/ADAy/wAuMP8ALC7/ACwu/wAsLv8AKSr/AB4g/wAhIv8ALC7/ACwu/wAsLv8ALC7/ACwu/wAsLv8AISP/AB8g/wAqK/8ALC7/ACwu/wAs
Lv8ALjD/ACwt/wBpbv8A+f3/AOz7/wDu/f8A7v3/AO79/wDu/f8A7v3/AO79/wDu/f8A6/r/APr9/wB2fP8ALC3/AC8x/wAsLv8ALS//ACwu/wBdYv8A9Pr6
A+bw/wQoKqMAAAAdBF5j4wL6//8A///8AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD/
//sA///7AP//+wD///sA///7AP//+wD9//sA+v/7APr/+wD6//sA+v/7APr/+wD6//sA+v/7APr/+wD6//sA+v/7APr/+wD9//sA///7AP//+wD///sA///7
AP//+wD///wC/f//BF1i4wAAAB0AAgIAAAAAKAVLUMUEpqn/A87W/wTQ2/8Dz9v/A9Db/wPQ2/8D0Nv/A9Db/wPQ2/8D0Nv/A9Db/wPQ2/8D0Nv/A9Db/wPQ
2/8D0Nv/A9Db/wPQ2/8D0Nv/A9Db/wPQ2/8D0Nv/A9Dc/wPQ3P8D0Nz/A9Dc/wPQ3P8D0Nz/A9Dc/wPQ3P8D0Nz/A9Dc/wPQ3P8D0Nz/A9Dc/wPQ3P8D0Nz/
A9Db/wPP2/8E0Nv/A87X/wSmqf8FSk/EAAAAKAACAgAAAAACAAICAAAAAAAEAAA7BQUFYwQJCWgECQdoBAkHaQQJB2kECQdpBAkHaQQJB2kECQdpBAkHaQQJ
B2kECQdpBAkHaQQJB2kECQdpBAkHaQQJB2kECQdpBAkHaQQJB2kECQdpBAkHaQQJB2kECQlpBAkJaQQJCWkECQlpBAkJaQQJCWkECQlpBAkJaQQJCWkECQlp
BAkJaQQJCWkECQdpBAkHaQQJB2gECQloBQUFYwQAADsAAAAAAAICAAAAAAIAAAAAAAAAAgACAwAAAwMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAwAAAgMAAAAAAgAAAAAAAAAAAAAAAAAAAAEAAAADAD8/BAA/PwQAPz8EAD8/BAA/
PwQAPz8EAD8/BAA/PwQAPz8EAD8/BAA/PwQAPz8EAD8/BAA/PwQAPz8EAD8/BAA/PwQAPz8EAD8/BAA/PwQAPz8EAD8/BAA/PwQAPz8EAD8/BAA/PwQAPz8E
AD8/BAA/PwQAPz8EAD8/BAA/PwQAPz8EAD8/BAA/PwQAPz8EAD8/BAA/PwQAPz8EAD8/BAAAAAMAAAABAAAAAAAAAAAoAAAAQAAAAIAAAAABACAAAAAAAABA
AADEDgAAxA4AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAA
AAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAE
AAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAAAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAIAf38CAAQEAAADAwAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIA
AAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAAC
AgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAICAAACAgAAAgIAAAMDAAAEBAAAf38CAAAAAgAAAAAAAAAAAAAAAAAAAAIAAgIAAAAAAAAAACcCAABZ
BAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQA
AGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagQAAGoEAABq
BAAAagQAAGoEAABqBAAAagQAAGoEAABqBAAAagIAAFkAAAAnAAAAAAACAgAAAAACAAAAAAAAAAIAAgIAAAAAJgQRFLAGZmn6BaKn/wWwuf8FsLn/BbG6/wWx
uv8Fsbr/BbG6/wWxuv8Fsbr/BbG6/wWwuf8FsLn/BbG6/wWxuv8Fsbr/BbG6/wWxuv8Fsbr/BbG5/wWwuf8FsLn/BbC5/wWxuv8Fsbr/BbC5/wWwuf8Fsbn/
BbG6/wWwuf8FsLn/BbC5/wWxuf8Fsbr/BbG6/wWxuv8FsLn/BbG6/wWxuv8Fsbr/BbG6/wWxuv8Fsbr/BbG6/wWxuv8Fsbr/BbG6/wWxuv8Fsbr/BbG6/wWx
uv8Fsbr/BbC5/wWwuf8Foab/BmZo+gQRFK8AAAAmAAICAAAAAAIAAgIAAAAANAY9QOwF1tv/Af///wD///wA///7AP//+wD///sA///7AP//+wD///sA///7
AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD/
//sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7
AP///AH///8F1dr/BT1A7AAAADQAAgIAAA4OEgUuMd8E7PT/AP//+gDt/f8A7Pv/APb//wDu/f8A7/7/AO/+/wDu/f8A7v3/AO38/wDt/P8A9f//ANzp/wDu
/f8A8///AO78/wDu/P8A7fz/AO38/wDu/f8A7v3/AOTy/wDk8v8A5PP/AOz7/wDw//8A5fP/AOTy/wDl8/8A7v3/AO38/wDj8v8A5PL/AOX0/wDr+/8A9f//
APD//wDW4/8A8v//APX//wDs/P8A7fz/APD//wDu/f8A7fz/AO/9/wDw//8A7fz/APD//wDw//8A7Pr/APH//wDr+/8A9f//AO/+/wDV4/8A8f//AP//+gTs
8/8FLjHfAA4OEgMAAIQFrbb/AP//+wC/zP8AfYT/AP3//wBWWv8A5PL/AKKs/wCkrf8AdXz/AMLO/wD3//8A+f//AJOa/wBhZv8AWl//ANXf/wBkaf8A2uf/
APX//wDx//8A6ff/AFdc/wB1ev8Ad33/AHuB/wDp9f8AanD/AG90/wB4fv8AipD/ANTf/wBQVP8AeH3/AHV7/wCEiv8A8/v/ANLb/wBmav8AgoT/AGJn/wDS
2/8A9P7/APj//wB2ff8Aztr/APz//wC1wf8AhY3/APn8/wDT4P8Aam//AOTx/wBuc/8A9///AM3W/wBlav8AgoT/AGNo/wDR3P8A///7Ba22/wMAAIQELS7c
Aur4/gD///0AtcD/AGJo/wDe6f8AFhb/ALbA/wCSmv8Agor/AOXm/wDj8v8A8v//APL//wDQ3P8A/v//AHh//wCGj/8A4+X/AOj2/wDw/v8A9P//AN/t/wBK
Tv8A+P//APv//wDx//8A9P//AEtO/wDY5P8A9///APr//wDH0v8AUlT/AP///wD3//8A8P7/APf9/wBTWP8AusX/AP///wCkrf8Ae4L/APz//wD5//8AUVb/
AMTP/wD///8Aoq3/AGpx/wD///8AcXj/AIqS/wDv/P8ARUf/APT7/wBQVf8AwMz/AP///wCdpv8AgYj/AP3//QLp9/4ELS7cBVFV+wH2//8A+///ALfC/wBz
ef8AmKH/AI6V/wCJkP8AkJf/AIiP/wD///8A7v3/APD//wDw//8A9P//AP///wCPl/8Aho//AP///wDt/P8A7/7/APT//wDi8P8ASU3/AMbR/wDN2P8A7fz/
APX//wBTVv8A1+T/APX//wD3//8AzNf/AEpN/wDQ1f8Azdn/APf//wDT4P8AU1b/APv//wDt/P8A9f//AO78/wDu/f8A+///AFlf/wDG0f8A////AKu2/wBS
V/8Ar7P/ACos/wDz/f8A4e//AFhd/wDL2P8AVlr/AP7//wDs+/8A9f//AO38/wDv/f8B+P//BVFU+wZWWv8B+P//APr//wC6xf8AYmj/AHB1/wDn8v8AfYP/
AGtw/wCRmf8A/v7/AOz7/wDw//8A8P//AOz6/wD///8Ai5P/AIeQ/wD+/v8A7Pv/AO/+/wDz//8A5fP/ADs+/wCEjP8AkZn/AOf1/wD1//8AUlX/ANfk/wD1
//8A9///AM/b/wA2OP8Ai4//AJef/wD2/f8Az9z/AFVZ/wD6//8A6vr/APX//wD4//8A6/v/APj8/wBYXf8AxM//AP39/wCtuP8ARUn/AKKj/wB5gP8Ad3z/
AODt/wBZXf8Ax9T/AFld/wD9//8A6vr/APX//wD3//8A7f3/Afr//wZWWv8GVVn/Afj//wD5//8AxND/ACos/wB8gv8A////AKGq/wAnKP8AmKH/AP///wDs
+/8A8P//APD//wDt+/8A////AImR/wCEjf8A////AOz7/wDv/v8A9P//AN7s/wBRVf8A////AP///wD6//8A9P//AE9R/wDW4/8A9f//APj//wDH0f8AWV3/
AP///wD///8A+P//APH6/wBMUP8A0N3/AP///wC8x/8AipL/AP///wD///8AWV7/AM/a/wD///8Ao63/AHV9/wD///8A9///AD1B/wDM1/8AUVX/AO32/wBK
Tv8A1+P/AP///wC2wf8Aj5f/APv//wH3//8GVVn/BlVZ/wH4//8A9v//AM/b/wAYGf8AuML/APz+/wDc6P8AGxv/AJ6n/wD9//8A7Pv/APD//wDw//8A7fv/
AP7//wCUnP8Aj5j/AP7//wDs+/8A7/7/APL//wDm9P8AR0r/AICG/wCCiP8Alp//APT//wBgZP8A2eb/APT//wD2//8A09//AEBD/wCHif8AgIb/AKCp/wD+
//8AvMT/AF5i/wCSk/8AV1v/AMbL/wC8v/8Ahor/AEFE/wBwdf8An6H/ALO+/wBFSP8AiIn/AGht/wCbov8A5/X/AFld/wD5//8At7//AF9j/wCSk/8AWFz/
AMbO/wD2/v8B+P//BlVZ/wZVWf8B+v//AO79/wDu/f8A4u//AO79/wDv/v8A8f//AOTy/wDq+P8A8P7/AO/+/wDv/v8A8P//APD//wDx//8A6vj/AOr4/wDw
/v8A7/7/AO/+/wDv/v8A7/7/AOHu/wDT3/8A09//ANjk/wDv/v8A5/X/AO38/wDv/v8A7/7/AO79/wDe6/8A0d7/ANLe/wDc6P8A7///APr//wDk8f8AwMz/
AOXz/wD6//8A3ev/ANHd/wDe6v8A1eH/ANbk/wDt+/8A2+j/ANHe/wDi8P8A+///AO38/wDn9f8A7f3/APn//wDh7v8Av8v/AObz/wD6//8A7Pz/Afr//wZV
Wf8GVVn/Afr//wDu/f8A7///APz//wD8//8A9v//APb//wD6//8A+P//APb//wD3//8A9v//APD//wDw//8A8f//APj//wD4//8A9///APf//wD3//8A9///
APf//wD6//8A+f//APf//wD3//8A9///APn//wD3//8A9///APf//wD3//8A+///AP7//wD7//8A9f//APD//wDt/f8A9f//AP///wD5//8A9f//APv//wD+
//8A+///AP3//wD9//8A9///APz//wD+//8A+v//APT//wD3//8A+f//APf//wD0//8A+v//AP///wD///8A7f3/AO79/wH6//8GVVn/BlVZ/wH6//8A7Pv/
APn//wDCy/8ATFD/ADY5/wA2OP8ANDf/ADU3/wA2OP8ANTf/AEhL/wDn9P8A+f//ANHd/wA1N/8ANTf/ADU4/wA1OP8ANTj/ADU4/wA2OP8ANDb/AMXR/wD7
/v8A1OH/ADg7/wA0N/8ANjj/ADU4/wA1OP8ANTj/ADc6/wA0Nv8AgYn/APv+/wDr+f8A+v//AMDL/wAzNv8ANjn/ADU4/wA0N/8ANDf/ADQ3/wA0N/8ANDf/
ADY5/wA3Ov8ANzr/ADU4/wA1OP8ANTj/ADQ3/wA1OP8ANTj/ADU4/wA7Pv8Aj5b/APj//wDt/P8B+v//BlVZ/wZVWf8B+f//APH9/wDj7f8AFhf/AAAA/wAA
AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAODv8A4/D/AP3//wDG0v8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wC3wv8A////AMvY/wAAAP8AAAD/
AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AFxi/wD///8A6fj/AP7//wCwuv8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAA
AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wClrf8A+///Aff//wZVWf8GVVn/Aff//wD5//8AusX/AAAA/wAEBP8AAgL/AAMD/wADA/8AAwP/
AAQE/wADA/8AGhv/AOTx/wD8//8AyNT/AAMD/wADA/8AAwP/AAMD/wADA/8AAwP/AAQE/wADA/8Au8b/AP///wDN2v8ABgf/AAMD/wAEBP8AAwP/AAMD/wAD
A/8ABgf/AAMD/wBka/8A////AOn4/wD9//8AtL7/AAMD/wAFBf8AAwP/AAMD/wADA/8AAwP/AAUF/wADA/8AXmL/AK2v/wCkrf8AIiT/AAMD/wAEBP8AAwP/
AAMD/wADA/8AAgP/AAcH/wACAv8AZmz/AP///wH2//8GVVn/BlVZ/wH3//8A+f//ALvF/wABAf8AAQH/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ABgZ/wDk
8f8A/P//AMjU/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ALrF/wD///8Azdr/AAQE/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAQE/wAAAP8AY2n/
AP///wDp+P8A/f//ALO9/wAAAP8AAgL/AAAA/wAAAP8AAAD/AAAA/wAEBP8AAAD/AJCX/wD///8A////ADI0/wAAAP8AAgL/AAAA/wAAAP8AAAD/AAAA/wAE
BP8AAAD/AGpw/wD///8B9v//BlVZ/wZVWf8B9///APn//wC7xf8AAAD/AAEB/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wAXGP8A4/D/APz//wDI1P8AAAD/
AAAA/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wC6xf8A////AM3a/wAEBP8AAAD/AAEB/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGNp/wD///8A6fj/AP3//wCz
vf8AAAD/AAIC/wAAAP8AAAD/AAAA/wAAAP8ABAT/AAAA/wCGjP8A+/v/AO36/wAuMP8AAAD/AAIC/wAAAP8AAAD/AAAA/wAAAP8ABAT/AAAA/wBpb/8A////
Afb//wZVWf8GVVn/Aff//wD5//8Au8X/AAAA/wABAf8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AFRb/AOLu/wD8//8AyNT/AAAA/wAAAP8AAAD/AAAA/wAA
AP8AAAD/AAEB/wAAAP8AusX/AP///wDN2v8ABAT/AAAA/wABAf8AAAD/AAAA/wAAAP8ABAT/AAAA/wBjaf8A////AOn4/wD9//8As73/AAAA/wACAv8AAAD/
AAAA/wAAAP8AAAD/AAQE/wAAAP8AiI7/AP///wDw/v8ALzH/AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/AAQE/wAAAP8AaW//AP///wH2//8GVVn/BlVZ/wH3
//8A+f//ALvF/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ABUW/wDi7v8A/P//AMjU/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/
ALrF/wD///8Azdr/AAQE/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAQE/wAAAP8AY2n/AP///wDp+P8A/f//ALO9/wAAAP8AAgL/AAAA/wAAAP8AAAD/AAAA/wAE
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
AP8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AusX/AP///wDN2v8ABAT/AAAA/wABAf8AAAD/AAAA/wAAAP8ABAT/AAAA/wBjaf8A////AOn4/wD9//8As73/
AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/AAQE/wAAAP8AiI7/AP///wDw/v8ALzH/AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/AAQE/wAAAP8AaW//AP///wH2
//8GVVn/BlVZ/wH3//8A+f//ALvF/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ABUW/wDi7v8A/P//AMjU/wAAAP8AAAD/AAAA/wAAAP8AAAD/
AAAA/wABAf8AAAD/ALrF/wD///8Azdr/AAQE/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAQE/wAAAP8AY2n/AP///wDp+P8A/f//ALS+/wACAv8ABAT/AAIC/wAC
Av8AAgL/AAIC/wAGBv8AAgL/AImP/wD///8A8P7/AC8x/wAAAP8AAgL/AAAA/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGlv/wD///8B9v//BlVZ/wZVWf8B9///
APn//wC7xf8AAAD/AAEB/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wAVFv8A4u7/APz//wDI1P8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wC6
xf8A////AM3a/wAEBP8AAAD/AAEB/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGNp/wD///8A6fj/AP3//wCxuv8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/
AAAA/wCEif8A////APD+/wAvMf8AAAD/AAIC/wAAAP8AAAD/AAAA/wAAAP8ABAT/AAAA/wBpb/8A////Afb//wZVWf8GVVn/Aff//wD5//8Au8X/AAAA/wAB
Af8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AExT/AODs/wD9//8AyNT/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AusX/AP///wDN2v8ABAT/
AAAA/wABAf8AAAD/AAAA/wAAAP8ABAT/AAAA/wBjaf8A////AOv6/wDz//8A4O3/ALK7/wCzvP8Asrz/ALK8/wCyvP8Asrz/ALO9/wCxuv8A1eH/APP//wDz
//8ALzH/AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/AAQE/wAAAP8AaW//AP///wH2//8GVVn/BlVZ/wH3//8A+f//ALvF/wAAAP8AAQH/AAAA/wAAAP8AAAD/
AAAA/wABAf8AAAD/ABMU/wDg7P8A/f//AMjU/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ALrF/wD///8Azdr/AAQE/wAAAP8AAQH/AAAA/wAA
AP8AAAD/AAQE/wAAAP8AY2n/AP///wDs+/8A7///APP//wD9//8A/f//AP3//wD9//8A/f//AP3//wD8//8A/f//APb//wDu//8A9P//AC8x/wAAAP8AAgL/
AAAA/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGlv/wD///8B9v//BlVZ/wZVWf8B9///APn//wC7xf8AAAD/AAEB/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wAT
FP8A4Oz/AP3//wDI1P8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wC6xf8A////AM3a/wAEBP8AAAD/AAEB/wAAAP8AAAD/AAAA/wAEBP8AAAD/
AGNp/wD///8A7Pv/APD//wDv/v8A7fz/AO38/wDt/P8A7fz/AO38/wDt/P8A7fz/AO38/wDv/v8A7///APT//wAvMf8AAAD/AAIC/wAAAP8AAAD/AAAA/wAA
AP8ABAT/AAAA/wBpb/8A////Afb//wZVWf8GVVn/Aff//wD5//8Au8X/AAAA/wABAf8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AExT/AODs/wD9//8AyNT/
AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AusX/AP///wDN2v8ABAT/AAAA/wABAf8AAAD/AAAA/wAAAP8ABAT/AAAA/wBjaf8A////AOz7/wDw
//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//AO///wD0//8ALzH/AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/AAQE/wAAAP8AaW//
AP///wH2//8GVVn/BlVZ/wH3//8A+f//ALvF/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ABMU/wDg7P8A/f//AMjU/wAAAP8AAAD/AAAA/wAA
AP8AAAD/AAAA/wABAf8AAAD/ALrF/wD///8Azdr/AAQE/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAQE/wAAAP8AY2n/AP///wDs+/8A8P//APD//wDw//8A8P//
APD//wDw//8A8P//APD//wDw//8A8P//APD//wDv//8A9P//AC8x/wAAAP8AAgL/AAAA/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGlv/wD///8B9v//BlVZ/wZV
Wf8B9///APn//wC7xf8AAAD/AAEB/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wATFP8A4Oz/AP3//wDI1P8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAQH/
AAAA/wC6xf8A////AM3a/wAEBP8AAAD/AAEB/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGNp/wD///8A7Pv/APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw
//8A8P//APD//wDw//8A7///APT//wAvMf8AAAD/AAIC/wAAAP8AAAD/AAAA/wAAAP8ABAT/AAAA/wBpb/8A////Afb//wZVWf8GVVn/Aff//wD5//8Au8X/
AAAA/wABAf8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AExT/AODs/wD9//8AyNT/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AusX/AP///wDN
2v8ABAT/AAAA/wABAf8AAAD/AAAA/wAAAP8ABAT/AAAA/wBjaf8A////AOz7/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//
AO///wD0//8ALzH/AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/AAQE/wAAAP8AaW//AP///wH2//8GVVn/BlVZ/wH3//8A+f//ALvF/wAAAP8AAQH/AAAA/wAA
AP8AAAD/AAAA/wABAf8AAAD/ABMU/wDg7P8A/f//AMjU/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ALrF/wD///8Azdr/AAQE/wAAAP8AAQH/
AAAA/wAAAP8AAAD/AAQE/wAAAP8AY2n/AP///wDs+/8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDv//8A9P//AC8x/wAA
AP8AAgL/AAAA/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGlv/wD///8B9v//BlVZ/wZVWf8B9///APn//wC7xf8AAAD/AAEB/wAAAP8AAAD/AAAA/wAAAP8AAQH/
AAAA/wATFP8A4Oz/AP3//wDI1P8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wC6xf8A////AM3a/wAEBP8AAAD/AAEB/wAAAP8AAAD/AAAA/wAE
BP8AAAD/AGNp/wD///8A7Pv/APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7///APT//wAvMf8AAAD/AAIC/wAAAP8AAAD/
AAAA/wAAAP8ABAT/AAAA/wBpb/8A////Afb//wZVWf8GVVn/Aff//wD5//8Au8X/AAAA/wABAf8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AExT/AODs/wD9
//8AyNT/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AusX/AP///wDN2v8ABAT/AAAA/wABAf8AAAD/AAAA/wAAAP8ABAT/AAAA/wBjaf8A////
AOz7/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//AO///wD0//8ALzH/AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/AAQE/wAA
AP8AaW//AP///wH2//8GVVn/BlVZ/wH3//8A+f//ALvF/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ABMU/wDg7P8A/f//AMjU/wAAAP8AAAD/
AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ALrF/wD///8Azdr/AAQE/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAQE/wAAAP8AY2n/AP///wDs+/8A8P//APD//wDw
//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDv//8A9P//AC8x/wAAAP8AAgL/AAAA/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGlv/wD///8B9v//
BlVZ/wZVWf8B9///APn//wC7xf8AAAD/AAEB/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wATFP8A4Oz/AP3//wDI1P8AAAD/AAAA/wAAAP8AAAD/AAAA/wAA
AP8AAQH/AAAA/wC6xf8A////AM3a/wAEBP8AAAD/AAEB/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGNp/wD///8A7Pv/APD//wDw//8A8P//APD//wDw//8A8P//
APD//wDw//8A8P//APD//wDw//8A7///APT//wAvMf8AAAD/AAIC/wAAAP8AAAD/AAAA/wAAAP8ABAT/AAAA/wBpb/8A////Afb//wZVWf8GVVn/Aff//wD5
//8Au8X/AAAA/wABAf8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AExT/AODs/wD9//8AyNT/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AusX/
AP///wDN2v8ABAT/AAAA/wABAf8AAAD/AAAA/wAAAP8ABAT/AAAA/wBjaf8A////AOz7/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw
//8A8P//AO///wD0//8ALzH/AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/AAQE/wAAAP8AaW//AP///wH2//8GVVn/BlVZ/wH3//8A+f//ALvF/wAAAP8AAQH/
AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ABMU/wDg7P8A/f//AMjU/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ALrF/wD///8Azdr/AAQE/wAA
AP8AAQH/AAAA/wAAAP8AAAD/AAQE/wAAAP8AY2n/AP///wDs+/8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDv//8A9P//
AC8x/wAAAP8AAgL/AAAA/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGlv/wD///8B9v//BlVZ/wZVWf8B9///APn//wC7xf8AAAD/AAEB/wAAAP8AAAD/AAAA/wAA
AP8AAQH/AAAA/wATFP8A4Oz/AP3//wDI1P8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wC6xf8A////AM3a/wAEBP8AAAD/AAEB/wAAAP8AAAD/
AAAA/wAEBP8AAAD/AGNp/wD///8A7Pv/APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7///APT//wAvMf8AAAD/AAIC/wAA
AP8AAAD/AAAA/wAAAP8ABAT/AAAA/wBpb/8A////Afb//wZVWf8GVVn/Aff//wD5//8Au8X/AAAA/wABAf8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AEhP/
AN/r/wD9//8AyNT/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AusX/AP///wDN2v8ABAT/AAAA/wABAf8AAAD/AAAA/wAAAP8ABAT/AAAA/wBj
af8A////AOz7/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//AO///wD0//8ALzH/AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/
AAQE/wAAAP8AaW//AP///wH2//8GVVn/BlVZ/wH3//8A+f//ALvF/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ABES/wDe6v8A/f//AMjU/wAA
AP8AAAD/AAAA/wAAAP8AAAD/AAAA/wABAf8AAAD/ALrF/wD///8Azdr/AAQE/wAAAP8AAQH/AAAA/wAAAP8AAAD/AAQE/wAAAP8AY2n/AP///wDs+/8A8P//
APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDv//8A9P//AC8x/wAAAP8AAgL/AAAA/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGlv/wD/
//8B9v//BlVZ/wZVWf8B9///APn//wC7xf8AAAD/AAEB/wAAAP8AAAD/AAAA/wAAAP8AAQH/AAAA/wAREv8A3en/APz+/wDH0/8AAAD/AAAA/wAAAP8AAAD/
AAAA/wAAAP8AAQH/AAAA/wC5xP8A/v7/AMzZ/wAEBP8AAAD/AAEB/wAAAP8AAAD/AAAA/wAEBP8AAAD/AGNp/wD///8A7Pv/APD//wDw//8A8P//APD//wDw
//8A8P//APD//wDw//8A8P//APD//wDw//8A7///APT//wAvMf8AAAD/AAIC/wAAAP8AAAD/AAAA/wAAAP8ABAT/AAAA/wBpb/8A////Afb//wZVWf8GVVn/
Aff//wD5//8AvMb/AAAA/wABAf8AAAD/AAAA/wAAAP8AAAD/AAEB/wAAAP8AERL/AOLu/wD///8Ay9j/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAEB/wAA
AP8Avcj/AP///wDQ3v8ABAT/AAAA/wABAf8AAAD/AAAA/wAAAP8ABAT/AAAA/wBjaf8A////AOz7/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//
APD//wDw//8A8P//AO///wD0//8ALzH/AAAA/wACAv8AAAD/AAAA/wAAAP8AAAD/AAQE/wAAAP8AanD/AP///wH2//8GVVn/BVJX/AH2//8A+v//ALnD/wAB
Af8AAgL/AAAA/wABAf8AAQH/AAEB/wACAv8AAQH/ABAR/wDQ2v8A7O//ALvG/wABAf8AAQH/AAEB/wABAf8AAQH/AAEB/wACAv8AAQH/AK64/wDu7/8AwMv/
AAQE/wABAf8AAQH/AAEB/wABAf8AAQH/AAUF/wABAf8AY2n/AP///wDs+/8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDv
//8A9P//AC8x/wABAf8AAwP/AAEB/wABAf8AAQH/AAEB/wAFBf8AAwP/AGZs/wD///8B9f//BVJX/AQzNuIC7vv+APf//gDR3P8AAAD/AAAA/wAAAP8AAAD/
AAAA/wAAAP8AAAD/AAAA/wAAAP8ADxD/ABES/wANDv8AAAD/AAAA/wAAAP8AAAD/AAAA/wAAAP8AAAD/AAAA/wANDf8AERL/AA4O/wAAAP8AAAD/AAAA/wAA
AP8AAAD/AAAA/wADA/8AAAD/AGJo/wD///8A7Pv/APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A7///APT//wAuMP8AAAD/
AAEB/wAAAP8AAAD/AAAA/wAAAP8AAgL/AAAA/wCEjP8A///+Auz5/gQzNuIDAwOTBbzG/wD8//wA9v7/AIeN/wAQEP8ABQT/AAMD/wADA/8AAwP/AAMC/wAD
A/8AAgL/AAAA/wAAAP8AAAD/AAMC/wADA/8AAwL/AAMD/wADA/8AAwP/AAMC/wADA/8AAAD/AAAA/wAAAP8AAwL/AAMD/wADAv8AAwP/AAMD/wADA/8ABwb/
AAIC/wBlav8A////AOz7/wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//APD//wDw//8A8P//AO///wD0//8AMTP/AAIC/wAFBP8AAwP/AAMD/wAD
A/8ABAT/AAYG/wBJTP8A5O7/AP///AW7xf8DAwOTAAAAHQU8P+0D+P7/APf/+wD2//8A2uf/AMzX/wDN2P8AzNj/AMzY/wDM2P8AzNj/AMzY/wDN2f8Aztn/
AM3Z/wDM2P8AzNj/AMzY/wDM2P8AzNj/AMzY/wDM2P8AzNj/AM3Y/wDO2f8Azdn/AMzY/wDM2P8AzNj/AMzY/wDM2P8AzNj/AM3Y/wDM1/8A2uf/APD9/wDt
/P8A7v3/AO79/wDu/f8A7v3/AO79/wDu/f8A7v3/AO79/wDu/f8A7v3/AO79/wDu/f8A7/3/ANPf/wDM1/8Azdj/AMzY/wDM2P8Azdj/AMzY/wDQ3P8A8P//
APz/+wP3/v8FPD/sAAAAHQACAwAAAABJBlFW+gTq7/8A///9AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD/
//sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP//+wD7//sA/P/7APz/+wD8//sA/P/7
APz/+wD8//sA/P/7APz/+wD8//sA/P/7APz/+wD8//sA/P/7APv/+wD///sA///7AP//+wD///sA///7AP//+wD///sA///7AP///QTp7v8GUVb6AAAASQAC
AwAAAAADAAIDAAAAAD0GJinLBoOG/wS8w/8FyNP/BcjT/wXJ0/8FydP/BcnT/wXJ0/8FydP/BcnT/wXJ0/8FydP/BcnT/wXJ0/8FydP/BcnT/wXJ0/8FydP/
BcnT/wXJ0/8FydP/BcnT/wXJ0/8FydP/BcnT/wXJ0/8FydP/BcnT/wXJ0/8FydP/BcnT/wXJ1P8Fy9X/BcrV/wXK1f8FytX/BcrV/wXK1f8FytX/BcrV/wXK
1f8FytX/BcrV/wXK1f8FytX/BcrV/wXK1f8FydT/BcnT/wXJ0/8FydP/BcnT/wXI0/8EyNP/BLzC/waDhv8FJinLAAAAPQACAwAAAAADAAAAAAAAAAMAAgMA
AAAAAQAAAEEEAAB5BQEAigUAAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUB
AIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCL
BQEAiwUBAIsFAQCLBQEAiwUBAIsFAQCLBQEAiwUBAIsFAACLBQEAigIAAHgAAABBAAAAAQACAwAAAAADAAAAAAAAAAAAAAAAAAAAAgACAgAABAQAAAEBAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQEAAAQEAAACAgAAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABAAAAAwAAAAQAAD8EAAAABAAAAAQAAAAE
AAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAA
AAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAEAAAABAAAAAQAAAAE
AAAABAAAAAQAAD8EAAAABAAAAAMAAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA==
'@

$LogoBase64 = @'
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
FOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKi
QBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREF
uoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQ
RURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEu
IiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiIiCnQR
EREFuoiIiCjQRURERIEuIiIiCnQREREFuoiIiCjQRURERIEuIiIiCnQREREFuoiIiCjQRURERIEuIiIiCnQREREFuoiIiCjQRUREpFhSKgIR6WushTBUOTS3
3DwwRuWgQBcR2aTSHEwZ+KUqimYNQCOgUFegS/dSy0Kk8y1zUwovPAWPPw2+D6Htxy1zA0EAe+4OM3cC26iWugJdulVFhcpApLOVYb8c/n0//Pg8lUfsV+fC
zD0gzLhKjijQpcjiivOQoe4/rFWZiHSmy72iHFIp98jl+m9R+L5roZeXu3IRBbqoy11kk/sMxUHenwPdWhfouqegZWsiIiKiQBcREREFuoiIiCjQRUREFOgi
IiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRUREFOgiIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcR
EREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiIiCjQRURERIEuIiKiQBcREREFuoiI
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
AABJRU5ErkJggg==
'@
#endregion

#region ------------------------------------- BOOTSTRAP ----------------------------------------
# WinForms needs an STA thread. Relaunch if necessary.
if ([System.Threading.Thread]::CurrentThread.GetApartmentState() -ne [System.Threading.ApartmentState]::STA) {
    $exe = (Get-Process -Id $PID).Path
    Start-Process -FilePath $exe -ArgumentList @('-STA', '-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    return
}

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$Inv = [System.Globalization.CultureInfo]::InvariantCulture
$script:Photos = New-Object System.Collections.ArrayList
$script:LogoImage = $null
$script:WicLoaded = $false
#endregion

#region ------------------------------------- HELPERS ------------------------------------------
function Show-Msg([string]$Text, [string]$Icon = 'Information', [string]$Buttons = 'OK') {
    [System.Windows.Forms.MessageBox]::Show($Text, $Config.ToolName,
        [System.Windows.Forms.MessageBoxButtons]$Buttons,
        [System.Windows.Forms.MessageBoxIcon]$Icon)
}

function Get-LogoPath {
    # Custom logo: Config.LogoFile (settings.txt "LogoFile"), relative to the project folder.
    $lf = [string]$Config.LogoFile
    if (-not $lf) { return $null }
    $root = if ($ProjectRoot) { $ProjectRoot } elseif ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $p = if ([System.IO.Path]::IsPathRooted($lf)) { $lf } else { Join-Path $root $lf }
    if (Test-Path -LiteralPath $p -PathType Leaf) { return $p }
    return $null
}

function Get-Logo {
    if ($script:LogoImage) { return $script:LogoImage }
    $builtIn = 'built-in M. J. Electric logo'
    $bytes = $null; $script:LogoSource = $builtIn
    $ext = Get-LogoPath
    if ($ext) { try { $bytes = [System.IO.File]::ReadAllBytes($ext); $script:LogoSource = $ext } catch { $bytes = $null } }
    if (-not $bytes) { $bytes = [Convert]::FromBase64String(($LogoBase64 -replace '\s', '')); $script:LogoSource = $builtIn }
    $ms = New-Object System.IO.MemoryStream(, $bytes)
    try { $tmp = [System.Drawing.Image]::FromStream($ms) }
    catch {
        # unreadable custom logo -> built-in logo
        $ms.Dispose()
        $ms = New-Object System.IO.MemoryStream(, [Convert]::FromBase64String(($LogoBase64 -replace '\s', '')))
        $tmp = [System.Drawing.Image]::FromStream($ms); $script:LogoSource = "$builtIn (custom logo could not be read)"
    }
    # copy so the stream can be released; Bitmap(Image) keeps 32bpp ARGB transparency
    $script:LogoImage = New-Object System.Drawing.Bitmap($tmp)
    $tmp.Dispose(); $ms.Dispose()
    return $script:LogoImage
}

function Get-AppIcon {
    if ($script:AppIcon) { return $script:AppIcon }
    try {
        $ms = New-Object System.IO.MemoryStream(, [Convert]::FromBase64String(($IconBase64 -replace '\s', '')))
        $script:AppIcon = New-Object System.Drawing.Icon($ms)
    } catch {
        try {   # fallback: build an icon from the logo bitmap
            $l = Get-Logo; $side = [Math]::Max($l.Width, $l.Height)
            $sq = New-Object System.Drawing.Bitmap(64, 64)
            $g = [System.Drawing.Graphics]::FromImage($sq)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $w = [int](64 * $l.Width / $side); $h = [int](64 * $l.Height / $side)
            $g.DrawImage($l, (New-Object System.Drawing.Rectangle([int]((64 - $w) / 2), [int]((64 - $h) / 2), $w, $h))); $g.Dispose()
            $script:AppIcon = [System.Drawing.Icon]::FromHandle($sq.GetHicon())
        } catch { $script:AppIcon = $null }
    }
    return $script:AppIcon
}

function Get-PhotoThumb($Photo, [int]$Max = 1000) {
    # Upright (EXIF-oriented) preview bitmap, cached on the photo object. Extra rotation is NOT applied.
    if ($Photo.Thumb) { return $Photo.Thumb }
    $img = $null; $ms = $null
    try {
        if ($Photo.Decoder -eq 'GDI') {
            $ms = New-Object System.IO.MemoryStream(, [System.IO.File]::ReadAllBytes($Photo.Path))
            $img = [System.Drawing.Image]::FromStream($ms, $true, $false)
        } else { $img = Get-WicBitmap $Photo.Path }
        $applyExif = ($Photo.Decoder -eq 'GDI') -or $Config.HeicApplyExifOrientation
        if ($applyExif -and $RotateMap.ContainsKey([int]$Photo.Orientation)) {
            $img.RotateFlip([System.Drawing.RotateFlipType]$RotateMap[[int]$Photo.Orientation])
        }
        $scale = [Math]::Min(1.0, $Max / [double][Math]::Max($img.Width, $img.Height))
        $tw = [Math]::Max(1, [int]($img.Width * $scale)); $th = [Math]::Max(1, [int]($img.Height * $scale))
        $t = New-Object System.Drawing.Bitmap($tw, $th)
        $g = [System.Drawing.Graphics]::FromImage($t)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img, (New-Object System.Drawing.Rectangle(0, 0, $tw, $th)))
        $g.Dispose()
        $Photo.Thumb = $t
        return $t
    } finally {
        if ($img) { $img.Dispose() }
        if ($ms) { $ms.Dispose() }
    }
}

function Clear-PhotoThumbs($Photos) {
    foreach ($p in @($Photos)) { if ($p.Thumb) { try { $p.Thumb.Dispose() } catch {}; $p.Thumb = $null } }
}

function Get-PhotoSlots {
    # Returns the ordered list of expected photos (AH set then BK set).
    param([string]$StrLabel, [string]$Stage, [bool]$CrossArm, [bool]$XBrace, [int]$AhAnom, [int]$BkAnom)
    $list = New-Object System.Collections.ArrayList
    foreach ($span in @('AH', 'BK')) {
        $items = New-Object System.Collections.ArrayList
        foreach ($s in $SpecSlots) {
            if ($s.N -eq 3 -and -not $CrossArm) { continue }
            if ($s.N -eq 4 -and -not $XBrace) { continue }
            [void]$items.Add([pscustomobject]@{ SpecNo = $s.N; Desc = $s.Desc })
        }
        $anom = if ($span -eq 'AH') { $AhAnom } else { $BkAnom }
        for ($i = 1; $i -le $anom; $i++) {
            [void]$items.Add([pscustomobject]@{ SpecNo = 9 + $i; Desc = "Anomaly #$i" })
        }
        $seq = 0
        foreach ($it in $items) {
            $seq++
            $no = if ($Config.RenumberSequential) { $seq } else { $it.SpecNo }
            $spanName = if ($span -eq 'AH') { 'Ahead' } else { 'Back' }
            [void]$list.Add([pscustomobject]@{
                    Span   = $span
                    Folder = (Get-SpanFolderName "$Stage $span")
                    Name   = ('Str {0} - {1} {2} {3}' -f $StrLabel, $no, $Stage, $span)
                    Desc   = "$spanName - $($it.Desc)"
                })
        }
    }
    return $list.ToArray()
}

# ---------- EXIF via System.Drawing (JPEG / PNG / TIFF) ----------
function Format-Coord($Value) {
    # ONE coordinate format for everything the user sees (photo caption, photo list, preview):
    # decimal degrees, 6 places, negative = S / W.
    $n = [int]$Config.CoordDecimals; if ($n -lt 0 -or $n -gt 10) { $n = 6 }
    return ([double]$Value).ToString("F$n", $Inv)
}

function Get-Rational([byte[]]$v, [int]$i) {
    $n = [BitConverter]::ToUInt32($v, $i * 8)
    $d = [BitConverter]::ToUInt32($v, $i * 8 + 4)
    if ($d -eq 0) { return 0.0 }
    return [double]$n / [double]$d
}

function Get-GdiGps($img, [int]$valId, [int]$refId) {
    $ids = $img.PropertyIdList
    if ($ids -notcontains $valId) { return $null }
    $v = $img.GetPropertyItem($valId).Value
    if ($null -eq $v -or $v.Length -lt 24) { return $null }
    $deg = (Get-Rational $v 0) + (Get-Rational $v 1) / 60.0 + (Get-Rational $v 2) / 3600.0
    if ($ids -contains $refId) {
        $r = [System.Text.Encoding]::ASCII.GetString($img.GetPropertyItem($refId).Value).Trim([char[]]@([char]0, ' ')).ToUpper()
        if ($r -eq 'S' -or $r -eq 'W') { $deg = - $deg }
    }
    return $deg
}

function Read-GdiMeta($img, $r) {
    $ids = $img.PropertyIdList
    if ($ids -contains 0x0112) {
        try { $r.Orientation = [int][BitConverter]::ToUInt16($img.GetPropertyItem(0x0112).Value, 0) } catch {}
    }
    foreach ($tid in @(0x9003, 0x0132)) {
        if ($ids -contains $tid) {
            try {
                $s = [System.Text.Encoding]::ASCII.GetString($img.GetPropertyItem($tid).Value).Trim([char[]]@([char]0, ' '))
                $r.Taken = [datetime]::ParseExact($s, 'yyyy:MM:dd HH:mm:ss', $Inv)
                $r.TakenSource = 'EXIF'
                break
            } catch {}
        }
    }
    $r.Lat = Get-GdiGps $img 2 1
    $r.Lon = Get-GdiGps $img 4 3
}

# ---------- WIC fallback (HEIC/HEIF and anything GDI+ can't open) ----------
function Initialize-Wic {
    if (-not $script:WicLoaded) {
        Add-Type -AssemblyName PresentationCore
        Add-Type -AssemblyName WindowsBase
        $script:WicLoaded = $true
    }
}

function Get-WicQuery($meta, [string[]]$Paths) {
    foreach ($p in $Paths) {
        try { $v = $meta.GetQuery($p); if ($null -ne $v) { return $v } } catch {}
    }
    return $null
}

function Convert-WicRationals($v) {
    # WIC returns GPS DMS as UInt64[3]: low 32 bits = numerator, high 32 bits = denominator
    if ($null -eq $v -or -not ($v -is [array]) -or $v.Count -lt 3) { return $null }
    $mask = [uint64]4294967295
    $div = @(1.0, 60.0, 3600.0)
    $t = 0.0
    for ($i = 0; $i -lt 3; $i++) {
        $u = [uint64]$v[$i]
        $n = [double]($u -band $mask)
        $d = [double]($u -shr 32)
        if ($d -ne 0) { $t += ($n / $d) / $div[$i] }
    }
    return $t
}

function Read-WicMeta([string]$Path, $r) {
    Initialize-Wic
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        $dec = [System.Windows.Media.Imaging.BitmapDecoder]::Create($fs,
            [System.Windows.Media.Imaging.BitmapCreateOptions]::DelayCreation,
            [System.Windows.Media.Imaging.BitmapCacheOption]::None)
        $meta = $dec.Frames[0].Metadata
        if ($null -eq $meta) { return }
        $lat = Convert-WicRationals (Get-WicQuery $meta @('/ifd/gps/{ushort=2}', '/app1/ifd/gps/{ushort=2}'))
        $lon = Convert-WicRationals (Get-WicQuery $meta @('/ifd/gps/{ushort=4}', '/app1/ifd/gps/{ushort=4}'))
        $latRef = [string](Get-WicQuery $meta @('/ifd/gps/{ushort=1}', '/app1/ifd/gps/{ushort=1}'))
        $lonRef = [string](Get-WicQuery $meta @('/ifd/gps/{ushort=3}', '/app1/ifd/gps/{ushort=3}'))
        if ($null -ne $lat -and $latRef.Trim().ToUpper().StartsWith('S')) { $lat = - $lat }
        if ($null -ne $lon -and $lonRef.Trim().ToUpper().StartsWith('W')) { $lon = - $lon }
        $r.Lat = $lat; $r.Lon = $lon
        $o = Get-WicQuery $meta @('/ifd/{ushort=274}', '/app1/ifd/{ushort=274}')
        if ($null -ne $o) { $r.Orientation = [int]$o }
        $dt = [string](Get-WicQuery $meta @('/ifd/exif/{ushort=36867}', '/app1/ifd/exif/{ushort=36867}'))
        if ($dt) {
            try { $r.Taken = [datetime]::ParseExact($dt.Trim([char[]]@([char]0, ' ')), 'yyyy:MM:dd HH:mm:ss', $Inv); $r.TakenSource = 'EXIF' } catch {}
        }
    } finally { $fs.Dispose() }
}

function Get-WicBitmap([string]$Path) {
    # Decode with WIC and hand back a System.Drawing.Bitmap
    Initialize-Wic
    $fs = [System.IO.File]::OpenRead($Path)
    try {
        $dec = [System.Windows.Media.Imaging.BitmapDecoder]::Create($fs,
            [System.Windows.Media.Imaging.BitmapCreateOptions]::None,
            [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
        $frame = $dec.Frames[0]
    } finally { $fs.Dispose() }
    $conv = New-Object System.Windows.Media.Imaging.FormatConvertedBitmap($frame, [System.Windows.Media.PixelFormats]::Bgr24, $null, [double]0)
    $enc = New-Object System.Windows.Media.Imaging.BmpBitmapEncoder
    $enc.Frames.Add([System.Windows.Media.Imaging.BitmapFrame]::Create($conv))
    $ms = New-Object System.IO.MemoryStream
    $enc.Save($ms); $ms.Position = 0
    $tmp = New-Object System.Drawing.Bitmap($ms)
    $bmp = New-Object System.Drawing.Bitmap($tmp)
    $tmp.Dispose(); $ms.Dispose()
    return $bmp
}

# ---------- Photo metadata ----------
function Get-PhotoMeta([string]$Path) {
    $r = [pscustomobject]@{
        Path = $Path; FileName = [System.IO.Path]::GetFileName($Path)
        Taken = $null; TakenSource = 'File'; Lat = $null; Lon = $null; HasGps = $false
        Orientation = 1; ExtraRotation = 0; Decoder = 'GDI'; Error = $null; Thumb = $null
    }
    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        $ms = New-Object System.IO.MemoryStream(, $bytes)
        $img = $null
        try { $img = [System.Drawing.Image]::FromStream($ms, $false, $false) } catch { $img = $null }
        if ($img) {
            try { Read-GdiMeta $img $r } finally { $img.Dispose(); $ms.Dispose() }
        } else {
            $ms.Dispose()
            $r.Decoder = 'WIC'
            Read-WicMeta $Path $r
        }
    } catch { $r.Error = $_.Exception.Message }
    if (-not $r.Taken) { $r.Taken = (Get-Item -LiteralPath $Path).LastWriteTime }
    if ($null -ne $r.Lat -and $null -ne $r.Lon -and -not ($r.Lat -eq 0 -and $r.Lon -eq 0)) { $r.HasGps = $true }
    return $r
}

# ---------- EXIF writing ----------
function New-PropItem([int]$Id, [int]$Type, [byte[]]$Value) {
    # PropertyItem has no public constructor; create an uninitialized instance.
    $t = [System.Drawing.Imaging.PropertyItem]
    $m = [System.Runtime.CompilerServices.RuntimeHelpers].GetMethod('GetUninitializedObject', [type[]]@([type]))
    $p = if ($m) { $m.Invoke($null, [object[]]@($t)) } else { [System.Runtime.Serialization.FormatterServices]::GetUninitializedObject($t) }
    $p.Id = $Id; $p.Type = [int16]$Type; $p.Len = $Value.Length; $p.Value = $Value
    return $p
}

function ConvertTo-DmsBytes([double]$Deg) {
    $Deg = [Math]::Abs($Deg)
    $d = [Math]::Floor($Deg)
    $mf = ($Deg - $d) * 60.0
    $m = [Math]::Floor($mf)
    $s = [Math]::Round(($mf - $m) * 60.0 * 10000.0)
    $vals = @([uint32]$d, [uint32]1, [uint32]$m, [uint32]1, [uint32]$s, [uint32]10000)
    $bytes = New-Object byte[] 24
    for ($i = 0; $i -lt 6; $i++) { [BitConverter]::GetBytes([uint32]$vals[$i]).CopyTo($bytes, $i * 4) }
    return , $bytes
}

function Set-OutputExif($bmp, $props, $Photo) {
    $skip = @(0x0112, 0x0100, 0x0101, 0x0201, 0x0202, 0xA002, 0xA003, 0x0000, 0x0001, 0x0002, 0x0003, 0x0004)
    foreach ($p in $props) {
        if ($skip -contains $p.Id) { continue }
        if ($p.Id -ge 0x5000 -and $p.Id -le 0x5FFF) { continue }   # GDI+ thumbnail tags (stale)
        try { $bmp.SetPropertyItem($p) } catch {}
    }
    $ascii = [System.Text.Encoding]::ASCII
    $latRef = if ($Photo.Lat -lt 0) { 'S' } else { 'N' }
    $lonRef = if ($Photo.Lon -lt 0) { 'W' } else { 'E' }
    $items = @(
        (New-PropItem 0x0112 3 ([BitConverter]::GetBytes([uint16]1))),
        (New-PropItem 0x0000 1 ([byte[]]@(2, 2, 0, 0))),
        (New-PropItem 0x0001 2 ($ascii.GetBytes($latRef + [char]0))),
        (New-PropItem 0x0002 5 (ConvertTo-DmsBytes $Photo.Lat)),
        (New-PropItem 0x0003 2 ($ascii.GetBytes($lonRef + [char]0))),
        (New-PropItem 0x0004 5 (ConvertTo-DmsBytes $Photo.Lon))
    )
    if ($Photo.TakenSource -eq 'EXIF' -and -not ($props | Where-Object { $_.Id -eq 0x9003 })) {
        $items += (New-PropItem 0x9003 2 ($ascii.GetBytes($Photo.Taken.ToString('yyyy:MM:dd HH:mm:ss', $Inv) + [char]0)))
    }
    foreach ($it in $items) { try { $bmp.SetPropertyItem($it) } catch {} }
}

# ---------- Image processing ----------
$RotateMap = @{
    2 = 'RotateNoneFlipX'; 3 = 'Rotate180FlipNone'; 4 = 'Rotate180FlipX'; 5 = 'Rotate90FlipX'
    6 = 'Rotate90FlipNone'; 7 = 'Rotate270FlipX'; 8 = 'Rotate270FlipNone'
}
$ExtraRotateMap = @{ 90 = 'Rotate90FlipNone'; 180 = 'Rotate180FlipNone'; 270 = 'Rotate270FlipNone' }

function Invoke-ProcessPhoto($Photo, $Slot) {
    # Returns @{ Bytes = finished JPEG (in memory - nothing is written to disk until Save); Thumb }
    $img = $null; $ms = $null; $props = @(); $out = $null; $g = $null
    try {
        # 1. Load
        if ($Photo.Decoder -eq 'GDI') {
            $bytes = [System.IO.File]::ReadAllBytes($Photo.Path)
            $ms = New-Object System.IO.MemoryStream(, $bytes)
            $img = [System.Drawing.Image]::FromStream($ms, $true, $true)
            $props = @($img.PropertyItems)
        } else {
            $img = Get-WicBitmap $Photo.Path
        }

        # 2. Rotate upright (EXIF orientation), then any manual rotation
        $applyExif = ($Photo.Decoder -eq 'GDI') -or $Config.HeicApplyExifOrientation
        if ($applyExif -and $RotateMap.ContainsKey([int]$Photo.Orientation)) {
            $img.RotateFlip([System.Drawing.RotateFlipType]$RotateMap[[int]$Photo.Orientation])
        }
        if ($ExtraRotateMap.ContainsKey([int]$Photo.ExtraRotation)) {
            $img.RotateFlip([System.Drawing.RotateFlipType]$ExtraRotateMap[[int]$Photo.ExtraRotation])
        }

        $w = $img.Width; $h = $img.Height
        $short = [Math]::Min($w, $h); $long = [Math]::Max($w, $h)
        $barH = [int][Math]::Max($Config.BarMinPx, [Math]::Round($short * $Config.BarHeightPct))

        # 3. Canvas = photo + bar (added below, or above with BarPosition = Top)
        $barTop = ([string]$Config.BarPosition -eq 'Top')
        $photoY = if ($barTop) { $barH } else { 0 }
        $barY = if ($barTop) { 0 } else { $h }
        $out = New-Object System.Drawing.Bitmap($w, ($h + $barH), [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
        $g = [System.Drawing.Graphics]::FromImage($out)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

        $g.DrawImage($img, (New-Object System.Drawing.Rectangle(0, $photoY, $w, $h)))
        $barBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($Config.BarColor))
        $g.FillRectangle($barBrush, 0, $barY, $w, $barH)
        $barBrush.Dispose()

        # 4. Logo (LogoPosition / LogoSize / LogoMargin / LogoOpacity), placed on the photo area
        $lpos = [string]$Config.LogoPosition
        if ($lpos -and $lpos -ne 'None') {
            $logo = Get-Logo
            $lw = [int][Math]::Round($long * $Config.LogoWidthPct)
            $lh = [int][Math]::Round($lw * $logo.Height / $logo.Width)
            $mg = [int][Math]::Round($short * $Config.LogoMarginPct)
            $lx = if ($lpos -like '*Left') { $mg } else { $w - $lw - $mg }
            $ly = if ($lpos -like 'Bottom*') { $photoY + $h - $lh - $mg } else { $photoY + $mg }
            $dest = New-Object System.Drawing.Rectangle($lx, $ly, $lw, $lh)
            $op = [double]$Config.LogoOpacity
            if ($op -ge 100) { $g.DrawImage($logo, $dest) }
            elseif ($op -gt 0) {
                $cm = New-Object System.Drawing.Imaging.ColorMatrix
                $cm.Matrix33 = [single]($op / 100.0)
                $ia = New-Object System.Drawing.Imaging.ImageAttributes
                $ia.SetColorMatrix($cm)
                $g.DrawImage($logo, $dest, 0, 0, $logo.Width, $logo.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
                $ia.Dispose()
            }
        }

        # 5. Caption (TextFormat: {NAME} {STRUCTURE} {LAT} {LONG} {DATE}), auto-fit to the bar
        $text = ([string]$Config.TextFormat).Replace('{NAME}', $Slot.Name).Replace('{LAT}', (Format-Coord $Photo.Lat)).Replace('{LONG}', (Format-Coord $Photo.Lon))
        $text = $text.Replace('{DATE}', $Photo.Taken.ToString('MMM d, yyyy h:mm tt', $Inv)).Replace('{STRUCTURE}', ($Slot.Name -replace ' - .*$', ''))
        $fStyle = if ($Config.FontBold) { [System.Drawing.FontStyle]::Bold } else { [System.Drawing.FontStyle]::Regular }
        $maxW = $w * $Config.TextMaxWidthPct
        $size = [double]$barH * 0.6
        while ($size -gt 6) {
            $f = New-Object System.Drawing.Font($Config.FontName, [single]$size, $fStyle, [System.Drawing.GraphicsUnit]::Pixel)
            $m = $g.MeasureString($text, $f)
            $f.Dispose()
            if ($m.Width -le $maxW -and $m.Height -le ($barH * 0.95)) { break }
            $size = $size * 0.95
        }
        $font = New-Object System.Drawing.Font($Config.FontName, [single]$size, $fStyle, [System.Drawing.GraphicsUnit]::Pixel)
        $sf = New-Object System.Drawing.StringFormat
        $sf.Alignment = switch ([string]$Config.TextAlign) { 'Left' { [System.Drawing.StringAlignment]::Near } 'Right' { [System.Drawing.StringAlignment]::Far } default { [System.Drawing.StringAlignment]::Center } }
        $sf.LineAlignment = [System.Drawing.StringAlignment]::Center
        $sf.FormatFlags = [System.Drawing.StringFormatFlags]::NoWrap
        $txtBrush = New-Object System.Drawing.SolidBrush([System.Drawing.ColorTranslator]::FromHtml($Config.TextColor))
        $padX = [single](($w - $maxW) / 2)      # side margin used by Left / Right alignment
        $g.DrawString($text, $font, $txtBrush, (New-Object System.Drawing.RectangleF($padX, [single]$barY, [single]($w - 2 * $padX), [single]$barH)), $sf)
        $txtBrush.Dispose(); $font.Dispose(); $sf.Dispose()
        $g.Dispose(); $g = $null

        # 6. EXIF + save JPEG
        Set-OutputExif $out $props $Photo
        $codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
        $ep = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $ep.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$Config.JpegQuality)
        $jms = New-Object System.IO.MemoryStream
        $out.Save($jms, $codec, $ep)
        $ep.Dispose()
        $jpegBytes = $jms.ToArray(); $jms.Dispose()

        # 7. Preview thumbnail
        $tw = [int][Math]::Min($Config.PreviewWidth, $out.Width)
        $th = [int][Math]::Round($out.Height * $tw / $out.Width)
        $thumb = New-Object System.Drawing.Bitmap($tw, $th)
        $tg = [System.Drawing.Graphics]::FromImage($thumb)
        $tg.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $tg.DrawImage($out, (New-Object System.Drawing.Rectangle(0, 0, $tw, $th)))
        $tg.Dispose()
        return [pscustomobject]@{ Bytes = $jpegBytes; Thumb = $thumb }
    } finally {
        if ($g) { $g.Dispose() }
        if ($out) { $out.Dispose() }
        if ($img) { $img.Dispose() }
        if ($ms) { $ms.Dispose() }
    }
}
#endregion

#region ------------------------------------- PROJECT STATUS SCAN ------------------------------
# These functions are kept as TEXT so they can be loaded both here (UI thread) and in the
# background runspace that performs the status check without freezing the GUI.
# Variables they expect: $Config, $ProjectRoot (set by the caller / runspace).
$ScanFunctionsText = @'
Add-Type -AssemblyName System.Drawing
$Inv = [System.Globalization.CultureInfo]::InvariantCulture
$StrFolderRegex = '^Str\s*#?\s*(\d+)$'
$StageSpans = @('Before AH', 'Before BK', 'After AH', 'After BK')   # internal keys (also used in file names)
# Folder names inside each "Str ####" folder - the section titles from the ES spec
$SpanFolderNames = @{
    'Before AH' = 'Existing Structure Ahead Span'
    'Before BK' = 'Existing Structure Back Span'
    'After AH'  = 'Replacement Structure Ahead Span'
    'After BK'  = 'Replacement Structure Back Span'
}
function Get-SpanFolderName([string]$Key) {
    if ($SpanFolderNames.ContainsKey($Key)) { return $SpanFolderNames[$Key] }
    return $Key
}

function Find-StrFolder([string]$Parent, [string]$Num) {
    # Returns the full path of the "Str <num>" folder inside $Parent, or $null.
    if (-not $Parent -or -not (Test-Path -LiteralPath $Parent -PathType Container)) { return $null }
    foreach ($d in @(Get-ChildItem -LiteralPath $Parent -Directory -ErrorAction SilentlyContinue)) {
        if ($d.Name -match $StrFolderRegex -and [decimal]$Matches[1] -eq [decimal]$Num) { return $d.FullName }
    }
    return $null
}

function Get-StrFolders([string]$Root) {
    # All "Str ###" folders, sorted by structure number.
    @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match $StrFolderRegex } |
        Sort-Object @{ Expression = { [decimal]([regex]::Match($_.Name, '\d+').Value) } }, Name)
}

function Get-U16([byte[]]$B, [int]$O, [bool]$LE) {
    if ($LE) { return [int]$B[$O] -bor ([int]$B[$O + 1] -shl 8) }
    return ([int]$B[$O] -shl 8) -bor [int]$B[$O + 1]
}
function Get-U32([byte[]]$B, [int]$O, [bool]$LE) {
    if ($LE) { return [long]([BitConverter]::ToUInt32($B, $O)) }
    return ([long]$B[$O] -shl 24) -bor ([long]$B[$O + 1] -shl 16) -bor ([long]$B[$O + 2] -shl 8) -bor [long]$B[$O + 3]
}
function Find-IfdTag([byte[]]$B, [int]$T, [int]$Ifd, [int]$N, [bool]$LE, [int]$Tag) {
    # Returns the 4-byte value/offset field position of $Tag in the IFD at $Ifd, or -1
    if ($Ifd + 2 -gt $N) { return -1 }
    $cnt = Get-U16 $B $Ifd $LE
    for ($i = 0; $i -lt $cnt; $i++) {
        $e = $Ifd + 2 + $i * 12
        if ($e + 12 -gt $N) { return -1 }
        if ((Get-U16 $B $e $LE) -eq $Tag) { return $e + 8 }
    }
    return -1
}
function Read-ExifDateFast([string]$Path) {
    # Reads only the first 128 KB of a JPEG and parses the EXIF header for DateTimeOriginal
    # (0x9003), falling back to DateTime (0x0132). Much faster than opening the whole image,
    # especially on network / SharePoint-synced drives. Returns [datetime] or $null.
    $fs = $null
    try {
        $fs = New-Object System.IO.FileStream($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite, 4096)
        $len = [int][Math]::Min(131072, $fs.Length)
        $buf = New-Object byte[] $len
        $n = $fs.Read($buf, 0, $len)
    } catch { return $null } finally { if ($fs) { $fs.Dispose() } }
    try {
        if ($n -lt 16 -or $buf[0] -ne 0xFF -or $buf[1] -ne 0xD8) { return $null }
        $p = 2
        while ($p + 10 -lt $n) {
            if ($buf[$p] -ne 0xFF) { return $null }
            $m = [int]$buf[$p + 1]
            if ($m -eq 0xD9 -or $m -eq 0xDA) { return $null }
            $seg = ([int]$buf[$p + 2] -shl 8) -bor [int]$buf[$p + 3]
            if ($m -eq 0xE1 -and [System.Text.Encoding]::ASCII.GetString($buf, $p + 4, 4) -eq 'Exif') {
                $t = $p + 10                                   # TIFF header
                $le = ($buf[$t] -eq 0x49)
                $ifd0 = $t + [int](Get-U32 $buf ($t + 4) $le)
                $at = -1
                $exifPtr = Find-IfdTag $buf $t $ifd0 $n $le 0x8769
                if ($exifPtr -ge 0) {
                    $exif = $t + [int](Get-U32 $buf $exifPtr $le)
                    $at = Find-IfdTag $buf $t $exif $n $le 0x9003
                }
                if ($at -lt 0) { $at = Find-IfdTag $buf $t $ifd0 $n $le 0x0132 }
                if ($at -lt 0) { return $null }
                $so = $t + [int](Get-U32 $buf $at $le)
                if ($so + 19 -gt $n) { return $null }
                $str = [System.Text.Encoding]::ASCII.GetString($buf, $so, 19)
                return [datetime]::ParseExact($str, 'yyyy:MM:dd HH:mm:ss', $Inv)
            }
            $p += 2 + $seg
        }
    } catch {}
    return $null
}

function Get-PhotoDateFast($File) {
    # Date taken for the status check. Order: remembered date (same file size + modified time)
    # -> fast EXIF header read -> full GDI+ read -> file modified date.
    # Cloud-only (OneDrive/SharePoint placeholder) files are NOT read, to avoid downloading them.
    $key = $File.FullName.ToLower()
    $stamp = "$($File.Length)|$($File.LastWriteTimeUtc.Ticks)"
    if ($DateCache -and $DateCache.ContainsKey($key)) {
        $c = $DateCache[$key]
        if ($c.Stamp -eq $stamp) { if ($DateSeen) { $DateSeen[$key] = $c }; return $c.Date }
    }
    if (([int]$File.Attributes -band 0x00401000) -ne 0) { return $File.LastWriteTime }
    $d = Read-ExifDateFast $File.FullName
    if (-not $d) {
        $fs = $null; $img = $null
        try {
            $fs = [System.IO.File]::OpenRead($File.FullName)
            $img = [System.Drawing.Image]::FromStream($fs, $false, $false)
            foreach ($tid in @(0x9003, 0x0132)) {
                if ($img.PropertyIdList -contains $tid) {
                    $s = [System.Text.Encoding]::ASCII.GetString($img.GetPropertyItem($tid).Value).Trim([char[]]@([char]0, ' '))
                    $d = [datetime]::ParseExact($s, 'yyyy:MM:dd HH:mm:ss', $Inv); break
                }
            }
        } catch {
        } finally {
            if ($img) { $img.Dispose() }
            if ($fs) { $fs.Dispose() }
        }
    }
    if (-not $d) { $d = $File.LastWriteTime }
    if ($DateSeen) { $DateSeen[$key] = [pscustomobject]@{ Stamp = $stamp; Date = $d } }
    return $d
}

function Test-SpanFolder([string]$StageSpan, [string]$Num, [bool]$Exists, $Files) {
    # $Files = the image files (FileInfo) directly inside the span folder.
    $r = [pscustomobject]@{
        Name = $StageSpan; Exists = $Exists; Count = 0; Valid = $false
        Issues = (New-Object System.Collections.ArrayList); Files = @()
    }
    $fn = Get-SpanFolderName $StageSpan
    if (-not $Exists) { [void]$r.Issues.Add("${fn}: folder missing"); return $r }
    $files = @($Files)
    $r.Files = $files; $r.Count = $files.Count
    if ($files.Count -eq 0) { [void]$r.Issues.Add("${fn}: folder is empty"); return $r }

    $parts = $StageSpan.Split(' ')
    $strict = [bool]$Config.StrictNaming
    # Strict = exact ES format, case-sensitive, .jpg only:  "Str 1234 - 5 Before AH.jpg"
    $rxStrict = '^Str (\d+) - (\d+) ' + $parts[0] + ' ' + $parts[1] + '\.jpg$'
    $rxLoose = '^Str\s*#?\s*(\d+)\s*-\s*(\d+)\s+' + $parts[0] + '\s+' + $parts[1] + '$'
    $nums = New-Object System.Collections.ArrayList
    foreach ($f in $files) {
        if ($strict) { $ok = ($f.Name -cmatch $rxStrict) -and ($Matches[1] -ceq $Num) }
        else { $ok = ([System.IO.Path]::GetFileNameWithoutExtension($f.Name) -match $rxLoose) -and ([decimal]$Matches[1] -eq [decimal]$Num) }
        if ($ok) { [void]$nums.Add([int]$Matches[2]) }
        else { [void]$r.Issues.Add("${fn}: non-conforming file name '$($f.Name)' (expected like 'Str $Num - 5 $StageSpan.jpg')") }
    }
    if ($Config.RenumberSequential) {
        $max = 0; if ($nums.Count) { $max = [int](($nums | Measure-Object -Maximum).Maximum) }
        $required = @(1..([Math]::Max(7, $max)))
    } else {
        $required = @(1, 2, 5, 6, 7, 8, 9)
        $an = @($nums | Where-Object { $_ -ge 10 } | Sort-Object)
        if ($an.Count -gt 0 -and $an[-1] -ne (9 + $an.Count)) { [void]$r.Issues.Add("${fn}: anomaly numbering has gaps (" + ($an -join ', ') + ')') }
    }
    $missing = @($required | Where-Object { $nums -notcontains $_ })
    if ($missing.Count -gt 0) { [void]$r.Issues.Add("${fn}: missing photo # " + ($missing -join ', ')) }
    $r.Valid = ($r.Issues.Count -eq 0)
    return $r
}

function Format-DateRange($Dates) {
    $d = @($Dates | Where-Object { $_ } | Sort-Object)
    if ($d.Count -eq 0) { return '' }
    $a = $d[0]; $b = $d[-1]
    # Display format e.g. "Nov 3, 2026" / "Nov 3 - Nov 5, 2026" / "Dec 30, 2025 - Jan 2, 2026"
    if ($a.Date -eq $b.Date) { return $a.ToString('MMM d, yyyy', $Inv) }
    if ($a.Year -eq $b.Year) { return '{0} - {1}' -f $a.ToString('MMM d', $Inv), $b.ToString('MMM d, yyyy', $Inv) }
    return '{0} - {1}' -f $a.ToString('MMM d, yyyy', $Inv), $b.ToString('MMM d, yyyy', $Inv)
}

function Test-IgnorableFile($File) {
    # System / OS junk that is never reported
    if (-not $File) { return $true }
    $n = $File.Name.ToLower()
    if ($Config.IgnoreFileNames -contains $n) { return $true }
    if ($n.StartsWith('~$') -or $n.StartsWith('._')) { return $true }
    return (([int]$File.Attributes -band 6) -ne 0)   # Hidden (2) or System (4)
}

function New-NamingRow([string]$Name, [string]$Path, [int]$Count, $Issues) {
    [pscustomobject]@{
        Num = [decimal]999999999; Name = $Name; Path = $Path; Status = 'Naming Issue'
        BeforeDates = @(); AfterDates = @(); BeforeText = ''; AfterText = ''
        BAH = ''; BBK = ''; AAH = ''; ABK = ''; Total = $Count; Issues = @($Issues)
    }
}

function Get-NonStrRows([string]$Root) {
    # Project-level folders that are not "Str ####" and photos dumped in the project folder.
    $rows = New-Object System.Collections.ArrayList
    foreach ($d in @(Get-ChildItem -LiteralPath $Root -Directory -ErrorAction SilentlyContinue)) {
        if ($d.Name -match $StrFolderRegex) { continue }
        if ($d.Name.StartsWith('.') -or ($Config.IgnoreProjectFolders -contains $d.Name)) { continue }
        $cnt = 0
        try { $cnt = @($d.GetFiles('*', [System.IO.SearchOption]::AllDirectories) | Where-Object { -not (Test-IgnorableFile $_) }).Count } catch {}
        [void]$rows.Add((New-NamingRow $d.Name $d.FullName $cnt @("Folder '$($d.Name)' is not named 'Str ####' - it is not counted in the project status. Rename it (e.g. 'Str 1234') or move its contents.")))
    }
    $loose = @(Get-ChildItem -LiteralPath $Root -File -ErrorAction SilentlyContinue |
            Where-Object { $Config.Extensions -contains $_.Extension.ToLower() -and $_.Name -ne 'logo.png' -and $_.Name -ne [System.IO.Path]::GetFileName([string]$Config.LogoFile) -and -not (Test-IgnorableFile $_) })
    if ($loose.Count -gt 0) {
        [void]$rows.Add((New-NamingRow '(project folder)' $Root $loose.Count @($loose | ForEach-Object { "Loose photo in the project folder (not in a Str folder): $($_.Name)" })))
    }
    return $rows.ToArray()
}

function Get-ProjectIndex([string]$Root) {
    # ONE listing of every file and folder under the project, grouped by top-level folder.
    # Returns $null if any folder can't be read (callers then list each structure separately).
    $rootDi = New-Object System.IO.DirectoryInfo($Root)
    try {
        $files = $rootDi.GetFiles('*', [System.IO.SearchOption]::AllDirectories)
        $dirs = $rootDi.GetDirectories('*', [System.IO.SearchOption]::AllDirectories)
    } catch { return $null }
    $cut = $rootDi.FullName.TrimEnd('\').Length + 1
    $idx = @{ Files = @{}; Dirs = @{} }
    foreach ($f in $files) {
        if ($f.FullName.Length -le $cut) { continue }
        $rel = $f.FullName.Substring($cut); $k = $rel.IndexOf('\')
        if ($k -lt 0) { continue }                                  # file directly in the project folder
        $top = $rel.Substring(0, $k).ToLower()
        if (-not $idx.Files.ContainsKey($top)) { $idx.Files[$top] = New-Object System.Collections.ArrayList }
        [void]$idx.Files[$top].Add($f)
    }
    foreach ($d in $dirs) {
        $rel = $d.FullName.Substring($cut); $k = $rel.IndexOf('\')
        if ($k -lt 0) { continue }                                  # the top-level folder itself
        $top = $rel.Substring(0, $k).ToLower()
        if (-not $idx.Dirs.ContainsKey($top)) { $idx.Dirs[$top] = New-Object System.Collections.ArrayList }
        [void]$idx.Dirs[$top].Add($d)
    }
    return $idx
}

function Get-StructureStatus($Dir, [bool]$ReadExif = $false, [bool]$Indexed = $false, $PreFiles = @(), $PreDirs = @()) {
    # $Indexed: files/sub-folders come from ONE listing of the whole project (Get-ProjectIndex)
    # instead of listing this structure folder again.
    # Quick check ($ReadExif = $false): folder listing only; dates = file modified date, which
    # this tool sets to the photo's taken date when it saves. Deep check reads EXIF dates.
    [void]($Dir.Name -match $StrFolderRegex); $num = $Matches[1]
    $strict = [bool]$Config.StrictNaming
    $extra = New-Object System.Collections.ArrayList     # naming / housekeeping issues
    if ($strict -and $Dir.Name -cnotmatch '^Str \d+$') { [void]$extra.Add("Structure folder '$($Dir.Name)' should be named exactly 'Str $num'") }

    # One directory listing per structure (fast on large projects / network drives)
    $di = New-Object System.IO.DirectoryInfo($Dir.FullName)
    $subDirs = @{}                                         # canonical span name -> DirectoryInfo
    $childDirs = if ($Indexed) { @($PreDirs | Where-Object { $_ -and $_.Parent.FullName -eq $di.FullName }) } else { @($di.GetDirectories()) }
    foreach ($sd in $childDirs) {
        $canon = @($StageSpans | Where-Object { $SpanFolderNames[$_] -eq $sd.Name })   # case-insensitive match
        $old = @($StageSpans | Where-Object { $_ -eq $sd.Name })                       # pre-v14 short names
        if ($canon.Count -gt 0) {
            $want = $SpanFolderNames[$canon[0]]
            $subDirs[$canon[0]] = $sd
            if ($strict -and $sd.Name -cne $want) { [void]$extra.Add("Folder '$($sd.Name)' should be named exactly '$want'") }
            $nested = if ($Indexed) { @($PreDirs | Where-Object { $_ -and $_.Parent.FullName -eq $sd.FullName }) } else { @($sd.GetDirectories()) }
            foreach ($nd in $nested) { [void]$extra.Add("Unexpected folder '$($sd.Name)\$($nd.Name)' - span folders should only contain photos") }
        } elseif ($old.Count -gt 0) {
            [void]$extra.Add("Folder '$($sd.Name)' uses the old short name - rename it to '$($SpanFolderNames[$old[0]])'")
        } else {
            [void]$extra.Add("Unexpected folder '$($sd.Name)' - only '" + (($StageSpans | ForEach-Object { $SpanFolderNames[$_] }) -join "', '") + "' belong in a Str folder")
        }
    }
    if ($Indexed) { $raw = @($PreFiles | Where-Object { $_ }) }   # never a $null "file"
    else {
        try { $raw = $di.GetFiles('*', [System.IO.SearchOption]::AllDirectories) }
        catch { $raw = @(Get-ChildItem -LiteralPath $Dir.FullName -File -Recurse -Force -ErrorAction SilentlyContinue) }
    }
    $all = New-Object System.Collections.ArrayList
    $byDir = @{}
    foreach ($f in $raw) {
        if (Test-IgnorableFile $f) { continue }
        $rel = $f.FullName.Substring($di.FullName.Length).TrimStart('\')
        if ($Config.Extensions -notcontains $f.Extension.ToLower()) {
            [void]$extra.Add("Other file type (not a photo): '$rel'")
            continue
        }
        [void]$all.Add($f)
        $k = $f.DirectoryName
        if (-not $byDir.ContainsKey($k)) { $byDir[$k] = New-Object System.Collections.ArrayList }
        [void]$byDir[$k].Add($f)
    }
    if ($byDir.ContainsKey($di.FullName)) {
        foreach ($f in $byDir[$di.FullName]) { [void]$extra.Add("Loose photo (not in a span folder): '$($f.Name)'") }
    }
    $spans = @{}
    foreach ($ss in $StageSpans) {
        $exists = $subDirs.ContainsKey($ss)
        $files = @()
        if ($exists -and $byDir.ContainsKey($subDirs[$ss].FullName)) { $files = @($byDir[$subDirs[$ss].FullName]) }
        $spans[$ss] = Test-SpanFolder $ss $num $exists $files
    }

    $beforeOk = $spans['Before AH'].Valid -and $spans['Before BK'].Valid
    $afterOk = $spans['After AH'].Valid -and $spans['After BK'].Valid
    $afterAny = ($spans['After AH'].Count + $spans['After BK'].Count) -gt 0
    $clean = ($extra.Count -eq 0)
    $issues = New-Object System.Collections.ArrayList
    if ($all.Count -eq 0 -and $clean) { $status = 'Not Started' }
    elseif ($clean -and $beforeOk -and $afterOk) { $status = 'Complete' }
    elseif ($clean -and $beforeOk -and -not $afterAny) { $status = 'Partially Complete' }
    else {
        $status = 'Needs Attention'
        if ($all.Count -gt 0) { foreach ($ss in @('Before AH', 'Before BK')) { foreach ($i in $spans[$ss].Issues) { [void]$issues.Add($i) } } }
        if ($afterAny) { foreach ($ss in @('After AH', 'After BK')) { foreach ($i in $spans[$ss].Issues) { [void]$issues.Add($i) } } }
        foreach ($i in $extra) { [void]$issues.Add($i) }
    }
    $getDate = if ($ReadExif) { { Get-PhotoDateFast $_ } } else { { $_.LastWriteTime } }
    $bDates = @(($spans['Before AH'].Files + $spans['Before BK'].Files) | ForEach-Object $getDate)
    $aDates = @(($spans['After AH'].Files + $spans['After BK'].Files) | ForEach-Object $getDate)
    [pscustomobject]@{
        Num = [decimal]$num; Name = $Dir.Name; Path = $Dir.FullName; Status = $status
        BeforeDates = $bDates; AfterDates = $aDates
        BeforeText = (Format-DateRange $bDates); AfterText = (Format-DateRange $aDates)
        BAH = $spans['Before AH'].Count; BBK = $spans['Before BK'].Count
        AAH = $spans['After AH'].Count; ABK = $spans['After BK'].Count
        Total = $all.Count; Issues = @($issues)
    }
}
'@

$ProjectRoot = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
. ([scriptblock]::Create($ScanFunctionsText))

# Background-scan worker (runs in its own runspace; results go into a thread-safe queue that a
# UI timer drains, so the window keeps working and rows appear as they are checked).
$ScanWorkerText = @'
try {
    $DateCache = $Sync.DateCache          # remembered photo dates (from earlier checks)
    $DateSeen = $Sync.DateSeen            # dates used in this check (saved for next time)
    $Sync.Current = 'Listing all project folders...'
    $dirs = Get-StrFolders $ProjectRoot
    $index = Get-ProjectIndex $ProjectRoot   # one walk of the whole project
    $others = @(Get-NonStrRows $ProjectRoot)
    $Sync.Total = $dirs.Count + $others.Count
    foreach ($d in $dirs) {
        if ($Sync.Stop) { break }
        $Sync.Current = $d.Name
        try {
            if ($index) {
                $k = $d.Name.ToLower()
                # NOTE: "$x = if (...) {...} else { @() }" leaves $x = $null in PowerShell (an empty
                # array unrolls to nothing) - so start with @() and only replace it when there are items.
                $pf = @(); if ($index.Files.ContainsKey($k)) { $pf = $index.Files[$k].ToArray() }
                $pd = @(); if ($index.Dirs.ContainsKey($k)) { $pd = $index.Dirs[$k].ToArray() }
                $row = Get-StructureStatus $d $Sync.Deep $true $pf $pd
            } else { $row = Get-StructureStatus $d $Sync.Deep }
        }
        catch {
            $row = [pscustomobject]@{ Num = 0; Name = $d.Name; Path = $d.FullName; Status = 'Needs Attention'; BeforeDates = @(); AfterDates = @(); BeforeText = ''; AfterText = ''; BAH = 0; BBK = 0; AAH = 0; ABK = 0; Total = 0; Issues = @("Scan error: $($_.Exception.Message)") }
        }
        $Sync.Queue.Enqueue($row)
        $Sync.Processed++
    }
    $Sync.Current = 'other folders in the project folder'
    foreach ($o in $others) {
        if ($Sync.Stop) { break }
        $Sync.Queue.Enqueue($o); $Sync.Processed++
    }
} catch { $Sync.Error = $_.Exception.Message }
finally { $Sync.Done = $true }
'@

# Status cache: last results are stored per project folder in %LOCALAPPDATA% (never in the
# project folder, which gets uploaded to SharePoint) and shown instantly on the next start.
# (No MD5/SHA here: those throw on PCs where IT enforces FIPS mode.)
$cacheKey = ($ProjectRoot.ToLower() -replace '[^a-z0-9]+', '_').Trim('_')
if ($cacheKey.Length -gt 120) { $cacheKey = $cacheKey.Substring($cacheKey.Length - 120) }
$cacheBase = if ($env:LOCALAPPDATA) { $env:LOCALAPPDATA } else { [System.IO.Path]::GetTempPath() }
$StatusCacheFile = Join-Path (Join-Path $cacheBase 'ES_TLINE_PTOOL') ('status_' + $cacheKey + '.clixml')
# Remembered photo dates (path, size|modified-time stamp, date taken) - the tool's own cache,
# so photos that haven't changed are never re-read. Kept on this PC, not in the project.
$DateCacheFile = Join-Path (Join-Path $cacheBase 'ES_TLINE_PTOOL') ('dates_' + $cacheKey + '.txt')
$script:DateCacheMem = $null

function Get-DateCache {
    if ($script:DateCacheMem) { return $script:DateCacheMem }
    $h = [hashtable]::Synchronized(@{})
    try {
        if (Test-Path -LiteralPath $DateCacheFile) {
            foreach ($line in [System.IO.File]::ReadAllLines($DateCacheFile)) {
                $p = $line.Split("`t")
                if ($p.Count -ne 3) { continue }
                $h[$p[0]] = [pscustomobject]@{ Stamp = $p[1]; Date = (New-Object DateTime([long]$p[2])) }
            }
        }
    } catch {}
    $script:DateCacheMem = $h
    return $h
}

function Save-DateCache($Seen) {
    # Keep only the photos seen in the last full check (the cache never grows without bound)
    try {
        $dir = Split-Path -Parent $DateCacheFile
        if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir) }
        $lines = foreach ($k in @($Seen.Keys)) { $v = $Seen[$k]; "$k`t$($v.Stamp)`t$(([datetime]$v.Date).Ticks)" }
        [System.IO.File]::WriteAllLines($DateCacheFile, [string[]]@($lines))
        $new = [hashtable]::Synchronized(@{}); foreach ($k in @($Seen.Keys)) { $new[$k] = $Seen[$k] }
        $script:DateCacheMem = $new
    } catch {}
}
#endregion

#region ------------------------------------- SETTINGS.TXT -------------------------------------
# Optional per-project settings: <ProjectRoot>\settings.txt, "Name = value" lines, # comments.
# Read at start-up and again every time Process Photos is clicked (no restart needed).
# Missing / blank / invalid settings fall back to the defaults in CONFIG (= the ES spec look).
$SettingsFile = Join-Path $ProjectRoot 'settings.txt'
$script:SettingsWarnings = @()
$script:SettingsLoaded = @()
# Name in settings.txt -> CONFIG key, kind, extra (allowed values or min/max)
$SettingDefs = [ordered]@{
    LogoFile      = @('LogoFile', 'text', $null)
    LogoPosition  = @('LogoPosition', 'choice', @('TopRight', 'TopLeft', 'BottomRight', 'BottomLeft', 'None'))
    LogoSize      = @('LogoWidthPct', 'percent', @(1, 50))
    LogoMargin    = @('LogoMarginPct', 'percent', @(0, 20))
    LogoOpacity   = @('LogoOpacity', 'number', @(0, 100))
    BarPosition   = @('BarPosition', 'choice', @('Bottom', 'Top'))
    BarHeight     = @('BarHeightPct', 'percent', @(1, 30))
    BarColor      = @('BarColor', 'color', $null)
    TextColor     = @('TextColor', 'color', $null)
    Font          = @('FontName', 'font', $null)
    FontBold      = @('FontBold', 'bool', $null)
    TextAlign     = @('TextAlign', 'choice', @('Center', 'Left', 'Right'))
    TextWidth     = @('TextMaxWidthPct', 'percent', @(30, 100))
    TextFormat    = @('TextFormat', 'text', $null)
    CoordDecimals = @('CoordDecimals', 'number', @(4, 8))
    JpegQuality   = @('JpegQuality', 'number', @(50, 100))
}
$SettingDefaultValues = @{}
foreach ($k in $SettingDefs.Keys) { $ck = $SettingDefs[$k][0]; $SettingDefaultValues[$ck] = $Config[$ck] }

function Import-UserSettings {
    # Resets to defaults, then applies settings.txt. Returns warning lines (also kept in
    # $script:SettingsWarnings); $script:SettingsLoaded lists what was applied.
    foreach ($ck in @($SettingDefaultValues.Keys)) { $Config[$ck] = $SettingDefaultValues[$ck] }
    if ($script:LogoImage) { try { $script:LogoImage.Dispose() } catch {}; $script:LogoImage = $null }
    $warn = New-Object System.Collections.ArrayList
    $loaded = New-Object System.Collections.ArrayList
    if (Test-Path -LiteralPath $SettingsFile -PathType Leaf) {
        $n = 0
        foreach ($raw in [System.IO.File]::ReadAllLines($SettingsFile)) {
            $n++
            $line = $raw.Trim()
            if (-not $line -or $line.StartsWith('#') -or $line.StartsWith(';')) { continue }
            $eq = $line.IndexOf('=')
            if ($eq -lt 1) { [void]$warn.Add("line ${n}: '$line' is not 'Name = value'"); continue }
            $name = $line.Substring(0, $eq).Trim()
            $val = $line.Substring($eq + 1).Trim()          # trim FIRST so "#FFEF00" isn't read as a comment
            $hash = $val.IndexOf(' #')                       # trailing comment: "value   # note"
            if ($hash -ge 0 -and $name -ne 'TextFormat') { $val = $val.Substring(0, $hash) }
            $val = $val.Trim().Trim('"').Trim("'")
            $key = @($SettingDefs.Keys | Where-Object { $_ -eq $name })   # case-insensitive
            if ($key.Count -eq 0) { [void]$warn.Add("line ${n}: unknown setting '$name'"); continue }
            $d = $SettingDefs[$key[0]]; $ck = $d[0]; $kind = $d[1]; $extra = $d[2]
            if ($val -eq '') { continue }                                   # blank = default
            $ok = $true; $v = $null
            if ($kind -eq 'text') { $v = $val }
            elseif ($kind -eq 'choice') {
                $m = @($extra | Where-Object { $_ -eq $val })
                if ($m.Count) { $v = $m[0] } else { $ok = $false; [void]$warn.Add("line ${n}: $name must be one of " + ($extra -join ', ')) }
            } elseif ($kind -eq 'percent' -or $kind -eq 'number') {
                $num = 0.0
                if ([double]::TryParse(($val -replace '%', '').Trim(), [System.Globalization.NumberStyles]::Float, $Inv, [ref]$num) -and $num -ge $extra[0] -and $num -le $extra[1]) {
                    $v = if ($kind -eq 'percent') { $num / 100.0 } else { [int][Math]::Round($num) }
                } else { $ok = $false; [void]$warn.Add("line ${n}: $name must be a number from $($extra[0]) to $($extra[1])") }
            } elseif ($kind -eq 'color') {
                $c = if ($val -match '^[0-9a-fA-F]{6}$') { '#' + $val } else { $val }
                try { [void][System.Drawing.ColorTranslator]::FromHtml($c); $v = $c }
                catch { $ok = $false; [void]$warn.Add("line ${n}: $name '$val' is not a colour (use e.g. #FFEF00 or Black)") }
            } elseif ($kind -eq 'font') {
                $fams = @((New-Object System.Drawing.Text.InstalledFontCollection).Families | ForEach-Object { $_.Name })
                $m = @($fams | Where-Object { $_ -eq $val })
                if ($m.Count) { $v = $m[0] } else { $ok = $false; [void]$warn.Add("line ${n}: font '$val' is not installed on this PC") }
            } elseif ($kind -eq 'bool') {
                if ($val -match '^(true|yes|on|1)$') { $v = $true } elseif ($val -match '^(false|no|off|0)$') { $v = $false }
                else { $ok = $false; [void]$warn.Add("line ${n}: $name must be true or false") }
            }
            if ($ok) { $Config[$ck] = $v; [void]$loaded.Add("$($key[0]) = $val") }
        }
    }
    if ($Config.LogoFile -and $Config.LogoFile -ne 'logo.png' -and -not (Get-LogoPath)) {
        [void]$warn.Add("LogoFile '$($Config.LogoFile)' was not found in the project folder - using the built-in logo")
    }
    $script:SettingsWarnings = $warn.ToArray(); $script:SettingsLoaded = $loaded.ToArray()
    return , $script:SettingsWarnings
}

function Show-SettingsWarnings {
    if (@($script:SettingsWarnings).Count -eq 0) { return }
    Show-Msg ("Some lines in settings.txt were ignored (defaults used instead):`r`n`r`n  " + ($script:SettingsWarnings -join "`r`n  ") +
        "`r`n`r`nFile: $SettingsFile") 'Warning' | Out-Null
}

$SettingsTemplate = @'
# ES TLINE PTOOL - settings.txt
# Optional. Keep this file in the project folder (next to ES TLINE PTOOL.ps1).
# Remove the # at the start of a line and change the value to use it.
# Lines that stay commented out (or are deleted) use the default shown.
# Changes apply the next time you click Process Photos. Already-saved photos are not changed.
# NOTE: the defaults match the Eversource photo spec - check before changing them.

# --- Logo ---
# LogoFile = logo.png          # image in the project folder (PNG with transparency works best)
# LogoPosition = TopRight      # TopRight, TopLeft, BottomRight, BottomLeft or None
# LogoSize = 7                 # logo width, % of the photo's longer side (1-50)
# LogoMargin = 1.5             # gap from the edge, % of the photo's shorter side (0-20)
# LogoOpacity = 100            # 0-100 (100 = solid)

# --- Caption bar ---
# BarPosition = Bottom         # Bottom or Top (the bar is added - it never covers the photo)
# BarHeight = 5                # % of the photo's shorter side (1-30)
# BarColor = #000000

# --- Caption text ---
# TextColor = #FFEF00
# Font = Segoe UI              # any font installed on this PC
# FontBold = true              # true or false
# TextAlign = Center           # Center, Left or Right
# TextWidth = 96               # max text width, % of the photo width (30-100); text shrinks to fit
# TextFormat = {NAME} // LAT: {LAT} // LONG: {LONG}
#     placeholders: {NAME} file name, {STRUCTURE} e.g. Str 1234, {LAT} {LONG} coordinates,
#                   {DATE} date taken
# CoordDecimals = 6            # decimal places for coordinates (4-8)

# --- Saved file ---
# JpegQuality = 92             # 50-100
'@

[void](Import-UserSettings)
#endregion

#region ------------------------------------- MAIN FORM ----------------------------------------
$form = New-Object System.Windows.Forms.Form
$form.Text = "$($Config.ToolName) v$($Config.ToolVersion) - Eversource Transmission Line Photo Tool"
$form.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
$form.ClientSize = New-Object System.Drawing.Size(1192, 772)
$form.MinimumSize = New-Object System.Drawing.Size(1010, 680)
$form.StartPosition = 'CenterScreen'
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$appIcon = Get-AppIcon
if ($appIcon) { $form.Icon = $appIcon }
$form.Font = New-Object System.Drawing.Font('Segoe UI', 9)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Dock = 'Fill'
$pageStatus = New-Object System.Windows.Forms.TabPage
$pageStatus.Text = '  Project Status  '
$pageProc = New-Object System.Windows.Forms.TabPage
$pageProc.Text = '  Process Photos  '
$tabs.TabPages.Add($pageStatus); $tabs.TabPages.Add($pageProc)
$form.Controls.Add($tabs)
# Give pages their real size BEFORE adding anchored controls (anchors are relative to it).
$pageProc.Size = New-Object System.Drawing.Size(1184, 744)
$pageStatus.Size = New-Object System.Drawing.Size(1184, 744)

$fontBold = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$ttip = New-Object System.Windows.Forms.ToolTip

function Add-Label([string]$Text, [int]$X, [int]$Y, [int]$W = 300, [int]$H = 20, [bool]$Bold = $false) {
    $l = New-Object System.Windows.Forms.Label
    $l.Text = $Text; $l.Location = New-Object System.Drawing.Point($X, $Y); $l.Size = New-Object System.Drawing.Size($W, $H)
    if ($Bold) { $l.Font = $fontBold }
    $pageProc.Controls.Add($l); return $l
}

# Logo in the header
$pbLogo = New-Object System.Windows.Forms.PictureBox
$pbLogo.Location = New-Object System.Drawing.Point(12, 10); $pbLogo.Size = New-Object System.Drawing.Size(70, 62)
$pbLogo.SizeMode = 'Zoom'
try { $pbLogo.Image = Get-Logo } catch {}
$pageProc.Controls.Add($pbLogo)
$hdr = Add-Label 'ES TLINE PTOOL' 90 14 230 26 $true
$hdr.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$lblVer = Add-Label "Eversource structure photos  -  v$($Config.ToolVersion)" 92 42 230 20
$lblVer.ForeColor = [System.Drawing.Color]::DimGray

[void](Add-Label 'Structure #' 12 84 310 20 $true)
$txtStr = New-Object System.Windows.Forms.TextBox
$txtStr.Location = New-Object System.Drawing.Point(12, 104); $txtStr.Size = New-Object System.Drawing.Size(310, 24)
$txtStr.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$pageProc.Controls.Add($txtStr)

$grpType = New-Object System.Windows.Forms.GroupBox
$grpType.Text = 'Photo set'; $grpType.Font = $fontBold
$grpType.Location = New-Object System.Drawing.Point(12, 140); $grpType.Size = New-Object System.Drawing.Size(310, 74)
$rbExisting = New-Object System.Windows.Forms.RadioButton
$rbExisting.Text = 'Existing structure  (Before)'; $rbExisting.Font = $form.Font
$rbExisting.Location = New-Object System.Drawing.Point(12, 20); $rbExisting.Size = New-Object System.Drawing.Size(280, 22)
$rbReplace = New-Object System.Windows.Forms.RadioButton
$rbReplace.Text = 'Replacement structure  (After)'; $rbReplace.Font = $form.Font
$rbReplace.Location = New-Object System.Drawing.Point(12, 44); $rbReplace.Size = New-Object System.Drawing.Size(280, 22)
$grpType.Controls.Add($rbExisting); $grpType.Controls.Add($rbReplace)
$pageProc.Controls.Add($grpType)

$chkCross = New-Object System.Windows.Forms.CheckBox
$chkCross.Text = 'Cross Brace / Cross Arm present  (photo #3)'; $chkCross.Checked = $true
$chkCross.Location = New-Object System.Drawing.Point(14, 222); $chkCross.Size = New-Object System.Drawing.Size(310, 22)
$pageProc.Controls.Add($chkCross)
$chkX = New-Object System.Windows.Forms.CheckBox
$chkX.Text = 'X-Bracing present  (photo #4)'; $chkX.Checked = $true
$chkX.Location = New-Object System.Drawing.Point(14, 246); $chkX.Size = New-Object System.Drawing.Size(310, 22)
$pageProc.Controls.Add($chkX)

# Anomaly counts side by side
[void](Add-Label 'Ahead (AH) anomalies' 12 278 150 20 $true)
$nudAh = New-Object System.Windows.Forms.NumericUpDown
$nudAh.Location = New-Object System.Drawing.Point(12, 298); $nudAh.Size = New-Object System.Drawing.Size(80, 24)
$nudAh.Minimum = 0; $nudAh.Maximum = 99; $nudAh.Value = 0
$pageProc.Controls.Add($nudAh)
[void](Add-Label 'Back (BK) anomalies' 172 278 150 20 $true)
$nudBk = New-Object System.Windows.Forms.NumericUpDown
$nudBk.Location = New-Object System.Drawing.Point(172, 298); $nudBk.Size = New-Object System.Drawing.Size(80, 24)
$nudBk.Minimum = 0; $nudBk.Maximum = 99; $nudBk.Value = 0
$pageProc.Controls.Add($nudBk)

$lblExpected = Add-Label '' 12 334 310 100 $false
$lblExpected.BorderStyle = 'FixedSingle'; $lblExpected.Padding = New-Object System.Windows.Forms.Padding(6)
$lblExpected.Font = New-Object System.Drawing.Font('Consolas', 9.5)
# Grow to fit its 5 lines at any screen size / DPI (fixed width, automatic height)
$lblExpected.AutoSize = $true
$lblExpected.MinimumSize = New-Object System.Drawing.Size(310, 0)
$lblExpected.MaximumSize = New-Object System.Drawing.Size(310, 0)

# Shooting-order guide: scrollable box that fills the space between the photo counts and the
# progress bar (Set-ProcLayout keeps it from overlapping the status text on small screens).
$rtbHelp = New-Object System.Windows.Forms.RichTextBox
$rtbHelp.ReadOnly = $true; $rtbHelp.DetectUrls = $false; $rtbHelp.ShortcutsEnabled = $true
$rtbHelp.BorderStyle = 'FixedSingle'; $rtbHelp.ScrollBars = 'Vertical'; $rtbHelp.WordWrap = $true
$rtbHelp.BackColor = [System.Drawing.Color]::FromArgb(250, 250, 250); $rtbHelp.TabStop = $false
$rtbHelp.Location = New-Object System.Drawing.Point(12, 450); $rtbHelp.Size = New-Object System.Drawing.Size(310, 190)
$pageProc.Controls.Add($rtbHelp)

$hFontH = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
$hFontT = New-Object System.Drawing.Font('Segoe UI', 9)
$hFontB = New-Object System.Drawing.Font('Segoe UI', 9, [System.Drawing.FontStyle]::Bold)
$hGray = [System.Drawing.Color]::DimGray
$hBlue = [System.Drawing.Color]::FromArgb(0, 70, 140)
function Add-HelpText([string]$Text, $Font, [System.Drawing.Color]$Color = [System.Drawing.Color]::Black) {
    # A plain paragraph
    $rtbHelp.SelectionStart = $rtbHelp.TextLength; $rtbHelp.SelectionLength = 0
    $rtbHelp.SelectionIndent = 2; $rtbHelp.SelectionHangingIndent = 0
    $rtbHelp.SelectionFont = $Font; $rtbHelp.SelectionColor = $Color
    $rtbHelp.AppendText($Text + "`n")
}
function Add-HelpRow([string]$Key, [string]$Text, [System.Drawing.Color]$Color = [System.Drawing.Color]::Black) {
    # "key <tab> text" with wrapped lines aligned under the text
    $rtbHelp.SelectionStart = $rtbHelp.TextLength; $rtbHelp.SelectionLength = 0
    $rtbHelp.SelectionIndent = 2; $rtbHelp.SelectionHangingIndent = 28
    try { $rtbHelp.SelectionTabs = [int[]]@(30) } catch {}
    $rtbHelp.SelectionFont = $hFontB; $rtbHelp.SelectionColor = $Color
    $rtbHelp.AppendText($Key + "`t")
    $rtbHelp.SelectionFont = $hFontT; $rtbHelp.SelectionColor = $Color
    $rtbHelp.AppendText($Text + "`n")
}
Add-HelpText 'Shooting order' $hFontH $hBlue
Add-HelpText 'Ahead span (AH) first, then repeat the same list for the back span (BK).' $hFontT $hGray
Add-HelpText '' $hFontT
Add-HelpRow '1' '100 ft away, looking along the span'
Add-HelpRow '2' 'Full structure close-up'
Add-HelpRow '3' 'Cross arm / cross brace *'
Add-HelpRow '4' 'X-bracing *'
Add-HelpRow '5' 'Left insulator and attachments'
Add-HelpRow '6' 'Middle insulator and attachments'
Add-HelpRow '7' 'Right insulator and attachments'
Add-HelpRow '8' 'Left static wire attachment'
Add-HelpRow '9' 'Right static wire attachment'
Add-HelpRow '10+' 'One photo per anomaly **'
Add-HelpText '' $hFontT
Add-HelpRow '*' "Skip if the structure has none. Numbers don't shift - the next shot is still 5." $hGray
Add-HelpRow '**' 'Existing structures only.' $hGray
Add-HelpText '' $hFontT
Add-HelpText 'Before you process' $hFontH $hBlue
Add-HelpRow '-' 'Photos are sorted by time taken.'
Add-HelpRow '-' "Click a photo to preview it and check 'Will be named' matches the picture."
Add-HelpRow '-' 'The list order is the processing order. Fix it with Move Up / Move Down, Ctrl+Up / Ctrl+Down, or drag a row to its place.'
Add-HelpRow '-' 'Sideways: Rotate Left / Rotate Right under the preview.'
$rtbHelp.SelectionStart = 0; $rtbHelp.ScrollToCaret()

# Right side: drop zone + list
$lblDrop = New-Object System.Windows.Forms.Label
$lblDrop.Text = 'Drag && drop photos (or a folder of photos) here  -  or click "Add Photos..."'
$lblDrop.TextAlign = 'MiddleCenter'; $lblDrop.BorderStyle = 'FixedSingle'
$lblDrop.BackColor = [System.Drawing.Color]::FromArgb(255, 252, 210); $lblDrop.Font = $fontBold
$lblDrop.Location = New-Object System.Drawing.Point(330, 12); $lblDrop.Size = New-Object System.Drawing.Size(838, 44)
$lblDrop.Anchor = 'Top,Left,Right'; $lblDrop.AllowDrop = $true
$pageProc.Controls.Add($lblDrop)

$lv = New-Object System.Windows.Forms.ListView
$lv.View = 'Details'; $lv.FullRowSelect = $true; $lv.GridLines = $true; $lv.HideSelection = $false
$lv.MultiSelect = $true; $lv.AllowDrop = $true
$lv.Location = New-Object System.Drawing.Point(330, 62); $lv.Size = New-Object System.Drawing.Size(500, 548)
$lv.Anchor = 'Top,Bottom,Left'     # width is set by Set-ProcLayout (list + preview share the space)
# Hidden 0-width column 0 (WinForms can't centre column 0) so every visible column is centred.
[void]$lv.Columns.Add('', 0)
$lv.Add_ColumnWidthChanging({ param($s, $e) if ($e.ColumnIndex -eq 0) { $e.Cancel = $true; $e.NewWidth = 0 } })
foreach ($c in @(@('#', 34), @('Will be named', 165), @('Shot', 200), @('Source file', 130), @('Taken', 130), @('GPS', 170), @('Rotation', 70))) {
    [void]$lv.Columns.Add($c[0], $c[1], [System.Windows.Forms.HorizontalAlignment]::Center)
}
$pageProc.Controls.Add($lv)

# Photo preview pane (right of the list) - shows the selected photo upright, with any manual rotation
$grpPrev = New-Object System.Windows.Forms.GroupBox
$grpPrev.Text = 'Photo preview (select a photo)'; $grpPrev.Font = $fontBold
$grpPrev.Location = New-Object System.Drawing.Point(838, 56); $grpPrev.Size = New-Object System.Drawing.Size(334, 554)
$grpPrev.Anchor = 'Top,Bottom,Left'
$pbPrev = New-Object System.Windows.Forms.PictureBox
$pbPrev.Dock = 'Fill'; $pbPrev.SizeMode = 'Zoom'; $pbPrev.BackColor = [System.Drawing.Color]::FromArgb(45, 45, 45)
$pbPrev.Cursor = [System.Windows.Forms.Cursors]::Hand
$lblPrev = New-Object System.Windows.Forms.Label
$lblPrev.Dock = 'Top'; $lblPrev.Height = 44; $lblPrev.Font = $form.Font; $lblPrev.AutoEllipsis = $true
$lblPrev.Text = 'Select a photo in the list to see it here.'
$pnlPrevBtns = New-Object System.Windows.Forms.Panel           # bottom strip of the preview
$pnlPrevBtns.Dock = 'Bottom'; $pnlPrevBtns.Height = 40
$flowRot = New-Object System.Windows.Forms.FlowLayoutPanel      # the 3 buttons, centred in the strip
$flowRot.AutoSize = $true; $flowRot.AutoSizeMode = 'GrowAndShrink'; $flowRot.WrapContents = $false
$flowRot.Top = 4
$pnlPrevBtns.Controls.Add($flowRot)
$centerRot = { $flowRot.Left = [Math]::Max(0, [int](($pnlPrevBtns.ClientSize.Width - $flowRot.Width) / 2)) }
$pnlPrevBtns.Add_Resize($centerRot); $flowRot.Add_SizeChanged($centerRot)
$btnRotL = New-Object System.Windows.Forms.Button
$btnRotL.Text = 'Rotate Left'; $btnRotL.Size = New-Object System.Drawing.Size(100, 30); $btnRotL.Font = $form.Font
$btnRotR = New-Object System.Windows.Forms.Button
$btnRotR.Text = 'Rotate Right'; $btnRotR.Size = New-Object System.Drawing.Size(100, 30); $btnRotR.Font = $form.Font
$btnRotReset = New-Object System.Windows.Forms.Button
$btnRotReset.Text = 'Reset'; $btnRotReset.Size = New-Object System.Drawing.Size(70, 30); $btnRotReset.Font = $form.Font
$ttip.SetToolTip($btnRotL, 'Rotate the selected photo(s) 90 degrees counter-clockwise')
$ttip.SetToolTip($btnRotR, 'Rotate the selected photo(s) 90 degrees clockwise')
$ttip.SetToolTip($btnRotReset, 'Undo manual rotation for the selected photo(s)')
$ttip.SetToolTip($pbPrev, 'Double-click to open the original photo')
$flowRot.Controls.AddRange(@($btnRotL, $btnRotR, $btnRotReset))
$grpPrev.Controls.Add($pbPrev); $grpPrev.Controls.Add($lblPrev); $grpPrev.Controls.Add($pnlPrevBtns)
$pbPrev.BringToFront()   # fill the space between the caption and the buttons
$pageProc.Controls.Add($grpPrev)

function Set-ProcLayout {
    # Left column: shooting-order box fills the gap between the photo counts and the progress bar.
    if (-not $sepLine -or -not $rtbHelp -or -not $grpPrev) { return }   # still building the form
    $rtbHelp.Top = $lblExpected.Bottom + 8
    $rtbHelp.Height = [Math]::Max(48, $btnAdd.Top + $btnAdd.Height - $rtbHelp.Top)   # bottom lines up with the list buttons
    # List gets ~58% and the preview ~42% of the space right of the input column.
    $left = 330; $right = $pageProc.ClientSize.Width - 12
    $avail = $right - $left
    if ($avail -lt 500) { return }
    $pw = [int][Math]::Max(300, $avail * 0.42)
    $lvW = $avail - $pw - 8
    $lv.Width = $lvW
    $grpPrev.Left = $left + $lvW + 8; $grpPrev.Width = $pw
}
$pageProc.Add_Resize({ Set-ProcLayout })
$lblExpected.Add_SizeChanged({ Set-ProcLayout })
$tabs.Add_SelectedIndexChanged({ Set-ProcLayout })

function New-Btn([string]$Text, [int]$X, [int]$Y, [int]$W, [string]$Tip) {
    $b = New-Object System.Windows.Forms.Button
    $b.Text = $Text; $b.Location = New-Object System.Drawing.Point($X, $Y); $b.Size = New-Object System.Drawing.Size($W, 30)
    $b.Anchor = 'Bottom,Left'
    if ($Tip) { $ttip.SetToolTip($b, $Tip) }
    $pageProc.Controls.Add($b); return $b
}
$btnAdd = New-Btn 'Add Photos...' 330 618 110 'Browse for photo files'
$btnUp = New-Btn 'Move Up' 446 618 85 'Move the selected photo(s) one place earlier (Ctrl+Up). You can also drag rows to reorder.'
$btnDown = New-Btn 'Move Down' 537 618 85 'Move the selected photo(s) one place later (Ctrl+Down). You can also drag rows to reorder.'
$btnRemove = New-Btn 'Remove' 628 618 75 'Remove selected photo(s)'
$btnClear = New-Btn 'Clear All' 709 618 75 'Remove all photos'
$btnSort = New-Btn 'Sort by Time' 790 618 100 'Re-sort photos by time taken'

# Bottom strip (y 656-722): thin separator, then [status text over progress bar] | [Process button],
# the text+bar stack and the button share the same vertical centre (y = 690).
$sepLine = New-Object System.Windows.Forms.Label
$sepLine.BorderStyle = 'Fixed3D'; $sepLine.AutoSize = $false
$sepLine.Location = New-Object System.Drawing.Point(12, 656); $sepLine.Size = New-Object System.Drawing.Size(1160, 2)
$sepLine.Anchor = 'Bottom,Left,Right'
$pageProc.Controls.Add($sepLine)
$lblStatus = New-Object System.Windows.Forms.Label
$lblStatus.Location = New-Object System.Drawing.Point(12, 666); $lblStatus.Size = New-Object System.Drawing.Size(948, 22)
$lblStatus.Anchor = 'Bottom,Left,Right'; $lblStatus.TextAlign = 'MiddleLeft'; $lblStatus.AutoEllipsis = $true
$lblStatus.Text = 'Ready.'
$pageProc.Controls.Add($lblStatus)
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = New-Object System.Drawing.Point(12, 692); $progress.Size = New-Object System.Drawing.Size(948, 22)
$progress.Anchor = 'Bottom,Left,Right'
$pageProc.Controls.Add($progress)

$btnProcess = New-Object System.Windows.Forms.Button
$btnProcess.Text = 'Process Photos'; $btnProcess.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
$btnProcess.BackColor = [System.Drawing.Color]::FromArgb(255, 239, 0); $btnProcess.FlatStyle = 'Flat'
$btnProcess.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$btnProcess.Location = New-Object System.Drawing.Point(972, 662); $btnProcess.Size = New-Object System.Drawing.Size(200, 56)
$btnProcess.Anchor = 'Bottom,Right'
$pageProc.Controls.Add($btnProcess)

# ---------- Project Status tab (the grid is the focus) ----------
$stHdr = New-Object System.Windows.Forms.Label
$stHdr.Text = 'Project Status'; $stHdr.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$stHdr.Location = New-Object System.Drawing.Point(12, 8); $stHdr.Size = New-Object System.Drawing.Size(200, 30)
$pageStatus.Controls.Add($stHdr)
$stPath = New-Object System.Windows.Forms.Label
$stPath.Location = New-Object System.Drawing.Point(214, 15); $stPath.Size = New-Object System.Drawing.Size(470, 20)
$stPath.Anchor = 'Top,Left,Right'; $stPath.AutoEllipsis = $true; $stPath.ForeColor = [System.Drawing.Color]::DimGray
$stPath.Text = "Project folder: $ProjectRoot"
$pageStatus.Controls.Add($stPath)

# Colour legend = status chips with live counts
$StatusOrder = @('Complete', 'Partially Complete', 'Not Started', 'Needs Attention', 'Naming Issue')
$StatusHelp = @{
    'Complete'           = 'All four span folders done'
    'Partially Complete' = 'Existing (Before) done, Replacement (After) not yet'
    'Not Started'        = 'No photos yet'
    'Needs Attention'    = 'Missing / misnamed photos or folders - hover the row for details'
    'Naming Issue'       = "Folder or photo in the project folder that is not a 'Str ####' folder"
}
$pnlLegend = New-Object System.Windows.Forms.FlowLayoutPanel
$pnlLegend.Location = New-Object System.Drawing.Point(12, 42); $pnlLegend.Size = New-Object System.Drawing.Size(1160, 30)
$pnlLegend.Anchor = 'Top,Left,Right'; $pnlLegend.WrapContents = $false
$pageStatus.Controls.Add($pnlLegend)
$LegendChips = @{}
foreach ($k in $StatusOrder) {
    $chip = New-Object System.Windows.Forms.Label
    $chip.AutoSize = $true; $chip.Padding = New-Object System.Windows.Forms.Padding(8, 4, 8, 4)
    $chip.Margin = New-Object System.Windows.Forms.Padding(0, 0, 8, 0); $chip.BorderStyle = 'FixedSingle'
    $chip.Font = $fontBold; $chip.Text = "$k  -"
    $ttip.SetToolTip($chip, $StatusHelp[$k])
    $pnlLegend.Controls.Add($chip)
    $LegendChips[$k] = $chip
}
$lblLegendHint = New-Object System.Windows.Forms.Label
$lblLegendHint.AutoSize = $true; $lblLegendHint.ForeColor = [System.Drawing.Color]::DimGray
$lblLegendHint.Margin = New-Object System.Windows.Forms.Padding(8, 6, 0, 0)
$lblLegendHint.Text = 'Double-click a structure to process it  |  right-click for more  |  F5 re-checks'
$pnlLegend.Controls.Add($lblLegendHint)

$lvSt = New-Object System.Windows.Forms.ListView
$lvSt.View = 'Details'; $lvSt.FullRowSelect = $true; $lvSt.GridLines = $true; $lvSt.HideSelection = $false
$lvSt.MultiSelect = $false; $lvSt.ShowItemToolTips = $true
$lvSt.Location = New-Object System.Drawing.Point(12, 78); $lvSt.Size = New-Object System.Drawing.Size(1160, 654)
$lvSt.Anchor = 'Top,Bottom,Left,Right'
# Column 0 of a WinForms ListView is always left-aligned, so it is a hidden 0-width column and
# every visible column is centred. The Issues column stretches to fill the width (no blank area).
[void]$lvSt.Columns.Add('', 0)
foreach ($c in @(@('Structure', 90), @('Status', 130), @('Before taken', 170), @('After taken', 170),
        @('Bef AH', 60), @('Bef BK', 60), @('Aft AH', 60), @('Aft BK', 60), @('Photos', 60), @('Issues (hover a row for all)', 300))) {
    [void]$lvSt.Columns.Add($c[0], $c[1], [System.Windows.Forms.HorizontalAlignment]::Center)
}
$lvSt.Add_ColumnWidthChanging({ param($s, $e) if ($e.ColumnIndex -eq 0) { $e.Cancel = $true; $e.NewWidth = 0 } })
$pageStatus.Controls.Add($lvSt)
function Resize-StatusColumns {
    $last = $lvSt.Columns.Count - 1
    $used = 0
    for ($i = 0; $i -lt $last; $i++) { $used += $lvSt.Columns[$i].Width }
    $w = $lvSt.ClientSize.Width - $used - 2
    if ($w -lt 150) { $w = 150 }
    $lvSt.Columns[$last].Width = $w
}
$lvSt.Add_Resize({ Resize-StatusColumns })

# Right-click menu (replaces the old buttons)
$cmSt = New-Object System.Windows.Forms.ContextMenuStrip
$miProc = $cmSt.Items.Add('Process this structure')
$miOpen = $cmSt.Items.Add('Open structure folder')
$miRoot = $cmSt.Items.Add('Open project folder')
[void]$cmSt.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
$miCheck = $cmSt.Items.Add('Re-check all structures  (F5)')
$miStop = $cmSt.Items.Add('Stop the status check')
$miProc.Font = New-Object System.Drawing.Font($miProc.Font, [System.Drawing.FontStyle]::Bold)
$lvSt.ContextMenuStrip = $cmSt

# Result of the last check - top right of the header
$stScanLbl = New-Object System.Windows.Forms.Label
$stScanLbl.Location = New-Object System.Drawing.Point(692, 15); $stScanLbl.Size = New-Object System.Drawing.Size(480, 20)
$stScanLbl.Anchor = 'Top,Right'; $stScanLbl.TextAlign = 'TopRight'; $stScanLbl.AutoEllipsis = $true
$stScanLbl.ForeColor = [System.Drawing.Color]::DimGray; $stScanLbl.Text = 'Not checked yet.'
$pageStatus.Controls.Add($stScanLbl)

# ---------- Status-check overlay: covers the status screen while a check runs ----------
$ovPanel = New-Object System.Windows.Forms.Panel
$ovPanel.Location = New-Object System.Drawing.Point(0, 40); $ovPanel.Size = New-Object System.Drawing.Size(1184, 704)
$ovPanel.Anchor = 'Top,Bottom,Left,Right'; $ovPanel.BackColor = [System.Drawing.Color]::FromArgb(236, 236, 236)
$ovPanel.Visible = $false
$ovCard = New-Object System.Windows.Forms.Panel
$ovCard.Size = New-Object System.Drawing.Size(560, 236); $ovCard.BackColor = [System.Drawing.Color]::White
$ovCard.BorderStyle = 'FixedSingle'
$ovStripe = New-Object System.Windows.Forms.Panel               # yellow brand stripe across the top
$ovStripe.Dock = 'Top'; $ovStripe.Height = 6; $ovStripe.BackColor = [System.Drawing.Color]::FromArgb(255, 239, 0)
$ovTitle = New-Object System.Windows.Forms.Label
$ovTitle.Text = 'Checking project folders'; $ovTitle.Font = New-Object System.Drawing.Font('Segoe UI', 15, [System.Drawing.FontStyle]::Bold)
$ovTitle.Location = New-Object System.Drawing.Point(28, 22); $ovTitle.Size = New-Object System.Drawing.Size(500, 32)
$ovFolder = New-Object System.Windows.Forms.Label
$ovFolder.Font = New-Object System.Drawing.Font('Segoe UI', 11)
$ovFolder.Location = New-Object System.Drawing.Point(28, 62); $ovFolder.Size = New-Object System.Drawing.Size(500, 24)
$ovFolder.AutoEllipsis = $true; $ovFolder.Text = 'Starting...'
$stScanProg = New-Object System.Windows.Forms.ProgressBar
$stScanProg.Location = New-Object System.Drawing.Point(28, 94); $stScanProg.Size = New-Object System.Drawing.Size(502, 24)
$ovCount = New-Object System.Windows.Forms.Label
$ovCount.Font = New-Object System.Drawing.Font('Segoe UI', 9.5); $ovCount.ForeColor = [System.Drawing.Color]::DimGray
$ovCount.Location = New-Object System.Drawing.Point(28, 124); $ovCount.Size = New-Object System.Drawing.Size(502, 20)
$ovNote = New-Object System.Windows.Forms.Label
$ovNote.ForeColor = [System.Drawing.Color]::DimGray
$ovNote.Location = New-Object System.Drawing.Point(28, 150); $ovNote.Size = New-Object System.Drawing.Size(380, 40)
$ovNote.Text = "Checking photo names, dates and folders for every structure.`r`nYou can keep using the Process Photos tab meanwhile."
$ovStop = New-Object System.Windows.Forms.Button
$ovStop.Text = 'Stop'; $ovStop.Size = New-Object System.Drawing.Size(100, 32)
$ovStop.Location = New-Object System.Drawing.Point(430, 184)
$ovCard.Controls.AddRange(@($ovStripe, $ovTitle, $ovFolder, $stScanProg, $ovCount, $ovNote, $ovStop))
$ovPanel.Controls.Add($ovCard)
$centerCard = {
    $ovCard.Left = [Math]::Max(0, [int](($ovPanel.ClientSize.Width - $ovCard.Width) / 2))
    $ovCard.Top = [Math]::Max(0, [int](($ovPanel.ClientSize.Height - $ovCard.Height) / 2.5))
}
$ovPanel.Add_Resize($centerCard); $ovPanel.Add_VisibleChanged($centerCard)
$pageStatus.Controls.Add($ovPanel)
$ovPanel.BringToFront()

function Show-ScanOverlay([bool]$On) {
    if ($On) {
        $ovFolder.Text = 'Starting...'; $ovCount.Text = ''; $stScanProg.Value = 0
        $ovStop.Enabled = $true; $ovStop.Text = 'Stop'
        $ovPanel.Visible = $true; $ovPanel.BringToFront(); & $centerCard
    } else { $ovPanel.Visible = $false }
}

# ---------- Create Structure Folders tab ----------
$pageCreate = New-Object System.Windows.Forms.TabPage
$pageCreate.Text = '  Create Structure Folders  '
$tabs.TabPages.Add($pageCreate)
$pageCreate.Size = New-Object System.Drawing.Size(1184, 744)

$crHdr = New-Object System.Windows.Forms.Label
$crHdr.Text = 'Create Structure Folders'; $crHdr.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
$crHdr.Location = New-Object System.Drawing.Point(12, 8); $crHdr.Size = New-Object System.Drawing.Size(400, 30)
$pageCreate.Controls.Add($crHdr)
$crInfo = New-Object System.Windows.Forms.Label
$crInfo.Location = New-Object System.Drawing.Point(12, 42); $crInfo.Size = New-Object System.Drawing.Size(1160, 58)
$crInfo.Anchor = 'Top,Left,Right'; $crInfo.AutoEllipsis = $true
$pageCreate.Controls.Add($crInfo)
$crLbl = New-Object System.Windows.Forms.Label
$crLbl.Text = "Structure numbers - one per line (paste a column from Excel). Also OK: 8, 10, 12  or ranges like 20-25"
$crLbl.Font = $fontBold
$crLbl.Location = New-Object System.Drawing.Point(12, 106); $crLbl.Size = New-Object System.Drawing.Size(1160, 20)
$crLbl.Anchor = 'Top,Left,Right'
$pageCreate.Controls.Add($crLbl)
$txtCreate = New-Object System.Windows.Forms.TextBox
$txtCreate.Multiline = $true; $txtCreate.ScrollBars = 'Vertical'; $txtCreate.AcceptsReturn = $true; $txtCreate.WordWrap = $false
$txtCreate.Font = New-Object System.Drawing.Font('Consolas', 11)
$txtCreate.Location = New-Object System.Drawing.Point(12, 130); $txtCreate.Size = New-Object System.Drawing.Size(300, 552)
$txtCreate.Anchor = 'Top,Bottom,Left'
$pageCreate.Controls.Add($txtCreate)
$crPreview = New-Object System.Windows.Forms.TextBox
$crPreview.Multiline = $true; $crPreview.ReadOnly = $true; $crPreview.ScrollBars = 'Vertical'
$crPreview.BackColor = [System.Drawing.Color]::White
$crPreview.Font = New-Object System.Drawing.Font('Consolas', 10)
$crPreview.Location = New-Object System.Drawing.Point(324, 130); $crPreview.Size = New-Object System.Drawing.Size(848, 552)
$crPreview.Anchor = 'Top,Bottom,Left,Right'
$pageCreate.Controls.Add($crPreview)
$btnCreate = New-Object System.Windows.Forms.Button
$btnCreate.Text = 'Create Folders'; $btnCreate.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
$btnCreate.BackColor = [System.Drawing.Color]::FromArgb(255, 239, 0); $btnCreate.FlatStyle = 'Flat'
$btnCreate.Location = New-Object System.Drawing.Point(12, 692); $btnCreate.Size = New-Object System.Drawing.Size(180, 40)
$btnCreate.Anchor = 'Bottom,Left'
$pageCreate.Controls.Add($btnCreate)
$btnCreateClear = New-Object System.Windows.Forms.Button
$btnCreateClear.Text = 'Clear List'; $btnCreateClear.Location = New-Object System.Drawing.Point(200, 692); $btnCreateClear.Size = New-Object System.Drawing.Size(100, 40)
$btnCreateClear.Anchor = 'Bottom,Left'
$pageCreate.Controls.Add($btnCreateClear)
$crResult = New-Object System.Windows.Forms.Label
$crResult.Location = New-Object System.Drawing.Point(312, 694); $crResult.Size = New-Object System.Drawing.Size(860, 38)
$crResult.Anchor = 'Bottom,Left,Right'
$pageCreate.Controls.Add($crResult)

# ---------- Instructions tab ----------
$pageHelp = New-Object System.Windows.Forms.TabPage
$pageHelp.Text = '  Instructions  '
$tabs.TabPages.Add($pageHelp)
$txtHelp = New-Object System.Windows.Forms.TextBox
$txtHelp.Multiline = $true; $txtHelp.ReadOnly = $true; $txtHelp.ScrollBars = 'Vertical'
$txtHelp.Dock = 'Fill'; $txtHelp.BackColor = [System.Drawing.Color]::White
$txtHelp.Font = New-Object System.Drawing.Font('Consolas', 10.5)
$txtHelp.Text = ($InstructionsText -replace "`r?`n", "`r`n")
$pageHelp.Controls.Add($txtHelp)
# Customising: settings.txt / logo (bottom of the Instructions tab)
$pnlHelpBtns = New-Object System.Windows.Forms.Panel
$pnlHelpBtns.Dock = 'Bottom'; $pnlHelpBtns.Height = 48
$btnSettings = New-Object System.Windows.Forms.Button
$btnSettings.Size = New-Object System.Drawing.Size(200, 32); $btnSettings.Location = New-Object System.Drawing.Point(8, 8)
$lblSettings = New-Object System.Windows.Forms.Label
$lblSettings.Location = New-Object System.Drawing.Point(220, 6); $lblSettings.Size = New-Object System.Drawing.Size(940, 38)
$lblSettings.Anchor = 'Top,Left,Right'; $lblSettings.ForeColor = [System.Drawing.Color]::DimGray; $lblSettings.AutoEllipsis = $true
$pnlHelpBtns.Controls.AddRange(@($btnSettings, $lblSettings))
$pageHelp.Controls.Add($pnlHelpBtns)
$txtHelp.BringToFront()
function Update-SettingsInfo {
    $has = Test-Path -LiteralPath $SettingsFile
    $btnSettings.Text = if ($has) { 'Open settings.txt' } else { 'Create settings.txt' }
    $n = @($script:SettingsLoaded).Count; $w = @($script:SettingsWarnings).Count
    $line2 = if ($has) { "settings.txt: $n custom setting(s) in use" + $(if ($w) { ", $w problem(s) - see the warning when you process" } else { '' }) } else { 'No settings.txt - using the standard (ES spec) look.' }
    $lblSettings.Text = "Logo on photos: $($script:LogoSource)`r`n$line2"
}
$btnSettings.Add_Click({
        if (-not (Test-Path -LiteralPath $SettingsFile)) {
            try {
                # CreateNew = never overwrites an existing file
                $fs = New-Object System.IO.FileStream($SettingsFile, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
                $bytes = [System.Text.Encoding]::UTF8.GetBytes(($SettingsTemplate -replace "`r?`n", "`r`n"))
                $fs.Write($bytes, 0, $bytes.Length); $fs.Dispose()
            } catch { Show-Msg "Could not create settings.txt:`r`n$($_.Exception.Message)" 'Warning' | Out-Null; return }
        }
        try { Start-Process notepad.exe -ArgumentList "`"$SettingsFile`"" } catch {}
        Update-SettingsInfo
    })
$tabs.Add_SelectedIndexChanged({ if ($tabs.SelectedTab -eq $pageHelp) { try { [void](Import-UserSettings); [void](Get-Logo); Update-SettingsInfo } catch {} } })
#endregion

#region ------------------------------------- UI LOGIC -----------------------------------------
function Get-Options {
    $stage = if ($rbExisting.Checked) { 'Before' } elseif ($rbReplace.Checked) { 'After' } else { '?' }
    $anomOk = ($stage -ne 'After') -or $Config.AllowAnomaliesOnReplacement
    $str = $txtStr.Text.Trim()
    [pscustomobject]@{
        StrText  = $str
        StrLabel = if ($str) { $str } else { '#' }
        Stage    = $stage
        CrossArm = $chkCross.Checked
        XBrace   = $chkX.Checked
        AhAnom   = if ($anomOk) { [int]$nudAh.Value } else { 0 }
        BkAnom   = if ($anomOk) { [int]$nudBk.Value } else { 0 }
    }
}

function Get-CurrentSlots($o) {
    return @(Get-PhotoSlots -StrLabel $o.StrLabel -Stage $o.Stage -CrossArm $o.CrossArm -XBrace $o.XBrace -AhAnom $o.AhAnom -BkAnom $o.BkAnom)
}

function Update-PhotoList([int[]]$Select = @()) {
    $o = Get-Options
    $slots = Get-CurrentSlots $o
    $ah = @($slots | Where-Object { $_.Span -eq 'AH' }).Count
    $bk = @($slots | Where-Object { $_.Span -eq 'BK' }).Count
    $n = $script:Photos.Count
    $noGps = @($script:Photos | Where-Object { -not $_.HasGps }).Count
    $lblExpected.Text = ("Expected photos : {0,3}`r`n  Ahead  (AH)   : {1,3}`r`n  Back   (BK)   : {2,3}`r`nLoaded          : {3,3}`r`nMissing GPS     : {4,3}" -f $slots.Count, $ah, $bk, $n, $noGps)
    $lblExpected.ForeColor = if ($n -eq $slots.Count -and $noGps -eq 0 -and $n -gt 0) { [System.Drawing.Color]::DarkGreen } else { [System.Drawing.Color]::Firebrick }

    $lv.BeginUpdate()
    $lv.Items.Clear()
    for ($i = 0; $i -lt $n; $i++) {
        $p = $script:Photos[$i]
        $slotName = '(EXTRA - remove)'; $slotDesc = ''
        if ($i -lt $slots.Count) { $slotName = $slots[$i].Name; $slotDesc = $slots[$i].Desc }
        $gps = if ($p.HasGps) { '{0}, {1}' -f (Format-Coord $p.Lat), (Format-Coord $p.Lon) } else { 'MISSING' }
        $taken = $p.Taken.ToString('MMM d, yyyy  h:mm:ss tt', $Inv) -replace '  ', ' '
        if ($p.TakenSource -ne 'EXIF') { $taken += ' (file)' }
        $item = New-Object System.Windows.Forms.ListViewItem('')        # hidden column 0
        [void]$item.SubItems.Add([string]($i + 1))                         # '#' 
        $rotTxt = switch ([int]$p.ExtraRotation) { 90 { 'Right 90' } 180 { '180' } 270 { 'Left 90' } default { '' } }
        foreach ($s in @($slotName, $slotDesc, $p.FileName, $taken, $gps, $rotTxt)) { [void]$item.SubItems.Add([string]$s) }
        if (-not $p.HasGps -or $i -ge $slots.Count -or $p.Error) { $item.ForeColor = [System.Drawing.Color]::Firebrick }
        if ($p.Error) { $item.ToolTipText = $p.Error }
        [void]$lv.Items.Add($item)
    }
    $lv.EndUpdate()
    foreach ($s in $Select) { if ($s -ge 0 -and $s -lt $lv.Items.Count) { $lv.Items[$s].Selected = $true; $lv.Items[$s].Focused = $true; $lv.EnsureVisible($s) } }
    # refresh the preview (names/shots change when the list changes)
    if (Get-Variable -Name prevTimer -Scope Script -ErrorAction SilentlyContinue) { $prevTimer.Stop(); $prevTimer.Start() }
    if ($n -lt $slots.Count) {
        $next = $slots[$n]
        $lblStatus.Text = "Next expected photo: #$($n + 1)  $($next.Name)  -  $($next.Desc)"
    } elseif ($n -eq $slots.Count -and $n -gt 0) { $lblStatus.Text = 'Photo count matches. Review the list, then click Process Photos.' }
    else { $lblStatus.Text = "Too many photos: $n loaded, $($slots.Count) expected. Check anomaly counts / bracing options or remove extras." }
}

function Sort-Photos {
    $sorted = @($script:Photos | Sort-Object -Property @{ Expression = { $_.Taken } }, @{ Expression = { $_.FileName } })
    $script:Photos.Clear()
    foreach ($p in $sorted) { [void]$script:Photos.Add($p) }
}

function Add-Photos([string[]]$Paths) {
    $files = New-Object System.Collections.ArrayList
    foreach ($p in $Paths) {
        if (Test-Path -LiteralPath $p -PathType Container) {
            Get-ChildItem -LiteralPath $p -File | Where-Object { $Config.Extensions -contains $_.Extension.ToLower() } |
                ForEach-Object { [void]$files.Add($_.FullName) }
        } elseif (Test-Path -LiteralPath $p -PathType Leaf) {
            if ($Config.Extensions -contains ([System.IO.Path]::GetExtension($p).ToLower())) { [void]$files.Add($p) }
        }
    }
    $existing = @($script:Photos | ForEach-Object { $_.Path.ToLower() })
    $new = @($files | Where-Object { $existing -notcontains $_.ToLower() } | Select-Object -Unique)
    if ($new.Count -eq 0) { $lblStatus.Text = 'No new supported photos found (jpg, jpeg, png, tif, heic).'; return }
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    $progress.Maximum = $new.Count; $progress.Value = 0
    $i = 0
    foreach ($f in $new) {
        $i++
        $lblStatus.Text = "Reading $i / $($new.Count): $([System.IO.Path]::GetFileName($f))"
        [System.Windows.Forms.Application]::DoEvents()
        [void]$script:Photos.Add((Get-PhotoMeta $f))
        $progress.Value = $i
    }
    $form.Cursor = [System.Windows.Forms.Cursors]::Default
    if ($script:ManualOrder -and $script:Photos.Count -gt $new.Count) {
        # keep the user's order; new photos (sorted by time among themselves) go at the end
        $added = @($script:Photos | Select-Object -Last $new.Count | Sort-Object @{ Expression = { $_.Taken } }, @{ Expression = { $_.FileName } })
        $script:Photos.RemoveRange($script:Photos.Count - $new.Count, $new.Count)
        foreach ($p in $added) { [void]$script:Photos.Add($p) }
        Update-PhotoList
        $lblStatus.Text = "Added $($new.Count) photo(s) at the END to keep your order - move them into place, or click Sort by Time."
    } else {
        Sort-Photos
        $script:ManualOrder = $false
        Update-PhotoList
    }
}

function Get-SelectedIdx { return @($lv.SelectedIndices | ForEach-Object { [int]$_ } | Sort-Object) }

$dragEnter = {
    param($s, $e)
    if ($e.Data.GetDataPresent('ES_PTOOL_ROWS')) { $e.Effect = if ($s -eq $lv) { [System.Windows.Forms.DragDropEffects]::Move } else { [System.Windows.Forms.DragDropEffects]::None } }
    elseif ($e.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) { $e.Effect = [System.Windows.Forms.DragDropEffects]::Copy }
    else { $e.Effect = [System.Windows.Forms.DragDropEffects]::None }
}
$dragDrop = {
    param($s, $e)
    if ($e.Data.GetDataPresent('ES_PTOOL_ROWS')) {
        if ($s -ne $lv) { return }
        # re-order rows dragged inside the list
        $pt = $lv.PointToClient((New-Object System.Drawing.Point($e.X, $e.Y)))
        $hit = $lv.HitTest($pt)
        $target = if ($hit.Item) { $hit.Item.Index } else { $script:Photos.Count - 1 }
        Move-PhotosTo @(Get-SelectedIdx) $target
        return
    }
    $paths = [string[]]$e.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    if ($paths) { Add-Photos $paths }
    else { Show-Msg "Nothing could be read from that drop.`r`nIf dragging straight from a phone, copy the photos to the PC first." 'Warning' | Out-Null }
}
$lv.Add_DragEnter($dragEnter); $lv.Add_DragDrop($dragDrop)
$lv.Add_DragOver($dragEnter)
# start dragging selected rows (only within the list - drop on a row to move them there)
$lv.Add_ItemDrag({
        param($s, $e)
        if (@(Get-SelectedIdx).Count -gt 0) {
            $do = New-Object System.Windows.Forms.DataObject('ES_PTOOL_ROWS', 'rows')
            [void]$lv.DoDragDrop($do, [System.Windows.Forms.DragDropEffects]::Move)
        }
    })
$lblDrop.Add_DragEnter($dragEnter); $lblDrop.Add_DragDrop($dragDrop)

$btnAdd.Add_Click({
        $ofd = New-Object System.Windows.Forms.OpenFileDialog
        $ofd.Multiselect = $true; $ofd.Title = 'Select structure photos'
        $ofd.Filter = 'Photos (*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.heic;*.heif)|*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.heic;*.heif|All files (*.*)|*.*'
        if ($ofd.ShowDialog($form) -eq 'OK') { Add-Photos $ofd.FileNames }
    })
$script:ManualOrder = $false     # true once the user re-orders by hand (adding photos won't re-sort)

function Get-SlotLabel([int]$Index) {
    $slots = Get-CurrentSlots (Get-Options)
    if ($Index -lt $slots.Count) { return "#$($Index + 1)  $($slots[$Index].Name)  ($($slots[$Index].Desc))" }
    return "#$($Index + 1)  (extra - not used)"
}

function Complete-Reorder([int[]]$NewSel, [string]$What) {
    $script:ManualOrder = $true
    Update-PhotoList $NewSel
    [void]$lv.Focus()
    $prevTimer.Stop(); Show-PhotoPreview
    $lblStatus.Text = $What
}

function Move-Photo([int]$Dir) {
    # Move the selected photo(s) up (-1) or down (+1) one place. The list order IS the
    # processing order: photo N gets name/shot N. Selection follows the moved photos.
    $sel = @(Get-SelectedIdx)
    if ($sel.Count -eq 0) { $lblStatus.Text = 'Select a photo first, then use Move Up / Move Down.'; return }
    $isSel = @{}; foreach ($i in $sel) { $isSel[$i] = $true }
    $order = if ($Dir -lt 0) { $sel } else { @($sel | Sort-Object -Descending) }
    $moved = $false
    foreach ($i in $order) {
        $j = $i + $Dir
        if ($j -lt 0 -or $j -ge $script:Photos.Count -or $isSel.ContainsKey($j)) { continue }   # blocked at the edge / by another selected photo
        $t = $script:Photos[$i]; $script:Photos[$i] = $script:Photos[$j]; $script:Photos[$j] = $t
        $isSel.Remove($i); $isSel[$j] = $true
        $moved = $true
    }
    if (-not $moved) { $lblStatus.Text = 'Already at the ' + $(if ($Dir -lt 0) { 'top' } else { 'bottom' }) + '.'; return }
    $newSel = @($isSel.Keys | ForEach-Object { [int]$_ } | Sort-Object)
    $msg = if ($newSel.Count -eq 1) { "Moved $($script:Photos[$newSel[0]].FileName) to " + (Get-SlotLabel $newSel[0]) } else { "Moved $($newSel.Count) photos " + $(if ($Dir -lt 0) { 'up' } else { 'down' }) }
    Complete-Reorder $newSel $msg
}

function Move-PhotosTo([int[]]$Sel, [int]$Target) {
    # Drag & drop inside the list: move the selected photos so they land at the drop row.
    $Sel = @($Sel | Sort-Object)
    if ($Sel.Count -eq 0) { return }
    $items = @($Sel | ForEach-Object { $script:Photos[$_] })
    $before = @($Sel | Where-Object { $_ -lt $Target }).Count
    for ($k = $Sel.Count - 1; $k -ge 0; $k--) { $script:Photos.RemoveAt($Sel[$k]) }
    $ins = $Target - $before
    if ($Target -gt $Sel[0]) { $ins += 1 }                       # dragging down: land after the target row
    $ins = [Math]::Max(0, [Math]::Min($ins, $script:Photos.Count))
    $script:Photos.InsertRange($ins, [object[]]$items)
    $newSel = @(0..($items.Count - 1) | ForEach-Object { $ins + $_ })
    $msg = if ($items.Count -eq 1) { "Moved $($items[0].FileName) to " + (Get-SlotLabel $ins) } else { "Moved $($items.Count) photos to #$($ins + 1)" }
    Complete-Reorder $newSel $msg
}
$btnUp.Add_Click({ Move-Photo -1 })
$btnDown.Add_Click({ Move-Photo 1 })
function Set-PreviewImage($Bmp) {
    $old = $pbPrev.Image
    $pbPrev.Image = $Bmp
    if ($old) { $old.Dispose() }
}

function Show-PhotoPreview {
    $sel = @(Get-SelectedIdx)
    if ($sel.Count -ne 1) {
        Set-PreviewImage $null
        $grpPrev.Text = 'Photo preview'
        $lblPrev.Text = if ($sel.Count -gt 1) { "$($sel.Count) photos selected - select one to preview it. Rotate buttons apply to all selected." } else { 'Select a photo in the list to see it here.' }
        return
    }
    $i = $sel[0]; $p = $script:Photos[$i]
    $slots = Get-CurrentSlots (Get-Options)
    $slotTxt = if ($i -lt $slots.Count) { "$($slots[$i].Name)   [$($slots[$i].Desc)]" } else { '(EXTRA - remove)' }
    $grpPrev.Text = "Photo preview  -  #$($i + 1)"
    $rotName = switch ([int]$p.ExtraRotation) { 90 { 'right 90' } 180 { '180' } 270 { 'left 90' } default { '' } }
    $rot = if ($rotName) { "   |   rotated $rotName" } else { '' }
    $gpsTxt = if ($p.HasGps) { "   |   LAT $(Format-Coord $p.Lat)  LONG $(Format-Coord $p.Lon)" } else { '   |   NO GPS' }
    $lblPrev.Text = "$slotTxt`r`n$($p.FileName)$gpsTxt$rot"
    $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        $t = Get-PhotoThumb $p
        $b = New-Object System.Drawing.Bitmap($t)
        if ($ExtraRotateMap.ContainsKey([int]$p.ExtraRotation)) { $b.RotateFlip([System.Drawing.RotateFlipType]$ExtraRotateMap[[int]$p.ExtraRotation]) }
        Set-PreviewImage $b
    } catch {
        Set-PreviewImage $null
        $lblPrev.Text = "$slotTxt`r`nPreview not available: $($_.Exception.Message)"
    } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
}

function Add-Rotation([int]$Degrees) {
    $sel = @(Get-SelectedIdx)
    if ($sel.Count -eq 0) { $lblPrev.Text = 'Select a photo first.'; return }
    foreach ($i in $sel) { $script:Photos[$i].ExtraRotation = ($script:Photos[$i].ExtraRotation + $Degrees + 360) % 360 }
    Update-PhotoList $sel; $lv.Focus()
    Show-PhotoPreview
}

# Debounce: wait until the selection settles before decoding a photo
$prevTimer = New-Object System.Windows.Forms.Timer
$prevTimer.Interval = 150
$prevTimer.Add_Tick({ $prevTimer.Stop(); Show-PhotoPreview })
$lv.Add_SelectedIndexChanged({ $prevTimer.Stop(); $prevTimer.Start() })
$btnRotL.Add_Click({ Add-Rotation 270 })
$btnRotR.Add_Click({ Add-Rotation 90 })
$btnRotReset.Add_Click({
        foreach ($i in @(Get-SelectedIdx)) { $script:Photos[$i].ExtraRotation = 0 }
        $sel = @(Get-SelectedIdx); Update-PhotoList $sel; $lv.Focus(); Show-PhotoPreview
    })
$pbPrev.Add_DoubleClick({
        $sel = @(Get-SelectedIdx)
        if ($sel.Count -eq 1) { try { Start-Process -FilePath $script:Photos[$sel[0]].Path } catch {} }
    })

$btnRemove.Add_Click({
        $sel = @(Get-SelectedIdx)
        foreach ($i in ($sel | Sort-Object -Descending)) { Clear-PhotoThumbs $script:Photos[$i]; $script:Photos.RemoveAt($i) }
        Update-PhotoList
    })
$btnClear.Add_Click({ Clear-PhotoThumbs $script:Photos; $script:Photos.Clear(); $script:ManualOrder = $false; Update-PhotoList })
$btnSort.Add_Click({
        if ($script:ManualOrder -and (Show-Msg 'Sort by time taken? This undoes the order you set by hand.' 'Question' 'YesNo') -ne 'Yes') { return }
        Sort-Photos; $script:ManualOrder = $false; Update-PhotoList
        $lblStatus.Text = 'Photos sorted by time taken.'
    })
$lv.Add_DoubleClick({
        $sel = @(Get-SelectedIdx)
        if ($sel.Count -ge 1) { try { Start-Process -FilePath $script:Photos[$sel[0]].Path } catch {} }
    })
$lv.Add_KeyDown({
        param($s, $e)
        if ($e.KeyCode -eq 'Delete') { $btnRemove.PerformClick() }
        elseif ($e.Control -and $e.KeyCode -eq 'Up') { Move-Photo -1; $e.Handled = $true }
        elseif ($e.Control -and $e.KeyCode -eq 'Down') { Move-Photo 1; $e.Handled = $true }
    })

$txtStr.Add_KeyPress({ param($s, $e) if (-not [char]::IsDigit($e.KeyChar) -and -not [char]::IsControl($e.KeyChar)) { $e.Handled = $true } })
$txtStr.Add_TextChanged({ Update-PhotoList })
# ---------- Replacement: set Cross Brace / X-Bracing from the saved Before photos ----------
$CrossText = $chkCross.Text; $XText = $chkX.Text
$script:BracingFor = $null
function Get-BeforeBracing([string]$StrDir) {
    # Looks for shot #3 / #4 among the saved Existing (Before) photos of this structure.
    $r = [pscustomobject]@{ Found = $false; Cross = $false; X = $false }
    if (-not $StrDir -or -not (Test-Path -LiteralPath $StrDir -PathType Container)) { return $r }
    $nums = @{}
    foreach ($name in @((Get-SpanFolderName 'Before AH'), (Get-SpanFolderName 'Before BK'), 'Before AH', 'Before BK')) {
        $d = Join-Path $StrDir $name
        if (-not (Test-Path -LiteralPath $d -PathType Container)) { continue }
        foreach ($f in @(Get-ChildItem -LiteralPath $d -File -ErrorAction SilentlyContinue)) {
            if ($f.BaseName -match '^Str\s*#?\s*\d+\s*-\s*(\d+)\s+Before\s+(AH|BK)$') { $r.Found = $true; $nums[[int]$Matches[1]] = $true }
        }
    }
    $r.Cross = $nums.ContainsKey(3); $r.X = $nums.ContainsKey(4)
    return $r
}
function Set-BracingFromBefore {
    # Applied once each time Replacement is chosen for a structure; the user can still change it.
    $str = $txtStr.Text.Trim()
    if (-not $rbReplace.Checked -or $str -notmatch '^\d+$' -or $Config.RenumberSequential) {
        $script:BracingFor = $null
        $chkCross.Text = $CrossText; $chkX.Text = $XText
        $ttip.SetToolTip($chkCross, ''); $ttip.SetToolTip($chkX, '')
        return
    }
    if ($script:BracingFor -eq $str) { return }
    $script:BracingFor = $str
    $b = Get-BeforeBracing (Get-StructureDir $str)
    if (-not $b.Found) {
        $chkCross.Text = $CrossText; $chkX.Text = $XText
        return
    }
    $chkCross.Checked = $b.Cross; $chkX.Checked = $b.X
    $chkCross.Text = "$CrossText - from Before"; $chkX.Text = "$XText - from Before"
    $tip = "Set automatically: the saved Existing (Before) photos for Str $str " +
    $(if ($b.Cross) { 'include' } else { 'have no' }) + ' a #3 cross arm photo and ' +
    $(if ($b.X) { 'include' } else { 'have no' }) + ' a #4 x-bracing photo. You can still change it.'
    $ttip.SetToolTip($chkCross, $tip); $ttip.SetToolTip($chkX, $tip)
}

$onTypeChange = {
    $allow = -not $rbReplace.Checked -or $Config.AllowAnomaliesOnReplacement
    $nudAh.Enabled = $allow; $nudBk.Enabled = $allow
    try { Set-BracingFromBefore } catch {}
    Update-PhotoList
}
$rbExisting.Add_CheckedChanged($onTypeChange); $rbReplace.Add_CheckedChanged($onTypeChange)
$chkCross.Add_CheckedChanged({ Update-PhotoList }); $chkX.Add_CheckedChanged({ Update-PhotoList })
$nudAh.Add_ValueChanged({ Update-PhotoList }); $nudBk.Add_ValueChanged({ Update-PhotoList })

# ---------- Lock Existing/Replacement when those photos are already saved ----------
$RbExistingText = $rbExisting.Text; $RbReplaceText = $rbReplace.Text
$script:LockStr = $null
function Update-StageLock {
    $str = $txtStr.Text.Trim()
    $lockB = @(); $lockA = @()
    if ($str -match '^\d+$' -and [decimal]$str -gt 0) {
        $dir = Get-StructureDir $str
        $lockB = @(Test-StageLocked $dir 'Before'); $lockA = @(Test-StageLocked $dir 'After')
    }
    $rbExisting.Enabled = ($lockB.Count -eq 0); $rbReplace.Enabled = ($lockA.Count -eq 0)
    $rbExisting.Text = if ($lockB.Count) { "$RbExistingText - already saved" } else { $RbExistingText }
    $rbReplace.Text = if ($lockA.Count) { "$RbReplaceText - already saved" } else { $RbReplaceText }
    if ($lockB.Count -and $rbExisting.Checked) { $rbExisting.Checked = $false }
    if ($lockA.Count -and $rbReplace.Checked) { $rbReplace.Checked = $false }
    $tip = if ($lockB.Count -or $lockA.Count) { "Str ${str}: " + (@($lockB) + @($lockA) -join '; ') + ". Saved photos are never overwritten." } else { '' }
    $ttip.SetToolTip($grpType, $tip); $ttip.SetToolTip($rbExisting, $tip); $ttip.SetToolTip($rbReplace, $tip)
    # Default stage: Existing (Before) unless Before photos are already saved, then Replacement
    # (After). Re-applied whenever the structure # changes; the user can still switch manually.
    $noneChecked = -not $rbExisting.Checked -and -not $rbReplace.Checked
    if ($str -ne $script:LockStr -or $noneChecked) {
        $script:LockStr = $str
        if ($lockB.Count -eq 0) { $rbExisting.Checked = $true }
        elseif ($lockA.Count -eq 0) { $rbReplace.Checked = $true }
    }
    try { Set-BracingFromBefore } catch {}
    Update-PhotoList
}
$lockTimer = New-Object System.Windows.Forms.Timer
$lockTimer.Interval = 300
$lockTimer.Add_Tick({ $lockTimer.Stop(); try { Update-StageLock } catch {} })
$txtStr.Add_TextChanged({ $lockTimer.Stop(); $lockTimer.Start() })

function Test-Inputs {
    $o = Get-Options
    $errs = New-Object System.Collections.ArrayList
    if (-not ($o.StrText -match '^\d+$') -or [decimal]$o.StrText -le 0) { [void]$errs.Add('Structure # is required and must be a whole number greater than 0.') }
    if ($o.Stage -eq '?') { [void]$errs.Add('Choose Existing (Before) or Replacement (After) structure.') }
    elseif ($o.StrText -match '^\d+$') {
        $lk = @(Test-StageLocked (Get-StructureDir $o.StrText) $o.Stage)
        if ($lk.Count) { [void]$errs.Add("$($o.Stage) photos are already saved for Str $($o.StrText) (" + ($lk -join '; ') + "). The tool never overwrites them.") }
    }
    $slots = Get-CurrentSlots $o
    if ($script:Photos.Count -eq 0) { [void]$errs.Add('No photos added.') }
    elseif ($script:Photos.Count -ne $slots.Count) {
        [void]$errs.Add(("Photo count mismatch: {0} loaded, {1} expected ({2} AH + {3} BK). Check Cross Brace / X-Bracing / anomaly settings." -f
                $script:Photos.Count, $slots.Count, @($slots | Where-Object { $_.Span -eq 'AH' }).Count, @($slots | Where-Object { $_.Span -eq 'BK' }).Count))
    }
    $bad = @($script:Photos | Where-Object { -not $_.HasGps })
    if ($bad.Count -gt 0) {
        [void]$errs.Add("These photos have NO GPS data (ES requires GPS tagging - turn on camera location services):`r`n   " + (($bad | Select-Object -First 15 | ForEach-Object { $_.FileName }) -join "`r`n   "))
    }
    $broken = @($script:Photos | Where-Object { $_.Error })
    foreach ($b in $broken) { [void]$errs.Add("Could not read $($b.FileName): $($b.Error)") }
    try { [void](Get-Logo) } catch { [void]$errs.Add("Logo could not be loaded: $($_.Exception.Message)") }
    return , $errs.ToArray()
}

function Set-UiEnabled([bool]$On) {
    foreach ($c in @($btnAdd, $btnUp, $btnDown, $btnRemove, $btnClear, $btnSort, $btnProcess, $txtStr, $grpType, $chkCross, $chkX, $lv, $btnRotL, $btnRotR, $btnRotReset)) { $c.Enabled = $On }
    if ($On) { & $onTypeChange; try { Update-StageLock } catch {} } else { $nudAh.Enabled = $false; $nudBk.Enabled = $false }
}

function Reset-Form {
    Clear-PhotoThumbs $script:Photos; $script:Photos.Clear(); $script:ManualOrder = $false; $txtStr.Text = ''
    $rbExisting.Checked = $false; $rbReplace.Checked = $false
    $chkCross.Checked = $true; $chkX.Checked = $true; $nudAh.Value = 0; $nudBk.Value = 0
    $script:BracingFor = $null; $chkCross.Text = $CrossText; $chkX.Text = $XText
    try { Update-StageLock } catch {}      # back to the default (Existing)
    Update-PhotoList; $txtStr.Focus()
}


$script:StatusRows = New-Object System.Collections.ArrayList
$script:RowIndex = @{}
$script:Scan = $null
$script:RescanPending = $false
$StatusColors = @{
    'Complete'           = [System.Drawing.Color]::FromArgb(214, 240, 214)
    'Partially Complete' = [System.Drawing.Color]::FromArgb(255, 240, 196)
    'Not Started'        = [System.Drawing.Color]::FromArgb(235, 235, 235)
    'Needs Attention'    = [System.Drawing.Color]::FromArgb(248, 212, 212)
    'Naming Issue'       = [System.Drawing.Color]::FromArgb(226, 212, 246)
}
$scanTimer = New-Object System.Windows.Forms.Timer
$scanTimer.Interval = 300

function Set-StatusItem($Item, $r) {
    while ($Item.SubItems.Count -lt 11) { [void]$Item.SubItems.Add('') }
    $Item.Text = ''                      # hidden column 0
    $vals = @($r.Name, $r.Status, $r.BeforeText, $r.AfterText, $r.BAH, $r.BBK, $r.AAH, $r.ABK, $r.Total, (@($r.Issues) -join ' | '))
    for ($i = 0; $i -lt $vals.Count; $i++) { $Item.SubItems[$i + 1].Text = [string]$vals[$i] }
    $Item.BackColor = $StatusColors[[string]$r.Status]
    $Item.ToolTipText = if (@($r.Issues).Count) { @($r.Issues) -join "`r`n" } else { '' }
}

function Show-StatusRows {
    $script:RowIndex = @{}
    $lvSt.BeginUpdate(); $lvSt.Items.Clear()
    for ($i = 0; $i -lt $script:StatusRows.Count; $i++) {
        $r = $script:StatusRows[$i]
        $it = New-Object System.Windows.Forms.ListViewItem('')
        Set-StatusItem $it $r
        [void]$lvSt.Items.Add($it)
        $script:RowIndex[[string]$r.Name] = $i
    }
    $lvSt.EndUpdate()
}

function Set-StatusRow($r) {
    # Update a row in place (by folder name) or append it - the table auto-updates as the
    # background check reports each structure.
    $key = [string]$r.Name
    if ($script:RowIndex.ContainsKey($key)) {
        $i = $script:RowIndex[$key]
        $script:StatusRows[$i] = $r
        Set-StatusItem $lvSt.Items[$i] $r
    } else {
        [void]$script:StatusRows.Add($r)
        $script:RowIndex[$key] = $script:StatusRows.Count - 1
        $it = New-Object System.Windows.Forms.ListViewItem('')
        Set-StatusItem $it $r
        [void]$lvSt.Items.Add($it)
    }
}

function Update-StatusStats {
    # Legend chips show the live count for each status
    foreach ($k in $StatusOrder) {
        $n = @($script:StatusRows | Where-Object { $_.Status -eq $k }).Count
        $LegendChips[$k].Text = "$k  $n"
        $LegendChips[$k].BackColor = $StatusColors[$k]
    }
    try { Resize-StatusColumns } catch {}
}

function Save-StatusCache([double]$Seconds, [bool]$Deep) {
    try {
        $dir = Split-Path -Parent $StatusCacheFile
        if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir -Force) }
        [pscustomobject]@{ Root = $ProjectRoot; Time = (Get-Date); Seconds = $Seconds; Deep = $Deep; Rows = @($script:StatusRows) } |
            Export-Clixml -LiteralPath $StatusCacheFile -Depth 5
    } catch {}
}

function Import-StatusCache {
    try {
        if (-not (Test-Path -LiteralPath $StatusCacheFile)) { return $false }
        $c = Import-Clixml -LiteralPath $StatusCacheFile
        $script:StatusRows.Clear()
        foreach ($r in @($c.Rows)) { [void]$script:StatusRows.Add($r) }
        Show-StatusRows
        Update-StatusStats
        $stScanLbl.Text = 'Showing results from the last check (' + ([datetime]$c.Time).ToString('MMM d, yyyy h:mm tt', $Inv) + ').'
        return $true
    } catch { return $false }
}

function Start-StatusCheck {
    if ($script:Scan) { $script:RescanPending = $true; return }   # one at a time; re-run after
    $Config.StrictNaming = $true    # status check is always the full, strict check
    if (-not (Test-Path -LiteralPath $ProjectRoot)) { $stScanLbl.Text = "Project folder not found: $ProjectRoot"; return }
    $sync = [hashtable]::Synchronized(@{
            Queue = (New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]')
            Done = $false; Stop = $false; Total = 0; Processed = 0; Error = $null; Deep = [bool]$Config.DeepCheck
            DateCache = (Get-DateCache); DateSeen = [hashtable]::Synchronized(@{})
        })
    $rs = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspace()
    $rs.Open()
    $rs.SessionStateProxy.SetVariable('Sync', $sync)
    $rs.SessionStateProxy.SetVariable('Config', $Config)
    $rs.SessionStateProxy.SetVariable('ProjectRoot', $ProjectRoot)
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.Runspace = $rs
    [void]$ps.AddScript($ScanFunctionsText + "`r`n" + $ScanWorkerText)
    $handle = $ps.BeginInvoke()
    $script:Scan = @{ PS = $ps; RS = $rs; Handle = $handle; Sync = $sync; Started = (Get-Date); Ticks = 0; Seen = @{} }
    Show-ScanOverlay $true
    $stScanLbl.Text = 'Checking...'
    $scanTimer.Start()
}

function Complete-StatusCheck {
    $scanTimer.Stop()
    $s = $script:Scan
    try { [void]$s.PS.EndInvoke($s.Handle) } catch {}
    try { $s.PS.Dispose(); $s.RS.Dispose() } catch {}
    $script:Scan = $null
    $secs = ((Get-Date) - $s.Started).TotalSeconds
    $mode = if ($s.Sync.Deep) { 'full, strict' } else { 'quick, strict' }
    if ($s.Sync.Error) {
        $stScanLbl.Text = "Status check failed - see message"
        Show-ScanOverlay $false
        Show-Msg "The project status check failed:`r`n`r`n$($s.Sync.Error)" 'Warning' | Out-Null
    } elseif ($s.Sync.Stop) {
        $stScanLbl.Text = "Check stopped after $($s.Sync.Processed) of $($s.Sync.Total) folders - some rows show older results."
    } else {
        # drop folders that no longer exist, keep numeric order
        $keep = @($script:StatusRows | Where-Object { $s.Seen.ContainsKey([string]$_.Name) } | Sort-Object @{ Expression = { [decimal]$_.Num } }, Name)
        $script:StatusRows.Clear(); foreach ($r in $keep) { [void]$script:StatusRows.Add($r) }
        Show-StatusRows
        Save-StatusCache $secs $s.Sync.Deep
        if ($s.Sync.Deep) { Save-DateCache $s.Sync.DateSeen }
        $stScanLbl.Text = ('Last checked {0}  ({1} folders, {2:N0} s)' -f (Get-Date).ToString('MMM d, yyyy h:mm tt', $Inv), $s.Sync.Total, $secs)
    }
    Show-ScanOverlay $false
    Update-StatusStats
    if ($script:RescanPending) { $script:RescanPending = $false; Start-StatusCheck }
}

$scanTimer.Add_Tick({
        $s = $script:Scan
        if (-not $s) { $scanTimer.Stop(); return }
        $row = $null; $got = 0
        $lvSt.BeginUpdate()
        try {
            while ($s.Sync.Queue.TryDequeue([ref]$row)) { Set-StatusRow $row; $s.Seen[[string]$row.Name] = $true; $got++ }
        } finally { $lvSt.EndUpdate() }
        $s.Ticks++
        $total = [int]$s.Sync.Total; $done = [int]$s.Sync.Processed
        if ($total -gt 0) { $stScanProg.Maximum = $total; $stScanProg.Value = [Math]::Min($done, $total) }
        $el = [int]((Get-Date) - $s.Started).TotalSeconds
        $cur = [string]$s.Sync.Current
        if ($cur) { $ovFolder.Text = if ($cur -like 'Listing*') { $cur } else { "Checking  $cur" } }
        $ovCount.Text = if ($total -gt 0) { '{0} of {1} folders   ({2:N0}%)   -   {3}:{4:00} elapsed' -f $done, $total, (100.0 * $done / $total), [int][Math]::Floor($el / 60), ($el % 60) } else { 'Finding structure folders...' }
        if (($s.Ticks % 4) -eq 0) { Update-StatusStats }   # live statistics while checking
        if ($s.Sync.Done -and $s.Sync.Queue.IsEmpty) { Complete-StatusCheck }
    })

function Open-SelectedStructure {
    if ($lvSt.SelectedIndices.Count -ne 1) { Show-Msg 'Select a structure first.' | Out-Null; return }
    $r = $script:StatusRows[$lvSt.SelectedIndices[0]]
    if ($r.Status -eq 'Naming Issue') {
        Show-Msg "'$($r.Name)' is not a structure folder.`r`n`r`n$(@($r.Issues) -join "`r`n")" 'Warning' | Out-Null
        return
    }
    if ($script:Photos.Count -gt 0 -and $txtStr.Text -and $txtStr.Text -ne [string]$r.Num) {
        if ((Show-Msg "The Process tab already has $($script:Photos.Count) photo(s) for structure $($txtStr.Text). Clear them and load $($r.Name)?" 'Question' 'YesNo') -ne 'Yes') { return }
        Clear-PhotoThumbs $script:Photos; $script:Photos.Clear()
    }
    $txtStr.Text = [string]$r.Num
    Update-StageLock
    if ($r.Status -eq 'Not Started') { $rbExisting.Checked = $true }
    elseif ($r.Status -eq 'Partially Complete') { $rbReplace.Checked = $true }
    Update-PhotoList
    $tabs.SelectedTab = $pageProc
}

# ---------- Create Structure Folders logic ----------
$script:ExistingStr = @{}

function Update-ExistingStr {
    # map "<number>" -> existing folder name (numeric match, so 'Str 012' counts as 12)
    $script:ExistingStr = @{}
    foreach ($d in @(Get-StrFolders $ProjectRoot)) {
        [void]($d.Name -match $StrFolderRegex)
        $script:ExistingStr[[string][decimal]$Matches[1]] = $d.Name
    }
    $names = @($script:ExistingStr.Values | Sort-Object @{ Expression = { [decimal]([regex]::Match($_, '\d+').Value) } })
    $crInfo.Text = if ($names.Count -eq 0) {
        "Project folder: $ProjectRoot`r`nThis project has NO structure folders yet. Enter the structure numbers below (they don't need to be in order or consecutive, e.g. 8, 10, 12, 13, 15) and click Create Folders."
    } else {
        "Project folder: $ProjectRoot`r`nExisting structure folders: $($names.Count)  ($($names[0]) ... $($names[-1])). Numbers that already exist are skipped. Add any new structures below."
    }
}

function ConvertFrom-StructureList([string]$Text) {
    # Accepts one per line, or separated by spaces/commas/semicolons; "Str 12" / "#12" ok; ranges "20-25".
    $out = New-Object System.Collections.ArrayList
    $bad = New-Object System.Collections.ArrayList
    $seen = @{}
    $t = ($Text -replace '(?i)str\.?', ' ' -replace '#', ' ' -replace '\s*-\s*', '-')
    foreach ($tok in ($t -split '[\s,;]+')) {
        if (-not $tok) { continue }
        $vals = @()
        if ($tok -match '^\d+$') {
            if ([decimal]$tok -le 0) { [void]$bad.Add($tok); continue }
            $vals = @($tok)
        } elseif ($tok -match '^(\d+)-(\d+)$') {
            $a = [decimal]$Matches[1]; $b = [decimal]$Matches[2]
            $pad = if ($Matches[1].StartsWith('0')) { $Matches[1].Length } else { 0 }
            if ($a -le 0 -or $b -lt $a -or ($b - $a) -gt 2000) { [void]$bad.Add($tok); continue }
            $vals = @(for ($k = $a; $k -le $b; $k++) { ([string]$k).PadLeft($pad, '0') })
        } else { [void]$bad.Add($tok); continue }
        foreach ($v in $vals) {
            $key = [string][decimal]$v
            if (-not $seen.ContainsKey($key)) { $seen[$key] = $true; [void]$out.Add($v) }
        }
    }
    [pscustomobject]@{
        Nums = @($out | Sort-Object @{ Expression = { [decimal]$_ } })
        Bad  = @($bad)
    }
}

function Update-CreatePreview {
    $p = ConvertFrom-StructureList $txtCreate.Text
    $new = @($p.Nums | Where-Object { -not $script:ExistingStr.ContainsKey([string][decimal]$_) })
    $skip = @($p.Nums | Where-Object { $script:ExistingStr.ContainsKey([string][decimal]$_) })
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine(('New folders to create : {0}' -f $new.Count))
    [void]$sb.AppendLine(('Already exist (skip)  : {0}' -f $skip.Count))
    [void]$sb.AppendLine(('Not understood        : {0}' -f $p.Bad.Count))
    if ($p.Bad.Count) { [void]$sb.AppendLine('   ' + (($p.Bad | Select-Object -First 30) -join ', ')) }
    [void]$sb.AppendLine('')
    if ($new.Count) {
        [void]$sb.AppendLine("Will create in: $ProjectRoot")
        foreach ($n in ($new | Select-Object -First 1000)) { [void]$sb.AppendLine("   Str $n") }
        if ($new.Count -gt 1000) { [void]$sb.AppendLine("   ... and $($new.Count - 1000) more") }
    }
    if ($skip.Count) {
        [void]$sb.AppendLine('')
        [void]$sb.AppendLine('Already exist (skipped): ' + (($skip | Select-Object -First 200 | ForEach-Object { $script:ExistingStr[[string][decimal]$_] }) -join ', '))
    }
    $crPreview.Text = $sb.ToString()
    $btnCreate.Enabled = ($new.Count -gt 0)
    $btnCreate.Text = if ($new.Count) { "Create $($new.Count) Folder(s)" } else { 'Create Folders' }
}

$txtCreate.Add_TextChanged({ Update-CreatePreview })
$btnCreateClear.Add_Click({ $txtCreate.Text = ''; $crResult.Text = '' })
$btnCreate.Add_Click({
        Update-ExistingStr
        $p = ConvertFrom-StructureList $txtCreate.Text
        $new = @($p.Nums | Where-Object { -not $script:ExistingStr.ContainsKey([string][decimal]$_) })
        if ($new.Count -eq 0) { Update-CreatePreview; return }
        $msg = "Create $($new.Count) structure folder(s) in:`r`n$ProjectRoot`r`n`r`n" + (($new | Select-Object -First 25 | ForEach-Object { "Str $_" }) -join ', ') + $(if ($new.Count -gt 25) { ', ...' } else { '' })
        if ($p.Bad.Count) { $msg += "`r`n`r`nThese entries were not understood and will be ignored: " + (($p.Bad | Select-Object -First 15) -join ', ') }
        if ((Show-Msg $msg 'Question' 'YesNo') -ne 'Yes') { return }
        $made = 0; $failed = New-Object System.Collections.ArrayList
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        try {
            foreach ($n in $new) {
                $path = Join-Path $ProjectRoot "Str $n"
                try {
                    if (Test-Path -LiteralPath $path) { throw 'already exists - skipped' }
                    [void](New-Item -ItemType Directory -Path $path)
                    $made++
                } catch { [void]$failed.Add("Str ${n}: $($_.Exception.Message)") }
            }
        } finally { $form.Cursor = [System.Windows.Forms.Cursors]::Default }
        Update-ExistingStr
        $crResult.Text = "Created $made folder(s) at $((Get-Date).ToString('HH:mm'))." + $(if ($failed.Count) { "  $($failed.Count) failed - see message." } else { '' })
        if ($failed.Count) { Show-Msg ("Some folders could not be created:`r`n`r`n" + (($failed | Select-Object -First 20) -join "`r`n")) 'Warning' | Out-Null }
        $txtCreate.Text = ''
        Update-CreatePreview
        Start-StatusCheck
        if ($made -gt 0) { $tabs.SelectedTab = $pageStatus }   # back to the main (Project Status) screen
    })
$tabs.Add_SelectedIndexChanged({
        if ($tabs.SelectedTab -eq $pageCreate) { Update-ExistingStr; Update-CreatePreview }
    })

$miProc.Add_Click({ Open-SelectedStructure })
$miOpen.Add_Click({
        if ($lvSt.SelectedIndices.Count -eq 1) { Start-Process explorer.exe -ArgumentList "`"$($script:StatusRows[$lvSt.SelectedIndices[0]].Path)`"" }
    })
$miRoot.Add_Click({ Start-Process explorer.exe -ArgumentList "`"$ProjectRoot`"" })
$miCheck.Add_Click({ Start-StatusCheck })
$stopScan = { if ($script:Scan) { $script:Scan.Sync.Stop = $true; $ovStop.Enabled = $false; $ovStop.Text = 'Stopping...' } }
$miStop.Add_Click($stopScan)
$ovStop.Add_Click($stopScan)
$cmSt.Add_Opening({
        $one = ($lvSt.SelectedIndices.Count -eq 1)
        $miProc.Enabled = $one; $miOpen.Enabled = $one
        $miCheck.Enabled = (-not $script:Scan); $miStop.Enabled = [bool]$script:Scan
    })
# select the row under the mouse on right-click
$lvSt.Add_MouseDown({
        param($s, $e)
        if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Right) {
            $hit = $lvSt.HitTest($e.Location)
            if ($hit.Item) { $hit.Item.Selected = $true; $hit.Item.Focused = $true }
        }
    })
$form.KeyPreview = $true
$form.Add_KeyDown({ param($s, $e) if ($e.KeyCode -eq 'F5' -and $tabs.SelectedTab -eq $pageStatus) { Start-StatusCheck; $e.Handled = $true } })
$lvSt.Add_DoubleClick({ Open-SelectedStructure })

$btnProcess.Add_Click({
        try { [void](Import-UserSettings); Show-SettingsWarnings } catch {}   # pick up settings.txt edits
        $errs = Test-Inputs
        if ($errs.Count -gt 0) {
            Show-Msg ("Please fix the following:`r`n`r`n- " + ($errs -join "`r`n`r`n- ")) 'Warning' | Out-Null
            return
        }
        $o = Get-Options
        $slots = Get-CurrentSlots $o
        $results = New-Object System.Collections.ArrayList
        Set-UiEnabled $false
        $form.Cursor = [System.Windows.Forms.Cursors]::WaitCursor
        $progress.Maximum = $slots.Count; $progress.Value = 0
        $ok = $false
        try {
            for ($i = 0; $i -lt $slots.Count; $i++) {
                $slot = $slots[$i]; $photo = $script:Photos[$i]
                $lblStatus.Text = "Processing $($i + 1) / $($slots.Count): $($photo.FileName)  ->  $($slot.Name).jpg"
                [System.Windows.Forms.Application]::DoEvents()
                $pr = Invoke-ProcessPhoto $photo $slot
                [void]$results.Add([pscustomobject]@{ Index = $i + 1; Slot = $slot; Photo = $photo; Bytes = $pr.Bytes; Thumb = $pr.Thumb; FileName = ($slot.Name + '.jpg') })
                $progress.Value = $i + 1
            }
            $ok = $true
        } catch {
            Show-Msg ("Processing failed on photo #$($i + 1) ($($script:Photos[$i].FileName)):`r`n`r`n" + $_.Exception.Message) 'Error' | Out-Null
        } finally {
            $form.Cursor = [System.Windows.Forms.Cursors]::Default
            Set-UiEnabled $true
        }
        if ($ok) {
            $lblStatus.Text = "Processed $($results.Count) photos. Review them in the preview window."
            $saved = Show-Preview $results $o
            foreach ($r in $results) { if ($r.Thumb) { $r.Thumb.Dispose() } }
            if ($saved) {
                # clear the form automatically for the next structure
                $savedMsg = "Saved $($results.Count) photos for Str $($o.StrText) ($($o.Stage)) to: $script:PvSavedRoot"
                Reset-Form
                Update-StageLock
                Start-StatusCheck
                $lblStatus.Text = $savedMsg + '   - ready for the next structure.'
            }
        } else {
            foreach ($r in $results) { if ($r.Thumb) { $r.Thumb.Dispose() } }
        }
    })
#endregion

#region ------------------------------------- PREVIEW / SAVE -----------------------------------
function Get-StructureDir([string]$Num) {
    # Existing "Str <num>" folder in the project (numeric match), or the path it will be created at.
    $p = Join-Path $ProjectRoot "Str $Num"
    if (Test-Path -LiteralPath $p -PathType Container) { return $p }
    $f = Find-StrFolder $ProjectRoot $Num
    if ($f) { return $f }
    return $p
}

function Test-StageLocked([string]$StrDir, [string]$Stage) {
    # Returns reasons why <Stage> photos can't be saved: the stage's two span folders (or their pre-v14 short names) already hold
    # files or folders. (Empty folders are fine - nothing to protect.)
    $why = New-Object System.Collections.ArrayList
    if (-not $StrDir -or -not (Test-Path -LiteralPath $StrDir -PathType Container)) { return @() }
    foreach ($span in @('AH', 'BK')) {
        foreach ($name in @((Get-SpanFolderName "$Stage $span"), "$Stage $span")) {   # current + old short name
            $d = Join-Path $StrDir $name
            if (Test-Path -LiteralPath $d -PathType Container) {
                $items = @(Get-ChildItem -LiteralPath $d -Force -ErrorAction SilentlyContinue)
                if ($items.Count -gt 0) { [void]$why.Add("'$name' already contains $($items.Count) item(s)") }
            }
        }
    }
    return $why.ToArray()
}

function Save-Processed($Opt, $Results, $Owner) {
    # Saves ONLY into <ProjectRoot>\Str <num>\<Stage> AH|BK. Never overwrites, moves or deletes.
    $root = Get-StructureDir $Opt.StrText
    $locked = @(Test-StageLocked $root $Opt.Stage)
    if ($locked.Count -gt 0) {
        Show-Msg ("$($Opt.Stage) photos are already saved for Str $($Opt.StrText):`r`n  " + ($locked -join "`r`n  ") +
            "`r`n`r`nNothing was saved. This tool never overwrites or deletes photos - if they must be replaced, move the old folder out yourself first.") 'Warning' | Out-Null
        return $null
    }
    $groups = @($Results | Group-Object { $_.Slot.Folder })
    $lines = ($groups | ForEach-Object { "  $root\$($_.Name)   ($($_.Count) photos)" }) -join "`r`n"
    if ((Show-Msg "Save $($Results.Count) photos to:`r`n`r`n$lines" 'Question' 'YesNo') -ne 'Yes') { return $null }

    $failed = New-Object System.Collections.ArrayList
    $saved = 0
    if (-not (Test-Path -LiteralPath $root)) { [void](New-Item -ItemType Directory -Path $root) }
    foreach ($r in $Results) {
        $dir = Join-Path $root $r.Slot.Folder
        if (-not (Test-Path -LiteralPath $dir)) { [void](New-Item -ItemType Directory -Path $dir) }
        $path = Join-Path $dir $r.FileName
        $fs = $null
        try {
            # CreateNew = fail if the file exists (never overwrite)
            $fs = New-Object System.IO.FileStream($path, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::Write)
            $fs.Write($r.Bytes, 0, $r.Bytes.Length)
            $fs.Dispose(); $fs = $null
            # file modified date = date taken, so the quick status check needs no EXIF reads
            try { [System.IO.File]::SetLastWriteTime($path, $r.Photo.Taken) } catch {}
            $saved++
        } catch {
            [void]$failed.Add("$($r.FileName): $($_.Exception.Message)")
        } finally { if ($fs) { $fs.Dispose() } }
    }
    if ($failed.Count) {
        Show-Msg ("Saved $saved of $($Results.Count) photos. These were NOT saved (nothing was overwritten):`r`n`r`n" + (($failed | Select-Object -First 20) -join "`r`n")) 'Warning' | Out-Null
    }
    if ($saved -eq 0) { return $null }
    return $root
}

function Show-FullImage([byte[]]$Bytes, [string]$Title, $Owner) {
    # Full-size viewer for an in-memory processed photo (Esc or double-click closes)
    $ms = New-Object System.IO.MemoryStream(, $Bytes)
    $img = [System.Drawing.Image]::FromStream($ms)
    try {
        $fv = New-Object System.Windows.Forms.Form
        $fv.Text = "$Title  (Esc to close)"; $fv.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
        $fv.BackColor = [System.Drawing.Color]::Black; $fv.KeyPreview = $true
        if ($appIcon) { $fv.Icon = $appIcon }
        $pbv = New-Object System.Windows.Forms.PictureBox
        $pbv.Dock = 'Fill'; $pbv.SizeMode = 'Zoom'; $pbv.Image = $img
        $fv.Controls.Add($pbv)
        $fv.Add_KeyDown({ param($s, $e) if ($e.KeyCode -eq 'Escape') { $s.Close() } })
        $pbv.Add_DoubleClick({ $this.FindForm().Close() })
        [void]$fv.ShowDialog($Owner)
        $fv.Dispose()
    } finally { $img.Dispose(); $ms.Dispose() }
}

function Show-Preview($Results, $Opt) {
    # Review window: photos in a grid (grouped by folder), opens scrolled to the TOP; the only
    # "Save Photos..." button is at the END of the grid, so the user scrolls past every photo.
    $script:PvSaved = $false; $script:PvSavedRoot = $null
    $script:PvOpt = $Opt; $script:PvResults = $Results

    $pv = New-Object System.Windows.Forms.Form
    $pv.Text = "$($Config.ToolName) - Review processed photos - Str $($Opt.StrText) ($($Opt.Stage))"
    $pv.AutoScaleDimensions = New-Object System.Drawing.SizeF(96, 96)
    $pv.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi
    $pv.Size = New-Object System.Drawing.Size(1120, 900)
    $pv.StartPosition = 'CenterScreen'; $pv.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $pv.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    if ($appIcon) { $pv.Icon = $appIcon }
    $script:PvForm = $pv

    $flow = New-Object System.Windows.Forms.FlowLayoutPanel
    $flow.Dock = 'Fill'; $flow.AutoScroll = $true; $flow.FlowDirection = 'LeftToRight'; $flow.WrapContents = $true
    $flow.BackColor = [System.Drawing.Color]::FromArgb(40, 40, 40); $flow.Padding = New-Object System.Windows.Forms.Padding(10)
    $script:PvFlow = $flow
    $script:PvCards = New-Object System.Collections.ArrayList
    $script:PvWide = New-Object System.Collections.ArrayList     # full-width rows (folder headers, footer)

    $yellow = [System.Drawing.Color]::FromArgb(255, 239, 0)
    $fTitle = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Bold)
    $fSub = New-Object System.Drawing.Font('Segoe UI', 8.5)
    $lastFolder = ''
    foreach ($r in $Results) {
        if ($r.Slot.Folder -ne $lastFolder) {
            $lastFolder = $r.Slot.Folder
            $n = @($Results | Where-Object { $_.Slot.Folder -eq $lastFolder }).Count
            $hdrL = New-Object System.Windows.Forms.Label
            $hdrL.Text = "FOLDER:  Str $($Opt.StrText)\$lastFolder   ($n photos)"
            $hdrL.ForeColor = $yellow; $hdrL.TextAlign = 'BottomLeft'
            $hdrL.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
            $hdrL.AutoSize = $false; $hdrL.Height = 40; $hdrL.Margin = New-Object System.Windows.Forms.Padding(6, 12, 6, 4)
            $flow.Controls.Add($hdrL); $flow.SetFlowBreak($hdrL, $true)
            [void]$script:PvWide.Add($hdrL)
        }
        # Card = picture + 2 caption lines
        $card = New-Object System.Windows.Forms.Panel
        $card.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 24); $card.Margin = New-Object System.Windows.Forms.Padding(6)
        $card.Padding = New-Object System.Windows.Forms.Padding(4)
        $pb = New-Object System.Windows.Forms.PictureBox
        $pb.Dock = 'Fill'; $pb.SizeMode = 'Zoom'; $pb.Image = $r.Thumb; $pb.Tag = [int]($r.Index - 1)
        $pb.Cursor = [System.Windows.Forms.Cursors]::Hand
        $ttip.SetToolTip($pb, "Double-click to open full size`r`nSource: $($r.Photo.FileName)")
        $pb.Add_DoubleClick({
                $rr = $script:PvResults[[int]$this.Tag]
                try { Show-FullImage $rr.Bytes $rr.FileName $script:PvForm } catch {}
            })
        $t1 = New-Object System.Windows.Forms.Label
        $t1.Dock = 'Bottom'; $t1.Height = 22; $t1.Font = $fTitle; $t1.ForeColor = [System.Drawing.Color]::White; $t1.AutoEllipsis = $true
        $t1.Text = "#$($r.Index)   $($r.Slot.Name)"
        $t2 = New-Object System.Windows.Forms.Label
        $t2.Dock = 'Bottom'; $t2.Height = 20; $t2.Font = $fSub; $t2.ForeColor = [System.Drawing.Color]::Silver; $t2.AutoEllipsis = $true
        $t2.Text = "$($r.Slot.Desc)   |   source: $($r.Photo.FileName)"
        $card.Controls.Add($pb); $card.Controls.Add($t2); $card.Controls.Add($t1)
        $pb.BringToFront()
        $flow.Controls.Add($card)
        [void]$script:PvCards.Add($card)
    }
    if ($script:PvCards.Count) { $flow.SetFlowBreak($script:PvCards[$script:PvCards.Count - 1], $true) }

    # Footer at the very end of the grid with the only Save button
    $foot = New-Object System.Windows.Forms.Panel
    $foot.Height = 120; $foot.Margin = New-Object System.Windows.Forms.Padding(6, 24, 6, 30)
    $foot.BackColor = [System.Drawing.Color]::FromArgb(24, 24, 24)
    $footLbl = New-Object System.Windows.Forms.Label
    $footLbl.ForeColor = [System.Drawing.Color]::White; $footLbl.Font = $fTitle
    $footLbl.Location = New-Object System.Drawing.Point(16, 12); $footLbl.Size = New-Object System.Drawing.Size(900, 40)
    $footLbl.Size = New-Object System.Drawing.Size(1100, 40)
    $footLbl.Text = "Will save to: $(Get-StructureDir $Opt.StrText)`r`nEnd of review - all $($Results.Count) photos shown. Confirm each name matches its photo, photos are upright, and the logo and GPS text look right."
    $endSave = New-Object System.Windows.Forms.Button
    $endSave.Text = 'Save Photos...'; $endSave.Size = New-Object System.Drawing.Size(240, 48)
    $endSave.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $endSave.BackColor = $yellow; $endSave.FlatStyle = 'Flat'
    $endSave.Location = New-Object System.Drawing.Point(16, 58)
    $foot.Controls.Add($footLbl); $foot.Controls.Add($endSave)
    $flow.Controls.Add($foot)
    [void]$script:PvWide.Add($foot)

    # Bottom bar: info + Close only (Save is at the end of the grid)
    $bottom = New-Object System.Windows.Forms.Panel
    $bottom.Dock = 'Bottom'; $bottom.Height = 56; $bottom.BackColor = [System.Drawing.Color]::Black
    $btnClose = New-Object System.Windows.Forms.Button
    $btnClose.Text = 'Close'; $btnClose.Size = New-Object System.Drawing.Size(110, 38)
    $btnClose.Location = New-Object System.Drawing.Point(10, 9); $btnClose.BackColor = [System.Drawing.Color]::Gainsboro
    $lblInfo = New-Object System.Windows.Forms.Label
    $lblInfo.ForeColor = $yellow; $lblInfo.Location = New-Object System.Drawing.Point(136, 9)
    $lblInfo.Size = New-Object System.Drawing.Size(900, 38); $lblInfo.Anchor = 'Top,Left,Right'; $lblInfo.TextAlign = 'MiddleLeft'
    $lblInfo.Font = $fTitle
    $lblInfo.Text = "$($Results.Count) photos processed. Scroll down through every photo - the Save Photos button is at the bottom of the list."
    $script:PvInfo = $lblInfo; $script:PvClose = $btnClose
    $bottom.Controls.AddRange(@($btnClose, $lblInfo))

    $pv.Controls.Add($flow)
    $pv.Controls.Add($bottom)
    $flow.BringToFront()   # docked last -> fills the remaining space above the bottom bar
    $pv.ActiveControl = $btnClose   # keep focus off the Save button so the view doesn't jump to the end

    $script:PvLayout = {
        $f = $script:PvFlow
        $avail = $f.ClientSize.Width - $f.Padding.Horizontal - [System.Windows.Forms.SystemInformation]::VerticalScrollBarWidth - 4
        if ($avail -lt 300) { $avail = 300 }
        $cols = [Math]::Max(1, [int][Math]::Floor($avail / 430.0))       # ~430 px per card
        $cardW = [int][Math]::Floor($avail / $cols) - 12                  # minus left+right margin
        $cardH = [int]($cardW * 0.8) + 50                                 # picture + captions
        $f.SuspendLayout()
        foreach ($c in $script:PvCards) { $c.Size = New-Object System.Drawing.Size($cardW, $cardH) }
        foreach ($w in $script:PvWide) { $w.Width = $avail - 12 }
        $f.ResumeLayout()
    }
    $pv.Add_Shown({
            & $script:PvLayout
            $script:PvFlow.AutoScrollPosition = New-Object System.Drawing.Point(0, 0)   # start at the top
        })
    $pv.Add_Resize({ & $script:PvLayout })

    $endSave.Add_Click({
            try {
                $root = Save-Processed $script:PvOpt $script:PvResults $script:PvForm
                if ($root) {
                    $script:PvSaved = $true
                    $script:PvSavedRoot = $root
                    $script:PvForm.Close()      # close the review window automatically
                }
            } catch { Show-Msg "Save failed:`r`n$($_.Exception.Message)" 'Error' | Out-Null }
        })
    $btnClose.Add_Click({ $script:PvForm.Close() })
    $pv.Add_FormClosing({
            param($s, $e)
            if (-not $script:PvSaved) {
                if ((Show-Msg "These processed photos have NOT been saved. Close without saving?`r`n`r`n(Your original photos are not changed either way.)" 'Warning' 'YesNo') -ne 'Yes') { $e.Cancel = $true }
            }
        })

    [void]$pv.ShowDialog($form)
    $pv.Dispose()
    return $script:PvSaved
}
#endregion

#region ------------------------------------- UPDATE CHECK -------------------------------------
# On start, quietly asks GitHub for the latest version number (version.txt in the repo; if that
# file is missing, the "ToolVersion = 'x.y'" line of the script on GitHub is used). Runs in the
# background with a 15 s limit and never blocks the tool; no internet = no message.
# If newer, the user can DOWNLOAD it (saved as a NEW file in Downloads - nothing is overwritten,
# per the tool's safety rule) or open the update instructions (README "Updating" section).
$script:UpdTask = $null; $script:UpdWc = $null; $script:UpdStart = $null; $script:UpdStage = ''
$updTimer = New-Object System.Windows.Forms.Timer
$updTimer.Interval = 500

function Get-VersionFromText([string]$Text, [bool]$IsScript) {
    if (-not $Text) { return $null }
    $m = if ($IsScript) { [regex]::Match($Text, "ToolVersion\s*=\s*'([0-9]+(\.[0-9]+){1,3})'") } else { [regex]::Match($Text.Trim(), '^v?([0-9]+(\.[0-9]+){1,3})') }
    if ($m.Success) { try { return [version]$m.Groups[1].Value } catch {} }
    return $null
}

function New-UpdateClient {
    try { [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12 } catch {}
    $wc = New-Object System.Net.WebClient
    $wc.Headers['User-Agent'] = "ES-TLINE-PTOOL/$($Config.ToolVersion)"
    $wc.Headers['Cache-Control'] = 'no-cache'
    try { $wc.Proxy = [System.Net.WebRequest]::GetSystemWebProxy(); $wc.Proxy.Credentials = [System.Net.CredentialCache]::DefaultNetworkCredentials } catch {}
    return $wc
}

function Start-UpdateCheck {
    if (-not $Config.UpdateCheck) { return }
    try {
        $script:UpdWc = New-UpdateClient
        $script:UpdStage = 'version.txt'
        $script:UpdTask = $script:UpdWc.DownloadStringTaskAsync($Config.VersionUrl + '?t=' + [DateTime]::UtcNow.Ticks)
        $script:UpdStart = Get-Date
        $updTimer.Start()
    } catch {}
}

$updTimer.Add_Tick({
        try {
            if (-not $script:UpdTask) { $updTimer.Stop(); return }
            if (((Get-Date) - $script:UpdStart).TotalSeconds -gt 15) { $updTimer.Stop(); try { $script:UpdWc.CancelAsync() } catch {}; return }
            if (-not $script:UpdTask.IsCompleted) { return }
            $txt = if ($script:UpdTask.Status -eq 'RanToCompletion') { $script:UpdTask.Result } else { $null }
            $remote = Get-VersionFromText $txt ($script:UpdStage -eq 'script')
            if (-not $remote -and $script:UpdStage -eq 'version.txt') {
                # no version.txt in the repo - read the version from the script itself
                $script:UpdStage = 'script'
                $script:UpdTask = $script:UpdWc.DownloadStringTaskAsync($Config.ScriptUrl + '?t=' + [DateTime]::UtcNow.Ticks)
                return
            }
            $updTimer.Stop()
            $local = [version]$Config.ToolVersion
            if ($remote -and $remote -gt $local) { Show-UpdatePrompt $remote }
        } catch { $updTimer.Stop() }
    })

function Save-UpdateDownload([version]$Remote) {
    # Downloads the new script into a NEW folder in Downloads (never overwrites anything)
    $dl = Join-Path $env:USERPROFILE 'Downloads'
    if (-not (Test-Path -LiteralPath $dl)) { $dl = [Environment]::GetFolderPath('Desktop') }
    $dir = Join-Path $dl "ES TLINE PTOOL v$Remote"; $k = 2
    while (Test-Path -LiteralPath $dir) { $dir = Join-Path $dl "ES TLINE PTOOL v$Remote ($k)"; $k++ }
    [void](New-Item -ItemType Directory -Path $dir)
    $target = Join-Path $dir 'ES TLINE PTOOL.ps1'
    $wc = New-UpdateClient
    try { $wc.DownloadFile($Config.ScriptUrl + '?t=' + [DateTime]::UtcNow.Ticks, $target) } finally { $wc.Dispose() }
    return $target
}

$UpdDir = Join-Path (Join-Path $cacheBase 'ES_TLINE_PTOOL') 'update'
$UpdMarker = Join-Path $UpdDir 'just-updated.txt'

function Invoke-SelfUpdate([version]$Remote) {
    # ONE-CLICK UPDATE (only when the user clicks "Update now" and confirms). The ONE place the
    # tool replaces a file: its own script. Steps:
    #   1. download the new version to %LOCALAPPDATA%\ES_TLINE_PTOOL\update\ (new file)
    #   2. verify it: right version number, PowerShell syntax check, sensible size
    #   3. keep a backup copy of the current script in ...\update\backup\ (new file)
    #   4. copy the new script over this one, unblock it, restart it, open the README #updating
    # Any failure before step 4 leaves the current script untouched.
    $here = $PSCommandPath
    if (-not $here -or -not (Test-Path -LiteralPath $here)) { throw 'The location of the running script is unknown - use Download only.' }
    if (-not (Test-Path -LiteralPath $UpdDir)) { [void](New-Item -ItemType Directory -Path $UpdDir -Force) }
    $stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $new = Join-Path $UpdDir "ES TLINE PTOOL v$Remote $stamp.ps1"
    $wc = New-UpdateClient
    try { $wc.DownloadFile($Config.ScriptUrl + '?t=' + [DateTime]::UtcNow.Ticks, $new) } finally { $wc.Dispose() }

    # verify
    $txt = [System.IO.File]::ReadAllText($new)
    $v = Get-VersionFromText $txt $true
    if (-not $v -or $v -ne $Remote) { throw "The downloaded file is not version $Remote (found '$v')." }
    if ($txt.Length -lt 50000) { throw 'The downloaded file looks incomplete.' }
    $tok = $null; $perr = $null
    [void][System.Management.Automation.Language.Parser]::ParseInput($txt, [ref]$tok, [ref]$perr)
    if ($perr -and $perr.Count -gt 0) { throw "The downloaded file failed a syntax check: $($perr[0].Message)" }

    # backup current version (new file, never overwritten)
    $bakDir = Join-Path $UpdDir 'backup'
    if (-not (Test-Path -LiteralPath $bakDir)) { [void](New-Item -ItemType Directory -Path $bakDir -Force) }
    $bak = Join-Path $bakDir "ES TLINE PTOOL v$($Config.ToolVersion) $stamp.ps1"
    Copy-Item -LiteralPath $here -Destination $bak

    # replace this script (PowerShell has already read it into memory, so it isn't locked)
    Copy-Item -LiteralPath $new -Destination $here -Force
    try { Unblock-File -LiteralPath $here -ErrorAction SilentlyContinue } catch {}
    try { Set-Content -LiteralPath $UpdMarker -Value "$($Config.ToolVersion)`t$Remote`t$bak" } catch {}
    return $bak
}

function Show-JustUpdated {
    # Shown by the NEW version on its first start after a one-click update
    if (-not (Test-Path -LiteralPath $UpdMarker)) { return }
    $p = @(); try { $p = ([System.IO.File]::ReadAllText($UpdMarker)).Trim().Split("`t") } catch {}
    try { Remove-Item -LiteralPath $UpdMarker -Force -ErrorAction SilentlyContinue } catch {}   # tool's own marker file
    $from = if ($p.Count -ge 1) { $p[0] } else { '?' }
    $bak = if ($p.Count -ge 3) { $p[2] } else { '' }
    Show-Msg ("ES TLINE PTOOL was updated from v$from to v$($Config.ToolVersion).`r`n`r`n" +
        "A copy of the old version was kept here:`r`n$bak`r`n`r`n" +
        "Have several projects? Update the copy in each project folder too.") | Out-Null
}

function Show-UpdatePrompt([version]$Remote) {
    $here = if ($PSCommandPath) { $PSCommandPath } else { Join-Path $ProjectRoot 'ES TLINE PTOOL.ps1' }
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "$($Config.ToolName) - update available"; $f.StartPosition = 'CenterParent'
    $f.FormBorderStyle = 'FixedDialog'; $f.MaximizeBox = $false; $f.MinimizeBox = $false
    $f.ClientSize = New-Object System.Drawing.Size(600, 262); $f.Font = New-Object System.Drawing.Font('Segoe UI', 9.5)
    if ($appIcon) { $f.Icon = $appIcon }
    $stripe = New-Object System.Windows.Forms.Panel
    $stripe.Dock = 'Top'; $stripe.Height = 6; $stripe.BackColor = [System.Drawing.Color]::FromArgb(255, 239, 0)
    $t = New-Object System.Windows.Forms.Label
    $t.Text = "A newer version is available:  v$Remote   (you have v$($Config.ToolVersion))"
    $t.Font = New-Object System.Drawing.Font('Segoe UI', 11, [System.Drawing.FontStyle]::Bold)
    $t.Location = New-Object System.Drawing.Point(20, 20); $t.Size = New-Object System.Drawing.Size(560, 26)
    $b = New-Object System.Windows.Forms.Label
    $b.Location = New-Object System.Drawing.Point(20, 54); $b.Size = New-Object System.Drawing.Size(560, 136)
    $b.Text = "Update now (recommended): downloads v$Remote, checks it, keeps a backup of your current`r`n" +
    "version, replaces this script and restarts the tool:`r`n" +
    "      $here`r`n`r`n" +
    "Download only: saves the new file to a new folder in Downloads - you then close this tool,`r`n" +
    "copy it into the project folder, unblock it (right-click > Properties > Unblock) and run it.`r`n`r`n" +
    "Your photos and folders are not affected either way."
    $mkBtn = {
        param($Text, $X, $W)
        $x1 = New-Object System.Windows.Forms.Button
        $x1.Text = $Text; $x1.Size = New-Object System.Drawing.Size($W, 34); $x1.Location = New-Object System.Drawing.Point($X, 208)
        $x1
    }
    $btnNow = & $mkBtn 'Update now' 20 140
    $btnNow.BackColor = [System.Drawing.Color]::FromArgb(255, 239, 0); $btnNow.FlatStyle = 'Flat'
    $btnNow.Font = New-Object System.Drawing.Font('Segoe UI', 9.5, [System.Drawing.FontStyle]::Bold)
    $btnDl = & $mkBtn 'Download only' 170 130
    $btnHelp = & $mkBtn 'Open update page' 310 140
    $btnLater = & $mkBtn 'Later' 480 100
    $btnLater.DialogResult = 'Cancel'; $f.CancelButton = $btnLater; $f.AcceptButton = $btnNow
    $f.Controls.AddRange(@($stripe, $t, $b, $btnNow, $btnDl, $btnHelp, $btnLater))
    $script:UpdRemote = $Remote

    $btnHelp.Add_Click({ try { Start-Process $Config.UpdateHelpUrl } catch {} })
    $btnNow.Add_Click({
            $warn = if ($script:Photos.Count -gt 0) { "`r`n`r`nThe $($script:Photos.Count) photo(s) loaded on the Process Photos tab will be cleared (your original photos are not touched)." } else { '' }
            if ((Show-Msg ("Update ES TLINE PTOOL to v$($script:UpdRemote) now?`r`n`r`nThe tool will close and restart." + $warn) 'Question' 'YesNo') -ne 'Yes') { return }
            $this.Enabled = $false; $this.Text = 'Updating...'
            [System.Windows.Forms.Application]::DoEvents()
            try {
                [void](Invoke-SelfUpdate $script:UpdRemote)
            } catch {
                $this.Enabled = $true; $this.Text = 'Update now'
                Show-Msg ("The update could not be installed - nothing was changed:`r`n$($_.Exception.Message)`r`n`r`n" +
                    "Use 'Download only' or 'Open update page' to update by hand.") 'Warning' | Out-Null
                return
            }
            # restart the new version (Bypass for this one process only, so a blocked policy can't stop it)
            try {
                $exe = (Get-Process -Id $PID).Path
                Start-Process -FilePath $exe -ArgumentList @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
            } catch {
                Show-Msg "Updated, but the tool could not restart by itself. Close it and run ES TLINE PTOOL.ps1 again.`r`nIf Windows blocks it: right-click the file > Properties > tick 'Unblock' > OK." 'Information' | Out-Null
            }
            try { Start-Process $Config.UpdateHelpUrl } catch {}     # README "Updating" (incl. unblocking)
            $script:UpdQuit = $true
            $this.FindForm().Close()
        })
    $btnDl.Add_Click({
            try {
                $this.Enabled = $false; $this.Text = 'Downloading...'
                $path = Save-UpdateDownload $script:UpdRemote
                Start-Process explorer.exe -ArgumentList "/select,`"$path`""
                try { Start-Process $Config.UpdateHelpUrl } catch {}
                Show-Msg "Downloaded to:`r`n$path`r`n`r`nClose this tool, copy that file into your project folder (replacing the old one), unblock it (right-click > Properties > Unblock) and run it.`r`nThe update steps are open in your browser." | Out-Null
                $this.FindForm().Close()
            } catch {
                $this.Enabled = $true; $this.Text = 'Download only'
                Show-Msg "The download failed:`r`n$($_.Exception.Message)`r`n`r`nUse 'Open update page' to download it from GitHub instead." 'Warning' | Out-Null
            }
        })
    $script:UpdQuit = $false
    [void]$f.ShowDialog($form)
    $f.Dispose()
    if ($script:UpdQuit) {
        $form.Close()          # the updated version has been started
    }
}
#endregion

#region ------------------------------------- RUN ----------------------------------------------
Update-PhotoList
$tabs.SelectedTab = $pageStatus
$form.Add_Shown({
        Set-ProcLayout
        try { Show-JustUpdated } catch {}       # first start after a one-click update
        try { Show-SettingsWarnings } catch {}  # problems in settings.txt
        try { Start-UpdateCheck } catch {}      # quiet background check for a newer version
        try { Update-StageLock } catch {}      # default stage = Existing
        try {
            Update-ExistingStr; Update-CreatePreview
            if ($script:ExistingStr.Count -eq 0) { $tabs.SelectedTab = $pageCreate }
        } catch {}
        try {
            [void](Import-StatusCache)
            Update-StatusStats
            Start-StatusCheck            # full + strict check, always, on start
        } catch {
            $stScanLbl.Text = "Status check could not start"
            try { Show-ScanOverlay $false } catch {}
            Show-Msg "The project status check could not start:`r`n`r`n$($_.Exception.Message)`r`n`r`nThe Process Photos tab still works." 'Warning' | Out-Null
        }
    })
try {
    [void]$form.ShowDialog()
} finally {
    if ($script:Scan) {
        $script:Scan.Sync.Stop = $true; $scanTimer.Stop()
        try { $script:Scan.PS.Stop(); $script:Scan.PS.Dispose(); $script:Scan.RS.Dispose() } catch {}
    }
    if ($script:LogoImage) { $script:LogoImage.Dispose() }
    $form.Dispose()
}
#endregion
