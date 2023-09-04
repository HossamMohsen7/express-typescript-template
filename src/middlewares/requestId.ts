import { IncomingMessage, ServerResponse } from "http";
import { REQUEST_ID_HEADER } from "../config/constants.js";
import { generateRequestId } from "../utils/utils.js";
import { context, store } from "../context.js";

export function requestIdMiddleware(
  req: IncomingMessage,
  res: ServerResponse,
  next: () => void
) {
  let requestId = req.headers[REQUEST_ID_HEADER];

  if (!requestId) {
    requestId = generateRequestId();
    req.headers[REQUEST_ID_HEADER] = requestId;
  }

  res.setHeader(REQUEST_ID_HEADER, requestId);

  const currentContext = context().getStore();

  if (currentContext) {
    // Append to the current context
    currentContext.requestId = requestId.toString();
    next();
    return;
  }

  context().run({ requestId: requestId as string }, next);
}
