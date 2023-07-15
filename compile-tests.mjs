#!/usr/bin/env zx

import fs, { createReadStream, existsSync, statSync } from "fs";
import events from "events";
import { readFile, stat } from "fs/promises";
import readline from "readline";
import { spawn } from "child_process";
import path from "path";
// import { chalk } from "zx";
// import 'zx/globals'

Array.prototype.last = function () {
    return this[this.length - 1];
};

const getImports = async (file) => {
    let rl = readline.createInterface({
        input: fs.createReadStream(file),
        crlfDelay: Infinity,
    });

    let import_paths = [];

    rl.on("line", (line) => {
        if (line.startsWith("import")) {
            let path = line.split(" ").last();
            path = path.slice(1, path.length - 2);
            import_paths.push(path);
        } else if (line.length !== 0 && !line.startsWith("//")) {
            rl.close();
            rl.removeAllListeners();
        }
    });

    await events.once(rl, "close");

    return import_paths;
};

const wasm_path = (file) => {
    let segments = file.split("/");
    segments.splice(1, 0, ".wasm");
    let basename = segments.last().replace(".mo", ".wasm");
    segments[segments.length - 1] = basename;
    return segments.join("/");
};

let test_files = await glob("./test?(s)/**/*.(test|Test).mo");

let moc = (await $`dfx cache show`).stdout.toString().trim() + "/moc";
let mops_sources = (await $`mops sources`).stdout.toString().split("\n");

let packages = {};
let package_args = [];


for (const source of mops_sources) {
    let segments = source.split(" ");
    package_args.push(...segments);
    packages[segments[1]] = segments[2];
}

const compile_motoko = async (src, dest) => {
    await $`${moc} ${package_args} -wasi-system-api ${src} -o ${dest}`;
};

if (test_files.length) {
    let wasm_dir = test_files[0].split("/")[0] + "/.wasm";
    await $`mkdir -p ${wasm_dir}`;
}

const last_modified_cache = {};

const is_recently_modified = (file, time) => {
    let cached_mtime = last_modified_cache[file];

    if (cached_mtime) {
        return cached_mtime > time;
    }

    let file_mtime = statSync(file).mtimeMs;
    last_modified_cache[file] = file_mtime;

    return file_mtime > time;
};

const is_dep_tree_recently_modified = async (file, wasm_mtime, visited) => {
    let modified = is_recently_modified(file, wasm_mtime);

    if (modified) {
        return true;
    }

    let imports = await getImports(file);

    // console.log({file, imports})

    for (let imp_path of imports) {
        if (imp_path.startsWith("mo:")) {
            let pkg = imp_path.slice(3).split("/")[0];
            let pkg_path = packages[pkg];

            pkg_path = (await glob(pkg_path + "/**/*.mo"))[0];

            if (pkg_path && !visited.has(pkg_path)) {
                visited.add(pkg_path);
                modified = is_recently_modified(pkg_path, wasm_mtime);
            }

            continue;
        }

        imp_path = path.resolve(path.dirname(file), imp_path);

        if (existsSync(imp_path.concat(".mo"))) {
            imp_path = imp_path.concat(".mo");
        } else {
            imp_path = imp_path.concat("/lib.mo");
        }

        if (visited.has(imp_path)) { continue; }

        visited.add(imp_path);

        // console.log({imp_path})

        if (await is_dep_tree_recently_modified(imp_path, wasm_mtime, visited)) {
            return true
        };

    }

    return false;
};

const compile_test = async (test_file) => {
    const wasm_file = wasm_path(test_file);

    let should_compile = !existsSync(wasm_file);

    if (!should_compile) {
        let wasm_mtime = statSync(wasm_file).mtimeMs;
        should_compile = await is_dep_tree_recently_modified(test_file, wasm_mtime, new Set());
    }

    if (should_compile) {
        console.log(`Compiling ${test_file}`);
        await compile_motoko(test_file, wasm_file);
    }

    return wasm_file;
}

const wasm_files = await Promise.all(
    test_files.map(compile_test)
);

for (const wasm_file of wasm_files) {
    await $`wasmtime ${wasm_file}`;
}