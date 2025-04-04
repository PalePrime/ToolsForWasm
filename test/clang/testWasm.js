import fs from "node:fs"

console.log(process.env.WASM_ROOT);
const Clang     = await import(`${process.env.WASM_ROOT}/clang/bin/clang.js`);
const Wasm_ld   = await import(`${process.env.WASM_ROOT}/clang/bin/wasm-ld.js`);
const Sysroot   = await import(`${process.env.WASM_ROOT}/em_sysroot/em_sysroot.js`);

const clang     = await Clang.default({noInitialRun: true, thisProgram: "/usr/bin/clang"});
const wasm_ld   = await Wasm_ld.default({noInitialRun: true, thisProgram: "/usr/bin/wasm-ld"});
const sysroot   = await Sysroot.default({noInitialRun: true});

sysroot.FS.mkdir("/em_sysroot/tmp2");

clang.FS.mkdir("/sysroot");
clang.FS.mount(clang.PROXYFS, {
    root: "/em_sysroot",
    fs: sysroot.FS
}, "/sysroot");

wasm_ld.FS.mkdir("/sysroot");
wasm_ld.FS.mount(wasm_ld.PROXYFS, {
    root: "/em_sysroot",
    fs: sysroot.FS
}, "/sysroot");

const program = fs.readFileSync(`${process.env.TEST_ROOT}/code/random_pi.c`,"utf-8");

//console.log(program);
//const stdio_h = clangFS.readFile("/sysroot/include/stdio.h", {encoding: "utf8"});
//console.log(stdio_h);

clang.FS.chdir("/sysroot/tmp2");
clang.FS.writeFile("random_pi.c", program);
clang.callMain(["-v", "--sysroot=/sysroot", "-c", "random_pi.c", "-o", "random_pi.o"]);
const objcode = clang.FS.readFile("random_pi.o");
fs.writeFileSync(`${process.env.BUILD_ROOT}/test/random_pi.o`, objcode);

wasm_ld.FS.chdir("/sysroot/tmp2");
try {
    wasm_ld.callMain(["-L/sysroot/lib/wasm32-emscripten", "-lcompiler_rt", "-lc", 
        "/sysroot/lib/wasm32-emscripten/crt1.o", "-lstandalonewasm-nocatch", 
        "random_pi.o", "-o", "random_pi.wasm"]);   
} catch (error) {
    console.log(`Linker error: ${error}`)
}

const wasmcode = clang.FS.readFile("random_pi.wasm");
fs.writeFileSync(`${process.env.BUILD_ROOT}/test/random_pi.wasm`, wasmcode);


console.log("Done!")
