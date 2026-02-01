import env from "./src/env.js";
import { defineConfig } from "prisma/config";
import path from "path";

export default defineConfig({
  schema: path.join("prisma", "schema"),
  migrations: {
    path: "prisma/migrations",
  },
  datasource: {
    url: env.DATABASE_URL,
  },
});
