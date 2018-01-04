// Entry
export interface EntryContent {
  // TODO: play with this
  content: string;
  translation: string;
}

export interface Entry extends EntryContent {
  type: 'entry';
}

export function isEntry(doc: {}): doc is Entry {
  return (<Entry>doc).type === 'entry';
}

// Database Contents
// Add things to the union as appropriate
// Leaving {} is desirable, in case we want some arbitrary data and
// we already check isEntry() when needed
export type DBDoc = Entry | {};
export type EphemeralDB = PouchDB.Database<DBDoc>;

// User Login types
export interface LoginUser {
  username: string;
  password: string;
}

// Taken from PouchDB types
export interface IdMeta {
  _id: string;
}
export interface RevisionIdMeta {
  _rev: string;
}
export type NewDocument<Content extends {}> = Content;
export type Document<Content extends {}> = Content & IdMeta;
export type ExistingDocument<Content extends {}> = Document<Content> &
  RevisionIdMeta;

// Convenience alias
export type DocumentID = string; // this is silly, but TS simple types are meh
export type ExportMethod = 'CSV' | 'ANKI';
