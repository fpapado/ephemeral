import { saveAs } from 'file-saver';
import stringify from 'csv-stringify';
import 'whatwg-fetch';

interface Card {
  content: string;
  translation: string;
}

export function exportCardsCSV(cards: Card[]) {
  cardsToCsv(cards, (err: any, csv: any) => {
    if (err) {
      console.warn('Error converting to CSV', err);
    } else {
      let blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
      saveAs(blob, 'ephemeral.csv');
    }
  });
}

export function exportCardsAnki(cards: Card[]) {
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

function cardsToCsv(cards: Card[], cb: any) {
  let cardEntries = cards.map(({ content, translation }) => {
    return { content, translation };
  });

  return stringify(cardEntries, { header: true }, cb);
}

function getAnkiPkg(cards: Card[]) {
  let cardEntries = cards.map(({ content, translation }) => {
    return { front: content, back: translation };
  });

  let req = fetch('https://micro-anki.now.sh', {
    method: 'POST',
    headers: new Headers({ 'Content-Type': 'application/json' }),
    body: JSON.stringify({ cards: cardEntries })
  });

  return req;
}
