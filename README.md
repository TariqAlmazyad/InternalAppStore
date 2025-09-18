# InternalAppStore

This project is a **demo** showing how to build an Internal App Store.  
It is focused on uploading **IPA files**, **manifest files**, and **app images** to create a simple internal distribution flow.  
The goal is to support **fast testing** and allow **quick enhancements** for internal apps.  

---


## Demo Video

[▶ Watch Video](https://github.com/user-attachments/assets/6b947e88-ca84-410b-a818-d0f42255cad9)





## Features

- Upload **IPA** files for iOS apps.  
- Provide a `manifest.plist` for iOS installation.  
- Attach an **app image (icon/logo)** for better visibility.  
- Display app versions in a clean list.  
- Enable quick install and update cycles for teams.  

---

## How to Use

1. **Upload files**  
   - Place the `.ipa` file in storage (Firebase Storage or any internal server).  
   - Upload the `manifest.plist` that points to the IPA.  
   - Add the app image (PNG/JPEG) to represent the app visually.  

2. **Connect to the store**  
   - Link the files in the app’s configuration.  
   - Ensure the `manifest.plist` has the correct URL pointing to the IPA file.  

3. **Browse and install**  
   - Open the Internal App Store UI.  
   - See the app image, name, and available versions.  
   - Tap “Install” to download via `itms-services`.  

---

## Notes

- This project is for **testing and demo purposes only**.  
- It is not a replacement for the official App Store.  
- Best suited for **internal teams** distributing test builds.  

---
