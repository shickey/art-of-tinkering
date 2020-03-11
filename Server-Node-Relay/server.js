const express = require('express');
const bodyParser = require('body-parser')
const path = require('path');
const app = express();
const WebSocket = require('ws');

const HTTP_PORT = 8080;
const WS_PORT = 8081;

let wsServer;

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

app.use(bodyParser.text({ limit: '50mb', type: '*/*' }));
app.use(express.static(path.join(__dirname, 'build')));

app.get('/server-status', function(req, res) {
    return res.send(JSON.stringify(serverStatus));
});

app.post('/', function(req, res) {
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

app.get('/', function (req, res) {
  res.sendFile(path.join(__dirname, 'build', 'index.html'));
});

app.listen(HTTP_PORT, () => {
    console.log('Dashboard visible at: http://localhost:8080\n');
    require('child_process').exec('open http://localhost:8080');
    log('Started HTTP server on port ' + HTTP_PORT);
    serverStatus.http.status = true;
    startWSServer();
});
