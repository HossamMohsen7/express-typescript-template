import { randomUUID } from "node:crypto";

export const capitalizeFirstLetter = (string: string) =>
  string.charAt(0).toUpperCase() + string.slice(1).toLowerCase();

export const chunk = <T>(array: T[], size: number) =>
  Array.from({ length: Math.ceil(array.length / size) }, (_, index) =>
    array.slice(index * size, index * size + size)
  );

export const generateRequestId = () => randomUUID();
