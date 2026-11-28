-- ============================================================================
-- win32_gdiplus.lua
-- Pure LuaJIT FFI bindings for Win32 Layered Windows, GDI, GDI+, Shell32,
-- Comdlg32, and a minimal JSON codec for MAW Monster HP Overlay.
-- Hardened for in-process MMExtension / LuaJIT 2.0 execution:
--   * JIT compilation disabled on all FFI functions (jit.off)
--   * Zero FFI callbacks (uses raw C DefWindowProcW pointer via GetProcAddress)
--   * Zero ffi.gc finalizers
--   * Pre-allocated FFI structures for zero per-frame cdata churn
-- ============================================================================

if jit and jit.off then
    jit.off(true, true)
end

if _G._MAW_WIN32_GDIPLUS_MOD then
    return _G._MAW_WIN32_GDIPLUS_MOD
end

local ffi = require("ffi")
local bit = require("bit")
local band, bor, bxor, lshift, rshift = bit.band, bit.bor, bit.bxor, bit.lshift, bit.rshift

local M = {}
_G._MAW_WIN32_GDIPLUS_MOD = M

function M.disable_jit(tbl)
    if not (jit and jit.off) or type(tbl) ~= "table" then return end
    for _, v in pairs(tbl) do
        if type(v) == "function" then
            pcall(jit.off, v, true)
        end
    end
end

