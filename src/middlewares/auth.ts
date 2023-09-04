import { NextFunction, Request, RequestHandler, Response } from "express";

export const authTokenMiddleware = (
  req: Request,
  _: Response,
  next: NextFunction
) => {
  const authHeader = req.headers.authorization;
  if (authHeader && authHeader.startsWith("Bearer ")) {
    const accessToken = authHeader.substring(7, authHeader.length);
    req.auth = accessToken;
  }
  next();
};
