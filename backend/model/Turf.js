const mongoose = require("mongoose");
const { Schema } = mongoose;

const ReviewSchema = new Schema({
  review: {
    type: String,
    required: true,
  },
  rating: {
    type: Number,
    required: true,
  },
  username: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "user",
  },
});

const LocationSchema = new Schema({
  streetName: {
    type: String,
    required: true,
  },
  city: {
    type: String,
    required: true,
  },
});

const SlotSchema = new mongoose.Schema({
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  status: { type: String, enum: ["available", "booked"], required: true },
});

const DaySlotSchema = new mongoose.Schema({
  date: { type: Date, required: true },
  slots: [SlotSchema], // SlotSchema from your existing model
});

const TurfSchema = new Schema({
  admin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: "admin",
  },
  name: {
    type: String,
    required: true,
  },
  size: {
    type: [String],
    required: true,
  },
  imgPath: {
    type: [String],
    required: true,
  },
  sports: {
    type: [String],
    required: true,
  },
  facility: {
    type: [String],
    required: true,
  },
  rate: {
    type: Number,
    required: true,
  },
  link: {
    type: String,
    required: true,
  },
  booking_start: {
    type: Number,
    required: true,
  },
  booking_end: {
    type: Number,
    required: true,
  },
  daySlots: [DaySlotSchema],
  reviews: [ReviewSchema],
  location: LocationSchema,
  date: {
    type: Date,
    default: Date.now,
  },
});
const Review = mongoose.model("review", ReviewSchema);
const Turf = mongoose.model("turf", TurfSchema);

module.exports = { Turf, Review };