if not _G._MAW_FFI_CDEF_DONE then
ffi.cdef[[
typedef void* HANDLE;
typedef void* HWND;
typedef void* HDC;
typedef void* HGDIOBJ;
typedef void* HBITMAP;
typedef void* HBRUSH;
typedef void* HPEN;
typedef void* HFONT;
typedef void* HICON;
typedef void* HCURSOR;
typedef void* HMENU;
typedef void* HINSTANCE;
typedef void* HMODULE;
typedef unsigned long DWORD;
typedef unsigned short WORD;
typedef unsigned char BYTE;
typedef int BOOL;
typedef unsigned int UINT;
typedef long LONG;
typedef intptr_t LONG_PTR;
typedef uintptr_t UINT_PTR;
typedef UINT_PTR WPARAM;
typedef LONG_PTR LPARAM;
typedef LONG_PTR LRESULT;
typedef wchar_t WCHAR;
typedef const WCHAR* LPCWSTR;
typedef WCHAR* LPWSTR;
typedef const char* LPCSTR;
typedef DWORD COLORREF;

typedef LRESULT (__stdcall *WNDPROC)(HWND, UINT, WPARAM, LPARAM);

typedef struct {
    LONG x;
    LONG y;
} POINT;

typedef struct {
    LONG cx;
    LONG cy;
} SIZE;

typedef struct {
    LONG left;
    LONG top;
    LONG right;
    LONG bottom;
} RECT;

typedef struct {
    float X;
    float Y;
    float Width;
    float Height;
} RectF;

typedef struct {
    int X;
    int Y;
} PointI;

typedef struct {
    UINT cbSize;
    UINT style;
    WNDPROC lpfnWndProc;
    int cbClsExtra;
    int cbWndExtra;
    HINSTANCE hInstance;
    HICON hIcon;
    HCURSOR hCursor;
    HBRUSH hbrBackground;
    LPCWSTR lpszMenuName;
    LPCWSTR lpszClassName;
    HICON hIconSm;
} WNDCLASSEXW;

typedef struct {
    HWND hwnd;
    UINT message;
    WPARAM wParam;
    LPARAM lParam;
    DWORD time;
    POINT pt;
} MSG;

typedef struct {
    DWORD biSize;
    LONG biWidth;
    LONG biHeight;
    WORD biPlanes;
    WORD biBitCount;
    DWORD biCompression;
    DWORD biSizeImage;
    LONG biXPelsPerMeter;
    LONG biYPelsPerMeter;
    DWORD biClrUsed;
    DWORD biClrImportant;
} BITMAPINFOHEADER;

typedef struct {
    BITMAPINFOHEADER bmiHeader;
    DWORD bmiColors[1];
} BITMAPINFO;

typedef struct {
    BYTE BlendOp;
    BYTE BlendFlags;
    BYTE SourceConstantAlpha;
    BYTE AlphaFormat;
} BLENDFUNCTION;

typedef struct {
    HDC hdc;
    BOOL fErase;
    RECT rcPaint;
    BOOL fRestore;
    BOOL fIncUpdate;
    BYTE rgbReserved[32];
} PAINTSTRUCT;

typedef struct {
    DWORD cbSize;
    HWND hWnd;
    UINT uID;
    UINT uFlags;
    UINT uCallbackMessage;
    HICON hIcon;
    WCHAR szTip[64];
} NOTIFYICONDATAW;

typedef struct {
    DWORD lStructSize;
    HWND hwndOwner;
    HWND hInstance;
    COLORREF rgbResult;
    COLORREF* lpCustColors;
    DWORD Flags;
    LPARAM lCustData;
    void* lpfnHook;
    LPCWSTR lpTemplateName;
} CHOOSECOLORW;

typedef struct {
    DWORD dwSize;
    DWORD dwICC;
} INITCOMMONCONTROLSEX;

// Kernel32
HMODULE __stdcall GetModuleHandleW(LPCWSTR lpModuleName);
int __stdcall MultiByteToWideChar(UINT CodePage, DWORD dwFlags, LPCSTR lpMultiByteStr, int cbMultiByte, LPWSTR lpWideCharStr, int cchWideChar);
int __stdcall WideCharToMultiByte(UINT CodePage, DWORD dwFlags, LPCWSTR lpWideCharStr, int cchWideChar, char* lpMultiByteStr, int cbMultiByte, LPCSTR lpDefaultChar, BOOL* lpUsedDefaultChar);
DWORD __stdcall GetTickCount(void);
BOOL __stdcall QueryPerformanceCounter(int64_t* lpPerformanceCount);
BOOL __stdcall QueryPerformanceFrequency(int64_t* lpFrequency);
void __stdcall Sleep(DWORD dwMilliseconds);

// User32
WORD __stdcall RegisterClassExW(const WNDCLASSEXW* lpwcx);
BOOL __stdcall UnregisterClassW(LPCWSTR lpClassName, HINSTANCE hInstance);
HWND __stdcall CreateWindowExW(DWORD dwExStyle, LPCWSTR lpClassName, LPCWSTR lpWindowName, DWORD dwStyle, int X, int Y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, void* lpParam);
BOOL __stdcall DestroyWindow(HWND hWnd);
BOOL __stdcall ShowWindow(HWND hWnd, int nCmdShow);
BOOL __stdcall UpdateWindow(HWND hWnd);
BOOL __stdcall SetWindowPos(HWND hWnd, HWND hWndInsertAfter, int X, int Y, int cx, int cy, UINT uFlags);
BOOL __stdcall MoveWindow(HWND hWnd, int X, int Y, int nWidth, int nHeight, BOOL bRepaint);
BOOL __stdcall UpdateLayeredWindow(HWND hWnd, HDC hdcDst, POINT* pptDst, SIZE* psize, HDC hdcSrc, POINT* pptSrc, COLORREF crKey, BLENDFUNCTION* pblend, DWORD dwFlags);
BOOL __stdcall PeekMessageW(MSG* lpMsg, HWND hWnd, UINT wMsgFilterMin, UINT wMsgFilterMax, UINT wRemoveMsg);
BOOL __stdcall TranslateMessage(const MSG* lpMsg);
LRESULT __stdcall DispatchMessageW(const MSG* lpMsg);
LRESULT __stdcall DefWindowProcW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
BOOL __stdcall PostMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
LRESULT __stdcall SendMessageW(HWND hWnd, UINT Msg, WPARAM wParam, LPARAM lParam);
int __stdcall GetSystemMetrics(int nIndex);
HICON __stdcall LoadIconW(HINSTANCE hInstance, LPCWSTR lpIconName);
HCURSOR __stdcall LoadCursorW(HINSTANCE hInstance, LPCWSTR lpCursorName);
BOOL __stdcall GetCursorPos(POINT* lpPoint);
BOOL __stdcall ScreenToClient(HWND hWnd, POINT* lpPoint);
BOOL __stdcall GetClientRect(HWND hWnd, RECT* lpRect);
BOOL __stdcall GetWindowRect(HWND hWnd, RECT* lpRect);
BOOL __stdcall InvalidateRect(HWND hWnd, const RECT* lpRect, BOOL bErase);
HDC __stdcall BeginPaint(HWND hWnd, PAINTSTRUCT* lpPaint);
BOOL __stdcall EndPaint(HWND hWnd, const PAINTSTRUCT* lpPaint);
int __stdcall FillRect(HDC hDC, const RECT* lprc, HBRUSH hbr);
int __stdcall FrameRect(HDC hDC, const RECT* lprc, HBRUSH hbr);
int __stdcall DrawTextW(HDC hdc, LPCWSTR lpchText, int cchText, RECT* lprc, UINT format);
int __stdcall GetWindowTextW(HWND hWnd, LPWSTR lpString, int nMaxCount);
int __stdcall GetWindowTextLengthW(HWND hWnd);
BOOL __stdcall SetWindowTextW(HWND hWnd, LPCWSTR lpString);
LONG __stdcall GetWindowLongW(HWND hWnd, int nIndex);
LONG __stdcall SetWindowLongW(HWND hWnd, int nIndex, LONG dwNewLong);
BOOL __stdcall EnableWindow(HWND hWnd, BOOL bEnable);
BOOL __stdcall IsWindow(HWND hWnd);
BOOL __stdcall IsWindowVisible(HWND hWnd);
BOOL __stdcall SetForegroundWindow(HWND hWnd);
int __stdcall MessageBoxW(HWND hWnd, LPCWSTR lpText, LPCWSTR lpCaption, UINT uType);
BOOL __stdcall RegisterHotKey(HWND hWnd, int id, UINT fsModifiers, UINT vk);
BOOL __stdcall UnregisterHotKey(HWND hWnd, int id);
HMENU __stdcall CreatePopupMenu(void);
BOOL __stdcall AppendMenuW(HMENU hMenu, UINT uFlags, UINT_PTR uIDNewItem, LPCWSTR lpNewItem);
UINT __stdcall TrackPopupMenu(HMENU hMenu, UINT uFlags, int x, int y, int nReserved, HWND hWnd, const RECT* prcRect);
BOOL __stdcall DestroyMenu(HMENU hMenu);
HDC __stdcall GetDC(HWND hWnd);
int __stdcall ReleaseDC(HWND hWnd, HDC hDC);

// Gdi32
HDC __stdcall CreateCompatibleDC(HDC hdc);
BOOL __stdcall DeleteDC(HDC hdc);
HBITMAP __stdcall CreateDIBSection(HDC hdc, const BITMAPINFO* pbmi, UINT usage, void** ppvBits, HANDLE hSection, DWORD offset);
HGDIOBJ __stdcall SelectObject(HDC hdc, HGDIOBJ h);
BOOL __stdcall DeleteObject(HGDIOBJ ho);
HBRUSH __stdcall CreateSolidBrush(COLORREF color);
HPEN __stdcall CreatePen(int iStyle, int cWidth, COLORREF color);
HFONT __stdcall CreateFontW(int cHeight, int cWidth, int cEscapement, int cOrientation, int cWeight, DWORD bItalic, DWORD bUnderline, DWORD cStrikeOut, DWORD iCharSet, DWORD iOutPrecision, DWORD iClipPrecision, DWORD iQuality, DWORD iPitchAndFamily, LPCWSTR pszFaceName);
int __stdcall SetBkMode(HDC hdc, int mode);
COLORREF __stdcall SetBkColor(HDC hdc, COLORREF color);
COLORREF __stdcall SetTextColor(HDC hdc, COLORREF color);
BOOL __stdcall BitBlt(HDC hdc, int x, int y, int cx, int cy, HDC hdcSrc, int x1, int y1, DWORD rop);
HGDIOBJ __stdcall GetStockObject(int i);

// Shell32, Comdlg32, Comctl32
BOOL __stdcall Shell_NotifyIconW(DWORD dwMessage, NOTIFYICONDATAW* lpData);
BOOL __stdcall ChooseColorW(CHOOSECOLORW* lpcc);
BOOL __stdcall InitCommonControlsEx(const INITCOMMONCONTROLSEX* picce);

// GDI+ Flat API
typedef int GpStatus;
typedef void GpGraphics;
typedef void GpBitmap;
typedef void GpImage;
typedef void GpBrush;
typedef void GpSolidFill;
typedef void GpPen;
typedef void GpFontFamily;
typedef void GpFont;
typedef void GpStringFormat;
typedef void GpPath;
typedef void GpFontCollection;
typedef void GpImageAttributes;
typedef DWORD ARGB;

typedef struct {
    uint32_t GdiplusVersion;
    void* DebugEventCallback;
    BOOL SuppressBackgroundThread;
    BOOL SuppressExternalCodecs;
} GdiplusStartupInput;

typedef struct {
    float m[5][5];
} ColorMatrix;

GpStatus __stdcall GdiplusStartup(UINT_PTR* token, const GdiplusStartupInput* input, void* output);
void __stdcall GdiplusShutdown(UINT_PTR token);

GpStatus __stdcall GdipCreateFromHDC(HDC hdc, GpGraphics** graphics);
GpStatus __stdcall GdipGetImageGraphicsContext(GpImage* image, GpGraphics** graphics);
GpStatus __stdcall GdipDeleteGraphics(GpGraphics* graphics);
GpStatus __stdcall GdipGraphicsClear(GpGraphics* graphics, ARGB color);

GpStatus __stdcall GdipSetSmoothingMode(GpGraphics* graphics, int smoothingMode);
GpStatus __stdcall GdipSetInterpolationMode(GpGraphics* graphics, int interpolationMode);
GpStatus __stdcall GdipSetPixelOffsetMode(GpGraphics* graphics, int pixelOffsetMode);
GpStatus __stdcall GdipSetCompositingMode(GpGraphics* graphics, int compositingMode);
GpStatus __stdcall GdipSetCompositingQuality(GpGraphics* graphics, int compositingQuality);
GpStatus __stdcall GdipSetTextRenderingHint(GpGraphics* graphics, int mode);

GpStatus __stdcall GdipCreateBitmapFromScan0(int width, int height, int stride, int format, BYTE* scan0, GpBitmap** bitmap);
GpStatus __stdcall GdipCreateBitmapFromFile(LPCWSTR filename, GpBitmap** bitmap);
GpStatus __stdcall GdipDisposeImage(GpImage* image);
GpStatus __stdcall GdipGetImageWidth(GpImage* image, UINT* width);
GpStatus __stdcall GdipGetImageHeight(GpImage* image, UINT* height);

GpStatus __stdcall GdipDrawImageRectI(GpGraphics* graphics, GpImage* image, int x, int y, int width, int height);
GpStatus __stdcall GdipDrawImageRectRectI(GpGraphics* graphics, GpImage* image, int dstx, int dsty, int dstwidth, int dstheight, int srcx, int srcy, int srcwidth, int srcheight, int srcUnit, const GpImageAttributes* imageAttributes, void* callback, void* callbackData);

GpStatus __stdcall GdipCreateImageAttributes(GpImageAttributes** imageattr);
GpStatus __stdcall GdipDisposeImageAttributes(GpImageAttributes* imageattr);
GpStatus __stdcall GdipSetImageAttributesColorMatrix(GpImageAttributes* imageattr, int type, BOOL enableFlag, const ColorMatrix* colorMatrix, const ColorMatrix* grayMatrix, int flags);

GpStatus __stdcall GdipCreateSolidFill(ARGB color, GpSolidFill** brush);
GpStatus __stdcall GdipDeleteBrush(GpBrush* brush);
GpStatus __stdcall GdipCreatePen1(ARGB color, float width, int unit, GpPen** pen);
GpStatus __stdcall GdipDeletePen(GpPen* pen);
GpStatus __stdcall GdipSetPenLineJoin(GpPen* pen, int lineJoin);

GpStatus __stdcall GdipFillRectangleI(GpGraphics* graphics, GpBrush* brush, int x, int y, int width, int height);
GpStatus __stdcall GdipDrawRectangleI(GpGraphics* graphics, GpPen* pen, int x, int y, int width, int height);
GpStatus __stdcall GdipFillEllipseI(GpGraphics* graphics, GpBrush* brush, int x, int y, int width, int height);
GpStatus __stdcall GdipDrawEllipseI(GpGraphics* graphics, GpPen* pen, int x, int y, int width, int height);
GpStatus __stdcall GdipFillPolygonI(GpGraphics* graphics, GpBrush* brush, const PointI* points, int count, int fillMode);
GpStatus __stdcall GdipDrawPolygonI(GpGraphics* graphics, GpPen* pen, const PointI* points, int count);
GpStatus __stdcall GdipDrawLineI(GpGraphics* graphics, GpPen* pen, int x1, int y1, int x2, int y2);
GpStatus __stdcall GdipFillPie(GpGraphics* graphics, GpBrush* brush, float x, float y, float width, float height, float startAngle, float sweepAngle);

GpStatus __stdcall GdipNewPrivateFontCollection(GpFontCollection** fontCollection);
GpStatus __stdcall GdipDeletePrivateFontCollection(GpFontCollection** fontCollection);
GpStatus __stdcall GdipPrivateAddFontFile(GpFontCollection* fontCollection, LPCWSTR filename);
GpStatus __stdcall GdipGetFontCollectionFamilyCount(GpFontCollection* fontCollection, int* numFound);
GpStatus __stdcall GdipGetFontCollectionFamilyList(GpFontCollection* fontCollection, int numSought, GpFontFamily* gpfamilies[], int* numFound);
GpStatus __stdcall GdipCreateFontFamilyFromName(LPCWSTR name, GpFontCollection* fontCollection, GpFontFamily** fontFamily);
GpStatus __stdcall GdipDeleteFontFamily(GpFontFamily* fontFamily);
GpStatus __stdcall GdipCreateFont(const GpFontFamily* fontFamily, float emSize, int style, int unit, GpFont** font);
GpStatus __stdcall GdipDeleteFont(GpFont* font);

GpStatus __stdcall GdipCreateStringFormat(int formatAttributes, int language, GpStringFormat** format);
GpStatus __stdcall GdipDeleteStringFormat(GpStringFormat* format);
GpStatus __stdcall GdipSetStringFormatAlign(GpStringFormat* format, int align);
GpStatus __stdcall GdipSetStringFormatLineAlign(GpStringFormat* format, int align);
GpStatus __stdcall GdipSetStringFormatFlags(GpStringFormat* format, int flags);

GpStatus __stdcall GdipCreatePath(int brushMode, GpPath** path);
GpStatus __stdcall GdipDeletePath(GpPath* path);
GpStatus __stdcall GdipResetPath(GpPath* path);
GpStatus __stdcall GdipAddPathString(GpPath* path, LPCWSTR string, int length, const GpFontFamily* family, int style, float emSize, const RectF* layoutRect, const GpStringFormat* format);
GpStatus __stdcall GdipGetPathWorldBounds(GpPath* path, RectF* bounds, const void* matrix, const GpPen* pen);
GpStatus __stdcall GdipDrawPath(GpGraphics* graphics, GpPen* pen, GpPath* path);
GpStatus __stdcall GdipFillPath(GpGraphics* graphics, GpBrush* brush, GpPath* path);
]]
_G._MAW_FFI_CDEF_DONE = true
end

