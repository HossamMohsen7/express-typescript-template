import express from "express";
import exampleController from "../controllers/exampleController.js";
import { authTokenMiddleware } from "../middlewares/auth.js";
import { validateExample } from "@/validators/exampleValidator.js";

const router = express.Router();
router.post(
  "/example",
  authTokenMiddleware,
  validateExample,
  exampleController.getExampleData,
);

export default router;
