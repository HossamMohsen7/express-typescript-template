import { AsyncLocalStorage } from "node:async_hooks";
import { Store } from "./models/store.js";

let currentContext: AsyncLocalStorage<Store>;

export const context = (): AsyncLocalStorage<Store> => {
  if (currentContext === undefined) {
    currentContext = new AsyncLocalStorage<Store>();
  }

  return currentContext;
};

export const store = (): Store => {
  const store = context().getStore();

  if (!store) {
    throw new Error("Store is not initialized");
  }

  return store;
};
