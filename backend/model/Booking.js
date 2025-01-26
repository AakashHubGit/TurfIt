const mongoose = require("mongoose");
const { Schema } = mongoose;

const BookingSchema = new Schema({
  turf: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "turf",
    required: true,
  },
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "user",
    required: true,
  },
  date: {
    type: Date,
    required: true,
  },
  timeSlot: {
    type: [String],
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
  timestamp: {
    type: Date,
    default: Date.now, // Automatically sets the timestamp
    required: true,
  },
  adminId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "admin",
    required: true,
  },
});

const Booking =
  mongoose.models.booking || mongoose.model("booking", BookingSchema);

module.exports = Booking;
