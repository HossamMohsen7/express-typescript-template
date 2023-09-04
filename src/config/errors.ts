import AppError from "../models/error.js";
export const errorCodes = {
  unexpected: 1999,
  notFound: 1000,
  validation: 1001,
} as const;

export const errors = {
  notFound: AppError.custom(404, errorCodes.notFound, "Not found"),
  unexpected: AppError.custom(
    500,
    errorCodes.unexpected,
    "Something went wrong"
  ),
} as const;
