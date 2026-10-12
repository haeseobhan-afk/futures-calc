const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('feed', {
  quotes: (list) => ipcRenderer.invoke('feed:quotes', list)
});
