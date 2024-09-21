import express from "express";
import cors from "cors";
import { createServer } from "http";
import { Server } from "socket.io";
import { User } from "./models/user.model.js";
import { Game } from "./models/game.model.js";
import { Chat } from "./models/chat.model.js";
import { GoogleGenerativeAI } from "@google/generative-ai";

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.CORS_ORIGIN,
  },
});

app.use(
  cors({
    origin: process.env.CORS_ORIGIN,
    credentials: true,
  })
);

const apiKey = process.env.GEMINI_API_KEY;
const genAI = new GoogleGenerativeAI(apiKey);

const model = genAI.getGenerativeModel({
  model: "gemini-1.5-flash",
  systemInstruction:
    "I will provide you with a message and the language I want it translated into. Please translate the message accordingly\n",
});

const generationConfig = {
  temperature: 1,
  topP: 0.95,
  topK: 64,
  maxOutputTokens: 8192,
  responseMimeType: "application/json",
};

const K_FACTOR = 32;
function expectedScore(ratingPlayer, ratingOpponent) {
  return 1 / (1 + Math.pow(10, (ratingOpponent - ratingPlayer) / 400));
}

function calculateNewRating(currentRating, opponentRating, result) {
  const expected = expectedScore(currentRating, opponentRating);

  const ratingChange = K_FACTOR * (result - expected);

  return ratingChange;
}

function swap(a, b) {
  return Math.random() < 0.5 ? [a, b] : [b, a];
}
const RATING_LEVELS = [
  { min: 1000, max: 1500 },
  { min: 1501, max: 2000 },
  { min: 2001, max: 2500 },
  { min: 2501, max: 3000 },
  { min: 3001, max: 3500 },
  { min: 3501, max: 4000 },
  { min: 4001, max: 4500 },
  { min: 4501, max: 5000 },
];

const matchmakingQueueRapid = new Map();
const matchmakingQueueBlitz = new Map();
const matchmakingQueueBullet = new Map();

function getPlayerLevel(rating) {
  for (let level of RATING_LEVELS) {
    if (rating >= level.min && rating <= level.max) {
      return `${level.min}-${level.max}`;
    }
  }
  return "1000-1500";
}

function getMatchmakingQueue(typeOfGame) {
  switch (typeOfGame.toLowerCase()) {
    case "rapid":
      return matchmakingQueueRapid;
    case "blitz":
      return matchmakingQueueBlitz;
    case "bullet":
      return matchmakingQueueBullet;
    default:
      throw new Error("Invalid game type");
  }
}
async function updateCurrentRating(player, gameType, rating) {
  try {
    const currentRating = player.gameStats[gameType].currentRating || 1000;
    player.gameStats[gameType].currentRating = currentRating + rating;
    await player.save();
  } catch (error) {
    console.error("Error updating rating:", error);
    throw error;
  }
}

async function addOpponentHistory(userId, opponentId, result) {
  await User.updateOne(
    { _id: userId, "opponentHistory.opponentId": opponentId },
    {
      $setOnInsert: { "opponentHistory.$.opponentId": opponentId },
      $inc: {
        "opponentHistory.$.winCount": result === "win" ? 1 : 0,
        "opponentHistory.$.loseCount": result === "lose" ? 1 : 0,
        "opponentHistory.$.drawCount": result === "draw" ? 1 : 0,
      },
    },
    { upsert: true }
  );
}

