# Repository Files Description

This document describes the purpose of most files in the Reflext-XR repository, which consists of a Node.js backend and a Swift iOS app called Inscape for AI image generation.

## Backend (Node.js)

### Root Files
- **package.json**: Defines the project dependencies, scripts, and metadata for the Node.js backend. Includes dependencies like OpenAI SDK, AWS S3 client, Express, PostgreSQL client, etc.
- **server.js**: The main entry point for the backend server. Sets up Express app, middleware (CORS, rate limiting), routes, and starts the server on port 3000.

### Config
- **config/database.js**: Handles database initialization and connection using PostgreSQL.

### Controllers
- **controllers/imageController.js**: Manages image-related operations including generating AI images via OpenAI, uploading to storage, saving to database, fetching user images, and deleting images. Handles credit deduction for image generation.
- **controllers/userController.js**: Likely handles user authentication, registration, and profile management (not fully read, but inferred from routes).

### Database
- **database/setup.sql**: SQL script to set up the database schema, including tables for users and images.

### Middleware
- **middleware/auth.js**: Authentication middleware, probably JWT-based, to protect routes.
- **middleware/rateLimiter.js**: Rate limiting middleware to prevent abuse.

### Routes
- **routes/images.js**: Defines API routes for image operations (generate, get, delete).
- **routes/users.js**: Defines API routes for user operations (login, register, etc.).

### Services
- **services/openaiService.js**: Integrates with OpenAI's DALL-E API to generate images from text prompts. Uses model 'gpt-image-1' (DALL-E 3) with 1024x1024 size.
- **services/storageService.js**: Handles uploading and deleting images to/from AWS S3 (or compatible storage like Cloudflare R2). Converts base64 data to images and manages public URLs.

## Inscape (Swift iOS App)

### Root Files
- **InscapeApp.swift**: The main app struct, entry point for the SwiftUI app. Manages the session state and displays ContentView.
- **ContentView.swift**: The root view that switches between AuthView (for unauthenticated users) and HomeView (for authenticated users). Contains the main tab bar with tabs for Generate, Gallery, History, and Profile.
- **AuthView.swift**: View for user authentication (login/register).

### Assets
- **Assets.xcassets/**: Contains app icons, images, and other assets like calm_bubbles, calm_freedraw, etc., used in the UI.

### Core
- **Core/Models/**: Data models like DailyCreationConcept, ImageModel for structuring data.
- **Core/Networking/APIClient.swift**: Handles API calls to the backend.
- **Core/Services/**: Services like KeychainService (secure storage), SessionManager (user session), StoreKitService (in-app purchases).

### Features
- **Features/Create/**: Views for creating images, including ConceptsView, CreateView, PromptView, ImageResultView, etc.
- **Features/CreativeCalm/**: Views for relaxation features like mandalas, bubbles, free draw, etc.
- **Features/Gallery/**: GalleryView and GalleryViewModel for displaying user's generated images.
- **Features/GenerateImage/**: Likely views for image generation process.
- **Features/History/**: History view for past activities.
- **Features/Home/**: Home view with navigation to different sections.
- **Features/Learn/**: Learn views for educational content.

### Xcode Project
- **Inscape.xcodeproj/** and **project.pbxproj**: Xcode project files.
- **xcuserdata/**: User-specific Xcode settings.

This covers the main files. The app is an AI image generation tool with creative calm features, user gallery, and in-app purchases for credits.</content>
<parameter name="filePath">/workspaces/Reflext-XR/repository-files-description.md