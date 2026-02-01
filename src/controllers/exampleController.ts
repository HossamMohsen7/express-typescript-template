import { ExampleController } from "@/validators/exampleValidator.js";
import { store } from "../context.js";
import exampleService from "../services/exampleService.js";

const getExampleData: ExampleController = async (req, res) => {
  const requestId = store().requestId;
  const { name, age } = req.body;
  const data = exampleService.getExampleData();
  res.status(200).json({ data, requestId });
};

export default {
  getExampleData,
};
