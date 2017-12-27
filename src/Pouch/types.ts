export interface EntryContent {}

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
export type DocumentID = string;
