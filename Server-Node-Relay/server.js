const http = require('http');
const WebSocket = require('ws');

const HTTP_PORT = 8080;
const WS_PORT = 8081;

const httpServer = http.createServer((req, res) => {
    if (req.method === 'POST') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            res.writeHead(200, {'Content-Type': 'text/plain'});
            res.write('SUCCESS');
            res.end();
            var buf = new ArrayBuffer(body.length);
            var bufView = new Uint8Array(buf);
            for (let i=0; i<body.length; i++) bufView[i] = body.charCodeAt(i);
            wsServer.clients.forEach(client => {
                if (client.readyState === WebSocket.OPEN)
                    client.send(buf);
            });
        });
    } else {
        res.writeHead(400, {'Content-Type': 'text/plain'});
        res.end();
    }
});

const wsServer = new WebSocket.Server({ port: WS_PORT });
console.log('Started WebSocket server on port %s', WS_PORT);
wsServer.on('connection', (client) => {
    console.log('Connected to client');
});

httpServer.listen(HTTP_PORT, () => {
    console.log('HTTP Server listening on port %s', HTTP_PORT);
});
