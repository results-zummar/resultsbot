# Najah Telegram Bot — Render deployment image
FROM node:20-slim

WORKDIR /app

ENV NODE_ENV=production

COPY package.json ./
RUN npm install --no-audit --no-fund

COPY . .

RUN npm run build

# Install Chromium + system deps for Playwright (root inside Docker is fine)
RUN npx playwright install --with-deps chromium

CMD ["node", "dist/index.js"]
