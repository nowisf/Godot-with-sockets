import Database from 'better-sqlite3';
import { join } from 'path';

const db = new Database(join(__dirname, 'game.db'));

// Enable foreign keys and WAL mode for better performance
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// Create users table if it doesn't exist
db.exec(`
  CREATE TABLE IF NOT EXISTS user (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    is_banned BOOLEAN DEFAULT FALSE,
    last_connection DATETIME
  )
`);

export interface User {
  id: number;
  username: string;
  password: string;
  created_at: string;
  is_banned: boolean;
  last_connection: string | null;
}

export const UserDB = {
  // Modify the connect query to only update last_connection for existing users
  connect: db.prepare<Pick<User, "username">>(
    `UPDATE user SET last_connection = CURRENT_TIMESTAMP 
     WHERE username = @username`
  ),

  // Use this to check if user exists
  getByUsername: db.prepare<Pick<User, "username">>(
    "SELECT * FROM user WHERE username = @username"
  ),

  create: db.prepare<
    Omit<User, "id" | "created_at" | "is_banned" | "last_connection">
  >("INSERT INTO user (username, password) VALUES (@username, @password)"),

  getById: db.prepare<Pick<User, "id">>("SELECT * FROM user WHERE id = @id"),

  updateLastConnection: db.prepare<Pick<User, "id">>(
    "UPDATE user SET last_connection = CURRENT_TIMESTAMP WHERE id = @id"
  ),

  setBanStatus: db.prepare<Pick<User, "id" | "is_banned">>(
    "UPDATE user SET is_banned = @is_banned WHERE id = @id"
  ),

  delete: db.prepare<Pick<User, "id">>("DELETE FROM user WHERE id = @id"),

  disconnect: db.prepare<Pick<User, "username">>(
    "UPDATE user SET last_connection = CURRENT_TIMESTAMP WHERE username = @username"
  ),
};

export default db; 