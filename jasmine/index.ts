
import os from 'os';
import path from 'path';

export * as text from "./text";

export const CLASSICO = path.resolve(`${import.meta.dir}/..`);

let _pre_imports_dirname = "";

export function _imports() {
  const home = os.homedir();
  _pre_imports_dirname = process.cwd();
  process.chdir(`${home}/.jasmine`);
}

export function _end_imports() {
  process.chdir(_pre_imports_dirname);
}
