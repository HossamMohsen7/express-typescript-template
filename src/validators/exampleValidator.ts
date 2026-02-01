import { validate } from "zod-express-validator";
import { exampleSchema } from "@/schemas/exampleSchema.js";

export const validateExample = validate({
  body: exampleSchema,
});

export type ExampleController = typeof validateExample;
