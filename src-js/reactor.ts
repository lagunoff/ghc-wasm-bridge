import { WASI, File, OpenFile } from '@bjorn3/browser_wasi_shim';
import { absurd } from './lib';
import * as p from './protocol';
import { UpCmd, DownCmd, DownCmdTag, UpCommandTag, Bindings, List } from './protocol';

export type HaskellPointer = number;

export type HaskellExports = {
  hs_init: (argc: number, argv: HaskellPointer) => void;
  hs_malloc: (size: number) => HaskellPointer;
  hs_free: (ptr: HaskellPointer) => void;
  app: (input: HaskellPointer) => HaskellPointer;
  memory: WebAssembly.Memory;
};

export type HaskellIstance = {
  exports: HaskellExports;
};

export function loadBuffer(inst: HaskellIstance, ptr: HaskellPointer) {
  const b = new Uint8Array(inst.exports.memory.buffer, ptr);
  const len = b[0] +
    (b[1] << 8) +
    (b[2] << 16) +
    (b[3] << 24) +
    (b[4] << 32) +
    (b[5] << 40) +
    (b[6] << 48) +
    (b[7] << 56);
  const buf = (new Uint8Array(inst.exports.memory.buffer, ptr + 8, len)).slice().buffer;
  inst.exports.hs_free(ptr);
  return new Uint8Array(buf);
}

export function storeBuffer(inst: HaskellIstance, u8array: Uint8Array) {
  const len = u8array.byteLength;
  const ptr = inst.exports.hs_malloc(u8array.length + 8);
  // Write the length of the buffer as 8 bytes before the buffer
  const view = new DataView(inst.exports.memory.buffer);
  view.setUint32(ptr, len, true);

  // Copy the buffer into WebAssembly memory
  const dest = new Uint8Array(inst.exports.memory.buffer, ptr + 8, len);
  dest.set(u8array);
  return ptr;
}

export function haskellApp(inst: HaskellIstance, down: DownCmd = { tag: DownCmdTag.Start }) {
  const upCmd = interactWithHaskell(inst, down);
  switch (upCmd.tag) {
    case UpCommandTag.Eval: {
      const result = p.evalExpr(globalContext, (down: DownCmd) => haskellApp(inst, down), upCmd.expr);
      const jvalue = p.unknownToJValue(result);
      return haskellApp(inst, { tag: DownCmdTag.Return, 0: jvalue });
    }
    case UpCommandTag.HotReload: {
      window.location.reload();
      return;
    }
    case UpCommandTag.Exit: {
      return;
    }
  }
  absurd(upCmd);
}

const globalContext: List<Bindings> = [window as any, null]

function interactWithHaskell(inst: HaskellIstance, down: DownCmd): UpCmd {
  const downBuf = p.downCmd.encode(down);
  console.log(`sending ${downBuf.length} bytes`);
  const downPtr = storeBuffer(inst, downBuf);
  const upBuf = loadBuffer(inst, inst.exports.app(downPtr));
  console.log(`receiving ${upBuf.length} bytes`);
  return p.upCmd.decode(upBuf);
}

export async function startReactor(wasmUri: string): Promise<void> {
  const wasi = new WASI([], [], [
    new OpenFile(new File([])), // stdin
    new OpenFile(new File([])), // stdout
    new OpenFile(new File([])), // stderr
  ]);

  const wasm = await WebAssembly.compileStreaming(fetch(wasmUri));
  const inst = await WebAssembly.instantiate(wasm, {
    "wasi_snapshot_preview1": wasi.wasiImport
  }) as HaskellIstance;
  wasi.inst = inst;

  inst.exports.hs_init(0, 0);

  haskellApp(inst);
};