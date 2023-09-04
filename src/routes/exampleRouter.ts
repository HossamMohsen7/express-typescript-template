import express from "express";
import exampleController from "../controllers/exampleController.js";
import { authTokenMiddleware } from "../middlewares/auth.js";

const router = express.Router();
router.get("/example", authTokenMiddleware, exampleController.getExampleData);

export default router;
