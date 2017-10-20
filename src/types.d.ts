declare module 'ephemeral/elm' {
  type ElmApp = {
    ports: {
      [portName: string]: {
        subscribe: (value: any) => void;
        unsubscribe: () => void;
        send: (value: any) => void;
      };
    };
  };

  export const Ephemeral: {
    embed(node: HTMLElement): ElmApp;
  };
}

declare module 'config' {
  type Config = {
    name: string;
    environment: string;
    couchUrl: string;
    dbName?: string;
  };

  export const config: Config;
}
