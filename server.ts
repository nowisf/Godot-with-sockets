import WebSocket from "ws";
import { UserDB, User } from "./db";
import crypto from "crypto";

// Interface for incoming player data (includes password)
interface AuthMessage {
  type: "auth";
  username: string;
  password: string;
}

interface PositionMessage {
  msg_type: "player_pos";
  data: {
    username: string;
    x: number;
    y: number;
  };
}

// Interface for game state (excludes password)
interface GameStatePlayer {
  id: number;
  username: string;
  position?: {
    x: number;
    y: number;
  };
}

// Helper function to hash passwords
function hashPassword(password: string): string {
  return crypto.createHash("sha256").update(password).digest("hex");
}

const port: number = 9001;
const wss: WebSocket.Server = new WebSocket.Server({ port });

let gameState: GameStatePlayer[] = [];
// Track authenticated connections
const authenticatedClients = new Map<WebSocket, string>();

console.log(`running on ws://127.0.0.1:${port}`);

wss.on("connection", (ws: WebSocket) => {
  ws.on("message", (message: WebSocket.RawData) => {
    const data = JSON.parse(message.toString());
    console.log("Received data:", data);

    // Handle authentication message
    if (data.type === "auth") {
      const authData = data as AuthMessage;
      
      if (!authData.username || !authData.password || 
          typeof authData.username !== "string" || 
          typeof authData.password !== "string") {
        console.error("Invalid authentication data");
        ws.close(1008, "Invalid authentication data");
        return;
      }

      // Check if user exists
      const user = UserDB.getByUsername.get({ username: authData.username }) as User | undefined;

      if (!user) {
        // If user doesn't exist, create new user
        try {
          const hashedPassword = hashPassword(authData.password);
          const newUser = {
            username: authData.username.trim(),
            password: hashedPassword,
          };

          console.log("Creating user:", { ...newUser, password: "***" });
          UserDB.create.run(newUser);
          
          // Add to authenticated clients
          authenticatedClients.set(ws, authData.username);
          
          // Add to game state
          const newPlayer: GameStatePlayer = {
            id: gameState.length + 1,
            username: authData.username,
            position: { x: 0, y: 0 }
          };
          gameState.push(newPlayer);
          
          console.log(`new player connected: ${authData.username}`);
        } catch (err) {
          console.error("Error creating user:", err);
          ws.close(1008, "Failed to create user");
          return;
        }
      } else {
        // If user exists, verify password
        const hashedPassword = hashPassword(authData.password);
        if (user.password !== hashedPassword) {
          console.error("Invalid password for user:", authData.username);
          ws.close(1008, "Invalid credentials");
          return;
        }

        if (user.is_banned) {
          console.error("Banned user attempted to connect:", authData.username);
          ws.close(1008, "User is banned");
          return;
        }

        // Update last connection
        UserDB.connect.run({ username: authData.username });
        
        // Add to authenticated clients
        authenticatedClients.set(ws, authData.username);
        
        // Add to game state if not already present
        if (!gameState.some(player => player.username === authData.username)) {
          const newPlayer: GameStatePlayer = {
            id: gameState.length + 1,
            username: authData.username,
            position: { x: 0, y: 0 }
          };
          gameState.push(newPlayer);
          console.log(`new player connected: ${authData.username}`);
        }
      }
    }
    // Handle position updates
    else if (data.msg_type === "player_pos") {
      const posData = data as PositionMessage;
      
      // Verify this is an authenticated client
      const username = authenticatedClients.get(ws);
      if (!username || username !== posData.data.username) {
        console.error("Unauthorized position update attempt");
        ws.close(1008, "Unauthorized");
        return;
      }

      // Update game state
      const player = gameState.find(p => p.username === username);
      if (player) {
        player.position = {
          x: posData.data.x,
          y: posData.data.y
        };
      }
    }

    // Broadcast the game state to all connected clients
    wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(gameState));
      }
    });
  });

  ws.on("close", () => {
    // Get username from authenticated clients
    const username = authenticatedClients.get(ws);
    if (username) {
      UserDB.disconnect.run({ username });
      gameState = gameState.filter(player => player.username !== username);
      authenticatedClients.delete(ws);
      console.log(`player disconnected: ${username}`);
    }

    // Broadcast the updated game state after player disconnection
    wss.clients.forEach((client) => {
      if (client.readyState === WebSocket.OPEN) {
        client.send(JSON.stringify(gameState));
      }
    });
  });
});