if not _G._MAW_FFI_CDEF_V2_DONE then
ffi.cdef[[
typedef struct {
    UINT cbSize;
    UINT style;
    void* lpfnWndProc;
    int cbClsExtra;
    int cbWndExtra;
    HINSTANCE hInstance;
    HICON hIcon;
    HCURSOR hCursor;
    HBRUSH hbrBackground;
    LPCWSTR lpszMenuName;
    LPCWSTR lpszClassName;
    HICON hIconSm;
} MAW_WNDCLASSEXW;

typedef struct {
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
} FILETIME;

typedef struct {
    DWORD dwFileAttributes;
    FILETIME ftCreationTime;
    FILETIME ftLastAccessTime;
    FILETIME ftLastWriteTime;
    DWORD nFileSizeHigh;
    DWORD nFileSizeLow;
    DWORD dwReserved0;
    DWORD dwReserved1;
    WCHAR cFileName[260];
    WCHAR cAlternateFileName[14];
} WIN32_FIND_DATAW;

void* __stdcall GetProcAddress(HMODULE hModule, LPCSTR lpProcName);
HANDLE __stdcall FindFirstFileW(LPCWSTR lpFileName, WIN32_FIND_DATAW* lpFindFileData);
BOOL __stdcall FindNextFileW(HANDLE hFindFile, WIN32_FIND_DATAW* lpFindFileData);
BOOL __stdcall FindClose(HANDLE hFindFile);
]]
_G._MAW_FFI_CDEF_V2_DONE = true
end

local kernel32 = ffi.load("kernel32")
local user32   = ffi.load("user32")
local gdi32    = ffi.load("gdi32")
local shell32  = ffi.load("shell32")
local comdlg32 = ffi.load("comdlg32")
local comctl32 = ffi.load("comctl32")
local gdiplus  = ffi.load("gdiplus")

M.kernel32 = kernel32
M.user32   = user32
M.gdi32    = gdi32
M.shell32  = shell32
M.comdlg32 = comdlg32
M.comctl32 = comctl32
M.gdiplus  = gdiplus

-- Initialize common controls (for trackbars/sliders in Settings UI)
local icc = ffi.new("INITCOMMONCONTROLSEX")
icc.dwSize = ffi.sizeof("INITCOMMONCONTROLSEX")
icc.dwICC = 0x00000004 -- ICC_BAR_CLASSES
comctl32.InitCommonControlsEx(icc)

-- Constants
M.WS_POPUP         = 0x80000000
M.WS_CHILD         = 0x40000000
M.WS_VISIBLE       = 0x10000000
M.WS_CAPTION       = 0x00C00000
M.WS_SYSMENU       = 0x00080000
M.WS_MINIMIZEBOX   = 0x00020000
M.WS_CLIPCHILDREN  = 0x02000000
M.WS_TABSTOP       = 0x00010000
M.WS_VSCROLL       = 0x00200000
M.WS_BORDER        = 0x00800000

M.WS_EX_LAYERED     = 0x00080000
M.WS_EX_TRANSPARENT = 0x00000020
M.WS_EX_TOPMOST     = 0x00000008
M.WS_EX_TOOLWINDOW  = 0x00000080
M.WS_EX_NOACTIVATE  = 0x08000000

M.WM_DESTROY       = 0x0002
M.WM_CLOSE         = 0x0010
M.WM_PAINT         = 0x000F
M.WM_ERASEBKGND    = 0x0014
M.WM_COMMAND       = 0x0111
M.WM_HSCROLL       = 0x0114
M.WM_CTLCOLORSTATIC = 0x0138
M.WM_CTLCOLORBTN   = 0x0135
M.WM_CTLCOLOREDIT  = 0x0133
M.WM_CTLCOLORLISTBOX = 0x0134
M.WM_DRAWITEM      = 0x002B
M.WM_HOTKEY        = 0x0312
M.WM_USER          = 0x0400
M.WM_TRAYICON      = 0x0400 + 20
M.WM_RBUTTONUP     = 0x0205
M.WM_LBUTTONDBLCLK = 0x0203
M.WM_LBUTTONDOWN   = 0x0201

