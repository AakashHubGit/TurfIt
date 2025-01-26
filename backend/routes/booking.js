const express = require("express");
const router = express.Router();
const { body, validationResult } = require("express-validator");
const Booking = require("../model/Booking");
const fetchUser = require("../middleware/fetchUser");
const Turf = require("../model/Turf");
const User = require("../model/User");
const moment = require("moment-timezone");

const mongoose = require("mongoose");
const { ObjectId } = mongoose.Types;

router.use(express.json());

router.post("/createbooking", fetchUser, async (req, res) => {
  try {
    const { turfId, date, timeSlots, adminId } = req.body;
    const userId = req.user.id;

    // Validate Turf and User
    const turf = await Turf.findById(turfId);
    const user = await User.findById(userId);

    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }
    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Calculate total booking price
    const pricePerSlot = turf.price; // Assuming price per slot is defined in the Turf model
    const totalBookingPrice = pricePerSlot * timeSlots.length;

    console.log(date);

    const newBooking = new Booking({
      turf: turfId,
      user: userId,
      date: date,
      timeSlot: timeSlots, // Array of time slots
      price: totalBookingPrice,
      rem_amount: totalBookingPrice, // Initial remaining amount is total price
      adminId: adminId, // Admin managing the booking
    });

    // Save booking
    await newBooking.save();

    // Update the user's adminId if not already present
    if (!user.adminId.includes(adminId)) {
      user.adminId.push(adminId);
      await user.save(); // Save the updated user document
    }

    res.status(200).json({
      message: "Booking created successfully",
      booking: newBooking,
    });
  } catch (error) {
    console.error("Error creating booking:", error);
    res.status(500).json({ message: "Unexpected error occurred" });
  }
});

router.get("/:turfId/booked-slots", async (req, res) => {
  const { turfId } = req.params;
  const { date } = req.query;
  console.log(date);
  try {
    // Validate required fields
    if (!date) {
      return res.status(400).json({ error: "Date is required" });
    }

    // Parse turfId to ObjectId
    const turfObjectId = new ObjectId(turfId);

    // Parse the provided date and calculate the UTC start and end times for the day
    const providedDate = new Date(date); // Assume input is in local date format
    const startOfDayUTC = new Date(
      Date.UTC(
        providedDate.getUTCFullYear(),
        providedDate.getUTCMonth(),
        providedDate.getUTCDate() - 1
      )
    );
    const endOfDayUTC = new Date(
      Date.UTC(
        providedDate.getUTCFullYear(),
        providedDate.getUTCMonth(),
        providedDate.getUTCDate()
      )
    );

    console.log("Fetching bookings for Turf:", turfObjectId, "on Date:", date);
    console.log("Querying UTC range:", startOfDayUTC, "to", endOfDayUTC);

    // Query to find bookings within the UTC range for the turf
    const bookings = await Booking.find({
      turf: turfObjectId,
      date: {
        $gte: startOfDayUTC,
        $lt: endOfDayUTC,
      },
    });

    console.log("Bookings found:", bookings);

    // Aggregate booked slots
    const bookedSlots = bookings.reduce((slots, booking) => {
      if (Array.isArray(booking.timeSlot) && booking.timeSlot.length > 0) {
        const startTime = booking.timeSlot[0].split("-")[0];
        const endTime =
          booking.timeSlot[booking.timeSlot.length - 1].split("-")[1];

        slots.push({
          startTime,
          endTime,
        });
      }
      return slots;
    }, []);

    console.log("Aggregated Booked Slots:", bookedSlots);

    // Respond with the booked slots
    res.status(200).json({
      data: {
        bookedSlots,
      },
    });
  } catch (error) {
    // Log error and respond with server error message
    console.error("Error fetching booked slots:", error.message);
    res.status(500).json({ error: "Server error. Please try again later." });
  }
});

router.put("/:id", async (req, res) => {
  const { id } = req.params;
  const { rem_amount } = req.body;

  try {
    // Find the booking by ID
    let booking = await Booking.findById(id);

    if (!booking) {
      return res
        .status(404)
        .json({ success: false, message: "Booking not found" });
    }

    // Update the booking's rem_amount
    booking.rem_amount = rem_amount;

    // Save the updated booking
    booking = await booking.save();

    res.status(200).json({ success: true, booking });
  } catch (error) {
    console.error("Error approving payment:", error);
    res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;
