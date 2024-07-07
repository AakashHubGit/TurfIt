const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { Turf, Review } = require("../model/Turf");
const Booking = require("../model/Booking");
const fetchAdmin = require("../middleware/fetchAdmin");
const { body, validationResult } = require("express-validator");
const moment = require("moment-timezone");

router.use(express.json());

// Set up multer storage for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, "../frontend/app/assets/uploads/"); // Upload files to the 'uploads' folder
  },
  filename: (req, file, cb) => {
    const newFileName = `${Date.now()}${path.extname(file.originalname)}`;
    cb(null, newFileName); // Rename file with custom name + extension
  },
});

// File upload limits and storage
const upload = multer({
  storage: storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB file size limit
  fileFilter: (req, file, cb) => {
    // Check file types
    const filetypes = /jpeg|jpg|png|gif/;
    const extname = filetypes.test(
      path.extname(file.originalname).toLowerCase()
    );
    const mimetype = filetypes.test(file.mimetype);
    if (extname && mimetype) {
      return cb(null, true);
    } else {
      cb("Error: Images only!");
    }
  },
}).array("images", 5); // Allow uploading up to 5 images with the field name 'images'

// Route to create a turf
router.post(
  "/createturf",
  fetchAdmin,
  // upload,
  [
    // Validation of turf details
    body("name", "Turf name is required").notEmpty(),
    body("size.*", "Turf size is required").notEmpty(), // Validate each size element
    body("sports.*", "Sports available in the turf are required").notEmpty(), // Validate each sports element
    body(
      "facility.*",
      "Facilities available in the turf are required"
    ).notEmpty(), // Validate each facility element
    body("rate", "Turf rate is required").notEmpty().isNumeric(),
    body("link", "Turf booking link is required").notEmpty(),
    body("booking_start", "Turf booking start time is required")
      .notEmpty()
      .isNumeric(),
    body("booking_end", "Turf booking end time is required")
      .notEmpty()
      .isNumeric(),
    body("streetName", "Street name is required").notEmpty(),
    body("city", "City is required").notEmpty(),
  ],
  async (req, res) => {
    let success = false;

    // Checking for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success, errors: errors.array() });
    }

    try {
      // Extract dynamic fields: size, sports, facility
      const sports = req.body.sports;
      const facility = req.body.facility;

      // Create a new turf
      const newTurf = new Turf({
        admin: req.admin.id,
        name: req.body.name,
        size: req.body.size,
        imgPath: req.body.images, // Store image paths in the database
        sports: sports,
        facility: facility,
        rate: req.body.rate,
        link: req.body.link,
        booking_start: req.body.booking_start,
        booking_end: req.body.booking_end,
        location: {
          streetName: req.body.streetName,
          city: req.body.city,
        },
      });

      // Calculate the date range for the next 30 days
      const currentDate = new Date();
      const endDate = new Date(
        currentDate.getTime() + 30 * 24 * 60 * 60 * 1000
      ); // 30 days from now

      // Generate day slots for each day in the next 30 days
      for (
        let date = new Date(currentDate);
        date <= endDate;
        date.setDate(date.getDate() + 1)
      ) {
        const daySlots = [];
        for (let i = req.body.booking_start; i < req.body.booking_end; i += 1) {
          daySlots.push({
            startTime: `${i}:00`,
            endTime: `${i + 1}:00`,
            status: "available",
          });
        }
        newTurf.daySlots.push({ date: new Date(date), slots: daySlots }); // Create a new Date object instance
      }

      // Save the turf to the database
      await newTurf.save();

      success = true;
      res.status(201).json({ success, turf: newTurf });
    } catch (error) {
      console.error(error.message);
      // Delete uploaded images if turf creation fails
      req.files.forEach((file) => {
        fs.unlinkSync(file.path);
      });
      res.status(500).send(`Unexpected error occurred ${error.message}`);
    }
  }
);

// Route to get all turfs
router.get("/allturf", async (req, res) => {
  try {
    const turfs = await Turf.find();
    res.json(turfs);
  } catch (error) {
    console.error(error.message);
    res.status(500).send("Unexpected error occurred");
  }
});

// Route to get turfs with specific owner (admin)
router.get("/adminturf", fetchAdmin, async (req, res) => {
  try {
    const turfs = await Turf.findOne({ admin: req.admin.id });
    res.json(turfs);
    console.log(turfs);
  } catch (error) {
    console.error(error.message);
    res.status(500).send("Unexpected error occurred");
  }
});

// Route to get turf by ID
router.get("/getturf/:id", async (req, res) => {
  try {
    const turf = await Turf.findById(req.params.id);
    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }
    res.json(turf);
  } catch (error) {
    console.error(error.message);
    res.status(500).send("Unexpected error occurred");
  }
});

router.post("/review/:turfId/add", async (req, res) => {
  const { review, rating, userId } = req.body;
  const { turfId } = req.params;

  try {
    const turf = await Turf.findById(turfId);
    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }

    const newReview = new Review({
      review,
      rating,
      username: userId, // Assuming you have a middleware to get the user ID
    });

    await newReview.save();

    turf.reviews.push(newReview);
    await turf.save();

    res.status(201).json({ message: "Review added successfully" });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Internal server error" });
  }
});

