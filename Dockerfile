FROM node:20-alpine AS test
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY public ./public
COPY src ./src
COPY test ./test
RUN npm test

FROM node:20-alpine AS dependencies
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

FROM node:20-alpine
ENV NODE_ENV=production
WORKDIR /app
COPY --from=dependencies /app/node_modules ./node_modules
COPY public ./public
COPY src ./src
COPY package.json ./
USER node
EXPOSE 3000
CMD ["node", "src/app.js"]
