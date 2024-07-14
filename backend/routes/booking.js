const express = require("express");
const router = express.Router();
const { body, validationResult } = require("express-validator");
const Booking = require("../model/Booking");
const fetchUser = require("../middleware/fetchUser");
const fetchAdmin = require("../middleware/fetchAdmin");
const { Turf } = require("../model/Turf");
const User = require("../model/User");
const OffUser = require("../model/OffUser");
const moment = require("moment-timezone");

router.use(express.json());

router.post("/createbooking", fetchUser, async (req, res) => {
  try {
    const { turfId, date, startTime, endTime, requestedPlayers } = req.body;
    const userId = req.user.id;
    const turf = await Turf.findById(turfId);
    const user = await User.findById(userId);
    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }

    const price = turf.rate;
    const turfName = turf.name;
    const userName = user.name;
    const serverDate = moment.utc(date).tz("Asia/Kolkata");

    const collidingBooking = await Booking.findOne({
      turf: turfId,
      date: serverDate.toDate(),
      $or: [
        { startTime: { $lt: endTime }, endTime: { $gt: startTime } },
        { startTime: { $eq: startTime }, endTime: { $eq: endTime } },
      ],
    });

    if (collidingBooking) {
      return res.status(400).json({ message: "Booking collision detected" });
    }

    const newBooking = new Booking({
      turf: turfId,
      turfName: turfName,
      user: userId,
      userName: userName,
      date: serverDate.toDate(),
      startTime: startTime,
      endTime: endTime,
      price:
        price *
        moment(endTime, "HH:mm").diff(moment(startTime, "HH:mm"), "hours"),
      rem_amount:
        price *
        moment(endTime, "HH:mm").diff(moment(startTime, "HH:mm"), "hours"),
      requestedPlayers: requestedPlayers,
      joinedPlayers: [],
    });

    await newBooking.save();

    turf.daySlots.forEach((daySlot) => {
      const slotDate = moment.utc(daySlot.date).tz("Asia/Kolkata");

      if (slotDate.isSame(serverDate, "day")) {
        daySlot.slots.forEach((slot) => {
          const slotStartTime = moment(slot.startTime, "HH:mm");
          const slotEndTime = moment(slot.endTime, "HH:mm");
          const bookingStartTime = moment(startTime, "HH:mm");
          const bookingEndTime = moment(endTime, "HH:mm");

          if (
            slotStartTime.isSameOrAfter(bookingStartTime) &&
            slotEndTime.isSameOrBefore(bookingEndTime)
          ) {
            slot.status = "booked";
          }
        });
      }
    });

    await turf.save();

    res.status(200).json({
      message: "Booking created successfully",
      booking: newBooking,
    });
  } catch (error) {
    console.error("Error creating booking:", error);
    res.status(500).json({ message: "Unexpected error occurred" });
  }
});

router.post("/createofflinebooking", async (req, res) => {
  try {
    const { turfId, name, number, date, startTime, endTime } = req.body;
    const turf = await Turf.findById(turfId);
    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }
    const turfName = turf.name;
    const price = turf.rate;
    const serverDate = moment.utc(date).tz("America/New_York");
    // Check if the user already exists or create a new user
    const collidingBooking = await Booking.findOne({
      turf: turfId,
      date: serverDate.toDate(), // Convert moment object back to JavaScript Date
      $or: [
        { startTime: { $lt: endTime }, endTime: { $gt: startTime } }, // Collision check
        { startTime: { $eq: startTime }, endTime: { $eq: endTime } },
      ],
    });

    // If there is a collision, return an error
    if (collidingBooking) {
      return res.status(400).json({ message: "Booking collision detected" });
    }
    let user = await OffUser.findOne({ number });
    if (!user) {
      user = new OffUser({ name, number });
      await user.save();
    }
    const userName = user.name;

    // Create the booking
    const booking = new Booking({
      turf: turfId,
      turfName: turfName,
      user: user._id,
      userName: userName,
      date,
      startTime,
      endTime,
      price:
        price *
        moment(endTime, "HH:mm").diff(moment(startTime, "HH:mm"), "hours"), // Calculate price for the entire range
      rem_amount:
        price *
        moment(endTime, "HH:mm").diff(moment(startTime, "HH:mm"), "hours"),
      // Other booking details
    });
    await booking.save();

    turf.daySlots.forEach((daySlot) => {
      // Convert day slot date to server's time zone
      const slotDate = moment.utc(daySlot.date).tz("America/New_York");

      // Compare dates using moment's isSame method
      if (slotDate.isSame(serverDate, "day")) {
        daySlot.slots.forEach((slot) => {
          // Check if the slot falls within the selected range
          const slotStartTime = moment(slot.startTime, "HH:mm");
          const slotEndTime = moment(slot.endTime, "HH:mm");
          const bookingStartTime = moment(startTime, "HH:mm");
          const bookingEndTime = moment(endTime, "HH:mm");
          if (
            slotStartTime.isSameOrAfter(bookingStartTime) &&
            slotEndTime.isSameOrBefore(bookingEndTime)
          ) {
            console.log(slot);
            console.log(slot.status);
            slot.status = "booked";
            console.log(slot.status);
            console.log(slot);
          }
        });
      }
    });

    // Save the updated Turf document in the database
    await turf.save();

    res
      .status(201)
      .json({ message: "Offline booking created successfully", booking });
  } catch (error) {
    console.error("Error creating offline booking:", error);
    res.status(500).json({ message: "Unexpected error occurred" });
  }
});