M.PixelFormat32bppARGB  = 0x0026200A
M.PixelFormat32bppPARGB = 0x000E200B
M.UnitWorld = 0
M.UnitPixel = 2

-- High-precision timer
local qpc_freq = ffi.new("int64_t[1]")
local has_qpc = kernel32.QueryPerformanceFrequency(qpc_freq) ~= 0 and qpc_freq[0] > 0
local qpc_cnt = ffi.new("int64_t[1]")

function M.now()
    if has_qpc and kernel32.QueryPerformanceCounter(qpc_cnt) ~= 0 then
        return tonumber(qpc_cnt[0]) / tonumber(qpc_freq[0])
    end
    return tonumber(kernel32.GetTickCount()) / 1000.0
end

-- UTF-8 <-> WideString Helpers
function M.W(str)
    if not str then return nil end
    str = tostring(str)
    local len = kernel32.MultiByteToWideChar(65001, 0, str, #str, nil, 0)
    local buf = ffi.new("WCHAR[?]", len + 1)
    kernel32.MultiByteToWideChar(65001, 0, str, #str, buf, len)
    buf[len] = 0
    return buf
end

function M.from_W(wstr)
    if wstr == nil then return "" end
    local len = kernel32.WideCharToMultiByte(65001, 0, wstr, -1, nil, 0, nil, nil)
    if len <= 1 then return "" end
    local buf = ffi.new("char[?]", len)
    kernel32.WideCharToMultiByte(65001, 0, wstr, -1, buf, len, nil, nil)
    return ffi.string(buf, len - 1)
end

-- Raw C pointer to user32.dll!DefWindowProcW (avoids any LuaJIT FFI callback trampoline!)
local h_user32 = kernel32.GetModuleHandleW(M.W("user32.dll"))
M.DefWindowProcW_ptr = kernel32.GetProcAddress(h_user32, "DefWindowProcW")

-- Native Win32 directory listing (avoids spawning cmd.exe via io.popen)
function M.list_dir(dir_path, folders_only)
    local results = {}
    local find_data = ffi.new("WIN32_FIND_DATAW")
    local search_path = dir_path:gsub("[/\\]+$", "") .. "\\*"
    local h_find = kernel32.FindFirstFileW(M.W(search_path), find_data)
    local INVALID_HANDLE = ffi.cast("HANDLE", -1)
    if h_find == INVALID_HANDLE or h_find == nil then
        return results
    end
    repeat
        local name = M.from_W(find_data.cFileName)
        if name ~= "" and name ~= "." and name ~= ".." then
            local is_dir = band(tonumber(find_data.dwFileAttributes) or 0, 0x10) ~= 0
            if folders_only then
                if is_dir then results[#results + 1] = name end
            else
                if not is_dir then results[#results + 1] = name end
            end
        end
    until kernel32.FindNextFileW(h_find, find_data) == 0
    kernel32.FindClose(h_find)
    return results
end

function M.ARGB(a, r, g, b)
    a = math.max(0, math.min(255, math.floor((a or 255) + 0.5)))
    r = math.max(0, math.min(255, math.floor((r or 0) + 0.5)))
    g = math.max(0, math.min(255, math.floor((g or 0) + 0.5)))
    b = math.max(0, math.min(255, math.floor((b or 0) + 0.5)))
    return tonumber(ffi.cast("uint32_t", bor(lshift(a, 24), lshift(r, 16), lshift(g, 8), b)))
end

function M.COLORREF(r, g, b)
    r = math.max(0, math.min(255, math.floor((r or 0) + 0.5)))
    g = math.max(0, math.min(255, math.floor((g or 0) + 0.5)))
    b = math.max(0, math.min(255, math.floor((b or 0) + 0.5)))
    return bor(r, lshift(g, 8), lshift(b, 16))
end

-- GDI+ Startup / Shutdown
local gdip_token = ffi.new("UINT_PTR[1]", 0)
function M.init_gdiplus()
    if gdip_token[0] == 0 then
        local input = ffi.new("GdiplusStartupInput")
        input.GdiplusVersion = 1
        input.DebugEventCallback = nil
        input.SuppressBackgroundThread = 0
        input.SuppressExternalCodecs = 0
        gdiplus.GdiplusStartup(gdip_token, input, nil)
    end
end

-- Cached opacity ImageAttributes (no ffi.gc used)
local opacity_attr_cache = {}
function M.get_opacity_attr(opacity)
    opacity = math.max(0, math.min(255, math.floor(opacity + 0.5)))
    if opacity >= 255 then return nil end
    local attr = opacity_attr_cache[opacity]
    if not attr then
        local p_attr = ffi.new("GpImageAttributes*[1]")
        if gdiplus.GdipCreateImageAttributes(p_attr) == 0 and p_attr[0] ~= nil then
            local cm = ffi.new("ColorMatrix")
            cm.m[0][0] = 1.0
            cm.m[1][1] = 1.0
            cm.m[2][2] = 1.0
            cm.m[3][3] = opacity / 255.0
            cm.m[4][4] = 1.0
            gdiplus.GdipSetImageAttributesColorMatrix(p_attr[0], 0, 1, cm, nil, 0)
            attr = p_attr[0]
            opacity_attr_cache[opacity] = attr
        end
    end
    return attr
end

function M.shutdown_gdiplus()
    for k, attr in pairs(opacity_attr_cache) do
        if attr ~= nil then
            gdiplus.GdipDisposeImageAttributes(attr)
        end
        opacity_attr_cache[k] = nil
    end
    if gdip_token[0] ~= 0 then
        gdiplus.GdiplusShutdown(gdip_token[0])
        gdip_token[0] = 0
    end
end

M.init_gdiplus()

-- Pre-allocated FFI Scratch Buffers (avoids per-frame cdata allocation & GC pressure)
local shared_p_br    = ffi.new("GpSolidFill*[1]")
local shared_p_pen   = ffi.new("GpPen*[1]")
local shared_p_path  = ffi.new("GpPath*[1]")
local shared_bounds  = ffi.new("RectF")
local shared_layout  = ffi.new("RectF")
local shared_drawrc  = ffi.new("RectF")
local shared_pts     = ffi.new("PointI[32]")
local shared_pt_dst  = ffi.new("POINT", {0, 0})
local shared_pt_src  = ffi.new("POINT", {0, 0})
local shared_sz      = ffi.new("SIZE", {0, 0})
local shared_blend   = ffi.new("BLENDFUNCTION", {0, 0, 255, 1})
local shared_msg     = ffi.new("MSG")

-- ============================================================================
-- GDI+ Bitmap & Surface Wrapper
-- ============================================================================
local Surface = {}
Surface.__index = Surface

local function configure_graphics(gfx, high_quality)
    if not gfx then return end
    gdiplus.GdipSetSmoothingMode(gfx, 4) -- SmoothingModeAntiAlias
    gdiplus.GdipSetInterpolationMode(gfx, high_quality and 7 or 2) -- HighQualityBicubic or Bilinear
    gdiplus.GdipSetPixelOffsetMode(gfx, 4) -- PixelOffsetModeHalf
    gdiplus.GdipSetCompositingMode(gfx, 0) -- CompositingModeSourceOver
    gdiplus.GdipSetTextRenderingHint(gfx, 4) -- TextRenderingHintAntiAlias
end

function M.create_surface(w, h, pargb)
    w = math.max(1, math.floor(w))
    h = math.max(1, math.floor(h))
    local fmt = pargb and M.PixelFormat32bppPARGB or M.PixelFormat32bppARGB
    local p_bmp = ffi.new("GpBitmap*[1]")
    if gdiplus.GdipCreateBitmapFromScan0(w, h, 0, fmt, nil, p_bmp) ~= 0 or p_bmp[0] == nil then
        return nil
    end
    local p_gfx = ffi.new("GpGraphics*[1]")
    if gdiplus.GdipGetImageGraphicsContext(p_bmp[0], p_gfx) ~= 0 or p_gfx[0] == nil then
        gdiplus.GdipDisposeImage(p_bmp[0])
        return nil
    end
    configure_graphics(p_gfx[0], true)
    local self = setmetatable({
        w = w,
        h = h,
        bmp = p_bmp[0],
        gfx = p_gfx[0],
        disposed = false,
    }, Surface)
    return self
end

function M.create_dib_surface(w, h)
    w = math.max(1, math.floor(w))
    h = math.max(1, math.floor(h))
    local hdc_screen = user32.GetDC(nil)
    local hdc_mem = gdi32.CreateCompatibleDC(hdc_screen)
    local bmi = ffi.new("BITMAPINFO")
    bmi.bmiHeader.biSize = ffi.sizeof("BITMAPINFOHEADER")
    bmi.bmiHeader.biWidth = w
    bmi.bmiHeader.biHeight = -h -- top-down
    bmi.bmiHeader.biPlanes = 1
    bmi.bmiHeader.biBitCount = 32
    bmi.bmiHeader.biCompression = 0

    local p_bits = ffi.new("void*[1]")
    local hbmp = gdi32.CreateDIBSection(hdc_screen, bmi, 0, p_bits, nil, 0)
    local old_bmp = gdi32.SelectObject(hdc_mem, hbmp)
    user32.ReleaseDC(nil, hdc_screen)

    local p_bmp = ffi.new("GpBitmap*[1]")
    gdiplus.GdipCreateBitmapFromScan0(w, h, w * 4, M.PixelFormat32bppPARGB, ffi.cast("BYTE*", p_bits[0]), p_bmp)
    local p_gfx = ffi.new("GpGraphics*[1]")
    gdiplus.GdipGetImageGraphicsContext(p_bmp[0], p_gfx)
    configure_graphics(p_gfx[0], false)

    local self = setmetatable({
        w = w,
        h = h,
        hdc = hdc_mem,
        hbmp = hbmp,
        old_bmp = old_bmp,
        bits = p_bits[0],
        bmp = p_bmp[0],
        gfx = p_gfx[0],
        is_dib = true,
        disposed = false,
    }, Surface)
    return self
end

function M.load_bitmap(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    f:close()
    local p_bmp = ffi.new("GpBitmap*[1]")
    if gdiplus.GdipCreateBitmapFromFile(M.W(path), p_bmp) ~= 0 or p_bmp[0] == nil then
        return nil
    end
    local pw = ffi.new("UINT[1]", 0)
    local ph = ffi.new("UINT[1]", 0)
    gdiplus.GdipGetImageWidth(p_bmp[0], pw)
    gdiplus.GdipGetImageHeight(p_bmp[0], ph)
    return setmetatable({
        w = tonumber(pw[0]),
        h = tonumber(ph[0]),
        bmp = p_bmp[0],
        gfx = nil,
        disposed = false,
    }, Surface)
end

function Surface:dispose()
    if self.disposed then return end
    self.disposed = true
    if self.gfx then
        gdiplus.GdipDeleteGraphics(self.gfx)
        self.gfx = nil
    end
    if self.bmp then
        gdiplus.GdipDisposeImage(self.bmp)
        self.bmp = nil
    end
    if self.is_dib then
        if self.hdc and self.old_bmp then
            gdi32.SelectObject(self.hdc, self.old_bmp)
        end
        if self.hbmp then gdi32.DeleteObject(self.hbmp) end
        if self.hdc then gdi32.DeleteDC(self.hdc) end
    end
end

function Surface:clear(a, r, g, b)
    if not a or (a == 0 and (not r or r == 0)) then
        if self.is_dib and self.bits then
            ffi.fill(self.bits, self.w * self.h * 4, 0)
        elseif self.gfx then
            gdiplus.GdipGraphicsClear(self.gfx, 0)
        end
    elseif self.gfx then
        gdiplus.GdipGraphicsClear(self.gfx, M.ARGB(a, r, g, b))
    end
end

function Surface:draw_image(img, x, y, w, h, opacity, anchor)
    if not img or not img.bmp or not self.gfx then return end
    w = math.floor((w or img.w) + 0.5)
    h = math.floor((h or img.h) + 0.5)
    if w <= 0 or h <= 0 then return end
    if anchor == "center" then
        x = x - math.floor(w / 2)
        y = y - math.floor(h / 2)
    elseif anchor == "w" then
        y = y - math.floor(h / 2)
    elseif anchor == "e" then
        x = x - w
        y = y - math.floor(h / 2)
    elseif anchor == "n" then
        x = x - math.floor(w / 2)
    elseif anchor == "s" then
        x = x - math.floor(w / 2)
        y = y - h
    elseif anchor == "sw" then
        y = y - h
    elseif anchor == "se" then
        x = x - w
        y = y - h
    elseif anchor == "ne" then
        x = x - w
    end
    x = math.floor(x + 0.5)
    y = math.floor(y + 0.5)
    opacity = opacity or 255
    if opacity <= 0 then return end
    if opacity >= 255 then
        gdiplus.GdipDrawImageRectI(self.gfx, img.bmp, x, y, w, h)
    else
        local attr = M.get_opacity_attr(opacity)
        gdiplus.GdipDrawImageRectRectI(
            self.gfx, img.bmp,
            x, y, w, h,
            0, 0, img.w, img.h,
            M.UnitPixel, attr, nil, nil
        )
    end
end

function Surface:draw_image_crop(img, dst_x, dst_y, dst_w, dst_h, src_x, src_y, src_w, src_h, opacity)
    if not img or not img.bmp or not self.gfx then return end
    dst_w = math.floor(dst_w + 0.5)
    dst_h = math.floor(dst_h + 0.5)
    if dst_w <= 0 or dst_h <= 0 or src_w <= 0 or src_h <= 0 then return end
    dst_x = math.floor(dst_x + 0.5)
    dst_y = math.floor(dst_y + 0.5)
    opacity = opacity or 255
    if opacity <= 0 then return end
    local attr = (opacity < 255) and M.get_opacity_attr(opacity) or nil
    gdiplus.GdipDrawImageRectRectI(
        self.gfx, img.bmp,
        dst_x, dst_y, dst_w, dst_h,
        math.floor(src_x), math.floor(src_y), math.floor(src_w), math.floor(src_h),
        M.UnitPixel, attr, nil, nil
    )
end

function Surface:fill_rect(x, y, w, h, a, r, g, b)
    if not self.gfx or w <= 0 or h <= 0 or a <= 0 then return end
    shared_p_br[0] = nil
    if gdiplus.GdipCreateSolidFill(M.ARGB(a, r, g, b), shared_p_br) == 0 and shared_p_br[0] ~= nil then
        gdiplus.GdipFillRectangleI(self.gfx, shared_p_br[0], math.floor(x + 0.5), math.floor(y + 0.5), math.floor(w + 0.5), math.floor(h + 0.5))
        gdiplus.GdipDeleteBrush(shared_p_br[0])
    end
end

function Surface:draw_rect(x, y, w, h, pen_w, a, r, g, b)
    if not self.gfx or w <= 0 or h <= 0 or a <= 0 then return end
    shared_p_pen[0] = nil
    if gdiplus.GdipCreatePen1(M.ARGB(a, r, g, b), pen_w or 1, M.UnitPixel, shared_p_pen) == 0 and shared_p_pen[0] ~= nil then
        gdiplus.GdipDrawRectangleI(self.gfx, shared_p_pen[0], math.floor(x + 0.5), math.floor(y + 0.5), math.floor(w + 0.5), math.floor(h + 0.5))
        gdiplus.GdipDeletePen(shared_p_pen[0])
    end
end

function Surface:fill_ellipse(x, y, w, h, a, r, g, b)
    if not self.gfx or w <= 0 or h <= 0 or a <= 0 then return end
    shared_p_br[0] = nil
    if gdiplus.GdipCreateSolidFill(M.ARGB(a, r, g, b), shared_p_br) == 0 and shared_p_br[0] ~= nil then
        gdiplus.GdipFillEllipseI(self.gfx, shared_p_br[0], math.floor(x + 0.5), math.floor(y + 0.5), math.floor(w + 0.5), math.floor(h + 0.5))
        gdiplus.GdipDeleteBrush(shared_p_br[0])
    end
end

function Surface:draw_ellipse(x, y, w, h, pen_w, a, r, g, b)
    if not self.gfx or w <= 0 or h <= 0 or a <= 0 then return end
    shared_p_pen[0] = nil
    if gdiplus.GdipCreatePen1(M.ARGB(a, r, g, b), pen_w or 1, M.UnitPixel, shared_p_pen) == 0 and shared_p_pen[0] ~= nil then
        gdiplus.GdipDrawEllipseI(self.gfx, shared_p_pen[0], math.floor(x + 0.5), math.floor(y + 0.5), math.floor(w + 0.5), math.floor(h + 0.5))
        gdiplus.GdipDeletePen(shared_p_pen[0])
    end
end

function Surface:fill_polygon(pts, a, r, g, b)
    if not self.gfx or not pts or #pts < 3 or a <= 0 then return end
    local n = math.min(32, #pts)
    for i = 1, n do
        shared_pts[i - 1].X = math.floor(pts[i][1] + 0.5)
        shared_pts[i - 1].Y = math.floor(pts[i][2] + 0.5)
    end
    shared_p_br[0] = nil
    if gdiplus.GdipCreateSolidFill(M.ARGB(a, r, g, b), shared_p_br) == 0 and shared_p_br[0] ~= nil then
        gdiplus.GdipFillPolygonI(self.gfx, shared_p_br[0], shared_pts, n, 0)
        gdiplus.GdipDeleteBrush(shared_p_br[0])
    end
end

function Surface:draw_polygon(pts, pen_w, a, r, g, b)
    if not self.gfx or not pts or #pts < 2 or a <= 0 then return end
    local n = math.min(32, #pts)
    for i = 1, n do
        shared_pts[i - 1].X = math.floor(pts[i][1] + 0.5)
        shared_pts[i - 1].Y = math.floor(pts[i][2] + 0.5)
    end
    shared_p_pen[0] = nil
    if gdiplus.GdipCreatePen1(M.ARGB(a, r, g, b), pen_w or 1, M.UnitPixel, shared_p_pen) == 0 and shared_p_pen[0] ~= nil then
        gdiplus.GdipDrawPolygonI(self.gfx, shared_p_pen[0], shared_pts, n)
        gdiplus.GdipDeletePen(shared_p_pen[0])
    end
end

function Surface:draw_line(x1, y1, x2, y2, pen_w, a, r, g, b)
    if not self.gfx or a <= 0 then return end
    shared_p_pen[0] = nil
    if gdiplus.GdipCreatePen1(M.ARGB(a, r, g, b), pen_w or 1, M.UnitPixel, shared_p_pen) == 0 and shared_p_pen[0] ~= nil then
        gdiplus.GdipDrawLineI(self.gfx, shared_p_pen[0], math.floor(x1 + 0.5), math.floor(y1 + 0.5), math.floor(x2 + 0.5), math.floor(y2 + 0.5))
        gdiplus.GdipDeletePen(shared_p_pen[0])
    end
end

function Surface:fill_pie(x, y, w, h, start_angle, sweep_angle, a, r, g, b)
    if not self.gfx or w <= 0 or h <= 0 or a <= 0 or math.abs(sweep_angle) < 0.1 then return end
    shared_p_br[0] = nil
    if gdiplus.GdipCreateSolidFill(M.ARGB(a, r, g, b), shared_p_br) == 0 and shared_p_br[0] ~= nil then
        gdiplus.GdipFillPie(self.gfx, shared_p_br[0], x, y, w, h, start_angle, sweep_angle)
        gdiplus.GdipDeleteBrush(shared_p_br[0])
    end
end

-- ============================================================================
-- Custom Font Loader & Outlined Text Renderer
-- ============================================================================
local font_family_cache = {}
local font_col_cache = {}
local str_fmt = nil

local function get_string_format()
    if not str_fmt then
        local p_fmt = ffi.new("GpStringFormat*[1]")
        if gdiplus.GdipCreateStringFormat(0, 0, p_fmt) == 0 then
            gdiplus.GdipSetStringFormatAlign(p_fmt[0], 0) -- Near
            gdiplus.GdipSetStringFormatLineAlign(p_fmt[0], 0)
            gdiplus.GdipSetStringFormatFlags(p_fmt[0], 0x00001000) -- NoWrap
            str_fmt = p_fmt[0]
        end
    end
    return str_fmt
end

function M.get_font_family(font_path)
    if font_path and font_family_cache[font_path] then
        return font_family_cache[font_path]
    end
    if font_path then
        local f = io.open(font_path, "rb")
        if f then
            f:close()
            local p_col = ffi.new("GpFontCollection*[1]")
            if gdiplus.GdipNewPrivateFontCollection(p_col) == 0 and p_col[0] ~= nil then
                if gdiplus.GdipPrivateAddFontFile(p_col[0], M.W(font_path)) == 0 then
                    local count = ffi.new("int[1]", 0)
                    gdiplus.GdipGetFontCollectionFamilyCount(p_col[0], count)
                    if count[0] > 0 then
                        local fams = ffi.new("GpFontFamily*[1]")
                        local found = ffi.new("int[1]", 0)
                        if gdiplus.GdipGetFontCollectionFamilyList(p_col[0], 1, fams, found) == 0 and found[0] > 0 then
                            font_col_cache[font_path] = p_col[0]
                            font_family_cache[font_path] = fams[0]
                            return fams[0]
                        end
                    end
                end
            end
        end
    end
    -- Fallback to Segoe UI or Arial
    if not font_family_cache["__default__"] then
        local p_fam = ffi.new("GpFontFamily*[1]")
        if gdiplus.GdipCreateFontFamilyFromName(M.W("Segoe UI"), nil, p_fam) ~= 0 or p_fam[0] == nil then
            gdiplus.GdipCreateFontFamilyFromName(M.W("Arial"), nil, p_fam)
        end
        font_family_cache["__default__"] = p_fam[0]
    end
    return font_family_cache["__default__"]
end

function M.render_text_surface(text, font_path, font_size, text_rgba, outline_width, outline_rgba, bold)
    text = tostring(text or "")
    if text == "" then return nil end
    local fam = M.get_font_family(font_path)
    if not fam then return nil end

    local style = bold and 1 or 0 -- 1 = FontStyleBold, 0 = Regular
    shared_p_path[0] = nil
    if gdiplus.GdipCreatePath(0, shared_p_path) ~= 0 or shared_p_path[0] == nil then return nil end

    shared_layout.X = 0
    shared_layout.Y = 0
    shared_layout.Width = 0
    shared_layout.Height = 0

    local wstr = M.W(text)
    local fmt = get_string_format()
    gdiplus.GdipAddPathString(shared_p_path[0], wstr, -1, fam, style, font_size, shared_layout, fmt)

    shared_bounds.X = 0
    shared_bounds.Y = 0
    shared_bounds.Width = 0
    shared_bounds.Height = 0
    gdiplus.GdipGetPathWorldBounds(shared_p_path[0], shared_bounds, nil, nil)
    gdiplus.GdipDeletePath(shared_p_path[0])

    local ow = math.max(0, outline_width or 0)
    local pad = ow + 3
    local w = math.max(4, math.ceil(shared_bounds.Width + pad * 2 + 4))
    local h = math.max(4, math.ceil(shared_bounds.Height + pad * 2 + 4))

    local surf = M.create_surface(w, h, false)
    if not surf then return nil end

    shared_p_path[0] = nil
    if gdiplus.GdipCreatePath(0, shared_p_path) == 0 and shared_p_path[0] ~= nil then
        shared_drawrc.X = pad - shared_bounds.X
        shared_drawrc.Y = pad - shared_bounds.Y
        shared_drawrc.Width = 0
        shared_drawrc.Height = 0
        gdiplus.GdipAddPathString(shared_p_path[0], wstr, -1, fam, style, font_size, shared_drawrc, fmt)

        if ow > 0 and outline_rgba then
            local oa = outline_rgba[4] or 255
            local or_ = outline_rgba[1] or 0
            local og = outline_rgba[2] or 0
            local ob = outline_rgba[3] or 0
            shared_p_pen[0] = nil
            if gdiplus.GdipCreatePen1(M.ARGB(oa, or_, og, ob), ow * 2.0, M.UnitPixel, shared_p_pen) == 0 and shared_p_pen[0] ~= nil then
                gdiplus.GdipSetPenLineJoin(shared_p_pen[0], 2) -- LineJoinRound
                gdiplus.GdipDrawPath(surf.gfx, shared_p_pen[0], shared_p_path[0])
                gdiplus.GdipDeletePen(shared_p_pen[0])
            end
        end

        local ta = (text_rgba and text_rgba[4]) or 255
        local tr = (text_rgba and text_rgba[1]) or 255
        local tg = (text_rgba and text_rgba[2]) or 255
        local tb = (text_rgba and text_rgba[3]) or 255
        shared_p_br[0] = nil
        if gdiplus.GdipCreateSolidFill(M.ARGB(ta, tr, tg, tb), shared_p_br) == 0 and shared_p_br[0] ~= nil then
            gdiplus.GdipFillPath(surf.gfx, shared_p_br[0], shared_p_path[0])
            gdiplus.GdipDeleteBrush(shared_p_br[0])
        end

        gdiplus.GdipDeletePath(shared_p_path[0])
    end

    return surf
end

-- ============================================================================
-- NativeLayeredWindow (Click-Through 32-bit Per-Pixel Alpha Overlay Window)
-- ============================================================================
local NativeLayeredWindow = {}
NativeLayeredWindow.__index = NativeLayeredWindow

local overlay_class_registered = false

function M.create_layered_window(width, height, title)
    local in_game = (_G.events ~= nil)
    local self = setmetatable({
        width = width,
        height = height,
        visible = true,
        in_game = in_game,
        tray_added = false,
        hotkey_id = 1,
        ID_TRAY_SETTINGS = 1001,
        ID_TRAY_TOGGLE   = 1002,
        ID_TRAY_EXIT     = 1003,
    }, NativeLayeredWindow)

    local hinst = kernel32.GetModuleHandleW(nil)
    local cls_name = M.W("MAW_Lua_NativeOverlay_Class_V2")

    if not overlay_class_registered then
        local wc = ffi.new("MAW_WNDCLASSEXW")
        wc.cbSize = ffi.sizeof("MAW_WNDCLASSEXW")
        wc.style = 0
        wc.lpfnWndProc = M.DefWindowProcW_ptr
        wc.hInstance = hinst
        wc.hCursor = user32.LoadCursorW(nil, ffi.cast("LPCWSTR", 32512))
        wc.lpszClassName = cls_name
        user32.RegisterClassExW(ffi.cast("const WNDCLASSEXW*", wc))
        overlay_class_registered = true
    end

    local ex_style = bor(M.WS_EX_LAYERED, M.WS_EX_TRANSPARENT, M.WS_EX_TOPMOST, M.WS_EX_TOOLWINDOW, M.WS_EX_NOACTIVATE)
    self.hwnd = user32.CreateWindowExW(
        ex_style,
        cls_name,
        M.W(title or "MAW Lua Monster HP Overlay"),
        M.WS_POPUP,
        0, 0, width, height,
        nil, nil, hinst, nil
    )

    user32.ShowWindow(self.hwnd, 4) -- SW_SHOWNOACTIVATE = 4
    self.surface = M.create_dib_surface(width, height)

    -- Only register Win32 hotkeys / tray icon when running standalone outside mm8.exe
    -- (inside mm8.exe, MMExtension's events.KeyDown handles Ctrl+Shift+F12 & Ctrl+Shift+F11)
    if not self.in_game then
        user32.RegisterHotKey(self.hwnd, self.hotkey_id, 6, 0x7B)
        self:_setup_tray_icon()
    end

    return self
end

function NativeLayeredWindow:_setup_tray_icon()
    if self.in_game then return end
    local nid = ffi.new("NOTIFYICONDATAW")
    nid.cbSize = ffi.sizeof("NOTIFYICONDATAW")
    nid.hWnd = self.hwnd
    nid.uID = 1
    nid.uFlags = 0x01 + 0x02 + 0x04 -- NIF_MESSAGE | NIF_ICON | NIF_TIP
    nid.uCallbackMessage = M.WM_TRAYICON
    nid.hIcon = user32.LoadIconW(nil, ffi.cast("LPCWSTR", 32512))
    local tip = M.W("MAW Lua Monster HP Overlay (Ctrl+Shift+F12)")
    ffi.copy(nid.szTip, tip, math.min(ffi.sizeof(nid.szTip) - 2, ffi.sizeof(tip)))
    if shell32.Shell_NotifyIconW(0, nid) ~= 0 then -- NIM_ADD = 0
        self.nid = nid
        self.tray_added = true
    end
end

function NativeLayeredWindow:_show_tray_menu(app)
    local hmenu = user32.CreatePopupMenu()
    local toggle_lbl = self.visible and "Hide Overlay (Ctrl+Shift+F12)" or "Show Overlay (Ctrl+Shift+F12)"
    user32.AppendMenuW(hmenu, 0x0000, self.ID_TRAY_SETTINGS, M.W("Overlay Settings"))
    user32.AppendMenuW(hmenu, 0x0000, self.ID_TRAY_TOGGLE, M.W(toggle_lbl))
    user32.AppendMenuW(hmenu, 0x0800, 0, nil) -- MF_SEPARATOR
    user32.AppendMenuW(hmenu, 0x0000, self.ID_TRAY_EXIT, M.W("Exit Overlay"))

    local pt = ffi.new("POINT")
    user32.GetCursorPos(pt)
    user32.SetForegroundWindow(self.hwnd)
    local cmd = user32.TrackPopupMenu(hmenu, 0x0100 + 0x0002, pt.x, pt.y, 0, self.hwnd, nil)
    user32.PostMessageW(self.hwnd, 0, 0, 0)
    user32.DestroyMenu(hmenu)

    if cmd == self.ID_TRAY_SETTINGS and app and app.open_settings then
        app:open_settings()
    elseif cmd == self.ID_TRAY_TOGGLE and app and app.toggle_visibility then
        app:toggle_visibility()
    elseif cmd == self.ID_TRAY_EXIT and app then
        app.running = false
    end
end

function NativeLayeredWindow:resize(new_w, new_h)
    new_w = math.max(1, math.floor(new_w))
    new_h = math.max(1, math.floor(new_h))
    if new_w == self.width and new_h == self.height then return end
    if self.surface then self.surface:dispose() end
    self.width = new_w
    self.height = new_h
    self.surface = M.create_dib_surface(new_w, new_h)
    user32.SetWindowPos(self.hwnd, ffi.cast("HWND", -1), 0, 0, new_w, new_h, 0x0010 + 0x0002)
end

function NativeLayeredWindow:set_visible(vis)
    self.visible = vis and true or false
    if self.hwnd then
        user32.ShowWindow(self.hwnd, self.visible and 4 or 0) -- 4=SW_SHOWNOACTIVATE, 0=SW_HIDE
    end
end

function NativeLayeredWindow:pump_events(app)
    -- Inside mm8.exe, the game's own main thread loop pumps Win32 messages
    if self.in_game or not self.hwnd then return end
    while user32.PeekMessageW(shared_msg, self.hwnd, 0, 0, 1) ~= 0 do
        if shared_msg.message == M.WM_HOTKEY and tonumber(shared_msg.wParam) == self.hotkey_id then
            if app and app.toggle_visibility then app:toggle_visibility() end
        elseif shared_msg.message == M.WM_TRAYICON then
            local event = band(tonumber(shared_msg.lParam), 0xFFFF)
            if event == M.WM_RBUTTONUP then
                self:_show_tray_menu(app)
            elseif event == M.WM_LBUTTONDBLCLK then
                if app and app.open_settings then app:open_settings() end
            end
        end
        user32.TranslateMessage(shared_msg)
        user32.DispatchMessageW(shared_msg)
    end
end

function NativeLayeredWindow:present()
    if not self.visible or not self.surface or not self.hwnd then return end
    shared_pt_dst.x = 0
    shared_pt_dst.y = 0
    shared_pt_src.x = 0
    shared_pt_src.y = 0
    shared_sz.cx = self.width
    shared_sz.cy = self.height
    shared_blend.BlendOp = 0
    shared_blend.BlendFlags = 0
    shared_blend.SourceConstantAlpha = 255
    shared_blend.AlphaFormat = 1
    user32.UpdateLayeredWindow(self.hwnd, nil, shared_pt_dst, shared_sz, self.surface.hdc, shared_pt_src, 0, shared_blend, 2)
end

function NativeLayeredWindow:destroy()
    if self.tray_added and self.nid then
        shell32.Shell_NotifyIconW(2, self.nid) -- NIM_DELETE = 2
        self.tray_added = false
    end
    if self.hwnd then
        if not self.in_game then
            user32.UnregisterHotKey(self.hwnd, self.hotkey_id)
        end
        user32.DestroyWindow(self.hwnd)
        self.hwnd = nil
    end
    if self.surface then
        self.surface:dispose()
        self.surface = nil
    end
end

-- ============================================================================
-- Pure Lua JSON Codec (for overlay_settings.json, theme.json, visible_monsters.json)
-- ============================================================================
local function skip_ws(str, idx)
    while idx <= #str do
        local c = str:byte(idx)
        if c == 32 or c == 9 or c == 10 or c == 13 then
            idx = idx + 1
        else
            break
        end
    end
    return idx
end

local parse_value

local function parse_string(str, idx)
    idx = idx + 1 -- skip opening quote
    local out = {}
    while idx <= #str do
        local c = str:sub(idx, idx)
        if c == '"' then
            return table.concat(out), idx + 1
        elseif c == '\\' then
            idx = idx + 1
            local esc = str:sub(idx, idx)
            if esc == 'n' then out[#out + 1] = '\n'
            elseif esc == 'r' then out[#out + 1] = '\r'
            elseif esc == 't' then out[#out + 1] = '\t'
            elseif esc == '"' or esc == '\\' or esc == '/' then out[#out + 1] = esc
            elseif esc == 'u' then
                local hex = str:sub(idx + 1, idx + 4)
                local code = tonumber(hex, 16) or 63
                if code < 128 then out[#out + 1] = string.char(code) else out[#out + 1] = "?" end
                idx = idx + 4
            else
                out[#out + 1] = esc
            end
            idx = idx + 1
        else
            out[#out + 1] = c
            idx = idx + 1
        end
    end
    return table.concat(out), idx
end

local function parse_array(str, idx)
    idx = idx + 1 -- skip '['
    local arr = {}
    idx = skip_ws(str, idx)
    if str:sub(idx, idx) == ']' then return arr, idx + 1 end
    while idx <= #str do
        local val
        val, idx = parse_value(str, idx)
        arr[#arr + 1] = val
        idx = skip_ws(str, idx)
        local ch = str:sub(idx, idx)
        if ch == ']' then return arr, idx + 1
        elseif ch == ',' then idx = skip_ws(str, idx + 1)
        else break end
    end
    return arr, idx
end

local function parse_object(str, idx)
    idx = idx + 1 -- skip '{'
    local obj = {}
    idx = skip_ws(str, idx)
    if str:sub(idx, idx) == '}' then return obj, idx + 1 end
    while idx <= #str do
        idx = skip_ws(str, idx)
        if str:sub(idx, idx) ~= '"' then break end
        local key
        key, idx = parse_string(str, idx)
        idx = skip_ws(str, idx)
        if str:sub(idx, idx) == ':' then idx = idx + 1 end
        idx = skip_ws(str, idx)
        local val
        val, idx = parse_value(str, idx)
        obj[key] = val
        idx = skip_ws(str, idx)
        local ch = str:sub(idx, idx)
        if ch == '}' then return obj, idx + 1
        elseif ch == ',' then idx = skip_ws(str, idx + 1)
        else break end
    end
    return obj, idx
end

parse_value = function(str, idx)
    idx = skip_ws(str, idx)
    local ch = str:sub(idx, idx)
    if ch == '"' then return parse_string(str, idx)
    elseif ch == '{' then return parse_object(str, idx)
    elseif ch == '[' then return parse_array(str, idx)
    elseif str:sub(idx, idx + 3) == "true" then return true, idx + 4
    elseif str:sub(idx, idx + 4) == "false" then return false, idx + 5
    elseif str:sub(idx, idx + 3) == "null" then return nil, idx + 4
    else
        local s, e = str:find("^[%-]?%d+%.?%d*[eE]?[%+%-]?%d*", idx)
        if s then
            return tonumber(str:sub(s, e)), e + 1
        end
        return nil, idx + 1
    end
end

function M.json_decode(str)
    if type(str) ~= "string" or str == "" then return nil end
    local ok, res = pcall(function()
        local val = parse_value(str, 1)
        return val
    end)
    return ok and res or nil
end

local function is_array(t)
    local max_k = 0
    local count = 0
    for k, _ in pairs(t) do
        if type(k) ~= "number" or k < 1 or math.floor(k) ~= k then return false end
        if k > max_k then max_k = k end
        count = count + 1
    end
    return max_k == count
end

local function encode_val(v, indent)
    local tv = type(v)
    if tv == "string" then
        local esc = v:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t")
        return '"' .. esc .. '"'
    elseif tv == "number" then
        if v ~= v or v == math.huge or v == -math.huge then return "0" end
        return tostring(v)
    elseif tv == "boolean" then
        return v and "true" or "false"
    elseif tv == "table" then
        local pad = string.rep("    ", indent)
        local pad_in = string.rep("    ", indent + 1)
        if is_array(v) then
            local parts = {}
            for i = 1, #v do
                parts[i] = encode_val(v[i], indent + 1)
            end
            return "[" .. table.concat(parts, ", ") .. "]"
        else
            local keys = {}
            for k in pairs(v) do keys[#keys + 1] = tostring(k) end
            table.sort(keys)
            if #keys == 0 then return "{}" end
            local lines = {}
            for _, k in ipairs(keys) do
                lines[#lines + 1] = pad_in .. '"' .. k .. '": ' .. encode_val(v[k], indent + 1)
            end
            return "{\n" .. table.concat(lines, ",\n") .. "\n" .. pad .. "}"
        end
    end
    return "null"
end

function M.json_encode(t)
    return encode_val(t, 0)
end

M.disable_jit(Surface)
M.disable_jit(NativeLayeredWindow)
M.disable_jit(M)

return M
