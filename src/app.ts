import "reflect-metadata";
import "dotenv/config";
import express from "express";
import { createServer } from "http";
import helmet from "helmet";
import hpp from "hpp";
import cors from "cors";
import morgan from "morgan";

import { helloRouter } from "./routes/helloRoute.js";

const PORT = process.env.PORT || 3000;
const app = express();
const http = createServer(app);

const corsOptions = {
  origin: (origin: any, callback: (err: any, origin?: any) => void) => {
    callback(null, origin);
  },
  allowedHeaders: ["Content-Type", "Authorization"],
  credentials: true,
};

app.set("trust proxy", "loopback");
app.use(
  helmet({
    crossOriginEmbedderPolicy: false,
    crossOriginOpenerPolicy: false,
    crossOriginResourcePolicy: false,
  })
);
app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(hpp());
app.use(cors(corsOptions));
app.use(morgan("combined"));

app.use(helloRouter);

app.get("/", (req, res) => {
  return res.status(200).send("Everything is working great!");
});

const startServer = () => {
  console.log("Starting server..");
  http.listen(PORT, () => {
    console.log("listening on *:" + PORT);
  });
};

const main = async () => {
  startServer();
};

main();
