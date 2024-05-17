import { ZodError } from "zod";
import { RequestValidationError } from "zod-express-validator";
import { errorCodes } from "../config/errors.js";
import util from "util";
import { fromZodError } from "zod-validation-error";

class AppError extends Error {
  public readonly statusCode: number;
  public readonly errorCode: number;
  public readonly isOperational: boolean;
  public readonly data: unknown;

  constructor(
    statusCode: number,
    errorCode: number,
    message: string,
    data: unknown = undefined,
    isOperational: boolean = true
  ) {
    super(message);

    Object.setPrototypeOf(this, new.target.prototype); // restore prototype chain

    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.isOperational = isOperational;
    this.data = data;

    Error.captureStackTrace(this);
  }

  static custom(statusCode: number, errorCode: number, message: string) {
    return new AppError(statusCode, errorCode, message);
  }

  static from(err: unknown) {
    console.log(typeof err);
    if (err instanceof AppError) return err;
    if (err instanceof ZodError) {
      return this.fromZod(err);
    }
    if (err instanceof RequestValidationError) {
      const error =
        err.errors.bodyError ?? err.errors.paramsError ?? err.errors.queryError;
      return this.fromZod(error!);
    }
    if (err instanceof Error) {
      return this.fromError(err);
    }
    return this.fromError(new Error("Internal server error"));
  }

  static fromError(err: Error, statusCode: number = 500) {
    return new AppError(statusCode, errorCodes.unexpected, err.message);
  }

  static fromZod(err: ZodError, statusCode: number = 400) {
    const formattedError = fromZodError(err);
    return new AppError(
      statusCode,
      errorCodes.validation,
      formattedError.message,
      formattedError.details
    );
  }

  format(...args: unknown[]) {
    return new AppError(
      this.statusCode,
      this.errorCode,
      util.format(this.message, ...args),
      this.data,
      this.isOperational
    );
  }
}
export default AppError;
