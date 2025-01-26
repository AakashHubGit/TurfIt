const express = require("express");
const router = express.Router();
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const Turf = require("../model/Turf");
const Booking = require("../model/Booking");
const fetchAdmin = require("../middleware/fetchAdmin");
const { body, validationResult } = require("express-validator");
const moment = require("moment-timezone");

router.use(express.json());

// Multer configuration with memory storage
const storage = multer.memoryStorage();

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
}).array("images", 5); // Allow up to 5 images

// Route to create a turf
router.post(
  "/createturf",
  fetchAdmin,
  upload,
  [
    // Validation of turf details
    body("name", "Turf name is required").notEmpty(),
    body("size", "Turf size is required").notEmpty(),
    body("location", "Location is required").notEmpty(),
    body("openTime", "Opening time is required").notEmpty(),
    body("closeTime", "Closing time is required").notEmpty(),
    body("price", "Turf price is required").notEmpty().isNumeric(),
    body("slotDuration", "Slot duration is required").notEmpty().isNumeric(),
  ],
  async (req, res) => {
    let success = false;

    // Checking for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success, errors: errors.array() });
    }

    try {
      // Extract request data
      const { name, size, location, openTime, closeTime, price, slotDuration } =
        req.body;

      // Process uploaded images
      const imagesBase64 = req.files.map((file) => {
        return file.buffer.toString("base64");
      });

      // Create a new turf
      const newTurf = new Turf({
        admin: req.admin.id,
        name,
        size,
        location,
        openTime,
        closeTime,
        price,
        slotDuration,
        images: imagesBase64, // Store images as Base64 strings
      });

      // Save the turf to the database
      await newTurf.save();

      success = true;
      res.status(201).json({ success, turf: newTurf });
    } catch (error) {
      console.error(error.message);

      res.status(500).send(`Unexpected error occurred: ${error.message}`);
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

// Endpoint to fetch open-close times and slot duration
router.get("/:turfId/open-close-times", async (req, res) => {
  const { turfId } = req.params;

  try {
    // Fetch the turf document from the database
    const turf = await Turf.findById(turfId);

    // Check if the turf exists
    if (!turf) {
      return res.status(404).json({ error: "Turf not found" });
    }

    // Destructure required information from the turf document
    const { openTime, closeTime, slotDuration } = turf;

    // Send the response with open-close times and slot duration
    res.json({
      openingTime: openTime,
      closingTime: closeTime,
      slotDuration,
    });
  } catch (error) {
    console.error("Error fetching turf information:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

// Endpoint to fetch slots for a specific turf and date
router.get("/:turfId/slots", async (req, res) => {
  const { turfId } = req.params;
  const { date } = req.query;

  try {
    if (!date || !moment(date, "YYYY-MM-DD", true).isValid()) {
      return res
        .status(400)
        .json({ error: "Invalid or missing date parameter" });
    }

    const turf = await Turf.findById(turfId);
    if (!turf) {
      return res.status(404).json({ error: "Turf not found" });
    }

    const { openTime, closeTime, slotDuration } = turf;
    const openingTime = moment(openTime, "HH:mm");
    const closingTime = moment(closeTime, "HH:mm");

    if (closingTime.isBefore(openingTime)) {
      return res.status(400).json({ error: "Invalid open and close times" });
    }

    const slots = [];
    let currentTime = openingTime.clone();

    while (currentTime.isBefore(closingTime)) {
      const startTime = currentTime.format("HH:mm");
      const endTime = currentTime.add(slotDuration, "minutes").format("HH:mm");
      if (moment(endTime, "HH:mm").isAfter(closingTime)) break;

      slots.push({ startTime, endTime });
    }

    res.json({
      data: {
        slots, // Wrap slots under the `data` key
      },
    });
  } catch (error) {
    console.error("Error fetching slots:", error);
    res.status(500).json({ error: "Internal server error" });
  }
});

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

module.exports = router;
