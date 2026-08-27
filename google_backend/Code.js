// FILE: google_backend/Code.js
// PHAROAH ERP 2-WAY CLOUD RELAY & STORE SYNC ENGINE

function testSetup() {
  var folderName = "Pharoah_ERP_Cloud";
  var folders = DriveApp.getFoldersByName(folderName);
  var folder = folders.hasNext() ? folders.next() : DriveApp.createFolder(folderName);
  Logger.log("✅ Google Drive Pharoah Cloud Folder Ready: " + folder.getId());
}

function getCloudFolder() {
  var folderName = "Pharoah_ERP_Cloud";
  var folders = DriveApp.getFoldersByName(folderName);
  return folders.hasNext() ? folders.next() : DriveApp.createFolder(folderName);
}

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return createJsonResponse({ status: "ERROR", message: "Empty request payload." });
    }

    var request = JSON.parse(e.postData.contents);
    var action = request.action;
    var folder = getCloudFolder();

    // 1. PUSH STORE DATA (Mobile App or Web -> Cloud Drive)
    if (action === "PUSH_STORE_DATA") {
      var storeToken = (request.storeToken || "").trim().toUpperCase();
      if (!storeToken) {
        return createJsonResponse({ status: "ERROR", message: "Store Token is missing." });
      }

      var fileName = storeToken + ".json";
      var files = folder.getFilesByName(fileName);
      
      request.syncedAt = new Date().toISOString();
      var jsonPayload = JSON.stringify(request);

      if (files.hasNext()) {
        var existingFile = files.next();
        existingFile.setContent(jsonPayload);
      } else {
        folder.createFile(fileName, jsonPayload, MimeType.PLAIN_TEXT);
      }

      return createJsonResponse({
        status: "SUCCESS",
        message: "Store snapshot synced atomically to cloud.",
        syncedAt: request.syncedAt
      });
    }

    // 2. PULL STORE DATA (Cloud Drive -> Client)
    if (action === "PULL_STORE_DATA") {
      return handlePullRequest(request.storeToken, request.username, request.password, folder);
    }

    return createJsonResponse({ status: "ERROR", message: "Unknown action: " + action });

  } catch (err) {
    return createJsonResponse({ status: "ERROR", message: err.toString() });
  }
}

function doGet(e) {
  // Handles PULL_STORE_DATA via GET for complete browser CORS bypass
  if (e && e.parameter && e.parameter.action === "PULL_STORE_DATA") {
    try {
      var storeToken = e.parameter.storeToken;
      var username = e.parameter.username;
      var password = e.parameter.password;
      var folder = getCloudFolder();

      return handlePullRequest(storeToken, username, password, folder);
    } catch (err) {
      return createJsonResponse({ status: "ERROR", message: err.toString() });
    }
  }

  // Health Check / Ping
  return createJsonResponse({
    status: "ACTIVE",
    service: "Pharoah ERP Bidirectional Cloud Relay Engine",
    version: "1.0.9",
    timestamp: new Date().toISOString()
  });
}

function handlePullRequest(storeToken, username, password, folder) {
  var cleanToken = (storeToken || "").trim().toUpperCase();
  var inputUser = (username || "").trim().toLowerCase();
  var inputPass = (password || "").trim();

  if (!cleanToken) {
    return createJsonResponse({ status: "ERROR", message: "Store Key is required." });
  }

  var fileName = cleanToken + ".json";
  var files = folder.getFilesByName(fileName);

  if (!files.hasNext()) {
    return createJsonResponse({
      status: "ERROR",
      message: "Store Key not found. Please tap 'SYNC NOW' in your app first."
    });
  }

  var storeData = JSON.parse(files.next().getBlob().getDataAsString());
  var savedUser = (storeData.adminUser || "").trim().toLowerCase();
  var savedPass = (storeData.adminPassword || "").trim();

  // Validate Credentials against stored snapshot
  if (savedUser === inputUser && savedPass === inputPass) {
    return createJsonResponse({
      status: "SUCCESS",
      companyName: storeData.companyName,
      fy: storeData.fy,
      registryProfile: storeData.registryProfile,
      files: storeData.files,
      syncedAt: storeData.syncedAt
    });
  } else {
    return createJsonResponse({
      status: "ERROR",
      message: "Invalid Username or Password for Store Key: " + cleanToken
    });
  }
}

function createJsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj))
    .setMimeType(ContentService.MimeType.JSON);
}
