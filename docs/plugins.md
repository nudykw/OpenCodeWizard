# OpenCode Plugins Documentation

*Read this in other languages: [Українська (plugins.uk.md)](plugins.uk.md)*

This guide provides details on the available OpenCode plugins, their purpose, and their use cases.

## Plugins Overview

| Plugin Name | Description | Best For |
| :--- | :--- | :--- |
| **[`oh-my-openagent`](oh-my-openagent.md)** | Core plugin for session management and advanced helper CLI commands. | All users (Essential) |
| **`opencode-mem`** | Long-term Rust RAG memory with hybrid search (BM25 + vector). | Analysts, researchers, long-term coders |
| **`@different-ai/opencode-browser`** | Real browser integration for web research. | Web researchers, writers |
| **`@tarquinen/opencode-smart-title`** | Generates context-aware titles for chat sessions. | Organized users, frequent chatters |
| **`opencode-token-speed-plugin`** | Real-time performance monitoring (Tokens Per Second). | Power users, model testers |
| **`opencode-codebase-index`** | Semantic indexing with file watching and auto-update. | Developers, codebase maintainers |

---

## Detailed Plugin Descriptions

### 1. [`oh-my-openagent`](oh-my-openagent.md)

* **What it does:** Provides the fundamental session orchestration, workspace utilities, and advanced helper CLI commands required for OpenCode to function effectively.
* **Who needs it:** Everyone. This is the heart of the OpenCode experience.
* **Why install:** Essential for managing chat sessions and accessing advanced assistant functionality.

### 2. `opencode-mem`

* **What it does:** Implements long-term RAG (Retrieval-Augmented Generation) memory in Rust. Uses hybrid search (BM25 keyword search + vector embeddings) to recall past interactions.
* **Who needs it:** Researchers, writers, and developers working on long-term projects where context retention is critical.
* **Why install:** Keeps the AI relevant across multiple days and sessions by "remembering" your previous work.

### 3. `@different-ai/opencode-browser`

* **What it does:** Grants the AI access to a real, headless web browser. It can navigate, scrape content, and interact with dynamic sites.
* **Who needs it:** Writers, researchers, and anyone who needs up-to-date internet data or data from complex web applications.
* **Why install:** Allows the AI to verify information, gather fresh data, and perform web-based tasks beyond its static knowledge.

### 4. `@tarquinen/opencode-smart-title`

* **What it does:** Analyzes the content of your chat and automatically renames the session to something meaningful.
* **Who needs it:** Users who keep many open chat sessions and need to quickly find the right one later.
* **Why install:** Replaces generic titles like "New Chat" with contextually relevant names.

### 5. `opencode-token-speed-plugin`

* **What it does:** Provides real-time performance monitoring, including TPS (Tokens Per Second), Average speed, and TTFT (Time To First Token).
* **Who needs it:** Performance-focused users and those troubleshooting latency.
* **Important Note:** Do not install multiple token speed plugins simultaneously, as they may conflict in the UI. Choose this one for comprehensive performance metrics.

### 6. `opencode-codebase-index`

* **What it does:** Automatically indexes your project files. It watches for changes and updates the semantic index in the background.
* **Who needs it:** Software developers.
* **Why install:** Enables high-speed, accurate semantic search across your entire codebase without manual re-indexing.
