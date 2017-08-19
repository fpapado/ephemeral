import {saveAs} from 'file-saver';
import stringify from 'csv-stringify';

export {exportCardsCSV, exportCardsAnki};

function cardsToCsv(cards, cb) {
  let cardEntries = cards.map(({content, translation}) => {
    return {content, translation};
  });

  return stringify(cardEntries, {header: true}, cb);
}

function exportCardsCSV(cards) {
  cardsToCsv(cards, (err, csv) => {
    if (err) {
      console.warn('Error converting to CSV', err);
    } else {
      let blob = new Blob([csv], {type: 'text/csv;charset=utf-8'});
      saveAs(blob, 'ephemeral.csv');
    }
  });
}

function getAnkiPkg(cards) {
  let cardEntries = cards.map(({content, translation}) => {
    return {front: content, back: translation};
  });

  let req = fetch('https://micro-anki.now.sh', {
    method: 'POST',
    headers: new Headers({'Content-Type': 'application/json'}),
    body: JSON.stringify({cards: cardEntries})
  });

  return req;
}

function exportCardsAnki(cards) {
  getAnkiPkg(cards)
    .then(res => {
      return res.blob();
    })
    .then(blob => {
      console.log('Will save');
      saveAs(blob, 'ephemeral.apkg');
    })
    .catch(err => {
      console.warn('Error communicating with micro-anki server', err);
    });
}
