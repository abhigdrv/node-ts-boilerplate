#!/bin/bash

# Project root directory
PROJECT_ROOT="nodejs-ts-prisma"

# Create project root directory
mkdir -p $PROJECT_ROOT

# Initialize project
cd $PROJECT_ROOT
npm init -y
npm install express prisma @prisma/client
npm install --save-dev typescript ts-node-dev @types/node @types/express

# Create directories
mkdir -p src/config src/controllers src/routes src/services src/middleware src/utils src/tests

# Create tsconfig.json
cat <<EOL > tsconfig.json
{
  "compilerOptions": {
    "target": "ES6",
    "module": "commonjs",
    "rootDir": "./src",
    "outDir": "./dist",
    "esModuleInterop": true,
    "strict": true
  },
  "include": ["src/**/*.ts"],
  "exclude": ["node_modules"]
}
EOL

# Initialize Prisma
npx prisma init --datasource-provider sqlite

# Update .env
cat <<EOL > .env
DATABASE_URL="file:./dev.db"
EOL

# Update helper.ts
cat <<EOL > helper.ts

EOL

# Update schema.prisma
cat <<EOL > prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "sqlite"
  url      = env("DATABASE_URL")
}

model Main {
  id    Int    @id @default(autoincrement())
  name  String
  value Int
}
EOL

# Generate Prisma client and migrate
npx prisma generate
npx prisma migrate dev --name init

# Create files with boilerplate content

# src/config/database.ts
cat <<EOL > src/config/database.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export default prisma;
EOL

# src/controllers/mainController.ts
cat <<EOL > src/controllers/mainController.ts
import { Request, Response } from 'express';
import prisma from '../config/database';

export const getMains = async (req: Request, res: Response): Promise<void> => {
    const mains = await prisma.main.findMany();
    res.json(mains);
};

export const createMain = async (req: Request, res: Response): Promise<void> => {
    const { name, value } = req.body;
    const main = await prisma.main.create({
        data: {
            name,
            value
        }
    });
    res.json(main);
};
EOL

# src/routes/mainRoute.ts
cat <<EOL > src/routes/mainRoute.ts
import { Router } from 'express';
import { getMains, createMain } from '../controllers/mainController';

const router = Router();

router.get('/mains', getMains);
router.post('/mains', createMain);

export default router;
EOL

# src/server.ts
cat <<EOL > src/server.ts
import express from 'express';
import mainRoute from './routes/mainRoute';

const app = express();

app.use(express.json());
app.use('/api', mainRoute);

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(\`Server is running on port \${PORT}\`);
});
EOL

# Create package.json with scripts
cat <<EOL > package.json
{
  "name": "nodejs-ts-prisma",
  "version": "1.0.0",
  "description": "A Node.js project with TypeScript and Prisma",
  "main": "dist/server.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/server.js",
    "dev": "ts-node-dev --respawn --transpile-only src/server.ts",
    "migrate": "prisma migrate dev",
    "generate": "prisma generate"
  },
  "dependencies": {
    "express": "^4.17.1",
    "prisma": "^3.5.0",
    "@prisma/client": "^3.5.0"
  },
  "devDependencies": {
    "typescript": "^4.4.4",
    "ts-node-dev": "^1.1.6",
    "ts-node": "^10.4.0",
    "chai": "^4.3.4",
    "mocha": "^8.4.0",
    "@types/node": "^16.10.2",
    "@types/express": "^4.17.13"
  },
  "author": "Abhishek Vishwakarma",
  "license": "ISC"
}
EOL

echo "Node.js TypeScript Prisma boilerplate project structure created successfully."
