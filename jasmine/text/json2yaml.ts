import * as fs from 'fs/promises';
import * as yaml from 'js-yaml';
//import * as hljs from 'highlight.js';
//const hljs = require('highlight.js');
//const chalk = require('chalk');

// format a string with block style (|) and custom indentation
function blockStyleWithIndentation(value, indent = 2) {
  const indentSpaces = ' '.repeat(indent); // adjust the number of spaces
  const indentedValue = value
    .split('\n')
    .map(line => `${indentSpaces}${line}`)
    .join('\n');

  return `|-\n${indentedValue}`;
}

export async function json2yaml(fname: string): Promise<string> {
  return fs.readFile(fname, 'utf8').then((data) => {
    const jdata = JSON.parse(data);
    const ydata = yaml.dump(jdata, {
      styles: {
        '!!str': (value) => blockStyleWithIndentation(value, 2),
      },
    });
    return ydata;
  }).catch((x) => {
    console.error('Error reading or parsing JSON file:', x);
    return "";
  });
}
