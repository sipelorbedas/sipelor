// =============================================
// SIPELOR BEDAS — Admin Panel (Electron Main)
// =============================================

const { app, BrowserWindow, shell, session } = require('electron');
const path = require('path');

// Prevent multiple instances
const gotLock = app.requestSingleInstanceLock();
if (!gotLock) {
  app.quit();
  process.exit(0);
}

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1366,
    height: 768,
    minWidth: 1100,
    minHeight: 650,
    title: 'SIPELOR BEDAS — Admin Panel',
    autoHideMenuBar: true,      // Sembunyikan menu bar (Alt untuk tampilkan)
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      webSecurity: false,        // Izinkan load CDN (Supabase, Chart.js) dari file://
      allowRunningInsecureContent: false,
    },
  });

  // Load halaman login sebagai entry point
  mainWindow.loadFile(path.join(__dirname, 'login.html'));

  // Buka link eksternal di browser default (bukan di Electron)
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    if (url.startsWith('http')) shell.openExternal(url);
    return { action: 'deny' };
  });

  // Tangani navigasi login ↔ index secara lokal
  mainWindow.webContents.on('will-navigate', (event, url) => {
    // Izinkan navigasi lokal (file://) — blokir navigasi ke luar
    if (!url.startsWith('file://')) {
      event.preventDefault();
      shell.openExternal(url);
    }
  });

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

// ── App Events ────────────────────────────────

app.on('ready', () => {
  // Izinkan CDN resources (Supabase, Chart.js, Google Fonts) via CSP
  session.defaultSession.webRequest.onHeadersReceived((details, callback) => {
    callback({
      responseHeaders: {
        ...details.responseHeaders,
        'Content-Security-Policy': [
          "default-src 'self' 'unsafe-inline' 'unsafe-eval' " +
          "https://*.supabase.co wss://*.supabase.co " +
          "https://cdn.jsdelivr.net " +
          "https://fonts.googleapis.com https://fonts.gstatic.com " +
          "data: blob:;"
        ],
      },
    });
  });

  createWindow();
});

app.on('second-instance', () => {
  // Fokus ke window yang sudah ada jika dibuka lagi
  if (mainWindow) {
    if (mainWindow.isMinimized()) mainWindow.restore();
    mainWindow.focus();
  }
});

app.on('window-all-closed', () => {
  app.quit();
});

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) createWindow();
});
