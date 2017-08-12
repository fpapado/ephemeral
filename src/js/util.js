export { string2Hex };

function string2Hex(tmp) {
  let str = '';
  for (let i = 0; i < tmp.length; i++) {
    str += tmp[i].charCodeAt(0).toString(16);
  }
  return str;
}
