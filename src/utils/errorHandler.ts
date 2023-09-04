import { errors } from "../config/errors.js";
import AppError from "../models/error.js";

const errorHandler = {
  // Listen to the global process-level error events
  listenToErrorEvents: () => {
    process.on("uncaughtException", async (error) => {
      await errorHandler.handleError(error);
    });

    process.on("unhandledRejection", async (reason) => {
      await errorHandler.handleError(reason);
    });
  },

  handleError: async (errorToHandle: unknown): Promise<AppError> => {
    try {
      const appError = AppError.from(errorToHandle);
      console.error(appError);
      return appError;
    } catch (handlingError: unknown) {
      // Not using the logger here because it might have failed
      process.stdout.write(
        "The error handler failed, here are the handler failure and then the origin error that it tried to handle"
      );
      process.stdout.write(JSON.stringify(handlingError));
      process.stdout.write(JSON.stringify(errorToHandle));
    }
    return errors.unexpected;
  },
};

export { errorHandler };
