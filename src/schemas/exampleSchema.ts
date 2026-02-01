import z from "zod";

export const exampleSchema = z.object({
  name: z.string(),
  age: z.coerce.number(),
});
