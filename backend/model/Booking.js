const mongoose = require("mongoose");
const { Schema } = mongoose;

const BookingSchema = new Schema({
  turf: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "turf",
  },
  turfName: {
    type: String,
    required: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "user",
  },
  userName: {
    type: String,
    required: true,
  },
  date: {
    type: Date,
    required: true,
  },
  startTime: {
    type: String,
    required: true,
  },
  endTime: {
    type: String,
    required: true,
  },
  price: {
    type: Number,
    required: true,
  },
  rem_amount: {
    type: Number,
    required: true,
  },
  totalPlayers: {
    type: Number,
    required: false,
  },
  requestedPlayers: {
    type: Number,
    required: false,
  },
  joinedPlayers: [
    {
      user: { type: mongoose.Schema.Types.ObjectId, ref: "user" },
      userName: String,
      playersCount: Number,
      price: Number,
    },
  ],
});

const Booking = mongoose.model("booking", BookingSchema);

module.exports = Booking;
