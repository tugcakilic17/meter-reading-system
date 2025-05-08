## 🧱 Project Structure

This repository contains a complete end-to-end solution for electricity meter reading, combining a Flutter-based mobile application and a Python Flask backend API.

- **/app**  
  The Flutter mobile application allows users to:
  - Open the device camera to capture electricity meter images
  - Manually enter meter values
  - Send scanned or manually entered data to the backend API
  - View confirmation messages returned from the server

  The app communicates with the Flask API over HTTP and supports real-time data input.

- **/api**  
  The Flask backend receives data and processes images in two ways:
  - Uses Roboflow to detect digits in the upper half of the image
  - Uses EasyOCR to extract text from the lower portion
  - Writes the results into a structured Excel file (`elektrik_fatura.xlsx`)
  
  It also supports a manual update endpoint (`/update_excel`) to write values to specific cells based on block, office number, and month.

- **README.md**  
  Documentation for project usage, structure, and setup.

- **.gitignore**  
  Ensures build files, IDE settings, and other unnecessary artifacts are not tracked.

This modular structure makes the system easy to understand, extend, and deploy across different platforms.
