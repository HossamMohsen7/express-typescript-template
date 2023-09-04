import express from "express";
import { store } from "../context.js";
import exampleService from "../services/exampleService.js";

const getExampleData = async (req: express.Request, res: express.Response) => {
  const requestId = store().requestId;
  const data = exampleService.getExampleData();
  return res.status(200).json({ data, requestId });
};

export default {
  getExampleData,
};