router.get("/getturf/:id", async (req, res) => {
  try {
    const turf = await Turf.findById(req.params.id).populate(
      "reviews.username"
    );
    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }
    res.json(turf);
  } catch (error) {
    console.error(error.message);
    res.status(500).send("Unexpected error occurred");
  }
});

router.get("/getTurfAnalytics/:turfId", async (req, res) => {
  try {
    const { turfId } = req.params;

    // Check if the turf exists
    const turf = await Turf.findById(turfId);
    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }

    const bookings = await Booking.find({ turf: turfId });

    // Calculate overall earnings
    const overallEarnings = bookings.reduce(
      (total, booking) => total + booking.price,
      0
    );

    // Group bookings by date and month
    const earningsByDate = {};
    const earningsByMonth = {};
    const bookingsByDayOfWeek = {};
    const userBookings = {};
    const timeSlotBookings = {};

    let totalBookingDuration = 0;

    bookings.forEach((booking) => {
      const date = moment(booking.date).format("YYYY-MM-DD");
      const month = moment(booking.date).format("YYYY-MM");
      const dayOfWeek = moment(booking.date).format("dddd");
      const userId = booking.userName;

      // Earnings by date
      if (!earningsByDate[date]) {
        earningsByDate[date] = 0;
      }
      earningsByDate[date] += booking.price;

      // Earnings by month
      if (!earningsByMonth[month]) {
        earningsByMonth[month] = 0;
      }
      earningsByMonth[month] += booking.price;

      // Bookings by day of the week
      if (!bookingsByDayOfWeek[dayOfWeek]) {
        bookingsByDayOfWeek[dayOfWeek] = 0;
      }
      bookingsByDayOfWeek[dayOfWeek] += 1;

      // User bookings count
      if (!userBookings[userId]) {
        userBookings[userId] = 0;
      }
      userBookings[userId] += 1;

      // Time slot bookings count
      const timeSlot = `${booking.startTime} - ${booking.endTime}`;
      if (!timeSlotBookings[timeSlot]) {
        timeSlotBookings[timeSlot] = 0;
      }
      timeSlotBookings[timeSlot] += 1;

      // Total booking duration
      const startTime = moment(booking.startTime, "HH:mm");
      const endTime = moment(booking.endTime, "HH:mm");
      totalBookingDuration += endTime.diff(startTime, "minutes");
    });

    // Find the day with the highest earnings
    const highestEarningDay = Object.keys(earningsByDate).reduce((a, b) =>
      earningsByDate[a] > earningsByDate[b] ? a : b
    );

    // Find the month with the highest earnings
    const highestEarningMonth = Object.keys(earningsByMonth).reduce((a, b) =>
      earningsByMonth[a] > earningsByMonth[b] ? a : b
    );

    // Find the user with the most bookings
    const topUser = Object.keys(userBookings).reduce((a, b) =>
      userBookings[a] > userBookings[b] ? a : b
    );

    // Find the day of the week with the most bookings
    const topDayOfWeek = Object.keys(bookingsByDayOfWeek).reduce((a, b) =>
      bookingsByDayOfWeek[a] > bookingsByDayOfWeek[b] ? a : b
    );

    // Calculate the average booking duration and average earnings per booking
    const averageBookingDuration = parseFloat(
      totalBookingDuration / bookings.length
    ).toFixed(2);
    const averageEarningsPerBooking = parseFloat(
      overallEarnings / bookings.length
    ).toFixed(2);

    // Calculate the percentage of slots booked (assuming each day has 24 slots for simplicity)
    const totalSlotsAvailable = bookings.length * 24; // Adjust this as per actual slots available in your system
    const percentageSlotsBooked = (bookings.length / totalSlotsAvailable) * 100;
    console.log(percentageSlotsBooked);
    res.status(200).json({
      overallEarnings,
      highestEarningDay,
      highestEarningMonth,
      topUser,
      topDayOfWeek,
      averageBookingDuration,
      averageEarningsPerBooking,
      percentageSlotsBooked,
    });
  } catch (error) {
    console.error("Error retrieving analytics:", error);
    res.status(500).json({ message: "Unexpected error occurred" });
  }
});

router.post("/slots/:turfId/:date", async (req, res) => {
  try {
    const { turfId, date } = req.params;
    console.log(date);
    // Find the turf by ID
    const turf = await Turf.findById(turfId);
    if (!turf) {
      return res.status(404).json({ message: "Turf not found" });
    }

    // Convert date string to Date object if needed
    const selectedDate = new Date(date);

    // Assume you have a 'daySlots' field in your Turf model that contains slots grouped by date
    const { daySlots } = turf;

    // Find the slots for the selected date
    const selectedDaySlots = daySlots.find(
      (daySlot) =>
        daySlot.date.toISOString().split("T")[0] ===
        selectedDate.toISOString().split("T")[0]
    );
    if (!selectedDaySlots) {
      return res
        .status(404)
        .json({ message: "Slots not found for the selected date" });
    }

    // Separate available and booked slots for the selected date
    const availableSlots = selectedDaySlots.slots.filter(
      (slot) => slot.status === "available"
    );
    const bookedSlots = selectedDaySlots.slots.filter(
      (slot) => slot.status === "booked"
    );

    // Send the available and booked slots data as a response
    res.json({ availableSlots, bookedSlots });
  } catch (error) {
    console.error("Error fetching turf slots:", error);
    res.status(500).json({ message: "Unexpected error occurred" });
  }
});
module.exports = router;
