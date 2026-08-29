import http from 'http';

const port = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
    console.log(`${req.method} ${req.url}`);
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', path: req.url }));
});

server.listen(port, () => {
    console.log(`Listening on port ${port}`);
});
