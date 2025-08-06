const http = require('http');
const fs   = require('fs').promises;
const port = 8080;

const page = `
    const Fujprog   = await import("wasm/fujprog/bin/fujprog.js");

    const fujprog   = await Fujprog.default({noInitialRun: true});

    fujprog.FS.writeFile("random_pi.c", program);
    fujprog.callMain(["-i"]);

    console.log("Done!")
`;

const page2 = `
  <script type="module">
    const Fujprog   = await import("./fujprog.js");
    const fujprog   = await Fujprog.default({noInitialRun: true});
    //fujprog.FS.writeFile("random_pi.c", program);

    function runFujprog() {
        navigator.usb.requestDevice({ filters: [{ vendorId: 0x0403 }] })
            .then((device) => {
                fujprog.callMain(["-i"]);
            })
    }

    globalThis.runFujprog = runFujprog;

    console.log("Boom!");
  </script>

  <button type="button" onclick="runFujprog()">Test</button>
`;

console.log(process.env.WASM_ROOT);

http.createServer((req, res) => {
  const headers = {
    'Cross-Origin-Embedder-Policy': 'require-corp',
    'Cross-Origin-Opener-Policy': 'same-origin',
  };

  if (req.method === 'OPTIONS') {
    res.writeHead(204, headers);
    res.end();
    return;
  }

  if (['GET', 'POST'].indexOf(req.method) > -1) {
    switch (req.url) {
        case "/":
            res.writeHead(200, headers);
            res.end(page2);
            break;
        case "/fujprog.js":
            fs.readFile((`${process.env.WASM_ROOT}/fujprog/bin/fujprog.js`))
                .then(contents => {
                    res.setHeader("Content-Type", "text/javascript");
                    res.writeHead(200);
                    res.end(contents);
                })
                .catch(err => {
                    res.writeHead(500);
                    res.end(err);
                    return;
                });
            break;
        case "/fujprog.wasm":
            fs.readFile((`${process.env.WASM_ROOT}/fujprog/bin/fujprog.wasm`))
                .then(contents => {
                    res.setHeader("Content-Type", "application/wasm");
                    res.writeHead(200);
                    res.end(contents);
                })
                .catch(err => {
                    res.writeHead(500);
                    res.end(err);
                    return;
                });
            break;
        default:
            res.writeHead(404, headers);
            res.end("Resource not found");
    };
    return;
  }

  res.writeHead(405, headers);
  res.end(`${req.method} is not allowed for the request.`);
}).listen(port);
