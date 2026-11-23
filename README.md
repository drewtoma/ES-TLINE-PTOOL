# ES TLINE PTOOL

**ES TLINE PTOOL** is a Windows desktop tool that renames, orients and stamps transmission line structure photos with the M. J. Electric logo and their GPS coordinates, files them into each structure's folder to Eversource's photo documentation spec, and tracks every structure's photo status across the project.

It is a single PowerShell file (`ES TLINE PTOOL.ps1`) with nothing to install.

**Current version: 0.3** – see [Updating](#updating) to get the latest version.

---

## Contents

1. [Requirements](#requirements)
2. [Setup](#setup)
3. [Unblocking and running the script](#unblocking-and-running-the-script)
4. [Phone and camera settings](#phone-and-camera-settings)
5. [Shooting order in the field](#shooting-order-in-the-field)
6. [Folder and file naming](#folder-and-file-naming)
7. [Using the tool](#using-the-tool)
   - [Project Status](#project-status-main-screen)
   - [Process Photos](#process-photos)
   - [Review and save](#review-and-save)
   - [Create Structure Folders](#create-structure-folders)
   - [Instructions](#instructions-tab)
8. [Customising the logo and photo stamp](#customising-the-logo-and-photo-stamp)
9. [Safety: what the tool will and won't do](#safety-what-the-tool-will-and-wont-do)
10. [Updating](#updating)
11. [Troubleshooting](#troubleshooting)
12. [Files the tool keeps on your PC](#files-the-tool-keeps-on-your-pc)

---

## Requirements

- **Windows 10 or 11.** The tool does not run on a Mac (use a Windows virtual machine such as Parallels instead).
- **Windows PowerShell 5.1** (built into Windows) or PowerShell 7. Nothing else needs to be installed.
- **Photos with GPS location data.** Eversource requires every photo to be GPS-tagged; the tool refuses photos without it.

## Setup

1. Put `ES TLINE PTOOL.ps1` **in the project (line) photo folder** – the folder that holds, or will hold, the `Str ####` structure folders:

   ```
   Line 391\
   ├── ES TLINE PTOOL.ps1
   ├── Str 8\
   ├── Str 10\
   └── Str 12\
   ```

   The tool checks the folder it sits in, so don't run it from your Downloads folder.

2. Unblock and run it (next section).

3. If the project has no structure folders yet, the tool opens on the **Create Structure Folders** tab so you can create them all at once.

---

## Unblocking and running the script

Windows blocks PowerShell scripts by default, and also blocks files downloaded from the internet or email. You only need to do this once per PC (and once per new copy of the file).

### Step 1 – Unblock the file

**Option A – File Explorer**

1. Right-click `ES TLINE PTOOL.ps1` → **Properties**.
2. On the **General** tab, tick **Unblock** at the bottom (if it is there).
3. Click **OK**.

**Option B – PowerShell**

```powershell
Unblock-File "C:\path\to\Line 391\ES TLINE PTOOL.ps1"
```

### Step 2 – Allow scripts for your account (one time)

Open **Windows PowerShell** (Start menu → type *PowerShell*) and run:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Answer **Y** if asked. This only affects your Windows account and does not need admin rights.

### Step 3 – Run it

- **Right-click** `ES TLINE PTOOL.ps1` → **Run with PowerShell**.

The tool opens maximized. A black PowerShell window also opens behind it – leave it open; closing it closes the tool.

### Alternative: run without changing any settings

If you'd rather not change the execution policy, run this from a PowerShell window each time (keep the quotes – the file name has spaces):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "C:\path\to\Line 391\ES TLINE PTOOL.ps1"
```

### If it still won't run

| Message | What to do |
|---|---|
| *"running scripts is disabled on this system"* | Do Step 2, or use the Bypass command above. |
| *"is not digitally signed"* | Unblock the file (Step 1). |
| *"…overridden by a policy defined at a more specific scope"* / *"…by Group Policy"* | Your IT department controls this setting. Ask IT to allow or sign the script. |
| Window flashes and closes | Run it with the Bypass command above so the window stays open, and read the red text. Also check `%TEMP%\ES_TLINE_PTOOL_error.txt`. |

---

## Phone and camera settings

Before going out:

- **Location / GPS on** for the camera app.
- **iPhone:** Settings → Camera → Formats → **Most Compatible** (saves JPEG instead of HEIC).
- **Correct date and time** on the device – photos are put in order by the time they were taken.
- Enough free storage.

---

## Shooting order in the field

Shoot **one structure at a time** and finish it before moving on. Shoot the **whole ahead span (AH) first**, then repeat the same list for the **back span (BK)**.

| # | Shot |
|---|---|
| 1 | 100 ft away, looking along the span |
| 2 | Full structure close-up |
| 3 | Cross arm / cross brace \* |
| 4 | X-bracing \* |
| 5 | Left insulator and attachments |
| 6 | Middle insulator and attachments |
| 7 | Right insulator and attachments |
| 8 | Left static wire attachment |
| 9 | Right static wire attachment |
| 10+ | One photo per anomaly (woodpecker hole, rot, broken insulator…) \*\* |

\* Skip if the structure doesn't have one. **Numbers don't shift** – the next shot is still 5.
\*\* Existing (Before) structures only.

**Tips**

- Note for each structure: cross arm yes/no, x-brace yes/no, number of AH anomalies, number of BK anomalies. The tool asks for exactly these.
- If a shot is bad, retake it straight away. Don't delete photos on the phone.
- **Existing structure = Before photos. Replacement (new) structure = After photos.**

---

## Folder and file naming

Each structure folder holds up to four span folders:

```
Str 1234\
├── Existing Structure Ahead Span\
│   ├── Str 1234 - 1 Before AH.jpg
│   ├── Str 1234 - 2 Before AH.jpg
│   └── ...
├── Existing Structure Back Span\
│   └── Str 1234 - 1 Before BK.jpg ...
├── Replacement Structure Ahead Span\
│   └── Str 1234 - 1 After AH.jpg ...
└── Replacement Structure Back Span\
    └── Str 1234 - 1 After BK.jpg ...
```

Every processed photo:

- is rotated upright,
- has the M. J. Electric logo in the top-right corner,
- has a black bar added **below** the photo (nothing in the photo is covered) with yellow text:
  `Str 1234 - 5 Before AH // LAT: 41.765432 // LONG: -72.678901`
- keeps its original GPS and camera information, and its file date is set to the date the photo was taken.

---

## Using the tool

The tool has four tabs.

### Project Status (main screen)

Shows every `Str ####` folder in the project and its status.

**Statuses**

| Colour | Status | Meaning |
|---|---|---|
| Green | **Complete** | All four span folders are done. |
| Amber | **Partially Complete** | Existing (Before) photos done, Replacement (After) not yet. |
| Grey | **Not Started** | No photos yet. |
| Red | **Needs Attention** | Something is missing or misnamed – **hover over the row** to see exactly what. |
| Purple | **Naming Issue** | A folder in the project folder that isn't named `Str ####`, or photos loose in the project folder. |

The coloured boxes above the table show how many structures have each status.

**The table** shows the dates Before/After photos were taken, the number of photos in each span folder, the total, and any issues.

**The status check**

- Runs automatically when the tool opens, after every save and after creating folders. Press **F5** to run it again.
- While it runs, a **Checking project folders** panel covers the screen showing the folder being checked and a progress bar. Click **Stop** to end it early. You can keep using the Process Photos tab meanwhile.
- When it finishes, the time of the last check shows at the top right.
- It checks that every required shot (1, 2, 5–9) is present, anomaly numbers have no gaps, and every file and folder name exactly matches the format above. It also flags extra folders, loose photos and non-photo files (videos, documents, RAW files).
- It is faster after the first run – photos that haven't changed are not re-read.
- It never downloads OneDrive / SharePoint "online-only" files.

**Actions**

- **Double-click** a structure to process it (Not Started loads as Existing, Partially Complete as Replacement).
- **Right-click** a structure for: *Process this structure*, *Open structure folder*, *Open project folder*, *Re-check all structures*, *Stop the status check*.

### Process Photos

1. **Copy the photos from the phone/camera to the PC first** (dragging straight from a plugged-in phone usually doesn't work). Copy them to a folder **outside** the project folder, e.g. `Photo Shoots\2026-11-20`, and keep it as your backup.
2. Enter the **Structure #** (numbers only – `1234` makes files named `Str 1234 - …`).
3. **Photo set:** *Existing (Before)* is picked for you, or *Replacement (After)* if the Before photos are already saved. Change it if needed. A set that is already saved is greyed out ("– already saved").
4. **Cross Brace / X-Bracing:** untick if the structure doesn't have them. For Replacement photos these are set for you from the saved Before photos (shown as "– from Before"); change them if the new structure is different.
5. Enter the number of **Ahead (AH)** and **Back (BK) anomalies** (Existing only).
6. **Add photos:** drag the photos (or their folder) onto the yellow box or the list, or click **Add Photos…**. They are sorted by the time they were taken.
7. **Check the list.** The list order *is* the order photos are named and processed – photo 4 in the list becomes shot 4.
   - Click a photo to see it in the **preview** on the right with the name it will get and its GPS.
   - **Wrong order?** Select a photo (or several) and click **Move Up / Move Down** (or **Ctrl+Up / Ctrl+Down**), or simply **drag the row** to where it belongs.
   - **Sideways photo?** Use **Rotate Left / Rotate Right** under the preview (**Reset** undoes it).
   - **Extra or bad photo?** Select it → **Remove** (or press **Delete**).
   - If you add more photos after re-ordering, they go at the end so your order is kept. **Sort by Time** resets the order (it asks first).
   - The box on the left shows expected vs. loaded photos and any missing GPS. Rows in red need fixing.
8. Click **Process Photos**. If anything is wrong (missing structure #, wrong number of photos, photos without GPS, set already saved) the tool lists it so you can fix it.

### Review and save

- A review window opens at the top, showing the processed photos in a grid grouped by span folder.
- **Scroll through every photo** and check the name, that it's upright, the logo, and the GPS text. Double-click a photo to see it full size.
- At the **bottom** of the grid, click **Save Photos…** and confirm. Photos always go into this structure's folder – there is no folder to pick:
  `Str 1234\Existing Structure Ahead Span` and `Str 1234\Existing Structure Back Span` (or the Replacement folders for After photos).
- The review window closes and the form clears automatically, ready for the next structure. The status line shows where the photos were saved.

Nothing is written to the project folder until you click **Save Photos…**.

### Create Structure Folders

Use this at the start of a project so every structure shows on Project Status (as Not Started).

1. Type or paste the structure numbers, **one per line** (a column copied from Excel works). They don't need to be in order or consecutive:

   ```
   8
   10
   12
   13
   15
   ```

   You can also type `8, 10, 12` on one line, or a range such as `20-25`.

2. The right side shows what will be created, which folders already exist (skipped) and anything not understood.
3. Click **Create Folders** and confirm. You're taken back to Project Status.

Only empty `Str ####` folders are created; the span folders are added when photos are saved.

### Instructions tab

A built-in copy of these operating instructions. At the bottom it shows which logo is being used and whether a `settings.txt` is active, with a **Create settings.txt** / **Open settings.txt** button (see [Customising](#customising-the-logo-and-photo-stamp)).

---

## Customising the logo and photo stamp

Out of the box the tool stamps photos to the Eversource spec with the built-in M. J. Electric logo – **no setup needed**. Both of the options below are optional and per project (they live in the project folder).

> **Note:** the defaults match the Eversource photo documentation spec. Check with your project lead before changing the look of submitted photos.

### Use your own logo

1. Save your logo as **`logo.png`** in the **project folder** (next to `ES TLINE PTOOL.ps1`).
2. That's it – it is used on every photo processed from then on, and in the tool's header.

Tips:

- A **PNG with a transparent background** looks best. Crop it tight – any empty border becomes part of the logo's size.
- Size, position and transparency can be changed in `settings.txt` (below).
- To use a different file name or location, set `LogoFile` in `settings.txt`.
- Delete or rename `logo.png` to go back to the built-in logo.
- The logo file is ignored by the status check (it isn't reported as a loose photo).

### settings.txt

For more control, add a **`settings.txt`** to the project folder.

**Easiest:** open the **Instructions** tab and click **Create settings.txt**. It creates a template (every setting listed but switched off) and opens it in Notepad. Remove the `#` at the start of a line and change the value to use it, then save.

Rules:

- One setting per line: `Name = value`. Names aren't case-sensitive.
- Lines starting with `#` are comments (switched off). You can also add a comment after a value: `LogoSize = 9   # bigger logo`.
- Leave a setting out (or blank) to use the default.
- Changes apply the **next time you click Process Photos** – no restart needed. Photos already saved are **not** changed.
- If a line can't be used (unknown name, value out of range, font not installed…) it is ignored, the default is used, and the tool tells you which line and why. The message only appears again if the problems change.
- You can keep `settings.txt` open in Notepad while you work – save it, then click **Process Photos**.
- Without a `settings.txt` (the normal case) the standard Eversource look and the built-in logo are used.

| Setting | Default | Allowed values |
|---|---|---|
| `LogoFile` | `logo.png` | File name in the project folder (or a full path). Built-in logo if not found. |
| `LogoPosition` | `TopRight` | `TopRight`, `TopLeft`, `BottomRight`, `BottomLeft`, `None` (no logo) |
| `LogoSize` | `7` | Logo width as % of the photo's longer side, 1–50 |
| `LogoMargin` | `1.5` | Gap from the photo edge as % of the shorter side, 0–20 |
| `LogoOpacity` | `100` | 0–100 (100 = solid) |
| `BarPosition` | `Bottom` | `Bottom` or `Top` – the bar is added to the photo, it never covers it |
| `BarHeight` | `5` | % of the photo's shorter side, 1–30 |
| `BarColor` | `#000000` | Hex colour (`#000000` or `000000`) or a colour name (`Black`, `Navy`…) |
| `TextColor` | `#FFEF00` | Hex colour or colour name |
| `Font` | `Segoe UI` | Any font installed on the PC |
| `FontBold` | `true` | `true` / `false` |
| `TextAlign` | `Center` | `Center`, `Left`, `Right` |
| `TextWidth` | `96` | Maximum text width as % of the photo width, 30–100 (text shrinks to fit) |
| `TextFormat` | `{NAME} // LAT: {LAT} // LONG: {LONG}` | Any text with these placeholders (not case-sensitive): `{NAME}` file name, `{STRUCTURE}` e.g. `Str 1234`, `{LAT}` / `{LONG}` coordinates, `{DATE}` date taken. Keep `{LAT}` and `{LONG}` – Eversource requires GPS on every photo (you're warned if they're missing). |
| `CoordDecimals` | `6` | Decimal places for coordinates, 4–8 (also used in the photo list) |
| `JpegQuality` | `92` | 50–100 |

**Example `settings.txt`** – a larger, semi-transparent logo in the bottom-left and white text:

```ini
# ES TLINE PTOOL - settings.txt
LogoFile = logo.png
LogoPosition = BottomLeft
LogoSize = 10
LogoOpacity = 85
TextColor = #FFFFFF
```

---

## Safety: what the tool will and won't do

- It **never deletes, moves or overwrites** your photos or folders. The only file it ever replaces is its own script, and only when you click **Update now** (a backup is kept – see [Updating](#updating)).
- Your **original photos are only read**, never changed.
- Once Before (or After) photos are saved for a structure, that set can't be processed or saved again. To redo a set, move the old span folders out of the structure folder yourself first (empty folders are fine).
- Folders created by older versions of the tool (`Before AH`, `Before BK`, `After AH`, `After BK`) are flagged on Project Status with the new name to use – the tool won't rename them itself.

---

## Updating

The tool checks this repository for a newer version each time it opens (quietly, in the background – if there's no internet connection, nothing happens). Your version number is shown in the window title and under the logo, e.g. **v0.3**.

### When an update is available

A window appears with four choices:

| Button | What it does |
|---|---|
| **Update now** *(recommended)* | One click (plus a confirmation): downloads the new version, checks it, keeps a backup of your current version, replaces `ES TLINE PTOOL.ps1` in your project folder, restarts the tool and opens this page. |
| **Download only** | Saves the new `ES TLINE PTOOL.ps1` into a **new folder** in your Downloads (e.g. `Downloads\ES TLINE PTOOL v0.4\`) and opens this page. You then install it by hand (below). |
| **Open update page** | Opens this section in your browser. |
| **Later** | Keeps using your current version. You'll be asked again next time. |

### Update now – what happens

1. The new version is downloaded to `%LOCALAPPDATA%\ES_TLINE_PTOOL\update\`.
2. It is checked (correct version number, valid PowerShell, complete file). If anything is wrong, **nothing is changed** and you're told why.
3. A **backup** of your current version is saved to `%LOCALAPPDATA%\ES_TLINE_PTOOL\update\backup\`.
4. The new version replaces `ES TLINE PTOOL.ps1` in your project folder, is unblocked, and restarts automatically. This page opens in your browser.
5. The new version tells you it was updated and where the backup is.

Any photos loaded on the Process Photos tab are cleared when the tool restarts (your original photos are never touched). Finish or save your work first.

**If the tool doesn't restart, or Windows blocks the new file:** close the tool, then right-click `ES TLINE PTOOL.ps1` → **Properties** → tick **Unblock** → **OK**, and run it again (see [Unblocking and running the script](#unblocking-and-running-the-script)). If your IT department blocks scripts with Group Policy, ask IT to allow the new version.

**To go back to the old version:** copy the backup from `%LOCALAPPDATA%\ES_TLINE_PTOOL\update\backup\` into the project folder, rename it to `ES TLINE PTOOL.ps1`, then unblock and run it.

### Installing the update by hand

Use this after **Download only**, or if **Update now** didn't work.

1. **Close** ES TLINE PTOOL.
2. Copy the new `ES TLINE PTOOL.ps1` into your **project folder**, replacing the old one.
3. Right-click the new file → **Properties** → tick **Unblock** → **OK** (see [Unblocking and running the script](#unblocking-and-running-the-script)).
4. Run it as usual (right-click → **Run with PowerShell**).

Your photos, structure folders and settings are not affected by updating.

### Updating manually

1. Open the repository: <https://github.com/drewtoma/ES-TLINE-PTOOL>
2. Click **`ES TLINE PTOOL.ps1`** → **Download raw file** (the download icon).
3. Follow *Installing the update by hand* above.

If you have several projects, update the copy in each project folder.

### For maintainers – publishing a new version

1. In the script, change `ToolVersion = '0.3'` (near the top, in the CONFIG section) to the new number, e.g. `'0.4'`.
2. Update **`version.txt`** in the repository to the same number (just the number, e.g. `0.4`).
3. Upload the script to the repository as **`ES TLINE PTOOL.ps1`** on the **main** branch.

The tool compares its own `ToolVersion` with `version.txt` (if `version.txt` is missing it reads the version from the script on GitHub instead). Turn the check off by setting `UpdateCheck = $false` in the script's CONFIG section.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| **"NO GPS data"** | The camera's location was off. Retake, or get the original from the phone – some apps and messaging services strip GPS. |
| **Photo count mismatch** | Check the Cross Brace / X-Bracing ticks and the anomaly counts, or remove extra photos. |
| **Photos in the wrong order** | Fix with Move Up / Move Down, Ctrl+Up / Ctrl+Down, or drag the rows. |
| **Photo is sideways** | Select it and use Rotate Left / Rotate Right under the preview. |
| **HEIC (iPhone) photos won't open** | Set the iPhone to **Most Compatible**, or install the HEIF and HEVC extensions from the Microsoft Store. |
| **Can't drag photos from the phone** | Copy them to the PC first, then drag the files or folder in. |
| **"Before / After … already saved"** | That set exists. The tool never overwrites it – move the old folder out first if it really needs redoing. |
| **Red row on Project Status** | Hover over the row to see the exact problems. |
| **Tool closes with an error** | An error box explains it; details are saved to `%TEMP%\ES_TLINE_PTOOL_error.txt` (paste that into File Explorer's address bar). Send that file to whoever supports the tool. |
| **"Update available" every time** | Install the update (see [Updating](#updating)); make sure you replaced the copy in the project folder you actually run. |
| **Logo needs changing** | Put a `logo.png` in the project folder – see [Customising](#customising-the-logo-and-photo-stamp). |
| **"Some lines in settings.txt were ignored"** | The message lists each line and why. Fix or remove those lines in `settings.txt` (Instructions tab → **Open settings.txt**). |
| **Logo / text looks wrong on photos** | Check `settings.txt` in the project folder, or rename it to go back to the standard look. |

---

## Files the tool keeps on your PC

The tool stores a few small files of its own **on your PC, never in the project folder**:

| File | Purpose |
|---|---|
| `%LOCALAPPDATA%\ES_TLINE_PTOOL\status_<project>.clixml` | Last status-check results, shown instantly when the tool opens. |
| `%LOCALAPPDATA%\ES_TLINE_PTOOL\dates_<project>.txt` | Remembered photo dates, so unchanged photos aren't re-read. |
| `%LOCALAPPDATA%\ES_TLINE_PTOOL\update\` | Downloaded updates, and backups of earlier versions in `backup\`. |
| `%TEMP%\ES_TLINE_PTOOL_error.txt` | Error log (only written if something goes wrong). |

These can be deleted at any time; the tool simply rebuilds them.

Optional files **you** can put in the project folder: `logo.png` (your logo) and `settings.txt` (see [Customising](#customising-the-logo-and-photo-stamp)).
