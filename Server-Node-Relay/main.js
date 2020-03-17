const express = require('express');
const bodyParser = require('body-parser')
const path = require('path');
const App = express();
const WebSocket = require('ws');
const { app, BrowserWindow, Tray, Menu, nativeImage } = require('electron');
const test = require('./tests/test');

const APP_VER = app.getVersion();

const HTTP_PORT = 8080;
const WS_PORT = 8081;

let wsServer;

const trayIcon = nativeImage.createFromPath(
  path.join(__dirname, 'assets', 'tray-icon.png')
);

let appIcon = null;

let serverStatus = {
    ws: {
        port: WS_PORT,
        status: false,
        clients: []
    },
    http: {
        port: HTTP_PORT,
        staus: false,
    },
    log: []
};

function createWindow () {
  // Create the browser window.
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      nodeIntegration: true
    }
  })

  // and load the index.html of the app.
  win.loadURL('http://localhost:8080');
  win.on('minimize', function (event) {
    event.preventDefault();
    win.hide();
  });
  win.on('close', (event) => {
    if (!app.isQuitting) {
      event.preventDefault();
      win.hide();
    }
    return false;
  });

  // var appIcon = null;
  appIcon = new Tray(trayIcon);
  var contextMenu = Menu.buildFromTemplate([
    { label: 'A-o-T Relay Server v' + APP_VER },
    { type: 'separator' },
    { label: 'Open Scratch-GUI', click: () => {
      require('child_process').exec('open https://shickey.github.io/art-of-tinkering');
    }},
    { label: 'Show Dashboard', click: () => {
      win.show();
    }},
    { type: 'separator' },
    { label: '[DEBUG] Send a test crab!', click: () => {
        test();
    }},
    { type: 'separator' },
    { label: 'Quit', click: () => {
      app.isQuitting = true;
      app.quit();
    }}
  ]);
  appIcon.setToolTip('Electron.js App');
  appIcon.setContextMenu(contextMenu);
}

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// Some APIs can only be used after this event occurs.
app.whenReady().then(createWindow)

// Quit when all windows are closed.
app.on('window-all-closed', () => {
  // On macOS it is common for applications and their menu bar
  // to stay active until the user quits explicitly with Cmd + Q
  if (process.platform !== 'darwin') {
    app.quit()
  }
})

app.on('activate', () => {
  // On macOS it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow()
  }
})

function startWSServer() {
    wsServer = new WebSocket.Server({ port: WS_PORT });
    log('Started WebSocket server on port ' + WS_PORT);
    serverStatus.ws.status = true;
    wsServer.on('connection', (client, req) => {
        const ip = req.connection.remoteAddress;
        log('Connected to WebSocket client at IP: ' + ip);
        serverStatus.ws.clients.push(ip);
    });
}

function log(msg) {
    const time = new Date().toLocaleString();
    msg = time + ':  ' + msg;
    console.log(msg);
    serverStatus.log.unshift(msg);
}

App.use(bodyParser.text({ limit: '50mb', type: '*/*' }));
App.use(express.static(path.join(__dirname, 'build')));

App.get('/server-status', function(req, res) {
    return res.send(JSON.stringify(serverStatus));
});

App.post('/', function(req, res) {
    const body = req.body;
    res.writeHead(200, {'Content-Type': 'text/plain'});
    res.write('SUCCESS');
    res.end();
    log('Received a container of size ' + body.length);
    var buf = new ArrayBuffer(body.length);
    var bufView = new Uint8Array(buf);
    for (let i=0; i<body.length; i++) bufView[i] = body.charCodeAt(i);
    wsServer.clients.forEach(client => {
        if (client.readyState === WebSocket.OPEN) {
            log('Relaying container to WebSocket client');
            client.send(buf);
        }
    });
});

console.log(app.getAppPath());
console.log(path.join(__dirname, 'build', 'index.html'));
App.get('/', function (req, res) {
    res.send("Hello World");
    // res.sendFile(path.join(process.resourcesPath, 'build', 'index.html'));
});

App.listen(HTTP_PORT, () => {
    console.log('Dashboard visible at: http://localhost:8080\n');
    // require('child_process').exec('open http://localhost:8080');
    log('Started HTTP server on port ' + HTTP_PORT);
    serverStatus.http.status = true;
    startWSServer();
});
