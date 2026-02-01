# Express TypeScript Template

A production-ready template for building Node.js backends using **TypeScript**, **Express 5**, **Prisma**, and **Zod** for validation. This template includes best practices for error handling, request validation, authentication, and Docker deployment.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Environment Variables](#environment-variables)
  - [Running the Application](#running-the-application)
- [Project Structure](#project-structure)
- [Core Concepts](#core-concepts)
  - [Creating a New Router](#creating-a-new-router)
  - [Creating a New Controller](#creating-a-new-controller)
  - [Creating a New Service](#creating-a-new-service)
  - [Creating a Validation Schema](#creating-a-validation-schema)
  - [Creating a Validator](#creating-a-validator)
  - [Creating Custom Errors](#creating-custom-errors)
  - [Creating Middleware](#creating-middleware)
  - [Using the Request Context](#using-the-request-context)
  - [Extending the Request Object](#extending-the-request-object)
- [Database](#database)
  - [Prisma Setup](#prisma-setup)
  - [Running Migrations](#running-migrations)
- [Docker](#docker)
  - [Development](#development)
  - [Production](#production)
- [API Reference](#api-reference)
- [License](#license)

---

## Features

- **Express 5** - Latest Express with async error handling
- **TypeScript** - Full type safety with path aliases (`@/`)
- **Zod Validation** - Type-safe request validation with automatic error messages
- **Prisma ORM** - Type-safe database access with PostgreSQL adapter
- **Error Handling** - Centralized error handling with custom error classes
- **Request Context** - AsyncLocalStorage for request-scoped data
- **Security** - Helmet, HPP, CORS configuration
- **Docker Ready** - Multi-stage Dockerfile with development and production targets
- **Hot Reload** - Development server with tsx watch mode

---

## Requirements

- **Node.js** >= 24
- **pnpm** >= 10
- **PostgreSQL** (or any Prisma-supported database)

---

## Getting Started

### Installation

```bash
# Clone the repository
git clone https://github.com/HossamMohsen7/express-typescript-template.git
cd express-typescript-template

# Install dependencies
pnpm install
```

### Environment Variables

Create a `.env` file in the root directory:

```bash
# Copy the example file
cp .env.example .env
```

Configure the following variables:

| Variable       | Description                  | Default       |
| -------------- | ---------------------------- | ------------- |
| `PORT`         | Server port                  | `3000`        |
| `NODE_ENV`     | Environment mode             | `development` |
| `DATABASE_URL` | PostgreSQL connection string | -             |

Example `.env`:

```env
PORT=5000
DATABASE_URL=postgresql://user:password@localhost:5432/mydb
```

### Running the Application

```bash
# Development mode (with hot reload)
pnpm dev

# Build for production
pnpm build

# Start production server
pnpm start

# Open Prisma Studio
pnpm studio

# Push schema to database
pnpm db
```

---

## Project Structure

```
├── prisma/
│   └── schema/
│       └── schema.prisma       # Database schema
├── src/
│   ├── config/
│   │   ├── constants.ts        # Application constants
│   │   └── errors.ts           # Error definitions
│   ├── controllers/            # Request handlers
│   ├── generated/              # Prisma generated client
│   ├── middlewares/            # Express middlewares
│   ├── models/                 # Data models and types
│   ├── routes/                 # Route definitions
│   ├── schemas/                # Zod validation schemas
│   ├── services/               # Business logic
│   ├── utils/                  # Utility functions
│   ├── validators/             # Request validators
│   ├── app.ts                  # Application entry point
│   ├── context.ts              # Request context (AsyncLocalStorage)
│   ├── db.ts                   # Database client
│   ├── env.ts                  # Environment configuration
│   └── index.d.ts              # Type augmentations
├── Dockerfile                  # Multi-stage Docker build
├── docker-compose.yml          # Production docker-compose
├── docker-compose.dev.yml      # Development overrides
├── Makefile                    # Common commands
└── package.json
```

---

## Core Concepts

### Creating a New Router

Routers define API endpoints and connect them to controllers and validators.

**1. Create a new router file in `src/routes/`:**

```typescript
// src/routes/userRouter.ts
import express from "express";
import userController from "@/controllers/userController.js";
import { authTokenMiddleware } from "@/middlewares/auth.js";
import {
  validateCreateUser,
  validateUpdateUser,
} from "@/validators/userValidator.js";

const router = express.Router();

// Public routes
router.get("/users", userController.getAllUsers);
router.get("/users/:id", userController.getUserById);

// Protected routes
router.post(
  "/users",
  authTokenMiddleware,
  validateCreateUser,
  userController.createUser,
);
router.put(
  "/users/:id",
  authTokenMiddleware,
  validateUpdateUser,
  userController.updateUser,
);
router.delete("/users/:id", authTokenMiddleware, userController.deleteUser);

export default router;
```

**2. Register the router in `src/app.ts`:**

```typescript
import userRouter from "@/routes/userRouter.js";

const setupRouters = () => {
  app.get("/", (req, res) => {
    res.status(200).send("Everything is working great!");
  });

  app.use("/api", exampleRouter);
  app.use("/api", userRouter); // Add your new router
};
```

---

### Creating a New Controller

Controllers handle HTTP requests and responses, orchestrating services and returning data.

**Create a controller file in `src/controllers/`:**

```typescript
// src/controllers/userController.ts
import { Request, Response } from "express";
import {
  CreateUserController,
  UpdateUserController,
} from "@/validators/userValidator.js";
import userService from "@/services/userService.js";
import { store } from "@/context.js";
import { errors } from "@/config/errors.js";

// Handler with validation type
const createUser: CreateUserController = async (req, res) => {
  const requestId = store().requestId;
  const { email, name } = req.body; // Fully typed from validator

  const user = await userService.createUser({ email, name });

  res.status(201).json({
    success: true,
    requestId,
    data: user,
  });
};

// Handler with validation type for params
const getUserById = async (req: Request<{ id: string }>, res: Response) => {
  const { id } = req.params;

  const user = await userService.getUserById(parseInt(id));

  if (!user) {
    throw errors.notFound; // Will be caught by error handler
  }

  res.status(200).json({
    success: true,
    data: user,
  });
};

// Handler for list endpoint
const getAllUsers = async (req: Request, res: Response) => {
  const users = await userService.getAllUsers();

  res.status(200).json({
    success: true,
    data: users,
  });
};

export default {
  createUser,
  getUserById,
  getAllUsers,
};
```

---

### Creating a New Service

Services contain business logic and interact with the database.

**Create a service file in `src/services/`:**

```typescript
// src/services/userService.ts
import { db } from "@/db.js";

interface CreateUserInput {
  email: string;
  name?: string;
}

const createUser = async (data: CreateUserInput) => {
  return db.user.create({
    data: {
      email: data.email,
      name: data.name,
    },
  });
};

const getUserById = async (id: number) => {
  return db.user.findUnique({
    where: { id },
  });
};

const getAllUsers = async () => {
  return db.user.findMany({
    orderBy: { createdAt: "desc" },
  });
};

const updateUser = async (id: number, data: Partial<CreateUserInput>) => {
  return db.user.update({
    where: { id },
    data,
  });
};

const deleteUser = async (id: number) => {
  return db.user.delete({
    where: { id },
  });
};

export default {
  createUser,
  getUserById,
  getAllUsers,
  updateUser,
  deleteUser,
};
```

---

### Creating a Validation Schema

Schemas define the shape and constraints of request data using Zod.

**Create a schema file in `src/schemas/`:**

```typescript
// src/schemas/userSchema.ts
import z from "zod";

// Create user schema
export const createUserSchema = z.object({
  email: z.string().email("Invalid email format"),
  name: z.string().min(2, "Name must be at least 2 characters").optional(),
});

// Update user schema (all fields optional)
export const updateUserSchema = z.object({
  email: z.string().email("Invalid email format").optional(),
  name: z.string().min(2, "Name must be at least 2 characters").optional(),
});

// Query params schema
export const listUsersQuerySchema = z.object({
  page: z.coerce.number().min(1).default(1),
  limit: z.coerce.number().min(1).max(100).default(10),
  search: z.string().optional(),
});

// Route params schema
export const userIdParamsSchema = z.object({
  id: z.coerce.number().positive("ID must be a positive number"),
});

// Infer types from schemas
export type CreateUserInput = z.infer<typeof createUserSchema>;
export type UpdateUserInput = z.infer<typeof updateUserSchema>;
export type ListUsersQuery = z.infer<typeof listUsersQuerySchema>;
```

---

### Creating a Validator

Validators connect Zod schemas to Express middleware using `zod-express-validator`.

**Create a validator file in `src/validators/`:**

```typescript
// src/validators/userValidator.ts
import { validate } from "zod-express-validator";
import {
  createUserSchema,
  updateUserSchema,
  userIdParamsSchema,
  listUsersQuerySchema,
} from "@/schemas/userSchema.js";

// Validate request body for creating user
export const validateCreateUser = validate({
  body: createUserSchema,
});

// Validate request body for updating user
export const validateUpdateUser = validate({
  body: updateUserSchema,
  params: userIdParamsSchema,
});

// Validate route params (e.g., /users/:id)
export const validateUserIdParams = validate({
  params: userIdParamsSchema,
});

// Validate query parameters (e.g., /users?page=1&limit=10)
export const validateListUsersQuery = validate({
  query: listUsersQuerySchema,
});

// Export types for controllers (use typeof for typed handlers)
export type CreateUserController = typeof validateCreateUser;
export type UpdateUserController = typeof validateUpdateUser;
```

**Using validators in routes:**

```typescript
// src/routes/userRouter.ts
import {
  validateCreateUser,
  validateUserIdParams,
} from "@/validators/userValidator.js";

router.post("/users", validateCreateUser, userController.createUser);
router.get("/users/:id", validateUserIdParams, userController.getUserById);
```

---

### Creating Custom Errors

Define application-specific errors for consistent error responses.

**1. Add error codes in `src/config/errors.ts`:**

```typescript
// src/config/errors.ts
import AppError from "@/models/error.js";

export const errorCodes = {
  unexpected: 1999,
  notFound: 1000,
  validation: 1001,
  unauthorized: 1002,
  forbidden: 1003,
  conflict: 1004,
  userNotFound: 2001,
  userAlreadyExists: 2002,
  invalidCredentials: 2003,
} as const;

export const errors = {
  // Generic errors
  notFound: AppError.custom(404, errorCodes.notFound, "Not found"),
  unexpected: AppError.custom(
    500,
    errorCodes.unexpected,
    "Something went wrong",
  ),
  unauthorized: AppError.custom(401, errorCodes.unauthorized, "Unauthorized"),
  forbidden: AppError.custom(403, errorCodes.forbidden, "Forbidden"),

  // User-specific errors
  userNotFound: AppError.custom(404, errorCodes.userNotFound, "User not found"),
  userAlreadyExists: AppError.custom(
    409,
    errorCodes.userAlreadyExists,
    "User already exists",
  ),
  invalidCredentials: AppError.custom(
    401,
    errorCodes.invalidCredentials,
    "Invalid credentials",
  ),
} as const;
```

**2. Using errors with dynamic messages:**

```typescript
// Using format() for parameterized messages
import AppError from "@/models/error.js";
import { errorCodes } from "@/config/errors.js";

// Create a template error
const userNotFoundTemplate = AppError.custom(
  404,
  errorCodes.userNotFound,
  "User with ID %s not found",
);

// Use format() to inject values
throw userNotFoundTemplate.format(userId);
// Error message: "User with ID 123 not found"
```

**3. Error response format:**

All errors return a consistent JSON structure:

```json
{
  "success": false,
  "errorCode": 2001,
  "error": "User not found",
  "stack": "..." // Only in development
}
```

---

### Creating Middleware

Middlewares process requests before they reach controllers.

**Create a middleware file in `src/middlewares/`:**

```typescript
// src/middlewares/rateLimit.ts
import { Request, Response, NextFunction } from "express";

const requestCounts = new Map<string, { count: number; resetAt: number }>();

export const rateLimitMiddleware = (
  maxRequests: number = 100,
  windowMs: number = 60000,
) => {
  return (req: Request, res: Response, next: NextFunction) => {
    const clientIp = req.ip || req.socket.remoteAddress || "unknown";
    const now = Date.now();

    const record = requestCounts.get(clientIp);

    if (!record || now > record.resetAt) {
      requestCounts.set(clientIp, { count: 1, resetAt: now + windowMs });
      return next();
    }

    if (record.count >= maxRequests) {
      res.status(429).json({
        success: false,
        error: "Too many requests",
      });
      return;
    }

    record.count++;
    next();
  };
};
```

**Using the middleware:**

```typescript
// In router
import { rateLimitMiddleware } from "@/middlewares/rateLimit.js";

router.post("/login", rateLimitMiddleware(5, 60000), authController.login);
```

---

### Using the Request Context

The template uses `AsyncLocalStorage` to maintain request-scoped data.

**Accessing context in any file:**

```typescript
import { store } from "@/context.js";

const someFunction = () => {
  // Access request-scoped data
  const { requestId } = store();

  console.log(`Processing request: ${requestId}`);
};
```

**Extending the store:**

```typescript
// src/models/store.ts
export interface Store {
  requestId: string;
  userId?: string; // Add custom properties
  tenantId?: string;
}
```

**Setting context values in middleware:**

```typescript
// src/middlewares/auth.ts
import { context } from "@/context.js";

export const authTokenMiddleware = (
  req: Request,
  _: Response,
  next: NextFunction,
) => {
  const authHeader = req.headers.authorization;
  if (authHeader?.startsWith("Bearer ")) {
    const accessToken = authHeader.substring(7);
    req.auth = accessToken;

    // Set user in context
    const currentStore = context().getStore();
    if (currentStore) {
      currentStore.userId = decodeToken(accessToken).userId;
    }
  }
  next();
};
```

---

### Extending the Request Object

Add custom properties to Express Request type.

**Edit `src/index.d.ts`:**

```typescript
export {};

declare global {
  namespace Express {
    interface Request {
      auth?: string; // JWT token
      user?: {
        // Decoded user
        id: string;
        email: string;
        role: string;
      };
      tenantId?: string; // Multi-tenant support
    }
  }
}
```

---

## Database

### Prisma Setup

The template uses Prisma with PostgreSQL adapter.

**Schema location:** `prisma/schema/schema.prisma`

```prisma
generator client {
  provider        = "prisma-client"
  previewFeatures = ["relationJoins"]
  output          = "../../src/generated/prisma"
}

datasource db {
  provider = "postgresql"
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  name      String?
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
  posts     Post[]
}

model Post {
  id        Int      @id @default(autoincrement())
  title     String
  content   String?
  published Boolean  @default(false)
  authorId  Int
  author    User     @relation(fields: [authorId], references: [id])
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt
}
```

### Running Migrations

```bash
# Generate Prisma client
npx prisma generate

# Push schema changes to database (development)
pnpm db

# Open Prisma Studio
pnpm studio

# Create a migration (production)
npx prisma migrate dev --name migration_name
```

---

## Docker

The template includes a multi-stage Dockerfile optimized for both development and production.

### Development

```bash
# Build development image
make build-dev

# Start development containers
make start-dev

# Start in detached mode
make start-dev-d

# View logs
make logs

# Stop containers
make stop
```

### Production

```bash
# Build production image
make build

# Start production containers
make start-prod

# Start in detached mode
make start-prod-d

# Access container shell
make shell
```

### Docker Compose Example

```yaml
# docker-compose.yml
services:
  app:
    build:
      context: .
      target: prod
    ports:
      - "5000:5000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
    depends_on:
      - db

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: mydb
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

---

## API Reference

### Example Endpoint

**POST** `/api/example`

Validates and processes example data.

**Headers:**

```
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**

```json
{
  "name": "John Doe",
  "age": 25
}
```

**Response:**

```json
{
  "data": "example",
  "requestId": "550e8400-e29b-41d4-a716-446655440000"
}
```

---

## Scripts Reference

| Script        | Description                              |
| ------------- | ---------------------------------------- |
| `pnpm dev`    | Start development server with hot reload |
| `pnpm build`  | Build for production                     |
| `pnpm start`  | Start production server                  |
| `pnpm db`     | Push Prisma schema to database           |
| `pnpm studio` | Open Prisma Studio                       |

---

## License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## Author

**Hossam Mohsen**

- GitHub: [@HossamMohsen7](https://s.hossamohsen.me/github)
- LinkedIn: [Hossam Mohsen](https://s.hossamohsen.me/linkedin)

---
