import { saveAs } from 'file-saver';
import stringify from 'csv-stringify';

export { exportCards };

function cardsToCsv(cards, cb){
  let cardEntries = cards.map(({content, translation}) => {
    return {content, translation};
  })

  return stringify(cardEntries, {header: true}, cb);
}

function exportCards(cards){
  cardsToCsv(cards, (err, csv) => {
    if (err){
      console.warn("Error converting to CSV", err);
    } else {
      console.log("Will save", csv);
      let blob = new Blob([csv], { type: "text/csv;charset=utf-8" });
      saveAs(blob, "ephemeral.csv");
    }
  });
}