router.get("/userbookings", fetchUser, async (req, res) => {
  try {
    const userBookings = await Booking.find({ user: req.user.id });
    res.json(userBookings);
  } catch (error) {
    console.error(error.message);
    res.status(500).send("Unexpected error occurred");
  }
});

router.get("/today/:turfId/:date", async (req, res) => {
  try {
    const { turfId, date } = req.params;
    const startOfDay = new Date(date);
    startOfDay.setHours(0, 0, 0, 0); // Set time to the start of the day
    const endOfDay = new Date(date);
    endOfDay.setHours(23, 59, 59, 999); // Set time to the end of the day

    // Find bookings for the specified turf and date range
    const bookings = await Booking.find({
      turf: turfId,
      date: { $gte: startOfDay, $lte: endOfDay },
    });

    res.json(bookings);
  } catch (error) {
    console.error("Error fetching bookings:", error);
    res.status(500).json({ message: "Unexpected error occurred" });
  }
});

router.get("/getNext5DaysBookings/:turfId", async (req, res) => {
  try {
    const { turfId } = req.params;

    const turf = await Turf.findById(turfId);
    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }

    const startDate = moment.tz("Asia/Kolkata").startOf("day");
    const endDate = moment.tz("Asia/Kolkata").add(5, "days").endOf("day");

    const bookings = await Booking.find({
      turf: turfId,
      date: {
        $gte: startDate.toDate(),
        $lte: endDate.toDate(),
      },
    })
      .populate("turf")
      .populate("user");

    res
      .status(200)
      .json({ message: "Bookings retrieved successfully", bookings });
  } catch (error) {
    console.error("Error retrieving bookings:", error);
    res.status(500).json({ message: "Unexpected error occurred" });
  }
});

router.get("/getTurfBookings/:turfId", async (req, res) => {
  try {
    const { turfId } = req.params;

    // Check if the turf exists
    const turf = await Turf.findById(turfId);
    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }
    // Get the current date and the date 5 days in the future

    // Find bookings that fall within this date range and for the specified turf
    const bookings = await Booking.find({
      turf: turfId,
    })
      .populate("turf")
      .populate("user"); // Populate turf and user details for a more comprehensive response

    // Return the bookings in the response
    res
      .status(200)
      .json({ message: "Bookings retrieved successfully", bookings });
  } catch (error) {
    console.error("Error retrieving bookings:", error);
    res.status(500).json({ message: "Unexpected error occurred" });
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

router.get("/upcomingbookings", fetchUser, async (req, res) => {
  try {
    const today = new Date();
    // Fetch bookings where the booking date is after or equal to today's date
    const upcomingBookings = await Booking.find({
      user: req.user.id,
      date: { $gte: today },
    }).sort({ date: 1 }); // Sort bookings by date in ascending order

    // Organize bookings by date
    const organizedBookings = {};
    upcomingBookings.forEach((booking) => {
      const dateKey = booking.date.toDateString();
      if (!organizedBookings[dateKey]) {
        organizedBookings[dateKey] = [];
      }
      organizedBookings[dateKey].push(booking);
    });

    res.json(organizedBookings);
  } catch (error) {
    console.error(error.message);
    res.status(500).send("Unexpected error occurred");
  }
});

router.post("/joinbooking", fetchUser, async (req, res) => {
  try {
    const { bookingId, playersCount } = req.body;
    const userId = req.user.id;
    const user = await User.findById(userId);

    const booking = await Booking.findById(bookingId);
    if (!booking) {
      return res.status(404).json({ message: "Booking not found" });
    }

    if (playersCount > booking.requestedPlayers) {
      return res
        .status(400)
        .json({ message: "Requested players exceed the needed players" });
    }

    booking.joinedPlayers.push({
      user: userId,
      userName: user.name,
      playersCount: playersCount,
    });

    booking.requestedPlayers -= playersCount;

    const totalPlayers = booking.joinedPlayers.reduce(
      (total, join) => total + join.playersCount,
      1
    );
    const newPrice = booking.price / totalPlayers;
    booking.rem_amount = newPrice;

    await booking.save();

    res.status(200).json({
      message: "Successfully joined the booking",
      booking,
    });
  } catch (error) {
    console.error("Error joining booking:", error);
    res.status(500).json({ message: "Unexpected error occurred" });
  }
});

module.exports = router;
