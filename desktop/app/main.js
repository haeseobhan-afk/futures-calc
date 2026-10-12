const { app, BrowserWindow, Menu, ipcMain, net, shell } = require('electron');
const path = require('path');

const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36';
const HOSTS = ['query1.finance.yahoo.com', 'query2.finance.yahoo.com'];

// Yahoo Finance 차트 API에서 한 종목 시세 가져오기
async function fetchChart(symbol) {
  for (const host of HOSTS) {
    try {
      const url = `https://${host}/v8/finance/chart/${encodeURIComponent(symbol)}?interval=1m&range=1d`;
      const res = await net.fetch(url, { headers: { 'User-Agent': UA, 'Accept': 'application/json' } });
      if (!res.ok) continue;
      const j = await res.json();
      const m = j && j.chart && j.chart.result && j.chart.result[0] && j.chart.result[0].meta;
      if (!m || typeof m.regularMarketPrice !== 'number') continue;
      return {
        price: m.regularMarketPrice,
        prev: m.previousClose || m.chartPreviousClose || null,
        time: m.regularMarketTime || null,
        symbol: m.symbol || symbol
      };
    } catch (e) { /* 다음 호스트 시도 */ }
  }
  return null;
}

// 후보 심볼을 순서대로 시도 (해당 월물 → 근월물)
ipcMain.handle('feed:quotes', async (_e, list) => {
  return Promise.all((list || []).map(async (item) => {
    const cands = item.candidates || [];
    for (let i = 0; i < cands.length; i++) {
      const q = await fetchChart(cands[i]);
      if (q) return { id: item.id, ok: true, used: i, ...q };
    }
    return { id: item.id, ok: false };
  }));
});

function createWindow() {
  const win = new BrowserWindow({
    width: 1060,
    height: 920,
    minWidth: 440,
    minHeight: 600,
    title: '해외선물 틱 손익 계산기',
    backgroundColor: '#EEF1F6',
    autoHideMenuBar: true,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: true
    }
  });
  win.loadFile(path.join(__dirname, 'index.html'));
  win.webContents.setWindowOpenHandler(({ url }) => { shell.openExternal(url); return { action: 'deny' }; });
}

Menu.setApplicationMenu(null);
app.whenReady().then(createWindow);
app.on('window-all-closed', () => app.quit());
