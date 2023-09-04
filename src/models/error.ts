import { ZodError } from "zod";
import { RequestValidationError } from "zod-express-validator";
import { errorCodes } from "../config/errors.js";

class AppError extends Error {
  public readonly statusCode: number;
  public readonly errorCode: number;
  public readonly isOperational: boolean;

  constructor(
    statusCode: number,
    errorCode: number,
    message: string,
    isOperational: boolean = true
  ) {
    super(message);

    Object.setPrototypeOf(this, new.target.prototype); // restore prototype chain

    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.isOperational = isOperational;

    Error.captureStackTrace(this);
  }

  static custom(statusCode: number, errorCode: number, message: string) {
    return new AppError(statusCode, errorCode, message);
  }

  static from(err: unknown) {
    if (err instanceof AppError) return err;
    if (err instanceof ZodError) {
      return this.fromZod(err);
    }
    if (err instanceof Error) {
      return this.fromError(err);
    }
    if (err instanceof RequestValidationError) {
      const error =
        err.errors.bodyError ?? err.errors.paramsError ?? err.errors.queryError;
      return this.fromZod(error!);
    }
    return this.fromError(new Error("Internal server error"));
  }

  static fromError(err: Error, statusCode: number = 500) {
    return new AppError(statusCode, errorCodes.unexpected, err.message);
  }

  static fromZod(err: ZodError, statusCode: number = 400) {
    const message = err.errors[0].message;
    return new AppError(statusCode, errorCodes.validation, message);
  }
}
export default AppError;
