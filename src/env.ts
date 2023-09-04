import "dotenv/config";
import { z } from "zod";

const envSchema = z.object({
  PORT: z.coerce.number().default(3000),
  NODE_ENV: z
    .enum(["development", "test", "production"])
    .default("development"),
  DATABASE_URL: z.string().url(),
});
const env = envSchema.parse(process.env);
export default env;

export const isDev = env.NODE_ENV === "development";
export const isTest = env.NODE_ENV === "test";
export const isProd = env.NODE_ENV === "production";
