# Inscape

AI image generation iOS app + Node.js backend.

## Backend Setup
```
cd Backend
npm install
cp .env.example .env
# Fill in .env with your values
node config/database.js
node server.js
```

## iOS Setup
- Open Inscape.xcodeproj in Xcode
- Select iPhone simulator
- Press ⌘R

## Requirements
- Node.js 18+
- PostgreSQL
- OpenAI API key