async function addPastMatch(userId, matchData) {
  await User.updateOne(
    { _id: userId },
    {
      $push: {
        pastMatches: matchData,
      },
    }
  );
}
async function addToQueue(player, gameType) {
  const playerLevel = getPlayerLevel(player.currentRating);
  if (!playerLevel) return;

  const queue = getMatchmakingQueue(gameType);

  if (!queue.has(playerLevel)) {
    queue.set(playerLevel, []);
  }

  player.waiting = true;
  await player.save();
  queue.get(playerLevel).push(player);
}
async function findOpponent(player, gameType) {
  const playerLevel = getPlayerLevel(player.currentRating);

  const queue = getMatchmakingQueue(gameType);
  let opponent = null;

  if (queue.has(playerLevel)) {
    const playersInQueue = queue.get(playerLevel);

    if (playersInQueue.length > 0) {
      opponent = playersInQueue.shift();
    }
  }

  if (!opponent) {
    addToQueue(player, gameType);
  }

  return opponent;
}
async function gameEnded(gameId, color) {
  try {
    if (!gameId || !color) {
      socket.emit("error", "Invalid Data");
      return;
    }

    const game = await Game.findById(gameId);

    if (!game) {
      socket.emit("error", `No room exists with the game: ${gameId}`);
      return;
    }
    let player1;
    let player2;
    if (color == "white") {
      player1 = await User.findById(game.playerWhite);
      player2 = await User.findById(game.playerBlack);
      updateCurrentRating(player1, game.gameType, game.whiteWin);
      updateCurrentRating(player2, game.gameType, game.blackLose);
    } else {
      player1 = await User.findById(game.playerBlack);
      player2 = await User.findById(game.playerWhite);
      updateCurrentRating(player1, game.gameType, game.blackWin);
      updateCurrentRating(player2, game.gameType, game.whiteLose);
    }
    addOpponentHistory(player1, player2, "win");
    addPastMatch(player1, {
      gameId: game,
      opponentId: player2,
      result: "win",
      date: new Date(),
      totalMoves: game.moves.length,
      gameType: game.gameType,
      ratingChange: color == "white" ? game.whiteWin : game.blackWin,
    });
    addOpponentHistory(player2, player1, "lose");
    addPastMatch(player2, {
      gameId: game,
      opponentId: player1,
      result: "lose",
      date: new Date(),
      totalMoves: game.moves.length,
      gameType: game.gameType,
      ratingChange: color == "white" ? game.whiteLose : game.whiteLose,
    });
    player1.lastGameStatus = "completed";
    player2.lastGameStatus = "completed";

    game.gameIsOver = true;
    game.endTime = Date.now();
    await Promise.all([game.save(), player1.save(), player2.save()]);
  } catch {
    console.log("error in update");
  }
}
io.on("connection", async (socket, username) => {
  if (username) {
    const player = await User.findOne({ username });
    player.isOnline = true;
    player.socketId = socket.id;
    await player.save();
  }

  console.log(`New connection to server ${socket.id}`);

  socket.on("start-game", async ({ userName, gameType }) => {
    try {
      if (!gameType || !userName) {
        socket.emit("error", "Invalid Data");
        return;
      }
      const player1 = await User.findOne({ userName });
      if (!player1) {
        socket.emit("error", "User not found");
        return;
      }
      const player2 = await findOpponent(player1, gameType);

      if (!player2) {
        socket.emit("wait", "No opponent found wait for it");
        return;
      }
      [player1, player2] = swap(player1, player2);

      const newGame = await Game.create({
        playerWhite: player1,
        whiteLan: player1.languagePreferred,
        blackLan: player2.languagePreferred,

        whiteDraw: calculateNewRating(
          player1.currentRating,
          player2.currentRating,
          0.5
        ),
        whiteLose: calculateNewRating(
          player1.currentRating,
          player2.currentRating,
          0
        ),
        whiteWin: calculateNewRating(
          player1.currentRating,
          player2.currentRating,
          1
        ),

        playerBlack: player2,
        blackDraw: calculateNewRating(
          player2.currentRating,
          player1.currentRating,
          0.5
        ),
        blackLose: calculateNewRating(
          player2.currentRating,
          player1.currentRating,
          0
        ),
        blackWin: calculateNewRating(
          player2.currentRating,
          player1.currentRating,
          1
        ),

        chat: [],
        chessBoardState:
          "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
        currentTurn: "white",
      });

      if (!newGame) {
        socket.emit("error", "Something went wrong while creating game");
        return;
      }
      player1.lastGame = newGame;
      player1.lastGameStatus = "ongoing";
      player1.waiting = false;
      await player1.save();

      console.log(`${player1.username} created the ${newGame._id}`);

      socket.join(newGame._id);
      io.to(player2.socketId).emit("join-game", newGame._id);
      socket.emit("game-started", newGame);
    } catch (error) {
      console.error(`Error creating room: ${error.message}`);
      socket.emit("error", "An error occurred while creating the room");
    }
  });
  socket.on("cancel-request", async ({ username, gameType }) => {
    try {
      const player = await User.findOne({ username });
      await findOpponent(player, gameType);
    } catch (error) {
      console.error(`Error joining room: ${error.message}`);
      socket.emit("error", "An error occurred while cancelling request");
    }
  });

  socket.on("joining-game", async ({ gameId, username }) => {
    try {
      const game = await Game.findById(gameId);
      const player = await User.findOne({ username });
      socket.join(gameId);
      player.lastGame = game;
      player.lastGameStatus = "ongoing";
      player.waiting = false;
      await player.save();

      io.to(gameId).emit("joined", { username });
      socket.emit("game-started", {
        game,
      });
    } catch (error) {
      console.error(`Error joining room: ${error.message}`);
      socket.emit("error", "An error occurred while joining the room");
    }
  });

  socket.on("resign-game", async ({ gameId, color }) => {
    try {
      if (!gameId || !color) {
        socket.emit("error", "Invalid Data");
        return;
      }

      const game = await Game.findById(gameId);

      if (!game) {
        socket.emit("error", `No room exists with the game: ${gameId}`);
        return;
      }
      await gameEnded(gameId, color == "white" ? "black" : "white");
    } catch (error) {
      console.error(`Error leaving room: ${error.message}`);
      socket.emit("error", "An error occurred while leaving the room");
    }
  });
  socket.on("win-game", async ({ gameId, color }) => {
    try {
      if (!gameId || !color) {
        socket.emit("error", "Invalid Data");
        return;
      }

      const game = await Game.findById(gameId);

      if (!game) {
        socket.emit("error", `No room exists with the game: ${gameId}`);
        return;
      }
      await gameEnded(gameId, color);
    } catch (error) {
      console.error(`Error leaving room: ${error.message}`);
      socket.emit("error", "An error occurred while leaving the room");
    }
  });
  socket.on("draw-game", async ({ gameId }) => {
    try {
      if (!gameId) {
        socket.emit("error", "Invalid Data");
        return;
      }

      const game = await Game.findById(gameId);

      if (!game) {
        socket.emit("error", `No room exists with the game: ${gameId}`);
        return;
      }
      const player1 = await User.findById(game.playerWhite);
      const player2 = await User.findById(game.playerBlack);

      addOpponentHistory(player1, player2, "draw");
      addPastMatch(player1, {
        gameId: game,
        opponentId: player2,
        result: "draw",
        date: new Date(),
        totalMoves: game.moves.length,
        gameType: game.gameType,
        ratingChange: game.whiteDraw,
      });
      addOpponentHistory(player2, player1, "draw");
      addPastMatch(player2, {
        gameId: game,
        opponentId: player1,
        result: "draw",
        date: new Date(),
        totalMoves: game.moves.length,
        gameType: game.gameType,
        ratingChange: game.blackDraw,
      });
      updateCurrentRating(player1, game.gameType, game.whiteDraw);
      updateCurrentRating(player2, game.gameType, game.blackDraw);

      player1.lastGameStatus = "completed";
      player2.lastGameStatus = "completed";

      game.gameIsOver = true;
      game.endTime = Date.now();
      await game.save();

      await player1.save();
      await player2.save();
    } catch (error) {
      console.error(`Error leaving room: ${error.message}`);
      socket.emit("error", "An error occurred while drawing");
    }
  });
  socket.on("update-board", async ({ gameId, chessBoard, senderColor }) => {
    try {
      if (!gameId || !chessBoard || !senderColor) {
        socket.emit("error", "Invalid Data");
        return;
      }

      const game = await Game.findById(gameId);

      if (!game) {
        socket.emit("error", `No room exists with the name: ${gameId}`);
        return;
      }

      const turn = senderColor === "white" ? "black" : "white";
      game.chessBoardState = chessBoard;
      game.currentTurn = turn;

      console.log(`Saving board: ${chessBoard}   ${turn} in ${gameId}`);

      await game.save();

      io.to(gameId).emit("newBoard", { chessBoard, currentTurn });
    } catch (error) {
      console.error("Error sending new board:", error);
      socket.emit("error", "An error occurred while updating the board");
    }
  });

  socket.on("send-draw-proposal", async ({ gameId, playerId }) => {
    try {
      if (!gameId || !playerId) {
        socket.emit("error", "Invalid Data");
        return;
      }

      const game = await Game.findById(gameId);

      if (!game) {
        socket.emit("error", `No room exists with the name: ${gameId}`);
        return;
      }

      io.to(gameId).emit("draw-proposal", { playerId });
    } catch (error) {
      console.error(`Error while setting gameover: ${error.message}`);
      socket.emit("error", "An error occurred while setting gameover");
    }
  });
  socket.on("send-message", async ({ gameId, senderId, message }) => {
    try {
      if (!gameId || !color || !message) {
        socket.emit("error", "Invalid Data");
        return;
      }

      const game = await Game.findById(gameId);

      if (!game) {
        socket.emit("error", `No room exists with the name: ${gameId}`);
        return;
      }

      const translate = model.startChat({
        generationConfig,
        history: [
          {
            role: "user",
            parts: [{ text: message }],
          },
        ],
      });

      const result = await translate.sendMessage(message);
      const translatedMessage = result.response
        .text()
        .trim()
        .replace(/^"|"$/g, "");
      const chat = await Chat.create({
        message,
        translatedMessage,
        senderId,
      });
      io.to(gameId).emit("new-message", chat);
    } catch (error) {
      console.error(`Error while setting gameover: ${error.message}`);
      socket.emit("error", "An error occurred while setting gameover");
    }
  });
  socket.on("rejected-draw-proposal", async ({ gameId, playerId }) => {
    try {
      if (!gameId || !playerId) {
        socket.emit("error", "Invalid Data");
        return;
      }

      const game = await Game.findById(gameId);

      if (!game) {
        socket.emit("error", `No room exists with the name: ${gameId}`);
        return;
      }

      io.to(gameId).emit("rejected-proposal", { playerId });
    } catch (error) {
      console.error(`Error while setting gameover: ${error.message}`);
      socket.emit("error", "An error occurred while setting gameover");
    }
  });
  socket.on("send-answer", async ({ gameId, sdpAnswer }) => {
    try {
      if (!gameId || !sdpAnswer) {
        socket.emit("error", "Invalid Data");
        return;
      }

      console.log("Sending Answer to give offer");
      socket.broadcast.to(gameId).emit("answered", { sdpAnswer });
    } catch (error) {
      console.error("Error sending new board:", error);
      socket.emit("error", "An error occurred while updating the board");
    }
  });

  socket.on("IceCandidateA", async ({ gameId, iceCandidate }) => {
    try {
      if (!gameId || !iceCandidate) {
        socket.emit("error", "Invalid Data");
        return;
      }
      console.log("Sending first ice candidates to give answer");
      socket.broadcast.to(gameId).emit("first-IceCandidate", { iceCandidate });
    } catch (error) {
      console.error("Error sending new board:", error);
      socket.emit("error", "An error occurred while updating the board");
    }
  });

  socket.on("IceCandidateB", async ({ gameId, iceCandidate }) => {
    try {
      if (!gameId || !iceCandidate) {
        socket.emit("error", "Invalid Data");
        return;
      }
      console.log("Sending second ice candidates to give first ice candidates");
      socket.broadcast.to(gameId).emit("second-IceCandidate", { iceCandidate });
    } catch (error) {
      console.error("Error sending new board:", error);
      socket.emit("error", "An error occurred while updating the board");
    }
  });

  socket.on("disconnect", async () => {
    console.log(`${socket.id} successfully disconnected`);
    if (username) {
      const player = await User.findOne({ username });
      player.isOnline = false;
      await player.save();
    }
  });
});

export { server };
