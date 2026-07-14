FROM node:20-alpine

WORKDIR /app
ENV NODE_ENV=production

COPY package*.json ./
RUN npm ci --omit=dev

COPY src ./src
COPY scripts ./scripts

# usuário não-root (segurança)
USER node

EXPOSE 3000
CMD ["node", "src/server.js"]
