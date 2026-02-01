# Phoenixmaze 

**Phoenixmaze** is an interactive, real-time maze generation and solving application built with the power of **Elixir** and **Phoenix LiveView**. It serves as a visual playground for understanding pathfinding algorithms, demonstrating how they navigate complex grids to find the optimal route from a starting point to a goal.

## 🌟 Key Features

*   **⚡ Real-time Visualization**: Watch algorithms work in real-time without refreshing the page, powered by Phoenix LiveView.
*   **🧠 Intelligent Pathfinding**:
    *   **A* (A-Star)**: A smart search algorithm that uses a heuristic (Manhattan distance) to find the shortest path efficiently.
    *   **Backtracking (DFS)**: A depth-first approach that blindly explores paths and backtracks upon hitting dead ends.
*   **🎮 Interactive Interface**: A clean, responsive UI built with CSS that allows you to generate new mazes and solve them instantly.
*   **🏗️ Robust Architecture**: Built on the PETAL stack for high performance and maintainability.

## 🛠️ Tech Stack

This project uses the **PETAL** stack, a modern choice for building rich, interactive web applications:
- **P**hoenix Framework (Web Interface)
- **E**lixir (Backend Logic)
- **T**ailwind CSS (Styling)
- **A**lpine.js (Lightweight Client-side Interactivity - *included via dependencies*)
- **L**iveView (Real-time updates)
+ **PostgreSQL** (Database)

## ⚙️ Prerequisites

Before you begin, ensure you have the following installed on your system. **See `requirements.txt` for specific version details.**

*   **Elixir** (v1.14 or later)
*   **Erlang/OTP** (compatible with your Elixir version)
*   **PostgreSQL** (running and accepting connections)
## 🎮 How to Play

### The Objective
Navigate the player object from the **Start** (top-left) to the **Goal** (bottom-right) of the maze.

### Controls
*   **Manual Movement**: Use your **Keyboard Arrow Keys** (⬆️ ⬇️ ⬅️ ➡️) to move the player through the maze.
*   **Auto-Move**: Stuck? Click the **Start Auto-Move** button in the bottom-left corner to let the AI solve it for you using the A* algorithm.

### Game Mechanics
*   **Levels**: There are 20 levels. The maze gets bigger and more complex as you progress.
*   **Scoring**: Earn points based on:
    *   **Speed**: How fast you solve it.
    *   **Efficiency**: Taking the shortest path (fewer steps).
*   **IQ Score(future enhancement)**: The game calculates a "Player IQ" every 5 levels based on your performance!

## 🚀 Getting Started

Follow these steps to get the project running locally on your machine.

### 1. Clone the Repository
```bash
git clone <repository_url>
cd "Maze game hackaton"
```

### 2. Setup Dependencies & Database
Run the setup script to install Elixir dependencies, create the database, run migrations, and install assets.
```bash
mix setup
```
> **Note**: If `mix setup` fails, ensure your PostgreSQL service is running and the credentials in `config/dev.exs` match your local postgres user.

### 3. Start the Server
Start the Phoenix server with the following command:
```bash
mix phx.server
```

### 4. Play the Game
Once the server is running, open your browser and visit:
👉 **[http://localhost:5000](http://localhost:5000)**

## 📂 Project Structure Overview

*   **`lib/maze_solver.ex`**: 🧠 **The Brain**. Contains the core implementation of the maze solving algorithms (A* and Backtracking).
*   **`lib/phoenixmaze_web/live/maze_live.ex`**: 🕹️ **The Controller**. The main LiveView module managing the game state.
*   **`lib/phoenixmaze_web/live/maze_live.html.heex`**: 🎨 **The View**. The HTML template for rendering the maze grid.
*   **`requirements.txt`**: 📋 **System Requirements**. Detailed list of system and software requirements.

## 🔧 Troubleshooting

*   **Port 5000 using**: The application attempts to bind to port 5000. If it fails, check if another process is using it.
*   **Database Error**: "Connection refused" usually means PostgreSQL is not running or credentials in `config/dev.exs` are wrong.

## 📚 Resources

*   [Phoenix Framework Documentation](https://hexdocs.pm/phoenix)
*   [Elixir Lang](https://elixir-lang.org/)
*   [Tailwind CSS](https://tailwindcss.com/)
