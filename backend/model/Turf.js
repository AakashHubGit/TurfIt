const mongoose = require("mongoose");
const { Schema } = mongoose;

// Turf Schema
const TurfSchema = new Schema({
  size: {
    type: String, // Changed from array to a single string
    required: true,
  },
  admin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "admin",
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  location: {
    type: String, // Simplified location from nested schema to a single string
    required: true,
  },
  openTime: {
    type: String,
    required: true,
  },
  closeTime: {
    type: String,
    required: true,
  },
  price: {
    type: Number, // Renamed "rate" to "price" for consistency
    required: true,
  },
  slotDuration: {
    type: Number,
    required: true,
  },
  images: [String],
  timeStamp: {
    type: Date,
    required: true,
    default: Date.now,
  },
});

const Turf = mongoose.model("turf", TurfSchema);

module.exports = Turf;
